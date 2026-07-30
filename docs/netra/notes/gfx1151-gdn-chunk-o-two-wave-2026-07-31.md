# gfx1151 GDN chunk-output two-wave replacement — 2026-07-31

Status: **accepted for the fixed production T=8192 shape**. Every performance and correctness number in this note is measured on gfx1151 (AMD Ryzen AI Max+ PRO 395); no result is estimated. The checkpoint remains MXFP4. This kernel is a model-native BF16/FP32 GDN operation.

## Decision

The tuned Triton `chunk_fwd_kernel_o` has been replaced by raw gfx1151 AMDGCN for the exact production shape B1/T8192/H32/Hg16/K128/V128/BT64/BV32. The compatibility ABI and 72-byte, eight-byte-aligned kernarg remain unchanged. Production geometry changes from the rejected four-wave raw prototype `(4,128,32) x 128` to the corrected two-wave design `(4,256,32) x 64`.

The new design assigns one 32-row query half to each two-wave workgroup. It stages a complete 32x128 Q half, one 32x128 H/V tile, the full 64-row K tile, and the full 64-row gate vector. This removes the rejected prototype's interaction between four query waves while retaining exact model math.

Two independent indexing defects were found in the first two-wave experiment:

1. With a 64-thread workgroup, `v201` spans only rows 0..3. The old `QR*8 + v201` loader therefore skipped Q rows 4..7 in each eight-row group. The accepted loader uses `QR*4 + v201`.
2. The second query half's gate address added 32 after converting the row index to bytes, advancing only 32 bytes rather than 32 FP32 elements. The accepted kernel adds the row-half offset before the `<<2` byte conversion.

After those concrete fixes, three diagnostic `s_waitcnt_depctr` operations were removed. Repeated eager and graph poisoning remained correct and median HIP-event time improved from approximately 14.014 ms to 12.790 ms in that run.

## Correctness and graph gates

The production compatibility path was compared against the exact tuned Triton BK64/BV32/eight-warp oracle. Every launch first poisoned the output buffer.

| Gate | Eager repeats | Graph replays | Failures | Max abs error | Existing tolerance |
|---|---:|---:|---:|---:|---:|
| experimental no-wait two-wave | 30 | 30 | 0 | 1.9073486328125e-6 | 3.814697265625e-6 |
| production ABI before default enable | 30 | 30 | 0 | 1.9073486328125e-6 | 3.814697265625e-6 |
| production ABI, default-enabled | 30 | 30 | 0 | 1.9073486328125e-6 | 3.814697265625e-6 |

The module is initialized before graph capture, the raw launch uses the caller's current HIP stream, capture does not load a module or allocate, and repeated `torch.cuda.CUDAGraph` replay matched eager output. The explicit `SGLANG_NETRA_DISABLE_GDN_CHUNK_O_RAW=1` kill switch remains. The former unsafe opt-in was removed only after these gates passed.

The real checkpoint was then tested with fresh, uncached deterministic requests. In every A/B pair, the Triton and raw paths used identical input IDs and produced identical greedy tokens and output hashes.

## Kernel performance

HIP-event results vary with thermal state, so both repeated direct timing and an independent request-window rocprofv3 trace are retained.

| Measurement | Raw eager | Raw graph replay | Tuned Triton | Raw speedup |
|---|---:|---:|---:|---:|
| experimental no-wait, median of 11 | 12.790 ms | 12.804 ms | 14.732 ms | 1.152x |
| production ABI, median of 11 | 12.803 ms | 12.771 ms | 15.025 ms | 1.173x |
| production final after clean rebuild | 14.036 ms | 14.049 ms | 15.036 ms | 1.071x |

The clean request-window rocprofv3 comparison measured:

| Kernel | Calls | Median GPU | Mean GPU | VGPR | LDS | Scratch |
|---|---:|---:|---:|---:|---:|---:|
| prior Triton `chunk_fwd_kernel_o` | 29 | 15.634 ms | 15.740 ms | 256 | 0 B | 432 B/work-item |
| accepted raw `gdn_chunk_o_bv32_gfx1151` | 30 | 13.250 ms | 13.630 ms | 216 | 25,088 B | 0 B |

