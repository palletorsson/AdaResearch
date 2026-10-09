from pathlib import Path
import json, hashlib, difflib, re

base = Path(__file__).resolve().parent
repo = base.parents[4]
saved = json.loads((base / 'before-source-sha256.json').read_text(encoding='utf-8'))
owned = [
    'commons/maps/FormFinding_Annealing/map_data.json',
    'commons/artifacts/max_q_basin_room/max_q_basin_room.gd',
    'commons/artifacts/gradient_descent_optimizer/gradient_descent_optimizer.gd',
    'algorithms/optimization/simulatedannealing/simulated_annealing_visualization.gd',
    'commons/artifacts/impossible_end_table/impossible_end_table.gd',
]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def function(text, name):
    return re.search(r'^func '+re.escape(name)+r'\(.*?(?=^func |\Z)', text, re.M|re.S).group(0).strip()

changes=[]
for rel in owned:
    old=base/'before-source'/rel
    live=repo/rel
    after=base/'after-source'/rel
    after.parent.mkdir(parents=True,exist_ok=True)
    after.write_bytes(live.read_bytes())
    diff=''.join(difflib.unified_diff(old.read_text(encoding='utf-8').splitlines(True),live.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
    diffpath=base/'diffs'/(live.stem+('.map' if live.suffix=='.json' else '')+'.diff')
    diffpath.parent.mkdir(exist_ok=True)
    diffpath.write_text(diff,encoding='utf-8')
    changes.append({'path':rel,'before_sha256':sha(old),'after_sha256':sha(live),'diff':str(diffpath.relative_to(base))})

invariants=[]
for rel,names in {
    owned[1]:['_well_mesh','_alive_floor_h','_constrain_alive','_refresh_live','_process'],
    owned[2]:['_energy','_grad','_surface_mesh','_ball_world','_refresh_trail'],
    owned[4]:['_build_base','_build_brackets','_build_cables','_build_top','_bar'],
}.items():
    old=(base/'before-source'/rel).read_text(encoding='utf-8')
    new=(repo/rel).read_text(encoding='utf-8')
    for name in names:
        prior,final=function(old,name),function(new,name)
        without_comments=lambda s:'\n'.join(x for x in s.splitlines() if not x.strip().startswith('#'))
        invariants.append({'path':rel,'function':name,'unchanged':prior==final,'executable_lines_unchanged':without_comments(prior)==without_comments(final)})
rel=owned[3]
old=(base/'before-source'/rel).read_text(encoding='utf-8');new=(repo/rel).read_text(encoding='utf-8')
invariants.append({'path':rel,'only_change':'TEMP label to START T','unchanged_except_label':old.replace('"label": "TEMP"','"label": "START T"')==new})

def leaf_diffs(a,b,at=''):
    if type(a)!=type(b):return [{'path':at,'before':a,'after':b}]
    if isinstance(a,dict):return [v for k in a.keys()|b.keys() for v in leaf_diffs(a.get(k),b.get(k),at+'/'+str(k))]
    if isinstance(a,list):return [v for i,(x,y) in enumerate(zip(a,b)) for v in leaf_diffs(x,y,at+'/'+str(i))] if len(a)==len(b) else [{'path':at,'before':a,'after':b}]
    return [] if a==b else [{'path':at,'before':a,'after':b}]
mapdiff=leaf_diffs(json.loads((base/'before-source'/owned[0]).read_text(encoding='utf-8')),json.loads((repo/owned[0]).read_text(encoding='utf-8')))
report={'changes':changes,'unchanged_functions':invariants,'map_leaf_diffs':mapdiff,'watched_sources_after':{r:sha(repo/r) for r in saved}}
(base/'changes.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
runs=[]
for p in sorted(base.glob('*/**/run.json')):
    r=json.loads(p.read_text(encoding='utf-8'))
    checks=[]; observed={}
    for name in ['museum.json','focused.json','optimizer.json']:
        q=p.parent/name
        if q.exists():observed=json.loads(q.read_text(encoding='utf-8'));checks=observed.get('checks',[])
    runs.append({'run':str(p.relative_to(base)),'pid':r['pid'],'returncode':r['returncode'],'seconds':r['seconds'],'sources_stable_during_run':r['source_sha256_before']==r['source_sha256_after'],'changed_during_run':[k for k,v in r['source_sha256_before'].items() if v!=r['source_sha256_after'][k]],'loaded_museum_sha256':observed.get('loaded_museum_sha256'),'checks':len(checks),'passed':sum(c['ok'] for c in checks)})
(base/'runtime-summary.json').write_text(json.dumps(runs,indent=2),encoding='utf-8')
(base/'evidence-sha256.json').write_text(json.dumps({str(p.relative_to(base)):sha(p) for p in sorted(base.rglob('*')) if p.is_file() and p.name!='evidence-sha256.json'},indent=2),encoding='utf-8')
print(json.dumps({'changed':len(changes),'map_leaf_diffs':mapdiff,'invariants':invariants,'runs':runs},indent=2))
