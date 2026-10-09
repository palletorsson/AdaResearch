from pathlib import Path
import hashlib,json,difflib
root=Path.cwd();base=root/'doc/book/iterations/2026-09-19-randomness-review/middle'
owned=['commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd','algorithms/randomness/randomdecay/scripts/random_decay_multimesh.gd']
diff=[]
for p in owned:
    diff+=list(difflib.unified_diff((base/'before-source'/p).read_text(encoding='utf-8').splitlines(True),(root/p).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+p,tofile='after/'+p))
(base/'owned-source.diff').write_text(''.join(diff),encoding='utf-8')
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
(base/'owned-after-sha256.json').write_text(json.dumps({p:sha(root/p)for p in owned},indent=2),encoding='utf-8')
pairs=[
    {'hall':'Random_Walk','before':'walk-before/instrument.png','after':'walk-accepted/instrument.png','claim':'Accurate LONG STEP label; primary seed777/mode2/300steps and camera matched. Ambient terrain is not seeded in this harness and differs between runs.'},
    {'hall':'Random_Rotate_Random_XYZ','before':'rotate-before/stacks.png','after':'rotate-after/stacks.png','claim':'Same camera in actual museum, complete20+120 stacks before/after common geometry fit.'},
    {'hall':'Random_Mushrooms','before':'mushroom-before/hall-plan.png','after':'mushroom-after/hall-plan.png','claim':'Same hall camera and seeded mushroom population; arrivals moved behind bed for the three-pass walking order.'},
    {'hall':'Random_Mushrooms','before':'mushroom-before/silhouette_arrivals.png','after':'mushroom-after/silhouette_arrivals.png','claim':'Same relative standing view and dress/form state; existing encounter at its new position.'},
]
runs=[]
for folder in ['walk-before','walk-accepted','rotate-before','rotate-after','mushroom-before','mushroom-after']:
    r=json.loads((base/folder/'museum-run.json').read_text());c=json.loads((base/folder/'museum-checks.json').read_text())
    assert r['returncode']==0 and not c['failures']
    assert r['source_sha256_before']==r['source_sha256_after']
    runs.append({'folder':folder,'checks':c['checks'],'returncode':r['returncode'],'source_stable':True,'shared_loader_sha256':r['source_sha256_before']['commons/scenes/endless_museum.gd']})
for pair in pairs:
    pair['before_sha256']=sha(base/pair['before']);pair['after_sha256']=sha(base/pair['after'])
manifest={'pairs':pairs,'actual_museum_runs':runs,'focused':'focused-accepted/behavior-checks.json','focused_checks':49,'owned_sources':owned,'before_context_files':len(json.loads((base/'before-sha256.json').read_text())),'limits':['Headset reach, eating interaction and comfort not tested.','Button-signal simulation and static capsule queries do not establish player understanding.','Ambient terrain state differs in Walk images; the primary terrarium is matched.','Walk button newline was changed to a plain space after focused checks because baked rendering joined words; final actual-museum run verifies the final label.','Baseline run manifests predate addition of live-plan/sequence hashes to the runner; root restoration/staging records preserve those intentional route changes.']}
(base/'evidence-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(runs,indent=2))
