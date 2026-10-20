"""Bounded native Godot assertions; log survives startup/parse failures."""
from pathlib import Path
import subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-vogue-a-phrase-of-your-own'
if __name__=='__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/'tests.json').unlink(missing_ok=True)
    with (OUT/'tests-engine.log').open('w',encoding='utf-8') as log:
        try:
            r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--xr-mode','off','--audio-driver','Dummy','--path',str(ROOT),'--script','res://tools/probes/vogue_timeline_test.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=50,creationflags=0x08000000)
            code=r.returncode
        except subprocess.TimeoutExpired: code=124
    print((OUT/'tests-engine.log').read_text(encoding='utf-8',errors='replace')[-7500:])
    raise SystemExit(code)
