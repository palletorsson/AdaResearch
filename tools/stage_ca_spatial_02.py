"""Extend two reviewed CA floors from a fresh snapshot; never replace other floors."""
import copy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/ca-spatial-02'
base=json.loads((OUT/'before.json').read_text(encoding='utf8'))['rooms'];draft=copy.deepcopy(base)
catalog_path=ROOT/'commons/void/catalog.json';catalog=json.loads(catalog_path.read_text(encoding='utf8'))
for key,title,description in [
 ('void_ca_neighbour_slice','CA / nine neighbourhood addresses','One large depth slice of the real 27-address neighbourhood. Shares the original three-state solver, STEP, VIEW and REPLAY.'),
 ('void_ca_health_canopy','CA / health opens the ceiling','Eighty suspended louvers read the original proximity bridge health. Aperture is a second reading of the same scalar; no extra clock or support rule.')]:
 catalog['artifacts'][key]={'lookup_name':key,'name':title,'label':title,'scene':'res://commons/void/'+key.removeprefix('void_')+'.tscn','description':description,'interaction':'observe','museum_import':False}
catalog_path.write_text(json.dumps(catalog,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
f=draft['floors'][104];source=f['artifacts'][0];source['config']['curated_console']=True
for depth,x in [(-1,-13.8),(0,0),(1,13.8)]:
 f['artifacts'].append({'id':f'ca-neighbour-slice-{depth+1}','artifact':'void_ca_neighbour_slice','station':'NW','position':[x,-5.65],'height':0,'facing':0,'scale':1,'config':{'depth':depth,'source_id':source['id']}})
f=draft['floors'][107];source=next(a for a in f['artifacts'] if a['artifact']=='decaying_bridge')
f['artifacts'].append({'id':'ca-health-canopy','artifact':'void_ca_health_canopy','station':'NW','position':source['position'].copy(),'height':source['height'],'facing':source['facing'],'scale':1,'config':{'source_id':source['id']}})
(OUT/'draft-rooms.json').write_text(json.dumps(draft,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
print('Draft104: three source-linked slices and original controls remounted. Draft107: source-linked overhead louvers. No main layout saved.')
