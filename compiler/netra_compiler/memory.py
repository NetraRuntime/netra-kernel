from __future__ import annotations

from dataclasses import dataclass

from .errors import ValidationError


U64_MAX = (1 << 64) - 1


def checked_mul(*values: int) -> int:
    result = 1
    for value in values:
        if value < 0 or (value and result > U64_MAX // value):
            raise ValidationError("uint64 buffer-size overflow")
        result *= value
    return result


def align_up(value: int, alignment: int) -> int:
    if alignment <= 0 or alignment & (alignment - 1):
        raise ValidationError("alignment must be a power of two")
    if value > U64_MAX - (alignment - 1):
        raise ValidationError("uint64 alignment overflow")
    return (value + alignment - 1) & -alignment


@dataclass(frozen=True)
class BufferRequest:
    name: str
    size: int
    alignment: int
    first_use: int
    last_use: int
    persistent: bool = False
    graph_stable: bool = True
    alias_of: str | None = None


@dataclass(frozen=True)
class BufferAllocation:
    name: str
    offset: int | None
    size: int
    alignment: int
    first_use: int
    last_use: int
    persistent: bool
    graph_stable: bool
    alias_of: str | None

    def to_dict(self) -> dict[str, object]:
        return self.__dict__.copy()


def plan_buffers(requests: tuple[BufferRequest, ...]) -> dict[str, object]:
    names = {r.name for r in requests}
    if len(names) != len(requests):
        raise ValidationError("duplicate memory buffer name")
    allocations: list[BufferAllocation] = []
    workspace: list[BufferAllocation] = []
    high_water = 0
    ordered = sorted(
        requests,
        key=lambda request: (request.alias_of is not None, request.first_use, request.name),
    )
    for req in ordered:
        if req.size < 0 or req.size > U64_MAX or req.first_use > req.last_use:
            raise ValidationError(f"invalid memory request: {req.name}")
        if req.alias_of:
            target = next((a for a in allocations if a.name == req.alias_of), None)
            if (
                target is None
                or target.persistent
                or target.alias_of is not None
                or req.size > target.size
                or target.offset is None
                or target.offset % req.alignment
            ):
                raise ValidationError(f"illegal alias for {req.name}")
            allocation = BufferAllocation(req.name, target.offset, req.size, req.alignment,
                                          req.first_use, req.last_use, False,
                                          req.graph_stable, req.alias_of)
        elif req.persistent:
            allocation = BufferAllocation(req.name, None, req.size, req.alignment,
                                          req.first_use, req.last_use, True,
                                          req.graph_stable, None)
        else:
            offset = 0
            while True:
                offset = align_up(offset, req.alignment)
                conflict = next((a for a in workspace if not (
                    req.last_use < a.first_use or req.first_use > a.last_use
                ) and not (offset + req.size <= (a.offset or 0) or offset >= (a.offset or 0) + a.size)), None)
                if conflict is None:
                    break
                offset = (conflict.offset or 0) + conflict.size
            end = offset + req.size
            if end > U64_MAX:
                raise ValidationError("uint64 workspace offset overflow")
            high_water = max(high_water, end)
            allocation = BufferAllocation(req.name, offset, req.size, req.alignment,
                                          req.first_use, req.last_use, False,
                                          req.graph_stable, None)
            workspace.append(allocation)
        allocations.append(allocation)
    return {
        "format": "netra-memory-plan-1",
        "workspace_bytes": align_up(high_water, 256),
        "workspace_alignment": 256,
        "buffers": [a.to_dict() for a in sorted(allocations, key=lambda a: a.name)],
    }
