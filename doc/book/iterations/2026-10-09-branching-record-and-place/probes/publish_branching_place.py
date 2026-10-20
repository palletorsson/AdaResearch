from pathlib import Path
from html.parser import HTMLParser
import copy, difflib, hashlib, html, json, re, shutil, zipfile
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-branching-record-and-place'
M = R / 'commons/maps/PG_Branching_Growth'
RUN = R / 'ada_run/encounter_pilot/PG_Branching_Growth'

def write(p, s): p.write_bytes(s.encode('utf-8'))
def dump(p, data): write(p, json.dumps(data, ensure_ascii=False, indent=2) + '\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

before = json.loads((O / 'before/hashes.json').read_text())
code = json.loads((O / 'checks.json').read_text())
room = json.loads((RUN / 'report.json').read_text())
assert code['passed'] and room['passed']
for p in [O / 'engine.log', RUN / 'engine.log']:
    assert not any(s in p.read_text(encoding='utf-8', errors='replace') for s in ['SCRIPT ERROR', 'Parse Error'])
n, q = len(code['checks']), len(room['checks'])
samples = room['observations']['route_samples']
protected = [p for p in before if p.startswith('algorithms/') or p.endswith(('map_data.json', 'proceduralgeneration.json', 'pg_workshop.gd'))]
for p in protected: assert sha(R / p) == before[p], p
runtime = 'commons/data/museum/em_plan.json'
old = json.loads((O / 'before' / runtime).read_text())
new = json.loads((R / runtime).read_text())
assert next(x for x in old['plans'] if x['map'] == M.name) == next(x for x in new['plans'] if x['map'] == M.name)
for d in ['assets', 'museum', 'after', 'probes']: (O / d).mkdir(exist_ok=True)
images = ['opening', 'two-steps', 'duplicates', 'variation', 'student-two', 'student-many', 'above', 'student-retired', 'organic']
for name in images: shutil.copyfile(RUN / (name + '.png'), O / 'assets' / (name + '.png'))
for name in ['report.json', 'engine.log', 'source_manifest.json']: shutil.copyfile(RUN / name, O / 'museum' / name)

p = R / 'doc/book/course/execution-plan/plan.json'
plan = json.loads(p.read_text(encoding='utf-8'))
prior = copy.deepcopy(plan)
row = next(x for x in plan['lessons'] if x['id'] == M.name)
decision = row['decision']
row.update(
    object='The carried PointBody, the preceding eight-point field and a tree of position, parent, target and active records.',
    change='Each active site selects one nearest unreached target. Count records separately from positions; retire each parent after its first child as the student edit.',
    reuses='PointBody unchanged from Space Colonization; position differences, normalization, lists, dictionaries, parent indices, deferred updates, deep copies and cylinder drawing.',
    given='Prepared Endless Museum and XRTools. Three complete files; inherited drawing helpers supplied. Installed jitter, pulse and Organic Space remain comparisons.',
    later='No new grab system, biological model, collision-growing structure or resumable simulation. HOLD retains records here; the installed desk retains a mesh.',
    checks=[f'{n} exact-printed native assertions, 48 source-step comparisons, complete retire-parent edit, and three faulty programs rejected.', f'{q} museum checks: six actual pointer buttons, inherited held action and release, counts, full student edit, nine captures and {samples} supported side-route samples. Existing entry marker remains blocked by desk.'],
    transfer='Add branch.active = false immediately after proposing a child. Predict three records at three positions after two steps, then compare ten requests with the baseline. Explain why retirement is not deduplication.',
    carry='A record is not a distinct place. Stored parentage, selected target, spatial occupancy and permission to act again are different relations.',
    next='PG_Percolation_Network: ask what can reach what under an explicit rule of contact.',
    notes='Reconstruction complete; draft retained. Geometry/parent/active/reached state matches no-jitter/no-pulse production opening in 48 comparisons. Ten requests: baseline192records/14positions; retired11/10. Production source/map/plan row unchanged. Temporary learner(8.5,0,21),yaw180. Entry marker floor-blocked by desk; only side bypass tested. No independent student/headset acceptance.',
    summary='Keep the eight targets and carried point from Space Colonization. Predict the half-metre step toward one nearest target, then rebuild it with a chosen-target index beside the parent index. Two steps create four records at three positions: an older site can answer again at the same place. Hold that record, retire each parent after its first child, and compare the chain with the original branching permission. Carry the distinction between stored relations and occupied space into Percolation.')
assert row['decision'] == decision
assert all(a == b for a, b in zip(prior['lessons'], plan['lessons']) if a['id'] != M.name)
assert all(prior[k] == plan[k] for k in prior if k != 'lessons')
dump(p, plan)
dump(O / 'after/lesson-plan.json', row)

tech = (O / 'before/commons/maps/PG_Branching_Growth/technical.md').read_text(encoding='utf-8') + f'''

## Reconstructed tutorial — 9 October 2026

Three complete printed files: growth.gd, branches.gd and byte-identical PointBody from Space Colonization. The eight targets are retained verbatim. Each active site selects its nearest unreached target strictly within8m; equal-distance ties keep the first index. A child records position/parent/target/active. Child proposal precedes the old-parent distance test strictly<0.32; reached flags are applied after all old sites read. Newborns wait until the next pass. Parents normally remain active and can produce coincident children; exact target matches can add zero-length records. Cap192 includes duplicates. Display0.4 is outside numerical data; rods supply no collision. No jitter/pulse or random hue draws in reconstruction; it isolates the installed opening. Learner step count is not the source per-branch depth.

{n} exact-printed native assertions PASS. Forty-eight source comparisons across four fixtures match positions, parents, active and reached flags. Complete student edit retires each parent immediately after proposing one child. Two steps: baseline4records/3positions, edited3/3. Ten requests: baseline192/14 (budget reached after8 steps), edited11/10. Retirement changes lifetime; it is not a duplicate-position filter. Full variant executed, not only a helper function. Tie-breaking, immediate-consumption and shallow-copy faulty programs rejected. Supplied XRTools poses under translated/rotated host exercise pickup/action/release; movement alone does not advance. Point release parks locally. Keyboard ten, copy independence, budgets and degenerate cases tested. First boundary fixture used Vector3(0.32,0,0), whose stored component is just below the decimal cutoff; corrected fixture to0.3201, production/learner logic unchanged. First failed receipt/probe retained in first-code-check.

{q} native museum checks PASS, including nine capture cameras, six actual desktop pointer buttons, installed192/14 counts, supplied jitter/pulse alternative, held mesh retention, exact learner and full edited program in museum. Temporary learner at hall-local(8.5,0,21),yaw180; supported clear approach(8.5,0,19.4). Eastern bypass from beside desk to exit approach passes {samples} supported capsule samples. Existing entry marker(13.5,0.05,1.5) reports floor blocked by the desk. This is an open room defect: the probe does not certify complete entrance or portal traversal. Initial route crossed desk/exit frame, failed1/32; its receipt, probe and images retained in first-room-check. Revised route starts beside desk and approaches the exit centrally; no collision or production placement changed to pass it. Organic Space presence checked, not its complete behaviour.

HOLD here deep-copies complete node records and renders position/parent edges. It does not save target reached flags or a continuation clock. Installed HOLD duplicates its mesh only. Drawing helpers use capped eight-sided cylinders, not the production line rendering. Native camera exposure0.45 for final images only; baseline exposure differs, scene lighting unchanged. Before/after photographs are not evidence of a lighting improvement. Organic Space can regenerate differently between runs. Thin installed branches remain visually slight beside the much larger organic work; learner caption is readable in close view, miniature nearly disappears overhead. Room composition and entry obstruction remain review findings.

Production algorithm/scene/workshop/organic source, map, sequence and target runtime plan row unchanged by hash/row comparison. Canonical reflection keeps its argument; one code excerpt becomes a short prose account of selection. Accepted logs have no SCRIPT ERROR or Parse Error; existing engine/renderer diagnostics retained. No physical headset, Quest performance, full portal traversal, independent ghost student or browser-layout acceptance claimed. Review doc/book/iterations/2026-10-09-branching-record-and-place/index.html. Third of seven procedural-generation halls; Percolation next.
'''
write(M / 'technical.md', tech)
for name in ['tutorial.md', 'final.md', 'technical.md', 'map_data.json']:
    shutil.copyfile(M / name, O / name)
    shutil.copyfile(M / name, O / 'after' / name)
    a = (O / 'before/commons/maps/PG_Branching_Growth' / name).read_text(encoding='utf-8')
    b = (M / name).read_text(encoding='utf-8')
    write(O / 'after' / (name + '.diff'), ''.join(difflib.unified_diff(a.splitlines(True), b.splitlines(True), fromfile='before/' + name, tofile='after/' + name)))

report = f'''# Branching Growth — a record and a place

Keep the point and the eight targets. In the previous hall, several requests contributed to a direction. Here each active site selects **one nearest target**. The tutorial reconstructs that choice, retains its index, and asks what a count of branches really counts.

After two steps there are four records but three positions. After ten requests the baseline has reached its192-record budget at only14 distinct positions. The full student edit retires each parent after its first child. It produces a chain:11 records at10 positions after ten requests. Even this can retain a zero-length child at an exact target. Changing who may act is a different operation from removing duplicate positions.

|Part|Before|Now|
|---|---|---|
|Tutorial|Short encounter with the installed controls|Three complete runnable files, explanation, prediction and one tested edit|
|Reflection|Encounter and argument with a code excerpt|The same reflection, with selection expressed in prose|
|Lineage|The eight-point field returns|PointBody and drawing helpers return too; target index extends the parent record|
|Museum|Existing desk, branching study, Organic Space and rear structure|Unchanged installation; temporary student work exercised in the real hall|

**{n} code checks and {q} museum checks passed.** Forty-eight comparisons with the installed source cover geometry, parentage, activity and reached flags. Three faulty programs are rejected. The complete student edit ran both in the code tests and inside the museum. These are author-led checks, not an independent ghost-student assessment.

The installed jitter and pulse remain an optional encounter. Organic Space remains a separate construction to compare, without becoming another programming obligation. The lesson has one new focus: selecting a target, preserving that relation, and seeing the consequences of repeated permission to act.

**Room issue remains:** the existing entrance marker is blocked by the desk. The tested side route starts beside that desk and reaches the exit approach through {samples} supported, clear capsule samples. It does not certify the entrance or complete portal traversal. The first failed route and the corrected route are both retained. No production placement was changed.

The overhead view also exposes a compositional imbalance: the fine branching study is slight beside the large Organic Space work. The student's miniature is useful close up and almost disappears from above. Final photographs use camera exposure0.45; baseline photographs use the earlier exposure. The room lighting was not changed. Organic Space may regenerate between runs, so these photographs are not a controlled comparison of that sculpture.

The initial code run also caught a bad boundary fixture: a stored Vector3 component for0.32 falls just below the decimal cutoff. The corrected fixture uses0.3201; the lesson and production growth logic were unchanged. Both receipts are in the review bundle.

Full tutorial and reflection are available separately and side by side. Printed code requires the prepared Endless Museum and XRTools. Physical headset use, Quest performance, independent learner understanding and browser layout remain unverified.

Next: **PG_Percolation_Network** — under a stated rule of contact, what can reach what?
'''
# Keep public prose readable while retaining compact technical notes above.
for a, b in [('its192', 'its 192'), ('only14', 'only 14'), ('chain:11', 'chain: 11'), ('at10', 'at 10'), ('exposure0.45', 'exposure 0.45'), ('for0.32', 'for 0.32'), ('uses0.3201', 'uses 0.3201')]: report = report.replace(a, b)
write(O / 'REPORT.md', report)
css = re.search(r'<style>(.*?)</style>', (R / 'doc/book/iterations/2026-10-09-evolution-what-the-score-reads/index.html').read_text(encoding='utf-8'), re.S).group(1)

def md(s, prefix=''):
    out = markdown.markdown(s, extensions=['fenced_code', 'tables', 'footnotes'])
    blocks = iter(re.findall(r'```gdscript\n(.*?)\n```', s, re.S))
    out = re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)', lambda m: m[1] + html.escape(next(blocks) + '\n') + m[2], out, flags=re.S)
    if prefix: out = re.sub(r'(id="|href="#)(fn[^" ]*)', lambda m: m[1] + prefix + m[2], out)
    return out

