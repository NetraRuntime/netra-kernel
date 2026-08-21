from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.build.build_gfx950_gemm_tuning_package import TABLES, build


ROOT = Path(__file__).resolve().parents[2]


class Gfx950GemmTuningPackageTest(unittest.TestCase):
    def test_package_is_model_neutral_and_byte_deterministic(self) -> None:
        for table in TABLES:
            self.assertNotIn("qwen", table.source.lower())
            self.assertNotIn("qwen", table.output.lower())
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            a, b = Path(first), Path(second)
            first_report = build(ROOT, a)
            second_report = build(ROOT, b)
            self.assertEqual(first_report, second_report)
            self.assertEqual(
                {path.name: path.read_bytes() for path in a.iterdir()},
                {path.name: path.read_bytes() for path in b.iterdir()},
            )
            report = json.loads((a / "package.json").read_text())
            self.assertEqual(report["target"], "gfx950")
            self.assertEqual(report["compute_units"], 256)
            self.assertFalse(report["netra_kernel_ownership"])
            self.assertEqual(report["framework_fallback"], "AITER")
            self.assertEqual(
                [item["rows"] for item in report["artifacts"]],
                [60, 10, 1, 1, 8, 1],
            )


if __name__ == "__main__":
    unittest.main()
