from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-caves-a-route-needs-room'
M=R/'commons/maps/PG_Caves_Mazes'
RUN=R/'ada_run/encounter_pilot/PG_Caves_Mazes/carving'
def write(p,s):p.write_bytes(s.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=json.loads((O/'before/hashes.json').read_text())
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text())
assert code['passed'] and room['passed']
for p in [O/'engine.log',RUN/'engine.log']:
    assert not any(s in p.read_text(encoding='utf-8',errors='replace') for s in ['SCRIPT ERROR','Parse Error'])
n,q=len(code['checks']),len(room['checks']);samples=room['observations']['route_samples']
protected=[p for p in before if p.startswith('algorithms/') or p.endswith(('map_data.json','proceduralgeneration.json','pg_workshop.gd'))]
for p in protected:assert sha(R/p)==before[p],p
runtime='commons/data/museum/em_plan.json'
old=json.loads((O/'before'/runtime).read_text());new=json.loads((R/runtime).read_text())
assert next(x for x in old['plans'] if x['map']==M.name)==next(x for x in new['plans'] if x['map']==M.name)
for d in ['assets','museum','after','probes']:(O/d).mkdir(exist_ok=True)
images=['cave-outside','cave-inside','cave-trace','maze','student-two','student-cut','above','student-three']
for name in images:shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
 object='The carried PointBody advances a retained position list through a solid-to-air carving operation.',
 change='Clear a radius-one cross for two vertical layers; repeat the same route with three layers of headroom.',
 reuses='Trace position lists, integer grid addresses, loops, bounds, cubes, and unchanged PointBody from Percolation. Introduces explicit flattening into a PackedByteArray and a carving footprint.',
 given='Prepared Endless Museum, player and XRTools. Full three-file hand model is printed. Installed biased-walk cave, backtracking maze and BSP remain comparisons.',
 later='No second random-walk implementation or full maze implementation. Air connectivity does not prove player clearance or support. Cutaway display does not carve data.',
 checks=[f'{n} exact-code checks; 18 source-kernel comparisons, independent union-of-footprints oracle, whole headroom edit, three faulty programs rejected.',f'{q} native checks: six pointer controls, actual cave-history replay, five supported mouth capsules, maze array route and removed wall colliders, inherited held action, complete edit, eight captures and {samples} side-route samples.'],
 transfer='Change only HEADROOM from 2 to 3; predict 44 to 66 empty cells on the same nine-centre route, unchanged history, retained roof, repeated visits adding history but no air.',
 carry='A route, the volume cleared around it, and its display are separate records. A connected line has no width; an empty volume still needs support and body-clearance review.',
 next='PG_Sculpted_Forms: sample positions from moving bodies and inspect what the resulting surface retains.',
 notes='Exact printed code and native museum checks passed; decision remains draft. Miniature has no collision or support. Installed production unchanged. First code run caught probe early XR type loading and one-shot park timing; restored established physics parking. First side route crossed maze wall; corrected x36 route starts beside desk, not at blocked authored entrance. No physical headset, independent student or full interior traversal acceptance.',
 summary='Use the familiar point to advance nine declared carving centres through a solid volume. Store solid and air in a flattened byte array, clear a five-cell lateral footprint across two layers, and keep repeated visits in history even when they remove nothing new. Rebuild the same route with three layers of headroom, predicting a larger void without a changed centre record. Inspect a cutaway without altering the data, compare the result with the installed cave and maze, and carry the distinction between a route, an interior and a display into Sculpted Forms.')
assert row['decision']==decision
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!=M.name)
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/PG_Caves_Mazes/technical.md').read_text(encoding='utf-8')+f'''

## Reconstructed tutorial — 9 October 2026

Full printed carver.gd/cave.gd/unchanged Percolation point_body.gd. SIZE=(7,4,7), PackedByteArray196 entries, 1=solid/0=air. Index=(y*7+z)*7+x. Radius1 clears five-cell x/z cross; headroom2, non-wrapping clipped bounds. Nine fixed route centres include one repeated entry. Route/history/volume/display kept distinct. Full route clears44cells; whole HEADROOM3 variation clears66, same history and roofy3 intact. Interior single carve10/15 cells, front-edge8/12. This is reconstruction of production _carve_ball, not another random-walk lesson. Its name does not imply a spherical footprint.

