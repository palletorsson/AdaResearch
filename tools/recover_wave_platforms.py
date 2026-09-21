"""Recover Wavefunctions' one-metre platforms without replacing its current maps.

Inspect by default; --apply archives both working maps and the pre-museum git
snapshot before changing data. Repeating --apply is a no-op. Only numeric 2 on
the actual structure rectangle's perimeter becomes 'w'; interior 2 stays a grid
stack of two cubes, with museum.wall_height=3 exposing its one-metre deck.
"""
from pathlib import Path
import argparse
import copy
from datetime import datetime, timezone
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HISTORICAL = 'a36f33c996004abcdc67ea2a0ac3fce72eba42fd'
OUT = ROOT / 'doc/space/wave-platform-recovery-2026-09-10'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def encode_map(doc):
    text = json.dumps(doc, indent=1, ensure_ascii=False)
    # Preserve the project's compact one-line scalar array convention.
    text = re.sub(r'\[\n\s*([^\[\]]*?)\n\s*\]',
                  lambda m: '[ ' + re.sub(r'\s*\n\s*', ' ', m[1]).strip() + ' ]', text)
    return (text + '\n').encode('utf-8')


def repaired(doc):
    result = copy.deepcopy(doc)
    s = result['layers']['structure']
    width, depth = max(map(len, s)), len(s)
    interior, perimeter = [], []
    for z, row in enumerate(s):
        for x, value in enumerate(row):
            if str(value).strip() != '2':
                continue
            if x in (0, width - 1) or z in (0, depth - 1):
                perimeter.append([x, z])
                row[x] = 'w'
            else:
                interior.append([x, z])
    result['map_info'].setdefault('museum', {})['wall_height'] = 3
    result['map_info']['museum']['gate_depth_rows'] = 0
    return result, interior, perimeter


def refresh_active_plans(active):
    """Refresh geometry/support only, retaining six-hall route and curation.

    Do not normalize again: normalization can add piers, cut paths and move
    anchors. The existing active maps already fit their halls.
    """
    import em_map_halls
    for rel in ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']:
        path = ROOT / rel
        plan = read(path)
        original = copy.deepcopy(plan)
        assert [r['map'] for r in plan['plans'] if r.get('sequence') == 'wavefunctions'] == active
        for row in plan['plans']:
            if row.get('sequence') != 'wavefunctions':
                continue
            fresh = em_map_halls.derive_row(row['pearl'], row['map'], row['museum'],
                    row['pearl_index'], row['pearls_total'], 'wavefunctions')
            assert list(map(len, fresh['tile'])) == list(map(len, row['tile'])), row['map']
            def key(a): return (a['token'], *a['tile_cell'])
            supports = {key(a): a['support_height_m'] for a in fresh['artifacts']}
            assert len(supports) == len(row['artifacts'])
            assert set(supports) == {key(a) for a in row['artifacts']}, row['map']
            row['tile'] = fresh['tile']
            row['interior_count'] = fresh['interior_count']
            row['gate_depth_rows'] = fresh['gate_depth_rows']
            for art in row['artifacts']:
                art['support_height_m'] = supports[key(art)]
        if plan != original:
            path.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    names = read(ROOT / 'commons/maps/sequences/wavefunctions.json')['sequences']['wavefunctions']['maps']
    active = read(ROOT / 'commons/data/map_authored.json')['wavefunctions']
    docs, report, before = {}, [], {}
    for name in names:
        rel = Path('commons/maps') / name / 'map_data.json'
        before[rel] = (ROOT / rel).read_bytes()
        old = json.loads(before[rel].decode('utf-8-sig'))
        new, inside, outside = repaired(old)
        assert repaired(new)[0] == new
        docs[rel] = new
        report.append({'map': name, 'active': name in active,
                       'interior_platform_cells': inside, 'perimeter_2_to_w': outside,
                       'before_sha256': hashlib.sha256(before[rel]).hexdigest(),
                       'changed': old != new})
    changed = {p: encode_map(d) for p, d in docs.items()
               if d != json.loads(before[p].decode('utf-8-sig'))}
    if args.apply and changed:
        if (OUT / 'recovery.json').exists():
            raise RuntimeError('Recovery archive exists but sources changed; inspect before making a new recovery.')
        # Collect every historical file before writing any current map.
        history = {p: subprocess.check_output(['git', '-c', 'safe.directory=' + ROOT.as_posix(),
                   'show', f'{HISTORICAL}:{p.as_posix()}'], cwd=ROOT) for p in docs}
        extra = [Path(p) for p in ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json',
                  'commons/data/map_authored.json', 'commons/data/museum_order_effective.json',
                  'tools/em_map_halls.py', 'commons/scenes/endless_museum.gd',
                  'doc/research/waves-chance-noise/audit.json',
                  'doc/research/waves-chance-noise/verification.json']]
        for rel in extra:
            before[rel] = (ROOT / rel).read_bytes()
        for folder, files in [('before', before), ('pre-museum', history)]:
            for rel, data in files.items():
                dest = OUT / folder / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
        for rel, data in before.items():
            if (ROOT / rel).read_bytes() != data:
                raise RuntimeError(f'Concurrent edit: {rel}')
        for rel, data in changed.items():
            temp = (ROOT / rel).with_suffix('.recovery.tmp')
            temp.write_bytes(data)
            temp.replace(ROOT / rel)
        result = {'at': datetime.now(timezone.utc).isoformat(), 'historical_commit': HISTORICAL,
                  'boundary': 'Outermost row/column of the actual structure array, without shifting cells.',
                  'maps': report, 'active_route': active,
                  'interior_platform_count': sum(len(r['interior_platform_cells']) for r in report),
                  'perimeter_wall_count': sum(len(r['perimeter_2_to_w']) for r in report),
                  'preserved': 'All non-perimeter structure values, other layers, artifacts, dimensions and texts.'}
        (OUT / 'recovery.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    if args.apply:
        refresh_active_plans(active)
    print(json.dumps({'apply': args.apply, 'changed_maps': len(changed),
                      'platforms': sum(len(r['interior_platform_cells']) for r in report),
                      'perimeter_walls': sum(len(r['perimeter_2_to_w']) for r in report)}))


if __name__ == '__main__':
    main()
