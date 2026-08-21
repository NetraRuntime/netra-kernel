from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from netra_compiler.engine import compile_engine, semantic_file_hashes
from netra_compiler.frontends import load_model
from netra_compiler.frontends.huggingface_config import read_recognized_config
from netra_compiler.planner import plan_graph
from netra_compiler.profiles import load_profile_registry, select_profile
from netra_compiler.types import stable_hash
from netra_compiler.validation import validate_engine_directory


ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / "manifests/gfx950/models/qwen36-27b-fp8.json"
TREE_HASH = "80fa5ef34e3beec2b0a5ae835ff24a85dedd7b4fb2dba5742bf47d18c63c02f5"


class Qwen3627BTest(unittest.TestCase):
    def test_real_huggingface_config_fields_are_recognized_without_invented_tp(self) -> None:
        config = {
            "architectures": ["Qwen3_5ForConditionalGeneration"],
            "model_type": "qwen3_5",
            "text_config": {
                "model_type": "qwen3_5_text",
                "hidden_size": 5120,
                "intermediate_size": 17408,
                "num_hidden_layers": 64,
                "num_attention_heads": 24,
                "num_key_value_heads": 4,
                "head_dim": 256,
                "linear_num_key_heads": 16,
                "linear_key_head_dim": 128,
                "linear_num_value_heads": 48,
                "linear_value_head_dim": 128,
                "linear_conv_kernel_dim": 4,
                "full_attention_interval": 4,
                "attn_output_gate": True,
                "vocab_size": 248320,
                "mtp_num_hidden_layers": 1,
                "layer_types": [
                    "full_attention" if layer % 4 == 3 else "linear_attention"
                    for layer in range(64)
                ],
                "max_position_embeddings": 262144,
            },
            "quantization_config": {
                "quant_method": "fp8",
                "fmt": "e4m3",
                "activation_scheme": "dynamic",
                "weight_block_size": [128, 128],
            },
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory, "config.json")
            path.write_text(json.dumps(config))
            recognized = read_recognized_config(path)
        self.assertEqual(recognized["architecture"], config["architectures"][0])
        self.assertEqual(recognized["model_type"], "qwen3_5_text")
        self.assertEqual(recognized["hidden_size"], 5120)
        self.assertEqual(recognized["linear_num_value_heads"], 48)
        self.assertTrue(recognized["attention_output_gate"])
        self.assertEqual(recognized["mtp_layers"], 1)
        self.assertEqual(recognized["quantization_config"], config["quantization_config"])
        self.assertNotIn("tensor_parallel", recognized)

    def test_real_manifest_hash_and_frontend_shape_inventory(self) -> None:
        graph, model = load_model(MODEL)
        self.assertEqual(
            stable_hash(model),
            "4441b80be89c2479037dab4c6893ace94dc6a790ee2f8fccf8550c0b7547e7d8",
        )
        self.assertEqual(
            stable_hash(graph.to_dict()),
            "0dc6ccefefbee7000f1997f423233d05dc807f214fc991cb5d35a7bb08cc9440",
        )
        dense = [operation for operation in graph.operations if operation.kind == "dense"]
        self.assertEqual(len(dense), 256)
        fixed = [
            operation for operation in graph.operations
            if operation.kind == "fixed_kernel"
        ]
        self.assertEqual(len(fixed), 56)
        self.assertEqual(
            {operation.attributes["operation"] for operation in fixed},
            {
                "add_rmsnorm_group_quant",
                "silu_mul_group_quant",
                "gated_rmsnorm_group_quant",
                "dense",
            },
        )
        self.assertEqual(
            {(op.attributes["n"], op.attributes["k"]) for op in dense},
            {
                (16384, 5120),
                (14336, 5120),
                (34816, 5120),
                (5120, 6144),
                (5120, 17408),
            },
        )
        self.assertEqual(
            [op.name for op in dense[:4]],
            [
                "model.layers.0.linear_attn.in_proj_qkvz",
                "model.layers.0.linear_attn.out_proj",
                "model.layers.0.mlp.gate_up_proj",
                "model.layers.0.mlp.down_proj",
            ],
        )
        self.assertEqual(
            [op.name for op in dense[12:16]],
            [
                "model.layers.3.self_attn.qkv_proj",
                "model.layers.3.self_attn.o_proj",
                "model.layers.3.mlp.gate_up_proj",
                "model.layers.3.mlp.down_proj",
            ],
        )
        configuration = model["configuration"]
        self.assertEqual(configuration["speculative_algorithm"], "DFLASH")
        self.assertTrue(configuration["dflash_enabled"])
        self.assertEqual(configuration["dflash_block_size"], 8)
        self.assertEqual(configuration["dflash_draft_window_size"], 2048)
        self.assertEqual(configuration["dflash_mamba_cache_steps"], 0)
        self.assertEqual(configuration["mamba_ssm_dtype"], "bfloat16")
        self.assertEqual(
            configuration["dflash_checkpoint_revision"],
            "0919688658996800f86b895034249700e9481106",
        )
        self.assertEqual(
            configuration["cuda_graph_batch_sizes"],
            [1, 2, 4, 8, 16, 32, 64, 80, 96, 112, 128, 160, 192],
        )

    def test_no_35b_tactic_is_relabelled_for_27b(self) -> None:
        graph, _ = load_model(MODEL)
        profile = {
            item.name: item
            for item in load_profile_registry(ROOT, "gfx950", tensor_parallel=1)
        }["decode_m1"]
        plan = plan_graph(graph, profile, "gfx950")
        dense = [item for item in plan.operations if item.operation.kind == "dense"]
        self.assertTrue(all(item.tactic is None for item in dense))
        self.assertTrue(all(item.execution == "fallback" for item in dense))
        self.assertEqual(
            sorted({item.contract.stable_id for item in dense}),
            [
                "nkf_214c47c754dc581ed47c42d8",
                "nkf_c1005fa8791524c3766a9ab7",
                "nkf_c5e33744cae9e5b3b5bd0384",
                "nkf_d004ef9b79aa9ee63798d2b2",
                "nkf_eafaa53e98077d793e037be6",
            ],
        )

    def test_layout_repack_and_scale_recipe_is_explicit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            compile_engine(
                MODEL,
                "gfx950",
                "decode_m1",
                output,
                checkpoint_hash=TREE_HASH,
            )
            layout = json.loads((output / "layout_plan.json").read_text())
            by_tensor = {item["tensor"]: item for item in layout["bindings"]}
            packed = by_tensor[
                "model.layers.0.linear_attn.in_proj_qkvz.weight"
            ]
            self.assertEqual(
                [step["transform"] for step in packed["steps"]],
                ["concatenate_output_shards", "aiter_shuffle_16x16"],
            )
            self.assertEqual(
                packed["scale"]["steps"],
                ["concatenate_output_scale_shards_axis0", "widen_bf16_to_fp32_exact"],
            )
            contract = json.loads((output / "contracts.json").read_text())["contracts"][0]
            self.assertEqual(
                contract["scale_layouts"],
                {
                    "activation": "transposed_kblock_major_fp32",
                    "weight": "row_major_nblock_kblock_fp32",
                },
            )

    def test_engine_is_byte_deterministic_and_deduplicated(self) -> None:
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            a, b = Path(first), Path(second)
            compile_engine(MODEL, "gfx950", "verify_m8_b129_192", a, checkpoint_hash=TREE_HASH)
            compile_engine(MODEL, "gfx950", "verify_m8_b129_192", b, checkpoint_hash=TREE_HASH)
            self.assertEqual(semantic_file_hashes(a), semantic_file_hashes(b))
            contracts = json.loads((a / "contracts.json").read_text())["contracts"]
            engine = json.loads((a / "engine.json").read_text())
            self.assertEqual(len(contracts), 61)
            self.assertEqual(len(engine["operations"]), 323)
            self.assertEqual(len(engine["kernel_symbols"]), 56)
            self.assertEqual(len(set(engine["kernel_symbols"])), 56)
            self.assertEqual(len(engine["fallbacks"]), 267)
            result = validate_engine_directory(a)
            self.assertEqual(result["kernel_operations"], 56)
            self.assertEqual(result["fallback_operations"], 267)

    def test_profiles_reject_unobserved_shapes(self) -> None:
        profiles = load_profile_registry(ROOT, "gfx950", tensor_parallel=1)
        by_name = {profile.name: profile for profile in profiles}
        observed = {
            "decode_m1": {"m": 1, "batch": 1, "sequence": 0},
            "decode_m16_b16": {"m": 16, "batch": 16, "sequence": 4752},
            "prefill_m80_b1": {"m": 80, "batch": 1, "sequence": 80},
            "prefill_m256_b1": {"m": 256, "batch": 1, "sequence": 256},
            "prefill_m3840_b15": {"m": 3840, "batch": 15, "sequence": 256},
            "verify_m4_b1": {"m": 4, "batch": 1, "sequence": 80},
            "verify_m8": {"m": 8, "batch": 128, "sequence": 32768},
            "verify_m8_b129_192": {"m": 8, "batch": 192, "sequence": 32768},
        }
        for name, dimensions in observed.items():
            self.assertTrue(
                by_name[name].matches(
                    dimensions,
                    quantization="fp8_block128",
                    tensor_parallel=1,
                ),
                name,
            )
        for dimensions in (
            {"m": 8, "batch": 129, "sequence": 32768},
            {"m": 8, "batch": 128, "sequence": 32769},
            {"m": 7, "batch": 128, "sequence": 32768},
        ):
            self.assertFalse(
                by_name["verify_m8"].matches(
                    dimensions,
                    quantization="fp8_block128",
                    tensor_parallel=1,
                )
            )
        for dimensions in (
            {"m": 8, "batch": 128, "sequence": 32768},
            {"m": 8, "batch": 193, "sequence": 32768},
            {"m": 8, "batch": 192, "sequence": 32769},
        ):
            self.assertFalse(
                by_name["verify_m8_b129_192"].matches(
                    dimensions,
                    quantization="fp8_block128",
                    tensor_parallel=1,
                )
            )
        unsupported = select_profile(
            profiles,
            {"m": 2, "batch": 1, "sequence": 0},
            quantization="fp8_block128",
            tensor_parallel=1,
        )
        self.assertFalse(unsupported.supported)
        self.assertIn("fallback", unsupported.reason)

    def test_35b_compatibility_inventory_remains_locked(self) -> None:
        deployment = json.loads(
            (
                ROOT
                / "manifests/gfx950/deployments/qwen36-35b-current-best.json"
            ).read_text()
        )
        self.assertEqual(len(deployment["artifacts"]), 18)
        self.assertEqual(
            sum(len(artifact["members"]) for artifact in deployment["artifacts"]),
            19,
        )
        self.assertTrue(
            all(
                len(artifact["locked_text_sha256"]) == 64
                for artifact in deployment["artifacts"]
            )
        )

    def test_bf16_c192_gsm8k_evidence_matches_optimized_manifest(self) -> None:
        deployment = json.loads(
            (
                ROOT
                / "manifests/gfx950/deployments/qwen36-27b-gdn-bf16-state-t8.json"
            ).read_text()
        )
        serving = deployment["serving_evidence"]
        self.assertEqual(serving["status"], "verified_opt_in")
        self.assertEqual(
            serving["summary_sha256"],
            "ed34b53f83733f37678fded570c9d2a01e6375d1e5a0cb730ad33b7feb0e1786",
        )
        self.assertEqual(serving["total_requests"], 13190)
        self.assertEqual(serving["tensor_parallelism"], 1)
        self.assertEqual(serving["data_parallelism"], 1)
        self.assertEqual(serving["throughput_profile"]["max_running_requests"], 192)
        self.assertEqual(
            serving["throughput_profile"]["graph_batch_sizes"][-2:], [160, 192]
        )
        _, model = load_model(MODEL)
        self.assertEqual(model["configuration"]["mamba_ssm_dtype"], "bfloat16")
        self.assertEqual(model["configuration"]["cuda_graph_batch_sizes"][-1], 192)


if __name__ == "__main__":
    unittest.main()
