from pathlib import Path
from html.parser import HTMLParser
import copy, difflib, hashlib, html, json, re, shutil, zipfile
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-sculpted-what-the-centres-keep'
M = R / 'commons/maps/PG_Sculpted_Forms'
RUN = R / 'ada_run/encounter_pilot/PG_Sculpted_Forms/sample'
FILES = ['sample.gd', 'faces.gd', 'sculpture.gd', 'point_body.gd']
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
baseline, edited = obs['learner_baseline'], obs['learner_edited']
protected = [p for p in before if p.startswith(('algorithms/', 'commons/primitives/')) or p.endswith(('map_data.json', 'proceduralgeneration.json', 'pg_workshop.gd'))]
for p in protected: assert sha(R / p) == before[p], p
runtime = 'commons/data/museum/em_plan.json'
old = json.loads((O / 'before' / runtime).read_text())
new = json.loads((R / runtime).read_text())
assert next(x for x in old['plans'] if x['map'] == M.name) == next(x for x in new['plans'] if x['map'] == M.name)
for d in ['assets', 'museum', 'after', 'probes']: (O / d).mkdir(exist_ok=True)
images = ['originals', 'sample-fine', 'sample-coarse', 'dome-cores', 'dome-section', 'student-originals', 'student-sample', 'student-edited', 'above', 'above-section']
for name in images: shutil.copyfile(RUN / (name + '.png'), O / 'assets' / (name + '.png'))
for name in ['report.json', 'engine.log', 'source_manifest.json']: shutil.copyfile(RUN / name, O / 'museum' / name)

p = R / 'doc/book/course/execution-plan/plan.json'
plan = json.loads(p.read_text(encoding='utf-8')); prior = copy.deepcopy(plan)
row = next(x for x in plan['lessons'] if x['id'] == M.name); decision = row['decision']
row.update(
    object='Three posed cubes, the centres captured from them, and a sampled surface; the carried PointBody commits the capture.',
    change='Mark an axis-aligned cell neighbourhood around each captured local centre and emit only exposed faces. Halve the marking extent while retaining the same inputs.',
    reuses='Local/global coordinates, position lists, dictionary occupancy, six-neighbour tests, face assembly and unchanged PointBody from Caves and Mazes. Its carving footprint becomes a marking footprint.',
    given='Prepared Endless Museum, player, camera and XRTools. Four complete files print the model, face assembler, three-cube host and carried point. The existing twelve falling cubes supply a full-scale comparison.',
    later='The learner cubes do not fall and have no collision. No exact rotated-cube voxelization, smoothing, CSG implementation or layered-membrane implementation. Preserve the actual enlarged source footprint.',
    checks=[f'{n} exact-code checks: nine source-assembler comparisons, complete extent edit, transformed capture, mesh winding, retained samples and three faulty programs rejected.', f'{q} native checks: six real pointer controls; all surface vertices agree with the actual frozen pile at two spacings; collider lifecycle; dome states; full learner and extent edit; supplied XRTools poses; ten images.'],
    transfer='Change only EXTENT_FACTOR from 1 to .5. Predict a smaller occupied subset with the same centres and origin; explain why rotating a source cube alone cannot change this sample.',
    carry='Source transforms, captured centres, occupied addresses and boundary geometry are distinct records. A sample preserves selected information and a declared approximation.',
    next='PG_Mirrored_Patterns: reuse inputs while composing operations; distinguish copying an image from connecting places.',
    notes='Exact printed and native checks pass; decision remains draft. Exact START fixture has275cells/270faces, extent edit81/126. Transformed captured inputs can fall either side of a floor boundary; receipt preserves the actual centres and counts. Existing dome dominates the hall and desk blocks authored entry. Clear side bypass is a measurement, not complete traversal acceptance. Production unchanged; no headset, Quest or independent student claim.',
    summary='Use the familiar point to capture three posed cubes in their construction frame. Mark a declared neighbourhood around each centre, omit faces between occupied cells, and assemble the remaining faces into a surface. Move a source cube without silently replacing the retained sample, then capture again. Halve the neighbourhood extent and predict a smaller occupied subset with the same centres. Compare this reconstruction with the installed falling pile; carry the distinction between a body, its sampled data and the surface made from it into Mirrored Patterns.')
