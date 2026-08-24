"""Framework-free ctypes binding for the versioned Netra engine C ABI."""

from __future__ import annotations

import ctypes
import ctypes.util
import os
from enum import IntEnum
from pathlib import Path


ENGINE_ABI_VERSION = 1
ENGINE_LIBRARY_ENV = "NETRA_ENGINE_LIBRARY"


class EngineError(RuntimeError):
    pass


class Status(IntEnum):
    OK = 0
    INVALID_ARGUMENT = 1
    IO = 2
    MANIFEST = 3
    UNSUPPORTED_TARGET = 4
    UNSUPPORTED_PROFILE = 5
    BINDING = 6
    HIP = 7
    BUSY = 8
    FALLBACK_REQUIRED = 9


class EngineOptions(ctypes.Structure):
    _fields_ = [
        ("struct_size", ctypes.c_uint32),
        ("device_id", ctypes.c_int32),
        ("enable_graph_capture", ctypes.c_uint32),
    ]


class ProfileInfo(ctypes.Structure):
    _fields_ = [
        ("struct_size", ctypes.c_uint32),
        ("profile_id", ctypes.c_uint32),
        ("min_m", ctypes.c_uint32),
        ("max_m", ctypes.c_uint32),
        ("min_batch", ctypes.c_uint32),
        ("max_batch", ctypes.c_uint32),
        ("min_sequence", ctypes.c_uint64),
        ("max_sequence", ctypes.c_uint64),
        ("tensor_parallel", ctypes.c_uint32),
        ("workspace_bytes", ctypes.c_uint64),
        ("requires_fallback", ctypes.c_uint32),
    ]


class LaunchShape(ctypes.Structure):
    _fields_ = [
        ("m", ctypes.c_uint32),
        ("batch", ctypes.c_uint32),
        ("sequence", ctypes.c_uint64),
        ("tensor_parallel", ctypes.c_uint32),
    ]


class PointerBinding(ctypes.Structure):
    _fields_ = [
        ("argument_index", ctypes.c_uint32),
        ("reserved", ctypes.c_uint32),
        ("pointer", ctypes.c_void_p),
    ]


def find_engine_library() -> str:
    explicit = os.getenv(ENGINE_LIBRARY_ENV)
    if explicit:
        return str(Path(explicit).expanduser()) if os.sep in explicit else explicit
    located = ctypes.util.find_library("netra_engine")
    if located:
        return located
    raise EngineError(
        "cannot find libnetra_engine; install the Netra runtime SDK or set "
        f"{ENGINE_LIBRARY_ENV}"
    )


def load_engine_library(reference: str | None = None) -> ctypes.CDLL:
    name = reference or find_engine_library()
    try:
        library = ctypes.CDLL(name)
    except OSError as error:
        raise EngineError(f"failed to load {name}: {error}") from error
    library.netra_engine_abi_version.argtypes = []
    library.netra_engine_abi_version.restype = ctypes.c_uint32
    actual = int(library.netra_engine_abi_version())
    if actual != ENGINE_ABI_VERSION:
        raise EngineError(
            f"Netra engine ABI {actual} is incompatible with Python ABI "
            f"{ENGINE_ABI_VERSION}: {name}"
        )
    handle = ctypes.c_void_p
    library.netra_engine_create.argtypes = [
        ctypes.c_char_p, ctypes.POINTER(EngineOptions), ctypes.POINTER(handle)
    ]
    library.netra_engine_create.restype = ctypes.c_int
    library.netra_engine_profile_count.argtypes = [handle]
    library.netra_engine_profile_count.restype = ctypes.c_size_t
    library.netra_engine_query_profile.argtypes = [
        handle, ctypes.c_uint32, ctypes.POINTER(ProfileInfo)
    ]
    library.netra_engine_query_profile.restype = ctypes.c_int
    library.netra_engine_bind.argtypes = [
        handle, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_void_p
    ]
    library.netra_engine_bind.restype = ctypes.c_int
    library.netra_engine_finalize_bindings.argtypes = [handle]
    library.netra_engine_finalize_bindings.restype = ctypes.c_int
    library.netra_engine_prepare_profile.argtypes = [
        handle, ctypes.c_uint32, ctypes.c_void_p
    ]
    library.netra_engine_prepare_profile.restype = ctypes.c_int
    library.netra_engine_launch.argtypes = [
        handle, ctypes.c_uint32, ctypes.POINTER(LaunchShape), ctypes.c_void_p
    ]
    library.netra_engine_launch.restype = ctypes.c_int
    library.netra_engine_launch_operation_bound.argtypes = [
        handle, ctypes.c_uint32, ctypes.c_uint32, ctypes.POINTER(LaunchShape),
        ctypes.POINTER(PointerBinding), ctypes.c_uint32, ctypes.c_void_p,
    ]
    library.netra_engine_launch_operation_bound.restype = ctypes.c_int
    library.netra_engine_last_error.argtypes = [handle]
    library.netra_engine_last_error.restype = ctypes.c_char_p
    library.netra_engine_destroy.argtypes = [handle]
    library.netra_engine_destroy.restype = ctypes.c_int
    return library


