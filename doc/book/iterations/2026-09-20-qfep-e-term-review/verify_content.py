from pathlib import Path
import json, hashlib, difflib, re
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; B=HERE/'before'; ROOM='QFEP_E_Term'; INTRO='QFEP_Introduction'
checks=[]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,s):checks.append({'ok':bool(ok),'message':s})
def omit(d,*keys):return {a:b for a,b in d.items() if a not in keys}
def families(d):return {c.split(':')[0].split('#')[0] for row in d['layers']['interactables'] for c in row if c.strip()}

seq=read(ROOT/'commons/maps/sequences/qfeplaboratory.json')['sequences']['qfeplaboratory']
oldseq=read(B/'commons/maps/sequences/qfeplaboratory.json')['sequences']['qfeplaboratory']
for key in ['maps','prerequisites','unlocks','deferred_maps','learning_objectives']:
 check(seq[key]==oldseq[key],key+' unchanged')
check([g for g in seq['artifact_groups'] if g['map']!=ROOM]==[g for g in oldseq['artifact_groups'] if g['map']!=ROOM],'Other hall groups preserved')
for room in seq['maps']:
 rel=Path('commons/maps')/room
 check(families(read(B/rel/'map_data.json'))==families(read(ROOT/rel/'map_data.json')),room+': artifact families retained')
 if room!=ROOM:
  check((B/rel/'map_data.json').read_bytes()==(ROOT/rel/'map_data.json').read_bytes(),room+': map byte-preserved')
  if room!=INTRO:check((B/rel/'final.md').read_bytes()==(ROOT/rel/'final.md').read_bytes(),room+': manuscript byte-preserved')
m=read(ROOT/'commons/maps'/ROOM/'map_data.json')
check(all(len(rows)==14 and all(len(r)==14 for r in rows) for rows in m['layers'].values()),'All layers 14 by 14')
check(len(families(m))==7,'All seven placed works retained')
check(all(m['layers']['structure'][z][6]=='1' for z in range(14)),'Level central floor through hall')
registry=read(ROOT/'commons/artifacts/registry/qfep.json')['artifacts']
check(omit(registry,'entropy_fan')==omit(read(B/'commons/artifacts/registry/qfep.json')['artifacts'],'entropy_fan'),'Other registry entries unchanged')
roles=read(ROOT/'commons/data/artifact_roles.json');oldroles=read(B/'commons/data/artifact_roles.json')
check(roles==oldroles,'Existing primary and secondary roles retained')
check(set(roles['roles'][ROOM])==families(m) and roles['order'][ROOM]['primary']==['entropy_fan'],'Roles and placements agree')
core=read(ROOT/'commons/data/museum_core_encounters.json')['rooms'];oldcore=read(B/'commons/data/museum_core_encounters.json')['rooms']
check(omit(core,ROOM,INTRO)==omit(oldcore,ROOM,INTRO),'Unrelated core encounters preserved')
check(omit(core[INTRO],'text_sha256')==omit(oldcore[INTRO],'text_sha256'),'Introduction core changes only manuscript hash')
for room in [ROOM,INTRO]:
 for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(core[room][k]==sha(ROOT/'commons/maps'/room/n),room+': current '+k)
check(core[ROOM]['learner_verified'] is False,'Learner verification pending')
text=(ROOT/'commons/maps'/ROOM/'final.md').read_text(encoding='utf-8')
check(re.findall(r'<!-- @([\w_]+) -->',text)==['entropy_fan'],'Book anchor agrees with primary')
archive=(ROOT/'commons/maps'/ROOM/'design-proposals.md').read_text(encoding='utf-8')
for n in ['technical.md','critical.md']:check((B/'commons/maps'/ROOM/n).read_text(encoding='utf-8-sig') in archive,'Original '+n+' retained as historical proposal')
for path in ['doc/ENTRY.md','doc/research/qfep/README.md','doc/research/qfep/entropic-morality.md','doc/research/qfep/source-entropic-morality.txt']:
 check((B/path).read_bytes()==(ROOT/path).read_bytes(),'Research source preserved: '+path)
for room in [INTRO,ROOM]:
 p=ROOT/'commons/maps'/room/'final.md';s=p.read_text(encoding='utf-8')
 check('Queer Free Energy Principle' in s,room+': full QFEP name included')
 for dest in re.findall(r'\]\((\.\./[^)]+)\)',s):check((p.parent/dest.split('#')[0]).resolve().is_file(),room+': local reference resolves '+dest)