assert row['decision'] == decision
assert all(a == b for a, b in zip(prior['lessons'], plan['lessons']) if a['id'] != M.name)
assert all(prior[k] == plan[k] for k in prior if k != 'lessons')
dump(p, plan); dump(O / 'after/lesson-plan.json', row)

tech = (O / 'before/commons/maps/PG_Sculpted_Forms/technical.md').read_text(encoding='utf-8') + f'''

## Reconstructed tutorial — 9 October 2026

Full printed sample.gd/faces.gd/sculpture.gd/unchanged Caves point_body.gd. Three fixed local centres(-1.5,1,0),(0,1,0),(1.5,1,0); host frame scale.3, y.8. Original rotations vary but are not sampled. capture(frame,bodies) uses frame.to_local(global_position). Component minimum minus BODY_EDGE anchors origin; floor((centre-origin)/spacing) picks address. Sparse dictionary is not clipped. Extent ceil(BODY_EDGE*EXTENT_FACTOR/spacing), inclusive offsets on all axes. Source opening1m cube/.5 spacing marks125cells, box2.5mwide. No extra half-cell centre shift. Six neighbours omit internal faces; each exposed face emits two clockwise triangles with outward normals. No smoothing or learner collision.

Point held action/SPACE samples; V changes visibility, M moves third source+.5x without recapturing, R restores source positions and original view. Physics parking returns inherited point to(0,1.1,1.5). SPACE also belongs to installed artifact, so prefer held action there. Temporary learner maplocal(8.5,0,21),yaw180; approach(8.5,0,19). Three static MeshInstance originals are explicit fixtures, not a replacement physics lesson.

{n} exact printed checks PASS. Nine source-assembler comparisons across three spacings/three inputs match submitted vertices. Empty input, duplicate union, alias-safe retained resampling, isolated and adjacent cells, actual packed mesh winding/normals, local/world transform, retained sample/view/move/reset, whole edited program and supplied XRTools pick/action/drop. Wrong world coordinates, rounded addresses and emitted internal faces all rejected. Exact START fixture275cells/270faces=540triangles; full EXTENT_FACTOR.5 edit81cells/126faces=252triangles. Single-source edited box1.5unitswide still approximates rather than matching rotated cube.

Floating-point local/global round trips can change floor at a cell boundary. Do not snap inputs to conceal this: exact local fixture and actual captured positions are separate test cases. Headless transformed host250cells/250faces; moved third300/290; edited72/114. Native capture {baseline['cells']}cells/{baseline['faces']}faces; edited{edited['cells']}/{edited['faces']}. Same captured inputs/origin and subset relation verified. First harness parse failure and second overly strict packed-normal comparison retained; final normal check uses angular dot>.99999 instead of component equality near1e-5. No tutorial geometry changed to satisfy it.

{q} native checks PASS. Actual pointer DROP/SAMPLE/VOXEL/ORIGINAL/CUT/RULE effects. Printed full pipeline reproduces actual frozen twelve-body production surface vertices at1.0and.5 spacing. Changing view/resolution retains frozen transforms; exactly one generated sibling collider; ORIGINAL leaves it active; DROP removes it and starts twelve moving bodies. Dome cast/blank/core/section states exercised. Full learner and whole extent edit instantiated in actualmuseum; suppliedXRTools hand action/release passed. Ten final images plus three baseline images. First camera receipt preserved because pile was clipped; final framing raised target without changing model.

Route: {route['samples']} quarter-metre capsule samples, clear={route['clear']}, supported={route['supported']}, from beside desk via left x3 aisle and rear x20 aisle to exit approach. Authored entry {obs['entry']['at']} remains blocked by desk, exit record valid. This does not certify entry portal/player traversal or standing on generated mound. Oversized dome roof obscures front court from above and extends beyond perimeter in image; section capture makes relationship inspectable. Production room/placement/lighting unchanged, camera exposure.45. Headset/Quest/independentghoststudent/browserlayout acceptance remain open.

Canonical reflection keeps its argument, removes two code blocks and adds the rotation/forgotten-information comparison. Only target execution-plan row updated, draft retained. Production mound/dome/workshop/map/sequence protected by hashes; runtime target row unchanged. Review doc/book/iterations/2026-10-09-sculpted-what-the-centres-keep/index.html. Next PG_Mirrored_Patterns, final hall of this sequence.
'''
write(M / 'technical.md', tech)
for name in ['tutorial.md', 'final.md', 'technical.md', 'map_data.json']:
    shutil.copyfile(M / name, O / name); shutil.copyfile(M / name, O / 'after' / name)
    a = (O / 'before/commons/maps/PG_Sculpted_Forms' / name).read_text(encoding='utf-8')
    b = (M / name).read_text(encoding='utf-8')
    write(O / 'after' / (name + '.diff'), ''.join(difflib.unified_diff(a.splitlines(True), b.splitlines(True), fromfile='before/' + name, tofile='after/' + name)))

