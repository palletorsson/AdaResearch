"""Restage only the existing pallet work area; preserve every other floor edit."""
import json,os,uuid
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/pallet-logic';OUT.mkdir(parents=True,exist_ok=True)
f=ROOT/'commons/void/rooms.json';before=f.read_text(encoding='utf-8');d=json.loads(before)
record=next(a for a in d['floors'][12]['artifacts'] if a['id']=='pallet-hand-workshop')
assert record['artifact']=='pallet_assemblage'
if record.get('config',{}).get('study')!='pallet_and':
 (OUT/'before-rooms.json').write_text(before,encoding='utf-8')
 record.setdefault('config',{})['study']='pallet_and'
 # Existing individual overrides are user arrangements and are retained.
 tmp=f.with_name(f.name+'.'+uuid.uuid4().hex+'.tmp');tmp.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8');os.replace(tmp,f)
print('Pallet AND staged on Melencolia; all other records retained.')
