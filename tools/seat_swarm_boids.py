"""Lift the two tabletop exhibits without changing their simulation rules."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-boids-who-is-near'
ID='SwarmIntelligence_Boids_Algorithm'
def save(rel,data,compact=False):
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
 p.write_bytes((json.dumps(data,ensure_ascii=False,indent=None if compact else 2,separators=(',',':') if compact else None)+'\n').encode())
rel=f'commons/maps/{ID}/map_data.json';data=json.loads((R/rel).read_text(encoding='utf8'))
for row in data['layers']['interactables']:
 for i,token in enumerate(row):
  if token.split(':')[0]=='boids_aquarium':row[i]='boids_aquarium:0#plinth:0.5'
  if token.split(':')[0]=='flocking_controls':row[i]='flocking_controls:0#plinth:0.85'
# The old exit at10,10 shares the newly raised controls' approach.
# Use the existing three-cell opening in the south perimeter.
for row in data['layers']['utilities']:
 for i,token in enumerate(row):
  if token=='t':row[i]=''
data['layers']['utilities'][12][6]='t'
save(rel,data)
rel='commons/data/museum/em_plan.json';data=json.loads((R/rel).read_text(encoding='utf8'))
row=next(r for r in data['plans'] if r.get('map')==ID)
for a in row['artifacts']:
 if a['token'] in ['boids_aquarium','flocking_controls']:
  a.setdefault('config',{}).update(plinth='0.5' if a['token']=='boids_aquarium' else '0.85')
  a['config'].pop('offset',None)
  a.pop('offset',None)
save(rel,data,True)
print('Boids: tank plinth0.5m / controls plinth0.85m, with existing automatic seating. Other halls unchanged.')
