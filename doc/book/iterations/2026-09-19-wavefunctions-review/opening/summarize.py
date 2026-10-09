from pathlib import Path
import hashlib,json,difflib

ROOT=Path(__file__).resolve().parents[5]
OUT=Path(__file__).resolve().parent
PASS=OUT.parent
sha=lambda b:hashlib.sha256(b).hexdigest()
code=lambda text:'\n'.join(x for x in text.splitlines() if x.strip() and not x.lstrip().startswith('#'))
owned=list(json.loads((OUT/'before-sha256.json').read_text()))
changes=[]
for rel in owned:
    before=(OUT/'before-source'/rel).read_bytes();after=(ROOT/rel).read_bytes()
    changes.append({'path':rel,'before_sha256':sha(before),'after_sha256':sha(after),
                    'executable_lines_unchanged':code(before.decode('utf-8'))==code(after.decode('utf-8')),
                    'diff':''.join(difflib.unified_diff(before.decode('utf-8').splitlines(True),after.decode('utf-8').splitlines(True),fromfile='before/'+rel,tofile=rel))})
(OUT/'source-changes.json').write_text(json.dumps(changes,indent=2),encoding='utf-8')
(OUT/'source-changes.diff').write_text(''.join(c['diff'] for c in changes),encoding='utf-8')

def prepass(rel):
    own=OUT/'before-source'/rel
    root_saved=PASS/'before'/rel
    return (own if own.exists() else root_saved if root_saved.exists() else ROOT/rel).read_bytes()

historical={'scope':'Historical evidence inspected on 2026-09-19; these are not new museum or headset tests.','manifests':[],'reports':[],'review_package_matches':[]}
for name in ['doc/space/sine-flow-hall-2026-09-12/source-hashes.json','doc/space/wcn-runtime-review-2026-09-10/evidence.json']:
    data=json.loads((ROOT/name).read_text(encoding='utf-8'))
    hashes=data.get('source_sha256',data)
    rows=[]
    for rel,h in hashes.items():
        if not isinstance(h,str) or len(h)!=64 or not (ROOT/rel).is_file():continue
        if not any(x in rel for x in ['Intro','intro','Pendulum','pendulum','Sine','sine']):continue
        rows.append({'path':rel,'recorded_sha256':h,'prepass_sha256':sha(prepass(rel)), 'matches_prepass':h==sha(prepass(rel))})
    historical['manifests'].append({'path':name,'sha256':sha((ROOT/name).read_bytes()),'comparisons':rows})

for hall,short in [('WaveFunctions_Intro','intro'),('WaveFunctions_Pendulum','pendulum'),('WaveFunctions_Sine_Space','sine_space')]:
    name=f'ada_run/waves_chance_noise/{hall}/probe_{short}_live.json'
    data=json.loads((ROOT/name).read_text(encoding='utf-8'))
    historical['reports'].append({'path':name,'sha256':sha((ROOT/name).read_bytes()),'checks':data.get('checks'),'failures':data.get('failures'),
                                'control_path':data.get('control_path'),'headset_verified':data.get('headset_verified'),
                                'full_artifact_source_fingerprint_in_report':False,
                                'date_context':f'commons/maps/{hall}/field_notes.md: 2026-09-13 entry'})
for name in ['ada_run/sine-flow-hall/report_2026-09-12.json','ada_run/sine-flow-hall/report.json']:
    data=json.loads((ROOT/name).read_text(encoding='utf-8'))
    historical['reports'].append({'path':name,'sha256':sha((ROOT/name).read_bytes()),'checks':data.get('checks'),'failures':data.get('failures')})
for rel in owned+['algorithms/wavefunctions/oscillation_driver/PendulumWave.gd','commons/artifacts/sine_flow_tray/sine_flow_tray.gd']:
    archived=ROOT/'doc/book/review-packages/2026-09-18/wavefunctions/sources'/rel
    if archived.exists():
        historical['review_package_matches'].append({'path':rel,'review_sha256':sha(archived.read_bytes()),'prepass_sha256':sha(prepass(rel)),'matches_prepass':archived.read_bytes()==prepass(rel)})
(OUT/'historical-evidence.json').write_text(json.dumps(historical,indent=2),encoding='utf-8')

runs=[]
for name in ['unit-transform-before','unit-transform-baseline','unit-transform-replay','unit-transform-after']:
    folder=OUT/name
    run=json.loads((folder/'run.json').read_text())
    checkfile=folder/'checks.json'
    result=json.loads(checkfile.read_text()) if checkfile.exists() else {}
    checks=result.get('checks',[])
    log=(folder/'process.log').read_text(encoding='utf-8',errors='replace')
    runs.append({'run':name,'checks':len(checks),'failures':len([c for c in checks if not c['passed']]),'returncode':run['returncode'],
                 'source_stable':run['source_stable'],'script_errors':'SCRIPT ERROR' in log,
                 'native_crash':'CrashHandlerException' in log,
                 'max_rod_center_error_m':max((o['center_error_m'] for o in result.get('observations',[])),default=None)})
chain=json.loads((PASS/'source-chain.json').read_text(encoding='utf-8'))
hallnames=['WaveFunctions_Intro','WaveFunctions_Pendulum','WaveFunctions_Sine_Space','WaveFunctions_Unit_Circle']
placements={h:len(chain[h]['placements']) for h in hallnames}
summary={'owned_source_files':len(owned),'behavioral_fix':'UnitCircle local projection-rod orientation', 'map_files_edited_by_subagent':0,
         'placements_preserved':placements,'runs':runs,'new_gpu_runs':0,'new_museum_runs':0,'headset_tested':False,
         'source_change_verification':[{'path':r['path'],'comments_only':r['executable_lines_unchanged']} for r in changes]}
(OUT/'verification.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2))
