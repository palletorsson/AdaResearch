"""Prepare or publish only the agreed first Wavefunctions comparison bay."""
import copy
import json
import sys
import urllib.request
import urllib.error
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/wavefunctions-shared-bay'
URL = 'http://localhost:3003/api/void-layout'
OUT.mkdir(exist_ok=True)

def post(data):
    request = urllib.request.Request(URL, json.dumps(data).encode(),
                                     {'Content-Type': 'application/json'}, method='POST')
    try:
        return json.load(urllib.request.urlopen(request, timeout=90))
    except urllib.error.HTTPError as error:
        raise RuntimeError(error.read().decode()) from error

def prepare():
    current = json.load(urllib.request.urlopen(URL, timeout=30))
    assert not (OUT / 'before-rooms.json').exists(), 'Preserve the current draft and edits.'
    rooms = copy.deepcopy(current['rooms'])
    floor = rooms['floors'][59]
    assert floor['map'] == 'WaveFunctions_Intro'
    assert not any(p['id'].startswith('return-bay-') for p in floor['props'])
    clock = next(a for a in floor['artifacts'] if a['id'] == 'clock')
    assert clock['artifact'] == 'y_oscillation_cube' and clock['height'] == 1.3
    clock['height'] = 1.45
    for identifier, kind, at, facing, scale in [
        ('backdrop', 'scaffold_tarp', [-2.0, .5], 0, 1),
        ('side', 'unfinished_wall', [-5.5, 2.3], 90, 1),
        ('low-edge', 'steel_barrier', [2.2, 3], 90, 1),
        ('store', 'crate', [-5.55, 6.1], 0, .5),
        ('stock', 'timber_plank_2m', [-4.75, 6.5], 90, 1),
        ('lamp', 'work_light', [2.25, 6.8], 0, 1),
    ]:
        floor['props'].append(dict(id='return-bay-' + identifier, kind=kind,
                                   position=at, facing=facing, scale=scale))
    result = post(dict(rooms=rooms, validateOnly=True))
    assert result['valid'], result
    for filename, value in [('before-rooms', current['rooms']), ('draft-rooms', rooms),
                            ('base-revision', current['revision']), ('validation', result)]:
        (OUT / (filename + '.json')).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')
    print('Prepared six independent existing props and a 15 cm mount correction. No live layout changed.')

def publish():
    report = json.loads((OUT / 'checks.json').read_text(encoding='utf-8'))
    assert report['passed'], 'Inspect the native bay receipt before publishing.'
    assert report['draft_sha256'] == hashlib.sha256((OUT / 'draft-rooms.json').read_bytes()).hexdigest(), 'Draft changed after native review.'
    before = json.loads((OUT / 'before-rooms.json').read_text(encoding='utf-8'))
    draft = json.loads((OUT / 'draft-rooms.json').read_text(encoding='utf-8'))
    current = json.load(urllib.request.urlopen(URL, timeout=30))
    # Preserve concurrent work on other floors; refuse to overwrite this floor.
    assert current['rooms']['floors'][59] == before['floors'][59], 'Floor59 changed; merge by review.'
    rooms = copy.deepcopy(current['rooms'])
    rooms['floors'][59] = draft['floors'][59]
    (OUT / 'before-publish-rooms.json').write_text(json.dumps(current['rooms'], indent=2) + '\n', encoding='utf-8')
    receipt = post(dict(rooms=rooms, revision=current['revision']))
    saved = json.load(urllib.request.urlopen(URL, timeout=30))['rooms']
    assert saved == rooms
    (OUT / 'save-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    assert all(saved['floors'][i] == current['rooms']['floors'][i]
               for i in range(len(saved['floors'])) if i != 59)
    print('Saved only floor59 through the revisioned editor API; other floors preserved.')

if __name__ == '__main__':
    publish() if '--publish' in sys.argv else prepare()
