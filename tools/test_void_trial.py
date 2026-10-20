"""Exercise original Trans_Pre scenes with the real project autoloads and both input rigs."""
from pathlib import Path
import json, os, subprocess, sys, hashlib
from void_trial_runtime import stage_runtime
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/void-trial-test'
OUT.mkdir(parents=True,exist_ok=True)
GODOT=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
capture='--capture' in sys.argv
stage=stage_runtime()
args=[GODOT,'--no-window' if capture else '--headless','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/void_trial_probe.gd','--','--no-bridges','--out='+str(OUT)]
if capture:args.append('--capture')
before={n:hashlib.sha256((ROOT/'commons/void'/n).read_bytes()).hexdigest() for n in ['rooms.json','layout.json']}
with (OUT/'run.log').open('w',encoding='utf8') as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,cwd=ROOT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text=(OUT/'run.log').read_text(encoding='utf8',errors='replace')
after={n:hashlib.sha256((ROOT/'commons/void'/n).read_bytes()).hexdigest() for n in before}
assert before==after,'Curated tower changed during trial'
errors=[l for l in text.splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l or l.startswith('ERROR:')]
print(json.dumps({'exit':result.returncode,'curated_unchanged':before==after,'errors':errors,'result':[l for l in text.splitlines() if 'VOID_TRIAL_RESULT' in l]}))
if result.returncode or errors:print(text[-16000:]);sys.exit(1)
