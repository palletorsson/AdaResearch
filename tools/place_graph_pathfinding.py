from pathlib import Path
import copy,json
R=Path(__file__).resolve().parents[1];ID='GT_Pathfinding'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/ID/'map_data.json';d=read(p)
d['map_info'].update(name='The route after a stone disappears',title='The route after a stone disappears',description='A river reroutes when a stone becomes unavailable. The learner carries seven vertices, adds one detour and records a path. A small maze remains a supporting encounter.')
d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'gate':False,'open_roof':True,'plinths':False,'artifact_placement':'map','sculpture_clear_rects':[[1,1,11,12]]}
d['map_info']['metadata'].update(n_artifacts=2,design_notes='Continuous13x14 floor and central passage. River on the right, compact3D maze at rear left, reserved learner bay at front left. No claim that the spark route is player navigation.')
floor=[['w' if x in (0,12) or z in (0,13) else '1' for x in range(13)] for z in range(14)]
for x in [5,6,7,8]:floor[0][x]='1'
for x in [5,6,7]:floor[13][x]='1'
inter=[['']*13 for _ in range(14)];inter[8][9]='impatient_river:180:0:1#plinth:0#pin:1';inter[10][3]='pathfinding3d:180:0:0.16#plinth:0#pin:1'
util=[['']*13 for _ in range(14)];util[1][6]='s';util[12][6]='t'
d['layers']={'structure':floor,'utilities':util,'interactables':inter}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=R/'commons/data/museum/em_plan.json';d=read(p);old=copy.deepcopy(d);row=next(x for x in d['plans'] if x.get('map')==ID)
row.update(tile=[['4' if x=='w' else x for x in line] for line in floor],gate=False,interior_count=sum(x=='1' for line in floor for x in line))
row['artifacts']=[]
for token,cell,scale in [('impatient_river',[9,8],1.0),('pathfinding3d',[3,10],.16)]:row['artifacts'].append({'token':token,'cell':cell,'tile_cell':cell,'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+ID,'cell':cell},'config':{'plinth':'0','pin':'1'},'scale':scale})
assert [x for x in d['plans'] if x.get('map')!=ID]==[x for x in old['plans'] if x.get('map')!=ID]
p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')),encoding='utf8')
p=R/'commons/artifacts/registry/graphtheory.json'
if not read(p)['artifacts']['impatient_river'].get('map_ready',False):
 raw=p.read_text(encoding='utf8').replace('"impatient_river": {','"impatient_river": {\n\t\t\t"lookup_name": "impatient_river",\n\t\t\t"map_ready": true,',1)
 p.write_text(raw,encoding='utf8')
print('GT_Pathfinding arrangement updated; river entry enabled. Artifact algorithms unchanged.')