def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><style>' + css + '</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation 03 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="branching-review.zip">Review ZIP</a></nav></header>' + body + '<footer>Native Godot evidence · author-led checks · existing entrance obstruction recorded · headset and independent student review remain open.</footer></body></html>'

def fig(path, caption):
    return '<figure><img loading="lazy" src="' + path + '" alt="' + html.escape(caption, quote=True) + '"><figcaption>' + html.escape(caption) + '</figcaption></figure>'

texts = {k: (O / (k + '.md')).read_text(encoding='utf-8') for k in ['tutorial', 'final']}
for k, s in texts.items(): write(O / (k + '.html'), page(k, '<main><article>' + md(s) + '</article></main>'))
write(O / 'parallel.html', page('A record and a place — facing texts', '<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>' + md(texts['tutorial'], 't-') + '</article><article><p class="eyebrow">Right · final.md</p>' + md(texts['final'], 'f-') + '</article></main>'))
changes = '<main><h1>Before and after.</h1>'
for k in texts:
    changes += '<h2>' + k + '.md</h2><div class="pair"><article>' + md((O / 'before/commons/maps/PG_Branching_Growth' / (k + '.md')).read_text(encoding='utf-8'), 'before-' + k) + '</article><article>' + md(texts[k], 'after-' + k) + '</article></div>'
