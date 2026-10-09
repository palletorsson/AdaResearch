"""Insert into the authored bay without reformatting or changing its structure."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[4]
path = ROOT / 'commons/maps/Point_Lines/map_data.json'
text = path.read_text(encoding='utf-8-sig')
data = json.loads(text)
rows = data['layers']['interactables']
assert rows[2][2].strip() == ''
old = '\t\t\t' + json.dumps(rows[2], ensure_ascii=False) + ','
assert text.count(old) == 1
rows[2][2] = 'line_black_box:0:0#plinth:0#pin:1#offset:0.5,0,0.5'
new = '\t\t\t' + json.dumps(rows[2], ensure_ascii=False) + ','
text = text.replace(old, new)
text = text.replace('"n_artifacts": 40', '"n_artifacts": 41')
text = text.replace('"layout": "Original entry', '"layout": "The authored x=1..4, z=1..4 entrance bay is a 4 m black room, with a north entrance and an east passage. Original entry')
text = text.replace('"encounters": ["two points and barrier"', '"encounters": ["black room: two held endpoints and changing length", "two points and barrier"')
result = json.loads(text)
before = json.loads((ROOT/'doc/book/iterations/2026-09-29-line-black-box/before/commons/maps/Point_Lines/map_data.json').read_text(encoding='utf-8-sig'))
assert result['layers']['structure'] == before['layers']['structure']
assert result['layers']['utilities'] == before['layers']['utilities']
path.write_text(text, encoding='utf-8')
print('Placed one artifact. Authored structure and utilities unchanged.')
