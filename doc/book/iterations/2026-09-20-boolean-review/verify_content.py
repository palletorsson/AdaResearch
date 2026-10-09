"""Check this pass's integration and retained evidence without starting another broad audit."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
checks=[]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok,why): checks.append({'passed':bool(ok),'check':why})
seq=['Boolean_Verbs','Boolean_Gallery','Boolean_Works']
check(read(ROOT/'commons/maps/sequences/boolean_surfaces.json')['sequences']['boolean_surfaces']['maps']==seq,'Declared order retained')
check(read(ROOT/'commons/data/map_authored.json')['boolean_surfaces']==seq,'Authored route retained')
for path in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
    old=read(HERE/'before'/path)['plans'];new=read(ROOT/path)['plans']
    check([r for r in old if r.get('map') not in ['Boolean_Verbs','Boolean_Works']]==[r for r in new if r.get('map') not in ['Boolean_Verbs','Boolean_Works']],path+': all other rows preserved')
    check([r['map'] for r in new if r.get('sequence')=='boolean_surfaces']==seq,path+': order agrees')
for path,key in [('commons/data/long_museum.json','segments'),('commons/data/museum_order_effective.json','halls')]:
    check([r['name'] for r in read(ROOT/path)[key] if r.get('sequence')=='boolean_surfaces' and r.get('kind','hall')=='hall']==seq,path+': derived order agrees')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms']
roles=read(ROOT/'commons/data/artifact_roles.json')
for m in seq:
    rel=Path('commons/maps')/m
    old=read(HERE/'before'/rel/'map_data.json');new=read(ROOT/rel/'map_data.json')
    def tokens(d): return {c.split('#')[0].split(':')[0] for row in d['layers']['interactables'] for c in row if c.strip() not in ('','0')}
    check(tokens(old)==tokens(new),m+': original artifact families retained')
    check(core[m]['text_sha256']==hashlib.sha256((ROOT/rel/'final.md').read_bytes()).hexdigest(),m+': current text reference')
    check(core[m]['map_sha256']==hashlib.sha256((ROOT/rel/'map_data.json').read_bytes()).hexdigest(),m+': current map reference')
check((ROOT/'commons/maps/Boolean_Gallery/map_data.json').read_bytes()==(HERE/'before/commons/maps/Boolean_Gallery/map_data.json').read_bytes(),'All 24 Gallery placements preserved byte-for-byte')
check(roles['roles']['Boolean_Works']['boolean_burrow']=='primary','Burrow promoted')
check(roles['order']['Boolean_Works']['primary']==core['Boolean_Works']['primary_tokens'],'Primary order agrees')
book=read(ROOT/'commons/data/book/boolean_surfaces.json')
check(any(r['token']=='boolean_burrow' for p in book['pearls'] if p.get('map')=='Boolean_Works' for r in p['lines']),'Burrow is in book index')
check('<!-- @boolean_burrow -->' in (ROOT/'commons/maps/Boolean_Works/final.md').read_text(encoding='utf-8'),'Burrow has a book encounter')
before=read(HERE/'baseline-runtime.json')['burrow'];after=read(HERE/'after-runtime.json')['burrow']
check(not before['all_six_reached'] and before['journey'][-1]['step']==2,'Original path stops at third hollow')
check(before['centres']==after['centres'],'Seeded centres unchanged')
check(before['graph']['components']==after['graph']['components']==1,'Same overlap component count')
check(before['graph']['cycles']==after['graph']['cycles'],'Same graph cycle count')
check(after['all_six_reached'],'Six inward waypoints passed')
check(len(after['return'])==6 and all(r['passed'] for r in after['return']),'Six return waypoints passed')
check(after['wall_stops_body'],'Intact stock wall blocks body')
check(all(r['passed'] for r in read(HERE/'after-runtime.json')['walks']),'Gallery bypass and original visual wall crossing passed')
labels=[l['text'] for a in read(HERE/'verbs-runtime.json')['artifacts'] if a['token']=='csg_intersection_demo' for l in a['labels']]
check(any('|A|' in l and '|B|' in l and '|A ∩ B|' in l for l in labels),'Intersection volume readout present in actual hall')
check(not read(HERE/'after-runtime.json')['failures'] and not read(HERE/'verbs-runtime.json')['failures'],'Relevant runtime reports pass')
result={'count':len(checks),'checks':checks,'failures':[r['check'] for r in checks if not r['passed']]}
(HERE/'content-checks.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'checks':len(checks),'failures':result['failures']}))
raise SystemExit(bool(result['failures']))
