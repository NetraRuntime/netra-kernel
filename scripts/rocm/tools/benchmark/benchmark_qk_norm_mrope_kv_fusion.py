#!/usr/bin/env python3
"""Correctness and HIP-event benchmark for the raw gfx1151 attention-prep fusion."""
import argparse
import ctypes
import json
import os
import time
from pathlib import Path
from statistics import mean, median

import torch

from sglang.kernels.ops.attention.rotary_triton import triton_mrope_fused
from sglang.kernels.ops.kvcache.kvcache import store_cache
from sglang.srt.models.utils import fused_qk_gemma_rmsnorm_with_gate

H_Q = 16
H_KV = 2
D = 256
ROTARY = 64
ROW = 9216
EPS = 1.0e-6
SECTIONS = [11, 11, 10]


def ptr(t):
    return ctypes.c_void_p(t.data_ptr())


def make_cache(max_pos, device):
    inv = 1.0 / (10000000.0 ** (torch.arange(0, ROTARY, 2, dtype=torch.float32) / ROTARY))
    pos = torch.arange(max_pos, dtype=torch.float32)
    freq = torch.einsum("i,j->ij", pos, inv)
    return torch.cat((freq.cos(), freq.sin()), dim=-1).to(device=device, dtype=torch.bfloat16)


def bind(lib_path, hsaco_path):
    lib = ctypes.CDLL(str(lib_path))
    lib.netra_qk_mrope_kv_init.argtypes = [ctypes.c_char_p]
    lib.netra_qk_mrope_kv_init.restype = ctypes.c_int
    args = [ctypes.c_void_p] * 11 + [ctypes.c_uint32, ctypes.c_void_p]
    lib.netra_qk_mrope_kv.argtypes = args
    lib.netra_qk_mrope_kv.restype = ctypes.c_int
    status = lib.netra_qk_mrope_kv_init(os.fsencode(hsaco_path))
    if status:
        raise RuntimeError(f"hipModuleLoad failed: {status}")
    return lib


def launch(lib, tensors, tokens):
    status = lib.netra_qk_mrope_kv(
        ptr(tensors["qkv"]), ptr(tensors["q"]), ptr(tensors["k"]), ptr(tensors["gate"]),
        ptr(tensors["qw"]), ptr(tensors["kw"]), ptr(tensors["cos"]), ptr(tensors["positions"]),
        ptr(tensors["kc"]), ptr(tensors["vc"]), ptr(tensors["loc"]), tokens,
        ctypes.c_void_p(torch.cuda.current_stream().cuda_stream),
    )
    if status:
        raise RuntimeError(f"hipModuleLaunchKernel failed: {status}")


def baseline_once(t):
    m = t["qkv"].shape[0]
    q, k, gate = fused_qk_gemma_rmsnorm_with_gate(
        t["qkv"][:, :8192], t["qkv"][:, 8192:8704], t["qw"], t["kw"], EPS, D, H_Q
    )
    q = q.view(m, H_Q * D)
    k = k.view(m, H_KV * D)
    gate = gate.view(m, H_Q * D)
    triton_mrope_fused(
        q, k, t["cos"], t["positions"], SECTIONS, D, ROTARY, True, False, True, t["axis"]
    )
    store_cache(
        k.view(m, H_KV * D), t["qkv"][:, 8704:9216], t["kc"], t["vc"], t["loc"],
        row_bytes=1024, num_split=2, size_limit=t["kc"].shape[0],
    )
    return q, k, gate


def compare(name, got, ref):
    g = got.float()
    r = ref.float()
    diff = (g - r).abs()
    exact = torch.equal(got, ref)
    return {
        "name": name,
        "exact": exact,
        "max_abs": diff.max().item(),
        "mean_abs": diff.mean().item(),
        "got_abs_mean": g.abs().mean().item(),
        "ref_abs_mean": r.abs().mean().item(),
        "got_min": g.min().item(),
        "got_max": g.max().item(),
        "ref_min": r.min().item(),
        "ref_max": r.max().item(),
        "mismatch": int((got != ref).sum().item()),
        "elements": got.numel(),
    }


