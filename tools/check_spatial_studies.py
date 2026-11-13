"""Capture and check saved reference studies serially through the native OS lock.

Run without arguments to create five isolated references once, or pass a recipe
ID to recheck that reference after a concrete fix. No main-tower layouts change.
"""
import json,os,subprocess,sys,time,uuid
from pathlib import Path
from spatial_lab import ROOT,RUN,read,write,create_trial,check,recipe_hash
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
OUT=ROOT/'ada_run/spatial-studies-2026-11-13'
def compile_files():
 OUT.mkdir(parents=True,exist_ok=True)
 with acquire_native_slot('Spatial studies / compile',timeout=60):
  stage=stage_runtime()
  r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--path',str(stage),'--xr-mode','off','--script','res://commons/testing/check_compile.gd','--','--files=res://commons/modular/spatial_studies.gd,res://commons/modular/builder.gd,res://commons/modular/sphere_fractal_live.gd,res://commons/modular/sphere_fractal_controls.gd,res://tools/probes/spatial_lab_probe.gd'],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60,creationflags=subprocess.CREATE_NO_WINDOW)
 text=r.stdout+r.stderr;(OUT/'compile.log').write_text(text,encoding='utf-8')
 assert r.returncode==0 and 'SCRIPT ERROR' not in text and not any(s.startswith('ERROR:') for s in text.splitlines()),text[-8000:]
 print('Compile passed',flush=True)
if __name__=='__main__':
 sys.stdout.reconfigure(encoding='utf-8');compile_files()
 if '--compile' in sys.argv:sys.exit(0)
 spec=read(ROOT/'commons/modular/lab.json');terms=read(ROOT/'commons/modular/terms.json')['terms']
 index=read(OUT/'references.json') if (OUT/'references.json').exists() else {}
 selected=[r for r in spec['recipes'] if r.get('kind') and (len(sys.argv)==1 or r['id'] in sys.argv)]
 for r in selected:
  if r['id'] not in index:
   job=uuid.uuid4().hex;request=dict(recipe=r['id'],bindings=r['defaults'],recipe_hash=recipe_hash(terms[r['id']]))
   trial=create_trial(request,job);index[r['id']]=dict(job=job,trial=trial);write(OUT/'references.json',index)
   write(RUN/'jobs'/(job+'.request.json'),request)
  job=index[r['id']]['job'];trial=index[r['id']]['trial']
  write(RUN/'jobs'/(job+'.json'),dict(status='testing',pid=os.getpid(),trial=trial))
  start=time.perf_counter()
  try:
   result=check(trial,RUN/trial);result['timing']['end_to_end_seconds']=round(time.perf_counter()-start,3)
   write(RUN/'jobs'/(job+'.json'),dict(status='complete',**result));index[r['id']].update(checks=result['native_checks'],models=result['models'],seconds=result['timing']['end_to_end_seconds'])
   write(OUT/'references.json',index);print(r['id'],json.dumps(index[r['id']]),flush=True)
  except Exception as error:
   write(RUN/'jobs'/(job+'.json'),dict(status='failed',trial=trial,error=str(error)));raise
