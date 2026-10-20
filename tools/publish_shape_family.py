from pathlib import Path
from html.parser import HTMLParser
import copy, difflib, hashlib, html, json, re, shutil, zipfile
import markdown

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-shape-grammar-a-face-continues'
M=R/'commons/maps/LSystems_Shape_Grammars'
RUN=R/'ada_run/encounter_pilot/LSystems_Shape_Grammars'
def write(p,s): p.write_bytes(s.encode('utf-8'))
def dump(p,d): write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text()); room=json.loads((RUN/'report.json').read_text())
before=json.loads((O/'before/hashes.json').read_text())
assert code['passed'] and room['passed']
for p in [O/'engine.log',RUN/'engine.log']:
    assert not any(t in p.read_text(encoding='utf-8',errors='replace') for t in ['SCRIPT ERROR','Parse Error'])
n=len(code['checks']); q=len(room['checks']); samples=room['observations']['route_samples']
for folder in ['assets','museum','after','probes']: (O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'): shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']: shutil.copyfile(RUN/name,O/'museum'/name)
protected=[p for p in before if p.startswith(('commons/artifacts/','commons/mesh_grammar/'))]+['commons/maps/LSystems_Shape_Grammars/map_data.json','commons/maps/sequences/lsystems.json']
for name in protected: assert sha(R/name)==before[name],name

# Compare runtime routing by map identity, preserving concurrent unrelated work.
runtime='commons/data/museum/em_plan.json'
old=json.loads((O/'before'/runtime).read_text()); current=json.loads((R/runtime).read_text())
old_rows={p['map']:p for p in old['plans']}; new_rows={p['map']:p for p in current['plans']}
assert 'LSystems_Shape_Grammars' not in old_rows
expected=['LSystems_Grammar_Lab','LSystems_Growth','LSystems_Grammars_And_Curves','LSystems_Architecture','LSystems_Competition','LSystems_Living','LSystems_Shape_Grammars','Assemblage_Same_Desire']
assert [p['map'] for p in current['plans'] if p['sequence']=='lsystems']==expected
for index,key in enumerate(expected):
    row=new_rows[key]; assert row['pearl_index']==index and row['pearls_total']==8
    if key in old_rows:
        a=copy.deepcopy(old_rows[key]); b=copy.deepcopy(row)
        for field in ['pearl_index','pearls_total']: a.pop(field,None); b.pop(field,None)
        assert a==b,('existing L-systems geometry changed',key)
unrelated=[k for k,v in old_rows.items() if v['sequence']!='lsystems' and new_rows.get(k)!=v]
authored=json.loads((R/'commons/data/map_authored.json').read_text())
assert authored['lsystems']==expected
dump(O/'after/runtime-routing.json',{'lsystems':expected,'unrelated_rows_changed_since_baseline':unrelated,'new_hall':new_rows['LSystems_Shape_Grammars'],'scope':'Existing L-systems rows identical except route indices/count. New hall restored from its existing map; concurrent unrelated rows preserved.'})

p=R/'doc/book/course/execution-plan/plan.json'; plan=json.loads(p.read_text(encoding='utf-8')); prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']=='LSystems_Shape_Grammars')
row.update(
 object='The existing cube face family, reconstructed by a complete inset/extrusion builder and the carried PointBody.',
 change='Select seed triangles, tag their descendants, inset each towards its centroid and extrude along its normal. Repeat on tips only; retain the recipe separately.',
 dependsOn=['Primitives_Polythedra','LSystems_Grammar_Lab','LSystems_Living'],
 reuses='Indexed vertices/faces, vectors, arrays, loops, independent dictionaries and byte-unchanged PointBody. The rule now replaces mesh faces directly.',
 given='Prepared Endless Museum floor, camera, player and XRTools. Three complete files print all new geometry and controls. Six fixed family specimens and three canopy studies remain the installed comparisons.',
 later='No general mesh editor, arbitrary topology, petal builder, physics simulation or persistent cross-hall record. The study supports this bounded cube recipe, with zero to three rounds.',
 checks=[f'{n} native exact-printed checks;31 full source-mesh comparisons; one-face student program executed; ascending removal and growing-border faults rejected.',f'{q} native museum checks including ten camera checks, exact source/reconstruction surfaces and collision, supplied XRTools actions, valid portal records and {samples} supported route samples.'],
 transfer='Change only RECIPE 04 faces from [8,9] to [8]. Predict one growing tip and 48 faces; identify the untouched second top triangle. Leave and reconstruct the recipe.',
 carry='An index is a current address; a descendant tag carries the next operation. A new selection and another operation open different possibilities.',
 next='Assemblage_Same_Desire: two diagonal marks, many local choices, and the paths a reader recognises in them.',
 notes='Seventh L-systems hall reconstructed; draft decision retained. No prior tutorial.md. Missing runtime hall restored between Living and Assemblage. Production artifacts, map, canonical sequence and mesh operations unchanged. Study runs temporarily in clear centre bay; no headset or independent learner claim.',
 summary='Return to the cube family already in the room. Follow the two top triangles through inset, extrusion and three repetitions, then compare another amount and an all-face selection. Reconstruct those exact meshes with three complete files: the builder, one cycling display and the unchanged point. Select faces before replacing them, work backwards through indices, and carry growing tags only to new tips. Change the fourth recipe to one top triangle; predict and verify 48 faces and one tip. Keep the recipe distinct from the mesh, and carry the question of which operation can express the next desired form.')
