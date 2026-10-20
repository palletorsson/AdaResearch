"""Publish Growth's paired texts, native captures and reproducible evidence."""
from pathlib import Path
import copy,difflib,hashlib,html,json,re,shutil,zipfile
from html.parser import HTMLParser
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-growth-what-a-branch-keeps'
M=R/'commons/maps/LSystems_Growth'
RUN=R/'ada_run/encounter_pilot/LSystems_Growth'
def dump(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text())
assert code['passed'] and room['passed']
assert not any(t in (RUN/'engine.log').read_text(encoding='utf-8',errors='replace') for t in ['SCRIPT ERROR','Parse Error'])
n=len(code['checks']);q=len(room['checks']);samples=room['observations']['route_samples']
for folder in ['museum','after','assets','probes']:(O/folder).mkdir(exist_ok=True)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
before=json.loads((O/'before/hashes.json').read_text())
for path in ['commons/artifacts/parametric_lsystem/parametric_lsystem.gd','commons/maps/sequences/lsystems.json']:
    assert sha(R/path)==before[path]
prior=json.loads((O/'before/commons/maps/LSystems_Growth/map_data.json').read_text())
current=json.loads((M/'map_data.json').read_text())
expected=copy.deepcopy(prior);expected['layers']['utilities'][26][9]='t'
assert current==expected
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));old=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']=='LSystems_Growth')
row.update(object='The carried PointBody controls branch ratio beside a saved reading of the same turtle.',
change='Extend the prior reader with copied state dictionaries and last-in-first-out restoration; replay one recorded symbol at a time.',
dependsOn=['LSystems_Grammar_Lab'],
reuses='Unchanged rewrite function, PointBody and LineSkin; dictionaries, arrays, loops, local hand position and held action.',
given='Prepared Endless Museum player, camera, lighting and XRTools. Four complete printed files; no named scene children. Full-size metre readings on an empty unit-scale study host.',
later='The installed six-button desk remains. Compact code uses Enter/H/T/R plus point/trigger, not recreated VR button scenes. No persistence between visits; no botanical simulation or segment colliders. Other four artifacts remain companions.',
checks=[f'{n} exact printed-file checks; executed nested-rule variation and two deliberately broken stack variants; eight production comparisons covering {code["production_frames"]} frames and raw endpoints.',f'{q} native museum assertions: real pointer access, XRTools with supplied poses, cylinder endpoints, retained works, {samples} supported route samples, valid entry/onward portals and eight captures.'],
transfer='Edit only RULE to F -> F[+F[-F]F]F. Predict five segments, inner return to outer stride0.576 and outer return to trunk0.8; final tip(0,1.6,0). Run it. Remove a bracket and explain rejection.',
carry='A branch restores an independent state record while preserving the geometry drawn during its departure. Rewriting generation, stack depth and trace cursor count different operations.',
next='LSystems_Grammars_And_Curves: carry the sentence and stack into comparison of geometric readers. Declare stride, turns and display frame before a path becomes a surface.',
notes='Growth completed in this pass; draft decision preserved. Core parametric generator byte-unchanged. Hand adapter added, lesson cylinder local-axis scaling repaired, missing onward token restored. Tests are author-led; no independent student, physical headset, Quest or full portal traversal claim.',
summary='At Growth, step from the existing first line into a saved branch. Hold its tip, then return: the branch remains while the turtle recovers its earlier position, heading, length and angle. Extend Grammar Lab’s reader with copied dictionary states and a last-in-first-out stack, retaining the same point and cylinder helper. Move the hand point to reread the same sentence at another branch ratio; keep the comparison in common metre units. Predict and execute a nested-rule edit, including its two distinct returns and an unmatched-bracket check. Carry the separation between sentence, interpretation and display into Grammars and Curves.')
assert all(a==b for a,b in zip(old['lessons'],plan['lessons']) if a['id']!='LSystems_Growth')
assert all(old[k]==plan[k] for k in old if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/LSystems_Growth/technical.md').read_text(encoding='utf-8')
tech+=f'''

## Complete Growth reconstruction — 9 October 2026

The canonical tutorial now contains four complete files. `grammar.gd` preserves the prior rewrite function and adds copied state dictionaries, balanced-bracket preflight, a stack, raw endpoints and post-symbol records. Its planar zero-variation reader matches the valid installed lesson at all four ratios and both generations: eight comparisons, {code['production_frames']} states. `growth.gd` constructs the point, two metre-scale readings and their controls; PointBody and LineSkin are byte-identical to Grammar Lab. A separate edited file executes the nested F[+F[-F]F]F exercise. Mutants replacing the state copy with an alias or pop_back with pop_front fail that exercise as expected. The compact reader rejects malformed brackets; production's permissive invalid-input behavior is not claimed equivalent.

GrowthHand adds the familiar sphere in front of the existing six-button desk. Local X selects 0.45/0.72/1/1.15 and calls the existing reinterpret function. Held action calls STEP. Release parks the sphere. The core parametric_lsystem.gd is byte-unchanged. GrowthLesson's cylinder renderer now scales its rotated local Y column, not the world Y row: the earlier Basis.scaled call made oblique cylinders miss the recorded endpoints. The native test now checks both rendered ends of all 25 second-generation cylinders.

The live museum had no onward token: the fresh baseline portal record was empty. Added t at source cell (9,26) inside the existing rear opening. Structure and all five authored placements remain unchanged. The first route probe turned at z=16.4 inside the existing cross-wall; the correct route passes its doorway before turning at z=17.5. Final {samples} capsule/floor samples and nonempty entry/exit approach validation pass. This is not a complete player portal traversal.

{n} exact printed-code and {q} museum assertions pass. Four baseline and eight final native images include the overhead arrangement. The temporary desktop pointer rig is removed before final images because it brings a competing environment; no production lighting was changed. The learner photograph temporarily hides the original primary to avoid duplicate labels, then restores it; that reconstruction is not permanently added to the hall. Logs contain no SCRIPT ERROR or Parse Error; a pre-existing unresolved UID diagnostic remains. No physical headset, Quest performance, blind ghost student or whole-sequence acceptance is claimed. Report: doc/book/iterations/2026-10-09-growth-what-a-branch-keeps/index.html.
'''
(M/'technical.md').write_bytes(tech.encode('utf-8'))
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
    a=(O/'before/commons/maps/LSystems_Growth'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
    (O/'after'/(name+'.diff')).write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)),encoding='utf-8')
