from pathlib import Path

import pytest

from netra_kernel.bundle import BundleError
from netra_kernel.cli import _doctor
from netra_kernel.sglang.compat import CompatibilityReport
from netra_kernel.source import build_source, source_environment, validate_source


def test_packaged_accepted_source_materializes_and_validates(tmp_path: Path) -> None:
    root = tmp_path / "sglang-source"
    manifest = build_source("qwen36-35b-20260817-best", root)

    assert manifest == root / "netra-source.json"
    assert (root / "LICENSE").is_file()
    assert (root / "python/sglang/srt/plugins/hook_registry.py").is_file()
    assert (
        root / "python/sglang/srt/layers/moe/netra_gfx950_qwen36.py"
    ).is_file()
    assert (root / "scripts/rocm/mi350x/qwen36_best_bf16.csv").is_file()
    assert (root / "scripts/rocm/mi350x/qwen36_best_fmoe.csv").is_file()
    result = validate_source(root)
    assert result["ok"] is True
    assert result["source_commit"] == (
        "c131cc0a1044ddf3a30b2e5096d56000e629993d"
    )
    assert result["file_count"] == 2753
    environment = source_environment(root)
    assert environment["PYTHONPATH"] == str(root / "python")
    assert environment["AITER_CONFIG_FMOE"].endswith("qwen36_best_fmoe.csv")

    cache = root / "python/sglang/__pycache__/__init__.cpython-310.pyc"
    cache.parent.mkdir()
    cache.write_bytes(b"runtime cache")
    assert validate_source(root)["ok"] is True

    (root / "python/sglang/__init__.py").write_text("corrupt\n")
    assert validate_source(root)["ok"] is False


def test_source_refuses_existing_output(tmp_path: Path) -> None:
    output = tmp_path / "keep"
    output.mkdir()
    with pytest.raises(BundleError, match="already exists"):
        build_source("qwen36-35b-20260817-best", output)


def test_doctor_audits_selected_source_tree(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    root = tmp_path / "source"
    build_source("qwen36-35b-20260817-best", root)
    report = CompatibilityReport(
        installed=True,
        version="0.5.16",
        source_root=str(root / "python"),
        plugin_api=True,
        netra_integration=True,
        missing_modules=(),
    )
    monkeypatch.setattr("netra_kernel.cli.probe", lambda _required: report)
    assert _doctor(None)["ok"] is True

    (root / "python/sglang/__init__.py").write_text("corrupt\n")
    result = _doctor(None)
    assert result["ok"] is False
    assert result["source"]["errors"] == ["source tree hash mismatch"]
