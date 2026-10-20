from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-cloth-which-points-stay'
M=R/'commons/maps/SoftBodies_Cloth_Physics'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Cloth_Physics'
RUN=R/'ada_run/encounter_pilot/SoftBodies_Cloth_Physics/boundary'
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text(encoding='utf8'));room=json.loads((RUN/'report.json').read_text(encoding='utf8'))
assert code['passed'] and room['passed']
for log in [O/'engine.log',RUN/'engine.log']:
    text=log.read_text(encoding='utf8',errors='replace')
    assert not any(s in text for s in ['SCRIPT ERROR','Parse Error','without a physics space'])
n,q=len(code['checks']),len(room['checks']);obs=room['observations']
baseline=json.loads((O/'before/hashes.json').read_text(encoding='utf8'))
protected=[p for p in baseline if p.startswith(('algorithms/','commons/artifacts/')) or p.endswith('softbodies.json')]
for p in protected:assert sha(R/p)==baseline[p],p
before=json.loads((O/'before/commons/maps/SoftBodies_Cloth_Physics/map_data.json').read_text(encoding='utf8'))
expected=copy.deepcopy(before);expected['layers']['interactables'][5][11]=expected['layers']['interactables'][3][15];expected['layers']['interactables'][3][15]=''
assert json.loads((M/'map_data.json').read_text(encoding='utf8'))==expected
old=json.loads((O/'before/commons/data/museum/em_plan.json').read_text(encoding='utf8'))
now=json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf8'))
expected=copy.deepcopy(next(x for x in old['plans'] if x['map']==M.name));a=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console')
a['cell']=[11,5];a['tile_cell']=[11,5];a['ruled']['cell']=[11,5]
current=copy.deepcopy(next(x for x in now['plans'] if x['map']==M.name))
for row in [expected,current]:row['artifacts'].sort(key=lambda x:x['token'])
assert current==expected
for name in ['tutorial','final']:
    old=(O/f'before/commons/maps/{M.name}/{name}.md').read_text(encoding='utf8')
    new=(M/f'{name}.md').read_text(encoding='utf8')
    marker='<!-- study-spine:tension_membrane -->'
    assert old[old.index(marker):]==new[new.index(marker):],name
for name in ['assets','museum','after','probes']:(O/name).mkdir(exist_ok=True)
images=['above','entry','installed-row','installed-corners','landing-samples','membrane','student-row','student-corners','student-more-columns','with-learner-above']
for name in images:shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/'after'/name)
    if name.endswith('.md'):shutil.copyfile(M/name,O/name)
for name in ['printed','variation']:shutil.copyfile(S/'study.tscn',O/name/'study.tscn')

# Read the shared plan immediately before editing one row; keep every other decision.
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
    object='One open sheet and the inherited black PointBody; optional installed four-anchor membrane return.',
    change='Retain reference coordinates; choose the full upper row, its corners or no pins. Rebuild explicitly to restore the starting sheet.',
    dependsOn=['SoftBodies_Soft_Body_Deformation'],
    reuses='SoftBody3D construction before world entry, mesh arrays, selection conditions, unchanged PointBody contact and XRTools action/release.',
    given='Prepared Endless Museum, camera/player/floor/XRTools and Jolt. The optional tension membrane supplies its own constraint solver.',
    later='Moving attachments belong to Carusell. Solver internals and material calibration are outside this reconstruction. The optional load edit is a separate return.',
    checks=[f'{n} exact printed-code checks: row/corners/release, real vertex motion, transformed host, full subdivision edit, XRTools and point contact. Three faulty whole hosts rejected.',f'{q} native museum checks: seven real pointer controls, temporary learner host and motion, full edit, native images, clear approaches and supported route through the central doorway.'],
    transfer='Change COLUMNS 6 to 10: predict 112 to 168 entries, 8 to 12 row pins, still two corners. Explain which released upper points can move with unchanged coefficients.',
    carry='Reference coordinates select the boundary independently of visible support. Changing pin flags and rebuilding dynamic state are separate operations.',
    next='SoftBodies_Carusell: retain the selected attachment while its support is driven.',
    notes='Hall 2 draft, exact code and actual museum checks passed. Desk moved from (15,3) to (11,5) to clear arrival. Native pin-only repinning did not reliably stop already-moving entries, so learner PINS returns via a rebuild. Installed algorithms and optional membrane text unchanged. No physical headset or independent student claim.',
    summary='Carry the black point and SoftBody3D setup from the yielding cube into one open sheet. Keep its original coordinates, then select the whole upper row, just its corners, or no attachments. Hide the visual bar to distinguish a visible support from the pin rule; use the point to press the surface. Rebuild to restore the starting sheet rather than treating a new pin flag as a rewind. Increase subdivisions and predict more row entries with the same two-corner rule. The installed membrane offers an optional load comparison with four anchors held. Carry boundary selection into the next hall, where the support itself moves.')
