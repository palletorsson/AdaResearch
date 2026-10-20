"""Collect current PG readings with fresh learner receipts and dated room evidence.

Read-only with respect to canonical lessons, studies, maps and artifact programs.
Run tools/test_procedural_sequence.py first; this publisher refuses stale evidence.
"""
from pathlib import Path, PurePosixPath
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import html
import json
import posixpath
import re
import shutil
import zipfile
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-procedural-generation-complete-readings'
REV = R / 'doc/book/iterations/2026-10-09-procedural-generation-revised'
editorial = json.loads((REV / 'editorial-checks.json').read_text())
revisions = {item['source']: item for item in editorial['sources']}
spatial = json.loads((REV / 'spatial-validation.json').read_text())
assert spatial['passed'] and spatial['after_checks'] == 66
shutil.copytree(REV, O / 'revision', dirs_exist_ok=True,
                ignore=shutil.ignore_patterns('*.zip', '*.uid', '__pycache__'))
revision_page = O / 'revision/index.html'
revision_page.write_text(revision_page.read_text(encoding='utf-8').replace(
    '../2026-10-09-procedural-generation-complete-readings/', '../'), encoding='utf-8')


def write(p, text):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(text.encode('utf-8'))


def dump(p, value):
    write(p, json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


latest = json.loads((O / 'latest-run.json').read_text())
assert latest['complete'] and latest['passed']
run = O / latest['directory']
run_manifest = json.loads((run / 'manifest.json').read_text())
results = json.loads((run / 'results.json').read_text())
assert results['complete'] and results['passed']
sequence_path = R / 'commons/maps/sequences/proceduralgeneration.json'
sequence = json.loads(sequence_path.read_text())['sequences']['proceduralgeneration']
assert sha(sequence_path) == run_manifest['sequence_sha256']
assert sequence['maps'] == [e['map'] for e in run_manifest['halls']]

roots = ['evolution-what-the-score-reads', 'colonization-who-can-answer',
         'branching-record-and-place', 'percolation-a-contact-rule',
         'caves-a-route-needs-room', 'sculpted-what-the-centres-keep', 'mirrored-a-copy-kept']
names = ['Genetic Evolution', 'Space Colonization', 'Branching Growth',
         'Percolation Network', 'Caves and Mazes', 'Sculpted Forms', 'Mirrored Patterns']
verbs = ['Evaluate', 'Guide', 'Branch', 'Connect', 'Carve', 'Sample', 'Copy']
subjects = [
    'A criterion reads a body', 'A field proposes a direction', 'A record has a lifetime',
    'A contact rule permits a route', 'A route needs clearance', 'A sample keeps selected information',
    'A copy depends on an address rule']
summaries = [
    'Return to the design records from L-systems. Build six fixed candidates, compute an estimate and rank them against a target. Keep a witness while changing the criterion. A ring can change a body without changing its score: the student learns exactly what this evaluator reads. Reproduction remains an installed museum comparison; the new learner program isolates evaluation.',
    'Keep the familiar point and let a small field guide growth. Each request chooses an eligible site; the site combines directions before taking a fixed-length step. Compare tips with the whole existing network, then change the weighting while retaining the field. The student carries forward positions, parent links and the distinction between who can answer and how an answer is combined.',
    'Reuse the eight-request field but change the relationship. Each active site now chooses one nearest unreached target. Follow two steps before growing many: different records can occupy the same position. Retire a parent after it produces a child and compare the resulting history. The new capacity is to control the lifetime of a record, without mistaking record count for spatial variety.',
    'Carry the distinction between a position and a connection into an occupied lattice. Start from a declared source plane and expand reach through permitted neighbour offsets, using separate old and next sets. Hold occupancy fixed while adding one pair of diagonal contacts. The student learns to change connectivity independently of the material that is present; closeness alone does not establish a route.',
    'Give a fixed list of nine carving centres a footprint and headroom inside a byte array. The familiar point advances one carving event. Keep a repeated centre in the history even when it removes nothing new. Increase headroom while preserving the route and compare the empty cells. This reconstructs the carving operation; the room’s random walkers and maze generator remain other encounters.',
    'Return to three cubes and capture their centres in a declared local frame. Map those centres to occupied addresses, then build only the exposed faces. Keep the captured sample while moving an original; resample deliberately. Change the marked extent and explain what remains absent, including rotation. This is the construction peak: earlier coordinates, arrays and triangle faces meet in a new approximation.',
    'Keep one square array and make a separate reflected result. Follow the address transformation on a five-by-five field, where the original rule leaves the centre axes untouched. Extend the rule to include those axes and compare cells, not only totals. The closing capacity is to preserve input while changing its reading. The room’s connected paths provide a further comparison, without becoming another required generator.'
]
handoffs = [
    'Design record → criterion → ranked comparison',
    'Eligible sites → combined direction → child with a parent',
    'Active record → next record → an explicit lifetime',
    'Occupied address → allowed contact → reachable address',
    'Recorded centre → footprint and headroom → empty volume',
    'Local centre → occupied cell → exposed face',
    'Held array → reflected result → a separately testable reading']
photos = ['student-corrected', 'student-forks', 'student-two', 'student-edited',
          'student-three', 'student-sample', 'student-axes']
above = ['above', 'above', 'above', 'above', 'above', 'above-section', 'above']
photo_captions = [
    'Earlier native capture: the complete learner comparison after changing the box coefficient.',
    'Earlier native capture: the learner field and its growing parent-linked branches.',
    'Earlier native capture: two steps produce four records at three positions.',
    'Earlier native capture: the learner lattice with the edited contact rule.',
    'Earlier native capture: the same carving centres with three layers of headroom.',
    'Earlier native capture: the surface assembled from the sampled occupied cells.',
    'Earlier native capture: the complete centre-axis variation beside its retained input.']
scope_notes = [
    'The six candidates and ranking are reconstructed. Selection, crossover and mutation are supplied museum behaviour, not a complete genetic algorithm written in this lesson.',
    'The small field makes assignment and direction inspectable. NETWORK permits existing sites to answer; parent links still form a rooted tree, not a cyclic graph.',
    'Retiring a parent limits later production; it does not guarantee unique positions. The lesson deliberately exposes coincident records before changing the rule.',
    'The learner reconstructs Boolean reachability. Flow amplitude, decay and the production collider changes are outside that small program.',
    'The learner model has no collision. Its nine declared centres are a fixture, not an automatic import of a live hand trace. The lesson reconstructs carving, not the whole random walker or maze generator.',
    'The student uses a static three-cube fixture. A captured centre contains neither the cube’s rotation nor its collision surface. The museum’s falling bodies, dome and membrane are separate comparisons.',
    'The learner isolates copying. Cellular evolution and the graph displays remain supplied museum comparisons. Equal live-cell totals do not prove equal fields or symmetry.']

sources = {sequence_path.relative_to(R).as_posix(): sha(sequence_path)}
records = []
protected = {}
historical_protected = {}
for i, entry in enumerate(run_manifest['halls']):
    key = entry['map']
    D = R / 'doc/book/iterations' / ('2026-10-09-' + roots[i])
    M = R / 'commons/maps' / key
    H = O / 'halls' / key
    for sub in ['code', 'receipts']:
        (H / sub).mkdir(parents=True, exist_ok=True)
    original = json.loads((D / 'manifest.json').read_text())
    texts = {}
    for kind in ['tutorial', 'final']:
        p = M / (kind + '.md')
        relative = p.relative_to(R).as_posix()
        assert sha(p) == entry['sources'][relative], ('stale learner receipt', relative)
        if relative in revisions:
            assert revisions[relative]['before_sha256'] == original['canonical'][p.name]
            assert sha(p) == revisions[relative]['after_sha256']
        else:
            assert sha(p) == original['canonical'][p.name], ('unrecorded text change', relative)
        texts[kind] = p.read_text(encoding='utf-8')
        sources[relative] = sha(p)
        shutil.copyfile(p, H / p.name)
    marked = dict(re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', texts['tutorial'], re.S))
    assert set(marked) == set(entry['printed'])
    for name, digest in entry['printed'].items():
        p = O / entry['directory'] / 'printed' / name
        assert sha(p) == digest == original['printed'][name]
        assert p.read_bytes() == (marked[name] + '\n').encode('utf-8')
        shutil.copyfile(p, H / 'code' / name)
    learner = json.loads((O / entry['directory'] / 'checks.json').read_text())
    museum = json.loads((D / 'museum/report.json').read_text())
    assert learner['passed'] and museum['passed']
    for old, new in [('checks.json', 'earlier-learner.json'), ('museum/report.json', 'earlier-museum.json'),
                     ('manifest.json', 'earlier-hall-manifest.json'), ('REPORT.md', 'earlier-hall-report.md')]:
        shutil.copyfile(D / old, H / 'receipts' / new)
    for filename in ['engine.log', 'museum/engine.log', 'museum/source_manifest.json']:
        if (D / filename).is_file():
            shutil.copyfile(D / filename, H / 'receipts' / ('earlier-' + filename.replace('/', '-')))
    images = []
    for stem, label in [(photos[i], 'study'), (above[i], 'above')]:
        target = O / 'assets' / (f'{i+1:02d}-' + label + '.png')
        target.parent.mkdir(exist_ok=True)
        photo_source = REV / 'museum' / key / 'after/above.png' if label == 'above' and i >= 2 else D / 'assets' / (stem + '.png')
        shutil.copyfile(photo_source, target)
        images.append(target.relative_to(O).as_posix())
    for relative, digest in original['unchanged'].items():
        historical_protected[relative] = digest
        if relative in spatial['sources']:
            assert sha(REV / 'before' / relative) == digest
            assert sha(R / relative) == spatial['sources'][relative]
        else:
            assert sha(R / relative) == digest, ('unrecorded museum change', relative)
        protected[relative] = sha(R / relative)
    records.append({'id': key, 'name': names[i], 'verb': verbs[i], 'subject': subjects[i],
                    'summary': summaries[i], 'handoff': handoffs[i], 'scope': scope_notes[i],
                    'images': images, 'caption': photo_captions[i], 'texts': texts,
                    'files': entry['printed'], 'fresh_checks': len(learner['checks']),
                    'earlier_museum_checks': len(museum['checks']), 'fresh_directory': entry['directory'],
                    'original_report': D.relative_to(R).as_posix()})

assert len({r['files']['point_body.gd'] for r in records}) == 1
file_count = sum(len(r['files']) for r in records)
fresh_count = sum(r['fresh_checks'] for r in records)
earlier_count = sum(r['earlier_museum_checks'] for r in records)
assert (file_count, fresh_count, earlier_count) == (22, 200, 231)


def portable(text, prefix):
    for reference in set(re.findall(r'/book-images/[^\s)"<>]+', text)):
        source = R / 'doc/book' / reference.removeprefix('/book-images/')
        assert source.is_file(), reference
        target = 'assets/reference-' + sha(source)[:12] + source.suffix
        shutil.copyfile(source, O / target)
        text = text.replace(reference, target)
    return re.sub(r'\[\^([^\]]+)\]', lambda m: '[^' + prefix + '-' + m[1] + ']', text)


def render(text):
    value = markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])
    blocks = iter(re.findall(r'```gdscript\n(.*?)\n```', text, re.S))
    return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',
                  lambda m: m[1] + html.escape(next(blocks) + '\n') + m[2], value, flags=re.S)


