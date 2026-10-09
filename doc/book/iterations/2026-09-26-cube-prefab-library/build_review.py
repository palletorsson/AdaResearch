"""Publish the bounded Cube prefab-library review and preservation evidence."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
HALL = ROOT / 'commons/maps/Point_Animatedcube'


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


checks = []


def check(name, result):
    checks.append({'name': name, 'passed': bool(result)})


before = read_json(HERE / 'before-map_data.json')
after = read_json(HALL / 'map_data.json')
for layer in ['interactables', 'utilities']:
    old = {(x, z): token for z, row in enumerate(before['layers'][layer])
           for x, token in enumerate(row) if token}
    new = {(x, z): token for z, row in enumerate(after['layers'][layer])
           for x, token in enumerate(row) if token}
    check(f'Every earlier {layer} token and coordinate retained',
          all(new.get(at) == token for at, token in old.items()))
    if layer == 'interactables':
        check('Only the library placement added',
              {at: token for at, token in new.items() if at not in old}
              == {(16, 7): 'prefab_box_library:270:0#plinth:0'})
        check('Fifteen earlier artifact placements retained', len(old) == 15)
    else:
        check('No extra utility added', old == new)
check('All layer rows match the new 19 by 14 hall',
      all(len(layer) == 14 and all(len(row) == 19 for row in layer)
          for layer in after['layers'].values()))

for filename, containers in [
    ('artifact_roles.json', ['roles', 'groups', 'order', 'notes', 'positions']),
    ('museum_core_encounters.json', ['rooms']),
]:
    old = read_json(HERE / ('before-' + filename))
    new = read_json(ROOT / 'commons/data' / filename)
    for key in containers:
        if isinstance(old.get(key), dict):
            old[key].pop('Point_Animatedcube', None)
            new[key].pop('Point_Animatedcube', None)
    check(f'Other curation records unchanged in {filename}', old == new)

native = read_json(HERE / 'report.json')
check('All 19 native checks completed and passed',
      native['passed'] and len(native['checks']) == 19
      and all(c['passed'] for c in native['checks']))
check('No GDScript error in the completed native run',
      'SCRIPT ERROR' not in (HERE / 'stdout.log').read_text(encoding='utf-8'))
manifest = read_json(HERE / 'source_manifest.json')
for name in ['commons/maps/Point_Animatedcube/map_data.json',
             'commons/scenes/endless_museum.gd',
             'doc/book/iterations/2026-09-26-cube-prefab-library/probe.gd']:
    check(f'Native run used the current {name}',
          hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == manifest['sources'][name])

catalog = read_json(ROOT / 'commons/artifacts/prefab_box_library/catalog.json')
sources = {c['source'].replace('res://', '') for c in catalog['columns']}
check('Four real source scene families', len(sources) == 4)
check('All catalog source scenes exist', all((ROOT / p).is_file() for p in sources))
check('Twenty-four catalog entries', sum(len(c['rows']) for c in catalog['columns']) == 24)
roles = read_json(ROOT / 'commons/data/artifact_roles.json')
check('Library is a primary encounter after the cube construction group',
      roles['roles']['Point_Animatedcube']['prefab_box_library'] == 'primary'
      and roles['order']['Point_Animatedcube']['primary'][-1] == 'prefab_box_library')

old_text = (HERE / 'before-final.md').read_text(encoding='utf-8')
text = (HALL / 'final.md').read_text(encoding='utf-8')
start = 'Read the cartons: **A WORLD / WITHOUT / COMPOSITION**.'
check('Earlier outline, corner, diagonal and net inquiry preserved verbatim',
      text.split('<!-- @prefab_box_library -->')[0] == old_text.split(start)[0])
check('Shared book illustration matches the native image',
      (ROOT / 'doc/book/figures/Point_Animatedcube/prefab-library.png').read_bytes()
      == (HERE / 'repetitions-and-variations.png').read_bytes())
core = read_json(ROOT / 'commons/data/museum_core_encounters.json')['rooms']['Point_Animatedcube']
check('Book digest matches current final.md',
      core['text_sha256'] == hashlib.sha256((HALL / 'final.md').read_bytes()).hexdigest())
check('Learner verification remains open', core['learner_verified'] is False)

for filename in ['final.md', 'technical.md', 'artifacts.md', 'map_data.json']:
    old = (HERE / ('before-' + filename)).read_text(encoding='utf-8')
    new = (HALL / filename).read_text(encoding='utf-8')
    (HERE / (filename + '.diff')).write_text(''.join(difflib.unified_diff(
        old.splitlines(True), new.splitlines(True),
        fromfile='before/' + filename, tofile='current/' + filename)), encoding='utf-8')

evidence = {'checks': checks, 'passed': all(c['passed'] for c in checks)}
(HERE / 'preservation.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
fingerprints = {}
for p in sorted((ROOT / 'commons/artifacts/prefab_box_library').glob('*')):
    if p.is_file():
        fingerprints[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
for source in sorted(sources):
    p = ROOT / source
    fingerprints[source] = hashlib.sha256(p.read_bytes()).hexdigest()
    script = p.with_suffix('.gd')
    if script.exists():
        fingerprints[script.relative_to(ROOT).as_posix()] = hashlib.sha256(script.read_bytes()).hexdigest()
(HERE / 'artifact-sources.json').write_text(json.dumps(fingerprints, indent=2) + '\n', encoding='utf-8')

css = '''body{margin:0;background:#f2efe7;color:#252a29;font:19px/1.7 Georgia,serif}
main{max-width:1280px;margin:auto;padding:40px 24px}h1{font-size:clamp(36px,6vw,72px);font-weight:normal;line-height:1.1}
h2{font-weight:normal}p{max-width:800px}img{width:100%;display:block}figure{margin:32px 0}
figcaption,nav,small,summary{font:14px/1.6 system-ui}a{color:#285e55}nav a{margin-right:20px}
.reading{max-width:800px;margin:60px auto}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}
pre{font:14px/1.5 monospace;background:#e5e2d8;padding:18px;overflow:auto}.scroll{overflow:auto}
table.diff{font:12px/1.5 monospace}.diff_add{background:#d9eadb}.diff_sub{background:#efd6d2}.diff_chg{background:#eee3b7}
td{vertical-align:top}.footnote{font-size:15px}@media(max-width:800px){.pair{display:block}}'''
diff = difflib.HtmlDiff(wrapcolumn=65).make_table(old_text.splitlines(), text.splitlines(),
    'Earlier Cube chapter', 'With the prefab encounter', context=True, numlines=3)
body = markdown.markdown(text, extensions=['footnotes', 'fenced_code', 'tables'])
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Again — a library of boxes</title><style>{css}</style><main>
<small>POINT ANIMATEDCUBE · 26 SEPTEMBER 2026 · LIVE MUSEUM + BOOK</small>
<h1>Again.<br>A library of boxes.</h1>
<p>A shelf of ready-made objects: some identical, some altered. Take a copy down and begin another arrangement.</p>
<nav><a href="#shelf">The collection</a><a href="#arrangement">Make an arrangement</a><a href="#reading">Read the chapter</a><a href="#changes">Text changes</a><a href="#evidence">Checks and sources</a></nav>
<figure id="shelf"><a href="repetitions-and-variations.png"><img src="repetitions-and-variations.png" alt="Twenty-four box prefabs in six columns, in the widened Cube hall."></a><figcaption>Native Godot view inside the museum. A 9.12 m shelf holds 24 copies. Four columns repeat their models; two columns vary the crate and printed carton.</figcaption></figure>
<p>The collection reuses the project's cardboard box, wooden crate and cargo crate scenes. The printed AGAIN carton is an original addition. Its <a href="catalog.json">catalogue snapshot</a> lists the sources and variations; the editable source is <code>commons/artifacts/prefab_box_library/catalog.json</code>.</p>
<div class="pair"><figure><a href="library-in-the-hall.png"><img src="library-in-the-hall.png" alt="The shelf from its open aisle in the Cube hall." loading="lazy"></a><figcaption>The east gallery is wider. All fifteen earlier artifact placements remain.</figcaption></figure><figure><a href="crate-editions.png"><img src="crate-editions.png" alt="Repeated cartons beside changed crate and carton editions." loading="lazy"></a><figcaption>Colour, construction and lettering vary while the underlying prefab family remains recognisable.</figcaption></figure></div>
<section id="arrangement"><h2>The shelf lends you a vocabulary</h2><p>An empty worktable gives the copies somewhere to go. Take two identical cartons and a wooden crate: their geometry remains the same while their neighbours change. The shelf keeps the gaps.</p>
<figure><a href="another-arrangement.png"><img src="another-arrangement.png" alt="Two identical AGAIN cartons physically stacked beside a wooden crate on the worktable." loading="lazy"></a><figcaption>The production pickup/release path was exercised with a supplied grabber. Two cartons settle one above the other; a crate joins them. This is native physics, not a posed image-generation result.</figcaption></figure></section>
<section id="reading" class="reading"><small>CURRENT FINAL.MD · PROMOTED TO THE BOOK</small>{body}</section>
<section id="changes"><h2>What changed in the writing</h2><p>The outline, editable corners, hidden diagonal and folding net retain their earlier text. The new encounter follows them. Its ending now acknowledges the arrangement you can make on the table.</p>
<p><a href="final.md.diff">Exact manuscript diff</a> · <a href="technical.md.diff">Technical companion diff</a> · <a href="artifacts.md.diff">Inventory diff</a> · <a href="map_data.json.diff">Map diff</a></p><div class="scroll">{diff}</div></section>
<section id="evidence"><h2>What was checked</h2><p>All 19 native checks pass: placement, 24 copies, 12 configured editions, shared meshes with independent bodies, pickup/release, table contact, stacking and a visitor-width walk beside the shelf. Four checks retain the capture cameras. {len(checks)} publication and preservation checks pass.</p>
<p>Headset reach, controller targeting and Quest performance remain untested. The cardboard model has an enclosing box collider, so its visible opening is not a usable collision cavity. Arrangements last for the session. The existing engine UID and unrelated furnishing warnings are retained in the logs; the completed run has no GDScript error.</p>
<p><a href="report.json">Native report</a> · <a href="preservation.json">Preservation report</a> · <a href="artifact-sources.json">Artifact fingerprints</a> · <a href="library-manifest.json">Runtime catalogue</a> · <a href="source_manifest.json">Museum source record</a> · <a href="stdout.txt">Native log</a> · <a href="DECISIONS.md">Decisions</a></p>
<p><a href="/compose/sources?map=Point_Animatedcube&amp;doc=final">Read or comment on the current Cube chapter</a> · <a href="/long-museum/encounters?map=Point_Animatedcube">Locate its encounters</a></p></section>
</main></html>'''
(HERE / 'index.html').write_text(page, encoding='utf-8')
for item in checks:
    if not item['passed']:
        print('FAIL:', item['name'])
print(f'{len(checks)} preservation/publication checks; passed={evidence["passed"]}')
if not evidence['passed']:
    raise SystemExit(1)
