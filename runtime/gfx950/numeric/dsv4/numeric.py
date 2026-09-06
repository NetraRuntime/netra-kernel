# SPDX-License-Identifier: MIT
"""Explicit gfx950 numeric primitives, with no implicit serving replacement.

Positions, token IDs and expert IDs must be valid nonnegative int32 indices;
input/output tensors may not alias except the explicitly in-place RoPE operation.
Temperature/noise and NaN contracts are defined by each operation, not repaired
by host-side readbacks. Streams and graph lifetimes belong to the caller.
"""
import ctypes
import struct
from pathlib import Path
import torch

_NAMES = ('rope_flat', 'hash_topk', 'online_combine', 'rms_fp8_4096', 'router_256', 'online_partial_1024', 'hc_head_4096', 'softmax_tile_stats', 'softmax_combine', 'softmax_apply', 'classic_accept', 'classic_tile_sum', 'classic_sample')
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

class Numeric:
    def __init__(self, build_dir, device=None, waves=None):
        if waves not in (None, 1, 4): raise ValueError('waves must be 1, 4 or automatic')
        self.waves = waves
        self.device = torch.device('cuda', torch.cuda.current_device() if device is None else device)
        self.lib = ctypes.CDLL(str(Path(build_dir) / 'libnetra_numeric.so'))
        p, u = ctypes.c_void_p, ctypes.c_uint32
        self.lib.netra_numeric_error.restype = ctypes.c_char_p
        self.lib.netra_numeric_create.argtypes = [ctypes.c_char_p, ctypes.POINTER(p)]
        self.lib.netra_numeric_launch.argtypes = [p, u, p, u, p]
        self.lib.netra_numeric_close.argtypes = [p]
        self.handle = p()
        with torch.cuda.device(self.device):
            self._check(self.lib.netra_numeric_create(
                str(Path(build_dir) / 'numeric.hsaco').encode(), ctypes.byref(self.handle)))
    def _check(self, status):
        if status:
            raise RuntimeError(self.lib.netra_numeric_error().decode())
    def _launch(self, mode, tensors, scalars, rows):
        if not self.handle.value:
            raise RuntimeError('module is closed')
        if not 0 <= rows <= 0x7fffffff:
            raise ValueError('row count exceeds launch contract')
        if any(t.device != self.device for t in tensors):
            raise ValueError('all tensors must be on the owning device')
        if any(not 0 <= int(v) <= 0xffffffff for v in scalars):
            raise ValueError('scalar exceeds ABI')
        if not rows:
            return
        # Per-call host storage: concurrent callers never share mutable arguments.
        args = _Args()
        for i, t in enumerate(tensors): args.p[i] = t.data_ptr()
        for i, v in enumerate(scalars): args.a[i] = int(v)
        args.a[15] = rows
        if self.waves == 4 or (self.waves is None and rows >= 128 and (mode != 4 or rows > 1024)): mode += len(_NAMES)
        with torch.cuda.device(self.device):
            self._check(self.lib.netra_numeric_launch(self.handle, mode,
                ctypes.byref(args), rows, torch.cuda.current_stream(self.device).cuda_stream))
    @staticmethod
    def _contiguous(*ts):
        if any(not t.is_contiguous() for t in ts): raise ValueError('contiguous buffers required')
    def rope_flat(self, x, freqs, positions=None, inverse=False):
        if x.ndim!=3 or x.dtype!=torch.bfloat16 or x.stride(2)!=1:
            raise ValueError('RoPE requires bf16 [tokens,heads,RD] with unit inner stride')
        n,heads,rd=x.shape
        if not heads or heads & (heads-1) or rd<2 or rd & (rd-1): raise ValueError('power-of-two heads and rotary dimension required')
        if x.stride(1)<rd or x.stride(0)<heads*x.stride(1): raise ValueError('overlapping RoPE rows')
        if freqs.ndim!=2 or freqs.dtype!=torch.float32 or freqs.shape[1]!=rd: raise ValueError('frequencies must be float32 [positions,RD]')
        self._contiguous(freqs)
        use=positions is not None
        if positions is not None:self._contiguous(positions);pb=_vector(positions,n)
        else:positions=freqs;pb=4
        pairs=n*heads*rd//2
        self._launch(0,(x,freqs,positions),(pairs,heads.bit_length()-1,(rd//2).bit_length()-1,
            x.stride(0)*2,x.stride(1)*2,pb,int(use),int(inverse),freqs.stride(0)*4),(pairs+63)//64)
    def hash_topk(self, logits, tokens, mapping, weights, ids, scaling):
        if logits.ndim!=2 or mapping.ndim!=2 or weights.ndim!=2 or ids.shape!=weights.shape:
            raise ValueError('invalid hash routing shapes')
        n,experts=logits.shape;k=mapping.shape[1];fused=weights.shape[1]
        if logits.dtype not in (torch.bfloat16,torch.float32) or weights.dtype!=torch.float32 or ids.dtype!=torch.int32:
            raise ValueError('invalid hash routing dtypes')
        if weights.shape[0]!=n or not 1<=k<=fused<=64 or scaling<=0: raise ValueError('invalid hash routing configuration')
        self._contiguous(logits,tokens,mapping,weights,ids)
        self._launch(1,(logits,tokens,mapping,weights,ids),
            (experts,k,fused,_vector(tokens,n),_integer(mapping),_bits(1.0/scaling),logits.element_size()),n)
    def online_combine(self, maxima, keys, indices, out):
        if maxima.ndim!=2 or keys.shape!=maxima.shape or indices.shape!=maxima.shape:
            raise ValueError('matching tile matrices required')
        n,tiles=maxima.shape
        if not 1<=tiles<=128 or maxima.dtype!=torch.float32 or keys.dtype!=torch.float32 or indices.dtype!=torch.int32 or out.dtype!=torch.int64:
            raise ValueError('invalid tile combine configuration')
        _vector(out,n);self._contiguous(maxima,keys,indices,out)
        self._launch(2,(maxima,keys,indices,out),(tiles,),n)
    def rms_fp8_4096(self, x, weight, quant, scales, normalized, eps):
        if x.ndim!=2 or x.shape[1]!=4096 or x.dtype!=torch.bfloat16 or weight.shape!=(4096,) or weight.dtype!=torch.bfloat16:
            raise ValueError('requires 4096-wide bf16 RMS input/weight')
        n=x.shape[0]
        if quant.shape!=x.shape or quant.dtype!=torch.float8_e4m3fn or scales.shape!=(n,32) or scales.dtype!=torch.float32:
            raise ValueError('FP8 E4M3FN output and float32 group-128 scales required')
        store=normalized is not None
        normalized=x if normalized is None else normalized
        if normalized.shape!=x.shape or normalized.dtype!=torch.bfloat16 or eps<=0: raise ValueError('invalid RMS normalized output/epsilon')
        self._contiguous(x,weight,quant,normalized)
        if not (scales.stride(1)==1 and scales.stride(0)>=32 or scales.stride(0)==1 and scales.stride(1)>=n):
            raise ValueError('scales require non-overlapping row or column major layout')
        self._launch(3,(x,weight,quant,scales,normalized),(_bits(eps),quant.stride(0),scales.stride(0)*4,
            scales.stride(1)*4,normalized.stride(0)*2,x.stride(0)*2,int(store)),n)
    @staticmethod
    def _recip(n):
        return (1<<32)//n if n>1 else 0
    def router_256(self, scores, bias, weights, ids, routed=6, scaling=1.0, renormalize=True, apply_scale=False):
        if scores.ndim!=2 or scores.shape[1]!=256 or scores.dtype!=torch.bfloat16 or bias.shape!=(256,) or bias.dtype!=torch.bfloat16:
            raise ValueError('router requires bf16 scores and bias for 256 ungrouped experts')
        n=scores.shape[0]
        if weights.ndim!=2 or weights.shape[0]!=n or ids.shape!=weights.shape or weights.dtype!=torch.float32 or ids.dtype!=torch.int32:
            raise ValueError('invalid routing outputs')
        k=weights.shape[1]
        if not 1<=routed<=k<=64 or scaling<=0: raise ValueError('invalid routing options')
        self._contiguous(scores,bias,weights,ids)
        self._launch(4,(scores,bias,weights,ids),(k,routed,int(renormalize),int(apply_scale),_bits(scaling)),n)
    def online_partial(self, logits, temperatures, greedy, noise, maxima, keys, indices):
        if logits.ndim!=2 or logits.dtype!=torch.float32 or noise.shape!=logits.shape or noise.dtype!=torch.float32:
            raise ValueError('float32 logits/noise matrices required')
        n,v=logits.shape;tiles=(v+1023)//1024
        if not 1<=tiles<=128 or temperatures.shape!=(n,) or temperatures.dtype!=torch.float32 or greedy.shape!=(n,) or greedy.dtype!=torch.int32:
            raise ValueError('invalid sampler input shape/type')
        if any(t.shape!=(n,tiles) for t in (maxima,keys,indices)) or maxima.dtype!=torch.float32 or keys.dtype!=torch.float32 or indices.dtype!=torch.int32:
            raise ValueError('invalid sampler tile buffers')
        self._contiguous(logits,temperatures,greedy,noise,maxima,keys,indices)
        self._launch(5,(logits,temperatures,greedy,noise,maxima,keys,indices),
            (v,logits.stride(0)*4,tiles,self._recip(tiles)),n*tiles)
    def hc_head_4096(self, x, fn, scale, base, out, norm_eps, hc_eps):
        if x.ndim!=3 or x.shape[1:]!=(4,4096) or x.dtype!=torch.bfloat16 or fn.shape!=(4,16384) or fn.dtype!=torch.float32:
            raise ValueError('requires hc_mult=4, hidden=4096, bf16 x and float32 mixer')
        if scale.numel()!=1 or scale.dtype!=torch.float32 or base.shape!=(4,) or base.dtype!=torch.float32 or out.shape!=(x.shape[0],4096) or out.dtype!=torch.bfloat16:
            raise ValueError('invalid mixer outputs/parameters')
        self._contiguous(x,fn,scale,base,out)
        self._launch(6,(x,fn,scale,base,out),(_bits(norm_eps),_bits(hc_eps)),x.shape[0])
    def softmax_temp(self, logits, temperatures, out, tile_max, tile_sum, row_max, inv_sum, rows_per_request=1):
        if logits.ndim!=2 or logits.dtype!=torch.float32 or out.shape!=logits.shape or out.dtype!=torch.float32:
            raise ValueError('float32 softmax matrices required')
        n,v=logits.shape;tiles=(v+1023)//1024;chunks=(v+255)//256
        if not 1<=tiles<=128 or rows_per_request<1 or temperatures.shape!=((n+rows_per_request-1)//rows_per_request,) or temperatures.dtype!=torch.float32:
            raise ValueError('invalid temperatures or vocabulary')
        if any(t.shape!=(n,tiles) or t.dtype!=torch.float32 for t in (tile_max,tile_sum)) or any(t.shape!=(n,) or t.dtype!=torch.float32 for t in (row_max,inv_sum)):
            raise ValueError('invalid caller-owned softmax workspace')
        self._contiguous(logits,temperatures,out,tile_max,tile_sum,row_max,inv_sum)
        self._launch(7,(logits,temperatures,tile_max,tile_sum),
            (v,logits.stride(0)*4,tiles,self._recip(tiles),rows_per_request,self._recip(rows_per_request)),n*tiles)
        self._launch(8,(tile_max,tile_sum,row_max,inv_sum),(tiles,),n)
        self._launch(9,(logits,temperatures,row_max,inv_sum,out),
            (v,logits.stride(0)*4,chunks,self._recip(chunks),rows_per_request,self._recip(rows_per_request)),n*chunks)
    def classic_sample(self, predicts, accept_index, count, candidates, retrieve, uniform, final_uniform, target, draft, state, tile_sum):
        if candidates.ndim!=2 or candidates.dtype!=torch.int64 or retrieve.shape!=candidates.shape or retrieve.dtype!=torch.int64:
            raise ValueError('int64 candidate/retrieve matrices required')
        n,slots=candidates.shape
        if slots<1 or target.ndim!=3 or target.shape[:2]!=(n,slots) or target.dtype!=torch.float32 or draft.ndim!=3 or draft.shape[0]!=n or draft.shape[1]<slots-1 or draft.shape[2]!=target.shape[2] or draft.dtype!=torch.float32:
            raise ValueError('invalid target/draft probabilities')
        v=target.shape[2];tiles=(v+4095)//4096
        if not 1<=tiles<=32 or v%16: raise ValueError('classic sampler requires vocabulary divisible by 16 and <=131072')
        if predicts.ndim!=1 or predicts.dtype!=torch.int32 or accept_index.shape!=(n,slots) or accept_index.dtype!=torch.int32 or count.shape!=(n,) or count.dtype!=torch.int32:
            raise ValueError('invalid acceptance outputs')
        if uniform.ndim!=2 or uniform.shape[0]!=n or uniform.shape[1]<slots-1 or uniform.dtype!=torch.float32 or final_uniform.shape!=(n,) or final_uniform.dtype!=torch.float32:
            raise ValueError('invalid supplied random draws')
        if state.shape!=(n,4) or state.dtype!=torch.int32 or tile_sum.shape!=(n,tiles) or tile_sum.dtype!=torch.float32:
            raise ValueError('invalid caller-owned sampling workspace')
        ts=(predicts,accept_index,count,candidates,retrieve,uniform,final_uniform,target,draft,state,tile_sum)
        self._contiguous(*ts)
        args=(slots,v,candidates.stride(0)*8,retrieve.stride(0)*8,uniform.stride(0)*4,
            target.stride(0)*4,target.stride(1)*4,draft.stride(0)*4,draft.stride(1)*4,accept_index.stride(0)*4,tiles,self._recip(tiles))
        self._launch(10,ts,args,n)
        self._launch(11,ts,args,n*tiles)
        self._launch(12,ts,args,n*tiles)
    def close(self):
        """Caller must finish eager and captured graph uses first."""
        if self.handle.value:
            with torch.cuda.device(self.device):
                self._check(self.lib.netra_numeric_close(self.handle))
            self.handle = ctypes.c_void_p()
