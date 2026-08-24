#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "compiler"))
from netra_compiler.cli import main

if __name__ == "__main__": raise SystemExit(main(["validate", "--engine", *sys.argv[1:], "--static"]))
