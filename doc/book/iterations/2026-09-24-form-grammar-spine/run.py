from pathlib import Path
import hashlib, json, os, shutil, subprocess
ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
STAGE = ROOT / 'ada_run/form-grammar-spine-isolated'
STAGE.mkdir(parents=True, exist_ok=True)
sources = ['commons/mesh_grammar/mesh_data.gd','commons/mesh_grammar/mesh_selector.gd','commons/mesh_grammar/mesh_rule.gd','commons/mesh_grammar/operations/inset_face_op.gd','commons/mesh_grammar/operations/extrude_face_op.gd','commons/maps/LSystems_Shape_Grammars/map_data.json']
sources += [p.relative_to(ROOT).as_posix() for p in (ROOT / 'commons/artifacts/form_grammar_family').glob('*') if p.suffix in ['.gd','.tscn']]
for source in sources:
 target = STAGE / source
 target.parent.mkdir(parents=True, exist_ok=True)
 shutil.copy2(ROOT/source, target)
shutil.copy2(OUT/'probe.gd', STAGE/'probe.gd')
(STAGE/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Form grammar spine study"\nrun/main_scene="res://commons/artifacts/form_grammar_family/study.tscn"\n[display]\nwindow/size/viewport_width=1440\nwindow/size/viewport_height=900\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8')
exe = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
si = subprocess.STARTUPINFO();si.dwFlags |= subprocess.STARTF_USESHOWWINDOW;si.wShowWindow = 0
with (OUT/'import.log').open('w',encoding='utf-8') as log:
 imported = subprocess.run([exe,'--headless','--editor','--path',str(STAGE),'--quit'],stdout=log,stderr=subprocess.STDOUT,startupinfo=si,creationflags=subprocess.CREATE_NO_WINDOW,timeout=60)
text = (OUT/'import.log').read_text(encoding='utf-8',errors='replace')
if imported.returncode or 'SCRIPT ERROR' in text:
 print(text);raise SystemExit(1)
env=dict(os.environ);env['ADA_GRAMMAR_OUT']=str(OUT)
with (OUT/'engine.log').open('w',encoding='utf-8') as log:
 process = subprocess.Popen([exe,'--path',str(STAGE),'--rendering-method','forward_plus','--audio-driver','Dummy','--position','4000,4000','--resolution','1440x900','--','--verify'],stdout=log,stderr=subprocess.STDOUT,startupinfo=si,creationflags=subprocess.CREATE_NO_WINDOW,env=env)
 print('Owned isolated Godot PID',process.pid,flush=True)
 try: code=process.wait(timeout=120)
 except subprocess.TimeoutExpired:
  process.terminate();process.wait(timeout=10);code=124
print((OUT/'engine.log').read_text(encoding='utf-8',errors='replace')[-5000:])
(OUT/'source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2)+'\n',encoding='utf-8')
if (OUT/'native-checks.json').exists():
 data=json.loads((OUT/'native-checks.json').read_text(encoding='utf-8'));print(sum(c['pass'] for c in data['checks']),'/',len(data['checks']),'native checks pass')
raise SystemExit(code)
