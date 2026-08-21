from __future__ import annotations

import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
from netra_compiler.frontends import load_model
from netra_compiler.planner import plan_graph
from netra_compiler.profiles import load_profile_registry


ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / "manifests/gfx950/models/qwen36-27b-fp8.json"
TACTIC_NAMES = {
    "gfx950.dense_fp8_blockscale_bf16_tile128x256_k128",
    "gfx950.dense_fp8_blockscale_bf16_tile192x256_k128",
}
SHAPES = {
    (1536, 5120, 6144),
    (1536, 5120, 17408),
    (1536, 14336, 5120),
    (1536, 16384, 5120),
}


class DenseVerifyAssemblyCatalogTest(unittest.TestCase):
    def test_tactics_are_model_neutral_raw_assembly(self) -> None:
        tactics = {
            tactic.name: tactic for tactic in load_fixed_tactic_catalog(ROOT)
            if tactic.name in TACTIC_NAMES
        }
        self.assertEqual(set(tactics), TACTIC_NAMES)
        for tactic in tactics.values():
            self.assertEqual(tactic.artifact_kind, "raw_assembly_template")
            self.assertEqual(tactic.maturity.value, "verified")
            self.assertEqual(tactic.kernarg_size, 88)
            self.assertEqual(tactic.threads_per_workgroup, 512)
            self.assertEqual(
                tactic.acceptance_scope,
                "bitwise_operator_exact_serving_regressed_opt_in_only",
            )
            self.assertTrue(tactic.graph_capture)
            self.assertTrue(tactic.deterministic)
            source = (ROOT / tactic.template).read_text().lower()
            self.assertNotIn("qwen", source)
            self.assertNotIn("aiter", source)

    def test_c192_profile_selects_only_the_four_exact_contracts(self) -> None:
        graph, _ = load_model(MODEL)
        profiles = {
            profile.name: profile
            for profile in load_profile_registry(ROOT, "gfx950", tensor_parallel=1)
        }
        plan = plan_graph(graph, profiles["verify_m8_b129_192"], "gfx950")
        selected = [
            item for item in plan.operations
            if item.operation.name.startswith("verify.dense_fp8_blockscale")
        ]
        self.assertEqual(len(selected), 4)
        self.assertTrue(all(item.execution == "kernel" for item in selected))
        self.assertEqual({item.tactic.name for item in selected}, TACTIC_NAMES)
        self.assertEqual(
            {
                (
                    dict((*item.contract.constants, *item.contract.specialization))["NETRA_M"],
                    dict((*item.contract.constants, *item.contract.specialization))["NETRA_N"],
                    dict((*item.contract.constants, *item.contract.specialization))["NETRA_K"],
                )
                for item in selected
            },
            SHAPES,
        )
        other = plan_graph(graph, profiles["verify_m8"], "gfx950")
        rejected = [
            item for item in other.operations
            if item.operation.name.startswith("verify.dense_fp8_blockscale")
        ]
        self.assertTrue(all(item.execution == "fallback" for item in rejected))

    def test_bridge_launch_path_has_no_control_plane_work(self) -> None:
        source = (ROOT / "runtime/gfx950/fp8/dense/blockscale_verify_bridge.hip").read_text()
        launch = source.split(
            'extern "C" int netra_gfx950_blockscale_verify_launch', 1
        )[1]
        for forbidden in (
            "getenv(", "hipMalloc", "hipFree", "hipDeviceSynchronize",
            "hipStreamSynchronize", "hipModuleLoad", "hipModuleGetFunction",
        ):
            self.assertNotIn(forbidden, launch)
        self.assertIn("hipModuleLaunchKernel", launch)
        self.assertIn("m != kM", launch)
        self.assertIn("n == 5120 && k == 6144", launch)
        self.assertIn("n == 16384 && k == 5120", launch)
        self.assertIn("sizeof(KernelArgs) == 88", source)


if __name__ == "__main__":
    unittest.main()
