"""Align only Flow's authored and shipped wall sentences with its two exhibits."""
from pathlib import Path
import copy,json,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-flow-room-for-another'
line='Crates use slots. A message can be copied. What does this connection carry?'
for rel in ['commons/data/book/graphtheory.json','commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
 stamp=p.stat().st_mtime_ns;d=json.loads(p.read_text(encoding='utf8'));old=copy.deepcopy(d)
 def visit(v,edit):
  if isinstance(v,dict):
   if v.get('map')=='GT_Flow':
    if not edit:return {'map':'GT_Flow'}
    if 'lines' in v:
     v['lines']=[{'token':'graph_worlds','text':line,'by':'draft'}]+[x for x in v['lines'] if x.get('token')=='push_relabel_algorithm']
    else:
     v['says']={'graph_worlds':line,'push_relabel_algorithm':v['says']['push_relabel_algorithm']}
     v['says_by']={k:'draft' for k in v['says']}
     if 'tokens' in v:v['tokens']=['graph_worlds','push_relabel_algorithm']
     else:
      v['tokens_add']=['graph_worlds'];v['tokens_remove']=['grid3d_dfs','grid3d_prim','karger_algorithm'];v['tokens_order']=['graph_worlds','push_relabel_algorithm']
    v['hero']='graph_worlds'
   return {k:visit(x,edit) for k,x in v.items()}
  if isinstance(v,list):return [visit(x,edit) for x in v]
  return v
 visit(d,True)
 assert visit(d,False)==visit(old,False),rel
 assert stamp==p.stat().st_mtime_ns
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Only Flow authored/shipped wall rows aligned.')
