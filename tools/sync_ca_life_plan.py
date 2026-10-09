"""Reconcile only the verified Life row after shared-plan refreshes."""
from pathlib import Path
import copy,json
import em_map_halls
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-a-pattern-visits'
p=R/'commons/data/museum/em_plan.json';raw=p.read_bytes();d=json.loads(raw);old=copy.deepcopy(d)
i=next(i for i,r in enumerate(d['plans']) if r['map']=='CA_BeyondBinary');r=d['plans'][i]
n=em_map_halls.derive_row(r['pearl'],r['map'],r['museum'],r['pearl_index'],r['pearls_total'],r['sequence']);em_map_halls.normalize_row(n,True,False)
tested=json.loads((O/'after/plan-row.json').read_text(encoding='utf-8'))
assert n==tested,'Map differs from this pass\'s staged row; inspect before syncing.'
# The museum rederives geometry from map_data at runtime, even when the cache is stale.
inventory=json.loads((O/'museum/report.json').read_text(encoding='utf-8'))['observations']['inventory']
for token,at in {'game_of_life_petri':[6.5,0,8.5],'science_screen':[1.5,1.5,23.5],'mold_network':[2.5,0,24.5],'dark_sphere':[6.5,0,25.5],'hexagon_ca_vr':[9.5,0,27.5],'ca_growth_network':[3.5,1.3,28.5]}.items():
 found=next(v for v in inventory if v['key']==token)
 assert all(abs(a-b)<.001 for a,b in zip(found['local'],at)),(token,found)
d['plans'][i]=n
assert all(a==b for j,(a,b) in enumerate(zip(old['plans'],d['plans'])) if j!=i)
assert all(old[k]==d[k] for k in d if k!='plans')
assert p.read_bytes()==raw,'Shared plan changed during reconciliation; retry from fresh read.'
p.write_bytes(json.dumps(d,ensure_ascii=False).encode('utf-8'))
after=json.loads(p.read_text(encoding='utf-8'));assert after==d
(O/'plan-checks.json').write_text(json.dumps({'map_matches_staged_plan':True,'captured_artifact_positions_match':True,'other_rows_preserved':True,'map':'CA_BeyondBinary'},indent=2),encoding='utf-8')
print('Current map, live plan and tested room agree; all other current rows retained.')
