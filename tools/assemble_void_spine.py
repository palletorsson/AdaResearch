"""Join already-transferred spine rooms without regenerating or curating artifacts.

Dry-run by default. The first eighteen authored floors are authoritative. Existing
trials stay intact; the main editor reuses their real local-coordinate GLBs.
"""
from pathlib import Path
import copy
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
VOID = ROOT / 'commons/void'
PUBLIC = ROOT.parent / 'ada_encyclopedia/public'
OUT = ROOT / 'ada_run/full-void-spine'
SKIPS = {
    'Point_Line_Grid': 'Integrated in the existing Point Trace shaft',
    'Primitives_Godot': 'Explicitly removed by the user',
    'Change_Intro': 'Change sequence skipped by the user',
    'Flow_Field': 'Change sequence skipped by the user',
}

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def text(data):
    return json.dumps(data, indent=2, ensure_ascii=False) + '\n'

def build():
    rooms_path, layout_path = VOID/'rooms.json', VOID/'layout.json'
    rooms, layout = read(rooms_path), read(layout_path)
    models_path = PUBLIC/'void-models/manifest.json'
    models = read(models_path)
    if layout.get('spine'):
        raise SystemExit('Spine already assembled. Do not overwrite subsequent user edits.')
    assert len(rooms['floors']) == 18
    originals = copy.deepcopy(rooms['floors'])
    trials = read(VOID/'trials/playable.json')['trials']
    candidates = {}
    for trial, definition in trials.items():
        source_rooms = read(ROOT/definition['rooms'].removeprefix('res://'))
        source_layout = read(ROOT/definition['layout'].removeprefix('res://'))
        for local, floor in enumerate(source_rooms['floors']):
            if local and floor.get('map') and any(floor.get(k) for k in ('artifacts','copies','construction','props','walls')):
                candidates.setdefault(floor['map'], []).append((trial, local, floor, source_layout, definition))
    current = {f['map']: i for i, f in enumerate(rooms['floors'])}
    sources, groups, entries = {}, [], []
    trial_models = {}
    for chapter in read(ROOT/'commons/data/long_museum.json')['chapters']:
        seq = chapter['sequence']
        definition = read(ROOT/f'commons/maps/sequences/{seq}.json')['sequences'][seq]
        indices = []
        for map_id in definition['maps']:
            if map_id in SKIPS:
                continue
            if map_id in current:
                index = current[map_id]
                origin = {'trial': '', 'floor': index}
            else:
                options = candidates.get(map_id, [])
                assert len(options) == 1, (map_id, 'ambiguous or missing saved transfer', len(options))
                trial, local, floor, source_layout, td = options[0]
                index = len(rooms['floors'])
                current[map_id] = index
                rooms['floors'].append(copy.deepcopy(floor))
                layout['levels'].append(-index * layout['storey_height'])
                layout['floor_roles'].append(floor['title'])
                origin = {'trial': trial, 'floor': local}
                sources[str(index)] = origin
                for field in ('floor_styles', 'spawn_points', 'floor_sign_positions'):
                    value = source_layout.get(field, {}).get(str(local))
                    if field == 'spawn_points':
                        value = td.get(field, {}).get(str(local), value)
                    if value is not None:
                        if field == 'spawn_points':
                            value = list(value)
                            value[0] = max(-layout['width']/2+1.2, min(layout['width']/2-1.2, value[0]))
                            value[2] = max(-layout['depth']/2+1.2, min(layout['depth']/2-1.2, value[2]))
                        if field == 'floor_sign_positions':
                            value = list(value)
                            value[1] = max(-layout['depth']/2+.7, min(layout['depth']/2-.7, value[1]))
                        layout.setdefault(field, {})[str(index)] = copy.deepcopy(value)
                descent = source_layout.get('descent', {})
                for field in ('pad_shafts', 'pad_x_sides'):
                    value = descent.get(field, {}).get(str(local))
                    if value is not None:
                        layout['descent'].setdefault(field, {})[str(index)] = value
                if local in descent.get('pad_disabled_floors', []):
                    layout['descent'].setdefault('pad_disabled_floors', []).append(index)
                if trial not in trial_models:
                    trial_models[trial] = read(PUBLIC/td['models'].lstrip('/'))
                source_models = trial_models[trial]
                exported = copy.deepcopy(source_models['floors'][str(local)])
                assert exported['map'] == map_id
                # Do not transplant the trial's enlarged structural floor. The
                # structure-only native export replaces this standard placeholder.
                exported['structure'] = copy.deepcopy(models['floors']['16']['structure'])
                models['floors'][str(index)] = exported
                for key, prop in source_models.get('props', {}).items():
                    models['props'].setdefault(key, copy.deepcopy(prop))
                for item in floor['artifacts'] + floor.get('copies', []):
                    assert not item.get('config', {}).get('editor_source'), 'Resolve cross-floor preview aliases explicitly'
            indices.append(index)
            entries.append({'floor': index, 'map': map_id, 'sequence': seq, 'title': rooms['floors'][index]['title'], 'source': origin})
        if indices:
            groups.append({'id': seq, 'title': definition.get('name', seq.replace('_', ' ').title()), 'floors': indices})
    assert rooms['floors'][:18] == originals
    assert sorted(e['floor'] for e in entries) == list(range(len(rooms['floors'])))
    assert len(entries) == 205
    layout['floor_sources'] = sources
    layout['spine'] = groups
    layout['status'] = 'Full included museum spine: 205 maps, standard floors, source placement retained; curation pending.'
    models['notes'] = list(models.get('notes', [])) + [
        'Full spine reuses the existing real trial exports. Source preview limitations and outstanding import findings remain applicable.',
        'All structural floors use the standard 42 x 18 metre frame. Oversized original exhibits remain full size and may extend beyond it.',
    ]
    models['source_files'] = {**models.get('source_files', {}),
        'commons/void/rooms.json': hashlib.sha256(text(rooms).encode()).hexdigest(),
        'commons/void/layout.json': hashlib.sha256(text(layout).encode()).hexdigest()}
    models['revision'] = hashlib.sha256(text(models).encode()).hexdigest()[:12]
    spine = {'version': 1, 'floors': entries, 'sequences': groups, 'exceptions': SKIPS,
        'scope': 'Map access and editable placement. Not a claim that every original occurrence, live physics import or oversized exhibit is fully integrated.'}
    outputs = {rooms_path: text(rooms), layout_path: text(layout), VOID/'spine.json': text(spine), models_path: text(models)}
    print(json.dumps({'maps': len(entries), 'sequences': len(groups), 'preserved_floors': 18, 'appended': len(sources), 'rooms_bytes': len(outputs[rooms_path].encode())}))
    if '--apply' in sys.argv:
        OUT.mkdir(parents=True, exist_ok=True)
        for path, content in outputs.items():
            if path.exists():
                backup = OUT/(path.parent.name+'-'+path.name+'.before')
                assert not backup.exists(), backup
                backup.write_bytes(path.read_bytes())
            path.write_text(content, encoding='utf8')
        (OUT/'assembly.json').write_text(text({'maps': len(entries), 'sequences': len(groups), 'curated_floors_preserved': rooms['floors'][:18] == originals}), encoding='utf8')

if __name__ == '__main__':
    build()
