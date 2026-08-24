"""Build and activate relocatable Netra serving bundles."""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
from dataclasses import dataclass
from importlib.resources import files
from pathlib import Path, PurePosixPath
from typing import Iterable, Mapping


PROFILE_FORMAT = "netra-deployment-profile-1"
BUNDLE_FORMAT = "netra-bundle-1"
LEGACY_PROFILE_FORMAT = "netra-sglang-profile-1"
LEGACY_BUNDLE_FORMAT = "netra-sglang-bundle-1"
BUNDLE_ENV = "NETRA_BUNDLE"
_SHA256 = re.compile(r"^[0-9a-f]{64}$")


class BundleError(RuntimeError):
    """Raised when a serving bundle is incomplete or corrupt."""


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _legacy_integration(payload: Mapping) -> dict:
    """Normalize the original SGLang-only profile fields."""

    integration = {
        "required_modules": list(payload.get("required_sglang_modules", ())),
        "environment": dict(payload.get("environment", {})),
    }
    snapshot = payload.get("sglang_source_snapshot")
    if snapshot:
        integration["source_snapshot"] = snapshot
    return integration


def _normalize_profile(payload: dict) -> dict:
    format_name = payload.get("format")
    if format_name not in {PROFILE_FORMAT, LEGACY_PROFILE_FORMAT}:
        raise BundleError(f"unsupported deployment profile format {format_name!r}")
    normalized = dict(payload)
    raw_integrations = payload.get("integrations", {})
    if not isinstance(raw_integrations, Mapping):
        raise BundleError("profile integrations must be an object")
    integrations = {
        name: dict(value)
        for name, value in raw_integrations.items()
        if isinstance(value, Mapping)
    }
    if len(integrations) != len(raw_integrations):
        raise BundleError("profile integration entries must be objects")
    if format_name == LEGACY_PROFILE_FORMAT or any(
        key in payload
        for key in ("required_sglang_modules", "sglang_source_snapshot", "environment")
    ):
        integrations.setdefault("sglang", {}).update(_legacy_integration(payload))
    normalized["format"] = PROFILE_FORMAT
    normalized["integrations"] = integrations
    for key in ("required_sglang_modules", "sglang_source_snapshot", "environment"):
        normalized.pop(key, None)
    return normalized


def _merge_integrations(parent: Mapping, child: Mapping) -> dict:
    result = {name: dict(value) for name, value in parent.items()}
    for name, value in child.items():
        current = result.setdefault(name, {})
        current.update({key: item for key, item in value.items() if key != "environment"})
        current["environment"] = {
            **current.get("environment", {}),
            **value.get("environment", {}),
        }
    return result


def _validate_profile(profile: Mapping, *, selectable: bool) -> None:
    if not isinstance(profile.get("target"), str) or not profile["target"]:
        raise BundleError("deployment profile requires a target")
    if not isinstance(profile.get("wave_size"), int) or profile["wave_size"] <= 0:
        raise BundleError("deployment profile requires a positive wave_size")
    artifacts = profile.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        raise BundleError("deployment profile requires artifacts")
    names: set[str] = set()
    for artifact in artifacts:
        if not isinstance(artifact, Mapping):
            raise BundleError("deployment profile artifacts must be objects")
        name = artifact.get("name")
        filename = artifact.get("filename")
        if not isinstance(name, str) or not name or name in names:
            raise BundleError(f"invalid or duplicate artifact name {name!r}")
        if (
            not isinstance(filename, str)
            or not filename
            or PurePosixPath(filename).name != filename
        ):
            raise BundleError(f"invalid artifact filename {filename!r}")
        names.add(name)
        digest = artifact.get("sha256")
        if selectable and (not isinstance(digest, str) or not _SHA256.fullmatch(digest)):
            raise BundleError(
                f"selectable profile artifact {name!r} requires an exact sha256"
            )
    if selectable and profile.get("abstract"):
        raise BundleError("abstract deployment profiles cannot be selected")
    if selectable and profile.get("accepted") is not True:
        raise BundleError("only explicitly accepted deployment profiles are selectable")
    integrations = profile.get("integrations", {})
    if not isinstance(integrations, Mapping):
        raise BundleError("profile integrations must be an object")
    for name, integration in integrations.items():
        if not isinstance(name, str) or not isinstance(integration, Mapping):
            raise BundleError("profile integration entries must be named objects")
        environment = integration.get("environment", {})
        if not isinstance(environment, Mapping) or any(
            not isinstance(key, str) or not isinstance(value, str)
            for key, value in environment.items()
        ):
            raise BundleError(f"integration {name!r} environment must contain strings")


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
    payload = _normalize_profile(json.loads(path.read_text(encoding="utf-8")))
    parent_name = payload.get("extends")
    if parent_name:
        parent = load_profile(parent_name, _seen | {name})
        merged = dict(parent)
        merged.update(
            {
                key: value
                for key, value in payload.items()
                if key not in {"artifacts", "integrations"}
            }
        )
        artifacts = {item["name"]: dict(item) for item in parent.get("artifacts", [])}
        for item in payload.get("artifacts", []):
            if item.get("remove"):
                artifacts.pop(item["name"], None)
            elif item["name"] in artifacts:
                artifacts[item["name"]].update(item)
            else:
                artifacts[item["name"]] = dict(item)
        merged["artifacts"] = list(artifacts.values())
        merged["integrations"] = _merge_integrations(
            parent.get("integrations", {}), payload.get("integrations", {})
        )
        payload = merged
    _validate_profile(payload, selectable=False)
    return payload


