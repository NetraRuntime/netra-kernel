from __future__ import annotations

from unittest.mock import MagicMock, patch

from netra_kernel.runtime.gfx1151 import Gfx1151Runtime


def test_runtime_configuration_is_framework_neutral() -> None:
    library = MagicMock()
    library.netra_mxfp4_sgl_init.return_value = 0
    with patch(
        "netra_kernel.runtime.gfx1151.load_native_library", return_value=library
    ):
        runtime = Gfx1151Runtime(lambda: 1234)
    assert runtime.stream().value == 1234
    assert library.netra_mxfp4_sgl_decode.restype is not None
    assert len(library.netra_mxfp4_sgl_decode.argtypes) == 15
