from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Particle_Swarm_Optimization'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,indent=2,ensure_ascii=False)+'\n')
A=R/'commons/artifacts/particle_swarm_walk'
write(A/'particle_swarm_walk.gd','extends "study.gd"\n## The permanent copy of the complete printed lesson.\n')
for name in ['swarm.gd','point_body.gd','study.gd']:shutil.copy2(R/'doc/book/studies/swarm-through-the-hands'/ID/name,A/name)
write(A/'particle_swarm_walk.tscn','''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="particle_swarm_walk.gd" id="1"]

[node name="ParticleSwarmWalk" type="Node3D"]
script = ExtResource("1")
''')
dump(R/'commons/artifacts/registry/particle_swarm_walk.json',{'artifacts':{'particle_swarm_walk':{
 'lookup_name':'particle_swarm_walk','name':'A place remembered','scene':'res://commons/artifacts/particle_swarm_walk/particle_swarm_walk.tscn',
 'description':'Walk among 24 grabbable PointBodies on a12m score field. See personal and shared best positions. Change the objective while preserving current bodies and motion.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'map_sequences':['swarmintelligence'],
 'footprint':[13,4,14],'size_group':'world_scale','tags':['pso','memory','objective','grabbable','walk-in'],
 'qfep_connection':'A remembered score is accountable to the rule that produced it. Shared success can gather bodies without rewarding diversity.',
 'parameters':{'footprint':[13,4,14],'size_group':'world_scale'}}}})
mp=R/'commons/maps'/ID/'map_data.json';m=read(mp);w,h=17,23
structure=[['w' if x in (0,w-1) or z in (0,h-1) else '1' for x in range(w)] for z in range(h)]
for z in [0,h-1]:
 for x in [7,8,9]:structure[z][x]='1'
utilities=[['']*w for _ in range(h)]
for x,z,token in [(8,1,'s'),(1,2,'an'),(1,5,'wp'),(15,5,'wp'),(8,21,'t'),(14,21,'sp')]:utilities[z][x]=token
artifacts=[('particle_swarm_walk',8,9,180,0,1),('fitness_landscape_politics',4,19,180,0,1),('self_organizing_patterns',12,19,180,.65,.35),('tick_flock',1,13,90,1.4,1)]
interactables=[['']*w for _ in range(h)]
for token,x,z,yaw,offset,scale in artifacts:interactables[z][x]=f'{token}:{yaw}:{offset}:{scale}'
m['layers'].update(structure=structure,utilities=utilities,interactables=interactables)
m['map_info']['dimensions'].update(width=w,depth=h)
m['map_info']['description']='A twelve-metre walk-through search field: current bodies, personal best positions, shared best and three explicit objectives. Existing novelty and self-organization comparisons beyond.'
m['map_info']['metadata']['design_notes']='Flat floor, no interior partitions. Primary field at8,9. Rear comparisons at4,19 and12,19; central route to next hall kept open. Score brightness does not represent floor height.'
m['map_info']['museum']['sculpture_clear_rects']=[[1,1,15,21]]
dump(mp,m)
pp=R/'commons/data/museum/em_plan.json';p=read(pp);row=next(x for x in p['plans'] if x.get('map')==ID)
row['tile']=[['4' if c=='w' else c for c in line] for line in structure]
row['h']=h;row['room']={'w':w,'h':h};row['interior_count']=sum(c=='1' for line in structure for c in line)
row['_ruling'].update(src_w=w,src_h=h)
row['artifacts']=[]
for token,x,z,yaw,offset,scale in artifacts:
 row['artifacts'].append({'token':token,'cell':[x,z],'tile_cell':[x,z],'rotation':yaw,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+ID,'cell':[x,z]},'scale':scale,'offset':[0.0,offset,0.0]})
write(pp,json.dumps(p,ensure_ascii=False,separators=(',',':'))+'\n')
print('Saved PSO room17x23; permanent12m field and rear comparisons. Other hall rows untouched.')
