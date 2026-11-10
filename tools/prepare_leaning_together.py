"""Add one independently editable study without replacing any saved arrangement."""
from pathlib import Path
from void_floors import floor_of
import json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/leaning-together';OUT.mkdir(parents=True,exist_ok=True)
rooms=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf-8'))
assert rooms['floors'][floor_of('Vectors_Act4a_KineticForces',rooms)]['map']=='Vectors_Act4a_KineticForces'
assert not any(a['id']=='matter-leaning-together' for a in rooms['floors'][floor_of('Vectors_Act4a_KineticForces',rooms)]['artifacts'])
assert not (OUT/'rooms.before.json').exists(), 'Preserve the existing review baseline.'
(OUT/'rooms.before.json').write_text(json.dumps(rooms,indent=2)+'\n',encoding='utf-8')
draft=json.loads(json.dumps(rooms));floor=draft['floors'][floor_of('Vectors_Act4a_KineticForces',draft)]
floor['artifacts'].append(dict(id='matter-leaning-together',artifact='matter_leaning_together',station='SW',position=[-16.8,6],height=0,scale=1,facing=180,config={}))
floor['route'].append(dict(label='LEANING TOGETHER / HOLD, PLACE, WITHDRAW',position=[-16.8,3.8]))
(OUT/'draft-rooms.json').write_text(json.dumps(draft,indent=2)+'\n',encoding='utf-8')
print('Prepared one additive Kinetic Forces study. Saved arrangement is unchanged.')