css = '''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;color:#252829;background:#eeece6;font-family:Georgia,serif;line-height:1.65}header,main,footer{max-width:1480px;margin:auto;padding:28px 4vw}header{border-bottom:1px solid #bebdb6}nav{display:flex;flex-wrap:wrap;gap:10px 22px;font:14px/1.5 system-ui}a{color:#375468}h1{font-size:clamp(2.4rem,5.8vw,5rem);line-height:1.08;font-weight:500}h2{line-height:1.2;font-size:2rem}h3{font-size:1.3rem}.eyebrow,.meta,figcaption{font:13px/1.5 system-ui}.eyebrow{letter-spacing:.1em;text-transform:uppercase;color:#626563}.lead{font-size:1.4rem;max-width:930px}.reading{max-width:970px}.chapter{padding:34px 0;border-top:1px solid #b8bab4;scroll-margin-top:12px}p,li{max-width:85ch}pre{overflow:auto;background:#242932;color:#eef1f1;padding:20px;font:13px/1.5 Consolas,monospace;tab-size:4}code{font-family:Consolas,monospace}p code,li code{font-size:.88em;background:#e1dfd9;padding:1px 4px}img{max-width:100%;height:auto}figure{margin:20px 0}figcaption{color:#59615f;padding-top:8px}.spread{display:grid;grid-template-columns:1fr 1fr;gap:30px;align-items:start}.spread article{min-width:0;background:#faf9f4;padding:24px}.spread h1{font-size:2.15rem}.spread pre{font-size:12px}.photos{display:grid;grid-template-columns:3fr 2fr;gap:24px;align-items:start}.toc{columns:2;column-gap:30px}.toc li{break-inside:avoid;margin-bottom:8px}.route{font:17px/2 system-ui;padding:18px;background:#e1dfd8}.table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font:14px/1.55 system-ui}td,th{vertical-align:top;text-align:left;padding:12px;border-bottom:1px solid #c5c6be}footer{color:#666b66;font:13px/1.5 system-ui}.note{border-left:3px solid #ac7289;padding:8px 20px;background:#f6f0ef}details{margin:18px 0}summary{font:15px/1.5 system-ui;cursor:pointer}@media(max-width:850px){.spread,.photos{grid-template-columns:1fr}.toc{columns:1}}@media print{header nav,.download{display:none}body{background:white}main{padding:0}.chapter{break-before:page}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#eee;color:#111}img{max-height:80vh;object-fit:contain}.spread{display:block}.spread article{break-before:page}a{color:inherit}}'''


