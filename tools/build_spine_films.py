"""Assemble independent films and place their monitors without replacing exhibits."""
from pathlib import Path
import argparse, copy, json, math
import em_map_halls as halls

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'commons/artifacts/spine_films'
OUT=ROOT/'doc/book/iterations/2026-10-04-spine-films'
RUN=ROOT/'ada_run/spine_films'

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

def manifests():
    entries=[]
    for p in [BASE/'manifest.json',BASE/'early/manifest.json',BASE/'middle/manifest.json',BASE/'late/manifest.json',
              BASE/'more_early/manifest.json',BASE/'more_motion/manifest.json',BASE/'more_structure/manifest.json',
              BASE/'foundation_a/manifest.json',BASE/'foundation_b/manifest.json',BASE/'foundation_c/manifest.json']:
        if p.exists():
            data=read(p)
            rows=data if isinstance(data,list) else data['films']
            if p.parent.name.startswith('more_'):
                rows=[{**row,'collection':'more'} for row in rows]
            elif p.parent.name.startswith('foundation_'):
                rows=[{**row,'collection':'foundation'} for row in rows]
            entries.extend(rows)
    order={d['name']:d['order'] for d in read(ROOT/'commons/maps/curriculum_spine.json')['spine']['sequences']}
    return sorted(entries,key=lambda d:(order[d['sequence']],d.get('sort',0),d['id']))

def find_row(obj,map_name):
    if isinstance(obj,dict):
        if obj.get('map')==map_name:return obj
        for v in obj.values():
            r=find_row(v,map_name)
            if r is not None:return r
    elif isinstance(obj,list):
        for v in obj:
            r=find_row(v,map_name)
            if r is not None:return r
    return None

def candidates(data,lookup):
    grid=data['layers']['structure']; items=data['layers']['interactables']
    occupied=[(x,z) for z,row in enumerate(items) for x,v in enumerate(row) if str(v).strip() not in ('','0') and not str(v).startswith(lookup+':')]
    h=len(grid);w=max(map(len,grid))
    util=data['layers'].get('utilities',[])
    museum=data.get('map_info',{}).get('museum',{})
    wall_height=int(museum.get('wall_height',2))
    floor_cells={tuple(cell[:2]) for cell in museum.get('floor_cells',[]) if len(cell)>=2}
    def floor(x,z):return 0<=z<h and 0<=x<len(grid[z]) and (str(grid[z][x])=='1' or (x,z) in floor_cells)
    def cell(layer,x,z):return layer[z][x] if 0<=z<len(layer) and 0<=x<len(layer[z]) else ''
    def empty(x,z):return floor(x,z) and str(cell(items,x,z)).strip() in ('','0') and str(cell(util,x,z)).strip() in ('','0')
    def wall(x,z):
        if not (0<=z<h and 0<=x<len(grid[z])) or (x,z) in floor_cells:return False
        token=str(grid[z][x]).strip()
        return token=='w' or (token.isdigit() and int(token)>=wall_height)
    def clear_ray(a,b):
        length=math.dist(a,b)
        steps=max(1,int(length/.12))
        for i in range(1,steps):
            t=i/steps
            x,z=round(a[0]+(b[0]-a[0])*t),round(a[1]+(b[1]-a[1])*t)
            if not (0<=z<h and 0<=x<len(grid[z])):return False
            value=str(grid[z][x]).strip()
            if wall(x,z) or ((x,z) not in floor_cells and value.isdigit() and int(value)>=3):return False
        return True
    def observer(x,z,dx,dz):
        views=[]
        for vz in range(max(0,z-4),min(h,z+5)):
            for vx in range(max(0,x-4),min(w,x+5)):
                if not empty(vx,vz):continue
                ox,oz=vx-x,vz-z
                length=math.hypot(ox,oz)
                if length<2 or length>4.3:continue
                alignment=(-dx*ox-dz*oz)/length
                if alignment<.5:continue
                if min((math.hypot(vx-a,vz-b) for a,b in occupied),default=8)<1.2:continue
                if not clear_ray((x-dx*.1,z-dz*.1),(vx,vz)):continue
                views.append((alignment-.05*abs(length-3),{'x':vx,'z':vz,'distance':round(length,3),'alignment':round(alignment,3)}))
        return max(views,key=lambda v:v[0])[1] if views else None
    result=[]
    for z in range(1,h-1):
        for x in range(1,len(grid[z])-1):
            if not empty(x,z):continue
            for dx,dz,angle in [(-1,0,90),(1,0,270),(0,-1,0),(0,1,180)]:
                # Three adjacent floor cells fit the 2.68m screen along its wall.
                tx,tz=-dz,dx
                if not wall(x+dx,z+dz):continue
                if not all(empty(x+tx*j,z+tz*j) for j in (-1,1)):continue
                # A standing visitor needs a real floor cell and clear sightline.
                # A narrow gallery can supply a view at up to 60 degrees rather
                # than requiring new floor across its deliberately open void.
                view=observer(x,z,dx,dz)
                if view is None:continue
                distance=min((math.hypot(x-a,z-b) for a,b in occupied),default=8)
                if distance<2.2:continue
                score=min(distance,6)-.018*abs(z-h*.4)-(.4 if z<4 or z>h-5 else 0)-(1-view['alignment'])
                result.append({'x':x,'z':z,'rotation':angle,'score':round(score,3),'observer':view})
    return sorted(result,key=lambda d:-d['score'])

