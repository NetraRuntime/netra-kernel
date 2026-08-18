from __future__ import annotations

import dataclasses
import unittest
from pathlib import Path

from netra_compiler.backends.gfx950.catalog import load_fixed_tactic_catalog
from netra_compiler.contracts import Workspace
from netra_compiler.engine import _operation_records
from netra_compiler.frontends import load_model
from netra_compiler.ir import Graph, Operation
from netra_compiler.planner import plan_graph
from netra_compiler.profiles import standard_profiles


ROOT = Path(__file__).resolve().parents[2]


class WorkspaceIntegrationTest(unittest.TestCase):
    def test_operation_and_kernarg_use_the_planned_workspace_offset(self) -> None:
        graph, _ = load_model(
            ROOT / "tests/compiler/fixtures/llama-moe-gate-up-exact.json"
        )
        tactic = next(
            item for item in load_fixed_tactic_catalog(ROOT)
            if item.name == "gfx950.moe_gate_up_decode_m1"
        )
        tactic = dataclasses.replace(tactic, workspace=Workspace(8192, 256))
        original = graph.operations[0]
        attributes = original.to_dict()["attributes"]
        attributes["arguments"][0]["source"] = "workspace"
        attributes["arguments"][0]["workspace_offset"] = 256
        operation = Operation(
            original.name,
            original.kind,
            original.inputs,
            original.outputs,
            attributes,
            original.to_dict()["numerical"],
        )
        graph = Graph(
            graph.name,
            graph.tensors,
            (operation,),
            graph.inputs,
            graph.outputs,
            graph.state,
        )
        plan = plan_graph(
            graph,
            standard_profiles()[0],
            "gfx950",
            fixed_registry=(tactic,),
        )
        records = _operation_records(plan, {
            "buffers": [{"name": f"{operation.name}.workspace", "offset": 4096}],
        })
        self.assertEqual(records[0]["workspace_offset"], 4096)
        self.assertEqual(records[0]["arguments"][0]["workspace_offset"], 4352)


if __name__ == "__main__":
    unittest.main()
