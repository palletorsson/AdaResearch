"""Test browser-generated copy fixtures and real Godot instances without writing live rooms."""
from pathlib import Path
from copy import deepcopy
import hashlib, json, os, shutil, subprocess, urllib.request
from validate_void_rooms import validate, ROOT, VOID
from void_editor_io import commit

OUT=ROOT/'ada_run/void-copy-test'
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
godot=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
data=json.loads((OUT/'draft.json').read_text())
checks=[]
def check(name, condition):
    assert condition, name
    checks.append({'name':name,'passed':True})
check('Copied instances validate',not validate(data))
bad=deepcopy(data);bad['floors'][3]['copies'][0]['config']['only_parts']=['MissingPart']
check('Unknown copied part rejected',bool(validate(bad)))
bad=deepcopy(data);bad['floors'][3]['copies'][1]['id']=bad['floors'][3]['copies'][0]['id']
check('Duplicate copy ID rejected',bool(validate(bad)))
before=(VOID/'rooms.json').read_bytes()
request=urllib.request.Request('http://localhost:3003/api/void-layout',json.dumps({'rooms':data,'validateOnly':True}).encode(),{'Content-Type':'application/json'})
check('Shared browser save validator accepts copies',json.load(urllib.request.urlopen(request))['valid'])
target=OUT/'saved-layout.json';target.write_bytes(before)
check('Shared native writer saves copies',commit(OUT/'draft.json',hashlib.sha256(before).hexdigest(),target)['ok'])
check('Saved copies retain their full definitions',json.loads(target.read_text())==data)
for relative in ['commons/void/floor_content.gd','commons/void/lines_area.gd','tools/probes/void_copy_probe.gd','addons/void_floor_editor/document.gd']:
    (stage/relative).parent.mkdir(exist_ok=True,parents=True);shutil.copy2(ROOT/relative,stage/relative)
# Feed the file from the actual shared writer to the game's supported draft input.
shutil.copy2(target,stage/'copy-test-rooms.json')
process=subprocess.run([godot,'--headless','--path',str(stage),'--xr-mode','off','--script','res://tools/probes/void_copy_probe.gd','--','--void-start-floor=3','--void-draft=res://copy-test-rooms.json','--out='+str(OUT)],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=90,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=process.stdout+process.stderr;(OUT/'godot-copy.log').write_text(log,encoding='utf-8')
if process.returncode or 'SCRIPT ERROR' in log or '\nERROR:' in log:
    raise SystemExit(log[-12000:])
check('Real game copy assertions pass',json.loads((OUT/'godot-copies.json').read_text())['passed'])
check('Live floor layout never changed',(VOID/'rooms.json').read_bytes()==before)
(OUT/'save-validation.json').write_text(json.dumps({'passed':True,'checks':checks},indent=2))
print(f'{len(checks)} copy save checks passed; Godot assertions passed')
