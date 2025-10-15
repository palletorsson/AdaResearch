import json, re
from pathlib import Path

base = Path(r"C:\\Users\\palle\\Documents\\GitHub\\AdaResearch\\commons\\maps")

maps = [p.name for p in base.iterdir() if p.is_dir() and p.name.lower().startswith('wavefunctions')]

summary = {}
for name in sorted(maps):
    path = base / name / 'map_data.json'
    if not path.exists():
        continue
    text = path.read_text(encoding='utf-8')
    clean = re.sub(r',(?=\s*[\]}])', '', text)
    data = json.loads(clean)
    utilities = []
    for z, row in enumerate(data['layers'].get('utilities', [])):
        for x, cell in enumerate(row):
            cell = str(cell).strip()
            if cell:
                utilities.append({'cell': cell, 'type': cell.split(':')[0], 'x': x, 'z': z})
    interactables = []
    for z, row in enumerate(data['layers'].get('interactables', [])):
        for x, cell in enumerate(row):
            cell = str(cell).strip()
            if cell:
                interactables.append({'cell': cell, 'scene': cell.split(':')[0], 'x': x, 'z': z})
    summary[name] = {
        'dimensions': data['map_info']['dimensions'],
        'utilities': utilities,
        'interactables': interactables
    }

import pprint
pprint.pprint(summary)
