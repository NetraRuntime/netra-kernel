from __future__ import annotations

import hashlib
import subprocess
from pathlib import Path
from typing import Any

from ...contracts import FixedKernelContract
from ...epilogues import CAPABILITIES, raw_epilogue_supported
from ...planner import Plan, _request
from ...tactics import Tactic, gfx950_registry
from .catalog import FixedAssemblyTactic, _source_closure


_TEMPLATE_ROOT = Path("kernels/gfx950/templates")
_SHARED_TEMPLATES = (
    "common/abi.inc",
    "common/metadata.inc",
    "dense/fp8_block128.inc",
    "dense/mfma_tiles.inc",
    "dense/weight_layouts.inc",
    "dense/epilogues.inc",
)
_SCHEDULES = {
    "gfx950.raw_dense_m1_one_wave": (
        "NETRA_DENSE_FP8_M1_ONE_WAVE",
        "wave1",
    ),
    "gfx950.raw_dense_m1_four_wave_lds": (
        "NETRA_DENSE_FP8_M1_FOUR_WAVE_LDS",
        "wave4_lds",
    ),
}


def _sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _pinned_source(repo_root: Path, tactic: Tactic) -> bytes:
    """Load deleted historical goldens by immutable revision and verify the blob."""
    if tactic.source is None:
        raise ValueError(f"raw tactic {tactic.name} lacks a golden source reference")
    source = repo_root / tactic.source
    if source.is_file():
        payload = source.read_bytes()
    elif tactic.source_revision:
        try:
            payload = subprocess.run(
                ["git", "show", f"{tactic.source_revision}:{tactic.source}"],
                cwd=repo_root,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ).stdout
        except (OSError, subprocess.CalledProcessError) as exc:
            raise FileNotFoundError(
                f"registered tactic source is absent and pinned revision cannot be read: "
                f"{tactic.source_revision}:{tactic.source}"
            ) from exc
    else:
        raise FileNotFoundError(f"registered tactic source is missing: {source}")
    actual = _sha256(payload)
    if tactic.source_sha256 and actual != tactic.source_sha256:
        raise ValueError(
            f"pinned golden source hash mismatch for {tactic.name}: "
            f"expected {tactic.source_sha256}, got {actual}"
        )
    return payload


def _canonical_symbol(request: dict[str, Any], schedule: str) -> str:
    """Return a model-independent symbol for one fully specialized contract."""
    input_dtype = request["input_dtype"].value.replace("_", "")
    output_dtype = request["output_dtype"].value.replace("_", "")
    epilogue = request["epilogue"].value.replace("_", "")
    return (
        f"netra_dense_m{request['m']}_n{request['n']}_k{request['k']}_"
        f"{input_dtype}_{output_dtype}_{epilogue}_gfx950_{schedule}"
    )


def _copy_template_closure(
    generated: Path, repo_root: Path, schedule_template: str
) -> dict[str, str]:
    include_root = generated / "includes"
    hashes: dict[str, str] = {}
    for relative in (*_SHARED_TEMPLATES, schedule_template):
        source = repo_root / _TEMPLATE_ROOT / relative
        if not source.is_file():
            raise FileNotFoundError(f"registered assembly template is missing: {source}")
        payload = source.read_bytes()
        destination = include_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and destination.read_bytes() != payload:
            raise RuntimeError(f"generated template collision: {relative}")
        destination.write_bytes(payload)
        hashes[f"generated/includes/{relative}"] = _sha256(payload)
    return hashes


def _copy_fixed_template_closure(
    generated: Path, repo_root: Path, tactic: FixedAssemblyTactic
) -> dict[str, str]:
    include_root = generated / "includes"
    hashes: dict[str, str] = {}
    for relative, payload in _source_closure(repo_root, tactic.template):
        destination = include_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and destination.read_bytes() != payload:
            raise RuntimeError(f"generated template collision: {relative}")
        destination.write_bytes(payload)
        hashes[f"generated/includes/{relative}"] = _sha256(payload)
    return hashes