def page(title, body, klass=''):
    nav = [('index.html', 'Seven-hall route'), ('tutorial.html', 'Full tutorial'), ('final.html', 'Full reflection'),
           ('parallel.html', 'Facing texts'), ('assessment.html', 'Sequence assessment'),
           ('revision/index.html', 'Revisions · before and after'),
           ('evidence.html', 'Evidence'), ('REVIEW.md', 'Reviewer brief'),
           ('procedural-generation-review.zip', 'Download ZIP')]
    return ('<!doctype html><html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) +
            '</title><style>' + css + '</style></head><body><header><p class="eyebrow">Endless Museum · Procedural Generation · 9 October 2026</p><nav>' +
            ''.join('<a href="' + link + '">' + label + '</a>' for link, label in nav) +
            '</nav></header><main class="' + klass + '">' + body + '</main><footer>'
            'Revised review draft. Fresh execution: 22 printed learner files, 200 checks; 7 worked-example checks; 66 repaired-room checks. Earlier learner photographs and 231 museum checks retain their original scope. '
            'This collection does not establish independent learner success, physical-headset use or a complete seven-hall walk.</footer></body></html>')


def toc(kind):
    return '<ol class="toc">' + ''.join('<li><a href="' + kind + '.html#' + r['id'] + '">' +
                                        r['name'] + '</a></li>' for r in records) + '</ol>'


