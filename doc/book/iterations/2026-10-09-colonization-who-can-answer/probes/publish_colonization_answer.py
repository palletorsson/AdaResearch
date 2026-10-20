from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-colonization-who-can-answer'
M=R/'commons/maps/PG_Space_Colonization';RUN=R/'ada_run/encounter_pilot/PG_Space_Colonization'
def write(p,s):p.write_bytes(s.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=json.loads((O/'before/hashes.json').read_text());code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text())
assert code['passed'] and room['passed']
for p in [O/'engine.log',RUN/'engine.log']:
    assert not any(s in p.read_text(encoding='utf-8',errors='replace') for s in ['SCRIPT ERROR','Parse Error'])
n,q=len(code['checks']),len(room['checks']);samples=room['observations']['route_samples']
protected=[p for p in before if p.startswith('algorithms/') or p.endswith(('map_data.json','proceduralgeneration.json'))]
for p in protected:assert sha(R/p)==before[p],p
runtime='commons/data/museum/em_plan.json';old=json.loads((O/'before'/runtime).read_text());new=json.loads((R/runtime).read_text())
assert next(x for x in old['plans'] if x['map']==M.name)==next(x for x in new['plans'] if x['map']==M.name)
for d in ['assets','museum','after','probes']:(O/d).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
shutil.copyfile(R/'doc/book/figures/proceduralgeneration/first-step-three-requests.png',O/'assets/first-step-three-requests.png')

p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(object='A retained attraction field, a parent-index tree and the carried PointBody advancing one generation.',
 change='Assign each request to its nearest eligible site; sum unit directions and append a fixed-length child. Keep the field and compare tips with all sites.',
 reuses='Position differences and normalization; lists, dictionaries, parent indices, deep copies, cylinders and the unchanged PointBody from Genetic Evolution.',
 given='Prepared Endless Museum and XRTools. Full nearest-site search and geometry helpers printed as support; central lesson is accumulation and eligibility.',
 later='The 96-point canopy remains an installed comparison. No collision-growing architecture, physical attraction, branch loops, biology model, or resumable held simulation.',
 checks=[f'{n} exact-printed native assertions, 60 source-step comparisons, complete weighted-vote student edit and three rejected faulty programs.',f'{q} actual-museum checks: six pointer buttons, strand/fork comparison, canopy, inherited hand action, full variation, 13 ramp samples and {samples} supported route samples.'],
 transfer='Remove only normalization of each request, keep normalization of the sum. Predict unchanged symmetric opening but a different eight-point first child; step length remains 0.5.',
 carry='Field, eligibility and combining rule are separate choices. A parent record, its drawing and physical support are separate constructions.',
 next='PG_Branching_Growth: compare one nearest invitation with a sum of requests; inspect coincident records and optional variation.',
 notes='Reconstruction complete; draft retained. Full search printed to avoid a hidden dependency, but not a second search-algorithm lesson. Learner rejects zero-sum tips; installed tips can append a zero-length child. Difference tested and declared, production unchanged. Temporary learner at hall-local (9.5,0,17), yaw180; 0.4 display scale. Independent student/headset checks open.',
 summary='Predict a half-metre child from the museum’s three requests. Rebuild the decision with position-and-parent records and the familiar point advancing each generation. Sum unit directions assigned to eligible sites; keep newborns out of the current pass. Hold the eight-point strand, change TIPS to NETWORK, and locate a real fork while the same field remains. Edit one normalization to compare equal contributions with distance-weighted contributions. Carry a clear distinction between a field, eligibility, a combining rule and the body drawn from their result.')
assert row['decision']==decision
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!=M.name)
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/PG_Space_Colonization/technical.md').read_text(encoding='utf-8')+f'''

## Reconstructed tutorial — 9 October 2026