Renderer .28m cubes, basey.75, floating miniature without collision/support; nominal headroom.56m/.84m. Installed cave cells1m. Cutaway hides solid y>=2 only; data/history unchanged. Gold dots retain repeated records. Point action advances one entry; movement does not. Physics parking reused from Percolation, release returnslocal(0,1.1,1.45). Temporary host maplocal(10.5,0,10),yaw180; approach(10.5,0,8). Production cube size, walks, room and collisions untouched.

{n} exact-printed assertions PASS. Eighteen production-kernel comparisons including repeats and clipped/outside centres, independent every-cell union-of-footprints oracle, index uniqueness/strides, bounds, cursor cap, display data parity, cutaway nonmutation, restart, complete headroom variation, keyboard finish and actual XRTools pick/action/drop with supplied poses under translatedrotatedhost. Three complete faulty models rejected: square footprint, extra cleared layer, deduplicated history. First run retained under first-code-check: early probe type check loaded XRTools before its autoload; probe now dynamically inspects method. One-shot deferred release park lost to physics update; tutorial host now uses the established physics parking. Point class unchanged.

{q} native checks PASS: six actual pointer buttons/effects; installed seed1338 cave has262centres/183distinct/533air cells; replaying its entire record with source kernel reproduces volume. Five supported clear standing capsules at front mouth only, not whole cave traversal. Maze9x9 contains16 logical rooms; all visited, array entrance-to-exit reachable, open-cell wall colliders removed. Wholelearner and editedprogram agree44/66cells in actualmuseum; supplied hand action and release passed. Eight native captures. Side bypass {samples} supported clear capsules using x36 starts beside desk; first x35 path hit maze boundarywall and is retained under first-room-check. Authored entry(19.5,.05,1.5) still blocked bydesk; valid exitrecord. No fullportal/interior traversal, headset, Questperformance or independentghoststudent claim.

