"""Publish the third L-systems hall's scoped texts and native evidence."""
from pathlib import Path
from html.parser import HTMLParser
import copy, difflib, hashlib, html, json, re, shutil, zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-curves-one-sentence-three-readers'
M=R/'commons/maps/LSystems_Grammars_And_Curves'
RUN=R/'ada_run/encounter_pilot/LSystems_Grammars_And_Curves'
def write(p,s):p.write_bytes(s.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text())
assert code['passed'] and room['passed']
assert not any(t in (RUN/'engine.log').read_text(encoding='utf-8',errors='replace') for t in ['SCRIPT ERROR','Parse Error'])
n=len(code['checks']);q=len(room['checks']);samples=room['observations']['route_samples']
for folder in ['museum','after','assets','probes']:(O/folder).mkdir(exist_ok=True)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
shutil.copyfile(R/'doc/book/figures/lsystems/believing-turtle-reflection.png',O/'assets/believing-turtle-reflection.png')
before=json.loads((O/'before/hashes.json').read_text())
for path in ['commons/artifacts/the_believing_turtle/the_believing_turtle.gd','commons/maps/sequences/lsystems.json','commons/maps/LSystems_Grammars_And_Curves/map_data.json']:
    assert sha(R/path)==before[path],path
marker='<!-- study-spine:tube_painting -->'
assert (M/'tutorial.md').read_text(encoding='utf-8').split(marker,1)[1]==(O/'before/commons/maps/LSystems_Grammars_And_Curves/tutorial.md').read_text(encoding='utf-8').split(marker,1)[1]
assert (M/'final.md').read_text(encoding='utf-8').split(marker,1)[1]==(O/'before/commons/maps/LSystems_Grammars_And_Curves/final.md').read_text(encoding='utf-8').split(marker,1)[1]
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']=='LSystems_Grammars_And_Curves')
row.update(
object='The carried PointBody chooses a turn angle and a direction mapping beside three readers of one sentence.',
change='Introduce direction as a returned value distinct from stored heading. Compare a fixed reference, a changed angle and exchanged x/y components.',
reuses='Growth’s copied-state stack; byte-unchanged replacement function, PointBody and LineSkin. Local hand position, held action, dictionaries, arrays, loops and vector turns.',
given='Existing Endless Museum player, camera, lighting and XRTools. Four complete printed files create the learner point, three drawings and labels on an empty unit-scale study host. Fixed stride 0.32 m and positive-Z plus-turn are explicit changes from Growth.',
later='Tube, cable, connected forms, synth and canopy notes remain as optional existing applications. No automatic transfer of these reader paths into the tube workbench is implemented or claimed. Those applications were not revalidated by the primary lesson tests.',
checks=[f'{n} printed-file assertions; twelve comparisons covering {code["production_frames"]} production frames and raw endpoints; executed rotation edit and rejected heading-mutation fault.',f'{q} native hall assertions including six desktop controls, actual XRTools with supplied poses, 216 rendered cylinder endpoint pairs, seven retained authored works, {samples} supported route samples and eight captures.'],
transfer='Change only sideways direction from (y,x,0) to (-y,x,0). Predict the first step left, then verify a 90-degree rotation of every endpoint while stored headings and sentence remain unchanged. Two applications reverse the vector; four restore it.',
carry='A symbol, logical heading, interpreted step and displayed position are distinct. Change one mapping, identify the relations it preserves, and compare in common metres.',
next='LSystems_Architecture: give interpreted steps width and consider paths as spaces for a body. The existing tube bay anticipates that operation without silently changing this lesson’s object.',
notes='Primary complete in this pass; draft decision retained. Core interpreter, map and sequence byte-unchanged. Hand adapter added and rotated cylinder local-Y scaling repaired. Author-led tests, not independent student, physical headset, Quest performance or continuous portal traversal.',
summary='At the three-reader desk, carry Growth’s sentence, stack and dark point. Keep the green reference, move the point to change the middle reader’s angle, and use its held trigger to exchange the blue drawing direction’s x/y components. Distinguish stored heading from the vector returned for movement; hold sentence, stride and display scale fixed. Reconstruct this relation with four complete files, declaring the fixed-stride and plus-turn changes from Growth. Change the mapping to (-y,x,0), predict rotation rather than reflection, and run the modified program. Carry that separation between instructions and their spatial consequences towards Architecture; the existing tube bay remains an optional application.')
assert all(a==b for a,b in zip(old['lessons'],plan['lessons']) if a['id']!='LSystems_Grammars_And_Curves')
assert all(old[k]==plan[k] for k in old if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/LSystems_Grammars_And_Curves/technical.md').read_text(encoding='utf-8')
tech+=f'''

## Three-reader reconstruction — 9 October 2026

The primary tutorial now prints four complete files. grammar.gd retains Growth’s rewrite function, copied-state stack and bracket preflight. Its direction function separates the stored unit-vector heading from the displacement returned for F. This hall deliberately uses fixed 0.32 m strides, fixed per-reader angles, a positive-Z plus-turn and the five-symbol F+-[] alphabet. These differ from Growth and are declared in the lesson. Twelve combinations of angle 25/45/90, forward/exchanged direction and generation 1/2 match the existing scalar-heading interpreter: all {code['production_frames']} frames and raw segment endpoints. PointBody and LineSkin are byte-identical to Growth. The actual edited program changes the swap to (-y,x,0); the test checks rotation of the whole path and detects a deliberately broken implementation that mutates heading during F.

InterpreterHand adds the carried sphere on a front rail. Local X chooses 25/45/90 degrees for the middle reading; held action calls the existing READ F action on the blue reader. Release parks the point. All six nearby controls remain. The production adapter’s rebuild still regenerates the same sentence before interpreting it; its contents, generation and cursor remain unchanged on angle/direction changes. The compact learner’s reinterpret uses its stored sentence directly. These are equivalent lesson results, not identical call graphs.

The core the_believing_turtle.gd, map_data.json and sequence JSON are byte-unchanged. InterpreterLesson now scales the rotated cylinder basis’s local Y column. The old Basis.scaled(Vector3(1,length,1)) changed world-axis components and made oblique cylinders miss their recorded endpoints. The native probe verifies both ends of all 216 cylinders across three readers and two generations.

{n} printed-program checks and {q} museum assertions pass. The latter include six pointer controls, actual XRTools pickup/action/release with supplied poses, seven retained authored works, {samples} supported capsule samples, nonempty valid portal approaches and eight native captures. Five baseline images are preserved. The initial standing point failed the 0.85 m reach check; moving the supported stance 15 cm closer to the rail passes. The first planned route cut through an existing decorative plinth near the rear opening; the final route passes beside it. No map placement was altered. Failed first-room receipt retained.

The original tube-bay tutorial and reflection blocks are retained verbatim after their marker. Their larger application scope is optional and not covered by the new reader tests; no automatic path handoff is claimed. The overhead images show the paired comparison, retained middle studies and rear canopy; some older curve geometry extends beyond its enclosure and existing labels remain dense. These are visible future spatial work, not resolved by this pass. The exact printed reconstruction is photographed temporarily in the actual hall, hiding the primary only for that image, then restoring it.

No SCRIPT ERROR or Parse Error appears in the final native logs. An existing unresolved-UID diagnostic remains. Tests are author-led; physical headset reach/readability, Quest performance, independent student understanding and full portal traversal remain untested. Report: doc/book/iterations/2026-10-09-curves-one-sentence-three-readers/index.html.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
    a=(O/'before/commons/maps/LSystems_Grammars_And_Curves'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
    write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# One sentence, three readers

The third L-systems hall carries the sentence and branch memory into a new question: what operation does an instruction permit? The tutorial reconstructs the existing three-reader comparison. The reflective text stays with its consequences.

## What the learner adds

One function stands between a heading and a movement. The green reader keeps its 25-degree turn; the middle reader changes angle; the blue reader can exchange x and y when it draws. All use the same sentence, cursor and 0.32-metre stride. The carried PointBody selects the middle angle by position and switches the blue mapping with its held trigger.

The lesson names what changes from Growth: a fixed stride, fixed angles and the opposite plus-turn convention used by this artifact. Position and heading remain in the saved state; length and angle no longer vary on branch entry. The replacement function and two object helpers are unchanged. The tutorial prints all four required files and explains their connections.

The student’s source edit changes (y,x,0) into (-y,x,0). The result rotates rather than reflects. Its first step points left; its stored heading still points up. This edit is executed as a separate program, not merely suggested in prose. A deliberately incorrect version that changes the heading itself is rejected by the tests.

## What changed in the museum

- The familiar sphere and an angle rail now sit immediately in front of the six-button desk.
- Oblique cylinders now join the endpoints the interpreter actually calculated. The former world-axis scaling made the drawing visibly fragment.
- Seven authored works, the room layout and its entry/onward tokens retain their positions. The source interpreter and sequence remain byte-unchanged.

From above, the room reads as a large comparison at the entrance, a smaller collection behind it, then the tube workshop and pink canopy. The first encounter is the required lesson. The older sweep, network, sound-patch and canopy notes remain intact as optional applications. Their existence does not require every visitor to learn them at once. This pass does not implement an automatic transfer from the turtle into those paths.

The overhead view also keeps spatial problems visible: some older curve geometry extends beyond its enclosure and the companion controls have dense labels. Those need a later spatial pass. The primary desk and route are usable in the automated checks; this is not a claim that the entire hall is perfected.

## Evidence and limits

{n} native checks execute code extracted exactly from tutorial.md. Twelve source comparisons cover {code['production_frames']} interpreter frames and all segment endpoints. The actual student edit, stack restoration, bracket rejection, reflection, rotation, constant strides and real XRTools pickup/action/release under supplied controller poses pass.

{q} museum assertions pass, including camera checks for eight new captures. Tests verify all 216 rendered cylinders across both generations, six nearby pointer controls, the point binding, seven authored placements and {samples} supported capsule positions along routes through the three spaces. Entry and onward portal records are nonempty and valid. Five before images provide the visual baseline.

The first room test failed because its stance was too far from the point and its route crossed an existing plinth. A closer clear stance and a route beside the plinth pass; the first receipt remains in the package. No room geometry was moved to obtain that result.

These are author-led reconstruction and integration tests. They do not establish independent learner understanding, physical headset comfort/readability, Quest performance or a continuous portal journey. The existing unresolved-UID diagnostic remains; final logs have no SCRIPT ERROR or Parse Error. Native images were inspected. HTML code, links and archive contents are checked; browser layout was not previewed.

## Next: Architecture

Grammar Lab gave the sentence a rule. Growth gave the reader a return. This hall separates the instruction from its spatial interpretation. Architecture can now ask what happens when a step has width and someone must find a way through it.

Three of the eight halls have received this complete reconstruction pass. Five remain.
'''
write(O/'REPORT.md',report)
css='''*{box-sizing:border-box}body{margin:0;background:#f4f0e9;color:#252c2e;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1180px;margin:auto;padding:30px}nav{display:flex;flex-wrap:wrap;gap:20px;font:14px/1.5 system-ui}a{color:#245d60}h1{font-size:clamp(36px,5vw,66px);line-height:1.1}h2{font-size:29px;line-height:1.3;margin-top:2em}.lead{font-size:25px;max-width:800px}.eyebrow,figcaption,footer{font:14px/1.5 system-ui;color:#556066}img{width:100%;height:auto}figure{margin:28px 0}figcaption{margin-top:8px}.pair,.spread{display:grid;grid-template-columns:1fr 1fr;gap:28px}.spread{max-width:1800px}.spread article{min-width:0;background:#fffdf8;padding:20px}.spread h1{font-size:38px}article{max-width:850px;margin:auto}pre{white-space:pre;overflow:auto;background:#222c33;color:#fff1e7;padding:20px;font:13px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.86em}table{border-collapse:collapse;font-size:.85em}td,th{padding:9px;border-bottom:1px solid #ccc;text-align:left}summary{cursor:pointer;padding:16px;border:1px solid #bbb}@media(max-width:850px){.pair,.spread{grid-template-columns:1fr}header,main,footer{padding:20px}}@media print{nav{display:none}pre{white-space:pre-wrap;background:white;color:black;font-size:9px}.spread{display:block}img{max-height:65vh;object-fit:contain}}'''
def md(s):
    s=s.replace('/book-images/figures/lsystems/believing-turtle-reflection.png','assets/believing-turtle-reflection.png')
    s=s.replace('](/book-review/','](http://localhost:3003/book-review/')
    rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],rendered,flags=re.S)
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 03 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="curves-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · physical headset and independent student review remain open.</footer></body></html>'
def fig(file,caption):return '<figure><img loading="lazy" src="'+file+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for name,title in [('tutorial','Tutorial'),('final','Reflection')]:
    write(O/(name+'.html'),page(title,'<main><article>'+md((O/(name+'.md')).read_text(encoding='utf-8'))+'</article></main>'))
