"""Publish the verified additive floor through the production editor save path."""
from pathlib import Path
import json, sys, urllib.request
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/threshold-workshop'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
assert read(ROOT/'ada_run/matter-reference/threshold-main-checks.json')['passed']
before=read(OUT/'main-rooms.before.json');draft=read(OUT/'draft-rooms.json')
url='http://localhost:3003/api/void-layout'
payload=json.load(urllib.request.urlopen(url,timeout=90));current=payload['rooms']
if '--east-correction' in sys.argv:
    assert read(ROOT/'ada_run/matter-reference/threshold-main-east-checks.json')['passed']
    floor=current['floors'][14]
    owned=next(a for a in floor['artifacts'] if a['id']=='threshold-workshop-descent')
    assert owned['position']==[15.5,-6.4] and owned['facing']==0, 'Eventually was edited after placement; preserve the edit.'
    owned.update(position=[18,4.4],facing=270)
    route=floor['route'];assert route[:len(before['floors'][14]['route'])]==before['floors'][14]['route']
    assert route[-2:]==[dict(label='EVENTUALLY / PHYSICAL MARGINS',position=[15.35,-3.6]),dict(label='RETURN TO SHAFT B',position=[10,-3.6])]
    floor['route']=route[:-2]+draft['floors'][14]['route'][-6:]
else:
    assert current['floors'][14]==before['floors'][14], 'Floor 14 changed during review; preserve the edits and rebase explicitly.'
    current['floors'][14]=draft['floors'][14]
request=urllib.request.Request(url,data=json.dumps(dict(rooms=current,revision=payload['revision'])).encode(),headers={'Content-Type':'application/json'},method='POST')
response=json.load(urllib.request.urlopen(request,timeout=90))
assert response['saved'],response
saved=read(ROOT/'commons/void/rooms.json');assert saved==current
assert saved['floors'][14]['artifacts'][:len(before['floors'][14]['artifacts'])]==before['floors'][14]['artifacts']
for key in before['floors'][14]:
    if key not in ['artifacts','route']:assert saved['floors'][14][key]==before['floors'][14][key],key
mirror=Path('C:/Users/palle/Desktop/Ada Void/rooms.json')
assert mirror.exists() and read(mirror)==saved
receipt=dict(passed=True,floor=14,added_artifacts=6,existing_floor_objects_preserved=True,other_floors_preserved=True,desktop_vr_mirror=True,save=response)
(OUT/'save-checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in receipt.items() if k!='save'}))
