from __future__ import annotations

import json
import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
from netra_compiler.backends.gfx950.codegen import instantiate_fixed_source


ROOT = Path(__file__).resolve().parents[2]
EXPECTED_RANGES = {
    "add_rmsnorm_group_quant_n5120": (1, 8192, 1),
    "silu_mul_group_quant_n17408_store_bf16": (1, 8192, 1),
    "silu_mul_group_quant_n17408_prequant_only": (1, 8192, 1),
    "gated_rmsnorm_group_quant_d128_rpb1": (48, 480, 48),
    "gated_rmsnorm_group_quant_d128_rpb2": (528, 1008, 48),
    "gated_rmsnorm_group_quant_d128_rpb4": (1056, 393216, 48),
}


def _tactics():
    return {
        tactic.name.removeprefix("gfx950."): tactic
        for tactic in load_fixed_tactic_catalog(ROOT)
    }


class GroupQuantAssemblyCatalogTest(unittest.TestCase):
    def test_tactics_are_model_neutral_fixed_assembly(self) -> None:
        tactics = _tactics()
        for name, expected_range in EXPECTED_RANGES.items():
            with self.subTest(name=name):
                tactic = tactics[name]
                self.assertEqual(tactic.artifact_kind, "raw_assembly_template")
                self.assertEqual(tactic.maturity.value, "verified")
                self.assertEqual(tactic.compile_definitions, ())
                self.assertEqual(
                    {item[0]: item[1:] for item in tactic.compile_ranges},
                    {"NETRA_ROWS": expected_range},
                )
                self.assertNotIn("qwen", tactic.name.lower())
                self.assertNotIn("qwen", tactic.family.lower())
                self.assertNotIn("gemma", tactic.name.lower())
                self.assertNotIn("gemma", tactic.family.lower())
                self.assertTrue(tactic.graph_capture)
                self.assertTrue(tactic.deterministic)

    def test_instantiation_is_deterministic_and_exactly_guarded(self) -> None:
        for name, (minimum, maximum, step) in EXPECTED_RANGES.items():
            with self.subTest(name=name):
                tactic = _tactics()[name]
                constants = {
                    key: values[0] for key, values in tactic.contract_constants
                }
                constants["NETRA_ROWS"] = minimum
                request = {
                    "family": tactic.family,
                    "operation": tactic.operation,
                    "target": tactic.target,
                    "wave_size": tactic.wave_size,
                    "semantics": tactic.semantics.to_dict(),
                    "constants": constants,
                    "launch_grid": (1, 1, 1),
                }
                contract = tactic.make_contract(request)
                first = instantiate_fixed_source(tactic, contract)
                second = instantiate_fixed_source(tactic, contract)
                self.assertEqual(first, second)
                self.assertIn(b"NETRA_ROWS", first[0])

                for rejected in (minimum - 1, maximum + 1, minimum + 1):
                    if rejected == minimum + 1 and step == 1:
                        continue
                    bad = dict(request)
                    bad["constants"] = dict(constants, NETRA_ROWS=rejected)
                    with self.assertRaisesRegex(ValueError, "NETRA_ROWS mismatch"):
                        tactic.make_contract(bad)

    def test_raw_sources_are_only_pinned_history(self) -> None:
        self.assertFalse(list((ROOT / "kernels/gfx950/activation/verify").glob("*.s")))
        self.assertFalse(list((ROOT / "kernels/gfx950/norm/verify").glob("*.s")))

    def test_bridge_hot_path_is_fixed_and_caller_stream_owned(self) -> None:
        source = (ROOT / "runtime/gfx950/group_quant/verify/"
                  "group_quant_assembly_bridge.hip").read_text()
        launch_source = source[source.index(
            'extern "C" int netra_add_rmsnorm_group_quant_n5120_launch'):]
        for forbidden in (
            "getenv(", "hipMalloc", "hipFree", "hipDeviceSynchronize",
            "hipStreamSynchronize", "hipModuleLoad", "hipModuleGetFunction",
        ):
            self.assertNotIn(forbidden, launch_source)
        self.assertIn("HIP_LAUNCH_PARAM_BUFFER_POINTER", source)
        self.assertIn("stream, nullptr, config", source)
        self.assertIn("sizeof(AddNormKernarg) == 96", source)
        self.assertIn("sizeof(SiluKernarg) == 64", source)
        self.assertIn("sizeof(GatedNormKernarg) == 104", source)
        self.assertIn("kMinTokenRows", launch_source)
        self.assertIn("kMaxTokenRows", launch_source)
        self.assertIn("kRpb1MaxTokenRows", launch_source)
        self.assertIn("kRpb2MaxTokenRows", launch_source)
        self.assertIn("properties.multiProcessorCount != kTargetComputeUnits", source)

    def test_manifest_records_the_measured_kernel_abi(self) -> None:
        model = json.loads((ROOT / "manifests/gfx950/models/"
                            "qwen36-27b-fp8.json").read_text())
        templates = model["fixed_operation_templates"]
        add_norm = next(item for item in templates if
                        item["operation"] == "add_rmsnorm_group_quant")
        self.assertEqual(
            [item["name"] for item in add_norm["arguments"]][7:13],
            ["rows", "cols", "input_row_stride", "residual_row_stride",
             "epsilon_f32_bits", "inv_fp8_max_f32_bits"],
        )
        add_tactic = _tactics()["add_rmsnorm_group_quant_n5120"]
        self.assertEqual(add_tactic.lds_bytes, 0)
        self.assertEqual(add_tactic.dynamic_lds_bytes, 256)
        bf16_add = _tactics()["add_rmsnorm_group_quant_n5120_bf16_weight"]
        self.assertEqual(bf16_add.maturity.value, "experiment")
        self.assertIn("bf16_bf16_bf16_to_", bf16_add.semantics.dtypes)
        self.assertNotEqual(add_tactic.stable_id, bf16_add.stable_id)
        gated_rpb4 = _tactics()["gated_rmsnorm_group_quant_d128_rpb4"]
        self.assertEqual(gated_rpb4.lds_bytes, 0)
        self.assertEqual(gated_rpb4.dynamic_lds_bytes, 256)
        gated = [item for item in templates if
                 item["operation"] == "gated_rmsnorm_group_quant"]
        self.assertEqual(len(gated), 3)
        for item in gated:
            self.assertEqual(item["arguments"][2]["name"], "weight_bf16")
            self.assertIn("bf16_bf16_bf16_to_",
                          item["semantics"]["dtypes"])


if __name__ == "__main__":
    unittest.main()
