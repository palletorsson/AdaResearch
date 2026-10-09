"""Open the rear history gallery; rederive only this hall's museum plan."""
from pathlib import Path
import copy,json,shutil
import em_map_halls
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-history-three-bodies'
p=R/'commons/maps/CA_GameOfLife/map_data.json'
assert p.read_bytes()==(O/'before/map_data.json').read_bytes()
d=json.loads(p.read_text(encoding='utf-8'));layers=d['layers']
for z in range(20,36):
 for x in range(1,14):layers['structure'][z][x]='1'
for x in range(10,14):layers['structure'][19][x]='1'
a=layers['interactables']
for old,new in [((5,25),(4,28)),((5,26),(8,28))]:
 x,z=old;xx,zz=new;assert a[z][x] and not a[zz][xx]
 a[zz][xx]=a[z][x];a[z][x]=''
m=d['map_info']['museum'];m['gate']=False
m['portal_entry']={'cage':False};m['portal_exit']={'approach':'from_hall'}
# Keep incidental sculptures out of this narrow rear circuit and the lab door.
m['sculpture_clear_rects']=[[1,1,13,35]]
u=layers['utilities'];assert u[1][6]=='sp' and u[35][6]=='t'
u[1][6]='';u[0][6]='sp';u[35][6]='';u[36][6]='t'
assert sorted(v for row in a for v in row if v)==sorted(v for row in json.loads((O/'before/map_data.json').read_text(encoding='utf-8'))['layers']['interactables'] for v in row if v)
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=1)+'\n').encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';plan=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(plan)
i=next(i for i,r in enumerate(plan['plans']) if r['map']=='CA_GameOfLife');row=plan['plans'][i]
new=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
em_map_halls.normalize_row(new,True,False);plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(old['plans'],plan['plans'])) if j!=i)
assert all(old[k]==plan[k] for k in plan if k!='plans')
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'));shutil.copy2(p,R/'commons/data/museum/em_plan.json')
(O/'after').mkdir(exist_ok=True)
(O/'after/plan-row.json').write_text(json.dumps(new,indent=2),encoding='utf-8')
print('One hall updated; all six authored artifacts retained; other plan rows preserved.')
