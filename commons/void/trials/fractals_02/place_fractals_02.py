"""First placement pass, preserving original token height/scale/config.

No encounter curation or button testing. Refuses to replace a saved arrangement.
"""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
inventory = json.loads((HERE/'source-inventory.json').read_text())
rooms = json.loads((HERE/'rooms.json').read_text())
assert not any(f['artifacts'] for f in rooms['floors']), 'Existing arrangement: edit in place.'
positions = [
    [(-17,10),(0,7),(15,9),(18,4),(0,-8),(15,-8),(-17,3.5),(-17,-4),(-17,-10.5)],
    [(-15,8),(0,-7),(15,8),(0,7),(18,4),(-16,-8),(16,-8),(0,-13),(-7,-10),(7,-10)],
    [(-17,10),(15,9),(-17,4),(0,0),(16,-4),(-17,-8)],
    [(0,8),(15,8),(-15,8),(16,-8),(0,-13),(0,-6),(-16,-8)],
    [(0,-10),(-14,8),(14,8),(-17,1),(17,1),(-17,-4),(0,0),(0,7),(17,-6),(-15,-10),(13,-11)],
]
for level, places in enumerate(positions,1):
    sources = [a for a in inventory['placements'] if a['floor'] == level]
    assert len(sources) == len(places)
    for source,(x,z) in zip(sources,places):
        head,*bits = source['token'].split('#');parts=head.split(':')
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
p=HERE/'layout.json';layout=json.loads(p.read_text());layout['status']='fractals_02 / placement-first transfer';layout['floor_sign_positions']={str(i):[18,12] for i in range(1,6)};p.write_text(json.dumps(layout,indent=2)+'\n')
print('Placed 43 original occurrences. Interaction/button testing deferred.')
