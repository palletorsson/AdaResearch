from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/space/entropy-ruin-2026-09-16'
OUT.mkdir(parents=True,exist_ok=True)
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8'))
def write(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p='commons/maps/Random_Entropy/map_data.json'; d=read(p)
if d['map_info']['dimensions']['depth']==23:
    (OUT/'before-map.json').write_text(json.dumps(d,indent=2),encoding='utf-8')
    for name,rows in d['layers'].items():
        old_exit=rows.pop()
        for z in range(8):
            rows.append([rows[1][x] if name=='structure' else ' ' for x in range(17)])
        rows.append(old_exit)
    d['map_info']['dimensions']['depth']=31
    d['map_info']['museum']['sculpture_clear_rects']=[[1,1,15,29]]
assert str(d['layers']['interactables'][26][8]).strip() in ('','entropy_ruin#controls:compact#control_front:-2.0#control_facing:-z')
d['layers']['interactables'][26][8]='entropy_ruin#controls:compact#control_front:-2.0#control_facing:-z'
write(p,d)
p='commons/artifacts/registry/randomness.json'; registry=read(p)
registry['artifacts']['entropy_ruin']={
 'lookup_name':'entropy_ruin','name':'What still holds?','scene':'res://commons/artifacts/randomness_space/entropy_ruin.tscn',
 'category':'procedural','sequence':'randomness','map_sequences':['randomness'],'map_ready':True,'include_in_map_data':True,
 'description':'Four fluted stone columns and a masonry wall dismantle by seeded top-piece selection. All 116 stones remain as architecture or bounded rubble. Run/pause, one stone, restore.',
 'qfep_connection':'An architectural form loses its arrangement while retaining its pieces. The staged rule invites comparison with, without equating it to, the hall\'s Shannon symbol-count measurement.',
 'parameters':{'footprint':[6.4,3.6,4.0],'size_group':'room_scale'},
 'interactions':['RUN / PAUSE freezes selection and descent','ONE STONE places the next exposed piece in rubble','RESTORE rebuilds and resets seed 79, paused']}
write(p,registry)
p='commons/data/artifact_roles.json'; roles=read(p)
roles['roles']['Random_Entropy']['entropy_ruin']='primary'
if 'entropy_ruin' not in roles['order']['Random_Entropy']['primary']: roles['order']['Random_Entropy']['primary'].append('entropy_ruin')
write(p,roles)
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
    plan=read(p)
    for i,row in enumerate(plan['plans']):
        if row['map']=='Random_Entropy': plan['plans'][i]=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'randomness')
    write(p,plan)
placements=[{'x':x,'z':z,'lookup':v.split('#')[0].split(':')[0],'token':v} for z,row in enumerate(d['layers']['interactables']) for x,v in enumerate(row) if str(v).strip() not in ('','0')]
(OUT/'manifest.json').write_text(json.dumps([{'map':'Random_Entropy','hero':'shannon_entropy_meter','size':d['map_info']['dimensions'],'placements':placements,'count':len(placements)}],indent=2),encoding='utf-8')
