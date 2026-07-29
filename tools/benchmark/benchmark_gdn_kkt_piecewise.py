#!/usr/bin/env python3
import ctypes,socket,json,statistics,sys,torch,triton,triton.language as tl
from pathlib import Path
if socket.gethostname() != 'Netra': raise SystemExit('refusing to run outside the Netra LXC')
sys.path.insert(0,'/root/work/sglang-main/python')
from sglang.kernels.ops.attention.fla.op import safe_exp
from sglang.kernels.ops.attention.fla.chunk_fwd import chunk_gated_delta_rule_fwd_kkt_solve_kernel as std
from sglang.kernels.ops.attention.fla.index import prepare_chunk_indices
@triton.jit
def solve16(a):
 o=tl.arange(0,16); inv=-a
 for i in range(2,16):
  row=tl.sum(tl.where((o==i)[:,None],-a,0.0),axis=0)
  row=tl.where(o<i,row,0.0)
  row+=tl.sum(row[:,None]*inv,axis=0)
  inv=tl.where((o==i)[:,None],row,inv)
 return inv+(o[:,None]==o[None,:])
@triton.jit
def kkt_ref(k,g,beta,out,H:tl.constexpr,Hg:tl.constexpr,K:tl.constexpr):
 p,c,h=tl.program_id(0),tl.program_id(1),tl.program_id(2)
 rb=tl.where(p==0,0,tl.where(p<=2,1,tl.where(p<=5,2,3)))
 start=tl.where(rb==0,0,tl.where(rb==1,1,tl.where(rb==2,3,6))); cb=p-start
 oi=tl.arange(0,16);oj=tl.arange(0,16);ok=tl.arange(0,128)
 ti=c*64+rb*16+oi;tj=c*64+cb*16+oj;hg=h//2
 ki=tl.load(k+(ti[:,None]*Hg+hg)*K+ok[None,:]);kj=tl.load(k+(tj[:,None]*Hg+hg)*K+ok[None,:])
 a=tl.dot(ki,tl.trans(kj));gi=tl.load(g+ti*H+h);gj=tl.load(g+tj*H+h);bi=tl.load(beta+ti*H+h).to(tl.float32)
 a=a*safe_exp(gi[:,None]-gj[None,:]);a=tl.where((rb>cb)|(oi[:,None]>oj[None,:]),a,0.0)*bi[:,None]
 tl.store(out+(ti[:,None]*H+h)*64+cb*16+oj[None,:],a)
@triton.jit
def solve_kernel(ws,out,H:tl.constexpr):
 c,h=tl.program_id(0),tl.program_id(1);o=tl.arange(0,16);base=c*64
 a00=tl.load(ws+(((base+o[:,None])*H+h)*64+o[None,:]))
 a10=tl.load(ws+(((base+16+o[:,None])*H+h)*64+o[None,:]))
 a11=tl.load(ws+(((base+16+o[:,None])*H+h)*64+16+o[None,:]))
 a20=tl.load(ws+(((base+32+o[:,None])*H+h)*64+o[None,:]))
 a21=tl.load(ws+(((base+32+o[:,None])*H+h)*64+16+o[None,:]))
 a22=tl.load(ws+(((base+32+o[:,None])*H+h)*64+32+o[None,:]))
 a30=tl.load(ws+(((base+48+o[:,None])*H+h)*64+o[None,:]))
 a31=tl.load(ws+(((base+48+o[:,None])*H+h)*64+16+o[None,:]))
 a32=tl.load(ws+(((base+48+o[:,None])*H+h)*64+32+o[None,:]))
 a33=tl.load(ws+(((base+48+o[:,None])*H+h)*64+48+o[None,:]))
 i00=solve16(a00);i11=solve16(a11);i22=solve16(a22);i33=solve16(a33)
 i10=-tl.dot(tl.dot(i11,a10,input_precision='ieee'),i00,input_precision='ieee')
 i21=-tl.dot(tl.dot(i22,a21,input_precision='ieee'),i11,input_precision='ieee')
 i32=-tl.dot(tl.dot(i33,a32,input_precision='ieee'),i22,input_precision='ieee')
 i20=-tl.dot(i22,tl.dot(a20,i00,input_precision='ieee')+tl.dot(a21,i10,input_precision='ieee'),input_precision='ieee')
 i31=-tl.dot(i33,tl.dot(a31,i11,input_precision='ieee')+tl.dot(a32,i21,input_precision='ieee'),input_precision='ieee')
 i30=-tl.dot(i33,tl.dot(a30,i00,input_precision='ieee')+tl.dot(a31,i10,input_precision='ieee')+tl.dot(a32,i20,input_precision='ieee'),input_precision='ieee')
 tl.store(out+(((base+o[:,None])*H+h)*64+o[None,:]),i00)
 tl.store(out+(((base+16+o[:,None])*H+h)*64+o[None,:]),i10)
 tl.store(out+(((base+16+o[:,None])*H+h)*64+16+o[None,:]),i11)
 tl.store(out+(((base+32+o[:,None])*H+h)*64+o[None,:]),i20)
 tl.store(out+(((base+32+o[:,None])*H+h)*64+16+o[None,:]),i21)
 tl.store(out+(((base+32+o[:,None])*H+h)*64+32+o[None,:]),i22)
 tl.store(out+(((base+48+o[:,None])*H+h)*64+o[None,:]),i30)
 tl.store(out+(((base+48+o[:,None])*H+h)*64+16+o[None,:]),i31)
 tl.store(out+(((base+48+o[:,None])*H+h)*64+32+o[None,:]),i32)
 tl.store(out+(((base+48+o[:,None])*H+h)*64+48+o[None,:]),i33)
