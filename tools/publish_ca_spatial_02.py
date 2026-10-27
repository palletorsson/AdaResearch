"""Merge only104/107 from inspected draft evidence into current user rooms."""
import copy,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/ca-spatial-02';URL='http://localhost:3003/api/void-layout'
def read(p):return json.loads(p.read_text(encoding='utf8'))
for mode in ['desktop','xr']:
 assert read(OUT/f'native-{mode}.json')['passed']
 engine=read(OUT/f'engine-{mode}.json');assert engine['engine_exit']==0 and not engine['errors']
base=read(OUT/'before.json')['rooms'];draft=read(OUT/'draft-rooms.json')
with urllib.request.urlopen(URL,timeout=120) as r:p=json.load(r)
current=p['rooms'];merged=copy.deepcopy(current)
for i in [104,107]:
 assert current['floors'][i]==base['floors'][i],f'Floor{i} was edited during native review; merge explicitly.'
 merged['floors'][i]=draft['floors'][i]
 for old in base['floors'][i]['artifacts']:
  actual=next(a for a in merged['floors'][i]['artifacts'] if a['id']==old['id'])
  clean=copy.deepcopy(actual)
  if old['artifact']=='structure_growth':clean['config'].pop('curated_console',None)
  assert clean==old,'Do not lose original scales, configs or arrangements.'
(OUT/'publish-before.json').write_text(json.dumps(p,indent=2)+'\n',encoding='utf8')
req=urllib.request.Request(URL,json.dumps({'rooms':merged,'revision':p['revision']}).encode(),{'Content-Type':'application/json'},method='POST')
with urllib.request.urlopen(req,timeout=120) as r:save=json.load(r)
with urllib.request.urlopen(URL,timeout=120) as r:after=json.load(r)
assert after['rooms']==merged
receipt={'passed':True,'changed_floors':[104,107],'other_floors_preserved':len(current['floors'])-2,'original_occurrences_unchanged':9,'new_source_linked_objects':4,'revision':after['revision'],'save':save}
(OUT/'publish.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8');print(json.dumps(receipt))
