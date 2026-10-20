from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-evolution-what-the-score-reads'
M=R/'commons/maps/PG_Genetic_Evolution';RUN=R/'ada_run/encounter_pilot/PG_Genetic_Evolution'
def write(p,s):p.write_bytes(s.encode('utf-8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=json.loads((O/'before/hashes.json').read_text())
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text())
assert code['passed'] and room['passed']
for p in [O/'engine.log',RUN/'engine.log']:
    assert not any(s in p.read_text(encoding='utf-8',errors='replace') for s in ['SCRIPT ERROR','Parse Error'])
n,q=len(code['checks']),len(room['checks']);samples=room['observations']['route_samples']
protected=[p for p in before if p.startswith('algorithms/') or p.endswith(('map_data.json','proceduralgeneration.json'))]
for p in protected:assert sha(R/p)==before[p],p
runtime='commons/data/museum/em_plan.json'
old=json.loads((O/'before'/runtime).read_text());new=json.loads((R/runtime).read_text())
assert next(x for x in old['plans'] if x['map']==M.name)==next(x for x in new['plans'] if x['map']==M.name)
for d in ['assets','museum','after','probes']:(O/d).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)

p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
 object='Six retained primitive candidate records, their miniatures, a score and an independent witness; the carried PointBody changes target.',
 change='Build once, evaluate records, rank a separate list, and reposition the existing bodies. Toggle an uncounted ring; change only the box coefficient in a full student variation.',
 reuses='Living design dictionaries; Shape Grammars cube; Assemblage record/reader distinction; arrays, shallow versus deep copies, functions, sorting, BoxMesh, TorusMesh and PointBody.',
 given='Prepared Endless Museum floor, camera, player and XRTools. Complete three-file learner comparison printed; installed reproduction kernel remains a supplied separate encounter.',
 later='No learner reproduction, arbitrary genome editor, exact union volume, ancestry tracking, candidate support collision or chosen-candidate pickup. Source torus omission and estimator coefficients are explicit.',
 checks=[f'{n} native exact-printed assertions,36 source score comparisons, complete coefficient edit and three rejected faulty programs.',f'{q} native museum checks including eight cameras,six actual pointer buttons,elite preservation,supplied XRTools poses,13 ramp samples and {samples} supported eastern bypass samples.'],
 transfer='Remove only the box estimator factor8. Predict ID5/scale2 now leads at target8,score100,while the same six genomes and meshes remain. The ring is still omitted.',
 carry='An evaluator reads a representation through a chosen criterion. A ranking can change without changed candidates; rank and identity do different jobs.',
 next='PG_Space_Colonization: spatial targets, site assignment and accumulated unit directions.',
 notes='First procedural-generation tutorial reconstructed; draft retained. Three files run in temporary museum gap. Target reranking reuses learner meshes although installed source rebuilds its display. Production code/map/sequence/runtime row unchanged. Headset and independent student acceptance open.',
 summary='Return to the six candidates already in the museum. Hold the leader, change target8 to16, and add a ring the score omits. Reconstruct the comparison with independent records, a pure estimate/score, a separate ranked list and the familiar point. Keep each body while its rank changes. Change only the box coefficient from8 to1; predict and execute a new leader without new genes. Return to the installed generation to see two elites carried onward, while reproduction remains supplied. Carry the distinction between a body, its representation and the criterion used to compare it.')