def figure(path, caption):
    return '<figure><img loading="lazy" src="' + path + '" alt="' + html.escape(caption, quote=True) + '"><figcaption>' + html.escape(caption) + '</figcaption></figure>'


body = '<h1>What a rule<br>lets through.</h1><p class="lead">Seven halls. The same familiar point. A growing capacity to evaluate a design, guide its growth, connect its parts and decide what a new representation keeps.</p>'
body += '<p class="route">Evaluate → Guide → Branch → Connect → Carve → Sample → Copy</p>'
body += '<p>The full tutorial and reflective texts are collected here in the current spine order. The programs remain complete and the museum remains their prepared environment. Each hall selects one operation; its other artifacts keep their place in the wider encounter.</p>'
body += '<p><a href="tutorial.md">Complete tutorial Markdown</a> · <a href="final.md">Complete reflective Markdown</a> · <a href="procedural-generation-review.zip">Review ZIP with code, images and receipts</a></p>'
body += '<p class="note">Revised after external review: the shared practice is explicit, the two dense lessons have small walkthroughs, and the first two reflections are shorter. The five entrance obstructions and oversized dome placement are repaired and checked in Godot. <a href="revision/index.html">See the exact changes and before/after room views.</a></p>' + toc('parallel')
for i, r in enumerate(records):
    caption = ('New native overhead capture after the desk relocation' + (' and dome refit' if i == 5 else '') + '. See Revisions for matched-camera before views and capture conditions.'
               if i >= 2 else 'Earlier native overhead capture — ' + r['name'] + '.')
    body += '<section class="chapter" id="' + r['id'] + '"><p class="eyebrow">' + f'{i+1:02d} / 07 · ' + r['verb'] + '</p><h2>' + r['name'] + '</h2><p class="lead">' + html.escape(r['summary']) + '</p><p class="meta">' + html.escape(r['handoff']) + '</p><p><a href="parallel.html#' + r['id'] + '">Read both texts</a> · <a href="evidence.html#' + r['id'] + '">Code and test scope</a></p><div class="photos">' + figure(r['images'][0], r['caption']) + figure(r['images'][1], caption) + '</div></section>'
write(O / 'index.html', page('Procedural Generation — complete readings', body))

for kind, label in [('tutorial', 'tutorial'), ('final', 'reflective sequence')]:
    title = 'Procedural Generation — complete ' + label
    combined = '# ' + title + '\n\nSeven halls in canonical spine order. Current source texts collected on 9 October 2026. See REVIEW.md and evidence.html for the scope of the checks.\n\n'
    body = '<h1>' + title + '</h1>' + toc(kind)
    for i, r in enumerate(records):
        text = portable(r['texts'][kind], f'{i+1}-{kind}')
        combined += '\n---\n\n<!-- hall: ' + r['id'] + ' -->\n\n' + text + '\n'
        body += '<article class="chapter" id="' + r['id'] + '"><p class="eyebrow">' + f'{i+1:02d} · ' + r['name'] + '</p>' + render(text) + '</article>'
    write(O / (kind + '.md'), combined)
    write(O / (kind + '.html'), page(title, body, 'reading'))

body = '<h1>Two texts,<br>one sequence.</h1><p>Tutorial on the left; reflection on the right. On narrow screens each pair stacks in that order.</p>' + toc('parallel')
for i, r in enumerate(records):
    body += '<section class="chapter" id="' + r['id'] + '"><p class="eyebrow">' + f'{i+1:02d} · ' + r['name'] + '</p><div class="spread">'
    for kind, label in [('tutorial', 'Left · tutorial.md'), ('final', 'Right · final.md')]:
        body += '<article><p class="eyebrow">' + label + '</p>' + render(portable(r['texts'][kind], f'{i+1}-{kind}')) + '</article>'
    body += '</div></section>'