write(O/'parallel.html',page('Three readers — facing pages','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md((O/'tutorial.md').read_text(encoding='utf-8'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md((O/'final.md').read_text(encoding='utf-8'))+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for name in ['tutorial.md','final.md']:
    changes+='<h2>'+name+'</h2><div class="pair"><article><p class="eyebrow">Before</p>'+md((O/'before/commons/maps/LSystems_Grammars_And_Curves'/name).read_text(encoding='utf-8'))+'</article><article><p class="eyebrow">After</p>'+md((O/name).read_text(encoding='utf-8'))+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><p class="eyebrow">Grammars and Curves · interpretation</p><h1>One sentence.<br>Three readers.</h1><p class="lead">Keep the instruction. Change the way it becomes a movement.</p><p>'+str(n)+' printed-code checks · '+str(q)+' museum assertions · 12 comparisons with the existing interpreter</p>'
body+=fig('assets/three.png','Inside the actual museum: the same sentence at 25 degrees, 45 degrees and with exchanged x/y directions. All retain 0.32-metre strides.')
body+='<div class="pair">'+fig('before-captures/three.png','Before: the interpreter calculates connected paths, but the oblique cylinders are shortened in the wrong coordinate frame.')+fig('assets/three.png','After: the rendered cylinders reach their calculated ends; the same point controls the two reader decisions.')+'</div>'
body+=fig('assets/hand.png','The hand point returns in front of the existing controls. Move for the middle angle; held trigger changes the blue reader.')
body+='<div class="pair">'+fig('before-captures/fork.png','Before, at symbol six: the early fork already reveals the display problem.')+fig('assets/fork.png','After, at the same symbol: a small reading makes the relation easier to follow than the entire tree.')+'</div>'
body+=fig('assets/opening-above.png','The opening from above: three large readings, one close console, then the original smaller studies. The required tutorial concentrates on the first encounter.')
body+='<div class="pair">'+fig('before-captures/above.png','Before: the complete hall, including the rear tube bay.')+fig('assets/above.png','After: seven authored works and all room placements remain; the sphere is the added interface.')+'</div>'
body+=fig('assets/applications.png','Retained optional applications: continuing a line, inspecting rings, joining runs, patching motion and changing the canopy. These systems were not rebuilt or newly certified by the reader tests.')
body+=fig('assets/student.png','The exact printed four-file reconstruction runs temporarily in the same museum. The original primary is hidden only for this photograph. This version uses the carried LineSkin rods and omits the supplied six-button furniture.')
body+=md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('One sentence, three readers',body))
for name in ['curves_reader_before.gd','curves_reader_room.gd','curves_reader_lesson.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
shutil.copyfile(R/'tools/test_curves_reader_lesson.py',O/'probes/test_curves_reader_lesson.py')
for name in ['interpreter_lesson.gd','interpreter_hand.gd']:shutil.copyfile(R/'commons/artifacts/interpreter_lesson'/name,O/'after'/name)
dump(O/'manifest.json',{'scope':'LSystems_Grammars_And_Curves primary','files':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'generator_unchanged':True,'map_unchanged':True,'sequence_unchanged':True,'tube_notes_unchanged':True,'learner_checks':n,'museum_checks':q,'production_comparisons':12,'production_frames':code['production_frames'],'route_samples':samples})
write(O/'README.txt','Open index.html for native museum images, parallel.html for tutorial left and reflection right. printed/ contains four tested student files; variation/ contains the executed rotation edit. Run in the prepared Endless Museum project with XRTools, not an empty Godot project. Optional tube-bay notes refer to the existing repository; their older study link needs the local encyclopedia server. This package does not rebuild that application or claim automatic path transfer. Tests are author-led with supplied poses, not independent student or headset evidence.\n')
archive=O/'curves-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="curves-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[]
    def handle_starttag(self,tag,attrs):
        for key,value in attrs:
            if key in ['href','src'] and value:self.links.append(value)
checked=0
for p in O.glob('*.html'):
    parser=Links();parser.feed(p.read_text(encoding='utf-8'))
    for value in parser.links:
        if value.startswith(('http:','https:','#','data:')):continue
        assert (p.parent/value.split('#')[0]).exists(),(p,value)
        checked+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf-8'),re.S)]
assert len(rendered)>=4
for name,code_text in zip(['grammar.gd','readers.gd','point_body.gd','line_skin.gd'],rendered[:4]):assert code_text==(O/'printed'/name).read_text(encoding='utf-8'),name
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf-8'))
            for value in parser.links:
                if value.startswith(('http:','https:','#','data:')):continue
                assert value.split('#')[0] in members,(name,value)
dump(O/'validation.json',{'passed':True,'local_references':checked,'rendered_tested_code_matches':4,'zip_internal_refs':True,'zip_crc':True,'zip_MB':round(archive.stat().st_size/1e6,2)})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'local_references':checked,'zip_MB':round(archive.stat().st_size/1e6,2)}))
