from pathlib import Path

from netra_kernel.sglang.compat import _module_exists


def test_module_discovery_does_not_import_parent_packages(tmp_path: Path) -> None:
    package = tmp_path / "sglang"
    module = package / "srt/layers/moe/netra_adapter.py"
    module.parent.mkdir(parents=True)
    module.write_text("raise RuntimeError('must never be imported')\n")
    (package / "srt/plugins").mkdir(parents=True)
    (package / "srt/plugins/hook_registry.py").write_text(
        "raise RuntimeError('must never be imported')\n"
    )

    assert _module_exists([package], "sglang.srt.layers.moe.netra_adapter")
    assert _module_exists([package], "sglang.srt.plugins.hook_registry")
    assert not _module_exists([package], "sglang.srt.layers.moe.absent")
    assert not _module_exists([package], "outside_sglang.module")
