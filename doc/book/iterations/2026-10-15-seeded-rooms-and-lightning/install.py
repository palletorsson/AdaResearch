"""Apply the two local map edits and refresh only their derived museum rows."""
from pathlib import Path
import json, sys, copy
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row, normalize_row
HERE=Path(__file__).parent
targets=['Random_Remove','Random_Space_Geometry']
for name in targets:
    path=ROOT/'commons/maps'/name/'map_data.json'
    original=path.read_text(encoding='utf-8')
    backup=HERE/(name+'-before.json')
    if not backup.exists(): backup.write_text(original,encoding='utf-8')
    data=json.loads(original); layers=data['layers']; mus=data['map_info'].setdefault('museum',{})
    if name=='Random_Remove':
        for z in range(12,23):
            for x in range(1,16):layers['structure'][z][x]='0'
        layers['interactables'][17][8]='random_removal_arena:0:3#columns:15#rows:11#full_crossing:true#tesla_coils:true#plinth:0'
        data['map_info']['description']='Sampling without replacement becomes a wall-to-wall crossing: 165 floor tiles and one downward Tesla coil per tile. A warning precedes removal of real support. Replay restores the seeded order.'
    else:
        mus.update(artifact_placement='map',plinths=False,piers=False,wall_height=3,gate_depth_rows=0,open_roof=True)
        rects=mus.setdefault('sculpture_clear_rects',[])
        if [1,1,10,11] not in rects:rects.append([1,1,10,11])
        layers['interactables'][7][5]='seeded_room:0:0#seed:42#pin:true#plinth:0'
        if layers['utilities'][6][6]=='rg':layers['utilities'][6][6]=' '
        data['map_info']['description']='Enter an 8 by 8 seeded plan extruded into Y. A declared blue passage remains open. Flatten, raise, replay, or change the source, then compare neighbouring independent and Perlin samples on the existing bench.'
    rendered=json.dumps(data,indent=2,ensure_ascii=False)+'\n'
    # Keep the map's mixed indentation when only existing cells change.
    if name=='Random_Remove':
        old=backup.read_text(encoding='utf-8').splitlines()
        new=rendered.splitlines()
        if len(old)==len(new):
            rendered='\n'.join(a[:len(a)-len(a.lstrip())]+b.lstrip() for a,b in zip(old,new))+'\n'
            assert json.loads(rendered)==data
    path.write_text(rendered,encoding='utf-8')
path=ROOT/'commons/data/museum/em_plan.json'
plan=json.loads(path.read_text(encoding='utf-8')); before=copy.deepcopy(plan)
oldrows=[]
for i, row in enumerate(plan['plans']):
    if row.get('map') not in targets:continue
    oldrows.append(row)
    new=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
    normalize_row(new,True,any(k in new for k in ('basin','passage','simulation')))
    plan['plans'][i]=new
    print(row['map'],new['room'],len(new['artifacts']),'artifacts')
backup=HERE/'plan-rows-before.json'
if not backup.exists():backup.write_text(json.dumps(oldrows,indent=2),encoding='utf-8')
assert all(a==b for a,b in zip(before['plans'],plan['plans']) if a.get('map') not in targets)
path.write_text(json.dumps(plan,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
