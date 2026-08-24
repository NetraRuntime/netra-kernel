#!/usr/bin/env python3
"""Install the deployment wheel in isolation and exercise its entry points."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
import venv
from pathlib import Path


def _run(argv: list[str], *, cwd: Path, environment: dict[str, str]) -> str:
    result = subprocess.run(
        argv,
        cwd=cwd,
        env=environment,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
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
    if not wheel.is_file():
        parser.error(f"wheel does not exist: {wheel}")

    with tempfile.TemporaryDirectory(prefix="netra-wheel-smoke-") as temporary:
        root = Path(temporary)
        environment = os.environ.copy()
        environment.pop("PYTHONPATH", None)
        environment.pop("NETRA_BUNDLE", None)
        venv.EnvBuilder(with_pip=True, clear=True).create(root / "venv")
        executable = root / "venv/bin/python"
        _run(
            [str(executable), "-m", "pip", "install", "--no-deps", str(wheel)],
            cwd=root,
            environment=environment,
        )
        profiles = _run(
            [str(root / "venv/bin/netra-sglang"), "profiles"],
            cwd=root,
            environment=environment,
        )
        if "qwen36-35b-current-best" not in profiles:
            raise RuntimeError("installed netra-sglang CLI did not list its profile")
        integrations = _run(
            [str(root / "venv/bin/netra-kernel"), "integrations"],
            cwd=root,
            environment=environment,
        )
        if integrations.strip() != "sglang":
            raise RuntimeError("installed netra-kernel CLI did not discover SGLang")
        probe = """
from importlib.metadata import distribution
from pathlib import Path
import netra_kernel.cli
import netra_kernel.kernel_cli
import netra_kernel.sglang.plugin

dist = distribution("netra-kernel")
entry_points = {ep.name: ep for ep in dist.entry_points}
assert entry_points["netra-sglang"].load() is netra_kernel.cli.main
assert entry_points["netra-kernel"].load() is netra_kernel.kernel_cli.main
plugin = entry_points["netra"].load()
assert plugin is netra_kernel.sglang.plugin.register
plugin()
root = Path(netra_kernel.cli.__file__).resolve()
assert "site-packages" in root.parts, root
print(root)
"""
        installed = _run(
            [str(executable), "-I", "-c", probe],
            cwd=root,
            environment=environment,
        ).strip()
        print(f"isolated wheel smoke passed: {wheel.name} ({installed})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
