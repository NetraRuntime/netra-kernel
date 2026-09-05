#!/usr/bin/env python3
"""Independent PyTorch correctness and graph gates for the Netra DSV4 router."""

from __future__ import annotations

import argparse
import ctypes
import json
import math
from pathlib import Path

import torch


class Bridge:
    def __init__(self, library: Path, hsaco: Path) -> None:
        self.lib = ctypes.CDLL(str(library))
        prefix = "netra_dsv4_router_shared_topk_bf16_v1"
        self.abi = getattr(self.lib, f"{prefix}_abi_version")
        self.abi.argtypes = []
        self.abi.restype = ctypes.c_uint32
        self.load = getattr(self.lib, f"{prefix}_load")
        self.load.argtypes = [ctypes.c_char_p]
        self.load.restype = ctypes.c_int
        self.launch_raw = getattr(self.lib, f"{prefix}_launch")
        self.launch_raw.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_uint32,
            ctypes.c_void_p,
        ]
        self.launch_raw.restype = ctypes.c_int
        self.last_error = getattr(self.lib, f"{prefix}_last_error")
        self.last_error.argtypes = []
        self.last_error.restype = ctypes.c_char_p
        self.check(self.load(str(hsaco).encode()), "load")
        if self.abi() != 1:
            raise RuntimeError(f"unexpected ABI version {self.abi()}")

    def check(self, status: int, operation: str) -> None:
        if status == 0:
            return
        raw = self.last_error()
        detail = raw.decode() if raw else f"status={status}"
        raise RuntimeError(f"{operation}: {detail}")

    def launch(
        self,
        scores: torch.Tensor,
        bias: torch.Tensor,
        weights: torch.Tensor,
        indices: torch.Tensor,
        stream: torch.cuda.Stream,
    ) -> None:
        self.check(
            self.launch_raw(
                scores.data_ptr(),
                bias.data_ptr(),
                weights.data_ptr(),
                indices.data_ptr(),
                scores.shape[0],
                stream.cuda_stream,
            ),
            "launch",
        )


def reference(scores: torch.Tensor, bias: torch.Tensor) -> tuple[torch.Tensor, torch.Tensor]:
    activated = torch.nn.functional.softplus(scores.float()).sqrt()
    ranked = activated + bias.float()
    ranked = torch.where(torch.isnan(ranked), torch.full_like(ranked, -1.0e30), ranked)
    # stable=True plus the ascending expert axis independently defines lowest-ID ties.
    indices = torch.argsort(ranked, dim=1, descending=True, stable=True)[:, :6]
    routed = torch.gather(activated, 1, indices)
    routed_sum = routed.sum(dim=1, keepdim=True)
    norm = torch.where(routed_sum > 0, routed_sum, torch.ones_like(routed_sum))
    routed = routed / norm * 1.5
    shared = (routed_sum / 1.5) / norm * 1.5
    weights = torch.cat((routed, shared), dim=1)
    shared_ids = torch.full((scores.shape[0], 1), 256, dtype=torch.int64, device=scores.device)
    return weights, torch.cat((indices, shared_ids), dim=1).to(torch.int32)


def make_case(rows: int, seed: int) -> tuple[torch.Tensor, torch.Tensor]:
    generator = torch.Generator(device="cpu").manual_seed(seed)
    scores = torch.randn((rows, 256), generator=generator, dtype=torch.float32).to(torch.bfloat16)
    bias = (torch.randn((256,), generator=generator, dtype=torch.float32) * 0.125).to(torch.bfloat16)
    return scores.cuda(), bias.cuda()


def compare_case(bridge: Bridge, rows: int, seed: int, stream: torch.cuda.Stream) -> dict:
    scores, bias = make_case(rows, seed)
    weights = torch.empty((rows, 7), dtype=torch.float32, device="cuda")
    indices = torch.empty((rows, 7), dtype=torch.int32, device="cuda")
    with torch.cuda.stream(stream):
        bridge.launch(scores, bias, weights, indices, stream)
    stream.synchronize()
    ref_weights, ref_indices = reference(scores, bias)
    torch.cuda.synchronize()
    if not torch.equal(indices, ref_indices):
        mismatch = (indices != ref_indices).nonzero()[0].tolist()
        raise AssertionError(f"rows={rows}: index mismatch at {mismatch}")
    finite = torch.isfinite(ref_weights)
    if not torch.allclose(weights[finite], ref_weights[finite], rtol=8e-4, atol=2e-5):
        delta = (weights[finite] - ref_weights[finite]).abs().max().item()
        raise AssertionError(f"rows={rows}: weight max_abs={delta}")
    if not torch.equal(torch.isnan(weights), torch.isnan(ref_weights)):
        raise AssertionError(f"rows={rows}: NaN mask mismatch")
    return {
        "rows": rows,
        "max_abs_weight": float((weights[finite] - ref_weights[finite]).abs().max().item()),
        "indices_exact": True,
    }


