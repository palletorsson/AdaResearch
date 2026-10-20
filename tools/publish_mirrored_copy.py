from pathlib import Path
from html.parser import HTMLParser
import copy, difflib, hashlib, html, json, re, shutil, zipfile
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-mirrored-a-copy-kept'
M = R / 'commons/maps/PG_Mirrored_Patterns'
RUN = R / 'ada_run/encounter_pilot/PG_Mirrored_Patterns/copy'
FILES = ['reflection.gd', 'panels.gd', 'point_body.gd']
def write(p, s): p.write_bytes(s.encode('utf-8'))
def dump(p, d): write(p, json.dumps(d, ensure_ascii=False, indent=2) + '\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

before = json.loads((O / 'before/hashes.json').read_text())
code = json.loads((O / 'checks.json').read_text())
room = json.loads((RUN / 'report.json').read_text())
assert code['passed'] and room['passed']
for p in [O / 'engine.log', RUN / 'engine.log']:
    assert not any(s in p.read_text(encoding='utf-8', errors='replace') for s in ['SCRIPT ERROR', 'Parse Error'])
n, q = len(code['checks']), len(room['checks'])
obs = room['observations']
route = obs['route']
field = obs['field']
protected = [p for p in before if p.startswith(('algorithms/', 'commons/primitives/')) or p.endswith(('map_data.json', 'proceduralgeneration.json', 'pg_workshop.gd'))]
for p in protected: assert sha(R / p) == before[p], p
runtime = 'commons/data/museum/em_plan.json'
old = json.loads((O / 'before' / runtime).read_text())
new = json.loads((R / runtime).read_text())
assert next(x for x in old['plans'] if x['map'] == M.name) == next(x for x in new['plans'] if x['map'] == M.name)
for d in ['assets', 'museum', 'after', 'probes']: (O / d).mkdir(exist_ok=True)
images = ['field-opening', 'field-held', 'field-quad', 'network-tree', 'network-rhizome', 'network-surface', 'network-severed', 'student-input', 'student-reflection', 'student-axes', 'above']
for name in images: shutil.copyfile(RUN / (name + '.png'), O / 'assets' / (name + '.png'))
for name in ['report.json', 'engine.log', 'source_manifest.json']: shutil.copyfile(RUN / name, O / 'museum' / name)

p = R / 'doc/book/course/execution-plan/plan.json'
plan = json.loads(p.read_text(encoding='utf-8')); prior = copy.deepcopy(plan)
row = next(x for x in plan['lessons'] if x['id'] == M.name); decision = row['decision']
row.update(
    dependsOn=['PG_Sculpted_Forms', 'CA_Introduction'],
    object='A held five-by-five field, a separate reflected result and the carried PointBody.',
    change='Copy the upper-left quarter to its three partners while preserving the input; extend the odd-grid loop to include the centre axes.',
    reuses='Nested arrays, old-to-new updates, coordinates, cubes, reflection and unchanged Sculpted Forms PointBody. A retained input is distinct from a displayed result.',
    given='Prepared Endless Museum, player/camera/XRTools. All three learner files printed. Existing cellular field, network specimen and pattern tunnel remain comparisons.',
    later='No second Life implementation or full graph generator. Native network shell has collision disabled; image copying does not create a walkable connection.',
    checks=[f'{n} exact-code checks; 32 whole-field production comparisons; independent destination oracle; complete axis edit; three complete faulty hosts rejected.',f'{q} native checks: six pointer controls, deterministic Life-before-copy order, actual held input versus printed model, graph metrics/collision, learner action/release, complete edit and eleven captures.'],
    transfer='Set INCLUDE_AXES true. Predict row [0,1,1,1,0], column [1,0,1,0,1]. Four cells differ from baseline, but both contain thirteen ones. Predict another odd field; even fields should be unchanged by the edit.',
    carry='A held record, a copying policy and a result remain distinct. An aggregate count does not establish symmetry, connectivity or bodily access.',
    next='Procedural Generation complete for review; collect all seven hall tutorials/reflections and inspect the sequence as a whole before starting another sequence.',
    notes='29 exact-code checks and native checks passed; draft retained. Baseline matches installed quadrant loop and leaves centre cross unchanged. Axis-inclusive variant is an explicit student extension, not a production fix. Room entry still blocked by desk; separate side bypass measured. No headset, Quest or independent student claim.',
    summary='Keep an independent copy of a five-by-five field beside its reflected result. Use the carried point to apply the installed quadrant rule, observing that the centre cross is left alone. Edit the displayed result and distinguish discarding that edit from explicitly holding it as a new input. Extend the loop to include the axes; predict four changed cells while the number of ones stays thirteen. Compare image copying with the separate network specimen, and finish the sequence with a precise distinction between held data, operations and the opportunities a built result provides.')
assert row['decision'] == decision
assert all(a == b for a, b in zip(prior['lessons'], plan['lessons']) if a['id'] != M.name)
assert all(prior[k] == plan[k] for k in prior if k != 'lessons')
dump(p, plan); dump(O / 'after/lesson-plan.json', row)

tech = (O / 'before/commons/maps/PG_Mirrored_Patterns/technical.md').read_text(encoding='utf-8') + f"""

## Reconstructed tutorial — 9 October 2026

Full reflection.gd/panels.gd/unchanged Sculpted point_body.gd. Held nested array deep-copied with duplicate(true); result independently copied. Each reflect starts from held, copies upper-left n/2 rows/columns to three partners using n-1-address. Production quadrant operation deliberately leaves odd centre cross unchanged. Complete INCLUDE_AXES=true variant extends limit by n%2; centre maps to itself. Five-by-five fixture baseline13ones, edited13ones; four changed cells between results. Baseline6diffsfrominput, edited10diffsfrominput. Predict centre row0,1,1,1,0 andcolumn1,0,1,0,1. Even fields unaffected by includeaxes.

Three-file host builds fifty .144m-wide box faces spaced.16m, zthickness.04. Dark/light=0/1; dark/lightpink=0/1 oncentreaxes. Leftinput/rightresult. Action/SPACEreflect,Voriginal,Mflipresult[2][4],Hholdresult,Rresetfixture. Moveheldpointdoesnotcopy;releasephysicsparkslocal(0,1.1,1.2). No undeclaredscene nodes, no learnercollision. Temporarymaplocal(8.5,0,6.5),yaw180;approach(8.5,0,4.5). Production unchanged.

{n} exactprintedchecksPASS. 32fullfieldcomparisons (sizes1,2,3,4,5,6,7,31 xfourfixturesincludingdistinctaddressvalues) matchproduction apply_quad_symmetry. Independentdestinationoracle checks alladdresses; input/caller nonmutation, idempotence, even/oddaxes, sample predictions, snapshotofresultalias, fullhost50cells/materialdatamatch,HOLD/M/RESET/keyboard, suppliedactualXRToolspick/action/drop undertranslatedrotatedhost. Entire studentedit andthreecompletefaultyhosts tested; wrongrowalias,offbyonepartner,notrestoringheld rejected. NoSCRIPT/Parseerrors acceptedlogs; existingprojectUID/rendererwarnings retained.

{q} nativechecksPASS. Realpointer STEP,HOLD,STENCIL,NETWORK,SURFACE,RULE; actualfield31x31 opens182live, STEPnone229live, heldquad233live. Printedreflection matchesactualheldarray. STEPcheckedasLife(displayed)thenquad withfixedborder/probabilities1; heldunchanged. Cyclingnone restoresheld rather thanlatestgeneration. Actualnetwork6nodes:tree5edges/1component/0cycles;rhizome11/1/6;severed2/4/0. Metrics deduplicate undirected records; seedpositionspreserved, severedfinalnodesmaymove. Bothsurfaceandbareviews collisiondisabled. Fullstudentbaselineandaxisvariant runintheexistingroom, suppliedXRTools action/releaseverified. Elevennativeimages includeheldstateAFTERSTEP/HOLD beforequad;firstcamera receiptretainedwhereopeningandquadinputdiffered. Captions distinguish opening,held,andreflected states.

Sidebypass{route['samples']}capsules supported={route['supported']},clear={route['clear']};startbesidedeskat(20,0,3.5),x28to44.5,rearx16.5toexit46.5. Authoredentry(16.5,.05,1.5)stillblockedbydesk. Locallearneranddeskapproachesclearandsupported. Notfullportal/playertraversal;networkspecimen deliberatelynoncolliding. Overheadshowsclearprincipalstations,effectofvisuallydominantpatterntunnel,andveryemptyrearcourt. Noarchitecturechange. Cameraexposure.45. Beforethreeimages/finaleleven. Noheadset/Quest/independentstudent/browserlayoutacceptance.

Canonicalfinalcodeexcerptreplacedwithproseandcentre-crossobservation;existingnetworkreflection/footnote/SoftBodieshandoffretained. Onlytargetexecutionplanrowupdated,draftretained; dependencies now Sculpted Forms/CA Introduction, no prerequisite symmetry or graph course. Algorithm/scene/workshop/map/sequencehashesprotected;runtimeplantargetrowunchanged. Review doc/book/iterations/2026-10-09-mirrored-a-copy-kept/index.html. Next:wholeProceduralGenerationreadings/review.
"""
write(M / 'technical.md', tech)
for name in ['tutorial.md', 'final.md', 'technical.md', 'map_data.json']:
    shutil.copyfile(M / name, O / name); shutil.copyfile(M / name, O / 'after' / name)
    a = (O / 'before/commons/maps/PG_Mirrored_Patterns' / name).read_text(encoding='utf-8')
    b = (M / name).read_text(encoding='utf-8')
    write(O / 'after' / (name + '.diff'), ''.join(difflib.unified_diff(a.splitlines(True), b.splitlines(True), fromfile='before/' + name, tofile='after/' + name)))

report = f"""# Mirrored Patterns — a copy kept

A held input sits beside a reflected result. The familiar point commits the copying operation. The lesson finishes this sequence by making the relationship between a record and an operation something the student can inspect, change and test.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter prose and two reflected assignments|Three complete files: independent nested arrays, copying loop, visible comparison and carried point|
|Student's decision|Broad symmetry comparison|Include the centre axes and predict exactly which addresses change|
|Reflection|Copying an image versus connecting a path|Argument retained; code excerpt replaced with prose; the centre cross makes the limit observable|
|Museum|Cellular field, network, pattern tunnel|Existing production unchanged; a temporary paired learner display tested in front of the field|

**{n} exact-code checks and {q} native museum checks passed.** Thirty-two fields across eight sizes match the installed quadrant function. A second, destination-based oracle checks every output address. Three complete broken hosts are rejected: shared rows, a wrong mirror address, and an operation that fails to return to its held input.

The original loop uses one quarter of the array and leaves the centre row and column alone. The student changes one constant to include those axes. Four cells then differ from the baseline result, while both still contain thirteen ones. The count remains true; it is insufficient to establish symmetry. The panel's displayed differences are measured against the input: six for the baseline and ten for the edit.

M changes the result. REFLECT discards that unheld change. H deliberately keeps it as the new input. The left panel makes that commitment visible. Deep copies keep editing from quietly changing the witness. Moving the point alone does not invoke the rule.

The museum field opens with {field['opening_live']} lit cells. One deterministic cellular step followed by HOLD retains {field['held_live']}; quadrant reflection gives {field['quad_live']}. The paired field images below compare that same held input before and after copying. The opening is shown separately. STEP reads the displayed field, evolves it and then applies symmetry; STENCIL instead begins again from the held field. These orders are tested explicitly.

The network remains a comparison, not a second tutorial implementation. Six seed positions produce these measured graph counts:

|Policy|Unique edges|Components|Independent cycles|
|---|---:|---:|---:|
|Tree|5|1|0|
|Rhizome|11|1|6|
|Severed|2|4|0|

The generator may store both directions of an edge; the counts use one undirected connection. Its surface is noncolliding in both shown and hidden states. The opaque shell makes the connections harder to read, which is why the bare view matters. No claim of walkable tunnel access follows from those graph counts.

**Room finding:** the three main encounters have separate space, and the pattern tunnel gives the room a strong middle axis. The learner panels make a useful close comparison in front of the larger floor field. The rear court remains quite empty; the retained older room is separate. A {route['samples']}-sample side bypass has support and capsule clearance. The authored entrance is still obstructed by the control desk. This pass documents that issue without changing production placement.

There are eleven new native images and three baseline views. Camera exposure is 0.45; museum lighting and architecture are unchanged. The first image set lacked the newly held field as a separate view; that set is preserved, and the final set includes it so the comparison does not confuse a cellular step with reflection.

The exact printed programs run in the prepared Endless Museum with XRTools. Physical headset use, Quest performance, full portal traversal and an independent ghost student's understanding remain open. The example is tested code with a visible student edit, not a claim of complete room acceptance.

This completes the seventh tutorial draft in Procedural Generation. Next is a combined reading of all seven tutorials and reflections, to judge the sequence together.
"""
write(O / 'REPORT.md', report)
css = re.search(r'<style>(.*?)</style>', (R / 'doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html').read_text(encoding='utf-8'), re.S).group(1)
def md(s, prefix=''):
    out = markdown.markdown(s, extensions=['fenced_code', 'tables', 'footnotes'])
    blocks = iter(re.findall(r'```gdscript\n(.*?)\n```', s, re.S))
    out = re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)', lambda m: m[1] + html.escape(next(blocks) + '\n') + m[2], out, flags=re.S)
    if prefix: out = re.sub(r'(id="|href="#)(fn[^" ]*)', lambda m: m[1] + prefix + m[2], out)
    return out
