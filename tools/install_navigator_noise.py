"""Guarded one-time placement; preserve all other hall works and generated plan rows."""
from pathlib import Path
import copy,json,re
import em_map_halls
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-navigator-an-imperfect-observation'
p=R/'commons/maps/SwarmIntelligence_Agent_Based_Modeling_ABM/map_data.json'
raw=p.read_bytes();assert raw==(O/'before/map_data.json').read_bytes()
d=json.loads(raw);assert not str(d['layers']['interactables'][8][3]).strip()
d['layers']['interactables'][8][3]='navigator_noise:180#pin:1#plinth:0'
d['map_info']['description']+=' A paired navigator compares accurate range with recorded range error or observation dropout; the world and detour remain fixed.'
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=R/'commons/artifacts/registry/swarmintelligence.json';raw=p.read_text(encoding='utf-8');data=json.loads(raw)
assert 'navigator_noise' not in data['artifacts']
entry={'lookup_name':'navigator_noise','name':'The Obstacle / The Reading / The Command','scene':'res://commons/artifacts/navigator_noise/NavigatorNoise.tscn','description':'Two inherited point spheres follow a known detour around a fixed disc. Compare true and noisy clearance, then missing observations with STOP or HOLD. One shared release, saved seed, measured path, contact and deadline. Explicit 2D kinematic course with swept contact; no navmesh or learning claim.','category':'swarmintelligence','complexity':'intermediate','map_sequences':['swarmintelligence'],'map_ready':True,'include_in_map_data':True,'parameters':{'footprint':[4.35,4.46,1.8],'size_group':'room_scale'},'interactions':['Pull lower point up/down then release','Strength slider','Run/pause','Replay','Noise/dropout mode','Stop/hold fallback','Next seed','Reset'],'qfep_connection':'Distinguish a shared environment from what an agent receives. Missing information does not prescribe one action; the fallback is a design choice.','tags':['perception','navigation','noise','dropout','point lineage']}
tail=re.search(r'\s*}\s*}\s*$',raw);assert tail
new=raw[:tail.start()]+',\n'+json.dumps({'navigator_noise':entry},ensure_ascii=False,indent=2)[2:-2]+raw[tail.start():]
expected=copy.deepcopy(data);expected['artifacts']['navigator_noise']=entry;assert json.loads(new)==expected
p.write_bytes(new.encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';raw=p.read_bytes();plan=json.loads(raw);before=copy.deepcopy(plan)
i=next(i for i,x in enumerate(plan['plans']) if x['map']=='SwarmIntelligence_Agent_Based_Modeling_ABM');row=plan['plans'][i]
updated=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
em_map_halls.normalize_row(updated,True,False);plan['plans'][i]=updated
assert all(a==b for j,(a,b) in enumerate(zip(before['plans'],plan['plans'])) if j!=i)
assert p.read_bytes()==raw
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'))
(O/'placement.json').write_text(json.dumps({'map':'SwarmIntelligence_Agent_Based_Modeling_ABM','cell':[3,8],'rotation_degrees':180,'other_plan_rows_unchanged':True,'original_works_unchanged':True},indent=2),encoding='utf-8')
print('One addition placed; all existing positions and other plan rows retained.')
