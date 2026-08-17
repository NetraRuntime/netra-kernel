# gfx950 B128 GDN replay promotion (2026-08-17)

The model-neutral B128 replay operation contract at `acbc301272` is promoted.
Its seven device code objects are byte-identical to the active capacity-fix
winner, and its host-only deterministic bridge rebuilt twice with SHA-256
`3e2848632304fa906381525448e26cce960a7d6d539d84ac22cd0129d0d500b2`.

Five fresh-process single-GPU exact 1K/1K runs averaged **10,004.95 output
tok/s**. Five strict full-routed DP8 runs through one `n=3072`, `c=1024`
client averaged **78,748.15 tok/s**, with a 76,374.32 minimum and 81,331.51
maximum. Every request passed exact token, cache, finish-reason, error, and
DFlash checks. A complete deployment recreated through the checked-in server
profile subsequently passed at 76,764.22 tok/s.

Runtime `/proc/*/maps` evidence confirms that the loaded bridge was the generic
`/netra-replay` artifact. The older bridge visible below a historical build
directory was not loaded. Raw benchmark, container, server-info, telemetry,
artifact-hash, and reproduction evidence is retained under
`/data/netra/benchmarks/gfx950_qwen36_optimization/20260817T042500Z-generic-deterministic-promote-dp8/`.
