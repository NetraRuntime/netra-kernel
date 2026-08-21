#!/usr/bin/env python3
"""Freeze one profiled gfx950 kernel from compiler assembly as a Netra template."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


_REL32 = re.compile(r"([A-Za-z_.$][A-Za-z0-9_.$]+)@rel32")


def _function_region(lines: list[str], symbol: str) -> tuple[int, int]:
    protected = next(
        index
        for index, line in enumerate(lines)
        if line.startswith(f"\t.protected\t{symbol}")
    )
    start = protected - 1
    if not lines[start].startswith("\t.section\t.text"):
        raise ValueError(f"missing text section before {symbol}")
    size = next(
        index
        for index, line in enumerate(lines[protected:], protected)
        if line.startswith(f"\t.size\t{symbol},")
    )
    end = next(
        (
            index - 1
            for index, line in enumerate(lines[size + 1 :], size + 1)
            if line.startswith("\t.section\t.text")
        ),
        len(lines) - 1,
    )
    return start, end


def _object_region(lines: list[str], symbol: str) -> tuple[int, int]:
    protected = next(
        index
        for index, line in enumerate(lines)
        if line.startswith(f"\t.protected\t{symbol}")
    )
    start = protected
    end = next(
        index
        for index, line in enumerate(lines[protected:], protected)
        if line.startswith(f"\t.size\t{symbol},")
    )
    return start, end


def _metadata(symbol: str, *, lds: int, sgprs: int, vgprs: int) -> str:
    return f"""
\t.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .offset:         0
        .size:           88
        .value_kind:     by_value
    .group_segment_fixed_size: {lds}
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           {symbol}
    .private_segment_fixed_size: 0
    .sgpr_count:     {sgprs}
    .sgpr_spill_count: 0
    .symbol:         {symbol}\\().kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     {vgprs}
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...
\t.end_amdgpu_metadata
""".strip("\n")


def extract(
    source: Path,
    output: Path,
    *,
    symbol: str,
    macro: str,
    requirements: tuple[tuple[str, int], ...],
    lds: int,
    sgprs: int,
    vgprs: int,
) -> None:
    lines = source.read_text(encoding="utf-8").splitlines()
    start, end = _function_region(lines, symbol)
    body = "\n".join(lines[start : end + 1])
    dependencies = sorted(set(_REL32.findall(body)))
    objects: list[str] = []
    replacements = {symbol: r"\symbol"}
    for index, dependency in enumerate(dependencies):
        object_start, object_end = _object_region(lines, dependency)
        objects.append("\n".join(lines[object_start : object_end + 1]))
        replacements[dependency] = f".Lnetra_dense_constant_{index}"
    payload = "\n".join((body, *objects))
    for original in sorted(replacements, key=len, reverse=True):
        payload = payload.replace(original, replacements[original])
    # LLVM's integrated assembler requires an explicit macro-token boundary
    # when a substituted symbol is immediately followed by a dot.
    payload = payload.replace(r"\symbol.", r"\symbol\().")
    required = "\n".join(
        f"\tNETRA_REQUIRE_EQ {name}, {value}" for name, value in requirements
    )
    rendered = f"""// SPDX-License-Identifier: MIT
// Model-independent, fixed-contract gfx950 schedule frozen from profiled machine code.
\t.include "kernels/gfx950/templates/common/primitives.inc"
\tNETRA_GFX950_MODULE_HEADER 6
\t.macro {macro} symbol
\tNETRA_REQUIRE_GFX950_WAVE64
{required}
{payload}
{_metadata(r"\symbol", lds=lds, sgprs=sgprs, vgprs=vgprs)}
\t.endm
"""
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--symbol", required=True)
    parser.add_argument("--macro", required=True)
    parser.add_argument("--require", action="append", default=[])
    parser.add_argument("--lds", type=int, required=True)
    parser.add_argument("--sgprs", type=int, required=True)
    parser.add_argument("--vgprs", type=int, required=True)
    args = parser.parse_args()
    requirements = tuple(
        (name, int(value))
        for item in args.require
        for name, value in (item.split("=", 1),)
    )
    extract(
        args.input,
        args.output,
        symbol=args.symbol,
        macro=args.macro,
        requirements=requirements,
        lds=args.lds,
        sgprs=args.sgprs,
        vgprs=args.vgprs,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
