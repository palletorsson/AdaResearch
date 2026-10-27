"""Read-only current-spine transfer coverage from inventories AND saved rooms.
Presence is not review acceptance, gameplay, fit or curation certification.
"""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def snapshot():
    inventories={};placed={}
    for p in (ROOT/'commons/void/trials').glob('*/source-inventory.json'):
        for m in read(p).get('maps',[]):inventories.setdefault(m,[]).append(p.parent.name)
    for p in [ROOT/'commons/void/rooms.json',*(ROOT/'commons/void/trials').glob('*/rooms.json')]:
        for f in read(p).get('floors',[]):
            if f.get('map') and any(f.get(k) for k in ('artifacts','construction','props','walls')):placed.setdefault(f['map'],[]).append(p.parent.name)
    exceptions={'Primitives_Godot':'User explicitly declined this map',
                'Point_Line_Grid':'Integrated into Trace shaft rather than its own floor',
                'Change_Intro':'User explicitly skipped Change sequence',
                'Flow_Field':'User explicitly skipped Change sequence'}
    rows=[]
    for chapter in read(ROOT/'commons/data/long_museum.json')['chapters']:
        seq=chapter['sequence'];s=read(ROOT/'commons/maps/sequences'/(seq+'.json'))['sequences'][seq]
        maps=[dict(map=m,placed_in=placed.get(m,[]),inventoried_in=inventories.get(m,[]),exception=exceptions.get(m,'')) for m in s['maps']]
        rows.append(dict(sequence=seq,maps=maps,remaining=[m['map'] for m in maps if not m['placed_in'] and not m['exception']]))
    return dict(scope='Source occurrence inventory and nonempty saved-floor presence only; not full acceptance/curation',sequences=rows)
if __name__=='__main__':print(json.dumps(snapshot(),indent=2))
