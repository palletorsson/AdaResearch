from pathlib import Path
import json, shutil, subprocess, sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-pendulum-a-record-of-return'

def main():
    before=OUT/'before/museum';before.mkdir(parents=True,exist_ok=True)
    source=ROOT/'doc/book/iterations/2026-10-08-wavefunctions-what-returns/before/WaveFunctions_Pendulum'
    for p in source.iterdir():
        if p.is_file(): shutil.copy2(p,before/p.name)
    dest=OUT/'after';dest.mkdir(exist_ok=True)
    spec=dest/'spec.json'
    spec.write_text(json.dumps({'lesson':'res://doc/book/iterations/2026-10-08-pendulum-a-record-of-return/extracted/02_pendulum_record.gd'}),encoding='utf8')
    run=subprocess.run([sys.executable,'-X','utf8','tools/run_encounter_probe.py','WaveFunctions_Pendulum','--sequence','wavefunctions','--probe','tools/probes/wavefunctions_pendulum_museum.gd','--spec',str(spec),'--render'],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf8')
    print(run.stdout[-3500:])
    for p in (ROOT/'ada_run/encounter_pilot/WaveFunctions_Pendulum').iterdir():
        if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,dest/p.name)
    report=json.loads((dest/'report.json').read_text(encoding='utf8'))
    passed=run.returncode==0 and report['passed'] and 'SCRIPT ERROR' not in (dest/'engine.log').read_text(encoding='utf8',errors='replace')
    return 0 if passed else 1

if __name__=='__main__': raise SystemExit(main())
