from pathlib import Path
from html.parser import HTMLParser
import copy,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-percolation-a-contact-rule'
M=R/'commons/maps/PG_Percolation_Network'
RUN=R/'ada_run/encounter_pilot/PG_Percolation_Network'
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
images=['face-before','face-after','corner','lattice-start','lattice-reached','student-corner','student-field','above','student-edited']
for name in images:shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
 object='The carried PointBody steps a fixed set of occupied cube addresses and a separate reached set.',
 change='Propagate one face contact per generation; add one symmetric pair of corner offsets without moving the cells.',
 reuses='Integer addresses, dictionaries, seeded sampling, cube display, synchronous old/next updates from CA, and unchanged PointBody from Branching Growth.',
 given='Prepared Endless Museum and XRTools; complete three-file six-cubed reconstruction. Installed eighteen-cubed amplitude/collision model is a comparison.',
 later='No universal threshold inference, conserved-fluid claim, new grab system or proof of body access from signal reachability.',
 checks=[f'{n} exact-code assertions; 72 reached-set comparisons with production kernel; independent graph-distance oracle; full edit and three rejected faulty programs.',f'{q} native museum checks: six pointer buttons, white-to-pink collision removal, 64-step full-field projection, inherited hand action, complete edit, nine captures, {samples} supported side-route samples.'],
 transfer='Add only (1,1,1) and (-1,-1,-1) to OFFSETS. Predict chosen corner now passes, reverse passes, another corner still fails; retain exact seeded occupancy when comparing waves.',
 carry='Occupied positions, permitted contacts and reached state are separate. Signal connectivity does not provide a floor or headroom.',
 next='PG_Caves_Mazes: construct an interior and inspect carving centres, backtracking and body clearance.',
 notes='Full reconstruction tested; draft retained. Boolean reachability projection, not amplitude replay. SIZE6 versus installed18 changes random draw/address assignment. Forced whole +z source plane follows museum desk, not standalone artifact default. R restarts flow only. Authored entrance remains blocked by desk; only side bypass certified. No physical headset/independent student/browser-layout acceptance.',
 summary='Reuse the point to advance two touching cubes. Face contact transmits; corner contact does not. Store occupied addresses separately from reached addresses and use an old/next buffer so each press crosses only one allowed contact. Rebuild a small seeded lattice, preserve its occupation while restarting the wave, and add one symmetric pair of diagonal offsets. Predict which corner now connects and which still fails. Carry the distinction between a relation that transmits a signal and an interior that can support a body into Caves / Mazzes.'.replace('Mazzes','Mazes'))
assert row['decision']==decision
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!=M.name)
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
dump(p,plan);dump(O/'after/lesson-plan.json',row)

