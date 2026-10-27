"""Export native geometry for a registered trial, or the main tower with 'main'."""
from pathlib import Path
import json, os, subprocess, sys, hashlib
from void_trial_runtime import stage_runtime
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1]
trial=sys.argv[1] if len(sys.argv)>1 else 'transformation'
definition=({'rooms':'res://commons/void/rooms.json','layout':'res://commons/void/layout.json','scene':'res://commons/void/void.tscn'} if trial=='main' else json.loads((ROOT/'commons/void/trials/playable.json').read_text(encoding='utf8'))['trials'][trial])
public='/void-models' if trial=='main' else '/void-trials/'+trial
out=ROOT.parent/'ada_encyclopedia/public'/public.lstrip('/')
out.mkdir(parents=True,exist_ok=True)
log=ROOT/'ada_run'/('void-trial-export-'+trial+'.log')
from void_native_slot import acquire_native_slot
native_slot=acquire_native_slot('export '+trial)
stage=stage_runtime()
renderer=os.environ.get('VOID_EXPORT_RENDERER','gl_compatibility')
assert renderer in ('gl_compatibility','mobile','forward_plus')
export_timeout=int(os.environ.get('VOID_EXPORT_TIMEOUT','300'))
assert 30<=export_timeout<=1800
with log.open('w',encoding='utf8') as stream:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),*(['--verbose'] if os.environ.get('VOID_EXPORT_VERBOSE')=='1' else []),'--no-window','--path',str(stage),'--rendering-method',renderer,'--xr-mode','off','--script','res://tools/probes/export_void_editor.gd','--','--no-bridges',*(['--void-trial='+trial] if trial!='main' else []),*(['--skip-palette'] if os.environ.get('VOID_EXPORT_SKIP_PALETTE')=='1' else []),'--out='+str(out),'--public-base='+public],cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=export_timeout,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text=log.read_text(encoding='utf8',errors='replace')
# Source artifacts can retain viewport textures or mesh resources at shutdown.
# Record only narrowly recognized teardown diagnostics AFTER the export marker;
# script, shader, startup and in-export errors still fail.
before, marker, cleanup = text.partition('VOID_EXPORT ')
from void_log_diagnostics import split_errors
runtime_errors,shutdown_errors=split_errors(text,'VOID_EXPORT ',allow_shutdown=result.returncode==0)
if result.returncode or runtime_errors:
    print(text[-12000:]);sys.exit(1)
file=out/'manifest.json';manifest=json.loads(file.read_text(encoding='utf8'))
assert not manifest['failures'], manifest['failures']
manifest['export_shutdown_diagnostics']=shutdown_errors
# Trial assemblies have the same editable member contract as tower assemblies.
# Register measured native defaults so copied/moved parts pass save validation.
parts_path=ROOT/'commons/void/line_parts.json'
parts=json.loads(parts_path.read_text(encoding='utf8'))
recipe_tokens=set()
for registry_name in ['modular.json','spatial_lab.json']:
    registry_path=ROOT/'commons/artifacts/registry'/registry_name
    if registry_path.exists():
        recipe_tokens.update(key for key,value in json.loads(registry_path.read_text(encoding='utf8'))['artifacts'].items() if value.get('scene')=='res://commons/modular/recipe_area.tscn')
for floor in manifest['floors'].values():
    for item in floor['artifacts'].values():
        if item['parts']:
            key=item['artifact'].removeprefix('void_lines_')
            measured={name:model['default'] for name,model in item['parts'].items()}
            # A bound recipe has variable members (e.g. nine staged copies versus
            # ten tabletop copies). Each placement's manifest is authoritative;
            # the validation catalogue must retain the union of measured names.
            if key in recipe_tokens:parts.setdefault(key,{}).update(measured)
            else:parts[key]=measured
parts_path.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf8')
paths=[ROOT/definition[n].removeprefix('res://') for n in ['rooms','layout','scene']]
manifest['source_files']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
manifest['revision']=hashlib.sha256(file.read_bytes()).hexdigest()[:12]
file.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
print(json.dumps({'trial':trial,'models':len(list(out.glob('*.glb'))),'failures':manifest['failures']}))
