"""Build the real Quest game from an isolated source mirror, keeping its package and saves."""
import argparse,hashlib,json,os,re,shutil,subprocess,sys,time,zipfile
import psutil
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from quest_runtime_payload import missing_runtime_assets, runtime_study_files, allowed_runtime_assets
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out',type=Path,default=ROOT/'ada_run/quest-menu-2026-10-28/apk')
parser.add_argument('--reuse-stage',type=Path)
parser.add_argument('--freeze-source',action='store_true',help='Copy commons, algorithms, addons and audio so concurrent source edits cannot change these during export')
args=parser.parse_args()
assert not (args.freeze_source and args.reuse_stage),'Frozen exports need a fresh stage'
OUT=args.out.resolve()
sys.stdout.reconfigure(encoding='utf-8')
OUT.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('Main Quest game export',timeout=1200)
rooms_snapshot=(ROOT/'commons/void/rooms.json').read_bytes()
json.loads(rooms_snapshot)  # Refuse an incomplete concurrent save.
snapshot_path=OUT/'rooms-snapshot.json'
snapshot_path.write_bytes(rooms_snapshot)
# Export filters apply after scanning. Skip only folders the preset excludes.
if args.reuse_stage:
 stage=args.reuse_stage.resolve()
 assert stage.is_relative_to((ROOT/'ada_run/void-trial-runtime').resolve()) and stage.name.startswith('run-'),stage
 assert os.path.samefile(stage/'commons',ROOT/'commons'), 'Stage does not use this project'
else:stage=stage_runtime(exclude_names={'.claude','.codex','ada_encyclopedia','doc','tools','output','reports_tmp','tmp','node_modules'},freeze_names={'commons','algorithms','addons','audio'} if args.freeze_source else ())
# Some installed artifacts reuse executable book studies. Copy only their
# dependency closure into this isolated export, never the whole document tree.
study_files=runtime_study_files(ROOT)
for rel in study_files:
 target=stage/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,target)
# Resource paths in this index are res:// relative. Reuse the completed editor
# index; Godot still checks changed files, without reparsing every source file.
cache=ROOT/'.godot/editor/filesystem_cache10'
if cache.exists() and not args.reuse_stage:
 (stage/'.godot/editor').mkdir(exist_ok=True)
 shutil.copy2(cache,stage/'.godot/editor/filesystem_cache10')
# Export the original application, rather than the test app's isolated name.
config=(ROOT/'project.godot').read_text(encoding='utf-8')
# Resolve this source audio resource without relying on the editor's UID cache.
config=config.replace('buses/default_bus_layout="uid://xebfboh7qcpk"','buses/default_bus_layout="res://default_bus_layout.tres"')
(stage/'project.godot').write_text(config,encoding='utf-8')
preset=(ROOT/'export_presets.cfg').read_text(encoding='utf-8').split('[preset.1]')[0]
exclusions=re.search(r'^exclude_filter="(.*)"$',preset,re.M).group(1).split(',')
preset=re.sub(r'^exclude_filter=".*"$','exclude_filter="'+','.join(p for p in exclusions if p not in {'doc/*','doc/**'})+'"',preset,flags=re.M)
preset=re.sub(r'^package/unique_name=.*$','package/unique_name="com.example.adaresearchzeroone"',preset,flags=re.M)
assert 'custom_features="quest_game"' in preset
version=int(re.search(r'^version/code=(\d+)$',preset,re.M).group(1))
version_name=re.search(r'^version/name="([^"]+)"$',preset,re.M).group(1)
apk=OUT/f'ada-research-{version_name}-v{version}.apk'
(stage/'export_presets.cfg').write_text(preset,encoding='utf-8')
receipt={'stage':str(stage),'apk':str(apk),'version_code':version,'package':'com.example.adaresearchzeroone','main_scene':'res://commons/scenes/vr_staging.tscn','started':time.time(),'source_files':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ['project.godot','export_presets.cfg','commons/void/rooms.json','commons/void/layout.json','commons/void/spine.json','commons/modular/construction-materials.json','commons/scenes/main_menu/MainMenu3D.gd','addons/quest_game_export/runtime-trial-files.json','commons/void/game.gd','commons/void/player_rules.gd','commons/void/grid_platform_carry.gd','commons/modular/grid_native_sources.gd','commons/modular/playgrounds/motion.json']}}
for rel in ['commons/modular/grid_playground.gd','commons/modular/ground_profile.gd','commons/modular/scaffold_connection.gd','commons/modular/playgrounds/connection.tscn','commons/modular/playgrounds/connection.json','commons/modular/playgrounds/revolving.json','commons/void/line_parts.json']:
 receipt['source_files'][rel]=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()
