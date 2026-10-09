from pathlib import Path
import hashlib, json
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; ROOM='Florensky_Paraconsistent'
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

p='commons/artifacts/registry/foundations.json'; d=read(p)
a=d['artifacts']['florensky_sphere']
a['description']='Florensky-inspired visual antinomy. In hold_both mode, the double-sided sphere holds the label A AND not-A while its colours change; observation and cycling cannot collapse it. It illustrates two readings, not a formal logic.'
a['qfep_connection']='Ask how an unresolved account can remain open to investigation. Rendering two faces does not establish a true contradiction or a QFEP theorem.'
a['interactions']=['Florensky hall: circle the sphere and wait; both readings remain. Legacy desktop observation/cycling remains available when hold_both is off.']
a['parameters']['hold_both']='Opt-in sustained BOTH reading; on in Florensky_Paraconsistent. Disables observation and state cycling without altering seam geometry.'
a=d['artifacts']['schrodinger_box']
a['description']='A labelled visual toy: desktop click chooses a random ALIVE/DEAD outcome, opens the lid, then resets after a timer. It is not a quantum simulation; tracked-hand opening remains unimplemented.'
a['qfep_connection']='Compare a scripted revelation with the sphere that holds two readings. Quantum superposition and logical contradiction are different questions.'
a['interactions']=['Desktop click selects a random outcome and opens the lid; timer resets. No tracked-hand opening is implemented.']
write(p,d)
p='commons/artifacts/registry/foundations_crisis.json'; d=read(p)
a=d['artifacts']['both_true_gate']
a['description']='Optional body-sized report study: P: OPEN, not-P: CLOSED and CLEAR buttons control two ghost leaves independently. Q: alarm triggered remains NO SUPPORT. The frame has collision; the leaves do not. The default small animated illustration remains available elsewhere.'
a['qfep_connection']='A finite store of conflicting reports invites investigation of non-explosion and of the separate decision that permits a body to pass. It does not implement a complete logic or prove that both reports are true.'
a.setdefault('parameters',{})['report_controls']='Opt-in 1.716 m by 2.392 m opening and reachable report console; on in Florensky_Paraconsistent.'
a['interactions']=['Press OPEN or CLOSED to toggle each report; CLEAR removes both. Walk through the ghost leaves regardless of report state.']
write(p,d)
p='commons/artifacts/registry/quantumalgorithms.json'; d=read(p)
a=d['artifacts']['superposition_display']
a['description']='Visual toy with two basis-state forms whose opacities cycle and a slider that changes their pace. Opacity is not a quantum amplitude. The display has no measurement or collapse operation.'
a['qfep_connection']='The shared visual language invites a comparison, not an identification, of quantum superposition and logical contradiction.'
a['interactions']=['Move the slider to change the pace of the opacity animation; no measurement control is present.']
write(p,d)

primary=['both_true_gate','florensky_sphere']; secondary=['schrodinger_box','superposition_display']
p='commons/data/artifact_roles.json'; d=read(p)
d['roles'][ROOM]={**{t:'primary' for t in primary},**{t:'secondary' for t in secondary}}
d['order'][ROOM]={'primary':primary,'secondary':secondary,'decoration':[]}; write(p,d)
p='commons/data/museum_core_encounters.json'; d=read(p); r=d['rooms'][ROOM]
r.update(primary_tokens=primary,reason='Change independent conflicting reports at a walkable threshold, then keep both readings on the sphere. Retain both quantum visual toys as distinct comparisons; neither implements logical contradiction.',status='encounter_and_text_revised',learner_verified=False,review_evidence=HERE.relative_to(ROOT).as_posix()+'/SUMMARY.md')
for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]: r[key]=hashlib.sha256((ROOT/'commons/maps'/ROOM/f).read_bytes()).hexdigest()
write(p,d)
lines={
 'both_true_gate':'Two reports disagree. What follows? Who still gets through?',
 'florensky_sphere':'Circle it. Wait. The colour shifts; both readings remain.',
 'schrodinger_box':'A scripted toy chooses an outcome. What can its closed lid tell you?',
 'superposition_display':'The forms keep fading. There is no measurement here. What does the image leave out?'}
p='commons/data/book/foundationscrisis.json'; d=read(p); pearl=next(p for p in d['pearls'] if p['map']==ROOM)
pearl.update(hero='both_true_gate',lines=[{'token':t,'text':s,'by':'hand'} for t,s in lines.items()]); write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p); node=next(n for n in d['trunk'] if n['node']=='foundationscrisis')
 for pearl in node['pearls']+d.get('hand_pearls',{}).get('foundationscrisis',[]):
  if pearl.get('map')==ROOM: pearl.update(hero='both_true_gate',says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
