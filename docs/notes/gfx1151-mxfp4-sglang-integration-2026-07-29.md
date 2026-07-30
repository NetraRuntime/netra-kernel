# Qwen3.6 MXFP4 SGLang integration on gfx1151

Date: 2026-07-29. Every command and measurement was executed inside the
`Netra` LXC on the Ryzen AI Max+ PRO 395 (`gfx1151`).

## Integrated path

SGLang main commit `1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`
loads the real 26-shard
`pahajokiconsulting/Qwen3.6-35B-A3B-MXFP4` checkpoint with
`SGLANG_USE_NETRA_MXFP4_GFX1151=1`.

The integration retains serialized MXFP4 bytes and E8M0 scales in VRAM.
Load-time transposes are layout changes, not dequantization. The serving path
uses:

- raw AMDGCN decode gate/up and down kernels with runtime expert IDs;
- raw AMDGCN grouped M64 prefill gate/up and down kernels;
- a raw AMDGCN FP32 router-weight reduction epilogue;
- a raw AMDGCN runtime-N/K linear decode kernel for packed GDN projections;
- a raw AMDGCN runtime-N/K M64 WMMA prefill kernel for packed GDN
  projections, replacing one M1 launch per prompt row;
- a HIP launch-only shared library and a Python SGLang dispatch bridge.

The upstream gfx1151 AOT router failed with `unspecified launch failure`.
SGLang's existing Triton fused router was enabled on HIP and independently
validated at `(tokens, experts, top-k) = (6, 256, 8)`. This router operation
does not replace any MXFP4 matrix kernel.

## Real-checkpoint correctness

Measured on gfx1151:

- full staged expert decode (gate, up, SiLU, down and top-k reduction):
  maximum BF16 error 0, normalized L2 0, exact BF16 fraction 1.0 versus the
  staged fp64 dequantized-MXFP4 reference;
- real layer-0 GDN `in_proj_qkv`, M=2 N=8192 K=2048:
  maximum BF16 error 0, normalized L2 0, exact BF16 fraction 1.0 versus fp64;
- real layer-0 GDN M64-prefill projection, M=65 N=64 K=2048:
  maximum BF16 error 0, normalized L2 0, exact BF16 fraction 1.0 versus fp64;
- real layer-0 GDN M64-prefill projection at full width,
  M=2 N=8192 K=2048: maximum BF16 error 0.000244140625,
  normalized L2 2.918713e-6, exact BF16 fraction 0.99993896484375
  versus fp64;
- end-to-end SGL smoke request:
  prompt `The capital of France is`, output ` Paris, a city`, 5 prompt and
  4 completion tokens.

## Stabilized GPU-event comparison

These measurements were rerun while the SGL deployment was resident but idle.
Both sides use real layer-0 checkpoint weights, rotating working sets larger
than the 32 MiB Infinity Cache. Raw timings use the launch/check HIP harnesses.
The baseline is Triton 3.5.1 `matmul_ogs` commit
`0add68262ab0a2e33b84524346cb27cbb2787356` with the corrected RDNA manual
MXFP4 decode path. Each Triton result uses 20 warmups and 100 timed iterations;
the raw harnesses use 100 timed iterations. Timings are HIP events on gfx1151.

| MXFP4 operation on gfx1151 | Shape | Raw ASM (us) | Triton (us) | Raw speedup |
|---|---:|---:|---:|---:|
| Gate/up decode | E8 M1 N512 K2048 | 90.342 | 110.137 | 1.219x |
| Down decode | E8 M1 N2048 K512 | 46.653 | 109.948 | 2.357x |
| Gate/up verify | E8 M12 N512 K2048 | 52.639 | 116.985 | 2.222x |
| Down verify | E8 M12 N2048 K512 | 26.656 | 114.250 | 4.286x |
| Gate/up grouped prefill | G8 M64 N512 K2048 | 104.223 | 216.789 | 2.080x |
| Down grouped prefill | G8 M64 N2048 K512 | 89.121 | 111.765 | 1.254x |

The Qwen expert MLP invokes gate, up and down, so gate/up is counted twice:

| Expert MLP path on gfx1151 | Raw ASM (us) | Triton (us) | Raw speedup | Latency reduction |
|---|---:|---:|---:|---:|
| Decode M1 | 227.337 | 330.222 | 1.453x | 31.16% |
| Speculative verify M12 | 131.934 | 348.221 | 2.639x | 62.11% |
| Grouped prefill M64 | 297.567 | 545.344 | 1.833x | 45.44% |

