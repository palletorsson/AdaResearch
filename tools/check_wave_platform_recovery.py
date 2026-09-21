"""Check the recovered platform/wall geometry while allowing encounter edits.

Use --snapshot to check the original recovery state, including its curation.
Neither mode rewrites maps or museum plans.
"""
from pathlib import Path
import copy
import importlib.util
import json
import sys
import argparse

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'doc/space/wave-platform-recovery-2026-09-10'
sys.path.insert(0, str(ROOT / 'tools'))
import em_map_halls
from recover_wave_platforms import repaired


def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', action='store_true', help='Audit the original recovery snapshot, before later encounter edits.')
    args = parser.parse_args()
    report = read(ARCHIVE / 'recovery.json')
    counts = {'maps': 0, 'interior_platforms': 0, 'perimeter_walls': 0, 'current_artifact_placements': 0}
    for room in report['maps']:
        rel = Path('commons/maps') / room['map'] / 'map_data.json'
        old, new = read(ARCHIVE / 'before' / rel), read(ROOT / rel)
        expected = repaired(old)[0]
        assert new['layers']['structure'] == expected['layers']['structure'], room['map'] + ': recovered geometry changed'
        assert new['map_info']['dimensions'] == expected['map_info']['dimensions'], room['map'] + ': dimensions changed'
        assert new['map_info']['museum']['wall_height'] == 3
        assert new['map_info']['museum']['gate_depth_rows'] == 0
        if args.snapshot:
            assert new == expected, room['map'] + ': changed since the recovery snapshot'
        counts['maps'] += 1
        counts['interior_platforms'] += len(room['interior_platform_cells'])
        counts['perimeter_walls'] += len(room['perimeter_2_to_w'])
        counts['current_artifact_placements'] += sum(bool(str(v).strip()) and str(v) != '0'
                for row in new['layers']['interactables'] for v in row)
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
        if not args.snapshot:
            continue
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
        after.pop('gate_depth_rows', None)
        changes = []
        for a, b in zip(prior['artifacts'], after['artifacts']):
            if a['support_height_m'] != b['support_height_m']:
                changes.append({'token': b['token'], 'from': a['support_height_m'], 'to': b['support_height_m']})
                b['support_height_m'] = a['support_height_m']
        assert after == prior, name
        consumers.append({'map': name, 'support_changes': changes})
    out = {**counts, 'active_halls': 6, 'extensions_not_activated': 6,
           'unrelated_plan_rows': 'snapshot checked' if args.snapshot else 'outside the geometry check',
           'mode': 'original snapshot' if args.snapshot else 'persistent geometry contract',
           'curation': 'snapshot checked' if args.snapshot else 'later encounter edits allowed',
           'wave_route': 'unchanged', 'checker': 'read-only; does not refresh plans', 'second_consumers': consumers,
           'runtime_evidence': 'ada_run/wave_platform_active.json; separate from these source checks'}
    # The original dated evidence is immutable. Current checks report separately.
    (ROOT / 'ada_run/wave_platform_contract_checks.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
    print(json.dumps(out))


if __name__ == '__main__': main()
