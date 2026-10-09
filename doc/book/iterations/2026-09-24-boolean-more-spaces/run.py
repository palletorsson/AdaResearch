from pathlib import Path
import subprocess,os,shutil,time,json,hashlib
R=Path(__file__).resolve().parents[4]
O=Path(__file__).resolve().parent
S=R/'ada_run/boolean-more-spaces-isolated'
S.mkdir(parents=True,exist_ok=True)
for p in (R/'commons/artifacts/boolean_colour_chamber').glob('*'):
 if p.is_file() and p.suffix in ['.gd','.gdshader','.tscn']:
  t=S/p.relative_to(R);t.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,t)
p=R/'addons/godot-xr-tools/events/pointer_event.gd';t=S/p.relative_to(R);t.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,t)
shutil.copy2(O/'probe.gd',S/'probe.gd')
(S/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Boolean Colour Study â€” isolated verification"\nrun/main_scene="res://commons/artifacts/boolean_colour_chamber/more_spaces.tscn"\n[display]\nwindow/size/viewport_width=1440\nwindow/size/viewport_height=900\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n',encoding='utf-8')
exe='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
env=dict(os.environ);env['ADA_BOOLEAN_OUT']=str(O)
with (O/'import.log').open('w',encoding='utf-8') as f:
 p=subprocess.run([exe,'--headless','--editor','--path',str(S),'--quit'],stdout=f,stderr=subprocess.STDOUT,startupinfo=si,creationflags=subprocess.CREATE_NO_WINDOW,timeout=70)
print('Import return',p.returncode,flush=True)
if 'Parse Error:' in (O/'import.log').read_text(encoding='utf-8',errors='replace'):
 print((O/'import.log').read_text(encoding='utf-8',errors='replace'));raise SystemExit(1)
with (O/'engine.log').open('w',encoding='utf-8') as f:
 p=subprocess.Popen([exe,'--path',str(S),'--audio-driver','Dummy','--position','4000,4000','--resolution','1440x900','--','--verify'],stdout=f,stderr=subprocess.STDOUT,env=env,startupinfo=si,creationflags=subprocess.CREATE_NO_WINDOW)
 print('Owned isolated render PID',p.pid,flush=True)
 try:code=p.wait(timeout=280)
 except subprocess.TimeoutExpired:
  p.terminate();p.wait(timeout=10);code=124
print('Exit',code,flush=True)
print((O/'engine.log').read_text(encoding='utf-8',errors='replace')[-9500:])
raise SystemExit(code)
