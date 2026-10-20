from pathlib import Path
import json,copy
R=Path(__file__).resolve().parents[1];ID='GT_Spanning_Trees'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/ID/'map_data.json';d=read(p)
# Keep existing architecture, film and doors; move only the large comparison.
layer=d['layers']['interactables']
for row in layer:
 for x,token in enumerate(row):
  if token.startswith('mst_visualization'):row[x]=''
layer[11][11]='mst_visualization:180:2.8:0.28#desktop_ui:off'
d['map_info']['metadata']['design_notes']='Existing 15x17 open gallery retained. Distance-weighted MST comparison moved to right rear, lowered and reduced; wall film retained. Left front bay for the explicitly installed student study; clear centre route.'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=R/'commons/data/museum/em_plan.json';d=read(p);old=copy.deepcopy(d);stamp=p.stat().st_mtime_ns
row=next(x for x in d['plans'] if x.get('map')==ID)
artifact=next(x for x in row['artifacts'] if x.get('token')=='mst_visualization')
artifact.update(cell=[11,11],tile_cell=[11,11],rotation=180,scale=.28,support_height_m=2.8,hand=False)
artifact['ruled']={'by':'map: '+ID,'cell':[11,11]}
assert [x for x in d['plans'] if x.get('map')!=ID]==[x for x in old['plans'] if x.get('map')!=ID]
assert stamp==p.stat().st_mtime_ns
p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')),encoding='utf8')
print('Existing gallery retained; MST comparison moved to right rear.')
