"""Additive main-floor draft. No existing tutorial object is moved or removed."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/friction-studies';OUT.mkdir(parents=True,exist_ok=True)
rooms=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf-8'));assert rooms['floors'][46]['map']=='Vectors_Act4a_KineticForces'
assert not any(a['id'].startswith('matter-friction-') for a in rooms['floors'][46]['artifacts'])
(OUT/'rooms.before.json').write_text(json.dumps(rooms,indent=2)+'\n',encoding='utf-8')
draft=json.loads(json.dumps(rooms));floor=draft['floors'][46]
for kind,position in [('pull',[-14.2,0]),('ramp',[-16,-5.8]),('coast',[15.8,-5.8])]:
    floor['artifacts'].append(dict(id='matter-friction-'+kind,artifact='matter_friction_'+kind,station='NW',position=position,height=0,scale=1,facing=0,config=dict(study=kind)))
floor.setdefault('route',[]).extend([dict(label=label,position=position) for label,position in [
 ('ALMOST ENOUGH / WEST SLAB',[-14.2,3.2]),('AROUND THE PULL RIG',[-18,3.2]),('WEST AISLE',[-18,-2.65]),('LET GO / THE SLOPE',[-16,-2.65]),('RETURN WEST',[-18,-2.65]),('SOUTH AISLE',[-18,3.2]),('AROUND BOTH SHAFTS',[15.8,3.2]),('KEEP GOING / SAME PUSH',[15.8,-2.6])]])
(OUT/'draft-rooms.json').write_text(json.dumps(draft,indent=2)+'\n',encoding='utf-8')
print('Prepared three new floor-46 studies; saved rooms unchanged.')
