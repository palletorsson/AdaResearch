"""Check the carried solids, original wp joins and real desktop / synthetic XR interaction."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-polyhedra-building-pieces'
OUT=Path(next((arg.split('=',1)[1] for arg in sys.argv if arg.startswith('--out=')),str(OUT))).resolve()
OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
if '--reuse-stage' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/polyhedra_building_probe.gd',stage/'tools/probes/polyhedra_building_probe.gd')
for rendered in ([True] if '--capture-only' in sys.argv else [False,True] if '--capture' in sys.argv else [False]):
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if rendered else '--headless','--path',str(stage),'--rendering-method','mobile',
        '--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/polyhedra_building_probe.gd','--','--out='+str(OUT)]
    if rendered:cmd.append('--capture')
    path=OUT/('capture.log' if rendered else 'engine.log')
    with path.open('w',encoding='utf-8') as stream:
        result=subprocess.run(cmd,stdout=stream,stderr=subprocess.STDOUT,timeout=240,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    log=path.read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-10000:]
    receipt=json.loads((OUT/('capture-checks.json' if rendered else 'checks.json')).read_text())
    assert receipt['passed'],receipt['failed']
    print(f"{len(receipt['checks'])} {'rendered' if rendered else 'desktop/synthetic XR'} checks passed",flush=True)