Three full printed files: growth.gd, colony.gd and byte-identical PointBody from Genetic Evolution. The new lesson is unit-direction accumulation and eligibility; the complete nearest-site search is supporting code. Three/eight field positions exactly match the installed study. Nodes store position/parent index. Assignments read one generation, then removals and additions are applied. TIPS eligible set is childless nodes; NETWORK keeps all sites, rejects already occupied/proposed endpoints. Strict influence <8, inclusive kill <=0.32; step0.5, limits192 nodes/60generations. Ties retain first listed site. No physics attraction or branch collision.

Declared reconstruction edge: zero-sum TIPS adds no child here; installed TIPS can append a coincident child. NETWORK already guards zero sums. Tests explicitly expose the difference. Both models agree for 15 steps on each of the three/eight-point fields under both policies (60 comparisons of positions, parents and active requests). Rooted tree, not cyclic graph. Held copy contains geometry only, not field/policy/RNG or continuation state. Miniature display scale0.4 outside data; held scale0.24. Live redraw uses ordinary eight-sided CylinderMesh rods; it does not reproduce the production six-sided open mesh exactly.

Full student variant removes only per-request normalization, keeping final normalization. Eight-point raw sum(-1.5,29.5,0.9) gives child(-0.02537915,0.49912325,0.01522749); baseline(-0.04951403,0.49738270,0.01260222). Both steps0.5. Symmetric opening hides the difference. Gold vectors then mean weighted contributions, not unit directions. Complete edited program executed in headless tests and museum.

{n} exact-printed native checks PASS; 60 source-step comparisons; missing-final-normalization, always-eligible-TIPS and shallow-witness mutants rejected by their specific oracles. Complete code extracted from canonical tutorial, byte-equal to study and rendered HTML. Supplied XRTools poses tested under translated/rotated host; movement alone does not advance, trigger advances once, release parks locally. Keyboard field switch checked. Model limits, tie, removal boundary, parent topology and copy independence covered.

{q} museum checks PASS, including nine capture cameras, six actual desktop pointer buttons, fifteen-step strand/fork comparison, held persistence, 96-point canopy bounds, 13 ramp support samples and {samples} clear supported capsule samples along eastern floor route. Temporary learner placed hall-local(9.5,0,17), yaw180; approach(9.5,0,15.4). Same inherited point, code and edited variant exercised in actual isolated museum. No full portal traversal, physical headset/Quest performance or independent learner acceptance claimed. Side film artifact remains an existing encounter, not newly tested curriculum.