The invocation totals differ by one between independently captured requests, so aggregate totals are not used for the speedup claim. The per-call trace medians show a measured 1.180x speedup. Production HSACO SHA-256 is `4704b4b29a7dae7c3c6064ee33cad6beb2b88d1c6c0752703173dea8bc6b795a`.

## Hardware counters

rocprofv3 used one counter per fresh standalone `/opt/rocm-7.2.1` HIP process. This avoids the incompatible mixed Python-wheel HSA runtime that causes `aqlprofile` to abort with signal 6.

| Counter | Measured gfx1151 value |
|---|---:|
| grid threads / workgroup | 2,097,152 / 64 |
| waves | 65,536 |
| occupancy | 12.464943% |
| mean occupancy per active CU | 7.984659 waves |
| fetched | 180,400.4375 KiB |
| written | 32,768 KiB |
| L2 cache hit | 63.664587% |
| memory unit busy | 92.294034% |
| LDS bank conflict | 52.114286% |
| SQ wave cycles | 6,241,831,808 |
| SQ busy cycles | 778,776,764 |
| SQ LDS instructions | 34,471,936 |
| SQ flat instructions | 3,538,944 |

The gfx1151 counter set exposed by this rocprofv3 build does not provide a direct dependency/wait-state stall counter. That value is unavailable, not estimated. The high memory-unit busy and bank-conflict percentages are recorded as future optimization evidence, not interpreted as proof of a specific stall source.

## End-to-end serving

All serving numbers are host monotonic end-to-end measurements. Graph and dFlash were disabled, output length was exactly one token, and cached tokens were zero.

| Exact request | Triton A1/A2 | Raw B1/B2 | Median Triton | Median raw | Improvement |
|---|---:|---:|---:|---:|---:|
| 8,192 input + 1 output | 4540.369 / 4531.915 ms | 4463.908 / 4455.559 ms | 4536.142 ms | 4459.733 ms | 1.01713x; 1.684% lower |
| 32,768 input + 1 output | 21636.981 / 21582.497 ms | 21286.598 / 21342.922 ms | 21609.739 ms | 21314.760 ms | 1.01384x; 1.365% lower |

For 8K, all outputs were token 220 with output SHA-256 `36a9e7f1c95b82ffb99743e0c5c4ce95d83c9a430aac59f84ef3cbfab6145068`. For 32K, all outputs were token 95726 with output SHA-256 `8af2350cfd65805bd50b6813ab70f85f1d71d94ad39f9d8915176d7a33168f8b`.

Peak sysfs VRAM ranged from 79.20 to 80.00 GB across these fresh-server runs with no consistent A/B direction. These samples do not support a VRAM-change claim.

## Rejected variants

- The original four-wave kernel remains rejected because it intermittently corrupted row 32 mod 64.
- A new one-wave/16-row kernel was fully correct across 30 eager and 30 graph repetitions but measured 22.000 ms versus 14.711 ms Triton, only 0.669x baseline performance.
- The first two-wave source had the missing-Q-row and gate-byte-offset defects described above. Broad dependency waits did not correct addressing errors.
- A duplicated-H-per-wave variant and CU-mode diagnostic inherited the pre-fix gate-address defect and were rejected.
- Keeping three conservative dependency waits was correct but approximately 9.6% slower than the final no-wait experiment in the paired measurements.

## Reproduction and artifacts

Run inside Netra:

```bash
cd /root/netra-mxfp4-gfx1151
python scripts/rocm/tools/correctness/check_gdn_chunk_o_repeated.py \
  --eager-repeats 30 --graph-repeats 30 --samples 11
scripts/rocm/tools/profiling/profile_gdn_chunk_o_bv32_counters.sh
```

Before/after disassembly and code-object metadata are under `docs/netra/notes/gfx1151-gdn-chunk-o-disassembly-2026-07-31/`. Machine-readable acceptance data are in the adjacent JSON note. The older repeatability-rejection note remains valid for the old four-wave implementation and is superseded only for the newly derived two-wave kernel.
