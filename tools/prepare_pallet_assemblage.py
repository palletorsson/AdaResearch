"""Add the bounded hand-built pallet study, without replacing existing arrangements."""
import json
import os,uuid
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/pallet-assemblage';OUT.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8'))
def write(p,d):
    f=ROOT/p;f.parent.mkdir(parents=True,exist_ok=True)
    tmp=f.with_name(f.name+'.'+uuid.uuid4().hex+'.tmp')
    tmp.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8');os.replace(tmp,f)
pieces=[]
def part(id,role,size,at):pieces.append(dict(id=id,role=role,source='cube' if role=='block' else 'plank',size=size,position=at,rotation=[0,0,0]))
for i,z in enumerate([-.32,0,.32]):part(f'bottom_{i+1}','bottom board',[1.2,.022,.10],[0,.011,z])
for i,x in enumerate([-.50,0,.50]):
    for j,z in enumerate([-.32,0,.32]):part(f'block_{i+1}_{j+1}','block',[.145,.078,.10],[x,.061,z])
for i,x in enumerate([-.50,0,.50]):part(f'bearer_{i+1}','cross bearer',[.10,.022,.80],[x,.111,0])
for i in range(5):part(f'deck_{i+1}','deck board',[1.2,.022,.145],[0,.133,(i-2)*.16375])
def build(ps):return dict(op='assemblage',parts=[dict(id=p['id'],of=dict(op='compose',parts=[dict(p='mesh',shape='box',size=p['size'],color='c9a978'),dict(p='collider',shape='box',size=p['size']),dict(p='grabbable')]),at=p['position'],rot=p['rotation']) for p in ps])
terms=read('commons/modular/terms.json')
if 'pallet_hand_kit' not in terms['terms']:
    terms['terms']['pallet_hand_kit']=dict(chapter=terms['terms']['eu_pallet']['chapter'],label='Euro pallet / hand assembly',expr='11 planks + 9 blocks → take apart → assemble by hand',build=build(pieces),handmade=dict(version=1,kind='kit',source='eu_pallet',parts=pieces,joined=False,mode='place'),**{'from':['eu_pallet','plank','cube']})
    write('commons/modular/terms.json',terms)
scene='res://commons/artifacts/pallet_assemblage/pallet_assemblage.tscn'
write('commons/artifacts/registry/pallet_assemblage.json',dict(artifacts=dict(pallet_assemblage=dict(lookup_name='pallet_assemblage',name='Euro pallet / take apart and save',scene=scene,map_ready=True,configure_before_ready=True,default_params=dict(term='pallet_hand_kit',workshop=True),description='Twenty separately grabbable timber parts. Place, test gravity, save a reusable loose assemblage. Saving creates no joints.',category='primitives',tags=['pallet','assemblage','handmade','prefab']))))
rooms=read('commons/void/rooms.json')
assert rooms['floors'][12]['map']=='Primitives_Melencolia'
if not any(a['id']=='pallet-hand-workshop' for a in rooms['floors'][12]['artifacts']):
    write('ada_run/pallet-assemblage/before-rooms.json',rooms)
    rooms['floors'][12]['artifacts'].append(dict(id='pallet-hand-workshop',artifact='pallet_assemblage',station='NW',position=[-4,4.8],height=0,facing=0,scale=1,config=dict(term='pallet_hand_kit',workshop=True)))
    write('commons/void/rooms.json',rooms)
print('Prepared 20 independent pieces on floor12; existing artifacts retained.')
