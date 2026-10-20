"""Coordinates arrangement: original point, solid floor, grip/readouts and route."""
from pathlib import Path
import json,os,subprocess,sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-18-coordinates-worksite'
OUT.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(ROOT/'tools/validate_void_rooms.py')],cwd=ROOT,check=True)
rooms=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf-8'))
floor=rooms['floors'][2]
assert not floor.get('basin'), 'Coordinates should use the solid slab'
assert next(a for a in floor['artifacts'] if a['id']=='held')['config']['study_plinth'] is False
subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for rendered in [False,True] if '--capture' in sys.argv else [False]:
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if rendered else '--headless','--path',str(stage),'--rendering-method','mobile',
        '--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_coordinates_site_probe.gd','--','--out='+str(OUT)]
    if rendered:cmd.append('--capture')
    path=OUT/('capture.log' if rendered else 'engine.log')
    with path.open('w',encoding='utf-8') as log:
        result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=180,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    log=path.read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-6500:]
    receipt=json.loads((OUT/('capture-checks.json' if rendered else 'checks.json')).read_text())
    assert receipt['passed'],receipt
    print(f"{len(receipt['checks'])} {'rendered' if rendered else 'desktop/XR'} Coordinates checks passed",flush=True)
