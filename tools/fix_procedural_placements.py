"""Move the five desks off arrival markers; fit the local dome instance to its bay."""
from pathlib import Path
import copy, hashlib, json
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-procedural-generation-revised'
baseline=json.loads((O/'before.json').read_text())
keys=['PG_Branching_Growth','PG_Percolation_Network','PG_Caves_Mazes','PG_Sculpted_Forms','PG_Mirrored_Patterns']
changes=[]
for key in keys:
 p=R/'commons/maps'/key/'map_data.json';raw=p.read_text(encoding='utf-8')
 assert hashlib.sha256(p.read_bytes()).hexdigest()==baseline[p.relative_to(R).as_posix()],key
 old=json.loads(raw);d=copy.deepcopy(old)
 w=d['map_info']['dimensions']['width'];x=w//2;nx=x-5
 token=d['layers']['interactables'][3][x]
 assert token.startswith('pg_workshop_console')
 assert not d['layers']['interactables'][5][nx].strip()
 d['layers']['interactables'][5][nx]=token;d['layers']['interactables'][3][x]=' '
 changes.append({'map':key,'token':'pg_workshop_console','from':[x,3],'to':[nx,5],'rotation':180})
 if key=='PG_Sculpted_Forms':
  assert d['layers']['interactables'][12][22]=='dome'
  assert not d['layers']['interactables'][13][23].strip()
  d['layers']['interactables'][12][22]=' '
  d['layers']['interactables'][13][23]='dome:0:0:0.55'
  changes.append({'map':key,'token':'dome','from':[22,12],'to':[23,13],'scale':0.55})
 assert d['layers']['structure']==old['layers']['structure'] and d['layers']['utilities']==old['layers']['utilities']
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

# Replace only complete matching PG rows in the current plan text. Other chats own other rows.
p=R/'commons/data/museum/em_plan.json';raw=p.read_text(encoding='utf-8');before=json.loads(raw)
for key in keys:
 rows=[r for r in before['plans'] if r.get('map')==key]
 assert len(rows)==1
 old=rows[0];row=copy.deepcopy(old)
 for change in [c for c in changes if c['map']==key]:
  item=next(a for a in row['artifacts'] if a['token']==change['token'])
  assert item['cell']==change['from']
  for field in ['cell','tile_cell']:item[field]=change['to'].copy()
  item['ruled']['cell']=change['to'].copy()
  if 'scale' in change:item['scale']=change['scale']
 source=json.dumps(old,ensure_ascii=False);dest=json.dumps(row,ensure_ascii=False)
 assert raw.count(source)==1,key
 raw=raw.replace(source,dest,1)
after=json.loads(raw)
assert [r for r in before['plans'] if r.get('map') not in keys]==[r for r in after['plans'] if r.get('map') not in keys]
assert {k:v for k,v in before.items() if k!='plans'}=={k:v for k,v in after.items() if k!='plans'}
p.write_text(raw,encoding='utf-8')
(O/'placements.json').write_text(json.dumps({'changes':changes,'other_plan_rows_preserved':True,'structure_and_utilities_preserved':True,'artifact_algorithms_unchanged':True},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'desks':5,'dome_scale':0.55,'other_plan_rows_preserved':True}))
