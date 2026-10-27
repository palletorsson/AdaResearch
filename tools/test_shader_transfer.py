from pathlib import Path
import os, subprocess, sys, json
from void_trial_runtime import stage_runtime
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'commons/void/trials/shaders/evidence';OUT.mkdir(exist_ok=True)
stage=stage_runtime()
with (OUT/'engine.log').open('w',encoding='utf8') as stream:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://commons/void/trials/shaders/probe.gd','--','--no-bridges','--capture','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=420,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'engine.log').read_text(encoding='utf8',errors='replace')
print(log[-9000:])
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log
report=json.loads((OUT/'checks.json').read_text());assert report['passed'],report['failed']
print(len(report['checks']),'shader checks passed')
