# SPDX-License-Identifier: MIT
"""Explicit gfx950 DSV4 control primitives. No implicit serving replacement.

Input semantic contracts (not read back from GPU): positions/chunk starts/state
slots fit nonnegative int32, per-row valid counts fit the page width, front-packed
page lists match indptr deltas, destination rows do not collide, and storage is
large enough. Every address calculation uses 64-bit row/page bases.
"""
import ctypes
import struct
from pathlib import Path
import torch

_NAMES = ('scatter_loc', 'swa_scatter', 'prefill_lengths', 'append_shared',
          'fill_compress_tail', 'prefill_indices', 'finalize_accept', 'gather_bonus',
          'build_out_tokens', 'compressed_metadata', 'build_out_tokens_flat')
class _Args(ctypes.Structure):
    _fields_ = [('p', ctypes.c_uint64 * 16), ('a', ctypes.c_uint32 * 16)]
assert ctypes.sizeof(_Args) == 192

def _bits(value):
    return struct.unpack('I', struct.pack('f', value))[0]

def _integer(t):
    if t.dtype not in (torch.int32, torch.int64):
        raise ValueError('requires int32/int64')
    return t.element_size()

def _vector(t, rows):
    if t.ndim != 1 or t.numel() != rows:
        raise ValueError('invalid vector shape')
    return _integer(t)