def build(place=False,only=None):
    entries=manifests()
    assert len({e['id'] for e in entries})==len(entries)
    declared=halls.declared()
    for entry in entries:
        assert entry['map'] in [p[1] for p in declared.get(entry['sequence'],[])], 'Not an authored spine hall: '+entry['id']
        for resource in [entry['scene'],*entry.get('source_paths',[])]:
            assert (ROOT/resource.removeprefix('res://')).is_file(), 'Missing film resource: '+resource
    registry={'artifacts':{}}
    monitors=BASE/'monitors';monitors.mkdir(parents=True,exist_ok=True)
    for e in entries:
        name='film_'+e['id']
        e['lookup']=name
        e['monitor_scene']='res://commons/artifacts/spine_films/monitors/'+name+'.tscn'
        monitor_script='res://commons/artifacts/spine_films/foundation_monitor.gd' if e.get('collection')=='foundation' else 'res://commons/artifacts/concept_monitor/concept_monitor.gd'
        text='[gd_scene load_steps=3 format=3]\n[ext_resource type="Script" path="'+monitor_script+'" id="1"]\n[ext_resource type="PackedScene" path="'+e['scene']+'" id="2"]\n[node name="'+name+'" type="Node3D"]\nscript = ExtResource("1")\nconcept_scene = ExtResource("2")\nnext_caption = "TURN VIEW"\n'
        (monitors/(name+'.tscn')).write_text(text,encoding='utf-8')
        registry['artifacts'][name]={'lookup_name':name,'name':e['title'],'scene':e['monitor_scene'],'description':e['description'],'map_ready':True,'include_in_map_data':True,'auto_ground':False,'footprint':[2.7,2.6,.55],'category':'education','map_sequences':[e['sequence']],'tags':['monitor','process','film',e['sequence']],'interactions':['Look at the screen to play.','Pause, replay, step or turn the view.'],'qfep_connection':e.get('limitation','A source-based construction shown in time.')}
        if e.get('collection')=='foundation':
            registry['artifacts'][name]['tags'].append('interactive-study')
            registry['artifacts'][name]['interactions'].extend([
                'Use the lower row to try the model; the demonstration pauses.',
                'Your choices remain when you look away. DEMO returns to the demonstration.'])
    write(ROOT/'commons/artifacts/registry/spine_films.json',registry)
    write(BASE/'catalog.json',entries)
    write(OUT/'catalog.json',entries)
    if not place:return entries
    plans={p:read(ROOT/p) for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']}
    placed=[]
    unplaced=[]
    original_plans=copy.deepcopy(plans)
    for dest,plan in plans.items():
        full_backup=OUT/'backups'/('active-plan-before.json' if dest.startswith('ada_run') else 'shipped-plan-before.json')
        if not full_backup.exists():write(full_backup,plan)
    overrides=read(RUN/'placement-overrides.json') if (RUN/'placement-overrides.json').exists() else {}
    for e in entries:
        if only and e['id'] not in only:continue
        p=ROOT/'commons/maps'/e['map']/'map_data.json'
        data=read(p)
        old=copy.deepcopy(data)
        backup=OUT/'backups'/e['map']/'map.json'
        if not backup.exists():write(backup,data)
        before_films=read(backup)
        prior=None
        for z,row in enumerate(data['layers']['interactables']):
            for x,v in enumerate(row):
                if str(v).startswith(e['lookup']+':'):
                    prior={'x':x,'z':z,'rotation':int(str(v).split(':')[1])}
                    rows=before_films['layers']['interactables']
                    original_cell=rows[z][x] if z<len(rows) and x<len(rows[z]) else ''
                    data['layers']['interactables'][z][x]=original_cell if str(original_cell).strip() in ('','0') else ''
        options=candidates(data,e['lookup'])
        write(OUT/'backups'/e['map']/'placement-options.json',options)
        kept=next((o for o in options if prior and all(o[k]==prior[k] for k in ('x','z','rotation'))),None)
        choice=overrides.get(e['id'],kept or (options[0] if options else None))
        if choice is None:
            unplaced.append({'id':e['id'],'map':e['map'],'reason':'No clear wall candidate with a 2.68 m screen footprint and a supported, unobstructed standing view. Existing geometry was preserved.'})
            continue
        x,z,angle=choice['x'],choice['z'],choice['rotation']
        # Sparse authored layers may stop before the room's outer floor cells.
        # Extend only the selected row with empty cells; retain every artifact.
        while len(data['layers']['interactables'])<=z:data['layers']['interactables'].append([])
        while len(data['layers']['interactables'][z])<=x:data['layers']['interactables'][z].append('')
        if choice.get('observer'):
            view=choice['observer']
            radians=math.radians(angle)
            vx,vz=view['x']-x,view['z']-z
            # Relative to LiveScreen, expressed in monitor-local axes. This is
            # a standing eye at 1.65 m; the screen centre is 1.72 m, z=0.087.
            choice['view_offset']=[round(math.cos(radians)*vx-math.sin(radians)*vz,4),-.07,
                                   round(math.sin(radians)*vx+math.cos(radians)*vz-.087,4)]
        assert str(data['layers']['interactables'][z][x]).strip() in ('','0')
        # `pin` is a museum dress key but is not a numeric Grid config key.
        # Numeric #pin:1 is parsed there as a tutorial shorthand and silently
        # replaces the requested yaw with one degree. The explicit boolean
        # preserves the same museum pin while leaving the authored yaw intact.
        token=f"{e['lookup']}:{angle}:0#plinth:0#pin:true"
        if choice.get('offset'):token+='#offset:'+choice['offset']
        data['layers']['interactables'][z][x]=token
        data['map_info'].setdefault('metadata',{})['n_artifacts']=sum(str(v).strip() not in ('','0') for r in data['layers']['interactables'] for v in r)
        old_items=[v for r in old['layers']['interactables'] for v in r if str(v).strip() not in ('','0') and not str(v).startswith(e['lookup']+':')]
        new_items=[v for r in data['layers']['interactables'] for v in r if str(v).strip() not in ('','0') and not str(v).startswith(e['lookup']+':')]
        assert old_items==new_items
        write(p,data)
        pairs=halls.declared()[e['sequence']]
        index=next(i for i,pair in enumerate(pairs) if pair[1]==e['map'])
        for dest,plan in plans.items():
            row=find_row(plan,e['map'])
            if row is None:raise RuntimeError('Missing museum row '+dest+' '+e['map'])
            backup=OUT/'backups'/e['map']/('active-row.json' if dest.startswith('ada_run') else 'shipped-row.json')
            if not backup.exists():write(backup,row)
            # Keep existing room, offsets, artifact configs and all layout data;
            # take only the new artifact entry from the authored map derivation.
            derived=halls.derive_row(row['pearl'],e['map'],row['museum'],index,len(pairs),e['sequence'])
            addition=next(a for a in derived['artifacts'] if e['lookup'] in str(a))
            row['artifacts']=[a for a in row['artifacts'] if e['lookup'] not in str(a)]+[addition]
        placed.append({**e,**choice,'existing_artifacts_preserved':True})
    def without_films(value):
        if isinstance(value,dict):
            return {k:[without_films(a) for a in v if not str(a.get('token','')).startswith('film_')]
                    if k=='artifacts' and isinstance(v,list) else without_films(v) for k,v in value.items()}
        if isinstance(value,list):return [without_films(v) for v in value]
        return value
    for dest,plan in plans.items():
        assert without_films(plan)==without_films(original_plans[dest]), 'Existing plan content changed: '+dest
        write(ROOT/dest,plan)
    old_placed=read(OUT/'placements.json') if (OUT/'placements.json').exists() else []
    ids={p['id'] for p in placed}
    write(OUT/'placements.json',[p for p in old_placed if p['id'] not in ids]+placed)
    write(OUT/'placement-issues.json',unplaced)
    print('Monitors placed:',len(placed),'unplaced:',len(unplaced))
    for issue in unplaced:print('UNPLACED:',issue['map'],'—',issue['reason'])
    return entries

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--place',action='store_true')
    parser.add_argument('--only',nargs='+')
    args=parser.parse_args()
    data=build(args.place,set(args.only) if args.only else None)
    print('Films assembled:',len(data))
