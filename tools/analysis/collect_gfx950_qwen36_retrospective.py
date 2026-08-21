#!/usr/bin/env python3
"""Collect immutable evidence for the gfx950 Qwen3.6 retrospective.

This script is intentionally CPU-only.  It inventories git history, refs,
reflogs, tracked evidence, numeric fields in historical JSON, external artifact
references, and the local execution environment.  It never interprets a
number as a new measurement and never writes into either source checkout.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any, Iterable


RELEVANT = re.compile(
    r"gfx950|mi350x|qwen3[._-]?6|qwen36|dflash|gdn|linear.attention|"
    r"fp8|blockscale|preshuff|routed.moe|fmoe|group.quant|argmax",
    re.IGNORECASE,
)
TARGET_RELEVANT = re.compile(r"gfx950|mi350x", re.IGNORECASE)
EXTERNAL_PATH = re.compile(r"/data/netra/[A-Za-z0-9_./:+@=-]+")
SHA256 = re.compile(r"\b[0-9a-f]{64}\b", re.IGNORECASE)


def run(args: list[str], cwd: Path, check: bool = True) -> str:
    proc = subprocess.run(
        args,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if check and proc.returncode:
        raise RuntimeError(f"command failed ({proc.returncode}): {args!r}\n{proc.stdout}")
    return proc.stdout


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_revision(repo: Path) -> dict[str, Any]:
    return {
        "path": str(repo.resolve()),
        "head": run(["git", "rev-parse", "HEAD"], repo).strip(),
        "branch": run(["git", "branch", "--show-current"], repo).strip() or None,
        "origin_main": run(
            ["git", "rev-parse", "refs/remotes/origin/main"], repo
        ).strip(),
        "status_porcelain_v2": run(
            ["git", "status", "--porcelain=v2", "--branch"], repo
        ).splitlines(),
        "remotes": run(["git", "remote", "-v"], repo).splitlines(),
    }


def git_refs(repo: Path, repository: str) -> list[dict[str, str]]:
    output = run(
        [
            "git",
            "for-each-ref",
            "--sort=creatordate",
            "--format=%(creatordate:iso8601-strict)%09%(objectname)%09%(refname)",
            "refs/heads",
            "refs/remotes",
            "refs/tags",
        ],
        repo,
    )
    rows = []
    for line in output.splitlines():
        if not line:
            continue
        date, commit, ref = line.split("\t", 2)
        rows.append(
            {"repository": repository, "date": date, "commit": commit, "ref": ref}
        )
    return rows


def git_reflog(repo: Path, repository: str) -> list[dict[str, str]]:
    output = run(
        [
            "git",
            "reflog",
            "show",
            "--all",
            "--date=iso-strict",
            "--format=%H%x09%gD%x09%gd%x09%gs",
        ],
        repo,
        check=False,
    )
    rows = []
    for line in output.splitlines():
        parts = line.split("\t", 3)
        if len(parts) != 4:
            continue
        commit, selector, short_selector, subject = parts
        if RELEVANT.search(" ".join(parts)):
            rows.append(
                {
                    "repository": repository,
                    "commit": commit,
                    "selector": selector,
                    "short_selector": short_selector,
                    "subject": subject,
                }
            )
    return rows


def infer_operation(text: str) -> str:
    rules = [
        (r"argmax|sampl", "sampling/argmax"),
        (r"lm.?head", "dense/lm_head"),
        (r"router|routing|sort", "moe/routing"),
        (r"shared.?gate", "moe/shared_gate"),
        (r"silu.*quant|gate.?up", "moe/gate_up_activation_quant"),
        (r"moe.*down|down.*moe|route.?reduce", "moe/down_reduction"),
        (r"fmoe|routed.?moe|moe", "moe/pipeline"),
        (r"causal.?conv", "gdn/causal_convolution"),
        (r"state.?replay", "gdn/state_replay"),
        (r"precompute", "gdn/precompute"),
        (r"gdn.*prefill|chunk.?h", "gdn/recurrent_initialization"),
        (r"chunk.?o", "gdn/chunk_output"),
        (r"kkt|recompute", "gdn/kkt_recompute"),
        (r"gdn|linear.?attention", "gdn/verification"),
        (r"gqa|attention|dflash", "attention"),
        (r"rmsnorm|group.?quant|norm.*quant", "normalization_activation_quant"),
        (r"dense|qkvz|gemm|fp8", "dense_projection"),
        (r"compiler|engine|modular|manifest|tactic", "compiler_engine"),
        (r"graph|capture|replay", "graph_integration"),
    ]
    lowered = text.lower()
    for pattern, operation in rules:
        if re.search(pattern, lowered):
            return operation
    return "cross_cutting"


def infer_model(text: str) -> str:
    lowered = text.lower()
    if "27b" in lowered or "hv48" in lowered or "gqa6" in lowered:
        return "Qwen3.6-27B"
    if "35b" in lowered or "hv32" in lowered or "gqa4" in lowered or "gqa8" in lowered:
        return "Qwen3.6-35B"
    return "Qwen3.6 (unspecified)"


def infer_status(text: str) -> str:
    lowered = text.lower()
    if any(word in lowered for word in ("negative", "reject", "revert", "failed")):
        return "rejected"
    if "supersed" in lowered or "replace" in lowered or "remove" in lowered:
        return "superseded"
    if any(word in lowered for word in ("accept", "promotion", "promote", "ship", "current best", "current-best")):
        return "accepted_or_promoted"
    if any(word in lowered for word in ("verified", "validation", "validate", "lock")):
        return "verified"
    if any(word in lowered for word in ("experiment", "prototype", "candidate", "screen")):
        return "experimental"
    return "evidence_only"


def git_commits(repo: Path, repository: str) -> list[dict[str, str]]:
    output = run(
        [
            "git",
            "log",
            "--all",
            "--since=2026-07-29T00:00:00+07:00",
            "--until=2026-08-21T23:59:59+07:00",
            "--date=iso-strict",
            "--format=%H%x1f%ad%x1f%an%x1f%P%x1f%D%x1f%s%x1e",
        ],
        repo,
    )
    rows = []
    seen: set[str] = set()
    for record in output.split("\x1e"):
        record = record.strip("\n")
        if not record:
            continue
        parts = record.split("\x1f")
        if len(parts) != 6:
            continue
        commit, date, author, parents, refs, subject = parts
        if commit in seen:
            continue
        seen.add(commit)
        changed = run(
            ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", commit],
            repo,
            check=False,
        ).splitlines()
        relevant_paths = [path for path in changed if RELEVANT.search(path)]
        target_paths = [path for path in changed if TARGET_RELEVANT.search(path)]
        if not (TARGET_RELEVANT.search(subject) or target_paths):
            continue
        joined = " ".join([subject, *relevant_paths])
        status = infer_status(subject)
        if status == "evidence_only":
            status = infer_status(" ".join(relevant_paths))
        rows.append(
            {
                "date": date,
                "repository": repository,
                "commit": commit,
                "parents": parents,
                "author": author,
                "refs": refs,
                "model": infer_model(joined),
                "operation": infer_operation(joined),
                "status_inferred": status,
                "subject": subject,
                "relevant_paths": ";".join(relevant_paths),
            }
        )
    rows.sort(key=lambda row: (row["date"], row["repository"], row["commit"]))
    return rows


def git_file_changes(
    repo: Path, repository: str, commits: list[dict[str, str]]
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for commit_row in commits:
        if commit_row["repository"] != repository:
            continue
        output = run(
            [
                "git",
                "diff-tree",
                "--root",
                "--no-commit-id",
                "--name-status",
                "-M",
                "-C",
                "-r",
                commit_row["commit"],
            ],
            repo,
            check=False,
        )
        for line in output.splitlines():
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            status = parts[0]
            paths = parts[1:]
            if not any(RELEVANT.search(path) for path in paths):
                continue
            rows.append(
                {
                    "date": commit_row["date"],
                    "repository": repository,
                    "commit": commit_row["commit"],
                    "status": status,
                    "old_path": paths[0] if len(paths) > 1 else "",
                    "path": paths[-1],
                    "subject": commit_row["subject"],
                }
            )
    return rows


def tactic_inventory(kernel: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted((kernel / "manifests/gfx950/tactics").glob("*.json")):
        payload = json.loads(path.read_text())
        for tactic in payload.get("tactics", []):
            semantics = tactic.get("semantics", {})
            workspace = tactic.get("workspace", {})
            rows.append(
                {
                    "catalog": path.relative_to(kernel).as_posix(),
                    "id": tactic.get("id", ""),
                    "family": tactic.get("family", ""),
                    "operation": tactic.get("operation", ""),
                    "maturity": tactic.get("maturity", ""),
                    "acceptance_scope": tactic.get("acceptance_scope", ""),
                    "abi": semantics.get("abi", ""),
                    "dtypes": semantics.get("dtypes", ""),
                    "quantization": semantics.get("quantization", ""),
                    "layouts": semantics.get("layouts", ""),
                    "numerical": semantics.get("numerical", ""),
                    "launch_block": tactic.get("launch_block", ""),
                    "kernarg_size": tactic.get("kernarg_size", ""),
                    "workspace_bytes": workspace.get("bytes", ""),
                    "workspace_alignment": workspace.get("alignment", ""),
                    "graph_capture": tactic.get("graph_capture", ""),
                    "deterministic": tactic.get("deterministic", ""),
                    "fallback": tactic.get("fallback", ""),
                    "template": tactic.get("template", ""),
                    "golden_source": tactic.get("golden_source", ""),
                    "source_revision": tactic.get("source_revision", ""),
                    "source_sha256": tactic.get("source_sha256", ""),
                    "template_sha256": tactic.get("template_sha256", ""),
                    "source_closure_sha256": tactic.get("source_closure_sha256", ""),
                    "locked_hsaco_sha256": ";".join(tactic.get("locked_hsaco_sha256", [])),
                }
            )
    return rows


def model_operation_inventory(kernel: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted((kernel / "manifests/gfx950/models").glob("*.json")):
        payload = json.loads(path.read_text())
        model = payload.get("name", path.stem)
        collections: list[tuple[str, list[dict[str, Any]]]] = []
        for key in (
            "layer_dense_operations",
            "fixed_operation_templates",
            "fallback_operations",
            "dense_operations",
            "golden_operations",
        ):
            value = payload.get(key, [])
            if isinstance(value, list):
                collections.append((key, value))
        graph_operations = payload.get("graph", {}).get("operations", [])
        if graph_operations:
            collections.append(("graph.operations", graph_operations))
        for collection, operations in collections:
            for operation in operations:
                artifact = operation.get("golden_artifact", {})
                attributes = operation.get("attributes", {})
                semantics = attributes.get("semantics", {})
                constraints = operation.get("profile_constraints", {})
                rows.append(
                    {
                        "manifest": path.relative_to(kernel).as_posix(),
                        "model": model,
                        "collection": collection,
                        "name": operation.get("name", ""),
                        "operation": operation.get("operation", "")
                        or attributes.get("operation", "")
                        or artifact.get("operation", ""),
                        "maturity": artifact.get("maturity", "")
                        or operation.get("external_status", ""),
                        "n": operation.get("n", ""),
                        "k": operation.get("k", ""),
                        "rows": json.dumps(operation.get("rows", ""), separators=(",", ":")),
                        "profile_constraints": json.dumps(constraints, sort_keys=True, separators=(",", ":")),
                        "abi": semantics.get("abi", "")
                        or artifact.get("semantics", {}).get("abi", ""),
                        "dtypes": semantics.get("dtypes", "")
                        or artifact.get("semantics", {}).get("dtypes", ""),
                        "quantization": semantics.get("quantization", "")
                        or artifact.get("semantics", {}).get("quantization", ""),
                        "layouts": semantics.get("layouts", "")
                        or artifact.get("semantics", {}).get("layouts", ""),
                        "numerical": semantics.get("numerical", "")
                        or artifact.get("semantics", {}).get("numerical", ""),
                        "fallback": operation.get("fallback", "")
                        or attributes.get("fallback", "")
                        or artifact.get("fallback", ""),
                        "graph_capture": attributes.get("graph_capture", "")
                        if attributes
                        else artifact.get("graph_capture", ""),
                        "source_refs": ";".join(artifact.get("source_refs", [])),
                        "evidence_refs": ";".join(
                            operation.get("evidence_refs", [])
                            or artifact.get("evidence_refs", [])
                        ),
                    }
                )
    return rows


def tracked_files(repo: Path) -> list[Path]:
    return [repo / line for line in run(["git", "ls-files"], repo).splitlines()]


def relevant_evidence(path: Path, repo: Path, repository: str) -> bool:
    rel = path.relative_to(repo).as_posix()
    if repository == "netra-kernel":
        prefixes = (
            "manifests/gfx950/",
            "docs/compiler/gfx950",
            "docs/notes/gfx950",
            "tools/benchmark/",
            "tools/build/build_gfx950",
            "tools/compiler/",
        )
    else:
        prefixes = (
            "docs/mi350x-gfx950/",
            "scripts/rocm/mi350x/",
            "test/registered/unit/test_qwen36",
            "test/registered/unit/spec/test_dflash",
        )
    return rel.startswith(prefixes) and RELEVANT.search(rel) is not None


def markdown_title(text: str) -> str:
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def evidence_rows(repo: Path, repository: str) -> list[dict[str, Any]]:
    rows = []
    for path in tracked_files(repo):
        if not path.is_file() or not relevant_evidence(path, repo, repository):
            continue
        rel = path.relative_to(repo).as_posix()
        text = ""
        title = ""
        if path.suffix.lower() in {".md", ".json", ".csv", ".txt", ".py", ".sh"}:
            text = path.read_text(errors="replace")
            if path.suffix.lower() == ".md":
                title = markdown_title(text)
        date_match = re.search(r"(2026[-_]?(?:07|08)[-_]?\d{2}|20260(?:7|8)\d{2})", rel)
        date = date_match.group(1).replace("_", "-") if date_match else ""
        descriptor = " ".join((rel, title))
        rows.append(
            {
                "repository": repository,
                "path": rel,
                "date_hint": date,
                "title": title,
                "model_inferred": infer_model(descriptor),
                "operation_inferred": infer_operation(descriptor),
                "status_inferred": infer_status(descriptor),
                "bytes": path.stat().st_size,
                "sha256": sha256_file(path),
                "external_path_references": len(EXTERNAL_PATH.findall(text)),
                "sha256_references": len(SHA256.findall(text)),
            }
        )
    return sorted(rows, key=lambda row: (row["repository"], row["path"]))


def flatten_json(value: Any, prefix: str = "$") -> Iterable[tuple[str, Any]]:
    if isinstance(value, dict):
        for key in sorted(value):
            yield from flatten_json(value[key], f"{prefix}.{key}")
    elif isinstance(value, list):
        for index, item in enumerate(value):
            yield from flatten_json(item, f"{prefix}[{index}]")
    else:
        yield prefix, value


def metric_classification(json_path: str) -> str:
    lowered = json_path.lower()
    if re.search(r"\[(?:\d+)\]", lowered) and any(
        word in lowered
        for word in ("sample", "run", "trial", "iteration", "latenc", "duration", "time")
    ):
        return "sample"
    if any(
        word in lowered
        for word in (
            "mean",
            "median",
            "p5",
            "p50",
            "p95",
            "std",
            "stdev",
            "confidence",
            "throughput",
            "tokens_per_second",
            "latency",
            "duration",
            "time_us",
            "time_ms",
            "speedup",
            "error",
            "mismatch",
        )
    ):
        return "aggregate_or_metric"
    return "context"


def historical_json_metrics(
    repo: Path, repository: str
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    files = []
    metrics = []
    for path in tracked_files(repo):
        if path.suffix.lower() != ".json" or not relevant_evidence(path, repo, repository):
            continue
        rel = path.relative_to(repo).as_posix()
        try:
            payload = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as exc:
            files.append(
                {
                    "repository": repository,
                    "path": rel,
                    "sha256": sha256_file(path),
                    "parse_status": f"error: {exc}",
                    "leaf_fields": 0,
                    "numeric_fields": 0,
                }
            )
            continue
        leaves = list(flatten_json(payload))
        numeric = 0
        for json_path, value in leaves:
            if isinstance(value, bool) or not isinstance(value, (int, float)):
                continue
            numeric += 1
            metrics.append(
                {
                    "repository": repository,
                    "evidence_path": rel,
                    "evidence_sha256": sha256_file(path),
                    "json_path": json_path,
                    "value": value,
                    "classification": metric_classification(json_path),
                }
            )
        files.append(
            {
                "repository": repository,
                "path": rel,
                "sha256": sha256_file(path),
                "parse_status": "ok",
                "leaf_fields": len(leaves),
                "numeric_fields": numeric,
            }
        )
    return files, metrics


def external_artifacts(repos: list[tuple[str, Path]]) -> list[dict[str, Any]]:
    references: dict[str, dict[str, Any]] = {}
    for repository, repo in repos:
        for path in tracked_files(repo):
            if not path.is_file() or not relevant_evidence(path, repo, repository):
                continue
            try:
                text = path.read_text(errors="replace")
            except OSError:
                continue
            rel = path.relative_to(repo).as_posix()
            for match in EXTERNAL_PATH.findall(text):
                external = match.rstrip(".,;:)")
                row = references.setdefault(
                    external,
                    {
                        "path": external,
                        "referenced_by": set(),
                        "expected_sha256": set(),
                    },
                )
                row["referenced_by"].add(f"{repository}:{rel}")
                window_start = max(0, text.find(match) - 500)
                window_end = min(len(text), text.find(match) + len(match) + 500)
                row["expected_sha256"].update(SHA256.findall(text[window_start:window_end]))
    rows = []
    for external, row in sorted(references.items()):
        path = Path(external)
        exists = path.exists()
        rows.append(
            {
                "path": external,
                "exists": exists,
                "kind": "directory" if exists and path.is_dir() else "file",
                "actual_sha256": sha256_file(path) if exists and path.is_file() else "",
                "expected_sha256_candidates": ";".join(sorted(row["expected_sha256"])),
                "referenced_by": ";".join(sorted(row["referenced_by"])),
            }
        )
    return rows


def command_probe(command: str) -> dict[str, Any]:
    executable = shutil.which(command)
    if not executable:
        return {"command": command, "available": False, "path": None, "version": None}
    version = subprocess.run(
        [executable, "--version"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=10,
    ).stdout.splitlines()
    return {
        "command": command,
        "available": True,
        "path": executable,
        "version": version[:8],
    }


def environment_manifest() -> dict[str, Any]:
    gpu_nodes = {}
    for node in (Path("/dev/kfd"), Path("/dev/dri")):
        if node.is_dir():
            gpu_nodes[str(node)] = sorted(child.name for child in node.iterdir())
        else:
            gpu_nodes[str(node)] = node.exists()
    return {
        "captured_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "hostname": platform.node(),
        "platform": platform.platform(),
        "uname": list(platform.uname()),
        "python": platform.python_version(),
        "gpu_device_nodes": gpu_nodes,
        "mi350x_capable": Path("/dev/kfd").exists(),
        "tools": [
            command_probe(command)
            for command in (
                "amd-smi",
                "rocm-smi",
                "rocminfo",
                "rocprofv3",
                "rocprof-compute",
                "hipcc",
                "clang",
                "llvm-objdump",
                "python3",
                "docker",
            )
        ],
        "relevant_environment": {
            key: value
            for key, value in sorted(os.environ.items())
            if key.startswith(("ROCM", "HIP", "HSA", "AMD", "SGLANG", "NETRA"))
        },
        "limitations": [
            "No MI350X/gfx950 benchmark can be executed when /dev/kfd is absent.",
            "Historical /data artifacts can only be verified when their filesystem is mounted.",
        ],
    }


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if fieldnames is None:
        fieldnames = list(rows[0]) if rows else []
    with path.open("w", newline="") as stream:
        writer = csv.DictWriter(
            stream,
            fieldnames=fieldnames,
            extrasaction="ignore",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--kernel-root", type=Path, required=True)
    parser.add_argument("--server-root", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    kernel = args.kernel_root.resolve()
    server = args.server_root.resolve()
    output = args.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    repos = [("netra-kernel", kernel), ("netra-server", server)]

    revisions = {name: git_revision(repo) for name, repo in repos}
    refs = [row for name, repo in repos for row in git_refs(repo, name)]
    reflogs = [row for name, repo in repos for row in git_reflog(repo, name)]
    commits = [row for name, repo in repos for row in git_commits(repo, name)]
    commits.sort(key=lambda row: (row["date"], row["repository"], row["commit"]))
    file_changes = [
        row
        for name, repo in repos
        for row in git_file_changes(repo, name, commits)
    ]
    tactics = tactic_inventory(kernel)
    model_operations = model_operation_inventory(kernel)
    evidence = [row for name, repo in repos for row in evidence_rows(repo, name)]
    json_files: list[dict[str, Any]] = []
    metrics: list[dict[str, Any]] = []
    for name, repo in repos:
        files_part, metrics_part = historical_json_metrics(repo, name)
        json_files.extend(files_part)
        metrics.extend(metrics_part)
    external = external_artifacts(repos)
    environment = environment_manifest()

    write_json(output / "git-revisions.json", revisions)
    write_json(output / "environment-manifest.json", environment)
    write_csv(output / "git-refs.csv", refs)
    write_csv(output / "git-reflog.csv", reflogs)
    write_csv(output / "chronological-optimization-ledger.csv", commits)
    write_csv(output / "historical-file-change-ledger.csv", file_changes)
    write_csv(output / "tactic-catalog-inventory.csv", tactics)
    write_csv(output / "manifest-operation-inventory.csv", model_operations)
    write_csv(output / "evidence-inventory.csv", evidence)
    write_csv(output / "historical-json-inventory.csv", json_files)
    write_csv(output / "historical-benchmark-metrics.csv", metrics)
    write_csv(output / "external-artifact-inventory.csv", external)

    summary = {
        "format": "netra-gfx950-qwen36-retrospective-evidence-1",
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "revisions": revisions,
        "counts": {
            "relevant_refs": len(refs),
            "relevant_reflog_entries": len(reflogs),
            "relevant_commits": len(commits),
            "relevant_file_changes": len(file_changes),
            "catalog_tactics": len(tactics),
            "manifest_operations": len(model_operations),
            "tracked_evidence_files": len(evidence),
            "historical_json_files": len(json_files),
            "historical_numeric_fields": len(metrics),
            "historical_sample_fields": sum(
                row["classification"] == "sample" for row in metrics
            ),
            "external_artifact_references": len(external),
            "external_artifacts_available": sum(row["exists"] for row in external),
        },
        "measurement_policy": {
            "new_gpu_measurements": "not_run_no_dev_kfd"
            if not environment["mi350x_capable"]
            else "eligible",
            "historical_numbers": "inventory_only; consult evidence path and checksum",
            "missing_artifacts": "unverified, never reconstructed from prose",
        },
    }
    write_json(output / "evidence-summary.json", summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
