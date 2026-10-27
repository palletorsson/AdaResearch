"""One-off batch-03 placement; original museum files remain read-only."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'commons/void/trials/isosurfaces'
def write(path,data): path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
inventory=json.loads((folder/'source-inventory.json').read_text())
rooms=json.loads((folder/'rooms.json').read_text())
if any(f['artifacts'] for f in rooms['floors']):
    raise SystemExit('Placements already exist; do not overwrite editorial work.')
poses=[(-4,-2),(-4,-8),(15,6),(-3,-2),(-3,-8),(14,8),(-3,8),(-46,0),(15,-8)]
aliases={'iso_workshop_console':'void_iso_workshop_console','iso_lookup_console':'void_iso_lookup_console'}
for p,(x,z) in zip(inventory['placements'],poses):
    fields=p['token'].split('#')[0].split(':')
    config={k:v or 'true' for k,_,v in (s.partition(':') for s in p['token'].split('#')[1:])}
    if len(fields)>1 and float(fields[1]):config['museum_yaw']=float(fields[1])
    item=dict(id=p['id'],artifact=aliases.get(p['artifact'],p['artifact']),position=[x,z],height=float(fields[2]) if len(fields)>2 else 0,facing=0,scale=float(fields[3]) if len(fields)>3 else 1,station=('N' if z<0 else 'S')+('W' if x<0 else 'E'),config=config)
    rooms['floors'][p['floor']]['artifacts'].append(item)
    p.update(status='placed',void_position=[x,item['height'],z])
write(folder/'rooms.json',rooms);write(folder/'source-inventory.json',inventory)
layout=json.loads((folder/'layout.json').read_text())
layout.update(storey_height=8,levels=[0,-8,-16,-24],status='Transfer: nine original placements; cave scale needs spatial integration')
layout['descent']['landing_max_speed']=14
write(folder/'layout.json',layout)
for name,source,key,var in [('iso_console','iso_workshop','voxel_noise_demo','field_root'),('lookup_console','iso_lookup_workshop','fifteen_cases_demo','model')]:
    src=(ROOT/f'commons/artifacts/timing_machines/{source}.gd').read_text()
    bind=src[src.index('func _bind()'):src.index('\nfunc act(')]
    begin=bind.index('\tvar em: Node=hall')
    end=bind.index('\n\tif '+var+'==null:push_error',begin)
    bind=bind[:begin]+f'''\tfor attempt in 100:
\t\t{var}=Links.find_artifact(hall,"{key}")
\t\tif {var}!=null:break
\t\tawait get_tree().create_timer(0.1).timeout
'''.rstrip()+bind[end:]
    begin=bind.index('\tfor at in [Vector3')
    end=bind.index('\n\t',bind.index('hall.add_child(light)',begin))
    bind=bind[:begin]+'\tLinks.light(self)'+bind[end:]
    (folder/(name+'.gd')).write_text(f'extends "res://commons/artifacts/timing_machines/{source}.gd"\n## Only the host lookup changes; original actions and extraction stay inherited.\nconst Links = preload("res://commons/void/trials/isosurfaces/floor_links.gd")\n\n'+bind+'\n',encoding='utf8')
    (folder/(name+'.tscn')).write_text(f'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://commons/void/trials/isosurfaces/{name}.gd" id="1"]\n[node name="Workshop" type="Node3D"]\nscript = ExtResource("1")\n',encoding='utf8')
catalog_path=ROOT/'commons/void/catalog.json'
catalog=json.loads(catalog_path.read_text(encoding='utf8'))
for old,new in aliases.items():
    entry=dict(catalog['artifacts'][old])
    script='iso_console' if old=='iso_workshop_console' else 'lookup_console'
    entry['scene']=f'res://commons/void/trials/isosurfaces/{script}.tscn'
    entry['source_scene']=catalog['artifacts'][old]['scene']
    catalog['artifacts'][new]=entry
write(catalog_path,catalog)
