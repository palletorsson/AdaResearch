"""Verify one saved cube/wedge recipe in Cube and the separate Transformation trial."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-cube-carried-structure'
OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
if '--staged' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/cube_walkway_probe.gd',stage/'tools/probes/cube_walkway_probe.gd')
for trial in ['', 'transformation']:
    if '--trial-only' in sys.argv and not trial: continue
    if '--cube-only' in sys.argv and trial: continue
    runtime=stage
    if trial:
        # Trans_Pre's existing pickups use the real GameManager autoload.
        # Keep its actual project dependencies and isolate only the user saves.
        from void_trial_runtime import stage_runtime
        runtime=stage_runtime()
        shutil.copy2(stage/'staging_type_probe.gd',runtime/'staging_type_probe.gd')
    for capture in ([True] if '--capture-only' in sys.argv else [False,True] if '--capture' in sys.argv else [False]):
        destination=OUT/(('trial' if trial else 'cube')+('-images' if capture else '-tests'))
        destination.mkdir(exist_ok=True)
        command=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--path',str(runtime),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/cube_walkway_probe.gd','--','--no-bridges','--out='+str(destination)]
        if trial:command.append('--void-trial='+trial)
        if capture:command.append('--capture')
        with (destination/'engine.log').open('w',encoding='utf-8') as log:
            result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
        log=(destination/'engine.log').read_text(encoding='utf-8',errors='replace')
        assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-8000:]
        receipt=json.loads((destination/'checks.json').read_text());assert receipt['passed'],receipt['failed']
        print(f'{destination.name}: {len(receipt["checks"])} checks passed',flush=True)
