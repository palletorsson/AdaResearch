from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-morphogenesis-who-connected-the-controls'
M=R/'commons/maps/Topology_Entropy_Morphogenesis';S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
RUN=R/'ada_run/encounter_pilot'/M.name/'morphogenesis-final';KEY='softbodies|topology entropy morphogenesis'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.write_bytes(s.encode())
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=read(O/'checks.json');room=read(RUN/'report.json');assert code['passed'] and room['passed']
assert any(c['name']=='All planned checks completed' and c['passed'] for c in room['checks'])
for p in [O/'code.log',RUN/'engine.log']:assert 'SCRIPT ERROR' not in text(p) and 'Parse Error' not in text(p)
hashes=read(O/'before/hashes.json');protected=[p for p in hashes if not p.startswith('commons/maps/'+M.name+'/')]
for p in protected:assert sha(R/p)==hashes[p],p
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S);assert len(blocks)==2
for name,source in blocks:assert source+'\n'==text(O/'printed'/name)==text(S/name) and sha(S/name)==read(O/'printed-hashes.json')[name]
assert (S/'point_body.gd').read_bytes()==(S.parent/'ProceduralGeneration_Reaction_Diffusion_Systems/point_body.gd').read_bytes()
expected=read(O/f'before/commons/maps/{M.name}/map_data.json');cells=expected['layers']['interactables'];cells[9][15]=cells[3][15];cells[3][15]=''
assert read(M/'map_data.json')==expected
plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x['map']==M.name)
expected=read(O/'before/museum-plan.json');a=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console');a['cell']=[15,9];a['tile_cell']=[15,9];a['ruled']['cell']=[15,9]
assert plan==expected
for folder in ['assets','museum','before-museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['above.png','entry.png','encounter.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'morphogenesis-before'/name,O/'before-museum'/name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
shutil.copyfile(R/'doc/book/figures/softbodies/gyroid-four-levels.png',O/'assets/previous-gyroid-four-levels.png')
n,q=len(code['checks']),len(room['checks'])
technical=f'''# Who connected the controls? — implementation

## Existing museum

The artifact is `algorithms/spacetopology/entropy_morphogenesis/entropy_morphogenesis_vr.gd`, using `GyroidFieldGenerator.gd` from the adjacent gyroid_cheese directory. The adapter `commons/artifacts/timing_machines/soft_workshop.gd` binds its six controls. This pass changes none of those algorithms or the adapter. The desk moves from (15,3) to (15,9), nearer the large surface at (15,14), offset four metres upward. Arrival is clear; the right-side museum route has floor and capsule clearance in {room['observations']['route']['samples']} samples. Passage through the gyroid and portal transitions were not tested.

Opening runtime observations: `{json.dumps(room['observations']['opening'])}`.

The scene exports a non-cubic (5,10,5) box with a 40-cubed resolution. The generator uses box_size.x/resolution.x as one spacing for every axis, starting at -box_size/2. The measured generated bounds therefore span (5,5,5), offset from y=-5, rather than filling the declared ten-metre height. This existing limitation remains explicitly recorded. The prior reflection's metrics for an eight-unit cube are not evidence for this actual exhibit and have been removed from the reflective text. The original illustration and text remain in before/.

S=.3 maps to frequency1.11, noise amplitude.095, threshold-.06. S1 maps to1.6,.20,.15 when the threshold centre is0 and noise is enabled. LEVEL changes threshold centre; NOISE changes its two endpoint amplitudes; RESOLUTION cycles24/16/32. RESET restores S.3, centre0, noise.05/.20, resolution24; the existing button-cycle indices and level string are not reset. Tests assert the resulting parameters, not a clean reset of every UI cursor. The startup resolution is40, not24.

The normalized density is clamp((sine_field + noise_amp * sampled_noise - threshold)/6 + .5,0,1). Threshold changes this mapping while retaining underlying field parameters. The supplied noise implementation multiplies coordinates by noise_freq while FastNoiseLite also holds that frequency; this lesson carries the implementation as supplied and makes no independent claim about its wavelength. A gyroid-like trigonometric level set is not a proof of exact minimality, topology, entropy or physical growth.

## Learner

`doc/book/studies/soft-bodies-through-the-hands/{M.name}/` supplies recipe.gd, unchanged point_body.gd and the minimal study.tscn. Both visible scripts are extracted from tutorial.md and executed. The lesson writes the recipe and its named recipients. Field generation, marching cubes and trimesh collision remain explicit project dependencies; future Isosurfaces work can open the extractor. No new backend and no implicit scene-child reference is introduced.

Two separate generators have equal seed1337, box(8,8,8), resolution24 cubed, and initial recipe at.3. Separate quarter-scale holders display two-metre specimens. The cubic volume avoids the supplied rectangular-spacing issue. A stays fixed; B uses ALL/FREQUENCY/NOISE/CUT modes relative to the original. Held PointBody height in the root's local frame previews0..1 over y.8..1.6; held trigger commits. Release parks at preview height without rebuilding. Keyboard1 cycles mode, arrows preview, Space builds, R resets. Mode selection is keyboard-driven in the student host; installed controls are pointer/VR buttons. The temporary native host sits at map(15,0,27),yaw180; it is not a permanent third artifact.

The independent CUT_SPAN .15->.30 edit changes the starting cut from-.06 to-.12 and the endpoint from.15 to.30, preserving frequency/noise. Source references separate the new analytic spatial field from the previous dynamic two-dimensional reaction field. Their lineage is the method of matched comparison and carried PointBody, not automatic transfer of concentration arrays.

## Evidence

{n} executable code checks passed on native Godot4.6/OpenGL: full host, parameter predictions, recipient isolation, equal seeds/meshes/collision, preview/commit/echo, reset, density difference, transformed-host XRTools, independent edit. Four executing faults were rejected: an uncentred cut, accidentally coupled noise, different seeds and writing to the reference object.

{q} native museum checks passed: actual pointer operations for six controls, current mesh/collider after rebuild, deterministic reconstruction, unchanged geometry at idle, complete learner at four modes, synthetic XRTools preview/trigger/release, independent edit, arrival and outer route. Real above/eye captures inspected. Display type was enlarged after the first capture; final code and museum runs were repeated for that change. Existing UID/Jolt/material warnings remain; no script or parse errors in the final runs. Physical headset comfort, Quest performance and an independent human learner remain untested.

Reproduce: `python tools/test_morphogenesis_lesson.py`; `python tools/run_encounter_probe.py {M.name} --sequence softbodies --render --no-bridges --output-tag morphogenesis-final --probe tools/probes/morphogenesis_room.gd`.
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
row.update(object='The carried PointBody controls a named parameter recipe; two supplied gyroid specimens provide a matched comparison.',change='Preview with point height, commit with trigger. Compare one combined control with separate frequency, noise and cut edits.',dependsOn=['ProceduralGeneration_Reaction_Diffusion_Systems','Noise_Voxel','Noise_Columns','WaveFunctions_Sine_Space'],reuses='PointBody unchanged; matched comparison from CA/reaction; lerp, threshold, local coordinates, sine and noise.',given='Museum/XRTools. GyroidFieldGenerator with MarchingCubesGenerator, VoxelChunk and CaveCollisionGenerator. Field and extractor explicitly supplied.',later='Isosurface extraction remains later. No growth/entropy measure, guaranteed topology or player passage claim.',checks=[f'{n} executable checks, analytical recipe/density predictions, exact meshes, actual input, synthetic XRTools, independent span edit and four faulty programs rejected.',f'{q} native museum checks, all six actual controls, deterministic mesh return, four student modes, independent edit and supported outer route.'],transfer='Change CUT_SPAN .15 to .30. Predict opening cut -.12 and endpoint .30; frequency/noise unchanged. Check CUT mode against fixed reference before interpreting its shape.',carry='Distinguish state evolution, spatial field, selected boundary and the interface connecting their parameters.',next='Review the complete nine-hall Soft Bodies sequence; surface extraction can be opened in Isosurfaces later.',notes='Revised draft; approval unchanged. Only desk relocated [15,3]->[15,9]. Production generator/adapter/order unchanged. Student host temporarily(15,0,27),yaw180. Native desktop/OpenGL and synthetic XR; physical headset untested.',summary='Return to the carried point and the method of matched comparison. The new encounter is a static three-dimensional sine-and-noise field, not the previous reaction array converted automatically. Write a named recipe connecting one bounded value to frequency, noise amplitude and cut level; compare each recipient separately against a kept specimen. Lift the point to preview and trigger to rebuild, making proposed and built states distinct. Predict the parameter triples, verify a cut’s effect on density, and independently double the cut span. Keep field sampling, surface extraction and collision supplied. Close the sequence by distinguishing a changing state, a selected surface and an authored control.')
previous=next(x for x in old['lessons'] if x['id']==M.name)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert all(any(x['id']==dep for x in d['lessons']) for dep in row['dependsOn'])
assert [x for x in d['lessons'] if x['id']!=M.name]==[x for x in old['lessons'] if x['id']!=M.name]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
report=f'''# Who connected the controls?

**Soft Bodies 9/9 — Morphogenesis.** A single gesture can change several decisions. This lesson separates them without requiring the student to write a surface extractor.

|Part|Before|Now|
|---|---|---|
|Tutorial|Three parameter-assignment lines|Complete runnable construction with two specimens and the carried point|
|Focus|Observe several controls|Write the recipe; change one recipient while holding others fixed|
|Interaction|Large surface, distant desk|Desk six metres closer; student point previews by height and commits by trigger|
|Lineage|General references to sine and noise|Reuse the point and matched-comparison method; explicitly distinguish the new spatial field|
|Reflection|Duplicated code and numeric claims for another volume|Who connected the controls, and what becomes possible when we separate them?|

## One value, three decisions

At 0.3, the recipe yields frequency 1.11, noise amplitude 0.095 and cut −0.06. At 1 it yields 1.60, 0.20 and 0.15. ALL changes the three together. Other modes isolate frequency, noise or cut, relative to the opening recipe. The same seed and sampling make A and B comparable.

Moving the held point previews a value. Triggering commits it. The unchanged A specimen lets the student see what B's new recipe did. The independent edit doubles the cut span and requires predictions for both the beginning and the endpoint.

This hall uses an analytic three-dimensional sine-and-noise field. Reaction–diffusion evolved two-dimensional concentration arrays. The connection is the practice of keeping conditions explicit and comparing one change; there is no hidden conversion of the student's previous data. Surface extraction remains supplied and named, ready to be opened in a later sequence.

## The actual room

The desk had obstructed arrival and sat eleven cells from the artifact centre. It now sits at (15,9), five cells from that centre. The specimen remains at (15,14). All other room structure, the original algorithm, adapter and sequence order stay unchanged. The temporary student host appears in the captures at (15,0,27); it is not an additional permanent exhibit.

The source's exported box is (5,10,5), but its shared sampling spacing produces bounds of (5,5,5), beginning at local y −5. That existing limitation is documented. The former text's measurements for an eight-unit cube do not describe this installed object. The lesson deliberately uses a cubic eight-unit field displayed at quarter scale, making two-metre specimens. It does not silently repair or reinterpret the existing extractor.

The room's RESET restores numeric settings and resolution 24; startup resolution is 40. Existing button-cycle cursors are retained. Read the actual values when comparing controls. Neither a threshold name nor an impressive image proves that a route through the surface is traversable.

## The sequence closes

The nine halls now have distinct operations: let a body yield; fix a boundary; drive its support; drive pressure; compare contact; keep a sampled shape; separate an appearance cue; sustain a pattern through local exchanges; compose and separate a parameter recipe. Those are different mechanisms. The point and the habit of controlled comparison give the learner something dependable to carry between them.

The reflection ends by returning to that capacity: carrying a point, relation, saved shape or rule while choosing which part may change. The next useful step is to read the whole Soft Bodies sequence together before external review.

## Evidence and limits

**{n} executable code checks and {q} native museum checks passed.** Exact code printed in tutorial.md is extracted and run. Assertions test predictions, equal initial meshes, isolated recipients, kept reference, current collision, actual keyboard input, transformed-host synthetic XRTools, the independent span edit and four deliberate faults. The faulty programs alter the cut mapping, couple an unwanted parameter, change the seed or write to the reference specimen; all are rejected.

The museum test operates all six buttons through the actual desktop pointer, captures four learner modes and an independent edit, checks deterministic reconstruction and samples a supported outer walking route. Pictures are native Godot captures, including views from above. No script/parse errors occurred; existing UID/Jolt/renderer warnings remain. Physical headset comfort, Quest performance, walking through the gyroid and an independent human student's understanding remain open.
'''
write(O/'REPORT.md',report)
css=re.search(r"css='''(.*?)'''",text(R/'tools/publish_sampling_examples.py'),re.S)[1]
def md(s,prefix=''):
 s=s.replace('/book-images/figures/softbodies/gyroid-four-levels.png','assets/previous-gyroid-four-levels.png')
 out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
 if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
 return out
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">ENDLESS MUSEUM · SOFT BODIES 09 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="morphogenesis-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum captures · exact printed code · physical headset and independent learner assessment remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:text(O/(k+'.md')) for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Morphogenesis — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE · HISTORICAL TEXT</p>'+md(text(O/f'before/commons/maps/{M.name}/{k}.md'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><p class="eyebrow">HALL 09 / MORPHOGENESIS</p><h1>Who connected the controls?</h1><p>Keep one specimen. Pull the point. Decide which part of the rule changes.</p><p class="note">'+str(n)+' code checks + '+str(q)+' museum checks passed.</p>'
body+=fig('assets/student-all.png','Exact tutorial code inside the museum. A keeps value 0.3; B uses 1.0 for all three parameters. The familiar black point previews and commits the recipe.')
body+='<h2>Separate the connections</h2><div class="pair">'
for name,caption in [('matched','Both begin with the same recipe, seed and sampling.'),('frequency','Change frequency alone: noise amplitude and cut keep their original values.'),('noise','Change noise amplitude alone: a modest difference from the same fixed noise field.'),('cut','Change only the cut; retain the underlying field parameters.')]:body+=fig('assets/student-'+name+'.png',caption)
body+='</div><h2>Move the desk toward the encounter</h2>'+fig('assets/desk.png','The existing control desk now stands closer to the large surface, clearing arrival and placing values beside the encounter.')
body+='<div class="pair">'+fig('assets/encounter.png','The original specimen at its opening recipe.')+fig('assets/large-at-one.png','The same specimen after changing S to 1; no simulation time has elapsed in its rule.')+'</div>'
body+='<h2>Before and after, from above</h2><div class="pair">'+fig('before-museum/above.png','Before: desk at the entrance, surface farther into the hall.')+fig('assets/with-learner-above.png','After: desk nearer the surface; temporary learner comparison behind it in the open court.')+'</div>'
body+=fig('assets/student-span-edit.png','Independent edit: double CUT_SPAN. The starting cut changes too; both consequences are predicted and tested.')+md(report)+'<p><a href="checks.json">Code checks</a> · <a href="museum/report.json">Museum checks</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('Who connected the controls?',body))
for name in ['morphogenesis_student.gd','morphogenesis_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['start_morphogenesis_lesson.py','test_morphogenesis_lesson.py','place_morphogenesis_desk.py','write_morphogenesis_lesson.py','publish_morphogenesis_lesson.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{k:sha(M/k) for k in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':read(O/'printed-hashes.json'),'unchanged_sources':{p:sha(R/p) for p in protected},'checks':[n,q],'headset':False})
write(O/'README.txt','Open index.html for museum images; parallel.html for tutorial left/reflection right. printed/ holds both full scripts plus study.tscn. Run inside the existing Endless Museum project, at floor level and unit scale, with camera/player/XRTools and GyroidFieldGenerator supplied. The generator and its marching-cubes/collision dependencies remain in the project; this is not an export of the entire Godot project. 1:mode; Up/Down:preview; Space:build; R:reset. Held PointBody height previews, trigger builds. variation/ doubles CUT_SPAN. fault-* files intentionally fail. Native/code receipts state tested scope. No physical headset or independent human learner claim.\n')
archive=O/'morphogenesis-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="morphogenesis-review.zip"',b'href="README.txt"')
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
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',text(O/'tutorial.html'),re.S)];assert len(rendered)==2
for name,s in zip(['recipe.gd','point_body.gd'],rendered):assert s==text(O/'printed'/name)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None;members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode())
   for link in parser.links:
    if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
result={'passed':True,'checks':[n,q],'local_refs':refs,'rendered_code_parity':2,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False}
dump(O/'validation.json',result);print(json.dumps(result))
