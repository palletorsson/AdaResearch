import hashlib,json,os,subprocess,sys,time,shutil
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];anchor='--stock-anchor' in sys.argv;reach='--reach' in sys.argv
OUT=ROOT/('ada_run/face-reach' if reach else ('ada_run/face-stock-anchor' if anchor else 'ada_run/face-assembly'));OUT.mkdir(exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
slot=acquire_native_slot('Edge-connected triangle and square faces');stage=stage_runtime()
digest=hashlib.sha256((ROOT/'commons/artifacts/face_assembly/face_assembly.gd' if anchor else OUT/'draft-rooms.json').read_bytes()).hexdigest()
if (OUT/'checks.json').exists():
 archive=OUT/('attempt-'+str(time.time_ns()));archive.mkdir()
 for f in OUT.iterdir():
  if f.is_file() and (f.suffix=='.png' or f.name in ['checks.json','native.log']):shutil.copy2(f,archive/f.name)
 (OUT/'checks.json').unlink()
with (OUT/'native.log').open('w',encoding='utf-8') as stream:
 result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--windowed','--position','-3000,-3000','--resolution','1440x900','--rendering-method','mobile','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/'+('face_stock_anchor' if anchor else 'face_assembly')+'.gd','--','--no-bridges','--out='+str(OUT)],stdout=stream,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'FACE_ASSEMBLY_RESULT ',allow_shutdown=result.returncode==0)
report=json.loads((OUT/'checks.json').read_text()) if (OUT/'checks.json').exists() else {'passed':False,'failed':['No fresh receipt']}
report.update(engine_exit=result.returncode,engine_errors=errors,shutdown_diagnostics=shutdown,**({'source_sha256':digest} if anchor else {'draft_sha256':digest}))
report['passed']=bool(report['passed'] and result.returncode==0 and not errors)
(OUT/'checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(log[-6000:]);assert report['passed'],report
