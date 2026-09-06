# SPDX-License-Identifier: MIT
"""Exact-output and paired timing checks against the deployment's Triton bodies."""
import argparse, ast, importlib.util, json, random, statistics, sys, time
from pathlib import Path
import torch
import triton

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'runtime/gfx950/numeric/dsv4'))
from numeric import Numeric

p = argparse.ArgumentParser()
p.add_argument('--build', required=True)
p.add_argument('--reference-root', required=True)
p.add_argument('--output', required=True)
p.add_argument('--smoke', action='store_true')
p.add_argument('--correctness-only', action='store_true')
p.add_argument('--only-classic', action='store_true', help='Targeted sampling regression suite')
a = p.parse_args()
# Extract only the exact JIT bodies, avoiding serving imports or GPU initialization.
names = {'apply_rotary_emb_flat_kernel','_hash_topk_triton_kernel','_online_combine_kernel',
 '_fused_rms_fp8_group_quant_kernel','_rmsmorm_op','_fp8_quant_op','_router_triton_kernel',
 '_online_partial_kernel','_hc_head_kernel','_softmax_temp_kernel','speculative_sampling_classic_kernel'}
nodes = []
for path in Path(a.reference_root).rglob('*.py'):
    tree = ast.parse(path.read_text())
    nodes += [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names]
assert {n.name for n in nodes} == names and len(nodes) == len(names)
ref_file = Path(a.build) / 'reference_bodies.py'
ref_file.write_text('import triton\nimport triton.language as tl\n_IDX_SENTINEL = tl.constexpr(2147483647)\n' +
                    '\n\n'.join(ast.unparse(n) for n in nodes) + '\n')
spec = importlib.util.spec_from_file_location('netra_numeric_references', ref_file)
ref = importlib.util.module_from_spec(spec); sys.modules[spec.name] = ref
spec.loader.exec_module(ref)
variants = {'wave1': Numeric(a.build, waves=1), 'wave4': Numeric(a.build, waves=4),
            'selected': Numeric(a.build)}
report = {'state': 'running', 'device': torch.cuda.get_device_name(), 'cases': [],
          'started': time.time(), 'scope': 'Isolated component tests, synthetic inputs; no serving TPS claim.'}
stream_cases=[]
def save(): Path(a.output).write_text(json.dumps(report, indent=2) + '\n')
def guard(shape, dtype):
    count = 1
    for dim in shape: count *= dim
    storage = torch.full((count + 32,), -111, dtype=torch.float32 if dtype==torch.float8_e4m3fn else dtype, device='cuda').to(dtype)
    return storage[16:-16].view(shape), storage

def timing(fn):
    for _ in range(3): fn()
    graph = torch.cuda.CUDAGraph()
    with torch.cuda.graph(graph):
        for _ in range(5): fn()
    begin, end = torch.cuda.Event(enable_timing=True), torch.cuda.Event(enable_timing=True)
    begin.record()
    for _ in range(20): graph.replay()
    end.record(); end.synchronize()
    return begin.elapsed_time(end) * 10  # ms / (20*5) -> us

