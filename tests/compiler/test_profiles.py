from __future__ import annotations

import unittest
from pathlib import Path

from netra_compiler.profiles import (
    DimensionGuard,
    ShapeProfile,
    load_profile_registry,
    select_profile,
    standard_profiles,
)


ROOT = Path(__file__).resolve().parents[2]


class ProfileTest(unittest.TestCase):
    def test_exact_and_bounded(self) -> None:
        profile = ShapeProfile("bounded", (("m", DimensionGuard(1, 4)), ("batch", DimensionGuard(1, 8))))
        self.assertTrue(profile.matches({"m": 3, "batch": 4}, quantization="fp8_block128", tensor_parallel=1))
        self.assertFalse(profile.matches({"m": 5, "batch": 4}, quantization="fp8_block128", tensor_parallel=1))

    def test_unsupported_is_structured(self) -> None:
        result = select_profile(standard_profiles(), {"m": 2, "batch": 1, "sequence": 0},
                                quantization="fp8_block128", tensor_parallel=1)
        self.assertFalse(result.supported)
        self.assertIn("fallback", result.reason)

    def test_registry_is_data_driven_and_binds_deployment_tp(self) -> None:
        profiles = load_profile_registry(ROOT, "gfx950", tensor_parallel=8)
        by_name = {profile.name: profile for profile in profiles}
        self.assertTrue(
            {"decode_m1", "verify_m12", "verify_m12_b1", "verify_m16", "small_prefill_m64"}
            <= set(by_name)
        )
        self.assertEqual(by_name["decode_m1"].tensor_parallel, 8)
        self.assertEqual(by_name["decode_m1"].priority, 30)
        self.assertTrue(by_name["decode_m1"].matches(
            {"m": 1, "batch": 1, "sequence": 0},
            quantization="fp8_block128",
            tensor_parallel=8,
        ))
        self.assertFalse(by_name["decode_m1"].matches(
            {"m": 1, "batch": 1, "sequence": 0},
            quantization="fp8_block128",
            tensor_parallel=1,
        ))


if __name__ == "__main__": unittest.main()
