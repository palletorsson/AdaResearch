"""Exercise or photograph the simplified crossing using the production game."""
from pathlib import Path
import json,os,subprocess,sys
from void_trial_runtime import stage_runtime
root=Path(__file__).resolve().parents[1]
capture='--capture' in sys.argv
out=root/'doc/book/iterations/2026-10-19-translation-single-crossing'/('images' if capture else 'tests')
out.mkdir(parents=True,exist_ok=True)
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if capture else '--headless','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/translation_crossing_probe.gd','--','--no-bridges','--out='+str(out)]
if capture:args.append('--capture')
with (out/'engine.log').open('w',encoding='utf8') as stream:
 result=subprocess.run(args,stdout=stream,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(out/'engine.log').read_text(encoding='utf8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-7000:]
if capture:
 for name in ['approach','suspension','whole-setup']:assert (out/(name+'.png')).is_file()
 print('Three native screenshots saved.')
else:
 report=json.loads((out/'checks.json').read_text())
 assert report['passed'],report['failed']
 print(str(len(report['checks']))+' desktop/synthetic XR checks passed.')
