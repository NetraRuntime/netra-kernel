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

    def test_frozen_imported_attention_sources_cannot_grow_silently(self) -> None:
        # These locked sources still require a text-preserving decomposition.
        # Keep the debt explicit and reject any additional large imported dump.
        allowed = {
            "attention/verify/gqa4_fp8kv.inc",
            "attention/verify/gqa8_fp8kv.inc",
            "attention/verify/gqa6_fp8kv_m8_qo32_kv32.inc",
            "attention/verify/gqa6_fp8kv_m8_qo32_kv64.inc",
            "attention/verify/gqa6_fp8kv_m8_qo64_kv64.inc",
            "attention/verify/splitseq_stage1.inc",
            "attention/verify/splitseq_stage2.inc",
        }
        large = {
            path.relative_to(TEMPLATES).as_posix()
            for path in (TEMPLATES / "attention").rglob("*.inc")
            if path.stat().st_size >= 25_000
        }
        self.assertEqual(large, allowed)


if __name__ == "__main__":
    unittest.main()
