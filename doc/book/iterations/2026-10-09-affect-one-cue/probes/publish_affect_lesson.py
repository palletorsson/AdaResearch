"""Publish one verified hall, preserving other halls' work and approval state."""
from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-affect-one-cue'
M=R/'commons/maps/SoftBodies_Affect_Theory_Visualization'
S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
RUN=R/'ada_run/encounter_pilot'/M.name/'affect-final'
KEY='softbodies|softbodies affect theory visualization'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.write_bytes(s.encode())
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=read(O/'checks.json');room=read(RUN/'report.json')
assert code['passed'] and room['passed']
assert any(c['name']=='All planned checks completed' and c['passed'] for c in room['checks'])
for p in [O/'code.log',RUN/'engine.log']:
 assert not any(s in text(p) for s in ['SCRIPT ERROR','Parse Error','without a physics space','Position cannot be returned'])
hashes=read(O/'before/hashes.json')
protected=[p for p in hashes if p.startswith(('algorithms/','commons/soft_body/')) or p.endswith('softbodies.json')]
for p in protected:assert sha(R/p)==hashes[p],p
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S)
assert len(blocks)==4
for name,source in blocks:
 assert source+'\n'==text(O/'printed'/name)==text(S/name)
 assert sha(S/name)==read(O/'printed-hashes.json')[name]
for name in ['vessel_surface.gd','point_body.gd','solver.gd']:
 assert (S/name).read_bytes()==(S.parent/'SoftBodies_Playground_of_Joy'/name).read_bytes()
expected=read(O/f'before/commons/maps/{M.name}/map_data.json')
for old,new in [([15,3],[15,11]),([9,11],[15,21])]:
 cells=expected['layers']['interactables'];cells[new[1]][new[0]]=cells[old[1]][old[0]];cells[old[1]][old[0]]=''
assert read(M/'map_data.json')==expected
plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x['map']==M.name)
expected=read(O/'before/museum-plan.json')
for a in expected['artifacts']:
 a['cell']={'soft_workshop_console':[15,11],'radiolaria':[15,21]}[a['token']];a['tile_cell']=a['cell'];a['ruled']['cell']=a['cell']
