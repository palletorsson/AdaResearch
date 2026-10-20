"""Give only the Flow Fields hall's existing table a hand editing interface."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
H='SwarmIntelligence_FlowFields'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
mp=R/f'commons/maps/{H}/map_data.json';m=read(mp)
assert m['layers']['interactables'][2][4].startswith(('flow_field_table','flow_direction_table'))
m['layers']['interactables'][2][4]='flow_direction_table:0:0:1#plinth:0#pin:1'
rects=m['map_info']['museum']['sculpture_clear_rects']
if [3,1,9,4] not in rects:rects.append([3,1,9,4])
write(mp,m)
pp=R/'commons/data/museum/em_plan.json';p=read(pp)
row=next(r for r in p['plans'] if r['map']==H)
item=next(a for a in row['artifacts'] if a['token'] in ['flow_field_table','flow_direction_table'])
item['token']='flow_direction_table';item['rotation']=0;item['config']={'plinth':'0','pin':'1'}
ending='\r\n' if pp.read_bytes().endswith(b'\r\n') else '\n'
pp.write_bytes((json.dumps(p,ensure_ascii=False,separators=(',',':'))+ending).encode('utf-8'))
write(R/'commons/artifacts/registry/flow_direction_table.json',{'artifacts':{'flow_direction_table':{
 'lookup_name':'flow_direction_table','name':'Leave a direction','scene':'res://commons/artifacts/flow_direction_table/flow_direction_table.tscn',
 'description':'The existing flow table with a small hand surface. Hold the carried point action and draw directions into its field; the original agents read the result.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'auto_ground':False,'footprint':[3,3,5],'size_group':'medium','map_sequences':['swarmintelligence'],
 'tags':['flow field','hand','direction','grabbable','editing'],
 'qfep_connection':'A collective turn can follow a direction written into the environment. The bodies keep moving after the author releases the point; the field retains the instruction.',
 'parameters':{'footprint':[3,3,5],'size_group':'medium'}}}})
print('Upgraded one table placement; original crowd and room dimensions preserved.')
