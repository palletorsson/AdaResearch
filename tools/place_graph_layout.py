from pathlib import Path
import json,copy
R=Path(__file__).resolve().parents[1];ID='GT_Layout'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/ID/'map_data.json';d=read(p)
d['map_info'].update(name='A connection is not a coordinate',title='A connection is not a coordinate',description='Keep adjacency fixed while forces change the drawing. A clear passage separates the installed cube graph from the learner bay.')
d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'gate':False,'open_roof':True,'plinths':False,'artifact_placement':'map','sculpture_clear_rects':[[1,1,13,11]]}
d['map_info']['metadata']['design_notes']='Continuous floor, two open bays and a central passage. The installed eight-vertex layout is elevated and reduced to fit the right bay. Left bay is for the printed seven-vertex learner study. Other graph exhibits remain available in their registry; they are not prerequisites here.'
d['map_info']['metadata']['n_artifacts']=1
floor=[['w' if x in (0,14) or z in (0,12) else '1' for x in range(15)] for z in range(13)]
for z in [0,12]:
 for x in [6,7,8]:floor[z][x]='1'
inter=[['']*15 for _ in range(13)];inter[7][10]='force_directed_layout:180:2.4:0.3#plinth:0#pin:1#graph:cube#layout_seed:41'
util=[['']*15 for _ in range(13)];util[1][7]='s';util[11][7]='t'
d['layers']={'structure':floor,'interactables':inter,'utilities':util}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=R/'commons/data/museum/em_plan.json';d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['plans'] if x.get('map')==ID)
row.update(tile=[['4' if x=='w' else x for x in line] for line in floor],gate=False,interior_count=sum(x=='1' for line in floor for x in line))
row['artifacts']=[{'token':'force_directed_layout','cell':[10,7],'tile_cell':[10,7],'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':2.4,'hand':False,'ruled':{'by':'map: '+ID,'cell':[10,7]},'config':{'plinth':'0','pin':'1','graph':'cube','layout_seed':'41'},'scale':.3}]
assert [x for x in d['plans'] if x.get('map')!=ID]==[x for x in old['plans'] if x.get('map')!=ID]
p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')),encoding='utf8')
print('Only GT_Layout arrangement and plan row changed; production graph code retained.')