class Engine:
    """Own one initialized engine and expose numeric, engine-neutral launches."""

    def __init__(
        self,
        directory: str | os.PathLike[str],
        *,
        device_id: int = 0,
        graph_capture: bool = True,
        library: ctypes.CDLL | None = None,
    ) -> None:
        self._library = library or load_engine_library()
        self._handle = ctypes.c_void_p()
        options = EngineOptions(
            ctypes.sizeof(EngineOptions), device_id, int(graph_capture)
        )
        status = self._library.netra_engine_create(
            os.fsencode(Path(directory).expanduser().resolve()),
            ctypes.byref(options),
            ctypes.byref(self._handle),
        )
        if status != Status.OK:
            self._raise(status, "create")

    def _raise(self, status: int, operation: str) -> None:
        detail = self._library.netra_engine_last_error(self._handle)
        message = detail.decode(errors="replace") if detail else "no native detail"
        try:
            name = Status(status).name
        except ValueError:
            name = f"UNKNOWN_{status}"
        raise EngineError(f"{operation} failed ({name}): {message}")

    @property
    def profile_count(self) -> int:
        return int(self._library.netra_engine_profile_count(self._handle))

    def profile(self, profile_id: int) -> ProfileInfo:
        result = ProfileInfo()
        result.struct_size = ctypes.sizeof(ProfileInfo)
        status = self._library.netra_engine_query_profile(
            self._handle, profile_id, ctypes.byref(result)
        )
        if status != Status.OK:
            self._raise(status, "query_profile")
        return result

    def bind(
        self, profile_id: int, operation_index: int, argument_index: int, pointer: int
    ) -> None:
        status = self._library.netra_engine_bind(
            self._handle, profile_id, operation_index, argument_index,
            ctypes.c_void_p(pointer),
        )
        if status != Status.OK:
            self._raise(status, "bind")

    def finalize_bindings(self) -> None:
        status = self._library.netra_engine_finalize_bindings(self._handle)
        if status != Status.OK:
            self._raise(status, "finalize_bindings")

    def prepare_profile(self, profile_id: int, *, stream: int) -> None:
        status = self._library.netra_engine_prepare_profile(
            self._handle, profile_id, ctypes.c_void_p(stream)
        )
        if status != Status.OK:
            self._raise(status, "prepare_profile")

    def launch(self, profile_id: int, shape: LaunchShape, *, stream: int) -> None:
        status = self._library.netra_engine_launch(
            self._handle, profile_id, ctypes.byref(shape), ctypes.c_void_p(stream)
        )
        if status != Status.OK:
            self._raise(status, "launch")

    def launch_operation(
        self,
        profile_id: int,
        operation_index: int,
        shape: LaunchShape,
        bindings: list[PointerBinding],
        *,
        stream: int,
    ) -> None:
        array_type = PointerBinding * len(bindings)
        array = array_type(*bindings)
        status = self._library.netra_engine_launch_operation_bound(
            self._handle, profile_id, operation_index, ctypes.byref(shape),
            array, len(bindings), ctypes.c_void_p(stream),
        )
        if status != Status.OK:
            self._raise(status, "launch_operation_bound")

    def close(self) -> None:
        if not self._handle:
            return
        status = self._library.netra_engine_destroy(self._handle)
        if status != Status.OK:
            self._raise(status, "destroy")
        self._handle = ctypes.c_void_p()

    def __enter__(self) -> "Engine":
        return self

    def __exit__(self, *_: object) -> None:
        self.close()