write(O / 'parallel.html', page('Procedural Generation — facing texts', body))

assessment = '''# Procedural Generation — how the sequence reads

The seven-hall order holds. Its strongest thread is learning to distinguish a record, an operation and a resulting body. L-systems has already established that a description can receive different readings. Procedural Generation asks what those readings select, connect and leave out.

The code now supports that reading: all 22 current printed files were extracted again and executed in the prepared Godot project. The established suites passed 200 checks, including complete lesson hosts, guided edits, deliberately faulty variants and supplied XRTools poses. This is a fresh author-led regression, not a blind ghost student or proof of independent learning.

## The capacities accumulate

| Hall | New decision the student can make | What continues |
|---|---|---|
| Genetic Evolution | Change what a score rewards without replacing the candidate bodies | A design record can be kept while another reader evaluates it |
| Space Colonization | Decide which sites answer and how directions are combined | Positions, parent links and a small fixed request field |
| Branching Growth | Change when a parent stops producing children | The same field; a distinction between records and positions |
| Percolation Network | Change contact while preserving occupancy | Arrays become a space of permitted connections |
| Caves and Mazes | Change clearance while preserving carving centres | A list of events becomes a volume; repeated events remain in history |
| Sculpted Forms | Choose the extent of a sampled approximation | Coordinates become cells, and exposed cell boundaries become triangle faces |
| Mirrored Patterns | Change a copying rule while preserving its input | Kept source, editable result and a test that inspects the actual cells |

Evolution is a useful departure from L-systems: a generated body now meets a criterion. Colonization and Branching then make two different target relationships visible. Percolation supplies the important break: a branch record or a nearby point does not automatically establish a connection.

The strongest continuous passage is **Percolation → Caves → Sculpted Forms**. Reachable addresses become clearance; occupied addresses become a surface. These are related uses of a grid, but each asks a different question. The learner can reuse earlier arrays, coordinates and triangle construction without pretending that one representation answers everything.

Mirrored Patterns is a good quieter ending after the construction load of Sculpted Forms. Its five-by-five field makes an odd centre axis inspectable. Two outputs can contain the same number of live cells and still differ at four addresses. That is a small, useful demonstration of why a summary is not the object it describes.

## Where the load rises

Space Colonization asks the student to coordinate eligibility, nearest-site assignment, direction averaging and parent links. Its three-request first step is essential. Stay with that prediction before opening the eight-request field; the large canopy is a comparison rather than a second implementation.

Sculpted Forms is the densest program: capture in a local frame, floor to an address, mark a neighbourhood, find exposed faces and submit triangles. The revised tutorial follows one fixed centre through these stages before assembling the three-cube surface. Its exact cell count and selected face coordinates pass seven native checks against the printed model and assembler. Ask whether the reader can now explain that cell and face before running the whole surface. Physics reconstruction and the dome remain separate museum comparisons.

The identical PointBody is printed in every lesson so no dependency disappears. It is reusable infrastructure, not seven new topics. The host changes which action the point triggers. The texts should continue to state that connection explicitly; a familiar appearance alone cannot explain a new action.

## What each text contributes

The tutorials give the complete construction, the chosen scope and a testable variation. The reflections ask what it means to value one feature, allow one response, count one record, permit a passage or call a representation sufficient. The pair works best where the reflection stays with an encounter and the tutorial carries the operating detail.

The first two reflections have been tightened. Evolution falls from 788 to 494 words; Colonization from 937 to 590. They retain the encounters, qualifications and reference while the tutorials carry the longer operating explanation. The before texts and exact diffs are included in the revision report.

The recurring critical question is concrete: **what information did this operation use, and what consequence followed from what it omitted?** A score can ignore a ring. A record can repeat a position. A route can lack headroom. A sample can forget rotation. These encounters support reflection without treating a software property as an automatic political or philosophical conclusion.

## Keep the lesson boundaries visible

This is not seven complete production generators rebuilt from nothing. Evolution reconstructs an evaluator while reproduction remains supplied. Caves reconstructs carving while random walkers and backtracking remain museum encounters. Sculpted Forms samples a static fixture while the museum supplies a physical fall. Mirrored Patterns reconstructs copying while the cellular evolution and graph displays remain comparisons.

Those boundaries are useful if a student can name what was supplied and reproduce the operation being taught. They are not permission to omit a helper required by the printed program. The current complete programs include their hosts and unchanged PointBody, with the prepared museum and XRTools declared as dependencies.

## The room repairs

The workshops in Branching, Percolation, Caves, Sculpted Forms and Mirrored Patterns have moved five metres left and two metres inward from their old positions. The Sculpted Forms dome moved into its bay and its local instance was uniformly scaled to 0.55. Its stock footprint now fits inside the room. The new review preserves matched-camera before/after views, exact placement changes and source hashes.

All five actual entrance and exit records are valid. The new native probes pass 66 checks: sampled standing-capsule routes with floor support, supplied desktop movement from the entrance, real pointer input at each desk, retained camera views and the dome's four cut states. They do not establish a complete portal-stream transition or physical-headset walk. The route through Sculpted Forms crosses in front of the desk before following the left aisle. Mirrored Patterns retains its spare rear space.

The earlier 231 museum checks and earlier learner photographs stay dated. New overhead views show the repaired layouts. After captures isolate command bridges and the dynamic environment; lighting and moving exhibits can differ from the before views. No new headset-comfort, Quest-performance or independent learner result is claimed.

## The next useful review

Keep the order. Give a reviewer the two complete readings and ask them to choose one unprescribed edit: state what stays fixed, predict an observable difference and test both. A reviewer who only reads should label that prediction as unexecuted. Record the first missing dependency or unexplained change of representation, rather than asking every artifact to become a tutorial.

The next sequence can then inherit a meaningful distinction: a body's stored relationships and the positions it currently occupies are not the same thing. That is a sound place to begin bodies that yield.
'''
write(O / 'REPORT.md', assessment)
write(O / 'assessment.html', page('Procedural Generation — sequence assessment', render(assessment), 'reading'))

