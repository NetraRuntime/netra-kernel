# gfx950 GDN replay B128 contract provenance (2026-08-17)

The production profile now selects a model-neutral replay operation contract
that explicitly records B128 capacity, T12/H16/HV32/K128/V128 shape, BF16
token inputs, FP32 recurrent state, strided input layout, no quantization, and
runtime ABI v1.

The generic profile rebuild reproduces all promoted device code objects
byte-for-byte:

| Artifact | SHA-256 |
|---|---|
| precompute | `b93c9bbc6926a4decc0b342cc77b2567d4bdf87e9000ba29987904906063ac5a` |
| replay waves1 | `cdf7271652bad2d8dc0ec760c0467af973a6923db94e61ed7b4223ceebe1fb53` |
| replay waves4 | `b3f34b1f0e2858b29823659b5d8d1d75d34281a10d304a7ee4f330161bc46fb5` |
| replay waves8 | `165a045e651837409097d9669df35d799ab2c96f4f6f1df408ac046dad6c9d06` |
| dual waves1 | `8b978f09d179eb7670c7cbc1cc891bb3af213259e7c02cf95668590c9e8cc788` |
| dual waves4 | `d9d11bda7989cc43ba95d9d89dd210174d3974c8b2eef1213a40e22f7a9ac1cf` |
| dual waves8 | `1886d408f2c3b02e6989f5f231214c336e586caac3e0ebedf26ebc982507b698` |

The prior `hipcc` host bridge was nondeterministic across identical builds.
The contract now uses a host-only clang link with a stable build ID. Two clean
profile builds produced the identical bridge hash
`3e2848632304fa906381525448e26cce960a7d6d539d84ac22cd0129d0d500b2`.

Build evidence is under
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260817T022828Z-b128-generic-dp8/`
in `generic-profile-b128-deterministic-rebuild1` and `rebuild2`.
