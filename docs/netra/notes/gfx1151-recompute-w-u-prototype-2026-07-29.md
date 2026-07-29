# GDN recompute-W/U prototype on gfx1151

All results are measured on gfx1151. The latest exact 32K rocprofv3 trace
ranked `recompute_w_u_fwd_kernel` fourth at 2,402.123 ms over 150 calls. Hot
calls measured about 19.69 ms median; the compiler kernel uses 256 VGPR and
four waves with three pipeline stages.

An exact B1/T8192/H32/Hg16/K128/V128/BT64 sweep measured the following HIP
event medians (seven samples each): 2w1 11.145 ms, 2w2 14.367 ms, 2w3 12.925
ms, 4w1 17.342 ms, 4w2 18.822 ms, 4w3 21.042 ms, 8w1 14.852 ms, 8w2 19.263
ms, and 8w3 19.481 ms. Every compiler configuration was bit-identical. The
2w1 configuration is therefore the temporary correctness/performance oracle,
not a final compute implementation.

The first hand-written AMDGCN prototype, `recompute_w_u_tile64_gfx1151.s`,
uses one 64-column U/W tile per workgroup, raw WMMA, 16 KiB LDS, 117 VGPR, and
zero scratch. Against the 2w1 oracle, measured max absolute errors were
3.8147e-6 for W and 7.6294e-6 for U; both outputs were finite. Eight HIP-event
samples measured 15.449 ms median. This is 1.362x faster than the current 4w3
kernel but 1.386x slower than the 2w1 oracle.

The negative cause is concrete: splitting four output tiles into independent
workgroups reloads the 64x64 A tile four times. This prototype is retained as
a correct raw baseline, not yet integrated or accepted for serving. The next
revision must combine A reuse with a two-wave schedule. Before/oracle/raw
disassemblies are in `docs/netra/notes/disassembly/recompute-w-u-gfx1151/`.

## Two-wave A-reuse revision: fast but rejected

All values in this section are measured on gfx1151; none are estimated. The
second raw revision, `recompute_w_u_reuse_a_gfx1151.s`, assigns one A tile to
each two-wave workgroup and evaluates all four U/W right-hand-side tiles before
retiring the workgroup. Its fixed launch is grid `(128,32)`, block 64, with
16 KiB LDS, 136 VGPR, 128 SGPR, and zero scratch in rocprofv3 metadata.

On the exact B1/T8192/H32/Hg16/K128/V128/BT64 shape, ten HIP-event samples
measured 9.974 ms median. The same-run 2w1 Triton oracle measured 11.112 ms,
so raw was 1.1140x faster than the best compiler configuration and 2.109x
faster than the deployed 4w3 measurement. Controlled random inputs had
7.6294e-6 max absolute error for both W and U. A wider random integrated-op
test reached one BF16 output ULP (0.00390625) and remained finite. Stable-
pointer HIP graph replay was bit-identical to raw eager output and measured
9.965 ms median over ten replays.

The real checkpoint guard intercepted all 30 GDN layers for an exact uncached
8192/+1 request. Per-layer comparison against the 2w1 compiler oracle measured
worst W error 0.0009765625 and worst U error 0.001953125. The deterministic
greedy token matched at this length: token 278 in both modes.

A normally finalized process-start rocprofv3 CSV trace for exact uncached
32768/+1 measured 120 raw calls, 1,217.875 ms total, 10.149 ms mean, and
10.128 ms median. The earlier deployed trace measured approximately
2,402.123 ms for this family including 30 negligible warmup/health calls, so
the raw request path removed approximately 1.184 seconds of GPU work. The
paired non-profiled serving run measured TTFT 30,024.270 ms with raw disabled
and 28,820.132 ms with raw enabled: 1.0418x faster on gfx1151. Both requests
were exact 32768 input +1 output, uncached, graph disabled, and dFlash disabled.

The replacement nevertheless fails the full-model deterministic correctness
gate. At the exact paired 32768-token input, raw selected token 220; the
deployed Triton 4w3 path and independently tested 2w1 oracle both selected
token 248045. Raw assigned log probabilities -6.03881 to token 220 and
-6.16381 to token 248045. The 2w1 oracle assigned -5.92670 to token 248045 and
-6.05170 to token 220. This is not merely the known server-epoch text/hash
instability: the raw result disagreed with the compiler oracle under the same
fixed input and remained separated by 0.125 log-probability.

Therefore the fast A-reuse kernel is retained only as a reproducible negative
prototype with its standalone HIP launcher and disassembly. Its temporary
SGLang dispatch, production HIP bridge, and build integration were removed.
No serving speedup from this kernel is claimed as accepted. A future revision
must reproduce the model-native compiler accumulation closely enough to pass
the 32768-token greedy/logit gate before integration.
