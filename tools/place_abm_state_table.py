"""Give the existing, complete ABM lesson a permanent museum table."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
H='SwarmIntelligence_Agent_Based_Modeling_ABM'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/f'commons/maps/{H}/map_data.json';d=read(p)
assert d['layers']['interactables'][4][9] in ['physarum_colony','']
d['layers']['interactables'][4][9]=''
assert d['layers']['interactables'][3][9] in ['', 'abm_state_table:0:0:1#plinth:0#pin:1']
d['layers']['interactables'][3][9]='abm_state_table:0:0:1#plinth:0#pin:1'
for x,z in [(1,1),(7,8),(6,9)]:d['layers']['utilities'][z][x]=''
for x,z,t in [(6,1,'sp'),(6,2,'s'),(6,8,'t')]:d['layers']['utilities'][z][x]=t
d['map_info']['museum']['portal_exit']={'approach':'from_hall'}
write(p,d)
p=R/'commons/data/museum/em_plan.json';data=p.read_bytes();plan=read(p)
row=next(r for r in plan['plans'] if r['map']==H)
a=next(a for a in row['artifacts'] if a['token'] in ['physarum_colony','abm_state_table'])
a.update(token='abm_state_table',cell=[9,3],tile_cell=[9,3],rotation=0,support_height_m=0.0,config={'plinth':'0','pin':'1'})
a['ruled']['cell']=[9,3]
p.write_bytes((json.dumps(plan,ensure_ascii=False,separators=(',',':'))+ ('\r\n' if data.endswith(b'\r\n') else '\n')).encode('utf-8'))
write(R/'commons/artifacts/registry/abm_state_table.json',{'artifacts':{'abm_state_table':{
 'lookup_name':'abm_state_table','name':'ABM: what the point carries',
 'scene':'res://commons/artifacts/abm_state_table/abm_state_table.tscn',
 'description':'The complete printed six-point foraging lesson, permanently in the museum. Hold, move, release and step to see a state change. Replace agents keeps the trace; Clear All erases both.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'auto_ground':False,
 'footprint':[2.7,2.4,3.2],'size_group':'large','parameters':{'footprint':[2.7,2.4,3.2]},
 'qfep_connection':'The same body responds differently when it carries food. Replacing individual records need not erase the shared history they inherit.'}}})
print('Installed the exact printed lesson; kept existing colony, navigator and listening court.')
