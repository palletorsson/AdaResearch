"""Shared editor/CLI validation for Void content; never mutates a source file."""
from pathlib import Path
import json
import sys
import math
from jsonschema import Draft7Validator

ROOT = Path(__file__).resolve().parents[1]
VOID = ROOT / 'commons/void'

def available_artifacts():
    items = {}
    for file in sorted((ROOT / 'commons/artifacts/registry').glob('*.json')):
        doc = json.loads(file.read_text(encoding='utf-8-sig'))
        for key, item in doc.get('artifacts', {}).items():
            if isinstance(item, dict) and item.get('scene') and (ROOT / item['scene'].removeprefix('res://')).is_file():
                items[key] = {'scene': item['scene'], 'label': item.get('name', key)}
    items.update(json.loads((VOID / 'catalog.json').read_text(encoding='utf-8'))['artifacts'])
    return items

def overlaps(a, b):
    return a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]


def rect(x, z, width, depth):
    return (x-width/2, z-depth/2, x+width/2, z+depth/2)


def original_scale_allowances(frame_path):
    """Only an inventoried museum scale may exceed the ordinary editor ceiling.

    This preserves as-is source transfers (including malformed original tokens)
    without raising the schema limit for arbitrary new or edited object sizes.
    """
    frame_path = frame_path or VOID/'layout.json'
    path = frame_path.parent/'source-inventory.json'
    paths = [path]
    # The main spine retains each imported floor's original transfer provenance.
    # Original outsize scales remain inventoried exceptions, never a new default.
    if frame_path == VOID/'layout.json':
        layout = json.loads(frame_path.read_text(encoding='utf-8-sig'))
        for trial in {s['trial'] for s in layout.get('floor_sources', {}).values()}:
            if trial and all(c.isalnum() or c in '_-' for c in trial):
                paths.append(VOID/'trials'/trial/'source-inventory.json')
    allowed = set()
    for path in paths:
        if path.is_file():
            for item in json.loads(path.read_text(encoding='utf-8-sig')).get('placements', []):
                parts = item['token'].split('#')[0].split(':')
                try: scale = float(parts[3]) if len(parts)>3 else 1.0
                except ValueError: continue
                if math.isfinite(scale) and scale>16: allowed.add((item['artifact'],scale))
    return allowed


def retained_original_scale(error, data, allowed):
    path = list(error.path)
    if error.validator != 'maximum' or len(path)!=5 or path[0]!='floors' or path[2] not in ('artifacts','copies') or path[4]!='scale':
        return False
    item = data['floors'][path[1]][path[2]][path[3]]
    return (item.get('artifact'),error.instance) in allowed


