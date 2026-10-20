from pathlib import Path
import json,shutil,copy
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-flow-directions-already-here'
def read(rel):return json.loads((R/rel).read_text(encoding='utf8'))
def save(rel,d):
 p=R/rel;q=O/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
 p.write_bytes((json.dumps(d,ensure_ascii=False,indent=None if 'em_plan.json' in rel else 2,separators=(',',':') if 'em_plan.json' in rel else None)+'\n').encode('utf8'))
rel='commons/artifacts/registry/algorithms_misc.json';d=read(rel)
# Preserve every other placement of the full-size exhibit.
baseline=O/'before'/rel
if baseline.exists():d['artifacts']['FlowFieldMain']=json.loads(baseline.read_text(encoding='utf8'))['artifacts']['FlowFieldMain']
a=copy.deepcopy(d['artifacts']['FlowFieldMain'])
a.update(lookup_name='flow_field_table',name='Flow field / live museum table',category='swarmintelligence')
d['artifacts']['flow_field_table']=a
a.update(scene='res://commons/artifacts/flow_museum/flow_museum.tscn',description='Live overhead view of the existing 200-agent, 40 by 40 flow field on a bounded 2.95 metre museum table. The original route, wind and noise tour runs in a private physics world.',footprint=[3,2,3],size_group='medium')
a.setdefault('parameters',{}).update(footprint=[3,2,3],size_group='medium')
a['geometry_spec']['animation']={'type':'live_viewport','driven_by':'original flow-field simulation','affects':['display_texture']}
a['spatial_profile'].update(range=3,derived_from='bounded outer table; private simulation excluded',derived_at='2026-10-10')
a['dna']['default']='scenario=tour, field_display=arrows: original simulation viewed on a bounded table. Existing full-size FlowFieldMain token is preserved.'
a['measurements']={'aabb_size':[2.95,1.7,2.95],'aabb_center':[0,.85,0],'grid_cells':[3,3],'max_dimension_m':2.95,'source':'Outer table; private full-size simulation excluded.'}
a.setdefault('spatial_needs',{}).update(footprint_cells=9,measured_footprint_cells=9,footprint_source='table_adapter_geometry',preferred_zone='teaching',clearance={'front':1,'back':0,'left':0,'right':0})
save(rel,d)
rel='commons/maps/SwarmIntelligence_FlowFields/map_data.json';p=R/rel
text=p.read_text(encoding='utf8');data=json.loads(text)
layer=data['layers']['interactables']
for row in layer:
 for i,token in enumerate(row):
  if token.startswith(('FlowFieldMain','flow_field_table')):row[i]=''
layer[2][4]='flow_field_table:90'
lines=text.splitlines();start=next(i for i,l in enumerate(lines) if '"interactables": [' in l)
for j,row in enumerate(layer):lines[start+j+1]='   [ '+', '.join(json.dumps(x) for x in row)+' ]'+(',' if j<len(layer)-1 else '')
p.write_text('\n'.join(lines)+'\n',encoding='utf8')
rel='commons/data/museum/em_plan.json';d=read(rel)
row=next(x for x in d['plans'] if x.get('map')=='SwarmIntelligence_FlowFields')
a=next(x for x in row['artifacts'] if x['token'] in ['FlowFieldMain','flow_field_table'])
a.update(token='flow_field_table',cell=[4,2],tile_cell=[4,2],rotation=90);a['ruled']['cell']=[4,2]
save(rel,d)
print('This hall uses flow_field_table at4,2 yaw90. Other placements and original flow algorithms unchanged.')
