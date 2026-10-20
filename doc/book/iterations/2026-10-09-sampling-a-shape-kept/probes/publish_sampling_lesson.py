from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-sampling-a-shape-kept'
M=R/'commons/maps/SoftBodies_Playground_of_Joy'
S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
RUN=R/'ada_run/encounter_pilot'/M.name/'sampling-verified'
def read(p):return p.read_text(encoding='utf8')
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads(read(O/'checks.json'));room=json.loads(read(RUN/'report.json'))
assert code['passed'] and room['passed']
assert any(c['name']=='All planned checks completed' and c['passed'] for c in room['checks'])
for p in [O/'engine.log',RUN/'engine.log']:
 assert not any(s in read(p) for s in ['SCRIPT ERROR','Parse Error','without a physics space','Position cannot be returned'])
before=json.loads(read(O/'before/hashes.json'))
protected=[p for p in before if p.startswith(('algorithms/','commons/artifacts/','commons/soft_body/')) or p.endswith('softbodies.json')]
for p in protected:assert sha(R/p)==before[p],p
expected=json.loads(read(O/f'before/commons/maps/{M.name}/map_data.json'))
expected['layers']['interactables'][5][11]=expected['layers']['interactables'][3][15];expected['layers']['interactables'][3][15]=''
assert json.loads(read(M/'map_data.json'))==expected
expected=json.loads(read(O/'before/museum-plan.json'))
a=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console');a['cell']=[11,5];a['tile_cell']=[11,5];a['ruled']['cell']=[11,5]
assert next(x for x in json.loads(read(R/'commons/data/museum/em_plan.json'))['plans'] if x['map']==M.name)==expected
for folder in ['assets','museum','before-museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for name in ['above','entry','encounter','vessel','desk','student-comparison','student-recapture','student-step200','with-learner-above']:shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'sampling-before'/name,O/'before-museum'/name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for folder in ['printed','variation']:shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
n,q=len(code['checks']),len(room['checks']);obs=room['observations'];evidence=code['observations']
technical=read(M/'technical.md')
marker='\n## Executable snapshot lesson — 9 October 2026\n'
technical=technical.split(marker)[0].rstrip()+marker+f'''

Canonical learner source: `doc/book/studies/soft-bodies-through-the-hands/{M.name}/`.

The new host copies the custom vessel solver's local positions and face indices into a separate ArrayMesh. The old Jolt panel is not treated as exposing the same state interface. PointBody is byte-identical to hall5; the supplied solver is byte-identical to `commons/soft_body/soft_body_sim.gd`. The adapter follows the installed vessel's construction and iteration order. Native comparison at 200 steps measured maximum vertex difference {evidence['installed_difference']:.7f} m.

Host timing: one explicit 0.0166667 solver step per physics callback, automatic capture40, trigger/key1 recapture, key2 reconstructs solver and clears snapshot. The stored copy has positions, indices and step number. Previous positions, constraints, force history, collision and disk persistence are not included. Two MeshInstance3D translations stage the same local coordinate system. The independently run edit captures at step200. Normals are rebuilt for each mesh.

{n} executable checks extract the four exact tutorial blocks, run their complete program, exercise actual keyboard dispatch and synthetic XRTools, compare installed geometry, and reject following-copy, clock-only-reset and truncated-face faults. {q} museum checks cover all seven real pointer controls, floor/capsule clearance, the temporary learner host and its step200 edit. This is native desktop/synthetic-input evidence, not a physical headset or independent human learner test.

The selected hall desk moves from (15,3) to (11,5) in map_data and the corresponding museum plan row. No artifact algorithm, solver, registry or sequence order changes. The runtime learner host is mounted temporarily at map-local (15,0,14), yaw180, unit scale; it is not a permanently registered duplicate. The checked route ends inside the exit at z47.5 for this 49-row hall. Its capsule query excludes the visitor's own Walker body.

SQUEEZE maps the desk's normalized .2 setting to strength1.0; .6 maps to3.0 and0 disables it. Existing pressure feedback requests a -1..2 range; Jolt clamps negative SoftBody3D pressure to0. Numerical values in a control and physical effects should be distinguished.

Report, screenshots, printed files, independent edit and receipts: `doc/book/iterations/2026-10-09-sampling-a-shape-kept/`. Reproduce with `python tools/test_sampling_lesson.py` and `python tools/run_encounter_probe.py {M.name} --sequence softbodies --render --no-bridges --output-tag sampling-verified --probe tools/probes/sampling_room.gd`.
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
p=R/'doc/book/course/execution-plan/plan.json';stamp=p.stat().st_mtime_ns;plan=json.loads(read(p));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name)
row.update(object="The installed glass vessel's sampled surface, with the inherited PointBody as capture control.",change='Copy local positions and face indices at a declared simulation step; keep the resulting mesh while the live solver continues.',dependsOn=['SoftBodies_Obsticals_Part2','PG_Sculpted_Forms','Primitives_Polythedra'],reuses='Sampling, arrays, indexed faces, local coordinates, mesh instances and the unchanged PointBody class.',given='Prepared Endless Museum. Unchanged custom particle solver and a fully printed adapter based on the installed vessel; geometry generation and integration remain supplied.',later='No interchangeable Jolt/custom-solver claim. No collision or disk persistence in the saved mesh. The snapshot omits prior positions, constraints and force history.',checks=[f'{n} native executable checks of four exact printed files, inherited/source parity, installed geometry, independent edit, real key dispatch, synthetic XRTools and three rejected faults.',f'{q} native museum checks with real pointer controls and temporary exact program, plus eye and overhead captures.'],transfer='Change capture40 to200; predict unchanged connectivity and changed positions. Confirm live motion continues, saved state remains, and explicit capture replaces it.',carry='A shape retains selected geometric consequences, not the complete process needed to resume or explain them.',next='SoftBodies_Affect_Theory_Visualization: organic appearance and the mechanism producing it.',notes='Draft. Only selected desk relocated (15,3)->(11,5); source artifact logic unchanged. Temporary learner host at (15,0,14), yaw180. No headset or independent student validation.',summary='Meet the changing measurement on the rounded body, then the frozen glass vessel. Carry the previous lesson’s act of sampling from one number to a whole surface: use the vessel’s supplied custom solver, copy its local positions and face indices at step40, and display the result beside the continuing simulation. The inherited black PointBody triggers another capture. Reconstruct the solver to restart, then change the automatic capture to step200 and verify that connectivity stays while the selected shape changes. Carry an explicit account of what the snapshot keeps and what it cannot recover into the next hall’s organic-looking forms.')
old=next(x for x in prior['lessons'] if x['id']==M.name)
assert row['decision']==old['decision'] and row['baseline']==old['baseline']
assert [x for x in plan['lessons'] if x['id']!=M.name]==[x for x in prior['lessons'] if x['id']!=M.name]
assert p.stat().st_mtime_ns==stamp,'Concurrent curriculum change; rerun for selected-row merge.'
dump(p,plan);dump(O/'lesson-plan.json',row)
report=f'''# A shape kept

Soft Bodies **6 of 9: Playground of Joy**. The last lesson kept a height reading while a panel continued falling. This one keeps a surface while its source continues changing. Next comes the distinction between an organic appearance and its generating mechanism.

|Part|Before|Now|
|---|---|---|
|Tutorial|Mostly a description of installed controls; two assignments|Complete snapshot host, three explicit supplied files, explanation and independent edit|
|Object lineage|Stopped vessel described|Installed vessel's construction exposed; previous PointBody returns as capture control|
|New operation|Unshown process-to-mesh step|Copy positions and face indices; retain local coordinates and selected step|
|Evidence|Descriptions of settings|Exact printed program, source comparison, three rejected faulty programs and actual museum controls|
|Reflection|Measurement and frozen form, with a code fragment|What a surface keeps and leaves out; the selected stop remains visible in its caption|
|Space|Control desk blocks centre arrival|Same desk to the side at (11,5); approach and route checked|

## What the new lesson teaches

The two displayed surfaces use the same construction. The left surface is rebuilt as the solver advances. At step40, the right surface receives an independent mesh made from copied positions and triangle indices. The black PointBody is the unchanged previous class: grip it and press trigger to capture another moment. Key1 does the same; key2 reconstructs the solver and clears the copy. No object is pulled behind the reader's back through an undeclared scene reference.

The lesson uses the installed vessel's custom particle solver, whose positions are directly readable. The previous panel used Jolt. This implementation boundary is stated rather than hidden: the sampling operation carries forward, while a supplied adapter gives access to another body. Writing the sphere and integrator is not a new prerequisite. All four files remain printed and included.

At step200, the adapter's positions matched the installed vessel exactly in the native comparison (maximum difference {evidence['installed_difference']:.7f} m). Both retain330 position entries and616 triangle records. The step40 and step200 shapes differed by up to {evidence['shape_difference_40_200']:.4f} m at corresponding entries. Those numbers describe this tested recipe, not a promise that longer simulation always means more deformation.

The snapshot includes local positions, face connections and a step number. It omits previous positions, pins, springs and force history. It has no added collision and is not saved to disk. The installed glass artifact retains its existing collision skin. Display offsets move the live and copied surfaces apart without modifying the underlying data.

## Checks

**{n} executable checks and {q} museum checks passed.** Tests extract the actual visible tutorial code, compare it with the runnable files, then execute it in native Godot4.6. They verify the capture boundary, independent mesh, retained faces, local coordinates under a rotated and translated host, continued live evolution, recapture and proper reconstruction on restart. The complete step200 edit also runs.

Three complete deliberately faulty programs are rejected: the saved shape follows every later step; restart only resets the counter; the saved mesh loses most of its face indices. Keyboard input goes through Godot dispatch. Synthetic XRTools pickup and action exercise the existing PointBody interface. This tests executable claims, not a human reader's understanding.

Inside the real museum, all seven controls respond through the desktop pointer. MEASURE and FEEDBACK retain separate roles. SQUEEZE's normalized .2 input becomes strength1.0 through the existing remapping. The vessel replaces its mesh and collision skin after DURATION or GRAVITY. The student host is mounted temporarily at hall-local(15,0,14), yaw180, for captures and checks; no permanent duplicate exhibit is registered.

The first inspection confirmed the desk across arrival. It is now at(11,5). The checked outer route has {obs['route']['samples']} samples with floor support and capsule clearance, ending inside the exit of this49-row hall. The test excludes the visitor's own collision body. This verifies one path, not every passage or inter-hall transition.

The final tests contain no script, parse or missing-physics-space errors. Existing UID, registry and compatibility-renderer warnings remain. Physical headset input, Quest performance and an independent learner remain untested. Browser layout was not automated; native images, local links, displayed code and ZIP integrity are checked.

## Scope

Updated tutorial.md, final.md, the implementation note and this hall's curriculum row. Moved only this hall's existing desk in its map and museum plan. Existing artifact algorithms, particle solver and sequence order remain unchanged. Before/after text and source receipts are preserved.

Next: **SoftBodies_Affect_Theory_Visualization — what does looking alive tell us?**
'''
write(O/'REPORT.md',report)
css=re.search(r"css='''(.*?)'''",read(R/'tools/publish_soft_yield.py'),re.S)[1]
def md(s,prefix=''):
 out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
 blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
 if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
 return out
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p>ENDLESS MUSEUM · SOFT BODIES 06 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="sampling-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot captures · executable checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:read(O/(k+'.md')) for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('A shape kept — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md(read(O/f'before/commons/maps/{M.name}/{k}.md'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>A shape kept.</h1><p class="lead">One body goes on. A copy holds the moment you selected.</p><p class="note">Hall6 of9 · '+str(n)+' code checks + '+str(q)+' museum checks passed.</p>'
body+=fig('assets/student-comparison.png','Exact tutorial program inside the museum: live simulation on the left, step40 snapshot on the right. The inherited black point captures another state.')
body+='<div class="pair">'+fig('assets/student-recapture.png','The point trigger replaces the snapshot with a later state.')+fig('assets/student-step200.png','Independent edit: automatic capture at step200. The source continues afterwards.')+'</div>'
body+='<h2>The existing encounter</h2>'+fig('assets/vessel.png','The installed glass vessel and rounded-body bench remain. Their code is unchanged.')
body+='<h2>Clear the arrival</h2><div class="pair">'+fig('before-museum/entry.png','Before: desk across the centre arrival.')+fig('assets/entry.png','After: the desk sits to the side, opening the view and walking route.')+'</div>'
body+='<h2>From above</h2><div class="pair">'+fig('before-museum/above.png','Before: existing exhibits and rear structure.')+fig('assets/with-learner-above.png','After: relocated desk and temporary learner comparison in the open court.')+'</div>'
body+='<section class="report">'+md(report)+'<p><a href="checks.json">Code checks</a> · <a href="museum/report.json">Museum checks</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></section></main>'
write(O/'index.html',page('A shape kept',body))
for name in ['sampling_lesson.gd','sampling_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_sampling_lesson.py','place_sampling_desk.py','publish_sampling_lesson.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{k:sha(M/k) for k in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads(read(O/'printed-hashes.json')),'unchanged_sources':{p:sha(R/p) for p in protected},'checks':[n,q],'placement_delta':{'token':'soft_workshop_console','from':[15,3],'to':[11,5]},'learner':'temporary host, (15,0,14), yaw180, unit scale','headset':False})
write(O/'README.txt','Open index.html for native museum images; parallel.html for tutorial left/reflection right. printed/ contains the complete four-file program and its root scene. variation/ changes SAMPLE_STEP from40 to200. Add study.tscn to a clear spot in the prepared Endless Museum project (camera/player/XRTools supplied), at floor level and unit scale. Hold the point and trigger to capture; keyboard1 captures,2 restarts. No collision or disk persistence is added to the snapshot. fault-* folders intentionally fail the lesson contract. Godot4.6 tests extract the visible code from tutorial.md. No physical headset or independent learner claim.\n')
archive=O/'sampling-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="sampling-review.zip"',b'href="README.txt"')
   z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
  self.ids.extend(v for k,v in attrs if k=='id')
refs=0
for p in O.glob('*.html'):
 parser=Links();parser.feed(read(p));assert len(parser.ids)==len(set(parser.ids))
 for link in parser.links:
  if link.startswith(('http:','https:','data:')):continue
  if link.startswith('#'):assert link[1:] in parser.ids;continue
  assert (p.parent/link.split('#')[0]).exists(),(p,link)
  refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',read(O/'tutorial.html'),re.S)]
assert len(rendered)==4
for name,s in zip(['study.gd','vessel_surface.gd','point_body.gd','solver.gd'],rendered):assert s==read(O/'printed'/name)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None;members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode('utf8'))
   for link in parser.links:
    if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
result={'passed':True,'checks':[n,q],'local_refs':refs,'rendered_code_parity':4,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False}
dump(O/'validation.json',result);print(json.dumps(result))
