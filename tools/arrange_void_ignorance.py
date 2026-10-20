"""Restore comparison groups through the revision-checked shared editor API."""
from pathlib import Path
import hashlib, json, urllib.request, urllib.error
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-ignorance-comparison-path'
OUT.mkdir(parents=True,exist_ok=True)
ENDPOINT='http://localhost:3003/api/void-layout'
assert not (OUT/'layout-change.json').exists(), 'Already applied; preserve later curation.'
p=json.load(urllib.request.urlopen(ENDPOINT));rooms=p['rooms'];f=rooms['floors'][8]
assert f['map']=='Primitives_Ignorance'
(OUT/'floor8-before.json').write_text(json.dumps(f,indent=2),encoding='utf-8')
others=json.dumps(rooms['floors'][:8]+rooms['floors'][9:],sort_keys=True)
original_ids=[a['id'] for a in f['artifacts']]
by_id={a['id'].removeprefix('museum-primitives_ignorance-'):a for a in f['artifacts']}
for row,prefix in enumerate(['18','21','24']):
    for suffix,x in [('13',-1.6),('16',1.6)]:
        a=by_id[prefix+'-'+suffix];a['position']=[x,2.5-row*2.5];a['height']=1.35
        a['config']['editor_label']=f'{a["artifact"].replace("_"," ")} / '+('edges visible' if suffix=='13' else 'plain surface')
by_id['2-6']['position']=[4.8,2.5]
by_id['2-6']['height']=1.10
# Clear the original atlas and its entry. Keep every source object and variant.
poses={'16-1':[-16,-5.5], '39-23':[-18.8,-4.8], '39-25':[-18.7,4.9],
       '33-21':[-13.5,5.5], '33-19':[-13.3,-5.4], '30-23':[4.9,-1.3],
       '36-23':[-18.4,6.5], '39-19':[-18.6,-6.4]}
for key,position in poses.items(): by_id[key]['position']=position
by_id['16-1']['config']['museum_yaw']=0
by_id['33-19']['config']['museum_yaw']=270
# The five-solids plaque belongs to its northern row, outside the sphere aisle.
parts=by_id['hall'].setdefault('config',{}).setdefault('parts',{})
parts['Caption_2']={'position':[0,.025,-3.7]}
parts['BudgetOfSmoothness']={'position':[-4.7,0,.5],'rotation':[0,0,0]}
route=[('Arrival',[11,4]),('Ordinary sphere',[4.8,3.8]),('Enter the comparisons',[0,4.8]),
       ('16 rings / edges and surface',[0,2.5]),('7 rings / edges and surface',[0,0]),
       ('1 ring / edges and surface',[0,-2.5]),('Five exact solids',[0,-3.5]),
       ('West of comparisons',[-2.7,-3.5]),('South aisle',[-2.7,4]),
       ('Reveal counts and edges',[-4.7,2]),('Leave the counter',[-4.7,4]),
       ('Atlas approach',[-13,4]),('Atlas entrance',[-16.79,4.3]),
       ('Atlas first row',[-16.79,1.85]),('Atlas middle rows',[-16.79,0]),
       ('Atlas far row',[-16.79,-1.85]),('Atlas return',[-16.79,4.3]),
       ('Back around shaft A',[-13,4]),('Towards the next descent',[6,4]),
       ('Next descent',[13.1,4])]
f['route']=[{'label':label,'position':pos} for label,pos in route]
assert original_ids==[a['id'] for a in f['artifacts']]
assert others==json.dumps(rooms['floors'][:8]+rooms['floors'][9:],sort_keys=True)
request=urllib.request.Request(ENDPOINT,data=json.dumps({'rooms':rooms,'revision':p['revision']}).encode(),headers={'Content-Type':'application/json'},method='POST')
try:receipt=json.load(urllib.request.urlopen(request))
except urllib.error.HTTPError as e:raise RuntimeError(e.read().decode()) from e
(OUT/'layout-change.json').write_text(json.dumps({'receipt':receipt,'artifact_ids':original_ids,
    'other_floors_sha256':hashlib.sha256(others.encode()).hexdigest(),
    'preserved_text_sha256':{name:hashlib.sha256((ROOT/'commons/maps/Primitives_Ignorance'/name).read_bytes()).hexdigest() for name in ['final.md','tutorial.md']}},indent=2),encoding='utf-8')
print('Saved floor 8. Original artifacts retained; other floors unchanged.')
