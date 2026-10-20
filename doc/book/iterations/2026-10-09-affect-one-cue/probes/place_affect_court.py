from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1];M='SoftBodies_Affect_Theory_Visualization'
def read(p):return json.loads(p.read_text(encoding='utf8'))
changes={'soft_workshop_console':([15,3],[15,11]),'radiolaria':([9,11],[15,21])}
p=R/'commons/maps'/M/'map_data.json';d=read(p);cells=d['layers']['interactables']
for token,(old,new) in changes.items():
 if cells[old[1]][old[0]].split(':')[0]==token:
  assert not cells[new[1]][new[0]];cells[new[1]][new[0]]=cells[old[1]][old[0]];cells[old[1]][old[0]]=''
p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
p=R/'commons/data/museum/em_plan.json';stamp=p.stat().st_mtime_ns;d=read(p);before=copy.deepcopy(d)
row=next(x for x in d['plans'] if x['map']==M)
for a in row['artifacts']:
 if a['token'] in changes:
  a['cell']=changes[a['token']][1];a['tile_cell']=a['cell'];a['ruled']['cell']=a['cell']
assert [x for x in d['plans'] if x['map']!=M]==[x for x in before['plans'] if x['map']!=M]
assert stamp==p.stat().st_mtime_ns;p.write_bytes(json.dumps(d,ensure_ascii=False,separators=(',',':')).encode())
print('Desk beside approach, forms centred in the hall. Other museum rows unchanged.')
