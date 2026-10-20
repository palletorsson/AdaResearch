"""Place one comparison without moving existing works or changing the spine."""
from pathlib import Path
import copy,json,shutil
import em_map_halls
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-geometry-noise-test'
p=R/'commons/maps/Random_Noise_Types/map_data.json'
assert p.read_bytes()==(O/'before/map_data.json').read_bytes(),'Source changed since baseline'
d=json.loads(p.read_text(encoding='utf-8'));before=copy.deepcopy(d)
assert not str(d['layers']['interactables'][11][3]).strip()
d['layers']['interactables'][11][3]='geometry_noise:90#plinth:0#pin:true'
d['map_info']['description'] += ' An optional Uncertain Surface comparison follows the sampling displays: one saved Gaussian displacement field, two indexed surfaces, measured deviation and local replay controls.'
assert d['layers']['structure']==before['layers']['structure']
assert d['layers']['utilities']==before['layers']['utilities']
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=R/'commons/artifacts/registry/randomness.json'
registry_text=p.read_text(encoding='utf-8')
registry=json.loads(registry_text);assert 'geometry_noise' not in registry['artifacts']
registry['artifacts']['geometry_noise']={
 'lookup_name':'geometry_noise','name':'The Uncertain Surface',
 'scene':'res://commons/artifacts/geometry_noise/GeometryNoiseTest.tscn',
 'description':'Compare fixed and Gaussian-displaced 2m surfaces. Same seed and connectivity; hand slider scales saved samples. Nearby next-seed, zero, reset and edge overlay controls. Measured RMS, maximum and centroid deviation; surfaces have no collision.',
 'category':'procedural','complexity':'intermediate','map_sequences':['noise'],
 'map_ready':True,'include_in_map_data':True,
 'parameters':{'footprint':[6,3.1,5],'size_group':'room_scale'},
 'signals':['experiment_updated'],
 'interactions':['Slide strength','Next seed','Zero displacement','Reset seed1847/strength0.18','Show/hide edge overlay'],
 'qfep_connection':'Compare how much a geometric embedding changes while its connectivity stays fixed. This measures deviation; neither failure nor adaptive organisation is inferred.',
 'tags':['noise','gaussian','geometry','replay','comparison','measurements']}
shutil.copy2(p,O/'before/randomness-registry.json')
# Preserve all existing registry formatting; append inside the artifacts object.
import re
tail=re.search(r'\s*}\s*}\s*$',registry_text)
assert tail
entry=json.dumps({'geometry_noise':registry['artifacts']['geometry_noise']},ensure_ascii=False,indent=2)[2:-2]
updated=registry_text[:tail.start()]+',\n'+entry+registry_text[tail.start():]
assert json.loads(updated)==registry
p.write_bytes(updated.encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';raw=p.read_bytes();plan=json.loads(raw);old=copy.deepcopy(plan)
i=next(i for i,row in enumerate(plan['plans']) if row['map']=='Random_Noise_Types');row=plan['plans'][i]
new=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
em_map_halls.normalize_row(new,True,False);plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(old['plans'],plan['plans'])) if j!=i)
assert all(old[k]==plan[k] for k in plan if k!='plans')
assert p.read_bytes()==raw,'Plan changed during derivation'
(O/'before/plan-row.json').write_text(json.dumps(row,indent=2),encoding='utf-8')
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'))
# Live authoring plan is independent; replace only its matching row as well.
live=R/'ada_run/em_plan.json'
if live.exists():
 raw=live.read_bytes();data=json.loads(raw)
 j=next(j for j,r in enumerate(data['plans']) if r['map']=='Random_Noise_Types')
 data['plans'][j]=new
 assert live.read_bytes()==raw,'Live plan changed during derivation'
 live.write_bytes(json.dumps(data,ensure_ascii=False).encode('utf-8'))
(O/'placement.json').write_text(json.dumps({'host':'Random_Noise_Types','cell':[3,11],'rotation_degrees':90,
 'retained_existing_artifacts':True,'structure_unchanged':True,'utilities_unchanged':True,
 'other_plan_rows_unchanged':True,'new_plan_row':new},indent=2),encoding='utf-8')
print('Registered and placed one artifact; all existing works and other plan rows preserved.')
