"""Publish the reviewed wind-tunnel occurrence only, preserving fresh user data."""
import copy,hashlib,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/wind-tunnel-108';URL='http://localhost:3003/api/void-layout'
def read(name):return json.loads((OUT/name).read_text(encoding='utf8'))
for mode in ['desktop','xr']:
 assert read(f'native-{mode}.json')['passed']
 e=read(f'engine-{mode}.json');assert e['engine_exit']==0 and not e['errors']
assert hashlib.sha256((ROOT/'commons/artifacts/lattice_gas_pump/lattice_gas_pump.gd').read_bytes()).hexdigest()==(OUT/'original-source.sha256').read_text()
base=read('before.json')['rooms'];draft=read('draft-rooms.json')
with urllib.request.urlopen(URL,timeout=120) as r:p=json.load(r)
current=p['rooms'];assert current['floors'][108]==base['floors'][108],'Concurrent floor108 edits: merge explicitly.'
f=draft['floors'][108];old=base['floors'][108]
assert len(f['artifacts'])==len(old['artifacts'])==6
for item in old['artifacts']:
 if item['artifact']!='lattice_gas_pump':assert item in f['artifacts']
for key in old:
 if key!='artifacts':assert old[key]==f[key]
merged=copy.deepcopy(current);merged['floors'][108]=f
(OUT/'publish-before.json').write_text(json.dumps(p,indent=2)+'\n',encoding='utf8')
request=urllib.request.Request(URL,json.dumps({'rooms':merged,'revision':p['revision']}).encode(),{'Content-Type':'application/json'},method='POST')
with urllib.request.urlopen(request,timeout=120) as r:save=json.load(r)
with urllib.request.urlopen(URL,timeout=120) as r:after=json.load(r)
assert after['rooms']==merged
receipt={'passed':True,'floor':108,'retained_original_occurrences':6,'changed_occurrences':1,'preserved_other_floors':len(current['floors'])-1,'revision':after['revision'],'save':save}
(OUT/'publish.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
print('Published wind tunnel on108; retained the other5 originals and',receipt['preserved_other_floors'],'other floors.')