def event_time(fn, reps):
    values = []
    for _ in range(reps):
        start = torch.cuda.Event(enable_timing=True)
        end = torch.cuda.Event(enable_timing=True)
        start.record()
        keep = fn()
        end.record()
        end.synchronize()
        values.append(start.elapsed_time(end))
    return values


def run_shape(lib, tokens, warmup, reps, multimodal, graph):
    device = torch.device("cuda")
    gen = torch.Generator(device=device).manual_seed(20260730 + tokens + int(multimodal))
    max_pos = max(32768, tokens + 1024)
    rows = tokens + 31
    qkv = (torch.randn((tokens, ROW), device=device, dtype=torch.bfloat16, generator=gen) * 0.25)
    qw = (torch.randn((D,), device=device, dtype=torch.bfloat16, generator=gen) * 0.05)
    kw = (torch.randn((D,), device=device, dtype=torch.bfloat16, generator=gen) * 0.05)
    base_pos = torch.arange(tokens, device=device, dtype=torch.int64)
    if multimodal:
        positions = torch.stack((base_pos, (base_pos * 3 + 7) % max_pos, (base_pos * 5 + 11) % max_pos))
    else:
        positions = base_pos.repeat(3, 1)
    loc = torch.randperm(rows, device=device, generator=gen, dtype=torch.int64)[:tokens]
    common = {
        "qkv": qkv, "qw": qw, "kw": kw, "cos": make_cache(max_pos, device),
        "positions": positions.contiguous(), "loc": loc.contiguous(),
        "axis": torch.zeros(1, device=device, dtype=torch.int64),
    }
    base = dict(common)
    base["kc"] = torch.full((rows, H_KV * D), float("nan"), device=device, dtype=torch.bfloat16)
    base["vc"] = torch.full_like(base["kc"], float("nan"))
    q_ref, k_ref, gate_ref = baseline_once(base)
    cand = dict(common)
    cand.update({
        "q": torch.empty((tokens, H_Q * D), device=device, dtype=torch.bfloat16),
        "k": torch.empty((tokens, H_KV * D), device=device, dtype=torch.bfloat16),
        "gate": torch.empty((tokens, H_Q * D), device=device, dtype=torch.bfloat16),
        "kc": torch.full((rows, H_KV * D), float("nan"), device=device, dtype=torch.bfloat16),
        "vc": torch.full((rows, H_KV * D), float("nan"), device=device, dtype=torch.bfloat16),
    })
    launch(lib, cand, tokens)
    torch.cuda.synchronize()
    checks = [
        compare("q", cand["q"], q_ref),
        compare("k", cand["k"], k_ref),
        compare("gate", cand["gate"], gate_ref),
        compare("k_cache_selected", cand["kc"][loc], base["kc"][loc]),
        compare("v_cache_selected", cand["vc"][loc], base["vc"][loc]),
    ]
    ok = all(x["exact"] for x in checks)
    for _ in range(warmup):
        baseline_once(base)
        launch(lib, cand, tokens)
    torch.cuda.synchronize()
    baseline_ms = event_time(lambda: baseline_once(base), reps)
    candidate_ms = event_time(lambda: launch(lib, cand, tokens), reps)
    graph_result = None
    if graph:
        capture_stream = torch.cuda.Stream()
        capture_stream.wait_stream(torch.cuda.current_stream())
        with torch.cuda.stream(capture_stream):
            for _ in range(warmup):
                launch(lib, cand, tokens)
        torch.cuda.current_stream().wait_stream(capture_stream)
        torch.cuda.synchronize()
        captured = torch.cuda.CUDAGraph()
        capture_start_ns = time.perf_counter_ns()
        with torch.cuda.graph(captured, stream=capture_stream):
            launch(lib, cand, tokens)
        torch.cuda.synchronize()
        capture_host_ms = (time.perf_counter_ns() - capture_start_ns) / 1.0e6

        cand["qkv"].copy_(
            torch.randn(
                (tokens, ROW),
                device=device,
                dtype=torch.bfloat16,
                generator=gen,
            )
            * 0.25
        )
        cand["kc"].fill_(float("nan"))
        cand["vc"].fill_(float("nan"))
        base["kc"].fill_(float("nan"))
        base["vc"].fill_(float("nan"))
        captured.replay()
        torch.cuda.synchronize()
        graph_q_ref, graph_k_ref, graph_gate_ref = baseline_once(base)
        torch.cuda.synchronize()
        graph_checks = [
            compare("q", cand["q"], graph_q_ref),
            compare("k", cand["k"], graph_k_ref),
            compare("gate", cand["gate"], graph_gate_ref),
            compare("k_cache_selected", cand["kc"][loc], base["kc"][loc]),
            compare("v_cache_selected", cand["vc"][loc], base["vc"][loc]),
        ]
        graph_ok = all(x["exact"] for x in graph_checks)
        graph_ms = event_time(captured.replay, reps)
        graph_result = {
            "correct_after_input_mutation": graph_ok,
            "checks": graph_checks,
            "capture_host_ms": capture_host_ms,
            "replay_hip_event_ms": {
                "mean": mean(graph_ms),
                "median": median(graph_ms),
                "samples": graph_ms,
            },
            "replay_overhead_hip_event_ms_mean": mean(graph_ms) - mean(candidate_ms),
        }
        ok = ok and graph_ok

    result = {
        "gfx": "gfx1151", "measurement": "measured", "tokens": tokens,
        "positions": "multimodal-3-axis" if multimodal else "text-identical-3-axis",
        "correct": ok, "checks": checks,
        "baseline_hip_event_ms": {"mean": mean(baseline_ms), "median": median(baseline_ms), "samples": baseline_ms},
        "candidate_hip_event_ms": {"mean": mean(candidate_ms), "median": median(candidate_ms), "samples": candidate_ms},
        "speedup_mean": mean(baseline_ms) / mean(candidate_ms),
        "speedup_median": median(baseline_ms) / median(candidate_ms),
    }
    if graph_result is not None:
        result["graph"] = graph_result
    return result


