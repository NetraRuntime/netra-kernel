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
