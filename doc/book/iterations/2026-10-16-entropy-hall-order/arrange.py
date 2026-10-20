from pathlib import Path
import json, shutil, sys
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
MAP=ROOT/'commons/maps/Random_Entropy'
for name in ['map_data.json','writing_wall.json','final.md','tutorial.md','plan.md','artifacts.md','intent.md','summary.md']:
    target=HERE/('before-'+name)
    if not target.exists():shutil.copy2(MAP/name,target)
path=MAP/'map_data.json';data=json.loads(path.read_text(encoding='utf8'))
old={}
for row in data['layers']['interactables']:
    for token in row:
        if token.strip():old[token.split(':')[0].split('#')[0]]=token
placements={
 'shannon_entropy_meter':(8,5,180),
 'entropy_jar_states':(5,8,180),
 'entropy_jar':(12,8,180),
 'prefab_disorder':(19,10,180),
 'entropy_sorting_table':(5,14,180),
 'entropy_compartments':(11,14,180),
 'hardware_entropy_decay':(3,19,180),
 'entropy_axiom':(17,21,0),
 'entropy_ruin':(8,29,0),
 'signal_room':(12,48,180)}
assert set(old)==set(placements),(set(old),set(placements))
for z,row in enumerate(data['layers']['structure']):
    if z>33:continue
    for x in range(25):
        # Same room width as the existing signal bay. Keep the authored arrival.
        row[x]='5' if x in [0,24] or z in [0,33] else '1'
        if z==0 and x in [7,8,9]:row[x]='1'
        if z==33 and x in [11,12,13]:row[x]='1'
data['layers']['interactables']=[[' ']*25 for _ in range(66)]
for key,(x,z,yaw) in placements.items():
    token=old[key];parts=token.split('#');base=parts[0].split(':')
    if len(base)>1:base[1]=str(yaw)
    else:base.append(str(yaw))
    data['layers']['interactables'][z][x]='#'.join([':'.join(base)]+parts[1:])
# Preserve the grid teleporter's void contract while the museum keeps a floor.
data['layers']['structure'][64][12]='0'
# Keep the grid entrance, but give the museum a supported portal landing inside
# the threshold wall. Its frame is 1.15 m before the marker, ahead of the ledger.
data['layers']['utilities'][2][8]='sp'
museum=data['map_info']['museum']
museum['floor_cells']=[[12,64]]
museum['sculpture_clear_rects']=[[1,1,23,32],[1,34,23,64]]
museum['weathering_wall']['start_z']=26
museum['reference_studies']['signal_room']['bay']=[0,34,24,65]
data['map_info']['metadata']['n_artifacts']=len(placements)
data['documentation']={**data.get('documentation',{}),
 'layout':'Two 25 m wide bays. Museum arrival at (8,2), grid entrance at (8,0). Counting and mixing precede arrangements; the point enclosure and physical ruin have separate floor areas. A 3 m doorway at z33 leads to the signal room and exit. Hybrid and wear studies are optional side encounters.',
 'key_elements':[f'{k} at ({x},{z}), yaw {yaw}' for k,(x,z,yaw) in placements.items()]}
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row
planpath=ROOT/'commons/data/museum/em_plan.json';plan=json.loads(planpath.read_text(encoding='utf8'))
row=next(r for r in plan['plans'] if r.get('map')=='Random_Entropy')
if not (HERE/'before-museum-row.json').exists():(HERE/'before-museum-row.json').write_text(json.dumps(row,indent=2),encoding='utf8')
fresh=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],row['sequence'])
for key in ['tile','h','rooms','room','artifacts','interior_count']:row[key]=fresh[key]
row['weathering_wall']=museum['weathering_wall']
planpath.write_text(json.dumps(plan,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(HERE/'placement.json').write_text(json.dumps({'placements':placements,'main_order':['shannon_entropy_meter','entropy_jar_states','entropy_jar','entropy_sorting_table','entropy_compartments','entropy_axiom','entropy_ruin','signal_room'],'optional':['prefab_disorder','hardware_entropy_decay'],'entry':[8,2],'door':[12,33],'exit':[12,64]},indent=2),encoding='utf8')
print('Placed all ten artifacts; widened first bay; moved dividing doorway to z33; kept signal room and sequence unchanged.')
