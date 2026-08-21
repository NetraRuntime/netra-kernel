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
        # Both head geometries instantiate the same model-independent family
        # source while retaining distinct exact computational contracts.
        self.assertEqual(
            tactics["gfx950.gdn_verify_precompute_m12"].template,
            precompute.template,
        )
        self.assertEqual(
            tactics["gfx950.gdn_verify_core_m12_packed_pair_interleaved"].template,
            core.template,
        )

    def test_27b_t8_qkvz_convolution_is_separate_from_accepted_35b(self) -> None:
        tactics = {t.name: t for t in load_fixed_tactic_catalog(ROOT)}
        accepted_35b = tactics["gfx950.gdn_qkvz_conv_m12"]
        qkvz_27b = tactics["gfx950.gdn_qkvz_conv_t8_d10240"]

        self.assertIs(accepted_35b.maturity, Maturity.ACCEPTED)
        self.assertEqual(
            accepted_35b.template,
            "kernels/gfx950/templates/gdn/verify/qkvz_causal_conv.inc",
        )
        self.assertEqual(
            accepted_35b.template_sha256,
            "f00ae305ee34386de392aa5018c2c73a4aaaef86362f9cd7186ccf93780f8d44",
        )
        self.assertEqual(qkvz_27b.template, accepted_35b.template)
        self.assertIs(qkvz_27b.maturity, Maturity.VERIFIED)
        self.assertEqual(
            qkvz_27b.acceptance_scope,
            "hardware_verified_operator_serving_rejected",
        )
        self.assertEqual(qkvz_27b.rank, 140)
        self.assertEqual(
            dict(qkvz_27b.contract_constants),
            {
                "NETRA_K": (2048,),
                "NETRA_N": (16384,),
                "NETRA_TOKENS": (8,),
            },
        )
        self.assertEqual(
            qkvz_27b.compatibility_symbols,
            ("netra_gdn_qkvz_conv_t8_d10240_gfx950",),
        )

        request = {
            "family": qkvz_27b.family,
            "operation": qkvz_27b.operation,
            "target": qkvz_27b.target,
            "wave_size": qkvz_27b.wave_size,
            "semantics": qkvz_27b.semantics.to_dict(),
            "constants": {
                name: values[0]
                for name, values in (
                    *qkvz_27b.contract_constants,
                    *qkvz_27b.compile_definitions,
                )
            },
            "launch_grid": (40, 128, 1),
        }
        self.assertEqual(qkvz_27b.rejection_reasons(request), ())
        contract = qkvz_27b.make_contract(request)
        self.assertEqual(contract.launch.grid, (40, 128, 1))
        self.assertEqual(contract.launch.block, (256, 1, 1))
        self.assertNotIn("qwen", contract.symbol)

        old_constants = {
            name: values[0]
            for name, values in accepted_35b.contract_constants
        }
        self.assertIn(
            "NETRA_N mismatch",
            qkvz_27b.rejection_reasons(
                {**request, "constants": old_constants}
            ),
        )
        self.assertIn(
            "layouts semantic mismatch",
            accepted_35b.rejection_reasons(request),
        )

    def test_hv48_bf16_state_tactics_are_distinct_t8_contracts(self) -> None:
        tactics = {t.name: t for t in load_fixed_tactic_catalog(ROOT)}
        fp32_core = tactics["gfx950.gdn_verify_core_m12_bv16_hv48_k0"]
        bf16_core = tactics[
            "gfx950.gdn_verify_core_t8_bv16_hv48_k0_bf16_state"
        ]
        bf16_replay = tactics[
            "gfx950.gdn_state_replay_t8_bv16_hv48_bf16_state"
        ]

        for tactic in (bf16_core, bf16_replay):
            self.assertIs(tactic.maturity, Maturity.VERIFIED)
            self.assertEqual(tactic.rank, 140)
            self.assertEqual(
                tactic.acceptance_scope,
                "hardware_verified_operator_and_five_process_serving",
            )
            definitions = dict(tactic.compile_definitions)
            self.assertEqual(definitions["NETRA_TOKENS"], (8,))
            self.assertEqual(definitions["NETRA_GDN_INITIAL_STATE_FP32"], (0,))
            self.assertTrue(
                all("qwen" not in symbol.lower() for symbol in tactic.compatibility_symbols)
            )

        self.assertNotEqual(fp32_core.stable_id, bf16_core.stable_id)
        fp32_request = {
            "operation": bf16_core.operation,
            "target": bf16_core.target,
            "wave_size": bf16_core.wave_size,
            "semantics": fp32_core.semantics.to_dict(),
            "constants": {
                name: values[0]
                for name, values in (
                    *bf16_core.contract_constants,
                    *bf16_core.compile_definitions,
                )
            },
        }
        self.assertIn(
            "dtypes semantic mismatch",
            bf16_core.rejection_reasons(fp32_request),
        )

    def test_hv48_bridge_unloads_optional_state_replay_module(self) -> None:
        source = (
            ROOT
            / "runtime/gfx950/linear_attention/verify/"
            "qwen36_27b_gdn_verify_m12_batched_bridge.hip"
        ).read_text()
        unload = source.split(
            'extern "C" int netra_qwen36_gdn_verify_m12_batched_unload(void)',
            1,
        )[1].split(
            'extern "C" int netra_qwen36_gdn_verify_m12_batched_set_block_tokens',
            1,
        )[0]
        self.assertIn("hipModuleUnload(state_replay_module)", unload)
        self.assertIn("state_replay_module = nullptr", unload)
        self.assertIn("state_replay_function = nullptr", unload)
        self.assertIn("loaded_state_replay_path.clear()", unload)

    def test_hv48_bridge_clears_expected_legacy_symbol_miss(self) -> None:
        source = (
            ROOT
            / "runtime/gfx950/linear_attention/verify/"
            "qwen36_27b_gdn_verify_m12_batched_bridge.hip"
        ).read_text()
        lookup = source.split(
            "hipError_t get_function_with_legacy_fallback(", 1
        )[1].split("\n}\n", 1)[0]
        self.assertIn("error != hipErrorNotFound", lookup)
        self.assertIn("hipGetLastError()", lookup)
        self.assertLess(
            lookup.index("hipGetLastError()"),
            lookup.index("hipModuleGetFunction(function, module, legacy_symbol)"),
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

    def test_gqa6_m8_attention_is_verified_separate_and_exact(self) -> None:
        tactics = {t.name: t for t in load_fixed_tactic_catalog(ROOT)}
        accepted_gqa8 = tactics["gfx950.attention_gqa8_fp8kv"]
        names = (
            "gfx950.attention_gqa6_fp8kv_m8_qo32_kv32",
            "gfx950.attention_gqa6_fp8kv_m8_qo32_kv64",
            "gfx950.attention_gqa6_fp8kv_m8_qo64_kv64",
        )
        variants = [tactics[name] for name in names]
        self.assertEqual([t.rank for t in variants], [130, 131, 132])
        self.assertTrue(all(t.maturity is Maturity.VERIFIED for t in variants))
        self.assertTrue(all(t.threads_per_workgroup == 64 for t in variants))
        self.assertTrue(all(t.lds_bytes == 32768 for t in variants))
        self.assertTrue(
            all(
                t.acceptance_scope
                == "hardware_verified_operator_five_process_serving_inconclusive"
                for t in variants
            )
        )
        self.assertEqual(
            [
                (
                    dict(t.contract_constants)["NETRA_QO_INDPTR_BITS"],
                    dict(t.contract_constants)["NETRA_KV_INDEX_BITS"],
                )
                for t in variants
            ],
            [((32,), (32,)), ((32,), (64,)), ((64,), (64,))],
        )
        self.assertTrue(
            all(
                dict(t.contract_constants)["NETRA_M_MAX"] == (8,)
                and dict(t.contract_constants)["NETRA_QUERY_HEADS"] == (24,)
                and dict(t.contract_constants)["NETRA_KV_HEADS"] == (4,)
                and dict(t.contract_constants)["NETRA_HEAD_DIM"] == (256,)
                for t in variants
            )
        )
        self.assertIs(accepted_gqa8.maturity, Maturity.ACCEPTED)
        self.assertEqual(
            accepted_gqa8.template,
            "kernels/gfx950/templates/attention/verify/gqa8_fp8kv.inc",
        )
        self.assertEqual(
            accepted_gqa8.template_sha256,
            "b7143d4c4e9af35c81786ae237eeceef6e47e2d3a1d86fb2c658f0ec30c32a31",
        )

        tactic = variants[0]
        constants = {
            name: values[0]
            for name, values in tactic.contract_constants
        }
        request = {
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
            "launch_grid": (192, 4, 3),
        }
        self.assertEqual(tactic.rejection_reasons(request), ())
        contract = tactic.make_contract(request)
        self.assertEqual(contract.launch.grid, (192, 4, 3))
        self.assertEqual(contract.launch.block, (64, 1, 1))
        self.assertEqual(contract.launch.lds_bytes, 32768)
        self.assertEqual(contract.launch.dynamic_lds_bytes, 0)
        self.assertNotIn("qwen", contract.symbol)
        self.assertIn(
            "NETRA_KV_HEADS mismatch",
            tactic.rejection_reasons(
                {**request, "constants": {**constants, "NETRA_KV_HEADS": 2}}
            ),
        )
        self.assertIn(
            "layouts semantic mismatch", accepted_gqa8.rejection_reasons(request)
        )

    def test_gqa6_bridge_has_no_hot_path_specialization_or_dynamic_lds(self) -> None:
        source = (
            ROOT
            / "runtime/gfx950/attention/verify/attention_gqa6_fp8kv_m8_bridge.hip"
        ).read_text()
        launch = source.split(
            'extern "C" int netra_attention_gqa6_fp8kv_m8_launch(', 1
        )[1].split(
            'extern "C" const char* netra_attention_gqa6_fp8kv_m8_last_error', 1
        )[0]
        self.assertIn("constexpr unsigned kDynamicLdsBytes = 0", source)
        self.assertIn("kDynamicLdsBytes, stream", launch)
        self.assertNotIn("hipModuleLoad", launch)
        self.assertNotIn("hipModuleGetFunction", launch)
        self.assertNotIn("getenv", launch)
        self.assertNotIn("hipMalloc", launch)
        self.assertNotIn("hipStreamSynchronize", launch)
        self.assertIn("1, 2, 4, 8, 16, 32, 64, 80, 96, 112, 128, 160, 192", source)

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
