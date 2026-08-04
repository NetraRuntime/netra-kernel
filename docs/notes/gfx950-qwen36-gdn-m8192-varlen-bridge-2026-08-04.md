# Qwen3.6 gfx950 M8192 varlen GDN bridge

Status: accepted and promoted.

## Cause

The retained raw gfx950 H-recurrence object was correct for one 8,192-token sequence.
Piecewise replay can pack two variable-length sequences into the same total-T8192 call.
The assembly is varlen-aware, but the HIP bridge launched only 32 Y workgroups.
The runtime therefore rejected the observed N=2, h-NT=129 ABI and killed the scheduler.

## Fix

- Launch 32 head workgroups per packed sequence, with N in the range 1 through 64.
- Pass the shape-derived sequence count through the graph-safe HIP bridge.
- Retain the original raw gfx950 wave64 assembly and its 103,296-byte LDS schedule.
- Keep generic FlashQLA disabled; this path replaces only the measured raw H hotspot.
- Keep the fixed-N chunk-O raw object disabled until it has a true varlen schedule.

## Validation

- Target: one AMD Instinct MI350X, gfx950, wave64, FP8 E4M3 Qwen weights and FP8 KV.
- B1 32K prefill: mean TTFT 715.99 to 706.94 ms, a 1.26% reduction over five repeats.
- c64 32K prefill control: 49,421.85 input tok/s.
- c64 32K prefill candidate: 49,863.56 input tok/s, a 0.89% gain, 64/64 complete.
- Canonical c64 n192 32K/4K: 2,955.57 output tok/s and 26,600.09 total tok/s.
- Canonical request completed all 6,291,456 input and 786,432 forced output tokens.
- dFlash acceptance length was 7.41; no scheduler, ABI, or GPU faults were observed.
- GSM8K no-think: 1,314 samples, 94.82% accuracy, 1.83% invalid.
- Serving artifact root: `/data/netra/benchmarks/gfx950_qwen36_optimization/20260804T121858Z-qwen36-c64-gpu6`.

This bridge change is required for production c64 admission; the old N=1 bridge is unsafe.
