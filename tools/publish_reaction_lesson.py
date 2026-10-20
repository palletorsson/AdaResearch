"""Publish the verified reaction lesson and update only its curriculum/layout rows."""
from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern'
M=R/'commons/maps/ProceduralGeneration_Reaction_Diffusion_Systems';S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
RUN=R/'ada_run/encounter_pilot'/M.name/'reaction-final';KEY='softbodies|proceduralgeneration reaction diffusion systems'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.write_bytes(s.encode())
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=read(O/'checks.json');room=read(RUN/'report.json');assert code['passed'] and room['passed']
assert any(c['name']=='All planned checks completed' and c['passed'] for c in room['checks'])
for p in [O/'code.log',RUN/'engine.log']:assert not any(s in text(p) for s in ['SCRIPT ERROR','Parse Error','without a physics space','Position cannot be returned'])
hashes=read(O/'before/hashes.json')
protected=[p for p in hashes if p.startswith(('algorithms/','commons/artifacts/turing_pattern_generator/')) or p.endswith(('softbodies.json','soft_workshop.json'))]
for p in protected:assert sha(R/p)==hashes[p],p
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S);assert len(blocks)==3
for name,source in blocks:assert source+'\n'==text(O/'printed'/name)==text(S/name) and sha(S/name)==read(O/'printed-hashes.json')[name]
assert (S/'point_body.gd').read_bytes()==(S.parent/'SoftBodies_Affect_Theory_Visualization/point_body.gd').read_bytes()
expected=read(O/f'before/commons/maps/{M.name}/map_data.json');cells=expected['layers']['interactables'];cells[6][8]=cells[3][15];cells[3][15]=''
assert read(M/'map_data.json')==expected
plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x['map']==M.name)
expected=read(O/'before/museum-plan.json');a=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console');a['cell']=[8,6];a['tile_cell']=[8,6];a['ruled']['cell']=[8,6]
assert plan==expected
for folder in ['assets','museum','before-museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['above.png','entry.png','encounter.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'reaction-before'/name,O/'before-museum'/name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
n,q=len(code['checks']),len(room['checks'])
technical=f'''# What keeps a pattern changing? — implementation

## Installed hall

Primary source: `commons/artifacts/turing_pattern_generator/turing_pattern_generator.gd`. It uses two old and two spare arrays, a weighted eight-neighbour Laplacian (axial 0.2, diagonal 0.05, centre −1), Du 0.16, Dv 0.08, explicit dt 1 and a 0–1 clamp. The hall selects resolution 32, centre seeding and pattern_seed 1337. Centre seeding constructs a **6 × 6 square: 36 cells**, not the twelve stated in the earlier prose. The default rates are feed 0.055 and kill 0.062. Preset names are parameter labels, not guaranteed visual outcomes.

The existing hall adapter holds this model: auto_run=false and processing disabled, while its six controls explicitly step and update the texture. STEP, 100 STEPS, REGIME, SEEDING, RESET and RULE were operated through the real desktop pointer. REGIME resets the state with another rate pair; SEEDING selects another initial arrangement. Local artifact sliders have their own existing behaviour and should not be confused with the desk's reset contract.

The desk moves from (15,3) to (8,6), beside the field at (8,9), clearing arrival. A museum-only ReactionWall in soft_workshop.gd adds a 3.7m upright QuadMesh using the **same live ImageTexture** as the table. Its material is unshaded with nearest filtering; it adds no second simulation. A solid frame, uprights, tabletop support and local fill light stage the display. The original field algorithm, other running reaction-diffusion implementation, other five placements and sequence order stay unchanged.

The final native wall image is the installed Stripes preset (feed 0.042, kill 0.059), centre seed, after ten actual 100-step button presses. It is not the startup image, a different model or a generated illustration. Starting state and step count remain available through reset/readout. The second reaction-diffusion exhibit runs on its own clock and is not a paired control.

## Learner lineage

Source: `doc/book/studies/soft-bodies-through-the-hands/{M.name}/`.

The learner returns to CA_SoftRules' Field and two-table host. The four-neighbour stencil, starting square, old/next update, coefficients and wrapped indices are carried. next_pair now separates conversion, supply and removal by name; local_terms toggles their contribution. Both copies retain exchange. A enables all terms; B initially exchanges only. C changes B's local-term switch and resets both fields; R restores initial arrays without changing that switch. Both advance by equal explicit steps, capped at 2,400. Enter/Space/C/R/V/I are the declared keyboard controls; XRTools/desktop pickup provides planting through the carried point.

The witness W moves from the CA boundary address (12,15) to the uniform interior (15,15). Its first step isolates the local terms: A becomes (0.48725,0.257); B remains (0.5,0.25). At B's boundary, diffusion still changes values. The independent FEED 0.050 edit predicts (0.49375,0.25375) in A and leaves B's local first step unchanged. The learner's feed/kill defaults are 0.037/0.060; these and its stencil differ from the installed artifact. No numerical identity between those implementations is claimed.

The default complete learner matched the earlier CA model exactly at 100 steps (maximum array difference {code['observations']['ca_max_difference']}). PointBody is byte-identical to both that CA lesson and the immediately preceding Affect lesson. The display and seeding host is carried with changed labels, witness and comparison switch. Full source is printed in tutorial.md; no undeclared child reference is required. A temporarily mounted host at map-local (15,0,18), yaw180, demonstrates the actual code in the museum.

## Validation

{n} executable code checks passed: analytical local values, indexing/wrapping, uniform fixed point, diffusion, synchronous traversal, prior model parity, exact texture values, input dispatch, replay, synthetic XRTools targeting in a translated/rotated host, shared planting, release, and the independent feed edit. Four executing fault programs were caught: wrong conversion sign, missing supply, in-place updates and a replay that resets only the clock. GPU texture inspection uses native OpenGL; the headless dummy renderer cannot validate texture uploads. The test creates the rotated host before adding rigid bodies, as the museum fixture does.

{q} native museum checks passed, including six desk controls and rule-card closure, live wall linkage, ten batches, held idle state, exact learner at 1 and 1,000 steps, identical restored fields, the independent edit and a supported outer route. The route is checked at {room['observations']['route']['samples']} sample positions, turning toward the centre at z60 and ending inside the exit at z62.5. It does not claim all paths or portal transitions were tested.

Existing UID, material and renderer warnings remain; no script/parse errors in final runs. Physical headset comfort, Quest frame time and an independent human student's understanding remain untested. Assertions validate program claims, not the analogy between chemical persistence and living bodies.

Reproduce with `python tools/test_reaction_lesson.py` and `python tools/run_encounter_probe.py {M.name} --sequence softbodies --render --no-bridges --output-tag reaction-final --probe tools/probes/reaction_room.gd`. Report: `doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern/`.
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
layout=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d);dest=O/'before'/('runtime-layout.json' if rel.startswith('ada_run') else 'canonical-layout.json')
 if not dest.exists():dump(dest,d['halls'].get(KEY))
 d['halls'][KEY]=layout
 assert {k:v for k,v in d['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,d)
p=R/'commons/data/long_museum.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d);segment=next(x for x in d['segments'] if x['name']==M.name)
if not (O/'before/long-museum-segment.json').exists():dump(O/'before/long-museum-segment.json',segment)
prior=len(segment['artifacts']);segment['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a.get('rotation',0)} for a in plan['artifacts']]
delta=len(segment['artifacts'])-prior;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='softbodies')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=M.name]==[x for x in old['segments'] if x['name']!=M.name]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d);row=next(x for x in d['lessons'] if x['id']==M.name)
row.update(object='The two concentration fields and PointBody planting tool from CA_SoftRules.',change='Open the previously supplied local Gray–Scott terms; hold exchange fixed and compare full reaction/supply/removal against exchange alone.',dependsOn=['CA_SoftRules','SoftBodies_Affect_Theory_Visualization'],reuses='Two arrays, wrapped four-neighbour stencil, synchronous updates, display/field distinction and unchanged PointBody.',given='Museum player/camera/XRTools. Carried field storage and table/panel staging. The installed eight-neighbour model remains a related encounter, not a numerically identical run.',later='No chemical lab fidelity, biological-life claim or arbitrary stable timestep. Mapping concentrations into 3D geometry belongs to the next hall.',checks=[f'{n} executable checks of three exact visible files, prior CA parity, analytical predictions, texture values, input/XRTools, feed edit and four caught faults.',f'{q} native museum checks with all installed controls, actual shared wall texture, two 1000-step comparisons, independent edit and route support.'],transfer='Change FEED 0.037 to 0.050. Predict A at W=(15,15) becomes U0.49375,V0.25375 after one step; B stays0.5,0.25 locally. Run from a matched start, then compare equal step counts.',carry='Separate a starting disturbance, the rule maintaining/changing it, numerical choices, and the display.',next='Topology_Entropy_Morphogenesis: map a field into a surface; inspect what its entropy-named parameter actually controls.',notes='Revised draft; approval unchanged. Desk relocated beside existing field, same-texture wall added. Native desktop/OpenGL and synthetic XR only. Learner mounted temporarily at(15,0,18),yaw180.',summary='Return to the CA fields and the same black PointBody. Keep neighbour exchange in both copies, then write the local conversion, supply and removal terms that were previously given. Predict the first update at an interior address where exchange is zero; compare full local dynamics with exchange alone from identical beginnings and at equal step counts. Plant the same patch in both fields with the held point, enable the missing terms and replay to recover exact agreement, then change feed and check both predicted concentrations. Keep the installed eight-neighbour display distinct from the learner’s carried four-neighbour model. Carry the difference between field state, update rule and its image into the next hall’s surface construction.')
previous=next(x for x in old['lessons'] if x['id']==M.name)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert all(any(x['id']==dep for x in d['lessons']) for dep in row['dependsOn'])
assert [x for x in d['lessons'] if x['id']!=M.name]==[x for x in old['lessons'] if x['id']!=M.name]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
report=f'''# What keeps a pattern changing?

**Soft Bodies 8/9 — Reaction–diffusion.** The earlier CA lesson already supplied a reaction function. This hall opens it, while retaining the field, its neighbour rule and the PointBody interaction.

|Part|Before|Now|
|---|---|---|
|Tutorial|Three isolated formula lines and descriptions of controls|Three complete runnable files with a predicted local step, matched comparison and independent edit|
|Lineage|CA's supplied reaction left implicit|Return to the same two fields; explain conversion, supply and removal|
|Comparison|Different exhibits could be mistaken for matched runs|A and B share initial conditions, neighbour exchange and step count; only local terms differ|
|Numerical scope|Stencil differences unstated|Learner keeps four neighbours; installed display uses eight weighted neighbours|
|Reflection|Mostly repeated technical explanation, code and unverified long-run claims|What needs to continue for a difference to persist; resemblance and biological claims distinguished|
|Room|Small horizontal field; desk blocked arrival and sat apart|Desk beside the field, large upright display of the same live texture, supported frame and local light|

## One focused operation

At each address, conversion removes U and adds V. Supply replenishes U. Removal takes V away, with feed contributing to that removal as well. The comparison holds neighbour exchange in both fields, enabling these local terms in A and initially disabling them in B.

At W=(15,15), all neighbours initially match. The first update is therefore predictable without computing diffusion: A changes from (0.5,0.25) to (0.48725,0.257), while B stays at (0.5,0.25) at that address. B still changes at the patch boundary. The learner can then compare the different consequences after 1,000 equal steps.

Enabling B's local terms restarts both fields; they agree exactly again. The same carried black sphere plants a patch in both fields. It changes their state, not their rule or clock. The independent edit raises feed to 0.050: the student predicts U = 0.49375 and V = 0.25375 at W before looking at the later picture.

The original CA behaviour is retained when all terms are enabled: at 100 steps, the maximum array difference is {code['observations']['ca_max_difference']}. The learner's code keeps the old four-neighbour discretization. The installed hall's eight-neighbour stencil and different rate pair are described explicitly. They are related demonstrations rather than interchangeable numerical evidence.

## A field you can read from the desk

The desk moves from (15, 3) to (8, 6), beside the existing generator. A 3.7 m square screen shows the very same ImageTexture as the tabletop. This changes the presentation without another solver, clock or pattern generator. The other artifacts and the sequence order remain.

The wall capture shows the installed Stripes preset after 1,000 updates from the centre seed. Its name does not guarantee stripes at that moment. The small patch, surrounding conditions and elapsed steps matter. The old text's twelve-cell seed is corrected: the actual 32 × 32 hall field begins with a 6 × 6 square, 36 cells.

The compact two-field learner is temporarily mounted inside the museum at (15, 0, 18), yaw 180°, for the images and tests. It is the student's construction beside the encounter, not another permanently registered exhibit. Its clock/comparison controls are keyboard-driven; planting uses the existing desktop/XR pickup interface. The installed desk retains its VR controls.

## Tested claims

**{n} code checks and {q} native museum checks passed.** Exact visible source is extracted and executed in native Godot 4.6/OpenGL. Checks include analytical predictions, wrapping, synchronous update order, the earlier model, display pixels, actual keyboard dispatch, synthetic XRTools targeting under a transformed host, the feed edit and four deliberately faulty programs. The faults reverse conversion, omit supply, update in place, or reset only the clock; each is detected.

The museum checks operate all six controls with the desktop pointer, advance ten actual hundred-step batches, verify shared texture identity and held time, run both learner comparisons and the complete independent edit, and sample floor support and capsule clearance. The larger display and before/after arrangement were inspected in native images from above and eye level.

These checks support the program's claims. They do not establish physical headset comfort, Quest performance or a human student's understanding. Existing UID/renderer warnings remain; final runs have no script/parse errors. Initial test-fixture issues concerned dummy-renderer texture inspection and placing a rigid-body host after initialization; final tests use native rendering and correct scene-entry order. The learner code did not need repair for those fixture issues.

Next: **Morphogenesis — a field becomes a surface.**
'''
write(O/'REPORT.md',report)
css=re.search(r"css='''(.*?)'''",text(R/'tools/publish_sampling_examples.py'),re.S)[1]
def md(s,prefix=''):
 out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
 if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
 return out
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">ENDLESS MUSEUM · SOFT BODIES 08 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="reaction-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum captures · exact printed code · physical headset and independent learner assessment remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:text(O/(k+'.md')) for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Reaction — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md(text(O/f'before/commons/maps/{M.name}/{k}.md'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><p class="eyebrow">HALL 08 / REACTION–DIFFUSION</p><h1>What keeps a pattern changing?</h1><p>Return to the two fields. Open the local rule. Let one difference become visible.</p><p class="note">'+str(n)+' code checks + '+str(q)+' museum checks passed.</p>'
body+=fig('assets/student-1000.png','Exact learner inside the museum, step 1,000. A: reaction, supply, removal and exchange. B: exchange alone. The same point plants a patch in either field.')
body+='<div class="pair">'+fig('assets/student-one-step.png','First step: W isolates the local terms. Its values can be predicted before the later pattern appears.')+fig('assets/student-matched.png','Enable B’s local terms and replay: both 1,000-step fields agree exactly.')+'</div>'
body+='<h2>The existing field, enlarged</h2>'+fig('assets/wall-1000.png','The museum’s existing simulation at 1,000 steps. The new upright screen shares its live texture with the tabletop; no second solver is added.')
body+='<h2>Before and after</h2><div class="pair">'+fig('before-museum/encounter.png','Before: the small field, separated from the hall desk.')+fig('assets/desk.png','After: the desk is beside the field, with a large upright display behind it.')+'</div>'
body+='<h2>The room from above</h2><div class="pair">'+fig('before-museum/above.png','Before: the desk obstructs central arrival. Existing rear architecture and other exhibits remain.')+fig('assets/with-learner-above.png','After: nearby controls and large display, with the temporary learner comparison in the open court.')+'</div>'
body+=fig('assets/student-feed-edit.png','Independent FEED 0.050 edit at 1,000 steps. Its first-step values were checked before this image was captured.')+md(report)+'<p><a href="checks.json">Code checks</a> · <a href="museum/report.json">Museum checks</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('What keeps a pattern changing?',body))
for name in ['reaction_student.gd','reaction_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_reaction_lesson.py','place_reaction_desk.py','write_reaction_lesson.py','publish_reaction_lesson.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
shutil.copyfile(R/'commons/artifacts/timing_machines/soft_workshop.gd',O/'after/soft_workshop.gd')
dump(O/'manifest.json',{'canonical':{k:sha(M/k) for k in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':read(O/'printed-hashes.json'),'unchanged_sources':{p:sha(R/p) for p in protected},'adapter':sha(R/'commons/artifacts/timing_machines/soft_workshop.gd'),'checks':[n,q],'headset':False})
write(O/'README.txt','Open index.html for museum images; parallel.html for tutorial left/reflection right. printed/ holds all three files plus study.tscn. Place the scene in the existing Endless Museum project, at unit scale and floor level, with camera/player/XRTools supplied. Enter:step; Space:+100; C:toggle B local terms and replay; R:replay preserving comparison; V:view U/V; held point trigger or I:plant in both fields. The compact clock/comparison controls use keyboard, installed hall has VR desk. variation/ changes FEED to0.050. fault-* files deliberately fail contracts. Learner keeps the earlier CA four-neighbour model; installed wall uses a distinct weighted eight-neighbour model. Code and native room receipts define tested scope. No physical headset or independent human learner claim.\n')
archive=O/'reaction-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="reaction-review.zip"',b'href="README.txt"')
   z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  self.links.extend(v for k,v in attrs if k in ['href','src'] and v);self.ids.extend(v for k,v in attrs if k=='id')
refs=0
for p in O.glob('*.html'):
 parser=Links();parser.feed(text(p));assert len(parser.ids)==len(set(parser.ids))
 for link in parser.links:
  if link.startswith(('http:','https:','data:')):continue
  if link.startswith('#'):assert link[1:] in parser.ids;continue
  assert (p.parent/link.split('#')[0]).exists(),(p,link)
  refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',text(O/'tutorial.html'),re.S)];assert len(rendered)==3
for name,s in zip(['field.gd','reaction.gd','point_body.gd'],rendered):assert s==text(O/'printed'/name)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None;members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode())
   for link in parser.links:
    if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
result={'passed':True,'checks':[n,q],'local_refs':refs,'rendered_code_parity':3,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False}
dump(O/'validation.json',result);print(json.dumps(result))
