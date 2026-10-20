from pathlib import Path
import concurrent.futures,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-placement'
def run(name,phase):
    spec=OUT/'specs'/(name+'.json')
    cmd=[sys.executable,'-X','utf8','tools/run_encounter_probe.py',name,'--sequence','tiling','--render','--no-bridges','--probe','tools/probes/tiling_placement.gd','--output-tag','tiling-placement-'+phase]
    if spec.exists():cmd+=['--spec',str(spec)]
    p=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True,encoding='utf8')
    print(name,phase,'exit',p.returncode,flush=True)
    return {'map':name,'exit':p.returncode,'output':p.stdout[-1500:]}
if __name__=='__main__':
    phase=sys.argv[1];names=sys.argv[2:] or json.loads((ROOT/'commons/maps/sequences/tiling.json').read_text())['sequences']['tiling']['maps']
    OUT.mkdir(parents=True,exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(lambda n:run(n,phase),names))
    (OUT/(phase+'-runs.json')).write_text(json.dumps(results,indent=2)+'\n')
    if any(r['exit'] for r in results):sys.exit(1)
