"""Serial, offscreen native AND tests and real model export."""
from pathlib import Path
import os, subprocess, sys, time
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/matter-gates'
OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
job=sys.argv[1] if len(sys.argv)>1 else 'probe'
assert job in ('probe','export','compile')
slot=acquire_native_slot('matter gates '+job)
stage=stage_runtime()
script='matter_gates_probe' if job=='probe' else 'export_matter_gates'
target=OUT if job=='probe' else ROOT.parent/'ada_encyclopedia/public/void-trials/matter_gates'
target.mkdir(parents=True,exist_ok=True)
if (OUT/(job+'.log')).exists():
    (OUT/'previous').mkdir(exist_ok=True)
    (OUT/(job+'.log')).rename(OUT/'previous'/(job+'-'+str(time.time_ns())+'.log'))
if job=='compile':
    command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(stage),'--xr-mode','off','--script','res://commons/testing/check_compile.gd','--','--files=res://commons/artifacts/matter_gates/matter_and.gd,res://commons/artifacts/matter_gates/ball_box.gd,res://tools/probes/matter_gates_probe.gd,res://tools/probes/export_matter_gates.gd']
else:
    command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(stage),
        '--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--position','-3000,-3000',
        '--resolution','1280x800','--script','res://tools/probes/'+script+'.gd','--','--no-bridges',
        '--void-trial=matter_gates','--out='+str(target),*sys.argv[2:]]
with (OUT/(job+'.log')).open('w',encoding='utf-8') as log:
    process=subprocess.Popen(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    started=time.monotonic()
    while process.poll() is None:
        time.sleep(.3)
        live=(OUT/(job+'.log')).read_text(encoding='utf-8',errors='replace')
        if 'SCRIPT ERROR' in live or time.monotonic()-started>240:
            process.terminate();process.wait(timeout=15);break
text=(OUT/(job+'.log')).read_text(encoding='utf-8',errors='replace')
if process.returncode==0 and job=='export':
    import json,hashlib
    manifest=json.loads((target/'manifest.json').read_text(encoding='utf-8'))
    # Reuse the tower's existing real prefab previews without exporting copies.
    tower_models=ROOT.parent/'ada_encyclopedia/public/void-models/manifest.json'
    manifest['props']=json.loads(tower_models.read_text(encoding='utf-8')).get('props',{})
    parts_file=ROOT/'commons/void/line_parts.json'
    parts=json.loads(parts_file.read_text(encoding='utf-8'))
    parts['matter_and']={key:model['default'] for key,model in manifest['floors']['1']['artifacts']['and']['parts'].items()}
    parts_file.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf-8')
    manifest['source_files']={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'commons/void/trials/matter_gates/rooms.json',ROOT/'commons/void/trials/matter_gates/layout.json',ROOT/'commons/artifacts/matter_gates/matter_and.gd',ROOT/'commons/artifacts/matter_gates/ball_box.gd']}
    (target/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(text[-8000:])
raise SystemExit(process.returncode or (1 if 'SCRIPT ERROR' in text or any(line.startswith('ERROR:') for line in text.splitlines()) else 0))
