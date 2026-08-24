from __future__ import annotations

import json
import hashlib
from pathlib import Path
from unittest.mock import patch

import pytest

from netra_kernel.bundle import BUNDLE_FORMAT
from netra_kernel.sglang.compat import CompatibilityReport
from netra_kernel.sglang.plugin import register


def _bundle(tmp_path: Path) -> Path:
    artifact = tmp_path / "artifact"
    artifact.write_bytes(b"plugin artifact")
    payload = {
        "format": BUNDLE_FORMAT,
        "profile": "test",
        "profile_revision": "test@1",
        "target": "gfx950",
        "runtime_root": "/opt/netra",
        "wave_size": 64,
        "artifacts": [
            {
                "name": "test",
                "filename": artifact.name,
                "kind": "data",
                "path": artifact.name,
                "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
            }
        ],
        "integrations": {
            "sglang": {
                "environment": {"NETRA_PLUGIN_TEST": "/opt/netra/artifact"},
                "required_modules": ["sglang.netra_test"],
            }
        },
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
        with pytest.raises(SystemExit, match="incompatible"):
            register()


def test_plugin_rejects_corrupt_bundle(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    root = _bundle(tmp_path)
    (root / "artifact").write_bytes(b"tampered")
    monkeypatch.setenv("NETRA_BUNDLE", str(root))
    report = CompatibilityReport(True, "1", "/sglang", True, True, ())
    with patch("netra_kernel.sglang.plugin.probe", return_value=report):
        with pytest.raises(SystemExit, match="hash mismatch"):
            register()
