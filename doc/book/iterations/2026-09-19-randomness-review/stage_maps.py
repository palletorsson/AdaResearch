"""Apply approved placement/opt-in changes, each guarded against its saved cell."""
from pathlib import Path
import json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
changes=[]
names=['Random_Pheromone'] if '--pheromone' in sys.argv else ['Random_Mushrooms','Random_Rotate_Random_XYZ']
for name in names:
 path=ROOT/f'commons/maps/{name}/map_data.json';d=read(path);grid=d['layers']['interactables']
 old=read(HERE/'before'/path.relative_to(ROOT));og=old['layers']['interactables']
 if name=='Random_Mushrooms':
  token=og[4][13]
  assert token.startswith('silhouette_arrivals') and not og[17][13].strip()
  if grid[4][13]==token:
   assert not grid[17][13].strip()
   grid[4][13]=og[17][13];grid[17][13]=token
  else:assert not grid[4][13].strip() and grid[17][13]==token
  changes.append(dict(map=name,action='move',token=token,before=[13,4],after=[13,17]))
 elif name=='Random_Rotate_Random_XYZ':
  token=og[10][6];new=token+'#stack_fit:10'
  assert token=='random_decay_multimesh' and grid[10][6] in [token,new]
  grid[10][6]=new
  changes.append(dict(map=name,action='configure',cell=[6,10],before=token,after=new))
 else:
  token=og[5][5];new=token+'#comparison:true#walk_seed:190919'
  assert token=='pheromone_terrain' and grid[5][5] in [token,new]
  grid[5][5]=new
  changes.append(dict(map=name,action='configure',cell=[5,5],before=token,after=new))
 path.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
record=HERE/'map-changes.json';previous=read(record) if record.exists() else []
previous=[x for x in previous if x['map'] not in names]
record.write_text(json.dumps(previous+changes,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Staged:',', '.join(names))