def main():
    ap = argparse.ArgumentParser()
    repo = Path(__file__).resolve().parents[4]
    build = repo / "build/experiments/qk-norm-mrope-kv-fusion"
    ap.add_argument("--tokens", type=int, nargs="+", default=[1, 12, 64, 1024])
    ap.add_argument("--warmup", type=int, default=3)
    ap.add_argument("--reps", type=int, default=9)
    ap.add_argument("--multimodal", action="store_true")
    ap.add_argument("--graph", action="store_true")
    ap.add_argument("--build-dir", type=Path, default=build)
    ap.add_argument("--output", type=Path)
    args = ap.parse_args()
    if torch.version.hip is None or torch.cuda.get_device_capability() != (11, 5):
        raise RuntimeError(f"requires gfx1151 ROCm; hip={torch.version.hip}, capability={torch.cuda.get_device_capability()}")
    stem = "qk_norm_mrope_gate_kv_store_gfx1151"
    lib = bind(args.build_dir / "libqk_norm_mrope_kv_fusion.so", args.build_dir / f"{stem}.hsaco")
    result = {
        "gfx": "gfx1151", "measurement": "measured", "device": torch.cuda.get_device_name(),
        "torch_hip": torch.version.hip, "results": [run_shape(lib, m, args.warmup, args.reps, args.multimodal, args.graph) for m in args.tokens],
    }
    text = json.dumps(result, indent=2)
    print(text)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text + "\n")
    if not all(x["correct"] for x in result["results"]):
        raise SystemExit(2)


if __name__ == "__main__":
    main()