tech=(O/'before/commons/maps/PG_Percolation_Network/technical.md').read_text(encoding='utf-8')+f'''

## Reconstructed tutorial — 9 October 2026

Three printed files: reach.gd, lattice.gd, unchanged Branching Growth point_body.gd. Occupied/sources/reached are Dictionary sets with Vector3i keys and true values. SIZE6, six face offsets, synchronous reached->next copy, no boundary wrap. Generation cap64. Source set persists; R restarts wave only, unlike installed RESET to contact fixture. Local RNG seed1337, x/y/z draw order, cutoffs.2/.4/.6, whole +z face explicitly forced occupied/source. Museum desk does this at18-cubed; standalone source normally seeds only occupied boundary sites. Different dimensions remap RNG draws to addresses; not scaled copies.

Learner keeps Boolean reached projection, omits numerical flow/decay/random transfer amplitudes/CONNECTED threshold and collision. No conserved-fluid claim. Installed white cube collision disappears on becoming pink. Miniature EDGE.3 equals address spacing, no gaps, visual geometry only. Full edit adds only (+1,+1,+1),(-1,-1,-1); one diagonal orientation in both directions, not all26neighbours. Point held action advances; movement alone does not; releaseparks(0,1.1,1.5). Temporary host maplocal(8.5,0,18),yaw180, clear supported approach(8.5,0,16).

{n} exact-printed checks PASS first run. Independent BFS distance oracle matches wave fronts across20generations on3density fixtures. Seventy-two production-kernel comparisons (six small fixtures embedded in18-cubed arrays,12steps each) match reached sites, not amplitudes. Source/old-buffer independence, one-step chain, gaps, six axes, boundary, restart, nested densities, all rendered cell addresses/sizes/colours, fullvariant, supplied XRTools poses under translated/rotatedhost verified. In-place avalanche, unrequested diagonal and flow-through-empty mutants rejected. At20steps six-cubed p.2:61occupied/3reached beyond36sources/0far; p.4:108/61/4; p.6:144/104/19. Those observations are finite seed-specific examples.

{q} native museum checks PASS including9capture cameras,6actual desktop pointer buttons, real white collision removed after face transmission, retained collision at corner, sourceplane324sites, nested densities and full64step installed comparison. Printed propagation with supplied18-cubed occupancy agrees at eight checkpoints. Actual p.4 field:2483occupied,1673reached beyond324sources,81on oppositeface after64steps. Extra STEP respects64cap. Complete learner+editedmodel exercised insidehall; handmove/action/release via suppliedXRTools poses. No headset/Quest or independentstudent acceptance.

Side bypass beside dense lattice: {samples} supportedclear capsule samples, from beside desk toexitapproach. Authoredentry(13.5,.05,1.5) remains invalid/floorblocked bydesk; fullentrance/portaltraversal notcertified. Existingrearraisedstructure notcertified aswalkabledeck. Before3/final9nativephotos retained. Firstcamera set passed35checks but projectionobscuredcorner andlargefieldintrudedintostudentview; retained first-cameras/. Revisedcamera viewsfromoppositeside andresetsinstalledfield forlearnercloseups, restoresdensefield forabove. No production placement/lightingchanged. Finalcamera exposure.45 differsfrombaseline; notlightingbefore/afterclaim. Physicalview andtexturetransparency remainindependentofnumericalconnectivity.

Canonicalfinal codeexcerpt removed, opposite-face wording corrected, one short reflection onpermittingcontact added. Productionalgorithm/scene/workshop/map/sequence andruntimeplan targetrowunchanged byhash/row checks. Engineacceptedlogs have noSCRIPT/Parseerrors; pre-existingdiagnostics retained. Report doc/book/iterations/2026-10-09-percolation-a-contact-rule/index.html. Tutorialprinted/extracted/renderedcode parity andZIP/staticHTMLchecked; browserlayoutunverified. FourthofsevenPGhalls. NextPG_Caves_Mazes.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name);shutil.copyfile(M/name,O/'after'/name)
    a=(O/'before/commons/maps/PG_Percolation_Network'/name).read_text(encoding='utf-8');b=(M/name).read_text(encoding='utf-8')
    write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
report=f'''# Percolation — a rule of contact

The point still advances the work. The cubes now keep their places while a signal moves through their relations. This hall teaches **occupied cells, permitted neighbours and reached cells** as three different things.

The student starts with two cubes. Face contact transmits; corner contact does not. They reconstruct one synchronous step, then add two opposite diagonal offsets. The same corner now transmits without either cube moving. Another diagonal remains closed. This small test distinguishes the rules before a larger field makes the difference harder to read.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter outline and six offsets|Complete model, cube display and inherited point; explanation and tested student edit|
|Reflection|Contact, local definition, signal versus body|Argument retained; code removed; short passage on changing relations; opposite-face wording corrected|
|Lineage|Grid and cellular update|Those return with the familiar point; occupancy persists while reached state changes|
|Museum|Contact pair and supplied 18-cubed lattice|Production unchanged; six-cubed student reconstruction tested in an open bay|

**{n} exact-code checks and {q} museum checks passed.** These include 72 comparisons against the production update on small fixtures and an independent graph-distance check. Three faulty programs are rejected. The complete student edit runs in the actual hall.

The full installed 18-cubed field also agrees with the tutorial's Boolean propagation at eight checkpoints through 64 steps. At density0.4 and seed1337, this field has2483 occupied sites,324 supplied sources,1673 other reached sites and81 reached on the opposite face. These are observations about this finite experiment, not a universal threshold.

The small reconstruction deliberately answers only whether a site has been reached. It does not reproduce numerical flow amounts, decay or the installed collision system. The native check separately verifies that the white neighbour loses its collision after transmission. A signal route is still not a promise of floor support or headroom.

The museum desk forces the entire source plane to exist. Its standalone artifact normally supplies only occupied boundary sites. That difference is now explicit. The small and large grids also assign seeded draws to addresses differently because their dimensions differ.

