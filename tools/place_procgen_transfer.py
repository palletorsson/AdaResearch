"""One-time placement of batch 02; refuses to overwrite a curated collection."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
folder = ROOT/'commons/void/trials/proceduralgeneration'
def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def write(path, data): path.write_text(json.dumps(data, indent=2)+'\n', encoding='utf8')

inventory = read(folder/'source-inventory.json')
rooms = read(folder/'rooms.json')
assert not any(f['artifacts'] for f in rooms['floors']), 'Do not overwrite editor work'
poses = [(-5,-4,0,0), (14,6,1.5,0), (-5,-4,0,0), (14,6,0,0)]
for entry, (x,z,y,facing) in zip(inventory['placements'], poses):
    config = {}
    for fragment in entry['token'].split('#')[1:]:
        key,_,value = fragment.partition(':'); config[key] = value or 'true'
    item = dict(id=entry['id'], artifact=entry['artifact'], position=[x,z],
                height=y, facing=facing, scale=1, station=('N' if z<0 else 'S')+('W' if x<0 else 'E'), config=config)
    rooms['floors'][entry['floor']]['artifacts'].append(item)
    entry['status']='placed'
    entry['void']=dict(position=[x,z],height=y,facing=facing,scale=1)
rooms['floors'][1]['title']='Genetic Evolution / original selection study'
rooms['floors'][2]['title']='Space Colonization / original growth study'
write(folder/'rooms.json',rooms)
write(folder/'source-inventory.json',inventory)
layout=read(folder/'layout.json'); layout['status']='proceduralgeneration / collection placed, validation pending'
layout['storey_height']=7;layout['levels']=[0,-7,-14,-21]
layout['route_note']='Transfer envelope: seven-metre storeys retain the original six-metre request field at 1:1 scale. Main tower stays unchanged; resolve the final fit during curation.'
write(folder/'layout.json',layout)
write(folder/'transfer-status.json',dict(owner='Codex',stage='placed',maps=inventory['maps'],source_count=4,placed=4,omitted=[],native_tested=False,headset_tested=False,curated=False,
    adaptations=[],unresolved_dependencies=['Original museum observation ramps depend on VESTIBULE_H and are not generated in Void. The existing Void floor carries the visitor; generated bodies still do not provide collision.','Science Screen mode:grid retains its original fallback; it is not wired to candidate fitness.']))
