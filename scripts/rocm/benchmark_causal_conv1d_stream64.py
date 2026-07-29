#!/usr/bin/env python3
import ctypes,json,statistics,sys
import torch
sys.path.insert(0,"/root/work/sglang-main/python")
from sglang.kernels.ops.mamba.causal_conv1d_triton import causal_conv1d_fn
D=T=8192
LIB="/root/netra-mxfp4-gfx1151/build/sglang/libcausal_conv1d_stream64.so"
HSACO="/root/netra-mxfp4-gfx1151/build/sglang/causal_conv1d_stream64_gfx1151.hsaco"
STATE_HSACO="/root/netra-mxfp4-gfx1151/build/sglang/causal_conv1d_state_update_gfx1151.hsaco"
def ptr(x): return ctypes.c_void_p(x.data_ptr())
def timing(fn):
 for _ in range(3): fn()
 torch.cuda.synchronize(); samples=[]
 for _ in range(9):
  a=torch.cuda.Event(enable_timing=True);b=torch.cuda.Event(enable_timing=True);a.record();fn();b.record();b.synchronize();samples.append(a.elapsed_time(b))
 return samples

torch.manual_seed(1151)
x_td=torch.randn((T,D),device="cuda",dtype=torch.bfloat16); x=x_td.T
w=torch.randn((D,4),device="cuda",dtype=torch.bfloat16)*0.02
state=torch.randn((1,D,3),device="cuda",dtype=torch.bfloat16)
cache=torch.tensor([0],device="cuda",dtype=torch.int32); has=torch.tensor([True],device="cuda",dtype=torch.bool); q=torch.tensor([0,T],device="cuda",dtype=torch.int32)
lib=ctypes.CDLL(LIB);lib.netra_causal_conv_init.argtypes=[ctypes.c_char_p,ctypes.c_char_p];lib.netra_causal_conv_init.restype=ctypes.c_int
lib.netra_causal_conv.argtypes=[ctypes.c_void_p]*7;lib.netra_causal_conv.restype=ctypes.c_int
assert lib.netra_causal_conv_init(HSACO.encode(),STATE_HSACO.encode())==0
stream=ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
out=torch.empty_like(x_td)
raw_state=state.clone()
def raw(): assert lib.netra_causal_conv(ptr(x_td),ptr(w),ptr(raw_state),ptr(cache),ptr(has),ptr(out),stream)==0
oracle_state=state.clone()
def oracle(): return causal_conv1d_fn(x,w,None,oracle_state,q,[T],cache,has,"silu")
ref=oracle().T.contiguous(); raw();torch.cuda.synchronize(); delta=(out.float()-ref.float()).abs(); state_delta=(raw_state.float()-oracle_state.float()).abs()
rs=timing(raw); ts=timing(oracle)
print(json.dumps({"device":torch.cuda.get_device_properties(0).gcnArchName,"shape":{"T":T,"D":D,"W":4},"correctness":{"max_abs":float(delta.max()),"mean_abs":float(delta.mean()),"equal":bool(torch.equal(out,ref)),"first5_max":[float(delta[i].max()) for i in range(5)],"interior_max":float(delta[3:].max()),"state_max_abs":float(state_delta.max()),"state_equal":bool(torch.equal(raw_state,oracle_state))},"raw_ms":{"median":statistics.median(rs),"samples":rs},"triton_ms":{"median":statistics.median(ts),"samples":ts},"speedup":statistics.median(ts)/statistics.median(rs)},indent=2))
