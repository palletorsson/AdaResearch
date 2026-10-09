"""Verify the recovery against its archived sources. Run from the repo root."""
from pathlib import Path
from collections import Counter
import json

ROOT = Path.cwd()
ARCHIVE = ROOT / 'doc/space/color-recovery-2026-09-09'

def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

report = read(ARCHIVE / 'recovery.json')
checks = 0

def check(value, message):
    global checks
    checks += 1
    assert value, message

def token(raw):
    return str(raw).split(':')[0].split('#')[0].strip()

for rec in report['rooms']:
    name = rec['map']
    relative = Path('commons/maps') / name / 'map_data.json'
    old = read(ARCHIVE / 'historical' / name / 'map_data.json') if name in report['color_maps'] else read(ARCHIVE / 'before' / relative)
    new = read(ROOT / relative)
    for layer in ['structure', 'utilities']:
        check(all(new['layers'][layer][z+4][x+4] == value
                  for z, row in enumerate(old['layers'].get(layer, []))
                  for x, value in enumerate(row)), name + ': preserved ' + layer)
    changed = {c['token'] for c in rec['changes']}
    additions = report.get('current_workspace_additions', {}).get(name, [])
    addition_cells = {tuple(a['at']) for a in additions}
    authored_targets = {tuple(c['to']) for c in rec['changes']}
    check(all(token(value) in changed or ((x+4, z+4) in addition_cells | authored_targets and not token(value)) or new['layers']['interactables'][z+4][x+4] == value
              for z, row in enumerate(old['layers']['interactables'])
              for x, value in enumerate(row)), name + ': untouched artifact placements')
    before = Counter(token(v) for row in old['layers']['interactables'] for v in row if token(v) not in ['', '0'])
    after = Counter(token(v) for row in new['layers']['interactables'] for v in row if token(v) not in ['', '0'])
    if name == 'Color_Flashlight':
        before['flashlight_demo'] += 1
    for addition in additions:
        before[addition['token']] += 1
    check(before == after, name + ': preserved artifact inventory')
    for a, b in zip(old.get('modifiers', []), new.get('modifiers', [])):
        check([[c[0]+4, c[1]+4] for c in a.get('target', {}).get('cells', [])] == b.get('target', {}).get('cells', []), name + ': translated modifier cells')
    for a, b in zip(old.get('paint_layers', []), new.get('paint_layers', [])):
        check([[c[0]+4, c[1]+4, *c[2:]] for c in a.get('brush', {}).get('cells', [])] == b.get('brush', {}).get('cells', []), name + ': translated brush cells')
    width = new['map_info']['dimensions']['width']
    depth = new['map_info']['dimensions']['depth']
    check(all(len(rows) == depth and all(len(row) == width for row in rows) for rows in new['layers'].values()), name + ': rectangular layers')
    check(all(new['layers']['structure'][z][x] == '1' for z in [0, depth-1] for x in range(width//2-1, width//2+2)), name + ': entrance and exit')

for chapter, maps in [('color', report['color_maps']), ('tiling', report['pattern_maps'])]:
    seq = read(ROOT / 'commons/maps/sequences' / (chapter + '.json'))['sequences'][chapter]
    check(seq['maps'] == maps, chapter + ': membership')
    book = read(ROOT / 'commons/data/book' / (chapter + '.json'))
    check([p['map'] for p in book['pearls']] == maps, chapter + ': book membership')
    for plan in ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']:
        rows = read(ROOT / plan)['plans']
        actual = [r.get('map') for r in rows if r.get('sequence') == chapter]
        check(actual == maps, chapter + ': plan membership in ' + plan)

check(not set(report['color_maps']) & set(report['pattern_maps']), 'chapters are disjoint')
print(f'{checks} recovery invariants passed.')
