"""Serialize actual tabletop physics/input tests without changing desktop focus."""
import json,os,subprocess,sys,time,shutil
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/matter-tabletop';OUT.mkdir(exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8');slot=acquire_native_slot('Matter AND tabletop');stage=stage_runtime()
if (OUT/'native.log').exists():
 archive=OUT/('attempt-'+str(time.time_ns()));archive.mkdir()
 for p in OUT.iterdir():
  if p.is_file() and (p.suffix=='.png' or p.name in ['checks.json','native.log']):shutil.copy2(p,archive/p.name)
if (OUT/'checks.json').exists():(OUT/'checks.json').unlink()
with (OUT/'native.log').open('w',encoding='utf-8') as log:
 result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','-3000,-3000','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/matter_tabletop.gd','--','--no-bridges','--void-start-floor=7','--out='+str(OUT)],stdout=log,stderr=subprocess.STDOUT,timeout=420,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'MATTER_TABLETOP_RESULT ',allow_shutdown=result.returncode==0)
r=json.loads((OUT/'checks.json').read_text()) if (OUT/'checks.json').exists() else {'passed':False,'failed':['No fresh native receipt']}
r.update(engine_exit=result.returncode,engine_errors=errors,shutdown_diagnostics=shutdown);r['passed']=bool(r['passed'] and result.returncode==0 and not errors)
(OUT/'checks.json').write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(log[-6500:]);assert r['passed'],r
