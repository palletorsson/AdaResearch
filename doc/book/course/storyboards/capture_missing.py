"""Photograph missing halls with private museum output directories."""
from pathlib import Path
import concurrent.futures
import json
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent

if len(sys.argv)>1 and sys.argv[1]!='--refresh':
    hall,seq=sys.argv[1:3]
    runner=ROOT/'tools/run_encounter_probe.py'
    code=runner.read_text(encoding='utf-8').replace("ROOT / 'ada_run/encounter_pilot' / args.room", "ROOT / 'ada_run/encounter_pilot' / (args.room + '_storyboard')")
    sys.argv=[str(runner),hall,'--sequence',seq,'--render','--probe',str(HERE/'capture.gd')]
    exec(compile(code,str(runner),'exec'),{'__name__':'__main__','__file__':str(runner)})
else:
    inventory=json.loads((HERE/'inventory.json').read_text(encoding='utf-8'))
    refresh='--refresh' in sys.argv
    missing=[h for h in inventory['halls'] if h['plan_present'] and ((ROOT/'ada_run/encounter_pilot'/(h['id']+'_storyboard')).exists() if refresh else not h['images'])]
    print('Photographing',len(missing),'planned halls',flush=True)
    def capture(h):
        result=subprocess.run([sys.executable,str(__file__),h['id'],h['sequence']],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        print(h['id'],result.returncode,flush=True)
        return {'hall':h['id'],'exit':result.returncode,'output':result.stdout[-1600:]}
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results=list(pool.map(capture,missing))
    (HERE/'capture-results.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
