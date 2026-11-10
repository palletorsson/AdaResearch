"""Save the verified additive floor through the editor's production API."""
from pathlib import Path
from void_floors import floor_of
import json,urllib.request,urllib.error
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/friction-studies';read=lambda p:json.loads(p.read_text(encoding='utf-8'))
assert read(ROOT/'ada_run/matter-reference/friction-studies-checks.json')['passed']
assert read(ROOT/'ada_run/matter-reference/friction-main-checks.json')['passed']
before=read(OUT/'rooms.before.json');draft=read(OUT/'draft-rooms.json');url='http://localhost:3003/api/void-layout'
payload=json.load(urllib.request.urlopen(url,timeout=90));rooms=payload['rooms'];assert rooms['floors'][floor_of('Vectors_Act4a_KineticForces',rooms)]==before['floors'][floor_of('Vectors_Act4a_KineticForces',before)], 'Kinetic Forces changed during review; preserve and rebase its edits.'
rooms['floors'][floor_of('Vectors_Act4a_KineticForces',rooms)]=draft['floors'][floor_of('Vectors_Act4a_KineticForces',draft)]
request=urllib.request.Request(url,data=json.dumps(dict(rooms=rooms,revision=payload['revision'])).encode(),headers={'Content-Type':'application/json'},method='POST')
try:response=json.load(urllib.request.urlopen(request,timeout=90))
except urllib.error.HTTPError as error:raise RuntimeError(error.read().decode()) from error
assert response['saved'];saved=read(ROOT/'commons/void/rooms.json');assert saved==rooms
assert saved['floors'][floor_of('Vectors_Act4a_KineticForces',saved)]['artifacts'][:5]==before['floors'][floor_of('Vectors_Act4a_KineticForces',before)]['artifacts']
assert read(Path('C:/Users/palle/Desktop/Ada Void/rooms.json'))==saved
receipt=dict(passed=True,floor=floor_of('Vectors_Act4a_KineticForces'),map='Vectors_Act4a_KineticForces',new_studies=3,original_artifacts_preserved=5,desktop_vr_mirror=True,save=response)
(OUT/'save-checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in receipt.items() if k!='save'}))
