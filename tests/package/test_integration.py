import tarfile
from pathlib import Path

from netra_kernel.sglang.integration import (
    GFX1151_BASE_COMMIT,
    GFX1151_PATCHES,
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
