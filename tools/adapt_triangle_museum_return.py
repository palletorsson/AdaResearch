"""Narrow, revision-checked layout edit. Run once; retain the before/after receipt."""
from pathlib import Path
import copy, hashlib, json, urllib.request

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-19-triangle-museum-return'
OUT.mkdir(parents=True, exist_ok=True)
receipt = OUT / 'layout-change.json'
assert not receipt.exists(), 'Already applied; do not overwrite the original receipt.'
url = 'http://localhost:3003/api/void-layout'
payload = json.load(urllib.request.urlopen(url))
before = payload['rooms']
rooms = copy.deepcopy(before)
floor = rooms['floors'][5]
items = {a['id']: a for a in floor['artifacts']}
# Only the enlargement was inside the shaft. Leave all other curator poses intact.
items['drawing']['config']['parts']['LiveTwin']['position'] = [-16, 0, 1.6]
# Existing captions follow the user's relocated exhibits, on solid floor.
for area, name, at in [
    ('arrival', 'Caption', [-16.25, .025, 8.2]),
    ('arrival', 'Caption_2', [-16.25, .025, 8.65]),
    ('drawing', 'Caption', [-10, .025, -3.55]),
    ('surfaces', 'Caption', [-1.5, .025, -6.4]),
    ('assembly', 'Caption', [0, .025, -7.1]),
]:
    items[area]['config']['parts'][name] = {'position': at}
request = urllib.request.Request(url, data=json.dumps({'rooms': rooms, 'revision': payload['revision']}).encode(), headers={'Content-Type': 'application/json'}, method='POST')
response = json.load(urllib.request.urlopen(request))
after = json.load(urllib.request.urlopen(url))['rooms']
assert after == rooms
hashes = {name: hashlib.sha256((ROOT/'commons/maps/Point_Triangle_Context'/name).read_bytes()).hexdigest() for name in ['final.md', 'tutorial.md', 'map_data.json']}
receipt.write_text(json.dumps({'before': before, 'after': after, 'preserved_text_sha256': hashes, 'saved': response}, indent=2), encoding='utf-8')
print('Moved only LiveTwin and five captions; saved shared layout and Desktop backup.')
