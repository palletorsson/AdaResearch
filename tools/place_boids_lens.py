from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
H='SwarmIntelligence_Boids_Algorithm'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/f'commons/maps/{H}/map_data.json';d=read(p)
for row in d['layers']['interactables']:
 for x,t in enumerate(row):
  if t.split(':')[0] in ['flocking_controls','boids_neighbour_lens']:row[x]=''
d['layers']['interactables'][3][9]='boids_neighbour_lens:0:0:1#plinth:0#pin:1'
for x,z in [(6,3),(9,7)]:d['layers']['structure'][z][x]='1'
for row in d['layers']['utilities']:
 for x,t in enumerate(row):
  if t in ['s','sp','t']:row[x]=''
for x,z,t in [(6,1,'sp'),(6,2,'s'),(6,11,'t')]:d['layers']['utilities'][z][x]=t
d['map_info']['museum']['portal_exit']={'approach':'from_hall'}
d['map_info']['museum']['sculpture_clear_rects']=[[1,1,12,12],[0,9,3,11],[11,1,27,12]]
write(p,d)
p=R/'commons/data/museum/em_plan.json';data=p.read_bytes();plan=read(p);row=next(r for r in plan['plans'] if r['map']==H)
row['tile']=[['4' if c=='w' else '0' if not c else c for c in cells] for cells in d['layers']['structure']]
row['interior_count']=sum(c=='1' for cells in row['tile'] for c in cells)
a=next(a for a in row['artifacts'] if a['token'] in ['flocking_controls','boids_neighbour_lens'])
a.update(token='boids_neighbour_lens',cell=[9,3],tile_cell=[9,3],rotation=0,support_height_m=0.0,config={'plinth':'0','pin':'1'});a['ruled']['cell']=[9,3]
p.write_bytes((json.dumps(plan,ensure_ascii=False,separators=(',',':'))+ ('\r\n' if data.endswith(b'\r\n') else '\n')).encode('utf-8'))
write(R/'commons/artifacts/registry/boids_neighbour_lens.json',{'artifacts':{'boids_neighbour_lens':{
 'lookup_name':'boids_neighbour_lens','name':'Boids: who enters the radius?','scene':'res://commons/artifacts/boids_neighbour_lens/boids_neighbour_lens.tscn',
 'description':'The original FlockingControls simulation in a clear bay. The carried point adjusts perception radius. Pause, compare the selected neighbours, and read the three requests for the gold body.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'auto_ground':False,'footprint':[1.8,2.2,1.8],'size_group':'medium','parameters':{'footprint':[1.8,2.2,1.8]},
 'qfep_connection':'A change in who can count as a neighbour changes the requests, even when the weights and positions stay the same. The visible radius declares the inclusion rule.'}}})
print('Placed existing flocking controls with a hand-operated neighbour lens.')
