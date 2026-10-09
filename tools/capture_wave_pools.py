from pathlib import Path
import json, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-wave-pools-walk-down'
def main():
    rooms=sys.argv[1:] or ['WaveFunctions_Sine_Space','WaveFunctions_3D_Wave_Propagation']
    ok=True
    for room in rooms:
        run=subprocess.run([sys.executable,'-X','utf8','tools/run_encounter_probe.py',room,'--sequence','wavefunctions','--probe','tools/probes/wave_pool_access.gd','--render'],cwd=ROOT,capture_output=True,text=True,encoding='utf8')
        print(run.stdout[-2200:]);print(run.stderr[-1500:])
        dest=OUT/'after'/room;dest.mkdir(parents=True,exist_ok=True)
        src=ROOT/'ada_run/encounter_pilot'/room
        for p in src.iterdir():
            if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,dest/p.name)
        ok=ok and run.returncode==0 and (src/'report.json').exists() and json.loads((src/'report.json').read_text(encoding='utf8'))['passed']
    return 0 if ok else 1
if __name__=='__main__':raise SystemExit(main())
