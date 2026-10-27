"""Join the real two-metre wedge ends to the three-metre comparison banks."""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/transformation-walkability'
url='http://localhost:3003/api/void-layout'
current=json.load(urllib.request.urlopen(url));before=current['rooms'];rooms=copy.deepcopy(before);f=rooms['floors'][16]
f['construction']=[c for c in f['construction'] if not c['id'].startswith(('WalkRamp','WalkStart-','WalkFinish-'))]
def add(id,kind,x,y,z,facing=0):f['construction'].append(dict(id=id,kind=kind,position=[x,y,z],facing=facing))
for side,x in [('Start',-6.5),('Finish',6.5)]:
    for z in range(-8,9):
        for y in range(3):add(f'Walk{side}-{z}-{y}','cube',x,y,z)
for side,sign,z in [('Start',1,-7.5),('Finish',-1,7.5)]:
    for step in range(3):
        x=sign*(-12+step*2)
        for offset in [-.5,.5]:
            for y in range(step):add(f'WalkRampBase-{side}-{step}-{int(offset*2)}-{y}','cube',x+offset,y,z)
        add(f'WalkRamp-{side}-{step}','wedge',x,step,z,90 if sign==1 else 270)
for a in f['artifacts']:
    if a['id']=='carousel-column':a['position']=[-15,-4.5]
    if a['id']=='carousel-cake':a['position']=[-18,-6.5]
    if a['id']=='hinge':a['position']=[17.8,6]
f['route'][0]['position']=[-13.4,-7.5];f['route'][4]['position']=[13.4,7.5]
assert all(rooms['floors'][i]==before['floors'][i] for i in range(len(before['floors'])) if i!=16)
def post(data):return json.load(urllib.request.urlopen(urllib.request.Request(url,json.dumps(data).encode(),{'Content-Type':'application/json'},method='POST')))
assert post(dict(rooms=rooms,validateOnly=True))['valid']
receipt=post(dict(rooms=rooms,revision=current['revision']))
(OUT/'access-save-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
graph_file=ROOT/'commons/void/capacity-artifacts.json';graph=json.loads(graph_file.read_text(encoding='utf-8'))
for node in graph['nodes']:
    if node['id']=='trans_16_angle_bands':
        node.update(title='Walkable rotation gradients / four bodily trials',learn='Walk equal full-size cubes as their orientation changes. Slopes, ridges and gaps make walkability depend on body width and direction.')
graph_file.write_text(json.dumps(graph,indent=2)+'\n',encoding='utf-8')
print('Joined two-metre ramps, widened common banks, cleared the approach and kept the hinge inside the floor.')
