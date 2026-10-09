"""Publish the opening L-systems lesson, its actual images and bounded evidence."""
from pathlib import Path
import copy,difflib,hashlib,html,json,re,shutil,zipfile
from html.parser import HTMLParser
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading'
M=R/'commons/maps/LSystems_Grammar_Lab'
RUN=R/'ada_run/encounter_pilot/LSystems_Grammar_Lab'
S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab'
def dump(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text())
assert code['passed'] and room['passed']
assert not any(s in (RUN/'engine.log').read_text(encoding='utf-8',errors='replace') for s in ['SCRIPT ERROR','Parse Error'])
n=len(code['checks']);q=len(room['checks'])
for folder in ['museum','after','assets']:(O/folder).mkdir(exist_ok=True)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
before=json.loads((O/'before-hashes.json').read_text())
assert sha(R/'commons/artifacts/lsystem_editor/lsystem_editor.gd')==before['commons/artifacts/lsystem_editor/lsystem_editor.gd']
assert sha(R/'commons/maps/sequences/lsystems.json')==before['commons/maps/sequences/lsystems.json']
prior=json.loads((O/'before/commons/maps/LSystems_Grammar_Lab/map_data.json').read_text())
current=json.loads((M/'map_data.json').read_text())
assert current['layers']['structure']==prior['layers']['structure']
assert current['layers']['interactables']==prior['layers']['interactables']
expected=copy.deepcopy(prior);expected['layers']['utilities'][23][8]='';expected['layers']['utilities'][25][9]='t'
assert current==expected
# Update only the selected lesson contract. The author's decision remains draft.
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']=='LSystems_Grammar_Lab')
row.update(object='Carried PointBody changes the reader angle of a rewritten sentence beside an independent held reading.',
change='Build a separate next string from a production dictionary, then interpret forward and turn commands. Keep text, angle and generation independently.',
dependsOn=['Fractal_Synthesis','Fractal_KochSierpinski','Point_Coordinates'],
reuses='Seed/rule/stop recipe, dictionaries, strings, loops, separate old/next data, unchanged PointBody and cylinder LineSkin.',
given='Prepared Endless Museum player, camera, lighting and XRTools. Four complete printed files: grammar.gd, sentence.gd, point_body.gd, line_skin.gd; no named scene children.',
later='Brackets, saved turtle state and branching belong to Growth. Other museum presets remain companions. No physical rule typing, saved files or automatic cross-hall data transfer. Compact code uses H/R/C keys alongside point/trigger; installed desk supplies nearby VR buttons.',
checks=[f'{n} native printed-file checks including real XRTools supplied poses and executed FplusF variant; forty rule-depth-angle comparisons match production after fitting.',f'{q} museum assertions including eight captures, six real pointer controls, carried hand action, all eight authored works, Cantor selection, {room["observations"]["route_samples"]} route samples and valid portal approaches.'],
transfer='Change only CURVE to F -> F+F. Predict and run generation2: seven symbols/four segments, closed square at90 but not120. Return to Cantor and explain8 intervals/27 advances after3 rewrites.',
carry='A sentence can be rewritten separately from its geometric interpretation; independent display fitting is a third operation. Cantor connects to the previous thirds recipe.',
next='LSystems_Growth: add explicit saved-state records and stack push/pop to the existing reader; define bracket errors and restore branch position/heading/length.',
notes='Opening hall completed in this pass; remaining seven require their own reconstruction. Core editor byte-unchanged; hand adapter and Cantor preset access added, rear portal relocated. Author-led native tests, no independent student, headset, Quest or full passage traversal.',
summary='At the existing comparison desk, rewrite F once and keep a reading. Move the familiar point to turn the live interpreter without changing its sentence; its held trigger advances one generation. Reconstruct the two operations in a compact, complete program, using the carried point and cylinder renderer. Distinguish the stored sentence, model endpoints and independently fitted drawing. Execute another production that makes a square at90 degrees, then return to Cantor: eight drawn intervals among twenty-seven advances connect this string to the previous thirds recipe. Carry the reader into Growth, where brackets will need a saved state.')
assert all(a==b for a,b in zip(old['lessons'],plan['lessons']) if a['id']!='LSystems_Grammar_Lab')
assert all(old[k]==plan[k] for k in old if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/LSystems_Grammar_Lab/technical.md').read_text(encoding='utf-8')
tech=tech.replace('PRESET cycles the seven existing grammars','PRESET cycles eight grammars, including Cantor').replace('Custom (index 7)','Custom (index 8)').replace('sliders and seven presets','sliders and eight presets')
tech+=f'''

## Complete opening lesson — 9 October 2026

The tutorial now prints four complete files under `doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab`. `grammar.gd` owns parallel replacement and the planar F/G/f/+/- reader. `sentence.gd` constructs both readings and all input/labels. PointBody and LineSkin are byte-identical to their previous Fractals lessons. The prepared museum remains the host. The compact reader rejects brackets; the full editor retains its existing stack. In the compact program R resets live only; the installed RESET resets the whole comparison. These controls are declared separately in the tutorial.

`grammar_hand.gd` adds the carried point to the current six-button desk. Local X chooses 30/60/90/120; held action calls NEXT. Angle edits invoke the existing setter without rewriting. Release parks the point. Preset-native angles remain until the visitor picks up the point, when it selects the nearest offered angle; no unheld quantization. Cantor, already preset7 in the generator, is now reachable by the lesson button; the cycle changes7 to8 and its label names Cantor. No editor algorithm change.

The onward token moves from blocked source(8,23) to the rear opening(9,25). Structure and all eight authored placements are unchanged. Actual route checks use source map coordinates: the museum hall transform also includes a four-metre lobby offset and cannot be treated as the source map origin.

{n} native printed-file checks and {q} museum checks pass. Forty rule/depth/angle combinations agree with production after normalizing the fitted endpoints; the changed FplusF file is executed independently. Both bypasses and the rear route pass188 capsule/floor samples; entry/exit approaches validate. A full player crossing, physical headset reach, Quest performance and an independent ghost-student assessment are not claimed. The preserved first code run had an early test-harness XRTools type-load diagnostic; runtime assertions passed, and removing that eager type dependency gave a clean rerun. The first museum run miscounted generic fixtures as authored works and used the lobby-shifted frame for routes; both test assumptions are corrected and archived.

Report: doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading/index.html. Existing blank wall frames and rear collection label density remain visible follow-up items, not hidden by this tutorial pass.
'''
if (M/'technical.md').read_text(encoding='utf-8') != tech:
    (M/'technical.md').write_text(tech,encoding='utf-8')
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
    oldtext=(O/'before/commons/maps/LSystems_Grammar_Lab'/name).read_text(encoding='utf-8')
    (O/'after'/(name+'.diff')).write_text(''.join(difflib.unified_diff(oldtext.splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name)),encoding='utf-8')
route='''# L-systems: what the next hall adds

Only Grammar Lab is completed in this pass. These next steps retain the existing eight-hall order; they do not certify the remaining tutorials or change their subjects automatically.

| Hall | Operation to carry | Next teaching focus |
|---|---|---|
| Grammar Lab | Seed/rule/stop from Fractals; the same point and line skin | Rewrite a sentence separately from reading its turns; preserve a comparison. Complete and tested here. |
| Growth | The sentence reader | Save and restore position, orientation and branch length with a stack; diagnose unmatched brackets. |
| Grammars and Curves | One sentence and saved states | Compare readers under declared strides and angles; separate interpreting a path from sweeping a surface around it. |
| Architecture | A constructed path | Give a fixed plan width, collision and clearance; a drawing is not yet a passage for a body. |
| Competition | A growth request | Read shared resources before each request; reverse the order from the same beginning. Return to CA's old-state versus updated-state distinction. |
| Living | A bounded growth recipe | Trace raw genes into effective grammar parameters; retain a stable recipe and its resulting specimen. |
| Shape Grammars | Indexed cube faces from Primitives | Name an inset/extrusion recipe and its selected faces; establish a small editable host before promising a general builder. No tutorial currently exists. |
| Assemblage | Decisions and their interpretations | Hold a binary decision sheet; compare marks, forms and apparent paths. Ask which connections the generator never tested. |

The tutorial will select one reconstructible operation in each hall. The reflective text and remaining museum works retain their other questions. The point carries interaction continuity; it need not become every generated object.
'''
(O/'LINEAGE.md').write_text(route,encoding='utf-8')
report=f'''# A sentence and a reading

Grammar Lab now has a complete first L-systems tutorial inside the existing Endless Museum. It follows Fractal Synthesis: the recipe gains a sentence, a replacement function and a separate geometric reader. The same PointBody chooses the turning angle; its trigger advances the sentence. HOLD preserves an independent reference.

## What changed

- Replaced the opening storyboard with an explained, runnable four-file tutorial. Two files are unchanged carried helpers.
- Updated final.md to retain its encounter and reflection, moving its code excerpt into the tutorial. Added the hand and Cantor connection; no new theoretical claim.
- Added the hand to the existing desk and exposed its already implemented Cantor preset. All eight authored artifacts and their placements remain.
- Moved the blocked exit token to the existing rear opening. The floor and walls are unchanged.
- Updated only the opening lesson contract; kept the eight-hall order and draft decision.

## Evidence and limits

{n} native learner assertions pass using files extracted exactly from tutorial.md. They cover parallel replacement, preserved symbols, empty strings, complete-generation refusal, read/turn separation, held data, rendering, the executed FplusF variation, Cantor correspondence and real XRTools pickup/action/release under supplied poses. Forty combinations agree with the production generator's normalized endpoints. This is an author-led reconstruction, not an independent student's assessment.

{q} museum assertions pass, including capture-camera assertions. Six nearby controls receive actual desktop rays. The added point changes the real generator's reading and advances once on action. Both primary bypasses and the rear route have188 supported capsule samples; portal approaches validate. Four before and eight after images are native Godot captures. The learner display is temporarily instantiated in the actual hall for its photograph, not permanently added as a duplicate artifact.

Final logs contain no SCRIPT ERROR or Parse Error. A pre-existing unresolved-UID diagnostic remains. The first learner run's eager XRTools type reference and the first museum run's inventory/coordinate assumptions were test-harness faults; those logs and checks are retained. No production generator fix was needed. No physical headset, Quest performance, complete player portal crossing or whole-sequence learner validation is claimed.

## How the two texts read

The tutorial asks the student to reconstruct and alter the operation. The reflection asks what we receive as a form when writing, reading, fitting and display have each intervened. Their shared encounter is precise: the same sentence can produce another body. Growth adds one necessary capability to this reader: a branch can remember where it began.

The remaining sequence is promising but not yet at the same implementation level: five further tutorials are short guides with no GDScript blocks, Grammars and Curves mixes its guide with tube applications, and Shape Grammars has no tutorial. Work through them one hall at a time. Blank museum frames and dense rear labels remain visible spatial issues for a later pass.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
css='''*{box-sizing:border-box}body{margin:0;background:#f5f1ea;color:#24262c;font:18px/1.6 Georgia,serif}header,main,footer{max-width:1180px;margin:auto;padding:30px}header{border-bottom:1px solid #c3bfb8}nav{display:flex;gap:20px;flex-wrap:wrap;font:14px/1.5 system-ui}a{color:#315d64}h1{font-size:clamp(36px,5vw,66px);line-height:1.08;max-width:950px}h2{font-size:29px;line-height:1.25;margin-top:2em}.eyebrow,.caption,figcaption,footer{font:14px/1.5 system-ui;color:#535b60}.lead{font-size:24px;max-width:820px}img{width:100%;height:auto;border-radius:5px}figure{margin:26px 0}figcaption{margin-top:8px}.pair,.spread{display:grid;grid-template-columns:1fr 1fr;gap:28px}.spread{max-width:1800px}.spread article{min-width:0;padding:20px;background:#fffcf6}.spread h1{font-size:37px}pre{white-space:pre;overflow:auto;padding:20px;background:#222831;color:#f3e8df;font:13px/1.65 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.86em}article{max-width:850px;margin:auto}td,th{padding:12px;border-bottom:1px solid #ccc;text-align:left;vertical-align:top}table{border-collapse:collapse;width:100%;font-size:16px}summary{cursor:pointer;padding:15px;border:1px solid #bbb}@media(max-width:850px){.pair,.spread{grid-template-columns:1fr}header,main,footer{padding:20px}}@media print{header nav{display:none}pre{white-space:pre-wrap;background:white;color:black;font-size:9px}.spread{display:block}img{max-height:65vh;object-fit:contain}}'''
def md(s):
    rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    # Markdown expands tabs before fenced-code processing; preserve the tested source.
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],rendered,flags=re.S)
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 01 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="lineage.html">Eight-hall route</a><a href="grammar-lab-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence. Physical headset and independent student review remain open.</footer></body></html>'
def fig(file,caption):return '<figure><img loading="lazy" src="'+file+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for name,title in [('tutorial','Tutorial'),('final','Reflection')]:
    (O/(name+'.html')).write_text(page(title,'<main><article>'+md((O/(name+'.md')).read_text(encoding='utf-8'))+'</article></main>'),encoding='utf-8')