**Room finding:** the existing desk blocks the authored entrance marker. The tested bypass starts beside it; {samples} supported clear samples reach the exit approach even with the dense lattice present. Complete entrance/portal traversal remains open. The overhead image shows space between the main field, the student bay and the retained rear structure; the large field needs that room, though its two-cell opening can look sparse.

First camera views concealed the corner relation and let the large field intrude into the close student view. The revised captures use the opposite side and reset the installed lattice for the learner closeups. The dense field returns for the overhead view. Both camera sets are retained. Final camera exposure is0.45; lighting and production geometry were not changed.

These are author-led native tests. Physical headset use, Quest performance, independent ghost-student understanding and browser layout remain unverified. The ZIP requires the prepared museum and XRTools; it is not a standalone project.

Next: **Caves / Mazes** — construct an interior that can receive a body.
'''
for a,b in [('density0.4','density 0.4'),('seed1337','seed 1337'),('has2483','has 2483'),(',324',', 324'),(',1673',', 1673'),('and81','and 81'),('is0.45','is 0.45')]:report=report.replace(a,b)
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html').read_text(encoding='utf-8'),re.S).group(1)
def md(s,prefix=''):
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
    return out
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation 04 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="percolation-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led tests · entry obstruction recorded · headset and independent student acceptance remain open.</footer></body></html>'
def fig(path,caption):return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf-8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('A contact rule — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>Before and after.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article>'+md((O/'before/commons/maps/PG_Percolation_Network'/(k+'.md')).read_text(encoding='utf-8'),'before-'+k)+'</article><article>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>What counts<br>as contact?</h1><p class="lead">Keep the cubes where they are. Change which relation may carry the signal.</p>'
body+='<div class="pair">'+fig('assets/student-corner.png','Six face neighbours: the white cube stays unreached at this corner contact.')+fig('assets/student-edited.png','The complete student edit admits this diagonal in both directions. The same cube now turns pink.')+'</div>'
body+=fig('assets/student-field.png','The same complete program in a six-cubed field. Dark pink marks the supplied source face; white sites have not been reached.')
body+='<div class="pair">'+fig('assets/face-before.png','Existing museum face contact: white has collision; the pink source does not.')+fig('assets/face-after.png','After STEP: the neighbouring cube becomes transparent pink and loses its collision. The signal and the visitor meet different conditions.')+'</div>'
body+='<div class="pair">'+fig('assets/lattice-start.png','The installed eighteen-cubed field before propagation, density 0.4 and seed 1337.')+fig('assets/lattice-reached.png','After 64 generations: 81 reached cells lie on the opposite z face in this particular field.')+'</div>'
body+='<div class="pair">'+fig('before-captures/above.png','Before: the two-cell opening leaves most of the front court empty. Earlier camera exposure.')+fig('assets/above.png','Dense installed field and the small student study. The side bypass stays outside both. Camera exposure 0.45; lighting unchanged.')+'</div>'
body+=md(report)+'<p><a href="checks.json">Exact-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="first-cameras/report.json">First camera receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html',page('Percolation — a rule of contact',body))
for name in ['percolation_contact_before.gd','percolation_contact_lesson.gd','percolation_contact_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_percolation_contact.py','test_percolation_contact.py','publish_percolation_contact.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged':{p:sha(R/p) for p in protected},'runtime_row_unchanged':True,'checks':[n,q],'source_steps':72,'full_lattice_steps':64,'full_lattice_checkpoints':8,'route_samples':samples,'entry_obstruction_open':True,'images':{'baseline':3,'final':9},'capture_exposure':0.45})
write(O/'README.txt','Open index.html for native images, parallel.html for tutorial left/reflection right. printed/ is the exact tested three-file lesson; variation/ adds one symmetric diagonal contact pair. wrong_buffer/wrong_contact/wrong_empty deliberately fail the baseline contract. Prepared Endless Museum and XRTools required, not a standalone project. Temporary learner installation; production unchanged. Side bypass checked; authored entrance remains blocked by desk. First camera set retained. No physical headset, independent student or browser-layout acceptance.\n')
archive=O/'percolation-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="percolation-review.zip"',b'href="README.txt"')
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
for name,s in zip(['reach.gd','lattice.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:','https:','#','data:')):assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_refs':refs,'unique_ids':True,'local_anchors':True,'rendered_code_parity':3,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