report = f'''# Sculpted Forms — what the centres keep

The previous hall cleared cells around positions. This hall marks cells around positions and assembles their exposed faces. The familiar point commits the capture. The lesson asks what this surface can retain from the bodies we showed it.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter and partial sampling excerpts|Four complete files: captured positions, occupied cells, exposed faces, visible comparison and inherited point|
|Student's change|A broad invitation to inspect resolution|Halve the marking extent; retain the same centres and predict the smaller occupied subset|
|Reflection|Sampling, subtraction and surfaces|Argument retained, two code blocks removed, rotation used to ask what the sample forgets|
|Museum|Falling pile, dome, layered membrane|Production unchanged; complete learner reconstruction tested in an open bay|

**{n} exact-code checks and {q} native museum checks passed.** The printed sampler and assembler reproduce all submitted surface vertices from the actual frozen pile at two resolutions. Three complete faulty programs are rejected: keeping world positions as local, rounding instead of flooring, and drawing internal faces.

The student has three fixed cubes so the comparison can be repeated. The installed twelve-cube pile remains the physical encounter. Sampling records their centres; it does not copy rotations or exact contact shapes. One one-unit cube produces a 2.5-unit-wide sample at the opening setting. Smaller cells do not automatically mean a faithful copy of the body.

For the exact declared three-centre fixture, the baseline has 275 occupied cells and 270 exposed faces. The full extent edit has 81 cells and 126 faces. Each exposed face becomes two triangles. The same captured centres and grid origin remain; the edit occupies a subset of the baseline addresses.

**A useful numerical limit appeared in testing.** Positions converted through moved and scaled frames can land just either side of a cell boundary. The museum capture has {baseline['cells']} occupied cells and {baseline['faces']} faces; its extent edit has {edited['cells']} and {edited['faces']}. The receipt stores the actual inputs. Those counts are compared against those inputs, separately from the exact fixture. We preserve the source's floor operation rather than hiding the difference by rounding.

M moves a source cube without replacing its recorded sample. Switching views can therefore show a current source beside an older answer. Only the next SAMPLE replaces that answer. Rotating a cube without moving its centre cannot change the occupied addresses: that information was never supplied.

The real museum controls were exercised through the desktop pointer. The originals remain frozen while resolution or visibility changes. The sampled collider stays active in ORIGINAL view, and a new DROP removes it. The learner miniature has no collider and does not fall. The supplied museum and XRTools are required.

**Room finding:** the dome is much too dominant for an evenly readable comparison. Its roof hides much of the front court from above, and the mesh extends across the perimeter in the image. A section view helps inspect the relationship but does not solve the layout. The authored entry is also blocked by the desk. A separate bypass of {route['samples']} supported, clear capsule positions reaches the exit approach from beside the desk; this is not proof of a complete entry or portal traversal.

The report includes ten new native captures and three baseline views. The original and sample images share a camera and frozen body transforms. The fine sample was captured with the dome in cast view; the originals and coarse sample were captured after CUT changed the dome to blank. The resulting light difference is not a material or voxel parameter. The overhead cast and section are explicitly different display states. Camera exposure is 0.45; architecture and production lighting are unchanged. The first framing clipped the top of the pile; that receipt is retained under first-camera-check.

The first code run caught a probe type-inference error; the second caught an overly strict comparison of packed mesh normals. The corrected check tests their angular agreement. Neither required changing the sampled geometry. Failed receipts are preserved. Accepted runs contain no SCRIPT or Parse errors; existing project warnings remain in the logs.

Physical headset use, Quest performance and an independent ghost student's understanding remain untested. This package contains the exact runnable reconstruction, its complete edit, fault variants and evidence—not a claim that every aspect of this room is finished.

Next: **Mirrored Patterns**, the seventh and final hall of Procedural Generation.
'''
write(O / 'REPORT.md', report)
css = re.search(r'<style>(.*?)</style>', (R / 'doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html').read_text(encoding='utf-8'), re.S).group(1)
def md(s, prefix=''):
    out = markdown.markdown(s, extensions=['fenced_code', 'tables', 'footnotes'])
    blocks = iter(re.findall(r'```gdscript\n(.*?)\n```', s, re.S))
    out = re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)', lambda m: m[1] + html.escape(next(blocks) + '\n') + m[2], out, flags=re.S)
    if prefix: out = re.sub(r'(id="|href="#)(fn[^" ]*)', lambda m: m[1] + prefix + m[2], out)
    return out