place_scripts=['commons/modular/places/principal_builder.gd','commons/modular/places/place_builder.gd','commons/modular/places/place_spec.gd','commons/modular/places/parameterized_place.gd','commons/artifacts/scaffold_workstation/place_controls.gd','commons/artifacts/scaffold_workstation/workstation.gd','commons/artifacts/scaffold_workstation/display.gd','commons/player/grab_hint.gd']
for rel in place_scripts:receipt['source_files'][rel]=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()
body_resources=[
 'commons/void/ada_android.gd',
 'commons/void/ada_body_editor.gd',
 'commons/void/ada_body_editor.tscn',
 'commons/void/ada_knit_shell.gd',
 'commons/void/ada_knit_finish.gdshader',
 'commons/void/ada_knit.glb',
 'commons/void/ada_look.gd',
 'commons/void/ada_look_presets.json',
 'commons/void/care_body.gd',
 'commons/primitives/parametric/shell_coiling_study.gd',
 'commons/artifacts/registry/ada_body_editor.json',
]
for rel in body_resources:receipt['source_files'][rel]=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()
receipt['runtime_study_files']=study_files
for rel in study_files:receipt['source_files'][rel]=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()
receipt['source_files']['commons/void/rooms.json']=hashlib.sha256(rooms_snapshot).hexdigest()
receipt['frozen_directories']=['commons','algorithms','addons','audio'] if args.freeze_source else []
if args.freeze_source:
 for rel in receipt['source_files']:
  if rel!='commons/void/rooms.json' and (stage/rel).is_file():
   receipt['source_files'][rel]=hashlib.sha256((stage/rel).read_bytes()).hexdigest()
