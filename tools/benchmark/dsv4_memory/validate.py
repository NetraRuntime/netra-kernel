# SPDX-License-Identifier: MIT
"""Exact-output and paired timing checks against the deployment's Triton bodies."""
import argparse, ast, importlib.util, json, random, statistics, sys, time
from pathlib import Path
import torch
import triton

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'runtime/gfx950/memory/dsv4'))
from memory import Memory

p = argparse.ArgumentParser()
p.add_argument('--build', required=True)
p.add_argument('--reference-root', required=True)
p.add_argument('--output', required=True)
p.add_argument('--smoke', action='store_true')
p.add_argument('--correctness-only', action='store_true')
a = p.parse_args()
# Extract only the exact JIT bodies, avoiding serving imports or GPU initialization.
names = {'_get_last_loc_safe_kernel','compute_position_kernel','assign_extend_cache_locs',
 'assign_req_to_token_pool','_expand_prefill_causally_kernel','write_req_to_token_pool_triton',
 'alloc_extend_kernel','_vocab_parallel_embedding_kernel'}
nodes = []
for path in Path(a.reference_root).rglob('*.py'):
    tree = ast.parse(path.read_text())
    nodes += [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names]
assert {n.name for n in nodes} == names and len(nodes) == len(names)
ref_file = Path(a.build) / 'reference_bodies.py'
ref_file.write_text('import triton\nimport triton.language as tl\n' +
                    '\n\n'.join(ast.unparse(n) for n in nodes) + '\n')
spec = importlib.util.spec_from_file_location('netra_memory_references', ref_file)
ref = importlib.util.module_from_spec(spec); sys.modules[spec.name] = ref
spec.loader.exec_module(ref)
variants = {'wave1': Memory(a.build, waves=1), 'wave4': Memory(a.build, waves=4),
            'selected': Memory(a.build)}
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


