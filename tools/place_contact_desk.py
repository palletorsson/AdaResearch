"""Clear the existing contact hall entrance; preserve every other shared row."""
from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1]
key='SoftBodies_Obsticals_Part2'
p=R/'commons/maps'/key/'map_data.json'
data=json.loads(p.read_text(encoding='utf8'))
cells=data['layers']['interactables']
token='soft_workshop_console:180#chapter:contact'
if cells[3][15]==token:
 assert cells[5][11]==''
 cells[3][15]='';cells[5][11]=token
 p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode())
else:assert cells[3][15]=='' and cells[5][11]==token
p=R/'commons/data/museum/em_plan.json'
data=json.loads(p.read_text(encoding='utf8'));prior=copy.deepcopy(data)
row=next(x for x in data['plans'] if x['map']==key)
desk=next(x for x in row['artifacts'] if x['token']=='soft_workshop_console')
assert desk['cell'] in [[15,3],[11,5]]
desk['cell']=[11,5];desk['tile_cell']=[11,5];desk['ruled']['cell']=[11,5]
assert [x for x in data['plans'] if x['map']!=key]==[x for x in prior['plans'] if x['map']!=key]
p.write_bytes(json.dumps(data,ensure_ascii=False,separators=(',',':')).encode())
print('Only contact hall desk moved: (15,3) -> (11,5).')
