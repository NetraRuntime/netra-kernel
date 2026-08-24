from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class DisassemblyComparisonTest(unittest.TestCase):
    def test_path_only_header_difference_is_ignored(self) -> None:
        body = "\nDisassembly of section .text:\n0000: aa bb v_mov_b32_e32 v0, 0\n"
        metadata = "vgpr_count: 3\nsgpr_count: 4\nkernarg_segment_size: 40\nwavefront_size: 64\n"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            golden, generated = root / "golden.dis", root / "generated.dis"
            golden.write_text("/golden/a.hsaco: file format elf64-amdgpu\n" + body)
            generated.write_text("build/a.hsaco: file format elf64-amdgpu\n" + body)
            gm, nm = root / "golden.meta", root / "generated.meta"
            gm.write_text(metadata); nm.write_text(metadata)
            result = subprocess.run([
                "python3", str(ROOT / "tools/compiler/compare_disassembly.py"),
                "--golden", str(golden), "--generated", str(generated),
                "--golden-metadata", str(gm), "--generated-metadata", str(nm),
            ], check=True, text=True, stdout=subprocess.PIPE)
            data = json.loads(result.stdout)
            self.assertTrue(data["normalized_instructions_identical"])
            self.assertTrue(data["metadata_semantic_identical"])

    def test_text_identity_and_symbol_only_metadata_are_classified(self) -> None:
        body = "Disassembly of section .text:\n0000: aa bb s_endpgm\n"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            golden, generated = root / "golden.dis", root / "generated.dis"
            golden.write_text("0000 <golden>:\n" + body)
            generated.write_text("0000 <generated>:\n" + body)
            gt, nt = root / "golden.text", root / "generated.text"
            gt.write_bytes(b"same-machine-code")
            nt.write_bytes(b"same-machine-code")
            gm, nm = root / "golden.meta", root / "generated.meta"
            common = "vgpr_count: 30\nsgpr_count: 32\nkernarg_segment_size: 40\n"
            gm.write_text(common + ".name: golden\n.symbol: golden.kd\n")
            nm.write_text(common + ".name: generated\n.symbol: generated.kd\n")
            result = subprocess.run([
                "python3", str(ROOT / "tools/compiler/compare_disassembly.py"),
                "--golden", str(golden), "--generated", str(generated),
                "--golden-text", str(gt), "--generated-text", str(nt),
                "--golden-metadata", str(gm), "--generated-metadata", str(nm),
            ], check=True, text=True, stdout=subprocess.PIPE)
            data = json.loads(result.stdout)
            self.assertTrue(data["text_byte_identical"])
            self.assertFalse(data["metadata_byte_identical"])
            self.assertTrue(data["metadata_semantic_identical"])
            self.assertFalse(data["instruction_difference"])


if __name__ == "__main__": unittest.main()
