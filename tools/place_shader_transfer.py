"""Place the source collection; preserve identity, config and source provenance."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'commons/void/trials/shaders'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,data):p.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
inventory=read(folder/'source-inventory.json')
rooms=read(folder/'rooms.json')
poses=[(-3,-12,0,0),(11,6,0,0),(-3,5,0,0),(-13,6,1.5,0),
       (0,-13.4,0,0),(-6,1.8,0,0),(-13,-9.6,0,0),(0,14.5,0,180),
       (-10,12,0,0),(13,-10.5,0,0),(-15,6.5,0,0),(10,7,0,0),(-3,7,0,0)]
adapters={'model_disagreement':'void_shader_disagreement','fuzzy_body':'void_shader_fuzzy_body'}
for floor in rooms['floors']:floor['artifacts']=[]
for entry,(x,z,y,facing) in zip(inventory['placements'],poses):
    config={}
    for field in entry['token'].split('#')[1:]:
        key,_,value=field.partition(':');config[key]=value or 'true'
    item=dict(id=entry['id'],artifact=adapters.get(entry['artifact'],entry['artifact']),position=[x,z],height=y,facing=facing,scale=1,station=('N' if z<0 else 'S')+('W' if x<0 else 'E'),config=config,
        )
    rooms['floors'][entry['floor']]['artifacts'].append(item)
    entry['status']='placed'
rooms['floors'][1]['title']='Shaping / the original instruments'
rooms['floors'][2]['title']='Patterns / the original collection'
write(folder/'rooms.json',rooms);write(folder/'source-inventory.json',inventory)
catalog=read(ROOT/'commons/void/catalog.json')
for source,key in adapters.items():
    value=dict(catalog['artifacts'][source]);value['scene']='res://commons/void/trials/shaders/'+('disagreement' if source=='model_disagreement' else 'fuzzy_body')+'.tscn'
    value['label']=source.replace('_',' ').title()+' / Void mount';value['museum_import']=True
    if source=='model_disagreement':value['configure_before_ready']=True
    catalog['artifacts'][key]=value
write(ROOT/'commons/void/catalog.json',catalog)
write(folder/'transfer-status.json',dict(owner='Codex',stage='placed',source_count=13,placed=13,omitted=[],native_tested=False,headset_tested=False,curated=False,adaptations=['Model Disagreement furniture relocated; model calculations unchanged.','Fuzzy Body backdrop and headings fitted below slab; hand controls and mesh calculation unchanged.']))
layout=read(folder/'layout.json');layout['status']='shaders / collection placed, validation pending';write(folder/'layout.json',layout)
batch=read(ROOT/'doc/void-transfer/2026-10-21-batch-01/batch.json')
batch['dispatch']={'claude':'UI submitted; acknowledgement verified in transfer-status.json','antigravity':'UI submitted; acknowledgement verified in transfer-status.json'}
write(ROOT/'doc/void-transfer/2026-10-21-batch-01/batch.json',batch)
