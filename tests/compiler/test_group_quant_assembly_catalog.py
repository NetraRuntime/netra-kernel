from __future__ import annotations

import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
from netra_compiler.backends.gfx950.codegen import instantiate_fixed_source


ROOT = Path(__file__).resolve().parents[2]
EXPECTED_ROWS = {
    "add_rmsnorm_group_quant_n5120": (8, 16, 32, 64, 128, 256, 512, 640,
                                       768, 896, 1024, 1280, 1536),
    "silu_mul_group_quant_n17408_store_bf16": (8, 16, 32, 64, 128, 256,
                                                512, 640, 768, 896, 1024,
                                                1280, 1536),
    "silu_mul_group_quant_n17408_prequant_only": (8, 16, 32, 64, 128, 256,
                                                   512, 640, 768, 896, 1024,
                                                   1280, 1536),
    "gated_rmsnorm_group_quant_d128_rpb1": (384,),
    "gated_rmsnorm_group_quant_d128_rpb2": (768,),
    "gated_rmsnorm_group_quant_d128_rpb4": (1536, 3072, 6144, 12288, 24576,
                                             30720, 36864, 43008, 49152,
                                             61440, 73728),
}


def _tactics():
    return {
        tactic.name.removeprefix("gfx950."): tactic
        for tactic in load_fixed_tactic_catalog(ROOT)
    }


class GroupQuantAssemblyCatalogTest(unittest.TestCase):
    def test_tactics_are_model_neutral_fixed_assembly(self) -> None:
        tactics = _tactics()
        for name, rows in EXPECTED_ROWS.items():
            with self.subTest(name=name):
                tactic = tactics[name]
                self.assertEqual(tactic.artifact_kind, "raw_assembly_template")
                self.assertEqual(tactic.maturity.value, "verified")
                self.assertEqual(dict(tactic.compile_definitions)["NETRA_ROWS"], rows)
                self.assertNotIn("qwen", tactic.name.lower())
                self.assertNotIn("qwen", tactic.family.lower())
                self.assertNotIn("gemma", tactic.name.lower())
                self.assertNotIn("gemma", tactic.family.lower())
                self.assertTrue(tactic.graph_capture)
                self.assertTrue(tactic.deterministic)

    def test_instantiation_is_deterministic_and_exactly_guarded(self) -> None:
        for name, rows in EXPECTED_ROWS.items():
            with self.subTest(name=name):
                tactic = _tactics()[name]
                constants = {
                    key: values[0] for key, values in tactic.contract_constants
                }
                constants["NETRA_ROWS"] = rows[0]
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

                bad = dict(request)
                bad["constants"] = dict(constants, NETRA_ROWS=7)
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
        self.assertIn("stream, arguments, nullptr", launch_source)
        self.assertIn("kTokenRows", launch_source)
        self.assertIn("kGatedRows", launch_source)


if __name__ == "__main__":
    unittest.main()
