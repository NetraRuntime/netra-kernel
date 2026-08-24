#!/usr/bin/env python3
"""Validate the model-neutral gfx950 tactic library and deployment build recipes."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def _git_blob(repo: Path, revision: str, source: str) -> bytes:
    return subprocess.run(
        ["git", "show", f"{revision}:{source}"],
        cwd=repo,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout


def validate(repo: Path, *, verify_git_goldens: bool = False) -> dict[str, Any]:
    sys.path.insert(0, str(repo / "compiler"))
    from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog

    errors: list[str] = []
    try:
        tactics = load_fixed_tactic_catalog(repo, "gfx950")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        tactics = ()
        errors.append(str(exc))
    by_id = {item.name.removeprefix("gfx950."): item for item in tactics}
    for item in tactics:
        if "qwen" in item.name.lower() or "qwen" in item.family.lower():
            errors.append(f"model name leaked into tactic identity: {item.name}")
        if item.rank < 0:
            errors.append(f"negative measured rank: {item.name}")
        if not item.fallback:
            errors.append(f"missing fallback: {item.name}")
    manifests = sorted((repo / "manifests/gfx950/deployments").glob("*.json"))
    artifact_count = 0
    specialization_count = 0
    artifact_names: set[str] = set()
    for path in manifests:
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("format") != "netra-compatibility-build-1":
            continue
        if data.get("target") != "gfx950" or data.get("wave_size") != 64:
            errors.append(f"{path}: deployment target must be gfx950/wave64")
        evidence = data.get("evidence", {})
        revision = evidence.get("source_revision")
        for artifact in data.get("artifacts", []):
            artifact_symbols: set[str] = set()
            artifact_count += 1
            name = artifact.get("name")
            if not isinstance(name, str) or name in artifact_names:
                errors.append(f"{path}: duplicate or invalid artifact {name!r}")
            artifact_names.add(name)
            for field in ("locked_text_sha256", "locked_hsaco_sha256"):
                value = artifact.get(field)
                if not isinstance(value, str) or len(value) != 64:
                    errors.append(f"{name}: invalid {field}")
            members = artifact.get("members", [])
            if not members:
                errors.append(f"{name}: empty artifact")
            for member in members:
                specialization_count += 1
                tactic = by_id.get(member.get("tactic"))
                if tactic is None:
                    errors.append(f"{name}: unknown tactic {member.get('tactic')!r}")
                    continue
                definitions = member.get("definitions", {})
                declared = dict(tactic.compile_definitions)
                if set(definitions) != set(declared):
                    errors.append(f"{name}: specialization must close every selectable constant")
                for key, value in definitions.items():
                    if value not in declared.get(key, ()):
                        errors.append(f"{name}: invalid {key}={value}")
                symbol = member.get("symbol")
                if not isinstance(symbol, str) or not symbol:
                    errors.append(f"{name}: missing symbol")
                elif symbol in artifact_symbols:
                    errors.append(f"{name}: duplicate linked symbol: {symbol}")
                else:
                    artifact_symbols.add(symbol)
                macro_symbols = member.get("macro_symbols", [symbol])
                if len(macro_symbols) != len(tactic.macro_parameters):
                    errors.append(f"{name}: macro symbol arity differs from tactic")
        if revision and verify_git_goldens:
            catalog = json.loads(
                (repo / "manifests/gfx950/tactics/fixed_assembly.json").read_text()
            )
            for entry in catalog["tactics"]:
                try:
                    payload = _git_blob(repo, entry["source_revision"], entry["golden_source"])
                except subprocess.CalledProcessError:
                    errors.append(f"cannot read pinned golden source for {entry['id']}")
                    continue
                if hashlib.sha256(payload).hexdigest() != entry["source_sha256"]:
                    errors.append(f"pinned golden source differs for {entry['id']}")
    raw_instances = sorted(
        path.relative_to(repo).as_posix()
        for path in (repo / "kernels/gfx950").rglob("*.s")
    )
    if raw_instances:
        errors.append("checked-in assembly instances remain: " + ", ".join(raw_instances))
    return {
        "format": "netra-tactic-library-validation-1",
        "target": "gfx950",
        "tactic_count": len(tactics),
        "deployment_artifact_count": artifact_count,
        "deployment_specialization_count": specialization_count,
        "checked_in_assembly_instances": len(raw_instances),
        "errors": errors,
        "passed": not errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument(
        "--verify-git-goldens",
        action="store_true",
        help="also verify pinned historical sources; requires a Git checkout",
    )
    args = parser.parse_args()
    try:
        result = validate(
            args.repo_root.resolve(), verify_git_goldens=args.verify_git_goldens
        )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"tactic catalog validation failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