def validate(data, frame_path=None):
    schema = json.loads((VOID / 'rooms.schema.json').read_text(encoding='utf-8'))
    allowed = original_scale_allowances(frame_path)
    errors = [f'{"/".join(map(str, e.path))}: {e.message}' for e in Draft7Validator(schema).iter_errors(data)
              if not retained_original_scale(e,data,allowed)]
    if errors:
        return errors
    catalog = json.loads((VOID / 'catalog.json').read_text(encoding='utf-8'))
    frame = json.loads((frame_path or VOID / 'layout.json').read_text(encoding='utf-8'))
    if len(data['floors']) != len(frame['levels']):
        return ['Floor record count must match layout levels']
    artifacts = available_artifacts()
    shafts = [rect(s['x'], 0, frame['shaft_width'], frame['shaft_depth']) for s in frame['shafts']]
    columns = [rect(x,z,frame['column_width'],frame['column_width']) for x in frame['column_x'] for z in frame['column_z']]
    for index, floor in enumerate(data['floors']):
        prefix = f'Floor {index}'
        if floor['map'] and not (ROOT / 'commons/maps' / floor['map'] / 'map_data.json').exists():
            errors.append(f'{prefix}: unknown map')
        if floor['origin'] and index != 0:
            errors.append(f'{prefix}: world zero belongs on the roof')
        protected = [rect(-6,4.5,1.2,1.2)]
        descent = frame.get('descent', {})
        if descent.get('mode') == 'balcony':
            for target in [index, index+1]:
                if 1 <= target < len(frame['levels']) and target <= len(descent.get('balcony_sides', [])) and target not in descent.get('shaft_corner_floors', []):
                    side = 1 if descent['balcony_sides'][target-1] == 'south' else -1
                    protected.append(rect(0,side*(frame['depth']/2-1),2.0,2.0))
        if floor['origin']: protected.append(rect(0,0,1.6,1.6))
        cells = [rect(x+.5,z+.5,1,1) for x,z in floor['impact_cells']]
        def placement(bounds, label, walkable_obstacle=True):
            if bounds[0] < -frame['width']/2 or bounds[2] > frame['width']/2 or bounds[1] < -frame['depth']/2 or bounds[3] > frame['depth']/2:
                errors.append(f'{prefix}: {label} leaves the structural floor')
            if any(overlaps(bounds,b) for b in shafts): errors.append(f'{prefix}: {label} overlaps a shaft')
            if walkable_obstacle and any(overlaps(bounds,b) for b in protected): errors.append(f'{prefix}: {label} blocks a checkpoint, balcony approach or origin')
            if walkable_obstacle and any(overlaps(bounds,b) for b in cells): errors.append(f'{prefix}: {label} overlaps a catalyst cell')
        construction_ids = set()
        for part in floor.get('construction', []):
            if part['id'] in construction_ids: errors.append(f'{prefix}: duplicate construction ID')
            construction_ids.add(part['id'])
            if not all(math.isfinite(v) for v in part['position'] + part.get('travel', [])):
                errors.append(f'{prefix}: invalid construction coordinates')
            if part['position'][1] < 0 or part['position'][1] > frame['storey_height']-.4:
                errors.append(f'{prefix}: construction height outside storey')
            if part['kind']=='platform':
                travel=part.get('travel', [0,0,-8])
                if sum(v*v for v in travel)<.01: errors.append(f'{prefix}: platform needs a nonzero journey')
                end=part['position'][1]+travel[1]
                if end<.2 or end>frame['storey_height']-.4: errors.append(f'{prefix}: platform destination outside storey')
            if part['kind']=='rotating_platform':
                if part['position'][1]<.2: errors.append(f'{prefix}: rotating deck top must be above the floor')
                if not all(math.isfinite(part.get(k, v)) for k,v in [('angle',-90),('turn_speed',9),('length',8),('pause',6)]):
                    errors.append(f'{prefix}: invalid rotation settings')
        stations, ids, occupied, standing = set(), set(), [], []
        for item in floor['artifacts'] + floor.get('copies', []):
            is_copy = item in floor.get('copies', [])
            if item['artifact'] not in artifacts: errors.append(f'{prefix}: artifact is not in the registry or its scene is missing')
            config = item.get('config', {})
            if item['height'] > frame['storey_height']-.4:
                errors.append(f'{prefix}: artifact anchor exceeds storey clearance')
            overrides = config.get('parts', {})
            if overrides or config.get('only_parts'):
                manifests = json.loads((VOID / 'line_parts.json').read_text(encoding='utf-8'))
                known = manifests.get(item['artifact'], manifests.get(item['artifact'].removeprefix('void_lines_'), {}))
                for name in config.get('only_parts', []):
                    if name not in known: errors.append(f'{prefix}: unknown copied part {name}')
                for name, transform in overrides.items():
                    if name not in known: errors.append(f'{prefix}: unknown artifact part {name}')
                    for values in transform.values():
                        if not all(math.isfinite(v) for v in values): errors.append(f'{prefix}: invalid part transform')

            if is_copy and 'editor_source' not in config: errors.append(f'{prefix}: copied artifact needs its preview source')
            if 'editor_source' in config:
                source = config['editor_source']
                source_count = len(json.loads((VOID / 'rooms.json').read_text(encoding='utf-8'))['floors']) if source.get('shared') else len(data['floors'])
                if source.get('trial'):
                    trials = json.loads((VOID/'trials/playable.json').read_text(encoding='utf-8'))['trials']
                    definition = trials.get(source['trial'])
                    if definition:
                        resource = definition.get('rooms', '')
                        if resource.startswith('res://commons/void/trials/') and '..' not in resource:
                            source_count = len(json.loads((ROOT/resource[6:]).read_text(encoding='utf-8'))['floors'])
                        else: errors.append(f'{prefix}: invalid preview trial resource')
                    else: errors.append(f'{prefix}: unregistered preview trial')
                if source['floor'] >= source_count: errors.append(f'{prefix}: invalid preview source floor')
                # The source points to a geometry export, not a live dependency.
                # Copies remain valid if their source instance is later removed.
            # Four electrical stations can supply multiple curated objects.
            if item['id'] in ids: errors.append(f'{prefix}: duplicate artifact ID')
            if not is_copy: stations.add(item['station'])
            ids.add(item['id'])
            x,z = item.get('position', catalog['stations'][item['station']])
            # A minimum access footprint, not an inferred full registry mesh bound.
            bounds = rect(x,z,1.3,1.3)
            placement(bounds, 'artifact '+item['id'])
            if any(overlaps(bounds,b) for b in columns): errors.append(f'{prefix}: artifact {item["id"]} overlaps a column')
            if any(overlaps(bounds,b) for b in occupied): errors.append(f'{prefix}: artifact access footprints overlap')
            occupied.append(bounds)
            if not artifacts.get(item['artifact'], {}).get('wall_mounted', False): standing.append(bounds)
        basins = []
        for x,z,w,d in floor.get('basin', {}).get('rects', []):
            bounds = (x,z,x+w,z+d)
            placement(bounds, 'basin')
            if any(overlaps(bounds,b) for b in columns): errors.append(f'{prefix}: basin overlaps a column')
            basins.append(bounds)
        wall_ids = set(); wall_bounds = []
        for wall in floor['walls']:
            x1,z1 = wall['from']; x2,z2 = wall['to']
            if wall['id'] in wall_ids: errors.append(f'{prefix}: duplicate wall ID')
            wall_ids.add(wall['id'])
            if (x1 == x2) == (z1 == z2): errors.append(f'{prefix}: wall must be a nonzero horizontal or vertical segment')
            if wall.get('base',0)+wall['height'] > frame['storey_height']-.6: errors.append(f'{prefix}: wall exceeds storey clearance')
            bounds = (min(x1,x2)-.09,min(z1,z2)-.09,max(x1,x2)+.09,max(z1,z2)+.09)
            low = wall.get('base',0) < 2.3
            placement(bounds, 'wall '+wall['id'], low)
            if low and any(overlaps(bounds,b) for b in standing): errors.append(f'{prefix}: wall covers an artifact access footprint')
            if low and any(overlaps(bounds,b) for b in basins): errors.append(f'{prefix}: wall covers the basin')
            if low: wall_bounds.append(bounds)
        prop_ids = set()
        for prop in floor.get('props',[]):
            if prop['id'] in prop_ids: errors.append(f'{prefix}: duplicate prop ID')
            prop_ids.add(prop['id'])
            size = catalog['props'][prop['kind']]['size']; scale = prop['scale']
            w,h,d = [v*scale for v in size]
            if prop['facing'] in [90,270]: w,d = d,w
            x,z = prop['position']; bounds = rect(x,z,w,d)
            placement(bounds, 'prop '+prop['id'])
            if h > frame['storey_height']-.6: errors.append(f'{prefix}: prop exceeds storey clearance')
            if any(overlaps(bounds,b) for b in columns): errors.append(f'{prefix}: prop overlaps a column')
            if any(overlaps(bounds,b) for b in occupied): errors.append(f'{prefix}: prop covers an artifact access footprint')
            if any(overlaps(bounds,b) for b in wall_bounds): errors.append(f'{prefix}: prop intersects a wall')
            if any(overlaps(bounds,b) for b in basins): errors.append(f'{prefix}: prop covers the basin')
        if floor['origin'] and any(-1 <= x <= 0 and -1 <= z <= 0 for x,z in floor['impact_cells']): errors.append(f'{prefix}: catalyst cells overlap the origin')
    return errors