def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + css + '</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation 07 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="mirrored-review.zip">Review ZIP</a></nav></header>' + body + '<footer>Native Godot evidence · author-led checks · room obstruction recorded · headset and independent student acceptance remain open.</footer></body></html>'
def fig(path, caption): return '<figure><img loading="lazy" src="' + path + '" alt="' + html.escape(caption, quote=True) + '"><figcaption>' + html.escape(caption) + '</figcaption></figure>'
texts = {k: (O / (k + '.md')).read_text(encoding='utf-8') for k in ['tutorial', 'final']}
for k, s in texts.items(): write(O / (k + '.html'), page(k, '<main><article>' + md(s) + '</article></main>'))
write(O / 'parallel.html', page('A copy kept — facing texts', '<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>' + md(texts['tutorial'], 't-') + '</article><article><p class="eyebrow">Right · final.md</p>' + md(texts['final'], 'f-') + '</article></main>'))
changes = '<main><h1>Before and after.</h1>'
for k in texts:
    changes += '<h2>' + k + '.md</h2><div class="pair"><article>' + md((O / 'before/commons/maps/PG_Mirrored_Patterns' / (k + '.md')).read_text(encoding='utf-8'), 'before-' + k) + '</article><article>' + md(texts[k], 'after-' + k) + '</article></div>'
