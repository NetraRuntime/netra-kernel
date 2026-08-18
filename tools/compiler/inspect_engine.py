#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} ENGINE_DIR", file=sys.stderr); return 2
    root = Path(sys.argv[1])
    for name in ("engine.json", "contracts.json", "graph_recipe.json", "validation_plan.json"):
        print(f"[{name}]")
        print(json.dumps(json.loads((root / name).read_text()), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__": raise SystemExit(main())