Baseline and final native images retained. Close learner caption is small from the wide camera; witness and distinct branches are visible. Existing rear structure appears sparse; this pass did not rebuild it. Existing UID/renderer diagnostics remain; accepted logs have no SCRIPT ERROR or Parse Error. Canonical production algorithm/wrapper/lesson/scene/map/sequence and target runtime row unchanged. Reflection retains its argument; code excerpts and operational explanation moved into tutorial. Review doc/book/iterations/2026-10-09-colonization-who-can-answer/index.html. Second of seven procedural-generation halls; Branching Growth next. Static report checks do not establish browser layout acceptance.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
    a=(O/'before/commons/maps/PG_Space_Colonization'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
    write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# Space Colonization — who can answer

The lesson now follows **one field, two eligibility policies**. The inherited point advances a generation. Under TIPS the single root develops into a strand; under NETWORK older sites may answer again and make forks. The tutorial reconstructs this in three complete files. The reflection asks whose requests the construction can receive.

The student brings vectors, parent relations, retained records and the point from earlier halls. The independent edit removes per-request normalization while keeping the final normalization: distance changes each contribution, but the new edge remains half a metre. The symmetric opening conceals this change; the eight-point field exposes it.

|Part|Before|Now|
|---|---|---|
|Tutorial|Six-step encounter outline; code delegated to the reflection|Complete model, drawing and inherited point, with explanation and a tested edit|
|Reflection|Encounter and argument with two code excerpts|Same question and route; operational code moves into the tutorial|
|Museum|Three fields, two policies, held specimen and ramp|Existing installation unchanged; temporary learner study tested behind it|
|Limits|Budget and eligibility described|Cancellation difference, scale and the scope of the held record made explicit|

**{n} code checks and {q} museum checks passed.** The baseline agrees with the installed source for 60 tested growth steps. Three faulty copies were rejected. All six real desk controls and the supplied learner hand action were exercised. The complete student edit ran inside the museum.

The two implementations have a declared edge: exactly cancelling requests can create a zero-length child under the installed TIPS policy. The small reconstruction stops that site. The production algorithm remains unchanged. Matching a silhouette would not have revealed this difference.

The room remains open around the principal study. The learner installation fits behind it, leaving the eastern route available; {samples} supported capsule samples and 13 ramp samples passed. The retained rear structure is sparse, and the wide learner views make the caption small. These are native captures of the actual museum, including the temporary student work.

The 96-point canopy and side film do not become extra programming obligations. This remains one hall about **who can answer and how requests combine**. Headset use, complete portal traversal and independent student assessment remain open. HTML and archive checks are static.

Next: **Branching Growth** — compare a sum of requests with one nearest invitation.
'''
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html').read_text(encoding='utf-8'),re.S).group(1)
def md(s,prefix=''):
    s=s.replace('/book-images/figures/proceduralgeneration/first-step-three-requests.png','assets/first-step-three-requests.png')
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
    return out
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation 02 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="colonization-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(path,caption):return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf-8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Who can answer — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for k in ['tutorial','final']:
    changes+='<h2>'+k+'.md</h2><div class="pair"><article>'+md((O/'before/commons/maps/PG_Space_Colonization'/(k+'.md')).read_text(encoding='utf-8'),'before-'+k)+'</article><article>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>Who can<br>answer?</h1><p class="lead">Keep the requests. Change which sites may respond. Find the first fork.</p>'+fig('assets/canopy.png','The installed 96-point canopy after thirty-five step requests. This larger encounter remains available beside the small lesson.')
body+='<div class="pair">'+fig('assets/strand.png','TIPS: one growing end replaces another. The original strand is held on the side plinth.')+fig('assets/forks.png','NETWORK: older sites remain eligible. The same eight points now permit forks across generations.')+'</div>'
body+='<div class="pair">'+fig('assets/student-opening.png','The complete printed program uses the inherited point to advance the first decision.')+fig('assets/student-forks.png','Printed model after fifteen NETWORK steps; smaller held TIPS specimen stays beside it.')+'</div>'
body+=fig('assets/student-weighted.png','The complete student variation: remove normalization of each request. Gold now shows distance-weighted contributions; the final edge still has fixed length.')
body+='<div class="pair">'+fig('before-captures/above.png','Before: the existing central display, comparison plinth and rear ramp.')+fig('assets/above.png','With the temporary student study in the gap behind the primary display. The eastern floor route remains available.')+'</div>'
body+=fig('assets/deck.png','The retained structure and side ramp supply collision independently of the branch records.')+md(report)+'<p><a href="checks.json">Exact-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('Space Colonization — who can answer',body))
for name in ['colonization_answer_before.gd','colonization_answer_lesson.gd','colonization_answer_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_colonization_answer.py','test_colonization_answer.py','publish_colonization_answer.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged':{p:sha(R/p) for p in protected},'runtime_row_unchanged':True,'checks':[n,q],'source_steps':60,'route_samples':samples,'images':{'baseline':4,'final':9}})
write(O/'README.txt','Open index.html for native views, parallel.html for tutorial left/reflection right. printed/ is the exact tested three-file lesson. variation/ contains the complete distance-weighted program; wrong_units/wrong_policy/wrong_hold are deliberately faulty programs. Prepared Endless Museum and XRTools required; not a standalone Godot project. Temporary learner installation, production code/map unchanged. Author-led assertions; independent student/headset acceptance remains open. Root final.md preserves canonical book-image URL; final.html packages its diagram locally.\n')
archive=O/'colonization-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="colonization-review.zip"',b'href="README.txt"')
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
for name,s in zip(['growth.gd','colony.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:','https:','#','data:')):assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_refs':refs,'unique_ids':True,'local_anchors':True,'rendered_code_parity':3,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
