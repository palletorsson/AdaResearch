"""Record the six halls' authored placements and source eligibility, not runtime admission."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
seq = read(ROOT / 'commons/maps/sequences/formfinding.json')['sequences']['formfinding']
roles = read(ROOT / 'commons/data/artifact_roles.json')
registry = {}
for p in sorted((ROOT / 'commons/artifacts/registry').glob('*.json')):
    data = read(p)
    for key, value in data.get('artifacts', {}).items():
        registry.setdefault(key, []).append((p, value))
records = {}
for name in seq['maps']:
    data = read(ROOT / f'commons/maps/{name}/map_data.json')
    items = []
    for z, row in enumerate(data['layers']['interactables']):
        for x, raw in enumerate(row):
            if str(raw) in ('', '0', 'None'): continue
            key = re.split('[:#]', str(raw))[0]
            entry = {'key': key, 'cell': [x, z], 'token': raw,
                     'role': roles['roles'].get(name, {}).get(key), 'sources': []}
            for path, value in registry.get(key, []):
                scene = value.get('scene', '')
                target = ROOT / scene.removeprefix('res://')
                source = {'registry': path.relative_to(ROOT).as_posix(), 'scene': scene,
                          'map_ready': value.get('map_ready'), 'include_in_map_data': value.get('include_in_map_data'),
                          'scene_exists': bool(scene) and target.is_file()}
                if source['scene_exists']:
                    source['scripts'] = re.findall(r'path="(res://[^"]+\.gd)"', target.read_text(encoding='utf-8'))
                    source['script_hashes'] = {s: digest(ROOT / s[6:]) for s in source['scripts'] if (ROOT / s[6:]).exists()}
                entry['sources'].append(source)
            items.append(entry)
    records[name] = {'order': roles['order'].get(name), 'placements': items}
previous = read(ROOT / 'doc/space/descent-landscape-2026-09-12/source-fingerprints.json')
historical = {p: {'recorded': h, 'current': digest(ROOT / p), 'unchanged': digest(ROOT / p) == h}
              for p, h in previous.items() if (ROOT / p).is_file()}
(HERE / 'source-chain.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
(HERE / 'descent-historical-evidence.json').write_text(json.dumps(historical, indent=2), encoding='utf-8')
for name, value in records.items():
    missing = [x['key'] for x in value['placements'] if not any(s['scene_exists'] and s['map_ready'] for s in x['sources'])]
    print(name, len(value['placements']), 'placements; unresolved/ineligible:', missing)
print('Descent historical hashes:', {p: v['unchanged'] for p,v in historical.items()})