def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + css + '</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation 06 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="sculpted-review.zip">Review ZIP</a></nav></header>' + body + '<footer>Native Godot evidence · author-led checks · room obstruction recorded · headset and independent student acceptance remain open.</footer></body></html>'
def fig(path, caption): return '<figure><img loading="lazy" src="' + path + '" alt="' + html.escape(caption, quote=True) + '"><figcaption>' + html.escape(caption) + '</figcaption></figure>'
texts = {k: (O / (k + '.md')).read_text(encoding='utf-8') for k in ['tutorial', 'final']}
for k, s in texts.items(): write(O / (k + '.html'), page(k, '<main><article>' + md(s) + '</article></main>'))
write(O / 'parallel.html', page('What the centres keep — facing texts', '<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>' + md(texts['tutorial'], 't-') + '</article><article><p class="eyebrow">Right · final.md</p>' + md(texts['final'], 'f-') + '</article></main>'))
changes = '<main><h1>Before and after.</h1>'
for k in texts:
    changes += '<h2>' + k + '.md</h2><div class="pair"><article>' + md((O / 'before/commons/maps/PG_Sculpted_Forms' / (k + '.md')).read_text(encoding='utf-8'), 'before-' + k) + '</article><article>' + md(texts[k], 'after-' + k) + '</article></div>'
