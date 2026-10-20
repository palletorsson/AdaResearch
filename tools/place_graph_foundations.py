"""Focused first-hall arrangement; preserve other halls and all artifact code."""
from pathlib import Path
import json,copy,shutil
R=Path(__file__).resolve().parents[1]; M='GT_Foundations'
B=R/'doc/book/iterations/2026-10-10-graph-two-orders/before'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def preserve(p):
 q=B/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
p=R/'commons/maps'/M/'map_data.json';preserve(p);d=read(p)
d['map_info'].update(name='Two travellers, one graph',title='Two travellers, one graph',description='Keep connections fixed; compare breadth-first and depth-first visit order. A small bridge model remains a supporting encounter.')
d['map_info']['museum']={'wall_height':4,'gate_depth_rows':0,'gate':False,'open_roof':True,'plinths':False,'artifact_placement':'map','sculpture_clear_rects':[[1,1,11,10]]}
d['map_info']['metadata']['design_notes']='Continuous floor and central aisle. Fifteen-lamp traversal on the right; a small bridge model on the rear left. Front-left bay reserved for the printed learner study. Earlier oversized stamped graph worlds are retained in the registry and baseline, not placed here.'
floor=[['w' if x in (0,12) or z in (0,11) else '1' for x in range(13)] for z in range(12)]
for z in (0,11):
 for x in (5,6,7):floor[z][x]='1'
inter=[['']*13 for _ in range(12)];inter[7][9]='two_travelers:180:0:1#plinth:0#pin:1';inter[8][3]='KonigsbergBridge:180:0:0.10#plinth:0#pin:1'
utility=[['']*13 for _ in range(12)];utility[1][6]='s';utility[10][6]='t'
d['layers']={'structure':floor,'utilities':utility,'interactables':inter}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
p=R/'commons/data/museum/em_plan.json';preserve(p);d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['plans'] if x.get('map')==M)
row.update(tile=[['4' if x=='w' else x for x in line] for line in floor],gate=False,interior_count=sum(x=='1' for line in floor for x in line))
row['artifacts']=[]
for token,cell,scale in [('two_travelers',[9,7],1.0),('KonigsbergBridge',[3,8],.10)]:
 row['artifacts'].append({'token':token,'cell':cell,'tile_cell':cell,'rotation':180,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,'ruled':{'by':'map: '+M,'cell':cell},'config':{'plinth':'0','pin':'1'},'scale':scale})
assert [x for x in d['plans'] if x.get('map')!=M]==[x for x in old['plans'] if x.get('map')!=M]
p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')),encoding='utf8')
preserve(R/'ada_run/necklace_hand.json')
p=R/'commons/artifacts/registry/graphtheory.json';preserve(p)
raw=p.read_text(encoding='utf8')
if not read(p)['artifacts']['two_travelers'].get('map_ready',False):
 raw=raw.replace('"two_travelers": {','"two_travelers": {\n\t\t\t"lookup_name": "two_travelers",\n\t\t\t"map_ready": true,',1)
 p.write_text(raw,encoding='utf8')
print('Only GT_Foundations map and museum plan row changed; older hand stamp preserved and bypassed by map declaration.')
