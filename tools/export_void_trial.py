"""Export native geometry for a registered trial, or the main tower with 'main'."""
from pathlib import Path
import json, os, subprocess, sys, hashlib
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
trial=sys.argv[1] if len(sys.argv)>1 else 'transformation'
definition=({'rooms':'res://commons/void/rooms.json','layout':'res://commons/void/layout.json','scene':'res://commons/void/void.tscn'} if trial=='main' else json.loads((ROOT/'commons/void/trials/playable.json').read_text(encoding='utf8'))['trials'][trial])
public='/void-models' if trial=='main' else '/void-trials/'+trial
out=ROOT.parent/'ada_encyclopedia/public'/public.lstrip('/')
out.mkdir(parents=True,exist_ok=True)
log=ROOT/'ada_run'/('void-trial-export-'+trial+'.log')
stage=stage_runtime()
with log.open('w',encoding='utf8') as stream:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/export_void_editor.gd','--','--no-bridges',*(['--void-trial='+trial] if trial!='main' else []),'--out='+str(out),'--public-base='+public],cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=300,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text=log.read_text(encoding='utf8',errors='replace')
if result.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
    print(text[-12000:]);sys.exit(1)
file=out/'manifest.json';manifest=json.loads(file.read_text(encoding='utf8'))
# Trial assemblies have the same editable member contract as tower assemblies.
# Register measured native defaults so copied/moved parts pass save validation.
parts_path=ROOT/'commons/void/line_parts.json'
parts=json.loads(parts_path.read_text(encoding='utf8'))
for floor in manifest['floors'].values():
    for item in floor['artifacts'].values():
        if item['parts']:
            parts[item['artifact'].removeprefix('void_lines_')]={name:model['default'] for name,model in item['parts'].items()}
parts_path.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf8')
paths=[ROOT/definition[n].removeprefix('res://') for n in ['rooms','layout','scene']]
manifest['source_files']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
manifest['revision']=hashlib.sha256(file.read_bytes()).hexdigest()[:12]
file.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
print(json.dumps({'trial':trial,'models':len(list(out.glob('*.glb'))),'failures':manifest['failures']}))
