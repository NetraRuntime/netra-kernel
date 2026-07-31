# gfx1151 LM-head four-tile wait batching — rejected

Status: **rejected, measured on gfx1151**. The production kernel is unchanged.

The fixed M=1, N=248320, K=2048 BF16 LM-head kernel was tested with four
original coalesced 128-byte K tiles issued before each full dependency wait.
Lane-to-K ownership and FP32 dot order were unchanged, so all ten real-weight
activation trials were bit-exact to the accepted raw kernel and produced the
same argmax.

Sixty interleaved HIP-event samples measured `5.020823 ms` for the accepted
kernel and `5.080175 ms` for batch-four, a `0.988317x` speed ratio (1.182%
slower). Batch-two also measured slower at `5.086506 ms`. The LM head is already
weight-bandwidth-bound on this shape; reducing broad waits did not increase
effective bandwidth. The temporary candidate is not shipped.
