"""Place every source occurrence as-is; never replace a saved user arrangement."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
inventory = json.loads((HERE/'source-inventory.json').read_text())
rooms = json.loads((HERE/'rooms.json').read_text())
assert not any(f['artifacts'] for f in rooms['floors']), 'Existing arrangement: edit in place.'
positions = [
    [(0,7),(-16,7),(0,-7),(15,8),(-16,-7),(17,-5),(17,-10)],
    [(0,6),(-18,-10),(15,8),(18,2),(-14,-7),(14,-7),(-17,8),(-18,-3),(0,-9)],
    [(0,0),(-16,8),(17,8)],
    [(0,6),(-16,-7),(16,-7),(-17,8),(16,8),(0,-10)],
    [(-10,0),(10,-2)],
    [(0,7),(-16,8),(16,8),(-17,0),(0,-7),(17,0),(-15,-9),(16,-7),(16,-12)],
]
for level, places in enumerate(positions,1):
    sources=[a for a in inventory['placements'] if a['floor']==level]
    assert len(sources)==len(places)
    for source,(x,z) in zip(sources,places):
        head,*bits=source['token'].split('#');parts=head.split(':')
        yaw=float(parts[1]) if len(parts)>1 and parts[1] else 0
        height=float(parts[2]) if len(parts)>2 and parts[2] else 0
        scale=float(parts[3]) if len(parts)>3 and parts[3] else 1
        config={}
        for bit in bits:
            k,_,v=bit.partition(':');config[k]=v or 'true'
        rooms['floors'][level]['artifacts'].append(dict(id=source['id'],artifact=source['artifact'],
            station=('S' if z>=0 else 'N')+('E' if x>=0 else 'W'),position=[x,z],
            facing=int((yaw+180)%360),height=height,scale=scale,config=config))
(HERE/'rooms.json').write_text(json.dumps(rooms,indent=2)+'\n')
p=HERE/'layout.json';layout=json.loads(p.read_text());layout['status']='lsystems_02 / placement-first transfer'
layout['floor_sign_positions']={str(i):[18,12] for i in range(1,7)}
p.write_text(json.dumps(layout,indent=2)+'\n')
print('Placed 36 original occurrences on six floors. Artifact button testing deferred.')
