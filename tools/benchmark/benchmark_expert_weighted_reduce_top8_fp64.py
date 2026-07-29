#!/usr/bin/env python3
import ctypes,json,statistics,torch
LIB='/root/netra-mxfp4-gfx1151/build/sglang/libnetra_mxfp4_sgl.so'
def ptr(x):return ctypes.c_void_p(x.data_ptr())
lib=ctypes.CDLL(LIB);lib.netra_mxfp4_sgl_init.restype=ctypes.c_int;assert lib.netra_mxfp4_sgl_init()==0
lib.netra_expert_weighted_reduce_fp64.argtypes=[ctypes.c_void_p]*4+[ctypes.c_uint,ctypes.c_void_p];lib.netra_expert_weighted_reduce_fp64.restype=ctypes.c_int
stream=ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
def run(tokens,rows):
 torch.manual_seed(1151+tokens);e=torch.randn((rows,2048),device='cuda');p=torch.randperm(rows,device='cuda',dtype=torch.int64)[:tokens*8].to(torch.int32).view(tokens,8);w=torch.rand((tokens,8),device='cuda');w/=w.sum(1,keepdim=True);o=torch.empty((tokens,2048),device='cuda',dtype=torch.bfloat16)
 def raw():assert lib.netra_expert_weighted_reduce_fp64(ptr(e),ptr(p),ptr(w),ptr(o),tokens,stream)==0
 def model_ref():return (e.index_select(0,p.flatten()).view(tokens,8,2048)*w[:,:,None]).sum(1).to(torch.bfloat16)
 selected=e.index_select(0,p.flatten()).view(tokens,8,2048)
 fp64=(selected.double()*w.double()[:,:,None]).sum(1).float().to(torch.bfloat16)
 raw();torch.cuda.synchronize();delta=(o.float()-fp64.float()).abs();bits=int((o.view(torch.int16)!=fp64.view(torch.int16)).sum())
 def time(fn,n=7):
  for _ in range(2):fn()
  torch.cuda.synchronize();a=[]
  for _ in range(n):
   x=torch.cuda.Event(enable_timing=True);y=torch.cuda.Event(enable_timing=True);x.record();fn();y.record();y.synchronize();a.append(x.elapsed_time(y))
  return a
 rs=time(raw);ts=time(model_ref,5)
 return {'tokens':tokens,'rows':rows,'max_abs_vs_fp64_to_fp32_bf16':float(delta.max()),'mean_abs':float(delta.mean()),'bit_mismatches':bits,'raw_median_ms':statistics.median(rs),'model_pipeline_median_ms':statistics.median(ts),'speedup':statistics.median(ts)/statistics.median(rs),'raw_samples_ms':rs,'model_samples_ms':ts}
print(json.dumps({'target':'gfx1151','measurement_status':'measured','timing':'HIP events','device':torch.cuda.get_device_properties(0).gcnArchName,'results':[run(128,1280),run(8192,81664)]},indent=2))
