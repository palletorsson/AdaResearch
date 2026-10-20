from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-architecture-a-place-to-pass';M=R/'commons/maps/LSystems_Architecture';RUN=R/'ada_run/encounter_pilot/LSystems_Architecture'
def write(p,s):p.write_bytes(s.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text());before=json.loads((O/'before/hashes.json').read_text())
assert code['passed'] and room['passed']
assert not any(t in (RUN/'engine.log').read_text(encoding='utf-8',errors='replace') for t in ['SCRIPT ERROR','Parse Error'])
n=len(code['checks']);q=len(room['checks']);samples=room['observations']['route_samples']
for folder in ['assets','museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['commons/artifacts/lsystem_dungeon/lsystem_dungeon.gd','commons/maps/sequences/lsystems.json']:assert sha(R/name)==before[name]
prior_map=json.loads((O/'before/commons/maps/LSystems_Architecture/map_data.json').read_text());expected=copy.deepcopy(prior_map);expected['layers']['utilities'][37][9]='t'
assert json.loads((M/'map_data.json').read_text())==expected
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']=='LSystems_Architecture')
row.update(object='The carried PointBody controls a four-segment path with measurable passage widths and room footprints.',
change='Extend the retained reader with R records, unique addresses and an occupied-cell union. Build walls only on exposed edges, with two explicit openings.',
reuses='Unchanged replacement function and PointBody; copied dictionary state and stack; vectors, loops, arrays, dictionaries, BoxMesh and collision shapes.',
given='Prepared Endless Museum player, continuous support floor, camera, lighting and XRTools. Four complete printed files include the footprint grouping and boundary builder. Orthogonal plan, fixed 4 m strides and explicit two-door policy.',
later='Arbitrary-angle joins, general dungeon doors, structural loads, persistent edits and multiplayer occupancy remain outside this reconstruction. Nine existing works remain; only the front study carries the required lesson.',
checks=[f'{n} printed-code checks; six width/room comparisons with production; real capsule passage and stopped-entry tests; executed relocated-R rule; two faulty builders detected.',f'{q} native museum assertions including eight capture checks, six pointer buttons, XRTools supplied poses, refused changes without queued rebuild, {samples} supported outer-route samples and valid onward approach.'],
transfer='Move each R after its branch F: F[+FR][-FR]F. Predict unchanged four segments and two addresses at local x/z (+4,-4) and (-4,-4). Enable rooms and test that the entrance width is still unchanged.',
carry='A grammatical record, an occupied footprint and a collision boundary are distinct. Shared cells remove internal partitions; passage depends on a particular body.',
next='LSystems_Competition: keep records separate from occupancy; inspect what permits or refuses a proposed next growth step.',
notes='Architecture primary complete in this pass; draft decision preserved. Core dungeon interpreter unchanged. Construction pitch corrected 0.2 → 0.1 m to match advertised widths; carried hand point added; missing onward token at (9,37) restored. Author-led tests, not independent learner or headset.',
summary='Keep the four-segment plan from the existing dungeon, then give it a footprint. Record R without moving: two instructions initially share one junction. Union the corridor and optional room cells, omit internal walls and declare two main openings. The carried point changes width and switches PLAN/BUILD outside the occupied frame. Reconstruct the complete program and compare actual collision passage at 0.4 and 1.4 metres for a 0.6-metre test body. Move the two Rs after their Fs; verify that the path stays fixed while two room addresses replace one shared address. Carry the distinction between a rule, a place and the conditions of passage into Competition.')
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!='LSystems_Architecture')
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/LSystems_Architecture/technical.md').read_text(encoding='utf-8').replace('fixed 0.2 m construction grid','fixed 0.1 m construction grid').replace('exactly 14×14 cells','exactly 28×28 cells')
tech+=f'''

## Tested reconstruction — 9 October 2026

Canonical tutorial.md prints grammar.gd, footprint.gd, architecture.gd and the unchanged carried point_body.gd. The replacement function is byte-unchanged from Grammars and Curves. The reader retains copied state/last-in-first-out return, now storing local X/Z in Vector2, stepping four metres and recording R positions without movement. Its mapped records agree with the existing dungeon. The full footprint, rectangle grouping, boundary runs, meshes, colliders, controls and occupancy refusal are printed. The learner does not need named scene children or hidden mesh references.

The baseline native measurement found that a 0.2 m grid rounded the 1.4m and 2.2 m labels to 1.6 m and 2.4 m. Production PITCH is now 0.1 m; all three widths measure correctly. The room square is 28×28 cells. Six combinations of width and room option match the printed builder’s occupied cells, room cells and wall count. Rectangle coverage is tested for omissions and overlaps. A deliberately coarse grid and a builder that walls internal edges are detected as faults.

The actual student-edited program moves R after each branch’s F. Four segments are unchanged; two addresses at (4,-4) and (-4,-4) produce two separate room squares. A 0.6 m CharacterBody capsule crosses the 1.4m main stem and its junction, stops at a closed side end, and cannot enter the 0.4m version. PLAN removes these construction colliders. These tests prescribe horizontal movement and body dimensions; they do not establish headset comfort, stair stepping or universal accessibility.

ArchitectureHand places the existing PointBody class on a front rail. Local X selects width; held trigger requests BUILD/PLAN through the existing action. The fixed-frame occupation guard also covers hand changes. A refused slot is remembered, so leaving does not silently apply it. A new slot change or trigger is required. Existing six buttons remain. The core lsystem_dungeon.gd is byte-unchanged.

The baseline exit record was empty. Restored the missing onward utility t at source cell (9,37), inside the existing rear opening. All structure, authored placements and sequence order are unchanged. Nine authored works remain, including the original miniature. {samples} floor/capsule samples certify the tested outer routes; they do not certify every path through the raised rear collection. The overhead views show that older tall geometry and museum fixtures still overlap some sightlines. No general spatial cleanup is claimed.

{n} printed-program checks and {q} actual-museum checks pass, including real pointer controls, XRTools with supplied poses, refusal/no-queue behavior, width measurement, actual capsule collisions and eight native capture-camera checks. Five baseline captures are retained. No SCRIPT ERROR/Parse Error in final logs; existing UID diagnostic remains. The printed study is photographed temporarily at the same host after placing the original in PLAN and hiding it, then removed; it is not installed as a duplicate.

Tests are author-led, not an independent ghost student, physical headset or full portal journey. Report and paired texts: doc/book/iterations/2026-10-09-architecture-a-place-to-pass/index.html. Competition remains next; four of eight L-systems halls have received this reconstruction pass.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
 a=(O/'before/commons/maps/LSystems_Architecture'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
 write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# A path is not yet a passage

Architecture now continues the same tutorial lineage inside Endless Museum. The student keeps the point, replacement function and saved turtle state, then learns how a path gains width and a boundary.

## The lesson

One short sentence supplies four moves. R records a position without moving, so two room instructions initially share one address. Rectangular corridor and room footprints become occupied cells. Shared cells are kept once; only exposed edges receive walls. Two main openings are deliberate construction choices.

The full tutorial prints four runnable files, including the builder. The reflection keeps the question of which bodies a plan admits, with the implementation excerpts moved into the tutorial. The point sits beside the existing six buttons: move it for width, hold its trigger for BUILD or PLAN. Changes refuse while a visitor is inside the fixed frame and do not apply later without a fresh action.

The student’s edited rule moves R after F in each branch. The four segments remain; two separate room addresses replace the shared junction. That complete modified program is executed in the tests.

## Corrections found through reconstruction

| Advertised clear width | Before: measured | After: measured |
|---|---|---|
|0.4 m|0.4 m|0.4 m|
|1.4 m|1.6 m|1.4 m|
|2.2 m|2.4 m|2.2 m|

The old construction grid could not represent the chosen half-widths exactly. Reducing its pitch from 0.2 to 0.1 metres fixes the mismatch. The dungeon grammar and raw interpreter remain unchanged.

The onward portal was also missing: the fresh baseline returned an empty exit record. The Competition token is restored inside the existing rear opening. Structure and all nine authored placements stay fixed.

## What passed

- **{n} printed-code checks**, including six comparisons with the installed construction, exact dimensions, grouping coverage, real capsule collision, occupied-frame refusal, the student’s relocated-R edit and two deliberately faulty builders.
- **{q} museum checks**, including eight camera checks, all six pointer buttons, actual XRTools with supplied poses, no queued change after exit, the retained nine works, {samples} supported outer-route samples and valid entry/onward records.
- The same 0.6-metre test capsule passes the 1.4-metre corridor and junction, but stops at the 0.4-metre entrance. Enlarging the junction does not widen that entrance.

Five before and eight after images come from native Godot. They include the actual room from above and the exact printed reconstruction temporarily running inside it. The source tutorial, rendered code, local links and review ZIP are checked.

The overhead pictures also expose unresolved spatial work: tall retained geometry and some fixtures cross sightlines over the main study. The tested outer routes remain clear; the raised rear collection has not received a complete accessibility pass. Browser layout, headset comfort/readability, Quest performance, independent student understanding and continuous portal travel remain untested. Final native logs contain no SCRIPT ERROR or Parse Error; the existing UID diagnostic remains.

## What comes next

Competition can now give a proposed growth step conditions it must meet. We bring a precise distinction: a rule may describe a connected route while the surrounding world refuses passage. Four of the eight L-systems halls now have complete reconstructed lessons; four remain.
'''
write(O/'REPORT.md',report)
css='''*{box-sizing:border-box}body{margin:0;background:#f4f0e9;color:#252c2e;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1180px;margin:auto;padding:30px}nav{display:flex;flex-wrap:wrap;gap:20px;font:14px/1.5 system-ui}a{color:#245d60}h1{font-size:clamp(36px,5vw,66px);line-height:1.1}h2{font-size:29px;line-height:1.3;margin-top:2em}.lead{font-size:25px;max-width:800px}.eyebrow,figcaption,footer{font:14px/1.5 system-ui;color:#556066}img{width:100%;height:auto}figure{margin:28px 0}figcaption{margin-top:8px}.pair,.spread{display:grid;grid-template-columns:1fr 1fr;gap:28px}.spread{max-width:1800px}.spread article{min-width:0;background:#fffdf8;padding:20px}.spread h1{font-size:38px}article{max-width:850px;margin:auto}pre{white-space:pre;overflow:auto;background:#222c33;color:#fff1e7;padding:20px;font:13px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.86em}table{border-collapse:collapse}td,th{padding:9px;border-bottom:1px solid #ccc;text-align:left}@media(max-width:850px){.pair,.spread{grid-template-columns:1fr}header,main,footer{padding:20px}}@media print{nav{display:none}pre{white-space:pre-wrap;background:white;color:black;font-size:9px}.spread{display:block}img{max-height:65vh;object-fit:contain}}'''
def md(s):
 rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],rendered,flags=re.S)
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 04 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="architecture-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Author-led native evidence · headset and independent student review remain open.</footer></body></html>'
def fig(path,caption):return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={name:(O/(name+'.md')).read_text(encoding='utf-8') for name in ['tutorial','final']}
for name,s in texts.items():write(O/(name+'.html'),page(name,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Architecture — facing pages','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'])+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'])+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for name in ['tutorial','final']:
 changes+='<h2>'+name+'.md</h2><div class="pair"><article>'+md((O/'before/commons/maps/LSystems_Architecture'/(name+'.md')).read_text(encoding='utf-8'))+'</article><article>'+md(texts[name])+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>A path is not<br>yet a passage.</h1><p class="lead">Keep the four moves. Give them width. Ask which body can enter.</p><p>'+str(n)+' printed-code checks · '+str(q)+' museum checks · 6 comparisons with the installed builder</p>'
