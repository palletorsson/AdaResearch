"""Add one independent monitor and derive only its map's two museum plan rows."""
from pathlib import Path
import json
import copy
import em_map_halls as h

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-04-resolution-reveal-monitor'
OUT.mkdir(parents=True,exist_ok=True)
MAP='Primitives_Ignorance'
path=ROOT/f'commons/maps/{MAP}/map_data.json'
m=json.loads(path.read_text(encoding='utf-8'))
backup=OUT/'map-before.json'
if not backup.exists(): backup.write_bytes(path.read_bytes())
cell=m['layers']['interactables'][16][1]
assert cell in ('','0') or cell.startswith('resolution_reveal_monitor:'), cell
m['layers']['interactables'][16][1]='resolution_reveal_monitor:90:0#plinth:0#pin:1'
m['map_info']['metadata']['n_artifacts']=sum(str(v).strip() not in ('','0') for row in m['layers']['interactables'] for v in row)
path.write_text(json.dumps(m,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
regpath=ROOT/'commons/artifacts/registry/concept_monitor.json'
reg=json.loads(regpath.read_text(encoding='utf-8'))
reg['artifacts']['resolution_reveal_monitor']={
    'lookup_name':'resolution_reveal_monitor','name':'Around / Along: Three Resolutions',
    'map_ready':True,'scene':'res://commons/artifacts/concept_monitor/resolution_reveal_monitor.tscn',
    'description':'A live camera films native cylinder, capsule and sphere meshes. Compare segments and rings independently, inspect actual triangle edges and explore every integer combination within S4-64 and R0-32 (sphere R1-32).',
    'category':'primitives','include_in_map_data':True,'auto_ground':False,
    'footprint':[2.7,2.6,.55],'size_group':'standard','map_sequences':['primitives'],
    'tags':['monitor','resolution','cylinder','capsule','sphere','rings','segments'],
    'interactions':['Look at the monitor to play; look away to freeze.','Pause, replay or step through the film.','Use S-/S+ and R-/R+ for each integer setting.','Toggle triangle edges with SURFACE.'],
    'qfep_connection':'Sampling around and along a body are independent choices. More geometry changes some silhouettes and leaves others intact; smooth shading is a separate decision.'}
regpath.write_text(json.dumps(reg,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

def find(obj):
    if isinstance(obj,dict):
        if obj.get('map')==MAP: return obj
        for value in obj.values():
            result=find(value)
            if result is not None: return result
    elif isinstance(obj,list):
        for value in obj:
            result=find(value)
            if result is not None: return result
    return None

pairs=h.declared()['primitives']
idx=next(i for i,p in enumerate(pairs) if p[1]==MAP)
for name,dest in [('plan','ada_run/em_plan.json'),('shipped','commons/data/museum/em_plan.json')]:
    p=ROOT/dest
    data=json.loads(p.read_text(encoding='utf-8-sig'))
    old=find(data)
    assert old is not None
    backup=OUT/f'{name}-row-before.json'
    if not backup.exists(): backup.write_text(json.dumps(old,indent=2),encoding='utf-8')
    row=h.derive_row(old['pearl'],MAP,old['museum'],idx,len(pairs),'primitives')
    h.normalize_row(row,False,any(k in row for k in ('basin','passage','simulation')),width_exempt=False)
    old.clear()
    old.update(row)
    p.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('Updated',dest,MAP)
