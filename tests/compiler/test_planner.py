from __future__ import annotations

import unittest
import hashlib
import subprocess
from pathlib import Path

from netra_compiler.frontends import load_model
from netra_compiler.planner import plan_graph
from netra_compiler.profiles import standard_profiles
from netra_compiler.tactics import gfx950_registry
from netra_compiler.types import Maturity


ROOT = Path(__file__).resolve().parents[2]


class PlannerTest(unittest.TestCase):
    def test_qwen_selects_compat_and_rejects_raw(self) -> None:
        graph, _ = load_model(ROOT / "manifests/gfx950/models/qwen36-dense.json")
        plan = plan_graph(graph, standard_profiles()[0], "gfx950")
        self.assertTrue(all(p.tactic.name.endswith(".compat") for p in plan.operations))
        self.assertTrue(all(p.execution == "framework_fallback" for p in plan.operations))
        raw = [c for c in plan.operations[0].explanation if c["tactic"] and "raw_dense" in c["tactic"]]
        self.assertEqual({c["reasons"][0] for c in raw}, {"maturity is rejected"})

    def test_rejected_not_selected_even_when_experimental_enabled(self) -> None:
        graph, _ = load_model(ROOT / "manifests/gfx950/models/qwen36-dense.json")
        plan = plan_graph(graph, standard_profiles()[0], "gfx950", allow_experimental=True)
        self.assertTrue(all(p.tactic.maturity is Maturity.ACCEPTED for p in plan.operations))

    def test_raw_tactics_register_real_templates_without_maturity_change(self) -> None:
        raw = [tactic for tactic in gfx950_registry() if tactic.artifact_kind == "raw_assembly"]
        self.assertEqual(len(raw), 2)
        for tactic in raw:
            self.assertIs(tactic.maturity, Maturity.REJECTED)
            self.assertIsNotNone(tactic.source_template)
            self.assertTrue((ROOT / tactic.source_template).is_file())
            self.assertFalse((ROOT / tactic.source).is_file())
            self.assertIsNotNone(tactic.source_revision)
            payload = subprocess.run(
                ["git", "show", f"{tactic.source_revision}:{tactic.source}"],
                cwd=ROOT,
                check=True,
                stdout=subprocess.PIPE,
            ).stdout
            self.assertEqual(hashlib.sha256(payload).hexdigest(), tactic.source_sha256)

    def test_gemma_reuses_without_changing_qwen_tactic(self) -> None:
        graph, _ = load_model(ROOT / "tests/compiler/fixtures/gemma-dense-synthetic.json")
        plan = plan_graph(graph, standard_profiles()[0], "gfx950")
        self.assertEqual(plan.operations[0].tactic.name, "gfx950.aiter_blockscale_dense_m1.compat")
        self.assertEqual(plan.operations[1].tactic.name, "gfx950.aiter_blockscale_dense_m1.compat")
        self.assertTrue(all(item.tactic is None for item in plan.operations[2:]))
        self.assertEqual(
            plan.operations[-1].operation.inputs[:2],
            (
                "model.layers.shared.gated_silu.fp8",
                "model.layers.shared.gated_silu.scale",
            ),
        )


if __name__ == "__main__": unittest.main()
