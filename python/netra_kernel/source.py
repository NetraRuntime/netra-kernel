"""Materialize the exact SGLang source tree used by an accepted deployment."""

from __future__ import annotations

import hashlib
import json
import os
import tarfile
import tempfile
from importlib.resources import files
from pathlib import Path, PurePosixPath
from typing import Mapping

from netra_kernel.bundle import BundleError, load_profile


SOURCE_FORMAT = "netra-sglang-source-1"
SOURCE_MANIFEST = "netra-source.json"

_SNAPSHOTS = {
    "sglang-c131cc0-qwen36-gfx950": {
        "archive": "netra-sglang-c131cc0-source.tar.gz",
        "archive_sha256": "4ed92be66adef50c3a5cb1ceb2cd8cd9ee06ce7f132dcc5be4e5c1e205c69128",
        "prefix": "netra-sglang-c131cc0",
        "source_commit": "c131cc0a1044ddf3a30b2e5096d56000e629993d",
        "validated_base_commit": "fdebc938f7f4d16fe6b9f55dcd9a767cf0899ea1",
        "tree_sha256": "e119c1c361898755a80acc1e3f1b8471b26a7a7086a569d42040cab7ca54fe3f",
        "file_count": 2753,
        "license": "Apache-2.0",
    }
}


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _snapshot(profile: Mapping) -> tuple[str, dict]:
    name = profile.get("integrations", {}).get("sglang", {}).get("source_snapshot")
    if not name:
        raise BundleError("profile does not declare an accepted SGLang source snapshot")
    try:
        return name, dict(_SNAPSHOTS[name])
    except KeyError as error:
        raise BundleError(f"unknown SGLang source snapshot {name!r}") from error


def _relative_member(member: tarfile.TarInfo, prefix: str) -> Path | None:
    archive_path = PurePosixPath(member.name)
    parts = archive_path.parts
    if (
        archive_path.is_absolute()
        or ".." in parts
        or not parts
        or parts[0] != prefix
    ):
        raise BundleError(f"unsafe SGLang source member: {member.name}")
    if len(parts) == 1:
        return None
    return Path(*parts[1:])


def _safe_link(root: Path, destination: Path, target: str) -> None:
    if PurePosixPath(target).is_absolute():
        raise BundleError(f"unsafe absolute symlink in SGLang source: {target}")
    resolved = (destination.parent / target).resolve()
    try:
        resolved.relative_to(root.resolve())
    except ValueError as error:
        raise BundleError(f"SGLang source symlink escapes output: {target}") from error
    os.symlink(target, destination)


def _extract(archive_path: Path, destination: Path, *, prefix: str) -> None:
    with tarfile.open(archive_path, "r:gz") as archive:
        for member in archive:
            relative = _relative_member(member, prefix)
            if relative is None:
                continue
            target = destination / relative
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                target.parent.mkdir(parents=True, exist_ok=True)
                source = archive.extractfile(member)
                if source is None:
                    raise BundleError(f"cannot read SGLang source member {member.name}")
                with target.open("xb") as output:
                    for chunk in iter(lambda: source.read(1024 * 1024), b""):
                        output.write(chunk)
                target.chmod(member.mode & 0o777)
            elif member.issym():
                target.parent.mkdir(parents=True, exist_ok=True)
                _safe_link(destination, target, member.linkname)
            else:
                raise BundleError(f"unsupported SGLang source member: {member.name}")


