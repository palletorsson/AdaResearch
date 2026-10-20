"""Align only Matching's authored and shipped exhibit sentences."""
from pathlib import Path
import copy,json,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-matching-room-for-two'
lines={'matching_workshop':'The drill is taken. The saw is free. Can an earlier choice make room for another?', 'ada_relations':'Going next, depending on, returning to, sharing: which relation does this line record?', 'edmonds_algorithm':'The same graph, two greedy scan orders: which pairs does an early choice prevent?'}
for rel in ['commons/data/book/graphtheory.json','commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
 stamp=p.stat().st_mtime_ns;d=json.loads(p.read_text(encoding='utf8'));old=copy.deepcopy(d)
 def visit(v,edit):
  if isinstance(v,dict):
   if v.get('map')=='GT_Matching':
    if not edit:return {'map':'GT_Matching'}
    if 'lines' in v:v['lines']=[{'token':k,'text':t,'by':'draft'} for k,t in lines.items()]
    else:
     v['says']=dict(lines);v['says_by']={k:'draft' for k in lines}
     if 'tokens' in v:v['tokens']=list(lines)
     else:v['tokens_add']=['matching_workshop','ada_relations'];v['tokens_remove']=[];v['tokens_order']=list(lines)
    v['hero']='matching_workshop'
   return {k:visit(x,edit) for k,x in v.items()}
  if isinstance(v,list):return [visit(x,edit) for x in v]
  return v
 visit(d,True)
 assert visit(d,False)==visit(old,False),rel
 assert stamp==p.stat().st_mtime_ns
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Matching wall rows aligned; other halls preserved.')
