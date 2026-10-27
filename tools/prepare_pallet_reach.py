"""Apply only the reachable track profile to the existing workshop."""
import json,os,uuid
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/pallet-reach';OUT.mkdir(parents=True,exist_ok=True)
f=ROOT/'commons/void/rooms.json';text=f.read_text(encoding='utf-8');d=json.loads(text)
a=next(a for a in d['floors'][12]['artifacts'] if a['id']=='pallet-hand-workshop');assert a['config']['study']=='pallet_and'
if a['config'].get('track_height')!=.6:
 (OUT/'before-rooms.json').write_text(text,encoding='utf-8');a['config']['track_height']=.6
 tmp=f.with_name(f.name+'.'+uuid.uuid4().hex+'.tmp');tmp.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8');os.replace(tmp,f)
print('Board top at0.6m, crate supports and integrated edge controls; other records unchanged.')
