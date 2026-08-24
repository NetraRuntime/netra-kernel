"""Relocatable discovery and loading for Netra's C ABI runtime.

This module deliberately has no torch or SGLang dependency.  Keeping native
discovery below the framework adapter lets tools inspect an installation on a
CPU-only host and keeps the shared library independent of PyTorch's C++ ABI.
"""

from __future__ import annotations

import ctypes
import ctypes.util
import os
from importlib.resources import as_file, files
from pathlib import Path
from typing import Iterator


ABI_VERSION = 1
LIBRARY_ENV = "NETRA_MXFP4_SGL_LIB"
ASSET_ROOT_ENV = "NETRA_HSACO_DIR"
LIBRARY_NAME = "libnetra_mxfp4_sgl.so"


class NativeLibraryError(RuntimeError):
    """Raised when a compatible Netra native runtime cannot be loaded."""


def package_asset_root(target: str = "gfx1151") -> Path:
    """Return the installed target asset directory.

    ``as_file`` is not needed for normal wheels because package data is
    installed as ordinary files.  A clear error is preferable for zip imports:
    HIP module loading requires stable filesystem paths for the process life.
    """

    traversable = files("netra_kernel").joinpath("assets", target)
    path = Path(str(traversable))
    if not path.is_dir():
        raise NativeLibraryError(
            f"Netra assets for {target} are not installed at {path}; install "
            f"the target wheel or build the native artifacts"
        )
    return path.resolve()


def _repo_candidates() -> Iterator[Path]:
    here = Path(__file__).resolve()
    for parent in here.parents:
        if (parent / "runtime" / "gfx1151").is_dir():
            yield parent / "build" / "sglang" / LIBRARY_NAME
            break


def _is_path_reference(value: str) -> bool:
    """Return whether *value* names a filesystem path rather than a soname."""

    return os.sep in value or (os.altsep is not None and os.altsep in value)


def native_library_candidates() -> tuple[str, ...]:
    """Return ordered, de-duplicated native-library candidates."""

    candidates: list[str] = []
    explicit = os.getenv(LIBRARY_ENV)
    if explicit:
        expanded = (
            str(Path(explicit).expanduser())
            if _is_path_reference(explicit)
            else explicit
        )
        candidates.append(expanded)
    try:
        candidates.append(str(package_asset_root() / LIBRARY_NAME))
    except NativeLibraryError:
        pass
    candidates.extend(str(path) for path in _repo_candidates())
    located = ctypes.util.find_library("netra_mxfp4_sgl")
    if located:
        # ``find_library`` normally returns an ELF soname (for example,
        # ``libnetra_mxfp4_sgl.so``), which the dynamic linker can resolve even
        # though it is not an absolute filesystem path.
        candidates.append(located)

    result: list[str] = []
    seen: set[str] = set()
    for candidate in candidates:
        normalized = (
            str(Path(candidate).resolve(strict=False))
            if _is_path_reference(candidate)
            else candidate
        )
        if normalized not in seen:
            seen.add(normalized)
            result.append(normalized)
    return tuple(result)


def find_native_library() -> str:
    """Find a Netra runtime library without loading it."""

    candidates = native_library_candidates()
    for candidate in candidates:
        if not _is_path_reference(candidate) or Path(candidate).is_file():
            return candidate
    rendered = ", ".join(str(path) for path in candidates) or "<none>"
    raise NativeLibraryError(
        f"cannot find {LIBRARY_NAME}; checked {rendered}. Set {LIBRARY_ENV} "
        "or run `netra-sglang build`."
    )


def resolve_asset_root(library_path: str | Path) -> Path:
    explicit = os.getenv(ASSET_ROOT_ENV)
    if explicit:
        return Path(explicit).expanduser().resolve()
    reference = os.fspath(library_path)
    if _is_path_reference(reference):
        return Path(reference).resolve().parent
    # A soname has no meaningful parent directory. Installed wheels still
    # provide a stable asset root; a system-only installation can leave the
    # native runtime's compiled default untouched.
    return package_asset_root()


def load_native_library() -> ctypes.CDLL:
    """Load and configure the gfx1151 library before kernel initialization."""

    library_reference = find_native_library()
    try:
        library = ctypes.CDLL(library_reference)
    except OSError as error:
        raise NativeLibraryError(
            f"failed to load {library_reference}: {error}"
        ) from error

    if hasattr(library, "netra_mxfp4_sgl_abi_version"):
        library.netra_mxfp4_sgl_abi_version.restype = ctypes.c_uint32
        actual = int(library.netra_mxfp4_sgl_abi_version())
        if actual != ABI_VERSION:
            raise NativeLibraryError(
                f"Netra runtime ABI {actual} is incompatible with Python ABI "
                f"{ABI_VERSION}: {library_reference}"
            )

    if hasattr(library, "netra_mxfp4_sgl_set_hsaco_dir"):
        library.netra_mxfp4_sgl_set_hsaco_dir.argtypes = [ctypes.c_char_p]
        library.netra_mxfp4_sgl_set_hsaco_dir.restype = ctypes.c_int
        try:
            root = resolve_asset_root(library_reference)
        except NativeLibraryError:
            # A system runtime selected by soname may carry its own compiled
            # HSACO location. Do not replace it with the process cwd. Users can
            # set NETRA_HSACO_DIR when the system package stores assets elsewhere.
            root = None
        if root is not None:
            status = library.netra_mxfp4_sgl_set_hsaco_dir(os.fsencode(root))
            if status:
                raise NativeLibraryError(
                    f"native runtime rejected HSACO directory {root} with status {status}"
                )
    return library
