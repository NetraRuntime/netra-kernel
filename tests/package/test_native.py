from __future__ import annotations

from unittest.mock import patch

from netra_kernel import native


def test_find_library_accepts_dynamic_linker_soname(
    monkeypatch,
) -> None:
    monkeypatch.delenv(native.LIBRARY_ENV, raising=False)
    with (
        patch.object(
            native,
            "package_asset_root",
            side_effect=native.NativeLibraryError("no packaged assets"),
        ),
        patch.object(native, "_repo_candidates", return_value=iter(())),
        patch.object(
            native.ctypes.util,
            "find_library",
            return_value="libnetra_mxfp4_sgl.so.1",
        ),
    ):
        assert native.find_native_library() == "libnetra_mxfp4_sgl.so.1"


def test_load_library_passes_soname_to_dynamic_linker() -> None:
    loaded = object()
    with (
        patch.object(
            native,
            "find_native_library",
            return_value="libnetra_mxfp4_sgl.so.1",
        ),
        patch.object(native.ctypes, "CDLL", return_value=loaded) as cdll,
    ):
        assert native.load_native_library() is loaded
    cdll.assert_called_once_with("libnetra_mxfp4_sgl.so.1")


def test_explicit_soname_has_priority(monkeypatch) -> None:
    monkeypatch.setenv(native.LIBRARY_ENV, "libnetra-custom.so")
    with patch.object(native.ctypes.util, "find_library", return_value=None):
        assert native.native_library_candidates()[0] == "libnetra-custom.so"
