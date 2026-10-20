"""Two successive grid encounters: central blockers, then side ramps."""
from pathlib import Path
import json,copy,re,sys
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):
    text=json.dumps(d,indent=2,ensure_ascii=False)+'\n'
    if p.name=='map_data.json':text=re.sub(r'\[\n((?:\s+"[^"\n]*",?\n)+)\s+\]',lambda m:'['+', '.join(line.strip().rstrip(',') for line in m[1].splitlines())+']',text)
    p.write_text(text,encoding='utf-8')
path=Path('commons/maps/Primitives_Polythedra/map_data.json')
d=read(HERE/'before'/path);s=d['layers']['structure'];u=d['layers']['utilities'];a=d['layers']['interactables']
# Clear only the prior crossing, keeping the opening works, basin and side room.
for z in range(23,35):
    for x in range(2,18):
        s[z][x]='1'
        if u[z][x].startswith('wp:'):u[z][x]=' '
        if a[z][x].split(':')[0] in ['prism_block','street_sign','wedge_palace']:a[z][x]=' '
# Five two-cell prisms occupy an exact 10 x 2-cell central bank. Their centres
# sit at the centre of each 2x2 footprint, rather than straddling grid borders.
for x in [5,7,9,11,13]:
    a[24][x]='prism_block:0:0:2#grain:solid#offset:0.5,0,0.5#plinth:0#pin:1'
# Three clear columns per side: west 2..4, east 15..17.
# Short inner walls hold the forward-facing side ramps after the bank.
for z in range(27,30):s[z][5]='w';s[z][14]='w'
for x in [2,3,4,15,16,17]:u[29][x]='wp:0'
# One broad structure-2 landing, followed by a centred return to the floor.
for z in range(30,33):
    for x in range(2,18):s[z][x]='2'
for x in [8,9,10,11]:u[33][x]='wp:180'
a[31][9]='wedge_palace:0:0#layout:map#plinth:0#pin:1'
sign='street_sign:180:0#pole_height:1.65#sign_radius:0.32#subtext:#plinth:0#pin:1'
a[23][9]=sign
a[23][10]=sign+'#direction:both#sign_sides:32#sign_color:0.08,0.28,0.50'
for x in [3,16]:a[26][x]=sign+'#direction:ahead#sign_sides:32#sign_color:0.08,0.28,0.50'
d['layers']['museum']=copy.deepcopy(s)
d['map_info']['description']='First walk around a central grid-aligned bank of five standing wedge stoppers, with three-metre side passages. Then follow forward-facing wp ramps along both sides onto a broad structure-2 platform. Descend towards the floored basin and rock side room.'
d['map_info']['metadata']['n_artifacts']=sum(bool(t.strip()) and t!='0' for row in a for t in row)
write(ROOT/path,d)
p=ROOT/'commons/data/museum/em_plan.json';plan=read(p);n=0
for i,row in enumerate(plan['plans']):
    if row.get('map')!='Primitives_Polythedra' or row.get('sequence')!='primitives':continue
    fresh=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'primitives')
    fresh['_ruling']={'src_w':len(fresh['tile'][0]),'src_h':len(fresh['tile']),'rotated':False,'pad':0,'pad_closed':False,'ring':None}
    plan['plans'][i]=fresh;n+=1
assert n==1
write(p,plan)
print('Central bank: 5 wedges / 10x2 cells. Side passages: 3 cells. Side ramps: +Z. Landing: 16x3 cells.')
