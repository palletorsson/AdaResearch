"""Incrementally export selected main floors; preserve every other model receipt."""
import hashlib,json,os,subprocess,sys,shutil,tempfile,uuid
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from generated_storage import model_directory
from void_log_diagnostics import split_errors
from void_model_publication import require_export_space, editor_directory, publish_models, merge_models, atomic_json
ROOT=Path(__file__).resolve().parents[1];out=Path(sys.argv[2]).resolve() if len(sys.argv)>2 else ROOT/'ada_run/transformation-workbench';out.mkdir(parents=True,exist_ok=True);public=ROOT.parent/'ada_encyclopedia/public/void-models';file=public/'manifest.json'
sys.stdout.reconfigure(encoding='utf-8')
options=sys.argv[3:]
preview_items=next((option for option in options if option.startswith('--preview-items=')),None)
trial=next((option.split('=',1)[1] for option in options if option.startswith('--trial=')),'')
public_base='/void-models'
rooms_source='commons/void/rooms.json'
if trial:
    if preview_items is None:
        raise ValueError('--trial is supported for live preview selections only')
    definition=json.loads((ROOT/'commons/void/trials/playable.json').read_text(encoding='utf-8'))['trials'][trial]
    public_base=definition.get('models',f'/void-trials/{trial}/manifest.json').rsplit('/',1)[0]
    rooms_source=definition['rooms'].removeprefix('res://')
if preview_items is not None:
    web_root=Path(os.environ.get('ADA_ENCYCLOPEDIA_ROOT',ROOT.parent/'ada_encyclopedia'))
    public=web_root/'public'/public_base.lstrip('/')
    file=public/'manifest.json'
public=editor_directory(public_base.lstrip('/'));file=public/'manifest.json'
require_export_space(public)
staged_models=model_directory(out/'native-models');staged_models.mkdir(parents=True,exist_ok=True)
if preview_items is not None:
    scratch=tempfile.TemporaryDirectory(prefix='preview-',dir=staged_models)
    staged_models=Path(scratch.name)
grids_only='--transition-grids-only' in options
slot=acquire_native_slot('incremental Void models') if preview_items is None else None
stage=stage_runtime()
mode=preview_items or ('--transition-grids-only' if grids_only else '--workbench')
if preview_items is not None:
    requested=json.loads(preview_items.split('=',1)[1])
    if not isinstance(requested,list) or not all(isinstance(item,str) for item in requested):
        raise ValueError('Live preview selection must be an array of artifact IDs')
    selection=staged_models/'selection.json'
    selection.write_text(json.dumps(requested),encoding='utf-8')
    mode='--preview-list='+selection.as_posix()
if preview_items is None:
    (out/'before-models.json').write_bytes(file.read_bytes())
with (out/'export.log').open('w',encoding='utf-8') as stream:
    r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method',os.environ.get('GODOT_RENDERER','mobile'),'--xr-mode','off','--script','res://tools/probes/export_void_editor.gd','--','--no-bridges','--floors='+sys.argv[1],'--skip-palette',mode,'--out='+str(staged_models),'--public-base='+public_base,*(['--void-trial='+trial] if trial else [])],stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text=(out/'export.log').read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(text,'VOID_EXPORT ',allow_shutdown=r.returncode==0)
if r.returncode or errors:print(text[-6000:]);raise RuntimeError(f'Targeted model export failed: exit={r.returncode}, errors={errors}')
new=json.loads((staged_models/'manifest.json').read_text(encoding='utf-8'));assert not new['failures'],new['failures']
input_revisions=json.loads(next((option.split('=',1)[1] for option in options if option.startswith('--input-revisions=')),'{}'))
for floor in new['floors'].values():
    for item_id,item in floor['artifacts'].items():
        if item_id in input_revisions:item['inputRevision']=input_revisions[item_id]
if '--verify-only' in sys.argv[3:]:
    assert not staged_models.resolve().is_relative_to(ROOT)
    (out/'export.json').write_text(json.dumps(dict(passed=True,verification_only=True,floors=list(new['floors']),failures=new['failures'],models_directory=str(staged_models),models=len(list(staged_models.glob('*.glb')))),indent=2)+'\n',encoding='utf-8')
    print('Verified native exports outside Godot:',staged_models);sys.exit(0)
def merge(old, produced):
    if grids_only or preview_items is not None:
        for key,floor in produced['floors'].items():
            destination=old['floors'].setdefault(key,{'map':floor['map'],'artifacts':{}})
            destination['structure']=floor['structure']
            destination['artifacts'].update(floor['artifacts'])
        merge_models(old,{key:value for key,value in produced.items() if key!='floors'})
    else: merge_models(old,produced)
new['export_shutdown_diagnostics']=shutdown
for key in [rooms_source,'commons/void/primitive-prefabs.json']:new.setdefault('source_files',{})[key]=hashlib.sha256((ROOT/key).read_bytes()).hexdigest()
with acquire_native_slot('update preview part defaults',timeout=120,lock_name='void-model-publication.lock'):
    parts_path=ROOT/'commons/void/line_parts.json';parts=json.loads(parts_path.read_text(encoding='utf-8'))
    previous_parts=json.dumps(parts,sort_keys=True)
    for floor in new['floors'].values():
        for a in floor['artifacts'].values():
            if a.get('parts'):
                # A configured workshop and a configured gate can share one scene
                # token while exposing different control members. Retain the verified
                # member names of both variants for independent editor saves.
                parts.setdefault(a['artifact'].removeprefix('void_lines_'),{}).update({name:m['default'] for name,m in a['parts'].items()})
    if json.dumps(parts,sort_keys=True)!=previous_parts:
        atomic_json(parts_path,parts)
old=publish_models(staged_models,new,public,public_base,merge)
(out/'export.json').write_text(json.dumps(dict(passed=True,floors=list(new['floors']),construction_previews=list(new.get('workbench',{})),failures=new['failures'],revision=old['revision'],models_directory=str(staged_models)),indent=2)+'\n',encoding='utf-8')
print('Updated floors',list(new['floors']),'and',len(new.get('workbench',{})),'native construction previews')
