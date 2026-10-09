"""Publish the AI student rehearsal, preserving its first failed expectation."""
from pathlib import Path
from html import escape
from urllib.parse import urlsplit, unquote
import hashlib, json, re, shutil, zipfile, posixpath
import markdown
from bs4 import BeautifulSoup
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-ghost-student'
def read(p):return p.read_text(encoding='utf-8-sig')
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
d=json.loads(read(O/'checks.json'));assert d['passed'] and len(d['checks'])==76
first=json.loads(read(O/'first-run/checks.json'));assert len(first['failures'])==1
manifest=json.loads(read(O/'manifest-before.json'))
assert all(sha(R/p)==v for p,v in manifest['canonical'].items())
assert all(sha(O/p)==v for p,v in manifest['printed'].items())
reviews=[
 ('CA_Introduction','A row with neighbours',10,
  'I can account for one next cell before asking for the whole row. The ordered lookup and the separate next array give me a usable rule engine. The reflected-seed variation also works, so I can carry a relation beyond the given single and adjacent seeds. The reflection expands the board into the overhead ring without pretending the picture changes the neighbourhood. The complete display code is long, but it is identified as support; I know which functions to read first.',
  'Carry: ordered input, stored rule, old/next separation, explicit wrapping.'),
 ('CA_ElementaryRules','A state that lingers',10,
  'The three-state transition is clear enough to make the two-cell seed: both cells fade and then disappear. The gold address and the distinction between being present and being counted give the reflection something specific to work with. This was the one place I made a wrong transfer: the installed specimen has seven active neighbours after its first step, while the compact reconstruction has fourteen. Both centres still fade, then empty. The text declares different beginnings, but naming both first-step counts would make that distinction easier to retain.',
  'Carry: integer states, spatial indexing and a transition that depends on prior state as well as neighbours.'),
 ('CA_GameOfLife','Keep a generation',9,
  'Returning from a volume to a row feels purposeful: I am changing what I keep, not merely increasing dimension. I can flip the upright image while preserving the data and the supporting deck. Selecting an earlier row and stepping still evolves the latest row, exactly as the prose says. The reflection adds a different judgment—whether I want the same gaps underfoot that I enjoy in an image. The historical map name is a navigation distraction, but the lesson itself explicitly identifies Rule30.',
  'Carry: independent history, distinct indices for site/time, and receivers with different consequences.'),
 ('CA_BeyondBinary','A pattern visits an address',9,
  'The previous history makes the two-dimensional present understandable: both axes now belong to the same instant. The glider, blinker and lamp give me distinct checks for apparent movement, fixed address and one-way output. Moving SITE makes the blinker lamp alternate without changing the cells. A block placed across the periodic corner also stays stable. The reflection does its own work when it asks what I follow while a recognisable figure travels; it does not need a new programming topic to earn that question.',
  'Carry: spatial neighbourhood, birth/survival, and an output connection separate from the rule.'),
 ('CA_ExpandingSpace','The surface includes you',9,
  'This is the clearest change in my relation to the work. Previously the point carried a command; now its position enters the update. The radius conversion, strict recovery threshold and separate support threshold all survive the tests, including a rotated host. The .49 edit is small but consequential. The reflection adds the possibility that a changed route changes my next input. I can test the compact calculation; this run does not establish the experience of walking the installed bridge.',
  'Carry: explicit input, coordinate conversion, thresholded consequences and update scheduling.'),
 ('CA_SoftRules','What a neighbour offers',7,
  'A neighbour difference grows naturally out of the earlier neighbour count. The first values at W are small enough to calculate, and the matched fields make exchange visible without asking me to derive Gray–Scott. The corner seed exercise also works through the existing function. This is the largest conceptual load: two fields, a model class, textures and intervention targeting arrive together. The supplied-model boundary keeps it manageable. In the compact version, my VR trigger plants but the keyboard advances; that division needs an especially clear workflow cue.',
  'Carry: state-owning model instances, neighbour differences, shared interventions and a separate display.'),
 ('CA_AgentsCircuits','Two ways to make',8,
  'The return to Rule90 lets me compare procedures rather than learn another automaton. The three-seed edit changes the row and leaves216 copy positions untouched; translating the copying origin translates every leaf. I only need to follow the supplied recursion far enough to see what it reads. The reflection earns its question through a failed or partial visual correspondence. It prepares Fractals without requiring mastery of that next sequence now.',
  'Carry: different procedures can resemble one another; an input change can expose which procedure is active.'),
 ('CA_EdgeOfChaos','What a difference keeps',11,
  'The paired-field comparison consolidates the earlier separations: stored state, measured count, selected section and display. Integer/fractional storage and the corner edit behave as described. Common forcing cannot split identical beginnings. I can therefore explain a bright difference image without calling it amplification. The optional task finally gives me permission to select a question rather than verify the supplied one. The historical title remains a question; neither the tutorial nor these tests demonstrates a transition into chaos.',
  'Carry: matched experiments, representation limits and the ability to choose what evidence a claim requires.'),
]
report='''# Cellular Automata — ghost-student test

8 October 2026 · Eight halls · Current revised tutorial and reflective sequence

**The progression holds, and all eight printed reconstructions run in the declared Godot environment.** This fresh pass finishes with76 passing native checks. It also exposed one reading trap: I applied a result from the full museum specimen to its smaller reconstruction. That should be clarified before treating the sequence as finished.

This is an **author-informed AI rehearsal**, not a blind second-model review, an observed novice or a physical headset playtest. I read all sixteen current manuscripts, froze them, extracted the nineteen printed scripts, made separate exercise edits, wrote predictions before execution, then ran native Godot4.6 checks. Existing teacher study files were not used to fill a missing learner function. The opening's older probe was visible during discovery; this report does not claim independence from prior author knowledge.

## What ran

- All nineteen printed files loaded as the eight complete constructions in the existing museum project. A native test scene supplied the declared host, camera and light; the installed XRTools supplied pickup and release.
- Eight separate source variants exercised the requested edits. Further checks tried a reflected row seed, a Life block across a periodic corner, a translated recursive origin and other variations.
- Actual XRTools pickup/action/release ran with supplied controller poses in every hall. The exchange lesson's trigger planted; the others advanced. This is runtime interaction evidence, not tracked-hand comfort evidence.
- Native collision flags were checked for recorded tiles and decaying support. The installed halls and their connecting passages were not walked in this pass.
- The required manuscripts and all nineteen extracted originals remained unchanged throughout the trial.

The76 checks include construction, interaction and numerical assertions. They are not76 independent learning outcomes, and passing them does not certify that an unfamiliar student could explain every line.

## One failed expectation, kept in the evidence

The first run passed75 checks and failed one. I expected the compact three-state centre to have seven active neighbours after its first step. It has fourteen. The seven belongs to the installed50³ specimen; the compact7³ study starts from twelve deliberately placed cells. Its centre reads11,14,5 active neighbours over generations0,1,2, while its states are active, fading, empty.

The prose already says the beginnings differ. This is not a broken transition rule or an explicit claim that both runs have identical counts. It is a plausible mistaken transfer between the two parts of the lesson. An independent calculation from the printed seed confirmed the compact result before I corrected the test expectation. The original failure, probe and logs are retained in `first-run/`.

Smallest proposed repair, after the compact setup paragraph: **“In this small beginning, the centre reads11, then14, then5 active neighbours. Its states are active, fading, empty. The seven-neighbour example belongs to the larger installed specimen.”** No rule change is needed. This assessment leaves the canonical manuscripts unchanged.

## The capacity that accumulates

I begin able to give one cell an answer. I leave able to decide what an observation would need to establish. The route is not a ladder of ever-larger algorithms: it returns to simpler rules when history, display or comparison becomes the new subject. Those returns help the chapter cohere.

The point supplies continuity through changes in role. Code reuses the same PointBody construction; each reconstruction creates its own instance. This test does not establish persistence of one physical sphere across map loads. Its familiar appearance is useful because each lesson explicitly states what its action or position now does.

The reflections add the desire to inhabit a history, the risk of lingering on responsive support and the uncertainty of recognising a moving body. They also revisit controls and numerical distinctions. Reading both tracks in full is therefore slower than reading the tutorial alone; the strongest separation occurs where the reflection asks a question the executable example cannot settle for us.

## What to improve next

1. **Clarify the two centre counts in hall two.** This is grounded in an actual failed expectation. Keep the installed encounter and the compact reconstruction distinct at the point of prediction.
2. **Let an exercise withhold its answer briefly.** History names the six expected sites; Procedures names13 and19; the final corner exercise supplies its eight-site result and denominators. These make good worked checks, but following them is not an independent demonstration. Put the result after a prediction checkpoint or add one comparable, unanswered variation. Keep the complete runnable code.
3. **State the making workflow once.** The later compact studies use keyboard controls while their installed counterparts have nearby VR consoles. Soft Rules in particular lets the held point plant, but needs Enter/Space to advance. Say explicitly: build and inspect the miniature with desktop tools, then return to its full VR encounter—or supply a shared VR control adapter if headset-only reconstruction is the goal. No adapter has been added by this review.
4. **Make the new lines easier to locate.** Later complete examples occupy334 and382 source lines including prose and repeated helper code. The named “read these functions first” passages help. Add a small changed-operation guide or visual emphasis to the book layout before removing any necessary dependency. The PointBody copies can remain complete and clearly marked unchanged.

These are targeted editorial/workflow repairs. I would keep the eight-hall order and the division between tutorial and reflection. No missing ninth topic is needed to make this passage useful.

## Optional composition: order returns as a question

I extended the printed presence study with an ordered input record, using the array/copying skills already available. It records66 committed updates:22 near one address,22 near another,22 absent. Repeated positions remain separate. The starting field, tick and schedule remain with the record.

Replay through the unchanged `evolve` function matches every value at every update:5,280 values. Reversing those same recorded inputs changes fourteen final cell values. The question can move from *where did the hand go?* to *when did each place receive it?* This is a useful transfer because the earlier distance-filtered trace would have thrown those pauses away.

The gesture was prescribed for the test. The new result demonstrates a working composition and order dependence; it does not establish the pleasure or surprise of an improvised museum encounter. The student response is kept in `attempt/recorded_presence.gd`, separate from the required studies and from the previous author-made optional helper.

## Limits of the verdict

No compile or script error occurred. No missing required child or helper was found within the declared museum environment. These are not standalone projects; the host and XRTools are prerequisites stated by the lessons. I did not verify historical citations, Quest performance, physical headset comfort, all secondary artifacts or the complete passage through the installed halls. A fresh human or separately briefed AI reader would still be valuable for judging whether the explanations themselves are sufficient.

The strongest outcome is not the count of passed checks. It is that a new connection can now be made using operations the sequence has already made available, and that its result can be distinguished from what the display suggests.
'''
# Keep normal spacing in user-facing prose and labels.
report=re.sub(r'(?<=[A-Za-z:])(?=\d)', ' ', report)
report=re.sub(r'(?<=\d)(?=[A-Za-z])', ' ', report)
for a,b in [('11,14,5','11, 14, 5'),('0,1,2','0, 1, 2'),('11, then14, then5','11, then 14, then 5')]:report=report.replace(a,b)
hall_md='\n## Hall-by-hall reading\n\n'
for hall,title,count,paragraph,carry in reviews:
 paragraph=re.sub(r'(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])',' ',paragraph)
 hall_md+='### '+title+'\n\n'+paragraph+'\n\n'+carry+'\n\n'+str(count)+' native checks passed.\n\n'