write(O / 'changes.html', page('What changed', changes + '</main>'))
body = '<main><h1>A copy<br>kept.</h1><p class="lead">The input stays beside the result. Four cells change; the count stays the same.</p>'
body += '<div class="pair">' + fig('assets/student-reflection.png', 'Baseline reflection. The held input stays on the left; the centre cross on the right is untouched. Six cells differ from the input.') + fig('assets/student-axes.png', 'Complete student edit: INCLUDE_AXES true. Four more addresses change, ten differences from the input. Both results contain thirteen ones.') + '</div>'
body += fig('assets/student-input.png', 'Opening: two equal fields and the inherited point. Holding and reflecting are separate actions.')
body += '<h2>The same held field</h2><div class="pair">' + fig('assets/field-held.png', 'The installed field after one cellular step and HOLD: 229 live cells. This is the input for the following reflection.') + fig('assets/field-quad.png', 'Quadrant copying from that held input: 233 live cells. The printed model matches every address.') + '</div>'
body += fig('assets/field-opening.png', 'Earlier opening: authored arithmetic field, 182 live cells. This precedes the cellular step and is not the input used in the paired comparison above.')
body += '<h2>Connections need their own test</h2><div class="pair">' + fig('assets/network-tree.png', 'Tree: six nodes, five unique edges, one component, no cycles.') + fig('assets/network-rhizome.png', 'Rhizome: the same seed positions, eleven unique edges, one component and six independent cycles.') + '</div>'
body += '<div class="pair">' + fig('assets/network-surface.png', 'The rhizome with its generated surface shown. Collision is disabled; an impressive shell does not prove an accessible route.') + fig('assets/network-severed.png', 'Severed: two remaining edges and four components. The policy also displaces final positions to open its gap.') + '</div>'
body += '<h2>The room from above</h2><div class="pair">' + fig('before-captures/above.png', 'Before: the floor field, central pattern tunnel, tree specimen and retained rear room.') + fig('assets/above.png', 'After: temporary student panels in front of the field; the field has been stepped and reflected, network severed. Architecture unchanged; exposure 0.45.') + '</div>'
body += md(report) + '<p><a href="checks.json">Exact-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O / 'index.html', page('Mirrored Patterns — a copy kept', body))
for name in ['mirrored_copy_before.gd', 'mirrored_copy_lesson.gd', 'mirrored_copy_room.gd']: shutil.copyfile(R / 'tools/probes' / name, O / 'probes' / name)
for name in ['write_mirrored_copy.py', 'test_mirrored_copy.py', 'publish_mirrored_copy.py']: shutil.copyfile(R / 'tools' / name, O / 'probes' / name)
dump(O / 'manifest.json', {'canonical': {name: sha(M / name) for name in ['tutorial.md', 'final.md', 'technical.md', 'map_data.json']}, 'printed': json.loads((O / 'printed-hashes.json').read_text()), 'unchanged': {p: sha(R / p) for p in protected}, 'runtime_row_unchanged': True, 'checks': [n, q], 'source_comparisons': code['source_comparisons'], 'field': field, 'graphs': obs['graphs'], 'route': route, 'entry_obstruction_open': True, 'images': {'baseline': 3, 'final': len(images)}, 'capture_exposure': 0.45})
write(O / 'README.txt', 'Open index.html for museum images; parallel.html for tutorial left/reflection right. printed/ has the exact three-file lesson; variation/ changes only INCLUDE_AXES to true. wrong_alias/wrong_address/wrong_input are deliberate faulty full programs. Prepared Endless Museum and XRTools required. Temporary display, production unchanged. Original quadrant rule omits odd centre axes; extending it is the student edit. 29 exact-code assertions, 32 source-field comparisons, independent oracle and native checks. Entrance remains obstructed by desk. Network shell deliberately noncolliding. Supplied hand poses are not a physical headset or independent student.\n')
archive = O / 'mirrored-review.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip', '.uid'] and p.name != 'validation.json':
            data = p.read_bytes()
            if p.suffix == '.html': data = data.replace(b'href="mirrored-review.zip"', b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(), data)