write(O / 'changes.html', page('Before and after', changes + '</main>'))
body = '<main><h1>A record.<br>A place.</h1><p class="lead">The same point. The same targets. A different permission to grow.</p>'
body += '<div class="pair">' + fig('assets/student-many.png', 'Exact printed program: 192 records at 14 positions. Several relations occupy the same place.') + fig('assets/student-retired.png', 'Complete student edit: each parent retires after one child. Ten requests produce 11 records at 10 positions.') + '</div>'
body += fig('assets/student-two.png', 'Two steps, four records, three positions. The familiar held point advances the lesson; the caption retains parent and target indices.')
body += '<div class="pair">' + fig('assets/duplicates.png', 'Installed study at its record budget. The repeated records are almost concealed by the thin outline.') + fig('assets/variation.png', 'Installed jitter and pulse separate paths. These remain supplied alternatives, outside the small reconstruction.') + '</div>'
body += '<div class="pair">' + fig('before-captures/above.png', 'Before: desk at the entrance, two principal works and the retained rear structure. Earlier camera exposure.') + fig('assets/above.png', 'Temporary learner before the rear structure. Final camera exposure 0.45; scene lighting unchanged. Desk still blocks the authored entrance marker.') + '</div>'
body += fig('assets/organic.png', 'Organic Space is a separate comparison, formed with shells and tunnels. Its brightness and scale compete with the fine branch study.')
body += md(report) + '<p><a href="checks.json">Exact-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="first-code-check/checks.json">Initial code receipt</a> · <a href="first-room-check/report.json">Initial route receipt</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O / 'index.html', page('Branching Growth — a record and a place', body))
for name in ['branching_place_before.gd', 'branching_place_lesson.gd', 'branching_place_room.gd']: shutil.copyfile(R / 'tools/probes' / name, O / 'probes' / name)
for name in ['write_branching_place.py', 'test_branching_place.py', 'publish_branching_place.py']: shutil.copyfile(R / 'tools' / name, O / 'probes' / name)
dump(O / 'manifest.json', {'canonical': {name: sha(M / name) for name in ['tutorial.md', 'final.md', 'technical.md', 'map_data.json']}, 'printed': json.loads((O / 'printed-hashes.json').read_text()), 'unchanged': {p: sha(R / p) for p in protected}, 'runtime_row_unchanged': True, 'checks': [n, q], 'source_steps': 48, 'route_samples': samples, 'entry_obstruction_open': True, 'images': {'baseline': 4, 'final': 9}, 'capture_exposure': 0.45})
write(O / 'README.txt', 'Open index.html for native views, parallel.html for tutorial left/reflection right. printed/ is the exact tested three-file lesson. variation/ is the complete retire-parent edit; wrong_tie/wrong_timing/wrong_hold are deliberately faulty programs. Prepared Endless Museum and XRTools required; not a standalone Godot project. Temporary learner installation; production code/map unchanged. Existing entrance blocked by desk; tested side bypass begins beside it. First failing test receipts retained. Author-led assertions; independent student/headset and browser-layout acceptance remain open.\n')
archive = O / 'branching-review.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip', '.uid'] and p.name != 'validation.json':
            data = p.read_bytes()
            if p.suffix == '.html': data = data.replace(b'href="branching-review.zip"', b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(), data)

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links = []; self.ids = []
    def handle_starttag(self, t, attrs):
        self.links.extend(v for k, v in attrs if k in ['href', 'src'] and v)
        self.ids.extend(v for k, v in attrs if k == 'id')

