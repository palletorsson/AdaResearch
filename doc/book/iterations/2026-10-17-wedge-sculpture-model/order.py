from pathlib import Path
from collections import Counter
import json,shutil,sys
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent;ROOM='Primitives_Polythedra'
sys.path.insert(0,str(ROOT/'tools'))
import build_spine_artifact_order as producer
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
for rel in ['commons/data/artifact_roles.json','commons/data/spine_artifact_order.json']:
    dest=HERE/'before'/rel
    if not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,dest)
p=ROOT/'commons/data/artifact_roles.json';d=read(p);roles=d['roles'][ROOM];order=d['order'][ROOM]
for key in ['align_tetrahedron','align_wedge','corner_tetrahedron','grab_trihedron','polyhedra_boundary_plate']:
    roles[key]={'role':'primary','group':'enclosure-and-collision'}
order['primary|enclosure-and-collision']=['align_tetrahedron','align_wedge','corner_tetrahedron','grab_trihedron','polyhedra_boundary_plate']
roles['pyramid_edit']={'role':'primary','group':'count-and-change'}
for g in d['groups'][ROOM]:
    if g['id']=='count-and-change':g['role']='primary'
    if g['id']=='stop-and-flow':g['title']='Blocking, climbing, sculpture and a small route'
order['primary|count-and-change']=['pyramid_edit']
order['primary']=['#note-1','@enclosure-and-collision','@count-and-change','#note-2','@stop-and-flow']
order['secondary']=[x for x in order['secondary'] if x!='@count-and-change']
for key in ['prism_block','wedge_palace','wedge_column','wedge_mouse_model','concrete_barrier']:
    roles[key]={'role':'primary','group':'stop-and-flow'}
order['primary|stop-and-flow']=['prism_block','wedge_palace','wedge_column','wedge_mouse_model','concrete_barrier']
roles['street_sign']='decoration'
save(p,d)
p=ROOT/'commons/data/spine_artifact_order.json';manifest=read(p);rows=manifest['order'];first=next(i for i,r in enumerate(rows) if r['map']==ROOM)
producer.ROLES=d
seen={r['lookup'] for r in rows[:first]}
fresh=[]
for key,role,by in producer.thread(ROOM):
    if key not in seen:
        fresh.append({'lookup':key,'sequence':'primitives','map':ROOM,'role':role,'by':by});seen.add(key)
manifest['order']=rows[:first]+fresh+[r for r in rows[first:] if r['map']!=ROOM]
meta=manifest['_meta'];meta['artifacts']=len(manifest['order']);meta['ordered_by']=dict(Counter(r['by'] for r in manifest['order']))
meta['primary']=sum(r['role']=='primary' for r in manifest['order']);meta['unruled']=sum(r['role']=='unruled' for r in manifest['order'])
refresh=meta.setdefault('scoped_refresh',{});refresh['date']='2026-10-17';refresh.setdefault('maps',[])
if ROOM not in refresh['maps']:refresh['maps'].append(ROOM)
save(p,manifest)
print('Refreshed only Polythedra curation and spine rows; existing notes retained.')
