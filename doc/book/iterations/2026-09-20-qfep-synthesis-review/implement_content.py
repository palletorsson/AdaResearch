from pathlib import Path
import json,hashlib
R=Path('.');H=R/'doc/book/iterations/2026-09-20-qfep-synthesis-review';B=H/'before';M='QFEP_Synthesis';D=R/'commons/maps'/M
old=(B/D/'final.md').read_text(encoding='utf-8')
p='Use the specimen’s own LAMBDA and PHI sliders. Hold one steady while changing the other, and compare the body’s shape and continuing movement. Watch for long enough to separate a persistent response from the timed breathing already present in the specimen.'
new=p+'''

Choose PAIR B and watch the pressure reading while it says PULSE. Press PULSE / STEADY. The number settles at its baseline. Has the body finished moving? Stay with one part of it for a moment. You have stopped the imposed breathing; the specimen remains subject to its other forces. Steady pressure is something you have given it. Stillness would be something else.
'''.rstrip()
text=old.replace(p,new)
text=text.replace('The mapping is authored for this specimen. Stiffness decreases across the lambda range, pressure has a designed peak near the middle, and signed phi changes the damping and drag values. The visible response makes those choices inspectable; it does not establish that nature uses the same numerical scale.','The mapping is authored for this specimen. Stiffness decreases across the lambda range, pressure has a designed peak near the middle, and signed phi changes the damping and drag values. Breathing varies around that pressure baseline within an interval the maker selected. The plate shows what the body receives. It does not establish that nature uses the same numerical scale.')
needle='The laboratory has now used its terms in several ways:'
i=text.index(needle)
text=text[:i]+'''The name above the glass stays. Inside, the terms of holding together have changed. The jar supplies another set of terms: a bottom, sides, a lid. Its clear surface lets you watch while its boundaries limit where the specimen can go. The sliders do not move those boundaries.

'''+text[i:]
text=text.replace('Post-crisis begins with representation itself.','Self-Q turns the investigation back towards the maker. After giving this body a name, a container and a range of responses, what have we trained ourselves to recognise as possible? Which part of the apparatus would we change next?\n\nPost-crisis begins with representation itself.')
(D/'final.md').write_text(text,encoding='utf-8')
archive='# Earlier Synthesis proposals\n\nRetained verbatim on 20 September 2026. These imagined mechanics and spatial claims are historical proposals; the current encounter is documented in technical.md.\n\n'
for n in ['technical.md','tutorial.md','critical.md']:
 if (B/D/n).exists(): archive+='## '+n+'\n\n'+(B/D/n).read_text(encoding='utf-8')+'\n\n---\n\n'
