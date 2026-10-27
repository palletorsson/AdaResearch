from pathlib import Path
import os, subprocess, sys
sys.stdout.reconfigure(encoding='utf8')
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
stage=stage_runtime()
log=ROOT/'commons/void/trials/shaders/measure.log'
with log.open('w',encoding='utf8') as stream:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--script','res://commons/void/trials/shaders/measure.gd','--','--no-bridges'],stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
print(result.returncode)
print(log.read_text(encoding='utf8',errors='replace')[-5000:])
