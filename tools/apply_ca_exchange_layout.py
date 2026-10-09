"""Preserve the comparison; fit the four secondary works around a level route."""
from pathlib import Path
import copy,json
import em_map_halls
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers'
p=R/'commons/maps/CA_SoftRules/map_data.json'
assert p.read_bytes()==(O/'before/map_data.json').read_bytes()
d=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(d);a=d['layers']['interactables']
for z in range(16,25):
 for x in range(1,16):d['layers']['structure'][z][x]='1'
for x,z in [(10,17),(4,20),(1,24),(3,24)]:a[z][x]=''
a[18][12]='lattice_gas_pump'
a[22][3]='ca_sphere:90:1.1'
a[18][3]='crack_propagation_ca:0:1.2:0.35'
a[22][12]='rule_30_110_gravity:0:2.6:0.3#host_lighting:1'
assert sorted(v.split(':')[0] for row in a for v in row if v.strip())==sorted(v.split(':')[0] for row in old['layers']['interactables'] for v in row if v.strip())
d['map_info']['museum'].update(gate=False,portal_entry={'cage':False},portal_exit={'approach':'from_hall'},sculpture_clear_rects=[[1,1,15,24]])
u=d['layers']['utilities'];assert u[1][8]=='sp' and u[24][8]=='t'
u[1][8]='';u[0][8]='sp';u[24][8]='';u[25][8]='t'
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';plan=json.loads(p.read_text(encoding='utf-8'));before=copy.deepcopy(plan)
i=next(i for i,row in enumerate(plan['plans']) if row['map']=='CA_SoftRules');row=plan['plans'][i]
(O/'before/plan-row.json').write_text(json.dumps(row,indent=2),encoding='utf-8')
new=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence']);em_map_halls.normalize_row(new,True,False)
plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(before['plans'],plan['plans'])) if j!=i)
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'))
(O/'after').mkdir(exist_ok=True);(O/'after/plan-row.json').write_text(json.dumps(new,indent=2),encoding='utf-8')
print('Six works retained; comparison preserved; rear level; secondary works fitted; threshold portals.')
