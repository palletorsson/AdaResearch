"""Apply the authorised GT→ML boundary; retain every hall and artifact within it."""
from pathlib import Path
import copy,json,shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-search-the-same-river'
def read(rel):return json.loads((R/rel).read_text(encoding='utf8'))
def save(rel,data,compact=False):
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
 p.write_text(json.dumps(data,ensure_ascii=False,indent=None if compact else 2)+'\n',encoding='utf8')

rel='commons/maps/curriculum_spine.json';d=read(rel)
row=next(x for x in d['lab_evolution']['actual_progression'] if x['stage']=='post_softbodies')
row['added']=['swarmintelligence'];row['note']='Emergence continues into Swarm Intelligence, then Graph Theory, then Machine Learning.'
save(rel,d)
# The main sequence unlock must not bypass the new prerequisite.
rel='commons/maps/sequences/softbodies.json';d=read(rel)
d['sequences']['softbodies']['unlocks']=[('swarmintelligence' if x=='machinelearning' else x) for x in d['sequences']['softbodies']['unlocks']]
save(rel,d)
order={s['name']:s['order'] for s in read('commons/maps/curriculum_spine.json')['spine']['sequences']}
# This is the museum's actual dealer input. Preserve authored artifact membership/order.
rel='commons/data/spine_artifact_order.json';d=read(rel);old=copy.deepcopy(d['order'])
d['order'].sort(key=lambda x:order.get(x['sequence'],999))
for seq in order:assert [x for x in old if x['sequence']==seq]==[x for x in d['order'] if x['sequence']==seq]
d['_meta']['sequence_revision']='2026-10-10: Graph Theory before Machine Learning; stable chapter reorder only. Artifact membership and within-chapter order retained.'
save(rel,d)
assert not (R/'commons/data/spine_artifact_order_hand.json').exists(), 'Inspect authored override before claiming the runtime order.'
# The atlas's old strip snapshot is a geometric record, not a fresh capture.
rel='commons/data/long_museum.json';d=read(rel);old=copy.deepcopy(d)
d['chapters'].sort(key=lambda x:order.get(x['sequence'],999))
z=0
for c in d['chapters']:
 length=c['z1']-c['z0'];c.update(order=order[c['sequence']],z0=z,z1=z+length);z+=length
d['segments'].sort(key=lambda x:order.get(x['sequence'],999))
z=0
for s in d['segments']:
 length=s['z1']-s['z0'];s.update(chapter=order[s['sequence']],z0=z,z1=z+length);z+=length
for seq in order:
 def geometry(rows):return [{k:v for k,v in x.items() if k not in ['z0','z1','chapter']} for x in rows if x['sequence']==seq]
 assert geometry(old['segments'])==geometry(d['segments'])
d['_sequence_revision']={'date':'2026-10-10','note':'GT then ML. Existing geometry retained, strip offsets recomputed; this is not a new engine walk.'}
save(rel,d,True)
print('Spine metadata, unlocks, runtime artifact order and strip chapter order aligned; inner order retained.')
