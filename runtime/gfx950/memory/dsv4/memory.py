# SPDX-License-Identifier: MIT
"""gfx950 request/cache primitives with explicit output buffers.

Semantic bounds are caller contracts: nonnegative int32 metadata, prefix <= seq,
request indices within the table, sums and output sizes below 2**31, distinct
written request rows. Prefix-pointer arrays must reference live int64 GPU storage.
The caller owns those pointed-to allocations through completion of every stream
and captured graph use. Table values are int32; location values are int64.
"""
import ctypes
import struct
from pathlib import Path
import torch

_NAMES = ('get_last_loc', 'compute_position', 'assign_cache_locs', 'expand_prefill', 'write_req_pool', 'alloc_extend', 'vocab_embedding')
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

class Memory:
    def __init__(self, build_dir, device=None, waves=None):
        if waves not in (None, 1, 4): raise ValueError('waves must be 1, 4 or automatic')
        self.waves = waves
        self.device = torch.device('cuda', torch.cuda.current_device() if device is None else device)
        self.lib = ctypes.CDLL(str(Path(build_dir) / 'libnetra_memory.so'))
        p, u = ctypes.c_void_p, ctypes.c_uint32
        self.lib.netra_memory_error.restype = ctypes.c_char_p
        self.lib.netra_memory_create.argtypes = [ctypes.c_char_p, ctypes.POINTER(p)]
        self.lib.netra_memory_launch.argtypes = [p, u, p, u, p]
        self.lib.netra_memory_close.argtypes = [p]
        self.handle = p()
        with torch.cuda.device(self.device):
            self._check(self.lib.netra_memory_create(
                str(Path(build_dir) / 'memory.hsaco').encode(), ctypes.byref(self.handle)))
    def _check(self, status):
        if status:
            raise RuntimeError(self.lib.netra_memory_error().decode())
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
            self._check(self.lib.netra_memory_launch(self.handle, mode,
                ctypes.byref(args), rows, torch.cuda.current_stream(self.device).cuda_stream))
    def _tiled(self, mode, tensors, scalars, rows, work):
        # Output cardinality is host metadata; no GPU readback or shared scratch.
        # A request tile owns lane + 64*tile + k*(64*tiles).
        target=max(1,(work+max(rows,1)*512-1)//(max(rows,1)*512))
        tiles=1
        while tiles<target and rows*(tiles*2)<=65535: tiles*=2
        scalars=tuple(scalars)+(0,)*(13-len(scalars))+(64*tiles,tiles.bit_length()-1)
        self._launch(mode,tensors,scalars,rows*tiles)
    @staticmethod
    def _table(t):
        if t.ndim != 2 or t.dtype != torch.int32:
            raise ValueError('request table must be int32 matrix')
        return t.shape[1]
    def get_last_loc(self, table, req, prefix, out):
        n=req.numel()
        if out.dtype != torch.int32: raise ValueError('last location output must be int32')
        _vector(out,n)
        self._launch(0,(table,req,prefix,out),
            (n,self._table(table),_vector(req,n),_vector(prefix,n)),(n+63)//64)
    def compute_position(self, prefix, extend, positions, starts):
        n=extend.numel()
        if positions.ndim!=1 or positions.dtype!=torch.int64 or starts.dtype!=torch.int32:
            raise ValueError('positions int64 vector and starts int32 vector required')
        _vector(starts,n)
        has=prefix is not None
        prefix=extend if prefix is None else prefix
        self._tiled(1,(positions,starts,prefix,extend),
            (_vector(prefix,n),_vector(extend,n),int(has)),n,positions.numel())
    def assign_cache_locs(self, req, table, start, end, locs, write=False):
        n=req.numel()
        if locs.ndim!=1 or locs.dtype!=torch.int64: raise ValueError('locations must be int64 vector')
        self._tiled(2,(req,table,start,end,locs),
            (self._table(table),_vector(req,n),_vector(start,n),_vector(end,n),int(write)),n,locs.numel())
    def expand_prefill(self, req, seq, extend, causal, repeated, num_tokens):
        n=req.numel()
        if n==0: raise ValueError('causal expansion requires at least one request')
        if causal.ndim!=1 or causal.dtype!=torch.int32 or repeated.shape!=causal.shape or repeated.dtype!=req.dtype:
            raise ValueError('invalid causal/repeated output')
        if not 0<=num_tokens<=causal.numel(): raise ValueError('invalid unpadded token count')
        self._tiled(3,(req,seq,extend,causal,repeated),
            (_vector(req,n),_vector(seq,n),_vector(extend,n),n,num_tokens,causal.numel()),n,causal.numel())
    def write_req_pool(self, table, req, prefix_ptrs, pre, seq, extend, locs, prefix_tokens=0):
        n=req.numel()
        if prefix_ptrs.dtype!=torch.int64 or locs.ndim!=1 or locs.dtype!=torch.int64:
            raise ValueError('prefix pointers and locations must be int64')
        if not 0<=prefix_tokens<0x80000000: raise ValueError('invalid prefix-work hint')
        _vector(prefix_ptrs,n)
        self._tiled(4,(table,req,prefix_ptrs,pre,seq,extend,locs),
            (self._table(table),_vector(req,n),_vector(pre,n),_vector(seq,n),_vector(extend,n)),n,locs.numel()+prefix_tokens)
    def alloc_extend(self, pre, seq, last, free, out, page_size=256):
        n=pre.numel()
        if page_size<1 or page_size & (page_size-1): raise ValueError('power-of-two page size required')
        if any(t.ndim!=1 or t.dtype!=torch.int64 for t in (last,free,out)):
            raise ValueError('last/free/output must be int64 vectors')
        _vector(last,n)
        self._tiled(5,(pre,seq,last,free,out),
            (_vector(pre,n),_vector(seq,n),page_size.bit_length()-1),n,out.numel())
    def vocab_embedding(self, tokens, weight, out, org_start, org_end, padding, added_start, added_end):
        n=tokens.numel()
        if tokens.ndim!=1 or weight.ndim!=2 or out.shape!=(n,weight.shape[1]):
            raise ValueError('invalid embedding shapes')
        if weight.dtype not in (torch.bfloat16,torch.float16) or out.dtype!=weight.dtype or weight.shape[1]%8:
            raise ValueError('16-bit embedding with width divisible by eight required')
        if any(t.data_ptr()%16 for t in (weight,out)): raise ValueError('embedding bases must be 16-byte aligned')
        if not 0<=org_start<=org_end<=0x7fffffff or not 0<=added_start<=added_end<=0x7fffffff or padding<0:
            raise ValueError('invalid vocabulary ranges')
        if org_end-org_start+padding+added_end-added_start>weight.shape[0]: raise ValueError('weight rows insufficient')
        self._launch(6,(tokens,weight,out),(_integer(tokens),out.shape[1]*2,
            weight.stride(0)*2,org_start,org_end,added_start,added_end,padding),n)
    def close(self):
        """Caller must finish eager and captured graph uses first."""
        if self.handle.value:
            with torch.cuda.device(self.device):
                self._check(self.lib.netra_memory_close(self.handle))
            self.handle = ctypes.c_void_p()
