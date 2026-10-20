from pathlib import Path
import json,copy,sys,re
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
NAMES=['Point_Trace','Point_Line_Grid','Point_Animatedcube','Primitives_Melencolia']
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):
 text=json.dumps(d,indent=2,ensure_ascii=False)+'\n'
 if p.name=='map_data.json':text=re.sub(r'\[\n((?:\s+"[^"\n]*",?\n)+)\s+\]',lambda m:'['+', '.join(line.strip().rstrip(',') for line in m[1].splitlines())+']',text)
 p.write_text(text,encoding='utf-8')
def fresh(name,w,h):
 d=read(HERE/'before/commons/maps'/name/'map_data.json')
 d['layers']={k:[[' ']*w for _ in range(h)] for k in ['structure','interactables','utilities','museum']}
 d['layers']['structure']=[['w' if x in [0,w-1] or z in [0,h-1] else '1' for x in range(w)] for z in range(h)]
 for z in [0,h-1]:
  for x in range(w//2-1,w//2+2):d['layers']['structure'][z][x]='1'
 d['layers']['utilities'][0][w//2]='sp';d['layers']['utilities'][h-1][w//2]='t'
 d['map_info']['dimensions']={'width':w,'depth':h,'max_height':5}
 d['map_info']['museum']={'artifact_placement':'map','piers':False,'plinths':False,'gate':False,'lobby':{'enabled':False},'props_deny':['bench','dream_bodies','cable_tray','wall_clock','electrical_panel','floor_grate','ceiling_vent'],'sculpture_clear_rects':[[0,0,w-1,h-1]]}
 return d
def put(d,x,z,token):d['layers']['interactables'][z][x]=token
def finish(name,d,struct=False):
 if struct:d['layers']['museum']=copy.deepcopy(d['layers']['structure'])
 d['map_info']['metadata']['n_artifacts']=sum(bool(str(c).strip()) for row in d['layers']['interactables'] for c in row)
 write(ROOT/'commons/maps'/name/'map_data.json',d)

folder=ROOT/'commons/artifacts/primitive_encounters'
registry={}
for token,script,title in [('glass_paint_wall','glass_paint_wall','Pens on glass / marks on a surface'),('paired_cube_diagonals','paired_cubes','Same corners / different surfaces')]:
 (folder/(token+'.tscn')).write_text(f'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://commons/artifacts/primitive_encounters/{script}.gd" id="1"]\n[node name="{token}" type="Node3D"]\nscript = ExtResource("1")\n',encoding='utf-8')
 registry[token]={'lookup_name':token,'name':title,'scene':f'res://commons/artifacts/primitive_encounters/{token}.tscn','map_ready':True,'include_in_map_data':True,'category':'primitives','complexity':'beginner','description':title,'map_sequences':['primitives'],'tags':['gesture','surface','comparison']}
write(ROOT/'commons/artifacts/registry/primitive_tools.json',{'artifacts':registry})

d=fresh('Point_Trace',24,24)
put(d,7,5,'glass_paint_wall:180:0#offset:0,0.75,0#plinth:0#pin:1')
put(d,18,14,'trace_ball_ramp:0:0#plinth:0#pin:1')
for x,res,ink in [(4,10,'e05b91'),(6,40,'30ad99'),(8,80,'7b6bc4')]:
 put(d,x,11,f'draw_dot:180:1#retention:none#resolution:{res}#ink:{ink}#plinth:0.90#offset:0,0.25,0#data_table_scale:0.55#data_table_tilt:50#data_table_mount:plinth#tool:bead#pin:1')
put(d,2,10,'trace_sampling_monitor:90:0#plinth:0#pin:1')
put(d,3,21,'hand_telemetry_diptych:180:0#offset:0,1.45,0.38#pin:1')
put(d,9,21,'science_screen:180:0:0.5#offset:0,1.45,0.47#support:pylon#screen_width:2.6#pin:1')
put(d,21,21,'film_foundation_trace:270:0#plinth:0#pin:1')
finish('Point_Trace',d,True)

d=read(HERE/'before/commons/maps/Point_Line_Grid/map_data.json')
for row in d['layers']['interactables']:
 for i,t in enumerate(row):
  if str(t).startswith('grid_lines:'):row[i]=t+'#selection:1#pin:1'
finish('Point_Line_Grid',d)

d=fresh('Point_Animatedcube',27,36)
for x in range(1,26):
 if x not in range(11,16):d['layers']['structure'][11][x]='w'
put(d,13,6,'paired_cube_diagonals:180:0#plinth:0#pin:1')
put(d,3,3,'cube_lines:0:0#pin:1')
put(d,2,7,'film_cube_corner:90:0#plinth:0#pin:1')
put(d,19,5,'cube_diagonal_plate:0:0:0.8#offset:0,0.8,0#pin:1')
put(d,13,16,'polyhedron_nets_cube:0:0#plinth:0#fall_cycle:true#loop_fold:true#edge_length:0.7#fold_duration:2.6#think_hold:2.2#pin:1')
put(d,5,24,'prefab_box_library:0:0#plinth:0#worktable_x:0#worktable_z:2.3#column_pitch:1.2#pin:1')
put(d,20,25,'cube_sorting_line:270:0#plinth:0#pin:1')
# Existing supporting works remain in side bays rather than competing with the pair.
extras=[(3,15,'first_shadow'),(23,15,'first_phosphor'),(3,19,'wooden_pallet:0:0#box_arrangement:pyramid#stencil_words:A_WORLD;WITHOUT;COMPOSITION'),(23,19,'hangar_supply_pile:0:0#palette:metal#crate_count:2#stencil_words:WITHOUT_COMPOSITION;YET'),(4,31,'crate:0:0#stamp_label:YET'),(2,33,'station_crates#upkeep:store'),(24,33,'station_crates:0:0'),(24,31,'glove_box:0:0#glove_count:1'),(7,16,'floating_sphere_field:0:0#bounds:3,2,3')]
for x,z,t in extras:put(d,x,z,t+'#pin:1#plinth:0')
for x,sides in zip([8,10,12,14,16],[3,4,5,6,8]):put(d,x,32,f'pyramid#base_sides:{sides}#pin:1#plinth:0')
finish('Point_Animatedcube',d,True)

d=read(HERE/'before/commons/maps/Primitives_Melencolia/map_data.json')
for row in d['layers']['interactables']:
 for i,t in enumerate(row):
  if str(t).startswith('durer_scene:'):row[i]=t+'#figure:skull'
finish('Primitives_Melencolia',d)

p=ROOT/'commons/data/museum/em_plan.json';plan=read(p)
for i,row in enumerate(plan['plans']):
 if row.get('map') not in NAMES or row.get('sequence')!='primitives':continue
 new=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'primitives')
 new['_ruling']={'src_w':len(new['tile'][0]),'src_h':len(new['tile']),'rotated':False,'pad':0,'pad_closed':False,'ring':None}
 plan['plans'][i]=new
write(p,plan)
print('Updated four scoped hall rows and two independent artifacts.')
