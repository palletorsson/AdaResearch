from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Swarm_Intelligence_Algorithms'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,indent=2,ensure_ascii=False)+'\n')
A=R/'commons/artifacts/population_account_walk'
write(A/'population_account_walk.gd','extends "study.gd"\n## Permanent exportable copy of the printed lesson.\n')
for n in ['account.gd','observed.gd','point_body.gd','study.gd']:shutil.copy2(R/'doc/book/studies/swarm-through-the-hands'/ID/n,A/n)
write(A/'population_account_walk.tscn','[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="population_account_walk.gd" id="1"]\n\n[node name="PopulationAccountWalk" type="Node3D"]\nscript = ExtResource("1")\n')
dump(R/'commons/artifacts/registry/population_account_walk.json',{'artifacts':{'population_account_walk':{'lookup_name':'population_account_walk','name':'Who keeps the count?','scene':'res://commons/artifacts/population_account_walk/population_account_walk.tscn','description':'A12m ecosystem of grabbable PointBodies. Births, losses and supplied bodies are counted separately; gold rings identify supplied organisms. Filter the account without removing actual support.','category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'map_sequences':['swarmintelligence'],'footprint':[13,4,15],'size_group':'world_scale','tags':['ecosystem','event-provenance','support','grabbable','walk-in'],'qfep_connection':'An apparent recovery has conditions. The account names supplied bodies without treating care as a failure of autonomy.','parameters':{'footprint':[13,4,15],'size_group':'world_scale'}}}})
mp=R/'commons/maps'/ID/'map_data.json';m=read(mp);w,h=17,21
structure=[['w' if x in (0,w-1) or z in (0,h-1) else '1' for x in range(w)] for z in range(h)]
for z in [0,h-1]:
 for x in [7,8,9]:structure[z][x]='1'
u=[['']*w for _ in range(h)]
for x,z,t in [(8,1,'s'),(1,2,'an'),(1,5,'wp'),(15,5,'wp'),(8,19,'t')]:u[z][x]=t
a=[['']*w for _ in range(h)];a[10][8]='population_account_walk:180:0:1'
m['layers'].update(structure=structure,utilities=u,interactables=a)
m['map_info']['dimensions'].update(width=w,depth=h)
m['map_info']['description']='Walk among the ecosystem: born, lost and supplied bodies. An observed account of the existing model, with support visible.'
m['map_info']['metadata']['design_notes']='17x21 flat open hall. Permanent12m field at8,10. Both control banks at reachable height, central entrance-to-exit route open. Body markers are not model feeding radii.'
m['map_info']['museum']['sculpture_clear_rects']=[[1,1,15,19]]
dump(mp,m)
p=R/'commons/data/museum/em_plan.json';d=read(p);row=next(r for r in d['plans'] if r.get('map')==ID)
row['tile']=[['4' if c=='w' else c for c in line] for line in structure];row['h']=h;row['room']={'w':w,'h':h};row['interior_count']=sum(c=='1' for line in structure for c in line);row['_ruling'].update(src_w=w,src_h=h)
row['artifacts']=[{'token':'population_account_walk','cell':[8,10],'tile_cell':[8,10],'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+ID,'cell':[8,10]},'scale':1,'offset':[0.0,0.0,0.0]}]
write(p,json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n')
print('Saved permanent population account in final Swarm hall17x21. Original ecosystem source untouched.')
