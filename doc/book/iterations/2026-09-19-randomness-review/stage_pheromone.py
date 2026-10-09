"""Give the restored comparison its own footprint; preserve all four works and ramp."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
path=ROOT/'commons/maps/Random_Pheromone/map_data.json';d=read(path);grid=d['layers']['interactables']
changes=read(HERE/'map-changes.json')
for before,after,token in [([5,5],[5,3],'pheromone_terrain#comparison:true#walk_seed:190919'),([4,5],[2,5],'dark_sphere')]:
 x,z=before;a,b=after
 if grid[z][x]==token:
  assert not grid[b][a].strip();empty=grid[b][a];grid[z][x]=empty;grid[b][a]=token
  changes.append(dict(map='Random_Pheromone',action='move',token=token,before=before,after=after,empty=empty))
 else:assert not grid[z][x].strip() and grid[b][a]==token
museum=dict(piers=False,floor_cells=[[x,z] for z in range(1,8) for x in range(2,8)])
if d['map_info'].get('museum')!=museum:
 assert 'museum' not in d['map_info']
 changes.append(dict(map='Random_Pheromone',action='museum-config',before=None,after=museum))
 d['map_info']['museum']=museum
write(path,d);write(HERE/'map-changes.json',changes)
print('Staged pheromone comparison, witness sphere and continuous local museum floor; all four artifacts and wp retained.')