class Control:
    def __init__(self, build_dir, device=None, waves=None):
        if waves not in (None, 1, 4): raise ValueError('waves must be 1, 4 or automatic')
        self.waves = waves
        self.device = torch.device('cuda', torch.cuda.current_device() if device is None else device)
        self.lib = ctypes.CDLL(str(Path(build_dir) / 'libnetra_control.so'))
        p, u = ctypes.c_void_p, ctypes.c_uint32
        self.lib.netra_control_error.restype = ctypes.c_char_p
        self.lib.netra_control_create.argtypes = [ctypes.c_char_p, ctypes.POINTER(p)]
        self.lib.netra_control_launch.argtypes = [p, u, p, u, p]
        self.lib.netra_control_close.argtypes = [p]
        self.handle = p()
        with torch.cuda.device(self.device):
            self._check(self.lib.netra_control_create(
                str(Path(build_dir) / 'control.hsaco').encode(), ctypes.byref(self.handle)))
    def _check(self, status):
        if status:
            raise RuntimeError(self.lib.netra_control_error().decode())
    def _launch(self, mode, tensors, scalars, rows):
        if not self.handle.value:
            raise RuntimeError('module is closed')
        if not 0 <= rows <= 65535:
            raise ValueError('row count exceeds launch contract')
        if any(t.device != self.device or not t.is_contiguous() for t in tensors):
            raise ValueError('all tensors must be contiguous on the owning device')
        if any(not 0 <= int(v) <= 0xffffffff for v in scalars):
            raise ValueError('scalar exceeds ABI')
        if not rows:
            return
        # Per-call host storage: concurrent callers never share mutable arguments.
        args = _Args()
        for i, t in enumerate(tensors): args.p[i] = t.data_ptr()
        for i, v in enumerate(scalars): args.a[i] = int(v)
        args.a[15] = rows
        if self.waves == 4 or (self.waves is None and rows >= 128): mode += len(_NAMES)
        with torch.cuda.device(self.device):
            self._check(self.lib.netra_control_launch(self.handle, mode,
                ctypes.byref(args), rows, torch.cuda.current_stream(self.device).cuda_stream))
    def scatter_loc(self, kv, loc, out):
        rows, width = self._scatter_shape(kv, out)
        self._launch(0, (kv, loc, out), (_vector(loc, rows), width), rows)
    @staticmethod
    def _scatter_shape(kv, out):
        if kv.ndim != 2 or out.ndim != 2 or kv.shape[1] != out.shape[1]:
            raise ValueError('scatter requires matching matrix widths')
        if kv.dtype != torch.bfloat16 or out.dtype != kv.dtype or kv.shape[1] % 8:
            raise ValueError('scatter requires bf16 and widths divisible by eight')
        if kv.data_ptr() % 16 or out.data_ptr() % 16:
            raise ValueError('scatter bases must be 16-byte aligned')
        return kv.shape[0], kv.shape[1] * 2
    def swa_scatter(self, kv, state, pos, final, out, win, ring_stride):
        rows, width = self._scatter_shape(kv, out)
        if not 1 <= win <= ring_stride <= 0x7fffffff or ring_stride < 2:
            raise ValueError('invalid SWA window/stride')
        has_final = final is not None
        final = pos if final is None else final
        values = (_vector(state, rows), _vector(pos, rows), _vector(final, rows),
                  int(has_final), win, ring_stride, (1 << 32) // ring_stride, width)
        self._launch(1, (kv, state, pos, final, out), values, rows)
    def prefill_lengths(self, pos, chunk, pages, prefix, extend, win):
        rows = pos.numel()
        if prefix.dtype != torch.int32 or extend.dtype != torch.int32:
            raise ValueError('length outputs must be int32')
        _vector(prefix, rows); _vector(extend, rows)
        width = self._pages(pages, rows)
        tensors = (pos, chunk, pos if pages is None else pages, prefix, extend)
        self._launch(2, tensors, (_vector(pos, rows), _vector(chunk, rows), width, win), rows)
    @staticmethod
    def _pages(pages, rows):
        if pages is None: return 0
        if pages.ndim != 2 or pages.shape[0] != rows or pages.dtype != torch.int32:
            raise ValueError('pages must be int32 [rows,width]')
        return pages.shape[1]
    def append_shared(self, ids, weights, out_ids, out_weights, base, scale):
        if ids.ndim != 2 or weights.shape != ids.shape or weights.dtype != torch.float32:
            raise ValueError('invalid routed inputs')
        rows, k = ids.shape
        if out_ids.ndim != 2 or out_ids.shape[0] != rows or out_weights.shape != out_ids.shape:
            raise ValueError('invalid shared outputs')
        if out_ids.dtype != ids.dtype or out_weights.dtype != torch.float32:
            raise ValueError('invalid shared output dtypes')
        shared = out_ids.shape[1] - k
        if not 1 <= k <= 64 or not 0 <= shared <= 64:
            raise ValueError('requires routed/shared widths <= 64')
        self._launch(3, (ids, weights, out_ids, out_weights),
                     (k, shared, base, _bits(scale), _integer(ids)), rows)
    def fill_compress_tail(self, out, indptr, prefix, pages, valid, swa_pages):
        rows = prefix.numel(); width = self._pages(pages, rows)
        self._indptr(indptr, rows)
        if out.ndim != 1 or out.dtype != torch.int32:
            raise ValueError('tail output must be int32 vector')
        self._launch(4, (out, indptr, prefix, pages, valid),
            (_vector(prefix, rows), _vector(valid, rows), width, swa_pages), rows)
    @staticmethod
    def _indptr(indptr, rows):
        if indptr.shape != (rows + 1,) or indptr.dtype != torch.int32:
            raise ValueError('indptr must be int32 [rows+1]')
    def prefill_indices(self, pos, chunk, cu, state, pages, pre_indptr,
                        ext_indptr, pre_out, ext_out, win, swa_pages, ring_stride):
        rows = pos.numel(); width = self._pages(pages, rows)
        self._indptr(pre_indptr, rows); self._indptr(ext_indptr, rows)
        if any(t.ndim != 1 or t.dtype != torch.int32 for t in (pre_out, ext_out)):
            raise ValueError('index outputs must be int32 vectors')
        if not 1 <= win <= ring_stride <= 0x7fffffff or ring_stride < 2:
            raise ValueError('invalid SWA window/stride')
        self._launch(5, (pos, chunk, cu, state, pos if pages is None else pages,
            pre_indptr, ext_indptr, pre_out, ext_out),
            (_vector(pos, rows), _vector(chunk, rows), _vector(cu, rows),
             _vector(state, rows), width, win, swa_pages, ring_stride,
             (1 << 32) // ring_stride), rows)
    def finalize_accept(self, correct, trim, prefix, commit, new_seq, trim_out):
        n = correct.numel()
        if commit.dtype != torch.int32 or trim_out.dtype != torch.int32 or new_seq.dtype != prefix.dtype:
            raise ValueError('invalid finalize output dtypes')
        for t in (commit, new_seq, trim_out): _vector(t, n)
        self._launch(6, (correct, trim, prefix, commit, new_seq, trim_out),
            (n, _vector(correct, n), _vector(trim, n), _vector(prefix, n)), (n + 63) // 64)
    def gather_bonus(self, accept_index, predicts, correct, out):
        if accept_index.ndim != 2 or predicts.ndim != 1 or out.dtype != torch.int64:
            raise ValueError('invalid gather shapes or output dtype')
        n, cols = accept_index.shape
        if not 1 <= cols <= 64: raise ValueError('accept-index width must be <= 64')
        _vector(out, n)
        self._launch(7, (accept_index, predicts, correct, out),
            (n, cols, _integer(accept_index), _integer(predicts), _vector(correct, n)), (n + 63) // 64)
    def build_out_tokens(self, draft, correct, bonus, out):
        if draft.ndim != 2 or out.ndim != 2 or draft.shape[0] != out.shape[0]:
            raise ValueError('invalid output-token matrices')
        n, gamma = draft.shape
        if not 1 <= gamma <= 64 or not 1 <= out.shape[1] <= 64:
            raise ValueError('gamma and output width must be <= 64')
        if any(t.dtype != torch.int64 for t in (draft, correct, bonus, out)):
            raise ValueError('output-token buffers must be int64')
        _vector(correct, n); _vector(bonus, n)
        width = out.shape[1]
        if width & (width - 1):
            self._launch(8, (draft, correct, bonus, out), (gamma, width), n)
        else:
            self._launch(10, (draft, correct, bonus, out),
                (gamma, width, width.bit_length() - 1, n * width), (n * width + 63) // 64)
    def compressed_metadata(self, seq, pos, raw_loc, pages, outputs, page_size=256):
        n = seq.numel()
        if raw_loc.dtype != torch.int64 or len(outputs) != 9:
            raise ValueError('raw locations must be int64; nine output buffers required')
        _vector(raw_loc, n)
        for i,t in enumerate(outputs[:8]):
            _vector(t, n)
            if t.dtype != (torch.int64 if i in (0,4) else torch.int32):
                raise ValueError('invalid compressed-metadata output dtype')
        max_pages = self._pages(pages, n)
        if page_size < 128 or page_size % 128:
            raise ValueError('page size must be a multiple of 128')
        ratio = page_size // 128
        if ratio & (ratio-1): raise ValueError('compressed page size must be a power of two')
        width = max_pages * ratio
        if outputs[8].shape != (n,width) or outputs[8].dtype != torch.int32:
            raise ValueError('invalid compressed page-index output')
        self._launch(9, (seq, pos, raw_loc, seq if pages is None else pages, *outputs),
            (_vector(seq,n), _vector(pos,n), max_pages, width, ratio.bit_length()-1), n)
    def close(self):
        """Caller must finish eager and captured graph uses first."""
        if self.handle.value:
            with torch.cuda.device(self.device):
                self._check(self.lib.netra_control_close(self.handle))
            self.handle = ctypes.c_void_p()