(O/'parallel.html').write_text(page('A sentence and a reading — facing pages','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md((O/'tutorial.md').read_text(encoding='utf-8'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md((O/'final.md').read_text(encoding='utf-8'))+'</article></main>'),encoding='utf-8')
(O/'lineage.html').write_text(page('L-systems route','<main>'+md(route)+'</main>'),encoding='utf-8')
changes='<main><h1>The opening, before and after.</h1><p>Exact archived texts. The first tutorial was a storyboard; the new one includes the complete learner reconstruction.</p>'
for name in ['tutorial.md','final.md']:
    changes+='<h2>'+name+'</h2><div class="pair"><article><p class="eyebrow">Before</p>'+md((O/'before/commons/maps/LSystems_Grammar_Lab'/name).read_text(encoding='utf-8'))+'</article><article><p class="eyebrow">After</p>'+md((O/name).read_text(encoding='utf-8'))+'</article></div>'
(O/'changes.html').write_text(page('Before and after',changes+'</main>'),encoding='utf-8')
body='<main><p class="eyebrow">One hall completed · seven to develop</p><h1>A sentence.<br>Another reading.</h1><p class="lead">Move the familiar point: the angle changes. Press its trigger: the sentence changes. Keep one reading beside the next.</p><p>'+str(n)+' learner checks · '+str(q)+' museum checks · 40 comparisons with the existing generator</p>'
body+=fig('assets/hand.png','Inside the actual Grammar Lab: the same small sphere now chooses the turning angle. The six existing controls stay close.')
body+='<div class="pair">'+fig('before-captures/comparison.png','Before: the six-button comparison desk.')+fig('assets/comparison.png','After: the carried point and angle rail join the existing desk. Capture lighting varies; no hall lighting settings were changed.')+'</div>'
body+=fig('assets/above.png','Native overhead view. All eight authored works and their positions remain. Two routes pass around the comparison plinths; the rear collection leads to Growth.')
body+='<div class="pair">'+fig('assets/cantor.png','Cantor is reachable as the eighth preset: eight drawn intervals among twenty-seven advances.')+fig('assets/student.png','The exact printed learner program running temporarily on an empty floor patch inside the museum. Four complete files; no named scene children.')+'</div>'
body+='<details><summary>Before overhead view</summary>'+fig('before-captures/above.png','The preserved arrangement before this pass. The earlier exit token was blocked.')+'</details>'
body+=fig('assets/rear.png','The rear opening now has a valid onward portal. The collection remains; dense labels and blank frames are visible follow-up work.')
body+=md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="LINEAGE.md">Short route file</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
(O/'index.html').write_text(page('Grammar Lab — a sentence and a reading',body),encoding='utf-8')
# Stable copies make the evidence portable even if future probes change.
(O/'probes').mkdir(exist_ok=True)
for name in ['grammar_sentence_before.gd','grammar_sentence_room.gd','grammar_sentence_lesson.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['grammar_lesson.gd','grammar_hand.gd']:shutil.copyfile(R/'commons/artifacts/grammar_lesson'/name,O/'after'/name)
shutil.copyfile(R/'tools/test_grammar_sentence_lesson.py',O/'probes/test_grammar_sentence_lesson.py')
dump(O/'manifest.json',{'scope':'Opening L-systems hall only','files':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'generator_unchanged':True,'sequence_unchanged':True,'eight_placements_unchanged':True,'structure_unchanged':True,'learner_checks':n,'museum_checks':q,'production_comparisons':40,'route_samples':188})
(O/'README.txt').write_text('Open index.html for report or parallel.html for tutorial left/reflection right. Four complete student files are in printed/. They require the prepared Endless Museum project with XRTools; this is not an empty Godot project. Future halls are described, not certified. Author-led tests; no independent student/headset claim.\n',encoding='utf-8')
archive=O/'grammar-lab-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="grammar-lab-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
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
assert len(rendered)==4
for name,code_text in zip(['grammar.gd','sentence.gd','point_body.gd','line_skin.gd'],rendered):
    assert code_text==(O/'printed'/name).read_text(encoding='utf-8'),name
with zipfile.ZipFile(archive) as z:
    members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf-8'))
            for value in parser.links:
                if value.startswith(('http:','https:','#','data:')):continue
                assert value.split('#')[0] in members,(name,value)
dump(O/'validation.json',{'passed':True,'local_references':checked,'rendered_tested_code_matches':4,'zip_internal_refs':True,'zip_crc':True,'zip_MB':round(archive.stat().st_size/1e6,2)})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'local_references':checked,'zip_MB':round(archive.stat().st_size/1e6,2)}))