brief = '''# Review Procedural Generation as the ghost student

You are the imagined future student. You learn to make things even in a future where a machine could produce them for you, much as someone still plays chess. Pleasure and melancholia can coexist. Treat that future as the premise of your role, not as an established prediction. Treat the code as real.

You are inside the prepared Endless Museum. Earlier lessons supplied points, lines, coordinates, arrays, loops, functions, classes, transformations, randomness, cell updates, triangle meshes and L-system descriptions/readers. PointBody is familiar. The museum supplies camera, player, floor and XRTools. Each tutorial declares a small reconstruction within that environment. Other artifacts may belong to reflection or simply to the encounter.

Read tutorial.html and final.html separately, or parallel.html together. Follow all seven halls in the supplied order. For each hall, say what you bring, what new decision you can make, what exact object or record you produce, what you can predict and what travels onward. Identify the earliest missing dependency or unexplained step. Do not infer a complete genetic algorithm, cave generator or cellular system where the lesson explicitly reconstructs only one operation.

Choose one variation that is not already prescribed. State the input you will retain, the result you predict and an invariant. Run it if you have the prepared project; otherwise mark it as a proposed, unexecuted experiment. Report whether you could choose and explain the change from the material alone.

Assess tutorial and reflection as different texts. The tutorial must reconstruct its stated focus with complete code and sufficient explanation. The reflection may associate and question, while keeping computational facts, spatial experiences and interpretations distinct. Flag repeated operational detail only where it interrupts that second reading.

All 22 primary files are in halls/<map>/code. Identical filenames live in separate hall folders. Each matches a marked code block in the current tutorial; no scene-node dollar references are required. PointBody is byte-identical across the seven lessons. This ZIP is not a standalone Godot project: its code expects the prepared museum and XRTools.

The fresh runtime folder records 200 passing checks using the author's existing assertion suites. Complete hosts, guided variations, faulty controls and supplied XRTools poses ran. These receipts support specific behaviour; they are not a blind independent student test. Seven new checks verify the worked centre-to-face example. The revision folder records 66 new room checks after repairing five entrance obstructions and the dome footprint, plus dated before evidence. The 231 earlier museum checks retain their original scope. No new seven-hall physical traversal, headset-comfort or Quest-performance result is claimed.

Use REVIEW-NOTES.md for your response. Give the hall, exact passage, difficulty, proposed change and what must remain intact. The order and texts remain reviewable. If you only inspect the package, do not describe the supplied receipts as tests you performed.
'''
write(O / 'REVIEW.md', brief)
if not (O / 'REVIEW-NOTES.md').exists():
    write(O / 'REVIEW-NOTES.md', '# Procedural Generation review notes\n\nFor each note: exact passage; difficulty; proposed change; what must remain intact.\n\n' + ''.join('## ' + r['name'] + '\n\n- \n\n' for r in records))

