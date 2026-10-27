"""Prepare an additive floor-14 draft; never replace the user's saved rooms."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/threshold-workshop';OUT.mkdir(parents=True,exist_ok=True)
saved=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf-8'))
floor=saved['floors'][14]
assert floor['map']=='Trans_Introduction'
assert not any(a['id'].startswith('threshold-workshop-') for a in floor['artifacts'])
(OUT/'main-rooms.before.json').write_text(json.dumps(saved,indent=2)+'\n',encoding='utf-8')
graphs=json.loads((ROOT/'commons/artifacts/matter_reference/material-programs.json').read_text(encoding='utf-8'))['graphs']
draft=json.loads(json.dumps(saved))
target=draft['floors'][14]
for kind,x in [('again',-17.25),('almost',-10.75),('just',-4.25),('barely',2),('still',8.5),('descent',15.5)]:
    frame_x=graphs['almost_'+kind+'_0']['frame']['x']
    target['artifacts'].append(dict(id='threshold-workshop-'+kind,artifact='threshold_'+kind,station='NW',position=[x,-6.4],height=0,scale=1,facing=0,
        config=dict(threshold=kind,editor_label='Matter / '+('Eventually' if kind=='descent' else kind.title()),parts={'Controls':dict(position=[frame_x,.8,1.2])})))
target['artifacts'][-1].update(position=[18,4.4],facing=270)
target.setdefault('route',[]).extend([
    dict(label='THRESHOLDS / AROUND THE WEST RAMP',position=[-19.2,4]),
    dict(label='NORTH AISLE / ON THE SOLID SLAB',position=[-19.2,-3.6]),
    *[dict(label=kind.upper()+' / PHYSICAL MARGINS',position=[x,-3.6]) for kind,x in [('again',-17.25),('almost',-10.45),('just',-4.45),('barely',1.3),('still',8.5)]],
    dict(label='AROUND SHAFT B / EAST AISLE',position=[13.1,-3.6]),
    dict(label='EAST BAY / PHYSICAL MARGINS',position=[13.1,4.25]),
    dict(label='EVENTUALLY / COOLING INTO A VALLEY',position=[15.2,4.25]),
    dict(label='AROUND SHAFT B / RETURN',position=[13.1,4.25]),
    dict(label='NORTH AISLE / RETURN',position=[13.1,-3.6]),
    dict(label='RETURN TO SHAFT B',position=[10,-3.6])])
(OUT/'draft-rooms.json').write_text(json.dumps(draft,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(prepared=True,floor=14,added=6,saved_rooms_unchanged=True)))