def available_profiles() -> tuple[str, ...]:
    root = Path(str(files("netra_kernel").joinpath("assets", "profiles")))
    result = []
    for path in sorted(root.glob("*.json")):
        try:
            profile = load_profile(path.stem)
        except BundleError:
            continue
        if profile.get("accepted") is True and not profile.get("abstract"):
            result.append(path.stem)
    return tuple(result)


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
    _validate_profile(profile, selectable=True)
    specs = profile.get("artifacts", [])
    candidates = _candidate_files(roots, {item["filename"] for item in specs})
    located: list[LocatedArtifact] = []
    errors: list[str] = []
    hash_cache: dict[Path, str] = {}
    for spec in specs:
        filename = spec["filename"]
        expected = spec["sha256"]
        matches: list[tuple[Path, str]] = []
        for path in candidates[filename]:
            actual = hash_cache.setdefault(path, _sha256(path))
            if actual == expected:
                matches.append((path, actual))
        if not matches:
            errors.append(f"missing {filename} with sha256 {expected}")
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
    _validate_profile(profile, selectable=True)
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
                "kind": spec.get(
                    "kind",
                    "runtime_library" if spec["filename"].endswith(".so") else "code_object",
                ),
                "path": relative.as_posix(),
                "sha256": actual,
                "source": str(item.source),
            }
        )

    integrations = {}
    for name, integration in profile.get("integrations", {}).items():
        rendered = dict(integration)
        rendered["environment"] = {
            key: value.format(root=runtime_root)
            for key, value in integration.get("environment", {}).items()
        }
        integrations[name] = rendered
    manifest = {
        "format": BUNDLE_FORMAT,
        "profile": profile_name,
        "profile_revision": profile.get("revision"),
        "target": profile["target"],
        "wave_size": profile["wave_size"],
        "runtime_root": runtime_root,
        "artifacts": records,
        "integrations": integrations,
    }
    manifest_path = output / "bundle.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    # Generic bundles do not guess an inference engine. Integration CLIs emit
    # their own environment from the namespaced manifest section.
    return manifest_path


def shlex_quote(value: str) -> str:
    """Small dependency-free POSIX shell quoting helper."""

    return "'" + value.replace("'", "'\"'\"'") + "'"


def _normalize_bundle(payload: dict) -> dict:
    format_name = payload.get("format")
    if format_name == BUNDLE_FORMAT:
        return payload
    if format_name != LEGACY_BUNDLE_FORMAT:
        raise BundleError(f"unsupported bundle format {format_name!r}")
    normalized = dict(payload)
    normalized["format"] = BUNDLE_FORMAT
    normalized["artifacts"] = []
    for artifact in payload.get("artifacts", ()):
        record = dict(artifact)
        filename = record.get("filename", "")
        record.setdefault(
            "kind",
            "runtime_library" if filename.endswith(".so") else "code_object",
        )
        normalized["artifacts"].append(record)
    normalized["integrations"] = {
        "sglang": {
            "required_modules": list(payload.get("required_sglang_modules", ())),
            "source_snapshot": payload.get("sglang_source_snapshot"),
            "environment": dict(payload.get("environment", {})),
        }
    }
    for key in ("required_sglang_modules", "sglang_source_snapshot", "environment"):
        normalized.pop(key, None)
    return normalized


def load_bundle(root: Path) -> dict:
    root = root.expanduser().resolve()
    manifest_path = root / "bundle.json"
    try:
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise BundleError(f"cannot read bundle manifest {manifest_path}: {error}") from error
    return _normalize_bundle(payload)


