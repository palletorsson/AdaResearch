from pathlib import Path
import json, hashlib

H=Path(__file__).resolve().parent
R=H.parents[3]
M='SpeculativeComputation_Rhizome_Network'
A='rhizome_grower'
S='postfoundationscrisis'
speech='Remove a busy node. What still connects?'
def read(p): return json.loads((R/p).read_text(encoding='utf-8'))
def write(p,d): (R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

p='commons/data/museum_core_encounters.json'
d=read(p)
e=d['rooms'][M]
e.update(status='runtime_checked_draft',learner_verified=False,
 reason='Hold the same points, compare one and three nearby links, then remove the same node. No named root does not imply equal degree or automatic repair.',
 review_report=H.relative_to(R).as_posix()+'/SUMMARY.md')
for key,name in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
 e[key]=hashlib.sha256((R/'commons/maps'/M/name).read_bytes()).hexdigest()
write(p,d)
p='commons/artifacts/registry/postfoundations_crisis.json'
d=read(p)
e=d['artifacts'][A]
e['description']='Points sampled inside a fixed annulus connect to earlier neighbours. Interactive placements compare one or three links on identical points, inspect birth order and degree, and temporarily remove nodes to count surviving connected groups.'
e['parameters'].update(interactive='Bool',sample_seed='Int',max_nodes='Int',links_per_node='Int',grow_period='Float',spread='Float')
e['map_note']='Interactive hall placement faces arrival at (5,5), at floor level, with spread 0.85. Measured local bounds are about 3.40 m wide, 1.69 m high and 2.06 m deep including side readouts and controls. Existing measurements describe the smaller passive display. Clear the approach and preserve room for circulation.'
write(p,d)
p=f'commons/data/book/{S}.json'
d=read(p)
e=next(v for v in d['pearls'] if v['map']==M)
e['hero']=A
e['lines']=[{'token':A,'text':speech,'by':'hand'}]
write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p)
 chapter=next(v for v in d['trunk'] if v['node']==S)
 # Both the generated pearl and its hand override must agree.
 e=next(v for v in chapter['pearls'] if v['map']==M)
 e.update(hero=A,hero_by='hand',says={A:speech},says_by={A:'hand'})
 e=next(v for v in d['hand_pearls'][S] if v['map']==M)
 e.update(hero=A,says={A:speech},says_by={A:'hand'})
 write(p,d)
