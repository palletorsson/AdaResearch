"""Refresh only Matter previews; preserve concurrently edited floor7 artifacts."""
import hashlib,json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/matter-tabletop';WEB=ROOT.parent/'ada_encyclopedia/public'
sys.stdout.reconfigure(encoding='utf-8');slot=acquire_native_slot('Matter tabletop models only');stage=stage_runtime()
with (OUT/'export.log').open('w',encoding='utf-8') as log:
 result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/matter_cube_export.gd','--','--no-bridges','--out='+str(OUT)],stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'export.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'MATTER_CUBE_EXPORT ',allow_shutdown=result.returncode==0)
assert result.returncode==0 and not errors,log[-3000:]
parts_file=ROOT/'commons/void/line_parts.json';parts=json.loads(parts_file.read_text(encoding='utf-8'));parts['matter_and']=json.loads((OUT/'part-defaults.json').read_text(encoding='utf-8'))
parts_file.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf-8')
file=WEB/'void-models/manifest.json';models=json.loads(file.read_text(encoding='utf-8'))
for relative in ['commons/artifacts/matter_gates/matter_and.gd','commons/artifacts/matter_gates/ball_box.gd','commons/void/primitive-prefabs.json']:
 models.setdefault('source_files',{})[relative]=hashlib.sha256((ROOT/relative).read_bytes()).hexdigest()
file.write_text(json.dumps(models,indent=2)+'\n',encoding='utf-8')
# The legacy editor uses the same actual part geometry with its own saved poses.
file=WEB/'void-trials/matter_gates/manifest.json'
if file.exists():
 trial=json.loads(file.read_text(encoding='utf-8'));before=trial['floors']['1']['artifacts']['and']
 refreshed=dict(models['floors']['7']['artifacts']['matter-and']);refreshed['config']=before.get('config',{})
 trial['floors']['1']['artifacts']['and']=refreshed;trial['revision']=models['revision']
 for relative in ['commons/void/trials/matter_gates/rooms.json','commons/artifacts/matter_gates/matter_and.gd','commons/artifacts/matter_gates/ball_box.gd']:
  trial.setdefault('source_files',{})[relative]=hashlib.sha256((ROOT/relative).read_bytes()).hexdigest()
 file.write_text(json.dumps(trial,indent=2)+'\n',encoding='utf-8')
(OUT/'export-checks.json').write_text(json.dumps({'passed':True,'parts':len(parts['matter_and']),'scope':'Only actual Matter source part meshes/labels and canonical dimensions refreshed; all other editor model entries preserved. Legacy trial uses the same real part geometry with its own poses.','shutdown_diagnostics':shutdown},indent=2)+'\n',encoding='utf-8')
print('Refreshed',len(parts['matter_and']),'Matter tabletop parts only')
