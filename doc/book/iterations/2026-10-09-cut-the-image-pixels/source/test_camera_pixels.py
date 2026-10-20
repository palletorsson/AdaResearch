"""Check actual pixel shaders; preserve earlier study receipts."""
from pathlib import Path
import subprocess,json
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-cut-the-image-pixels/validation'
T=R/'ada_run/camera_pixel_tests';T.mkdir(exist_ok=True)
def run(script,name,render):
 target=O/(name+'.json')
 if target.exists():target.unlink()
 cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--script','res://'+script.relative_to(R).as_posix()]
 cmd+=['--no-window','--rendering-method','gl_compatibility'] if render else ['--headless']
 cmd+=['--','res://'+target.relative_to(R).as_posix()]
 with (O/(name+'.log')).open('w',encoding='utf-8') as log:
  p=subprocess.Popen(cmd,cwd=R,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
  try:code=p.wait(timeout=45)
  except subprocess.TimeoutExpired:p.kill();p.wait();code=124
 data=json.loads(target.read_text()) if target.exists() else {}
 text=(O/(name+'.log')).read_text(encoding='utf-8')
 errors=[s for s in text.splitlines() if 'SCRIPT ERROR' in s or 'Shader compilation failed' in s or 'SHADER ERROR' in s]
 return {'exit':code,'passed':code==0 and data.get('passed',False) and not errors,'checks':len(data.get('checks',[])),'failures':[x['name'] for x in data.get('checks',[]) if not x['passed']],'errors':errors}
results={}
for name,script,render in [('geometry-regression','camera_glitch_test.gd',False),('spatial-gpu-regression','camera_glitch_gpu.gd',True),('pixels','camera_pixels_gpu.gd',True)]:
 results[name]=run(R/'tools/probes'/script,name,render)
shader=(R/'commons/artifacts/camera_glitch_study/pixel_surface.gdshader').read_text();probe=(R/'tools/probes/camera_pixels_gpu.gd').read_text()
for name,old,new in [('stride-removed','size.x+int(round(amount*float(max(1,size.x/12))))','size.x'),('saved-is-live','texture(held_frame,','texture(camera_frame,')]:
 assert old in shader
 path=T/(name+'.gdshader');path.write_text(shader.replace(old,new),encoding='utf-8')
 test=T/(name+'.gd');test.write_text(probe.replace('res://commons/artifacts/camera_glitch_study/pixel_surface.gdshader','res://'+path.relative_to(R).as_posix()),encoding='utf-8')
 results[name]=run(test,name,True)
(O/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8');print(json.dumps(results,indent=2))
assert all(results[x]['passed'] for x in ['geometry-regression','spatial-gpu-regression','pixels'])
assert results['stride-removed']['exit']==1 and 'wrong stride reads row8 column60' in results['stride-removed']['failures']
assert results['saved-is-live']['exit']==1 and 'held block reads the actual saved red texture' in results['saved-is-live']['failures']
