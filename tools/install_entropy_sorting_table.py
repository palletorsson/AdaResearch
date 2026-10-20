"""Register the four-cube table without replacing existing entropy encounters."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def update(path, edit):
    target = ROOT / path
    data = json.loads(target.read_text(encoding='utf-8'))
    edit(data)
    target.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def registry(data):
    data['artifacts']['entropy_sorting_table'] = {
        'lookup_name': 'entropy_sorting_table', 'name': 'Four cubes / How many ways?',
        'scene': 'res://commons/artifacts/entropy_sorting_table/entropy_sorting_table.tscn',
        'category': 'randomness', 'sequence': 'randomness', 'map_sequences': ['randomness'],
        'map_ready': True, 'include_in_map_data': True, 'complexity': 'beginner',
        'description': 'A tube delivers one kept batch: two pink and two black cubes. Sort the same four occupied spots, add one divider at a time, and inspect every colour arrangement matching the current counts in each box. Pauses indefinitely for sorting; no replacement draws.',
        'interactions': ['DROP FOUR delivers the fixed batch once', 'Lift and drop a cube over another spot to exchange them', 'ADD DIVIDER progresses from one to four boxes without moving cubes', 'ONE BOX removes dividers, retaining the arrangement'],
        'parameters': {'footprint': [2.8, 1.8, 2.25], 'size_group': 'installation'},
        'tags': ['entropy', 'multiplicity', 'sorting', 'partition', 'tutorial'],
        'qfep_connection': 'A boundary changes which distinctions the record retains while the material inventory stays fixed.'
    }

def room(data):
    grid = data['layers']['interactables']
    assert grid[9][13].strip() in ('', 'entropy_sorting_table:180:0#plinth:0#pin:1')
    grid[9][13] = 'entropy_sorting_table:180:0#plinth:0#pin:1'
    data['map_info']['metadata']['n_artifacts'] = sum(bool(c.strip()) for row in grid for c in row)

def wall(data):
    if 'entropy_sorting_table' not in data['order']:
        data['order'].insert(data['order'].index('entropy_compartments'), 'entropy_sorting_table')
    if not any(m['id'] == 'entropy_sorting_table' for m in data['magnets']):
        data['magnets'].append({
            'id': 'entropy_sorting_table', 'x': 105, 'y': 115,
            'brief': 'Four cubes stay. Dividers change which colour arrangements agree with each box’s counts.',
            'question': 'Can a boundary change WAYS without moving a single cube?',
            'theme': 'measurement', 'tutorial': 'Keep P B P B and add dividers: 6, 4, 2, 1. Then sort P P | B B: only one colour arrangement agrees. Count the pictures before using a formula.',
            'final': 'A wall can narrow the record without changing the objects. Sorting changes the counts inside that wall; adding a wall changes the question.',
            'proposal': 'Observe whether the pictures make the count understandable before approaching the sixteen-site dials.',
            'tags': ['tutorial', 'final']
        })

update('commons/artifacts/registry/randomness.json', registry)
update('commons/maps/Random_Entropy/map_data.json', room)
update('commons/maps/Random_Entropy/writing_wall.json', wall)
print('Registered four-cube sorting table in Entropy Workshop at (13, 9).')
