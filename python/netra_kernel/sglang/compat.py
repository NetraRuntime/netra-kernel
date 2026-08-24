"""Read-only compatibility probes for an installed SGLang tree."""

from __future__ import annotations

import importlib.util
from importlib.machinery import all_suffixes
from dataclasses import asdict, dataclass
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path


@dataclass(frozen=True)
class CompatibilityReport:
    installed: bool
    version: str | None
    source_root: str | None
    plugin_api: bool
    netra_integration: bool
    missing_modules: tuple[str, ...]

    @property
    def usable(self) -> bool:
        return self.installed and self.plugin_api and self.netra_integration

    def to_dict(self) -> dict:
        result = asdict(self)
        result["usable"] = self.usable
        return result


def _module_exists(package_roots: list[Path], module: str) -> bool:
    """Check a module below ``sglang`` without importing any parent package."""

    prefix = "sglang."
    if not module.startswith(prefix):
        return False
    relative = Path(*module.removeprefix(prefix).split("."))
    for root in package_roots:
        candidate = root / relative
        if candidate.is_dir():
            return True
        if any(Path(f"{candidate}{suffix}").is_file() for suffix in all_suffixes()):
            return True
    return False


def probe(required_modules: tuple[str, ...] = ()) -> CompatibilityReport:
    spec = importlib.util.find_spec("sglang")
    if spec is None:
        return CompatibilityReport(False, None, None, False, False, required_modules)
    try:
        installed_version = version("sglang")
    except PackageNotFoundError:
        installed_version = None
    roots = [Path(root).resolve() for root in spec.submodule_search_locations or ()]
    source_root = str(roots[0].parent) if roots else None
    plugin_api = _module_exists(roots, "sglang.srt.plugins.hook_registry")
    missing = tuple(module for module in required_modules if not _module_exists(roots, module))
    return CompatibilityReport(
        True,
        installed_version,
        source_root,
        plugin_api,
        not missing,
        missing,
    )
