"""Export real Void meshes into the encyclopedia, using the isolated game test project."""
from pathlib import Path
import hashlib, json, os, shutil, subprocess
from void_native_slot import acquire_native_slot

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT.parent / 'ada_encyclopedia'
OUT = WEB / 'public/void-models'
STAGE = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
GODOT = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
OUT.mkdir(parents=True, exist_ok=True)
slot = acquire_native_slot('Legacy main editor model export')
os.environ['ADA_SOURCE_PROJECT'] = str(ROOT)
# Refresh the already resolved dependency closure, without importing the enormous museum.
for target in STAGE.rglob('*'):
    rel=target.relative_to(STAGE)
    source=ROOT/rel
    if '.godot' not in rel.parts and rel.name not in {'project.godot','export_presets.cfg'} and rel.suffix != '.import' and source.is_file() and target.is_file():
        shutil.copy2(source,target)
(STAGE/'project.godot').write_text('''config_version=5
[application]
config/name="Void editor model export"
run/main_scene="res://commons/void/void.tscn"
[autoload]
TraceData="*res://commons/globals/trace_data.gd"
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[filesystem]
import/blender/enabled=false
[physics]
3d/physics_engine="Jolt Physics"
[rendering]
renderer/rendering_method="gl_compatibility"
''',encoding='utf-8')
probe=STAGE/'tools/probes/export_void_editor.gd'
probe.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'tools/probes/export_void_editor.gd',probe)
shutil.copy2(ROOT/'tools/generated_storage.gd',STAGE/'tools/generated_storage.gd')
log=ROOT/'ada_run/void-editor-export.log'
with log.open('w',encoding='utf-8') as stream:
    subprocess.run([GODOT,'--headless','--path',str(STAGE),'--editor','--import'],stdout=stream,stderr=subprocess.STDOUT,timeout=120,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0,check=True)
    result=subprocess.run([GODOT,'--no-window','--path',str(STAGE),'--rendering-method','gl_compatibility','--xr-mode','off',
        '--script','res://tools/probes/export_void_editor.gd','--','--out='+str(OUT)],
        stdout=stream,stderr=subprocess.STDOUT,timeout=150,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text=log.read_text(encoding='utf-8',errors='replace')
if result.returncode or 'SCRIPT ERROR' in text or 'Parse Error' in text or '\nERROR:' in text:
    raise SystemExit(text[-10000:])
manifest=json.loads((OUT/'manifest.json').read_text())
# Runtime-generated part defaults also drive validation and the native editor.
parts_path=ROOT/'commons/void/line_parts.json'
parts=json.loads(parts_path.read_text(encoding='utf-8'))
for floor in manifest['floors'].values():
    for item in floor['artifacts'].values():
        if item['parts']:
            key=item['artifact'].removeprefix('void_lines_')
            parts[key]={name:model['default'] for name,model in item['parts'].items()}
parts_path.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf-8')
manifest['source_files']={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
    for p in (ROOT/'commons/void').iterdir() if p.suffix in {'.gd','.tscn','.json'}}
manifest['source_files'].update({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
    for p in (ROOT/'commons/artifacts/construction_site').iterdir() if p.suffix in {'.gd','.tscn','.gdshader'}})
manifest['revision']=hashlib.sha256((OUT/'manifest.json').read_bytes()).hexdigest()[:12]
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps({'files':len(list(OUT.glob('*.glb'))),'bytes':sum(p.stat().st_size for p in OUT.glob('*.glb')),'failures':manifest['failures'],'shader_material_previews':manifest['shader_material_previews']}))
