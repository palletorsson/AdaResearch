from pathlib import Path
import json
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
STAGE = ROOT / 'ada_run/facade-screenshots-isolated'
STAGE.mkdir(parents=True, exist_ok=True)
for folder in ['commons/facade_parts', 'commons/artifacts/facade_builder', 'commons/composition']:
    shutil.copytree(ROOT / folder, STAGE / folder, dirs_exist_ok=True)
shutil.copy2(OUT / 'capture.gd', STAGE / 'capture.gd')
(STAGE / 'capture.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://capture.gd" id="1"]\n[node name="FacadeScreenshots" type="Node3D"]\nscript = ExtResource("1")\n', encoding='utf-8')
(STAGE / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Facade screenshots"\nrun/main_scene="res://capture.tscn"\n[display]\nwindow/size/viewport_width=1440\nwindow/size/viewport_height=900\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
exe = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
si = subprocess.STARTUPINFO()
si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
si.wShowWindow = 0
with (OUT / 'import.log').open('w', encoding='utf-8') as log:
    result = subprocess.run([exe, '--headless', '--editor', '--path', str(STAGE), '--quit'], stdout=log, stderr=subprocess.STDOUT, startupinfo=si, creationflags=subprocess.CREATE_NO_WINDOW, timeout=70)
print('Import', result.returncode, flush=True)
if 'Parse Error:' in (OUT / 'import.log').read_text(encoding='utf-8', errors='replace'):
    print((OUT / 'import.log').read_text(encoding='utf-8', errors='replace'))
    raise SystemExit(1)
env = dict(os.environ)
env['ADA_FACADE_CAPTURE_OUT'] = str(OUT)
with (OUT / 'engine.log').open('w', encoding='utf-8') as log:
    proc = subprocess.Popen([exe, '--path', str(STAGE), '--rendering-method', 'forward_plus', '--audio-driver', 'Dummy', '--position', '4000,4000', '--resolution', '1440x900'], stdout=log, stderr=subprocess.STDOUT, startupinfo=si, creationflags=subprocess.CREATE_NO_WINDOW, env=env)
    print('Owned render PID', proc.pid, flush=True)
    try:
        code = proc.wait(timeout=160)
    except subprocess.TimeoutExpired:
        proc.terminate()
        proc.wait(timeout=10)
        code = 124
print((OUT / 'engine.log').read_text(encoding='utf-8', errors='replace')[-4500:])
if code == 0:
    captures = json.loads((OUT / 'captures.json').read_text(encoding='utf-8'))
    assert len(captures) == 8 and all(c['composed'] and c['saved'] for c in captures)
    print('Eight existing facade presets captured.')
raise SystemExit(code)
