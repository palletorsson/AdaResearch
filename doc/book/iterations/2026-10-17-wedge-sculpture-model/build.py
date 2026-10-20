"""Add two independent artifacts, preserving the previous route and other halls."""
from pathlib import Path
import copy, json, re, shutil, sys
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
MAP=ROOT/'commons/maps/Primitives_Polythedra'
paths=[MAP/n for n in ['map_data.json','final.md','tutorial.md','technical.md','summary.md','artifacts.md','intent.md']]
paths += [ROOT/'commons/data/museum/em_plan.json', ROOT/'commons/artifacts/registry/primitive_encounters.json']
for p in paths:
    dest=HERE/'before'/p.relative_to(ROOT)
    if not dest.exists():
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
(HERE/'before/.gdignore').touch()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):
    s=json.dumps(d,indent=2,ensure_ascii=False)+'\n'
    if p.name=='map_data.json':s=re.sub(r'\[\n((?:\s+"[^"\n]*",?\n)+)\s+\]',lambda m:'['+', '.join(x.strip().rstrip(',') for x in m[1].splitlines())+']',s)
    p.write_text(s,encoding='utf-8')
d=read(MAP/'map_data.json')
d['layers']['interactables'][32][6]='wedge_column:0:0#offset:0.5,0,0#plinth:0#pin:1'
d['layers']['interactables'][32][13]='wedge_mouse_model:0:0#plinth:0#pin:1'
d['map_info']['description']='Walk around standing wedges, climb side wp ramps, and encounter the same prisms as a sculpture on the platform. A small rearrangeable wedge-mouse model on a plinth tests obstruction, support and a jump towards cheese. The basin and rock room follow.'
d['map_info']['metadata']['n_artifacts']=sum(bool(t.strip()) and t!='0' for row in d['layers']['interactables'] for t in row)
write(MAP/'map_data.json',d)
p=ROOT/'commons/artifacts/registry/primitive_encounters.json';reg=read(p)
for key,name,description in [
    ('wedge_column','Same wedges / sculptural column','Six original prism_block scenes paired into three diamond modules. Fixed joints let the same geometry become sculpture after obstruction and ascent.'),
    ('wedge_mouse_model','Wedge mouse / a route on a plinth','Move and turn small wedges to change a brown wedge mouse\'s course. Complementary wedges form a platform, a sloping wedge supports ascent, and a physical jump aims towards a cheese wedge.')]:
    reg['artifacts'][key]={'lookup_name':key,'name':name,'scene':f'res://commons/artifacts/primitive_encounters/{key}.tscn','map_ready':True,'description':description,'category':'primitives','tags':['wedge','configuration','sculpture','support','path'],'complexity':'beginner','qfep_connection':'A form acquires capacities through arrangement and its relation to another body: obstruction, support, silhouette and access.'}
write(p,reg)
p=ROOT/'commons/data/museum/em_plan.json';plan=read(p);count=0
for i,row in enumerate(plan['plans']):
    if row.get('map')!='Primitives_Polythedra' or row.get('sequence')!='primitives':continue
    fresh=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'primitives')
    fresh['_ruling']={'src_w':len(fresh['tile'][0]),'src_h':len(fresh['tile']),'rotated':False,'pad':0,'pad_closed':False,'ring':None}
    plan['plans'][i]=fresh;count+=1
assert count==1
write(p,plan)
print('Platform: sculpture at (6.5,32); model at (13,32). Existing route retained.')
