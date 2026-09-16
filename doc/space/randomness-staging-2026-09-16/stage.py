"""Curate the seven active Randomness rooms; retain a recoverable source snapshot."""
import copy
from collections import Counter
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'tools'))
from em_map_halls import derive_row

# Spatial hero first; supports retain their own mechanisms and native working scale.
ROOMS = {
    'Random_Definition': (11, 13, [
        (5, 6, 'seed_replay_demo:180#comparison:replicas#stand:table'),
        (2, 4, 'prng_crank_machine:180:0.62'),
        (8, 4, 'slot_machine:180'),
        (2, 10, 'trng_vs_prng:180:1.12:0.1'),
        (8, 10, 'random_number_book_page_1955:0:1.5:0.4'),
        (8, 7, 'catalyst_pickup:180#sequence_name:randomness#label_text:RANDOMNESS CATALYST#orb_color:0.95,0.55,0.20#accent_color:0.95,0.55,0.20'),
    ], 'Recover a seeded picture, then compare how other devices produce or retain a draw.'),
    'Random_Entropy': (13, 13, [
        (6, 6, 'shannon_entropy_meter:180#stand:ledger#disclosure:ledger'),
        (2, 4, 'entropy_jar:180'),
        (3, 9, 'hardware_entropy_decay:180:0.45:0.6'),
        (10, 11, 'entropy_axiom:180:1.2:0.45'),
        (10, 4, 'random_butterflies:180'),
    ], 'Measure symbol shares at the central ledger; compare the measurement with visible disorder in the side exhibits.'),
    'Random_Remove': (9, 10, [
        (4, 5, 'remove_random:180#local_grid:true'),
    ], 'The eligible set, removal controls and retained slots are one complete central experiment.'),
    'Random_Walk': (11, 13, [
        (5, 6, 'random_walk_terrarium:180#stand:logbook'),
        (2, 10, 'random_walk_collection:180#plinth:0.75#bench_bare_rack:1'),
        (8, 10, 'random_walk_leash:180'),
        (2, 3, 'random_walk_128:180:0:0.2'),
        (8, 3, 'pixel_cloud:180:0.1:0.18#walk_seed:101'),
    ], 'Follow accumulated steps in the central terrarium, then compare paper traces, a leash and a self-avoiding path.'),
    'Random_Gaussian': (11, 13, [
        (5, 6, 'distribution_sampler:180#stand:cabinet'),
        (2, 10, 'galton_board:180:0.9:1.5'),
        (8, 10, 'distribution_comparator:180:0.83'),
        (2, 7, 'GaussianPaintSplatter:180:1.5:0.65'),
    ], 'Compare retained samples at the central cabinet; falling beads, three sampling laws and paint marks extend that comparison.'),
    'Random_Mushrooms': (13, 14, [
        (6, 7, 'mushrooms:180#stand:specimen#size:6#edible:some'),
        (2, 11, 'bubbles_random:180:0.85:0.25#plinth:0.85'),
    ], 'Walk around the six-metre specimen bed and its controls. A small bubble dish offers a second population of varied bodies.'),
    'Random_Game': (15, 20, [
        # The crossing and field controls are already authored facing -Z.
        (7, 5, 'r_c#stand:chasm#cue:advance'),
        (7, 13, 'cube_projectile_spawner#mode:field#field_size:8x8#field_height:8#fall_min:1.6#fall_max:2.6#drift:0.25#jitter:0.25#jitter_interval:0.45#vertical_variation:0.2#spawn_interval:0.5#max_projectiles:24#stand:field'),
    ], 'The central crossing samples waits; a separate rear bay samples falling-cube positions and velocities. Both remain book encounters.'),
}

def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def save(path, data, indent=2):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=indent) + '\n', encoding='utf-8')

def lookup(token):
    return token.split('#')[0].split(':')[0]

def placements(data):
    return [{'x': x, 'z': z, 'token': token, 'lookup': lookup(token)}
            for z, row in enumerate(data['layers']['interactables'])
            for x, token in enumerate(row) if token.strip()]

