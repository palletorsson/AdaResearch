"""Publish native museum photographs, the revised reading, and bounded checks."""
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
HALL = ROOT / 'commons/maps/Primitives_Ignorance'
RUN = ROOT / 'ada_run/encounter_pilot/Primitives_Ignorance_courtyard'


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


photos = [
    ('courtyard-entry', 'Let No One Ignorant of Geometry Enter. The inscription is back above the passage.'),
    ('five-solids', 'One of each Platonic solid, in off-black and off-white. All five can be picked up.'),
    ('resolution-chamber', 'The second room: paired spheres, twelve further constructions, and the five-segment capsule at the centre.'),
    ('five-on-four-to-eleven', 'The original capsule, enlarged to 1.6 m, still turning. Eight cylinder tiers have four through eleven radial divisions.'),
    ('sphere-atlas', 'Twelve spheres vary rings and radial segments independently. Their actual triangle edges stay visible.'),
    ('primitive-prefabs', 'Eight other engine mesh families, each packaged in its own reusable scene. These are fixed viewing exhibits.'),
    ('secondary-alcove', 'The older studies remain through the side opening. The diamond tower keeps its twelve units at a smaller scale.'),
]
for name, _ in photos:
    shutil.copy2(RUN / (name + '.png'), HERE / (name + '.png'))
for name in ['report.json', 'source_manifest.json']:
    shutil.copy2(RUN / name, HERE / name)
shutil.copy2(RUN / 'stdout.log', HERE / 'stdout.txt')

checks = []


def check(name, result):
    checks.append({'name': name, 'passed': bool(result)})


before = read_json(HERE / 'before-map_data.json')
after = read_json(HALL / 'map_data.json')
placements = [(x, z, token) for z, row in enumerate(after['layers']['interactables'])
              for x, token in enumerate(row) if token]
check('All four map layers are 27 by 43',
      all(len(layer) == 43 and all(len(row) == 27 for row in layer)
          for layer in after['layers'].values()))
check('Twenty-eight declared artifact placements', len(placements) == 28)
old_supports = Counter(token for row in before['layers']['interactables'] for token in row
                       if token.strip() and token.split(':')[0].split('#')[0] not in {
                           'sphere', 'sphere_high', 'sphere_mid', 'sphere_low',
                           'platonic_grabbables', 'budget_of_smoothness', 'capsule'})
alcove = [(x, z, t) for x, z, t in placements if x >= 19]
new_supports = Counter(t.split('#scale:')[0] if t.startswith('diamonds#scale:') else t
                       for _, _, t in alcove)
check('All sixteen older secondary/decorative placements kept in the alcove',
      len(alcove) == 16 and new_supports == old_supports)
for key in ['sphere_high', 'sphere_mid', 'sphere_low']:
    entries = [t for _, _, t in placements if t.split(':')[0] == key]
    check(key + ' retains both inspection presentations',
          len(entries) == 2 and any('#inspection_edges:1' in t for t in entries)
          and any('#inspection_edges:0' in t for t in entries))

for filename, containers in [
    ('artifact_roles.json', ['roles', 'groups', 'order', 'notes', 'positions']),
    ('museum_core_encounters.json', ['rooms']),
]:
    old = read_json(HERE / 'before/commons/data' / filename)
    new = read_json(ROOT / 'commons/data' / filename)
    for container in containers:
        if isinstance(old.get(container), dict):
            old[container].pop('Primitives_Ignorance', None)
            new[container].pop('Primitives_Ignorance', None)
    check('Other curation records preserved in ' + filename, old == new)

native = read_json(HERE / 'report.json')
check('All sixty native checks completed and passed',
      native['passed'] and len(native['checks']) == 60
      and all(c['passed'] for c in native['checks']))
log = (HERE / 'stdout.txt').read_text(encoding='utf-8')
check('All twenty-eight placements loaded at authored cells',
      '28 verbatim + 0 slid of 28, 0 left behind' in log)