def compare(got,want,op,shape,name):
    if op=='classic_sampling' and not torch.equal(got[0],want[0]):
        idx=int(torch.nonzero(got[0]!=want[0])[0])-16
        found=torch.nonzero(classic_fixture['retrieve']==idx)
        row=int(found[0,0]) if found.numel() else 0
        fixture={k:v[row:row+1].cpu() for k,v in classic_fixture.items()}
        fixture.update(prediction_size=got[0].numel()-32, failing_index=idx,
                       got=got[0][16:-16].cpu(), reference=want[0][16:-16].cpu())
        target=Path(a.output).with_suffix('.sampling-repro.pt')
        torch.save(fixture,target)
        print('Saved exact-token regression fixture',target,flush=True)
    for x,y in zip(got,want):
        xb=x.view(torch.uint8) if x.dtype==torch.float8_e4m3fn else x
        yb=y.view(torch.uint8) if y.dtype==torch.float8_e4m3fn else y
        assert torch.equal(xb[:16],yb[:16]) and torch.equal(xb[-16:],yb[-16:]),(op,shape,name,'canary')
        if op in ('hash_topk','router_256') and x.dtype==torch.float32:
            torch.testing.assert_close(x,y,atol=2e-7,rtol=2e-6,equal_nan=True)
        elif op=='online_partial' and x.dtype==torch.float32:
            torch.testing.assert_close(x,y,atol=1e-6,rtol=2e-5,equal_nan=True)
        elif op=='softmax_temp':
            torch.testing.assert_close(x,y,atol=1e-9,rtol=3e-5,equal_nan=True)
        elif op=='hc_head':
            torch.testing.assert_close(x.float(),y.float(),atol=0.002,rtol=0.008)
        elif op=='rms_fp8' and x.dtype==torch.float8_e4m3fn:
            diff=(xb.to(torch.int16)-yb.to(torch.int16)).abs()
            if not (int(diff.max())<=1 and float((diff>0).float().mean())<=0.001):
                print('FP8 diagnostic',name,'max code diff',int(diff.max()),'mismatch rate',float((diff>0).float().mean()),flush=True)
                for xx,yy in zip(got,want):
                    xx=xx.float();yy=yy.float()
                    print('buffer',tuple(xx.shape),'max abs',float((xx-yy).abs().max()),'got',xx[16:24].tolist(),'reference',yy[16:24].tolist(),flush=True)
                raise AssertionError((op,shape,name,'FP8 rounding'))
        elif op=='rms_fp8' and x.dtype==torch.float32:
            torch.testing.assert_close(x,y,atol=0,rtol=2e-5)
        elif op=='rms_fp8' and x.dtype==torch.bfloat16:
            torch.testing.assert_close(x.float(),y.float(),atol=0,rtol=0.008)
        else:assert torch.equal(x,y),(op,shape,name,'exact mismatch',int((x!=y).sum()))
def case(op,shape,make,mutate=None):
    fns,buffers=make()
    for fn in fns.values():fn()
    for name in variants:compare(buffers[name],buffers['triton'],op,shape,name)
    item={'operation':op,'shape':shape,'passed_all_variants':True,
        'comparison':{'hash_topk':'FP32 weights rtol2e-6 atol2e-7; IDs exact','router_256':'FP32 weights rtol2e-6 atol2e-7; IDs exact','online_partial':'FP32 rtol2e-5 atol1e-6; IDs exact','softmax_temp':'FP32 rtol3e-5 atol1e-9','hc_head':'BF16 rtol0.008 atol0.002','rms_fp8':'FP8 <=1 codepoint and <=0.1% mismatch; scales rtol2e-5; BF16 rtol0.008'}.get(op,'exact')}
    if mutate is not None:
        graphs={}
        for name in variants:
            graphs[name]=torch.cuda.CUDAGraph()
            with torch.cuda.graph(graphs[name]):fns[name]()
        changed=0
        for _ in range(3):
            changed += int(mutate() is not None)
            fns['triton']()
            for name,g in graphs.items():g.replay();compare(buffers[name],buffers['triton'],op,shape,name)
        item['graph_replays']=3
        item['changed_graph_replays']=changed
    if not a.correctness_only:
        item['rounds_us']=[]
        for rep in range(5):
            order=list(fns);random.Random(rep).shuffle(order)
            item['rounds_us'].append({name:timing(fns[name]) for name in order})
        item['median_us']={name:statistics.median(x[name] for x in item['rounds_us']) for name in fns}
    report['cases'].append(item);save();print(json.dumps(item),flush=True)
    if op in ('softmax_temp','classic_sampling') and shape[0] in (1,3) and shape[1] < 5000 and (op!='classic_sampling' or shape[-1]=='random'):
        stream_cases.append((op,shape,fns,buffers))

_case=case
def case(*args,**kwargs):
    try:return _case(*args,**kwargs)
    except AssertionError as exc:
        if not a.smoke:raise
        failure={'operation':args[0],'shape':args[1],'error':str(exc)}
        report.setdefault('failures',[]).append(failure);save();print('FAILED',json.dumps(failure),flush=True)

