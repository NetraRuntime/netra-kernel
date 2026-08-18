from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from .errors import ValidationError


_REQUIRED_PATHS = (
    Path("schemas/netra-model.schema.json"),
    Path("schemas/netra-engine.schema.json"),
    Path("manifests/gfx950/profiles"),
    Path("manifests/gfx950/tactics"),
    Path("kernels/gfx950/templates"),
)


@dataclass(frozen=True)
class KernelLibrary:
    """Filesystem-backed Netra kernel catalog.

    The compiler package is relocatable: kernel templates, schemas, profiles,
    and tactic catalogs belong to an explicitly resolved library root rather
    than being inferred from the installed Python package layout.
    """

    root: Path

    def __post_init__(self) -> None:
        root = self.root.expanduser().resolve()
        missing = [path.as_posix() for path in _REQUIRED_PATHS if not (root / path).exists()]
        if missing:
            raise ValidationError(
                f"invalid Netra kernel library root {root}: missing {', '.join(missing)}"
            )
        object.__setattr__(self, "root", root)

    @classmethod
    def discover(
        cls,
        explicit: Path | None = None,
        *,
        anchors: Iterable[Path] = (),
    ) -> "KernelLibrary":
        if explicit is not None:
            return cls(explicit)
        candidates: list[Path] = []
        for anchor in (*anchors, Path.cwd(), Path(__file__)):
            path = anchor.expanduser().resolve()
            if path.is_file():
                path = path.parent
            candidates.extend((path, *path.parents))
        seen: set[Path] = set()
        for candidate in candidates:
            if candidate in seen:
                continue
            seen.add(candidate)
            if all((candidate / required).exists() for required in _REQUIRED_PATHS):
                return cls(candidate)
        raise ValidationError(
            "cannot locate the Netra kernel library; pass library_root or "
            "--library-root pointing at a checkout/artifact containing schemas, "
            "manifests, and kernels/gfx950/templates"
        )

    def schema(self, name: str) -> Path:
        return self.root / "schemas" / name

    def profile_root(self, target: str) -> Path:
        return self.root / "manifests" / target / "profiles"

    def tactic_root(self, target: str) -> Path:
        return self.root / "manifests" / target / "tactics"
