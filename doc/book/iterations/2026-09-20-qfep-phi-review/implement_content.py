from pathlib import Path
import json,difflib,hashlib
R=Path.cwd();H=R/'doc/book/iterations/2026-09-20-qfep-phi-review';B=H/'before';M='QFEP_Phi_Term';D=R/'commons/maps'/M
read=lambda p:json.loads((R/p).read_text(encoding='utf-8-sig'))
def write(p,d):(R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def md(n,t):(D/n).write_text(t,encoding='utf-8')
m=read(f'commons/maps/{M}/map_data.json');info=m['map_info'];info.update(name='Giving change a sign',title='Sign, magnitude and interpretation',description='Compare negative, zero and positive feedback; reveal the earlier labels and ask what they decide. Nearby forms keep their own dynamics.')
info['metadata']['learning_objectives']=['Distinguish sign from magnitude by crossing zero','Compare the same magnitude with opposite signs','Distinguish a parameter, a measured change and an interpretation','Notice that neighbouring artifacts need not be causally connected']
info['museum'].update(artifact_placement='map',sculpture_clear_rects=[[1,0,11,12]])
m['utility_definitions']['t']['description']='Next: compare a pattern with the controls actually driving it.'
m['documentation'].update(summary='Giving change a sign',layout='Central reachable rail; static and moving comparisons behind it; level approaches around display plinths.',objective='Try the signed control before revealing the earlier resist/embrace interpretation.',key_elements=['phi_slider: negative / zero / positive, then optional earlier labels','transforming_pattern: waves independent of PHI','Retained static and moving comparisons; no automated moral classification'])
a=[['' for x in range(13)] for z in range(12)];u=[row[:] for row in a];s=[['w' if x in (0,12) or z in (0,11) else '1' for x in range(13)] for z in range(12)]
for z in (0,11):
 for x in (5,6,7):s[z][x]='1'
placements={(3,3):'rigid_sculpture:0:0.05:1',(9,3):'fluid_form:0:0.05:1',(6,4):'phi_slider:180:1.1:1#sign_study:on#phi:0',(3,7):'preserved_pattern:0:0.05:2.5',(8,7):'transforming_pattern:0:0.05:1#cell_size:0.15',(6,9):'lambda_promenade:0:0',(3,9):'tt:90:phi_conservative:180:0.5',(9,9):'tt:90:phi_queer:180:0.5'}
for (x,z),v in placements.items():a[z][x]=v
for x,z in [(3,3),(9,3),(3,7),(8,7)]:s[z][x]='2'
u[1][6]='s';u[2][4]='sub:map';u[10][6]='t'
m['layers']=dict(structure=s,utilities=u,interactables=a);write(f'commons/maps/{M}/map_data.json',m)
t=(B/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
t=t.replace('one side sends particles down, the other sends them up.','one side sends particles down, the other sends them up. At zero, no new particles are released; those already in flight take a moment to disappear. The pattern behind the rail keeps moving.')
t=t.replace('The slider’s particles make the sign easy to recognise.', 'After trying both sides, press EARLIER LABELS. RESIST and EMBRACE appear above the same rail. Nothing else has changed. Does the upward movement feel different once it has been called an embrace? You can hide the words again, although you may still carry them into the next movement of your hand.\n\nThe slider’s particles make the sign easy to recognise.')
t=t.replace('a causal experiment connecting them remains to be built.','their independence is part of this comparison. Bringing them under one control would be another experiment, with another rule to explain.')
t=t.replace('The sign of a project parameter cannot decide which history deserves continuity.','The sign of a project parameter cannot decide which history deserves continuity. Before that judgement, someone has to decide what counts as change and whether the resulting score is something to raise or lower.')
t=t.replace('\n<!-- @ -->\n','\n');md('final.md',t)
archive='# Earlier Phi proposals — historical drafts\n\nPreserved 20 September 2026. These drafts imagine restoration, mutation and a slider connected to every nearby work. The implementation does not do that. Keep these as proposals to revisit, not descriptions of the current hall. The political readings require their own research; a positive coefficient does not by itself favour increasing entropy under minimization.\n'
for n in ['technical.md','critical.md']:archive+='\n---\n\n## Preserved '+n+'\n\n'+(B/'commons/maps'/M/n).read_text(encoding='utf-8')
md('design-proposals.md',archive)
md('technical.md','''# A signed control before its interpretation

The Lambda hall separated a recommendation from its surroundings. Here the PHI rail separates sign, magnitude and the language used to interpret them. The museum uses the existing phi_slider with sign_study:on and starts at zero. Its original XR handle remains full size on a plinth, 1.1 metres above the floor.

The hall-specific feedback uses equal speeds at equal magnitudes, opposite vertical directions and no particle gravity. Zero stops new emission; already emitted particles may survive for their two-second lifetime. The original legacy feedback favoured upward motion and continued emitting at zero. Other placements retain that legacy behaviour.

```gdscript
phi = (position / rail_length) * 2.0 - 1.0
particle_mat.direction = Vector3.UP * signf(phi)
particle_mat.initial_velocity_min = absf(phi) * 0.20
particle_mat.initial_velocity_max = absf(phi) * 0.20
_particles.emitting = not is_zero_approx(phi)
```

NEGATIVE / ZERO / POSITIVE remain on an evenly marked rail. EARLIER LABELS / HIDE reveals or hides the old RESIST / EMBRACE interpretation on a backed sign. That button changes text only: it does not move PHI, alter the wave pattern, or choose a moral classification. Blue and pink, upward and downward remain authored choices, available to question.

The sign study does not join the global qfep_phi_controllers group. The transforming_pattern runs independently from its prescribed wave field; its 6 by 6 cells are enlarged to 0.15 metres for comparison. The preserved pattern, rigid sculpture, fluid form, lambda promenade and two existing secondary teleporter tokens remain placed. The map uses its authored placements, with four display plinths and level circulation.

The QFEP expression in the project documents is QFE = F - lambda E + phi Delta E. A signed weight is not a measurement of change. For Delta E=+0.5, phi=+1 adds +0.5 to the score, while phi=-1 adds -0.5. If the score is minimized, the first increases cost with F and E held fixed. Reversing Delta E reverses those contributions. Zero phi makes this contribution zero, not the world's change zero. This rail does not measure entropy or run an optimizer.

Delta E names a difference between specified observations. It becomes a rate only after division by the elapsed interval. An entropy claim also needs defined states, probabilities, units and normalization. The wave field supplies none of those through its animation alone.

The earlier technical and critical drafts are archived in design-proposals.md. They describe intended connections, not shipped behaviours. Headset operation and what readers learn remain distinct from the recorded desktop signal and route checks.
''')
md('critical.md','''# A word arrives after the movement

The particles have already gone up. Then a word arrives: embrace.

The button changes the inscription while leaving the movement alone. We can ask whether it also changes our account of what happened. Hiding the word gives us the earlier display again; it cannot promise the earlier reading.

The unlabelled experience was already shaped. A rail offers two directions. One rises, one falls. Colours distinguish them. A body brings associations to all of this. The first display is a place from which to examine these choices, rather than an escape from interpretation.

Behind the rail the pattern keeps moving. At zero it still moves. A system's refusal to give change weight does not stop that change from occurring elsewhere. Nor does our ability to move a control establish authority over every object that shares its theme.

A pattern worth protecting can need resistance to imposed change. A damaging arrangement can survive by demanding continuity. The word alone cannot choose between them. In the QFEP documents, keeping models revisable includes keeping open the capacities of those their terms exclude. The question reaches the person setting the terms: what have we already made easier to call an embrace?

This encounter makes the older judgement available to examine. It does not measure the ethics of the visitor or assign a queer identity to a parameter setting.

Project framing: [QFEP development notes](../../../doc/research/qfep/README.md), [entropic morality](../../../doc/research/qfep/entropic-morality.md) and the Self-Q section of [ENTRY](../../../doc/ENTRY.md).
''')
md('summary.md','''# Phi — giving change a sign

Fifth declared QFEP Laboratory hall. Compare equal distances on opposite sides of zero on a reachable PHI rail. Its particles reverse direction at equal speed; zero stops new emission. Reveal and hide the earlier RESIST / EMBRACE labels without changing the movement.

The enlarged transforming pattern remains an independent primary comparison. Watch it continue at zero. All eight map placements are retained. Six works instantiate in the museum; the two legacy teleporter tokens are suppressed by its continuous-hall rules. None of the comparisons is wired to the study rail. The 13 by 12 gallery has four display plinths, an entrance and an exit with level circulation.

The chapter preserves its existing sign/magnitude argument and adds the delayed label encounter. This is a test of a parameter and its interpretation, not a measurement of entropy, life, or queer identity. Next: a pattern with controls actually connected to its evolution.
''')
md('blurb.md','''*The movement came first. Then someone called it an embrace.*

Cross zero. Let the particles settle. The nearby pattern keeps moving.

Reveal the earlier labels, and try the same gesture again.
''')
p='commons/data/museum_core_encounters.json';d=read(p);r=d['rooms'][M];r.update(reason='Compare sign and magnitude before revealing an interpretation; the neighbouring pattern keeps its independent rhythm.',status='encounter_and_text_revised',review_evidence=H.relative_to(R).as_posix()+'/SUMMARY.md',learner_verified=False)
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[k]=hashlib.sha256((D/n).read_bytes()).hexdigest()
write(p,d)
lines={'phi_slider':'The movement came first. Then someone called it an embrace.','transforming_pattern':'At zero, I keep moving.'}
p='commons/data/book/qfeplaboratory.json';d=read(p);e=next(x for x in d['pearls'] if x['map']==M);e.update(hero='phi_slider',lines=[{'token':k,'text':v,'by':'hand'} for k,v in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 for e in node['pearls']+d.get('hand_pearls',{}).get('qfeplaboratory',[]):
  if e.get('map')==M:e.update(hero='phi_slider',says=lines,says_by={k:'hand' for k in lines})
 write(p,d)
p='commons/maps/sequences/qfeplaboratory.json';d=read(p);s=d['sequences']['qfeplaboratory'];s['content'][4]='QFEP_Phi_Term: Giving change a sign';g=next(g for g in s['artifact_groups'] if g['map']==M);g['rationale']='Two primary encounters: a signed rail with a delayed interpretation and an independently moving pattern. Retain the supporting comparisons.';write(p,d)
p='commons/artifacts/registry/qfep.json';d=read(p);e=d['artifacts']['phi_slider'];e['description']='Signed PHI controller with local particle feedback. Optional sign_study gives equal-speed opposite directions, zero emission at zero, and delayed earlier labels on a plinth; the study remains outside the global controller group.';e.setdefault('parameters',{})['sign_study']='on/off, default off: local sign encounter with optional earlier interpretation';write(p,d)
for n in ['final.md','technical.md','critical.md']:
 old=(B/'commons/maps'/M/n).read_text(encoding='utf-8');new=(D/n).read_text(encoding='utf-8');(H/(n.removesuffix('.md')+'.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+n,tofile='after/'+n)),encoding='utf-8')
print('Phi map, manuscript, supporting notes and speech aligned')
