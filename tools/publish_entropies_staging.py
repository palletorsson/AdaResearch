"""Merge only the tested floor and the lower room's clearance setting."""
import json, urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-23-entropies-staging'
URL='http://localhost:3003/api/void-layout'

def request(data=None):
    req=urllib.request.Request(URL, data=None if data is None else json.dumps(data).encode(),headers={'Content-Type':'application/json'})
    with urllib.request.urlopen(req,timeout=90) as response:return json.load(response)

if __name__=='__main__':
    checks=json.loads((OUT/'native/checks.json').read_text(encoding='utf8'))
    assert checks['passed'],checks['failed']
    fresh=request()
    before=json.loads((OUT/'before-floor.json').read_text(encoding='utf8'))
    draft=json.loads((OUT/'draft-rooms.json').read_text(encoding='utf8'))
    assert fresh['rooms']['floors'][72]==before,'Floor 72 changed in the editor: merge that work before publishing.'
    (OUT/'before-publish.json').write_text(json.dumps(fresh['rooms'],indent=2)+'\n',encoding='utf8')
    fresh['rooms']['floors'][72]=draft['floors'][72]
    room=next(a for a in fresh['rooms']['floors'][73]['artifacts'] if a['id']=='f1_signal_room_12_48')
    room.setdefault('config',{})['void_room_height']=5.4
    # Keep the person's current room position, facing and scale.
    result=request({'rooms':fresh['rooms'],'revision':fresh['revision']})
    (OUT/'publish.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in result.items() if k not in ['warnings','rooms']},indent=2))
