from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any

from ...contracts import FixedKernelContract
from ...planner import Plan
from .catalog import FixedAssemblyTactic, _source_closure


def _sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


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
    return [records[key] for key in sorted(records)]


# Kept as an internal compatibility name for callers created during Stage 1.
emit_preserved_candidates = emit_specialized_candidates
