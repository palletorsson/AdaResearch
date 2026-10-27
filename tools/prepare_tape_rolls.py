"""Add the tape family to shared catalogues; stage a guarded additive room draft."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/tape-rolls';OUT.mkdir(exist_ok=True)
def read(rel):return json.loads((ROOT/rel).read_text(encoding='utf-8-sig'))
def write(rel,data):(ROOT/rel).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
rooms=read('commons/void/rooms.json')
before=OUT/'rooms.before.json'
if not before.exists():before.write_bytes((ROOT/'commons/void/rooms.json').read_bytes())
assert not any(a['id']=='tape-supply' for a in rooms['floors'][3]['artifacts']), 'Already placed; preserve user edits'
entry=dict(id='tape-supply',artifact='tape_roll_station',station='SW',position=[-8.0,5.25],height=0,facing=0,scale=1,config={})
rooms['floors'][3]['artifacts'].append(entry)
(OUT/'rooms.draft.json').write_text(json.dumps(rooms,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'entry.json').write_text(json.dumps(entry,indent=2)+'\n',encoding='utf-8')
registry=read('commons/artifacts/registry/tape_rolls.json')['artifacts']
catalog=read('commons/void/catalog.json')
prefabs=read('commons/void/primitive-prefabs.json')
graph=read('commons/void/capacity-artifacts.json')
for key,value in registry.items():
    record=dict(value,label=value['name'],footprint=[1.8,2.1,1.2] if key=='tape_roll_station' else [.3,.52,.15])
    catalog['artifacts'][key]=record
    existing=next((p for p in prefabs['prefabs'] if p['id']==key),None)
    if existing:
        existing['scene']=value['scene']
        if key!='tape_roll_station':
            member={'tape_roll_masking':'MaskingRoll','tape_roll_pink':'PinkRoll','tape_roll_barrier':'BarrierRoll'}[key]
            existing['placement']=dict(artifact='tape_roll_station',source_floor=3,source_id='tape-supply',height=.16,scale=1,
                config=dict(only_parts=[member],parts={member:dict(position=[0,0,0],rotation=[0,0,0])}))
        continue
    p=dict(id=key,title=value['name'],map='Point_Lines',family='Line / tape',scene=value['scene'],
        dimensions=record['footprint'],anchor='Roll centre; endpoints attach in each touched object local frame',
        behaviour=value['description'],learn=value['qfep_connection'],icon='line',recipe=['line','point_held'])
    if key=='tape_roll_station':p['placement']=dict(artifact=key,source_floor=3,source_id='tape-supply',height=0,scale=1)
    else:p['config']=value['default_params']
    prefabs['prefabs'].append(p)
    if not any(n['id']==key for n in graph['nodes']):
        graph['nodes'].append(dict(id=key,title=value['name'],sequence='primitives',learn=value['qfep_connection'],
            use=value['description'],icon='line',insertion=dict(map='Point_Lines',basis='authored',reason='A carried roll turns two endpoints into a material mark or boundary.')))
    graph['edges'].append(dict(source='line',target=key,kind='associate',label='Make the segment into an attached strip; the roll chooses its material and width.'))
write('commons/void/catalog.json',catalog);write('commons/void/primitive-prefabs.json',prefabs);write('commons/void/capacity-artifacts.json',graph)
print('Four shared tape catalogue entries; main layout unchanged; draft ready.')