def adversarial_cases(bridge: Bridge, stream: torch.cuda.Stream) -> list[str]:
    passed = []
    for name, scores, bias in (
        ("ties", torch.zeros((1, 256), dtype=torch.bfloat16), torch.zeros(256, dtype=torch.bfloat16)),
        ("negative_infinity", torch.full((1, 256), -math.inf, dtype=torch.bfloat16), torch.zeros(256, dtype=torch.bfloat16)),
        ("all_nan", torch.full((1, 256), math.nan, dtype=torch.bfloat16), torch.zeros(256, dtype=torch.bfloat16)),
    ):
        scores = scores.cuda()
        bias = bias.cuda()
        weights = torch.empty((1, 7), dtype=torch.float32, device="cuda")
        indices = torch.empty((1, 7), dtype=torch.int32, device="cuda")
        bridge.launch(scores, bias, weights, indices, stream)
        stream.synchronize()
        ref_weights, ref_indices = reference(scores, bias)
        torch.cuda.synchronize()
        if not torch.equal(indices, ref_indices):
            raise AssertionError(f"{name}: index mismatch")
        if not torch.equal(torch.isnan(weights), torch.isnan(ref_weights)):
            raise AssertionError(f"{name}: NaN mismatch")
        finite = torch.isfinite(ref_weights)
        if not torch.allclose(weights[finite], ref_weights[finite], rtol=8e-4, atol=2e-5):
            raise AssertionError(f"{name}: finite weight mismatch")
        passed.append(name)
    return passed


def graph_gate(bridge: Bridge) -> None:
    scores, bias = make_case(17, 20260831)
    weights = torch.empty((17, 7), dtype=torch.float32, device="cuda")
    indices = torch.empty((17, 7), dtype=torch.int32, device="cuda")
    stream = torch.cuda.Stream()
    stream.wait_stream(torch.cuda.current_stream())
    with torch.cuda.stream(stream):
        for _ in range(3):
            bridge.launch(scores, bias, weights, indices, stream)
        graph = torch.cuda.CUDAGraph()
        with torch.cuda.graph(graph, stream=stream):
            bridge.launch(scores, bias, weights, indices, stream)
        graph.replay()
        graph.replay()
    stream.synchronize()
    ref_weights, ref_indices = reference(scores, bias)
    torch.cuda.synchronize()
    if not torch.equal(indices, ref_indices):
        raise AssertionError("graph replay index mismatch")
    if not torch.allclose(weights, ref_weights, rtol=8e-4, atol=2e-5):
        raise AssertionError("graph replay weight mismatch")


def invalid_abi_gate(bridge: Bridge) -> list[str]:
    scores, bias = make_case(1, 7)
    weights = torch.empty((1, 7), dtype=torch.float32, device="cuda")
    indices = torch.empty((1, 7), dtype=torch.int32, device="cuda")
    stream = torch.cuda.current_stream()
    rejected = []
    for name, rows, score_ptr in (("rows_zero", 0, scores.data_ptr()), ("rows_8193", 8193, scores.data_ptr()), ("null_scores", 1, 0)):
        status = bridge.launch_raw(score_ptr, bias.data_ptr(), weights.data_ptr(), indices.data_ptr(), rows, stream.cuda_stream)
        if status == 0:
            raise AssertionError(f"invalid ABI case accepted: {name}")
        rejected.append(name)
    return rejected


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bridge", type=Path, required=True)
    parser.add_argument("--hsaco", type=Path, required=True)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()
    if not torch.cuda.is_available() or torch.version.hip is None:
        raise RuntimeError("ROCm GPU is required")
    props = torch.cuda.get_device_properties(0)
    arch = getattr(props, "gcnArchName", "")
    if "gfx950" not in arch:
        raise RuntimeError(f"gfx950 is required, got {arch}")
    bridge = Bridge(args.bridge, args.hsaco)
    stream = torch.cuda.Stream()
    rows_to_test = (1, 3, 7, 17, 255, 256, 257, 1000, 7000, 8000, 8192)
    results = [compare_case(bridge, rows, 20260831 + rows, stream) for rows in rows_to_test]
    # Repeated deterministic launch on a non-default stream.
    results.append(compare_case(bridge, 17, 20260848, stream))
    results.append(compare_case(bridge, 17, 20260848, stream))
    adversarial = adversarial_cases(bridge, stream)
    graph_gate(bridge)
    invalid = invalid_abi_gate(bridge)
    report = {
        "abi_version": bridge.abi(),
        "arch": arch,
        "operator": "netra_dsv4_router_shared_topk_bf16_v1",
        "cases": results,
        "adversarial": adversarial,
        "non_default_stream": "pass",
        "repeated_launch": "pass",
        "graph_capture_replay": "pass",
        "invalid_abi_rejections": invalid,
    }
    rendered = json.dumps(report, indent=2, sort_keys=True)
    print(rendered)
    if args.json:
        args.json.write_text(rendered + "\n")


if __name__ == "__main__":
    main()