def _tree_digest(root: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    count = 0
    for path in sorted(root.rglob("*"), key=lambda item: item.as_posix()):
        relative_path = path.relative_to(root)
        if (
            path.name == SOURCE_MANIFEST
            or "__pycache__" in relative_path.parts
            or path.suffix in {".pyc", ".pyo"}
        ):
            continue
        relative = relative_path.as_posix().encode()
        if path.is_symlink():
            digest.update(b"L\0" + relative + b"\0" + os.readlink(path).encode() + b"\n")
        elif path.is_dir():
            continue
        elif path.is_file():
            digest.update(b"F\0" + relative + b"\0" + _sha256(path).encode() + b"\n")
        else:
            raise BundleError(f"unsupported file in SGLang source: {path}")
        count += 1
    return digest.hexdigest(), count


def build_source(profile_name: str, output: Path) -> Path:
    """Extract a profile's accepted source snapshot without modifying a checkout."""

    profile = load_profile(profile_name)
    snapshot_name, snapshot = _snapshot(profile)
    archive_path = Path(
        str(
            files("netra_kernel").joinpath(
                "assets", "overlays", snapshot["archive"]
            )
        )
    )
    if not archive_path.is_file() or _sha256(archive_path) != snapshot["archive_sha256"]:
        raise BundleError(f"packaged SGLang source archive is absent or corrupt: {archive_path}")

    output = output.expanduser().resolve()
    if output.exists():
        raise BundleError(f"SGLang source output already exists: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix=".netra-sglang-source-", dir=output.parent
    ) as temporary:
        payload = Path(temporary) / "payload"
        payload.mkdir()
        _extract(archive_path, payload, prefix=snapshot["prefix"])
        if not (payload / "python/sglang/__init__.py").is_file():
            raise BundleError("packaged SGLang source has no importable sglang package")
        tree_sha256, file_count = _tree_digest(payload)
        if (
            tree_sha256 != snapshot["tree_sha256"]
            or file_count != snapshot["file_count"]
        ):
            raise BundleError("packaged SGLang source tree does not match its lock")
        manifest = {
            "format": SOURCE_FORMAT,
            "profile": profile_name,
            "snapshot": snapshot_name,
            "source_commit": snapshot["source_commit"],
            "validated_base_commit": snapshot["validated_base_commit"],
            "archive_sha256": snapshot["archive_sha256"],
            "tree_sha256": tree_sha256,
            "file_count": file_count,
            "python_path": "python",
            "license": snapshot["license"],
        }
        manifest_path = payload / SOURCE_MANIFEST
        manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
        payload.rename(output)
    return output / SOURCE_MANIFEST


def validate_source(root: Path) -> dict:
    root = root.expanduser().resolve()
    manifest_path = root / SOURCE_MANIFEST
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise BundleError(f"cannot read SGLang source manifest {manifest_path}: {error}") from error
    if manifest.get("format") != SOURCE_FORMAT:
        raise BundleError(f"unsupported SGLang source format in {manifest_path}")
    actual, count = _tree_digest(root)
    errors = []
    snapshot = _SNAPSHOTS.get(manifest.get("snapshot"))
    if snapshot is None:
        errors.append("unknown source snapshot")
    if actual != manifest.get("tree_sha256") or (
        snapshot is not None and actual != snapshot["tree_sha256"]
    ):
        errors.append("source tree hash mismatch")
    if count != manifest.get("file_count") or (
        snapshot is not None and count != snapshot["file_count"]
    ):
        errors.append("source tree file count mismatch")
    if snapshot is not None and (
        manifest.get("source_commit") != snapshot["source_commit"]
        or manifest.get("archive_sha256") != snapshot["archive_sha256"]
    ):
        errors.append("source provenance mismatch")
    return {
        "ok": not errors,
        "profile": manifest.get("profile"),
        "snapshot": manifest.get("snapshot"),
        "source_commit": manifest.get("source_commit"),
        "file_count": count,
        "python_path": str(root / manifest.get("python_path", "python")),
        "errors": errors,
    }


def source_environment(root: Path) -> dict[str, str]:
    """Return the environment needed to select a validated source snapshot."""

    root = root.expanduser().resolve()
    result = validate_source(root)
    if not result["ok"]:
        raise BundleError("SGLang source validation failed: " + ", ".join(result["errors"]))
    tuning = root / "scripts/rocm/mi350x"
    return {
        "PYTHONPATH": str(root / "python"),
        "AITER_CONFIG_GEMM_BF16": str(tuning / "qwen36_best_bf16.csv"),
        "AITER_CONFIG_FMOE": str(tuning / "qwen36_best_fmoe.csv"),
    }