def main():
    before = OUT / 'before'
    before.mkdir(exist_ok=True)
    roles_path = ROOT / 'commons/data/artifact_roles.json'
    roles = load(roles_path)
    archived_roles = {key: {name: value[name] for name in ROOMS if name in value}
                      for key, value in roles.items() if isinstance(value, dict)}
    if not (before / 'artifact_roles.json').exists():
        save(before / 'artifact_roles.json', archived_roles)
    manifest = []
    for name, (width, depth, items, purpose) in ROOMS.items():
        path = ROOT / 'commons/maps' / name / 'map_data.json'
        if not (before / (name + '.json')).exists():
            (before / (name + '.json')).write_bytes(path.read_bytes())
        original = load(before / (name + '.json'))
        data = load(path)
        centre = width // 2
        structure = [['w' if x in (0, width-1) or z in (0, depth-1) else '1'
                      for x in range(width)] for z in range(depth)]
        for z in (0, depth-1):
            for x in range(centre-1, centre+2):
                structure[z][x] = '1'
        if name == 'Random_Game':
            for z in range(4, 7):
                for x in range(5, 10):
                    structure[z][x] = '0'
        utilities = [[' ' for _ in range(width)] for _ in range(depth)]
        utilities[0][centre] = 's'
        utilities[depth-1][centre] = 't'
        interactables = [[' ' for _ in range(width)] for _ in range(depth)]
        for x, z, token in items:
            assert not interactables[z][x].strip()
            interactables[z][x] = token
        data['layers'] = {'structure': structure, 'utilities': utilities, 'interactables': interactables}
        info = data['map_info']
        info['dimensions'] = {'width': width, 'depth': depth, 'max_height': 3}
        info['description'] = purpose + ' Central hero, open approach from -Z and supporting exhibits oriented toward -Z. Curated 2026-09-16; original placements are archived in doc/space/randomness-staging-2026-09-16/before.'
        info['museum'] = {'wall_height': 3, 'gate_depth_rows': 0, 'artifact_placement': 'map',
                          'plinths': False, 'props_deny': ['dream_bodies'],
                          'sculpture_clear_rects': [[1, 1, width-2, depth-2]]}
        if name == 'Random_Game':
            info['museum']['open_roof'] = True
        data['settings']['gutter'] = 0.0
        data['settings']['initial_tile_visibility'] = 'all'
        save(path, data)
        primary = [lookup(items[0][2])]
        if name == 'Random_Game':
            primary.append('cube_projectile_spawner')
        secondary = [lookup(token) for _, _, token in items if lookup(token) not in primary]
        roles['roles'][name] = {key: ('primary' if key in primary else 'secondary') for key in primary + secondary}
        roles['order'][name] = {'primary': primary, 'secondary': secondary, 'decoration': []}
        old = placements(original)
        new = placements(data)
        remaining = Counter(p['lookup'] for p in new)
        removed = []
        for placement in old:
            if remaining[placement['lookup']] > 0:
                remaining[placement['lookup']] -= 1
            else:
                removed.append(placement)
        manifest.append({'map': name, 'before_size': original['map_info']['dimensions'],
                         'size': info['dimensions'], 'hero': primary[0], 'purpose': purpose,
                         'before_count': len(old), 'count': len(new), 'placements': new,
                         'removed_placements': removed})
    save(roles_path, roles, indent=1)
    for relative in ('ada_run/em_plan.json', 'commons/data/museum/em_plan.json'):
        path = ROOT / relative
        plan = load(path)
        old_rows = [r for r in plan['plans'] if r.get('map') in ROOMS]
        archive = before / ('runtime-plan-rows.json' if relative.startswith('ada_run') else 'shipped-plan-rows.json')
        if not archive.exists():
            save(archive, old_rows)
        untouched = [r for r in plan['plans'] if r.get('map') not in ROOMS]
        for index, row in enumerate(plan['plans']):
            if row.get('map') in ROOMS:
                plan['plans'][index] = derive_row(row['pearl'], row['map'], row['museum'], row['pearl_index'], row['pearls_total'], 'randomness')
        assert untouched == [r for r in plan['plans'] if r.get('map') not in ROOMS]
        save(path, plan)
    save(OUT / 'manifest.json', manifest)
    print('Staged', len(ROOMS), 'rooms;', sum(r['before_count'] for r in manifest), '->', sum(r['count'] for r in manifest), 'placements')

if __name__ == '__main__':
    main()
