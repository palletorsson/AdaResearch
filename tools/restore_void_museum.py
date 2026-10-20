"""One-time additive migration. Native inventory resolves objects already in the tower.

Default: write a reviewable coverage plan. --apply: back up, compare and save.
Existing user transforms are never regenerated. Re-running recognises stable IDs.
"""
from pathlib import Path
import collections, copy, hashlib, json, math, re, sys

ROOT = Path(__file__).resolve().parents[1]
VOID = ROOT / 'commons/void'
OUT = ROOT / 'doc/book/iterations/2026-10-19-museum-objects-and-landings'
OUT.mkdir(parents=True, exist_ok=True)
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
rooms_path = VOID / 'rooms.json'
original = rooms_path.read_bytes()
rooms = json.loads(original)
catalog = read(VOID / 'catalog.json')
frame = read(VOID / 'layout.json')
registry = {}
for file in sorted((ROOT / 'commons/artifacts/registry').glob('*.json')):
    for key, value in read(file).get('artifacts', {}).items():
        if isinstance(value, dict) and value.get('scene') and (ROOT / value['scene'].removeprefix('res://')).is_file():
            registry[key] = value
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
inventory = read(stage/'inventory.json')

def script_of(scene):
    text = (ROOT/scene.removeprefix('res://')).read_text(encoding='utf-8-sig')
    refs = {i:p for p,i in re.findall(r'\[ext_resource type="Script" path="([^"]+)" id="([^"]+)"\]',text)}
    script = re.search(r'^script = ExtResource\("([^"]+)"\)',text,re.M)
    return refs.get(script[1], '') if script else ''

# These are deliberate tower adaptations, not missing objects. Keep recent
# choices (rod light switch, open shafts, expanded galleries and triangle signs).
adapted = {
    (0,'arrival_shaft'):'Permanent open elevator shaft',
    (1,'point_sun_switch'):'Rod light switch on the Point One floor',
    (8,'geometry_courtyard'):'hall / five separate original solid studies',
    (9,'primitive_mesh_library'):'hall / eight separate original engine primitives',
    (10,'resolution_colonnade_museum'):'hall / twenty-five separate original columns',
}
coverage, added, removed = [], [], []
for index, floor in enumerate(rooms['floors']):
    for collection in ['artifacts','copies']:
        retained = []
        for item in floor.get(collection, []):
            if item['artifact']=='void_trace_descent' or 'TimberDescent' in item.get('config',{}).get('only_parts',[]):
                removed.append({'floor':index,'id':item['id']}); continue
            item.get('config',{}).get('parts',{}).pop('TimberDescent',None)
            retained.append(item)
        if collection in floor: floor[collection]=retained
    available = [v for v in inventory if v['floor']==index and 'TimberDescent' not in v['node']]
    used = set()
    occupied = [a.get('position',catalog['stations'][a['station']]) for a in floor['artifacts']+floor.get('copies',[])]
    occupied += [p['position'] for p in floor.get('props',[])]
    # Clear shaft approaches and the central route. Staging positions only;
    # the designer has full control once the source objects are restored.
    slots = [[x,z] for z in [-6,-3,0,3,6] for x in [-18,-15,-6,-3,0,3,6,15,18]
             if not (z==3 and x==-6)]
    maps = [floor['map']] + (['Point_Line_Grid'] if index==4 else [])
    for map_name in maps:
        doc = read(ROOT/'commons/maps'/map_name/'map_data.json')
        for row_num, row in enumerate(doc['layers']['interactables']):
            for col, token in enumerate(row):
                if not isinstance(token,str) or not token.strip(): continue
                chunks=token.split('#'); head=chunks[0].split(':'); key=head[0]
                if key not in registry: raise ValueError(f'Unresolved {map_name}: {token}')
                entry=registry[key]; scene=entry['scene']; script=script_of(scene)
                config={}
                for chunk in chunks[1:]:
                    k,sep,v=chunk.partition(':'); config[k]=v if sep else True
                ident=f'museum-{map_name.lower()}-{row_num}-{col}'
                record={'floor':index,'map':map_name,'cell':[col,row_num],'artifact':key,'scene':scene,'token':token}
                existing = next((a for a in floor['artifacts'] if a['id']==ident),None)
                match=next((v for v in available if v['node'] not in used and
                    (v['scene']==scene or (script and v.get('script')==script))),None)
                if existing:
                    record.update(status='added',id=ident)
                elif (index,key) in adapted:
                    record.update(status='adapted',target=adapted[index,key])
                elif match:
                    used.add(match['node']); record.update(status='retained',target=match['node'])
                else:
                    # Source yaw may be non-cardinal; retain it inside the object
                    # while the editor's outer mount still turns in 90-degree steps.
                    yaw=float(head[1]) if len(head)>1 and head[1] else 0
                    height=float(head[2]) if len(head)>2 and head[2] else 0
                    scale=float(head[3]) if len(head)>3 and head[3] else 1
                    position=max(slots,key=lambda p:min((p[0]-a[0])**2+(p[1]-a[1])**2 for a in occupied))
                    slots.remove(position); occupied.append(position)
                    if not slots: slots=[[x,z] for z in [-7.5,-4.5,4.5,7.5] for x in [-18,-15,-6,-3,0,3,6,15,18]]
                    # Offsets belong to the former grid placement; the new mount
                    # owns translation. Save the complete token in the audit.
                    for k in ['offset','plinth','pin']: config.pop(k,None)
                    config['museum_yaw']=yaw
                    config['editor_label']=key.replace('_',' ')+' / original museum'
                    config['museum_origin']=map_name+':'+str(col)+','+str(row_num)
                    item={'id':ident,'artifact':key,'station':('N' if position[1]<0 else 'S')+('W' if position[0]<0 else 'E'),
                          'position':position,'height':min(2.5,max(0,height)), 'scale':min(4,max(.25,scale)), 'facing':0,'config':config}
                    floor['artifacts'].append(item)
                    definition=copy.deepcopy(entry)
                    definition.update(label=entry.get('name',key.replace('_',' ')),museum_import=True)
                    catalog['artifacts'][key]=definition
                    record.update(status='added',id=ident)
                    added.append(record)
                coverage.append(record)
frame['descent']={'mode':'corner_pads','landing_max_speed':13,'pad_shaft':'B','boards_per_pad':2}
frame['route_note']='Two thin, marked plank pads in alternating outside corners of shaft B; one floor at a time. Shaft A and the Trace Grid remain clear.'
plan={'source':'Original Primitives map_data.json interactable cells','coverage':coverage,'added':len(added),'removed_descent_assemblies':removed,
      'counts':dict(collections.Counter(v['status'] for v in coverage)), 'rooms_before_sha256':hashlib.sha256(original).hexdigest()}
(OUT/'inventory.json').write_text(json.dumps(plan,indent=2)+'\n',encoding='utf-8')
(OUT/'rooms.proposed.json').write_text(json.dumps(rooms,indent=2)+'\n',encoding='utf-8')
if '--apply' in sys.argv:
    if rooms_path.read_bytes()!=original: raise RuntimeError('Editor saved during migration; rerun from the latest layout.')
    backup=ROOT/'ada_run/void-museum-migration';backup.mkdir(parents=True,exist_ok=True)
    (backup/'rooms.before.json').write_bytes(original)
    for path,data in [(rooms_path,rooms),(VOID/'catalog.json',catalog),(VOID/'layout.json',frame)]:
        path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'cells':len(coverage),'added':len(added),'counts':plan['counts'],'by_floor':dict(collections.Counter(v['floor'] for v in added))}))
