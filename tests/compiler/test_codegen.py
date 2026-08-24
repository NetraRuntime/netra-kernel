from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.build import _normalize_tool_output
from netra_compiler.backends.gfx950.codegen import _fixed_wrapper
from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
from netra_compiler.engine import compile_engine


ROOT = Path(__file__).resolve().parents[2]


class CodegenTest(unittest.TestCase):
    def test_multi_symbol_gdn_leaf_uses_shared_core_without_runtime_choice(self) -> None:
        tactic = next(
            item for item in load_fixed_tactic_catalog(ROOT)
            if item.name == "gfx950.gdn_state_replay_m12_fused_exact"
        )
        constants = {
            name: values[0]
            for name, values in (*tactic.contract_constants, *tactic.compile_definitions)
        }
        contract = tactic.make_contract({
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": constants,
            "launch_grid": (32768, 1, 1),
        })
        payload, symbols = _fixed_wrapper(tactic, contract)
        source = payload.decode("utf-8")
        self.assertEqual(symbols, (contract.symbol,))
        self.assertIn(
            "NETRA_GDN_RECURRENT_FUSED_REPLAY "
            + contract.symbol
            + ", "
            + contract.symbol
            + "_dual",
            source,
        )
        self.assertNotIn("qwen", source.lower())
        self.assertNotIn("s_cbranch", source)
        self.assertEqual(contract.launch.block, (64, 1, 1))

        waves4 = tactic.make_contract({
            "family": tactic.family,
            "operation": tactic.operation,
            "target": tactic.target,
            "wave_size": tactic.wave_size,
            "semantics": tactic.semantics.to_dict(),
            "constants": {**constants, "NETRA_GDN_WAVES_PER_WORKGROUP": 4},
            "launch_grid": (8192, 1, 1),
        })
        self.assertEqual(waves4.launch.block, (256, 1, 1))

    def test_tool_output_uses_stable_artifact_path(self) -> None:
        artifact = Path("build/a/hsaco/kernel.hsaco")
        value = _normalize_tool_output(
            "build/a/hsaco/kernel.hsaco: file format elf64-amdgpu\n"
            f"File: {artifact.absolute()}\n",
            artifact=artifact,
        )
        self.assertEqual(
            value,
            "hsaco/kernel.hsaco: file format elf64-amdgpu\n"
            "File: hsaco/kernel.hsaco\n",
        )

    def test_symbol_source_and_specialization_are_stable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            compile_engine(ROOT / "manifests/gfx950/models/qwen36-dense.json",
                           "gfx950", "decode_m1", output)
            names = sorted(path.name for path in (output / "generated").glob("*.s"))
            self.assertEqual(names, [
                "netra_dense_m1_n2048_k4096_fp8e4m3_bf16_identity_gfx950_wave1.s",
                "netra_dense_m1_n2048_k4096_fp8e4m3_bf16_identity_gfx950_wave4_lds.s",
            ])
            for path in (output / "generated").glob("*.s"):
                source = path.read_text()
                self.assertNotIn(str(ROOT), source)
                self.assertNotIn("qwen", path.name.lower())
                self.assertNotIn("gemma", path.name.lower())
                self.assertIn(".set NETRA_M, 1", source)
                self.assertIn(".set NETRA_N, 2048", source)
                self.assertIn(".set NETRA_K, 4096", source)
                self.assertIn(".set NETRA_EPILOGUE, 0", source)
                self.assertIn('.include "dense/', source)

    def test_qwen_and_gemma_same_contract_use_model_independent_sources(self) -> None:
        with tempfile.TemporaryDirectory() as qwen_dir, tempfile.TemporaryDirectory() as gemma_dir:
            qwen, gemma = Path(qwen_dir), Path(gemma_dir)
            compile_engine(ROOT / "manifests/gfx950/models/qwen36-dense.json",
                           "gfx950", "decode_m1", qwen)
            compile_engine(ROOT / "tests/compiler/fixtures/gemma-dense-synthetic.json",
                           "gfx950", "decode_m1", gemma)
            qwen_names = {path.name for path in (qwen / "generated").glob("*.s")}
            gemma_names = {path.name for path in (gemma / "generated").glob("*.s")}
            self.assertEqual(qwen_names, gemma_names)
            for name in qwen_names:
                self.assertEqual(
                    (qwen / "generated" / name).read_bytes(),
                    (gemma / "generated" / name).read_bytes(),
                )


if __name__ == "__main__": unittest.main()
