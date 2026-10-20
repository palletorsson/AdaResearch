"""Original museum inventory + real desktop/XR landing regression."""
from pathlib import Path
import json, os, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-museum-objects-and-landings'
OUT.mkdir(parents=True,exist_ok=True)
if '--staged' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
godot=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
receipt={}
for label,probe in [('inventory','void_inventory_probe.gd'),('fall','void_fall_probe.gd'),('landing','void_corner_landings_probe.gd')]:
    shutil.copy2(ROOT/'tools/probes'/probe,stage/'tools/probes'/probe)
    with (OUT/(label+'.log')).open('w',encoding='utf-8') as log:
        result=subprocess.run([godot,'--headless','--fixed-fps','60','--path',str(stage),'--xr-mode','off',
            '--script','res://tools/probes/'+probe,'--','--out='+str(OUT)],stdout=log,stderr=log,timeout=120,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    text=(OUT/(label+'.log')).read_text(encoding='utf-8',errors='replace')
    assert result.returncode==0 and 'SCRIPT ERROR' not in text and '\nERROR:' not in text,text[-5000:]
    receipt[label]={'exit':result.returncode,'shutdown_warning':'ObjectDB instances leaked' in text}
native=json.loads((stage/'inventory.json').read_text())
plan=json.loads((OUT/'inventory.json').read_text())
missing=[]
for item in plan['coverage']:
    if item['status']!='added': continue
    suffix='/Content%d/%s/Artifact'%(item['floor'],item['id'])
    if not any(n['node'].endswith(suffix) and n['scene']==item['scene'] for n in native): missing.append(item['id'])
assert not missing,missing
fall=json.loads((OUT/'checks.json').read_text()); landing=json.loads((OUT/'landing-checks.json').read_text())
assert fall['passed'] and landing['passed']
receipt.update(passed=True,original_placements=len(plan['coverage']),added_verified=sum(c['status']=='added' for c in plan['coverage']),
    native_assertions=len(fall['checks'])+len(landing['checks']),scope='Godot 4.6; real scenes and Jolt; synthetic XRTools tracking, not a physical headset test.')
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt),flush=True)
