"""Read-only inventory for the Void's first-map trials. No automatic placement.

Opening maps come from the current curriculum and sequence files, not a cached
artifact order. The authored briefs choose a focus; this audit never invents it.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]


def read(relative):
    return json.loads((ROOT / relative).read_text(encoding='utf-8-sig'))


def digest(relative):
    p = ROOT / relative
    return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None


def inventory():
    brief = read('commons/void/trials/briefs.json')
    authored = {r['sequence']: r for r in brief['trials']}
    registry = {}
    for path in sorted((ROOT / 'commons/artifacts/registry').glob('*.json')):
        registry.update(read(path.relative_to(ROOT)).get('artifacts', {}))
    floors = read('commons/void/rooms.json')['floors']
    frame = read('commons/void/layout.json')
    spine = read('commons/maps/curriculum_spine.json')['spine']['sequences']
    rows = []
    for s in sorted(spine, key=lambda s: s['order']):
        name = s['name']
        seq_path = f'commons/maps/sequences/{name}.json'
        seq = read(seq_path)['sequences'][name]
        first = seq['maps'][0]
        # Do not silently carry a brief to a different opening after a reorder.
        row = dict(authored.get(name, {'sequence': name, 'map': first, 'title': name}))
        row.update(order=s['order'], actual_map=first, sequence_title=seq['name'],
                   maps_in_sequence=len(seq['maps']))
        warnings = []
        if row['map'] != first:
            warnings.append('Opening changed: review the brief before building. It still describes ' + row['map'])
        if name not in authored:
            warnings.append('This sequence needs an authored trial brief.')
        map_path = f'commons/maps/{first}/map_data.json'
        data = read(map_path)
        variants = Counter()
        for line in data.get('layers', {}).get('interactables', []):
            for cell in line:
                token = str(cell).strip()
                if token and token not in {'0', '-1', 'None'}:
                    variants[token] += 1
        items = []
        for token, count in variants.items():
            key = token.split('#')[0].split(':')[0]
            entry = registry.get(key, {})
            scene = entry.get('scene', '')
            exists = bool(scene) and (ROOT / scene.removeprefix('res://')).is_file()
            items.append(dict(key=key, token=token, count=count, scene=scene, exists=exists))
            if not exists:
                warnings.append('Unresolved artifact scene: ' + key)
        placed_keys = {i['key'] for i in items}
        for key in row.get('primary', []):
            if key not in placed_keys:
                warnings.append('Proposed primary is not a direct source-map placement: ' + key)
        paths = [seq_path, map_path, f'commons/maps/{first}/tutorial.md', f'commons/maps/{first}/final.md']
        sources = {p: digest(p) for p in paths}
        for path, sha in sources.items():
            if sha is None:
                warnings.append('Missing source: ' + path)
        row['sources'] = sources
        row['fingerprint'] = hashlib.sha256(json.dumps({'sources': sources, 'brief': authored.get(name),
            'scenes': {i['scene']: digest(i['scene'].removeprefix('res://')) for i in items if i['exists']}}, sort_keys=True).encode()).hexdigest()
        row['artifacts'] = items
        row['source_dimensions'] = data.get('map_info', {}).get('dimensions', {})
        row['playable'] = read('commons/void/trials/playable.json')['trials'].get(name)
        row['existing_floors'] = [i for i, f in enumerate(floors) if f.get('map') == first]
        row['warnings'] = list(dict.fromkeys(warnings))
        rows.append(row)
    return dict(version=1, purpose=brief['purpose'], rules=brief['rules'], capabilities=brief['capabilities'],
        trials=rows, frame={k: frame[k] for k in ['width', 'depth', 'storey_height', 'shaft_width', 'shaft_depth']},
        existing_floor_count=len(floors), source='commons/maps/curriculum_spine.json',
        notice='Source inventory only. File existence does not verify loading, interaction, performance or headset use.')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    result = inventory()
    if '--check' in sys.argv:
        problems = [f"{r['sequence']}: {w}" for r in result['trials'] for w in r['warnings']]
        capabilities = {c['id'] for c in result['capabilities']}
        for row in result['trials']:
            for key in row.get('capabilities', []):
                if key not in capabilities:
                    problems.append(f"{row['sequence']}: unknown capacity {key}")
        for c in result['capabilities']:
            for p in c['sources']:
                if digest(p) is None:
                    problems.append('Missing capacity source: ' + p)
        print(json.dumps({'trials': len(result['trials']), 'artifact_placements': sum(i['count'] for r in result['trials'] for i in r['artifacts']), 'problems': problems}, indent=2))
        sys.exit(1 if problems else 0)
    print(json.dumps(result, ensure_ascii=False))
