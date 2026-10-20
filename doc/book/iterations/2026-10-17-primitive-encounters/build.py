"""Scoped map edits for Palle's primitive encounter trial; never rebuild other halls."""
from pathlib import Path
import copy, json, sys, re
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
NAMES=['Point_One','Point_Lines','Point_Triangle_Context','Primitives_Polythedra']
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):
 text=json.dumps(d,ensure_ascii=False,indent='\t' if p.name=='map_data.json' else 2)+'\n'
 if p.name=='map_data.json' and p.parent.name in ['Point_Lines','Primitives_Polythedra']:
  text=re.sub(r'\[\n((?:\s+"[^"\n]*",?\n)+)\s+\]',lambda m:'['+', '.join(line.strip().rstrip(',') for line in m[1].splitlines())+']',text)
 p.write_text(text,encoding='utf-8')
def backup(p):
 q=HERE/'before'/p.relative_to(ROOT);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():q.write_bytes(p.read_bytes())
def fresh(d,w,h):
 d=copy.deepcopy(d);d['layers']={k:[[' ']*w for _ in range(h)] for k in ['structure','interactables','utilities','museum']}
 d['layers']['structure']=[['0']*w for _ in range(h)]
 d['map_info']['dimensions']={'width':w,'depth':h,'max_height':5}
 d['map_info']['museum']={'artifact_placement':'map','piers':False,'plinths':False,'gate':False,'lobby':{'enabled':False},'props_deny':['bench','dream_bodies','cable_tray','wall_clock','electrical_panel','floor_grate','ceiling_vent'],'sculpture_clear_rects':[[0,0,w-1,h-1]]}
 return d
def room(d,x0,z0,x1,z1):
 s=d['layers']['structure']
 for z in range(z0,z1+1):
  for x in range(x0,x1+1):s[z][x]='w' if x in (x0,x1) or z in (z0,z1) else '1'
def door(d,z,xs):
 for x in xs:d['layers']['structure'][z][x]='1'
def put(d,x,z,t):
 assert not d['layers']['interactables'][z][x].strip(),(x,z,t)
 d['layers']['interactables'][z][x]=t
def finish(d,name):
 if name!='Point_Triangle_Context':d['layers']['museum']=copy.deepcopy(d['layers']['structure'])
 d['map_info']['metadata']={'source':'editor','n_artifacts':sum(bool(str(c).strip()) for row in d['layers']['interactables'] for c in row)}
 write(ROOT/f'commons/maps/{name}/map_data.json',d)
for n in NAMES:
 for p in (ROOT/f'commons/maps/{n}').glob('*.md'):backup(p)
 backup(ROOT/f'commons/maps/{n}/map_data.json')

# New artifacts are small, independent scene entries; the editor can drag them.
folder=ROOT/'commons/artifacts/primitive_encounters'
entries={}
for token,script,title,extra in [
 ('pairing_point_field','pairing_field','Twelve points / many lines',''),
 ('triangle_assembly_table','triangle_table','Twelve triangles / open assembly',''),
 ('align_tetrahedron','align_solid','Align the tetrahedron','kind = "tetrahedron"\n'),
 ('align_wedge','align_solid','Align the wedge','kind = "wedge"\n'),
 ('wedge_palace','wedge_palace','Two approaches / one platform',''),
 ('corner_tetrahedron','corner_tetrahedron','A tetrahedron changes the corner','')]:
 (folder/f'{token}.tscn').write_text(f'[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://commons/artifacts/primitive_encounters/{script}.gd" id="1"]\n\n[node name="{token}" type="Node3D"]\nscript = ExtResource("1")\n{extra}',encoding='utf-8')
 entries[token]={'lookup_name':token,'name':title,'scene':f'res://commons/artifacts/primitive_encounters/{token}.tscn','map_ready':True,'description':title+'. A primitive changes what a hand or a walking body can do.','category':'primitives','tags':['points','lines','surfaces','construction'],'complexity':'beginner'}
write(ROOT/'commons/artifacts/registry/primitive_encounters.json',{'artifacts':entries})

# Lines: free connections, measurement, imposed route, consequences, then gallery.
old=read(HERE/'before/commons/maps/Point_Lines/map_data.json')
d=fresh(old,27,63)
room(d,9,0,17,7);room(d,0,7,26,16);room(d,6,16,20,28)
room(d,10,28,14,35);room(d,0,35,26,62)
for z,xs in [(0,range(12,15)),(7,range(11,16)),(16,range(8,12)),(28,range(11,14)),(35,range(11,14)),(62,range(12,15))]:door(d,z,xs)
d['layers']['utilities'][0][13]='sp';d['layers']['utilities'][62][13]='t:Point_Trace'
put(d,13,3,'pairing_point_field:180:0#plinth:0#pin:1')
put(d,13,11,'line_black_box:0:0#plinth:0#pin:1')
# Five zigzags, each made from two joined four-metre tape barriers.
for row,z in enumerate([18,20,22,24,26]):
 for x in ([8,12] if row%2==0 else [14,18]):
  put(d,x,z,'do_not_cross_barrier:0:0#plinth:0#pin:1#form:tape#span_m:4#height_m:1.15#solid:1#legend_text:DO NOT CROSS')
