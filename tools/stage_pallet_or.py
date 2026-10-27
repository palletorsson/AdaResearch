"""Append OR only after its real-physics checks; preserve the latest existing floor records."""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/pallet-or';URL='http://localhost:3003/api/void-layout'
def post(d):
 req=urllib.request.Request(URL,json.dumps(d).encode(),{'Content-Type':'application/json'},method='POST')
 return json.load(urllib.request.urlopen(req,timeout=90))
assert json.loads((OUT/'checks.json').read_text(encoding='utf-8'))['passed']
now=json.load(urllib.request.urlopen(URL));rooms=copy.deepcopy(now['rooms']);record=json.loads((OUT/'placement.json').read_text(encoding='utf-8'))
existing=next((a for a in rooms['floors'][12]['artifacts'] if a['id']==record['id']),None)
if existing is not None:
 assert existing==record,'Existing OR was edited; do not replace it'
else:rooms['floors'][12]['artifacts'].append(record)
valid=post({'rooms':rooms,'validateOnly':True});(OUT/'validation.json').write_text(json.dumps(valid,indent=2)+'\n',encoding='utf-8');assert valid['valid'],valid
result=post({'rooms':rooms,'revision':now['revision']});(OUT/'save-receipt.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');assert result['saved'],result
print('OR added on floor12; all existing records preserved.')
