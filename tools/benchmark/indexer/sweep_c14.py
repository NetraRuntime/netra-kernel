# SPDX-License-Identifier: MIT
"""C1-C4 schedule comparisons with production-aligned and canary row pitches."""
import argparse, importlib.util, json, random
from pathlib import Path
import torch
from validate import Scorer, make, reference, check, graph_time, deepgemm_fp8_paged_mqa_logits
p=argparse.ArgumentParser()
for name in ['build','output','baseline-runtime','baseline-build']: p.add_argument('--'+name,required=True)
a=p.parse_args()
spec=importlib.util.spec_from_file_location('previous_scorer',a.baseline_runtime)
prev=importlib.util.module_from_spec(spec);spec.loader.exec_module(prev)
old=prev.Scorer(a.baseline_build)
variants={f'transpose{n}':Scorer(a.build,mode=7,pages_per_wave=n) for n in [1,2,4,8]}
variants.update({f'prefetch{n}':Scorer(a.build,mode=8,pages_per_wave=n) for n in [1,2]})
variants['selected']=Scorer(a.build)
variants.update({f'pair{n}':Scorer(a.build,mode=5,pages_per_wave=n) for n in [1,2]})
variants.update({f'heads{n}':Scorer(a.build,mode=9,pages_per_wave=n) for n in [1,2]})
variants.update({f'shared{n}':Scorer(a.build,mode=10,pages_per_wave=n) for n in [1,2,4]})
variants.update({f'group{n}':Scorer(a.build,mode=6,pages_per_wave=n) for n in [1,2,4]})
variants.update({f'preload_pair{n}':Scorer(a.build,mode=11,pages_per_wave=n) for n in [1,2]})
variants.update({f'preload_shared{n}':Scorer(a.build,mode=12,pages_per_wave=n) for n in [1,2]})
variants.update({f'shared_prefetch{n}':Scorer(a.build,mode=13,pages_per_wave=n) for n in [1,2,4]})
report={'state':'running','device':torch.cuda.get_device_name(),'cases':[]}
def save():Path(a.output).write_text(json.dumps(report,indent=2)+'\n')
save()
try:
 for aligned in [True,False]:
  shapes=[(n,4096) for n in [1,2,4,8,16,24,32,64,128,256]]+[(n,w) for w in [1024,16384] for n in [8,16,24,32]]
  for rows,width in shapes:
   t=list(make(rows,width,90,request_groups=max(1,rows//8)))
   t[3].fill_(width)
   if rows>1:t[4][0].copy_(t[4][-1])
   if aligned:t[5]=torch.empty((rows,width),device='cuda')
   ref=reference(t);base=torch.empty_like(t[5])
   fns={k:(lambda fn=fn:fn(*t[:6])) for k,fn in variants.items()}
   fns['previous']=lambda:old(*t[:6])
   fns['gluon']=lambda:deepgemm_fp8_paged_mqa_logits(*t[:3],base,t[3],t[4],width,Preshuffle=True,KVBlockSize=64)
   for name,fn in fns.items():
    out=base if name=='gluon' else t[5];out.fill_(float('nan'));fn()
    try:assert check(out,ref,t[3])['top512_set_equal']
    except Exception as e:raise AssertionError(f'{name}, aligned={aligned}, {rows}x{width}: {e}') from e
   item={'rows':rows,'width':width,'aligned':aligned,'rounds':[]}
   for rep in range(5):
    order=list(fns);random.Random(rep).shuffle(order)
    item['rounds'].append({name:graph_time(fns[name]) for name in order})
   report['cases'].append(item);save();print(json.dumps(item),flush=True)
 report['state']='passed'
except BaseException as e:report.update(state='failed',error=repr(e));raise
finally:
 save();torch.cuda.synchronize()
 for fn in [old,*variants.values()]:fn.close()