write(O / 'changes.html', page('What changed', changes + '</main>'))
body = '<main><h1>What the<br>centres keep.</h1><p class="lead">Capture three cubes. Change the neighbourhood marked around them. See what the surface was never told.</p>'
body += '<div class="pair">' + fig('assets/student-originals.png', 'The three fixed source cubes. Their different rotations remain visible here.') + fig('assets/student-sample.png', f"The surface records centres and a marking rule. Native capture: {baseline['cells']} cells, {baseline['faces']} exposed faces.") + '</div>'
body += fig('assets/student-edited.png', f"The full student edit halves the marking extent: {edited['cells']} cells, {edited['faces']} faces. The source centres stay the same.")
body += '<h2>The installed physical comparison</h2><div class="pair">' + fig('assets/originals.png', 'Twelve originals frozen during a fall, before reaching the ground. The dome is in blank view here.') + fig('assets/sample-fine.png', 'The same frozen centres at spacing 0.5. This earlier capture has the dome in cast view and different shadowing. Rotation and exact contact surfaces were not inputs.') + '</div>'
body += fig('assets/sample-coarse.png', 'The same centres at spacing 1.0, dome in blank view as in the originals image. All submitted vertices agree with the printed pipeline. The installed mesh regenerates normals; the learner keeps flat face normals.')
body += '<h2>Other constructions in the room</h2><div class="pair">' + fig('assets/dome-cores.png', 'CUT: the existing subtractive cores. CSG remains a museum comparison in this lesson.') + fig('assets/dome-section.png', 'CUT: a section of the same oversized dome. Its scale dominates the room.') + '</div>'
body += '<h2>Read the room from above</h2><div class="pair">' + fig('before-captures/above.png', 'Before: the dome hides much of the front court. Baseline exposure.') + fig('assets/above.png', 'Same architecture, student reconstruction added temporarily. Cast view; final exposure 0.45.') + '</div>'
body += fig('assets/above-section.png', 'Diagnostic section view from the same overhead camera. This changes the dome display state, not its authored size or placement.')
body += md(report) + '<p><a href="checks.json">Exact-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O / 'index.html', page('Sculpted Forms — what the centres keep', body))
for name in ['sculpted_sample_before.gd', 'sculpted_sample_lesson.gd', 'sculpted_sample_room.gd']: shutil.copyfile(R / 'tools/probes' / name, O / 'probes' / name)
for name in ['write_sculpted_sample.py', 'test_sculpted_sample.py', 'publish_sculpted_sample.py']: shutil.copyfile(R / 'tools' / name, O / 'probes' / name)
dump(O / 'manifest.json', {'canonical': {name: sha(M / name) for name in ['tutorial.md', 'final.md', 'technical.md', 'map_data.json']}, 'printed': json.loads((O / 'printed-hashes.json').read_text()), 'unchanged': {p: sha(R / p) for p in protected}, 'runtime_row_unchanged': True, 'checks': [n, q], 'source_comparisons': code['source_comparisons'], 'actual_pile_spacings': [s['spacing'] for s in obs['production_samples']], 'route': route, 'entry_obstruction_open': True, 'images': {'baseline': 3, 'final': len(images)}, 'capture_exposure': 0.45})
write(O / 'README.txt', 'Open index.html for images, parallel.html for tutorial left/reflection right. printed/ is the exact four-file tested lesson; variation/ changes only EXTENT_FACTOR to .5. wrong_world/wrong_round/wrong_faces deliberately fail its contract. Prepared Endless Museum and XRTools required, not a standalone project. Temporary learner model has no collision or falling bodies. Production unchanged. The dome dominates the room; the desk blocks the authored entrance. Side bypass sampled, not full portal traversal. Supplied XRTools poses are not a headset test or an independent ghost student. Failed harness receipts and first camera framing retained.\n')
archive = O / 'sculpted-review.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip', '.uid'] and p.name != 'validation.json':
            data = p.read_bytes()
            if p.suffix == '.html': data = data.replace(b'href="sculpted-review.zip"', b'href="README.txt"')
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
dump(O / 'validation.json', {'passed': True, 'local_refs': refs, 'unique_ids': True, 'local_anchors': True, 'rendered_code_parity': 4, 'zip_crc': True, 'zip_internal_refs': True, 'zip_MB': round(archive.stat().st_size / 1e6, 2), 'browser_layout_checked': False})
print(json.dumps({'published': str(O / 'index.html'), 'checks': [n, q], 'refs': refs, 'zip_MB': round(archive.stat().st_size / 1e6, 2)}))
