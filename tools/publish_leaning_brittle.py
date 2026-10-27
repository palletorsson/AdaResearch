"""Save the selected posture only; retain every arrangement and unrelated edit."""
from pathlib import Path
import json,urllib.request
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/leaning-brittle';read=lambda p:json.loads(p.read_text(encoding='utf-8'))
for name in ['leaning-brittle-physics-checks.json','leaning-brittle-player-checks.json']:assert read(ROOT/'ada_run/matter-reference'/name)['passed']
before=read(OUT/'rooms.before.json');url='http://localhost:3003/api/void-layout';payload=json.load(urllib.request.urlopen(url,timeout=90));rooms=payload['rooms'];entry=next(a for a in rooms['floors'][46]['artifacts'] if a['id']=='matter-leaning-together')
previous=next(a for a in before['floors'][46]['artifacts'] if a['id']==entry['id']);assert entry==previous,'Preserve concurrent authoring edits; rebase this posture update.'
entry.setdefault('config',{})['brittle']=True
request=urllib.request.Request(url,data=json.dumps(dict(rooms=rooms,revision=payload['revision'])).encode(),headers={'Content-Type':'application/json'},method='POST');response=json.load(urllib.request.urlopen(request,timeout=90));assert response['saved']
assert read(ROOT/'commons/void/rooms.json')==rooms and read(Path('C:/Users/palle/Desktop/Ada Void/rooms.json'))==rooms
receipt=dict(passed=True,floor=46,posture='brittle',preserved_authored_parts=entry['config'].get('parts',{}),desktop_vr_mirror=True,save=response)
(OUT/'save-checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print('Saved the brittle posture; positions and authored member overrides retained.')
