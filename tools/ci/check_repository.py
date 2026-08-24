#!/usr/bin/env python3
"""Check source-tree invariants that do not require ROCm or a GPU."""

from __future__ import annotations

import json
import re
import stat
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
SCRIPT_DEPENDENCY = re.compile(
    r"(?:scripts/rocm/)?tools/(?:build|compiler)/[A-Za-z0-9_.-]+\.(?:py|sh)"
)
REQUIRED = (
    "README.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "SECURITY.md",
    "SUPPORT.md",
    "GOVERNANCE.md",
    "LICENSE",
    "CMakeLists.txt",
    "include/netra/engine.h",
    "examples/reference_engine/main.c",
    "compiler/pyproject.toml",
    "schemas/netra-engine.schema.json",
    "schemas/netra-bundle.schema.json",
    "schemas/netra-deployment-profile.schema.json",
    "compiler/netra_compiler/library_data/manifests/gfx950/tactics/fixed_assembly.json",
    "tools/compiler/build_gfx950_tactic_catalog.py",
    "tools/compiler/build_gfx950_tactic_catalog.sh",
    "tools/compiler/validate_gfx950_tactic_catalog.py",
)


def tracked_files(pattern: str | None = None) -> list[Path]:
    command = ["git", "ls-files", "-z"]
    if pattern is not None:
        command.append(pattern)
    payload = subprocess.check_output(command, cwd=ROOT)
    return [Path(value.decode()) for value in payload.split(b"\0") if value]


def main() -> int:
    errors: list[str] = []
    files = tracked_files()
    tracked = {relative.as_posix() for relative in files}

    for relative in REQUIRED:
        if relative not in tracked:
            errors.append(f"required project file is not Git-tracked: {relative}")
        elif not (ROOT / relative).is_file():
            errors.append(f"missing required project file: {relative}")

    generated_suffixes = {".hsaco", ".o", ".pyc"}
    for relative in files:
        if relative.suffix in generated_suffixes or "__pycache__" in relative.parts:
            errors.append(f"generated artifact is tracked: {relative}")
        path = ROOT / relative
        if path.is_symlink() and not path.exists():
            errors.append(f"broken tracked symlink: {relative}")

    raw_gfx950 = sorted(
        relative.as_posix()
        for relative in files
        if relative.parts[:2] == ("kernels", "gfx950")
        and relative.suffix in {".s", ".asm"}
    )
    if raw_gfx950:
        errors.append(
            "checked-in generated/legacy gfx950 assembly remains: "
            + ", ".join(raw_gfx950)
        )

    for relative in tracked_files("*.json"):
        if not (ROOT / relative).is_file():
            continue
        try:
            json.loads((ROOT / relative).read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            errors.append(f"invalid JSON {relative}: {exc}")

    for relative in tracked_files("*.md"):
        path = ROOT / relative
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for raw_target in MARKDOWN_LINK.findall(text):
            target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
            if not target or target.startswith(("#", "http://", "https://", "mailto:")):
                continue
            destination = path.parent / target.split("#", 1)[0]
            if not destination.exists():
                errors.append(f"broken local Markdown link in {relative}: {target}")

    for relative in tracked_files("*.sh"):
        path = ROOT / relative
        if not path.is_file():
            continue
        if not path.stat().st_mode & stat.S_IXUSR:
            errors.append(f"shell entry point is not executable: {relative}")
        text = path.read_text(encoding="utf-8")
        for dependency in SCRIPT_DEPENDENCY.findall(text):
            if dependency not in tracked:
                errors.append(f"{relative} references untracked builder {dependency}")
            elif not (ROOT / dependency).is_file():
                errors.append(f"{relative} references missing builder {dependency}")

    if errors:
        for error in errors:
            print(f"repository check: {error}", file=sys.stderr)
        return 1
    print(
        json.dumps(
            {
                "format": "netra-repository-check-1",
                "tracked_files": len(files),
                "checked_in_gfx950_assembly_instances": len(raw_gfx950),
                "status": "passed",
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