refs = 0
for p in O.glob('*.html'):
    parser = Links(); parser.feed(p.read_text(encoding='utf-8'))
    assert len(parser.ids) == len(set(parser.ids))
    for v in parser.links:
        if v.startswith(('http:', 'https:', 'data:')): continue
        if v.startswith('#'): assert v[1:] in parser.ids, (p, v); continue
        assert (p.parent / v.split('#')[0]).exists(), (p, v)
        refs += 1
rendered = [html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>', (O / 'tutorial.html').read_text(encoding='utf-8'), re.S)]
assert len(rendered) == 3
for name, s in zip(['growth.gd', 'branches.gd', 'point_body.gd'], rendered): assert s == (O / 'printed' / name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    members = set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser = Links(); parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:', 'https:', '#', 'data:')): assert v.split('#')[0] in members, (name, v)
dump(O / 'validation.json', {'passed': True, 'local_refs': refs, 'unique_ids': True, 'local_anchors': True, 'rendered_code_parity': 3, 'zip_crc': True, 'zip_internal_refs': True, 'zip_MB': round(archive.stat().st_size / 1e6, 2), 'browser_layout_checked': False})
print(json.dumps({'published': str(O / 'index.html'), 'checks': [n, q], 'refs': refs, 'zip_MB': round(archive.stat().st_size / 1e6, 2)}))
