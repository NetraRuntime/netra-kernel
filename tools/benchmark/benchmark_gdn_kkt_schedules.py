import json, statistics, sys, torch
sys.path.insert(0, "/root/work/sglang-main/python")
from sglang.kernels.ops.attention.fla.chunk_fwd import chunk_gated_delta_rule_fwd_kkt_solve_kernel as std
from sglang.srt.hardware_backend.xpu.kernels.fla.chunk_fwd import chunk_gated_delta_rule_fwd_kkt_solve_kernel_low_reg as low
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices
B,T,H,Hg,K,BT,BC=1,8192,32,16,128,64,16
NT=T//BT
torch.manual_seed(1151)
k=(torch.randn((B,T,Hg,K),device="cuda",dtype=torch.bfloat16)*0.03).contiguous()
g=torch.cumsum(torch.randn((B,T,H),device="cuda",dtype=torch.float32)*0.001,dim=1).contiguous()
beta=torch.sigmoid(torch.randn((B,T,H),device="cuda",dtype=torch.float32)).to(torch.bfloat16).contiguous()
cu=torch.tensor([0,T],device="cuda",dtype=torch.int64)
ci=prepare_chunk_indices(cu,BT)
ref=torch.empty((B,T,H,BT),device="cuda",dtype=torch.bfloat16)
out=torch.empty_like(ref)
def launch(fn,dst,bk,warps):
 fn[(NT,B*H)](k=k,g=g,beta=beta,A=dst,cu_seqlens=cu,chunk_indices=ci,T=T,H=H,Hg=Hg,K=K,BT=BT,BC=BC,BK=bk,USE_G=True,IS_VARLEN=True,num_warps=warps,num_stages=3)
def timed(fn,n=5):
 for _ in range(2): fn()
 torch.cuda.synchronize(); samples=[]
 for _ in range(n):
  a=torch.cuda.Event(enable_timing=True);b=torch.cuda.Event(enable_timing=True);a.record();fn();b.record();b.synchronize();samples.append(a.elapsed_time(b))
 return samples
base=std.fn.fn
ref.zero_();launch(base,ref,64,4);torch.cuda.synchronize()
rows=[]
bs=timed(lambda:launch(base,ref,64,4))
rows.append({"kind":"production","bk":64,"warps":4,"median_ms":statistics.median(bs),"samples_ms":bs,"bit_mismatches":0,"max_abs":0.0})
for bk,warps in [(64,1),(64,2),(32,1),(32,2),(32,4)]:
 out.zero_();launch(base,out,bk,warps);torch.cuda.synchronize();delta=(out.float()-ref.float()).abs();bits=int((out.view(torch.int16)!=ref.view(torch.int16)).sum());s=timed(lambda:launch(base,out,bk,warps),3);rows.append({"kind":"standard_schedule","bk":bk,"warps":warps,"median_ms":statistics.median(s),"samples_ms":s,"bit_mismatches":bits,"max_abs":float(delta.max()),"mean_abs":float(delta.mean())})
for bk,warps in [(64,4),(64,8),(32,4),(32,8)]:
 out.zero_();launch(low.fn.fn,out,bk,warps);torch.cuda.synchronize();delta=(out.float()-ref.float()).abs();bits=int((out.view(torch.int16)!=ref.view(torch.int16)).sum());s=timed(lambda:launch(low.fn.fn,out,bk,warps),3);rows.append({"kind":"low_reg","bk":bk,"warps":warps,"median_ms":statistics.median(s),"samples_ms":s,"bit_mismatches":bits,"max_abs":float(delta.max()),"mean_abs":float(delta.mean())})
production_ms=rows[0]["median_ms"]
for row in rows:
 row["speedup_vs_production"] = production_ms / row["median_ms"]
print(json.dumps({"target":"gfx1151","measurement_status":"measured","shape":{"B":B,"T":T,"H":H,"Hg":Hg,"K":K,"BT":BT,"BC":BC},"timing":"HIP events","results":rows},indent=2))
