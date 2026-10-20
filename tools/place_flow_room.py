"""Contain the ant comparison; open the authored routes in Flow Fields only."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
H='SwarmIntelligence_FlowFields'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/f'commons/maps/{H}/map_data.json';m=read(p)
assert m['layers']['interactables'][2][4].startswith('flow_direction_table')
for row in m['layers']['interactables']:
 for x,token in enumerate(row):
  if token.split(':')[0].split('#')[0] in ['AntColonyV2','ant_colony_table','ecosystem_simulation','flow_ecosystem_stand']:row[x]=''
m['layers']['interactables'][2][9]='ant_colony_table:0:0:1#plinth:0#pin:1'
m['layers']['interactables'][7][2]='flow_ecosystem_stand:0:0:1#plinth:0#pin:1'
for x,z in [(10,3),(10,7),(6,7)]:m['layers']['structure'][z][x]='1'
m['layers']['structure'][7][2]='1'
for row in m['layers']['utilities']:
 for x,token in enumerate(row):
  if token in ['s','sp','t']:row[x]=''
m['layers']['utilities'][1][6]='sp'
m['layers']['utilities'][2][6]='s'
m['layers']['utilities'][8][6]='t'
m['map_info']['museum']['portal_exit']={'approach':'from_hall'}
m['map_info']['museum']['sculpture_clear_rects']=[[1,1,12,9],[11,1,32,14]]
m['map_info']['description']='A hand-written direction field beside a contained Ant Colony V2 comparison. An open route joins the table, the ecosystem plinth and the walk-in crowd. Entry and exit align with the north and south openings.'
write(p,m)
p=R/'commons/data/museum/em_plan.json';oldbytes=p.read_bytes();d=read(p)
r=next(x for x in d['plans'] if x['map']==H)
r['tile']=[['4' if c=='w' else '0' if not c else c for c in row] for row in m['layers']['structure']]
r['interior_count']=sum(c=='1' for row in r['tile'] for c in row)
a=next(a for a in r['artifacts'] if a['token'] in ['AntColonyV2','ant_colony_table'])
a.update(token='ant_colony_table',cell=[9,2],tile_cell=[9,2],rotation=0,support_height_m=0.0,config={'plinth':'0','pin':'1'})
a['ruled']['cell']=[9,2]
a=next(a for a in r['artifacts'] if a['token'] in ['ecosystem_simulation','flow_ecosystem_stand'])
a.update(token='flow_ecosystem_stand',cell=[2,7],tile_cell=[2,7],support_height_m=0.0,config={'plinth':'0','pin':'1'})
a['ruled']['cell']=[2,7]
p.write_bytes((json.dumps(d,ensure_ascii=False,separators=(',',':'))+ ('\r\n' if oldbytes.endswith(b'\r\n') else '\n')).encode())
write(R/'commons/artifacts/registry/ant_colony_table.json',{'artifacts':{'ant_colony_table':{
 'lookup_name':'ant_colony_table','name':'Ant Colony V2 — a trail comparison','scene':'res://commons/artifacts/ant_colony_table/ant_colony_table.tscn',
 'description':'The original 50 m Ant Colony V2 simulation viewed on a 1.8 m table, with a nearby pause/play button. Private physics retains its original scale.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'auto_ground':False,'map_sequences':['swarmintelligence'],
 'footprint':[2,2,2.4],'size_group':'medium','parameters':{'footprint':[2,2,2.4],'size_group':'medium'},
 'tags':['ants','comparison','field','table'],'qfep_connection':'The colony changes the field it reads. Beside a hand-authored direction field, this comparison makes the source of an instruction visible.'}}})
print('Flow Fields: one contained colony, one moved plinth, four cleared posts, authored entry/exit.')

p=R/'commons/artifacts/registry/ant_colony_table.json';d=read(p)
d['artifacts']['flow_ecosystem_stand']={
 'lookup_name':'flow_ecosystem_stand','name':'Ecosystem - a supported comparison',
 'scene':'res://commons/artifacts/flow_comparison_stands/ecosystem_stand.tscn',
 'description':'The existing ecosystem, unchanged on an 80 cm solid plinth.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,
 'footprint':[1,1.5,1],'size_group':'compact','parameters':{'footprint':[1,1.5,1],'size_group':'compact'},
 'qfep_connection':'An existing comparison of local encounters and population-level support, given space beside the supplied direction field.'}
write(p,d)
