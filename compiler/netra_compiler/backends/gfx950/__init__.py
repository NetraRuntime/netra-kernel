"""gfx950 compiler backend."""

from __future__ import annotations

from pathlib import Path
from typing import Any

class Gfx950Backend:
    target = "gfx950"
    wave_size = 64

    def tactics(self) -> tuple[Any, ...]:
        from ...tactics import gfx950_registry

        return gfx950_registry()

    def fixed_tactics(self, library_root: Path) -> tuple[Any, ...]:
        from .catalog import load_fixed_tactic_catalog

        return load_fixed_tactic_catalog(library_root, self.target)

    def profiles(self, library_root: Path, tensor_parallel: int) -> tuple[Any, ...]:
        from ...profiles import load_profile_registry

        return load_profile_registry(library_root, self.target, tensor_parallel)

    def emit(self, plan: Any, output: Path, library_root: Path) -> list[dict[str, Any]]:
        from .codegen import emit_specialized_candidates

        return emit_specialized_candidates(plan, output, library_root)

    def build(self, engine_dir: Path) -> list[dict[str, Any]]:
        from .build import build_sources

        return build_sources(engine_dir)


backend = Gfx950Backend()

__all__ = ["Gfx950Backend", "backend"]
