from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from netra_kernel import engine


def test_engine_library_accepts_matching_abi() -> None:
    library = MagicMock()
    library.netra_engine_abi_version.return_value = engine.ENGINE_ABI_VERSION
    with patch.object(engine.ctypes, "CDLL", return_value=library):
        assert engine.load_engine_library("libnetra_engine.so.1") is library


def test_engine_library_rejects_mismatched_abi() -> None:
    library = MagicMock()
    library.netra_engine_abi_version.return_value = 99
    with patch.object(engine.ctypes, "CDLL", return_value=library):
        with pytest.raises(engine.EngineError, match="ABI 99"):
            engine.load_engine_library("libnetra_engine.so.99")


def test_explicit_engine_soname_is_supported(monkeypatch) -> None:
    monkeypatch.setenv(engine.ENGINE_LIBRARY_ENV, "libnetra_engine_custom.so")
    assert engine.find_engine_library() == "libnetra_engine_custom.so"
