# SPDX-License-Identifier: MIT
"""Exact-output and paired timing checks against the deployment's Triton bodies."""
import argparse, ast, importlib.util, json, random, statistics, sys, time
from pathlib import Path
import torch
import triton

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'runtime/gfx950/control/dsv4'))
from control import Control

p = argparse.ArgumentParser()
p.add_argument('--build', required=True)
p.add_argument('--reference-root', required=True)
p.add_argument('--output', required=True)
p.add_argument('--smoke', action='store_true')
p.add_argument('--correctness-only', action='store_true')
a = p.parse_args()
# Extract only the exact JIT bodies, avoiding serving imports or GPU initialization.
names = {'_scatter_loc_kernel', '_swa_scatter_kernel', '_prefill_lengths_kernel',
         '_build_prefill_indices_kernel', '_fill_compress_tail_kernel',
         '_fused_append_shared_experts_kernel', '_finalize_accept_lens_kernel',
         '_gather_two_level_bonus_kernel', '_build_out_tokens_kernel',
         '_init_compressed_attn_metadata_kernel'}
nodes = []
for path in Path(a.reference_root).rglob('*.py'):
    tree = ast.parse(path.read_text())
    nodes += [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names]
assert {n.name for n in nodes} == names and len(nodes) == len(names)
ref_file = Path(a.build) / 'reference_bodies.py'
ref_file.write_text('import triton\nimport triton.language as tl\n' +
                    '\n\n'.join(ast.unparse(n) for n in nodes) + '\n')
spec = importlib.util.spec_from_file_location('netra_control_references', ref_file)
ref = importlib.util.module_from_spec(spec); sys.modules[spec.name] = ref
spec.loader.exec_module(ref)
variants = {'wave1': Control(a.build, waves=1), 'wave4': Control(a.build, waves=4),
            'selected': Control(a.build)}
report = {'state': 'running', 'device': torch.cuda.get_device_name(), 'cases': [],
          'started': time.time(), 'scope': 'Isolated component tests, synthetic inputs; no serving TPS claim.'}
def save(): Path(a.output).write_text(json.dumps(report, indent=2) + '\n')
def guard(shape, dtype):
    count = 1
    for dim in shape: count *= dim
    storage = torch.full((count + 32,), -111, dtype=dtype, device='cuda')
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

def case(op, shape, make_fns, mutate=None, graph_check=False):
    # make_fns creates a separate output/storage pair for each implementation.
    fns, buffers = make_fns()
    for name, fn in fns.items():
        for b in buffers[name]: b.fill_(-111)
        fn()
    for name in variants:
        for got, want in zip(buffers[name], buffers['triton']):
            assert torch.equal(got, want), (op, shape, name, 'value or canary mismatch',
                int((got != want).sum().item()))
    item = {'operation': op, 'shape': shape, 'exact_all_variants': True}
    if graph_check and mutate is not None:
        graphs = {}
        for name in variants:
            graphs[name] = torch.cuda.CUDAGraph()
            with torch.cuda.graph(graphs[name]): fns[name]()
        for _ in range(3):
            mutate()
            for b in buffers['triton']: b.fill_(-111)
            fns['triton']()
            for name, graph in graphs.items():
                for b in buffers[name]: b.fill_(-111)
                graph.replay()
                assert all(torch.equal(x,y) for x,y in zip(buffers[name],buffers['triton'])), (op,shape,name,'graph mismatch')
        item['changed_graph_replays'] = 3
        del graphs
    if not a.correctness_only and shape[0] > 0:
        item['rounds_us'] = []
        for rep in range(5):
            order = list(fns); random.Random(rep).shuffle(order)
            item['rounds_us'].append({name: timing(fns[name]) for name in order})
        item['median_us'] = {name: statistics.median(r[name] for r in item['rounds_us']) for name in fns}
    report['cases'].append(item); save(); print(json.dumps(item), flush=True)