assert row['decision']==decision
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!=M.name)
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)
tech=(O/'before/commons/maps/PG_Genetic_Evolution/technical.md').read_text(encoding='utf-8')+f'''

## Reconstructed tutorial — 9 October 2026

Three complete files: evaluator.gd, selection.gd and byte-identical carried PointBody. Six box records retain IDs0..5 and the installed scales/positions. The pure estimator reproduces the installed box/sphere/cylinder coefficients and omitted torus. Score is100/(1+absolute difference). Ranking shallow-copies a list of references and sorts without mutating the input; equal scores choose lower ID, an explicit learner convention not declared by the source sort. HOLD deep-copies the whole record. Target changes reposition existing nodes and update captions without rebuilding meshes. The installed source itself rebuilds its display; the learner's renderer exposes the separation more directly. Only a ring edit rebuilds one body; reset rebuilds the opening six while held remains.

The bounded learner builder accepts box and torus genes only, matching their unit mesh parameters/transforms. Candidate bodies use a0.38 display scale outside their genomes; estimates remain in the original proxy units. The same point changes TARGET on held trigger; moving alone edits nothing. T/G/H/R map to target/ring/hold/reset. Release parks at local(0,1.15,1.1). All study geometry/captions are in printed code, with no scene-node references. No support collision, plinth or replacement XR system. A tested temporary host is hall-local(9.5,0,16.8),yaw180,unit scale, approach(9.5,0,15). The original museum remains in place; this is not a permanent added artifact.

{n} exact-printed native assertions pass, including36 source estimates/scores across four gene types,three positive scale settings and three targets. Known leading IDs1/2/3 for targets8/16/32;100 exact and50 one-unit scores; no input mutation; explicit ties; ring omission/restoration; retained mesh instance IDs during target change; independent witness; source mesh bounds/transforms; keyboard and supplied XRTools poses under a rotated/translated host. The complete student variant removes only the box factor8: ID5,scale2,estimate8,score100 at target8; originalID1 scores12.5. It keeps all candidate genes and geometry. Torus still omitted. Signed-distance, in-place-list-sort and shallow-witness mutants are rejected. These checks do not validate arbitrary genomes or prove every possible surface property.

{q} native museum checks pass, including eight cameras,six actual pointer buttons,unchanged candidate descriptions under target change,two unchanged elites in one source generation,held witness persistence,generation50 guard,collision-free specimens,13 supported ramp points, {samples} supported capsule samples on the eastern bypass,valid entry/exit records,clear learner bay,reachable point,supplied pickup/action/release and the full student variation in the museum. This is not a full traversal,headset/Quest-performance or independent-student test; science_screen remains outside scoring acceptance.

Four baseline and eight final native images were inspected. The first wide baseline opening included the near wall; the final camera is inside it. The first learner images showed small labels and an obstructing original cube: label pixel size increased .0012->.002 and capture camera moved closer. The earlier passing receipt/images/code are kept in first-visual-run. Final close shots expose both rankings; tiny rear captions still require approaching. TARGET and RING desk captures are darker than the opening and learner views; the cause has not been established. Retained deck/ramp and raised structures remain unchanged. Existing UID/renderer diagnostics persist; accepted logs have no SCRIPT ERROR or Parse Error.

Production GeneticProgramming,wrapper,selection lesson,scene,authored map,canonical sequence and target runtime row unchanged. final.md retains its argument and encounters; two code excerpts and their procedural explanation move to the tutorial. Review doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html. First of seven procedural-generation halls in this reconstruction pass; Space Colonization next. Static HTML/code/link/archive checks are not browser layout verification.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
    a=(O/'before/commons/maps/PG_Genetic_Evolution'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
    write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# Genetic Evolution — what the score reads

Procedural generation begins with **a candidate, a body and an evaluator**. The six existing boxes let us change the criterion while keeping what it judges. The new tutorial reconstructs that comparison; the reflection asks what the judgement leaves out.

The student brings design records from Living, the cube from Shape Grammars and the distinction between a record and its reading from Assemblage. The familiar point now changes the target. Six miniature candidates are constructed once. Changing the target reorders their existing nodes, with stable IDs and new ranks. A deep copy keeps a witness while its original changes.

The new edit has a precise consequence. Remove the box estimator's factor eight. At target 8 the largest box now scores 100, while the formerly leading unit box scores 12.5. The geometry and genes are unchanged. The ring remains omitted: one corrected term is not a complete volume measurement.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter outline; evaluator and builder supplied|Three complete files, explained ranking and a tested independent edit|
|Reflection|Argument plus two code excerpts|Same encounters and argument; code explanation moved into tutorial|
|Museum|Six-candidate study, witness and retained deck|Same installed arrangement and code; temporary learner comparison in the gap|
|Reproduction|Installed tournament/crossover/mutation kernel|Still supplied; one generation's elite preservation checked explicitly|

**{n} code checks and {q} museum checks passed.** These include 36 score comparisons with the installed source, the executed full student variation, three deliberately faulty programs rejected, all six real desk buttons, hand-action input, a supported eastern route and the retained ramp. The close learner views were improved after image inspection.

The study uses 0.38 display scale outside its genome. Its numbers describe the original estimator, not the miniature's measured volume. Candidate meshes supply no collision; the surrounding museum supplies support. The installed algorithm rebuilds its display when ranking; the compact learner program reuses its nodes. Both compute the same scores for the tested records. The learner's lower-ID tie-break is its own declared convention.

No production scoring, reproduction, scene or map logic changed. The six primary shapes are distinct in the views; small rear captions still need a closer look. Two desk-interaction captures are darker than the opening and learner views; the cause has not been established. The science screen is not connected to the evaluator. Author-led native assertions and supplied hand poses do not establish physical-headset comfort, independent learning or complete portal traversal. HTML/code/link/ZIP checks are static.

Next: **Space Colonization**. A target becomes a point in space; we will inspect which growing site receives its request.
'''
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-10-09-assemblage-the-choices-remain/index.html').read_text(encoding='utf-8'),re.S).group(1)
def md(s):
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation 01 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="evolution-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(path,caption):return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf-8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('What the score reads — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'])+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'])+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for k in ['tutorial','final']:
    changes+='<h2>'+k+'.md</h2><div class="pair"><article>'+md((O/'before/commons/maps/PG_Genetic_Evolution'/(k+'.md')).read_text(encoding='utf-8'))+'</article><article>'+md(texts[k])+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>What the<br>score reads.</h1><p class="lead">The body stays. The criterion changes. Another candidate becomes first.</p>'+fig('assets/opening.png','The installed six-candidate comparison. Pink identifies the present leader; the witness remains to the side.')
