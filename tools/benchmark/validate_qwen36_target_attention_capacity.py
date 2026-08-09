#!/usr/bin/env python3
"""Validate the raw Qwen3.6 target-attention ABI through serving batch 128.

The reference and candidate use the production ``extend_attention_fwd`` call.
Only the raw-dispatch environment gate changes between them.  Every BF16 output
element is compared, candidate launches are poisoned first, and graph replay is
validated separately so a partial/no-op kernel cannot inherit stale output.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

import torch


ENABLE_ENV = "SGLANG_NETRA_QWEN36_GFX950_EXTEND_ATTENTION_GQA8_FP8KV"
HSACO_ENV = f"{ENABLE_ENV}_HSACO"
BRIDGE_ENV = f"{ENABLE_ENV}_BRIDGE"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hsaco", type=Path, required=True)
    parser.add_argument("--bridge", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--batches", default="64,80,96,112,128")
    parser.add_argument("--prefix-len", type=int, default=1024)
    parser.add_argument("--warmup", type=int, default=3)
    parser.add_argument("--repeats", type=int, default=10)
    return parser.parse_args()


def launch_case(tensors: dict[str, torch.Tensor]) -> None:
    from sglang.srt.layers.attention.triton_ops.extend_attention import (
        extend_attention_fwd,
    )

    extend_attention_fwd(
        tensors["q"],
        tensors["k_extend"],
        tensors["v_extend"],
        tensors["out"],
        tensors["k_buffer"],
        tensors["v_buffer"],
        tensors["qo_indptr"],
        tensors["kv_indptr"],
        tensors["kv_indices"],
        None,
        True,
        None,
        12,
        1.0,
        1.0,
        sm_scale=1.0 / 16.0,
        logit_cap=0.0,
        skip_prefix_custom_mask=True,
        sliding_window_size=-1,
        sinks=None,
        xai_temperature_len=-1,
    )


def timing_us(fn, warmup: int, repeats: int) -> dict[str, float]:
    for _ in range(warmup):
        fn()
    torch.cuda.synchronize()
    samples = []
    for _ in range(repeats):
        start = torch.cuda.Event(enable_timing=True)
        stop = torch.cuda.Event(enable_timing=True)
        start.record()
        fn()
        stop.record()
        stop.synchronize()
        samples.append(start.elapsed_time(stop) * 1000.0)
    values = torch.tensor(samples, dtype=torch.float64)
    return {
        "mean": float(values.mean()),
        "p50": float(values.quantile(0.50)),
        "p90": float(values.quantile(0.90)),
        "min": float(values.min()),
        "max": float(values.max()),
    }


def make_tensors(batch: int, prefix_len: int) -> dict[str, torch.Tensor]:
    device = torch.device("cuda")
    tokens = batch * 12
    cache_tokens = batch * prefix_len
    q = torch.randn((tokens, 16, 256), device=device, dtype=torch.bfloat16)
    k_extend = torch.randn((tokens, 2, 256), device=device, dtype=torch.bfloat16)
    v_extend = torch.randn((tokens, 2, 256), device=device, dtype=torch.bfloat16)
    # Keep values modest to avoid FP8 saturation while exercising native E4M3
    # loads in both implementations.
    k_buffer = (
        torch.randn((cache_tokens, 2, 256), device=device, dtype=torch.bfloat16)
        .mul_(0.25)
        .to(torch.float8_e4m3fn)
    )
    v_buffer = (
        torch.randn((cache_tokens, 2, 256), device=device, dtype=torch.bfloat16)
        .mul_(0.25)
        .to(torch.float8_e4m3fn)
    )
    return {
        "q": q,
        "k_extend": k_extend,
        "v_extend": v_extend,
        "out": torch.empty_like(q),
        "k_buffer": k_buffer,
        "v_buffer": v_buffer,
        "qo_indptr": torch.arange(
            0, tokens + 1, 12, device=device, dtype=torch.int64
        ),
        "kv_indptr": torch.arange(
            0, cache_tokens + 1, prefix_len, device=device, dtype=torch.int32
        ),
        "kv_indices": torch.arange(
            cache_tokens, device=device, dtype=torch.int64
        ),
    }


def validate_graph(tensors: dict[str, torch.Tensor], expected: torch.Tensor) -> dict:
    graph = torch.cuda.CUDAGraph()
    launch_case(tensors)
    torch.cuda.synchronize()
    with torch.cuda.graph(graph):
        launch_case(tensors)
    tensors["out"].fill_(float("nan"))
    graph.replay()
    torch.cuda.synchronize()
    actual = tensors["out"].clone()
    delta = (actual.float() - expected.float()).abs()
    return {
        "unwritten": int(torch.isnan(actual).sum()),
        "max_abs": float(delta.max()),
        "mean_abs": float(delta.mean()),
        "equal_to_eager_candidate": bool(torch.equal(actual, expected)),
    }


def main() -> None:
    args = parse_args()
    os.environ[HSACO_ENV] = str(args.hsaco)
    os.environ[BRIDGE_ENV] = str(args.bridge)
    os.environ[ENABLE_ENV] = "1"
    from sglang.srt.layers.attention.netra_gfx950_qwen36_target_attention import (
        maybe_load_netra_qwen36_target_attention_gqa8_fp8kv,
    )

    assert maybe_load_netra_qwen36_target_attention_gqa8_fp8kv()
    torch.manual_seed(20260809)
    results = []
    for batch in (int(x) for x in args.batches.split(",")):
        tensors = make_tensors(batch, args.prefix_len)
        os.environ[ENABLE_ENV] = "0"
        launch_case(tensors)
        torch.cuda.synchronize()
        reference = tensors["out"].clone()
        reference_timing = timing_us(
            lambda: launch_case(tensors), args.warmup, args.repeats
        )

        os.environ[ENABLE_ENV] = "1"
        tensors["out"].fill_(float("nan"))
        launch_case(tensors)
        torch.cuda.synchronize()
        candidate = tensors["out"].clone()
        candidate_second = torch.empty_like(candidate)
        tensors["out"].fill_(float("nan"))
        launch_case(tensors)
        torch.cuda.synchronize()
        candidate_second.copy_(tensors["out"])
        delta = (candidate.float() - reference.float()).abs()
        result = {
            "batch": batch,
            "tokens": batch * 12,
            "elements": candidate.numel(),
            "unwritten": int(torch.isnan(candidate).sum()),
            "deterministic": bool(torch.equal(candidate, candidate_second)),
            "bf16_mismatches": int(torch.ne(candidate, reference).sum()),
            "max_abs": float(delta.max()),
            "mean_abs": float(delta.mean()),
            "rmse": float(torch.sqrt(torch.mean(delta * delta))),
            "cosine": float(
                torch.nn.functional.cosine_similarity(
                    candidate.float().reshape(1, -1),
                    reference.float().reshape(1, -1),
                )
            ),
            "reference_timing_us": reference_timing,
            "candidate_timing_us": timing_us(
                lambda: launch_case(tensors), args.warmup, args.repeats
            ),
        }
        result["graph"] = validate_graph(tensors, candidate)
        # Existing B64 production validation established this kernel's FP8
        # numerical envelope.  Apply the same envelope to every larger batch
        # and require complete writes plus deterministic eager/graph replay.
        result["passed"] = bool(
            result["unwritten"] == 0
            and result["deterministic"]
            and result["max_abs"] <= 0.0625
            and result["cosine"] >= 0.999
            and result["graph"]["unwritten"] == 0
            and result["graph"]["equal_to_eager_candidate"]
        )
        results.append(result)
        del tensors, reference, candidate, candidate_second
        torch.cuda.empty_cache()

    output = {
        "architecture": torch.cuda.get_device_properties(0).gcnArchName,
        "seed": 20260809,
        "prefix_len": args.prefix_len,
        "results": results,
        "passed": all(row["passed"] for row in results),
    }
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n")
    print(json.dumps(output, indent=2, sort_keys=True))
    if not output["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
