"""Source-tree import shim for ``python -m netra_compiler.cli``.

Installed packages use ``compiler/pyproject.toml`` directly.
"""

from pathlib import Path

__path__.append(str(Path(__file__).resolve().parents[1] / "compiler" / "netra_compiler"))

from .contracts import KernelContract
from .engine import compile_engine

__all__ = ["KernelContract", "compile_engine"]
__version__ = "0.2.0"
