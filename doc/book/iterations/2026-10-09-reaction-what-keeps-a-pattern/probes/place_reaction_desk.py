from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1];M='ProceduralGeneration_Reaction_Diffusion_Systems'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/M/'map_data.json';d=read(p);cells=d['layers']['interactables']
if cells[3][15].startswith('soft_workshop_console'):
 assert not cells[6][8];cells[6][8]=cells[3][15];cells[3][15]=''
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
p=R/'commons/data/museum/em_plan.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['plans'] if x['map']==M);a=next(x for x in row['artifacts'] if x['token']=='soft_workshop_console')
a['cell']=[8,6];a['tile_cell']=[8,6];a['ruled']['cell']=[8,6]
assert [x for x in d['plans'] if x['map']!=M]==[x for x in old['plans'] if x['map']!=M]
assert p.stat().st_mtime_ns==stamp;p.write_bytes(json.dumps(d,ensure_ascii=False,separators=(',',':')).encode())
print('Desk moved to the primary field, arrival cleared; other exhibits preserved.')