report=f'''# Growth — what a branch keeps

The second L-systems hall now has a complete tutorial, its reflective partner and a hand interaction in the existing Endless Museum. The new capability is precise: leave a branch, then recover the state from which it began.

## The lineage

Grammar Lab separated writing a sentence from reading it. Growth extends that reader. The same PointBody chooses the branch ratio; its held trigger reveals one recorded symbol. A dictionary holds the state. A copy preserves it; a stack determines the order of returns. The drawn branch remains after the turtle returns.

The tutorial prints all four required files and explains what changed. Two helpers and the replacement function are carried unchanged. The reflection keeps the question of what a return preserves and what a saved state leaves out. Its two code excerpts become prose, with the operations explained in the tutorial. These remain two complementary readings of one encounter.

## Museum changes

- Added the carried sphere to the current desk; six nearby buttons remain.
- Fixed oblique cylinder rendering: each visible branch now reaches the two positions calculated by the interpreter. The generating algorithm is unchanged.
- Added the missing onward portal at the rear opening.
- Retained the walls, floor and all five authored works in their existing positions.

The overhead view shows a paired reading with routes around it, an open middle, and the older growth experiments in the rear enclosure. Their tall silhouettes extend beyond that enclosure. The tutorial concentrates on the first desk; the companion works are not extra required lessons. Existing blank frames and the dense rear collection remain visible spatial follow-ups.

## What passed

{n} native Godot checks run files extracted verbatim from tutorial.md. The checks include copied records, all restored state fields, preserved geometry, nested returns, malformed brackets, retained comparisons, actual XRTools pickup/action/release with supplied poses, and a separately executed student edit. Two deliberately broken stack implementations are detected. Eight ratio/generation comparisons match all {code['production_frames']} production trace frames and raw endpoints.

{q} museum assertions pass, including capture-camera checks. They exercise all six pointer controls and the physical point's binding, verify every second-generation cylinder's ends, retain the five works, sample {samples} supported capsule positions and validate nonempty entry/onward approaches. Four before and eight after images come from native Godot rendering.

The first route test crossed a wall because its waypoint turned before the doorway; the corrected path passes through the opening. Its failed receipt is retained. Visual inspection also found the oblique-cylinder error; that required a real renderer correction and a new geometric assertion. The temporary pointer rig's extra environment was removed before final photographs.

These are author-led code and museum tests. They do not establish independent student understanding, headset reach and readability, Quest performance or continuous travel through the whole sequence. Final logs contain no SCRIPT ERROR or Parse Error; an existing unresolved-UID warning remains. HTML source links, displayed code and ZIP contents are checked; no browser preview is claimed.

## What comes next

Grammars and Curves: keep the sentence and the stack, then compare what different geometric readers make of the instructions. Two of the eight halls have now received this complete reconstruction pass. The remaining six still need their own work.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
css='''*{box-sizing:border-box}body{margin:0;background:#f4f0e9;color:#252c2e;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1180px;margin:auto;padding:30px}nav{display:flex;flex-wrap:wrap;gap:20px;font:14px/1.5 system-ui}a{color:#245d60}h1{font-size:clamp(36px,5vw,66px);line-height:1.1}h2{font-size:29px;line-height:1.3;margin-top:2em}.lead{font-size:25px;max-width:800px}.eyebrow,figcaption,footer{font:14px/1.5 system-ui;color:#556066}img{width:100%;height:auto}figure{margin:28px 0}figcaption{margin-top:8px}.pair,.spread{display:grid;grid-template-columns:1fr 1fr;gap:28px}.spread{max-width:1800px}.spread article{min-width:0;background:#fffdf8;padding:20px}.spread h1{font-size:38px}article{max-width:850px;margin:auto}pre{white-space:pre;overflow:auto;background:#222c33;color:#fff1e7;padding:20px;font:13px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.86em}summary{cursor:pointer;padding:16px;border:1px solid #bbb}@media(max-width:850px){.pair,.spread{grid-template-columns:1fr}header,main,footer{padding:20px}}@media print{nav{display:none}pre{white-space:pre-wrap;background:white;color:black;font-size:9px}.spread{display:block}img{max-height:65vh;object-fit:contain}}'''
def md(s):
    rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],rendered,flags=re.S)
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 02 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="growth-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · physical headset and independent student review remain open.</footer></body></html>'
def fig(file,caption):return '<figure><img loading="lazy" src="'+file+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for name,title in [('tutorial','Tutorial'),('final','Reflection')]:
    (O/(name+'.html')).write_text(page(title,'<main><article>'+md((O/(name+'.md')).read_text(encoding='utf-8'))+'</article></main>'),encoding='utf-8')
