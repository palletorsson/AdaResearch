"""Keep all three placed works; clear the approach and use threshold portals."""
from pathlib import Path
import copy,json
import em_map_halls
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-08-ca-two-ways-to-make'
p=R/'commons/maps/CA_AgentsCircuits/map_data.json';assert p.read_bytes()==(O/'before/map_data.json').read_bytes()
d=json.loads(p.read_text(encoding='utf-8'));a=copy.deepcopy(d['layers']['interactables'])
d['map_info']['museum'].update(gate=False,portal_entry={'cage':False},portal_exit={'approach':'from_hall'},sculpture_clear_rects=[[1,1,11,16]])
u=d['layers']['utilities'];assert u[1][6]=='s' and u[16][6]=='t'
u[1][6]='';u[0][6]='s';u[16][6]='';u[17][6]='t'
assert a==d['layers']['interactables']
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';plan=json.loads(p.read_text(encoding='utf-8'));before=copy.deepcopy(plan)
i=next(i for i,row in enumerate(plan['plans']) if row['map']=='CA_AgentsCircuits');row=plan['plans'][i]
(O/'before/plan-row.json').write_text(json.dumps(row,indent=2),encoding='utf-8')
new=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence']);em_map_halls.normalize_row(new,True,False);plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(before['plans'],plan['plans'])) if j!=i)
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'));(O/'after').mkdir(exist_ok=True);(O/'after/plan-row.json').write_text(json.dumps(new,indent=2),encoding='utf-8')
print('All authored placements and floor retained; incidental sculpture cleared; threshold portals.')
