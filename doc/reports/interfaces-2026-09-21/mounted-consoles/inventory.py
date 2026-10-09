"""Recorded placements only: not proof of current runtime/spine membership."""
from pathlib import Path
import json, re
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
names = ('grammar_provenance','fitness_landscape_politics','edge_of_chaos_unlocked')
rows = []
for path in sorted((ROOT/'commons/maps').glob('*/map_data.json')):
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    for layer, grid in data.get('layers',{}).items():
        if not isinstance(grid,list): continue
        for z,row in enumerate(grid):
            if not isinstance(row,list): continue
            for x,cell in enumerate(row):
                if not isinstance(cell,str): continue
                base = cell.split('#')[0].split(':')[0].strip()
                mount = re.search(r'#mount:([^#]+)',cell)
                target = mount.group(1).strip() if mount else base
                if target in names:
                    rows.append(dict(map=path.parent.name,layer=layer,x=x,z=z,artifact=target,
                                     mounted=bool(mount),token=cell))
(HERE/'inventory.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
for name in names:
    subset = [r for r in rows if r['artifact']==name]
    print(name, len(subset),'recorded;',sum(r['mounted'] for r in subset),'mounted')
print('Mounted examples:', [(r['map'],r['token']) for r in rows if r['mounted']][:5])
