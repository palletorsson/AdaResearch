"""Idempotent promotion of the reviewed egg study to Boolean Works."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
def read(path): return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))
def save(path, data): (ROOT / path).write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

path = 'commons/artifacts/registry/reference_studies.json'
data = read(path)
data['artifacts']['boolean_eggs'] = {
    'lookup_name': 'boolean_eggs', 'name': 'Boolean Eggs — a darkness held',
    'scene': 'res://commons/artifacts/kapoor_void_studies/boolean_eggs_museum.tscn',
    'description': 'Three deep-colour CSG ovoids on a colliding low plinth: union, intersection and a genuinely concave subtraction whose interior material removes lighting cues.',
    'category': 'reference_studies', 'sequence': 'boolean_surfaces',
    'map_ready': True, 'include_in_map_data': True, 'complexity': 'intermediate',
    'tags': ['boolean', 'colour', 'void', 'reference-study'],
    'minimum_display_bounds_m': [7.84, 4.8, 3.24],
    'reference_artist': 'Anish Kapoor (original response, not a reconstruction)',
    'interactions': ['Walk around the three forms; compare the lit rim with the unlit cavity.'],
    'parameters': {}, 'signals': [],
    'qfep_connection': 'The deterministic cut makes a boundary; its material decides which depth cues remain visible.',
    'status': 'Installed in Boolean_Works; desktop capture verified separately from headset acceptance.'
}
save(path, data)

path = 'commons/maps/Boolean_Works/map_data.json'
data = read(path)
if not any('boolean_eggs' in str(cell) for row in data['layers']['interactables'] for cell in row):
    # Keep the existing work intact; make a quiet bay before the final two comparisons.
    for name, layer in data['layers'].items():
        new_rows = [(['4']+['1']*15+['4']) if name == 'structure' else ['']*17 for _ in range(8)]
        layer[36:36] = new_rows
    data['layers']['interactables'][39][7] = 'boolean_eggs:180:0'
    data['map_info']['dimensions']['depth'] = len(data['layers']['structure'])
    data['map_info']['museum']['sculpture_clear_rects'] = [[1,1,15,50]]
    data['map_info']['description'] = 'Boolean composition at sculptural and architectural scale: visible interiors, an inhabitable burrow, and deep-colour eggs whose dark cut asks what a surface lets us see.'
for row in data['layers']['interactables']:
    for x, cell in enumerate(row):
        if str(cell).startswith('boolean_eggs:'):
            row[x] = 'boolean_eggs:180:0'
# Four approach rows keep the viewing position outside the preceding cavern.
if data['layers']['interactables'][39][7].startswith('boolean_eggs'):
    for name, layer in data['layers'].items():
        layer[36:36] = [(['4']+['1']*15+['4']) if name == 'structure' else ['']*17 for _ in range(4)]
    data['map_info']['dimensions']['depth'] = len(data['layers']['structure'])
    data['map_info']['museum']['sculpture_clear_rects'] = [[1,1,15,54]]
save(path, data)

path = 'commons/maps/sequences/boolean_surfaces.json'
data = read(path)
seq = data['sequences']['boolean_surfaces']
for group in seq['artifact_groups']:
    if group['map'] == 'Boolean_Works':
        if 'boolean_eggs' not in group['artifacts']:
            group['artifacts'].insert(group['artifacts'].index('booleanvariations'), 'boolean_eggs')
        group['rationale'] = 'A workbench, visual models, a colliding burrow and deep-colour Boolean eggs distinguish a geometric interior, its visible surface and body clearance.'
seq['content'][2] = 'Boolean_Works: compare a visual wall, a level-floor burrow, a raised cavern and the dark concavity of three Boolean eggs.'
save(path, data)
print('Boolean eggs registered and placed in the dedicated Boolean_Works bay (7,43).')
