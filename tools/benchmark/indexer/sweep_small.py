# SPDX-License-Identifier: MIT
"""Paired isolated GPU timings for small-batch assembly schedules."""
import argparse
import importlib.util
import json
from pathlib import Path
import random
import sys
import torch
from validate import make, reference, check, graph_time, Scorer, select_schedule, deepgemm_fp8_paged_mqa_logits

p=argparse.ArgumentParser()
p.add_argument('--build',required=True)
p.add_argument('--output',required=True)
p.add_argument('--baseline-runtime',required=True)
p.add_argument('--baseline-build',required=True)
p.add_argument('--all-variants',dest='selected_only',action='store_false',default=True)
a=p.parse_args()
spec=importlib.util.spec_from_file_location('netra_original_scorer',a.baseline_runtime)
baseline=importlib.util.module_from_spec(spec);spec.loader.exec_module(baseline)
old=baseline.Scorer(a.baseline_build)
variants={'selected':Scorer(a.build)}
if not a.selected_only:
 variants.update({f'page{n}':Scorer(a.build,pages_per_wave=n,mode=0) for n in [1,2,4,8]})
 variants.update(tile16=Scorer(a.build,mode=1),wave4=Scorer(a.build,mode=2))
 variants.update({f'pipe{n}':Scorer(a.build,pages_per_wave=n,mode=3) for n in [1,2,4]})
 variants['tile32']=Scorer(a.build,mode=4)
 variants.update({f'pair{n}':Scorer(a.build,pages_per_wave=n,mode=5) for n in [1,2]})
 variants.update({f'group{n}':Scorer(a.build,pages_per_wave=n,mode=6) for n in [1,2,4]})
report={'state':'running','cases':[],'device':torch.cuda.get_device_name(),'scope':'synthetic isolated GPU graph timings'}
def save():Path(a.output).write_text(json.dumps(report,indent=2)+'\n')
save()
try:
 shapes=[(n,4096) for n in [1,2,4,8,16,24,32,64,128,256]]+[(n,w) for w in [1024,16384] for n in [1,8,128]]
 if a.selected_only: shapes += [(1024,4096),(8,262144),(128,32768),(1024,262144)]
 for rows,width in shapes:
  t=make(rows,width,90,request_groups=max(1,rows//8))
  t[3].fill_(width)
  if rows>1:t[4][0].copy_(t[4][-1])
  wide_pool=t[1].numel()*t[1].element_size() > (1 << 31)
  if wide_pool:
   # Bound the reference's 32-bit buffer offsets; preserve absolute physical
   # page IDs in both assembly launches. Row 0 can reference another group.
   ref=torch.empty_like(t[5])
   for start,end in [(0,1)]+[(i,min(rows,i+8)) for i in range(1,rows,8)]:
    page_base=int(t[4][start:end].min())
    page_end=int(t[4][start:end].max())+1
    assert (page_end-page_base)*t[1].stride(0) < (1 << 31)
    local=(t[0][start:end],t[1][page_base:page_end],t[2][start:end],
           t[3][start:end],t[4][start:end]-page_base,t[5][start:end])
    ref[start:end].copy_(reference(local))
  else:
   ref=reference(t)
  base=torch.empty_like(t[5])
  fns={k:(lambda fn=fn:fn(*t[:6])) for k,fn in variants.items()}
  fns['previous']=lambda:old(*t[:6])
  if not wide_pool:
   fns['gluon']=lambda:deepgemm_fp8_paged_mqa_logits(*t[:3],base,t[3],t[4],width,Preshuffle=True,KVBlockSize=64)
  for k,fn in fns.items():
   (base if k=='gluon' else t[5]).fill_(float('nan'))
   fn()
   try:
    assert check(base if k=='gluon' else t[5],ref,t[3])['top512_set_equal'],k
   except Exception as e:
    raise AssertionError(f'{k} at {rows}x{width}: {e}') from e
  item={'rows':rows,'width':width,'schedule':select_schedule(rows,width),'request_groups':max(1,rows//8),'reference':('rebased KV slices below 2 GiB' if wide_pool else 'full-pool Gluon'),'rounds':[]}
  for round_id in range(5):
   order=list(fns);random.Random(round_id).shuffle(order)
   times={k:graph_time(fns[k]) for k in order}
   item['rounds'].append(times)
  report['cases'].append(item);save();print(json.dumps(item),flush=True)
 report['state']='passed'
except BaseException as e:
 report.update(state='failed',error=repr(e));raise
finally:
 save()
 torch.cuda.synchronize()
 for fn in [old,*variants.values()]: fn.close()
