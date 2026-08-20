#!/usr/bin/env python3
"""Build the verified exact GQA6/D256/M=8 attention artifacts for gfx950."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


VARIANTS = (
    (
        "attention_gqa6_fp8kv_m8_qo32_kv32",
        "netra_attention_gqa6_fp8kv_m8_qo32_kv32_gfx950",
        "9be7258190ed58773b11362edac5da90fc8636f6d6ad54014ac4ad3d67254d40",
        {"agpr_count": 156, "vgpr_count": 412, "sgpr_count": 102},
    ),
    (
        "attention_gqa6_fp8kv_m8_qo32_kv64",
        "netra_attention_gqa6_fp8kv_m8_qo32_kv64_gfx950",
        "c07af9e6b92e749d1640d10ff231f0b02ce46c88d53817e7ae0d66ddcfdebbbe",
        {"agpr_count": 153, "vgpr_count": 409, "sgpr_count": 102},
    ),
    (
        "attention_gqa6_fp8kv_m8_qo64_kv64",
        "netra_attention_gqa6_fp8kv_m8_qo64_kv64_gfx950",
        "0829ddf232082b05dd2aaf6b74cb39af45b32428520d628faa5ca12c62e28200",
        {"agpr_count": 178, "vgpr_count": 434, "sgpr_count": 102},
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


def build(repo: Path, output: Path, rocm: Path) -> dict[str, Any]:
    sys.path.insert(0, str(repo / "compiler"))
    from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
    from netra_compiler.backends.gfx950.codegen import instantiate_fixed_source

    tools = {
        "clang": rocm / "llvm/bin/clang",
        "linker": rocm / "llvm/bin/ld.lld",
        "objcopy": rocm / "llvm/bin/llvm-objcopy",
        "readobj": rocm / "llvm/bin/llvm-readobj",
        "hipcc": rocm / "bin/hipcc",
    }
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
    for tactic_id, symbol, locked_text_sha256, expected_registers in VARIANTS:
        tactic = tactics[tactic_id]
        constants = {name: values[0] for name, values in tactic.contract_constants}
        request = {
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
            "launch_grid": (1, 4, 3),
            "symbol": symbol,
        }
        contract = tactic.make_contract(request)
        source_payload, exported_symbols = instantiate_fixed_source(tactic, contract)
        source = generated / f"{tactic_id}.s"
        source.write_bytes(source_payload)
        obj = output / f"{tactic_id}.o"
        hsaco = output / f"{tactic_id}_gfx950.hsaco"
        metadata = output / f"{tactic_id}.metadata"
        text = output / f"{tactic_id}.text"
        _run(
            [
                str(tools["clang"]),
                "-target",
                "amdgcn-amd-amdhsa",
                "-mcpu=gfx950",
                "-I",
                str(repo),
                "-x",
                "assembler",
                "-c",
                str(source),
                "-o",
                str(obj),
            ],
            cwd=repo,
        )
        _run([str(tools["linker"]), "-shared", str(obj), "-o", str(hsaco)], cwd=repo)
        _run([str(tools["readobj"]), "--notes", str(hsaco)], cwd=repo, stdout=metadata)
        _run(
            [str(tools["objcopy"]), "--dump-section", f".text={text}", str(hsaco)],
            cwd=repo,
        )
        metadata_text = metadata.read_text(encoding="utf-8", errors="replace")
        required = {
            "kernarg_segment_size": 96,
            "group_segment_fixed_size": 32768,
            "private_segment_fixed_size": 0,
            "max_flat_workgroup_size": 64,
            "wavefront_size": 64,
            **expected_registers,
        }
        actual = {name: _metadata_integer(metadata_text, name) for name in required}
        if actual != required:
            raise RuntimeError(f"{tactic_id}: metadata mismatch: {actual} != {required}")
        text_sha256 = _sha256(text)
        if text_sha256 != locked_text_sha256:
            raise RuntimeError(
                f"{tactic_id}: .text mismatch: {text_sha256} != {locked_text_sha256}"
            )
        artifacts.append(
            {
                "tactic": tactic.name,
                "tactic_id": tactic.stable_id,
                "contract_id": contract.stable_id,
                "symbol": exported_symbols[0],
                "source_sha256": _sha256(source),
                "hsaco": hsaco.name,
                "hsaco_sha256": _sha256(hsaco),
                "text_sha256": text_sha256,
                "metadata": actual,
                "launch": {
                    "grid_per_batch": [1, 4, 3],
                    "block": list(contract.launch.block),
                    "fixed_lds_bytes": contract.launch.lds_bytes,
                    "dynamic_lds_bytes": contract.launch.dynamic_lds_bytes,
                },
            }
        )

    bridge = output / "libattention_gqa6_fp8kv_m8_bridge.so"
    _run(
        [
            str(tools["hipcc"]),
            "-std=c++17",
            "-O2",
            "-fPIC",
            "-shared",
            "-I",
            str(repo),
            str(
                repo
                / "runtime/gfx950/attention/verify/attention_gqa6_fp8kv_m8_bridge.hip"
            ),
            "-o",
            str(bridge),
        ],
        cwd=repo,
    )
    report = {
        "format": "netra-gqa6-fp8kv-m8-build-result-1",
        "target": "gfx950",
        "wave_size": 64,
        "maturity": "verified",
        "artifact_count": len(artifacts),
        "all_text_identical": True,
        "bridge": bridge.name,
        "bridge_sha256": _sha256(bridge),
        "artifacts": artifacts,
    }
    (output / "build-result.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root", type=Path, default=Path(__file__).resolve().parents[2]
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--rocm-dir", type=Path, default=Path(os.environ.get("ROCM_DIR", "/opt/rocm"))
    )
    args = parser.parse_args()
    try:
        report = build(
            args.repo_root.resolve(), args.output.resolve(), args.rocm_dir.resolve()
        )
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"GQA6 FP8-KV M=8 build failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
