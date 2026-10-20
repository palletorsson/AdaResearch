from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-contact-the-same-start'
M=R/'commons/maps/SoftBodies_Obsticals_Part2'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals_Part2'
RUN=R/'ada_run/encounter_pilot/SoftBodies_Obsticals_Part2/contact-fixed'
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def read(p):return p.read_text(encoding='utf8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads(read(O/'checks.json'));room=json.loads(read(RUN/'report.json'))
assert code['passed'] and room['passed']
assert any(c['name']=='All planned checks completed' and c['passed'] for c in room['checks'])
for p in [O/'engine.log',RUN/'engine.log']:
 log=read(p)
 assert not any(s in log for s in ['SCRIPT ERROR','Parse Error','without a physics space','Index -1 of pinned vertex','Position cannot be returned'])
baseline=json.loads(read(O/'before/hashes.json'))
changed_control='commons/artifacts/timing_machines/soft_workshop.gd'
protected=[p for p in baseline if (p.startswith(('algorithms/','commons/artifacts/')) or p.endswith('softbodies.json')) and p!=changed_control]
for p in protected:assert sha(R/p)==baseline[p],p
before=json.loads(read(O/f'before/commons/maps/{M.name}/map_data.json'));expected=copy.deepcopy(before)
expected['layers']['interactables'][5][11]=expected['layers']['interactables'][3][15];expected['layers']['interactables'][3][15]=''
assert json.loads(read(M/'map_data.json'))==expected
expected=json.loads(read(O/'before/museum-plan.json'))
a=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console');a['cell']=[11,5];a['tile_cell']=[11,5];a['ruled']['cell']=[11,5]
current=json.loads(read(R/'commons/data/museum/em_plan.json'))
assert next(x for x in current['plans'] if x['map']==M.name)==expected
for folder in ['assets','museum','diagnostic-museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for name in ['above','entry','gallery','desk','student-drop','student-reading','student-interrupted','student-equal-damping','with-learner-above']:
 shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['report.json','engine.log','source_manifest.json']:
 shutil.copyfile(RUN/name,O/'museum'/name)
 shutil.copyfile(RUN.parent/'contact-after'/name,O/'diagnostic-museum'/name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
for folder in ['printed','variation']:shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
control_before=read(O/'before'/changed_control);control_after=read(R/changed_control)
write(O/'after/soft_workshop.gd',control_after)
write(O/'control-fix.diff',''.join(difflib.unified_diff(control_before.splitlines(True),control_after.splitlines(True),fromfile='before/soft_workshop.gd',tofile='after/soft_workshop.gd')))
n,q=len(code['checks']),len(room['checks']);obs=room['observations']
p=R/'doc/book/course/execution-plan/plan.json';stamp=p.stat().st_mtime_ns;plan=json.loads(read(p));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
 object='Two copies of the pressure panel fall onto two copies of the inherited black PointBody.',
 change='Release both panels, rotate them horizontal and vary only damping. Reconstruct the panels to replay; keep one timed height span.',
 dependsOn=['SoftBodies_Obsticals','SoftBodies_Cloth_Physics'],
 reuses='Unchanged pressure panel and PointBody classes; arrays of cases, dictionaries, loops, time accumulation, local/world positions, grip and trigger.',
 given='Existing Endless Museum player, camera, floor, XRTools and Jolt. Twelve gallery encounters remain the wider field.',
 later='Do not teach all gallery shapes or infer calibrated materials from names. No deterministic cross-machine physics claim. Detailed sampling belongs to the next hall.',
 checks=[f'{n} native checks of printed code and hold regression: two-case recipe, timed sample, retained readings, actual contact, rebuild, hand interruption, independent edit and three faulty programs.',f'{q} real museum checks: six pointer controls, corrected hold, keyboard input, synthetic XRTools, original gallery, temporary learner host and supported outer route.'],
 transfer='Set B damping .6 to .1. Predict matching recipes; compare results from fresh runs without concealing variation.',
 carry='A repeated recipe is not an erased history. A measured extent is one observation, not the whole responding body.',
 next='SoftBodies_Playground_of_Joy: what a chosen measurement or stopped shape keeps from an event.',
 notes='Draft. Three complete files printed. Hall desk moved (15,3)->(11,5); gallery HOLD now uses only referenced mesh entries and fixed attachments, restores original pins and clears hold before rebuild. Learner temporarily at (23,0,26), yaw180; no permanent duplicate. No headset/independent learner claim.',
 summary='Meet twelve different body/contact cases, then reuse the previous panel and black PointBody for a smaller comparison. Release both panels from the same height over matching points and change only damping. At a declared time keep their vertical extents while the bodies continue. Moving a point interrupts the comparison; trigger and release rebuild fresh panels while retaining the points. Set both damping values equal and compare repeated outcomes. Carry the difference between a controlled recipe, an unfolding event and a selected observation into the next room.')
assert row['decision']==decision and row['baseline']==next(x for x in prior['lessons'] if x['id']==M.name)['baseline']
assert [x for x in plan['lessons'] if x['id']!=M.name]==[x for x in prior['lessons'] if x['id']!=M.name]
assert p.stat().st_mtime_ns==stamp,'Concurrent plan edit; rerun to merge selected row.'
dump(p,plan);dump(O/'lesson-plan.json',row)
isolated=code['observations'];old_room=json.loads(read(O/'diagnostic-museum/report.json'))
report=f'''# Same fall, another encounter

Soft Bodies **5 of 9**. The previous hall distinguished a pressure command from a responding surface. This hall makes a smaller comparison: reuse that panel and PointBody, remove the pins, and change one coefficient. The next hall will examine what a selected reading retains.

|Part|Before|Now|
|---|---|---|
|Tutorial|Three setting assignments; no full construction|Complete host plus the two unchanged inherited classes|
|Comparison|Select two gallery cells, often unlike in several ways|Two matching drops; damping .1 and .6|
|Replay|Seed discussion|Reconstruct panels, retain points, clear readings and restart time|
|Hand interaction|Installed gallery controls|Holding a point interrupts the trial; trigger queues a replay until release|
|Transfer|Open observation|Set both damping values to .1; compare fresh trials|
|Reflection|Names, folds and the array|What a comparison can establish; the hand as an added condition; a kept number and a changing body|
|Room|Desk in centre arrival|Same desk at (11,5), clear entrance and supported route|
|HOLD control|Invalid pins and a surface that kept moving|Referenced mesh entries attached in place; original attachments restored on release|

## What the learner carries

`pressure_panel.gd` and `point_body.gd` are byte-identical to the previous hall. The host removes the panel's perimeter pins and turns it horizontal. Both copies retain the same mesh, mass, stiffness, pressure, material and solver setting. Two matching black points remain grabbable contact objects. They are instances of the carried class, not a claim that one object is literally in two places.

At the first physics step reaching 1.5 seconds, the host stores maximum minus minimum local vertex height. That is a vertical extent, not volume or a material diagnosis. The values remain while the surfaces continue. A held point cancels the measurement; a queued replay waits for both points to be released. Keyboard **1** follows the same path. R is avoided because the existing gallery uses it to reload the scene.

## Native evidence

**{n} code/control checks and {q} museum checks passed.** The code test extracts all three visible blocks from tutorial.md, checks source parity, and runs them under Godot 4.6 with Jolt. It also runs the complete equal-damping edit. Behavioural checks reject three faulty hosts: clock-only reset, a hidden mass change and measuring through a hand interruption.

The tests verify real falling vertices, local/world conversion under a translated and rotated parent, retained point identity, replaced panel identity, original pin restoration and actual contact. Removing the point collider from an otherwise matching drop changed the sampled geometry by up to {isolated['contact_difference']:.3f} m in the paired native fixture. The solver continues after a reading is kept.

|Run|A height (m)|B height (m)|Damping|
|---|---:|---:|---|
|Isolated printed program|{isolated['native_heights'][0]:.4f}|{isolated['native_heights'][1]:.4f}|.1 / .6|
|Isolated independent edit|{isolated['equal_damping_heights'][0]:.4f}|{isolated['equal_damping_heights'][1]:.4f}|.1 / .1|
|Inside the museum|{obs['learner_heights'][0]:.4f}|{obs['learner_heights'][1]:.4f}|.1 / .6|
|Museum independent edit|{obs['equal_damping_heights'][0]:.4f}|{obs['equal_damping_heights'][1]:.4f}|.1 / .1|

The equal settings did not produce equal heights in every fixture. These observations are retained, rather than replaced with a promise of deterministic replay. The tests establish the declared construction and operation; they do not establish that damping alone explains every resulting fold. Contact sensitivity and numerical conditions require further experiments if that stronger claim is wanted.

## A repair found through use

The first real pointer test found invalid Jolt pin indices when HOLD visited unused mesh entries. The first specimen also moved {old_room['observations']['hold']['motion']:.3f} m during the hold observation. The repaired control uses only indices referenced by the mesh and attaches the current points to a fixed anchor. RELEASE restores the original pin indices, attachment paths and offsets. Replaying or switching groups clears the old hold first. The repaired native hold drift measured {obs['hold']['motion']:.6f} m; regression checks also cover an existing attachment and repeated HOLD.

This follows the engine's distinction between mesh entries and physics vertices, and its spatial-attachment mechanism. [Godot 4.6 Jolt source](https://github.com/godotengine/godot/blob/4.6-stable/modules/jolt_physics/objects/jolt_soft_body_3d.cpp), [SoftBody3D attachment source](https://github.com/godotengine/godot/blob/4.6-stable/scene/3d/physics/soft_body_3d.cpp).

## Source precision

The installed part-two scene runs the shared `softbody_test_gallery.gd`; it has twelve cases, three columns and four-metre spacing. The lesson disables added coefficient jitter, respawning and the root callback that performs ongoing deflation. All twelve bodies report precision7. Vacuum's zero pressure repeats the default; Caving Sphere requests negative pressure but the engine reports zero. Names cannot establish a physical phenomenon by themselves.

## Space and review scope

The entrance obstruction was the existing desk. It is moved from (15,3) to (11,5). The native probe checks its reachable controls and {obs['route']['samples']} quarter-metre samples along an outer route with floor support and capsule clearance. The first proposed crossing intersected a stick's collision body; the final path passes ahead of it. This checks one route, not every possible path through moving specimens.

The learner pair is temporarily mounted at hall-local (23,0,26), yaw180, unit scale, in the actual museum. Screenshots include the encounter, trial, retained reading, hand interruption, independent edit and hall from above. The source gallery, exhibits and sequence order are retained; no permanent duplicate tutorial exhibit is registered.

The final runs contain no script, parse, missing-space or invalid-pin errors. Existing UID and compatibility-renderer warnings remain in the logs. Input uses the real desktop pointer and synthetic XRTools controllers; physical headset input, Quest performance and an independent student's understanding remain untested. The HTML's links and displayed code are checked; browser layout was not automated.

Next: **SoftBodies_Playground_of_Joy — the reading and the event.**
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
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p>ENDLESS MUSEUM · SOFT BODIES 05 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="contact-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot captures · executable checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:read(O/(k+'.md')) for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Same fall — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md(read(O/f'before/commons/maps/{M.name}/{k}.md'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>Same fall.<br>Another encounter.</h1><p class="lead">Keep the construction. Change one setting. Watch what the comparison can tell you.</p><p class="note">The same panel and PointBody classes · '+str(n)+' code/control checks + '+str(q)+' museum checks passed.</p>'
body+='<div class="pair">'+fig('assets/student-drop.png','A fresh drop: two matching panels, two black points, damping .1 and .6.')+fig('assets/student-reading.png','The readings stay on the captions while the surfaces continue changing.')+'</div>'
body+='<div class="pair">'+fig('assets/student-interrupted.png','A hand enters the experiment. The readings clear; replay waits for release.')+fig('assets/student-equal-damping.png','Independent edit: both damping coefficients are .1. The complete modified program runs in the museum.')+'</div>'
body+='<h2>The encounter remains wider than the lesson</h2>'+fig('assets/gallery.png','The existing twelve-case gallery. Shape, contact and coefficients vary across its cells.')
body+='<h2>Clear the arrival</h2><div class="pair">'+fig('before-museum/entry.png','Before: the desk stood across centre arrival.')+fig('assets/entry.png','After: the desk is to the side; the gallery comes into view.')+'</div>'
body+='<h2>From above</h2><div class="pair">'+fig('before-museum/above.png','Before: gallery and retained rear structure.')+fig('assets/with-learner-above.png','After: clear arrival and the temporary learner pair beside the gallery.')+'</div>'
body+='<section class="report">'+md(report)+'<p><a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="control-fix.diff">HOLD repair</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></section></main>'
write(O/'index.html',page('Same fall, another encounter',body))
for name in ['contact_lesson.gd','contact_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_contact_lesson.py','place_contact_desk.py','publish_contact_lesson.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{k:sha(M/k) for k in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads(read(O/'printed-hashes.json')),'unchanged_sources':{p:sha(R/p) for p in protected},'control_after':sha(R/changed_control),'inherited':['pressure_panel.gd','point_body.gd'],'checks':[n,q],'placement_delta':{'token':'soft_workshop_console','from':[15,3],'to':[11,5]},'learner':'temporary host at (23,0,26), yaw180, unit scale','headset':False})
write(O/'README.txt','Open index.html for museum images; parallel.html for tutorial left/reflection right. printed/ is the complete three-file program; variation/ changes B damping to .1. Instantiate study.tscn in the prepared Endless Museum, with floor/player/camera/XRTools/Jolt supplied. Key1 replays. Grip interrupts; trigger and release replays. fault-* folders intentionally contain broken examples. diagnostic-museum records the initial HOLD failure; museum records the repaired passing run. Hall 5 of 9. No physical headset or independent learner claim.\n')
archive=O/'contact-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="contact-review.zip"',b'href="README.txt"')
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
assert len(rendered)==3
for name,s in zip(['study.gd','pressure_panel.gd','point_body.gd'],rendered):assert s==read(O/'printed'/name)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None;members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode('utf8'))
   for link in parser.links:
    if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
result={'passed':True,'checks':[n,q],'local_refs':refs,'rendered_code_parity':3,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False}
dump(O/'validation.json',result);print(json.dumps(result))
