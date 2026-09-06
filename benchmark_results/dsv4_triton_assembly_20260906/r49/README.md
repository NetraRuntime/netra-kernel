# Numeric bring-up (r49)

Exploratory results retained, including failures. Instruction spacing fixed the
initial FP8 conversion failure; job 04 passed 115 smoke cases. Job 05 then exposed
one exact-token mismatch in a 1,024-request sampling case. The later r50 campaign
matches the reference summation/scan order and includes additional sampling stress.

The initial build manifest predates these fixes; it is not a manifest for the
final r50 source. Use r50 final manifests and final runs for the committed code.
Production restoration and authenticated API checks passed after this window.
