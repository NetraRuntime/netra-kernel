# gfx1151 attention softmax issue-distance negative result (2026-07-30)

Status: **rejected; production kvbatch16 remains unchanged**. Every timing below
is measured with gfx1151 HIP events; no value is estimated.

The raw ASM candidate preserves every per-row online-softmax operation and its
order, but issues exponentials for all eight output rows before consuming them
in the sum-reduction and running-normalizer update. The goal was to increase
`v_exp_f32` producer/consumer distance without changing VGPR, LDS, barriers,
loads, arithmetic count, or numerical behavior.

T64 prefix 0/64/192 and T8192 prefix 0/8K/16K/24K are byte-identical to the
accepted raw kvbatch16 kernel.

| Prefix | kvbatch16 ms | softpipe ms | Speedup | Decision |
|---:|---:|---:|---:|---|
| 0 | 34.981861 | 34.628643 | 1.010200x | faster |
| 8,192 | 99.865608 | 99.885239 | 0.999803x | neutral |
| 16,384 | 166.671036 | 166.519409 | 1.000911x | neutral |
| 24,576 | 233.599304 | 233.910568 | 0.998669x | slower |
| **sum** | **535.117809** | **534.943859** | **1.000325x** | **reject** |

The slight prefix-0 movement does not generalize. Prefix 8K and 24K are neutral
to slower, and the total gain is only 0.0325%, below run-to-run
noise and far below an end-to-end gate. rocprofv3 counters and serving tests
were intentionally not run after this failed HIP-event gate. The retained
experimental `.s` is a correctness-preserving scheduling oracle; it is not
linked by the production build.
