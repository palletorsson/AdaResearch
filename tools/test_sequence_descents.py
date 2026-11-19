"""Run the real tower's descent routes with isolated saves and the native slot."""
from pathlib import Path
import json, os, subprocess, sys
from void_trial_runtime import stage_runtime
from void_native_slot import acquire_native_slot

ROOT=Path(__file__).resolve().parents[1]
kind=sys.argv[1] if len(sys.argv)>1 else 'jump_terraces'
xr='--synthetic-xr' in sys.argv
map_name=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--map=')), '')
out=ROOT/'ada_run/sequence-descents'/(kind+('-'+map_name if map_name else '')+('-xr' if xr else ''))
out.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('sequence descent '+kind,timeout=60)
stage=stage_runtime()
config=stage/'project.godot'
config.write_text(config.read_text(encoding='utf8').replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AdaDescent-'+stage.name+'"'),encoding='utf8')
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
      '--no-window' if '--render' in sys.argv else '--headless','--path',str(stage),'--xr-mode','off',
      '--fixed-fps','60','--resolution','1200x900','--log-file',str(out/'godot.log'),
      '--script','res://tools/probes/sequence_descents.gd','--','--no-bridges','--kind='+kind,'--out='+out.as_posix()]
if xr:args.append('--synthetic-xr')
args.extend(a for a in sys.argv if a.startswith('--map='))
(out/'checks.json').unlink(missing_ok=True)
with (out/'runner.log').open('w',encoding='utf8') as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW)
if not (out/'checks.json').exists():
    print((out/'godot.log').read_text(encoding='utf8',errors='replace')[-6500:]);raise SystemExit(1)
data=json.loads((out/'checks.json').read_text())
print(json.dumps(data,indent=2))
raise SystemExit(0 if result.returncode==0 and data['passed'] else 1)
