// SPDX-License-Identifier: MIT
#pragma once

#define NETRA_GFX1151_ALWAYS_INLINE inline __attribute__((always_inline))

#ifndef NETRA_HSACO_DIR
#define NETRA_HSACO_DIR "/root/netra-mxfp4-gfx1151/build/sglang"
#endif

#ifndef NETRA_EXTEND_ATTENTION_GRID_Y
#define NETRA_EXTEND_ATTENTION_GRID_Y 4
#endif
#ifndef NETRA_EXTEND_ATTENTION_BLOCK_X
#define NETRA_EXTEND_ATTENTION_BLOCK_X 512
#endif
#ifndef NETRA_PREFILL_GATE_GRID_X
#define NETRA_PREFILL_GATE_GRID_X 8
#endif
#ifndef NETRA_PREFILL_GATE_BLOCK_X
#define NETRA_PREFILL_GATE_BLOCK_X 128
#endif
