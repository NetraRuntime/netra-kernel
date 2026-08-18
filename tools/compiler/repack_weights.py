#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "compiler"))
from netra_compiler.layouts import RepackStep, repack_fixture


def main() -> int:
    parser = argparse.ArgumentParser(description="Execute validated fixture repacks or emit real-checkpoint recipes")
    parser.add_argument("--input", type=Path, required=True); parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--rows", type=int, required=True); parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--transform", choices=("identity", "transpose_bytes"), required=True)
    args = parser.parse_args()
    step = RepackStep("fixture_source", "fixture_target", args.transform)
    args.output.write_bytes(repack_fixture(args.input.read_bytes(), args.rows, args.columns, step))
    return 0


if __name__ == "__main__": raise SystemExit(main())
