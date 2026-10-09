"""Append one walk-in oval bay; preserve every existing Fields placement."""
from pathlib import Path
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-07-gravity-oval'
MAP = 'Vectors_Act3_FieldsAndMotion'

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p, d):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
def backup(p):
    target = OUT / 'before' / p.relative_to(ROOT)
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, target)

def main():
    registry = ROOT / 'commons/artifacts/registry/force_play.json'
    backup(registry)
    data = read(registry)
    data['artifacts']['gravity_oval'] = dict(lookup_name='gravity_oval', name='Gravity oval', scene='res://commons/artifacts/gravity_oval/gravity_oval.tscn', category='vectors_forces', map_ready=True, include_in_map_data=True, map_sequences=['forces'], footprint=[14, 13, 16], parameters={'footprint': [14, 13, 16], 'size_group': 'large'}, description='A walk-in artificial field carries 24 familiar prefab bodies up the left column, over the top and down the right in a repeating vertical oval. Step into the stream to travel with them; walk sideways to leave. Real contacts, hand pickup, finite bodies and local reset. The field supplies energy; the tracked head stays upright.')
    write(registry, data)
    path = ROOT / 'commons/artifacts/force_halls/curation.json'
    backup(path)
    plan = read(path)
    hall = next(h for h in plan['halls'] if h['map'] == MAP)
    if not any(p['token'] == 'gravity_oval' for p in hall['placements']):
        hall['placements'].append(dict(token='gravity_oval', cell=[14, 92], zone=[14, 16], config='', y=0, pedestal=False, rotation=0, role='comparison'))
    hall['size'] = [28, 104]
    hall['walk'] = [[14.5, 3.5], [25.5, 3.5], [25.5, 99.5]]
    hall['after_count'] = len(hall['placements'])
    mp = ROOT / f'commons/maps/{MAP}/map_data.json'
    backup(mp)
    data = read(mp)
    w, depth = hall['size']
    old = len(data['layers']['structure'])
    for layer in data['layers'].values(): layer.extend([[''] * w for _ in range(depth - len(layer))])
    if old < depth:
        for z in range(old - 1, depth):
            for x in range(w):
                wall = x in [0, w-1] or (z == depth-1 and abs(x-w//2) > 2)
                data['layers']['structure'][z][x] = 'w' if wall else '1'
    for row in data['layers']['utilities']:
        for x, v in enumerate(row):
            if v == 't': row[x] = ''
    data['layers']['utilities'][depth-4][w-3] = 't'
    data['layers']['interactables'][92][14] = 'gravity_oval#pin:1#plinth:0'
    data['map_info']['dimensions'] = {'width': w, 'depth': depth, 'max_height': 13}
    data['map_info']['museum'].update(open_roof=True, sculpture_clear_rects=[[0, 0, w-1, depth-1]])
    data['map_info']['metadata']['n_artifacts'] = len(hall['placements'])
    data['documentation']['supporting_artifacts'] = [p['token'] for p in hall['placements'] if p['role'] != 'tutorial']
    write(mp, data)
    write(path, plan)
    from em_map_halls import derive_row
    # Update the relevant row in both plans without copying unrelated live edits.
    for pp in [ROOT/'commons/data/museum/em_plan.json', ROOT/'commons/data/museum/em_plan.json']:
        backup(pp)
        museum = read(pp)
        for i, row in enumerate(museum['plans']):
            if row.get('sequence') == 'forces' and row.get('map') == MAP:
                museum['plans'][i] = derive_row(row['pearl'], MAP, row['museum'], hall['number']-1, len(plan['halls']), 'forces')
        write(pp, museum)
    print('Gravity oval appended to Fields; five artifacts, existing anchors and eleven-hall order retained.')

if __name__ == '__main__': main()
