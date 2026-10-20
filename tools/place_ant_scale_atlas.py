"""Add a side court to the existing ACO hall; retain original lesson and routes."""
from pathlib import Path
import json, shutil, hashlib
R=Path(__file__).resolve().parents[1]
H='SwarmIntelligence_Ant_Colony_Optimization'
OUT=R/'doc/book/iterations/2026-10-11-ants-time-and-scale'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,d):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
mp=R/f'commons/maps/{H}/map_data.json';pp=R/'commons/data/museum/em_plan.json'
for path in [mp,pp]:
    target=OUT/'before'/path.relative_to(R)
    target.parent.mkdir(parents=True,exist_ok=True)
    if not target.exists():shutil.copy2(path,target)
preserved=[R/'commons/artifacts/stigmergy_grid/stigmergy_grid.gd',R/'commons/artifacts/langton_swarm/langton_swarm.gd',R/'commons/artifacts/particle_swarm_walk/point_body.gd']
preserved+=list((R/'commons/artifacts/ant_colony_walk').glob('*.gd'))
for folder in (R/'commons/maps').glob('SwarmIntelligence*'):
    preserved += [p for p in [folder/'tutorial.md',folder/'final.md'] if p.exists()]
if not (OUT/'before/preserved-hashes.json').exists():write(OUT/'before/preserved-hashes.json',{p.relative_to(R).as_posix():sha(p) for p in preserved})
m=read(mp)
if m['map_info']['dimensions']['width']==17:
    for name,rows in m['layers'].items():
        for z,row in enumerate(rows):
            row.extend(['4' if z in [0,16] or x==32 else '1' for x in range(17,33)] if name=='structure' else [' ']*16)
    for z in [7,8,9]:m['layers']['structure'][z][16]='1'
    m['layers']['interactables'][8][26]='ant_scale_atlas:0:0:1'
    m['map_info']['dimensions']['width']=33
    m['map_info']['museum']['sculpture_clear_rects'].append([17,1,32,16])
    m['map_info']['museum']['gate']=False
    m['map_info']['metadata']['design_notes']+=' East comparison court: hand/table/floor show one live state. Existing lesson and north/south passages retained.'
    write(mp,m)
# Rectangles are min/max corners, not width/depth.
m['map_info']['museum']['sculpture_clear_rects']=[r for r in m['map_info']['museum']['sculpture_clear_rects'] if r not in [[17,1,15,15],[17,1,32,16]]]+[[17,1,32,16]]
m['layers']['interactables'][8][26]='ant_scale_atlas:0:0:1#plinth:0#pin:1'
if [14,6,18,11] not in m['map_info']['museum']['sculpture_clear_rects']:m['map_info']['museum']['sculpture_clear_rects'].append([14,6,18,11])
write(mp,m)
p=read(pp);row=next(x for x in p['plans'] if x['map']==H)
row['tile']=m['layers']['structure'];row['room']['w']=33;row['room']['h']=17;row['h']=17
row['interior_count']=sum(c=='1' for line in row['tile'] for c in line)
row['_ruling']['src_w']=33
if not any(a['token']=='ant_scale_atlas' for a in row['artifacts']):
    row['artifacts'].append({'token':'ant_scale_atlas','cell':[26,8],'tile_cell':[26,8],'rotation':0,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+H,'cell':[26,8]},'scale':1.0})
original=pp.read_bytes();ending='\r\n' if original.endswith(b'\r\n') else '\n'
pp.write_bytes((json.dumps(p,ensure_ascii=False,separators=(',',':'))+ending).encode('utf-8'))
write(R/'commons/artifacts/registry/ant_scale_atlas.json',{'artifacts':{'ant_scale_atlas':{
    'lookup_name':'ant_scale_atlas','name':'One pattern, three sizes','scene':'res://commons/artifacts/ant_scale_atlas/ant_scale_atlas.tscn',
    'description':'Original pheromone-grid, turmite and Ant Colony V2 simulations displayed at 45 cm, 1.8 m and 8 m. Carry the same PointBody; pause, compare and restart explicitly.',
    'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'auto_ground':False,
    'footprint':[15,4,12],'size_group':'world_scale','map_sequences':['swarmintelligence'],
    'tags':['ants','stigmergy','turmites','three scales','grabbable','Ant Colony V2'],
    'qfep_connection':'A shared pattern can become a thing held or a ground crossed. Scale changes the encounter; it does not establish that two different rules describe the same organism.',
    'parameters':{'footprint':[15,4,12],'size_group':'world_scale'}}}})
print('Added ant scale court. Other halls, lesson code and texts retained.')
