#!/usr/bin/env python3
"""Extract reproducible static ISA/metadata facts from recovered gfx950 HSACOs."""

from __future__ import annotations

import argparse
import csv
import re
import subprocess
from pathlib import Path


def run(*args: str) -> str:
    return subprocess.run(
        list(args), check=True, text=True, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    ).stdout


def scalar(pattern: str, text: str) -> str:
    match = re.search(pattern, text, re.MULTILINE)
    return match.group(1) if match else ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--verification", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--llvm-objdump", default="llvm-objdump")
    parser.add_argument("--llvm-readelf", default="llvm-readelf")
    args = parser.parse_args()

    with args.inventory.open(newline="") as stream:
        inventory = list(csv.DictReader(stream))
    with args.verification.open(newline="") as stream:
        verification = list(csv.DictReader(stream))
    verified = {row["actual_sha256"]: row for row in verification}

    unique: dict[str, dict[str, str]] = {}
    for row in inventory:
        if row["kind"] == "code_object" and row["sha256"]:
            unique.setdefault(row["sha256"], row)

    rows: list[dict[str, object]] = []
    for digest, item in sorted(unique.items()):
        path = Path(item["repository_root"]) / item["path"]
        headers = run(args.llvm_objdump, "-h", str(path))
        disassembly = run(args.llvm_objdump, "-d", "--no-show-raw-insn", str(path))
        notes = run(args.llvm_readelf, "-n", str(path))
        opcodes = []
        for line in disassembly.splitlines():
            match = re.match(r"^\s+([a-z][a-z0-9_]+)(?:\s|$)", line)
            if match:
                opcodes.append(match.group(1))
        verify = verified.get(digest, {})
        rows.append({
            "sha256": digest,
            "representative_path": item["path"],
            "matching_tactic_ids": verify.get("matching_tactic_ids", ""),
            "current_locked_tactic": verify.get("matches_current_locked_tactic", "false"),
            "symbol": scalar(r"^\s*\.symbol:\s+(\S+?)\.kd$", notes),
            "target": scalar(r"^amdhsa\.target:\s+(\S+)", notes),
            "text_bytes": int(scalar(r"^\s*\d+\s+\.text\s+([0-9a-fA-F]+)", headers) or "0", 16),
            "instruction_count": len(opcodes),
            "vgpr_count": scalar(r"^\s*\.vgpr_count:\s+(\d+)", notes),
            "sgpr_count": scalar(r"^\s*\.sgpr_count:\s+(\d+)", notes),
            "wavefront_size": scalar(r"^\s*\.wavefront_size:\s+(\d+)", notes),
            "max_workgroup_size": scalar(r"^\s*\.max_flat_workgroup_size:\s+(\d+)", notes),
            "fixed_lds_bytes": scalar(r"^\s*\.group_segment_fixed_size:\s+(\d+)", notes),
            "private_segment_bytes": scalar(r"^\s*\.private_segment_fixed_size:\s+(\d+)", notes),
            "vgpr_spills": scalar(r"^\s*\.vgpr_spill_count:\s+(\d+)", notes),
            "sgpr_spills": scalar(r"^\s*\.sgpr_spill_count:\s+(\d+)", notes),
            "global_load_instructions": sum(x.startswith("global_load") for x in opcodes),
            "global_store_instructions": sum(x.startswith("global_store") for x in opcodes),
            "ds_instructions": sum(x.startswith("ds_") for x in opcodes),
            "mfma_instructions": sum("mfma" in x for x in opcodes),
            "dpp_instructions": sum("dpp" in x for x in opcodes),
            "waitcnt_instructions": sum("waitcnt" in x for x in opcodes),
            "barrier_instructions": sum("barrier" in x for x in opcodes),
            "branch_instructions": sum("branch" in x for x in opcodes),
            "exp_instructions": sum(x.startswith("v_exp") for x in opcodes),
            "reciprocal_instructions": sum("rcp" in x for x in opcodes),
            "tooling_note": "static counts only; instruction count is not a performance measurement",
        })

    fields = list(rows[0]) if rows else []
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"analyzed {len(rows)} unique gfx950 code objects")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
