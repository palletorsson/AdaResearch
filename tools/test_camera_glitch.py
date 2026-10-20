"""Native geometry, real shader fixtures, and two deliberate geometry faults."""
from pathlib import Path
import json, subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-camera-image-becomes-body/validation'
T=R/'ada_run/camera_glitch_tests';T.mkdir(exist_ok=True)
def run(script,name,render=False):
    target=O/(name+'.json')
    if target.exists():target.unlink()
    command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--script','res://'+script.relative_to(R).as_posix()]
    command+=['--no-window','--rendering-method','gl_compatibility'] if render else ['--headless']
    command+=['--','res://'+target.relative_to(R).as_posix()]
    with (O/(name+'.log')).open('w',encoding='utf-8') as log:
        process=subprocess.Popen(command,cwd=R,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        try:code=process.wait(timeout=40)
        except subprocess.TimeoutExpired:process.kill();process.wait();code=124
    d=json.loads(target.read_text()) if target.exists() else {}
    errors=[s for s in (O/(name+'.log')).read_text(encoding='utf-8').splitlines() if 'SCRIPT ERROR' in s or 'Shader compilation failed' in s]
    return {'exit':code,'passed':code==0 and d.get('passed',False) and not errors,'checks':len(d.get('checks',[])),'failures':[c['name'] for c in d.get('checks',[]) if not c['passed']],'script_errors':errors}
results={}
results['core']=run(R/'tools/probes/camera_glitch_test.gd','camera-core')
results['gpu']=run(R/'tools/probes/camera_glitch_gpu.gd','camera-gpu',True)
source=(R/'commons/artifacts/camera_glitch_study/receivers.gd').read_text()
probe=(R/'tools/probes/camera_glitch_test.gd').read_text()
for name,old,new in [('repeated-tile','(tile*7+5)%24','5'),('open-seam','var u:=uv.x*TAU','var u:=uv.x*PI')]:
    assert old in source
    model=T/(name+'.gd');model.write_text(source.replace(old,new),encoding='utf-8')
    test=T/(name+'-test.gd');test.write_text(probe.replace('res://commons/artifacts/camera_glitch_study/receivers.gd','res://'+model.relative_to(R).as_posix()),encoding='utf-8')
    results[name]=run(test,name)
(O/'camera-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print(json.dumps(results,indent=2))
assert results['core']['passed'] and results['gpu']['passed'],results
assert results['repeated-tile']['exit']==1 and 'tile shuffle visits every source tile exactly once' in results['repeated-tile']['failures']
assert results['open-seam']['exit']==1 and 'torus closes both geometric seams' in results['open-seam']['failures']
