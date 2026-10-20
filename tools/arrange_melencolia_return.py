"""Name the existing court walk, then carry it through composition and the counter."""
from pathlib import Path
import hashlib, json, urllib.request
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-melencolia-carried-forms'
endpoint='http://localhost:3003/api/void-layout'
payload=json.load(urllib.request.urlopen(endpoint))
rooms=payload['rooms']
index=next(i for i,f in enumerate(rooms['floors']) if f['map']=='Primitives_Melencolia')
floor=rooms['floors'][index]
before=json.loads((OUT/'layout-change.json').read_text())['before'] if (OUT/'layout-change.json').exists() else json.loads(json.dumps(floor))
stops=[('Arrival',11,4),('Approach the court',7,4),('East view',7,2.7),('Wedges from Polyhedra',0,2.7),
       ('On the court',0,0),('Between the same bodies',-1,0),('Another viewpoint',-1,-.9),
       ('Return to the ramp',0,0),('Down the wedge',0,3),('South aisle',-6,4),('Winged skull',-13,4),
       ('Return along the aisle',-6,4),('Around the composition table',0,6.6),('Arrange the carried solids',4,6.6),
       ('Around the column',4,8.2),('East aisle',8,8.2),('Along the shaft',8,4),('Beyond the shaft',13,4),('Box library returns',14.5,1.5),
       ('The counter is still running',16,4.5)]
floor['route']=[{'label':label,'position':[x,z]} for label,x,z in stops]
request=urllib.request.Request(endpoint,data=json.dumps({'rooms':rooms,'revision':payload['revision']}).encode(),headers={'Content-Type':'application/json'},method='POST')
receipt=json.load(urllib.request.urlopen(request))
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'layout-change.json').write_text(json.dumps({'floor':index,'before':before,'after':floor,'receipt':receipt,
 'preserved_text_sha256':{name:hashlib.sha256((ROOT/'commons/maps/Primitives_Melencolia'/name).read_bytes()).hexdigest() for name in ['final.md','tutorial.md']}},indent=2),encoding='utf-8')
print(json.dumps(receipt))
