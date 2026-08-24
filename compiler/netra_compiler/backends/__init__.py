"""Target backend protocol and registry."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Protocol

from ..errors import ValidationError


class CompilerBackend(Protocol):
    target: str
    wave_size: int

    def tactics(self) -> tuple[Any, ...]: ...
    def fixed_tactics(self, library_root: Path) -> tuple[Any, ...]: ...
    def profiles(self, library_root: Path, tensor_parallel: int) -> tuple[Any, ...]: ...
    def emit(self, plan: Any, output: Path, library_root: Path) -> list[dict[str, Any]]: ...
    def build(self, engine_dir: Path) -> list[dict[str, Any]]: ...


_BACKENDS: dict[str, CompilerBackend] = {}


def register_backend(backend: CompilerBackend) -> None:
    if backend.target in _BACKENDS:
        raise RuntimeError(f"compiler backend already registered: {backend.target}")
    _BACKENDS[backend.target] = backend


def get_backend(target: str) -> CompilerBackend:
    if not _BACKENDS:
        from .gfx950 import backend

        register_backend(backend)
    try:
        return _BACKENDS[target]
    except KeyError as error:
        available = ", ".join(sorted(_BACKENDS)) or "<none>"
        raise ValidationError(
            f"unsupported target {target!r}; available backends: {available}"
        ) from error


def available_backends() -> tuple[str, ...]:
    if not _BACKENDS:
        get_backend("gfx950")
    return tuple(sorted(_BACKENDS))


__all__ = ["CompilerBackend", "available_backends", "get_backend", "register_backend"]
