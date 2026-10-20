"""Guarded one-time placement; preserve all other hall works and generated plan rows."""
from pathlib import Path
import copy,json,re
import em_map_halls
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-pendulum-a-recorded-push'
p=R/'commons/maps/Vectors_Act4b_Oscillation/map_data.json'
raw=p.read_bytes();assert raw==(O/'before/map_data.json').read_bytes()
d=json.loads(raw);assert not str(d['layers']['interactables'][20][8]).strip()
d['layers']['interactables'][20][8]='pendulum_noise:90#pin:1#plinth:0'
d['map_info']['description']+=' A paired pendulum comparison between the spring and swing bays replays a saved horizontal push, then compares damping under the same input.'
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
p=R/'commons/artifacts/registry/wavefunctions.json';raw=p.read_text(encoding='utf-8');data=json.loads(raw)
assert 'pendulum_noise' not in data['artifacts']
entry={'lookup_name':'pendulum_noise','name':'The Same Release / A Recorded Push','scene':'res://commons/artifacts/pendulum_noise/PendulumNoise.tscn','description':'Pull either familiar point to set both releases. Compare a recorded four-second horizontal force off/on, then the same input with different damping. Local controls,20s clock,angles,peaks and terminal settling tolerance. Angular model; not a contact or Jolt hinge simulation.','category':'physics','complexity':'intermediate','map_sequences':['forces','wavefunctions'],'map_ready':True,'include_in_map_data':True,'parameters':{'footprint':[6.6,3.5,4.9],'size_group':'room_scale'},'interactions':['Pull either point; release both','Force strength','Comparison damping','Run/pause','Replay','Switch comparison','Next seed','Reset'],'qfep_connection':'Separate a retained disturbance from its receiver. A changed response need not imply a changed rule or adaptive controller.','tags':['pendulum','force','noise','damping','paired comparison','point lineage']}
tail=re.search(r'\s*}\s*}\s*$',raw);assert tail
new=raw[:tail.start()]+',\n'+json.dumps({'pendulum_noise':entry},ensure_ascii=False,indent=2)[2:-2]+raw[tail.start():]
expected=copy.deepcopy(data);expected['artifacts']['pendulum_noise']=entry;assert json.loads(new)==expected
p.write_bytes(new.encode('utf-8'))
p=R/'commons/data/museum/em_plan.json';raw=p.read_bytes();plan=json.loads(raw);before=copy.deepcopy(plan)
i=next(i for i,x in enumerate(plan['plans']) if x['map']=='Vectors_Act4b_Oscillation');row=plan['plans'][i]
updated=em_map_halls.derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
em_map_halls.normalize_row(updated,True,False);plan['plans'][i]=updated
assert all(a==b for j,(a,b) in enumerate(zip(before['plans'],plan['plans'])) if j!=i)
assert p.read_bytes()==raw
p.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'))
(O/'placement.json').write_text(json.dumps({'map':'Vectors_Act4b_Oscillation','cell':[8,20],'rotation_degrees':90,'other_plan_rows_unchanged':True,'original_works_unchanged':True},indent=2),encoding='utf-8')
print('One addition placed; all existing positions and other plan rows retained.')
