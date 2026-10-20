from pathlib import Path
import json,re
HERE=Path(__file__).parent;ROOT=HERE.parents[3]
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
names={'Point_Trace','Point_Line_Grid','Point_Animatedcube','Primitives_Melencolia'}
checks=[]
def check(name,condition):
 checks.append({'name':name,'passed':bool(condition)})
 assert condition,name
rel=Path('commons/data/museum/em_plan.json')
before=load(HERE/'before'/rel);after=load(ROOT/rel)
outside=lambda doc:[r for r in doc['plans'] if not(r.get('sequence')=='primitives' and r.get('map') in names)]
check('Unrelated museum plan rows preserved',outside(before)==outside(after))
rel=Path('commons/data/artifact_roles.json');before=load(HERE/'before'/rel);after=load(ROOT/rel)
for section in ['roles','order','groups']:
 check('Unrelated '+section+' preserved',{k:v for k,v in before.get(section,{}).items() if k not in ['Point_Trace','Point_Animatedcube']}=={k:v for k,v in after.get(section,{}).items() if k not in ['Point_Trace','Point_Animatedcube']})
rel=Path('commons/data/spine_artifact_order.json');before=load(HERE/'before'/rel);after=load(ROOT/rel)
outside=lambda doc:[r for r in doc['order'] if r.get('map') not in ['Point_Trace','Point_Animatedcube']]
check('Other generated order rows preserved',outside(before)==outside(after))
check('Generated order keeps unique lookup names',len({r['lookup'] for r in after['order']})==len(after['order']))
for name in names:
 d=load(ROOT/'commons/maps'/name/'map_data.json');placed=[c for row in d['layers']['interactables'] for c in row if str(c).strip()]
 check(name+' placement count matches metadata',len(placed)==d['map_info']['metadata']['n_artifacts'])
 check(name+' all grid layers rectangular',all(len(set(map(len,rows)))==1 for rows in d['layers'].values()))
 (HERE/'scope-verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
print(f'{len(checks)} scoped data checks passed.')