for z in [29,31,33]:put(d,12,z,'anamorphic_cross:0:0#plinth:0#pin:1#passage:1#bar_len_m:2.5#cross_height_m:1.2#damage_per_tick:14#tick_interval:0.6')
for z in [30,32,34]:put(d,12,z,'health_cross:0:0#plinth:0#pin:1#passage:1#arm_m:0.8#hover_m:1.2#boost:21#take_below:1#respawn:8#color:bdebdc')
skip={'line_demo','do_not_cross_barrier','line_black_box','anamorphic_cross','health_cross'}
arts=[str(c) for row in old['layers']['interactables'] for c in row if str(c).strip() and str(c).split(':')[0].split('#')[0] not in skip]
# Large witnesses get breathing space. Small examples occupy the perimeter.
special={'line_relations_gallery':(13,48),'line_space_workshop':(6,58),'walk_this_line_marking':(13,40),'modulor_man_demo':(3,42),'line_proof_pair':(21,40)}
slots=[(x,z) for z in [37,41,45,49,53,57,60] for x in [2,5,21,24]]+[(9,56),(17,56),(9,37),(16,37),(9,60),(17,60),(9,44),(17,44)]
for t in arts:
 token=t.split(':')[0].split('#')[0]
 if token=='walk_this_line_marking':t=t.replace(':0:0.9:2',':0:0:2')
 if token in special:x,z=special[token]
 else:x,z=slots.pop(0)
 put(d,x,z,t)
finish(d,'Point_Lines')

# Triangle: keep the existing surface investigations, add an accessible worktable.
d=read(HERE/'before/commons/maps/Point_Triangle_Context/map_data.json')
put(d,3,26,'triangle_assembly_table:180:0#plinth:0#pin:1')
finish(d,'Point_Triangle_Context')

# Solids: two construction encounters, corner, symmetric ascent, basin and rock bay.
old=read(HERE/'before/commons/maps/Primitives_Polythedra/map_data.json')
d=fresh(old,27,46)
room(d,1,0,15,8);room(d,1,8,15,16);room(d,1,16,18,45)
room(d,18,22,26,39)
for z,xs in [(0,range(6,9)),(8,range(6,10)),(16,range(10,14)),(45,range(7,10))]:door(d,z,xs)
for z in range(25,28):d['layers']['structure'][z][18]='1'
d['layers']['utilities'][0][7]='sp';d['layers']['utilities'][45][8]='t:Point_Animatedcube'
put(d,7,4,'align_tetrahedron:180:0#plinth:0#pin:1')
put(d,7,12,'align_wedge:180:0#plinth:0#pin:1')
put(d,2,17,'corner_tetrahedron:0:0#plinth:0#pin:1#offset:-0.49,0,-0.49')
put(d,9,28,'wedge_palace:0:0#plinth:0#pin:1')
put(d,14,19,'polyhedra_boundary_plate:180:0:0.8#offset:0,0.34,0')
put(d,4,20,'grab_trihedron:180:0#plinth:0.90')
put(d,7,20,'pyramid_edit:180:0#plinth:0.65,micropod#workbench:1')
put(d,14,22,'polyhedra_reveal_monitor:180:0#plinth:0#pin:1')
# Basin retains the striped wedge-profile stoppers. Every cell has a floor.
for x in range(7,12):
 for z in [36,41]:put(d,x,z,'concrete_barrier:0:0#barrier_length:1.0#barrier_height:0.85#base_width:0.60#blocking:1#plinth:0')
for z in range(37,41):
 for x in [6,12]:put(d,x,z,'concrete_barrier:90:0#barrier_length:1.0#barrier_height:0.85#base_width:0.60#blocking:1#plinth:0')
put(d,9,38,'diamonds:0:0:0.15#plinth:0')
# Rock box belongs to the side room, with standing space at its scanner.
for z in range(29,34):
 for x in range(20,25):
  if x in [20,24] or z in [29,33]:d['layers']['structure'][z][x]='2'
put(d,22,31,'rock_spawner#rock_count:30#spawn_height:3.5#spawn_area_x:2.6#spawn_area_y:1#spawn_area_z:2.6#plinth:0')
put(d,22,35,'rock_scanner:180:0#plinth:0')
d['map_info']['description']='Align a tetrahedron, align a wedge, encounter a corner, walk symmetric wedges onto a platform, descend to a floored basin. A side room holds the rock box. No cube exhibit.'
finish(d,'Primitives_Polythedra')

# Update only these four chapter rows; preserve all unrelated hand-authored plans.
p=ROOT/'commons/data/museum/em_plan.json';backup(p);plan=read(p)
for i,row in enumerate(plan['plans']):
 if row.get('map') not in NAMES or row.get('sequence')!='primitives':continue
 new=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'primitives')
 new['_ruling']={'src_w':len(new['tile'][0]),'src_h':len(new['tile']),'rotated':False,'pad':0,'pad_closed':False,'ring':None}
 plan['plans'][i]=new
write(p,plan)
print('Updated four primitive halls and six independent artifact entries.')
