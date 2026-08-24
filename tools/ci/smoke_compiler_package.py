#!/usr/bin/env python3
"""Prove the compiler wheel carries its schemas, manifests, and templates."""

from __future__ import annotations

import argparse
import os
import subprocess
import tempfile
import venv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def run(argv: list[str], *, cwd: Path, environment: dict[str, str]) -> str:
    result = subprocess.run(
        argv, cwd=cwd, env=environment, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if result.returncode:
        raise RuntimeError(
            f"{' '.join(argv)} failed\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("wheel", type=Path)
    args = parser.parse_args()
    wheel = args.wheel.resolve()
    with tempfile.TemporaryDirectory(prefix="netra-compiler-wheel-") as value:
        temporary = Path(value)
        environment = os.environ.copy()
        environment.pop("PYTHONPATH", None)
        venv.EnvBuilder(with_pip=True, clear=True).create(temporary / "venv")
        python = temporary / "venv/bin/python"
        command = temporary / "venv/bin/netra-compile"
        run([str(python), "-m", "pip", "install", "--no-deps", str(wheel)],
            cwd=temporary, environment=environment)
        tactics = run([str(command), "list-tactics", "--target", "gfx950"],
                      cwd=temporary, environment=environment)
        if "gfx950.moe_gate_up_decode_m1" not in tactics:
            raise RuntimeError("installed compiler could not load its tactic catalog")
        output = temporary / "engine"
        fixture = ROOT / "tests/compiler/fixtures/llama-moe-gate-up-exact.json"
        run([
            str(command), "compile", "--model", str(fixture), "--target", "gfx950",
            "--profile", "decode_m1", "--output", str(output),
        ], cwd=temporary, environment=environment)
        if not (output / "engine.json").is_file():
            raise RuntimeError("installed compiler did not emit an engine")
    print(f"isolated compiler wheel smoke passed: {wheel.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
