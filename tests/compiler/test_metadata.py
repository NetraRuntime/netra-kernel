from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.metadata import validate_readobj_metadata
from netra_compiler.errors import ValidationError


class MetadataValidationTest(unittest.TestCase):
    def _metadata(self, symbol: str) -> str:
        return (
            "amdhsa.target: amdgcn-amd-amdhsa--gfx950\n"
            "wavefront_size: 64\n"
            f".name: {symbol}\n"
            f".symbol: {symbol}.kd\n"
            "kernarg_segment_size: 40\n"
            "max_flat_workgroup_size: 64\n"
            "group_segment_fixed_size: 0\n"
            "vgpr_count: 30\nsgpr_count: 32\n"
        )

    def test_kernel_descriptor_symbol_is_validated_not_just_name(self) -> None:
        symbol = "netra_dense_test"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "metadata.txt"
            path.write_text(self._metadata(symbol).replace(
                f".symbol: {symbol}.kd", ".symbol: \\symbol.kd"
            ))
            with self.assertRaisesRegex(ValidationError, "symbol"):
                validate_readobj_metadata(
                    path, symbol=symbol, kernarg_size=40, threads=64, lds_bytes=0
                )

    def test_exact_kernel_descriptor_symbol_passes(self) -> None:
        symbol = "netra_dense_test"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "metadata.txt"
            path.write_text(self._metadata(symbol))
            resources = validate_readobj_metadata(
                path, symbol=symbol, kernarg_size=40, threads=64, lds_bytes=0
            )
            self.assertEqual(resources["vgpr_count"], 30)

    def test_launch_block_may_be_below_but_not_above_metadata_maximum(self) -> None:
        symbol = "netra_gdn_test"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "metadata.txt"
            path.write_text(self._metadata(symbol).replace(
                "max_flat_workgroup_size: 64", "max_flat_workgroup_size: 512"
            ))
            resources = validate_readobj_metadata(
                path, symbol=symbol, kernarg_size=40, threads=64, lds_bytes=0
            )
            self.assertEqual(resources["threads"], 64)
            self.assertEqual(resources["max_threads"], 512)
            with self.assertRaisesRegex(ValidationError, "threads"):
                validate_readobj_metadata(
                    path, symbol=symbol, kernarg_size=40, threads=1024, lds_bytes=0
                )


if __name__ == "__main__":
    unittest.main()
