"""Install the tested room-scale host only in the ACO hall."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Ant_Colony_Optimization'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,indent=2,ensure_ascii=False)+'\n')
art=R/'commons/artifacts/ant_colony_walk'
write(art/'ant_colony_walk.gd','extends "study.gd"\n## Permanent museum instance of the exact printed learner host.\n')
for name in ['colony.gd','point_body.gd','study.gd']:
 shutil.copy2(R/'doc/book/studies/swarm-through-the-hands'/ID/name,art/name)
write(art/'ant_colony_walk.tscn','''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="ant_colony_walk.gd" id="1"]

[node name="AntColonyWalk" type="Node3D"]
script = ExtResource("1")
''')
dump(R/'commons/artifacts/registry/ant_colony_walk.json',{'artifacts':{'ant_colony_walk':{
 'lookup_name':'ant_colony_walk','name':'Two trails underfoot','scene':'res://commons/artifacts/ant_colony_walk/ant_colony_walk.tscn',
 'description':'Walk among24 carried PointBody spheres. Searching reads food/leaves home; returning reverses channels. Hold to pause and move. Two control banks.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'map_sequences':['swarmintelligence'],
 'footprint':[13,4,13],'size_group':'world_scale','qfep_connection':'Different states read and sustain different shared traces. Replacement preserves inherited marks; clearing removes them. Brightness alone establishes no optimality.',
 'tags':['swarm','pheromone','walk-in','grabbable','two-channel'],'parameters':{'footprint':[13,4,13],'size_group':'world_scale'}}}})
mp=R/'commons/maps'/ID/'map_data.json';m=read(mp)
for row in m['layers']['interactables']:
 for x,token in enumerate(row):
  if isinstance(token,str) and (token.startswith('AntColonyV2') or token.startswith('ant_colony_walk')):row[x]='ant_colony_walk:180:0:1'
m['map_info']['description']='Walk among the carried PointBody spheres in a twelve-metre two-channel trail field.'
m['map_info']['metadata']['design_notes']='Open field; twelve-metre floor display centred8,8, controls at both ends. Existing north/south passages retained. No Y-corridor or shortest-path claim.'
dump(mp,m)
pp=R/'commons/data/museum/em_plan.json';p=read(pp);row=next(x for x in p['plans'] if x.get('map')==ID)
for a in row['artifacts']:
 if a['token'] in ('AntColonyV2','ant_colony_walk'):
  a['token']='ant_colony_walk';a['rotation']=180;a['scale']=1.0
# Preserve the runtime file's compact serialization.
write(pp,json.dumps(p,ensure_ascii=False,separators=(',',':'))+'\n')
print('Registered permanent walk-in ACO; other runtime rows preserved.')
