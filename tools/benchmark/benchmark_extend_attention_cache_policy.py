#!/usr/bin/env python3
import ctypes,hashlib,json,statistics,torch

def ptr(x): return ctypes.c_void_p(x.data_ptr())
def load(path,prefix,hsaco):
 lib=ctypes.CDLL(path); init=getattr(lib,prefix+'_init'); init.argtypes=[ctypes.c_char_p]; init.restype=ctypes.c_int; assert init(hsaco.encode())==0
 fn=getattr(lib,prefix); fn.argtypes=[ctypes.c_void_p]*8+[ctypes.c_uint32,ctypes.c_float,ctypes.c_void_p]; fn.restype=ctypes.c_int; return fn
base=load('/root/netra-mxfp4-gfx1151/build/sglang/libextend_attention_wmma.so','netra_extend_attention_wmma','/root/netra-mxfp4-gfx1151/build/sglang/extend_attention_wmma_n64_gfx1151.hsaco')
glc=load('/root/netra-mxfp4-gfx1151/build/experiments/libextend_attention_wmma_glc.so','netra_extend_attention_wmma_glc','/root/netra-mxfp4-gfx1151/build/experiments/extend_attention_wmma_n64_glc_gfx1151.hsaco')
stream=ctypes.c_void_p(torch.cuda.current_stream().cuda_stream); rows=[]
for prefix in (0,8192,16384,24576):
 torch.manual_seed(20260729)
 T=8192;q=(torch.randn((T,16,256),device='cuda',dtype=torch.bfloat16)*.02).contiguous();k=(torch.randn((T,2,256),device='cuda',dtype=torch.bfloat16)*.02).contiguous();v=(torch.randn((T,2,256),device='cuda',dtype=torch.bfloat16)*.02).contiguous();kb=(torch.randn((max(prefix,1),2,256),device='cuda',dtype=torch.bfloat16)*.02).contiguous();vb=(torch.randn_like(kb)*.02).contiguous();idx=torch.arange(prefix,device='cuda',dtype=torch.int64);ip=torch.tensor([0,prefix],device='cuda',dtype=torch.int32);a=torch.empty_like(q);b=torch.empty_like(q)
 def call(fn,o): assert fn(ptr(q),ptr(k),ptr(v),ptr(o),ptr(kb),ptr(vb),ptr(idx),ptr(ip),T,.0625,stream)==0
 call(base,a);call(glc,b);torch.cuda.synchronize();d=(a.float()-b.float()).abs()
 def tm(fn,o):
  vals=[]
  for _ in range(2):call(fn,o)
  torch.cuda.synchronize()
  for _ in range(9): x=torch.cuda.Event(enable_timing=True);y=torch.cuda.Event(enable_timing=True);x.record();call(fn,o);y.record();y.synchronize();vals.append(x.elapsed_time(y))
  return vals
 av=tm(base,a);bv=tm(glc,b);raw=a.cpu().view(torch.uint8).numpy().tobytes();var=b.cpu().view(torch.uint8).numpy().tobytes()
 rows.append({'prefix_tokens':prefix,'bit_equal':bool(torch.equal(a,b)),'max_abs':float(d.max()),'mean_abs':float(d.mean()),'baseline_sha256':hashlib.sha256(raw).hexdigest(),'glc_sha256':hashlib.sha256(var).hexdigest(),'baseline_median_ms':statistics.median(av),'glc_median_ms':statistics.median(bv),'speedup':statistics.median(av)/statistics.median(bv),'baseline_samples_ms':av,'glc_samples_ms':bv})
print(json.dumps({'target':'gfx1151','measurement_status':'measured_hip_events','tokens':8192,'rows':rows},indent=2))
