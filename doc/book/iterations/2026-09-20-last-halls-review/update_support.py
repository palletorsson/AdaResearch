from pathlib import Path
import json, hashlib

H=Path(__file__).resolve().parent; R=H.parents[3]
A='AdvancedLaboratory_Lab_Equipment_Simulation'; Z='PostCrisis_Synthesis'
def edit(room,name,old,new):
 p=R/'commons/maps'/room/name; text=p.read_text(encoding='utf-8')
 assert old in text,(room,name,old)
 p.write_text(text.replace(old,new),encoding='utf-8')

old='Choose a visible part during the floating phase. Follow it as an assembly forms. Watch another floating phase and a different assembly; notice both its destination and any change of shape or colour.'
new='Walk around the floating inventory and follow the part carrying the amber ring. Keep that instance in view as the body gives way to a chair or another assembly. Its position and visible form can change while the ring remains with it.'
for name in ['technical.md','critical.md','tutorial.md','summary.md']:
 edit(A,name,old,new)
for name in ['critical.md','tutorial.md']:
 edit(A,name,'or does it demand a part the inventory cannot supply?', 'or does it demand a kind of part the catalogue does not describe? The initial inventory is mutable: an assembly can retype an existing instance or create more instances.')
edit(A,'technical.md',"MolecularDesigner.tscn enables automatic ten-second floating and assembling phases and starts with forty part instances.","The scene starts with forty reusable part instances. This hall configures eight seconds of floating, eighteen seconds of assembly, scale 2 and body_study=true. An amber ring stays attached to the first instance as its catalogue type changes. The source scene's default phases remain ten seconds elsewhere.")
edit(A,'technical.md','while idle translation accumulates a sine-derived offset each frame.', 'while idle translation accumulates a sine-derived offset weighted by elapsed time. Inventory positions are local to the exhibit; target positions use to_global(), so museum position, rotation and scale apply to the assembly. Changing assembly releases surplus instances from their previous targets.')
old='This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book\'s encounter, not the only permitted content.'
new='The private museum probe checks instantiated behaviour and selected walking routes. See the [current evidence](../../../doc/book/iterations/2026-09-20-last-halls-review/SUMMARY.md). Headset readability, comfort, Quest performance and learner understanding remain unverified. The assembly parts are visual objects without supporting collision: walking among them does not establish a chair you can sit on or a body you can wear.'
edit(A,'technical.md',old,new)
edit(Z,'technical.md','The defaults are log_interval=1.8 and visible_lines=6.', 'The source defaults are log_interval=1.8 and visible_lines=6. This hall sets log_interval=6, places the ledger at height 0.65 m and scale 1.8, and faces its readout towards arrival. The six lines sit on the physical panel with depth testing. Configuration rebuilding preserves museum-added children.')
edit(Z,'technical.md',old,'The private museum probe checks the bounded buffer, timer, configuration rebuilding and selected routes. See the [current evidence](../../../doc/book/iterations/2026-09-20-last-halls-review/SUMMARY.md). Headset readability, comfort, Quest performance and learner understanding remain unverified. All six existing artifact families remain in the map; primary status identifies the book\'s encounter, not the only permitted content.')
for name in ['tutorial.md','critical.md','summary.md']:
 edit(Z,name,'The examples are prewritten.', 'The examples are prewritten and arrive every six seconds.')
for name in ['tutorial.md','critical.md']:
 edit(Z,name,'Return to one earlier hall. The spine has supplied tools for another pass, not a final inventory of possible bodies.', 'Return to one earlier hall. Remember both an obstacle and a form you wanted to enter. Desire can locate a next experiment as clearly as a fault. The spine has supplied tools for another pass, not a final inventory of possible bodies.')

def read(rel): return json.loads((R/rel).read_text(encoding='utf-8'))
def write(rel,data): (R/rel).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
speeches={A:('MolecularDesigner','Follow the amber ring. Which part stays the same?'),Z:('accountability_ledger','The count continues. Which consequence will you carry back?')}
rel='commons/data/museum_core_encounters.json'; d=read(rel)
for room,(hero,speech) in speeches.items():
 e=d['rooms'][room]
 e.update(status='runtime_checked_draft',learner_verified=False,review_report=H.relative_to(R).as_posix()+'/SUMMARY.md',reason=speech)
 for key,name in [('text_sha256','final.md'),('map_sha256','map_data.json')]: e[key]=hashlib.sha256((R/'commons/maps'/room/name).read_bytes()).hexdigest()
write(rel,d)
rel='commons/data/book/postfoundationscrisis.json';d=read(rel)
for room,(hero,speech) in speeches.items():
 e=next(v for v in d['pearls'] if v['map']==room);e['hero']=hero;e['lines']=[{'token':hero,'text':speech,'by':'hand'}]
write(rel,d)
for rel in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(rel); chapter=next(v for v in d['trunk'] if v['node']=='postfoundationscrisis')
 for room,(hero,speech) in speeches.items():
  e=next(v for v in chapter['pearls'] if v['map']==room);e.update(hero=hero,hero_by='hand',says={hero:speech},says_by={hero:'hand'})
  e=next(v for v in d['hand_pearls']['postfoundationscrisis'] if v['map']==room);e.update(hero=hero,says={hero:speech},says_by={hero:'hand'})
 write(rel,d)
rel='commons/artifacts/registry/postfoundations_crisis.json'; d=read(rel)
e=d['artifacts']['accountability_ledger']
e['description']='An illustrative ledger cycles through paired, prewritten design choices and exclusions. Six visible examples form a bounded buffer while the entry count continues. It does not record visitor decisions or persist a visit.'
e.setdefault('parameters',{}).update(log_interval='Float',visible_lines='Int')
write(rel,d)
print('Aligned supporting text and two encounter records.')
