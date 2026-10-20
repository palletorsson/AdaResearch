"""Read current source declarations; keep relation types and evidence separate."""
from pathlib import Path
import argparse
import json,hashlib,re
R=Path(__file__).resolve().parents[1];A=R/'commons/artifacts/ada_relations';A.mkdir(parents=True,exist_ok=True)
sources={}
def read(rel):
 p=R/rel;sources[rel]=hashlib.sha256(p.read_bytes()).hexdigest();return json.loads(p.read_text(encoding='utf8'))
spine=sorted(read('commons/maps/curriculum_spine.json')['spine']['sequences'],key=lambda x:x['order'])
plan=read('doc/book/course/execution-plan/plan.json');nodes=[];owner={};tokens={};edges=[];omissions=[]
for i,s in enumerate(spine):
 sid=s['name'];rel=f'commons/maps/sequences/{sid}.json';seq=read(rel)['sequences'][sid]
 maps=seq.get('maps',[]);nodes.append({'id':sid,'title':seq.get('name',sid),'order':s['order'],'maps':maps,'phase':s.get('phase',''),'source':rel})
 for mid in maps:
  assert mid not in owner,mid
  owner[mid]=sid
  rel=f'commons/maps/{mid}/map_data.json'
  if not (R/rel).exists():omissions.append({'kind':'missing_map','id':mid});continue
  d=read(rel);seen=set()
  for row in d.get('layers',{}).get('interactables',[]):
   for v in row:
    if isinstance(v,str) and v.strip():
     token=re.split(r'[:#]',v.strip())[0]
     if token in seen:continue
     seen.add(token);tokens.setdefault(token,[]).append({'sequence':sid,'map':mid,'source':rel})
for i in range(len(nodes)-1):edges.append({'kind':'walk','a':nodes[i]['id'],'b':nodes[i+1]['id'],'evidence':[{'source':'commons/maps/curriculum_spine.json','relation':'adjacent sorted order'}]})
for lesson in plan['lessons']:
 target=lesson['id']
 if target not in owner:continue
 for dependency in lesson.get('dependsOn',[]):
  if dependency not in owner:omissions.append({'kind':'dependency_outside_current_spine','from':dependency,'to':target});continue
  edges.append({'kind':'dependency','a':owner[dependency],'b':owner[target],'evidence':[{'source':'doc/book/course/execution-plan/plan.json','from':dependency,'to':target,'relation':'dependsOn','decision':lesson.get('decision','unknown')}]})
for topic in plan['topics']:
 first=topic.get('first')
 for returned in topic.get('returns',[]):
  if first not in owner or returned not in owner:omissions.append({'kind':'topic_reference_outside_current_spine','topic':topic['title'],'from':first,'to':returned});continue
  edges.append({'kind':'concept','a':owner[first],'b':owner[returned],'evidence':[{'source':'doc/book/course/execution-plan/plan.json','topic':topic['title'],'from':first,'to':returned,'relation':'declared first → return','scope':topic.get('scope','')}]})
for token,appearances in tokens.items():
 seqs=sorted({x['sequence'] for x in appearances},key=lambda s:[n['id'] for n in nodes].index(s))
 for i,a in enumerate(seqs):
  for b in seqs[i+1:]:edges.append({'kind':'shared','a':a,'b':b,'evidence':[{'token':token,'appearances':[x for x in appearances if x['sequence'] in [a,b]],'relation':'same placement token, not proven shared mutable state'}]})
# Aggregate only identical typed endpoints. Never conflate edges from different sets.
groups={}
for e in edges:
 key=(e['kind'],e['a'],e['b']);groups.setdefault(key,{'kind':e['kind'],'a':e['a'],'b':e['b'],'evidence':[]})['evidence']+=e['evidence']
milestones=[('2026-10-03','point-zero-one-lesson','Opening lesson'),('2026-10-04','museum-tutorial-storyboards','Storyboards'),('2026-10-05','lesson-state-chain','Ghost state chain'),('2026-10-06','trace-saved-to-grid','Trace travels'),('2026-10-07','forces-extravaganza','Forces experiments'),('2026-10-08','fractals-complete-readings','Fractal readings'),('2026-10-09','soft-bodies-complete-readings','Soft-body readings'),('2026-10-10','flow-room-for-another','Graph worlds')]
history=[]
for date,slug,title in milestones:
 p=R/f'doc/book/iterations/{date}-{slug}';assert p.is_dir(),p
 history.append({'date':date,'title':title,'source':p.relative_to(R).as_posix(),'meaning':'date in saved review-folder name, not first invention or completion date'})
data={'schema':'ada-relations/1','snapshot':'2026-10-10','nodes':nodes,'edges':list(groups.values()),'history':history,'omissions':omissions,'source_hashes':sources,'limits':['Spine order is recommended route, not elapsed time.','Dependencies and concept returns are authored plan declarations, not demonstrated mastery.','Shared placement tokens do not prove a carried student object or shared runtime state.','Timeline selects dated review folders; it is not a complete history.','Layout height separates rows for reading; it is not importance.']}
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=Path,default=A/'data.json',help='Alternative snapshot destination; leaves the native artifact snapshot untouched.')
output=parser.parse_args().output
output.parent.mkdir(parents=True,exist_ok=True)
output.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps({'sequences':len(nodes),'maps':len(owner),'relations':len(groups),'omissions':len(omissions),'history':len(history)}))
