"""Export one original GridSystem for read-only comparison, under the native lock."""
import sys,os,json,hashlib,subprocess,shutil
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from generated_storage import public_directory
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];WEB=ROOT.parent/'ada_encyclopedia'
name=sys.argv[1] if len(sys.argv)>1 else 'Trans_Rotation'
assert name.replace('_','').isalnum()
out=ROOT/'ada_run/spatial-comparison'/name;out.mkdir(parents=True,exist_ok=True)
source=ROOT/'commons/maps'/name/'map_data.json';before=source.read_bytes()
models=public_directory('spatial-comparison')/name;models.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('read-only Grid comparison / '+name);stage=stage_runtime()
with (out/'export.log').open('w',encoding='utf-8') as log:
 r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/export_spatial_grid.gd','--','--no-bridges','--map='+name,'--out='+str(models),'--public-base=/spatial-comparison/'+name],stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
log=(out/'export.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'COMPARISON_EXPORT ',allow_shutdown=r.returncode==0)
assert r.returncode==0 and not errors,(r.returncode,errors,log[-3000:])
assert source.read_bytes()==before,'Source map changed externally during export; re-export from a stable source'
manifest=json.loads((models/'manifest.json').read_text(encoding='utf-8'));assert not manifest['failures']
manifest.update(source_sha256=hashlib.sha256(before).hexdigest(),source='commons/maps/'+name+'/map_data.json',shutdown_diagnostics=shutdown)
(models/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
public=WEB/'public/spatial-comparison'/name;public.mkdir(parents=True,exist_ok=True)
for f in models.iterdir():
 if f.is_file():shutil.copy2(f,public/f.name)
(out/'checks.json').write_text(json.dumps(dict(passed=True,objects=len(manifest['objects']),source_unchanged=True,models_directory=str(models)),indent=2)+'\n',encoding='utf-8')
print('Grid comparison exported:',name,len(manifest['objects']),'original instances')
