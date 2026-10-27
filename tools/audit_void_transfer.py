"""Verify source coverage and parameter preservation before native acceptance."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
sequence = sys.argv[1]
folder = ROOT / 'commons/void/trials' / sequence
inventory = json.loads((folder / 'source-inventory.json').read_text(encoding='utf-8-sig'))
rooms = json.loads((folder / 'rooms.json').read_text(encoding='utf-8-sig'))
catalog = json.loads((ROOT / 'commons/void/catalog.json').read_text(encoding='utf-8-sig'))['artifacts']
checks = []

def check(name, passed, detail=''):
    checks.append(dict(name=name, passed=bool(passed), detail=detail))

flat = [(i, a) for i, f in enumerate(rooms['floors']) for a in f.get('artifacts', [])]
ids = [a['id'] for _, a in flat]
check('No duplicate placement identities', len(ids) == len(set(ids)))
for p in inventory['placements']:
    found = [(i, a) for i, a in flat if a['id'] == p['id']]
    check(p['id'] + ': present exactly once', len(found) == 1)
    if len(found) != 1:
        continue
    level, item = found[0]
    check(p['id'] + ': source floor retained', level == p['floor'] and rooms['floors'][level]['map'] == p['map'])
    parsed = {}
    for fragment in p['token'].split('#')[1:]:
        key, _, value = fragment.partition(':')
        parsed[key] = value or 'true'
    errors = {key: {'source': value, 'placed': item.get('config', {}).get(key)} for key, value in parsed.items() if str(item.get('config', {}).get(key)).lower() != value.lower()}
    check(p['id'] + ': original config retained', not errors, json.dumps(errors) if errors else '')
    if p.get('source_layer') == 'utilities' and 'utility_params' in item.get('config', {}):
        check(p['id'] + ': original utility parameters retained', item['config']['utility_params'] == p['token'].split('#')[0].partition(':')[2])
    scene = catalog.get(item['artifact'], {}).get('scene', '')
    check(p['id'] + ': registered real scene exists', bool(scene) and (ROOT / scene.removeprefix('res://')).is_file(), scene)
check('All original placements covered', len(flat) == len(inventory['placements']))
for source, digest in inventory['preserved_sources'].items():
    path = ROOT / source
    check(source + ': unchanged', path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
result = {'passed': all(c['passed'] for c in checks), 'checks': checks}
(folder / 'evidence').mkdir(exist_ok=True)
(folder / 'evidence/source-checks.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
for failure in (c for c in checks if not c['passed']):
    print('FAIL:', failure['name'], failure['detail'])
print(sum(c['passed'] for c in checks), '/', len(checks), sequence, 'source checks passed')
raise SystemExit(0 if result['passed'] else 1)