run_note = '''# Re-running the current learner checks

Use the prepared AdaResearch project with its existing XRTools installation and Godot 4.6. This package is review material, not a complete project.

The repository command is `python -X utf8 tools/test_procedural_sequence.py`. It creates a new timestamped runtime folder instead of replacing earlier hall receipts. Its individual harnesses compare marked tutorial code with the study sources before execution. The current harnesses use the author's local Godot executable path; set that path for another machine before running them.

For the exact supplied native probes, copy this complete-readings folder into `doc/book/iterations/2026-10-09-procedural-generation-complete-readings` within the prepared project, preserving runtime subpaths. For each hall, run the command below with its runtime path. The probe loads the supplied printed, variation and deliberately faulty versions. It replaces that run's checks.json; retain the original archive if you need to compare receipts.

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://doc/book/iterations/2026-10-09-procedural-generation-complete-readings/RUNTIME_PATH/run.gd
```

Use a nonzero exit, SCRIPT ERROR, Parse Error or a false assertion as a failure. Headless execution does not test visual presentation or physical controllers. The copied run.py files record the original invocation and contain machine-specific paths; run.gd and its adjacent source folders are the portable native test inputs within the prepared project.

Runtime paths for this publication:

''' + ''.join('- `' + r['fresh_directory'] + '`\n' for r in records)
write(O / 'RUN.md', run_note)
write(O / 'README.txt', 'Open index.html for the seven-hall route, tutorial.html or final.html for separate complete readings, or parallel.html for tutorial left / reflection right. REPORT.md assesses the sequence. REVIEW.md is a reviewer brief; REVIEW-NOTES.md is editable. Current printed programs passed 200 fresh checks, with 7 further worked-example checks. revision/index.html shows editorial changes and before/after views of five repaired entrances and the resized dome, with 66 native room checks. Earlier museum images and 231 checks remain dated hall evidence. No complete seven-hall walk or physical-headset result. Requires the prepared museum and XRTools; not a standalone Godot project. RUN.md explains test reproduction. Canonical hall Markdown copies preserve original references; compiled readings include portable images.\n')

evidence = '<h1>What was actually checked.</h1><p class="lead">200 fresh learner checks. 22 exact printed files. Seven complete lesson hosts.</p><p>The existing author-led suites were run again from the current code blocks. They include the guided variants and faulty controls. The same run also verifies the complete hosts and supplied XRTools poses. It does not simulate an unfamiliar learner’s understanding.</p><p><a href="' + latest['directory'] + '/results.json">Fresh results</a> · <a href="' + latest['directory'] + '/manifest.json">Run manifest</a> · <a href="RUN.md">Re-run instructions</a> · <a href="manifest.json">Publication manifest</a></p>'
evidence += '<p>The 231 museum checks below belong to the earlier individual hall passes. Their artifact programs are unchanged; five map placements have since been repaired. <a href="revision/index.html">The revision report</a> provides 66 new room checks, native before/after captures, seven worked-example checks and exact source changes. Historical manifests are preserved rather than relabelled as current tests.</p><div class="table-wrap"><table><tr><th>Hall</th><th>Fresh learner checks</th><th>Earlier museum checks</th><th>Printed files</th></tr>'
for r in records:
    evidence += '<tr><td><a href="#' + r['id'] + '">' + r['name'] + '</a></td><td>' + str(r['fresh_checks']) + '</td><td>' + str(r['earlier_museum_checks']) + '</td><td>' + str(len(r['files'])) + '</td></tr>'
evidence += '</table></div><p>Counts are not a teaching-quality score. See the sequence assessment for density, continuity and the limits of spatial verification.</p>'
for r in records:
    base = 'halls/' + r['id'] + '/'
    fresh = r['fresh_directory'] + '/'
    evidence += '<section class="chapter" id="' + r['id'] + '"><h2>' + r['name'] + '</h2><p>' + html.escape(r['scope']) + '</p><p><a href="' + fresh + 'checks.json">Fresh assertions</a> · <a href="' + fresh + 'engine.log">Engine log</a> · <a href="' + fresh + 'run.gd">Exact native probe</a></p><p><a href="' + base + 'receipts/earlier-museum.json">Earlier museum receipt</a> · <a href="' + base + 'receipts/earlier-hall-manifest.json">Earlier hall manifest</a> · <a href="' + base + 'receipts/earlier-hall-report.md">Earlier room findings</a></p><p><a href="' + base + 'tutorial.md">Canonical tutorial source</a> · <a href="' + base + 'final.md">Canonical reflection source</a></p><ul>' + ''.join('<li><a href="' + base + 'code/' + name + '">' + name + '</a></li>' for name in r['files']) + '</ul></section>'
write(O / 'evidence.html', page('Procedural Generation — evidence and scope', evidence))

