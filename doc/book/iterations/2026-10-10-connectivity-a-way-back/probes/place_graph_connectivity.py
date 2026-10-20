from pathlib import Path
import json,copy
R=Path(__file__).resolve().parents[1];ID='GT_Connectivity'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/ID/'map_data.json';d=read(p)
d['map_info'].update(name='A way back',title='A way back',description='Follow directed paths outward and back. A small carried graph finds one strongly connected group; the existing Tarjan exhibit offers a larger two-ring comparison.')
d['map_info']['metadata']['design_notes']='Continuous 14x10 floor, clear centre route and original doorway positions. Existing Tarjan split graph in right bay; temporary learner in left bay. Other algorithm exhibits remain in catalogue.'
d['map_info']['museum']={'wall_height':3,'gate_depth_rows':0,'gate':False,'open_roof':True,'plinths':False,'artifact_placement':'map','sculpture_clear_rects':[[1,1,12,8]]}
floor=[['w' if x in (0,13) or z in (0,9) else '1' for x in range(14)] for z in range(10)]
for x in [4,5,6,7]:floor[0][x]='1'
for x in [5,6,7]:floor[9][x]='1'
inter=[['']*14 for _ in range(10)];inter[6][10]='tarjan_algorithm:180:1.15:0.5#mutuality:split#graph_size:12#plinth:0#pin:1'
util=[['']*14 for _ in range(10)];util[1][6]='s';util[8][6]='t'
d['layers']={'structure':floor,'utilities':util,'interactables':inter}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=R/'commons/data/museum/em_plan.json';d=read(p);old=copy.deepcopy(d);stamp=p.stat().st_mtime_ns
row=next(x for x in d['plans'] if x.get('map')==ID)
row.update(tile=[['3' if x=='w' else x for x in line] for line in floor],gate=False,interior_count=sum(x=='1' for line in floor for x in line))
row['artifacts']=[{'token':'tarjan_algorithm','cell':[10,6],'tile_cell':[10,6],'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':1.15,'hand':False,'ruled':{'by':'map: '+ID,'cell':[10,6]},'config':{'mutuality':'split','graph_size':'12','plinth':'0','pin':'1'},'scale':.5}]
assert [x for x in d['plans'] if x.get('map')!=ID]==[x for x in old['plans'] if x.get('map')!=ID]
assert stamp==p.stat().st_mtime_ns
p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')),encoding='utf8')
print('Connectivity placement only; algorithms and registry unchanged.')