assert plan==expected
for folder in ['assets','museum','before-museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['above.png','entry.png','encounter.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'affect-before'/name,O/'before-museum'/name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
n,q=len(code['checks']),len(room['checks'])

technical=f'''# What makes this look alive? — implementation

## Installed encounter

`algorithms/computationalbiology/radiolaria2/radiolaria.tscn` constructs nine forms by drawing from six families. Repeated families are possible. Its source geometry recipes are unchanged. The forms are CSG assemblies, not simulated growing organisms or deformable SoftBody3D objects. Visible CSG skins have `use_collision=false`.

The hall-specific adapter in `commons/artifacts/timing_machines/soft_workshop.gd` now raises the generator by2.2m, selects seed1337 and spacing4m, and adds nine solid low plinths plus a flat display runner. ROTATION originally turned the demo camera, whose view is inactive in the museum. The adapter now also turns each specimen about its own Y axis while that control is enabled. Other chapters do not enter this branch. The original demo camera behaviour and geometric construction algorithms remain unchanged.

The six existing pointer controls remain: ROTATION, COLOUR, EFFECTS, SEED, SPIKES, RULE. COLOUR rebuilds the forms with another palette. At the fixed seed, the tested hierarchy, transforms below each specimen root and CSG construction properties remain equal across this palette change. SEED selects1338/1339/1337. SPIKES changes the polyhedral branch probability and can alter subsequent random choices; it is not a uniform switch for every spine on every family. EFFECTS toggles the existing particles, which may take their lifetime to clear.

Map placements: desk(15,3)→(15,11), radiolaria(9,11)→(15,21). Existing hall dimensions and floor architecture remain. The desk approach and outer route have support and capsule clearance; the route turns toward the centre at z41 before entering the exit frame at z43.5. It does not cross the portal's solid side post. These are checked paths, not exhaustive navigation or inter-hall transition tests.

## Executable learner

Canonical source: `doc/book/studies/soft-bodies-through-the-hands/{M.name}/`.

Four complete files are printed in tutorial.md. study.gd is new. vessel_surface.gd, solver.gd and point_body.gd are byte-identical to the preceding Sampling lesson. The host reconstructs the same step40 surface using the same recipe and creates a shared ArrayMesh:330 stored positions and616 triangles. This is repeatable reconstruction, not a disk transfer or continuation of a previous running session. The solver runs only during initialization.

Two MeshInstance3D nodes share this mesh but receive separate materials. Left remains neutral/still. Right has three conditions: neutral/still; turn about local Z at0.7rad/s; accent colour with orientation reset. PointBody trigger or key1 cycles. Key2 restores baseline. The independent edit uses0.35rad/s. Both conditions retain all saved positions and face indices. Shared geometry is safe here because it remains unmodified; it is not a general permission to edit a resource used by multiple bodies.

The test mounts this exact learner temporarily at map-local(18,0,33), yaw180, unit scale. It is a student construction beside the existing encounter, not another permanently registered artifact. Its surface adds neither collision nor biological behaviour.

## Evidence

{n} executable code checks pass: exact visible blocks, carried-file parity, previous snapshot equivalence, isolated materials, fixed geometry, condition reset, actual keyboard dispatch, synthetic XRTools pickup/action/release and the independent speed edit. Three executing fault programs are caught: shared materials, an accumulated orientation cue, and a solver that keeps advancing.

{q} native museum checks pass, including six pointer controls, specimen rotation, fixed-seed construction comparison, temporary printed host and variation, floor/capsule queries, and retained capture camera. Native eye-level and overhead images are included. Existing UID, compatibility renderer and legacy material warnings remain; final runs contain no script/parse errors. Neither automated assertions nor screenshots establish a visitor's felt response. Physical headset comfort, Quest performance and independent student understanding remain untested.

Reproduce: `python tools/test_affect_lesson.py`, then `python tools/run_encounter_probe.py {M.name} --sequence softbodies --render --no-bridges --output-tag affect-final --probe tools/probes/affect_room.gd`.

Report, before/after texts, exact code, independent edit, deliberate faults and receipts: `doc/book/iterations/2026-10-09-affect-one-cue/`.
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)

# Synchronize just this hall in derived layout records.
layout=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
 dest=O/'before'/('runtime-' if rel.startswith('ada_run') else 'canonical-')
 dest=dest.with_name(dest.name+'layout.json')
 if not dest.exists():dump(dest,d.get('halls',{}).get(KEY))
 d['halls'][KEY]=layout
 assert {k:v for k,v in d['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,d)
p=R/'commons/data/long_museum.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
segment=next(x for x in d['segments'] if x['name']==M.name)
if not (O/'before/long-museum-segment.json').exists():dump(O/'before/long-museum-segment.json',segment)
prior=len(segment['artifacts']);segment['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a.get('rotation',0)} for a in plan['artifacts']]
delta=len(segment['artifacts'])-prior;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='softbodies')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=M.name]==[x for x in old['segments'] if x['name']!=M.name]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))

p=R/'doc/book/course/execution-plan/plan.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['lessons'] if x['id']==M.name)
row.update(object='The previous hall’s step40 captured vessel, displayed twice; the same PointBody selects one presentation cue.',change='Keep geometry fixed; change motion or colour on one copy while resetting the previous cue.',dependsOn=['SoftBodies_Playground_of_Joy','Trans_Rotation','Color_Context_Placed'],reuses='Saved local positions and indexed faces, node transforms, materials, conditionals and the unchanged PointBody.',given='Prepared Endless Museum, unchanged solver/adapter/point class. Radiolaria gallery prompts the question; the learner uses their existing sampled surface.',later='No new biological simulation. No file-persistence claim. Automated checks validate changed program state, not a universal experience of aliveness.',checks=[f'{n} executable checks of four exact printed files, inherited/source parity, keyboard dispatch, synthetic XRTools, half-speed edit and three caught fault programs.',f'{q} native museum checks including six pointer controls, actual specimen rotation, fixed-seed construction, floor/capsule clearance and temporary learner.'],transfer='Change TURN_SPEED from 0.7 to 0.35. Predict half the angle after one second while both vertex arrays, the left display and colours stay unchanged.',carry='A recorded shape can receive another presentation without another underlying process; name the observation and interpretation separately.',next='ProceduralGeneration_Reaction_Diffusion_Systems: let local exchanges change a field, then distinguish that evolving state from its display.',notes='Revised draft; review decision preserved. Museum-only rotation/staging fix, original generator/solver/order unchanged. Temporary learner host at (18,0,33), yaw180. Native desktop and synthetic XR; no physical headset or independent student claim.',summary='Meet nine generated specimens, stop their turn and remove the surrounding particles. Carry the last hall’s saved vessel into a comparison of two identical copies: the left remains still and neutral while the inherited PointBody selects motion or colour on the right. Reconstruct the same step40 recipe once, keep its shared mesh unchanged, use separate materials and remove the previous cue before applying the next. Halve the rotation rate and verify what changes and what remains. Carry the distinction between a visible cue, its implemented cause and your response into the next hall’s evolving reaction–diffusion field.')
previous=next(x for x in old['lessons'] if x['id']==M.name)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert [x for x in d['lessons'] if x['id']!=M.name]==[x for x in old['lessons'] if x['id']!=M.name]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)

report=f'''# One shape, one cue

**Soft Bodies 7/9 — What makes this look alive?** The student carries the sampled vessel from the previous hall and changes how it appears. The next hall will change a field through local exchanges.

|Part|Before|Now|
|---|---|---|
|Tutorial|An observational comparison without a runnable learner construction|Four complete visible files; one new host and three unchanged carried files|
|Object lineage|Gallery forms described|The previous step40 vessel returns twice; the same PointBody cycles conditions|
|Learning focus|Organic appearance, broadly|Keep geometry fixed; isolate one motion or colour cue; reset the previous cue|
|Reflection|Several claims overstated what the source constructs|Nine forms from six families; apparent life and implemented behaviour remain distinct|
|Room|Forms partly buried, clustered near arrival|Raised specimens, nine low numbered plinths, a 4m grid and clear approach|
|ROTATION|Moved the artifact’s inactive demo camera|Also turns the specimens visible from the museum’s player camera|
|Palette comparison|Initial seed was unpinned|Seed1337 gives a repeatable construction; palette change tested separately|

## What carries forward

The previous hall taught how to retain local positions and their face indices. This lesson uses that retained geometry. It reconstructs the same step40 recipe once at startup, shares the resulting mesh between two displays, and gives each display its own material. It does not silently load a previous play session. All three carried source files are unchanged and printed for completeness; the reader can reuse them.

The left copy remains still and neutral. The point trigger or key1 selects a condition for the right: still, turning, or coloured. Before applying a condition, the script clears the earlier orientation and colour. Key2 restores baseline. The independent edit halves the rotation rate. The student therefore works with a specific, testable comparison without taking on another procedural generator.

The reflective text asks what resemblance invites us to infer, whether knowing a construction ends our attachment, and which familiar signs make a body easier to recognise. It keeps those questions separate from claims of sensation or biological development. A code assertion can confirm that only one material changed. It cannot confirm what every visitor felt.

## Inside the museum

The source audit found that ROTATION acted on a camera which the museum does not use. The hall adapter now turns the actual specimen nodes. The original geometric recipes remain unchanged. Nine forms are drawn from six families; the display can include repeated families. Their visible skins have no collision, unlike the solid plinths below them.

The generator moves from cell(9,11) to(15,21), rises2.2m and uses spacing4m. The desk moves from(15,3) to(15,11). A pale runner marks the court; numbered dark plinths distinguish its nine positions. The overhead view shows a clear outside route. The checked approach to the exit turns toward its centre before the solid side post.

The two-copy learner is mounted temporarily at(18,0,33), yaw180, for the tests and images. It is the construction the student adds beside the encounter, not a new permanent duplicate exhibit. Both the installed gallery and the learner program are captured in the real museum.

## Evidence and limits

**{n} code checks and {q} native museum checks passed.** Exact printed code was extracted and executed in Godot 4.6/Jolt. Tests cover the 330 retained positions and 616 triangles, separate materials, reset between cues, saved state, actual keyboard dispatch, inherited synthetic XRTools pickup/action/release, and a complete half-speed variation. Three executing faulty programs are caught: shared materials, an orientation left over from the previous cue, and a solver that keeps changing the surface.

All six installed desk controls respond to the actual desktop pointer. ROTATION stops and restarts specimen motion. The fixed-seed palette switch preserves the tested construction hierarchy and CSG properties. The outer route has {room['observations']['route']['samples']} support/clearance samples. Initial checks caught a typed-variable error in the new adapter and a test route that crossed the exit’s solid side post; both were corrected before the final run.

These checks do not establish physical headset comfort, Quest performance or independent student understanding. Existing UID, compatibility-renderer and legacy-material warnings remain; the final runs have no script/parse errors. Browser layout has not been automated. The report verifies local links, exact rendered code, before/after images and the review ZIP.

Next: **Reaction–diffusion — a field that keeps changing through local exchanges.**
'''
write(O/'REPORT.md',report)
css=re.search(r"css='''(.*?)'''",text(R/'tools/publish_sampling_examples.py'),re.S)[1]
def md(s,prefix=''):
 out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
 blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
 if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
 return out
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">ENDLESS MUSEUM · SOFT BODIES07 /09 ·9 OCTOBER2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="affect-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum captures · exact printed code · physical headset and independent learner assessment remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:text(O/(k+'.md')) for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('One shape, one cue — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md(text(O/f'before/commons/maps/{M.name}/{k}.md'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><p class="eyebrow">HALL07 / APPEARANCE AND MECHANISM</p><h1>One shape, one cue.</h1><p>The surface you kept returns. Change its presence while holding its geometry fixed.</p><p class="note">'+str(n)+' code checks + '+str(q)+' museum checks passed.</p>'
body+=fig('assets/court.png','The existing forms, raised and spaced in a nine-position court. Native Godot capture.')
body+='<h2>The student’s comparison</h2><div class="pair">'+fig('assets/student-baseline.png','Exact printed program, temporarily placed in the museum. Same saved geometry; separate materials.')+fig('assets/student-turn.png','The point trigger selects motion. Only the right node turns; its saved positions stay unchanged.')+'</div>'
body+=fig('assets/student-colour.png','Next condition: only the right colour changes. The previous turn is reset.')
body+='<h2>Before and after, from above</h2><div class="pair">'+fig('before-museum/above.png','Before: specimens clustered near the entrance and partly inside the floor.')+fig('assets/with-learner-above.png','After: the central court and temporary learner comparison. An open route runs around them.')+'</div>'
body+='<h2>At the controls</h2><div class="pair">'+fig('assets/desk.png','The existing six controls. ROTATION now turns the specimens; the construction seed starts fixed.')+fig('assets/student-half-speed.png','Independent code edit:0.35rad/s produces half the angle after one second.')+'</div>'
body+=md(report)+'<p><a href="checks.json">Code checks</a> · <a href="museum/report.json">Museum checks</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('One shape, one cue',body))
for name in ['affect_student.gd','affect_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_affect_lesson.py','place_affect_court.py','write_affect_lesson.py','publish_affect_lesson.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
shutil.copyfile(R/'commons/artifacts/timing_machines/soft_workshop.gd',O/'after/soft_workshop.gd')
dump(O/'manifest.json',{'canonical':{k:sha(M/k) for k in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':read(O/'printed-hashes.json'),'unchanged_sources':{p:sha(R/p) for p in protected},'adapter':sha(R/'commons/artifacts/timing_machines/soft_workshop.gd'),'checks':[n,q],'headset':False})
write(O/'README.txt','Open index.html for native museum images; parallel.html for tutorial left/reflection right. printed/ contains the four-file program and root scene. Add study.tscn in a clear place in the existing Endless Museum project, with Godot4.6/XRTools/camera/player supplied. The solver reconstructs the previous hall step40 recipe once; this is not loading a prior play session. Point trigger or key1 cycles baseline, motion, colour; key2 restores baseline. variation/ halves TURN_SPEED. fault-* folders intentionally violate the contract. No collision is added to the learner surfaces. Read checks.json and museum/report.json for actual scope. No physical headset or independent student claim.\n')
archive=O/'affect-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="affect-review.zip"',b'href="README.txt"')
   z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
  self.ids.extend(v for k,v in attrs if k=='id')
refs=0
for p in O.glob('*.html'):
 parser=Links();parser.feed(text(p));assert len(parser.ids)==len(set(parser.ids))
 for link in parser.links:
  if link.startswith(('http:','https:','data:')):continue
  if link.startswith('#'):assert link[1:] in parser.ids;continue
  assert (p.parent/link.split('#')[0]).exists(),(p,link)
  refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',text(O/'tutorial.html'),re.S)]
assert len(rendered)==4
for name,s in zip(['study.gd','vessel_surface.gd','point_body.gd','solver.gd'],rendered):assert s==text(O/'printed'/name)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None;members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode())
   for link in parser.links:
    if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
result={'passed':True,'checks':[n,q],'local_refs':refs,'rendered_code_parity':4,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False}
dump(O/'validation.json',result);print(json.dumps(result))