(O/'parallel.html').write_text(page('Growth — facing pages','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md((O/'tutorial.md').read_text(encoding='utf-8'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md((O/'final.md').read_text(encoding='utf-8'))+'</article></main>'),encoding='utf-8')
changes='<main><h1>Growth, before and after.</h1>'
for name in ['tutorial.md','final.md']:
    changes+='<h2>'+name+'</h2><div class="pair"><article><p class="eyebrow">Before</p>'+md((O/'before/commons/maps/LSystems_Growth'/name).read_text(encoding='utf-8'))+'</article><article><p class="eyebrow">After</p>'+md((O/name).read_text(encoding='utf-8'))+'</article></div>'
(O/'changes.html').write_text(page('Before and after',changes+'</main>'),encoding='utf-8')
body='<main><p class="eyebrow">Growth · one hall, one new capability</p><h1>Leave a branch.<br>Keep the way back.</h1><p class="lead">The same point controls a new relation. A saved state lets the drawing continue from where it left.</p><p>'+str(n)+' printed-code checks · '+str(q)+' museum assertions · 8 comparisons with the existing interpreter</p>'
body+=fig('assets/hand.png','The carried PointBody in the actual Growth hall: move for ratio, held trigger for STEP. The six existing controls stay close.')
body+='<div class="pair">'+fig('before-captures/branch.png','Before: the short branch is calculated correctly, but its oblique cylinder misses the fork.')+fig('assets/branch.png','After: the same saved branch, with correct local-axis cylinder scaling and the new hand control.')+'</div>'
body+=fig('assets/return.png','The live tip returns to the fork; the held tip remains at the branch end. Both drawings retain that branch.')
body+=fig('assets/tree.png','Two rewriting generations, twenty-five segments and a 7.2-metre trunk beside the held first generation. These views use common metres, not independent fitting.')
body+='<div class="pair">'+fig('before-captures/above.png','Before: the paired desk and the retained rear enclosure.')+fig('assets/above.png','After, from above: walls and five works retain their positions. The rear opening gains its missing onward portal.')+'</div>'
body+=fig('assets/student.png','The exact printed reconstruction, running temporarily inside the hall. The original primary is hidden only for this photograph to avoid duplicate labels; no duplicate artifact is permanently installed.')
body+=md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
(O/'index.html').write_text(page('Growth — what a branch keeps',body),encoding='utf-8')
for name in ['growth_branch_before.gd','growth_branch_room.gd','growth_branch_lesson.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
shutil.copyfile(R/'tools/test_growth_branch_lesson.py',O/'probes/test_growth_branch_lesson.py')
for name in ['growth_lesson.gd','growth_hand.gd']:shutil.copyfile(R/'commons/artifacts/growth_lesson'/name,O/'after'/name)
dump(O/'manifest.json',{'scope':'LSystems_Growth only','files':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'generator_unchanged':True,'structure_and_five_placements_unchanged':True,'sequence_unchanged':True,'learner_checks':n,'museum_checks':q,'production_comparisons':8,'production_frames':code['production_frames'],'route_samples':samples})
(O/'README.txt').write_text('Open index.html for native museum images, parallel.html for tutorial left and reflection right. printed/ contains all four tested student files; variation/ is the executed nested-rule edit. Use the prepared Endless Museum project with XRTools. This is not an empty Godot project. Tests are author-led and use supplied poses, not independent student or headset evidence.\n',encoding='utf-8')
archive=O/'growth-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="growth-review.zip"',b'href="README.txt"')
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
assert len(rendered)==4
for name,code_text in zip(['grammar.gd','growth.gd','point_body.gd','line_skin.gd'],rendered):assert code_text==(O/'printed'/name).read_text(encoding='utf-8'),name
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
