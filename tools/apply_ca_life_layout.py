"""Open this hall's rear gallery without changing its six authored algorithms."""
from pathlib import Path
import copy,json
import em_map_halls
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-pattern-visits'
p=R/'commons/maps/CA_BeyondBinary/map_data.json'
assert p.read_bytes()==(O/'before/map_data.json').read_bytes(), 'One-shot layout: inspect instead of overwriting later work.'
d=json.loads(p.read_text(encoding='utf-8')); layers=d['layers']; a=layers['interactables']
for z in range(20,26):
 for x in range(1,14):layers['structure'][z][x]='1'
for x,z in [(1,21),(6,22),(4,23),(3,25)]:a[z][x]=''
a[20][2]='mold_network:0:0:0.4'
a[19][1]='science_screen:90:1.5'
a[21][6]='dark_sphere'
a[24][3]='ca_growth_network:0:1.3:0.35'
for row in a:
 for x,v in enumerate(row):
  if v and not v.strip():row[x]=''
before=json.loads((O/'before/map_data.json').read_text(encoding='utf-8'))
assert sorted(v.split(':')[0] for row in a for v in row if v.strip())==sorted(v.split(':')[0] for row in before['layers']['interactables'] for v in row if v.strip())
m=d['map_info']['museum'];m.update(gate=False,portal_entry={'cage':False},portal_exit={'approach':'from_hall'},sculpture_clear_rects=[[1,1,13,25]])
u=layers['utilities'];assert u[1][6]=='sp' and u[25][6]=='t'
u[1][6]='';u[0][6]='sp';u[25][6]='';u[26][6]='t'
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=1)+'\n').encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';plan=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(plan)
i=next(i for i,r in enumerate(plan['plans']) if r['map']=='CA_BeyondBinary');row=plan['plans'][i]
(O/'before/plan-row.json').write_text(json.dumps(row,indent=2),encoding='utf-8')
new=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
em_map_halls.normalize_row(new,True,False);plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(old['plans'],plan['plans'])) if j!=i)
assert all(old[k]==plan[k] for k in plan if k!='plans')
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'))
(O/'after').mkdir(exist_ok=True)
(O/'after/plan-row.json').write_text(json.dumps(new,indent=2),encoding='utf-8')
print('CA_BeyondBinary only: level rear gallery; six authored works kept; other plan rows preserved.')