def instantiate_fixed_source(
    tactic: FixedAssemblyTactic,
    contract: FixedKernelContract,
    *,
    macro_symbols: tuple[str, ...] | None = None,
) -> tuple[bytes, tuple[str, ...]]:
    """Emit one fully specialized assembler translation unit."""
    if macro_symbols is None:
        extra_macro_symbols = tuple(
            f"{contract.symbol}_{parameter.removesuffix('_symbol')}"
            for parameter in tactic.macro_parameters[1:]
        )
        macro_symbols = (contract.symbol, *extra_macro_symbols)
    if len(macro_symbols) != len(tactic.macro_parameters):
        raise ValueError(
            f"{tactic.name} requires {len(tactic.macro_parameters)} macro symbols, "
            f"received {len(macro_symbols)}"
        )
    constants = (
        ("NETRA_TARGET_GFX", 950),
        ("NETRA_WAVE_SIZE", contract.wave_size),
        *contract.constants,
        *contract.specialization,
    )
    lines = [
        "// SPDX-License-Identifier: MIT",
        "// Deterministic Netra compiler output; all choices are assembler-time constants.",
        f"// Tactic: {tactic.name}; contract: {contract.stable_id}.",
        "",
    ]
    lines.extend(f"\t.set {name}, {value}" for name, value in constants)
    lines.extend((
        "",
        f'\t.include "{tactic.template}"',
        f"\t{tactic.instantiation_macro} {', '.join(macro_symbols)}",
        "",
    ))
    # Additional macro symbol parameters may name mutually exclusive entry
    # points. The registered exact contract resolves to the primary symbol;
    # do not advertise inactive macro arguments as code-object exports.
    return "\n".join(lines).encode("utf-8"), (contract.symbol,)


# Compatibility for callers of the initial compiler prototype.
_fixed_wrapper = instantiate_fixed_source


def _emit_fixed_candidate(
    planned: Any, generated: Path, repo_root: Path
) -> dict[str, Any]:
    tactic = planned.tactic
    contract = planned.contract
    if not isinstance(tactic, FixedAssemblyTactic) or not isinstance(
        contract, FixedKernelContract
    ):
        raise TypeError("fixed candidate requires a fixed assembly tactic and contract")
    payload, symbols = instantiate_fixed_source(tactic, contract)
    destination = generated / f"{contract.symbol}.s"
    if destination.exists() and destination.read_bytes() != payload:
        raise RuntimeError(f"generated source collision: {destination.name}")
    destination.write_bytes(payload)
    template_hashes = _copy_fixed_template_closure(generated, repo_root, tactic)
    return {
        "tactic": tactic.name,
        "tactic_id": tactic.stable_id,
        "contract_id": contract.stable_id,
        "maturity": tactic.maturity.value,
        "selected": True,
        "artifact_kind": "raw_assembly_template",
        "source": f"generated/{destination.name}",
        "source_sha256": _sha256(payload),
        "generated_from_template": True,
        "template": f"generated/includes/{tactic.template}",
        "template_files": template_hashes,
        "equivalence_status": "not_run_for_generated_symbol",
        "symbol": contract.symbol,
        "symbols": list(symbols),
        "kernarg_size": contract.kernarg_size,
        "launch": {
            "grid": list(contract.launch.grid),
            "block": list(contract.launch.block),
            "lds_bytes": contract.launch.lds_bytes,
            "dynamic_lds_bytes": contract.launch.dynamic_lds_bytes,
        },
    }


def _wrapper(
    request: dict[str, Any], tactic: Tactic, *, symbol: str, template: str, macro: str
) -> bytes:
    if not raw_epilogue_supported(request["epilogue"]):
        capability = CAPABILITIES[request["epilogue"]]
        raise ValueError(
            f"raw gfx950 dense epilogue {request['epilogue'].value} is unsupported: "
            f"{capability.note}"
        )
    parameters = dict(tactic.compile_parameters)
    waves = int(parameters["waves_per_workgroup"])
    capability = CAPABILITIES[request["epilogue"]]
    lines = (
        "// SPDX-License-Identifier: MIT",
        "// Deterministic Netra compiler output. All contract values are assembler-time constants.",
        f"// Tactic: {tactic.name}; maturity remains {tactic.maturity.value}.",
        "",
        f"\t.set NETRA_M, {request['m']}",
        f"\t.set NETRA_N, {request['n']}",
        f"\t.set NETRA_K, {request['k']}",
        "\t.set NETRA_TILE_N, 16",
        f"\t.set NETRA_WAVES_PER_WG, {waves}",
        f"\t.set NETRA_SCALE_BLOCK_K, {request['activation_scale_block']}",
        f"\t.set NETRA_SCALE_BLOCK_N, {request['weight_scale_block'][0]}",
        "\t.set NETRA_WEIGHT_LAYOUT, 1",
        f"\t.set NETRA_EPILOGUE, {capability.assembly_value}",
        "",
        f'\t.include "{template}"',
        f"\t{macro} {symbol}",
        "",
    )
    return "\n".join(lines).encode("utf-8")


