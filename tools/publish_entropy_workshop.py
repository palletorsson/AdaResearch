"""Merge the tested floor-73 fittings and partitions into the current editor layout."""
import copy
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-23-entropy-workshop'
URL = 'http://localhost:3003/api/void-layout'


def request(data=None):
    req = urllib.request.Request(
        URL, data=None if data is None else json.dumps(data).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=90) as response:
        return json.load(response)


if __name__ == '__main__':
    checks = json.loads((OUT / 'native/checks.json').read_text(encoding='utf8'))
    assert checks['passed'] and any(c['name'].startswith('XR:') for c in checks['checks'])
    log = (OUT / 'native/native.log').read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    frame = json.loads((ROOT/'commons/void/layout.json').read_text(encoding='utf8'))
    assert frame['floor_sign_positions']['73'] == [0, -7.8]
    fresh = request()
    original = copy.deepcopy(fresh['rooms'])
    before = json.loads((OUT / 'before-floor.json').read_text(encoding='utf8'))
    target = json.loads((OUT / 'draft-rooms.json').read_text(encoding='utf8'))['floors'][73]
    floor = fresh['rooms']['floors'][73]
    for wanted in target['artifacts']:
        baseline = next(a for a in before['artifacts'] if a['id'] == wanted['id'])
        current = next(a for a in floor['artifacts'] if a['id'] == wanted['id'])
        assert current in [baseline, wanted], f"Reconcile new editor changes to {current['id']} before publishing."
        if wanted != baseline:
            current.setdefault('config', {})['entropy_workshop_hardware'] = True
    for category in ['walls', 'props']:
        for wanted in target[category]:
            if wanted in before[category]:
                continue
            current = next((a for a in floor[category] if a['id'] == wanted['id']), None)
            assert current in [None, wanted], f"Conflicting new {category} record"
            if current is None:
                floor[category].append(copy.deepcopy(wanted))
    check = copy.deepcopy(fresh['rooms'])
    check['floors'][73] = original['floors'][73]
    assert check == original, 'Only floor 73 may change.'
    (OUT / 'before-publish.json').write_text(json.dumps(original, indent=2)+'\n', encoding='utf8')
    receipt = request({'rooms': fresh['rooms'], 'revision': fresh['revision']})
    (OUT / 'publish.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf8')
    print(json.dumps({k: v for k, v in receipt.items() if k not in ['warnings', 'rooms']}, indent=2))