Before3 andfinal8 images. Finalcameraexposure.45, productionlightingunchanged. Miniature opening and cutaway inspected; fullcave andmaze remainlarger comparisons. Originalrearstructure retained. Canonical final two code blocks removed, short same-route/different-height reflection added; argument preserved. Onlytargetexecutionplan row updated, draftretained. Productionalgorithm/scene/workshop/map/sequence protected byhash; runtime targetrowunchanged. Final logs noSCRIPT/Parseerrors; preexistingUID/renderer/resource diagnostics retained. Report doc/book/iterations/2026-10-09-caves-a-route-needs-room/index.html. NextPG_Sculpted_Forms.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
    a=(O/'before/commons/maps/PG_Caves_Mazes'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
    write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# Caves and Mazes — a route needs room

The point advances a list we already understand. The new operation gives that list an interior: clear a footprint and headroom around each position. We keep the route fixed while changing the room it makes.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter prose and two short excerpts|Three complete files; byte array, carving footprint, visible model, inherited point and a tested edit|
|Student's decision|Change a seed and inspect the result|Keep nine centres; change headroom from two layers to three|
|Reflection|Route, absence, directed randomness and backtracking|Argument retained; code removed; short passage on a route admitting another body|
|Museum|Biased-walk cave, backtracking maze, BSP comparison|Existing production unchanged; student reconstruction tested in an open bay|

**{n} exact-code checks and {q} museum checks passed.** The baseline removes 44 cells; the complete headroom edit removes 66. The same nine entries remain in the operation history. One repeated centre adds an event without removing more material. Three deliberately faulty programs are rejected.

Eighteen comparisons match the installed carving operation, including boundary clipping. An independent geometric check accounts for every cell in the finished learner volume. The whole edited program runs in the actual museum. Moving the point alone does not carve; its action does.

The museum cave at seed 1338 has 262 recorded centres, 183 distinct centres and 533 empty cells. Replaying those recorded centres reproduces its volume exactly. They are several walkers' carving events, not one continuous journey. Five standing positions at its front mouth have floor and headroom. The maze also has a completed route through its array and removed colliders at its open cells. These tests do not certify every interior turn for a player.

The first code run caught an early XRTools type lookup in the test harness and a real one-shot parking problem in the host script. The point now uses its established physics parking. The first circulation route ran along the maze's outer wall; the tested x = 36 route passes outside it. Those failed receipts are preserved.

**Room finding:** the cave has room around its entrances and the maze reads clearly from above. The miniature makes the difference between route and clearance easy to compare close up; it is small in the overall room. The retained rear structure remains separate from the two main studies. The desk still blocks the authored entrance marker. The {samples}-sample bypass begins beside the desk and reaches the exit approach; complete entrance/portal traversal remains open.

The learner model floats above the floor and has no collision. Its cutaway hides layers without changing the data. It is an illustration of a carving rule, not a walkable addition to the museum. Its nominal two-layer height is 0.56 metres; the production cave's is two metres. Scale is part of the claim.

Native images use camera exposure 0.45; production lighting and placement were not changed. Physical headset use, Quest performance, independent ghost-student understanding and browser layout remain unverified. The ZIP requires the prepared museum and XRTools.

Next: **Sculpted Forms** — what can a surface keep from bodies that have moved?
'''
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html').read_text(encoding='utf-8'),re.S).group(1)
def md(s,prefix=''):
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
    return out
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation 05 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="caves-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led tests · entrance obstruction recorded · headset and independent student acceptance remain open.</footer></body></html>'
def fig(path,caption):return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf-8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('A route needs room — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article>'+md((O/'before/commons/maps/PG_Caves_Mazes'/(k+'.md')).read_text(encoding='utf-8'),'before-'+k)+'</article><article>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('What changed',changes+'</main>'))
body='<main><h1>A route<br>needs room.</h1><p class="lead">Keep the same centres. Change the space cleared around them.</p>'
body+='<div class="pair">'+fig('assets/student-two.png','Same nine entries: two layers of headroom clear 44 cells. The point advances the carving.')+fig('assets/student-three.png','The full student edit changes only HEADROOM to 3. It clears 66 cells and keeps the same recorded centres.')+'</div>'
body+=fig('assets/student-cut.png','Cutaway: the upper two layers are hidden, not removed from the data. Gold dots mark carving events; repeated entries occupy the same place.')
body+='<div class="pair">'+fig('assets/cave-outside.png','The installed cave is the full-scale comparison. Its walking and climbing rules remain unchanged.')+fig('assets/cave-inside.png','Inside the existing cave mouth with TRACE on. A route of dots and the space around it are different things.')+'</div>'
body+='<div class="pair">'+fig('assets/cave-trace.png','The existing volume has prescribed levels and openings; its centres are not an unconstrained single walk.')+fig('assets/maze.png','The finished nine-by-nine maze contains sixteen logical rooms. Backtracking remains a museum comparison, not another code obligation.')+'</div>'
body+='<div class="pair">'+fig('before-captures/above.png','Before: the existing cave, maze, BSP and retained rear structure. Earlier camera exposure.')+fig('assets/above.png','The same hall with the temporary student model beside the cave and the maze completed. Final exposure 0.45; architecture unchanged.')+'</div>'
body+=md(report)+'<p><a href="checks.json">Exact-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="first-room-check/report.json">First circulation receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('Caves and Mazes — a route needs room',body))
for name in ['caves_room_before.gd','caves_room_lesson.gd','caves_room_museum.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_caves_room.py','publish_caves_room.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged':{p:sha(R/p) for p in protected},'runtime_row_unchanged':True,'checks':[n,q],'source_comparisons':18,'route_samples':samples,'entry_obstruction_open':True,'images':{'baseline':3,'final':8},'capture_exposure':0.45})
write(O/'README.txt','Open index.html for native images, parallel.html for tutorial left/reflection right. printed/ is the exact tested three-file lesson; variation/ changes only HEADROOM to3. wrong_square/wrong_height/wrong_history deliberately fail the baseline contract. Prepared Endless Museum and XRTools required, not a standalone project. Temporary miniature; production unchanged. Side bypass and five mouth samples checked; authored entrance remains blocked by desk. First failed receipts retained. No physical headset, independent student, full interior traversal or browser-layout acceptance.\n')
archive=O/'caves-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="caves-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.ids=[]
    def handle_starttag(self,t,attrs):
        self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
        self.ids.extend(v for k,v in attrs if k=='id')
refs=0
for p in O.glob('*.html'):
    parser=Links();parser.feed(p.read_text(encoding='utf-8'));assert len(parser.ids)==len(set(parser.ids))
    for v in parser.links:
        if v.startswith(('http:','https:','data:')):continue
        if v.startswith('#'):assert v[1:] in parser.ids,(p,v);continue
        assert (p.parent/v.split('#')[0]).exists(),(p,v)
        refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf-8'),re.S)]
assert len(rendered)==3
for name,s in zip(['carver.gd','cave.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:','https:','#','data:')):assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_refs':refs,'unique_ids':True,'local_anchors':True,'rendered_code_parity':3,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
