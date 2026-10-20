"""Authored layout for the FBM bathhouse; retains all three exhibit identities."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
path = ROOT / 'commons/maps/Shader_09_FBM/map_data.json'
data = json.loads(path.read_text(encoding='utf-8-sig'))
w, d = 26, 29
data['map_info']['dimensions'] = dict(width=w, depth=d, max_height=6)
data['map_info']['museum'].update(
    gate_depth_rows=0, gate=False,
    sculpture_clear_rects=[[0,0,w-1,d-1]],
    basin=dict(depth=1.2, glass=False, fire=False, rects=[[7,7,11,11]]))
data['map_info']['description'] = 'A bathhouse for layered noise: hold a field, compare colour, normal and vertex height, cross it on glass.'
structure = [['5' if x in (0,w-1) or z in (0,d-1) else '1' for x in range(w)] for z in range(d)]
for x in (11,12,13):
    structure[0][x] = '1'
    structure[d-1][x] = '1'
layers = {'structure':structure, 'utilities':[[' ']*w for _ in range(d)], 'interactables':[[' ']*w for _ in range(d)]}
layers['utilities'][1][12]='s'
layers['utilities'][27][12]='t'
for x,z,token in [
    (12,4,'basin_water:180:0#width:11#depth:11#study:on#pin:1#plinth:0'),
    (12,24,'shader_09_fbm:180:0#setting:wall#pin:1#plinth:0'),
    (4,20,'dark_sphere:0:0#pin:1')]: layers['interactables'][z][x]=token
data['layers']=layers
data['utility_definitions']['t']['name']='Next: Pink Extravaganza'
data['utility_definitions']['t']['description']='Compose surface, pattern and displacement in the next setting.'
path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(path)
