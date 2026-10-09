"""Keep the already level comparison room; make its thresholds explicit."""
from pathlib import Path
import copy,json
import em_map_halls
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-08-ca-what-a-difference-keeps'
p=R/'commons/maps/CA_EdgeOfChaos/map_data.json';assert p.read_bytes()==(O/'before/map_data.json').read_bytes()
d=json.loads(p.read_text(encoding='utf-8'));before=copy.deepcopy(d)
d['map_info']['museum'].update(gate=False,portal_entry={'cage':False},portal_exit={'approach':'from_hall'})
u=d['layers']['utilities'];assert u[1][9]=='sp' and u[28][9]=='t'
u[1][9]='';u[0][9]='sp';u[28][9]='';u[29][9]='t'
assert d['layers']['structure']==before['layers']['structure'] and d['layers']['interactables']==before['layers']['interactables']
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';plan=json.loads(p.read_text(encoding='utf-8'));before=copy.deepcopy(plan)
i=next(i for i,row in enumerate(plan['plans']) if row['map']=='CA_EdgeOfChaos');row=plan['plans'][i]
(O/'before/plan-row.json').write_text(json.dumps(row,indent=2),encoding='utf-8')
new=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence']);em_map_halls.normalize_row(new,True,False);plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(before['plans'],plan['plans'])) if j!=i)
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'));(O/'after').mkdir(exist_ok=True);(O/'after/plan-row.json').write_text(json.dumps(new,indent=2),encoding='utf-8')
print('Five placements and level floor retained; entry/exit at thresholds.')