repo=Path(__file__).resolve().parents[2]; build=repo/'build'/'experiments'
lib=ctypes.CDLL(str(build/'libgdn_kkt_build.so'));lib.gdn_kkt_init.argtypes=[ctypes.c_char_p];lib.gdn_kkt_init.restype=ctypes.c_int
lib.gdn_kkt_launch.argtypes=[ctypes.c_void_p]*5;lib.gdn_kkt_launch.restype=ctypes.c_int;lib.gdn_kkt_error.restype=ctypes.c_char_p
assert lib.gdn_kkt_init(str(build/'gdn_kkt_build_fp32_gfx1151.hsaco').encode())==0,lib.gdn_kkt_error()
lib_exact=ctypes.CDLL(str(build/'libgdn_kkt_build_compiler_frag.so'));lib_exact.gdn_kkt_init.argtypes=[ctypes.c_char_p];lib_exact.gdn_kkt_init.restype=ctypes.c_int
lib_exact.gdn_kkt_launch.argtypes=[ctypes.c_void_p]*5;lib_exact.gdn_kkt_launch.restype=ctypes.c_int;lib_exact.gdn_kkt_error.restype=ctypes.c_char_p
assert lib_exact.gdn_kkt_init(str(build/'gdn_kkt_build_fp32_compiler_frag_gfx1151.hsaco').encode())==0,lib_exact.gdn_kkt_error()
torch.manual_seed(1151);B,T,H,Hg,K,BT,BC=1,8192,32,16,128,64,16;NT=T//BT
k=(torch.randn((B,T,Hg,K),device='cuda')*.03).bfloat16().contiguous();g=torch.cumsum(torch.randn((B,T,H),device='cuda')*.001,dim=1).float().contiguous();beta=torch.sigmoid(torch.randn((B,T,H),device='cuda')).bfloat16().contiguous()
cu=torch.tensor([0,T],device='cuda',dtype=torch.int64);ci=prepare_chunk_indices(cu,BT)
prod=torch.zeros((B,T,H,BT),device='cuda',dtype=torch.bfloat16);from_ref=torch.zeros_like(prod);from_raw=torch.zeros_like(prod);from_exact=torch.zeros_like(prod);ws_ref=torch.zeros((T,H,64),device='cuda');ws_raw=torch.zeros_like(ws_ref);ws_exact=torch.zeros_like(ws_ref)
def production():std.fn.fn[(NT,B*H)](k=k,g=g,beta=beta,A=prod,cu_seqlens=cu,chunk_indices=ci,T=T,H=H,Hg=Hg,K=K,BT=BT,BC=BC,BK=64,USE_G=True,IS_VARLEN=True,num_warps=1,num_stages=3)
def build_ref():kkt_ref[(10,128,32)](k,g,beta,ws_ref,H=H,Hg=Hg,K=K,num_warps=1,num_stages=3)
def build_raw():
 st=lib.gdn_kkt_launch(k.data_ptr(),g.data_ptr(),beta.data_ptr(),ws_raw.data_ptr(),torch.cuda.current_stream().cuda_stream);assert st==0,lib.gdn_kkt_error()
def build_exact():
 st=lib_exact.gdn_kkt_launch(k.data_ptr(),g.data_ptr(),beta.data_ptr(),ws_exact.data_ptr(),torch.cuda.current_stream().cuda_stream);assert st==0,lib_exact.gdn_kkt_error()
def piece_ref():build_ref();solve_kernel[(128,32)](ws_ref,from_ref,H=H,num_warps=1,num_stages=3)
def piece_raw():build_raw();solve_kernel[(128,32)](ws_raw,from_raw,H=H,num_warps=1,num_stages=3)
def piece_exact():build_exact();solve_kernel[(128,32)](ws_exact,from_exact,H=H,num_warps=1,num_stages=3)
def timed(fn,n=5):
 for _ in range(2):fn()
 torch.cuda.synchronize();v=[]
 for _ in range(n):
  a=torch.cuda.Event(enable_timing=True);b=torch.cuda.Event(enable_timing=True);a.record();fn();b.record();b.synchronize();v.append(a.elapsed_time(b))
 return v
production();piece_ref();piece_raw();piece_exact();torch.cuda.synchronize()
def errors(x,y):
 d=(x.float()-y.float()).abs();return {'bf16_bit_mismatches':int((x.view(torch.int16)!=y.view(torch.int16)).sum()),'max_abs':float(d.max()),'mean_abs':float(d.mean())}
ps=timed(production);bc=timed(build_ref);br=timed(build_raw);be=timed(build_exact);cr=timed(piece_ref);rr=timed(piece_raw);re=timed(piece_exact)
print(json.dumps({'target':'gfx1151','measurement_status':'measured','production_schedule':'BK64_w1','compiler_piecewise_vs_production':errors(from_ref,prod),'raw_lds_piecewise_vs_production':errors(from_raw,prod),'raw_exact_piecewise_vs_production':errors(from_exact,prod),'production_samples_ms':ps,'production_median_ms':statistics.median(ps),'compiler_builder_samples_ms':bc,'compiler_builder_median_ms':statistics.median(bc),'raw_lds_builder_samples_ms':br,'raw_lds_builder_median_ms':statistics.median(br),'raw_exact_builder_samples_ms':be,'raw_exact_builder_median_ms':statistics.median(be),'compiler_piecewise_samples_ms':cr,'compiler_piecewise_median_ms':statistics.median(cr),'raw_lds_piecewise_samples_ms':rr,'raw_lds_piecewise_median_ms':statistics.median(rr),'raw_exact_piecewise_samples_ms':re,'raw_exact_piecewise_median_ms':statistics.median(re)},indent=2))