report=report.replace('## What to improve next',hall_md+'## What to improve next')
write(O/'REPORT.md',report)
write(O/'attempt/reading-log.md','''# Reading and outside knowledge

Read in order: all sixteen frozen packet/<hall>/tutorial.md and final.md files. The repeated PointBody helper was read in the opening and its eight copies were checked identical. Read the complete review brief before testing. The prior opening row probe was visible during tool discovery; no blind-review claim is made. The latest author feedback and prior reports were already in conversation context.

Used prior knowledge: GDScript syntax, Godot Node3D/SceneTree test setup, assertions, native XRTools test-pose plumbing, Python extraction and publication. These are evaluator tools. The learner is allowed the existing museum host and XRTools as stated in each lesson. The optional response additionally uses inheritance and shallow dictionary/array snapshots, operations already present in the project; no extra serialization framework was introduced. No online research used in this test.

Fresh code is in attempt/reconstructed/, source edits in attempt/variants/, and the optional student response in attempt/recorded_presence.gd. Predictions were saved before native execution. The first failed expectation is preserved in first-run/; it was corrected only after calculating the printed compact seed independently.
''')
write(O/'attempt/README.md','''# Reconstructed student work

reconstructed/ contains nineteen files extracted verbatim from the frozen tutorials. Put each hall's files together and attach its entry script to the supplied PointStudy node, as the manuscript instructs. These files require the existing Endless Museum Godot/XRTools environment.

Entry scripts in order: row.gd, volume.gd, history.gd, life.gd, presence.gd, exchange.gd, comparison.gd, difference.gd. variants/ keeps one actual requested code edit per hall in a separate folder, with local dependencies. Some additional seed changes were made through the test harness using the same public properties; variants.json records source replacements.

recorded_presence.gd is a separate optional composition extending the reconstructed presence study. Attach it in place of presence.gd, call begin_record() after the chosen reset, then use the ordinary STEP actions. The inherited point and display are reused. play_record() replays ordered inputs; play_record(true) reverses them. Begin a new record after resetting, changing the field or schedule, or replaying; do not advance outside the recorder. Records are in memory and replay is immediate, not a paced animation or a saved file. The helper intentionally asserts when its stated recording agreement is broken.

To reproduce the automated trial in the original repository, run python -X utf8 tools/test_ca_ghost_student.py. The runner names this machine's Godot4.6 path; adjust on another machine. verification/ holds copies of the evaluator scripts for inspection. Predictions-before.md records expectations before execution. Code under reconstructed/ was never modified during testing.
''')
for path in ['tools/probes/ca_ghost_student.gd','tools/test_ca_ghost_student.py','tools/prepare_ca_ghost_student.py']:
 target=O/'verification'/Path(path).name;target.parent.mkdir(exist_ok=True);shutil.copy2(R/path,target)
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f0ede5;color:#202627;font:18px/1.65 Georgia,serif}header{background:#163d42;color:#f6eee3;padding:24px max(24px,calc((100vw - 1120px)/2))}nav{display:flex;flex-wrap:wrap;gap:24px;font:14px/1.4 system-ui}a{color:#145b64}header a{color:inherit}main{max-width:1120px;margin:auto;padding:56px 24px}h1{font-size:clamp(38px,5vw,68px);line-height:1.07;max-width:900px}h2{font-size:32px;line-height:1.2;margin-top:54px}h3{font-size:25px}p,li{max-width:80ch}.meta{font:14px/1.5 system-ui;color:#546e6c}.stats{display:flex;gap:16px;flex-wrap:wrap;margin:32px 0}.stats div{background:#fffaf1;padding:20px 30px;border-top:4px solid #d9a8bd}.stats strong{font:38px/1.2 system-ui;display:block}section.hall{margin:40px 0;background:#fffaf1;padding:30px;border:1px solid #c9ccc1}img{max-width:100%;height:auto;display:block}figure{margin:24px 0}figcaption{font:13px/1.5 system-ui;color:#536667;padding:8px 0}details{border-top:1px solid #d6d8cf;padding:16px 0}summary{cursor:pointer;font:16px/1.5 system-ui}table{border-collapse:collapse;width:100%;font:14px/1.5 system-ui}td,th{text-align:left;border-bottom:1px solid #d6d8cf;padding:10px;vertical-align:top}pre{overflow:auto;background:#182d31;color:#f3eee4;padding:20px;font:13px/1.5 monospace}footer{max-width:1120px;margin:auto;padding:30px 24px;font:13px/1.5 system-ui}@media print{nav{display:none}body{background:white}.hall{break-inside:avoid}details{display:block}}
'''
write(O/'reading.css',css)
def render(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+escape(title)+'</title><link rel="stylesheet" href="reading.css"></head><body><header><nav><a href="index.html">Ghost-student report</a><a href="#halls">Eight halls</a><a href="REPORT.md">Markdown</a><a href="attempt/predictions-before.md">Predictions before testing</a><a href="checks.json">Native checks</a><a href="ca-ghost-student-review.zip">Download test packet</a></nav></header>'+body+'<footer>AI rehearsal · Godot4.6 · Artificial controller poses · No physical headset or whole-route certification.</footer></body></html>'
body='<main><p class="meta">ENDLESS MUSEUM / CELLULAR AUTOMATA / 8 OCTOBER 2026</p><h1>The ghost student can carry the work forward.</h1><p>The eight printed reconstructions run. One mistaken transfer between the museum specimen and its miniature needs a clearer sentence.</p><div class="stats"><div><strong>8</strong>halls reconstructed</div><div><strong>19</strong>printed files unchanged</div><div><strong>76</strong>fresh checks passed</div></div><p><strong>Scope:</strong> an author-informed AI rehearsal, not a blind second reader or a physical VR playtest. First run:75/76; the one corrected expectation and its evidence are retained.</p>'
intro,tail=report.split('## Hall-by-hall reading',1)
_,ending=tail.split('## What to improve next',1)
body+=render(intro)+'<div id="halls"><h2>Eight halls, eight changes in capacity</h2>'
for hall,title,count,paragraph,carry in reviews:
 paragraph=re.sub(r'(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])',' ',paragraph)
 body+='<section class="hall" id="'+hall+'"><p class="meta">'+hall+' / '+str(count)+' CHECKS PASSED</p><h3>'+escape(title)+'</h3><p>'+escape(paragraph)+'</p><p><strong>'+escape(carry)+'</strong></p>'
 figures=re.findall(r'!\[([^\]]*)\]\((images/[^)]+)\)',read(O/'packet'/hall/'final.md'))
 if figures:
  alt,src=figures[0];body+='<details><summary>See the existing museum encounter</summary><figure><img loading="lazy" src="packet/'+hall+'/'+src+'" alt="'+escape(alt,quote=True)+'"><figcaption>Previously recorded native museum image, included as context. This test ran the printed reconstruction in a native test scene; it did not recapture or walk this installed hall.</figcaption></figure></details>'
 body+='<p><a href="packet/'+hall+'/tutorial.md">Frozen tutorial</a> · <a href="packet/'+hall+'/final.md">Frozen reflection</a></p></section>'
body+='</div>'+render('## What to improve next'+ending)
body+='<h2>Inspect the evidence</h2><ul><li><a href="first-run/checks.json">Original75/76 result</a></li><li><a href="checks.json">Final76 checks</a></li><li><a href="run-receipt.json">Fresh Godot run receipt</a></li><li><a href="attempt/recorded_presence.gd">Optional student composition</a></li><li><a href="attempt/README.md">Run the student work</a></li><li><a href="attempt/reading-log.md">Reading log and outside knowledge</a></li><li><a href="manifest-before.json">Frozen manuscript and printed-code hashes</a></li></ul></main>'
write(O/'index.html',page('CA — ghost-student assessment',body))
write(O/'README.md','''# Cellular Automata: ghost-student test packet

