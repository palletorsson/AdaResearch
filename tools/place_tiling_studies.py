"""One placement pass; preserve every authored exhibit and unrelated museum row."""
from pathlib import Path
import copy, json, collections, shutil
from em_map_halls import derive_row
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-tiling-placement'
layouts={
 'Pattern_Foundry':[
  (4,4,'pattern_tile_4x4:0:1.35'),(7,4,'pattern_tile_mirror:0:1.35'),
  (4,9,'pattern_tile_brick:0:1.35'),(7,9,'pattern_tile_herringbone:0:1.35'),
  (17,6,'pattern_machine_c:0:0'),(5,18,'pattern_machine_a:90:0#lesson:shared_recipe'),
  (8,13,'pattern_maker_station:0:0'),(19,18,'pattern_mill:0:0'),
  (18,31,'pattern_machine_d:180:0'),(3,26,'tiling_demo:0:0.05:0.3#embedded:true'),
  (6,34,'pattern_tile_plate:180:0.51'),(10,5,'pattern_architecture#target:walls')],
 'Tutorial_Pattern':[
  (4,7,'pattern_tile_plate:180:0.51#p4m'),(8,7,'pattern_tile_plate:180:0.51#p4m'),
  (12,7,'pattern_tile_plate:180:0.51#p4m'),(5,3,'pattern_studio_plate:0:0'),
  (4,12,'pattern_tile_mirror:0:1.35'),(7,12,'pattern_tile_puzzle:0:1.35'),
  (13,12,'grid_model:180:0'),(4,17,'script_runner:0:1.1'),
  (13,17,'pulsar_compact:0:1.1'),(12,16,'panel_bridge_loom:0:0#shafts:8'),
  (8,17,'dark_sphere')],
 'Array_Patterns':[
  (4,4,'pattern_tile_4x4:0:1.35'),(4,7,'pattern_tile_mirror:0:1.35'),
  (4,14,'pattern_tile_brick:0:1.35'),(7,14,'pattern_tile_herringbone:0:1.35'),
  (9,5,'vr_tile_editor_mirror:0:0'),(16,3,'science_screen:180:1.5'),
  (3,8,'tiling_demo:0:0.05:0.25#embedded:true'),
  (13,5,'facade_grammar_demo:0:0.02:0.28#embedded:true'),(13,10,'pattern_tile_plate:0:0.51'),
  (6,16,'panel_bridge_loom:0:0'),(13,14,'grid_model:0:0'),(8,16,'dark_sphere')],
 'Symmetry_Seventeen':[
  (4,5,'loom_escher_mirror:0:0'),(10,5,'pattern_loom:0:0'),(16,5,'loom_alhambra_p6m:0:0'),
  (4,12,'mill_persian_p4:0:0'),(10,12,'mill_alhambra_p6m:0:0'),(4,18,'mill_escher_p4g:0:0'),
  (21,4,'wallpaper_cage:0:1.1'),(10,17,'pattern_tile_puzzle:0:1.35'),
  (13,26,'pattern_atlas_gallery:0:0'),(21,18,'kaleidoscope:0:0#plinth:0.90'),
  (4,24,'pattern_artifact:0:0#plinth:0.90'),(21,24,'tile_meander_floor:0:0'),
  (8,6,'wall_pattern_gallery:90:0#surfaces:walls#emission_strength:0.25')]
}
def base(t):return t.split('#')[0].split(':')[0]
changes=[]
for name,places in layouts.items():
 p=R/'commons/maps'/name/'map_data.json';old=json.loads(p.read_text(encoding='utf-8'))
 backup=O/'before'/name/'map_data.json';backup.parent.mkdir(parents=True,exist_ok=True)
 assert not backup.exists(), 'Placement pass already applied; inspect before re-running'
 shutil.copy2(p,backup)
 d=copy.deepcopy(old);layer=d['layers']['interactables'];moving=collections.Counter(base(t) for _,_,t in places)
 original=[(x,z,t) for z,row in enumerate(layer) for x,t in enumerate(row) if str(t).strip()]
 assert all(sum(base(t)==k for _,_,t in original)==v for k,v in moving.items())
 for x,z,t in original:
  if base(t) in moving:layer[z][x]=' '
 for x,z,t in places:
  assert not layer[z][x].strip(),(name,x,z,layer[z][x]);layer[z][x]=t
 assert collections.Counter(base(t) for _,_,t in original)==collections.Counter(base(t) for row in layer for t in row if t.strip())
 # Level only obsolete metre-high interior dividers. The tunnel's raised deck stays.
 flattened=[]
 for z,row in enumerate(d['layers']['structure']):
  for x,v in enumerate(row):
   if str(v)=='2' and not (name=='Array_Patterns' and x>=19):
    row[x]=1 if isinstance(v,int) else '1';flattened.append([x,z])
 if name=='Tutorial_Pattern':
  for x in range(4,14):d['layers']['structure'][15][x]='1'
 # Arrival and continuation on existing outer passages, rather than old interior gates.
 entry_exit={'Tutorial_Pattern':((9,1),(9,19)), 'Array_Patterns':((9,1),(9,17)), 'Symmetry_Seventeen':((12,1),(12,28))}
 if name in entry_exit:
  u=d['layers']['utilities']
  for row in u:
   for x,t in enumerate(row):
    if t in ('s','t'):row[x]=' '
  for token,(x,z) in zip(('s','t'),entry_exit[name]):
   assert not str(u[z][x]).strip();u[z][x]=token
   d['layers']['structure'][z][x]='1'
 dims=d['map_info']['dimensions'];d['map_info']['museum']['sculpture_clear_rects']=[[1,1,dims['width']-2,dims['depth']-2]]
 d.setdefault('documentation',{})['placement_pass']='2026-10-09: existing exhibits regrouped; small editors raised; obsolete low partitions levelled. Primary lesson stations retained.'
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 changes.append({'map':name,'old':original,'new':places,'levelled_cells':flattened,'artifact_count':len(original)})

# Replace only the four affected rows. Keep fields the map derivation does not own.
p=R/'commons/data/museum/em_plan.json';raw=p.read_text(encoding='utf-8');before=json.loads(raw)
for name in layouts:
 old=next(r for r in before['plans'] if r.get('map')==name)
 (O/'before'/name/'plan-row.json').write_text(json.dumps(old,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 new=derive_row(old['pearl'],name,old['museum'],old['pearl_index'],old['pearls_total'],'tiling')
 row={**old,**new};source=json.dumps(old,ensure_ascii=False)
 if raw.count(source)!=1:source=json.dumps(old,ensure_ascii=False,separators=(',',':'))
 assert raw.count(source)==1,name
 raw=raw.replace(source,json.dumps(row,ensure_ascii=False),1)
after=json.loads(raw)
assert [r for r in before['plans'] if r.get('map') not in layouts]==[r for r in after['plans'] if r.get('map') not in layouts]
p.write_text(raw,encoding='utf-8')
(O/'changes.json').write_text(json.dumps({'halls':changes,'other_plan_rows_preserved':True,'all_authored_exhibits_preserved':True},indent=2)+'\n',encoding='utf-8')
print('Repositioned four halls; all authored exhibits and other plan rows preserved.')