check('No GDScript error in the final native run', 'SCRIPT ERROR' not in log)
manifest = read_json(HERE / 'source_manifest.json')
for name in ['commons/maps/Primitives_Ignorance/map_data.json',
             'commons/scenes/endless_museum.gd',
             'doc/book/iterations/2026-09-27-ignorance-courtyard/probe.gd']:
    check('Native run used current ' + name, digest(ROOT / name) == manifest['sources'][name])

core = read_json(ROOT / 'commons/data/museum_core_encounters.json')['rooms']['Primitives_Ignorance']
text = (HALL / 'final.md').read_text(encoding='utf-8')
check('Book digest is current', digest(HALL / 'final.md') == core['text_sha256'])
check('Map digest is current', digest(HALL / 'map_data.json') == core['map_sha256'])
check('Headset and learner verification remain open', core['learner_verified'] is False)
anchors = [a for a in re.findall(r'<!--\s*@([^>]*?)\s*-->', text) if a]
check('Every book encounter anchor is actually placed',
      set(anchors) <= {t.split(':')[0].split('#')[0] for _, _, t in placements})
check('Core order matches manuscript encounters', anchors == core['primary_tokens'])

registry = read_json(ROOT / 'commons/artifacts/registry/commons_artifacts.json')['artifacts']
for token in ['geometry_courtyard', 'sphere_resolution_atlas', 'capsule_reliquary', 'primitive_mesh_library']:
    entry = registry[token]
    check(token + ' has a live registered scene',
          entry['map_ready'] and (ROOT / entry['scene'].replace('res://', '')).is_file())

for filename in ['final.md', 'technical.md', 'artifacts.md', 'map_data.json',
                 'summary.md', 'intent.md', 'tutorial.md', 'blurb.md']:
    old = (HERE / ('before-' + filename)).read_text(encoding='utf-8')
    new = (HALL / filename).read_text(encoding='utf-8')
    (HERE / (filename + '.diff')).write_text(''.join(difflib.unified_diff(
        old.splitlines(True), new.splitlines(True),
        fromfile='before/' + filename, tofile='current/' + filename)), encoding='utf-8')

sources = list((ROOT / 'commons/artifacts/ignorance_gallery').rglob('*.gd'))
sources += list((ROOT / 'commons/artifacts/ignorance_gallery').rglob('*.tscn'))
sources += [ROOT / 'commons/artifacts/station/station_plinth.gd',
            ROOT / 'commons/scenes/em/em_plinths.gd', ROOT / 'tools/em_map_halls.py']
fingerprints = {p.relative_to(ROOT).as_posix(): digest(p) for p in sorted(sources)}
(HERE / 'artifact-sources.json').write_text(json.dumps(fingerprints, indent=2) + '\n', encoding='utf-8')
evidence = {'checks': checks, 'passed': all(c['passed'] for c in checks)}
(HERE / 'preservation.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')

def figure(name, caption):
    return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

reading = markdown.markdown(text, extensions=['footnotes', 'fenced_code', 'tables'])
old_text = (HERE / 'before-final.md').read_text(encoding='utf-8')
diff = difflib.HtmlDiff(wrapcolumn=64).make_table(old_text.splitlines(), text.splitlines(),
    'Previous chapter', 'The expanded encounter', context=True, numlines=3)