Extract this ZIP and open index.html. REPORT.md contains the complete assessment. The packet/ folder freezes all sixteen manuscripts and their figures. attempt/ contains code extracted only from those tutorials, actual exercise variants, pre-run predictions and the new optional student response. first-run/ preserves the failed expectation; checks.json and run-receipt.json describe the final76-check run. verification/ contains evaluator scripts.

These files require the existing Endless Museum Godot4.6 project and XRTools, as stated by the tutorials. This is not a standalone game. See attempt/README.md. The test is an author-informed AI rehearsal, not a blind independent reader or a physical headset/Quest/whole-route test. Canonical manuscripts were not edited during this assessment.
''')
soup=BeautifulSoup(read(O/'index.html'),'html.parser')
archive=O/'ca-ghost-student-review.zip'
def pack():
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
  for p in sorted(O.rglob('*')):
   if p.is_file() and p!=archive:
    name=p.relative_to(O).as_posix()
    if name=='index.html':z.writestr(name,read(p).replace('href="ca-ghost-student-review.zip"','href="README.md"').replace('>Download test packet</a>','>Package README</a>'))
    else:z.write(p,name)
pack()
links=0
for tag in soup.find_all(['a','img','link']):
 url=tag.get('href') or tag.get('src')
 if not url:continue
 u=urlsplit(url)
 if u.scheme or u.netloc:continue
 if u.path:assert (O/unquote(u.path)).is_file(),url
 if u.fragment:assert soup.find(id=unquote(u.fragment)),url
 links+=1
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for p,v in manifest['printed'].items():assert hashlib.sha256(z.read(p)).hexdigest()==v
validation={'canonical_manuscripts_unchanged':16,'printed_files_unchanged':19,'fresh_native_checks_passed':76,'first_run_passed':75,'first_run_total':76,'local_links_checked':links,'zip_crc':'passed','browser_render_checked':False,'scope':manifest['scope']}
write(O/'validation.json',json.dumps(validation,indent=2)+'\n')
pack()
print(json.dumps({'output':str(O),'links':links,'zip_mb':round(archive.stat().st_size/1024**2,2),'checks':76}))
