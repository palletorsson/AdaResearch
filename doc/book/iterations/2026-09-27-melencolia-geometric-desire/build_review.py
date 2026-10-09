"""Publish source-grounded comparison and photographs from the actual museum."""
from pathlib import Path
from collections import Counter
import difflib
import hashlib
import html
import json
import re
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
HALL = ROOT / 'commons/maps/Primitives_Melencolia'
RUN = ROOT / 'ada_run/encounter_pilot/Primitives_Melencolia_durer'
URL = 'http://localhost:3003/book-review/doc/book/iterations/' + HERE.name + '/index.html'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

photos = [
    ('tableau-front', 'The whole arrangement, photographed inside the museum. This frontal study lifts the viewpoint to show the tools on the ground.'),
    ('tableau-walk', 'At walking height on the left: the stone hides part of the smaller figure. Moving changes that overlap.'),
    ('tools-and-body', 'A sphere, a resting animal, folded cloth and the tools of a trade. The forms have company.'),
    ('number-and-stone', 'The stone and the square can be checked, while the scene remains open to interpretation.'),
    ('hall', 'The second platform in the existing hall. The earlier geometric court is retained.'),
]
for name, _ in photos:
    shutil.copy2(RUN / (name + '.png'), HERE / (name + '.png'))
for name in ['report.json', 'source_manifest.json']:
    shutil.copy2(RUN / name, HERE / name)
shutil.copy2(RUN / 'stdout.log', HERE / 'stdout.txt')
figure_folder = ROOT / 'doc/book/figures/Primitives_Melencolia'
figure_folder.mkdir(parents=True, exist_ok=True)
shutil.copy2(HERE / 'tableau-front.png', figure_folder / 'melencolia-tableau.png')
ref = Path('C:/Users/palle/AppData/Local/Temp/codex-clipboard-191ee995-2ad0-4f18-9a92-cf2dba33d40f.png')
if ref.is_file():
    shutil.copy2(ref, HERE / 'reference-engraving.png')