def rope(rows,heads,rd,inverse,usepos,padded=False,far=False):
    pitch=rd+16 if padded else rd
    source=torch.randn((rows,heads,pitch),device='cuda',dtype=torch.bfloat16)
    maxpos=1048576 if far else max(rows,1)+32
    angle=torch.arange(maxpos,device='cuda',dtype=torch.float32)[:,None]*torch.exp(-torch.arange(rd//2,device='cuda',dtype=torch.float32)/16)[None,:]
    freqs=torch.stack((angle.cos(),angle.sin()),-1).flatten(1).contiguous()
    pos=torch.arange(rows,device='cuda',dtype=torch.int64).flip(0)+(1048576-rows if far else 7)
    inputs=[]
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            full,b=guard((rows,heads,pitch),torch.bfloat16);full.copy_(source);x=full[:,:,-rd:];inputs.append(x);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda x=x:ref.apply_rotary_emb_flat_kernel[(triton.cdiv(rows*heads,16),)](
                x,freqs,pos,rows*heads,heads,x.stride(0),x.stride(1),1,rd,1,USE_POS=usepos,IS_INVERSE=inverse,RD=rd,RDH=rd//2,BLOCK_ROWS=16,num_warps=1)
            else:fns[name]=lambda x=x,c=variants[name]:c.rope_flat(x,freqs,pos if usepos else None,inverse)
        return fns,buffers
    def mutate():
        for x in inputs:x.add_(0.125)
    case('rope_flat',[rows,heads,rd,inverse,usepos,padded,far],make,mutate if rows in (3,16) else None)

def hash_route(rows,experts,k,shared,dtype,extreme=False):
    logits=(torch.randn((rows,experts),device='cuda')*7).to(dtype)
    if extreme:
        logits[::3]=-100
        logits[1::3]=100
    tokens=torch.arange(rows,device='cuda',dtype=torch.int64)%37
    mapping=(torch.arange(37*k,device='cuda',dtype=torch.int32).view(37,k)*7)%experts
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            weights,wb=guard((rows,k+shared),torch.float32);ids,ib=guard((rows,k+shared),torch.int32);buffers[name]=(wb,ib)
            if name=='triton':fns[name]=lambda weights=weights,ids=ids:ref._hash_topk_triton_kernel[(rows,)](logits,tokens,mapping,weights,ids,experts,k,k+shared,2.5,BLOCK_K=triton.next_power_of_2(k+shared),num_warps=1)
            else:fns[name]=lambda weights=weights,ids=ids,c=variants[name]:c.hash_topk(logits,tokens,mapping,weights,ids,2.5)
        return fns,buffers
    case('hash_topk',[rows,experts,k,shared,str(dtype),extreme],make,lambda:logits.add_(0.5) if rows in (3,16) else None)

def combine(rows,tiles,ties=False):
    maxima=torch.randn((rows,tiles),device='cuda')*7
    keys=torch.rand((rows,tiles),device='cuda')+0.01
    indices=torch.arange(rows*tiles,device='cuda',dtype=torch.int32).view(rows,tiles).flip(1)*7
    if ties:maxima.zero_();keys.fill_(1)
    elif tiles>1:maxima[:,1]=-float('inf');keys[:,1]=-1
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((rows,),torch.int64);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda out=out:ref._online_combine_kernel[(rows,)](maxima,keys,indices,out,tiles,BLOCK_TILES=triton.next_power_of_2(tiles))
            else:fns[name]=lambda out=out,c=variants[name]:c.online_combine(maxima,keys,indices,out)
        return fns,buffers
    case('online_combine',[rows,tiles,ties],make,lambda:indices.add_(3) if rows in (3,16) else None)

def rms(rows,column_major=False,store=True,zero=False):
    x=torch.randn((rows,4096),device='cuda',dtype=torch.bfloat16)
    if zero:x.zero_()
    w=torch.randn(4096,device='cuda',dtype=torch.bfloat16)
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            quant,qb=guard(x.shape,torch.float8_e4m3fn)
            scales,sb=guard((32,rows) if column_major else (rows,32),torch.float32)
            if column_major:scales=scales.T
            norm,nb=guard(x.shape,torch.bfloat16);buffers[name]=(qb,sb,nb)
            if name=='triton':
                kw={n:1 for n in ref._fused_rms_fp8_group_quant_kernel.arg_names}
                kw.update(inp1_ptr=x,weight1_ptr=w,inp2_ptr=x,weight2_ptr=w,res1_ptr=x,
                    out1_fp8_ptr=quant,out1_bs_ptr=scales,out2_ptr=norm,out_res1_ptr=norm,out1_ptr=norm,
                    gate_ptr=x,linear_bias_ptr=w,eps1=1e-6,eps2=1e-6,n_rows=rows,inp1_n_cols=4096,inp2_n_cols=4096,
                    inp1_row_stride=4096,inp2_row_stride=4096,res1_row_stride=4096,out1_fp8_row_stride=4096,
                    out1_bs_row_stride=scales.stride(0),out1_bs_col_stride=scales.stride(1),out1_row_stride=4096,
                    out2_row_stride=4096,out_res1_row_stride=4096,stride_gate_row=4096,
                    BLOCK_SIZE_N=4096,QUANT_BLOCK_SIZE=128,DTYPE_MAX=448.,DTYPE_MIN=-448.,
                    HAVE_SECOND_INPUT=False,FIRST_INPUT_RES=False,FIRST_INPUT_OUT=store,GATED_RMS_FP8=False,
                    RMS_TILE=1024,ROWS_PER_BLOCK=1,GROUP_SIZE_GATED=128,NUM_GROUPS_GATED=32,BLOCK_G=128,
                    HAS_BIAS_GATED=False,HAS_Z_GATED=False,NORM_BEFORE_GATE=False,FP8_MIN=-448.,FP8_MAX=448.,
                    USE_UE8M0=False,FP8_MIN_SCALING_FACTOR=1e-10,ACTIVATION='silu')
                fns[name]=lambda kw=kw:ref._fused_rms_fp8_group_quant_kernel[(rows,)](**kw,num_warps=4)
            else:fns[name]=lambda q=quant,sc=scales,norm=norm,c=variants[name]:c.rms_fp8_4096(x,w,q,sc,norm if store else None,1e-6)
        return fns,buffers
    case('rms_fp8',[rows,column_major,store,zero],make,lambda:x.add_(0.125) if rows in (3,16) and not zero else None)

def router(rows,k=6,shared=1,ties=False):
    scores=(torch.randn((rows,256),device='cuda')*7).to(torch.bfloat16)
    bias=torch.randn(256,device='cuda',dtype=torch.bfloat16)*0.1
    if ties:scores.fill_(-30);bias.zero_()
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            weights,wb=guard((rows,k+shared),torch.float32);ids,ib=guard((rows,k+shared),torch.int32);buffers[name]=(wb,ib)
            if name=='triton':fns[name]=lambda weights=weights,ids=ids:ref._router_triton_kernel[(rows,)](
                scores,bias,weights,ids,rows,2.5,0.,N=256,K=k+shared,K_ROUTED=k,BLOCK_M=1,BLOCK_N=256,
                BLOCK_K=triton.next_power_of_2(k+shared),N_GROUP=1,TOPK_GROUP=1,EXPERTS_PER_GROUP=256,BLOCK_G=1,
                SCORING_FUNC=1,HAS_SOFTCAP=False,RENORMALIZE=True,APPLY_SCALE=False,USE_PDL=False,
                stride_sm=256,stride_sn=1,stride_wm=k+shared,stride_wk=1,stride_im=k+shared,stride_ik=1,num_warps=1)
            else:fns[name]=lambda weights=weights,ids=ids,c=variants[name]:c.router_256(scores,bias,weights,ids,k,2.5)
        return fns,buffers
    case('router_256',[rows,k,shared,ties],make,lambda:scores.add_(0.5) if rows in (3,16) else None)

def partial(rows,vocab=131072,greedy_only=False):
    logits=torch.randn((rows,vocab),device='cuda')*7
    temp=torch.rand(rows,device='cuda')+0.25
    greedy=(torch.arange(rows,device='cuda')%2).to(torch.int32)
    if greedy_only:greedy.fill_(1);logits.zero_()
    noise=torch.empty_like(logits).exponential_().clamp_min_(1e-7)
    tiles=triton.cdiv(vocab,1024)
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            mx,mb=guard((rows,tiles),torch.float32);key,kb=guard((rows,tiles),torch.float32);idx,ib=guard((rows,tiles),torch.int32)
            buffers[name]=(mb,kb,ib)
            if name=='triton':fns[name]=lambda mx=mx,key=key,idx=idx:ref._online_partial_kernel[(rows,tiles)](
                logits,temp,greedy,noise,mx,key,idx,vocab,vocab,tiles,BLOCK_V=1024,num_warps=4)
            else:fns[name]=lambda mx=mx,key=key,idx=idx,c=variants[name]:c.online_partial(logits,temp,greedy,noise,mx,key,idx)
        return fns,buffers
    case('online_partial',[rows,vocab,greedy_only],make,lambda:temp.add_(0.125) if rows in (3,16) else None)

def hc(rows):
    x=torch.randn((rows,4,4096),device='cuda',dtype=torch.bfloat16)
    fn=torch.randn((4,16384),device='cuda')/128
    scale=torch.tensor([0.5],device='cuda');base=torch.tensor([-1.,0.,1.,2.],device='cuda')
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((rows,4096),torch.bfloat16);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda out=out:ref._hc_head_kernel[(rows,)](x,fn,scale,base,out,
                hidden_size=4096,HC_MULT=4,K_TOTAL=16384,BLOCK_K=512,BLOCK_D=512,norm_eps=1e-6,hc_eps=1e-5,num_warps=4)
            else:fns[name]=lambda out=out,c=variants[name]:c.hc_head_4096(x,fn,scale,base,out,1e-6,1e-5)
        return fns,buffers
    case('hc_head',[rows],make,lambda:x.add_(0.125) if rows in (3,16) else None)

def softmax(rows,vocab=131072,rpr=1):
    logits=torch.randn((rows,vocab),device='cuda')*7
    temps=torch.rand(triton.cdiv(rows,rpr),device='cuda')+0.5;tiles=triton.cdiv(vocab,1024)
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((rows,vocab),torch.float32)
            ws=[guard((rows,tiles),torch.float32) for _ in range(2)]+[guard((rows,),torch.float32) for _ in range(2)]
            buffers[name]=(b,*(edge for _,storage in ws for edge in (storage[:16],storage[-16:])))
            if name=='triton':fns[name]=lambda out=out:ref._softmax_temp_kernel[(rows,)](logits,temps,out,vocab,rpr,vocab,BLOCK_V=4096,num_warps=4)
            else:fns[name]=lambda out=out,ws=ws,c=variants[name]:c.softmax_temp(logits,temps,out,*(t for t,_ in ws),rows_per_request=rpr)
        return fns,buffers
    case('softmax_temp',[rows,vocab,rpr],make,lambda:temps.add_(0.125) if rows in (3,16) else None)

def classic(rows,vocab=4096,slots=8,mode='random'):
    cand=torch.randint(0,vocab,(rows,slots),device='cuda',dtype=torch.int64)
    retrieve=torch.randperm(rows*slots,device='cuda').view(rows,slots).to(torch.int64)
    target=torch.softmax(torch.randn((rows,slots,vocab),device='cuda'),dim=-1)
    draft=torch.softmax(torch.randn((rows,max(slots-1,1),vocab),device='cuda'),dim=-1)
    uniform=torch.rand((rows,max(slots-1,1)),device='cuda');final=torch.rand(rows,device='cuda')
    if mode=='accept':uniform.zero_()
    if mode=='reject':
        target.zero_();target[:,:,0]=1;draft.fill_(1/vocab);cand.fill_(vocab-1);uniform.fill_(0.5)
    if mode=='boundary':
        target.fill_(1/vocab);draft.copy_(target[:,:draft.shape[1]]);uniform.zero_()
        final.copy_((torch.arange(rows,device='cuda')%5)/4)
    tiles=triton.cdiv(vocab,4096)
    global classic_fixture
    classic_fixture=dict(cand=cand,retrieve=retrieve,target=target,draft=draft,uniform=uniform,final=final)
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            pred,pb=guard((rows*slots,),torch.int32);accept,ab=guard((rows,slots),torch.int32);count,cb=guard((rows,),torch.int32)
            st,sb=guard((rows,4),torch.int32);ts,tb=guard((rows,tiles),torch.float32)
            buffers[name]=(pb,ab,cb,sb[:16],sb[-16:],tb[:16],tb[-16:])
            if name=='triton':fns[name]=lambda pred=pred,accept=accept,count=count:ref.speculative_sampling_classic_kernel[(rows,)](
                pred,accept,count,cand,retrieve,uniform,final,target,draft,slots,1,slots,1,uniform.shape[1],1,
                target.stride(0),target.stride(1),1,draft.stride(0),draft.stride(1),1,NUM_SLOTS=slots,VOCAB_SIZE=vocab,BLOCK_V=4096,num_warps=4)
            else:fns[name]=lambda pred=pred,accept=accept,count=count,st=st,ts=ts,c=variants[name]:c.classic_sample(
                pred,accept,count,cand,retrieve,uniform,final,target,draft,st,ts)
        return fns,buffers
    case('classic_sampling',[rows,vocab,slots,mode],make,lambda:final.copy_(torch.rand_like(final)) if rows in (3,16) and mode!='boundary' else None)

try:
    torch.manual_seed(716)
    for rows in ([] if a.only_classic else ([1,2,3,4,8,16,24,32] if a.smoke else [1,3,8,16,24,32,128,1024,2,4])):
        rms(rows);rms(rows,column_major=True,store=False);rms(rows,zero=True)
        router(rows);router(rows,ties=True)
        partial(rows,1057);partial(rows,1024,greedy_only=True)
        hc(rows);softmax(rows,1057,rpr=3)
        for mode in ['random','accept','reject','boundary']:classic(rows,4096,8,mode)
        for heads in ([32] if a.smoke else [1,8,32,128]):
            for inv in (False,True):rope(rows,heads,64,inv,True,padded=True)
        for dtype in (torch.bfloat16,torch.float32):
            hash_route(rows,256,6,1,dtype)
            hash_route(rows,256,6,0,dtype,True)
        for tiles in ([3,32] if a.smoke else [1,3,32,64,128]):
            combine(rows,tiles);combine(rows,tiles,True)
    if a.only_classic:
        for seed in range(6):
            torch.manual_seed(716+seed)
            for mode in ['random','accept','reject','boundary']:classic(1024,4096,8,mode)
            classic(32,131072,8)
            classic(16,16,1,'boundary')
    if not a.smoke and not a.only_classic:
        for rows in [1,3,8,16,24,32,128]:
            partial(rows);softmax(rows,rpr=8);classic(rows,131072,8)
        classic(16,16,1,'boundary')
        rope(3,32,64,False,True,padded=True,far=True)
        rope(16,8,32,False,False)
        rope(8192,32,64,False,True,padded=True)
        rms(49152);rms(49152,column_major=True,store=False);router(49152)
        hash_route(49152,256,6,1,torch.bfloat16)
        combine(49152,32)
    if stream_cases:
        streams=[torch.cuda.Stream(),torch.cuda.Stream()]
        for stream in streams:stream.wait_stream(torch.cuda.current_stream())
        for repeat in range(5):
            for i,(op,shape,fns,buffers) in enumerate(stream_cases):
                with torch.cuda.stream(streams[i%2]):fns['selected']()
        for stream in streams:stream.synchronize()
        for op,shape,fns,buffers in stream_cases:
            compare(buffers['selected'],buffers['triton'],op,shape,'concurrent_selected')
        report['concurrent_streams']={'passed':True,'streams':2,'fixtures':len(stream_cases),'iterations':5,'scratch':'owned independently by each fixture'}
    if report.get('failures'):raise AssertionError(str(len(report['failures']))+' component cases failed')
    report.update(state='passed',finished=time.time());save()
except BaseException as exc:
    report.update(state='failed',error=repr(exc),finished=time.time());save();raise
finally:
    torch.cuda.synchronize()
    for c in variants.values():c.close()
