import json,statistics,torch,triton
from sglang.kernels.ops.attention.fla.chunk_delta_h import chunk_gated_delta_rule_fwd_kernel_h_blockdim64
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices,prepare_chunk_offsets
T=8192; H=32; Hg=16; K=128; V=128; BT=64; NT=128
torch.manual_seed(1151)
k=(torch.randn((1,T,Hg,K),device='cuda')*.01).bfloat16()
w=(torch.randn((1,T,H,K),device='cuda')*.01).bfloat16()
u=(torch.randn((1,T,H,V),device='cuda')*.01).bfloat16()
g=(-torch.rand((1,T,H),device='cuda')*.002).cumsum(1)
cu=torch.tensor([0,T],device='cuda',dtype=torch.int32)
ci=prepare_chunk_indices(cu,BT); co=prepare_chunk_offsets(cu,BT)
idx=torch.tensor([0],device='cuda',dtype=torch.int32)
state0=(torch.randn((1,H,V,K),device='cuda')*.01).bfloat16()

def make(bv,nw,ns):
 h=torch.empty((1,NT,H,V,K),device='cuda',dtype=torch.bfloat16)
 vn=torch.empty_like(u); st=state0.clone()
 def op():
  chunk_gated_delta_rule_fwd_kernel_h_blockdim64.fn[(triton.cdiv(V,bv),H)](
   k,u,w,vn,g,None,h,st,idx,cu,co,T,
   H=H,Hg=Hg,K=K,V=V,BT=BT,BV=bv,USE_G=True,USE_GK=False,
   USE_INITIAL_STATE=True,INPLACE_UPDATE=True,SAVE_NEW_VALUE=True,
   IS_VARLEN=True,NT_BUCKET=1,USE_EXP2=False,num_warps=nw,num_stages=ns)
 return h,vn,st,op
configs=[(32,4,2),(16,4,2),(16,8,2),(8,4,2),(32,8,2),(32,4,1)]
base=make(*configs[0]); base[3](); torch.cuda.synchronize()
basevals=[x.clone() for x in base[:3]]
out=[]
for cfg in configs:
 h,vn,st,op=make(*cfg); st.copy_(state0); op(); torch.cuda.synchronize()
 diffs=[]
 for a,b in zip((h,vn,st),basevals):
  d=(a.float()-b.float()).abs(); diffs.append({'max':float(d.max()),'mean':float(d.mean()),'equal':bool(torch.equal(a,b))})
 vals=[]
 for _ in range(2): st.copy_(state0); op()
 torch.cuda.synchronize()
 for _ in range(7):
  st.copy_(state0); begin=torch.cuda.Event(enable_timing=True); end=torch.cuda.Event(enable_timing=True); begin.record();op();end.record();end.synchronize();vals.append(begin.elapsed_time(end))
 out.append({'BV':cfg[0],'num_warps':cfg[1],'num_stages':cfg[2],'median_ms':statistics.median(vals),'samples_ms':vals,'diffs_h_vnew_state':diffs})
 del h,vn,st
print(json.dumps({'target':'gfx1151','measurement_status':'measured','shape':'B1_T8192_H32_Hg16_K128_V128_BT64_varlen_initial_state', 'results':out},indent=2))
