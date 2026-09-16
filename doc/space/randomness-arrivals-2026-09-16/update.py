import json,pathlib,sys
R=pathlib.Path.cwd(); O=R/'doc/space/randomness-arrivals-2026-09-16'; sys.path.insert(0,str(R/'tools'))
from em_map_halls import derive_row

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def backup(p):
 q=O/'before'/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():q.write_bytes(p.read_bytes())
p=R/'commons/artifacts/registry/randomness.json';backup(p);d=read(p)
d['artifacts']['silhouette_arrivals']={'lookup_name':'silhouette_arrivals','name':'Who arrives?','scene':'res://commons/artifacts/randomness_space/silhouette_arrivals.tscn','category':'randomness','sequence':'randomness','map_sequences':['randomness'],'map_ready':True,'include_in_map_data':True,'parameters':{'footprint':[3,3,4],'size_group':'medium'},'description':'Seeded sampling of six places and independently sampled silhouette dress. Bounded non-hostile arrivals with replay.'};save(p,d)
p=R/'commons/maps/Random_Mushrooms/map_data.json';backup(p);d=read(p);d['layers']['interactables'][4][13]='silhouette_arrivals#controls:compact#control_front:-1.65#control_facing:-z';save(p,d)
p=R/'commons/maps/Random_Walk/map_data.json';backup(p);d=read(p)
d['layers']['interactables'][17][9]+='#glass_moat:true'
for z in range(10,25):
 for x in range(2,17):
  if (x in (2,16) or z in (10,24)) and not (z in (10,24) and x in (8,9,10)):d['layers']['structure'][z][x]='0'
d['map_info']['museum']['basin']={'depth':2.5,'glass':False,'fire':False};save(p,d)
p=R/'commons/data/artifact_roles.json';backup(p);d=read(p);d['roles']['Random_Mushrooms']['silhouette_arrivals']='secondary'
if 'silhouette_arrivals' not in d['order']['Random_Mushrooms']['secondary']:d['order']['Random_Mushrooms']['secondary'].append('silhouette_arrivals')
save(p,d)
for rel in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 p=R/rel;backup(p);d=read(p)
 for i,row in enumerate(d['plans']):
  if row.get('map') in ['Random_Walk','Random_Mushrooms']:d['plans'][i]=derive_row(row['pearl'],row['map'],row['museum'],row['pearl_index'],row['pearls_total'],'randomness')
 save(p,d)
p=R/'commons/maps/Random_Mushrooms/final.md';backup(p);s=p.read_text(encoding='utf-8');s += '\nAt the smaller arrival stage, wait for a silhouette. Another place is chosen from those still empty. Six arrivals fill it; the program does not keep producing bodies without somewhere to put them. Press REPLAY and watch the places return in the same order. Press DRESS: the collars, hems and colours change while the occupied places remain. A different appearance has not yet become a different permission. These visitors neither block nor attack you. What rule would make their presence matter to one another?\n';p.write_bytes(s.encode('utf-8'))
p=R/'commons/maps/Random_Mushrooms/artifacts.md';backup(p);p.write_bytes((p.read_text(encoding='utf-8')+'\n| `silhouette_arrivals` | secondary | Six seeded arrivals; independent dress variations, replay and automatic/manual controls. |\n').encode('utf-8'))
p=R/'commons/maps/Random_Walk/final.md';backup(p);s=p.read_text(encoding='utf-8').replace('Now enter the larger glass frame.','Cross the bridge over the narrow basin and enter the larger glass frame. The gallery and the experiment remain at the same level; the gap distinguishes their floors.');p.write_bytes(s.encode('utf-8'))
print('Updated two halls, registry, roles, book and both plans.')