core_path = ROOT / 'commons/data/museum_core_encounters.json'
core = read(core_path)
entry = core['rooms']['Primitives_Melencolia']
entry.update({
    'reason': 'Recognise the court, then meet those forms among figures and tools after Dürer. Geometric desire links exact construction to unsettled purposes; the engine counter returns before Transformation.',
    'status': 'encounter_and_text_revised',
    'text_sha256': sha(HALL / 'final.md'),
    'map_sha256': sha(HALL / 'map_data.json'),
    'local_review': URL,
    'learner_verified': False,
})
core_path.write_text(json.dumps(core, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

checks = []
def check(name, ok):
    checks.append({'name': name, 'passed': bool(ok)})

before = read(HERE / 'before-map_data.json')
after = read(HALL / 'map_data.json')
native = read(HERE / 'report.json')
check('Native checks all completed and passed', native['passed'] and len(native['checks']) >= 45)
log = (HERE / 'stdout.txt').read_text(encoding='utf-8')
check('No GDScript errors in final run', 'SCRIPT ERROR' not in log)
check('All nineteen artifact placements load verbatim', '19 verbatim + 0 slid of 19, 0 left behind' in log)
check('Every original layer rectangular, 13 by 29', set(after['layers']) == set(before['layers']) and all(
    len(rows) == 29 and all(len(row) == 13 for row in rows) for rows in after['layers'].values()))
tokens = lambda d: [v.split(':')[0].split('#')[0] for row in d['layers']['interactables'] for v in row if v]
check('All nineteen original artifact identities retained', len(tokens(after)) == 19 and Counter(tokens(before)) == Counter(tokens(after)))
for layer in before['layers']:
    check('First court retained: ' + layer, before['layers'][layer][:10] == after['layers'][layer][:10])
text = (HALL / 'final.md').read_text(encoding='utf-8')
old_text = (HERE / 'before-final.md').read_text(encoding='utf-8')
check('First court prose preserved verbatim', old_text.split('## The tools are still here')[0] == text.split('## The tools are still here')[0])
check('Engine counter return and ending preserved', old_text.split('## The number that was already running')[1].split('[^solids]:')[0] == text.split('## The number that was already running')[1].split('[^solids]:')[0])
anchors = [a for a in re.findall(r'<!--\s*@([^>]*?)\s*-->', text) if a]
check('Book encounters retain primary order', anchors == entry['primary_tokens'])
check('Each book artifact is placed', set(anchors) <= set(tokens(after)))
check('Published book picture equals native capture', sha(figure_folder / 'melencolia-tableau.png') == sha(RUN / 'tableau-front.png'))
check('Old eight-prop scene retained', (ROOT / 'commons/scenes/demos/durer/DurerScene.tscn').read_bytes() == (HERE / 'before/commons/scenes/demos/durer/DurerScene.tscn').read_bytes())
old_core = read(HERE / 'before/commons/data/museum_core_encounters.json')
new_core = read(core_path)
old_core['rooms'].pop('Primitives_Melencolia'); new_core['rooms'].pop('Primitives_Melencolia')
check('Other core encounter records unchanged', old_core == new_core)
check('Artifact roles unchanged', read(HERE / 'before/commons/data/artifact_roles.json') == read(ROOT / 'commons/data/artifact_roles.json'))
old_registry = read(HERE / 'before/commons/artifacts/registry/commons_artifacts.json')
new_registry = read(ROOT / 'commons/artifacts/registry/commons_artifacts.json')
old_registry['artifacts'].pop('durer_scene'); new_registry['artifacts'].pop('durer_scene')
check('Other registry entries unchanged', old_registry == new_registry)
check('Current source digests in curation', entry['text_sha256'] == sha(HALL / 'final.md') and entry['map_sha256'] == sha(HALL / 'map_data.json'))

files = ['final.md', 'tutorial.md', 'critical.md', 'artifacts.md', 'intent.md', 'summary.md', 'map_data.json']
for name in files:
    old = (HERE / 'before/commons/maps/Primitives_Melencolia' / name).read_text(encoding='utf-8')
    current = (HALL / name).read_text(encoding='utf-8')
    (HERE / (name + '.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True), current.splitlines(True), fromfile='before/' + name, tofile='current/' + name)), encoding='utf-8')
    shutil.copy2(HALL / name, HERE / ('current-' + name))
sources = list((ROOT / 'commons/scenes/demos/durer').glob('*.gd')) + list((ROOT / 'commons/scenes/demos/durer').glob('*.tscn'))
sources += [HALL / name for name in files]
(HERE / 'artifact-sources.json').write_text(json.dumps({p.relative_to(ROOT).as_posix(): sha(p) for p in sources}, indent=2) + '\n', encoding='utf-8')
(HERE / 'preservation.json').write_text(json.dumps({'checks': checks, 'passed': all(c['passed'] for c in checks)}, indent=2) + '\n', encoding='utf-8')

def image(name, caption):
    return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

reading = markdown.markdown(text, extensions=['footnotes', 'fenced_code', 'tables'])
critical = markdown.markdown((HALL / 'critical.md').read_text(encoding='utf-8'), extensions=['tables'])
diff = difflib.HtmlDiff(wrapcolumn=62).make_table(old_text.splitlines(), text.splitlines(), 'Previous text', 'Current final.md', context=True, numlines=3)
css = '''body{margin:0;background:#eeeae1;color:#282720;font:19px/1.75 Georgia,serif}main{max-width:1260px;margin:auto;padding:40px 24px}h1{font-weight:normal;font-size:clamp(40px,6vw,75px);line-height:1.1;max-width:1000px}h2{font-weight:normal}p{max-width:830px}nav,figcaption,small,summary{font:14px/1.6 system-ui}nav a{margin-right:20px}a{color:#506345}img{width:100%;display:block}figure{margin:30px 0}figcaption{margin-top:10px}.pair{display:grid;grid-template-columns:1fr 2fr;gap:28px;align-items:start}.pair img{max-height:720px;object-fit:contain}.reading{max-width:790px;margin:75px auto}.reading img{margin-top:24px}.footnote{font-size:15px}.scroll{overflow:auto}table.diff{font:12px/1.45 monospace}td{vertical-align:top}table{border-collapse:collapse}th,td{padding:8px;border-bottom:1px solid #cfc9bb}.diff_add{background:#d6e6d1}.diff_sub{background:#ecd3cb}.diff_chg{background:#eadfa9}pre{background:#e2ded4;padding:18px;overflow:auto;font:14px/1.6 monospace}@media(max-width:750px){.pair{display:block}}'''
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Melencolia — geometric desire</title><style>{css}</style><main>
<nav><a href="#encounter">The room</a><a href="#reading">Read the chapter</a><a href="#relations">Geometric desire</a><a href="#diff">Text changes</a><a href="#evidence">Checks</a></nav>
<p><small>PRIMITIVES · 27 SEPTEMBER 2026 · NATIVE MUSEUM PHOTOGRAPHS</small></p>
<h1>The forms have company.</h1>
<p>A sphere beside a sleeping dog; a compass held by a figure who has stopped. The rebuilt Dürer tableau brings the primitive into an arrangement of work, bodily hesitation and desire.</p>
<section id="encounter"><div class="pair">{image('reference-engraving','The engraving supplied for this revision: Albrecht Dürer, Melencolia I, 1514. Public domain.')} {image('tableau-front',photos[0][1])}</div>
<p>The principal objects now follow the engraving’s relationships. This is a stylised sculptural interpretation: depths, hidden surfaces and the solid’s proportions are authored choices. The first geometric court remains a separate manuscript reference.</p>
{image('tableau-walk',photos[1][1])}{image('tools-and-body',photos[2][1])}
<details><summary>Previous tableau and wider hall views</summary>{image('before-tableau','Before: the earlier collection of separate props, photographed in the museum.')}{image('number-and-stone',photos[3][1])}{image('hall',photos[4][1])}</details></section>
<section id="reading" class="reading"><p><small>CURRENT CANONICAL FINAL.MD · <a href="http://localhost:3003/compose/sources?map=Primitives_Melencolia&amp;doc=final">Read and comment in Sources</a></small></p>{reading}</section>
<section id="relations"><h2>Different promises of geometry</h2><p>The chapter introduces the thread. This companion differentiates the histories and identifies possible returns elsewhere in the spine. These additional artists are references for development, not new exhibits installed in this hall.</p>{critical}</section>
<section id="diff"><h2>The exact text changes</h2><div class="scroll">{diff}</div><p><a href="final.md.diff">Plain manuscript diff</a> · <a href="map_data.json.diff">Map diff</a> · <a href="critical.md.diff">Critical companion diff</a> · <a href="current-tutorial.md">Implementation companion</a></p></section>
<section id="evidence"><h2>What was checked</h2><p>{len(native['checks'])} native checks: solid topology, numbers, the actual museum placement, circulation with a body-sized collider, ramps under gravity and screenshot camera retention. {sum(c['passed'] for c in checks)}/{len(checks)} publication and preservation checks pass.</p><p>Headset comfort, fine lettering at VR resolution, and Quest performance remain untested. Small tools are fixed scenic objects; they are not pick-up interfaces. The existing native run still reports unrelated legacy material and UID warnings.</p><p><a href="report.json">Native report</a> · <a href="preservation.json">Preservation checks</a> · <a href="artifact-sources.json">Source hashes</a> · <a href="stdout.txt">Native log</a></p></section>
</main></html>'''
(HERE / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'url': URL, 'native_checks': len(native['checks']), 'publication_checks': len(checks), 'failures': [c['name'] for c in checks if not c['passed']]}, indent=2))
assert all(c['passed'] for c in checks), 'Review checks failed; inspect preservation.json'
