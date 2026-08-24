from __future__ import annotations

import unittest

from netra_compiler.contracts import (
    GoldenKernelContract,
    KernelArgument,
    KernelContract,
    Launch,
)
from netra_compiler.errors import ValidationError
from netra_compiler.types import DType, Epilogue, Maturity


def contract(**changes) -> KernelContract:
    values = dict(target="gfx950", wave_size=64, operation="dense", m=1, n=2048, k=4096,
                  input_dtype=DType.FP8_E4M3, weight_dtype=DType.FP8_E4M3,
                  accumulator_dtype=DType.FP32, output_dtype=DType.BF16,
                  activation_quantization="e4m3_per_128", weight_quantization="e4m3_128x128",
                  activation_scale_block=128, weight_scale_block=(128, 128),
                  activation_layout="row_major_fp8_block128",
                  weight_layout="aiter_shuffle_16x16_fp8_block128",
                  output_layout="row_major_bf16", epilogue=Epilogue.IDENTITY,
                  tactic="test", launch=Launch((128, 1, 1), (64, 1, 1)))
    values.update(changes)
    return KernelContract(**values)


class ContractTest(unittest.TestCase):
    def test_hash_is_stable_and_model_independent(self) -> None:
        first = contract(source_refs=("one",), evidence_refs=("machine-a",))
        second = contract(source_refs=("two",), evidence_refs=("machine-b",))
        self.assertEqual(first.stable_id, second.stable_id)
        self.assertRegex(first.stable_id, r"^nk_[0-9a-f]{24}$")

    def test_invalid_target_wave_and_layout_rejected(self) -> None:
        for changes in ({"target": "gfx942"}, {"wave_size": 32},
                        {"weight_scale_block": (127, 128)}):
            with self.subTest(changes=changes), self.assertRaises(ValidationError):
                contract(**changes)

    def test_immutable(self) -> None:
        value = contract()
        with self.assertRaises(Exception):
            value.m = 2

    def test_fixed_and_dynamic_lds_are_distinct_contract_fields(self) -> None:
        launch = Launch((128, 1, 1), (128, 1, 1), 1024, 0)
        value = contract(launch=launch)
        self.assertEqual(value.to_dict()["launch"]["lds_bytes"], 1024)
        self.assertEqual(value.to_dict()["launch"]["dynamic_lds_bytes"], 0)
        with self.assertRaises(ValidationError):
            Launch((1, 1, 1), (64, 1, 1), 0, -1)

    def test_golden_contract_validates_typed_kernarg_size_and_maturity(self) -> None:
        values = dict(
            target="gfx950", wave_size=64, operation="test", tactic="golden",
            symbol="fixed_symbol", hsaco_name="fixed.hsaco",
            hsaco_sha256="a" * 64, kernarg_size=16,
            launch=Launch((1, 1, 1), (64, 1, 1)),
            arguments=(KernelArgument("pointer", "pointer"),
                       KernelArgument("constant", "u32_constant", "value", 1)),
            maturity=Maturity.ACCEPTED,
        )
        value = GoldenKernelContract(**values)
        self.assertRegex(value.stable_id, r"^nk_[0-9a-f]{24}$")
        with self.assertRaisesRegex(ValidationError, "kernarg size mismatch"):
            GoldenKernelContract(**{**values, "kernarg_size": 8})
        with self.assertRaisesRegex(ValidationError, "already be accepted"):
            GoldenKernelContract(**{**values, "maturity": Maturity.VERIFIED})


if __name__ == "__main__": unittest.main()
