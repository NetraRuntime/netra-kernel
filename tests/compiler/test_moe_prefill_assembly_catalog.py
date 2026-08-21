from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
from netra_compiler.backends.gfx950.codegen import instantiate_fixed_source
from netra_compiler.engine import compile_engine, semantic_file_hashes
from netra_compiler.frontends import load_model
from netra_compiler.profiles import load_profile_registry, select_profile
from netra_compiler.types import DType


ROOT = Path(__file__).resolve().parents[2]


def _tactics():
    return {
        tactic.name.removeprefix("gfx950."): tactic
        for tactic in load_fixed_tactic_catalog(ROOT)
    }


class MoePrefillAssemblyCatalogTest(unittest.TestCase):
    def test_exact_c64_model_records_real_fp16_workspace_dataflow(self) -> None:
        graph, model = load_model(
            ROOT / "manifests/gfx950/models/qwen36-35b-c64-fp8.json"
        )
        tensors = {tensor.name: tensor for tensor in graph.tensors}
        self.assertIs(tensors["partials_f16"].dtype, DType.FP16)
        self.assertEqual(
            tensors["route_scale_workspace_f32"].shape,
            (23360, 4),
        )
        self.assertEqual(graph.operations[1].inputs[0], "partials_f16")
        self.assertEqual(model["configuration"]["dflash_block_size"], 12)
        self.assertEqual(model["configuration"]["cuda_graph_batch_sizes"][-1], 64)

    def test_exact_c64_profile_rejects_neighboring_route_shapes(self) -> None:
        profiles = load_profile_registry(ROOT, "gfx950", tensor_parallel=1)
        exact = {
            "m": 12,
            "batch": 64,
            "route_rows": 768,
            "sequence": 1024,
        }
        selected = select_profile(
            profiles,
            exact,
            quantization="fp8_block128",
            tensor_parallel=1,
        )
        self.assertEqual(selected.profile.name, "verify_m12_b64_routes768")
        for field, value in (("m", 8), ("batch", 63), ("route_rows", 767)):
            dimensions = dict(exact, **{field: value})
            result = select_profile(
                tuple(
                    profile for profile in profiles
                    if profile.name == "verify_m12_b64_routes768"
                ),
                dimensions,
                quantization="fp8_block128",
                tensor_parallel=1,
            )
            self.assertFalse(result.supported, field)

    def test_c64_engine_is_byte_deterministic_and_orders_the_pair(self) -> None:
        model = ROOT / "manifests/gfx950/models/qwen36-35b-c64-fp8.json"
        with (
            tempfile.TemporaryDirectory() as first_dir,
            tempfile.TemporaryDirectory() as second_dir,
        ):
            first_path = Path(first_dir)
            second_path = Path(second_dir)
            first = compile_engine(
                model, "gfx950", "verify_m12_b64_routes768", first_path
            )
            second = compile_engine(
                model, "gfx950", "verify_m12_b64_routes768", second_path
            )
            self.assertEqual(first["engine_id"], second["engine_id"])
            self.assertEqual(
                semantic_file_hashes(first_path), semantic_file_hashes(second_path)
            )
            self.assertEqual(first["workspace_bytes"], 0)
            recipe = json.loads((first_path / "graph_recipe.json").read_text())
            self.assertEqual(
                [operation["depends_on"] for operation in recipe["operations"]],
                [[], [0]],
            )

    def test_exact_m768_producer_and_reducer_are_model_neutral(self) -> None:
        tactics = _tactics()
        producer = tactics["moe_prefill_fused_splitk2_fp8_m768"]
        reducer = tactics["moe_prefill_route_reduce_splitk2_f16_m768"]
        self.assertEqual(producer.maturity.value, "verified")
        self.assertEqual(reducer.maturity.value, "verified")
        self.assertEqual(producer.threads_per_workgroup, 256)
        self.assertEqual(producer.lds_bytes, 65536)
        self.assertEqual(producer.kernarg_size, 112)
        self.assertEqual(reducer.threads_per_workgroup, 64)
        self.assertEqual(reducer.lds_bytes, 0)
        self.assertEqual(reducer.kernarg_size, 32)
        for tactic in (producer, reducer):
            self.assertNotIn("qwen", tactic.name.lower())
            self.assertNotIn("qwen", tactic.family.lower())
            self.assertNotIn("qwen", tactic.template.lower())
            self.assertTrue(tactic.graph_capture)
            self.assertTrue(tactic.deterministic)

    def test_instantiation_is_deterministic_and_has_exact_guards(self) -> None:
        for name, grid in (
            ("moe_prefill_fused_splitk2_fp8_m768", (2, 365, 1)),
            ("moe_prefill_route_reduce_splitk2_f16_m768", (16, 768, 1)),
        ):
            with self.subTest(name=name):
                tactic = _tactics()[name]
                constants = {
                    key: values[0] for key, values in tactic.contract_constants
                }
                request = {
                    "family": tactic.family,
                    "operation": tactic.operation,
                    "target": tactic.target,
                    "wave_size": tactic.wave_size,
                    "semantics": tactic.semantics.to_dict(),
                    "constants": constants,
                    "launch_grid": grid,
                }
                contract = tactic.make_contract(request)
                first = instantiate_fixed_source(tactic, contract)
                second = instantiate_fixed_source(tactic, contract)
                self.assertEqual(first, second)
                self.assertEqual(contract.launch.grid, grid)
                self.assertNotIn("qwen", contract.symbol)
                wrong = dict(request)
                wrong["constants"] = dict(constants, NETRA_ROWS=767)
                self.assertIn(
                    "NETRA_ROWS mismatch", tactic.rejection_reasons(wrong)
                )

    def test_public_producer_uses_semantic_stages_not_numbered_pipelines(self) -> None:
        root = ROOT / "kernels/gfx950/templates/moe/prefill"
        wrapper = (root / "fused_splitk2_fp8.inc").read_text()
        for stage in (
            "entry_routing.inc",
            "gate_up.inc",
            "silu_quant.inc",
            "down_partial.inc",
            "metadata.inc",
        ):
            self.assertIn(stage, wrapper)
        for legacy_name in ("pipeline1", "pipeline2", "pipeline3", "pipeline4"):
            self.assertNotIn(legacy_name, wrapper.lower())
        self.assertFalse(list(root.rglob("*.s")))

    def test_deployment_contains_two_real_artifacts_without_legacy_copies(self) -> None:
        deployment = json.loads(
            (ROOT / "manifests/gfx950/deployments/"
             "qwen36-35b-c64-current-best.json").read_text()
        )
        self.assertEqual(len(deployment["artifacts"]), 2)
        self.assertEqual(
            {item["name"] for item in deployment["artifacts"]},
            {
                "qwen36_moe_fused_m64n256_partial_fp8_gfx950",
                "qwen36_moe_route_reduce_f16_2h_x2_gfx950",
            },
        )

    def test_bridge_hot_launch_has_fixed_dimensions_and_no_runtime_setup(self) -> None:
        source = (
            ROOT / "runtime/gfx950/fp8/moe/moe_prefill_m768_bridge.hip"
        ).read_text()
        launch = source.split(
            'extern "C" int netra_moe_prefill_m768_launch', 1
        )[1].split(
            'extern "C" int netra_moe_prefill_m768_unload', 1
        )[0]
        for forbidden in (
            "getenv(",
            "hipMalloc",
            "hipFree",
            "hipModuleLoad",
            "hipModuleGetFunction",
            "hipDeviceSynchronize",
            "hipStreamSynchronize",
        ):
            self.assertNotIn(forbidden, launch)
        self.assertIn("producer_function, 2, kSortedBlockCapacity", launch)
        self.assertIn("reducer_function, 16, kRows", launch)
        self.assertIn("kSortedBlockCapacity = 365", source)

    def test_original_35b_compatibility_inventory_is_unchanged(self) -> None:
        original = json.loads(
            (ROOT / "manifests/gfx950/deployments/"
             "qwen36-35b-current-best.json").read_text()
        )
        self.assertEqual(len(original["artifacts"]), 18)
        self.assertEqual(
            sum(len(item["members"]) for item in original["artifacts"]), 19
        )


if __name__ == "__main__":
    unittest.main()