(D/'design-proposals.md').write_text(archive,encoding='utf-8')
(D/'technical.md').write_text('''# A body receives the mapping

Sandbox separated a moving handle from the values another object receives. Synthesis uses a specimen with its own two local sliders. Neither control is broadcast to the surrounding formula, spheres, ceiling or meter.

Lambda maps to two SoftBody3D coefficients:

```gdscript
stiffness = lerpf(0.9, 0.1, lambda)
midpoint_weight = 1.0 - abs(lambda - 0.5) * 2.0
pressure_baseline = base_pressure * (1.0 + midpoint_weight * 0.5)
```

With the default base pressure of 1, the baseline is 1 at the endpoints and 1.5 at the midpoint. This triangular peak is authored. No phase transition or entropy estimate is detected by it.

When pulsing is enabled and 0.3 < lambda < 0.7, the pressure used by the body is baseline * (1 + sin(time * speed) * amplitude), with speed interpolated from 0.5 to 2.0 and amplitude from 0.02 to 0.1 across the lambda range. At lambda 0.5 the pressure varies between 1.41 and 1.59 around 1.5. The former frame callback overwrote this baseline with values near 1. The repaired physics callback preserves the mapped baseline and advances elapsed simulation time independently of rendered frames.

PULSE / STEADY disables or enables this imposed modulation and restarts its phase. It leaves the body's mesh, existing motion, gravity, stiffness, damping and drag intact. It does not pause or reset the physics engine. PAIR A, B and C select (lambda, phi) = (0.1, -0.8), (0.5, 0), (0.8, 0.6). They are sample combinations, not classified biological states.

Phi ranges from -1 to +1. Its normalized coordinate u=(phi+1)/2 maps damping from 0.2 to 0.001 and drag from 0.3 to 0. The controls also change material colour and shader parameters, so a changing image is not by itself evidence of mechanical deformation. The plate reads the actual body coefficients, while the framed viewport updates text without rebuilding baked meshes every tick.

The jar previously had only a floor collider. A sixteen-part side shell and lid now match the closed jar. The cracked variant has a shorter open shell; escaped retains only the base; clouded retains its fixed 160-grain MultiMesh and has no deformable body. The live plate identifies that distinction. A glass shader is not a fluid solver: there is no buoyancy calculation here.

In this hall the specimen stands at full scale on two adjacent support cells, facing the entry, with the controls to its side. Other placements and the central terraces remain. The selection labels, live readout and causal mapping support a comparison; they do not establish a universal correspondence between a coefficient and an identity.

The main manuscript retains the proposal to record deformation histories. Such a trace is not yet implemented. Headset comfort and whether learners can distinguish the responses remain open checks.
''',encoding='utf-8')
(D/'tutorial.md').write_text('''# Follow one response

Choose PAIR B. Compare pressure base with pressure now. Use PULSE / STEADY to hold pressure at its baseline; keep watching the body rather than assuming it was paused.

Keep Phi steady and change Lambda. Compare stiffness and baseline pressure. Then hold Lambda and move Phi across zero: damping and drag change while that pressure baseline remains. Compare one visible region through time.

The three PAIR buttons select examples. They do not reset the body's previous motion. The live plate reports coefficients, not measured entropy or a biological state. The implementation is in technical.md; the earlier imagined noise-deformed specimen is preserved in design-proposals.md.
''',encoding='utf-8')
(D/'critical.md').write_text('''# The name above the glass

A specimen is already a decision about how to look. A name, a container, a selected body: the display makes something available to attention by making it stand apart. Its edges are also conditions placed upon the thing we hope to understand.

Here Lambda changes stiffness and pressure; Phi changes damping and drag. Neither rail can remove the lid. The visitor can select a response within the apparatus while the apparatus retains authority over the available responses. Its generosity has a shape.

Stopping the pressure pulse does not stop physics. The body continues to inherit its previous motion and its contact with the container. This is a small distinction, but one the hand can investigate: changing an ongoing condition is different from erasing what happened under it. The nearby controls give access to the former.

The title Queer Morphology opens a question; the coefficients cannot certify its answer. Why should persistent motion signify freedom, or settling signify submission? A boundary may confine, sustain or shelter. That judgment requires attention to consequences the pressure reading alone cannot supply.

Self-Q asks what building this specimen does to its maker. Do we become better at noticing how a body is supported, or quicker to read our own parameter choices as its nature? Keeping that question open means carrying the frame, the lid and the chosen mappings into the account of what we see.

The next sequence begins with the distinctions a representation permits. We leave this specimen with a more specific question for that work: what else would have to change for another kind of body to become possible here?
''',encoding='utf-8')
(D/'summary.md').write_text('''# What should this body keep?

The last of eight QFEP Laboratory halls compares authored mechanical mappings on one deformable specimen. Its local Lambda rail controls stiffness and pressure baseline; signed Phi controls damping and drag. PULSE / STEADY separates an imposed pressure wave from the body's continuing physics. The live plate names these quantities instead of certifying a life regime.

The specimen is full size on an accessible west-side display. All ten original artifact families and the central terraces remain. The formula and grabbable terms return as supporting works. The current continuous museum proceeds to Post-Crisis; the old standalone return-to-lab teleporter remains a legacy utility, not that museum crossing.

The question moves from varying an input to asking who can revise the container and response law. Headset comfort and learner understanding remain unverified.
''',encoding='utf-8')
(D/'blurb.md').write_text('''*The name stays. The body has other work to do.*

Stop the imposed breath. Watch what continues.

What should this body keep?
''',encoding='utf-8')
def read(p):return json.loads((R/p).read_text(encoding='utf-8-sig'))
def write(p,d):(R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p='commons/data/museum_core_encounters.json';d=read(p);e=d['rooms'][M];e.update(status='encounter_and_text_revised',reason='Separate stiffness, pressure and dissipation in one existing specimen; stop imposed pressure modulation while physics continues.',learner_verified=False,review_evidence=H.as_posix()+'/SUMMARY.md')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:e[k]=hashlib.sha256((D/n).read_bytes()).hexdigest()
write(p,d)
lines={'queer_morphology_specimen':'The name stays. The body has other work to do. Stop the imposed breath; watch what continues.'}
p='commons/data/book/qfeplaboratory.json';d=read(p);e=next(e for e in d['pearls'] if e['map']==M);e['hero']='queer_morphology_specimen';e['lines']=[{'token':k,'text':v,'by':'hand'} for k,v in lines.items()];write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 for e in node['pearls']+d.get('hand_pearls',{}).get('qfeplaboratory',[]):
  if e.get('map')==M:e.update(hero='queer_morphology_specimen',says=lines,says_by={k:'hand' for k in lines})
 write(p,d)
p='commons/maps/sequences/qfeplaboratory.json';d=read(p);s=d['sequences']['qfeplaboratory'];s['content'][7]='QFEP_Synthesis: What should this body keep?';g=next(g for g in s['artifact_groups'] if g['map']==M);g['rationale']='Compare authored mechanical quantities and separate imposed pressure modulation from the response of a contained body.';write(p,d)
p='commons/artifacts/registry/commons_artifacts.json';d=read(p);a=d['artifacts']['queer_morphology_specimen'];a['description']='A contained soft-body specimen with local Lambda stiffness/pressure and signed Phi damping/drag controls. Live mechanical readout, three sample pairs and PULSE / STEADY reveal authored conditions of response. Jarred, cracked, escaped and clouded forms remain distinct.';a['qfep_connection']='Ask who can revise the conditions under which a body holds together: the visitor can change coefficients and imposed breathing, while the response law and container remain authored. This is not an assay of life, entropy or queerness.';write(p,d)
print('Manuscript and supporting notes updated; earlier proposals preserved')
