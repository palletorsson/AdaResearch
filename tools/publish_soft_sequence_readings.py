"""Publish current nine-hall texts, the ghost rehearsal and a portable review pack."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote
import difflib, hashlib, html, json, posixpath, re, shutil, zipfile
import markdown
from test_soft_sequence_ghost import ROWS

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-soft-bodies-complete-readings'
def read(p): return p.read_text(encoding='utf8')
def write(p,s): p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d): write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checks=json.loads(read(O/'ghost-checks.json'));assert checks['passed']
N=checks['total_checks']
latest=''
fresh_path=O/'ghost-rerun/validation.json'
if fresh_path.exists():
    fresh=json.loads(read(fresh_path))
    fresh_checks=json.loads(read(O/'ghost-rerun/ghost-checks.json'))
    assert fresh['passed'] and fresh_checks['passed']
    assert fresh['fresh_lesson_checks']==N and fresh['fresh_composition_checks']==21
    for row in fresh_checks['halls']:
        assert row['fresh_engine_run'] and sha(R/'commons/maps'/row['map']/'tutorial.md')==row['tutorial_sha256']
    latest='\n\n## Fresh run after the revision\n\nAll nine printed lessons were run again: **263 checks passed**, with no cached receipts. The three-attachment composition was also repeated inside the museum: **21 checks passed**. No learner-code repair was needed. [Read the fresh ghost-student report and native captures](ghost-rerun/index.html). Earlier evidence below is preserved as the development history.\n\n'
extension=R/'doc/book/iterations/2026-10-09-soft-bodies-three-attachments'
extra=json.loads(read(extension/'manifest.json'))
extra_report=json.loads(read(extension/'evidence/report.json'))
assert extra['passed'] and extra_report['passed'] and not extra_report['failures']
assert len(extra_report['checks'])==extra['checks']==21
assert any(c['name']=='All planned composition checks completed' and c['passed'] for c in extra_report['checks'])
for name,digest in extra['files'].items():assert sha(extension/'student'/name)==digest
for name in ['stdout.log','engine.log']:
    log=read(extension/'evidence'/name)
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
shutil.copytree(extension,O/'extensions/three-attachments',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.uid'))
titles=['A point that stays','Which points must stay?','The support moves','A drive and a room','The same start','A shape kept','One shape, one cue','What keeps a pattern changing?','Who connected the controls?']
inputs=['Cube mesh; the carried point; prepared museum','SoftBody3D construction and the same point','The unchanged cloth sheet and point','The closed cube construction and boundary selection','The unchanged pressure panel and point','Sampling an observation; supplied vessel and solver','The same vessel recipe, solver and point','Earlier CA field and the same point','Matched comparison and the same point; a supplied 3D field']
lessons=['Select one attachment; separate material settings from a restart.','Select a row, two corners or no pins from reference coordinates.','Drive the two attachments; let the free surface respond.','Send a periodic pressure command to a closed surface.','Repeat a fall, vary damping and retain a timed reading.','Copy positions and connectivity while the source continues.','Keep geometry; isolate a turn or a material change.','Open local conversion, supply and removal beside neighbour exchange.','Separate frequency, disturbance and cut; preview before committing.']
transfers=['Reduce cube subdivisions; select a valid top attachment again.','6 → 10 subdivisions: 12 row pins, 2 corner pins, 168 entries.','Double rate: twice the commanded angle, without promising twice the deformation.','Halve amplitude: pressures 0.125, 0.25, 0 at the three chosen phases.','Set both damping values to 0.1; match recipes and repeat the measured fall.','Capture at step 200; retain indices while the live body keeps changing.','Halve turn speed; leave the recorded shape and the reference alone.','Feed 0.050: at W, U=0.49375 and V=0.25375 after one step.','Double CUT_SPAN: opening cut −0.12 and endpoint 0.30; other parameters stay.']
images=['student-press.png','student-corners.png','student-turning.png','student-cycle.png','student-reading.png','student-comparison.png','student-colour.png','student-1000.png','student-all.png']
probes=['soft_yield_lesson.gd','cloth_boundary_lesson.gd','carousel_lesson.gd','pressure_lesson.gd','contact_lesson.gd','sampling_lesson.gd','affect_student.gd','reaction_student.gd','morphogenesis_student.gd']

report=f'''# Soft Bodies — what a form can keep

9 October 2026 · Nine halls · Revised tutorial and reflective texts

The sequence moves from a yielding body to its attachments, a driven support, pressure, comparison, a saved surface, appearance, continuing exchange and an authored control. The order stays. The tightening makes the changes of model explicit and gives the reader a clearer main route through the wider museum collection.

## Three movements

**Halls 1–4: conditions of movement.** A body yields; selected points stay; the support moves; a pressure signal changes. The student reuses construction patterns, coordinates and the black PointBody. The new problem is how a changing condition reaches a body whose response is simulated.

**Halls 5–7: an event becomes a record and an appearance.** First keep a number, then a surface, then vary that surface's presentation. This is the closest material handoff: the vessel construction and solver remain identical in Sampling and Affect. Affect reconstructs the common step-40 snapshot; an arbitrary trigger capture is not persisted between halls.

**Halls 8–9: processes and choices that produce form.** Reaction–diffusion returns to the student's earlier CA field. Morphogenesis introduces a different three-dimensional sine-and-noise field and examines an interface that couples its controls. These are declared changes of model. The point and the method of comparison continue; the same soft-body simulation does not run through all nine halls.

## What changed in this pass

- Cloth's repeated pin and rebuild explanations are shorter. The membrane remains as an optional museum return, apart from the sheet needed by Carusell.
- Sampling names its change from Jolt to the supplied particle solver at the handoff. It also states what the next lesson reconstructs.
- Affect keeps its complete inherited files available in expandable sections, so the new comparison is easier to find.
- Reaction's departure and its execution-plan summary now say that the concentrations stay here. The following hall starts a different spatial field.
- Several repeated qualifications were shortened in the reflection. The distinctions that change what a visitor can infer remain.
- All nine tutorials now begin with **Carry / New work / Supplied**: a short guide to the lesson's scope before its complete code.
- The last three reflections follow a shared question through distinct mechanisms: a retained record, continuing exchanges, and reconstruction from a rule.
- Cloth offers an optional three-attachment composition after its main lesson. The [worked example and native evidence](extensions/three-attachments/index.html) are included in this package.

Every printed code block, the museum maps, sequence order and learner scripts are unchanged. Existing review decisions remain unchanged.

## Ghost-student rehearsal

The tutorial code was extracted and compared with the learner files, then run using the existing Godot probes. **All nine halls passed: {N} executable checks across {checks['printed_files']} printed files.** Five continuity checks verify the shared PointBody and the other inherited files. The probes include the stated independent edits and deliberately faulty variants where provided. This later editorial pass verifies that every printed code block still matches that tested version; it does not claim another engine run. The original receipt and its exact tutorial texts remain available beside the revision hashes.

The additional three-attachment composition passed **21 native checks**. It reuses the printed sheet and point while asking a new question about attachment. Its first checker attempt failed and is retained as rejected evidence; the corrected checker requires completion. The learner's attachment logic needed no repair. A caption colour was improved after inspecting the pictures.

This rehearsal is operated by the authoring assistant. It checks runnable construction, declared behaviours, data handoffs and what the exercises ask the student to change. It is not a second model's blind assessment or evidence of an independent learner's understanding. The images on the overview are earlier native Godot captures; the text pass did not change the rooms or take new headset captures.

## What remains for a reviewer

Read the new operation before opening inherited files. Can you name what must remain fixed and predict the independent edit? At each handoff, distinguish a carried class, a recreated recipe, a copied state and a new model.

The compact learner hosts still use keyboard controls for some comparisons; their grab/trigger operations and the installed museum controls are separately described. An entirely controller-only learning session, physical headset comfort and Quest performance remain unverified. No claim is made that an arbitrary captured shape is automatically saved across halls.

The next useful critique concerns density and understanding: does the supplied-code boundary remain clear, and can a reader make a purposeful variation without reopening our conversation?
'''
if latest:
    report=report.replace('## Three movements',latest+'## Three movements',1)
    report=report.replace('This later editorial pass verifies','The preceding editorial-only pass verified').replace('it does not claim another engine run.','it retained the existing engine receipt. The separate fresh run is linked above.')
write(O/'REPORT.md',report)
ghost=f'''# Ghost student — Soft Bodies

## Role and scope

Read as a student entering the existing Endless Museum after the preceding spine lessons. Camera, player, lighting, XRTools and Jolt are prepared. The book teaches selected artifacts; the rest of the collection remains a field for exploration. Tutorial and reflection have different jobs.

This is an author-operated reconstruction with real Godot checks. It is not a blind external review. The source of each assertion is available in the per-hall evidence and probe; a passing assertion establishes that behaviour, not a feeling or universal interpretation.

## Handoffs and independent actions

|Hall|I bring|The new operation|I can change independently|Executable checks|
|---|---|---|---|---|
'''
for i,(name,tool,slug) in enumerate(ROWS):
    c=checks['halls'][i];assert c['map']==name
    ghost+=f'|{i+1}. {titles[i]}|{inputs[i]}|{lessons[i]}|{transfers[i]}|{c["checks"]} passed|\n'
ghost+='''
## Reading findings addressed

1. Cloth had repeated rebuild explanations and a second solver encounter mixed into the main lesson. The repeat is removed; the membrane is explicitly optional.
2. Sampling changes implementation. The tutorial identifies the supplied vessel solver before asking the reader to work on copying arrays.
3. The phrase “carry the shape” could imply persistent state. Sampling and Affect now agree: the next host reconstructs the step-40 recipe. This is known geometry, not a saved session.
4. The final transition could imply that the reaction concentrations become the gyroid. Both departures now state that the field changes; the point and comparison method carry forward.
5. Reprinted helpers can bury a short operation. Affect's unchanged files are expandable and remain complete in the text and download.
6. Each tutorial now identifies what carries forward, what the student writes here and what is supplied. The complete files remain visible.
7. The final handoffs distinguish a recorded surface, a pattern sustained by exchanges and a surface reconstructed from a spatial rule.

## Additional composition

After the nine-hall run, the authoring assistant composed a new comparison using Cloth's existing sheet and PointBody. Two upper corners were compared with three selected reference positions. All other pins were cleared. The freed corner moved while the selected entries stayed within the predicted tolerance. All 21 native checks passed. The [complete exercise](extensions/three-attachments/index.html) includes predictions recorded before execution, code, captures, corrected checker and the rejected first attempt.

This supports reuse beyond a supplied parameter edit. It remains an author-operated exercise with prior context. An unfamiliar learner's ability to devise such an experiment is still an open test.

The later editorial changes alter no printed code. `ghost-checks.json` retains the earlier engine result; `text-revision.json` records the current text hashes and exact code comparison. No new engine run is claimed for this prose revision.

## What was actually exercised

The per-hall probes initialize the printed scripts, inspect their resulting objects and execute interaction paths. They check such distinctions as pin flags versus reconstruction, elapsed time versus response, a kept reading versus a continuing body, saved vertices versus node motion, old versus next field state, and preview versus commit. The independent parameter edits are executed. Fault programs test whether assertions notice specific mistakes, including missing unpinning, coupled comparisons, a moving snapshot and a wrong parameter recipient.

Every hall contains the same PointBody source. Cloth → Carusell retains hanging_sheet.gd; Pressure → Contact retains pressure_panel.gd; Sampling → Affect retains vessel_surface.gd and solver.gd. These checks concern source and declared data relationships. Each host creates its own instances in the museum; this is not a test of inventory persistence or walking through all portals in one session.

The first five hall results were retained during this run after a harness-only correction: the supplied particle solver uses Windows line endings. Its printed text was already identical when decoded; no learner code needed repair. The extraction comparison now normalizes line endings while the protected-source hashes continue to use original bytes.

## Open tests

- Ask a second reader to reconstruct an exercise from the printed instructions without these probes as hints.
- Test the entire learning session with controllers only. Some reduced hosts currently depend on keyboard actions beyond their grab/trigger path.
- Ask an unfamiliar reader to devise another variation and explain its result. The author-operated three-attachment composition is one example, not independent learner evidence.
- Test comfort and performance on the actual headset.

The result is ready for external review as a coherent, executable draft. These checks do not certify the pedagogy as finished.
'''
if latest:
    ghost=ghost.replace('## Handoffs and independent actions',latest+'## Handoffs and independent actions',1)
    ghost=ghost.replace('No new engine run is claimed for this prose revision.','That prose-only revision preserved its existing evidence; the subsequent fresh run is recorded separately above.')
    ghost=ghost.replace('The first five hall results were retained during this run','The first five hall results were retained during the earlier run')
write(O/'GHOST-STUDENT.md',ghost)
brief='''# Reviewer brief — Soft Bodies

You are the ghost student: a possible future reader learning for pleasure, inquiry and the capacity to make, even in a world where an AI can produce the code faster. Melancholia can accompany that pleasure. This is a reading position, not a prediction about employment.

You are already inside the Endless Museum. Camera, player, floor, lighting, XRTools and Jolt exist. You have followed the prior spine through primitives, transformation, arrays, colour, forces, cellular automata, fractals, L-systems and procedural generation. Return to earlier concepts when a lesson explicitly names them. Some helpers and solvers are supplied; the new operation must still be visible and explainable.

Read tutorial.md for complete runnable learner code and final.md for the reflective sequence. Review one hall at a time, then the handoffs. Identify what is carried, what is supplied, what is new, what you can predict, and what you can independently change. Name an exact missing dependency or unclear instruction instead of silently inventing one.

Check that code behaviour, mathematical statement, artistic association and your felt response stay distinguishable. Does the critical writing sharpen the encounter? Does the tutorial let you reconstruct its selected operation? A museum artifact need not appear in either text.

Read GHOST-STUDENT.md and ghost-checks.json after your first pass if you want to compare with the author-operated rehearsal. Report blockers, density problems and successful transfers separately. Do not infer headset testing or independent pedagogical success from passing code assertions.

This ZIP is a review companion for the existing project, not a standalone Godot project. The nine halls/code folders contain the complete printed learner scripts and minimal study scenes; addons and explicitly supplied engine/project components remain in AdaResearch_46.
'''
write(O/'REVIEWER.md',brief)

CSS='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f3efe6;color:#24202a;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1500px;margin:auto;padding:30px 5vw}header{border-bottom:1px solid #cfc5b7}nav{display:flex;gap:12px 24px;flex-wrap:wrap;font:14px/1.6 system-ui,sans-serif}a{color:#69375f;text-underline-offset:3px}h1{font-size:clamp(34px,5vw,70px);line-height:1.07;max-width:1050px;font-weight:400;margin:24px 0}h2{font-size:30px;line-height:1.2;margin-top:40px}h3{font-size:23px}p,ul,ol{max-width:82ch}.eyebrow,.tag,summary,figcaption{font-family:system-ui,sans-serif}.eyebrow{font-size:12px;letter-spacing:.13em;text-transform:uppercase;color:#745e69}.intro{font-size:25px;max-width:850px}.note{padding:18px 22px;border-left:4px solid #9c4677;background:#e8dfe5}.cards{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}.card{background:#faf8f2;border:1px solid #d7cec2;padding:24px}.card h2{margin-top:15px;font-size:28px}.card p{font-size:17px}.card img{width:100%;height:auto;display:block}.reading{max-width:1000px}.spread{display:grid;grid-template-columns:1fr 1fr;gap:3vw;align-items:start}.spread article{min-width:0;padding:25px;background:#faf8f2;border:1px solid #d7cec2}.spread h1{font-size:36px}.spread h2{font-size:26px}pre{font:13px/1.6 ui-monospace,Consolas,monospace;background:#26252e;color:#f6f0e7;padding:22px;overflow:auto;tab-size:4}code{font-family:ui-monospace,Consolas,monospace;font-size:.86em}pre code{font-size:inherit}details{margin:22px 0;padding:14px 18px;border:1px solid #cfc5b7}summary{cursor:pointer;font-size:15px;font-weight:600}table{border-collapse:collapse;width:100%;font:15px/1.55 system-ui,sans-serif}th,td{padding:12px;border-bottom:1px solid #cfc5b7;text-align:left;vertical-align:top}figure{margin:28px 0}figure img{display:block;width:100%}figcaption{font-size:13px;color:#655967;margin-top:8px}.chapter{padding:35px 0 60px;border-bottom:1px solid #cfc5b7}.diff{font-family:ui-monospace,Consolas,monospace}.diff_header{background:#ddd6cb}footer{font:13px/1.6 system-ui,sans-serif;border-top:1px solid #cfc5b7}@media(max-width:950px){.cards{grid-template-columns:1fr 1fr}.spread{grid-template-columns:1fr}}@media(max-width:600px){.cards{grid-template-columns:1fr}header,main,footer{padding:24px}pre{font-size:11px}}@media print{header nav,footer nav{display:none}body{background:white;font-size:11pt}main{padding:0}.chapter{page-break-before:always}.cards{display:block}.card{break-inside:avoid}.spread{display:block}details{display:block}details>*{display:block!important}pre{white-space:pre-wrap;color:black;background:#f2f2f2;border:1px solid #ddd;overflow:visible}h1,h2,h3{break-after:avoid}img{max-height:20cm;object-fit:contain}}'''
def md(s,prefix,base=''):
    s=s.replace('<details>','<details markdown="1">')
    s=s.replace('/book-review/doc/book/iterations/2026-10-09-soft-bodies-three-attachments/index.html',base+'extensions/three-attachments/index.html')
    s=s.replace('](/book-review/','](http://localhost:3003/book-review/')
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes','md_in_html'])
    # Markdown expands indentation tabs; preserve the exact runnable source.
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    return re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
def page(title,body,base=''):
    nav=''.join('<a href="'+base+file+'">'+label+'</a>' for file,label in [('index.html','Sequence'),('tutorial.html','Full tutorial'),('final.html','Full reflection'),('ghost.html','Ghost review'),('changes.html','Changes'),('soft-bodies-review.zip','Review ZIP')])
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+html.escape(title)+' · Endless Museum</title><style>'+CSS+'</style></head><body><header><div class="eyebrow">Endless Museum · Soft Bodies · 9 October 2026</div><nav>'+nav+'</nav></header>'+body+'<footer>Nine halls. Tutorial left, reflection right. Existing museum captures; new text revision and executable-code rehearsal. Physical headset and independent learner review remain open.</footer></body></html>'

collected={k:'# Soft Bodies — '+('complete tutorial' if k=='tutorial' else 'complete reflective sequence')+'\n\n9 October 2026 · Nine halls in canonical spine order.\n\n' for k in ['tutorial','final']}
full={k:'<main class="reading"><h1>'+('Soft Bodies: the tutorial' if k=='tutorial' else 'Soft Bodies: the reflection')+'</h1><p>Nine halls, in the museum’s order.</p><nav>' for k in collected}
for k in full:
    for i,(name,_,_) in enumerate(ROWS):full[k]+='<a href="#'+name+'">'+str(i+1)+'. '+html.escape(titles[i])+'</a>'
    full[k]+='</nav>'
cards='';diffs='<main><h1>The passages tightened</h1><p>Text and reading structure only. All printed code blocks are unchanged.</p>'
for i,(name,tool,slug) in enumerate(ROWS):
    dest=O/'halls'/name;old=R/'doc/book/iterations'/('2026-10-09-'+slug)
    for k in collected:
        s=read(R/'commons/maps'/name/(k+'.md'))
        write(dest/(k+'.md'),s)
        collected[k]+='\n---\n\n<!-- hall:'+name+' -->\n\n'+s+'\n'
        full[k]+='<section class="chapter" id="'+name+'"><p class="eyebrow">Hall '+str(i+1)+' / 09</p>'+md(s,str(i)+'-'+k+'-')+'</section>'
        before=read(O/'before'/name/(k+'.md'))
        assert re.findall(r'```.*?```',s,re.S)==re.findall(r'```.*?```',before,re.S)
        if before!=s:
            delta=''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='before/'+name+'/'+k+'.md',tofile='current/'+name+'/'+k+'.md'))
            write(dest/(k+'-changes.diff'),delta)
            diffs+='<h2>'+html.escape(titles[i])+' · '+k+'</h2><details><summary>Read the textual changes</summary><pre>'+html.escape(delta)+'</pre></details>'
    shutil.copyfile(old/'assets'/images[i],dest/'museum.png')
    dump(dest/'capture-source.json',{'source':(old/'assets'/images[i]).relative_to(R).as_posix(),'sha256':sha(old/'assets'/images[i]),'new_capture':False,'scope':'Earlier native Godot learner comparison. Layout and code unchanged by this text pass.'})
    shutil.copyfile(R/'tools'/('test_'+tool+'.py'),dest/'evidence'/('test_'+tool+'.py'))
    shutil.copyfile(R/'tools/probes'/probes[i],dest/'evidence'/probes[i])
    navigation='<nav>'
    if i:navigation+='<a href="../'+ROWS[i-1][0]+'/parallel.html">← Previous hall</a>'
    navigation+='<a href="../../index.html">All nine halls</a>'
    if i<len(ROWS)-1:navigation+='<a href="../'+ROWS[i+1][0]+'/parallel.html">Next hall →</a>'
    navigation+='</nav>'
    body='<main>'+navigation+'<p class="eyebrow">Hall '+str(i+1)+' / 09</p><div class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(read(dest/'tutorial.md'),'t-','../../')+'</article><article><p class="eyebrow">Right · final.md</p>'+md(read(dest/'final.md'),'f-','../../')+'</article></div>'+navigation+'</main>'
    write(dest/'parallel.html',page(titles[i],body,'../../'))
    cards+='<section class="card"><a href="halls/'+name+'/parallel.html"><img loading="lazy" src="halls/'+name+'/museum.png" alt="'+html.escape(titles[i])+' — earlier native museum capture"><p class="eyebrow">Hall '+str(i+1)+' / 09</p><h2>'+html.escape(titles[i])+'</h2></a><p>'+html.escape(lessons[i])+'</p><p class="tag">'+str(checks['halls'][i]['checks'])+' executable checks passed</p></section>'
for k in collected:
    write(O/(k+'.md'),collected[k]);write(O/(k+'.html'),page(k,full[k]+'</main>'))
write(O/'changes.html',page('Changes',diffs+'</main>'))
write(O/'ghost.html',page('Ghost student', '<main>'+md(ghost,'g-')+'<p><a href="ghost-checks.json">Original test results</a> · <a href="text-revision.json">Text revision and code parity</a> · <a href="REVIEWER.md">Brief for an external reviewer</a></p></main>'))
write(O/'index.html',page('What a form can keep','<main><p class="eyebrow">Complete readings · revision and review</p><h1>What a form can keep.</h1><p class="intro">A body yields. A boundary moves. A moment becomes a sculpture. The next room asks what survived.</p><p class="note">'+str(N)+' executable checks passed across all nine halls. Read each pair below, or use the full tutorial and reflection above.</p><div class="cards">'+cards+'</div>'+md(report,'r-')+'<p><a href="GHOST-STUDENT.md">Ghost review Markdown</a> · <a href="REVIEWER.md">Reviewer brief</a> · <a href="tutorial.md">Full tutorial Markdown</a> · <a href="final.md">Full reflection Markdown</a></p></main>'))
write(O/'README.txt','Open index.html for the complete sequence, or halls/<hall>/parallel.html for facing pages. tutorial.md and final.md contain all nine current texts. GHOST-STUDENT.md records the author-operated rehearsal; REVIEWER.md is the external review brief. halls/<hall>/code contains the complete printed scripts and the minimal scene. Use these inside the existing AdaResearch_46 project, with its prepared museum, XRTools/Jolt and explicit supplied dependencies. This ZIP is not a standalone project. The nine overview captures are from earlier museum tests. extensions/three-attachments contains the additional native composition test, its pictures, complete code and retained failed attempt. The original 263-check receipt is unchanged; text-revision.json verifies this prose revision against the tested code. No physical headset or independent human learning claim. Before texts and diffs are included.\n')

class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.ids=[];self.details=0
    def handle_starttag(self,tag,attrs):
        self.links += [v for k,v in attrs if k in ['href','src'] and v]
        self.ids += [v for k,v in attrs if k=='id']
        if tag=='details':self.details+=1
    def handle_endtag(self,tag):
        if tag=='details':self.details-=1

# Retain the original test receipt; certify a prose revision only after matching
# both its tested baseline and every extracted learner file.
revisions=[]
for row in checks['halls']:
    current=R/'commons/maps'/row['map']/'tutorial.md'
    original=O/'before-feedback'/row['map']/'tutorial.md'
    assert sha(original)==row['tutorial_sha256'],row['map']
    assert re.findall(r'```.*?```',read(original),re.S)==re.findall(r'```.*?```',read(current),re.S)
    blocks=dict(re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',read(current),re.S))
    assert set(blocks)==set(row['files'])
    for name,code in blocks.items():assert hashlib.sha256((code+'\n').encode('utf8')).hexdigest()==row['files'][name]
    revisions.append({'map':row['map'],'tested_text_sha256':row['tutorial_sha256'],'current_text_sha256':sha(current),'printed_code_matches_tested_files':True})
dump(O/'text-revision.json',{'date':'2026-10-09','scope':'Prose-only revision verified against the original engine receipt. A subsequent fresh rehearsal, when present, is stored separately under ghost-rerun/.','halls':revisions,'earlier_engine_checks':N,'separate_composition_checks':extra['checks'],'subsequent_fresh_rehearsal':'ghost-rerun/ghost-checks.json' if latest else None})

archive=O/'soft-bodies-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
        if p==O/'before/execution-plan.json':continue # unrelated global lessons are not part of this review
        data=p.read_bytes()
        if p.suffix=='.html':data=data.replace(b'soft-bodies-review.zip',b'README.txt')
        z.writestr(p.relative_to(O).as_posix(),data)
refs=0;code_count=0
for p in O.rglob('*.html'):
    parser=Links();parser.feed(read(p));assert parser.details==0,p
    assert len(parser.ids)==len(set(parser.ids)),p
    for link in parser.links:
        if link.startswith(('http:','https:','data:','mailto:')):continue
        file,_,anchor=link.partition('#')
        target=p.parent/unquote(file) if file else p
        assert target.exists(),(p,link)
        if anchor:
            other=Links();other.feed(read(target));assert unquote(anchor) in other.ids,(p,link)
        refs+=1
for name,_,_ in ROWS:
    dest=O/'halls'/name
    expected=re.findall(r'```gdscript\n(.*?)\n```',read(dest/'tutorial.md'),re.S)
    got=[html.unescape(s).rstrip('\n') for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',read(dest/'parallel.html'),re.S)]
    assert got==expected,(name,len(got),len(expected))
    code_count+=len(got)
    blocks=dict(re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',read(dest/'tutorial.md'),re.S))
    for filename,code in blocks.items():assert code+'\n'==read(dest/'code'/filename)
for path,digest in json.loads(read(O/'protected-hashes.json')).items():assert sha(R/path)==digest,path
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    members=set(z.namelist())
    for name in members:
        if not name.endswith('.html'):continue
        parser=Links();parser.feed(z.read(name).decode('utf8'))
        for link in parser.links:
            if link.startswith(('http:','https:','data:','mailto:','#')):continue
            target=posixpath.normpath(posixpath.join(posixpath.dirname(name),unquote(link.split('#')[0])))
            assert target in members,(name,link)
dump(O/'validation.json',{'passed':True,'executable_checks':N,'separate_composition_checks':extra['checks'],'editorial_pass_engine_rerun':False,'subsequent_fresh_rehearsal_passed':bool(latest),'fresh_rehearsal':'ghost-rerun/validation.json' if latest else None,'current_printed_code_matches_tested_files':True,'halls':9,'printed_files':checks['printed_files'],'rendered_code_blocks':code_count,'local_references':refs,'details_balanced':True,'protected_sources_unchanged':True,'zip_crc':True,'zip_links':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(read(O/'validation.json'))
