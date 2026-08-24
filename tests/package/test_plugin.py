from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest

from netra_kernel.bundle import BUNDLE_FORMAT
from netra_kernel.sglang.compat import CompatibilityReport
from netra_kernel.sglang.plugin import register


def _bundle(tmp_path: Path) -> Path:
    payload = {
        "format": BUNDLE_FORMAT,
        "profile": "test",
        "target": "gfx950",
        "runtime_root": "/opt/netra",
        "artifacts": [],
        "environment": {"NETRA_PLUGIN_TEST": "/opt/netra/artifact"},
        "required_sglang_modules": ["sglang.netra_test"],
    }
    (tmp_path / "bundle.json").write_text(json.dumps(payload))
    return tmp_path


def test_plugin_activates_bundle(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    root = _bundle(tmp_path)
    monkeypatch.setenv("NETRA_BUNDLE", str(root))
    monkeypatch.setenv("NETRA_PLUGIN_TEST", "/stale/artifact")
    report = CompatibilityReport(True, "1", "/sglang", True, True, ())
    with patch("netra_kernel.sglang.plugin.probe", return_value=report):
        register()
    assert Path(__import__("os").environ["NETRA_PLUGIN_TEST"]) == root / "artifact"


def test_plugin_fails_closed_when_integration_is_missing(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    root = _bundle(tmp_path)
    monkeypatch.setenv("NETRA_BUNDLE", str(root))
    monkeypatch.setenv("NETRA_STRICT_COMPATIBILITY", "1")
    report = CompatibilityReport(
        True, "1", "/sglang", True, False, ("sglang.netra_test",)
    )
    with patch("netra_kernel.sglang.plugin.probe", return_value=report):
        with pytest.raises(RuntimeError, match="incompatible"):
            register()