auth=read(ROOT/'commons/data/map_authored.json');oldauth=read(B/'commons/data/map_authored.json')
check(auth==oldauth,'Authored halls unchanged')
expected=[r for r in seq['maps'] if r!='QFEP_Sandbox']
for p in ['ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 old,now=read(B/p),read(ROOT/p)
 check([r for r in now['plans'] if r.get('map')!=ROOM]==[r for r in old['plans'] if r.get('map')!=ROOM],p+': all other rows retained')
 check([r['map'] for r in now['plans'] if r.get('sequence')=='qfeplaboratory']==expected,p+': seven authored halls in declared order')
 row=next(r for r in now['plans'] if r.get('map')==ROOM)
 check({a['token'] for a in row['artifacts']}==families(m),p+': all seven works in plan')
 a=next(a for a in row['artifacts'] if a['token']=='entropy_fan')
 check(a['config']=={'visitor_control':'on'} and a['rotation']==180,p+': visitor control enabled facing entrance')
check(read(ROOT/'ada_run/em_plan.json')==read(ROOT/'commons/data/museum/em_plan.json'),'Live/shipped plan files agree')
book=read(ROOT/'commons/data/book/qfeplaboratory.json')['pearls'];oldbook=read(B/'commons/data/book/qfeplaboratory.json')['pearls']
check([p for p in book if p['map']!=ROOM]==[p for p in oldbook if p['map']!=ROOM],'Other book pearls retained')
b=next(p for p in book if p['map']==ROOM)
for path in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 old,now=read(B/path),read(ROOT/path)
 check([n for n in old['trunk'] if n['node']!='qfeplaboratory']==[n for n in now['trunk'] if n['node']!='qfeplaboratory'],path+': unrelated chapters unchanged')
 o,n=[next(v for v in d['trunk'] if v['node']=='qfeplaboratory') for d in [old,now]]
 check([p for p in n['pearls'] if p['map']!=ROOM]==[p for p in o['pearls'] if p['map']!=ROOM],path+': other hall speech unchanged')
 p=next(p for p in n['pearls'] if p['map']==ROOM)
 check(p['hero']==b['hero']=='entropy_fan' and p['says']=={ln['token']:ln['text'] for ln in b['lines']},path+': hero and speech aligned')
r=read(HERE/(ROOM+'-runtime.json'))
check(r['passed'] and not r['failures'],'Godot museum probe passes')
check(len(r['checks'])==31 and all(c['ok'] for c in r['checks']),'31 interaction/reach checks pass')
check(len(r['walks'])==5 and all(w['passed'] for w in r['walks']),'Five selected walking routes pass')
check(len(r['shots'])==5 and all((HERE/Path(p).name).is_file() for p in r['shots']),'Five real Godot images retained')
a,b,c,d=[s['reading'] for s in r['captured_states'][:4]]
check(a['leaves']==1 and b['leaves']==81 and c['leaves']==27 and c['closures']==18 and c['removed_leaves']==54,'Captured states agree with chapter')
check(b==d,'Reopening restores exactly the original reading')
check('SCRIPT ERROR:' not in (HERE/(ROOM+'-engine.log')).read_text(encoding='utf-8',errors='replace'),'No script errors in final run; secondary formatting errors recorded separately')
for room in [ROOM,INTRO]:
 for name in (['final.md','technical.md','critical.md'] if room==ROOM else ['final.md']):
  rel=Path('commons/maps')/room/name
  target=(name.replace('.md','') if room==ROOM else 'introduction-final')+'.diff'
  (HERE/target).write_text(''.join(difflib.unified_diff((B/rel).read_text(encoding='utf-8-sig').splitlines(True),(ROOT/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile=rel.as_posix())),encoding='utf-8')
(HERE/'current-inputs.json').write_text(json.dumps({f.relative_to(B).as_posix():{'before':sha(f),'current':sha(ROOT/f.relative_to(B))} for f in B.rglob('*') if f.is_file() and (ROOT/f.relative_to(B)).is_file()},indent=2)+'\n',encoding='utf-8')
failed=[c['message'] for c in checks if not c['ok']]
(HERE/'content-checks.json').write_text(json.dumps({'count':len(checks),'checks':checks,'passed':not failed,'failures':failed},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':failed}));raise SystemExit(bool(failed))