def scatter(rows, width, dtype, swa=False, has_final=True):
    kv = torch.randn((rows,width),device='cuda',dtype=torch.bfloat16)
    loc = torch.arange(rows,device='cuda',dtype=dtype).flip(0)
    if rows: loc[::9] = -1
    stride, win = 520, 512
    state = torch.arange(rows,device='cuda',dtype=dtype)//win
    pos = torch.arange(rows,device='cuda',dtype=dtype)%win + 1048000
    final = pos.clone()
    if rows: final[::7] += win
    slots = max(1, (rows+win-1)//win)*stride if swa else max(1,rows)
    def make():
        fns={}; buffers={}
        for name in ['triton',*variants]:
            out, storage=guard((slots,width),torch.bfloat16);buffers[name]=(storage,)
            if name=='triton':
                if swa:
                    fns[name]=lambda out=out: ref._swa_scatter_kernel[(rows,)](kv,state,pos,final,out,rows,stride,
                        win=win,D=width,HAS_FINAL=has_final,BLOCK_D=triton.next_power_of_2(width),num_warps=8) if rows else None
                else:
                    fns[name]=lambda out=out: ref._scatter_loc_kernel[(rows,)](kv,loc,out,rows,
                        D=width,BLOCK_D=triton.next_power_of_2(width),num_warps=8) if rows else None
            elif swa:
                fns[name]=lambda out=out,c=variants[name]:c.swa_scatter(kv,state,pos,final if has_final else None,out,win,stride)
            else:
                fns[name]=lambda out=out,c=variants[name]:c.scatter_loc(kv,loc,out)
        return fns,buffers
    case('swa_scatter' if swa else 'scatter_loc',[rows,width,str(dtype),has_final],make,
         lambda:kv.add_(1),rows in (3,16))

def metadata(rows, width, dtype, win=512, stride=520):
    idx=torch.arange(rows,dtype=torch.int64)
    chunk=(idx%3)*500000
    pos=chunk+(idx*37)%1537
    cu=idx*2048;state=idx%31
    counts=(idx*23)%(width+1)
    pages=(idx[:,None]*17+torch.arange(width)[None,:]*3).to(torch.int32)
    pages[torch.arange(width)[None,:]>=counts[:,None]]=-1
    low=torch.clamp(pos-win+1,min=0)
    ext=torch.minimum(pos-chunk+1,torch.tensor(win))
    prefix=torch.clamp(chunk-low,min=0,max=win)
    preptr=torch.cat([torch.zeros(1,dtype=torch.int64),(prefix+counts).cumsum(0)]).to(torch.int32)
    extptr=torch.cat([torch.zeros(1,dtype=torch.int64),ext.cumsum(0)]).to(torch.int32)
    pre_size=int(preptr[-1]);ext_size=int(extptr[-1])
    pos,chunk,cu,state=[t.to(device='cuda',dtype=dtype) for t in (pos,chunk,cu,state)]
    pages=pages.cuda();preptr=preptr.cuda();extptr=extptr.cuda()
    prefix=prefix.to(device='cuda',dtype=dtype);counts=counts.to(device='cuda',dtype=dtype)
    block=min(1024,triton.next_power_of_2(max(win,width,1)))
    def make_lengths():
        fns={};buffers={}
        for name in ['triton',*variants]:
            pre,pb=guard((rows,),torch.int32);ex,eb=guard((rows,),torch.int32);buffers[name]=(pb,eb)
            if name=='triton':
                fns[name]=lambda pre=pre,ex=ex:ref._prefill_lengths_kernel[(rows,)](pos,chunk,pages,pre,ex,
                    win=win,Wc=max(width,1),HAS_COMPRESS=width>0,BLOCK=block,num_warps=4)
            else:fns[name]=lambda pre=pre,ex=ex,c=variants[name]:c.prefill_lengths(pos,chunk,pages,pre,ex,win)
        return fns,buffers
    case('prefill_lengths',[rows,width,str(dtype)],make_lengths,
         lambda:pages.mul_(-1),False)
    def make_indices():
        fns={};buffers={}
        for name in ['triton',*variants]:
            pre,pb=guard((pre_size,),torch.int32);ex,eb=guard((ext_size,),torch.int32);buffers[name]=(pb,eb)
            if name=='triton':
                fns[name]=lambda pre=pre,ex=ex:ref._build_prefill_indices_kernel[(rows,)](pos,chunk,cu,state,pages,preptr,extptr,pre,ex,
                    100000,stride,win=win,Wc=max(width,1),HAS_COMPRESS=width>0,BLOCK=block,num_warps=4)
            else:
                fns[name]=lambda pre=pre,ex=ex,c=variants[name]:c.prefill_indices(pos,chunk,cu,state,pages,
                    preptr,extptr,pre,ex,win,100000,stride)
        return fns,buffers
    # Change only valid page ids; the ragged lengths remain valid across replay.
    def mutate_pages():pages.add_(torch.where(pages>=0,1,0))
    case('prefill_indices',[rows,width,str(dtype)],make_indices,mutate_pages,rows in (3,16))
    if width:
        def make_tail():
            fns={};buffers={}
            for name in ['triton',*variants]:
                out,b=guard((pre_size,),torch.int32);buffers[name]=(b,)
                if name=='triton':
                    fns[name]=lambda out=out:ref._fill_compress_tail_kernel[(rows,)](out,preptr,prefix,pages,counts,100000,
                        Wc=width,BLOCK=min(1024,triton.next_power_of_2(width)),num_warps=4)
                else:fns[name]=lambda out=out,c=variants[name]:c.fill_compress_tail(out,preptr,prefix,pages,counts,100000)
            return fns,buffers
        case('fill_compress_tail',[rows,width,str(dtype)],make_tail,mutate_pages,rows in (3,16))

def append(rows,k,shared,dtype):
    ids=torch.randint(0,256,(rows,k),dtype=dtype,device='cuda')
    weights=torch.randn((rows,k),device='cuda');scale=0.25
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            oi,ib=guard((rows,k+shared),dtype);ow,wb=guard((rows,k+shared),torch.float32);buffers[name]=(ib,wb)
            if name=='triton':
                fns[name]=lambda oi=oi,ow=ow:ref._fused_append_shared_experts_kernel[(rows,)](ids,weights,oi,ow,256,scale,
                    K=k,S=shared,BLOCK_K=triton.next_power_of_2(k),BLOCK_S=triton.next_power_of_2(max(shared,1)),num_warps=1)
            else:fns[name]=lambda oi=oi,ow=ow,c=variants[name]:c.append_shared(ids,weights,oi,ow,256,scale)
        return fns,buffers
    case('append_shared',[rows,k,shared,str(dtype)],make,lambda:weights.add_(1),rows in (3,16))

def helpers(rows, dtype):
    correct=(torch.arange(rows,device='cuda')%8).to(dtype)
    trim=(torch.arange(rows,device='cuda')%3).to(dtype)
    prefix=(torch.arange(rows,device='cuda')+((1<<34)-4 if dtype==torch.int64 else 1000000)).to(dtype)
    def make_finalize():
        fns={};buffers={}
        for name in ['triton',*variants]:
            co,cb=guard((rows,),torch.int32);ns,nb=guard((rows,),dtype);tr,tb=guard((rows,),torch.int32)
            buffers[name]=(cb,nb,tb)
            if name=='triton':
                fns[name]=lambda co=co,ns=ns,tr=tr:ref._finalize_accept_lens_kernel[(triton.cdiv(rows,256),)](
                    correct,trim,prefix,co,ns,tr,rows,BLOCK=256)
            else:fns[name]=lambda co=co,ns=ns,tr=tr,c=variants[name]:c.finalize_accept(correct,trim,prefix,co,ns,tr)
        return fns,buffers
    case('finalize_accept',[rows,str(dtype)],make_finalize,lambda:prefix.add_(13),rows in (3,16))
    index=torch.randperm(rows*8,device='cuda').reshape(rows,8).to(dtype)
    predicts=(torch.arange(rows*8,device='cuda')*7-91).to(dtype)
    if dtype==torch.int64:predicts+=(1<<36)
    def make_bonus():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((rows,),torch.int64);buffers[name]=(b,)
            if name=='triton':
                fns[name]=lambda out=out:ref._gather_two_level_bonus_kernel[(triton.cdiv(rows,256),)](
                    index,predicts,correct,out,8,rows,BLOCK=256)
            else:fns[name]=lambda out=out,c=variants[name]:c.gather_bonus(index,predicts,correct,out)
        return fns,buffers
    case('gather_bonus',[rows,str(dtype)],make_bonus,lambda:predicts.add_(17),rows in (3,16))
    if dtype==torch.int64:
        draft=torch.arange(rows*7,device='cuda',dtype=torch.int64).view(rows,7)+(1<<35)
        bonus=torch.arange(rows,device='cuda',dtype=torch.int64)-(1<<35)
        def make_tokens():
            fns={};buffers={}
            for name in ['triton',*variants]:
                out,b=guard((rows,8),torch.int64);buffers[name]=(b,)
                if name=='triton':
                    fns[name]=lambda out=out:ref._build_out_tokens_kernel[(triton.cdiv(rows*8,256),)](
                        draft,correct,bonus,out,7,8,rows*8,BLOCK=256)
                else:fns[name]=lambda out=out,c=variants[name]:c.build_out_tokens(draft,correct,bonus,out)
            return fns,buffers
        case('build_out_tokens',[rows,7,8],make_tokens,lambda:bonus.add_(13),rows in (3,16))

def compressed(rows,max_pages,dtype,ratio=2):
    lens=torch.tensor([0,1,3,4,127,128,129,4096,1048576],device='cuda',dtype=dtype)
    seq=lens[torch.arange(rows,device='cuda')%len(lens)];pos=(seq-1).to(torch.int64)
    raw=(torch.arange(rows,device='cuda',dtype=torch.int64)+1)*(1<<34)+127
    pages=torch.arange(rows*max_pages,device='cuda',dtype=torch.int32).reshape(rows,max_pages)+13
    width=max_pages*ratio
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            pairs=[guard((rows,),torch.int64 if i in (0,4) else torch.int32) for i in range(8)]
            pairs.append(guard((rows,width),torch.int32));outs=tuple(x[0] for x in pairs);buffers[name]=tuple(x[1] for x in pairs)
            if name=='triton':
                fns[name]=lambda outs=outs:ref._init_compressed_attn_metadata_kernel[(rows,)](
                    seq,pos,raw,pages,*outs,rows,max_pages,width,c128_page_size=ratio,
                    BLOCK_SIZE=64,COMPUTE_PAGE_INDICES=max_pages>0,num_warps=4)
            else:fns[name]=lambda outs=outs,c=variants[name]:c.compressed_metadata(seq,pos,raw,pages,outs,page_size=128*ratio)
        return fns,buffers
    case('compressed_metadata',[rows,max_pages,str(dtype),ratio],make,lambda:pages.add_(1),rows in (3,16))

def extra_edges():
    for ratio,pages in [(1,257),(2,129),(4,65),(8,33)]:
        compressed(16,pages,torch.int64,ratio)
    for gamma,width in [(6,7),(4,5),(63,64)]:
        rows=16
        draft=torch.arange(rows*gamma,device='cuda',dtype=torch.int64).view(rows,gamma)+(1<<35)
        correct=torch.arange(rows,device='cuda',dtype=torch.int64)%(gamma+1)
        bonus=-torch.arange(rows,device='cuda',dtype=torch.int64)-(1<<35)
        def make():
            fns={};buffers={}
            for name in ['triton',*variants]:
                out,b=guard((rows,width),torch.int64);buffers[name]=(b,)
                if name=='triton':fns[name]=lambda out=out:ref._build_out_tokens_kernel[(triton.cdiv(rows*width,256),)](draft,correct,bonus,out,gamma,width,rows*width,BLOCK=256)
                else:fns[name]=lambda out=out,c=variants[name]:c.build_out_tokens(draft,correct,bonus,out)
            return fns,buffers
        case('build_out_tokens',[rows,gamma,width],make,lambda:bonus.add_(1),True)
    width=257
    pages=torch.arange(width,device='cuda',dtype=torch.int32).view(1,width);pages[:,::3]=-1
    prefix=torch.tensor([2],device='cuda',dtype=torch.int64);valid=torch.tensor([width],device='cuda',dtype=torch.int64)
    indptr=torch.tensor([0,width+2],device='cuda',dtype=torch.int32)
    def make_tail():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((width+2,),torch.int32);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda out=out:ref._fill_compress_tail_kernel[(1,)](out,indptr,prefix,pages,valid,1000,Wc=width,BLOCK=512,num_warps=4)
            else:fns[name]=lambda out=out,c=variants[name]:c.fill_compress_tail(out,indptr,prefix,pages,valid,1000)
        return fns,buffers
    case('fill_compress_tail_negative_pages',[1,width],make_tail)

try:
    torch.manual_seed(716)
    rows_list=[1,3,8,16,24,32] if a.smoke else [0,1,3,8,16,24,32,128,1024,4096,49152]
    for rows in rows_list:
        for dtype in (torch.int32,torch.int64):
            for width in ([512] if a.smoke else [128,512]):
                scatter(rows,width,dtype)
                scatter(rows,width,dtype,swa=True,has_final=True)
            if rows:
                for width in ([0,65,512] if rows<=128 else [0,512]): metadata(rows,width,dtype)
                for k,s in ([(6,1)] if a.smoke else [(6,1),(8,2),(63,3)]):append(rows,k,s,dtype)
    for rows in ([1,3,8,16,24,32] if a.smoke else [1,3,8,16,24,32,128,1024,49152]):
        for dtype in (torch.int32,torch.int64):
            helpers(rows,dtype)
            compressed(rows,0,dtype)
            compressed(rows,65 if rows<=128 else 4,dtype)
    if not a.smoke:
        extra_edges()
        compressed(16,4096,torch.int64)
        for rows in [1,16,128,1024]:metadata(rows,8192,torch.int64)
        scatter(32,512,torch.int64,swa=True,has_final=False)
        # Direct physical row beyond 4 GiB, without a full-pool oracle allocation.
        kv=torch.randn((1,512),device='cuda',dtype=torch.bfloat16)
        loc=torch.tensor([(1<<32)//1024+7],device='cuda',dtype=torch.int64)
        out=torch.empty(((1<<32)//1024+9,512),device='cuda',dtype=torch.bfloat16)
        for c in variants.values():
            out[-3:].fill_(-111);c.scatter_loc(kv,loc,out)
            assert torch.equal(out[-2],kv[0]) and bool((out[-3]==-111).all()) and bool((out[-1]==-111).all())
        del out;report['wide_scatter_address_above_4_GiB']=True
        streams=[torch.cuda.Stream(),torch.cuda.Stream()]
        tensors=[]
        for stream in streams:
            kv=torch.randn((16,512),device='cuda',dtype=torch.bfloat16)
            loc=torch.arange(16,device='cuda',dtype=torch.int64).flip(0)
            out=torch.zeros_like(kv);tensors.append((kv,loc,out));stream.wait_stream(torch.cuda.current_stream())
        for stream,t in zip(streams,tensors):
            with torch.cuda.stream(stream):variants['selected'].scatter_loc(*t)
        for stream,t in zip(streams,tensors):
            stream.synchronize();assert torch.equal(t[2],t[0].flip(0))
        report['concurrent_streams']=2
    report['state']='passed'
except BaseException as e:
    report.update(state='failed',error=repr(e));raise
finally:
    torch.cuda.synchronize()
    for c in variants.values():c.close()
    report['finished']=time.time();save()
