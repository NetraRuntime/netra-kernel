# gfx1151 current-head exact 32,768-input +1 serving (2026-07-30)

This is a measured host HTTP end-to-end result on gfx1151 at repository head `e44a63726d853eb39dea9f790a8e46fffc15b6bb`, before the later uncommitted gate+SiLU epilogue fusion. That fusion is M12-only and does not execute in the M32768 prefill.

- Exact input tokens: 32,768
- Exact forced output tokens: 1
- Cached tokens: 0
- Host E2E: 21,544.885299 ms measured
- Server-reported E2E: 21,529.709378 ms measured
- Derived input-plus-first-token rate: 1,520.918 input tokens/s from measured host E2E
- Output token: `[82]`, identical to the prior exact-seed record
- Peak unified-memory sysfs sample: 101,506,072,576 bytes measured
- Graph mode: disabled
- dFlash mode: disabled
- Context limit: 49,152
- Shard loader: two threads; launch-to-health 24,166 ms measured
- TTFT: not separately exposed and not estimated

The immediately preceding exact-seed page-1 production record was 21,515.386865 ms. The current run is 29.498434 ms or 0.137104% slower, within the earlier page-1 sample standard deviation of 29.431782 ms. No speedup or regression is claimed from this single fresh-server pair.

The terminal server status 137 is intentional SIGTERM cleanup after the response, not a load or inference failure. Machine-readable request details are in `gfx1151-current-head-32768-plus1-serving-2026-07-30.json`.
