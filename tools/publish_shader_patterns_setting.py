"""Publish source-grounded images of the second shader setting."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/encounter_pilot/Shader_05_Patterns/passage'
OUT = ROOT / 'doc/book/iterations/2026-10-10-patterns-in-the-museum'
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
old = json.loads((OUT / 'before/map_data.json').read_text(encoding='utf-8-sig'))
now = json.loads((ROOT / 'commons/maps/Shader_05_Patterns/map_data.json').read_text(encoding='utf-8-sig'))
for z, row in enumerate(old['layers']['interactables']):
    for x, token in enumerate(row):
        if str(token).strip():
            assert now['layers']['interactables'][z][x].split('#')[0] == token.split('#')[0]
assert old['layers']['utilities'] == now['layers']['utilities']
assert old['layers']['structure'][16:] == now['layers']['structure'][16:]
for key in ['reference_studies', 'model_disagreement', 'fuzzy_body', 'fuzzy_doorway']:
    assert old['map_info']['museum'][key] == now['map_info']['museum'][key]

views = [
    ('passage', 'Walk into the repeat', 'The first hall’s circle becomes a repeated lookup on walls, floor, cube, column and chair. A plain central strip keeps the route legible. This is a standing-height Godot capture inside Shader_05_Patterns.'),
    ('console', 'Three changes, one bench', 'DENSITY changes repeats per metre. SHIFT slides the lookup while the objects stay still. CHAIR moves the existing chair prefab along its rail. ATTACH switches its coordinate frame; RESET restores the comparison.'),
    ('across', 'The object and its surroundings', 'The circle has travelled from a square display into a furnished space. Architecture and chair use a supplied three-direction projection; the small teaching square uses its UVs. These are declared adapters, not identical coordinate sources.'),
    ('chair-room', 'Before moving the chair', 'The pattern is anchored to the room. Geometry, material rule and light are held for the following comparison.'),
    ('chair-room-moved', 'The chair crosses the pattern', 'The same camera sees the chair 0.7 metres farther along its rail. The pattern remains anchored to the room, so the chair receives a different part of it.'),
    ('chair-attached', 'The chair carries its pattern', 'The chair is at the same rail position as the preceding image, but its projection now uses the chair’s frame. Further movement carries the pattern along. Metre units are retained despite the enlarged prefab.'),
    ('overview', 'A place within the existing hall', 'A slightly elevated view. The new entrance bay occupies previously unused cells. All eight earlier artifacts remain at their authored cells, including the pattern garden, camera study, model gallery and fuzzy studies.'),
]
sources = [
    'commons/maps/Shader_05_Patterns/map_data.json',
    'algorithms/shaders/book_of_shaders/shader_05_patterns.gd',
    'commons/artifacts/shader_pattern_passage/repeated_mask.gdshader',
    'commons/artifacts/shader_pattern_passage/shader_pattern_passage.gd',
    'commons/artifacts/shader_pattern_passage/shader_pattern_passage.tscn',
    'commons/artifacts/registry/shader_pattern_passage.json',
    'commons/primitives/chair/chair_modern.gd',
    'tools/probes/shader_patterns_museum.gd',
]
manifest = {'hall': 'Shader_05_Patterns', 'checks_passed': len(report['checks']),
            'scope': report['scope'], 'prior_placements_preserved': True,
            'source_sha256': {}, 'image_sha256': {}}
for rel in sources:
    dest = OUT / 'source' / rel; dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / rel, dest)
    manifest['source_sha256'][rel] = hashlib.sha256(dest.read_bytes()).hexdigest()
for stem, _, _ in views:
    shutil.copy2(RUN / f'{stem}.png', OUT / f'{stem}.png')
    manifest['image_sha256'][f'{stem}.png'] = hashlib.sha256((OUT / f'{stem}.png').read_bytes()).hexdigest()
for filename in ['report.json', 'source_manifest.json', 'engine.log']:
    shutil.copy2(RUN / filename, OUT / filename)
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')

def esc(value): return html.escape(str(value), quote=True)

first = ROOT / 'doc/book/iterations/2026-10-10-shaping-in-the-museum/index.html'
style = re.search(r'<style>.*?</style>', first.read_text(encoding='utf-8'), re.S).group()
figures = ''.join(f'<figure id="{stem}"><a href="{stem}.png"><img src="{stem}.png" alt="{esc(title)} — native museum capture" {"loading=lazy" if i else ""}></a><figcaption><h2>{esc(title)}</h2><p>{esc(caption)}</p></figcaption></figure>' for i, (stem, title, caption) in enumerate(views))
checks = ''.join(f'<li>{esc(c["test"])}</li>' for c in report['checks'])
links = ''.join(f'<li><a href="source/{p}">{esc(p)}</a></li>' for p in sources)
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Patterns inside Endless Museum</title>{style}
<header><div class="eyebrow">Endless Museum · Shaders / hall 2 · 10 October 2026</div><h1>The image leaves its frame.</h1><p>Shaping drew one circle. Patterns reads that same rule at repeated addresses. Now the image crosses a floor, a column and a familiar chair: a surface operation becomes a place you can enter.</p><nav><a href="#passage">The passage</a><a href="#console">Controls</a><a href="#chair-room">Chair comparison</a><a href="#evidence">Evidence</a><a href="../2026-10-10-shaping-in-the-museum/index.html">Previous hall</a></nav></header>
{figures}
<section class="facts"><div><h2>Carried forward</h2><p>The circle still uses distance and a radius. Applying fract() before reading that distance repeats the mask. The cube and chair remain their original meshes; the shader does not instantiate copies.</p></div><div><h2>A precise comparison</h2><p>Move the image while keeping the bodies still. Then move the chair. A room-anchored pattern and one attached to the chair respond differently. The projection adapter is supplied infrastructure.</p></div><div><h2>The wider museum stays</h2><p>The existing pattern rack has full-square receivers and raised controls in all three modes. The other studies, their placements, the main sequence and the tutorial/final manuscripts are retained.</p></div></section>
<section class="evidence" id="evidence"><div class="inner"><span class="badge">{len(report['checks'])} native checks passed</span><h2 style="margin-top:22px">What the run establishes</h2><p>Godot 4.6 loads the actual museum map and registered installation. Tests cover all three slider receivers, buttons, existing artifacts, all three rack modes, and rendered-pixel comparisons for repetition, a full-period return, and object/room mapping. The entrance, passage and return loop are checked at quarter-metre intervals for floor and standing clearance.</p><p>Walk out of the existing entrance landing before turning right into the new bay. The first test’s immediate sideways turn intersected the landing enclosure; the verified route respects that existing doorway.</p><p>The run uses the compatibility renderer, XR disabled. Physical headset input, traversal into the next hall and learner reconstruction remain untested. The log reports an existing unresolved default-audio-bus UID from project.godot; no script or shader errors occurred in this final run.</p><p><a href="report.json">Checks</a> · <a href="engine.log">Engine log</a> · <a href="manifest.json">Source and image hashes</a> · <a href="source_manifest.json">Museum harness manifest</a></p><details><summary>All native checks</summary><ol>{checks}</ol></details><details><summary>Source snapshots and prior layout</summary><ul>{links}</ul><p><a href="before/map_data.json">Before: map</a> · <a href="before/shader_05_patterns.gd">Before: pattern rack</a></p></details><details><summary>Reproduce</summary><p><code>python -X utf8 tools/run_encounter_probe.py Shader_05_Patterns --sequence shaders --probe tools/probes/shader_patterns_museum.gd --render --no-bridges --output-tag passage</code></p></details></div></section><footer>Seven actual museum captures. The last view is elevated; the others are at standing eye height. Next proposed setting: the familiar object acquires another skin, in Queer Materials.</footer></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'page': str(OUT / 'index.html'), 'images': len(views), 'checks': len(report['checks'])}))
