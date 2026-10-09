from pathlib import Path
import json, urllib.request, concurrent.futures, hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BASE='http://localhost:3003'
def fetch(path):
    with urllib.request.urlopen(BASE+path,timeout=60) as r:return r.read().decode('utf-8')
paths=['/book-review/doc/book/iterations/2026-10-06-primitives-feedback/index.html','/book-review/doc/book/iterations/2026-10-05-primitives-facing-pages/Primitives_Godot.html','/api/ghost-student','/api/tutorial-cards']
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    results=dict(zip(paths,pool.map(fetch,paths)))
assert 'Keep the lineage' in results[paths[0]]
assert 'Resolution as a construction parameter' in results[paths[1]]
ghost=json.loads(results[paths[2]])
states=ghost.get('states',ghost.get('manifest',{}).get('states',[]))
assert len(states)==14
statuses=[{'id':s['id'],'evidence':s.get('evidence',{}).get('status'),'sourceDrift':s.get('evidence',{}).get('sourceDrift')} for s in states]
assert all(s['evidence']=='current' and s['sourceDrift']==[] for s in statuses),statuses
cards=json.loads(results[paths[3]])
report={'http_pages_resolve':True,'ghost_states':statuses,'scope':'Publication checks. Printed-source/native validation is separate.'}
known='commons/maps/Point_Triangle_Context/map_data.json'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(ROOT/known)==sha(HERE/'before'/known)
report['whole_project_audit']={'passed':False,'existing_issue':known,'unchanged_in_this_pass':True,'reason':'Protected source differs from the older plan baseline; no matching recorded revision. Not a failure of the tutorial programs.'}
report['existing_final_blank_lines']={}
for hall in ['Primitives_Ignorance','Primitives_Melencolia','Primitives_Portals']:
    rel=f'commons/maps/{hall}/tutorial.md'
    before=(HERE/'before'/rel).read_text(encoding='utf-8')
    after=(ROOT/rel).read_text(encoding='utf-8')
    assert len(before)-len(before.rstrip())==len(after)-len(after.rstrip())
    report['existing_final_blank_lines'][hall]='Unchanged from the pre-review tutorial; no whitespace introduced by this prose review.'
(HERE/'publication-check.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('Pages served; all fourteen Ghost Student states current. Existing Triangle map audit issue recorded separately.')
