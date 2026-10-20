"""Remove the redundant Void floor, preserving all other authored placements."""
from pathlib import Path
import copy, json, re, urllib.request

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-void-without-godot-map'
API='http://localhost:3003/api/void-layout'
payload=json.load(urllib.request.urlopen(API))
rooms=copy.deepcopy(payload['rooms'])
index=next(i for i,f in enumerate(rooms['floors']) if f['map']=='Primitives_Godot')
assert index==9
frame_path=ROOT/'commons/void/layout.json'
frame_text=frame_path.read_text(encoding='utf-8')
frame=json.loads(frame_text)
OUT.mkdir(parents=True,exist_ok=True)
assert not (OUT/'removed-floor.json').exists(), 'Already applied; do not overwrite the archive.'
(OUT/'rooms-before.json').write_text(json.dumps(payload['rooms'],indent=2)+'\n',encoding='utf-8')
(OUT/'layout-before.json').write_text(frame_text,encoding='utf-8')
removed=rooms['floors'].pop(index)
for new_index,floor in enumerate(rooms['floors']):
    if new_index>=index:
        floor['title']=re.sub(r'^Floor \d+ /',f'Floor {new_index:02} /',floor['title'])
    for item in floor['artifacts']+floor.get('copies',[]):
        source=item.get('config',{}).get('editor_source')
        if source:
            assert source['floor']!=index,'A copied preview still references the removed floor.'
            if source['floor']>index: source['floor']-=1
frame['levels']=[-i*frame['storey_height'] for i in range(len(rooms['floors']))]
frame['floor_roles']=[f['title'] for f in rooms['floors']]
frame['status']='Primitives route: 13 floors; Grid shares Trace; Ignorance leads directly to Columns.'
# The server validates the floor count against this shared frame.
frame_path.write_text(json.dumps(frame,indent=2)+'\n',encoding='utf-8')
try:
    request=urllib.request.Request(API,json.dumps({'rooms':rooms,'revision':payload['revision']}).encode(),{'Content-Type':'application/json'},method='POST')
    receipt=json.load(urllib.request.urlopen(request))
except Exception:
    frame_path.write_text(frame_text,encoding='utf-8')
    raise
(OUT/'removed-floor.json').write_text(json.dumps(removed,indent=2)+'\n',encoding='utf-8')
tree_path=ROOT/'commons/void/capacity-tree.json'
tree=json.loads(tree_path.read_text(encoding='utf-8'))
def remap(value):
    if isinstance(value,dict):
        if isinstance(value.get('floor'),int) and value['floor']>index: value['floor']-=1
        for item in value.values(): remap(item)
    elif isinstance(value,list):
        for item in value: remap(item)
remap(tree)
tree_path.write_text(json.dumps(tree,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
current=json.load(urllib.request.urlopen(API))
assert current['rooms']==rooms and current['frame']==frame
for i,floor in enumerate(rooms['floors']):
    before=copy.deepcopy(payload['rooms']['floors'][i if i<index else i+1])
    before['title']=floor['title']
    assert before==floor, 'Unexpected placement change'
result={'passed':True,'removed_map':removed['map'],'preserved_floors':len(rooms['floors']),'placements_unchanged':True,'floor_order':[f['map'] for f in rooms['floors']],'save':receipt}
(OUT/'migration.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2))