assert row['decision']==decision
assert [x for x in plan['lessons'] if x['id']!=M.name]==[x for x in prior['lessons'] if x['id']!=M.name]
assert {k:v for k,v in plan.items() if k!='lessons'}=={k:v for k,v in prior.items() if k!='lessons'}
dump(p,plan);dump(O/'lesson-plan.json',row)

report=f'''# Which points must stay?

Soft Bodies, hall 2 of 9. The first lesson fixed one point of a yielding cube. Here the student keeps the same black PointBody, changes the closed mesh to an open sheet and selects a boundary: an upper row, its two corners, or none. The next hall will move that attachment.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter description and pin snippets; optional membrane study|A complete sheet class and host, with the inherited point included unchanged|
|Learning operation|Changing controls|Selecting a set from retained local coordinates, then predicting which entries are free|
|Transfer|No complete learner reconstruction|Change one subdivision constant: 112 → 168 entries; 8 → 12 row pins; still two corners|
|Reflection|A pin formula inside the prose|The encounter and question remain in prose; technical construction belongs to the tutorial|
|Room entrance|Desk occupied the centre arrival|Same desk moved to cell (11,5) from (15,3)|

**{n} exact-code checks and {q} actual museum checks passed.** The three printed files are extracted from tutorial.md and executed together under Jolt. Tests check real vertex motion, the fixed corners, transformed-parent coordinates, the explicit rebuild and the same point's grip/action/release. Point contact is compared with an equivalent disabled-contact host. The full subdivision edit runs as another host. Three deliberately wrong versions fail the boundary invariant: forgetting to unpin the old row, combining tests with OR, and selecting from current world coordinates instead of retained local coordinates.

## A test changed the lesson

The initial draft said that repinning a moving edge would hold it exactly where it had reached. A native run contradicted that claim: the flags were set, but newly selected entries continued to move. The tutorial now uses the clearest reliable comparison: release a row to two corners; rebuild before returning to the full row. REBUILD creates a new sheet and retains the same PointBody. This is not an assertion that a pin flag restores dynamic state.

Gold markers initially sampled positions before the body's first physics update. That also failed a transformed-parent test. They now follow the queried positions on physics steps. The small sphere's contact is resolved against a discrete cloth mesh; the contact check passes through a vertex column and compares the result with contact disabled. It does not certify gap-free contact at every point on a coarse mesh.

The installed curtain still has its existing pin toggle. We have not changed that production algorithm. The tutorial asks for the one-way row → corners → release comparison, followed by the existing REBUILD control. Runtime selection is explained without promising unrestricted capture of a moving surface.

## Inside the existing museum

The eight-strip curtain remains the main encounter. Its seven desk buttons were exercised through the real desktop pointer. The installed support can disappear while the pins remain; its physical frame and its simulated attachment are different constructions.

The learner scene was temporarily placed beside the curtain at hall-local (12.5,0,10.5), yaw 180 degrees, unit scale. Its standing approach has floor and capsule clearance. It is included as a runnable study, **not newly installed as a permanent exhibit**. Native images show the row, corners and complete subdivision edit. The released upper edge moved {obs['learner_edge_motion']:.3f} metres in the supplied hand-contact run; the image is a moment in that evolving state, not a calibrated material comparison.

The original arrival was blocked by the desk. Only that placement was moved, four metres sideways and two metres into the hall. The route then follows the side aisle, turns through the central opening into the membrane bay, and approaches the exit. All {obs['route']['samples']} samples on that route have floor support and capsule clearance. An earlier test incorrectly continued the side aisle through the dividing wall; that failed probe is retained. The wall needs a doorway route, not removal.

The view from above exposes a long empty interval between the front encounters and the membrane room. There is room to shorten that walk or articulate it later; this pass repairs arrival and teaches one boundary operation. It does not redesign the whole hall.

The four falling samples and the separate tension membrane remain. The membrane's optional tutorial and reflective passage are preserved byte for byte. Its source, the curtain source and workshop control algorithms are hash-checked unchanged. The optional supplied load-edit lesson was not independently rerun in this pass.

## Evidence and limits

The code files, learner edit, faulty controls, test scripts, hashes, engine logs and before/after texts are included in the review ZIP. These are author-led executable checks using supplied input and XRTools poses. They do not establish headset comfort, Quest performance or an independent student's understanding.

Native screenshots use the compatibility renderer and camera exposure 0.45. Lighting and physics continue between photographs, so before/after images show placement rather than identical illumination. The project logs retain unrelated UID, registry and renderer warnings; the passing runs contain no script/parse or missing-physics-space errors. Local HTML references and rendered code parity are checked; browser layout was not automated.

Next: **Carusell — the support moves**. Boundary selection is now available to reuse; it does not need to be taught again.
'''
write(O/'REPORT.md',report)
css=re.search(r"css='''(.*?)'''",(R/'tools/publish_soft_yield.py').read_text(encoding='utf8'),re.S)[1]
def md(s,prefix=''):
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    out=out.replace('href="/book-review/','href="http://localhost:3003/book-review/')
    if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
    return out
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p>ENDLESS MUSEUM · SOFT BODIES 02 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="cloth-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Actual Godot captures · executable author checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Which points stay — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md((O/f'before/commons/maps/{M.name}/{k}.md').read_text(encoding='utf8'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>Which points<br>must stay?</h1><p class="lead">One sheet. Eight attachments, then two. The same point presses the surface.</p><p class="note">Second hall of Soft Bodies. Tutorial left, reflection right. '+str(n)+' exact-code checks + '+str(q)+' native museum checks passed.</p>'
body+='<div class="pair">'+fig('assets/student-row.png','The complete learner sheet in the actual museum. Eight gold markers show the upper row; the same black PointBody waits beside it.')+fig('assets/student-corners.png','Two corners remain after a supplied grip and trigger action. Released upper vertices move; the material settings stay the same.')+'</div>'
body+='<h2>The selection survives another resolution</h2>'+fig('assets/student-more-columns.png','COLUMNS changes from 6 to 10. Twelve row attachments replace eight; the same rule still selects two corners. Full edited host, native Godot capture.')
body+='<h2>The existing encounters</h2><div class="pair">'+fig('assets/installed-row.png','The eight installed strips: the visual gantry seems to account for their suspension.')+fig('assets/installed-corners.png','The same curtain with its frame removed and only corner pins left. The architecture disappears; the attachment survives.')+'</div>'
body+='<div class="pair">'+fig('assets/landing-samples.png','Four retained falling samples meet the pan geometry. These are soft spheres, not another cloth lesson.')+fig('assets/membrane.png','The separate membrane return keeps four anchors while varying its load. Its existing tutorial and reflective text are preserved.')+'</div>'
body+='<h2>Clear the entrance</h2><div class="pair">'+fig('before-museum/entry.png','Before: the desk occupied the arrival path.')+fig('assets/entry.png','After: the desk moved aside. Its seven existing controls remain accessible.')+'</div>'
body+='<h2>Read the room from above</h2><div class="pair">'+fig('before-museum/above.png','Before: front encounters, retained raised cells and the separate membrane bay. The desk sits on the centre arrival.')+fig('assets/with-learner-above.png','After: clear arrival and a temporary learner sheet beside the curtain. The route turns through the centre doorway into the rear bay.')+'</div>'
body+='<section class="report">'+md(report)+'<p><a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></section></main>'
write(O/'index.html',page('Cloth — which points must stay?',body))
for name in ['cloth_boundary_lesson.gd','cloth_boundary_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_cloth_boundary.py','publish_cloth_boundary.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged_sources':{p:sha(R/p) for p in protected},'optional_membrane_text':'byte-identical from study marker in tutorial and reflection','checks':[n,q],'placement_delta':{'token':'soft_workshop_console','from':[15,3],'to':[11,5]},'route':obs['route'],'learner_placement':'temporary, not installed artifact','headset':False})
write(O/'README.txt','Open index.html for native museum images; parallel.html for tutorial left/reflection right. printed/ contains the complete lesson; variation/ changes only COLUMNS from 6 to 10. The three fault folders deliberately fail the boundary invariant. Run study.tscn within the prepared Endless Museum project (camera, floor, XRTools and Jolt supplied). Hall 2 of 9. Optional membrane text retained, not independently revalidated. No physical headset or independent student claim.\n')
archive=O/'cloth-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="cloth-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.ids=[]
    def handle_starttag(self,tag,attrs):
        self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
        self.ids.extend(v for k,v in attrs if k=='id')
count=0
for p in O.glob('*.html'):
    parser=Links();parser.feed(p.read_text(encoding='utf8'));assert len(parser.ids)==len(set(parser.ids))
    for link in parser.links:
        if link.startswith(('http:','https:','data:')):continue
        if link.startswith('#'):assert link[1:] in parser.ids;continue
        assert (p.parent/link.split('#')[0]).exists(),(p,link)
        count+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf8'),re.S)]
assert len(rendered)==4
for name,s in zip(['hanging_sheet.gd','study.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
dump(O/'validation.json',{'passed':True,'local_refs':count,'rendered_code_parity':3,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(json.dumps({'report':str(O/'index.html'),'checks':[n,q],'local_refs':count,'zip_MB':round(archive.stat().st_size/1e6,2)}))