All six raw runs and all six Triton runs passed their fp64 correctness gates.
An initial 30-iteration Triton run was rejected because the M1 gate time
dropped from 158.5 us to about 111 us after longer warmup.

## SGL serving measurements

These are uncached HTTP end-to-end measurements using the host monotonic clock;
they are not kernel timings and are not used to calculate the Triton speedups.
Each prompt begins with a unique nonce, and SGL reported zero cached tokens.

| SGL request on gfx1151 | Median | Mean | Samples |
|---|---:|---:|---|
| 25 prompt + 8 completion tokens | 1024.757 ms | 1034.387 ms | 1116.442, 1024.757, 961.963 ms |
| 36 prompt + 16 completion tokens | 1594.988 ms | 1587.959 ms | 1594.988, 1567.456, 1601.432 ms |
| 210 prompt + 1 completion token | 2780.742 ms | 2772.345 ms | 2786.017, 2780.742, 2750.276 ms |

The initial dense GDN integration launched the raw M1 kernel once for every
prompt row. The runtime-N/K M64 WMMA replacement reuses each decoded MXFP4
tile over 64 activation rows. On a cache-resident real layer-0
N=8192 K=2048 projection, HIP events measured 21,942.634 us for the old
210-row launch loop and 332.002 us for four M64 groups: 66.092x faster for
that isolated projection path on gfx1151.

After installing the M64 raw-ASM path, three exact 210-token, uncached
requests measured 440.138, 448.285 and 447.245 ms end to end. The
447.245 ms median is 6.217x faster than the 2,780.742 ms median above and
reduces serving latency by 83.92% on gfx1151. Effective input rate calculated
from end-to-end latency is 469.54 token/s. These serving values are measured,
but include HTTP, scheduling, prefill and one decode token.

### Exact 32K-input / 16K-output serving run

SGLang's streaming `bench_one_batch_server` harness ran batch size 1 with
exactly 32,768 random input IDs and exactly 16,384 forced output tokens
(`ignore_eos=True`). The server used `context_length=65536`, four real
8,192-token prefill chunks, zero cached prompt tokens in the scheduler log,
and disabled decode/prefill graphs.

Measured on gfx1151:

| Metric | Result |
|---|---:|
| Time to first token | 35.3761 s |
| Input throughput | 926.28 token/s |
| Output throughput | 12.90 token/s |
| Mean inter-token latency | 77.52 ms |
| End-to-end latency | 1305.4599 s (21m45.4599s) |
| Overall input+output throughput | 37.65 token/s |
| Final server-side decode throughput near 49K context | 12.37 token/s |

The server log showed decode easing from roughly 13.5 token/s just after
prefill to 12.37 token/s near the final context length. These are measured
deployment results on gfx1151, not a projection-kernel benchmark and not a
claimed hardware ceiling.

The first version of the prefill benchmark reused the prompt and reported 320
cached tokens. Those samples were rejected and replaced by the uncached run.

## Launch

The consolidated patch was checked against a clean archive of SGLang commit
`1eee8fbdcc25b44e13bc097d5ff6ac24e8c24af4`:

```bash
cd /root/work/sglang-main
git apply /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/sglang-gfx1151-integration.patch
cp /root/netra-mxfp4-gfx1151/scripts/rocm/integrations/sglang/netra_gfx1151_sglang.py \
  python/sglang/srt/layers/quantization/netra_gfx1151.py
```

The verified deployment command included both the isolated environment and
ROCm tools in `PATH`:

```bash
SGLANG_USE_NETRA_MXFP4_GFX1151=1 \
PATH=/root/sglvenv1151/bin:/opt/rocm-7.2.1/bin:$PATH \
HIP_VISIBLE_DEVICES=0 \
PYTHONPATH=/root/work/sglang-main/python \
/root/sglvenv1151/bin/python -m sglang.launch_server \
  --model-path /root/models/qwen36-sgl-mxfp4 \
  --host 127.0.0.1 --port 30000 \
  --attention-backend triton --moe-runner-backend triton \
  --cuda-graph-backend-decode disabled \
  --cuda-graph-backend-prefill disabled \
  --mem-fraction-static 0.80 --context-length 2048 \
  --skip-server-warmup --disable-shared-experts-fusion
```

CUDA graphs were disabled for this first correctness-qualified integration,
so the HTTP figures are a bring-up baseline rather than the deployment limit.
