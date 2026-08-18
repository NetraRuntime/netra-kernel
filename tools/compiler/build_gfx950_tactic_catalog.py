#!/usr/bin/env python3
"""Build deployment compatibility artifacts from the model-neutral tactic catalog."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _run(argv: list[str], *, cwd: Path, stdout: Path | None = None) -> None:
    if stdout is None:
        subprocess.run(argv, cwd=cwd, check=True)
        return
    with stdout.open("wb") as stream:
        subprocess.run(argv, cwd=cwd, check=True, stdout=stream)


def build(repo: Path, deployment_path: Path, output: Path, rocm: Path) -> dict[str, Any]:
    sys.path.insert(0, str(repo / "compiler"))
    from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
    from netra_compiler.backends.gfx950.codegen import instantiate_fixed_source

    deployment = json.loads(deployment_path.read_text(encoding="utf-8"))
    if deployment.get("format") != "netra-compatibility-build-1":
        raise ValueError("unsupported compatibility-build manifest")
    if deployment.get("target") != "gfx950" or deployment.get("wave_size") != 64:
        raise ValueError("compatibility build requires gfx950/wave64")
    tactics = {
        tactic.name.removeprefix("gfx950."): tactic
        for tactic in load_fixed_tactic_catalog(repo, "gfx950")
    }
    tools = {
        "clang": rocm / "llvm/bin/clang",
        "linker": rocm / "llvm/bin/ld.lld",
        "objdump": rocm / "llvm/bin/llvm-objdump",
        "readobj": rocm / "llvm/bin/llvm-readobj",
        "objcopy": rocm / "llvm/bin/llvm-objcopy",
    }
    missing = [str(path) for path in tools.values() if not os.access(path, os.X_OK)]
    if missing:
        raise RuntimeError("required ROCm tools are unavailable: " + ", ".join(missing))
    output.mkdir(parents=True, exist_ok=True)
    generated = output / "generated"
    generated.mkdir(exist_ok=True)
    results: list[dict[str, Any]] = []
    for artifact in deployment["artifacts"]:
        name = artifact["name"]
        objects: list[Path] = []
        members: list[dict[str, Any]] = []
        for index, member in enumerate(artifact["members"]):
            tactic = tactics.get(member["tactic"])
            if tactic is None:
                raise ValueError(f"unknown tactic {member['tactic']} in {name}")
            definitions = dict(member.get("definitions", {}))
            constants = {
                key: values[0] for key, values in tactic.contract_constants
            }
            constants.update(definitions)
            request = {
                "family": tactic.family,
                "operation": tactic.operation,
                "target": tactic.target,
                "wave_size": tactic.wave_size,
                "semantics": tactic.semantics.to_dict(),
                "constants": constants,
                "launch_grid": (1, 1, 1),
                "symbol": member["symbol"],
            }
            contract = tactic.make_contract(request)
            macro_symbols = member.get("macro_symbols")
            payload, _ = instantiate_fixed_source(
                tactic,
                contract,
                macro_symbols=(tuple(macro_symbols) if macro_symbols else None),
            )
            stem = name if len(artifact["members"]) == 1 else f"{name}.{index}"
            source = generated / f"{stem}.s"
            source.write_bytes(payload)
            obj = output / f"{stem}.o"
            _run([
                str(tools["clang"]), "-target", "amdgcn-amd-amdhsa",
                "-mcpu=gfx950", "-I", str(repo), "-x", "assembler",
                "-c", str(source), "-o", str(obj),
            ], cwd=repo)
            objects.append(obj)
            members.append({
                "tactic": tactic.name,
                "tactic_id": tactic.stable_id,
                "contract_id": contract.stable_id,
                "symbol": contract.symbol,
                "source": source.relative_to(output).as_posix(),
                "source_sha256": _sha256(source),
            })
        hsaco = output / f"{name}.hsaco"
        _run([str(tools["linker"]), "-shared", *map(str, objects), "-o", str(hsaco)], cwd=repo)
        dis = output / f"{name}.dis"
        metadata = output / f"{name}.metadata"
        _run([str(tools["objdump"]), "--disassemble", "--mcpu=gfx950", str(hsaco)], cwd=repo, stdout=dis)
        _run([str(tools["readobj"]), "--notes", str(hsaco)], cwd=repo, stdout=metadata)
        metadata_text = metadata.read_text(encoding="utf-8", errors="replace")
        if "amdgcn-amd-amdhsa--gfx950" not in metadata_text:
            raise RuntimeError(f"{name}: code object is not gfx950")
        if "wavefront_size: 64" not in metadata_text:
            raise RuntimeError(f"{name}: code object is not wave64")
        text_path = output / f"{name}.text"
        _run([str(tools["objcopy"]), "--dump-section", f".text={text_path}", str(hsaco)], cwd=repo)
        text_hash = _sha256(text_path)
        if text_hash != artifact["locked_text_sha256"]:
            raise RuntimeError(
                f"{name}: locked .text mismatch: {text_hash} != "
                f"{artifact['locked_text_sha256']}"
            )
        results.append({
            "name": name,
            "members": members,
            "hsaco_sha256": _sha256(hsaco),
            "prior_locked_hsaco_sha256": artifact["locked_hsaco_sha256"],
            "full_hsaco_identical": _sha256(hsaco) == artifact["locked_hsaco_sha256"],
            "text_sha256": text_hash,
            "text_identical": True,
        })
    report = {
        "format": "netra-compatibility-build-result-1",
        "target": "gfx950",
        "wave_size": 64,
        "deployment_manifest_sha256": _sha256(deployment_path),
        "artifact_count": len(results),
        "all_text_identical": all(item["text_identical"] for item in results),
        "artifacts": results,
    }
    (output / "build-result.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument(
        "--deployment",
        type=Path,
        default=Path("manifests/gfx950/deployments/qwen36-35b-current-best.json"),
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--rocm-dir", type=Path, default=Path(os.environ.get("ROCM_DIR", "/opt/rocm")))
    args = parser.parse_args()
    repo = args.repo_root.resolve()
    deployment = args.deployment
    if not deployment.is_absolute():
        deployment = repo / deployment
    try:
        report = build(repo, deployment, args.output.resolve(), args.rocm_dir.resolve())
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"gfx950 tactic catalog build failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
