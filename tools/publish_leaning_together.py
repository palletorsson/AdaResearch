"""Revision-guarded save of the reviewed additive floor."""
from pathlib import Path
from void_floors import floor_of
import json,urllib.request,urllib.error
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/leaning-together';read=lambda p:json.loads(p.read_text(encoding='utf-8'))
for name in ['leaning-physics-checks.json','leaning-player-checks.json']:
    assert read(ROOT/'ada_run/matter-reference'/name)['passed'],name
before=read(OUT/'rooms.before.json');draft=read(OUT/'draft-rooms.json');url='http://localhost:3003/api/void-layout'
payload=json.load(urllib.request.urlopen(url,timeout=90));rooms=payload['rooms'];assert rooms['floors'][floor_of('Vectors_Act4a_KineticForces',rooms)]==before['floors'][floor_of('Vectors_Act4a_KineticForces',before)], 'Preserve new user arrangements; rebase this addition.'
rooms['floors'][floor_of('Vectors_Act4a_KineticForces',rooms)]=draft['floors'][floor_of('Vectors_Act4a_KineticForces',draft)]
request=urllib.request.Request(url,data=json.dumps(dict(rooms=rooms,revision=payload['revision'])).encode(),headers={'Content-Type':'application/json'},method='POST')
try:response=json.load(urllib.request.urlopen(request,timeout=90))
except urllib.error.HTTPError as error:raise RuntimeError(error.read().decode()) from error
assert response['saved'];saved=read(ROOT/'commons/void/rooms.json');assert saved==rooms
assert saved['floors'][floor_of('Vectors_Act4a_KineticForces',saved)]['artifacts'][:-1]==before['floors'][floor_of('Vectors_Act4a_KineticForces',before)]['artifacts']
assert read(Path('C:/Users/palle/Desktop/Ada Void/rooms.json'))==saved
receipt=dict(passed=True,floor=floor_of('Vectors_Act4a_KineticForces'),map='Vectors_Act4a_KineticForces',original_installations_preserved=8,desktop_vr_mirror=True,save=response)
(OUT/'save-checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print('Saved Leaning Together; all eight existing installations preserved.')
