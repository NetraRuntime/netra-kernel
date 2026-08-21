#!/usr/bin/env python3
"""Build fixed gfx950 fused normalization and group-quant assembly tactics."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class Variant:
    tactic: str
    symbol: str
    rows: int
    grid: tuple[int, int, int]
    text_sha256: str
    metadata: dict[str, int]


VARIANTS = (
    Variant(
        "add_rmsnorm_group_quant_n5120",
        "netra_add_rmsnorm_group_quant_n5120_gfx950",
        8,
        (8, 1, 1),
        "c14e41486b1c9bbd175d2efba1297c1188bc0e54d45d907396192e725762ec80",
        {"agpr_count": 0, "vgpr_count": 28, "sgpr_count": 46,
         "kernarg_segment_size": 96, "group_segment_fixed_size": 0,
         "private_segment_fixed_size": 0, "max_flat_workgroup_size": 1024,
         "wavefront_size": 64},
    ),
    Variant(
        "add_rmsnorm_group_quant_n5120_bf16_weight",
        "netra_add_rmsnorm_group_quant_n5120_gfx950",
        8,
        (8, 1, 1),
        "23a9b09e3b8b30795757d149ef1ea21b047d7e09a37e28456bdf7199c05959bd",
        {"agpr_count": 0, "vgpr_count": 28, "sgpr_count": 46,
         "kernarg_segment_size": 96, "group_segment_fixed_size": 0,
         "private_segment_fixed_size": 0, "max_flat_workgroup_size": 1024,
         "wavefront_size": 64},
    ),
    Variant(
        "silu_mul_group_quant_n17408_store_bf16",
        "netra_silu_mul_group_quant_n17408_store_bf16_gfx950",
        8,
        (8, 34, 1),
        "f112971ecfc8b2146d60b6a7f17c2166d40287101f8ac15a43c7fa10d672558d",
        {"agpr_count": 0, "vgpr_count": 40, "sgpr_count": 34,
         "kernarg_segment_size": 64, "group_segment_fixed_size": 0,
         "private_segment_fixed_size": 0, "max_flat_workgroup_size": 64,
         "wavefront_size": 64},
    ),
    Variant(
        "silu_mul_group_quant_n17408_prequant_only",
        "netra_silu_mul_group_quant_n17408_prequant_only_gfx950",
        8,
        (8, 34, 1),
        "c439caebddf80669f0f8860a47f1625bf818877835d1f23fd4957a000ac747ce",
        {"agpr_count": 0, "vgpr_count": 39, "sgpr_count": 30,
         "kernarg_segment_size": 64, "group_segment_fixed_size": 0,
         "private_segment_fixed_size": 0, "max_flat_workgroup_size": 64,
         "wavefront_size": 64},
    ),
    Variant(
        "gated_rmsnorm_group_quant_d128_rpb1",
        "netra_gated_rmsnorm_group_quant_d128_rpb1_gfx950",
        384,
        (384, 1, 1),
        "755a3001d0d864e34d026e16ea845e6a09144967e944bf5744ceff8de232659a",
        {"agpr_count": 0, "vgpr_count": 20, "sgpr_count": 46,
         "kernarg_segment_size": 104, "group_segment_fixed_size": 0,
         "private_segment_fixed_size": 0, "max_flat_workgroup_size": 64,
         "wavefront_size": 64},
    ),
    Variant(
        "gated_rmsnorm_group_quant_d128_rpb2",
        "netra_gated_rmsnorm_group_quant_d128_rpb2_gfx950",
        768,
        (384, 1, 1),
        "e3f04a89ff09d83d92bf942d16af9a48b684336cf5f73e2b02216e7758417815",
        {"agpr_count": 0, "vgpr_count": 33, "sgpr_count": 46,
         "kernarg_segment_size": 104, "group_segment_fixed_size": 0,
         "private_segment_fixed_size": 0, "max_flat_workgroup_size": 64,
         "wavefront_size": 64},
    ),
    Variant(
        "gated_rmsnorm_group_quant_d128_rpb4",
        "netra_gated_rmsnorm_group_quant_d128_rpb4_gfx950",
        1536,
        (384, 1, 1),
        "ac98722f3f44a44e9f70e0d42e2aabeac4361fe4e83431ecc0d9f264098c3851",
        {"agpr_count": 0, "vgpr_count": 53, "sgpr_count": 46,
         "kernarg_segment_size": 104, "group_segment_fixed_size": 0,
         "private_segment_fixed_size": 0, "max_flat_workgroup_size": 64,
         "wavefront_size": 64},
    ),
)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _run(argv: list[str], *, cwd: Path, stdout: Path | None = None) -> None:
    if stdout is None:
        subprocess.run(argv, cwd=cwd, check=True)
        return
    with stdout.open("wb") as stream:
        subprocess.run(argv, cwd=cwd, check=True, stdout=stream)


def _metadata_integer(text: str, name: str) -> int:
    match = re.search(rf"\.{re.escape(name)}:\s*([0-9]+)", text)
    if match is None:
        raise RuntimeError(f"metadata field .{name} is absent")
    return int(match.group(1))


def build(
    repo: Path,
    output: Path,
    rocm: Path,
    *,
    build_bridge: bool = True,
) -> dict[str, Any]:
    sys.path.insert(0, str(repo / "compiler"))
    from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
    from netra_compiler.backends.gfx950.codegen import instantiate_fixed_source

    tools = {
        "clang": rocm / "llvm/bin/clang",
        "linker": rocm / "llvm/bin/ld.lld",
        "objcopy": rocm / "llvm/bin/llvm-objcopy",
        "readobj": rocm / "llvm/bin/llvm-readobj",
    }
    if build_bridge:
        tools["hipcc"] = rocm / "bin/hipcc"
    missing = [str(path) for path in tools.values() if not os.access(path, os.X_OK)]
    if missing:
        raise RuntimeError("required ROCm tools are unavailable: " + ", ".join(missing))

    tactics = {
        tactic.name.removeprefix("gfx950."): tactic
        for tactic in load_fixed_tactic_catalog(repo)
    }
    output.mkdir(parents=True, exist_ok=True)
    generated = output / "generated"
    generated.mkdir(exist_ok=True)
    artifacts: list[dict[str, Any]] = []
    for variant in VARIANTS:
        tactic = tactics[variant.tactic]
        constants = {name: values[0] for name, values in tactic.contract_constants}
        constants["NETRA_ROWS"] = variant.rows
        request = {
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
            "launch_grid": variant.grid,
            "symbol": variant.symbol,
        }
        contract = tactic.make_contract(request)
        source_payload, symbols = instantiate_fixed_source(tactic, contract)
        source = generated / f"{variant.tactic}.s"
        source.write_bytes(source_payload)
        obj = output / f"{variant.tactic}.o"
        hsaco = output / f"{variant.tactic}_gfx950.hsaco"
        metadata = output / f"{variant.tactic}.metadata"
        text = output / f"{variant.tactic}.text"
        _run([
            str(tools["clang"]), "-target", "amdgcn-amd-amdhsa",
            "-mcpu=gfx950", "-I", str(repo), "-x", "assembler", "-c",
            str(source), "-o", str(obj),
        ], cwd=repo)
        _run([str(tools["linker"]), "-shared", str(obj), "-o", str(hsaco)], cwd=repo)
        _run([str(tools["readobj"]), "--notes", str(hsaco)], cwd=repo, stdout=metadata)
        _run([str(tools["objcopy"]), "--dump-section", f".text={text}", str(hsaco)], cwd=repo)

        metadata_text = metadata.read_text(encoding="utf-8", errors="replace")
        actual = {
            name: _metadata_integer(metadata_text, name)
            for name in variant.metadata
        }
        if actual != variant.metadata:
            raise RuntimeError(f"{variant.tactic}: metadata mismatch: {actual}")
        text_sha256 = _sha256(text)
        if text_sha256 != variant.text_sha256:
            raise RuntimeError(
                f"{variant.tactic}: .text mismatch: {text_sha256} != {variant.text_sha256}"
            )
        artifacts.append({
            "tactic": tactic.name,
            "tactic_id": tactic.stable_id,
            "contract_id": contract.stable_id,
            "symbol": symbols[0],
            "source_sha256": _sha256(source),
            "hsaco": hsaco.name,
            "hsaco_sha256": _sha256(hsaco),
            "text_sha256": text_sha256,
            "metadata": actual,
            "launch": {"grid": list(variant.grid), "block": list(contract.launch.block),
                       "lds_bytes": contract.launch.lds_bytes,
                       "dynamic_lds_bytes": contract.launch.dynamic_lds_bytes},
        })

    bridge = output / "libnetra_group_quant_assembly_bridge.so"
    if build_bridge:
        _run([
            str(tools["hipcc"]), "-std=c++17", "-O2", "-fPIC", "-shared",
            "-I", str(repo),
            str(repo / "runtime/gfx950/group_quant/verify/group_quant_assembly_bridge.hip"),
            "-o", str(bridge),
        ], cwd=repo)

    report = {
        "format": "netra-group-quant-assembly-build-result-1",
        "target": "gfx950",
        "wave_size": 64,
        "maturity": "verified",
        "artifact_count": len(artifacts),
        "all_text_identical": True,
        "bridge_built": build_bridge,
        "bridge": bridge.name if build_bridge else None,
        "bridge_sha256": _sha256(bridge) if build_bridge else None,
        "artifacts": artifacts,
    }
    (output / "build-result.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--rocm-dir", type=Path,
                        default=Path(os.environ.get("ROCM_DIR", "/opt/rocm")))
    parser.add_argument(
        "--skip-bridge",
        action="store_true",
        help="cross-build assembly only when HIP headers/runtime are unavailable",
    )
    args = parser.parse_args()
    try:
        report = build(
            args.repo_root.resolve(),
            args.output.resolve(),
            args.rocm_dir.resolve(),
            build_bridge=not args.skip_bridge,
        )
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"group-quant assembly build failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