css = '''body{margin:0;background:#f2f0e9;color:#202423;font:19px/1.7 Georgia,serif}
main{max-width:1280px;margin:auto;padding:45px 24px}h1{font:normal clamp(40px,6vw,76px)/1.08 Georgia,serif;max-width:950px}
h2{font-weight:normal}p{max-width:810px}nav,small,figcaption,summary{font:14px/1.6 system-ui}nav a{margin-right:20px}
a{color:#285b55}figure{margin:34px 0}img{width:100%;display:block}figcaption{margin-top:10px;max-width:900px}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:28px}.reading{max-width:790px;margin:75px auto}
.reading img{margin-top:25px}.footnote{font-size:15px}.scroll{overflow:auto}table.diff{font:12px/1.4 monospace}
td{vertical-align:top}.diff_add{background:#d7e9d9}.diff_sub{background:#eed5ce}.diff_chg{background:#eee0b4}
pre{background:#e6e4dc;overflow:auto;padding:18px;font:14px/1.5 monospace}@media(max-width:800px){.pair{display:block}}'''
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Five solids, many beginnings — Primitive Ignorance</title><style>{css}</style><main>
<small>PRIMITIVES IGNORANCE · 27 SEPTEMBER 2026 · NATIVE MUSEUM PHOTOGRAPHS</small>
<h1>Five solids.<br>Many beginnings.</h1>
<p>A court for the regular solids, a room for the many constructions of roundness, and a collection of forms the engine gives us. The older studies keep their own side alcove.</p>
<nav><a href="#court">The court</a><a href="#roundness">Roundness</a><a href="#prefabs">Other primitives</a><a href="#reading">Read the chapter</a><a href="#changes">Text changes</a><a href="#evidence">Checks</a></nav>
<section id="court">{figure(*photos[0])}{figure(*photos[1])}
<p>The sixteen columns pass through eight radial resolutions. The five solids keep their defining faces. Their shared furniture is now a plain matte off-white block, with the same finish used by the museum’s other shared plinths.</p></section>
<section id="roundness"><h2>A place for the five-sided body</h2>{figure(*photos[2])}
<div class="pair">{figure(*photos[3])}{figure(*photos[4])}</div>
<p>The earlier marked/plain sphere pairs and their counting counter remain. The twelve new spheres separate two decisions: how often to divide around the body, and how often along it. The capsule keeps its original five-by-five construction and rotation.</p></section>
<section id="prefabs"><h2>Other forms of beginning</h2>{figure(*photos[5])}
<p>Prism, torus, plane, quad, point, extruded text, ribbon trail and tube trail: eight reusable scenes around actual Godot mesh resources. The trail specimens show their rest geometry. The point holds a screen-pixel size. The earlier rooms already supply box, cylinder, sphere and capsule; a cone is a cylinder with one end radius reduced to zero.</p>
{figure(*photos[6])}<p>All sixteen older secondary/decorative placements remain in the alcove. Its tower is a smaller edition of the same twelve-part construction.</p></section>
<section id="reading" class="reading"><small>CURRENT FINAL.MD · PROMOTED TO THE BOOK</small>{reading}</section>
<section id="changes"><h2>The writing follows the new arrangement</h2>
<p>The earlier sphere comparison, cost and symmetry inquiry remains. New passages connect the courtyard, independent subdivisions, the capsule’s staging and the engine’s other primitive forms.</p>
<p><a href="final.md.diff">Manuscript diff</a> · <a href="technical.md.diff">Technical companion</a> · <a href="artifacts.md.diff">Inventory</a> · <a href="map_data.json.diff">Map</a></p>
<div class="scroll">{diff}</div></section>
<section id="evidence"><h2>What was checked</h2>
<p>All 28 placements loaded at their authored cells. Sixty native checks pass: the actual meshes, divisions, capsule rotation, support dimensions, pickup/release and five body-width routes, including the alcove entrance. {len(checks)} publication and preservation checks pass.</p>
<p>The existing engine UID warning remains in the log; the final run has no GDScript error. Headset targeting, comfort, label legibility and Quest performance remain untested. The main rooms are 19 cells wide; the requested side alcove makes the total 27, a deliberate exception to the template’s width preference.</p>
<p><a href="report.json">Native report</a> · <a href="preservation.json">Preservation checks</a> · <a href="source_manifest.json">Museum source record</a> · <a href="artifact-sources.json">Artifact sources</a> · <a href="stdout.txt">Native log</a> · <a href="DECISIONS.md">Decisions</a></p>
<p><a href="/compose/sources?map=Primitives_Ignorance&amp;doc=final">Read or comment on the current chapter</a> · <a href="/long-museum/encounters?map=Primitives_Ignorance">Locate the encounters</a></p></section>
</main></html>'''
(HERE / 'index.html').write_text(page, encoding='utf-8')
for item in checks:
    if not item['passed']:
        print('FAIL:', item['name'])
print(f'{len(checks)} publication/preservation checks; passed={evidence["passed"]}')
if not evidence['passed']:
    raise SystemExit(1)
