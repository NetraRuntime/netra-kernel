# gfx1151 GDN KKT blockwise raw-ASM negative result (2026-07-30)

Status: **rejected**. Every number in this note is **measured on gfx1151** unless explicitly labeled. The experimental kernel is not connected to the production SGLang path.

## Scope

The Qwen3.6 GDN KKT solve at the real prefill shape is `B=1, T=8192, H=32, Hg=16, K=128, BT=64, BC=16`, with BF16 `k`, FP32 `g`, FP32 `beta`, and BF16 output. The raw kernel uses one wave per `(chunk, head)`, a `128 x 32` grid, wave32, 16 KiB LDS, no scratch, 208 allocated VGPRs (206 next-free in source metadata, rounded by the code object), and 48 next-free SGPRs.

## Correctness and arithmetic reconstruction

The initial failure was not a model instability: the real checkpoint supplies FP32 `beta`, while the first experiment loaded it as BF16. After correcting that input contract, the remaining differences were traced to arithmetic order.

Two gfx1151 compiler behaviors had to be reproduced:

1. Triton's 16-lane triangular reduction combines K indices at xor distances `8, 4, 2, 1`. The xor-8 pair is formed by an FMA, and its operand orientation depends on the active row's bit 3.
2. `tl.dot(A,B) + tl.dot(C,D)` lowers to one continuous FP32 FMA accumulator: 16 K terms from the first dot followed by 16 K terms from the second. A separate pair of matmuls followed by `v_add_f32` did not match. A standalone probe measured 175/256 FP32 mismatches for the separate-add version and zero mismatches for the concatenated FMA chain.

On captured real-checkpoint inputs, the final raw result versus SGLang's autotuned production kernel had:

- 28,567 BF16 bit mismatches out of 16,777,216 values;
- 4,884 numerical mismatches;
- maximum absolute difference `1.1112095035116937e-38`;
- mean absolute difference `5.521115949439779e-43`;
- all numerical differences below the minimum normal FP32 value (subnormal-only).

The paired uncached deterministic serving gate passed after the material differences were removed:

| Case | Exact request | Baseline token / ms | Raw token / ms | Result |
|---|---:|---:|---:|---|
| pair A | 32,768 input + 1 output | 220 / 23,632.266 | 220 / 23,501.102 | token match |
| pair B | 32,768 input + 1 output | 290 / 23,453.798 | 290 / 23,330.436 | token match |

Both paths had zero cached tokens, graph disabled, and dFlash disabled. These host end-to-end samples differ by only about 0.5% and are not used as a GPU speed claim.

## Performance decision

The reproducible HIP-event comparison on captured real-checkpoint inputs measured:

- SGLang autotuned production median: `5.239525 ms` (9 samples);
- raw blockwise median: `5.386481 ms` (9 samples);
- raw speedup: `0.972718x`, i.e. **2.8% slower**.

A separate 15-sample run measured `5.213172 ms` versus `5.407635 ms` (`0.964039x`). The raw kernel is consistently 2.8-3.6% slower than the current autotuned one-wave compiler kernel, so it is rejected despite eliminating the global workspace and passing the token gate.

A five-dispatch rocprofv3 trace measured `5.719091 ms` mean dispatch duration, with profiler overhead included. The trace reported 208 VGPRs, 16 KiB LDS, zero scratch, grid size 131,072 work-items, workgroup size 32, and 4,096 waves per dispatch.

Selected one-counter-per-process rocprofv3 results from the standalone harness:

| Counter | Mean |
|---|---:|
| OccupancyPercent | 12.384405% |
| MeanOccupancyPerActiveCU | 7.952568 |
| Wavefronts | 4,096 |
| L2CacheHit | 34.005181% |
| FETCH_SIZE | 131,315.875 KiB |
| WRITE_SIZE | 16,384 KiB |
| LDSBankConflict | 41.314554 |
| SQ_WAVE_CYCLES | 2,597,597,308.7 |
| VALUInsts | 12,594 |

The low 12.38% occupancy and 208-VGPR allocation explain why eliminating the workspace did not beat the compiler schedule. The next attempt should reduce live state or distribute the solve over more than one wave without reintroducing a full global workspace.

## Why rocprofv3 printed repeated `caught signal 6`

The repeated abort is a profiler counter-collection failure, not evidence that this kernel trapped. PMC collection around the Python/PyTorch process printed:

```text
aqlprofile API table load failed: HSA_STATUS_ERROR: A generic error has occurred.
rocprofv3 caught signal 6...
```

Looping over counters then launched another failing process, producing the repeated message. Kernel and HIP runtime tracing work in the ABI-matched Python environment, but PMC passes must use the standalone HIP harness with `/opt/rocm-7.2.1/bin/rocprofv3`. All nine standalone passes completed. `--disable-signal-handlers true` avoids recursive profiler cleanup behavior but cannot repair an unavailable aqlprofile table.

## Static disassembly

The measured production comparator selected `BK=64`, one wave, and FP32 `beta`. Static gfx1151 disassembly counts show the compiler kernel at 8,167 instructions, 256 VGPRs, 916 bytes of scratch per work-item, 227 scratch loads, 203 scratch stores, 1,050 `s_delay_alu`, and 328 `s_waitcnt`. The raw kernel has 7,195 instructions, 208 allocated VGPRs, zero scratch, zero `s_delay_alu`, and 380 `s_waitcnt`, but replaces the compiler schedule with 1,280 `ds_bpermute_b32` operations and 1,524 total LDS operations. This explains why the ostensibly leaner raw code still loses the HIP-event gate. Before/after disassemblies, their unified diff, and machine-readable counts are under `docs/notes/disassembly/gdn-kkt-blockwise-negative-gfx1151/` and `docs/notes/gfx1151-gdn-kkt-blockwise-disassembly-2026-07-30.json`. These are static counts, not runtime measurements.

## Reproduction

Inside the Netra LXC:

```bash
tools/build/build_gdn_kkt_piecewise_experiment.sh
python tools/benchmark/benchmark_gdn_kkt_blockwise.py --iterations 15
# Optional real-input capture produced during a diagnostic server run:
python tools/benchmark/benchmark_gdn_kkt_blockwise.py \
  --real-inputs /tmp/netra-kkt-real/real-inputs.pt --iterations 15

tools/profiling/profile_gdn_kkt_blockwise_counters.sh
```

The production SGLang bridge and dispatch hook were deliberately removed after rejection. The raw `.s`, experimental bridge, standalone harness, build path, benchmark, and counter script remain for future scheduling work.