assert all(a==b for a,b in zip(prior['lessons'],plan['lessons']) if a['id']!='LSystems_Shape_Grammars')
assert all(prior[k]==plan[k] for k in prior if k!='lessons')
assert row['decision']=='draft'
dump(p,plan); dump(O/'after/lesson-plan.json',row)

tech=(O/'before/commons/maps/LSystems_Shape_Grammars/technical.md').read_text(encoding='utf-8')+f'''

## Reconstructed tutorial — 9 October 2026

Three complete files: faces.gd, family.gd and the byte-unchanged Living point_body.gd. The builder exposes the production cube's eight positions/twelve index triples, selects seed indices, then propagates a growing tag. Inset replaces each selected triangle with a smaller triangle and six shoulder triangles; extrusion adds a raised triangle and six wall triangles. The selection is captured before each operation and processed in descending index order. Extrusion uses the source's 0.4m offset, 0.001 minimum area and 0.05 aspect threshold. The study accepts distinct seed indices 0..11 and zero to three rounds; inset amounts clamp to0.01..0.99. It is a bounded reconstruction of this cube family, not a general mesh-editing API.

The point cycles six independent recipes by held trigger; Space does the same and R returns to the seed. Moving the point alone changes nothing. Release parks it at host-local(0,1.15,2.2). Each display reconstructs from the original seed. It retains metre scale and aligns its lowest vertex to0.56m. No study surface collider or additional plinth is supplied. A checked host is hall-local(10.5,0,21.5), yaw180, unit scale; its approach is(10.5,0,18.4). The program appears temporarily in this bay for tests/captures and is not a permanent new museum artifact.

{n} native exact-printed checks pass, including31 complete source-mesh comparisons across six gallery recipes,24 further bounded settings and a tiny-tip guard case. Faces, positions and roles agree; counts are12/24/36/84/84/444. Six standard constructions have two indexed faces per edge and Euler characteristic2; this does not prove arbitrary self-intersection freedom. The complete student change RECIPE04.faces=[8] makes48 faces, one tip and leaves the other top triangle untouched. Two deliberate faults (ascending index removal and growing border tags) are rejected. Keyboard and supplied XRTools poses under translated/rotated hosts pass.

The first native hall launch revealed a missing em_plan/map_authored entry and fell back to Grammar Lab. Restored only this hall using the existing scoped sequence refresh; seven previous L-systems rows retain their content except indices/counts. Shape Grammars is index6, Assemblage index7, total8. Canonical map_data and sequence are unchanged. The refresh warns that the authored21m width exceeds its13–19m preference; that existing room width is preserved. Four baseline captures were made AFTER this route repair, before the learner study, and are labelled accordingly.

{q} final native museum checks pass, including ten camera checks, six family/three canopy specimens, exact triangle collision, two-sided open-strip collision, fourfold canopy mesh reuse, identical printed/source rendered triangles, {samples} supported side-route samples, valid entry/exit records, clear learner bay, supplied XRTools pickup/move/action/release and the full edited program. The first room probe expected exactly two edit records, incorrectly counting shared lobby/showing/clock fixtures as extra lesson artifacts; corrected to require each primary once. That rejected receipt is preserved. No production artifact logic was altered.

Final native views were inspected. The two-row comparison and the larger canopy have space between them; the temporary learner reconstruction fits that bay. The first-three camera clips the outer plaque edges, and fine edge overlays show some shimmer; the oblique whole-family and close study views give the complementary evidence. Existing environment UID/renderer diagnostics remain; accepted logs contain no SCRIPT ERROR or Parse Error. These are author-led native assertions and supplied input, not independent ghost-student, headset, Quest-performance or full portal-traversal acceptance. HTML/code/link/ZIP checks do not claim browser layout validation.

Reflection preserved except one sentence distinguishing changing face-list addresses from descendant tags. Its four existing images remain with portable report copies. Review: doc/book/iterations/2026-10-09-shape-grammar-a-face-continues/index.html. Seven of eight L-systems halls reconstructed; Assemblage next.
'''
write(M/'technical.md',tech)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/name); shutil.copyfile(M/name,O/'after'/name)
    bp=O/'before/commons/maps/LSystems_Shape_Grammars'/name
    a=bp.read_text(encoding='utf-8') if bp.exists() else ''
    b=(M/name).read_text(encoding='utf-8')
    write(O/'after'/(name+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+name,tofile='after/'+name)))

