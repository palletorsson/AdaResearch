from pathlib import Path
import json,hashlib,difflib
ROOT=Path.cwd();BASE=Path(__file__).parent
owned=[
 'commons/artifacts/laundry_line_cathedral/laundry_line_cathedral.gd',
 'commons/artifacts/calder_mobile/calder_mobile.gd',
 'commons/primitives/tensegrity_triangle/tensegrity_triangle.gd',
 'commons/artifacts/fractal_truss_tower/fractal_truss_tower.gd',
 'commons/primitives/parametric/catenoid.gd',
 'commons/primitives/parametric/catenoid.tscn',
 'commons/primitives/parametric/helicoid.tscn',
 'algorithms/wavefunctions/line_builder_3d/cable_builder.gd']
changes=[]
for p in owned:
 old=(BASE/'before'/p).read_bytes();new=(ROOT/p).read_bytes()
 changes.append({'path':p,'before_sha256':hashlib.sha256(old).hexdigest(),'after_sha256':hashlib.sha256(new).hexdigest(),'diff':''.join(difflib.unified_diff(old.decode('utf8').splitlines(True),new.decode('utf8').splitlines(True),fromfile='before/'+p,tofile=p))})
(BASE/'changes.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2),encoding='utf8')
(BASE/'source-changes.diff').write_text(''.join(c['diff'] for c in changes),encoding='utf8')
pairs=[('FormFinding_Catenary','capture-before-accepted','capture-after-verified',['laundry-standing','laundry-plaque']),('FormFinding_Equilibrium','capture-before-verified','capture-after-verified',['calder-standing','calder-plaque','truss-standing'])]
summary={'source_scope':owned,'pairs':[],'headset_tested':False,'accepted_runs':{}}
accepted=['museum-baseline-final-FormFinding_Catenary','headless-after-FormFinding_Catenary']
for hall,before,after,views in pairs:
 a=BASE/(before+'-'+hall);b=BASE/(after+'-'+hall)
 accepted += [a.name,b.name]
 cameras={view:json.loads((a/(view+'-camera.json')).read_text(encoding='utf8'))==json.loads((b/(view+'-camera.json')).read_text(encoding='utf8')) for view in views}
 ar=json.loads((a/'run.json').read_text());br=json.loads((b/'run.json').read_text())
 stable={p:ar['hashes_before'][p]==br['hashes_before'][p] for p in ar['hashes_before'] if p not in owned and not p.endswith('final.md')}
 summary['pairs'].append({'hall':hall,'before':a.name,'after':b.name,'camera_matches':cameras,'shared_source_matches':stable,'notes':'Restored catalog common to both rendered versions; original artifact source replayed in before. Frozen compiling museum loader common to both.'})
for name in accepted:
 d=BASE/name;v=json.loads((d/'verification.json').read_text(encoding='utf8'));r=json.loads((d/'run.json').read_text(encoding='utf8'))
 log=(d/'process.log').read_text(encoding='utf8')
 summary['accepted_runs'][name]={'checks':len(v['checks']),'failures':len(v['failures']),'returncode':r['returncode'],'sources_stable':r['sources_stable_during_run'],'script_errors':'SCRIPT ERROR:' in log}
(BASE/'verification.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
print(json.dumps(summary['accepted_runs'],indent=2))
