from pathlib import Path
import json,hashlib,difflib
R=Path.cwd();H=R/'doc/book/iterations/2026-09-20-qfep-edge-review';B=H/'before';M='QFEP_Edge_Of_Chaos';D=R/'commons/maps'/M
read=lambda p:json.loads((R/p).read_text(encoding='utf-8-sig'))
def write(p,d):(R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def md(n,t):(D/n).write_text(t,encoding='utf-8')
p=f'commons/maps/{M}/map_data.json';m=read(p);info=m['map_info'];info.update(name='A pattern and the way we drive it',title='Same start, same time',description='Compare the same reaction-diffusion field with two numerical timesteps; follow a feature before naming a regime.')
info['metadata']['learning_objectives']=['Separate an authored parameter path from a measured regime','Compare two timesteps at equal elapsed model time','Distinguish repeating a start from choosing a new seed','Ask which visible features persist across numerical resolution']
m['utility_definitions']['t']['description']='Next: find out which objects receive each control.'
m['documentation'].update(summary='A pattern and the way we drive it',layout='Central terraced work retained; level east bay for a paired numerical study.',objective='Follow a feature across two calculations of the same starting field before calling a regime stable or chaotic.',key_elements=['Two fields with the same seed, parameters and model duration','Reachable LAMBDA and SIM SPEED rails','RESTART, NEW SEED, DT .3 / .15 and HOLD / RUN','Existing secondary comparisons retained; their controls are independent'])
m['layers']['utilities'][2][2]='';m['layers']['utilities'][1][7]='s';write(p,m)
t=(B/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
t=t.replace('Use RESEED to compare a fresh start at the same setting. Describe what persists, spreads or disappears without relying on the regime name supplied by the display.', 'Use RESTART to repeat the same start, or NEW SEED to choose another. Describe what persists, spreads or disappears before giving the whole picture a name.')
t=t.replace('Initial conditions matter too. Reseeding changes the starting concentrations while leaving the chosen parameter setting available for comparison. A pattern that survives one start may not appear in the same way from another. Keep a record in words: what feature are you comparing, and over how much observed time?', 'Initial conditions matter too. NEW SEED changes the starting concentrations while leaving the chosen parameter setting available for comparison. RESTART returns that numbered seed to its beginning. A pattern that survives one start may not appear in the same way from another. Keep a record in words: what feature are you comparing, and over how much observed time?')
a=t.index('The present numerical update');b=t.index('The hall’s recommended middle',a)
t=t[:a]+'''There are two images in front of you. They begin with the same concentrations and reach the same model time, but the right-hand calculation takes twice as many smaller steps. Follow the boundary you chose in both. Does it still turn in the same place? Press HOLD / RUN when there is something you want to look at for longer.

DT .3 / .15 starts the comparison again with a different step size. The smaller number gives the calculation more occasions to respond along the way. SIM SPEED instead changes how quickly the model clock advances while you stand here. Those are different ways of changing time. Making the picture run faster does not make its calculation more precise.

The small difference reading compares the two B concentration fields cell by cell. A low value means these calculations are close in that particular respect. It does not tell you whether the pattern is alive, beautiful or worth keeping. Look back at your boundary. Does the number register what you were watching?

The earlier calculation could produce a pattern largely through overshooting and clipping its values. That was still something code had made. It answered a different question from the one the display claimed to ask. Repairing the calculation gives us another way to investigate the image; it does not make the image explain itself.

'''+t[b:]
t=t.replace('As the next development, compare the same starting field under a smaller, controlled timestep while keeping the physical duration comparable. Agreement would give more confidence that the visible difference belongs to the model.', 'Repeat the comparison at another LAMBDA setting, or from another seed. Agreement across smaller steps gives us a reason to trust a feature more. Disagreement gives us somewhere to look. The question remains open long enough to become an experiment.')
t=t.replace('\n<!-- @ -->\n','\n');md('final.md',t)
archive='# Earlier Edge of Chaos proposals — historical drafts\n\nPreserved 20 September 2026. These drafts present a privileged lambda interval as established life/criticality and describe a locked secondary rail that does not implement its locked token. They remain theoretical and spatial proposals to assess, not evidence from the numerical experiment. The current chapter asks what a specific solver and defined comparison can show.\n'
for n in ['technical.md','critical.md']:archive+='\n---\n\n## Preserved '+n+'\n\n'+(B/'commons/maps'/M/n).read_text(encoding='utf-8')
md('design-proposals.md',archive)
md('technical.md','''# Two timesteps, one model duration

Phi separated a weight from both measured change and interpretation. This hall puts a parameter in contact with a specific Gray-Scott update. LAMBDA remains one authored route: feed 0.01–0.08, removal 0.08–0.03, diffusion A 0.8–1.2 and diffusion B 0.3–0.7. Varying it changes all four together.

Every tenure now uses the same periodic four-neighbour operator: neighbour average minus centre. The previous interactive solver used neighbour sum minus four times centre at dt=1; only the two endpoint presets used the normalized operator. Normalization divides the spatial diffusion operator by four. This changes effective diffusion relative to the old interactive model; it is not simply a smaller timestep. The current comparison keeps this normalized model identical on both screens.

```gdscript
var reaction := av * bv * bv
na[idx] = av + (_diffusion_a * lap_a - reaction + _feed_rate * (1.0-av)) * dt
nb[idx] = bv + (_diffusion_b * lap_b + reaction - (_kill_rate+_feed_rate)*bv) * dt
```

For pure diffusion, the normalized operator's most negative eigenvalue is -2; explicit Euler needs D*dt <= 1. Our largest diffusion coefficient times the coarser timestep is 1.2*0.3=0.36. That bound alone is not a proof of stability for nonlinear reaction terms. The recorded numerical checks also examine finite, nonnegative concentrations and a selected timestep-refinement comparison. No claim of universal convergence or physical criticality follows.

The fields are not clipped to [0,1]. B can exceed one transiently with the existing seed; imposing the palette range on the simulated concentrations would change the update. An invalid negative/nonfinite value stops calculation and reports a solver fault. The display palette saturates separately. The paired display uses dt=0.3 with dt=0.15, or dt=0.15 with dt=0.075. One coarse tick and two fine ticks advance both by exactly the same model duration, under the same current coefficients.

RESTART reproduces the numbered seed and resets both clocks. NEW SEED increments it and restarts both. DT .3 / .15 switches the pair and restarts the same seed. HOLD / RUN pauses both fields and their clock. LAMBDA changes their common coefficients; use RESTART after selecting it for a comparison of fixed settings. The readout's B difference is the root mean square of cellwise differences, not entropy or a quality score.

SIM SPEED now requests 3–24 model-time units per visitor second, independently of rendered frame count. Work is limited to four coarse ticks per frame. Under load model time can fall behind the requested rate; the readout reports only time actually integrated. This prevents catch-up work from growing without bound. Quest performance remains unmeasured. Display rate changes texture refresh cadence only.

The pair is enabled through comparison_study:on in this hall. Other placements retain their single display and tenure geometry, but receive the common solver, elapsed-time scheduling and separate RESTART / NEW SEED controls. Legacy regime words become LAMBDA LOW / MID / HIGH, explicitly ranges of the knob, not measured dynamics. Historical tenure names frozen/chaos remain configuration vocabulary. Endpoint presets still preroll 192 model-time units.

The map keeps its central terraces and all six placement families. A level east bay gives the paired study a clear approach; controls occupy two compact rows facing into the hall. The other lambda_slider is still an independent secondary. Its legacy locked token is ignored by that script; this pass makes no claim that it is fixed or drives the solver. The continuous museum suppresses its legacy teleporter, and retains five instantiated works. These secondary links belong to the Sandbox investigation rather than an inferred connection here.

Numerical probe: check_solver.gd and solver-checks.json in the dated review folder. Museum probe: check_hall.py. Neither replaces headset testing or a learner's account of what changed.
''')
md('critical.md','''# A pattern can belong to the calculation

The calculation had made something vivid. It had also made it difficult to tell whether the chosen parameters mattered: different settings could run into the same limits and return a similar image.

There is a temptation to call that image chaos because it refuses the regularity we expected. But the label would conceal a more specific event. A numerical decision had overwhelmed the differences the visitor was trying to explore.

The paired study gives that decision a visible consequence. Two images receive the same start and the same time. Their different steps can leave a difference between them. The comparison asks the visitor to choose a feature and keep looking; the number on the console cannot choose what deserves attention.

Repair does not exhaust the artistic question. An unstable calculation can still produce a form we desire. We can return to it as a study of instability, saturation or the image of complexity. What we cannot honestly do is use that pleasure as evidence for a privileged biological or political regime.

In the project's QFEP framing, revisability includes the criteria by which an outcome is recognised. Here even closeness has a chosen definition: the square root of averaged squared concentration differences. A boundary important to a body might occupy very few cells. We need to keep both the measurement and the encounter available to question.

The next room extends this attention to the reach of a control. Before a hand can revise a system, something has to receive its gesture.
''')
md('summary.md','''# Edge of Chaos — a pattern and the way we drive it

Sixth declared QFEP Laboratory hall. A paired Gray-Scott display starts two fields from the same numbered seed and advances them through the same model duration using two numerical timesteps. Follow a boundary, hold the images, repeat the seed or choose a new one. Change LAMBDA slowly while keeping SIM SPEED steady, then restart at a fixed setting for comparison.

The numerical repair applies to every tenure of the main artifact. The chapter preserves its investigative opening and replaces the proposed future experiment with the actual paired comparison. It does not classify an image as life or criticality from the knob setting.

All six map placements remain. Five works instantiate; the legacy teleporter is suppressed by the continuous museum. The central terraced structure remains, with an accessible east-side study bay. Headset operation and learner understanding remain pending. Next: Sandbox and the question of which objects actually receive a control.
''')
md('blurb.md','''*The image changes. Which part of the change belongs to the way we calculated it?*

Two fields begin together. One takes smaller steps.

Choose a boundary and keep looking.
''')
p='commons/data/museum_core_encounters.json';d=read(p);r=d['rooms'][M];r.update(reason='Compare the same starting field at equal model time with two numerical timesteps; choose a feature before naming a regime.',status='encounter_and_text_revised',review_evidence=H.relative_to(R).as_posix()+'/SUMMARY.md',learner_verified=False)
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[k]=hashlib.sha256((D/n).read_bytes()).hexdigest()
write(p,d)
lines={'edge_of_chaos_unlocked':'Two fields begin together. One takes smaller steps.'}
p='commons/data/book/qfeplaboratory.json';d=read(p);e=next(x for x in d['pearls'] if x['map']==M);e.update(hero='edge_of_chaos_unlocked',lines=[{'token':k,'text':v,'by':'hand'} for k,v in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 for e in node['pearls']+d.get('hand_pearls',{}).get('qfeplaboratory',[]):
  if e.get('map')==M:e.update(hero='edge_of_chaos_unlocked',says=lines,says_by={k:'hand' for k in lines})
 write(p,d)
p='commons/maps/sequences/qfeplaboratory.json';d=read(p);s=d['sequences']['qfeplaboratory'];s['content'][5]='QFEP_Edge_Of_Chaos: A pattern and the way we drive it';g=next(g for g in s['artifact_groups'] if g['map']==M);g['rationale']='Compare a shared Gray-Scott model at two timesteps before assigning a regime name. Retain the surrounding secondary comparisons.';write(p,d)
p='commons/artifacts/registry/qfep.json';d=read(p);e=d['artifacts']['edge_of_chaos_unlocked'];e['description']='Gray-Scott field on an authored lambda parameter route. Every tenure uses a normalized neighbour stencil and bounded timestep. Optional comparison_study shows equal-time fields with dt and dt/2; restart repeats the seed, new seed changes it.';e.setdefault('parameters',{})['comparison_study']='on/off: paired timestep display, compact controls and B-field RMS difference';e['qfep_connection']='Who chooses the model, numerical resolution and observable used to recognise a pattern? Parameter bands do not establish criticality or life.';write(p,d)
for n in ['final.md','technical.md','critical.md']:
 old=(B/'commons/maps'/M/n).read_text(encoding='utf-8');new=(D/n).read_text(encoding='utf-8');(H/(n.removesuffix('.md')+'.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+n,tofile='after/'+n)),encoding='utf-8')
print('Edge manuscript and metadata aligned; secondary ecology and terraces retained')