body+=fig('assets/inside.png','Inside the actual 1.4-metre corridor: the junction stays open while the side branches end at walls. The grammar does not specify these boundary decisions.')
body+='<div class="pair">'+fig('before-captures/built.png','Before: the advertised 1.4-metre passage was actually 1.6 metres wide.')+fig('assets/built.png','After: the construction matches the label; the carried point is added at the desk.')+'</div>'
body+=fig('assets/hand.png','Move the point to choose width. Held trigger requests BUILD or PLAN. The fixed occupation guard also applies to these hand actions.')
body+='<div class="pair">'+fig('assets/plan.png','PLAN keeps the same four centrelines without construction collision.')+fig('assets/room.png','ROOMS adds one shared square: two instructions have recorded the same junction.')+'</div>'
body+=fig('assets/narrow.png','The narrow entrance remains 0.4 metres even when the room is enabled. The0.6-metre test capsule is stopped here.')
body+='<div class="pair">'+fig('before-captures/above.png','Before, from above: the full-size study, retained raised collection and oversized companion geometry.')+fig('assets/above.png','After, from above: all nine authored works remain. The added onward portal sits in the existing rear opening. Animated companion geometry changes pose between captures.')+'</div>'
body+=fig('assets/student.png','The exact printed reconstruction, temporarily running at the same host in the museum. The original primary is placed in PLAN and hidden for this photograph, then restored.')
body+=md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('A path is not yet a passage',body))
for name in ['architecture_passage_before.gd','architecture_passage_lesson.gd','architecture_passage_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
shutil.copyfile(R/'tools/test_architecture_passage.py',O/'probes/test_architecture_passage.py')
for name in ['architecture_lesson.gd','architecture_hand.gd']:shutil.copyfile(R/'commons/artifacts/architecture_lesson'/name,O/'after'/name)
dump(O/'manifest.json',{'files':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'source_interpreter_unchanged':True,'sequence_unchanged':True,'only_map_change':'onward t at (9,37)','checks':[n,q],'production_comparisons':6,'route_samples':samples})
write(O/'README.txt','Open index.html for native museum views and parallel.html for tutorial left / reflection right. printed/ is the exact tested four-file program; variation/ is the executed moved-R exercise. Use the prepared Endless Museum project with XRTools and a clear study host. This is not an empty Godot project. Tests are author-led, with supplied controller poses and specified test-body dimensions; physical headset and independent student review remain open.\n')
archive=O/'architecture-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
   data=p.read_bytes()
   if p.suffix=='.html':data=data.replace(b'href="architecture-review.zip"',b'href="README.txt"')
   z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  for k,v in attrs:
   if k in ['href','src'] and v:self.links.append(v)
refs=0
for p in O.glob('*.html'):
 parser=Links();parser.feed(p.read_text(encoding='utf-8'))
 for value in parser.links:
  if value.startswith(('http:','https:','#','data:')):continue
  assert (p.parent/value.split('#')[0]).exists(),(p,value)
  refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf-8'),re.S)]
assert len(rendered)==4
for name,s in zip(['grammar.gd','footprint.gd','architecture.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 members=set(z.namelist())
 for name in members:
  if '/' not in name and name.endswith('.html'):
   parser=Links();parser.feed(z.read(name).decode('utf-8'))
   for v in parser.links:
    if not v.startswith(('http:','https:','#','data:')):assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_references':refs,'rendered_code_matches':4,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2)})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
