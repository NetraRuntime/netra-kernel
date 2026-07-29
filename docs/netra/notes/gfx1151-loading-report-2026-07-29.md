# gfx1151 checkpoint-loading report (2026-07-29)

Every number in this report is measured on gfx1151. No value is estimated.
The real `/root/models/qwen36-sgl-mxfp4` checkpoint was used and all quantized
bytes remained MXFP4.

## Result

| Loader | Cold-cache weight load | Relative to baseline | Status |
|---|---:|---:|---|
| Buffered mmap baseline | 731.51 s | 1.000x | gfx1151 measured |
| 256-way expert batching, mmap retained | 734.27 s | 0.996x | gfx1151 measured, rejected |
| 256-way expert batching, non-mmap, two threads | 9.24 s | 79.168x | gfx1151 measured, accepted |

The accepted loader removes 722.27 seconds, or 98.737%, from weight loading.
All 26 cold-cache shards completed in 8 seconds according to SGLang's shard
progress, and the server reached ready state normally after graph setup.
A second cold-cache run through the committed benchmark script loaded weights
in 9.13 seconds and reached HTTP health in 23.145 seconds from host launch;
both values are gfx1151 measured.

## Root cause

The checkpoint contains 63,321 tensors across 26 safetensors shards. Of these,
61,440 tensors are the 40 main-model layers' 256-expert MXFP4 packed weights
and scales. With mmap enabled, sorted per-tensor processing faults thousands of
small, discontiguous file ranges into memory. The scheduler spent its time in
KFD waits and file-backed page faults even though the checkpoint is on local
KIOXIA NVMe.

Reducing 61,440 expert device copies to 240 while retaining mmap changed load
time from 731.51 to 734.27 seconds. This measured negative proves launch/copy
count was not sufficient. Reading each shard sequentially with
`--weight-loader-disable-mmap`, bounded to two threads for the 16 GiB machine,
made the tensors resident before the batched copies and removed the fault
storm.

A real-size 256 MiB contiguous copy was also measured with HIP events on
gfx1151. After warmup, pageable host memory took 3.361--3.385 ms and pinned host
memory took 3.325--3.417 ms, approximately 79--81 GB/s. Pinning is therefore
not retained as a claimed material optimization on this unified-memory GPU.

## Accepted configuration

The standard `integrations/sglang/launch.sh` now supplies:

```text
--weight-loader-disable-mmap
--model-loader-extra-config {"num_threads":2}
--weight-loader-drop-cache-after-load
```

The SGLang model patch recognizes the real expert tensor names, preserves the
serialized MXFP4 representation, stages each complete 256-expert projection,
and copies it to the existing `w13_weight`, `w13_weight_scale`, `w2_weight`, or
`w2_weight_scale` parameter. It rejects incomplete or mismatched batches.

`scripts/rocm/benchmark_sglang_fast_load.sh` reproduces the load test. It
refuses to run while another SGLang server is active, uses scoped
`POSIX_FADV_DONTNEED` only on the selected checkpoint's safetensors files for a
cold-cache run, waits for health, and stops only the server process it started.

## Real-checkpoint correctness after fast loading

All requests were uncached, full-decode graph mode was enabled for M=1, and
dFlash was disabled.

| Exact input/output | E2E ms | Output tok/s | Stable reference hash | Status |
|---:|---:|---:|---|---|
| 16 / 1 | 395.212 | n/a | match | gfx1151 measured |
| 210 / 1 | 391.129 | n/a | match | gfx1151 measured |
| 8,192 / 1 | 7,117.081 | n/a | match | gfx1151 measured |
| 32,768 / 1 | 34,810.206 | n/a | known near-tie mismatch | gfx1151 measured |
| 1 / 32 | 1,798.343 | 18.050 | match | gfx1151 measured |
| 210 / 128 | 7,451.358 | 17.991 | match | gfx1151 measured |

The 32,768/+1 output was already unstable across unmodified server epochs; it
is not used as the deterministic acceptance hash. The fixed 1/+32 and
210/+128 sequences match the pre-loader-change QKVZ+BA graph integration.

Raw evidence is retained under
`results/loading/gfx1151/batched-disable-mmap-2t-20260729/`.
The rejected run is retained under
`results/loading/gfx1151/batched-expert-20260729/`.
