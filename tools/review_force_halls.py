"""Capture and check the curated Forces route in the production museum."""
from pathlib import Path
import json,subprocess,shutil,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-curated-progression'
HALLS=json.loads((ROOT/'commons/artifacts/force_halls/curation.json').read_text(encoding='utf8'))['halls']
def run(m,probe,dest,render=False):
    dest.mkdir(parents=True,exist_ok=True)
    cmd=[sys.executable,'-X','utf8','tools/run_encounter_probe.py',m,'--sequence','forces','--probe',probe]
    if render:cmd.append('--render')
    result=subprocess.run(cmd,cwd=ROOT,stdout=subprocess.PIPE,text=True,encoding='utf8')
    print(result.stdout[-2200:],flush=True)
    folder=ROOT/'ada_run/encounter_pilot'/m
    for p in folder.iterdir():
        if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,dest/p.name)
    report=json.loads((dest/'report.json').read_text(encoding='utf8')) if (dest/'report.json').exists() else {'passed':False}
    good=result.returncode==0 and report['passed'] and 'SCRIPT ERROR' not in (folder/'engine.log').read_text(encoding='utf8',errors='replace')
    return {'map':m,'passed':good,'exit':result.returncode}
def main():
    results=[]
    for r in HALLS:results.append(run(r['map'],'tools/probes/forces_layout.gd',OUT/'after'/r['map'],True))
    (OUT/'capture-status.json').write_text(json.dumps(results,indent=2),encoding='utf8')
    results.append(run(HALLS[0]['map'],'tools/probes/forces_vectors_compact.gd',OUT/'tests'/'vectors'))
    results.append(run(HALLS[0]['map'],'tools/probes/forces_curated_route.gd',OUT/'tests'/'route'))
    (OUT/'verification-status.json').write_text(json.dumps(results,indent=2),encoding='utf8')
    return 0 if all(r['passed'] for r in results) else 1
if __name__=='__main__':raise SystemExit(main())
