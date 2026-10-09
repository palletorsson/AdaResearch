"""Check recovery against archived working maps and untouched museum rows."""
from pathlib import Path
import copy
import hashlib
import importlib.util
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'doc/space/wave-platform-recovery-2026-09-10'
sys.path.insert(0, str(ROOT / 'tools'))
import em_map_halls
from recover_wave_platforms import repaired, refresh_active_plans


def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))


def main():
    report = read(ARCHIVE / 'recovery.json')
    counts = {'maps': 0, 'interior_platforms': 0, 'perimeter_walls': 0, 'artifact_placements_retained': 0}
    for room in report['maps']:
        rel = Path('commons/maps') / room['map'] / 'map_data.json'
        old, new = read(ARCHIVE / 'before' / rel), read(ROOT / rel)
        assert new == repaired(old)[0], room['map'] + ': unplanned source change'
        counts['maps'] += 1
        counts['interior_platforms'] += len(room['interior_platform_cells'])
        counts['perimeter_walls'] += len(room['perimeter_2_to_w'])
        counts['artifact_placements_retained'] += sum(bool(str(v).strip()) and str(v) != '0'
                for row in old['layers']['interactables'] for v in row)
        derived = em_map_halls.derive_row('check', room['map'], 'check', 0, 1, 'wavefunctions')
        for x, z in room['interior_platform_cells']:
            assert derived['tile'][z][x] == '1', (room['map'], x, z)
        for x, z in room['perimeter_2_to_w']:
            assert derived['tile'][z][x] == '4', (room['map'], x, z)
        assert derived['gate_depth_rows'] == 0
    rel = 'commons/data/map_authored.json'
    assert (ROOT / rel).read_bytes() == (ARCHIVE / 'before' / rel).read_bytes(), rel
    # The encyclopedia watcher refreshes measured extents and timestamps after
    # a museum probe. Membership and order, rather than cached dimensions, stay.
    rel = 'commons/data/museum_order_effective.json'
    assert [(r['name'], r['sequence']) for r in read(ROOT / rel)['halls']] == [
        (r['name'], r['sequence']) for r in read(ARCHIVE / 'before' / rel)['halls']]
    for rel in ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']:
        old, new = read(ARCHIVE / 'before' / rel), read(ROOT / rel)
        assert len(old['plans']) == len(new['plans'])
        assert [r['map'] for r in new['plans'] if r.get('sequence') == 'wavefunctions'] == report['active_route']
        restored = copy.deepcopy(new)
        for prior, row in zip(old['plans'], restored['plans']):
            if row.get('sequence') != 'wavefunctions':
                assert row == prior, row.get('map')
                continue
            for field in ['tile', 'interior_count']:
                row[field] = prior[field]
            row.pop('gate_depth_rows')
            for a, b in zip(prior['artifacts'], row['artifacts']):
                b['support_height_m'] = a['support_height_m']
        assert restored == old, rel + ': changed curation outside geometry/support'
    # A second consumer: compare old and new derivation on other chapters.
    # Only raised-floor support can change; default-wall maps remain identical.
    spec = importlib.util.spec_from_file_location('previous_halls', ARCHIVE / 'before/tools/em_map_halls.py')
    previous = importlib.util.module_from_spec(spec);spec.loader.exec_module(previous);previous.ROOT = ROOT
    consumers = []
    for name in ['Trans_Pre', 'Trans_Pit', 'Point_One', 'Noise_Perlin_Simplex']:
        prior = previous.derive_row('check', name, 'check', 0, 1)
        after = em_map_halls.derive_row('check', name, 'check', 0, 1)
        changes = []
        for a, b in zip(prior['artifacts'], after['artifacts']):
            if a['support_height_m'] != b['support_height_m']:
                changes.append({'token': b['token'], 'from': a['support_height_m'], 'to': b['support_height_m']})
                b['support_height_m'] = a['support_height_m']
        assert after == prior, name
        consumers.append({'map': name, 'support_changes': changes})
    paths = [ROOT / r for r in ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']]
    before_hash = [hashlib.sha256(p.read_bytes()).hexdigest() for p in paths]
    refresh_active_plans(report['active_route'])
    assert before_hash == [hashlib.sha256(p.read_bytes()).hexdigest() for p in paths]
    out = {**counts, 'active_halls': 6, 'extensions_not_activated': 6, 'unrelated_plan_rows': 'unchanged',
           'curation_and_route': 'unchanged', 'repeat_apply': 'no-op', 'second_consumers': consumers,
           'runtime_evidence': 'ada_run/wave_platform_active.json; separate from these source checks'}
    (ARCHIVE / 'source-checks.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
    print(json.dumps(out))


if __name__ == '__main__': main()
