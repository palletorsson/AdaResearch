"""Focused free-fall policy check using production game/body and actual Jolt contacts."""
from pathlib import Path
import json,subprocess
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/safe-falls';OUT.mkdir(exist_ok=True)
rooms=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf8'))
for floor in rooms['floors']:
 for key in ['artifacts','props','walls','copies','construction','impact_cells']:floor[key]=[]
 floor['origin']=False;floor['supply_leads']=False;floor.pop('basin',None)
draft=OUT/'empty-encounters.json';draft.write_text(json.dumps(rooms),encoding='utf8')
with acquire_native_slot('Safe falling / production physics'):
 stage=stage_runtime()
 with (OUT/'native.log').open('w',encoding='utf8') as log:
  r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(stage),'--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_safe_fall_probe.gd','--','--no-bridges','--void-start-floor=0','--void-draft='+str(draft),'--out='+str(OUT)],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
text=(OUT/'native.log').read_text(encoding='utf8',errors='replace');assert r.returncode==0 and 'SCRIPT ERROR' not in text,text[-6500:]
receipt=json.loads((OUT/'checks.json').read_text(encoding='utf8'));assert receipt['passed'],receipt
print(str(len(receipt['checks']))+' safe-fall checks passed')
