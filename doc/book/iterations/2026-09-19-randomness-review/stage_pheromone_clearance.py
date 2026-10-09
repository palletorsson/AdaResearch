"""Use measured collision bounds to separate the plot, crosswall and retained ramp."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
path=ROOT/'commons/maps/Random_Pheromone/map_data.json';d=read(path);changes=read(HERE/'map-changes.json')
for layer,before,after,token in [('interactables',[5,3],[6,3],'pheromone_terrain#comparison:true#walk_seed:190919'),('utilities',[7,6],[10,6],'wp')]:
 grid=d['layers'][layer];x,z=before;a,b=after
 if grid[z][x]==token:
  assert not grid[b][a].strip();empty=grid[b][a];grid[z][x]=empty;grid[b][a]=token
  changes.append(dict(map='Random_Pheromone',action='move',layer=layer,token=token,before=before,after=after,empty=empty))
 else:assert not grid[z][x].strip() and grid[b][a]==token
for z in range(1,8):
 for x in range(2,11):
  old=d['layers']['structure'][z][x];assert old in ['0','1']
  if old=='0':
   d['layers']['structure'][z][x]='1'
   changes.append(dict(map='Random_Pheromone',action='layer-cell',layer='structure',cell=[x,z],before=old,after='1'))
write(path,d);write(HERE/'map-changes.json',changes)
print('Separated plot and ramp; explicit continuous source floor supports this restored exhibit and extends its authored crop.')
