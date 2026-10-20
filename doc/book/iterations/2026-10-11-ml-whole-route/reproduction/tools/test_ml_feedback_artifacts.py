"""Check the reviewed production exhibits independently of the student models."""
from pathlib import Path
import json, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-ml-feedback'

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/'artifact-tests.json').unlink(missing_ok=True)
    with (OUT/'artifact-engine.log').open('w',encoding='utf-8') as log:
        run=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--xr-mode','off','--audio-driver','Dummy','--path',str(ROOT),'--script','res://tools/probes/ml_feedback_artifacts_test.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=0x08000000)
    log=(OUT/'artifact-engine.log').read_text(encoding='utf-8',errors='replace')
    print('\n'.join(line for line in log.splitlines() if 'ML FEEDBACK ' in line or 'SCRIPT ERROR' in line))
    result=json.loads((OUT/'artifact-tests.json').read_text()) if (OUT/'artifact-tests.json').exists() else {}
    assert run.returncode==0 and result.get('passed') and 'SCRIPT ERROR' not in log,'See artifact-engine.log'
    print(len(result['checks']),'artifact checks PASS')

if __name__=='__main__':main()
