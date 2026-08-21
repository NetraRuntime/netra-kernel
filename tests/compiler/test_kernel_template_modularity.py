from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TEMPLATES = ROOT / "kernels/gfx950/templates"


class KernelTemplateModularityTest(unittest.TestCase):
    def test_rejected_dense_template_family_is_absent(self) -> None:
        self.assertEqual(
            [
                path
                for path in (TEMPLATES / "dense").glob("**/*")
                if path.is_file()
            ],
            [],
        )
        source = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (
                ROOT / "compiler/netra_compiler/tactics.py",
                ROOT / "compiler/netra_compiler/backends/gfx950/codegen.py",
            )
        )
        self.assertNotIn("raw_dense_m1", source)
        self.assertNotIn("templates/dense", source)

    def test_gdn_operation_families_have_one_public_template_each(self) -> None:
        verify = TEMPLATES / "gdn/verify"
        common = TEMPLATES / "gdn/common"
        self.assertEqual(
            sorted(path.name for path in verify.glob("precompute*.inc")),
            ["precompute.inc"],
        )
        self.assertEqual(
            sorted(path.name for path in verify.glob("qkvz_causal_conv*.inc")),
            ["qkvz_causal_conv.inc"],
        )
        self.assertEqual(
            sorted(path.name for path in common.glob("recurrent_bv16_core*.inc")),
            ["recurrent_bv16_core.inc"],
        )

    def test_attention_public_templates_are_compositional(self) -> None:
        verify = TEMPLATES / "attention/verify"
        public = {
            path.name: path.read_text(encoding="utf-8")
            for path in verify.glob("*.inc")
        }
        self.assertTrue(
            all(
                len(source.encode("utf-8")) < 25_000
                for source in public.values()
            )
        )
        self.assertNotIn("gqa6_fp8kv_m8_qo32_kv32.inc", public)
        self.assertNotIn("gqa6_fp8kv_m8_qo32_kv64.inc", public)
        self.assertNotIn("gqa6_fp8kv_m8_qo64_kv64.inc", public)

        gqa6 = public["gqa6_fp8kv_m8.inc"]
        self.assertIn(".macro NETRA_ATTENTION_GQA6_FP8KV_M8 symbol", gqa6)
        self.assertIn("gqa6_m8/output_normalize.inc", gqa6)
        self.assertIn("gqa6_m8/output_pack_first_store.inc", gqa6)
        self.assertEqual(gqa6.count("_schedule.inc"), 3)

        for geometry in ("gqa4", "gqa8"):
            source = public[f"{geometry}_fp8kv.inc"]
            self.assertIn(f"{geometry}/entry_addressing.inc", source)
            self.assertIn(f"{geometry}/prefix_fp8kv_attention.inc", source)
            self.assertIn(f"{geometry}/causal_tail_output.inc", source)

    def test_attention_templates_have_no_imported_debug_payload(self) -> None:
        forbidden = (".file", ".loc", ".cfi_", ".debug_")
        for path in (TEMPLATES / "attention").rglob("*.inc"):
            source = path.read_text(encoding="utf-8")
            for directive in forbidden:
                self.assertNotIn(directive, source, path.as_posix())
            self.assertNotRegex(source, r"pipeline_[0-9]+")


if __name__ == "__main__":
    unittest.main()