dump(O / 'manifest.json', {'date': '2026-10-09', 'canonical_sources': sources,
    'scope': 'Current revised readings. Fresh existing learner suites; seven new worked-example checks; 66 new repaired-room checks and captures. Earlier museum evidence remains dated. No independent learner, full portal traversal or physical headset test.',
    'fresh_run': latest['directory'], 'fresh_checks': fresh_count, 'primary_files': file_count,
    'earlier_museum_checks': earlier_count, 'same_point_body_across_halls': True,
    'protected_museum_sources': protected,
    'historical_museum_sources': historical_protected,
    'revision': {'directory': 'revision', 'editorial_sources': len(revisions), 'walkthrough_checks': 7,
                 'native_after_checks': spatial['after_checks'], 'before_diagnostics': spatial['before_diagnostic_checks']},
    'halls': [{k: v for k, v in r.items() if k != 'texts'} for r in records]})


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = []

    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k, v in attrs if k in ['href', 'src'] and v)
        self.ids.extend(v for k, v in attrs if k == 'id')


parsers = {}
for path in O.glob('*.html'):
    parser = Links()
    parser.feed(path.read_text(encoding='utf-8'))
    assert len(parser.ids) == len(set(parser.ids)), ('duplicate IDs', path.name)
    parsers[path.name] = parser
archive = O / 'procedural-generation-review.zip'
refs = 0
for name, parser in parsers.items():
    for ref in parser.links:
        u = urlsplit(ref)
        if u.scheme:
            continue
        target = unquote(u.path) or name
        assert (O / target).is_file() or target == archive.name, (name, ref)
        if u.fragment and target in parsers:
            assert u.fragment in parsers[target].ids, (name, ref)
        refs += 1

for kind in ['tutorial', 'final', 'parallel']:
    kinds = ['tutorial', 'final'] if kind == 'parallel' else [kind]
    expected = [block + '\n' for r in records for k in kinds for block in re.findall(r'```gdscript\n(.*?)\n```', r['texts'][k], re.S)]
    actual = [html.unescape(block) for block in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>', (O / (kind + '.html')).read_text(encoding='utf-8'), re.S)]
    assert expected == actual, ('rendered code parity', kind)
for path, digest in sources.items():
    assert sha(R / path) == digest, ('source changed during publication', path)
for path, digest in protected.items():
    assert sha(R / path) == digest, ('museum changed during publication', path)

with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for path in O.rglob('*'):
        if not path.is_file() or path.suffix in ['.zip', '.uid'] or '__pycache__' in path.parts or path == O / 'validation.json':
            continue
        data = path.read_bytes()
        if path.suffix == '.html':
            data = re.sub(rb'href="((?:\.\./)*)procedural-generation-review.zip"', rb'href="\1README.txt"', data)
        z.writestr(path.relative_to(O).as_posix(), data)

with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    members = set(z.namelist())
    for name in [n for n in members if n.endswith('.html')]:
        parser = Links()
        parser.feed(z.read(name).decode('utf-8'))
        for ref in parser.links:
            u = urlsplit(ref)
            if u.scheme:
                continue
            target = posixpath.normpath(str(PurePosixPath(name).parent / unquote(u.path))) if u.path else name
            assert target in members, ('archive link', name, ref)
    for r in records:
        for kind in ['tutorial', 'final']:
            relative = 'halls/' + r['id'] + '/' + kind + '.md'
            assert z.read(relative) == (R / 'commons/maps' / r['id'] / (kind + '.md')).read_bytes()
        for name, digest in r['files'].items():
            relative = 'halls/' + r['id'] + '/code/' + name
            assert hashlib.sha256(z.read(relative)).hexdigest() == digest

validation = {'passed': True, 'canonical_hashes': len(sources), 'primary_file_parity': file_count,
    'fresh_native_checks': fresh_count, 'earlier_museum_checks': earlier_count,
    'same_point_body_across_halls': True, 'local_refs_and_anchors': refs,
    'unique_html_ids': True, 'all_rendered_gdscript_blocks_match': True,
    'canonical_hall_copies_match_zip': True, 'zip_crc': True, 'zip_internal_refs': True,
    'protected_museum_hashes': len(protected), 'canonical_texts_changed_in_revision': len(revisions),
    'printed_code_changed': False, 'museum_algorithm_changed': False,
    'placement_changes': 'Five desks and one local dome instance; maps and matching plan rows',
    'new_walkthrough_checks': 7, 'new_museum_checks': 66, 'fresh_museum_render': True,
    'independent_learner_test': False, 'browser_layout_tested': False,
    'physical_headset_test': False, 'fresh_run': latest['directory']}
dump(O / 'validation.json', validation)
with zipfile.ZipFile(archive, 'a', zipfile.ZIP_DEFLATED) as z:
    z.write(O / 'validation.json', 'validation.json')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
print(json.dumps({'published': str(O / 'index.html'), 'halls': len(records), 'files': file_count,
                  'fresh_checks': fresh_count, 'refs': refs, 'zip_MB': round(archive.stat().st_size / 1e6, 2)}))
