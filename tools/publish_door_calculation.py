"""Publish only the tested door installation, preserving current editor work."""
import copy
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-23-door-calculation'
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
    fresh = request()
    original = copy.deepcopy(fresh['rooms'])
    before = json.loads((OUT / 'before-floor.json').read_text(encoding='utf8'))
    draft = json.loads((OUT / 'draft-rooms.json').read_text(encoding='utf8'))
    baseline = next(a for a in before['artifacts'] if a['id'] == 'doors')
    target = next(a for a in draft['floors'][72]['artifacts'] if a['id'] == 'doors')
    doors = next(a for a in fresh['rooms']['floors'][72]['artifacts'] if a['id'] == 'doors')
    assert doors in [baseline, target], 'Door placement changed during testing; reconcile it before publishing.'
    doors.update(copy.deepcopy(target))
    # Prove the merge contains only the tested artifact change.
    check = copy.deepcopy(fresh['rooms'])
    index = next(i for i, a in enumerate(check['floors'][72]['artifacts']) if a['id'] == 'doors')
    check['floors'][72]['artifacts'][index] = original['floors'][72]['artifacts'][index]
    assert check == original
    (OUT / 'before-publish.json').write_text(json.dumps(original, indent=2) + '\n', encoding='utf8')
    receipt = request({'rooms': fresh['rooms'], 'revision': fresh['revision']})
    (OUT / 'publish.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf8')
    print(json.dumps({k: v for k, v in receipt.items() if k not in ['warnings', 'rooms']}, indent=2))
