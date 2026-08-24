"""Build and activate relocatable Netra serving bundles."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
from dataclasses import dataclass
from importlib.resources import files
from pathlib import Path
from typing import Iterable, Mapping


BUNDLE_FORMAT = "netra-sglang-bundle-1"
BUNDLE_ENV = "NETRA_BUNDLE"


class BundleError(RuntimeError):
    """Raised when a serving bundle is incomplete or corrupt."""


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_profile(name: str, _seen: frozenset[str] = frozenset()) -> dict:
    if name in _seen:
        raise BundleError(f"cyclic profile inheritance involving {name!r}")
    resource = files("netra_kernel").joinpath("assets", "profiles", f"{name}.json")
    path = Path(str(resource))
    if not path.is_file():
        available = sorted(
            item.name.removesuffix(".json")
            for item in path.parent.glob("*.json")
        ) if path.parent.is_dir() else []
        raise BundleError(
            f"unknown profile {name!r}; available: {', '.join(available) or '<none>'}"
        )
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("format") != "netra-sglang-profile-1":
        raise BundleError(f"unsupported profile format in {path}")
    parent_name = payload.get("extends")
    if parent_name:
        parent = load_profile(parent_name, _seen | {name})
        merged = dict(parent)
        merged.update({key: value for key, value in payload.items() if key not in {"artifacts", "environment"}})
        artifacts = {item["name"]: dict(item) for item in parent.get("artifacts", [])}
        for item in payload.get("artifacts", []):
            if item.get("remove"):
                artifacts.pop(item["name"], None)
            elif item["name"] in artifacts:
                artifacts[item["name"]].update(item)
            else:
                artifacts[item["name"]] = dict(item)
        merged["artifacts"] = list(artifacts.values())
        merged["environment"] = {
            **parent.get("environment", {}),
            **payload.get("environment", {}),
        }
        payload = merged
    return payload


def available_profiles() -> tuple[str, ...]:
    root = Path(str(files("netra_kernel").joinpath("assets", "profiles")))
    return tuple(sorted(path.stem for path in root.glob("*.json")))


@dataclass(frozen=True)
class LocatedArtifact:
    name: str
    source: Path
    sha256: str


def _candidate_files(roots: Iterable[Path], names: set[str]) -> dict[str, list[Path]]:
    result = {name: [] for name in names}
    for root in roots:
        root = root.expanduser().resolve()
        if root.is_file() and root.name in result:
            result[root.name].append(root)
            continue
        if not root.is_dir():
            continue
        for directory, subdirs, filenames in os.walk(root):
            subdirs[:] = [entry for entry in subdirs if entry not in {".git", ".venv"}]
            for filename in names.intersection(filenames):
                result[filename].append(Path(directory, filename))
    return result


def locate_artifacts(profile: Mapping, roots: Iterable[Path]) -> tuple[LocatedArtifact, ...]:
    specs = profile.get("artifacts", [])
    candidates = _candidate_files(roots, {item["filename"] for item in specs})
    located: list[LocatedArtifact] = []
    errors: list[str] = []
    hash_cache: dict[Path, str] = {}
    for spec in specs:
        filename = spec["filename"]
        expected = spec.get("sha256")
        matches: list[tuple[Path, str]] = []
        for path in candidates[filename]:
            actual = hash_cache.setdefault(path, _sha256(path))
            if expected is None or actual == expected:
                matches.append((path, actual))
        if not matches:
            suffix = f" with sha256 {expected}" if expected else ""
            errors.append(f"missing {filename}{suffix}")
            continue
        matches.sort(key=lambda value: (len(value[0].parts), str(value[0])))
        source, actual = matches[0]
        located.append(LocatedArtifact(spec["name"], source, actual))
    if errors:
        raise BundleError("artifact resolution failed:\n  - " + "\n  - ".join(errors))
    return tuple(located)


def _materialize(source: Path, destination: Path, *, mode: str) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if mode == "copy":
        shutil.copy2(source, destination)
    elif mode == "hardlink":
        try:
            os.link(source, destination)
        except OSError:
            shutil.copy2(source, destination)
    else:
        raise BundleError(f"unsupported materialization mode: {mode}")


def build_bundle(
    profile_name: str,
    roots: Iterable[Path],
    output: Path,
    *,
    mode: str = "hardlink",
    runtime_root: str = "/opt/netra",
) -> Path:
    """Resolve locked artifacts and create one relocatable serving directory."""

    profile = load_profile(profile_name)
    output = output.expanduser().resolve()
    if output.exists() and any(output.iterdir()):
        raise BundleError(f"output directory is not empty: {output}")
    output.mkdir(parents=True, exist_ok=True)
    located = locate_artifacts(profile, roots)
    by_name = {item.name: item for item in located}
    records = []
    for spec in profile["artifacts"]:
        item = by_name[spec["name"]]
        relative = Path("artifacts", spec["name"], spec["filename"])
        destination = output / relative
        _materialize(item.source, destination, mode=mode)
        actual = _sha256(destination)
        if actual != item.sha256:
            raise BundleError(f"copy verification failed for {item.source}")
        records.append(
            {
                "name": item.name,
                "filename": spec["filename"],
                "path": relative.as_posix(),
                "sha256": actual,
                "source": str(item.source),
            }
        )

    env = {}
    for key, value in profile.get("environment", {}).items():
        env[key] = value.format(root=runtime_root)
    manifest = {
        "format": BUNDLE_FORMAT,
        "profile": profile_name,
        "profile_revision": profile.get("revision"),
        "target": profile["target"],
        "wave_size": profile["wave_size"],
        "runtime_root": runtime_root,
        "required_sglang_modules": profile.get("required_sglang_modules", []),
        "sglang_source_snapshot": profile.get("sglang_source_snapshot"),
        "artifacts": records,
        "environment": env,
    }
    manifest_path = output / "bundle.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    (output / "docker.env").write_text(
        "\n".join([f"{BUNDLE_ENV}={runtime_root}", *[f"{k}={v}" for k, v in sorted(env.items())]])
        + "\n"
    )
    shell_env = {key: value.replace(runtime_root, str(output)) for key, value in env.items()}
    (output / "env.sh").write_text(
        "\n".join(
            [f"export {BUNDLE_ENV}={shlex_quote(str(output))}", *[
                f"export {key}={shlex_quote(value)}" for key, value in sorted(shell_env.items())
            ]]
        )
        + "\n"
    )
    return manifest_path


def shlex_quote(value: str) -> str:
    """Small dependency-free POSIX shell quoting helper."""

    return "'" + value.replace("'", "'\"'\"'") + "'"


def load_bundle(root: Path) -> dict:
    root = root.expanduser().resolve()
    manifest_path = root / "bundle.json"
    try:
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise BundleError(f"cannot read bundle manifest {manifest_path}: {error}") from error
    if payload.get("format") != BUNDLE_FORMAT:
        raise BundleError(f"unsupported bundle format in {manifest_path}")
    return payload


def validate_bundle(root: Path) -> dict:
    root = root.expanduser().resolve()
    payload = load_bundle(root)
    errors = []
    for artifact in payload["artifacts"]:
        path = root / artifact["path"]
        if not path.is_file():
            errors.append(f"missing {artifact['path']}")
        elif _sha256(path) != artifact["sha256"]:
            errors.append(f"hash mismatch {artifact['path']}")
    return {
        "ok": not errors,
        "profile": payload["profile"],
        "target": payload["target"],
        "artifact_count": len(payload["artifacts"]),
        "errors": errors,
    }


def activate_bundle(root: Path, *, overwrite: bool = False) -> dict[str, str]:
    """Set the bundle's SGLang environment in the current process."""

    root = root.expanduser().resolve()
    payload = load_bundle(root)
    configured: dict[str, str] = {}
    runtime_root = payload.get("runtime_root", "/opt/netra")
    for key, template in payload["environment"].items():
        value = template.replace(runtime_root, str(root))
        if overwrite or key not in os.environ:
            os.environ[key] = value
            configured[key] = value
    os.environ.setdefault(BUNDLE_ENV, str(root))
    return configured
