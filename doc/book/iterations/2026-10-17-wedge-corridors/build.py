"""Scoped map revision; the before snapshot is the baseline for this trial."""
from pathlib import Path
import copy, json, re, sys
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):
    text=json.dumps(d,indent=2,ensure_ascii=False)+'\n'
    if p.name=='map_data.json':
        text=re.sub(r'\[\n((?:\s+"[^"\n]*",?\n)+)\s+\]',lambda m:'['+', '.join(line.strip().rstrip(',') for line in m[1].splitlines())+']',text)
    p.write_text(text,encoding='utf-8')

name='Primitives_Polythedra'
path=Path('commons/maps')/name/'map_data.json'
d=read(HERE/'before'/path)
s=d['layers']['structure']; u=d['layers']['utilities']; a=d['layers']['interactables']
# Numeric 2 now means a one-metre rise. Existing rock enclosure stays a wall.
for row in s:
    for x,v in enumerate(row):
        if v=='2': row[x]='w'
d['map_info']['museum']['wall_height']=3
# Symmetric approaches between a front baffle and a full cross-hall divider.
# The only ordinary walking connection to the far room is over the platform.
for x in range(6,14): s[26][x]='w'
for x in range(2,18): s[29][x]='w'
for z in range(27,31):
    for x in range(8,12): s[z][x]='2'
for z in range(29,32):
    s[z][7]='w'; s[z][12]='w'
for x in [8,11]: s[31][x]='w'
# Each 2m-wide approach consists of two adjacent stock 1m-wide wp prisms.
for z in [27,28]:
    u[z][7]='wp:90';u[z][12]='wp:270'
for x in [9,10]: u[31][x]='wp:180'
# Move the rock-room doorway beyond the crossing, closing the side-room bypass.
for z in [25,26,27]: s[z][18]='w'
for z in [34,35,36]: s[z][18]='1'
a[28][9]='wedge_palace:0:0#layout:map#plinth:0#pin:1'
sign='street_sign:180:0#pole_height:1.65#sign_radius:0.32#subtext:#plinth:0#pin:1'
a[25][9]=sign
a[25][10]=sign+'#direction:both#sign_sides:32#sign_color:0.08,0.28,0.50'
# Simple arrows beside the approaches; the ramp mouths remain clear.
for x in [4,15]:
    a[26][x]=sign+'#direction:ahead#sign_sides:32#sign_color:0.08,0.28,0.50'
d['layers']['museum']=copy.deepcopy(s)
d['map_info']['description']='Align a tetrahedron and a wedge; meet a corner, then follow symmetric walled wp approaches onto a structure-2 platform. STOP and arrows mark the route. Descend toward the floored basin; the rock side room opens beyond the crossing.'
d['map_info']['metadata']['n_artifacts']=sum(bool(str(t).strip()) and str(t)!='0' for row in a for t in row)
write(ROOT/path,d)
p=ROOT/'commons/data/museum/em_plan.json';plan=read(p)
changed=0
for i,row in enumerate(plan['plans']):
    if row.get('map')!=name or row.get('sequence')!='primitives':continue
    new=derive_row(row['pearl'],name,row['museum'],row['pearl_index'],row['pearls_total'],'primitives')
    new['_ruling']={'src_w':len(new['tile'][0]),'src_h':len(new['tile']),'rotated':False,'pad':0,'pad_closed':False,'ring':None}
    plan['plans'][i]=new;changed+=1
assert changed==1,changed
write(p,plan)
print('Updated Polythedra only: 16 raised cells, six stock wp wedges, four signs.')
