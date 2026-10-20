"""Three metres between ramp heads, with existing upright prism blockers."""
from pathlib import Path
import copy,json,re,sys
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
# Rebuild only the crossing. The platform runs x=8..10: its edges are exactly
# three metres apart. The east ramp and east corridor move one cell inward.
for z in range(26,32):
    for x in range(2,18):s[z][x]='1'
for x in range(6,13):s[26][x]='w'
for x in range(2,18):s[29][x]='w'
for z in range(27,31):
    for x in range(8,11):s[z][x]='2'
for z in range(29,32):s[z][7]='w';s[z][11]='w'
for z in [27,28]:
    u[z][12]=' ';u[z][11]='wp:270'
# Three adjacent units keep the far descent centred on the narrower landing.
for x in range(8,11):u[31][x]='wp:180'
sign=a[25][9];double=a[25][10];ahead=a[26][15]
a[25][9]=' ';a[25][8]=sign+'#offset:0.5,0,0'
a[25][10]=' ';a[25][9]=double+'#offset:0.5,0,0'
a[26][15]=' ';a[26][14]=ahead
# A solid two-metre standing prism at each mouth: triangular end towards the
# entering body, rather than the climbable longitudinal face of the wp ramp.
for x in [5,13]:a[24][x]='prism_block:0:0:2#grain:solid#plinth:0#pin:1'
d['layers']['museum']=copy.deepcopy(s)
d['map_info']['description']='Upright prism stoppers redirect the walk before two symmetric wp approaches. Their upper ends are separated by a three-metre structure-2 landing. STOP and arrows mark the route; the far descent leads to the basin and rock side room.'
d['map_info']['metadata']['n_artifacts']=sum(bool(str(t).strip()) and str(t)!='0' for row in a for t in row)
write(ROOT/path,d)
p=ROOT/'commons/data/museum/em_plan.json';plan=read(p)
count=0
for i,row in enumerate(plan['plans']):
    if row.get('map')!='Primitives_Polythedra' or row.get('sequence')!='primitives':continue
    new=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'primitives')
    new['_ruling']={'src_w':len(new['tile'][0]),'src_h':len(new['tile']),'rotated':False,'pad':0,'pad_closed':False,'ring':None}
    plan['plans'][i]=new;count+=1
assert count==1
write(p,plan)
print('Polythedra: 3m landing, two standing prism stoppers, seven wp units.')