body+='<div class="pair">'+fig('assets/target.png','TARGET16 changes the ranking of the same installed descriptions.')+fig('assets/ring.png','RING changes the visible leader. The installed estimator omits its torus.')+'</div>'
body+='<div class="pair">'+fig('assets/student.png','Exact printed program in the gap behind the large comparison. The original box coefficient selects ID1 at target8.')+fig('assets/student-corrected.png','Complete student edit executed: removing the box factor8 selects ID5 at the same target. The six candidates retain their descriptions.')+'</div>'
body+=fig('assets/student-ring.png','Held-point trigger changes TARGET. The ring is another visible feature; its omission remains explicit.')
body+='<div class="pair">'+fig('before-captures/above.png','Before: the original primary comparison and retained raised structure.')+fig('assets/above.png','After: the temporary learner miniature fits in the gap. Existing architecture and eastern bypass remain.')+'</div>'
body+=fig('assets/deck.png','The retained decks and ramps supply support independently of the candidates and their scores.')+md(report)+'<p><a href="checks.json">Exact-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('Genetic Evolution — what the score reads',body))
for name in ['evolution_score_before.gd','evolution_score_lesson.gd','evolution_score_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_evolution_score.py','test_evolution_score.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged':{p:sha(R/p) for p in protected},'runtime_row_unchanged':True,'checks':[n,q],'source_comparisons':36,'route_samples':samples,'images':{'baseline':4,'final':8}})
write(O/'README.txt','Open index.html for native views, parallel.html for tutorial left/reflection right. printed/ is the exact tested three-file lesson. variation/ is the complete box-coefficient edit; wrong_score/wrong_rank/wrong_hold are deliberately faulty programs. Requires prepared Endless Museum and XRTools; not a standalone Godot project. The temporary learner study reconstructs evaluation/ranking; installed reproduction remains supplied. Production code/map unchanged. Author-led assertions, no independent student/headset claim. first-visual-run preserves the earlier smaller-label captures and source.\n')
archive=O/'evolution-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="evolution-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[]
    def handle_starttag(self,t,attrs):self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
refs=0
for p in O.glob('*.html'):
    parser=Links();parser.feed(p.read_text(encoding='utf-8'))
    for v in parser.links:
        if v.startswith(('http:','https:','#','data:')):continue
        assert (p.parent/v.split('#')[0]).exists(),(p,v)
        refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf-8'),re.S)]
assert len(rendered)==3
for name,s in zip(['evaluator.gd','selection.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:','https:','#','data:')):assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_refs':refs,'rendered_code_parity':3,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
