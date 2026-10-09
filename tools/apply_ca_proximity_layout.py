"""Fit this hall's seven works and preserve the primary basin and rule."""
from pathlib import Path
import copy,json
import em_map_halls
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-the-surface-includes-you'
p=R/'commons/maps/CA_ExpandingSpace/map_data.json'
assert p.read_bytes()==(O/'before/map_data.json').read_bytes()
d=json.loads(p.read_text(encoding='utf-8')); layers=d['layers'];a=layers['interactables']
before=copy.deepcopy(d)
for z in range(18,27):
 for x in range(1,14):layers['structure'][z][x]='1'
for x,z in [(4,20),(6,20),(1,21),(3,21),(4,22),(3,26)]:a[z][x]=''
a[19][1]='ca_chair_test:0:0:0.12#host_lighting:1'
a[18][9]='crossway_ca:0:0.8:0.25'
a[24][3]='dark_sphere'
a[25][1]='catalyst_prompter_box:0:0#emergence:doors#sequence:auto#lease_s:45'
a[24][9]='catalyst_vent:0:0#emit_interval_s:2.5#wave_size:3#start_delay_s:5.0#sequence:auto'
a[25][12]='cellular_automata_3d_tree:0:0:0.35#host_lighting:1'
assert sorted(v.split(':')[0] for row in a for v in row if v.strip())==sorted(v.split(':')[0] for row in before['layers']['interactables'] for v in row if v.strip())
m=d['map_info']['museum'];m.update(gate=False,portal_entry={'cage':False},portal_exit={'approach':'from_hall'},sculpture_clear_rects=[[1,1,13,26]])
u=layers['utilities'];assert u[1][6]=='sp' and u[26][6]=='t'
u[1][6]='';u[0][6]='sp';u[26][6]='';u[27][6]='t'
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=1)+'\n').encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';plan=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(plan)
i=next(i for i,r in enumerate(plan['plans']) if r['map']=='CA_ExpandingSpace');row=plan['plans'][i]
(O/'before/plan-row.json').write_text(json.dumps(row,indent=2),encoding='utf-8')
new=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
em_map_halls.normalize_row(new,True,False);plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(old['plans'],plan['plans'])) if j!=i)
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'))
(O/'after').mkdir(exist_ok=True)
(O/'after/plan-row.json').write_text(json.dumps(new,indent=2),encoding='utf-8')
print('One hall: seven works retained; primary basin preserved; rear level; threshold portals.')
