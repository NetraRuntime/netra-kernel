#!/usr/bin/env python3
"""Inventory target-relevant ignored artifacts without modifying their repositories."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import stat
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


RELEVANT = re.compile(
    r"gfx950|mi350x|qwen3[._-]?6|qwen36|dflash|gdn|linear.attention|"
    r"fp8|blockscale|preshuff|routed.moe|fmoe|group.quant|argmax",
    re.IGNORECASE,
)
USEFUL_SUFFIXES = {
    ".s", ".inc", ".hsaco", ".co", ".so", ".json", ".jsonl", ".csv",
    ".log", ".txt", ".md", ".yaml", ".yml", ".db", ".rpd", ".sqlite",
    ".metadata", ".safetensors", ".bin",
}


def git_ignored(root: Path) -> list[str]:
    proc = subprocess.run(
        ["git", "ls-files", "--others", "--ignored", "--exclude-standard", "-z"],
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    return [x.decode(errors="surrogateescape") for x in proc.stdout.split(b"\0") if x]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def classify(path: str) -> str:
    suffix = Path(path).suffix.lower()
    if suffix in {".hsaco", ".co"}:
        return "code_object"
    if suffix in {".s", ".inc"}:
        return "generated_assembly"
    if suffix in {".json", ".jsonl", ".csv", ".log", ".rpd", ".db", ".sqlite"}:
        return "benchmark_or_profile_data"
    if suffix in {".safetensors", ".bin"}:
        return "checkpoint_data"
    if suffix == ".metadata":
        return "download_metadata"
    return "other_relevant_artifact"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repository", action="append", required=True, metavar="LABEL=PATH",
        help="repeatable repository label and path",
    )
    parser.add_argument("--output-csv", type=Path, required=True)
    parser.add_argument("--output-summary", type=Path, required=True)
    parser.add_argument("--max-hash-bytes", type=int, default=64 * 1024 * 1024)
    args = parser.parse_args()

    rows: list[dict[str, object]] = []
    repo_counts: dict[str, dict[str, int]] = {}
    for item in args.repository:
        if "=" not in item:
            parser.error(f"invalid --repository {item!r}; expected LABEL=PATH")
        label, raw_root = item.split("=", 1)
        root = Path(raw_root).resolve()
        ignored = git_ignored(root)
        selected = 0
        for rel in ignored:
            if not RELEVANT.search(rel):
                continue
            path = root / rel
            if "__pycache__" in path.parts or path.suffix == ".pyc":
                continue
            if path.suffix.lower() not in USEFUL_SUFFIXES:
                continue
            selected += 1
            try:
                info = path.lstat()
            except FileNotFoundError:
                rows.append(dict(repository=label, repository_root=str(root), path=rel, kind="missing_during_scan", bytes="", mtime_utc="", sha256="", hash_status="missing"))
                continue
            mode = info.st_mode
            if stat.S_ISLNK(mode):
                status = "symlink_not_followed"
                digest = ""
            elif not stat.S_ISREG(mode):
                status = "not_regular_file"
                digest = ""
            elif info.st_size > args.max_hash_bytes:
                status = f"skipped_over_{args.max_hash_bytes}_bytes"
                digest = ""
            else:
                status = "hashed"
                digest = sha256(path)
            rows.append(dict(
                repository=label,
                repository_root=str(root),
                path=rel,
                kind=classify(rel),
                bytes=info.st_size,
                mtime_utc=datetime.fromtimestamp(info.st_mtime, timezone.utc).isoformat(),
                sha256=digest,
                hash_status=status,
            ))
        repo_counts[label] = {"ignored_total": len(ignored), "target_artifacts_selected": selected}

    rows.sort(key=lambda row: (str(row["repository"]), str(row["path"])))
    args.output_csv.parent.mkdir(parents=True, exist_ok=True)
    fields = ["repository","repository_root","path","kind","bytes","mtime_utc","sha256","hash_status"]
    with args.output_csv.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    status_counts = Counter(str(row["hash_status"]) for row in rows)
    kind_counts = Counter(str(row["kind"]) for row in rows)
    summary = {
        "format": "netra-gfx950-ignored-artifact-inventory-1",
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "read_only": True,
        "max_hash_bytes": args.max_hash_bytes,
        "repositories": repo_counts,
        "selected_artifacts": len(rows),
        "hash_status_counts": dict(sorted(status_counts.items())),
        "kind_counts": dict(sorted(kind_counts.items())),
        "policy": "Ignored target-relevant regular files at or below the size limit are hashed; symlinks are not followed and large checkpoint files are not read in full.",
    }
    args.output_summary.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(json.dumps(summary, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