def editor_validation(data, frame_path=None):
    """Placement heuristics advise the designer; invalid resources/data block save.

    The old 2D access rectangles cannot judge raised artifacts, intentional
    overlaps or beams across shafts. Keep these checks visible without rejecting
    the user's whole document because an unrelated floor has a warning.
    """
    issues = validate(data, frame_path)
    spatial = ('leaves the structural floor', 'overlaps a shaft',
               'blocks a checkpoint, balcony approach or origin',
               'overlaps a catalyst cell', 'overlaps a column',
               'artifact access footprints overlap', 'wall exceeds storey clearance',
               'wall covers an artifact access footprint', 'wall covers the basin',
               'prop exceeds storey clearance', 'prop covers an artifact access footprint',
               'prop intersects a wall', 'prop covers the basin',
               'catalyst cells overlap the origin')
    warnings = [issue for issue in issues if any(issue.endswith(s) for s in spatial)]
    errors = [issue for issue in issues if issue not in warnings]
    allowed = original_scale_allowances(frame_path)
    for index,floor in enumerate(data.get('floors', [])):
        for item in floor.get('artifacts', [])+floor.get('copies', []):
            if (item.get('artifact'),item.get('scale')) in allowed:
                warnings.append(f"Floor {index}: {item['id']} retains original museum scale {item['scale']}, above the ordinary editor limit; spatial integration is pending")
    return {'valid': not errors, 'errors': errors, 'warnings': warnings}


if __name__ == '__main__':
    if '--catalog' in sys.argv:
        print(json.dumps(available_artifacts()))
        sys.exit(0)
    try:
        trial = next((a.split('=',1)[1] for a in sys.argv if a.startswith('--trial=')), '')
        definition = json.loads((VOID/'trials/playable.json').read_text(encoding='utf8'))['trials'][trial] if trial else {}
        frame_path = ROOT / definition['layout'].removeprefix('res://') if trial else None
        rooms_path = ROOT / definition['rooms'].removeprefix('res://') if trial else VOID/'rooms.json'
        data = json.load(sys.stdin) if '--stdin' in sys.argv else json.loads(rooms_path.read_text(encoding='utf-8'))
        report = editor_validation(data, frame_path) if '--editor' in sys.argv else None
        errors = report['errors'] if report else validate(data, frame_path)
    except Exception as exc:
        errors = [str(exc)]
    print(json.dumps(report if 'report' in locals() and report is not None else {'valid': not errors, 'errors': errors}))
    sys.exit(bool(errors))
