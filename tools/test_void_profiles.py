"""Verify the actual letter profiles, route and editor parts in the Void tower."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-profiles-in-the-tower';OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
if '--staged' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/void_profiles_probe.gd',stage/'tools/probes/void_profiles_probe.gd')
capture='--capture' in sys.argv
dest=OUT/('images' if capture else 'tests');dest.mkdir(exist_ok=True)
cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_profiles_probe.gd','--','--no-bridges','--out='+str(dest)]
if capture:cmd.append('--capture')
with (dest/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(dest/'engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-9000:]
if (dest/'checks.json').exists():
    r=json.loads((dest/'checks.json').read_text());assert r['passed'],r['failed']
    print(f'{len(r["checks"])} checks passed; {dest}')
else:print(dest)
