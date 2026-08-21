#!/usr/bin/env python3
"""Build the fixed gfx950 FP8 block-scale dense verification schedules."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class Variant:
    tactic: str
    symbol: str
    m: int
    n: int
    k: int
    grid_x: int
    machine_text_sha256: str
    metadata: dict[str, int]


_TILE128_METADATA = {
    "agpr_count": 0,
    "vgpr_count": 182,
    "sgpr_count": 63,
    "kernarg_segment_size": 88,
    "group_segment_fixed_size": 98336,
    "private_segment_fixed_size": 0,
    "max_flat_workgroup_size": 512,
    "wavefront_size": 64,
}
_TILE192_METADATA = {
    "agpr_count": 0,
    "vgpr_count": 227,
    "sgpr_count": 64,
    "kernarg_segment_size": 88,
    "group_segment_fixed_size": 114720,
    "private_segment_fixed_size": 0,
    "max_flat_workgroup_size": 512,
    "wavefront_size": 64,
}
_TILE128_TEXT = "4d14c9bdcb8aedc23380aa9455a34209d36e67fe7899144a404ef94de7ff74e2"
_TILE192_TEXT = "55e26f6979ce1b72179c5ea016fb6263b22c1adf214c359046939fdbdbdff3a0"


VARIANTS = (
    Variant(
        "dense_fp8_blockscale_bf16_tile128x256_k128",
        "netra_dense_fp8_blockscale_bf16_m1536_n5120_k6144_gfx950",
        1536, 5120, 6144, 240, _TILE128_TEXT, _TILE128_METADATA,
    ),
    Variant(
        "dense_fp8_blockscale_bf16_tile128x256_k128",
        "netra_dense_fp8_blockscale_bf16_m1536_n5120_k17408_gfx950",
        1536, 5120, 17408, 240, _TILE128_TEXT, _TILE128_METADATA,
    ),
    Variant(
        "dense_fp8_blockscale_bf16_tile192x256_k128",
        "netra_dense_fp8_blockscale_bf16_m1536_n14336_k5120_gfx950",
        1536, 14336, 5120, 448, _TILE192_TEXT, _TILE192_METADATA,
    ),
    Variant(
        "dense_fp8_blockscale_bf16_tile192x256_k128",
        "netra_dense_fp8_blockscale_bf16_m1536_n16384_k5120_gfx950",
        1536, 16384, 5120, 512, _TILE192_TEXT, _TILE192_METADATA,
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


def _function_bytes(path: Path, symbol: str) -> bytes:
    """Read one ELF64 symbol payload without depending on binutils."""
    payload = path.read_bytes()
    header = struct.unpack_from("<16sHHIQQQIHHHHHH", payload, 0)
    ident, section_offset, section_size, section_count = (
        header[0], header[6], header[11], header[12]
    )
    if ident[:6] != b"\x7fELF\x02\x01":
        raise RuntimeError(f"{path} is not a little-endian ELF64 object")
    section_format = "<IIQQQQIIQQ"
    sections = [
        struct.unpack_from(section_format, payload, section_offset + index * section_size)
        for index in range(section_count)
    ]
    for section in sections:
        if section[1] != 2:  # SHT_SYMTAB
            continue
        string_section = sections[section[6]]
        strings = payload[string_section[4]:string_section[4] + string_section[5]]
        entry_size = section[9] or struct.calcsize("<IBBHQQ")
        for offset in range(section[4], section[4] + section[5], entry_size):
            name_offset, _info, _other, index, value, size = struct.unpack_from(
                "<IBBHQQ", payload, offset
            )
            end = strings.find(b"\0", name_offset)
            name = strings[name_offset:end].decode("utf-8", errors="strict")
            if name == symbol:
                target = sections[index]
                return payload[target[4] + value:target[4] + value + size]
    raise RuntimeError(f"symbol {symbol} is absent from {path}")


def build(repo: Path, output: Path, rocm: Path, *, build_bridge: bool = True) -> dict[str, Any]:
    sys.path.insert(0, str(repo / "compiler"))
    from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
    from netra_compiler.backends.gfx950.codegen import instantiate_fixed_source

    tools = {
        "clang": rocm / "llvm/bin/clang",
        "linker": rocm / "llvm/bin/ld.lld",
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
        constants = {
            name: values[0] for name, values in tactic.contract_constants
        }
        constants.update(NETRA_M=variant.m, NETRA_N=variant.n, NETRA_K=variant.k)
        request = {
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
            "launch_grid": (variant.grid_x, 1, 1),
            "symbol": variant.symbol,
        }
        contract = tactic.make_contract(request)
        source_payload, symbols = instantiate_fixed_source(tactic, contract)
        stem = f"dense_fp8_blockscale_bf16_m{variant.m}_n{variant.n}_k{variant.k}"
        source = generated / f"{stem}.s"
        source.write_bytes(source_payload)
        obj = output / f"{stem}.o"
        hsaco = output / f"{stem}_gfx950.hsaco"
        metadata = output / f"{stem}.metadata"
        _run([
            str(tools["clang"]), "-target", "amdgcn-amd-amdhsa", "-mcpu=gfx950",
            "-I", str(repo), "-x", "assembler", "-c", str(source), "-o", str(obj),
        ], cwd=repo)
        machine_text_sha256 = hashlib.sha256(
            _function_bytes(obj, variant.symbol)
        ).hexdigest()
        if machine_text_sha256 != variant.machine_text_sha256:
            raise RuntimeError(
                f"{stem}: machine text mismatch: {machine_text_sha256} != "
                f"{variant.machine_text_sha256}"
            )
        _run([str(tools["linker"]), "-shared", str(obj), "-o", str(hsaco)], cwd=repo)
        _run([str(tools["readobj"]), "--notes", str(hsaco)], cwd=repo, stdout=metadata)
        metadata_text = metadata.read_text(encoding="utf-8", errors="replace")
        actual = {
            name: _metadata_integer(metadata_text, name)
            for name in variant.metadata
        }
        if actual != variant.metadata:
            raise RuntimeError(f"{stem}: metadata mismatch: {actual}")
        artifacts.append({
            "tactic": tactic.name,
            "tactic_id": tactic.stable_id,
            "contract_id": contract.stable_id,
            "shape": {"m": variant.m, "n": variant.n, "k": variant.k},
            "symbol": symbols[0],
            "source_sha256": _sha256(source),
            "hsaco": hsaco.name,
            "hsaco_sha256": _sha256(hsaco),
            "machine_text_sha256": machine_text_sha256,
            "metadata": actual,
            "launch": {
                "grid": [variant.grid_x, 1, 1],
                "block": list(contract.launch.block),
                "lds_bytes": contract.launch.lds_bytes,
                "dynamic_lds_bytes": contract.launch.dynamic_lds_bytes,
            },
        })

    bridge = output / "libnetra_dense_verify_assembly_bridge.so"
    if build_bridge:
        _run([
            str(tools["hipcc"]), "-std=c++17", "-O2", "-fPIC", "-shared",
            "-I", str(repo),
            str(repo / "runtime/gfx950/fp8/dense/blockscale_verify_bridge.hip"),
            "-o", str(bridge),
        ], cwd=repo)
    report = {
        "format": "netra-dense-verify-assembly-build-result-1",
        "target": "gfx950",
        "wave_size": 64,
        "maturity": "verified",
        "artifact_count": len(artifacts),
        "all_machine_text_identical": True,
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
    parser.add_argument("--rocm-dir", type=Path, default=Path(os.environ.get("ROCM_DIR", "/opt/rocm")))
    parser.add_argument("--skip-bridge", action="store_true")
    args = parser.parse_args()
    try:
        report = build(
            args.repo_root.resolve(), args.output.resolve(), args.rocm_dir.resolve(),
            build_bridge=not args.skip_bridge,
        )
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"dense verification assembly build failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
