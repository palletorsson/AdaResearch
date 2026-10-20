"""Seat the existing simulation in a bounded live display, not a scaled physics world."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside'
def read(rel):return json.loads((R/rel).read_text(encoding='utf8'))
def save(rel,d):
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
 p.write_text(json.dumps(d,ensure_ascii=False,indent=None if 'em_plan.json' in rel else 2,separators=(',',':') if 'em_plan.json' in rel else None)+'\n',encoding='utf8')
rel='commons/artifacts/registry/swarmintelligence.json';d=read(rel)
a=d['artifacts']['PhysarumColony']
a.update(scene='res://commons/artifacts/physarum_museum/physarum_museum.tscn',category='swarmintelligence',description='Live overhead view of the original 300-agent Physarum simulation, contained on a 2.95 metre museum table. Three-sensor movement, deposition, diffusion, decay and the 20-second anchor carousel remain in the original private simulation world.',footprint=[3,2,3],size_group='medium')
a['parameters'].update(footprint=[3,2,3],size_group='medium')
a['measurements']={'aabb_size':[2.95,1.7,2.95],'aabb_center':[0,.85,0],'grid_cells':[3,3],'max_dimension_m':2.95,'source':'Table adapter geometry; private 50m simulation excluded from outer-world footprint.'}
a['spatial_needs'].update(footprint_cells=9,measured_footprint_cells=9,footprint_source='table_adapter_geometry',preferred_zone='teaching',clearance={'front':1,'back':0,'left':0,'right':0})
a['geometry_spec']['animation']={'type':'live_viewport','driven_by':'original colony physics updates','affects':['display_texture']}
save(rel,d)
rel='commons/maps/SwarmIntelligence_PhysarumColony/map_data.json';d=read(rel)
layer=d['layers']['interactables']
for row in layer:
 for i,token in enumerate(row):
  if token.startswith('PhysarumColony'):row[i]=''
layer[2][4]='PhysarumColony:90'
p=R/rel;q=O/'before'/rel
if not q.exists():q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
original=q.read_text(encoding='utf8')
old_row='[ "", "", "", "", "", "PhysarumColony:90", "", "", "", "", "", "ant_agent", "" ]'
new_row='[ "", "", "", "", "", "", "", "", "", "", "", "ant_agent", "" ]'
assert old_row in original
lines=original.replace(old_row,new_row).splitlines()
start=next(i for i,line in enumerate(lines) if '"interactables": [' in line)
lines[start+3]='   [ "", "", "", "", "PhysarumColony:90", "", "", "", "", "", "", "", "" ],'
p.write_text('\n'.join(lines)+'\n',encoding='utf8')
rel='commons/data/museum/em_plan.json';d=read(rel)
row=next(x for x in d['plans'] if x.get('map')=='SwarmIntelligence_PhysarumColony')
a=next(x for x in row['artifacts'] if x['token']=='PhysarumColony')
a.update(cell=[4,2],tile_cell=[4,2],rotation=90)
a['ruled']['cell']=[4,2]
save(rel,d)
print('Same registered colony, live 2.95m display; authored placement and runtime museum plan agree.')
