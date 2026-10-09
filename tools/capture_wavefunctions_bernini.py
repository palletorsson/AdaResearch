from pathlib import Path
import json,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-bernini-a-turn-through-height'

def main():
    dest=OUT/'after';dest.mkdir(exist_ok=True)
    spec=dest/'spec.json'
    spec.write_text(json.dumps({'lesson':'res://doc/book/iterations/2026-10-08-bernini-a-turn-through-height/extracted/07_twisted_shaft.gd'}),encoding='utf8')
    run=subprocess.run([sys.executable,'-X','utf8','tools/run_encounter_probe.py','Wavefunctions_Bernini','--sequence','wavefunctions','--probe','tools/probes/wavefunctions_bernini_museum.gd','--spec',str(spec),'--render'],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf8')
    print(run.stdout[-4000:])
    for p in (ROOT/'ada_run/encounter_pilot/Wavefunctions_Bernini').iterdir():
        if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,dest/p.name)
    if run.returncode!=0:return run.returncode
    report=json.loads((dest/'report.json').read_text(encoding='utf8'))
    log=(dest/'engine.log').read_text(encoding='utf8',errors='replace')
    return 0 if report['passed'] and 'SCRIPT ERROR' not in log and 'blocked t exit' not in log and 'no clear supported entrance' not in log else 1

if __name__=='__main__':raise SystemExit(main())
