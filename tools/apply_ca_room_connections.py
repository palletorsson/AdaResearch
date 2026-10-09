"""Apply the reviewed opening-hall layout once; only replace its museum row."""
from pathlib import Path
import copy, hashlib, json, shutil
import em_map_halls

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-rooms-connected'
path=R/'commons/maps/CA_Introduction/map_data.json'
assert path.read_bytes()==(O/'before/map_data.json').read_bytes(), 'Baseline changed; review rather than overwrite.'
doc=json.loads(path.read_text(encoding='utf-8'))
layers=doc['layers']; floor=layers['structure']
# Three-metre comparison openings in the long divider.
for z in [3,4,5,11,12,13]: floor[z][7]='1'
# Preserve the rug room's southern wall, with a two-metre side passage.
floor[7][5]='1'
# Replace the inaccessible lower pockets with one level gallery.
for z in range(8,18):
 for x in range(1,7): floor[z][x]='1'
arts=layers['interactables']
assert arts[17][1]=='ca_showcase' and not arts[14][3]
arts[14][3]=arts[17][1]; arts[17][1]=''
# Keep the existing dealt sculpture, but reserve the teaching aisle, rug,
# approaches and showcase. Source-grid rectangles are read by the museum.
doc['map_info']['museum']['sculpture_clear_rects']=[
 [0,0,12,8], [6,0,12,18], [0,12,6,18]
]
# The generic chapter gate cuts through the rug; this room already has portals.
doc['map_info']['museum']['gate']=False
doc['map_info']['museum']['portal_entry']={'cage':False}
doc['map_info']['museum']['portal_exit']={'approach':'from_hall'}
utilities=layers['utilities']
assert utilities[1][2]=='sp' and utilities[16][2]=='t'
utilities[1][2]=''; utilities[0][6]='sp'
utilities[16][2]=''; utilities[18][6]='t'
assert all(len(layer)==19 and all(len(row)==13 for row in layer) for layer in layers.values())
path.write_bytes((json.dumps(doc,ensure_ascii=False,indent=1)+'\n').encode('utf-8'))

planpath=R/'commons/data/museum/em_plan.json'
plan=json.loads(planpath.read_text(encoding='utf-8'))
before=copy.deepcopy(plan)
i=next(i for i,r in enumerate(plan['plans']) if r.get('map')=='CA_Introduction')
old=plan['plans'][i]
new=em_map_halls.derive_row(old['pearl'],old['map'],old['museum'],old['pearl_index'],old['pearls_total'],old['sequence'])
em_map_halls.normalize_row(new,True,False)
plan['plans'][i]=new
assert all(a==b for j,(a,b) in enumerate(zip(before['plans'],plan['plans'])) if j!=i)
assert all(before[k]==plan[k] for k in plan if k!='plans')
planpath.write_bytes(json.dumps(plan,ensure_ascii=False).encode('utf-8'))
# Ship just the edited generated file; leave concurrent bake/control work alone.
destination=R/'commons/data/museum/em_plan.json'; destination.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(planpath,destination)
(O/'after').mkdir(exist_ok=True)
shutil.copy2(path,O/'after/map_data.json')
(O/'after/plan-row.json').write_text(json.dumps(new,indent=2),encoding='utf-8')
print(json.dumps({'hall':old['map'],'artifacts':len(new['artifacts']),'floor_cells_before':old['interior_count'],'floor_cells_after':new['interior_count'],'other_plan_rows_unchanged':True}))
