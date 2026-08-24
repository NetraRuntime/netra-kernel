from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class RuntimeHotPathTest(unittest.TestCase):
    def test_runtime_does_not_reallocate_code_object_fixed_lds(self) -> None:
        source = (ROOT / "runtime/gfx950/engine/netra_engine.hip").read_text()
        self.assertIn("op.dynamic_lds_bytes, stream", source)
        self.assertNotIn("op.lds_bytes, stream", source)

    def test_launch_has_no_control_plane_work(self) -> None:
        source = (ROOT / "runtime/gfx950/engine/netra_engine.hip").read_text()
        match = re.search(r'extern "C" netra_status_t netra_engine_launch\(.*?\n\}', source, re.S)
        self.assertIsNotNone(match)
        launch = match.group(0)
        for forbidden in ("ifstream", "getenv", "hipMalloc", "hipFree", "hipModuleLoad",
                          "hipModuleGetFunction", "hipDeviceSynchronize", "hipStreamSynchronize",
                          "Parser(", "new "):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, launch)
        self.assertIn("hipGetDevice", launch)

    def test_fixed_operation_launch_has_no_control_plane_work(self) -> None:
        source = (ROOT / "runtime/gfx950/engine/netra_engine.hip").read_text()
        match = re.search(
            r'extern "C" netra_status_t netra_engine_launch_operation\(.*?\n\}',
            source,
            re.S,
        )
        self.assertIsNotNone(match)
        launch = match.group(0)
        for forbidden in (
            "ifstream", "getenv", "hipMalloc", "hipFree", "hipModuleLoad",
            "hipModuleGetFunction", "hipDeviceSynchronize", "hipStreamSynchronize",
            "Parser(", "new ",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, launch)

    def test_bound_operation_launch_has_no_control_plane_work(self) -> None:
        source = (ROOT / "runtime/gfx950/engine/netra_engine.hip").read_text()
        match = re.search(
            r'extern "C" netra_status_t netra_engine_launch_operation_bound\(.*?\n\}',
            source,
            re.S,
        )
        self.assertIsNotNone(match)
        launch = match.group(0)
        for forbidden in (
            "ifstream", "getenv", "hipMalloc", "hipFree", "hipModuleLoad",
            "hipModuleGetFunction", "hipDeviceSynchronize", "hipStreamSynchronize",
            "Parser(", "new ", "std::map", "std::string",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, launch)
        self.assertIn("std::array<void*, 16> launch_values{}", launch)
        self.assertNotIn("op.argument_values[bindings", launch)

    def test_direct_records_are_immutable_before_concurrent_launch(self) -> None:
        source = (ROOT / "runtime/gfx950/engine/netra_engine.hip").read_text()
        self.assertIn("netra_engine_finalize_bindings", source)
        self.assertIn("bindings are finalized and immutable", source)
        launch = re.search(
            r'extern "C" netra_status_t netra_engine_launch\(.*?\n\}', source, re.S
        ).group(0)
        self.assertIn("bindings_finalized.load", launch)


if __name__ == "__main__": unittest.main()
