import tarfile
import builtins
import runpy
from pathlib import Path
from unittest.mock import patch

import pytest

from netra_kernel.sglang.integration import (
    GFX1151_BASE_COMMIT,
    GFX1151_PATCHES,
    _write_adapter_shim,
)


def test_gfx1151_overlay_is_complete() -> None:
    archive = (
        Path(__file__).resolve().parents[2]
        / "python/netra_kernel/assets/overlays/gfx1151-patches.tar.gz"
    )
    assert GFX1151_BASE_COMMIT == "1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4"
    assert len(GFX1151_PATCHES) == 15
    with tarfile.open(archive, "r:gz") as stream:
        assert set(stream.getnames()) == set(GFX1151_PATCHES)


def test_generated_shim_explains_required_wheel(tmp_path: Path) -> None:
    quantization = tmp_path / "python/sglang/srt/layers/quantization"
    quantization.mkdir(parents=True)
    _write_adapter_shim(tmp_path)
    shim = quantization / "netra_gfx1151.py"
    real_import = builtins.__import__

    def without_netra(name, *args, **kwargs):
        if name == "netra_kernel" or name.startswith("netra_kernel."):
            raise ModuleNotFoundError("No module named 'netra_kernel'", name="netra_kernel")
        return real_import(name, *args, **kwargs)

    with (
        patch("builtins.__import__", side_effect=without_netra),
        pytest.raises(ModuleNotFoundError, match="requires netra-kernel to be installed"),
    ):
        runpy.run_path(str(shim))
