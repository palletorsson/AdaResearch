"""Audit/recover interior 2 platforms in Randomness, Noise and Cellular Automata.

No engine-wide reinterpretation: use the existing per-map wall threshold.
--apply archives working sources and two historical snapshots, then patches
only affected maps and matching active plan geometry/support. --check verifies
the persistent geometry contract while allowing subsequent encounter edits.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import copy
import hashlib
import json
import subprocess
import tempfile

import em_map_halls
from recover_wave_platforms import encode_map
from map_pathfinder import MapGraph

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/space/sequence-platform-recovery-2026-09-10'
SEQUENCES = ['randomness', 'noise', 'cellularautomata']
REFS = {'pre-museum': 'a36f33c996004abcdc67ea2a0ac3fce72eba42fd',
        'pre-rewrite': '4d8dc7c7cbea69bc189b259b5c998a44b4a13e46'}
PLAN_PATHS = ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']
SPAWN_REPAIRS = {'Random_Mushrooms', 'Randomness_Examples_of_Randomness'}


def repair_access(doc):
    """Three source-verified exceptions: a wall cannot remain an arrival path."""
    name = doc['map_info'].get('lookup_name')
    if name in SPAWN_REPAIRS:
        u = doc['layers']['utilities']
        if str(u[0][0]).strip() == 's':
            assert str(u[1][1]).strip() == '', name
            assert str(doc['layers']['structure'][1][1]).strip() == '1', name
            u[0][0], u[1][1] = ' ', 's'
    if name == 'Noise_Inside_Noise':
        # The exit at (7,12) was approached over border (6,12). A landing
        # immediately inside it retains access with the border now a wall.
        row = doc['layers']['structure'][11]
        if str(row[7]).strip() == '0':
            assert str(row[6]).strip() == '2'
            assert str(doc['layers']['utilities'][12][7]).strip() == 't'
            row[7] = '2'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(data):
    return hashlib.sha256(data).hexdigest()


def fix(doc):
    new = copy.deepcopy(doc)
    repair_access(new)
    rows = new['layers']['structure']
    w, h = max(map(len, rows)), len(rows)
    assert all(len(row) == w for row in rows), 'Ragged structure needs manual inspection'
    inside, edge = [], []
    for z, row in enumerate(rows):
        for x, v in enumerate(row):
            if str(v).strip() != '2':
                continue
            if x in (0, w - 1) or z in (0, h - 1):
                edge.append([x, z])
                row[x] = 'w'
            else:
                inside.append([x, z])
    if inside or edge:
        museum = new['map_info'].setdefault('museum', {})
        museum['wall_height'] = max(3, int(museum.get('wall_height', 2)))
        if inside:
            assert int(new['map_info']['dimensions'].get('max_height', 6)) >= 2
            # Keep the sliding gate's depth out of recovered interior decks.
            museum.setdefault('gate_depth_rows', 0)
    return new, inside, edge


def derive(doc, name, seq, row=None):
    """Run the existing deriver on a candidate without editing a live map."""
    row = row or {'pearl': name, 'museum': 'check', 'pearl_index': 0, 'pearls_total': 1}
    original = em_map_halls.ROOT
    with tempfile.TemporaryDirectory(prefix='platform-derive-', dir=ROOT / 'ada_run') as tmp:
        base = Path(tmp).resolve()
        assert base.is_relative_to((ROOT / 'ada_run').resolve())
        p = base / 'commons/maps' / name / 'map_data.json'
        p.parent.mkdir(parents=True)
        p.write_bytes(encode_map(doc))
        try:
            em_map_halls.ROOT = base
            return em_map_halls.derive_row(row['pearl'], name, row['museum'],
                                          row['pearl_index'], row['pearls_total'], seq)
        finally:
            em_map_halls.ROOT = original


def untouched_parts(doc):
    other = copy.deepcopy(doc)
    if other['map_info'].get('lookup_name') in SPAWN_REPAIRS:
        u = other['layers']['utilities']
        if str(u[0][0]).strip() == '' and str(u[1][1]).strip() == 's':
            u[0][0], u[1][1] = 's', ''
        if str(u[1][1]).strip() == '':
            u[1][1] = ''  # Both empty spellings are valid in the vacated cell.
    other['layers'].pop('structure')
    museum = other['map_info'].get('museum', {})
    museum.pop('wall_height', None)
    museum.pop('gate_depth_rows', None)
    if not museum:
        other['map_info'].pop('museum', None)
    return other


def fixture_checks():
    sample = {'map_info': {'dimensions': {'max_height': 5}}, 'layers': {
        'structure': [['2','w','3','2'], ['1','2','4','1'], ['1','0','p','1']],
        'interactables': [['example']], 'utilities': [['spawn']]}}
    new, inside, edge = fix(sample)
    assert inside == [[1, 1]] and edge == [[0, 0], [3, 0]]
    assert new['layers']['structure'][0] == ['w','w','3','w']
    assert new['layers']['structure'][1] == ['1','2','4','1']
    assert new['layers']['structure'][2] == sample['layers']['structure'][2]
    assert untouched_parts(new) == untouched_parts(sample)
    assert fix(new)[0] == new
    high = copy.deepcopy(sample)
    high['map_info']['museum'] = {'wall_height': 5, 'gate_depth_rows': 2, 'open_roof': True}
    assert fix(high)[0]['map_info']['museum'] == high['map_info']['museum']
    no_two = copy.deepcopy(sample)
    no_two['layers']['structure'] = [['w','1'], ['0','3']]
    assert fix(no_two)[0] == no_two


def check_current():
    report = read(OUT / 'recovery.json')
    checked = 0
    for entry in report['maps']:
        if not entry['changed']:
            continue
        name, seq = entry['map'], entry['sequence']
        rel = Path('commons/maps') / name / 'map_data.json'
        expected = fix(read(OUT / 'before' / rel))[0]
        actual = read(ROOT / rel)
        assert actual['layers']['structure'] == expected['layers']['structure'], name
        assert actual['map_info']['dimensions'] == expected['map_info']['dimensions'], name
        assert int(actual['map_info']['museum']['wall_height']) >= 3, name
        if entry['interior_platform_cells']:
            assert actual['map_info']['museum'].get('gate_depth_rows') == 0, name
        row = derive(actual, name, seq)
        old_graph = MapGraph(read(OUT / 'before' / rel))
        new_graph = MapGraph(actual)
        old_walk, new_walk = old_graph.bfs_flood(), new_graph.bfs_flood()
        lost_inside = [(x,z) for z,x in old_walk - new_walk
                       if x not in (0,new_graph.cols-1) and z not in (0,new_graph.rows-1)]
        assert not lost_inside, (name, 'previously reachable interior lost', lost_inside)
        for exit_cell in old_graph.teleports:
            if old_graph.bfs_path(exit_cell) is not None:
                assert new_graph.bfs_path(exit_cell) is not None, (name, exit_cell)
        for x, z in entry['interior_platform_cells']:
            assert row['tile'][z][x] == '1', (name, x, z)
            checked += 1
        for x, z in entry['perimeter_2_to_w']:
            assert row['tile'][z][x] == '4', (name, x, z)
            checked += 1
    for seq, names in report['active_routes'].items():
        assert read(ROOT / 'commons/data/map_authored.json')[seq] == names
    result = {'mode': 'persistent geometry contract', 'checked_cells': checked,
              'maps': report['summary']['changed_maps'], 'route': 'unchanged',
              'runtime': 'not run; see the separate runtime probe',
              'later_encounter_edits': 'allowed; maps and plans are not regenerated by this check'}
    result['access'] = 'All previously reachable interior cells and teleporters retained'
    (ROOT / 'ada_run/sequence_platform_checks.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--repair-access', action='store_true', help='Apply the three documented arrival/exit exceptions after initial recovery.')
    args = parser.parse_args()
    fixture_checks()
    if args.repair_access:
        report = read(OUT / 'recovery.json')
        repairs = []
        for name in [*sorted(SPAWN_REPAIRS), 'Noise_Inside_Noise']:
            rel = Path('commons/maps') / name / 'map_data.json'
            current = read(ROOT / rel)
            new = copy.deepcopy(current)
            repair_access(new)
            if current != new:
                p = ROOT / rel
                tmp = p.with_suffix('.platform-access.tmp')
                tmp.write_bytes(encode_map(new))
                assert read(p) == current, 'Concurrent edit: ' + name
                tmp.replace(p)
            repairs.append({'map': name, 'change': 'spawn (0,0) -> existing floor (1,1)' if name in SPAWN_REPAIRS else 'add height-2 landing at (7,11) before unchanged exit (7,12)'})
        entry = next(e for e in report['maps'] if e['map'] == 'Noise_Inside_Noise')
        if [7,11] not in entry['interior_platform_cells']:
            entry['interior_platform_cells'].append([7,11])
        report['access_repairs'] = repairs
        report['summary']['additional_exit_landings'] = 1
        report['preservation'] = 'Artifact layers/configurations, dimensions, route/role/order sources and unselected plan rows preserved. Two spawn tokens moved onto existing floor and one interior exit landing added after before/after reachability exposed blocked routes.'
        (OUT / 'recovery.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        check_current()
        return
    if args.check:
        check_current()
        return
    active = read(ROOT / 'commons/data/map_authored.json')
    before, docs, entries, derived = {}, {}, [], {}
    for seq in SEQUENCES:
        path = Path('commons/maps/sequences') / (seq + '.json')
        before[path] = (ROOT / path).read_bytes()
        for name in read(ROOT / path)['sequences'][seq]['maps']:
            rel = Path('commons/maps') / name / 'map_data.json'
            before[rel] = (ROOT / rel).read_bytes()
            old = read(ROOT / rel)
            new, inside, edge = fix(old)
            assert untouched_parts(old) == untouched_parts(new), name
            assert fix(new)[0] == new, name
            old_row, new_row = derive(old, name, seq), derive(new, name, seq)
            newly_platform = [[x,z] for x,z in inside if old_row['tile'][z][x] == '4']
            for x,z in inside:
                assert new_row['tile'][z][x] == '1', name
            for x,z in edge:
                assert new_row['tile'][z][x] == '4', name
            entries.append({'map': name, 'sequence': seq, 'active': name in active[seq],
                'changed': old != new, 'before_sha256': sha(before[rel]),
                'interior_platform_cells': inside, 'newly_platform_cells': newly_platform,
                'perimeter_2_to_w': edge,
                'geometry_changes': old_row['tile'] != new_row['tile']})
            if old != new:
                docs[rel] = encode_map(new)
            derived[name] = (old_row, new_row)
    # Only actual floor changes need plan refresh. A boundary-only 2 -> w has
    # identical geometry; do not use it to overwrite already stale curation.
    refresh = {e['map'] for e in entries if e['active'] and e['geometry_changes']}
    for rel in map(Path, PLAN_PATHS):
        before[rel] = (ROOT / rel).read_bytes()
        plan = read(ROOT / rel)
        for row in plan['plans']:
            if row.get('map') not in refresh or row.get('sequence') not in SEQUENCES:
                continue
            name = row['map']
            old_row, fresh = derived[name]
            assert row['tile'] == old_row['tile'], name + ': stale plan geometry needs inspection'
            key = lambda a: (a['token'], tuple(a['tile_cell']))
            supports = {key(a): a['support_height_m'] for a in fresh['artifacts']}
            assert len(supports) == len(row['artifacts']), name
            assert set(supports) == {key(a) for a in row['artifacts']}, name
            row['tile'] = fresh['tile']
            row['interior_count'] = fresh['interior_count']
            row['gate_depth_rows'] = fresh['gate_depth_rows']
            for a in row['artifacts']:
                a['support_height_m'] = supports[key(a)]
        if plan != read(ROOT / rel):
            docs[rel] = (json.dumps(plan, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
    for rel in map(Path, ['commons/data/map_authored.json', 'commons/data/museum_order_effective.json',
                         'commons/data/artifact_roles.json', 'commons/data/spine_artifact_order.json']):
        before[rel] = (ROOT / rel).read_bytes()
    summary = {'audited_maps': len(entries), 'changed_maps': sum(e['changed'] for e in entries),
        'changed_active': sum(e['changed'] and e['active'] for e in entries),
        'new_platform_cells': sum(len(e['newly_platform_cells']) for e in entries),
        'new_active_platform_cells': sum(len(e['newly_platform_cells']) for e in entries if e['active']),
        'boundary_cells_made_explicit': sum(len(e['perimeter_2_to_w']) for e in entries),
        'active_plan_rows_refreshed': len(refresh)}
    print(json.dumps({'apply': args.apply, **summary}))
    if not args.apply or not docs:
        return
    if (OUT / 'recovery.json').exists():
        raise RuntimeError('Dated recovery already exists; inspect later edits before another migration')
    history = {}
    git = ['git', '-c', 'safe.directory=' + ROOT.as_posix()]
    for e in entries:
        rel = Path('commons/maps') / e['map'] / 'map_data.json'
        e['history'] = {}
        for label, rev in REFS.items():
            data = subprocess.check_output(git + ['show', rev + ':' + rel.as_posix()], cwd=ROOT)
            old = json.loads(data.decode('utf-8-sig'))
            rows = old['layers']['structure']
            e['history'][label] = {'commit': rev, 'sha256': sha(data),
                'dimensions': [max(map(len, rows)), len(rows)],
                'two_cells': sum(str(v).strip() == '2' for r in rows for v in r)}
            history[Path(label) / rel] = data
    # Archive all source and plan inputs before any mutation.
    for rel, data in {**{Path('before') / p: b for p,b in before.items()}, **history}.items():
        dest = OUT / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            assert dest.read_bytes() == data, str(dest)
        else:
            dest.write_bytes(data)
    report = {'at': datetime.now(timezone.utc).isoformat(), 'summary': summary, 'maps': entries,
        'historical_refs': REFS, 'active_routes': {s: active[s] for s in SEQUENCES},
        'refreshed_plan_maps': sorted(refresh),
        'boundary': 'Actual structure rectangle; no origin shift or old-footprint guessing.',
        'before_sha256': {p.as_posix(): sha(b) for p,b in before.items()},
        'changed_files': [p.as_posix() for p in docs],
        'runtime': 'pending; source derivation is not a physical collision test'}
    for rel, data in before.items():
        assert (ROOT / rel).read_bytes() == data, 'Concurrent edit: ' + str(rel)
    for rel, data in docs.items():
        p = ROOT / rel
        tmp = p.with_suffix('.platform-recovery.tmp')
        tmp.write_bytes(data)
        tmp.replace(p)
    # Prove that this migration did not alter artifacts, routes or other rows.
    for e in entries:
        rel = Path('commons/maps') / e['map'] / 'map_data.json'
        assert untouched_parts(read(ROOT / rel)) == untouched_parts(read(OUT / 'before' / rel)), e['map']
    for rel in map(Path, PLAN_PATHS):
        old, new = read(OUT / 'before' / rel), read(ROOT / rel)
        restored = copy.deepcopy(new)
        for a,b in zip(old['plans'], restored['plans']):
            if b.get('map') in refresh and b.get('sequence') in SEQUENCES:
                for k in ['tile', 'interior_count', 'gate_depth_rows']:
                    if k in a: b[k] = a[k]
                    else: b.pop(k, None)
                for x,y in zip(a['artifacts'], b['artifacts']):
                    y['support_height_m'] = x['support_height_m']
        assert restored == old, str(rel)
    for rel,b in before.items():
        if rel not in docs:
            assert (ROOT / rel).read_bytes() == b, str(rel)
    report['preservation'] = 'All artifact/utilities layers, metadata except the two museum fields, dimensions, route/role/order sources, and unselected plan rows preserved.'
    (OUT / 'recovery.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    check_current()


if __name__ == '__main__':
    main()
