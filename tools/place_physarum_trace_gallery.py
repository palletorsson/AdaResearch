"""Enlarge Physarum's existing hall and move its single colony into a trace court."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
H='SwarmIntelligence_PhysarumColony'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
mp=R/f'commons/maps/{H}/map_data.json';m=read(mp)
if m['map_info']['dimensions']['width']==13:
    for name,rows in m['layers'].items():
        for z,row in enumerate(rows):
            row.extend(['4' if z in [0,10] or x==27 else '1' for x in range(13,28)] if name=='structure' else ['']*15)
    for z in [4,5,6]:m['layers']['structure'][z][12]='1'
    assert m['layers']['interactables'][2][4].startswith('PhysarumColony')
    m['layers']['interactables'][2][4]=''
    m['map_info']['dimensions']['width']=28
    m['map_info']['metadata']['design_notes']+=' Existing Physarum table moved into east trace court; same private colony feeds a 6m wall and 1.2m hand surface.'
assert m['map_info']['dimensions']['width']==28
m['layers']['interactables'][5][20]='physarum_trace_gallery:0:0:1#plinth:0#pin:1'
mu=m['map_info'].setdefault('museum',{})
mu['gate']=False
mu['gate_depth_row']=0
mu.setdefault('sculpture_clear_rects',[])
for rect in [[11,1,27,10]]:
    if rect not in mu['sculpture_clear_rects']:mu['sculpture_clear_rects'].append(rect)
write(mp,m)
pp=R/'commons/data/museum/em_plan.json';p=read(pp)
row=next(x for x in p['plans'] if x['map']==H)
row['tile']=[['4' if c=='w' else c for c in line] for line in m['layers']['structure']]
row['room']['w']=28;row['h']=11;row['room']['h']=11;row['_ruling']['src_w']=28
row['interior_count']=sum(c=='1' for line in row['tile'] for c in line)
row['artifacts']=[a for a in row['artifacts'] if a['token'] not in ['PhysarumColony','physarum_trace_gallery']]
row['artifacts'].append({'token':'physarum_trace_gallery','cell':[20,5],'tile_cell':[20,5],'rotation':0,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+H,'cell':[20,5]},'scale':1.0})
ending='\r\n' if pp.read_bytes().endswith(b'\r\n') else '\n'
pp.write_bytes((json.dumps(p,ensure_ascii=False,separators=(',',':'))+ending).encode('utf-8'))
write(R/'commons/artifacts/registry/physarum_trace_gallery.json',{'artifacts':{'physarum_trace_gallery':{
 'lookup_name':'physarum_trace_gallery','name':'A mark left behind',
 'scene':'res://commons/artifacts/physarum_trace_gallery/physarum_trace_gallery.tscn',
 'description':'The existing 300-agent Physarum table, a six-metre wall and a 1.2m hand surface share one colony. Carry the point and hold its action to deposit a trace.',
 'category':'swarmintelligence','map_ready':True,'include_in_map_data':True,'auto_ground':False,
 'footprint':[10,8,9],'size_group':'world_scale','map_sequences':['swarmintelligence'],
 'tags':['physarum','trace','hand','shared field','grabbable'],
 'qfep_connection':'A hand leaves a mark that later bodies can sense. Its persistence depends on deposition, diffusion and decay, not on its author remaining present.',
 'parameters':{'footprint':[10,8,9],'size_group':'world_scale'}}}})
print('Moved the original Physarum table into its trace court; other hall plans untouched.')
