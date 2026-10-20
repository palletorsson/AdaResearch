"""Point Trace: construction framing, clear shaft Grid, retained drawing and editor placement."""
from pathlib import Path
import json,os,subprocess,sys

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-18-trace-worksite'
OUT.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(ROOT/'tools/validate_void_rooms.py')],cwd=ROOT,check=True)
rooms=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf-8'))
before=json.loads((OUT/'before-floor.json').read_text())
assert {k:v for k,v in rooms['floors'][4].items() if k not in ('props','route')}=={k:v for k,v in before.items() if k not in ('props','route')},'Original lesson arrangement changed'
assert rooms['floors'][4]['props'][:len(before['props'])]==before['props'],'Existing props changed'
baseline=json.loads((OUT/'before-rooms.json').read_text(encoding='utf-8'))
assert all(a==b for i,(a,b) in enumerate(zip(rooms['floors'],baseline['floors'])) if i!=4),'Another floor changed'
subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for rendered in [True] if '--capture-only' in sys.argv else [False,True] if '--capture' in sys.argv else [False]:
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if rendered else '--headless','--path',str(stage),'--rendering-method','mobile',
        '--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_trace_site_probe.gd','--','--out='+str(OUT)]
    if rendered:cmd.append('--capture')
    path=OUT/('capture.log' if rendered else 'engine.log')
    with path.open('w',encoding='utf-8') as log:
        result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=180,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    log=path.read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-6500:]
    receipt=json.loads((OUT/('capture-checks.json' if rendered else 'checks.json')).read_text())
    assert receipt['passed'],receipt
    print(f"{len(receipt['checks'])} {'rendered' if rendered else 'desktop/XR'} Point Trace checks passed",flush=True)
