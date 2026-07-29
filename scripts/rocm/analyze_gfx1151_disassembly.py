#!/usr/bin/env python3
"""Count concrete instruction families in gfx1151 llvm-objdump output."""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path

ADDRESS = re.compile(r"// [0-9A-Fa-f]{12,}:")


def analyze(path: Path) -> dict:
    opcodes = Counter()
    for line in path.read_text(errors="replace").splitlines():
        if not ADDRESS.search(line):
            continue
        text = line.split("//", 1)[0].strip()
        if not text:
            continue
        opcode = text.split()[0]
        opcodes[opcode] += 1
    prefix = lambda value: sum(count for op, count in opcodes.items() if op.startswith(value))
    return {
        "target": "gfx1151", "measurement_status": "static_disassembly_count",
        "file": str(path), "instructions": sum(opcodes.values()),
        "s_waitcnt": opcodes["s_waitcnt"], "s_waitcnt_depctr": opcodes["s_waitcnt_depctr"],
        "s_barrier": prefix("s_barrier"), "s_nop": prefix("s_nop"),
        "global_load": prefix("global_load"), "global_store": prefix("global_store"),
        "scratch_load": prefix("scratch_load"),
        "scratch_store": prefix("scratch_store"),
        "scalar_load": prefix("s_load"), "lds_ds": prefix("ds_"),
        "s_delay_alu": prefix("s_delay_alu"),
        "v_perm": prefix("v_perm"), "v_cvt": prefix("v_cvt"),
        "v_exp": prefix("v_exp"), "v_rcp": prefix("v_rcp"),
        "v_dot": prefix("v_dot"), "v_wmma": prefix("v_wmma"), "v_mfma": prefix("v_mfma"),
        "top_opcodes": dict(opcodes.most_common(25)),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    result = {"target": "gfx1151", "measurement_status": "static_disassembly_count",
              "kernels": [analyze(path) for path in args.paths]}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