receipt['rooms_snapshot']=str(snapshot_path)
(OUT/'build.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
expected_rooms=json.loads(rooms_snapshot)
receipt['expected_floor_maps']=[f['map'] for f in expected_rooms['floors']]
print('Building main game:',apk,flush=True)
export_env=os.environ.copy()
export_env['ADA_QUEST_ROOMS_SNAPSHOT']=str(snapshot_path)
with (OUT/'export.log').open('w',encoding='utf-8') as log:
 result=subprocess.Popen([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--xr-mode','off','--path',str(stage),'--export-debug','adaresearchonexy',str(apk),'--','--no-bridges'],cwd=ROOT,env=export_env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 # Scene customization and archive compression can be silent for minutes.
 # Publish measured CPU/I/O progress, not an unconditional heartbeat, so a
 # watchdog can distinguish actual work from a frozen export dialog.
 previous=None
 while result.poll() is None:
  if time.time()-receipt['started']>1800:
   subprocess.run(['taskkill','/PID',str(result.pid),'/T','/F'],capture_output=True)
   result.wait(timeout=15);raise TimeoutError('Quest export exceeded 30 minutes')
  samples=[]
  try:
   parent=psutil.Process(result.pid)
   for process in [parent]+parent.children(recursive=True):
    try:
     cpu=process.cpu_times();io=process.io_counters()
     samples.append((process.pid,round(cpu.user+cpu.system,1),io.read_bytes,io.write_bytes))
    except (psutil.NoSuchProcess,psutil.AccessDenied):pass
  except psutil.NoSuchProcess:pass
  sample={'processes':sorted(samples),'log_bytes':(OUT/'export.log').stat().st_size}
  if sample!=previous:
   (OUT/'progress.json').write_text(json.dumps(sample),encoding='utf8');previous=sample
  time.sleep(5)
receipt.update(exit_code=result.returncode,finished=time.time(),exists=apk.exists())
log_text=(OUT/'export.log').read_text(encoding='utf-8',errors='replace')
plain_log=re.sub(r'\x1b\[[0-9;]*m','',log_text)
receipt['export_completed']='[ DONE ] export' in plain_log and apk.exists() and apk.stat().st_mtime>=receipt['started']
receipt['shutdown_clean']=result.returncode==0
if receipt['export_completed']:
 digest=hashlib.sha256()
 with apk.open('rb') as source:
  for chunk in iter(lambda:source.read(4*1024*1024),b''):digest.update(chunk)
 receipt.update(bytes=apk.stat().st_size,sha256=digest.hexdigest())
 with zipfile.ZipFile(apk) as z:
  receipt['zip_integrity_passed']=z.testzip() is None
  names=z.namelist()
  runtime=json.loads((ROOT/'addons/quest_game_export/runtime-trial-files.json').read_text(encoding='utf-8'))['runtime']
  receipt['missing_runtime_assets']=missing_runtime_assets(z,runtime+study_files)
  receipt['runtime_payload_passed']=not receipt['missing_runtime_assets']
  receipt['new_game_assets']={p:'assets/'+p in names for p in ['commons/void/rooms.json','commons/void/layout.json','commons/modular/construction-materials.json','commons/modular/playgrounds/motion.json','commons/modular/playgrounds/revolving.json','commons/modular/playgrounds/connection.json','commons/modular/playgrounds/connection.tscn.remap','commons/modular/scaffold_connection.gd.remap','commons/modular/ground_profile.gd.remap','commons/void/grid_platform_carry.gd.remap']}
  for rel in place_scripts:receipt['new_game_assets'][rel+'.remap']='assets/'+rel+'.remap' in names
  for rel in body_resources:
   if rel.endswith('.glb'):
    imported='assets/'+rel+'.import'
    resource=re.search(r'^path="res://(.+)"$',z.read(imported).decode('utf-8'),re.M) if imported in names else None
    receipt['new_game_assets'][rel]=bool(resource and 'assets/'+resource[1] in names)
   else:
    receipt['new_game_assets'][rel]=any('assets/'+rel+suffix in names for suffix in ('','.remap'))
  if 'Playground_PrincipalPlaces' in receipt['expected_floor_maps']:
   for p in ['commons/void/trials/principal_places/places.tscn.remap','commons/void/trials/principal_places/places.gd.remap','commons/void/trials/principal_places/activity_insert.gd.remap','commons/void/trials/principal_places/recipe.json','commons/artifacts/scaffold_workstation/fitted_geometry.gd.remap']:
    receipt['new_game_assets'][p]='assets/'+p in names
  allowed_studies=allowed_runtime_assets(study_files)
  receipt['authoring_leaks']=[n for n in names if (n.startswith(('assets/ada_run/','assets/doc/','assets/tools/','assets/commons/testing/')) or '/evidence/' in n or '/screenshots/' in n) and n not in allowed_studies]
  if 'assets/commons/void/rooms.json' in names:
   rooms=json.loads(z.read('assets/commons/void/rooms.json'));receipt['packaged_floors']=len(rooms['floors']);receipt['floor_20']=rooms['floors'][20]['map']
   receipt['packaged_floor_maps']=[f['map'] for f in rooms['floors']]
   receipt['packaged_rooms_sha256']=hashlib.sha256(z.read('assets/commons/void/rooms.json')).hexdigest()
(OUT/'build.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in receipt.items() if k not in ['source_files','stage']}),flush=True)
if result.returncode:print(log_text[-6500:])
sys.exit(result.returncode or (0 if receipt.get('runtime_payload_passed',False) else 1))
