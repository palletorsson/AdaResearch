"""Verify real one-storey falls, health, death feedback and checkpoint recovery."""
from pathlib import Path
import json
import os
import subprocess
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-18-void-fall-health'
OUT.mkdir(parents=True,exist_ok=True)
with wave.open(str(ROOT/'commons/void/audio/grunt.wav')) as clip:
    assert .4 < clip.getnframes()/clip.getframerate() < .8 and clip.getnchannels()==1
subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for rendered in [False,True] if '--capture' in sys.argv else [False]:
    cmd = [os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if rendered else '--headless','--path',str(stage),'--rendering-method','mobile',
        '--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_fall_probe.gd','--','--out='+str(OUT)]
    if rendered: cmd.append('--capture')
    log_path = OUT/('capture.log' if rendered else 'engine.log')
    with log_path.open('w',encoding='utf-8') as log:
        result = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=180,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    log = log_path.read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-6500:]
    receipt = json.loads((OUT/('capture-checks.json' if rendered else 'checks.json')).read_text(encoding='utf-8'))
    assert receipt['passed'],receipt
    print(f"{len(receipt['checks'])} {'rendered' if rendered else 'desktop/XR'} fall checks passed",flush=True)
