from __future__ import annotations

import unittest

from netra_compiler.errors import ValidationError
from netra_compiler.memory import BufferRequest, U64_MAX, checked_mul, plan_buffers


class MemoryTest(unittest.TestCase):
    def test_reuses_non_overlapping_lifetimes(self) -> None:
        plan = plan_buffers((BufferRequest("a", 512, 256, 0, 1),
                             BufferRequest("b", 512, 256, 2, 3),
                             BufferRequest("c", 256, 256, 1, 2)))
        offsets = {b["name"]: b["offset"] for b in plan["buffers"]}
        self.assertEqual(offsets["a"], offsets["b"])
        self.assertNotEqual(offsets["a"], offsets["c"])

    def test_overflow_and_illegal_alias(self) -> None:
        with self.assertRaises(ValidationError): checked_mul(U64_MAX, 2)
        with self.assertRaises(ValidationError):
            plan_buffers((BufferRequest("a", 4, 4, 0, 1, persistent=True),
                          BufferRequest("b", 4, 4, 0, 1, alias_of="a")))

    def test_alias_uses_target_offset_and_cannot_chain(self) -> None:
        plan = plan_buffers((
            BufferRequest("storage", 1024, 256, 0, 2),
            BufferRequest("view", 512, 256, 1, 2, alias_of="storage"),
        ))
        buffers = {item["name"]: item for item in plan["buffers"]}
        self.assertEqual(buffers["view"]["offset"], buffers["storage"]["offset"])
        with self.assertRaises(ValidationError):
            plan_buffers((
                BufferRequest("storage", 1024, 256, 0, 2),
                BufferRequest("view", 512, 256, 1, 2, alias_of="storage"),
                BufferRequest("view2", 256, 256, 1, 2, alias_of="view"),
            ))


if __name__ == "__main__": unittest.main()
