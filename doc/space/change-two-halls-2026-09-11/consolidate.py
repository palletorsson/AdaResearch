from pathlib import Path
import json, shutil, sys, hashlib, csv
ROOT=Path.cwd(); OUT=ROOT/'doc/space/change-two-halls-2026-09-11'
names=['Change_Intro','Accumulation_Riemann','Flow_Field','Change_Reconciliation']+[f'Ribbon_Change_{i:02d}' for i in range(1,5)]
keep=['Change_Intro','Flow_Field']; retired=[n for n in names if n not in keep]
def read(p): return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def backup(p):
 p=ROOT/p; q=OUT/'before'/p.relative_to(ROOT)
 if p.exists() and not q.exists():q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
def save(p,d):
 backup(p);Path(p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
for n in names:
 for p in (ROOT/'commons/maps'/n).iterdir():
  if p.is_file():backup(p)
raws={}; provenance=[]
for n in names:
 d=read(OUT/'before/commons/maps'/n/'map_data.json')
 for z,row in enumerate(d['layers']['interactables']):
  for x,v in enumerate(row):
   if not v.strip():continue
   token=v.split('#')[0].split(':')[0];raws.setdefault(token,v);provenance.append({'map':n,'cell':[x,z],'token':token,'raw':v})
plans={
 'Change_Intro':(27,35,{
 'tangent_slope_workbench':(6,5,90,0,1),'riemann_sum_workbench':(20,5,270,0,1),'ftc_bridge':(6,12,0,0,1),
 'derivative_pair':(20,12,0,0,1),'integral_area':(18,17,0,0,1),'riemann_pump':(23,17,0,0,1),
 'gradient_descent_well':(6,19,0,0,1),'paper_regatta':(20,21,0,0,1),'partial_derivative_terrain':(6,25,0,0,1),
 'descent_marble_toy':(20,27,0,0,1),'riemann_pi':(2,29,0,0,.18),'zeno_staircase':(10,29,0,0,1),
 'velocity_arrow':(23,10,0,0,1),'slope_tangent_demo':(23,24,0,0,1),'code_display':(9,20,0,0,1),
 'science_screen':(18,30,0,0,1),'synthesis_stand':(20,32,0,0,1)}),
 'Flow_Field':(19,23,{'flow_field_painter':(5,5,0,1.05,2.5),'vector_field_visualizer':(13,5,0,.8,1),
 'vector_field_grid':(5,11,0,.8,1),'particle_flow_swarm':(13,11,0,.8,1),
 'noc_5_04_flow_field':(5,17,0,.8,1),'grand_zoetrope':(13,17,0,0,1)})}
assert set(raws)=={t for _,_,ps in plans.values() for t in ps}
primary={'Change_Intro':['tangent_slope_workbench','riemann_sum_workbench','ftc_bridge'],'Flow_Field':['flow_field_painter']}
titles={'Change_Intro':'Change and accumulation','Flow_Field':'Flow and trajectories'}
destinations={}
for n,(w,h,ps) in plans.items():
 layers={k:[['' for x in range(w)] for z in range(h)] for k in ['structure','utilities','interactables']}
 for z in range(h):
  for x in range(w):layers['structure'][z][x]='4' if x in [0,w-1] or z in [0,h-1] else '1'
 for z in [0,h-1]:
  for x in range(w//2-1,w//2+2):layers['structure'][z][x]='1'
 for z in ([15,23] if n=='Change_Intro' else [9,15]):
  for x in [1,2,w-3,w-2]:layers['structure'][z][x]='4'
 layers['utilities'][2][w//2]='s';layers['utilities'][h-3][w//2]='t'
 for t,(x,z,rot,y,scale) in ps.items():
  cfg={a.split(':',1)[0]:a for a in raws[t].split('#')[1:]};cfg.update(pin='pin:1',plinth='plinth:0')
  if t=='flow_field_painter':cfg['lesson']='lesson:shared_field'
  if t=='ftc_bridge':cfg['evidence']='evidence:longhand'
  raw=f'{t}:{rot}:{y}:{scale}'+''.join('#'+v for v in cfg.values());layers['interactables'][z][x]=raw
  destinations[t]={'map':n,'cell':[x,z],'placement':raw}
 d={'map_info':{'name':n,'lookup_name':n,'title':titles[n],'version':'1.0','format':'json','dimensions':{'width':w,'depth':h,'max_height':4},'museum':{'sculpture_clear_rects':[[w//2-2,0,w//2+2,h-1]],'wall_height':4,'open_roof':True,'gate':False,'plinths':False,'passage':{'kind':'straight','width':3,'offset':0}},'metadata':{'sequence':'change','n_artifacts':len(ps),'source':'2026-09-11 two-hall consolidation','source_maps':names,'layout':'Framed gallery bays and a three-metre central route.'}},'layers':layers}
 save(f'commons/maps/{n}/map_data.json',d)
for n in retired:
 p=f'commons/maps/{n}/map_data.json';d=read(p);d['map_info'].setdefault('metadata',{})['consolidated_into']='Change_Intro' if n in ['Accumulation_Riemann','Change_Reconciliation','Ribbon_Change_01'] else 'Flow_Field';save(p,d)
 save(f'commons/maps/{n}/consolidation.json',{'active':False,'date':'2026-09-11','destinations':{v['token']:destinations[v['token']] for v in provenance if v['map']==n},'note':'Original room retained for historical comparison; no longer in the active Change sequence.'})
p='commons/maps/sequences/change.json';d=read(p);s=d['sequences']['change'];s['maps']=keep
s['content']=[n+': '+titles[n] for n in keep];s['artifact_groups']=[{'map':n,'artifacts':primary[n],'position':'intro' if i==0 else 'synthesis','rationale':titles[n]} for i,n in enumerate(keep)]
s['deferred_maps']=list(dict.fromkeys(s.get('deferred_maps',[])+retired));s['deferred_reason']='2026-09-11: eight active halls become two; all 23 distinct artifacts retained once. Three rate/accumulation/reconciliation encounters precede flow.'
s['taxonomy']={'1_measure_and_accumulate':'Change_Intro: finite difference, Riemann sum, signed net change.','2_follow_a_field':'Flow_Field: sample local direction, update position, inspect the retained path.'}
s['_status']='two halls; desktop verification in progress';s['prerequisites']=['tiling'];s['unlock_requirements']=['tiling']
s['formula']="rate = rise / h; total += f(x) * width; position += direction(position, time) * speed * delta"
s['consolidation_ledger']='doc/space/change-two-halls-2026-09-11/ledger.json';save(p,d)
p='commons/maps/sequences/placed_museums.json';d=read(p)
for s in d['sequences'].values():
 s['maps']=[n for n in s.get('maps',[]) if n not in retired]
 if 'content' in s:s['content']=[v for v in s['content'] if str(v).split(':')[0] not in retired]
save(p,d)
p='commons/data/map_authored.json';d=read(p);d['change']=keep;d.get('_placed_added',{}).pop('change',None);save(p,d)
p='commons/data/artifact_roles.json';d=read(p)
for key in ['roles','order','groups']:
 for n in retired:d.get(key,{}).pop(n,None)
for n,(_,_,ps) in plans.items():
 d['roles'][n]={t:'primary' if t in primary[n] else 'secondary' for t in ps};d['order'][n]={'primary':primary[n],'secondary':[t for t in ps if t not in primary[n]],'decoration':[]};d['groups'][n]=[]
save(p,d)
p='commons/data/museum_core_encounters.json';d=read(p)
for n in retired:d['rooms'].pop(n,None)
for n in keep:d['rooms'][n]={'sequence':'change','primary_tokens':primary[n],'status':'desktop_verification_pending','learner_verified':False,'reason':titles[n],'map_sha256':hashlib.sha256(Path(f'commons/maps/{n}/map_data.json').read_bytes()).hexdigest()}
save(p,d)
p='commons/data/book/change.json';d=read(p);d['pearls']=[{'map':n,'pearl':n.replace('_',' ').lower(),'title':titles[n],'hero':primary[n][0],'join':True,'lines':[{'token':t,'text':t.replace('_',' '),'by':'astra'} for t in primary[n]]} for n in keep];save(p,d)
sys.path.insert(0,str(ROOT/'tools'));from em_map_halls import derive_row
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 d=read(p);old=next(r for r in d['plans'] if r.get('sequence')=='change');d['plans']=[r for r in d['plans'] if r.get('sequence')!='change']+[derive_row(n.replace('_',' ').lower(),n,old['museum'],i,2,'change') for i,n in enumerate(keep)];save(p,d)
p='doc/research/possible-bodies/curation.tsv';backup(p);rows=list(csv.DictReader(Path(p).read_text(encoding='utf-8').splitlines(),delimiter='\t'));rows=[r for r in rows if r['map'] not in retired]
for r in rows:
 if r['map']=='Change_Intro':r.update(leads=','.join(primary['Change_Intro']),question='What is retained when we measure, add and recover a change?',next='Continue through the three bays, then enter Flow_Field.',proof='Compare finite differences, held Riemann sums and the bridge endpoint difference.',carry='Sampling and signed accumulation retain different accounts of one function.')
 if r['map']=='Flow_Field':r.update(next='Inspect the shared field arrows and particles before moving to Forces.',proof='Freeze field evolution; compare one sampled direction with one particle update.',carry='A direction field prescribes movement; a force model updates velocity through acceleration.')
with Path(p).open('w',encoding='utf-8',newline='') as f:w=csv.DictWriter(f,fieldnames=rows[0].keys(),delimiter='\t',lineterminator='\n');w.writeheader();w.writerows(rows)
save(OUT/'ledger.json',{'before_halls':names,'after_halls':keep,'before_placements':len(provenance),'after_placements':len(destinations),'distinct_preserved':len(destinations),'destinations':destinations,'sources':provenance,'retired_halls_preserved_on_disk':retired})
print('Consolidated 38 placements into 23 unique artifacts in two halls.')
