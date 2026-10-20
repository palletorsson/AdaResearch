from pathlib import Path
import copy,json,re
R=Path(__file__).resolve().parents[1];M='Topology_Entropy_Morphogenesis'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/M/'map_data.json';d=read(p);cells=d['layers']['interactables']
if cells[3][15].startswith('soft_workshop_console'):
 assert not cells[9][15];cells[9][15]=cells[3][15];cells[3][15]=''
encoded=json.dumps(d,ensure_ascii=False,indent=2)+'\n'
original=(R/'doc/book/iterations/2026-10-09-morphogenesis-who-connected-the-controls/before/commons/maps'/M/'map_data.json').read_text(encoding='utf8').splitlines()
lines=encoded.splitlines();assert len(lines)==len(original)
encoded='\n'.join(re.match(r'^\s*',before)[0]+after.lstrip() for before,after in zip(original,lines))+'\n'
p.write_bytes(encoded.encode())
p=R/'commons/data/museum/em_plan.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['plans'] if x['map']==M);a=next(x for x in row['artifacts'] if x['token']=='soft_workshop_console')
a['cell']=[15,9];a['tile_cell']=[15,9];a['ruled']['cell']=[15,9]
assert [x for x in d['plans'] if x['map']!=M]==[x for x in old['plans'] if x['map']!=M]
assert p.stat().st_mtime_ns==stamp;p.write_bytes(json.dumps(d,ensure_ascii=False,separators=(',',':')).encode())
print('Desk moved to the primary field, arrival cleared; other exhibits preserved.')
