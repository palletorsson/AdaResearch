"""Apply the one-metre, raised, electric-course and tc-lift steering via editor save."""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'doc/ports/2026-10-26-rotation-z-width/electric';OUT.mkdir(parents=True,exist_ok=True)
catalog_file=ROOT/'commons/void/catalog.json';catalog=json.loads(catalog_file.read_text(encoding='utf8'))
for key,scene,label,footprint in [('void_rotation_gantry','rotation_gantry','Rotation / safe gantry',[14,4.5,17]),('void_rotation_electric_bed','rotation_electric_bed','Rotation / live electric bed',[6.2,.5,14.4]),('void_rotation_tc_lift','rotation_tc_lift','tc / gantry lift',[2,4.5,2])]:
    catalog['artifacts'][key]=dict(scene='res://commons/void/'+scene+'.tscn',label=label,footprint=footprint,museum_import=True)
(OUT/'before-catalog.json').write_bytes(catalog_file.read_bytes());catalog_file.write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf8')
URL='http://localhost:3003/api/void-layout'
def post(payload):
    with urllib.request.urlopen(urllib.request.Request(URL,json.dumps(payload).encode(),{'Content-Type':'application/json'}),timeout=120) as r:return json.load(r)
current=json.load(urllib.request.urlopen(URL,timeout=60));before=current['rooms'];rooms=copy.deepcopy(before);floor=rooms['floors'][16]
assert not any(a['id']=='gantry-tc' for a in floor['artifacts']),'Already staged; preserve edits'
(OUT/'before-rooms.json').write_text(json.dumps(before,indent=2)+'\n',encoding='utf8')
for artifact in floor['artifacts']:
    if artifact['id'] in ['angle-bands','z-wide']:
        artifact['config'].update(cube_edge=1.0,cube_pitch=1.0,walkway_height=3.5)
        if artifact['id']=='angle-bands':artifact['config']['tower_band_positions']={'X':[-6,3.5,-2.75],'Y':[-3,3.5,-2.75],'Z':[3,3.5,-2.75],'XYZ':[6,3.5,-2.75]}
        else:artifact['position']=[0,0]
for id,kind,pos,height,config in [('rotation-gantry','void_rotation_gantry',[0,0],0,{'deck_height':3.5}),('rotation-electric','void_rotation_electric_bed',[0,0],2.0,{'width':6.2,'depth':14.4}),('gantry-tc','void_rotation_tc_lift',[-8,4.5],0,{'rise':3.5})]:
    floor['artifacts'].append(dict(id=id,artifact=kind,station='SE',position=pos,height=height,facing=0,scale=1,config=config))
validation=post(dict(rooms=rooms,revision=current['revision'],validateOnly=True));assert validation['valid'],validation
receipt=post(dict(rooms=rooms,revision=current['revision']))
after=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf8'));assert after==rooms
assert all(after['floors'][i]==before['floors'][i] for i in range(len(before['floors'])) if i!=16)
assert after['floors'][16]['construction']==before['floors'][16]['construction']
(OUT/'save-receipt.json').write_text(json.dumps(dict(passed=True,receipt=receipt,cube_edge_m=1,centre_pitch_m=1,gantry_height_m=3.5,hazard_height_m=2,transport_source='tc',other_floors_unchanged=True),indent=2)+'\n',encoding='utf8')
print('Saved one-metre courses at 3.5 m with separate electric bed, gantry and tc lift.')
