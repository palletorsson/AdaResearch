from pathlib import Path
import json,copy
R=Path(__file__).resolve().parents[1];ID='GT_Network_Analysis'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/ID/'map_data.json';d=read(p)
d['map_info'].update(name='Important by which measure?',title='Important by which measure?',description='An inspectable fictional ledger. Count incoming and outgoing records, change the filter, move the drawing. The record wall and learner bay share a continuous museum floor.')
d['map_info']['metadata']['design_notes']='Continuous 23x34 floor. Existing evidence wall along right boundary, its controls facing the room. Clear left aisle joins original entry and rear exit. Learner bay at front left. Other network scenes remain catalogued.'
d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'gate':False,'open_roof':True,'plinths':False,'artifact_placement':'map','reference_studies':{'evidence_network':{'cell':[17,20],'rotation':270,'bay':[10,12,22,29]}},'sculpture_clear_rects':[[1,1,21,32]]}
floor=[['w' if x in (0,22) or z in (0,33) else '1' for x in range(23)] for z in range(34)]
for x in [5,6,7]:floor[0][x]='1'
for x in [10,11,12]:floor[33][x]='1'
inter=[['']*23 for _ in range(34)];inter[20][17]='evidence_network:270:0#plinth:0#pin:1'
util=[['']*23 for _ in range(34)];util[1][6]='s';util[32][11]='t'
d['layers']={'structure':floor,'utilities':util,'interactables':inter}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=R/'commons/data/museum/em_plan.json';d=read(p);old=copy.deepcopy(d);stamp=p.stat().st_mtime_ns
row=next(x for x in d['plans'] if x.get('map')==ID)
row.update(tile=[['4' if x=='w' else x for x in line] for line in floor],gate=False,interior_count=sum(x=='1' for line in floor for x in line))
row['artifacts']=[{'token':'evidence_network','cell':[17,20],'tile_cell':[17,20],'rotation':270,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+ID,'cell':[17,20]},'config':{'plinth':'0','pin':'1'},'scale':1.0}]
assert [x for x in d['plans'] if x.get('map')!=ID]==[x for x in old['plans'] if x.get('map')!=ID]
assert stamp==p.stat().st_mtime_ns
p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')),encoding='utf8')
print('Only Network Analysis placements changed. Exhibit code and registry untouched.')