def emit_specialized_candidates(
    plan: Plan, output: Path, repo_root: Path
) -> list[dict[str, Any]]:
    """Instantiate fixed raw-assembly candidates; never mutate or select goldens."""
    generated = output / "generated"
    generated.mkdir(parents=True, exist_ok=True)
    records: dict[str, dict[str, Any]] = {}
    for planned in plan.operations:
        if planned.operation.kind == "fixed_kernel" and planned.execution == "kernel":
            record = _emit_fixed_candidate(planned, generated, repo_root)
            key = f"{record['tactic']}:{record['contract_id']}"
            existing = records.get(key)
            if existing is not None and existing != record:
                raise RuntimeError(f"conflicting fixed candidate record: {key}")
            records[key] = record
            continue
        if planned.operation.kind != "dense":
            continue
        request = _request(planned.operation, plan.profile, "gfx950")
        for tactic in gfx950_registry():
            schedule = _SCHEDULES.get(tactic.name)
            if (
                schedule is None
                or tactic.artifact_kind != "raw_assembly"
                or tactic.source is None
                or tactic.predicate.rejection_reasons(request)
            ):
                continue
            macro, suffix = schedule
            if tactic.source_template is None:
                raise ValueError(f"raw tactic {tactic.name} lacks source_template")
            try:
                template = Path(tactic.source_template).relative_to(_TEMPLATE_ROOT).as_posix()
            except ValueError as exc:
                raise ValueError(
                    f"raw tactic template must be under {_TEMPLATE_ROOT}: "
                    f"{tactic.source_template}"
                ) from exc
            symbol = _canonical_symbol(request, suffix)
            payload = _wrapper(
                request, tactic, symbol=symbol, template=template, macro=macro
            )
            destination = generated / f"{symbol}.s"
            if destination.exists() and destination.read_bytes() != payload:
                raise RuntimeError(f"generated source collision: {destination.name}")
            destination.write_bytes(payload)
            template_hashes = _copy_template_closure(generated, repo_root, template)
            golden_payload = _pinned_source(repo_root, tactic)
            golden_name = Path(tactic.source).name
            golden_artifact = generated / "golden" / golden_name
            golden_artifact.parent.mkdir(parents=True, exist_ok=True)
            if golden_artifact.exists() and golden_artifact.read_bytes() != golden_payload:
                raise RuntimeError(f"generated golden-source collision: {golden_name}")
            golden_artifact.write_bytes(golden_payload)
            records[tactic.name] = {
                "tactic": tactic.name,
                "maturity": tactic.maturity.value,
                "selected": False,
                "source": f"generated/{destination.name}",
                "source_sha256": _sha256(payload),
                "generated_from_template": True,
                "template": f"generated/includes/{template}",
                "template_files": template_hashes,
                "golden_source": tactic.source,
                "golden_source_revision": tactic.source_revision,
                "golden_source_artifact": f"generated/golden/{golden_name}",
                "golden_source_sha256": _sha256(golden_payload),
                "equivalence_status": "not_run",
                "symbol": symbol,
                "kernarg_size": 40,
                "compatibility_symbol": tactic.symbol,
                "epilogue": request["epilogue"].value,
                "launch": {
                    "grid": list(tactic.launch.grid),
                    "block": list(tactic.launch.block),
                    "lds_bytes": tactic.launch.lds_bytes,
                    "dynamic_lds_bytes": tactic.launch.dynamic_lds_bytes,
                },
            }
    return [records[key] for key in sorted(records)]


# Kept as an internal compatibility name for callers created during Stage 1.
emit_preserved_candidates = emit_specialized_candidates
