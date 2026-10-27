"""Incrementally export selected main floors; preserve every other model receipt."""
import hashlib,json,os,subprocess,sys,shutil
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from generated_storage import model_directory
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];out=Path(sys.argv[2]).resolve() if len(sys.argv)>2 else ROOT/'ada_run/transformation-workbench';out.mkdir(parents=True,exist_ok=True);public=ROOT.parent/'ada_encyclopedia/public/void-models';file=public/'manifest.json'
sys.stdout.reconfigure(encoding='utf-8')
staged_models=model_directory(out/'native-models');staged_models.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('incremental Transformation models');stage=stage_runtime()
old=json.loads(file.read_text(encoding='utf-8'));(out/'before-models.json').write_text(json.dumps(old),encoding='utf-8')
with (out/'export.log').open('w',encoding='utf-8') as stream:
    r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/export_void_editor.gd','--','--no-bridges','--floors='+sys.argv[1],'--skip-palette','--workbench','--out='+str(staged_models),'--public-base=/void-models'],stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
text=(out/'export.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(text,'VOID_EXPORT ',allow_shutdown=r.returncode==0)
if r.returncode or errors:print(text[-6000:]);raise RuntimeError('Targeted model export failed')
new=json.loads((staged_models/'manifest.json').read_text(encoding='utf-8'));assert not new['failures'],new['failures']
if '--verify-only' in sys.argv[3:]:
    assert not staged_models.resolve().is_relative_to(ROOT)
    (out/'export.json').write_text(json.dumps(dict(passed=True,verification_only=True,floors=list(new['floors']),failures=new['failures'],models_directory=str(staged_models),models=len(list(staged_models.glob('*.glb')))),indent=2)+'\n',encoding='utf-8')
    print('Verified native exports outside Godot:',staged_models);sys.exit(0)
old['floors'].update(new['floors']);old.setdefault('workbench',{}).update(new.get('workbench',{}));old['export_shutdown_diagnostics']=shutdown
for source in staged_models.iterdir():
    if source.is_file() and source.name!='manifest.json':shutil.copy2(source,public/source.name)
for key in ['commons/void/rooms.json','commons/void/primitive-prefabs.json']:old.setdefault('source_files',{})[key]=hashlib.sha256((ROOT/key).read_bytes()).hexdigest()
old['revision']=hashlib.sha256(json.dumps(old).encode()).hexdigest()[:12];temporary=file.with_suffix('.next.json');temporary.write_text(json.dumps(old,indent=2)+'\n',encoding='utf-8');os.replace(temporary,file)
parts_path=ROOT/'commons/void/line_parts.json';parts=json.loads(parts_path.read_text(encoding='utf-8'))
for floor in new['floors'].values():
    for a in floor['artifacts'].values():
        if a.get('parts'):
            # A configured workshop and a configured gate can share one scene
            # token while exposing different control members. Retain the verified
            # member names of both variants for independent editor saves.
            parts.setdefault(a['artifact'].removeprefix('void_lines_'),{}).update({name:m['default'] for name,m in a['parts'].items()})
parts_path.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf-8')
(out/'export.json').write_text(json.dumps(dict(passed=True,floors=list(new['floors']),construction_previews=list(new.get('workbench',{})),failures=new['failures'],revision=old['revision'],models_directory=str(staged_models)),indent=2)+'\n',encoding='utf-8')
print('Updated floors',list(new['floors']),'and',len(new.get('workbench',{})),'native construction previews')
