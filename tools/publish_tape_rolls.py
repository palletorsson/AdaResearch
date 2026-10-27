"""Publish one additive, tested entry against the current revision."""
import json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/tape-rolls'
def read(path):return json.loads(path.read_text(encoding='utf-8'))
for name in ['tape-rolls-checks.json','tape-rolls-player-checks.json']:
    assert read(ROOT/'ada_run/matter-reference'/name)['passed'],name
before=read(OUT/'rooms.before.json');entry=read(OUT/'entry.json')
url='http://localhost:3003/api/void-layout';payload=json.load(urllib.request.urlopen(url,timeout=90));rooms=payload['rooms']
assert rooms['floors'][3]==before['floors'][3], 'Point Lines changed since staging; rebase rather than replace user work'
rooms['floors'][3]['artifacts'].append(entry)
request=urllib.request.Request(url,data=json.dumps(dict(rooms=rooms,revision=payload['revision'])).encode(),headers={'Content-Type':'application/json'},method='POST')
response=json.load(urllib.request.urlopen(request,timeout=90));assert response['saved'],response
assert read(ROOT/'commons/void/rooms.json')==rooms
assert read(Path('C:/Users/palle/Desktop/Ada Void/rooms.json'))==rooms
(OUT/'save-checks.json').write_text(json.dumps(dict(passed=True,floor=3,entry=entry,preserved_existing_artifacts=len(before['floors'][3]['artifacts']),shared_desktop_vr=True,save=response),indent=2)+'\n',encoding='utf-8')
print('Published tape supply; existing Point Lines artifacts and other floors retained.')
