"""Recover inherited interior platforms across all 24 spine sequences.

Audit by default. --apply records exact inputs before narrow source/plan edits.
--check verifies the saved recovery contract without regenerating encounters.
Embedded GridSystem arenas and rebuilt early galleries are separate cases.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import copy
import json
import subprocess

from em_map_halls import spine_names
from recover_sequence_platforms import ROOT, REFS, PLAN_PATHS, read, sha, derive
from recover_wave_platforms import encode_map
from map_pathfinder import MapGraph, check_rules

OUT = ROOT / 'doc/space/spine-platform-recovery-2026-09-10'
PROTECTED = {
    'Point_One', 'Point_Lines', 'Point_Line_Grid', 'Point_Triangle_Context',
    'Primitives_Polythedra', 'Point_Animatedcube', 'Primitives_Ignorance',
    'Array', 'Change_Intro',
}
ROUTE_PATHS = ['commons/maps/curriculum_spine.json', 'commons/data/map_authored.json',
               'commons/data/artifact_roles.json', 'commons/data/spine_artifact_order.json']


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + '.spine-platform.tmp')
    tmp.write_bytes(data)
    tmp.replace(path)


def save_json(path, doc):
    write(path, (json.dumps(doc, indent=2, ensure_ascii=False) + '\n').encode('utf-8'))


def inspect(doc):
    rows = doc['layers']['structure']
    width, depth = max(map(len, rows)), len(rows)
    assert all(len(row) == width for row in rows), 'Ragged structure requires review'
    inside, edge = [], []
    for z, row in enumerate(rows):
        for x, value in enumerate(row):
            if str(value).strip() == '2':
                (edge if x in (0, width-1) or z in (0, depth-1) else inside).append([x,z])
    return inside, edge


def decision(name, doc):
    inside, edge = inspect(doc)
    museum = doc['map_info'].get('museum', {})
    # The real grid constructs numeric heights directly. Its shell and its
    # arrival path must not be reinterpreted using the museum tile threshold.
    if museum.get('simulation', {}).get('grid', False):
        return 'embedded-grid', 'Real GridSystem supplies platforms; staged museum shell remains separate.'
    if not inside:
        return 'no-interior-2', 'No interior numeric 2 to restore.'
    if int(museum.get('wall_height', 2)) >= 3:
        return 'already-platforms', 'Existing per-map threshold already exposes the interior decks.'
    if name in PROTECTED:
        return 'preserved-gallery', 'Palle requested preservation of the newer gallery partitions on 2026-09-10; retain the current layout.'
    return 'recover', ('Authored intent explicitly calls the sills steps, not walls (intent.md).'
                       if name == 'Boolean_Verbs' else 'Inherited grid heights: retain interior 2 as one-metre decks inside the museum shell.')


def repair(doc):
    result = copy.deepcopy(doc)
    inside, edge = inspect(doc)
    for x,z in edge:
        result['layers']['structure'][z][x] = 'w'
    museum = result['map_info'].setdefault('museum', {})
    museum['wall_height'] = max(3, int(museum.get('wall_height', 2)))
    museum.setdefault('gate_depth_rows', 0)
    assert int(result['map_info']['dimensions'].get('max_height', 6)) >= 2
    return result


def non_geometry(doc):
    doc = copy.deepcopy(doc)
    doc['layers'].pop('structure')
    museum = doc['map_info'].get('museum', {})
    museum.pop('wall_height', None)
    museum.pop('gate_depth_rows', None)
    if not museum:
        doc['map_info'].pop('museum', None)
    return doc


def access(before, after):
    a, b = MapGraph(before), MapGraph(after)
    old_walk, new_walk = a.bfs_flood(), b.bfs_flood()
    lost = [[x,z] for z,x in sorted(old_walk - new_walk)
            if x not in (0,b.cols-1) and z not in (0,b.rows-1)]
    exits_before = [p for p in a.teleports if a.bfs_path(p) is not None]
    lost_exits = [[x,z] for z,x in exits_before if b.bfs_path((z,x)) is None]
    assert not lost and not lost_exits, (a.name, lost, lost_exits)
    # The grid pathfinder models numeric heights, not the museum's full-height
    # wall threshold. This establishes grid access non-regression only.
    return {'grid_reachable_before': len(old_walk), 'grid_reachable_after': len(new_walk),
            'lost_reachable_interior': lost, 'lost_reachable_exits': lost_exits,
            'previously_reachable_exits': len(exits_before),
            'rules_before': check_rules(a), 'rules_after': check_rules(b)}


def patch_plan(row, old, new, inside):
    """Patch affected cells/support only; retain unrelated cache and curation."""
    assert [len(r) for r in row['tile']] == [len(r) for r in old['tile']], row['map']
    note = {'map': row['map'], 'cells_changed': 0, 'supports_changed': 0,
            'preexisting_tile_differences': [], 'unmatched_source_artifacts': [],
            'curated_supports_preserved': []}
    original = copy.deepcopy(row)
    for z, rr in enumerate(old['tile']):
        for x, value in enumerate(rr):
            if original['tile'][z][x] != value:
                note['preexisting_tile_differences'].append([x,z,original['tile'][z][x],value])
    for x,z in inside:
        assert old['tile'][z][x] == '4' and new['tile'][z][x] == '1'
        assert row['tile'][z][x] in ('4','1'), (row['map'], x,z)
        note['cells_changed'] += row['tile'][z][x] != '1'
        row['tile'][z][x] = '1'
    row['interior_count'] = sum(v == '1' for r in row['tile'] for v in r)
    row['gate_depth_rows'] = new.get('gate_depth_rows', 0)
    key = lambda a: (a['token'], tuple(a['tile_cell']))
    old_arts = {key(a): a for a in old['artifacts']}
    new_arts = {key(a): a for a in new['artifacts']}
    row_keys = {key(a) for a in row['artifacts']}
    note['unmatched_source_artifacts'] = [list(k) for k in new_arts.keys()-row_keys]
    inside_set = {tuple(p) for p in inside}
    for art in row['artifacts']:
        k = key(art)
        if k not in new_arts or tuple(art['tile_cell']) not in inside_set:
            continue
        old_h, new_h = old_arts[k]['support_height_m'], new_arts[k]['support_height_m']
        if art['support_height_m'] not in (old_h, new_h):
            note['curated_supports_preserved'].append(list(k))
            continue
        note['supports_changed'] += art['support_height_m'] != new_h
        art['support_height_m'] = new_h
    restored = copy.deepcopy(row)
    for k in ['tile', 'interior_count', 'gate_depth_rows']:
        if k in original: restored[k] = original[k]
        else: restored.pop(k, None)
    for a,b in zip(original['artifacts'], restored['artifacts']):
        b['support_height_m'] = a['support_height_m']
    assert restored == original, row['map'] + ': curation changed'
    return note


def check_current():
    report = read(OUT / 'recovery.json')
    cells, checked = 0, []
    for entry in report['maps']:
        if not entry['changed']: continue
        name = entry['map']; rel = Path('commons/maps') / name / 'map_data.json'
        old, current = read(OUT / 'before' / rel), read(ROOT / rel)
        expected = repair(old)
        assert current['layers']['structure'] == expected['layers']['structure'], name
        assert current['map_info']['dimensions'] == expected['map_info']['dimensions'], name
        assert current['map_info'].get('museum', {}).get('wall_height', 2) >= 3, name
        assert current['map_info']['museum'].get('gate_depth_rows') == expected['map_info']['museum']['gate_depth_rows'], name
        fresh = derive(current, name, entry['sequence'])
        for x,z in entry['interior_platform_cells']:
            assert fresh['tile'][z][x] == '1', (name,x,z)
            cells += 1
        for x,z in entry['perimeter_2_to_w']:
            assert fresh['tile'][z][x] == '4', (name,x,z)
            cells += 1
        checked.append({'map': name, **access(old, current)})
    assert read(ROOT / 'commons/data/map_authored.json') == report['active_routes']
    assert spine_names() == report['spine_sequences']
    result = {'maps': len(checked), 'checked_cells': cells, 'source_geometry': 'pass',
              'grid_access_non_regression': 'pass', 'route': 'unchanged',
              'runtime': 'not run', 'later_artifact_and_text_edits': 'allowed', 'details': checked}
    save_json(ROOT / 'ada_run/spine_platform_checks.json', result)
    print(json.dumps({k:v for k,v in result.items() if k != 'details'}))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        check_current(); return
    active = read(ROOT / 'commons/data/map_authored.json')
    seqs = spine_names()
    before, updates, entries, derived = {}, {}, [], {}
    for seq in seqs:
        seq_rel = Path('commons/maps/sequences') / (seq+'.json')
        before[seq_rel] = (ROOT / seq_rel).read_bytes()
        seq_maps = read(ROOT / seq_rel)['sequences'][seq]['maps']
        for name in dict.fromkeys(seq_maps + active.get(seq, [])):
            rel = Path('commons/maps') / name / 'map_data.json'
            raw = (ROOT / rel).read_bytes(); old = json.loads(raw.decode('utf-8-sig'))
            before[rel] = raw
            status, reason = decision(name, old)
            inside, edge = inspect(old)
            entry = {'map': name, 'sequence': seq, 'active': name in active.get(seq, []),
                     'in_sequence_file': name in seq_maps, 'status': status, 'reason': reason,
                     'changed': status == 'recover', 'before_sha256': sha(raw),
                     'interior_platform_cells': inside, 'perimeter_2_to_w': edge if status == 'recover' else [],
                     'numeric_boundary_cells': len(edge)}
            if status == 'recover':
                new = repair(old)
                assert non_geometry(old) == non_geometry(new), name
                assert repair(new) == new, name
                entry['access'] = access(old, new)
                derived[name] = (derive(old,name,seq), derive(new,name,seq))
                updates[rel] = encode_map(new)
            entries.append(entry)
    selected = {e['map']: e for e in entries if e['changed'] and e['active']}
    plan_notes = {}
    for rel in map(Path, PLAN_PATHS):
        before[rel] = (ROOT / rel).read_bytes()
        plan = json.loads(before[rel].decode('utf-8-sig')); notes = []
        for row in plan['plans']:
            if row.get('map') in selected and row.get('sequence') == selected[row['map']]['sequence']:
                old,new = derived[row['map']]
                notes.append(patch_plan(row,old,new,selected[row['map']]['interior_platform_cells']))
        assert {n['map'] for n in notes} == selected.keys(), 'Missing selected active plan rows'
        plan_notes[rel.as_posix()] = notes
        if plan != json.loads(before[rel].decode('utf-8-sig')):
            updates[rel] = (json.dumps(plan, ensure_ascii=False, indent=2)+'\n').encode('utf-8')
    for rel in map(Path, ROUTE_PATHS): before[rel] = (ROOT / rel).read_bytes()
    summary = {'sequences': len(seqs), 'audited_maps': len(entries),
               'active_maps': sum(e['active'] for e in entries),
               'changed_maps': sum(e['changed'] for e in entries),
               'changed_active': len(selected),
               'new_platform_cells': sum(len(e['interior_platform_cells']) for e in entries if e['changed']),
               'boundary_cells_made_explicit': sum(len(e['perimeter_2_to_w']) for e in entries),
               'preserved_galleries': sum(e['status']=='preserved-gallery' for e in entries),
               'embedded_grid_maps': sum(e['status']=='embedded-grid' for e in entries)}
    print(json.dumps({'apply': args.apply, **summary}))
    report = {'at': datetime.now(timezone.utc).isoformat(), 'summary': summary,
              'spine_sequences': seqs, 'active_routes': active, 'maps': entries,
              'plan_patches': plan_notes, 'historical_refs': REFS,
              'before_sha256': {p.as_posix():sha(b) for p,b in before.items()},
              'changed_files': [p.as_posix() for p in updates],
              'runtime': 'pending; source derivation and grid BFS are not physical collision tests'}
    if not args.apply:
        save_json(ROOT / 'ada_run/spine_platform_audit.json', report); return
    if not updates: return
    if (OUT / 'recovery.json').exists():
        raise RuntimeError('Dated recovery exists; inspect later edits before another apply')
    git = ['git', '-c', 'safe.directory='+ROOT.as_posix()]
    for entry in entries:
        if not entry['changed'] and entry['status'] != 'preserved-gallery': continue
        rel = Path('commons/maps') / entry['map'] / 'map_data.json'
        entry['history'] = {}
        for label,rev in REFS.items():
            run = subprocess.run(git+['show',rev+':'+rel.as_posix()], cwd=ROOT, capture_output=True)
            if run.returncode:
                entry['history'][label] = {'exists': False, 'commit':rev}; continue
            historic = json.loads(run.stdout.decode('utf-8-sig'))
            entry['history'][label] = {'exists':True, 'commit':rev, 'sha256':sha(run.stdout),
                'same_structure':historic['layers']['structure'] == read(ROOT/rel)['layers']['structure']}
            write(OUT / label / rel, run.stdout)
    for rel,raw in before.items(): write(OUT / 'before' / rel, raw)
    # Preflight hashes cover the maps we own and shared plan/route sources.
    # Unselected W1 files may be changing in another session; never write them.
    for rel in set(updates) | set(map(Path, ROUTE_PATHS)):
        assert (ROOT/rel).read_bytes() == before[rel], 'Concurrent edit: '+str(rel)
    for rel,raw in updates.items():
        assert (ROOT/rel).read_bytes() == before[rel], 'Concurrent edit: '+str(rel)
        write(ROOT/rel, raw)
    for entry in entries:
        if not entry['changed']: continue
        rel = Path('commons/maps') / entry['map'] / 'map_data.json'
        assert non_geometry(read(ROOT/rel)) == non_geometry(read(OUT/'before'/rel))
    for rel in map(Path, ROUTE_PATHS): assert (ROOT/rel).read_bytes() == before[rel]
    report['preservation'] = 'All changed maps retain artifact and utility layers, dimensions, and metadata except wall/gate fields. No route, role, order, script, text or unselected plan row was changed.'
    save_json(OUT / 'recovery.json', report)
    check_current()


if __name__ == '__main__':
    main()