def run(rows,dtype,extent=71,context=1024):
    idx=torch.arange(rows)
    lengths=(idx*37+extent)%(extent+1)
    lengths[0]=extent
    if rows>1: lengths[-1]=0
    pre=(idx*131)%(context-extent)
    pre[::5]=0
    total=int(lengths.sum());seq=pre+lengths
    req=idx.flip(0).to(device='cuda',dtype=dtype)
    pre,seq,lengths=[t.to(device='cuda',dtype=dtype) for t in (pre,seq,lengths)]
    table=(torch.arange(rows*context,dtype=torch.int32,device='cuda').view(rows,context)*13-1111)
    locs=(torch.arange(total,device='cuda',dtype=torch.int64)+((1<<34)-31))
    def last_make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((rows,),torch.int32);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda out=out:ref._get_last_loc_safe_kernel[(triton.cdiv(rows,256),)](
                table,req,pre,out,rows,context,BLOCK_SIZE=256,PREFIX_DTYPE_IS_I64=dtype==torch.int64)
            else:fns[name]=lambda out=out,c=variants[name]:c.get_last_loc(table,req,pre,out)
        return fns,buffers
    case('get_last_loc',[rows,extent,context,str(dtype)],last_make,lambda:table.add_(1),rows in (3,16))
    for has in (True,False):
        def position_make():
            fns={};buffers={}
            for name in ['triton',*variants]:
                out,b=guard((total,),torch.int64);start,sb=guard((rows,),torch.int32);buffers[name]=(b,sb)
                if name=='triton':fns[name]=lambda out=out,start=start:ref.compute_position_kernel[(rows,)](out,start,pre,lengths,has_prefix=has)
                else:fns[name]=lambda out=out,start=start,c=variants[name]:c.compute_position(pre if has else None,lengths,out,start)
            return fns,buffers
        case('compute_position',[rows,extent,context,str(dtype),has],position_make)
    for write in (False,True):
        def assign_make():
            fns={};buffers={}
            for name in ['triton',*variants]:
                out,b=guard((rows,context) if write else (total,),torch.int32 if write else torch.int64);buffers[name]=(b,)
                t=out if write else table;l=locs if write else out
                if name=='triton':
                    fn=ref.assign_req_to_token_pool if write else ref.assign_extend_cache_locs
                    fns[name]=lambda fn=fn,t=t,l=l:fn[(rows,)](req,t,pre,seq,l,context,triton.next_power_of_2(rows))
                else:fns[name]=lambda t=t,l=l,c=variants[name]:c.assign_cache_locs(req,t,pre,seq,l,write)
            return fns,buffers
        case('assign_req_to_token_pool' if write else 'assign_extend_cache_locs',[rows,extent,context,str(dtype)],assign_make,
             lambda:locs.add_(7) if write else table.add_(7),rows in (3,16))
    def expand_make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            causal,cb=guard((total+17,),torch.int32);repeat,rb=guard((total+17,),dtype);buffers[name]=(cb,rb)
            if name=='triton':fns[name]=lambda causal=causal,repeat=repeat:ref._expand_prefill_causally_kernel[(triton.cdiv(total+17,128),)](
                req,seq,lengths,causal,repeat,rows,total,total+17,BLOCK=128,BS_P2=triton.next_power_of_2(rows))
            else:fns[name]=lambda causal=causal,repeat=repeat,c=variants[name]:c.expand_prefill(req,seq,lengths,causal,repeat,total)
        return fns,buffers
    case('expand_prefill',[rows,extent,context,str(dtype)],expand_make,lambda:seq.add_(1),rows in (3,16))
    # Restore seq after graph mutations so prefix/extend allocation contracts match.
    seq.copy_(pre+lengths)
    prefixes=[torch.arange(int(n),device='cuda',dtype=torch.int64)+(1<<35) for n in pre.cpu()]
    ptrs=torch.tensor([t.data_ptr() for t in prefixes],device='cuda',dtype=torch.int64)
    def write_make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((rows,context),torch.int32);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda out=out:ref.write_req_to_token_pool_triton[(rows,)](out,req,ptrs,pre,seq,lengths,locs,context)
            else:fns[name]=lambda out=out,c=variants[name]:c.write_req_pool(out,req,ptrs,pre,seq,lengths,locs)
        return fns,buffers
    case('write_req_pool',[rows,extent,context,str(dtype)],write_make,lambda:locs.add_(3),rows in (3,16))
    for page in ([1,16,256] if rows<=3 else [256]):
        pages=((seq+page-1)//page-(pre+page-1)//page).to(torch.int64)
        num=int(pages.sum())
        # Offset free-page pointer by eight bytes to cover allocator reslicing.
        free=(torch.arange(num+1,device='cuda',dtype=torch.int64)*13+(1<<33))[1:]
        last=torch.arange(rows,device='cuda',dtype=torch.int64)*(1<<33)-1
        def alloc_make():
            fns={};buffers={}
            for name in ['triton',*variants]:
                out,b=guard((total,),torch.int64);buffers[name]=(b,)
                if name=='triton':fns[name]=lambda out=out:ref.alloc_extend_kernel[(rows,)](pre,seq,last,free,out,triton.next_power_of_2(rows),page)
                else:fns[name]=lambda out=out,c=variants[name]:c.alloc_extend(pre,seq,last,free,out,page)
            return fns,buffers
        case('alloc_extend',[rows,extent,context,str(dtype),page],alloc_make,lambda:free.add_(1),rows in (3,16))

def embedding(rows,width,dtype):
    tokens=(torch.arange(rows,device='cuda')%19+97).to(dtype)
    if rows:tokens[0]=103
    if rows>2:tokens[1]=-1;tokens[2]=203
    if rows>4 and dtype==torch.int64:tokens[4]=(1<<32)+103
    weight=torch.randn((32,width),device='cuda',dtype=torch.bfloat16)
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            out,b=guard((rows,width),torch.bfloat16);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda out=out:ref._vocab_parallel_embedding_kernel[(rows,triton.cdiv(width,1024))](
                tokens,weight,out,width,width,100,113,3,200,216,BLOCK_H=min(1024,triton.next_power_of_2(width)),num_warps=8)
            else:fns[name]=lambda out=out,c=variants[name]:c.vocab_embedding(tokens,weight,out,100,113,3,200,216)
        return fns,buffers
    case('vocab_embedding',[rows,width,str(dtype)],make,lambda:weight.add_(1),rows in (3,16))

def boundaries():
    # The table's selected physical row starts above 4 GiB. Only touch live slots.
    table=torch.empty((1026,1048576),device='cuda',dtype=torch.int32)
    req=torch.tensor([1024,1025,0],device='cuda',dtype=torch.int64)
    pre=torch.tensor([3,0,1],device='cuda',dtype=torch.int64)
    table[1024,2]=716;table[0,0]=-817
    for c in variants.values():
        out,b=guard((3,),torch.int32);c.get_last_loc(table,req,pre,out)
        assert out.tolist()==[716,-1,-817] and bool((b[:16]==-111).all()) and bool((b[-16:]==-111).all())
    del table
    report['last_loc_address_above_4_GiB']=True
    n=1048570
    prefix=torch.arange(n,device='cuda',dtype=torch.int64)+(1<<35)
    pointers=torch.tensor([prefix.data_ptr()],device='cuda',dtype=torch.int64)
    req=torch.zeros(1,device='cuda',dtype=torch.int64)
    pre=torch.tensor([n],device='cuda',dtype=torch.int64);seq=pre.clone();extend=torch.zeros_like(pre)
    locs=torch.empty(0,device='cuda',dtype=torch.int64)
    def make():
        fns={};buffers={}
        for name in ['triton',*variants]:
            table,b=guard((1,1048576),torch.int32);buffers[name]=(b,)
            if name=='triton':fns[name]=lambda table=table:ref.write_req_to_token_pool_triton[(1,)](table,req,pointers,pre,seq,extend,locs,1048576)
            else:fns[name]=lambda table=table,c=variants[name]:c.write_req_pool(table,req,pointers,pre,seq,extend,locs,prefix_tokens=n)
        return fns,buffers
    case('write_req_pool_prefix_only',[1,n],make,lambda:prefix.add_(1),True)

try:
    for rows in ([1,2,3,4,16,128] if a.smoke else [1,2,3,4,8,16,24,32,128,256,1024]):
        for dtype in (torch.int32,torch.int64):
            run(rows,dtype)
            for width in ([128] if a.smoke else [128,512,4096]):embedding(rows,width,dtype)
    if not a.smoke:
        for rows,extent,context in [(1,0,1048576),(1,1048570,1048576),(3,8192,1048576),(128,257,4096)]:run(rows,torch.int64,extent,context)
        embedding(49152,4096,torch.int64)
        boundaries()
    torch.cuda.synchronize()
    for c in variants.values():c.close()
    report.update(state='passed',finished=time.time());save()
except BaseException as exc:
    report.update(state='failed',error=repr(exc),finished=time.time());save();raise
