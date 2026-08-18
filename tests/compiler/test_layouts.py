from __future__ import annotations

import unittest

from netra_compiler.errors import ValidationError
from netra_compiler.layouts import (
    RepackStep,
    plan_weight_layout,
    plan_scale_layout,
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

    def test_split_checkpoint_pack_and_shuffle_is_explicit(self) -> None:
        sources = ("layer.gate_proj.weight", "layer.up_proj.weight")
        plan = plan_weight_layout(
            "layer.gate_up_proj.weight",
            "checkpoint_split_output_row_major_fp8_block128",
            "aiter_shuffle_16x16_fp8_block128",
            checkpoint_tensors=sources,
        )
        self.assertEqual(plan.checkpoint_tensors, sources)
        self.assertEqual(
            [step.transform for step in plan.steps],
            ["concatenate_output_shards", "aiter_shuffle_16x16"],
        )
        self.assertEqual(plan.steps[0].parameters, (("axis", 0), ("shards", 2)))

    def test_split_checkpoint_layout_requires_source_bindings(self) -> None:
        with self.assertRaisesRegex(ValidationError, "at least two source tensors"):
            plan_weight_layout(
                "layer.gate_up_proj.weight",
                "checkpoint_split_output_row_major_fp8_block128",
                "aiter_shuffle_16x16_fp8_block128",
            )

    def test_checkpoint_bf16_block_scales_are_widened_once(self) -> None:
        plan = plan_scale_layout(
            "layer.qkv.weight_scale",
            (
                "layer.q_proj.weight_scale_inv",
                "layer.k_proj.weight_scale_inv",
                "layer.v_proj.weight_scale_inv",
            ),
            checkpoint_dtype="bf16",
            kernel_dtype="fp32",
            block=(128, 128),
        )
        self.assertEqual(
            plan.steps,
            (
                "concatenate_output_scale_shards_axis0",
                "widen_bf16_to_fp32_exact",
            ),
        )


if __name__ == "__main__": unittest.main()
