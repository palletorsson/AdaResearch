"""Revision-guarded save of the reviewed additive floor."""
from pathlib import Path
import json,urllib.request,urllib.error
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/leaning-together';read=lambda p:json.loads(p.read_text(encoding='utf-8'))
for name in ['leaning-physics-checks.json','leaning-player-checks.json']:
    assert read(ROOT/'ada_run/matter-reference'/name)['passed'],name
before=read(OUT/'rooms.before.json');draft=read(OUT/'draft-rooms.json');url='http://localhost:3003/api/void-layout'
payload=json.load(urllib.request.urlopen(url,timeout=90));rooms=payload['rooms'];assert rooms['floors'][46]==before['floors'][46], 'Preserve new user arrangements; rebase this addition.'
rooms['floors'][46]=draft['floors'][46]
request=urllib.request.Request(url,data=json.dumps(dict(rooms=rooms,revision=payload['revision'])).encode(),headers={'Content-Type':'application/json'},method='POST')
try:response=json.load(urllib.request.urlopen(request,timeout=90))
except urllib.error.HTTPError as error:raise RuntimeError(error.read().decode()) from error
assert response['saved'];saved=read(ROOT/'commons/void/rooms.json');assert saved==rooms
assert saved['floors'][46]['artifacts'][:-1]==before['floors'][46]['artifacts']
assert read(Path('C:/Users/palle/Desktop/Ada Void/rooms.json'))==saved
receipt=dict(passed=True,floor=46,original_installations_preserved=8,desktop_vr_mirror=True,save=response)
(OUT/'save-checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print('Saved Leaning Together; all eight existing installations preserved.')