report=f'''# Shape Grammars — a face continues

The seventh L-systems lesson returns to the cube already in the museum. A rule now changes its face list directly. The tutorial follows one construction through six recipes while the reflection asks what those available operations allow us to desire.

## The progression

Start with the cube's two top triangles. Inset them independently: their smaller faces stay flat, with borders joining them to the old edges. Extrude the tips by forty centimetres. Repeat that pair three times. Compare a smaller inset amount, then select all twelve starting faces. A changed amount and a changed selection do different work.

The student reconstructs these exact surfaces. Three complete files include the builder, a cycling display and the unchanged PointBody. The prepared museum supplies camera, floor, player and XRTools. No hidden scene reference supplies the mesh. The small program displays one construction at a time in a clear bay between the existing collections. It is a learner installation in a working copy, not another permanent gallery object.

The new distinction is **address and continuation**. Face indices move when the list changes. A growing tag identifies the new tip for the next operation. Borders remain behind. The code makes that decision visible, alongside the centroid, normal and connections needed to build the next surface.

## An edit that can be tested

Change only the fourth recipe's selection from `[8,9]` to `[8]`. One top triangle continues; the other stays in the original cube. Predict **48 faces and one growing tip**, then run the complete edited program. Return to another recipe and rebuild: the saved selection produces the same result.

Both that edit and the original program have run inside the museum. The six installed family specimens stay available for comparison. Beyond them, the retained triangle, curved strips and fourfold canopy remain part of the wider encounter; the tutorial does not turn every visible object into another builder to learn.

|Part|Before|Now|
|---|---|---|
|Tutorial|No canonical tutorial.md|Complete explained builder, inherited point, concrete student edit|
|Reflection|The family of forms and the limits of its operations|Preserved; one sentence clarifies tags versus changing indices|
|Museum route|Hall existed in the canonical spine but was missing from runtime routing|Restored between Living and Assemblage|
|Arrangement|Six fixed family specimens and three canopy studies|Same installed arrangement; a checked temporary learner bay|

## Native evidence

- **{n} printed-program checks**, including **31 complete source-mesh comparisons**, the executed one-face variation and two rejected faulty implementations.
- **{q} museum checks**, including ten camera checks, actual displayed/collision triangles, open-surface collision, scaled canopy, hand events, portal records and **{samples} supported route samples**.
- Four baseline images after restoring the missing route, ten final native images, printed-code parity and a portable review archive.

The original artifact scripts, mesh operations, authored map and canonical sequence order are unchanged. The runtime route now includes the hall. One initial room assertion wrongly treated shared museum fixtures as extra lesson artifacts; the corrected check requires each intended collection once. Both receipts are preserved.

The photographs show the arrangement, a working bay and the executed edit. Some fine outlines shimmer and the near frontal view crops the outer plaques. These checks do not establish headset comfort, Quest performance, independent learner understanding or traversal through every portal. The report's HTML is statically checked, not browser-render verified.

## What travels onward

A rule needs a way to identify what it may change. Repetition can carry a selected face's descendants, but cannot invent an operation that the builder lacks. **Assemblage** is next: separate local choices, then the paths we recognise across them. Seven of eight halls have received this tutorial reconstruction pass.
'''
write(O/'REPORT.md',report)
css=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-10-09-competition-the-next-turn/index.html').read_text(encoding='utf-8'),re.S).group(1)
def md(s):
    rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    rendered=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],rendered,flags=re.S)
    for ref in re.findall(r'/book-images/iterations/[^"\s<>]+',rendered):
        relative=ref.removeprefix('/book-images/iterations/')
        target='reference-'+relative.replace('/','-')
        shutil.copyfile(R/'doc/book/iterations'/relative,O/'assets'/target)
        rendered=rendered.replace(ref,'assets/'+target)
    return rendered
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 07 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="shape-grammar-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led tests · physical headset and independent student review remain open.</footer></body></html>'
def fig(path,caption): return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={name:(O/(name+'.md')).read_text(encoding='utf-8') for name in ['tutorial','final']}
for name,s in texts.items(): write(O/(name+'.html'),page(name,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Shape Grammars — facing pages','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'])+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'])+'</article></main>'))
changes='<main><h1>Before and after.</h1><p>The baseline images show the existing room after restoring its missing runtime route.</p>'
for name in ['tutorial','final']:
    bp=O/'before/commons/maps/LSystems_Shape_Grammars'/(name+'.md')
    previous=md(bp.read_text(encoding='utf-8')) if bp.exists() else '<p>No canonical tutorial.md existed.</p>'
    changes+='<h2>'+name+'.md</h2><div class="pair"><article>'+previous+'</article><article>'+md(texts[name])+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>A face<br>continues.</h1><p class="lead">The cube returns. Two triangles receive the next operation; the shoulders stay behind.</p><p>'+str(n)+' printed-code checks · '+str(q)+' museum checks · 31 source-mesh comparisons</p>'
