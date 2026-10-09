from pathlib import Path
import json,re,hashlib,subprocess,shutil
R=Path(__file__).resolve().parents[1];REC=R/'doc/space/inside-review-2026-09-13';RUN=R/'ada_run/inside-review-2026-09-13';O=R/'doc/research';NAME='Noise_Inside_Noise'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def save(p,d):p.write_bytes((json.dumps(d,indent=2,ensure_ascii=False)+'\n').encode('utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
run=read(RUN/'run.json');assert run['exit']==0 and run['checks']==42 and not run['failures']
assert run['sources_unchanged'] and run['original_hand_unchanged']
for p,h in run['source_sha256'].items():assert sha(R/p)==h,p
d=read(RUN/NAME/'probe_inside_live.json')['measurements'];assert not d['museum_walk_severed']
assert len(d['pointer'])==4 and all('InteractableAreaButton' in v['hover'] and v['before']!=v['after'] for v in d['pointer'])
assert [x['strength'] for x in d['cases']]==[0,.35,.8,1.4]
assert [x['changed_samples'] for x in d['cases']]==[0,9216,9216,9216]
assert all(x['vertices']==8514 and len(x['probes'])==5 for x in d['cases'])
assert d['relief_max_error']<1e-6
for case in d['cases']:
 for probe in case['probes']:
  assert max(abs(probe['p'][i]+case['strength']*probe['d'][i]-probe['q'][i]) for i in range(2))<1e-6
old=read(REC/f'before/commons/maps/{NAME}/map_data.json');new=read(R/f'commons/maps/{NAME}/map_data.json')
assert len(new['layers']['structure'])==len(old['layers']['structure'])+1==14
for i,row in enumerate(old['layers']['structure']):assert row==new['layers']['structure'][i][:len(row)]
assert old['layers']['utilities']==new['layers']['utilities']
tokens=lambda x:sorted(re.split('[:#]',s)[0] for row in x['layers']['interactables'] for s in row if s.strip())
assert tokens(old)==tokens(new)==['dark_sphere','noisesphere']
final=(R/f'commons/maps/{NAME}/final.md').read_text(encoding='utf-8')
anchors=re.findall(r'^\s*<!-- @([A-Za-z0-9_]+) -->\s*$',final,re.M);assert anchors==['noisesphere','dark_sphere']
roles=read(R/'commons/data/artifact_roles.json');assert roles['order'][NAME]['primary']==anchors
book=next(x for x in read(R/'commons/data/book/noise.json')['pearls'] if x['map']==NAME)
assert [x['token'] for x in book['lines']]==anchors
norm=lambda s:'\n'.join(x.strip() for x in s.strip().splitlines() if x.strip())
source=norm((R/'algorithms/randomness/noisesphere/warp_study.gd').read_text(encoding='utf-8'))
codes=re.findall(r'```gdscript\n(.*?)```',final,re.S)
for code in codes:assert norm(code) in source,code
for p in ['commons/artifacts/dark_sphere/dark_sphere.gd','algorithms/randomness/noisesphere/noisesphere.tscn','commons/resourses/shaders/noisePlanet2.gdshader']:assert sha(R/p)==sha(REC/'before'/p)
trial=next(x for x in read(RUN/'review-plan.json')['plans'] if x.get('map')==NAME)
for path in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 current=read(R/path);row=next(x for x in current['plans'] if x.get('map')==NAME)
 assert row==trial,('accepted geometry differs',path)
 before=read(REC/'before'/path)
 original={x['map']:x for x in before['plans']}
 for x in current['plans']:
  if x['map']==NAME:continue
  a=dict(x);b=dict(original[x['map']])
  if a.get('sequence')=='noise':
   for key in ['pearl_index','pearls_total']:a.pop(key,None);b.pop(key,None)
  assert a==b,('unrelated plan row changed',path,x['map'])
maps=read(R/'commons/data/map_authored.json')['noise'];assert maps[maps.index('Noise_6_Wall')+1]==NAME and 'Noise_Space_10' not in maps
log=(RUN/NAME/'engine.log').read_text(encoding='utf-8');assert 'SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log
for script in ['long_museum.py','museum_necklace.py','build_waves_chance_noise_plan.py','build_inside_review.py']:
 args=['python','-X','utf8',str(R/'tools'/script)]+(['--apply'] if script in ['long_museum.py','museum_necklace.py'] else [])
 p=subprocess.run(args,cwd=R,capture_output=True);(REC/(script+'.log')).write_bytes(p.stdout+p.stderr);assert p.returncode==0,(script,p.stderr)
audit=read(O/'waves-chance-noise/audit.json');own=next(x for x in audit['maps'] if x['map']==NAME);assert own['role_book_match'] and not own['unplaced_primary']
halls=read(R/'commons/data/museum_order_effective.json')['halls'];hall=next(x for x in halls if x['name']==NAME);assert hall['pack']['placed']==2 and hall['pack']['refused']==0
assert halls[halls.index(hall)-1]['name']=='Noise_6_Wall'
shutil.copyfile(R/f'commons/maps/{NAME}/final.md',O/f'waves-chance-noise/texts/{NAME}-final.md')
manifest=['possible-bodies/'+n for n in read(REC/'publication-manifest.json')]
manifest+=['waves-chance-noise/'+n for n in ['index.html','all-maps.md','audit.json','plan.json','HANDOFF.md',f'texts/{NAME}-final.md']]
manifest += [p.relative_to(O).as_posix() for p in sorted((O/'waves-chance-noise/maps').glob('*.md'))]
save(REC/'publish-targets.json',manifest);save(REC/'publish-hashes.json',{n:sha(O/n) for n in manifest})
save(REC/'verification.json',{'run':run,'primary':anchors,'pack':hall['pack'],'source_exact_code_blocks':len(codes),'all_original_structure_cells_and_utilities_preserved':True,'both_authored_works_retained':True,'legacy_scene_shader_and_orb_unchanged':True,'live_rows_match_accepted_row':True,'unrelated_plan_rows_unchanged_except_noise_indices':True,'final_words':len(final.split()),'diagnostics':[l for l in log.splitlines() if l.startswith(('ERROR:','WARNING:'))],'publication_files':len(manifest)})
print(json.dumps({'checks':run['checks'],'primary':anchors,'words':len(final.split()),'files':len(manifest)}))