class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links = []; self.ids = []
    def handle_starttag(self, t, attrs):
        self.links.extend(v for k, v in attrs if k in ['href', 'src'] and v)
        self.ids.extend(v for k, v in attrs if k == 'id')
refs = 0
for p in O.glob('*.html'):
    parser = Links(); parser.feed(p.read_text(encoding='utf-8')); assert len(parser.ids) == len(set(parser.ids))
    for v in parser.links:
        if v.startswith(('http:', 'https:', 'data:')): continue
        if v.startswith('#'): assert v[1:] in parser.ids, (p, v); continue
        assert (p.parent / v.split('#')[0]).exists(), (p, v)
        refs += 1
rendered = [html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>', (O / 'tutorial.html').read_text(encoding='utf-8'), re.S)]
assert len(rendered) == len(FILES)
for name, s in zip(FILES, rendered): assert s == (O / 'printed' / name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None; members = set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser = Links(); parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:', 'https:', '#', 'data:')): assert v.split('#')[0] in members, (name, v)
dump(O / 'validation.json', {'passed': True, 'local_refs': refs, 'unique_ids': True, 'local_anchors': True, 'rendered_code_parity': 3, 'zip_crc': True, 'zip_internal_refs': True, 'zip_MB': round(archive.stat().st_size / 1e6, 2), 'browser_layout_checked': False})
print(json.dumps({'published': str(O / 'index.html'), 'checks': [n, q], 'refs': refs, 'zip_MB': round(archive.stat().st_size / 1e6, 2)}))
