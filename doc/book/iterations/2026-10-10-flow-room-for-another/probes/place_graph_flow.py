from pathlib import Path
import json,copy
R=Path(__file__).resolve().parents[1];ID='GT_Flow'
def read(p):return json.loads(p.read_text(encoding='utf8'))
p=R/'commons/maps'/ID/'map_data.json';d=read(p)
d['map_info'].update(name='Room for another',title='Flow: room for another',description='Allocate crate slots in a concrete harbour; revise an earlier route. Compare the existing forward-only preflow display and eleven documented real-world contexts.')
d['map_info']['metadata']['design_notes']='13x12 continuous floor with original central door openings. Context gallery left, forward-only comparison right rear; right-front bay for printed learner harbour. No extra algorithm prerequisites.'
d['map_info']['museum']={'wall_height':3,'gate_depth_rows':0,'gate':False,'open_roof':True,'plinths':False,'artifact_placement':'map','sculpture_clear_rects':[[1,1,11,10]]}
floor=[['w' if x in (0,12) or z in (0,11) else '1' for x in range(13)] for z in range(12)]
for x in [5,6,7]:floor[0][x]='1';floor[11][x]='1'
inter=[['']*13 for _ in range(12)]
inter[6][3]='graph_worlds:180:0:1#plinth:0#pin:1'
inter[9][9]='push_relabel_algorithm:180:1.2:0.32#plinth:0#pin:1'
util=[['']*13 for _ in range(12)];util[1][6]='s';util[10][6]='t'
d['layers']={'structure':floor,'utilities':util,'interactables':inter}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=R/'commons/data/museum/em_plan.json';d=read(p);old=copy.deepcopy(d);stamp=p.stat().st_mtime_ns
row=next(x for x in d['plans'] if x.get('map')==ID)
row.update(tile=[['3' if x=='w' else x for x in line] for line in floor],gate=False,interior_count=sum(x=='1' for line in floor for x in line))
row['artifacts']=[]
for token,cell,height,scale in [('graph_worlds',[3,6],0,1),('push_relabel_algorithm',[9,9],1.2,.32)]:
 row['artifacts'].append({'token':token,'cell':cell,'tile_cell':cell,'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':height,'hand':False,'ruled':{'by':'map: '+ID,'cell':cell},'config':{'plinth':'0','pin':'1'},'scale':scale})
assert [x for x in d['plans'] if x.get('map')!=ID]==[x for x in old['plans'] if x.get('map')!=ID]
assert stamp==p.stat().st_mtime_ns;p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')),encoding='utf8')
p=R/'commons/artifacts/registry/graph_contexts.json'
entry={'lookup_name':'graph_worlds','scene':'res://commons/artifacts/graph_worlds/graph_worlds.tscn','name':'Graph worlds: what a connection means','description':'Eleven concrete tabletop comparisons for the eight Graph Theory halls. Previous/Next selects; Try It changes a relation or allocation; Reset restores. Defaults to the harbour. Fictional datasets and limits are stated on the model.','qfep_connection':'Keep represented relations exact while exposing the limits of transferring a graph operation between material and social situations.','category':'graphtheory','dev_category':'graphtheory','complexity':'intermediate','tags':['graph','capacity','society','animal','disease','history','future'],'map_ready':True,'include_in_map_data':True,'footprint':[4,3,4],'interactions':['Select a context with Previous or Next','Try It changes the example','Reset restores the declared starting conditions']}
p.write_text(json.dumps({'artifacts':{'graph_worlds':entry}},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Flow hall: concrete gallery plus existing comparison; other scenes retained in catalogue.')
