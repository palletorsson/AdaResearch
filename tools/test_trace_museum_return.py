"""Original Trace interactions in the current Void, with optional native captures."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-trace-museum-return'
sys.stdout.reconfigure(encoding='utf-8')
if '--staged' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for name in ['void_grid_probe.gd','void_trace_site_probe.gd','void_trace_light_probe.gd','trace_museum_return_probe.gd']:
    shutil.copy2(ROOT/'tools/probes'/name,stage/'tools/probes'/name)
capture='--capture' in sys.argv
dest=OUT/('images' if capture else 'tests');dest.mkdir(parents=True,exist_ok=True)
cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/trace_museum_return_probe.gd','--','--no-bridges','--out='+str(dest)]
if capture:cmd.append('--capture')
with (dest/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(dest/'engine.log').read_text(encoding='utf-8',errors='replace')
report=json.loads((dest/'checks.json').read_text()) if (dest/'checks.json').exists() else {}
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,(report.get('failed'),log[-6000:])
assert report['passed'],report['failed']
print(f'{len(report["checks"])} checks passed; {dest}')
