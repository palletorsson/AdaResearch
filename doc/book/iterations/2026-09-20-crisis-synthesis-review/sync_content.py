from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; ROOM='Crisis_Synthesis'
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d):(ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# Normalise PowerShell's UTF-8 BOM before hashing or composing the book.
for name in ['final.md','technical.md','critical.md','summary.md','blurb.md']:
 p=ROOT/'commons/maps'/ROOM/name;p.write_text(p.read_text(encoding='utf-8-sig').rstrip()+'\n',encoding='utf-8')
p='commons/artifacts/registry/qfep.json';d=read(p)
a=d['artifacts']['qfep_formula_3d']
a.update(description='Spatial display of Ada’s QFEP research proposal. Opt-in reading_study binds this hall’s lambda and phi sliders to term colours and a numeric reading panel; three reachable buttons select questions. It does not calculate entropy, free energy or QFE.',interaction='observe; term buttons in reading_study mode')
a['parameters']['reading_study']='Opt-in local slider connections, reading panel and term buttons; on in Crisis_Synthesis. Default off.'
a['dna']['default']='posture=line, emphasis=none; glyph widths are measured to avoid overlaps. Reading apparatus is opt-in.'
a=d['artifacts']['lambda_slider']
a['description']='QFEP parameter rail from 0 to 1, with authored visual effects and a lambda_changed signal. Its preferred green band is a design choice, not a universal interval where life exists. calibration selects optimum, band, dispute, gap or none. In Crisis_Synthesis its signal updates the local formula display only.'
a=d['artifacts']['phi_slider']
a['description']='QFEP parameter rail from -1 to +1 with a phi_changed signal and authored colour/particle interpretations of change. Positive values are not intrinsically an instruction to welcome entropy: that depends on the receiver and objective. calibration offers competing ways to mark desirable settings. In Crisis_Synthesis it updates the local formula display only.'
write(p,d)
p='commons/artifacts/registry/foundations.json';d=read(p);a=d['artifacts']['bifurcation_diagram']
a['description']='Numerical logistic-map diagram with r-window and transient controls. Opt-in visitor_control adds an independent r rail and a yellow orbit sample: x0=0.5, 512 steps skipped, 128 shown. Reports short repeats found in the sample, not proof of chaos.'
a.setdefault('parameters',{})['visitor_control']='Optional r slider and finite orbit readout; on in Crisis_Synthesis.'
a['interactions']=['Move r independently of the QFEP sliders. Compare 2.9, 3.2, 3.5 and 3.83; examine what the sample retains.']
a['qfep_connection']='Compare an explicit recurrence with the research formula. The logistic map does not establish a universal optimal lambda, a moral preference for chaos or a QFEP theorem.'
write(p,d)
p='commons/artifacts/registry/concept_architecture.json';d=read(p);a=d['artifacts']['goedel_atrium']
a['description']='Walk-in atrium containing nested tenth-scale models, to a finite recursion depth. The wall presents THIS ROOM CANNOT PROVE THIS ROOM as a spatial metaphor. It makes self-description and bodily scale approachable; it does not implement Gödel’s proof.'
write(p,d)
primary=['qfep_formula_3d','lambda_slider','phi_slider','bifurcation_diagram','goedel_atrium','russell_paradox_workbench']
secondary=['godel_statement_plaque','russell_set_box','escher_staircase','florensky_sphere']
p='commons/data/artifact_roles.json';d=read(p)
d['roles'][ROOM]={**{t:'primary' for t in primary},**{t:'secondary' for t in secondary}}
d['order'][ROOM]={'primary':primary,'secondary':secondary,'decoration':[]};write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p);r=d['rooms'][ROOM]
r.update(primary_tokens=primary,reason='Read and question the research formula; compare an independently controlled recurrence, enter a finite self-description, and return to the membership test. All ten families retained, with four smaller reminders secondary.',status='encounter_and_text_revised',learner_verified=False,review_evidence=HERE.relative_to(ROOT).as_posix()+'/SUMMARY.md')
for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[key]=hashlib.sha256((ROOT/'commons/maps'/ROOM/f).read_bytes()).hexdigest()
write(p,d)
lines={
 'qfep_formula_3d':'An equals sign waits. What would you need to know before you could trust it?',
 'lambda_slider':'The green region reassures. Who chose its place?',
 'phi_slider':'Your hand changes the display. What would make this a change in the world?',
 'bifurcation_diagram':'Two heights, four, then three again. What does this run retain?',
 'goedel_atrium':'You can look into your description. Can this body enter it?',
 'russell_paradox_workbench':'Try membership both ways. Self-reference alone was never the whole trouble.',
 'godel_statement_plaque':'A sentence about proof returns with its conditions.',
 'russell_set_box':'A nested image remembers a membership demand it cannot settle.',
 'escher_staircase':'A convincing view returns. Keep its difference from a proof.',
 'florensky_sphere':'Both readings remain. We have more ways to continue than the rail has labels.'}
p='commons/data/book/foundationscrisis.json';d=read(p);pearl=next(x for x in d['pearls'] if x['map']==ROOM)
pearl.update(hero=primary[0],lines=[{'token':t,'text':s,'by':'hand'} for t,s in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='foundationscrisis')
 for pearl in node['pearls']+d.get('hand_pearls',{}).get('foundationscrisis',[]):
  if pearl.get('map')==ROOM:pearl.update(hero=primary[0],says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
p='commons/maps/sequences/foundationscrisis.json';d=read(p);s=d['sequences']['foundationscrisis']
s.update(truth='Different formal systems and representations have different powers and limits. Investigate their assumptions before generalising.',
 qfep_connection='The sequence supplies questions for Ada’s QFEP research proposal. Geometry, incompleteness, construction and non-explosion do not prove that proposal or a universal need for chaos.',
 formula='QFE = F − λE(S) + φΔE(S,t) — the synthesis presents this as a project proposal.',
 description='Eight encounters with assumptions, membership, proof, projection, construction and conflicting reports. The final hall asks what a model accounts for and who can answer back.',
 learning_objectives=['Compare Euclidean and non-Euclidean choices of geometry.','Distinguish unrestricted comprehension from self-reference alone.','Understand incompleteness as a result about specified arithmetic theories.','Compare constructive evidence, unresolved claims and non-explosion.','Question how a research model selects, measures and values its states.'],
 content=['Euclid_Parallel: What is assumed about parallel lines?','NonEuclidean_Spaces: What changes with the geometry?','Russell_Paradox: Which membership demand produces the contradiction?','Godel_Incompleteness: What can this theory prove?','Escher_Impossible: What does the convincing view conceal?','Brouwer_Intuitionism: What has been constructed?','Florensky_Paraconsistent: What follows from conflicting reports?','Crisis_Synthesis: Who can answer the model?'])
# Sequence/group order and prerequisites are unchanged. Only the current hall's group is reconciled.
group=next(g for g in s['artifact_groups'] if g['map']==ROOM)
group.update(artifacts=primary+secondary,rationale='Level 19 by 24 gallery: local formula reading, independent logistic-map control, walk-in recursive atrium, Russell workbench and four retained comparisons.')
for k,vals in s['references'].items():
 s['references'][k]=[v.replace('GÃ¶del','Gödel') for v in vals]
write(p,d)
