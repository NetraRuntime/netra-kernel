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
    LOCKED_ACCEPTED_TACTICS = frozenset(
        {
            "gfx950.attention_gqa4_fp8kv",
            "gfx950.attention_gqa8_fp8kv",
            "gfx950.attention_splitseq_prepare",
            "gfx950.attention_splitseq_stage1",
            "gfx950.attention_splitseq_stage2",
            "gfx950.gdn_h_m8192_bv16_varlen",
            "gfx950.gdn_qkvz_conv_m12",
            "gfx950.gdn_state_replay_m12_fused_exact",
            "gfx950.gdn_verify_core_m12_packed_pair_interleaved",
            "gfx950.gdn_verify_precompute_m12",
            "gfx950.moe_down_reduce_decode_m1",
            "gfx950.moe_gate_up_decode_m1",
            "gfx950.moe_silu_quant_decode_m1",
            "gfx950.router_bf16_verify_m16",
        }
    )

    def test_registry_is_model_independent_and_locked(self) -> None:
        tactics = load_fixed_tactic_catalog(ROOT)
        accepted = [t for t in tactics if t.maturity is Maturity.ACCEPTED]
        # The accepted set is exactly the locked Qwen3.6-35B current-best
        # registry. New tactics must enter as experiment or verified and may
        # not silently join or displace this set.
        self.assertEqual({t.name for t in accepted}, self.LOCKED_ACCEPTED_TACTICS)
        self.assertTrue(all(t.acceptance_scope == "locked_exact_contract" for t in accepted))
        for tactic in tactics:
            if tactic.maturity is not Maturity.ACCEPTED:
                self.assertIn(tactic.maturity, (Maturity.EXPERIMENT, Maturity.VERIFIED))
        self.assertEqual(len({t.stable_id for t in tactics}), len(tactics))
        for tactic in tactics:
            self.assertNotIn("qwen", tactic.name.lower())
            self.assertNotIn("qwen", tactic.family.lower())
            self.assertNotIn("qwen", tactic.template.lower())
            semantic_source = _computational_text((ROOT / tactic.template).read_text())
            self.assertNotIn("qwen", semantic_source.lower())
            renamed = dataclasses.replace(tactic, compatibility_symbols=("another_model_alias",))
            self.assertEqual(tactic.stable_id, renamed.stable_id)

    def test_hv48_verify_tactics_are_verified_and_hv32_contracts_reject_them(self) -> None:
        tactics = {t.name: t for t in load_fixed_tactic_catalog(ROOT)}
        precompute = tactics["gfx950.gdn_verify_precompute_m12_qk_hv48"]
        core = tactics["gfx950.gdn_verify_core_m12_bv16_hv48_k0"]
        for tactic in (precompute, core):
            self.assertIs(tactic.maturity, Maturity.VERIFIED)
            self.assertEqual(tactic.rank, 150)
            constants = dict(tactic.contract_constants)
            self.assertEqual(constants["NETRA_VALUE_HEADS"], (48,))
            definitions = dict(tactic.compile_definitions)
            self.assertEqual(definitions["NETRA_TOKENS"], (8, 12))
            request = {
                "operation": tactic.operation,
                "target": "gfx950",
                "wave_size": 64,
                "semantics": tactic.semantics.to_dict(),
                "constants": {
                    name: allowed[0]
                    for name, allowed in (
                        *tactic.contract_constants,
                        *tactic.compile_definitions,
                    )
                },
            }
            self.assertEqual(tactic.rejection_reasons(request), ())
            hv32_request = dict(request)
            hv32_request["constants"] = {
                **request["constants"],
                "NETRA_VALUE_HEADS": 32,
            }
            self.assertIn(
                "NETRA_VALUE_HEADS mismatch", tactic.rejection_reasons(hv32_request)
            )
        # The locked 35B verify tactics keep their own templates untouched.
        self.assertEqual(
            tactics["gfx950.gdn_verify_precompute_m12"].template,
            "kernels/gfx950/templates/gdn/verify/precompute.inc",
        )
        self.assertEqual(
            tactics["gfx950.gdn_verify_core_m12_packed_pair_interleaved"].template,
            "kernels/gfx950/templates/gdn/verify/recurrent_packed_pair.inc",
        )

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
