"""Second staging pass: instrument + spatial encounter. Prior pass is archived."""
import json
import pathlib
import sys
ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT/'tools'))
from em_map_halls import derive_row

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p, d): p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
def compact(front): return f'#controls:compact#control_front:{front}'
def glass(w,d,h,title): return f'#glass_width:{w}#glass_depth:{d}#glass_height:{h}#glass_title:{title}'
ROOMS = {
 'Random_Definition': (13,16,[
 (6,6,'seed_replay_demo:180#comparison:replicas#stand:table'+compact(1.0)),
 (3,4,'prng_crank_machine:180:0.62'),(10,4,'slot_machine:180'),
 (3,12,'trng_vs_prng:180:1.12:0.1'),(9,12,'random_number_book_page_1955:0:2.7:0.8'),
 (10,8,'catalyst_pickup:180#sequence_name:randomness#label_text:RANDOMNESS CATALYST#orb_color:0.95,0.55,0.20#accent_color:0.95,0.55,0.20')],[]),
 'Random_Entropy': (17,23,[
 (8,5,'shannon_entropy_meter:180#stand:ledger#disclosure:ledger'+compact(1.7)),
 (3,5,'entropy_jar:180'),(3,9,'hardware_entropy_decay:180:0.45:0.6'),
 (8,15,'entropy_axiom#square:true'+glass(10,10,4.5,'ORDER / DISPLACEMENT')),
 (13,7,'random_butterflies:180')],['entropy_axiom']),
 'Random_Remove': (17,26,[
 (8,5,'remove_random:180#local_grid:true'+compact(1.15)),
 (8,17,'random_removal_arena:0:3#columns:9#rows:11'+glass(11,13,4.5,'WALK / REMOVE')+'#glass_grid:false'+compact(-7.0)+'#control_facing:-z')],['random_removal_arena']),
 'Random_Walk': (19,26,[
 (9,5,'random_walk_terrarium:180#stand:logbook'+compact(1.25)),
 (3,5,'random_walk_collection:180#plinth:0.75#bench_bare_rack:1'),
 (15,5,'random_walk_leash:180'),
 (9,17,'random_walk_128:180'+glass(12,12,5,'WALK / RETAIN')),
 (3,9,'pixel_cloud:180:0.1:0.18#walk_seed:101')],['random_walk_128']),
 'Random_Gaussian': (11,13,[
 (5,6,'distribution_sampler:180#stand:cabinet'+compact(1.05)),
 (2,10,'galton_board:180:0.9:1.5'),(8,10,'distribution_comparator:180:0.83'),
 (2,7,'GaussianPaintSplatter:180:1.5:0.65')],[]),
 'Random_Mushrooms': (17,20,[
 (8,11,'mushrooms:180#stand:specimen#size:6#edible:some'+glass(8,8,4.5,'POPULATION / DIFFERENCE')+'#glass_entry:4'+compact(5.1)),
 (3,5,'bubbles_random:180:0.85:0.25#plinth:0.85')],[]),
 'Random_Game': (19,45,[
 (9,6,'r_c:0:3#stand:chasm#cue:advance'+compact(-2.6)+'#control_facing:-z#control_height:1.38#control_floor:0.28#control_fixed:true'),
 (9,17,'random_removal_arena:0:3#columns:9#rows:9'+glass(11,11,4.5,'THE SET UNDERFOOT')+'#glass_grid:false'+compact(-6.0)+'#control_facing:-z'),
 (9,29,'random_doors'+compact(-4.0)+'#control_facing:-z'),
 (9,37,'cube_projectile_spawner#mode:field#field_size:8x8#field_height:8#fall_min:1.6#fall_max:2.6#drift:0.25#jitter:0.25#jitter_interval:0.45#vertical_variation:0.2#spawn_interval:0.5#max_projectiles:24#stand:field'+compact(-5.0)+'#control_facing:-z')],['random_removal_arena','random_doors','cube_projectile_spawner'])
}

def main():
 roles=read(ROOT/'commons/data/artifact_roles.json'); manifest=[]
 for name,(w,d,items,extra) in ROOMS.items():
  p=ROOT/'commons/maps'/name/'map_data.json'; data=read(p)
  structure=[['w' if x in (0,w-1) or z in (0,d-1) else '1' for x in range(w)] for z in range(d)]
  for z in (0,d-1):
   for x in range(w//2-1,w//2+2): structure[z][x]='1'
  holes=[]
  if name=='Random_Remove': holes=[(4,12,9,11)]
  if name=='Random_Game': holes=[(7,5,5,3),(5,13,9,9)]
  for x,z,ww,dd in holes:
   for zz in range(z,z+dd):
    for xx in range(x,x+ww): structure[zz][xx]='0'
  util=[[' ']*w for _ in range(d)]; util[0][w//2]='s'; util[-1][w//2]='t'
  layer=[[' ']*w for _ in range(d)]
  placements=[]
  for x,z,token in items:
   layer[z][x]=token; placements.append(dict(x=x,z=z,token=token,lookup=token.split('#')[0].split(':')[0]))
  data['layers']=dict(structure=structure,utilities=util,interactables=layer)
  data['map_info']['dimensions']=dict(width=w,depth=d,max_height=9 if name=='Random_Game' else 6)
  data['map_info']['museum'].update(wall_height=5,open_roof=True,sculpture_clear_rects=[[1,1,w-2,d-2]])
  if holes: data['map_info']['museum']['basin']=dict(depth=3,glass=False,fire=True,fire_top=-2.3)
  data['map_info']['description']='A reachable instrument and a spatial application of the rule, with clear approach and gallery bypass. Spatial revision 2026-09-16.'
  save(p,data)
  primary=[placements[0]['lookup']]+extra
  secondary=[p['lookup'] for p in placements if p['lookup'] not in primary]
  roles['roles'][name]={key:('primary' if key in primary else 'secondary') for key in primary+secondary}
  roles['order'][name]=dict(primary=primary,secondary=secondary,decoration=[])
  manifest.append(dict(map=name,size=data['map_info']['dimensions'],hero=primary[0],placements=placements,count=len(placements),purpose=data['map_info']['description']))
 save(ROOT/'commons/data/artifact_roles.json',roles)
 for rel in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
  p=ROOT/rel; plan=read(p)
  for i,row in enumerate(plan['plans']):
   if row.get('map') in ROOMS: plan['plans'][i]=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'randomness')
  save(p,plan)
 save(OUT/'manifest.json',manifest)
 print('Updated seven halls: instruments + spaces; intentional removal reprise in Random_Game.')

if __name__=='__main__': main()
