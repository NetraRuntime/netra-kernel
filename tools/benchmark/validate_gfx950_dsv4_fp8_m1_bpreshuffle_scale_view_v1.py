#!/usr/bin/env python3
"""Independent storage/stride/lifetime checks for the Netra M=1 layout op."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import torch


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", required=True, type=Path)
    parser.add_argument("--json", required=True, type=Path)
    args = parser.parse_args()

    torch.ops.load_library(str(args.library))
    assert (
        torch.ops.netra.dsv4_fp8_m1_bpreshuffle_scale_view_v1_abi_version()
        == 1
    )

    cases = []
    for groups in (1, 2, 12, 16, 24, 32, 64):
        source = torch.arange(groups, dtype=torch.float32, device="cuda").view(1, groups)
        alias = torch.ops.netra.dsv4_fp8_m1_bpreshuffle_scale_view_v1(source)
        materialized = source.t().contiguous().t()
        assert alias.data_ptr() == source.data_ptr()
        assert alias.untyped_storage().data_ptr() == source.untyped_storage().data_ptr()
        assert alias.storage_offset() == source.storage_offset()
        assert alias.shape == source.shape
        assert alias.dtype == source.dtype
        assert alias.stride() == (1, 1)
        # Singleton dimensions permit multiple valid strides.  Current PyTorch
        # elides contiguous() here and can retain (G, 1), so byte/value parity
        # rather than stride equality is the independent materialized oracle.
        torch.testing.assert_close(alias, materialized, rtol=0, atol=0)
        source.add_(7)
        torch.testing.assert_close(alias, source, rtol=0, atol=0)
        cases.append({"groups": groups, "status": "pass"})

    # An aligned sliced row proves non-zero storage-offset ownership and aliasing.
    backing = torch.arange(80, dtype=torch.float32, device="cuda")
    source = backing[4:36].view(1, 32)
    alias = torch.ops.netra.dsv4_fp8_m1_bpreshuffle_scale_view_v1(source)
    assert alias.data_ptr() == source.data_ptr()
    assert alias.storage_offset() == source.storage_offset()

    rejected = []
    for name, tensor in (
        ("m_ge_2", torch.empty((2, 32), dtype=torch.float32, device="cuda")),
        ("wrong_dtype", torch.empty((1, 32), dtype=torch.float16, device="cuda")),
        ("rank_one", torch.empty((32,), dtype=torch.float32, device="cuda")),
        ("too_many_groups", torch.empty((1, 65), dtype=torch.float32, device="cuda")),
        ("unaligned", torch.empty((1, 33), dtype=torch.float32, device="cuda")[:, 1:]),
    ):
        try:
            torch.ops.netra.dsv4_fp8_m1_bpreshuffle_scale_view_v1(tensor)
        except RuntimeError:
            rejected.append(name)
        else:
            raise AssertionError(f"invalid case accepted: {name}")

    result = {
        "abi_version": 1,
        "cases": cases,
        "storage_alias": True,
        "zero_copy": True,
        "consumer_strides": [1, 1],
        "rejected": rejected,
    }
    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.json.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
