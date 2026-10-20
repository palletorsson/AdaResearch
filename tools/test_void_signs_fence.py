"""Verify the changed doorway and sign readability in native Godot."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-signs-and-fence'
OUT.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for name in ['void_evening_probe.gd','void_signs_fence_probe.gd']:
    shutil.copy2(ROOT/'tools/probes'/name,stage/'tools/probes'/name)
with (OUT/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_signs_fence_probe.gd','--','--out='+str(OUT)],stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-8000:]
receipt=json.loads((OUT/'checks.json').read_text());assert receipt['passed'],receipt
print(f"{len(receipt['checks'])} native checks passed.")
