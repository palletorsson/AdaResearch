"""Remove only the divider block under the entrance chair; retain all placements."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
path = ROOT/'commons/maps/Random_Entropies/map_data.json'
data = json.loads(path.read_text(encoding='utf-8'))
locations = [(x, z) for z, row in enumerate(data['layers']['interactables'])
             for x, token in enumerate(row) if token.startswith('entropy_chair_reference:')]
assert locations == [(9, 3)], locations
x, z = locations[0]
assert data['layers']['structure'][z][x] in ('p:1', '1')
data['layers']['structure'][z][x] = '1'
path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print('Reference chair at (9,3): removed one platform cell; low divider continues behind it.')
