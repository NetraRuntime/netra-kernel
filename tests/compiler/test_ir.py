from __future__ import annotations

import json
import unittest

from netra_compiler.errors import ValidationError
from netra_compiler.ir import Graph, Operation, Tensor
from netra_compiler.types import DType


class IrTest(unittest.TestCase):
    def test_round_trip_preserves_numerical_contract(self) -> None:
        graph = Graph("g", (Tensor("x", ("M", 128), DType.BF16, "row", "input"),
                            Tensor("y", ("M", 128), DType.BF16, "row", "output")),
                      (Operation("norm", "normalization", ("x",), ("y",),
                                 {"placeholder": True}, {"reduction_order": "fixed", "rounding": "rne"}),),
                      ("x",), ("y",))
        restored = Graph.from_dict(json.loads(graph.serialize()))
        self.assertEqual(restored.serialize(), graph.serialize())

    def test_operation_contract_is_deeply_immutable(self) -> None:
        operation = Operation(
            "fixed",
            "fixed_kernel",
            ("x",),
            ("y",),
            {"semantics": {"layouts": "layout.v1"}, "grid": [1, 1, 1]},
            {"order": ["a", "b"]},
        )
        with self.assertRaises(TypeError):
            operation.attributes["new"] = 1
        with self.assertRaises(TypeError):
            operation.attributes["semantics"]["layouts"] = "changed.v1"
        self.assertIsInstance(operation.attributes["grid"], tuple)
        self.assertIsInstance(operation.numerical["order"], tuple)

    def test_rejects_duplicate_operations_dangling_alias_and_unordered_use(self) -> None:
        x = Tensor("x", (1,), DType.BF16, "row", "input")
        y = Tensor("y", (1,), DType.BF16, "row", "output")
        operation = Operation("copy", "copy", ("x",), ("y",))
        with self.assertRaisesRegex(ValidationError, "duplicate operation name"):
            Graph("g", (x, y), (operation, operation), ("x",), ("y",))
        with self.assertRaisesRegex(ValidationError, "aliases an unknown tensor"):
            Graph(
                "g",
                (x, Tensor("view", (1,), DType.BF16, "row", alias_of="missing")),
                (),
                ("x",),
                (),
            )
        temp = Tensor("temp", (1,), DType.BF16, "row")
        with self.assertRaisesRegex(ValidationError, "before production"):
            Graph(
                "g",
                (x, y, temp),
                (
                    Operation("consume", "copy", ("temp",), ("y",)),
                    Operation("produce", "copy", ("x",), ("temp",)),
                ),
                ("x",),
                ("y",),
            )


if __name__ == "__main__": unittest.main()
