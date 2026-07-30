#!/usr/bin/env python3
"""Exact-shape raw-vs-raw correctness, HIP-event, and graph gate on Netra/gfx1151."""
import argparse, ctypes, json, socket, statistics
from pathlib import Path
import torch
from sglang.kernels.ops.attention.fla.chunk_o import chunk_fwd_kernel_o
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices

def ptr(t): return ctypes.c_void_p(t.data_ptr())
def measure(op, samples):
    for _ in range(3): op()
    torch.cuda.synchronize(); out=[]
    for _ in range(samples):
        a=torch.cuda.Event(enable_timing=True); b=torch.cuda.Event(enable_timing=True)
        a.record(); op(); b.record(); b.synchronize(); out.append(a.elapsed_time(b))
    return out

def main():
    p=argparse.ArgumentParser(); p.add_argument('--launcher-so',type=Path,required=True)
    p.add_argument('--baseline-hsaco',type=Path,required=True); p.add_argument('--candidate-hsaco',type=Path,required=True)
    p.add_argument('--candidate-symbol',default='gdn_chunk_o_bv32_batch2_gfx1151')
    p.add_argument('--samples',type=int,default=11); p.add_argument('--seed',type=int,default=3007); p.add_argument('--output',type=Path)
    a=p.parse_args()
    if socket.gethostname()!='Netra': raise SystemExit('refusing to run outside Netra')
    lib=ctypes.CDLL(str(a.launcher_so)); lib.netra_gdn_chunk_o_dual_init.argtypes=[ctypes.c_char_p,ctypes.c_char_p,ctypes.c_char_p]
    lib.netra_gdn_chunk_o_dual_init.restype=ctypes.c_int
    lib.netra_gdn_chunk_o_dual_launch.argtypes=[ctypes.c_int]+[ctypes.c_void_p]*8+[ctypes.c_float,ctypes.c_uint,ctypes.c_void_p]
    lib.netra_gdn_chunk_o_dual_launch.restype=ctypes.c_int
    st=lib.netra_gdn_chunk_o_dual_init(str(a.baseline_hsaco).encode(),str(a.candidate_hsaco).encode(),a.candidate_symbol.encode())
    if st: raise RuntimeError(f'dual init HIP status {st}')
    torch.manual_seed(a.seed)
    q=(torch.randn((1,8192,16,128),device='cuda')*.01).bfloat16(); k=(torch.randn_like(q)*.01).bfloat16()
    v=(torch.randn((1,8192,32,128),device='cuda')*.01).bfloat16()
    h=(torch.randn((1,128,32,128,128),device='cuda')*.01).bfloat16()
    g=(-torch.rand((1,8192,32),device='cuda')*.002).cumsum(1)
    cu=torch.tensor([0,8192],device='cuda',dtype=torch.int32); ci=prepare_chunk_indices(cu,64); scale=128**-.5
    ref=torch.empty_like(v); base=torch.empty_like(v); cand=torch.empty_like(v)
    def raw(which,out):
        st=lib.netra_gdn_chunk_o_dual_launch(which,ptr(q),ptr(k),ptr(v),ptr(h),ptr(g),ptr(out),ptr(cu),ptr(ci),scale,8192,ctypes.c_void_p(torch.cuda.current_stream().cuda_stream))
        if st: raise RuntimeError(f'launch HIP status {st}')
    def triton(): chunk_fwd_kernel_o[(4,128,32)](q,k,v,h,g,ref,cu,ci,scale,T=8192,H=32,Hg=16,K=128,V=128,BT=64,BK=64,BV=32,USE_G=True,IS_VARLEN=True,num_warps=8,num_stages=2)
    bop=lambda:raw(0,base); cop=lambda:raw(1,cand)
    cop(); torch.cuda.synchronize(); cand_first=cand.clone()
    cop(); torch.cuda.synchronize(); repeat_equal=torch.equal(cand,cand_first)
    triton(); bop(); torch.cuda.synchronize()
    base_diff=(base.float()-ref.float()).abs(); cand_diff=(cand.float()-ref.float()).abs()
    bit_equal=torch.equal(base,cand)
    bt=[]; ct=[]
    for i in range(a.samples):
        first,second=(bop,cop) if i%2==0 else (cop,bop)
        x=measure(first,1)[0]; y=measure(second,1)[0]
        if i%2==0: bt.append(x);ct.append(y)
        else: ct.append(x);bt.append(y)
    graph=torch.cuda.CUDAGraph(); cop(); torch.cuda.synchronize()
    with torch.cuda.graph(graph): cop()
    graph.replay(); torch.cuda.synchronize(); graph_equal=torch.equal(base,cand)
    gt=measure(graph.replay,a.samples)
    r={'target':'gfx1151','measurement_status':'measured','shape':'B1_T8192_H32_Hg16_K128_V128_BT64',
       'baseline_median_hip_event_ms':statistics.median(bt),'candidate_median_hip_event_ms':statistics.median(ct),
       'speedup':statistics.median(bt)/statistics.median(ct),'baseline_samples_ms':bt,'candidate_samples_ms':ct,
       'raw_bit_equal':bit_equal,'baseline_max_abs_vs_triton':base_diff.max().item(),'candidate_max_abs_vs_triton':cand_diff.max().item(),
       'candidate_mean_abs_vs_triton':cand_diff.mean().item(),'finite':torch.isfinite(cand).all().item(),
       'candidate_repeat_bit_equal':repeat_equal,'graph_bit_equal_to_baseline':graph_equal,'graph_replay_median_ms':statistics.median(gt),'graph_samples_ms':gt}
    text=json.dumps(r,indent=2,sort_keys=True)+'\n'; print(text,end='')
    if a.output: a.output.parent.mkdir(parents=True,exist_ok=True); a.output.write_text(text)
if __name__=='__main__': main()
