from __future__ import annotations

import unittest

from netra_compiler.errors import ValidationError
from netra_compiler.layouts import (
    RepackStep,
    plan_weight_layout,
    qwen_fp8_weight_plan,
    repack_fixture,
)


class LayoutTest(unittest.TestCase):
    def test_plan_determinism_and_fixture_transform(self) -> None:
        self.assertEqual(qwen_fp8_weight_plan("w", "row").to_dict(),
                         qwen_fp8_weight_plan("w", "row").to_dict())
        step = RepackStep("row", "col", "transpose_bytes")
        self.assertEqual(repack_fixture(bytes(range(6)), 2, 3, step), bytes((0, 3, 1, 4, 2, 5)))

    def test_real_hook_not_claimed_as_fixture_transform(self) -> None:
        step = qwen_fp8_weight_plan("w", "row").steps[0]
        with self.assertRaisesRegex(ValidationError, "recipe hook"):
            repack_fixture(bytes(4), 2, 2, step)

    def test_unknown_model_layout_does_not_silently_use_qwen_shuffle(self) -> None:
        with self.assertRaisesRegex(ValidationError, "unsupported weight layout transform"):
            plan_weight_layout(
                "w", "unknown_checkpoint_layout", "aiter_shuffle_16x16_fp8_block128"
            )


if __name__ == "__main__": unittest.main()