def _artifact_path(root: Path, value: object) -> Path:
    if not isinstance(value, str) or not value:
        raise BundleError("bundle artifact path must be a nonempty string")
    relative = PurePosixPath(value)
    if relative.is_absolute() or ".." in relative.parts:
        raise BundleError(f"bundle artifact path escapes its root: {value}")
    resolved = (root / Path(*relative.parts)).resolve()
    try:
        resolved.relative_to(root)
    except ValueError as error:
        raise BundleError(f"bundle artifact path escapes its root: {value}") from error
    return resolved


def validate_bundle(root: Path) -> dict:
    root = root.expanduser().resolve()
    payload = load_bundle(root)
    errors = []
    for key in ("profile", "profile_revision", "target", "runtime_root"):
        if not isinstance(payload.get(key), str) or not payload[key]:
            errors.append(f"bundle {key} must be a nonempty string")
    if not isinstance(payload.get("wave_size"), int) or payload["wave_size"] <= 0:
        errors.append("bundle wave_size must be a positive integer")
    artifacts = payload.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        errors.append("bundle requires a nonempty artifact list")
        artifacts = []
    names: set[str] = set()
    paths: set[str] = set()
    for artifact in artifacts:
        if not isinstance(artifact, Mapping):
            errors.append("bundle artifact entries must be objects")
            continue
        name = artifact.get("name")
        if not isinstance(name, str) or not name or name in names:
            errors.append(f"invalid or duplicate bundle artifact name {name!r}")
        else:
            names.add(name)
        value = artifact.get("path")
        if isinstance(value, str) and value in paths:
            errors.append(f"duplicate bundle artifact path {value!r}")
        elif isinstance(value, str):
            paths.add(value)
        if artifact.get("kind") not in {"code_object", "runtime_library", "data"}:
            errors.append(f"invalid artifact kind for {name or '<unnamed>'}")
        expected = artifact.get("sha256")
        if not isinstance(expected, str) or not _SHA256.fullmatch(expected):
            errors.append(f"invalid sha256 for {artifact.get('name', '<unnamed>')}")
            continue
        try:
            path = _artifact_path(root, artifact.get("path"))
        except BundleError as error:
            errors.append(str(error))
            continue
        if not path.is_file():
            errors.append(f"missing {artifact.get('path')}")
        elif _sha256(path) != expected:
            errors.append(f"hash mismatch {artifact.get('path')}")
    integrations = payload.get("integrations")
    if not isinstance(integrations, Mapping):
        errors.append("bundle integrations must be an object")
    else:
        for name, integration in integrations.items():
            if not isinstance(name, str) or not isinstance(integration, Mapping):
                errors.append("bundle integration entries must be named objects")
                continue
            environment = integration.get("environment", {})
            if not isinstance(environment, Mapping) or any(
                not isinstance(key, str) or not isinstance(value, str)
                for key, value in environment.items()
            ):
                errors.append(f"integration {name!r} environment must contain strings")
    return {
        "ok": not errors,
        "profile": payload.get("profile"),
        "target": payload.get("target"),
        "artifact_count": len(artifacts),
        "errors": errors,
    }


def integration_configuration(root: Path, name: str) -> dict:
    payload = load_bundle(root)
    integration = payload.get("integrations", {}).get(name)
    if not isinstance(integration, Mapping):
        raise BundleError(f"bundle has no {name!r} integration")
    return dict(integration)


def integration_environment(root: Path, name: str) -> dict[str, str]:
    root = root.expanduser().resolve()
    result = validate_bundle(root)
    if not result["ok"]:
        raise BundleError("bundle validation failed: " + ", ".join(result["errors"]))
    payload = load_bundle(root)
    integration = integration_configuration(root, name)
    runtime_root = payload.get("runtime_root", "/opt/netra")
    return {
        key: value.replace(runtime_root, str(root))
        for key, value in integration.get("environment", {}).items()
    }


def activate_bundle(
    root: Path, *, integration: str | None = None, overwrite: bool = False
) -> dict[str, str]:
    """Validate and activate one inference-engine integration."""

    root = root.expanduser().resolve()
    result = validate_bundle(root)
    if not result["ok"]:
        raise BundleError("bundle validation failed: " + ", ".join(result["errors"]))
    configured: dict[str, str] = {}
    environment: dict[str, str] = {}
    if integration:
        payload = load_bundle(root)
        configuration = integration_configuration(root, integration)
        runtime_root = payload.get("runtime_root", "/opt/netra")
        environment = {
            key: value.replace(runtime_root, str(root))
            for key, value in configuration.get("environment", {}).items()
        }
    for key, value in environment.items():
        if overwrite or key not in os.environ:
            os.environ[key] = value
            configured[key] = value
    os.environ.setdefault(BUNDLE_ENV, str(root))
    return configured
