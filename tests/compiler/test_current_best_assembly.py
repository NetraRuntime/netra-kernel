from __future__ import annotations

import dataclasses
import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.catalog import (
    _computational_hash,
    _computational_text,
    load_fixed_tactic_catalog,
)
from netra_compiler.types import Maturity
from netra_compiler.errors import ValidationError
from netra_compiler.frontends import load_model
from netra_compiler.planner import plan_graph
from netra_compiler.profiles import standard_profiles


ROOT = Path(__file__).resolve().parents[2]


class CurrentBestAssemblyTest(unittest.TestCase):
    def test_registry_is_model_independent_and_locked(self) -> None:
        tactics = load_fixed_tactic_catalog(ROOT)
        self.assertEqual(len(tactics), 14)
        self.assertTrue(all(t.maturity is Maturity.ACCEPTED for t in tactics))
        self.assertTrue(all(t.acceptance_scope == "locked_exact_contract" for t in tactics))
        self.assertEqual(len({t.stable_id for t in tactics}), 14)
        for tactic in tactics:
            self.assertNotIn("qwen", tactic.name.lower())
            self.assertNotIn("qwen", tactic.family.lower())
            self.assertNotIn("qwen", tactic.template.lower())
            semantic_source = _computational_text((ROOT / tactic.template).read_text())
            self.assertNotIn("qwen", semantic_source.lower())
            renamed = dataclasses.replace(tactic, compatibility_symbols=("another_model_alias",))
            self.assertEqual(tactic.stable_id, renamed.stable_id)

    def test_exact_contract_matches_and_one_dimension_mismatch_rejects(self) -> None:
        tactic = next(
            item
            for item in load_fixed_tactic_catalog(ROOT)
            if item.name == "gfx950.moe_down_reduce_decode_m1"
        )
        constants = {
            name: allowed[0]
            for name, allowed in (*tactic.contract_constants, *tactic.compile_definitions)
        }
        request = {
            "operation": tactic.operation,
            "target": "gfx950",
            "wave_size": 64,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
        }
        self.assertEqual(tactic.rejection_reasons(request), ())
        self.assertEqual(tactic.threads_per_workgroup, 128)
        self.assertEqual(tactic.lds_bytes, 1024)
        request["constants"] = {**constants, "NETRA_HIDDEN_SIZE": 4096}
        self.assertIn("NETRA_HIDDEN_SIZE mismatch", tactic.rejection_reasons(request))
        request["constants"] = {**constants, "NETRA_TYPO_BLOCK": 128}
        self.assertIn(
            "undeclared compile-time constant NETRA_TYPO_BLOCK",
            tactic.rejection_reasons(request),
        )

    def test_rank_is_explicit_and_equal_rank_is_rejected_as_ambiguous(self) -> None:
        graph, _ = load_model(ROOT / "tests/compiler/fixtures/llama-moe-gate-up-exact.json")
        base = next(
            item for item in load_fixed_tactic_catalog(ROOT)
            if item.name == "gfx950.moe_gate_up_decode_m1"
        )
        proven = dataclasses.replace(base, name="gfx950.proven", rank=10)
        unranked = dataclasses.replace(base, name="gfx950.unranked", rank=20)
        plan = plan_graph(
            graph, standard_profiles()[0], "gfx950",
            fixed_registry=(unranked, proven),
        )
        self.assertEqual(plan.operations[0].tactic.name, "gfx950.proven")
        with self.assertRaisesRegex(ValidationError, "ambiguous fixed tactics"):
            plan_graph(
                graph, standard_profiles()[0], "gfx950",
                fixed_registry=(
                    dataclasses.replace(proven, name="gfx950.a"),
                    dataclasses.replace(proven, name="gfx950.z"),
                ),
            )

    def test_gqa8_pointer_width_is_an_assembler_time_variant(self) -> None:
        tactic = next(
            item
            for item in load_fixed_tactic_catalog(ROOT)
            if item.name == "gfx950.attention_gqa8_fp8kv"
        )
        self.assertEqual(
            dict(tactic.compile_definitions)["NETRA_QO_INDPTR_BITS"],
            (32, 64),
        )

    def test_source_integrity_and_computational_identity_are_separate(self) -> None:
        tactics = load_fixed_tactic_catalog(ROOT)
        self.assertTrue(all(len(t.source_closure_sha256) == 64 for t in tactics))
        tactic = tactics[0]
        provenance_only = dataclasses.replace(
            tactic,
            source_closure_sha256="0" * 64,
        )
        self.assertEqual(tactic.stable_id, provenance_only.stable_id)
        computational_change = dataclasses.replace(
            tactic,
            computational_sha256="0" * 64,
        )
        self.assertNotEqual(tactic.stable_id, computational_change.stable_id)
        payloads = (("old/name.inc", b"v_mov_b32 v0, v1\n"),)
        renamed_payloads = (("new/name.inc", b"v_mov_b32 v0, v1\n"),)
        self.assertEqual(
            _computational_hash(payloads), _computational_hash(renamed_payloads)
        )

    def test_exact_leaf_reuse_ignores_model_name_but_not_contract(self) -> None:
        tactic = next(
            item
            for item in load_fixed_tactic_catalog(ROOT)
            if item.name == "gfx950.moe_gate_up_decode_m1"
        )
        constants = {
            name: values[0]
            for name, values in (*tactic.contract_constants, *tactic.compile_definitions)
        }
        request = {
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
        }
        for model_family in ("qwen", "gemma", "llama"):
            self.assertEqual(
                tactic.rejection_reasons({**request, "model_family": model_family}),
                (),
            )
        self.assertIn(
            "tactic-family mismatch",
            tactic.rejection_reasons({**request, "family": "attention.gqa_fp8kv"}),
        )
        self.assertIn(
            "NETRA_HIDDEN_SIZE mismatch",
            tactic.rejection_reasons(
                {**request, "constants": {**constants, "NETRA_HIDDEN_SIZE": 4096}}
            ),
        )
        self.assertIn(
            "layouts semantic mismatch",
            tactic.rejection_reasons({
                **request,
                "semantics": {**tactic.semantics.to_dict(), "layouts": "other.v1"},
            }),
        )

    def test_fixed_contract_symbol_is_model_independent_and_launch_is_fixed(self) -> None:
        tactic = next(
            item
            for item in load_fixed_tactic_catalog(ROOT)
            if item.name == "gfx950.moe_gate_up_decode_m1"
        )
        constants = {
            name: values[0]
            for name, values in (*tactic.contract_constants, *tactic.compile_definitions)
        }
        base = {
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
            "launch_grid": (576, 1, 1),
        }
        qwen = tactic.make_contract({**base, "model_family": "qwen"})
        llama = tactic.make_contract({**base, "model_family": "llama"})
        self.assertEqual(qwen.stable_id, llama.stable_id)
        self.assertEqual(qwen.symbol, llama.symbol)
        self.assertEqual(qwen.launch.grid, (576, 1, 1))
        self.assertEqual(qwen.launch.block, (64, 1, 1))
        self.assertEqual(qwen.kernarg_size, 48)


if __name__ == "__main__":
    unittest.main()