body+=fig('assets/family.png','The existing six constructions: seed, inset, extrusion, repetition, another amount and another selection. All retain metre scale.')
body+=fig('assets/first-three.png','A closer frontal view of the first three stages. The outer plaques are partly cropped; the oblique view above includes the whole family.')
body+='<div class="pair">'+fig('assets/student-seed.png','The exact printed learner program in the open bay. Its familiar point cycles the recipe; the museum stays around it.')+fig('assets/student-inset.png','Inset: each selected top triangle moves inward independently. The connecting shoulders remain in the same plane.')+'</div>'
body+='<div class="pair">'+fig('assets/student-extrude.png','One extrusion lifts the two inner triangles and joins their boundaries to the surface below.')+fig('assets/student-repeat.png','Three repetitions: two growing tips continue; the mint shoulders record the earlier steps.')+'</div>'
body+=fig('assets/student-one-face.png','The complete student edit, executed: select only face 8. One tip continues, the other top triangle stays at the cube. 48 faces, one growing tag.')
body+='<div class="pair">'+fig('before-captures/above.png','Baseline after restoring the runtime hall: two collections with a clear bay and side routes between them.')+fig('assets/student-above.png','The same overhead camera with the temporary learner reconstruction in the central bay. The gallery comparisons remain in place.')+'</div>'
body+=fig('assets/beneath.png','At 1.7m camera height beneath the existing canopy. The same surface has been enlarged four times; its boundaries remain open.')
body+=md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a> · <a href="after/runtime-routing.json">Routing check</a></p></main>'
write(O/'index.html',page('Shape Grammars — a face continues',body))
for name in ['shape_family_before.gd','shape_family_lesson.gd','shape_family_room.gd']: shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_shape_family.py','write_shape_family.py']: shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged':{name:sha(R/name) for name in protected},'checks':[n,q],'source_comparisons':31,'route_samples':samples,'images':{'baseline_after_route_repair':4,'final':10}})
write(O/'README.txt','Open index.html for native museum views; parallel.html places tutorial left/reflection right. printed/ contains the exact tested three-file program. variation/ is the complete one-face edit; wrong_order/ and wrong_tag/ are deliberate faults. Requires the prepared Endless Museum with XRTools, floor and player. Not an empty-project starter. Source specimens remain fixed; the learner program was run temporarily in the clear middle bay. Runtime routing now includes this previously omitted hall. Baseline images are after that repair. Canonical Markdown preserves its /book-images references; the HTML carries local copies for offline reading. Physical headset and independent student review remain open.\n')
archive=O/'shape-grammar-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html': data=data.replace(b'href="shape-grammar-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]
    def handle_starttag(self,tag,attrs):
        for k,v in attrs:
            if k in ['href','src'] and v: self.links.append(v)
refs=0
for p in O.glob('*.html'):
    parser=Links(); parser.feed(p.read_text(encoding='utf-8'))
    for value in parser.links:
        if value.startswith(('http:','https:','#','data:')): continue
        assert (p.parent/value.split('#')[0]).exists(),(p,value)
        refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf-8'),re.S)]
assert len(rendered)==3
for name,s in zip(['faces.gd','family.gd','point_body.gd'],rendered): assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links(); parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:','https:','#','data:')): assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_references':refs,'rendered_code_matches':3,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'runtime_hall_order':expected,'unrelated_runtime_rows_changed_since_baseline':unrelated})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
