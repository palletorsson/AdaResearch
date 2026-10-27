"""Project the existing kit and saved spine variants into one spawn catalogue.

The projection owns labels, never scenes. Placement carries the original config,
scale and height; a label is not parsed back into an artifact token.
"""
from __future__ import annotations

import copy
import hashlib
import json
import re
from pathlib import Path

COLORS = ['#80c9b4', '#e7bd7b', '#aebdf0', '#dca5ca', '#9fcf89', '#e99b89']


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def compact(name):
    return re.sub(r'[^\w:.×-]+', '-', str(name).lower()).strip('-')


def enrich(doc, root, web):
    kit = read(root / 'commons/void/primitive-prefabs.json')['prefabs']
    catalog = read(root / 'commons/void/catalog.json')
    rooms = read(root / 'commons/void/rooms.json')
    manifest_path = web / 'public/void-models/manifest.json'
    models = read(manifest_path) if manifest_path.exists() else {}
    items = doc['items']
    sequences = doc['trees'][0]['children']
    map_sequence = {m['id']: s['id'] for s in sequences for m in s['children']}

    def decorate(key, item):
        family = item.get('family') or item.get('category') or 'Studies'
        item['family'] = str(family)
        item['color'] = COLORS[int(hashlib.sha256(str(family).encode()).hexdigest()[:4], 16) % len(COLORS)]
        item.setdefault('short_label', compact(key))

    for key, item in items.items():
        item['placement'] = {'kind': 'artifact', 'artifact': key, 'config': {}, 'height': 0, 'scale': 1}
        decorate(key, item)

    signatures = {}
    for fi, floor in enumerate(rooms['floors']):
        for record in floor.get('artifacts', []) + floor.get('copies', []):
            token = record['artifact']
            config = copy.deepcopy(record.get('config', {}))
            # Provenance is metadata, but part poses and all native options matter.
            semantic = {k: v for k, v in config.items() if k not in ('editor_label', 'editor_source', 'museum_origin')}
            sig = json.dumps([token, record.get('scale', 1), record.get('height', 0), semantic], sort_keys=True)
            if sig in signatures:
                entry = items[signatures[sig]]
                if floor['map'] not in entry['maps']:
                    entry['maps'].append(floor['map'])
                seq = map_sequence.get(floor['map'])
                if seq and seq not in entry['sequences']:
                    entry['sequences'].append(seq)
                continue
            base = items.get(token, {})
            key = token if 'sourceFloor' not in base.get('placement', {}) else token + '@' + hashlib.sha256(sig.encode()).hexdigest()[:10]
            source = config.get('editor_source') or {'floor': fi, 'id': record['id']}
            source_floor, source_id = source.get('floor', fi), source.get('id', record['id'])
            placement = {'kind': 'artifact', 'artifact': token, 'sourceFloor': source_floor, 'sourceId': source_id,
                         'config': config, 'height': record.get('height', 0), 'scale': record.get('scale', 1), 'sharedSource': True}
            config.pop('editor_source', None)
            label = config.get('editor_label') or base.get('label') or token
            mode = next((str(config[k]) for k in ('variant', 'mode', 'form', 'preset') if k in config), '')
            short = compact(token) + (':' + compact(mode) if mode else '')
            if key != token and not mode:
                short += ':' + compact(record['id']).removeprefix('museum-')[-24:]
            entry = {**copy.deepcopy(base), 'label': label, 'short_label': short, 'placement': placement,
                     'maps': [floor['map']], 'sequences': [map_sequence.get(floor['map'], 'primitives')],
                     'family': base.get('category') or 'Studies', 'description': base.get('description', ''),
                     'thumbnail': base.get('thumbnail'), 'map_ready': True}
            decorate(key, entry)
            items[key] = entry
            signatures[sig] = key

    aliases = {'trace_point_ball': 'psphere:trace', 'construction_cube': 'box:concrete', 'wp': 'wedge:1'}
    for p in kit:
        match = next((k for k, v in catalog['props'].items() if v.get('scene') == p.get('scene')), None)
        placement = None
        thumb = None
        if match:
            placement = {'kind': 'prop', 'propKind': match}
            thumb = models.get('props', {}).get(match, {}).get('thumbnail')
        if p.get('placement'):
            src = p['placement']
            placement = {'kind': 'artifact', 'artifact': src['artifact'], 'sourceFloor': src['source_floor'],
                         'sourceId': src['source_id'], 'sharedSource': True, 'height': src.get('height', 0),
                         'scale': src.get('scale', 1), 'config': copy.deepcopy(src.get('config', {}))}
        if p.get('construction'):
            placement = {'kind': 'construction', 'items': copy.deepcopy(p['construction']['items'])}
        if not placement:
            continue
        short = aliases.get(p['id'], compact(p['id']))
        if p['id'].startswith('timber_plank_'):
            short = 'plank:' + p['id'].removeprefix('timber_plank_').removesuffix('m')
        if p['id'].startswith('timber_panel_'):
            short = 'panel:' + p['id'].removeprefix('timber_panel_')
        sphere = re.fullmatch(r'sphere_comparisonstand_(\d+)_(edges|surface)', p['id'])
        if sphere:
            short = 'sphere:' + ':'.join(sphere.groups())
        if p['id'].startswith('profile_profile_'):
            short = 'profile:' + p['id'].removeprefix('profile_profile_').replace('_', ':')
        if p['id'].startswith('column_grove_'):
            short = 'column:' + p['id'].removeprefix('column_grove_').replace('_', '×')
        if p['id'].startswith('trans_'):
            short = re.sub(r'^trans_\d+_', 'trans:', p['id']).replace('_', '-')
        entry = {'label': p['title'], 'short_label': short, 'family': p['family'], 'description': p.get('behaviour', ''),
                 'maps': [p['map']], 'sequences': [map_sequence.get(p['map'], 'primitives')], 'placement': placement,
                 'dimensions': p.get('dimensions'), 'thumbnail': thumb, 'map_ready': True, 'prefab_id': p['id']}
        decorate(p['id'], entry)
        items['kit:' + p['id']] = entry

    # Keep the complete construction palette available, with its existing identifiers.
    for key, prop in catalog['props'].items():
        if any(v['placement'].get('propKind') == key for v in items.values()):
            continue
        entry = {'label': prop['label'], 'short_label': compact(key), 'family': prop.get('group', 'Construction'),
                 'maps': [], 'sequences': [], 'description': '', 'dimensions': prop.get('size'),
                 'thumbnail': models.get('props', {}).get(key, {}).get('thumbnail'), 'map_ready': True,
                 'placement': {'kind': 'prop', 'propKind': key}}
        decorate(key, entry)
        items['prop:' + key] = entry
    for sequence in sequences:
        sequence['items'] = [k for k, v in items.items() if sequence['id'] in v.get('sequences', [])]
        for m in sequence['children']:
            m['items'] = [k for k, v in items.items() if m['id'] in v.get('maps', [])]
    doc['version'] = 2
    doc['summary'].update(items=len(items), with_thumbnail=sum(bool(v.get('thumbnail')) for v in items.values()),
                          configured=sum('sourceFloor' in v['placement'] for v in items.values()),
                          kit=sum(k.startswith('kit:') for k in items))
    doc['source_files'].update({str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()[:16]
                               for p in [root / 'commons/void/rooms.json', root / 'commons/void/primitive-prefabs.json', root / 'commons/void/catalog.json']})
    return doc


def append_placement(floor, item, at, facing, rid):
    """Native bridge counterpart of the editor's placeLibraryPrefab. Never replaces objects."""
    p = copy.deepcopy(item['placement'])
    if p['kind'] == 'prop':
        floor.setdefault('props', []).append({'id': rid, 'kind': p['propKind'], 'position': at, 'facing': facing, 'scale': 1})
    elif p['kind'] == 'construction':
        import math
        c, s = math.cos(math.radians(facing)), math.sin(math.radians(facing))
        for cell in p['items']:
            x, y, z = cell['position']
            cell.update(id=rid + '-' + cell['id'], position=[at[0] + c*x + s*z, y, at[1] - s*x + c*z], facing=cell.get('facing', 0) + facing)
            floor.setdefault('construction', []).append(cell)
    else:
        config = p.get('config', {})
        config['editor_label'] = item['label']
        if 'sourceFloor' in p:
            config['editor_source'] = {'floor': p['sourceFloor'], 'id': p['sourceId'], 'shared': True}
        floor.setdefault('artifacts', []).append({'id': rid, 'artifact': p['artifact'], 'station': 'NW', 'position': at,
            'height': p.get('height', 0), 'scale': p.get('scale', 1), 'facing': facing, 'config': config})
