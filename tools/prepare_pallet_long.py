"""Only expand the active pallet study to two standard board sheets."""
import json,os,uuid
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/pallet-long';OUT.mkdir(parents=True,exist_ok=True)
f=ROOT/'commons/void/rooms.json';text=f.read_text(encoding='utf-8');d=json.loads(text)
a=next(a for a in d['floors'][12]['artifacts'] if a['id']=='pallet-hand-workshop');assert a['config']['study']=='pallet_and'
if a['config'].get('board_count')!=2:
 (OUT/'before-rooms.json').write_text(text,encoding='utf-8');a['config']['board_count']=2
 tmp=f.with_name(f.name+'.'+uuid.uuid4().hex+'.tmp');tmp.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8');os.replace(tmp,f)
print('Two 2.4m sheets; working height and all other saved records preserved.')
