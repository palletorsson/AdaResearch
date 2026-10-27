"""Read-only coordinator snapshot. Passing receipts are not reviewer acceptance."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
BATCH = Path(__file__).resolve().parent


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def inspect(job):
    folder = ROOT / job['folder']
    inventory = read(folder / 'source-inventory.json')
    rooms = read(folder / 'rooms.json')
    layout = read(folder / 'layout.json')
    items = [(level, item) for level, floor in enumerate(rooms['floors'])
             for item in floor.get('artifacts', [])]
    problems = []
    expected_ids = {p['id'] for p in inventory['placements']}
    for p in inventory['placements']:
        matches = [(level, item) for level, item in items if item['id'] == p['id']]
        if len(matches) != 1:
            problems.append(f"{p['id']}: expected once, found {len(matches)}")
            continue
        level, item = matches[0]
        if level != p['floor'] or rooms['floors'][level]['map'] != p['map']:
            problems.append(f"{p['id']}: source floor/map differs")
        if item['artifact'] != p['artifact']:
            problems.append(f"{p['id']}: artifact identity differs")
        parts = p['token'].split('#')[0].split(':')
        for field, index, default in [('height', 2, 0), ('scale', 3, 1)]:
            # Match the museum parser's numeric-only overrides. Malformed
            # tutorial tokens may put a text ID in the height slot; source
            # defaults remain in effect rather than inventing a new transform.
            try:
                expected = float(parts[index] or default) if len(parts) > index else default
            except ValueError:
                expected = default
            if abs(float(item.get(field, default)) - expected) > 1e-6:
                problems.append(f"{p['id']}: {field} source={expected}, placed={item.get(field)}")
    for _, item in items:
        if item['id'] not in expected_ids:
            problems.append(f"Uninventoried addition: {item['id']}")
    for name, value in [('width', 42), ('depth', 32), ('storey_height', 6),
                        ('shaft_width', 5), ('shaft_depth', 6)]:
        if layout.get(name) != value:
            problems.append(f'Nonstandard layout: {name}')
    for path, expected in inventory['preserved_sources'].items():
        if digest(ROOT / path) != expected:
            problems.append('Source changed: ' + path)
    receipts = {}
    for name in ['source-checks', 'checks', 'editor-checks']:
        path = folder / 'evidence' / (name + '.json')
        if path.is_file():
            receipt = read(path)
            receipts[name] = {
                'passed': receipt.get('passed', False),
                'checks': len(receipt.get('checks', [])),
                'acceptance': receipt.get('acceptance'),
                'errors': receipt.get('engine_errors', []),
            }
        else:
            receipts[name] = {'state': 'pending'}
    manifest = ROOT.parent / 'ada_encyclopedia/public/void-trials' / job['sequence'] / 'manifest.json'
    export = {'state': 'pending'}
    if manifest.is_file():
        model = read(manifest)
        stale = [p for p, h in model.get('source_files', {}).items() if digest(ROOT / p) != h]
        export = {'failures': model.get('failures'), 'stale_sources': stale,
                  'has_source_fingerprints': bool(model.get('source_files'))}
    return {'trial': job['sequence'], 'placed': len(items), 'expected': len(expected_ids),
            'source_scale_height_layout_problems': problems,
            'receipts': receipts, 'export': export, 'reviewer_acceptance': 'pending'}


if __name__ == '__main__':
    result = [inspect(job) for job in read(BATCH / 'batch.json')['jobs']]
    print(json.dumps(result, indent=2))
