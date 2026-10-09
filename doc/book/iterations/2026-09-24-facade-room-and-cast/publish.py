from pathlib import Path
import difflib
import hashlib
import json
import re

import markdown
from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
MAP = ROOT / 'commons/maps/Boolean_Facade_Cast'
TESTED = ROOT / 'ada_run/facade-room-cast-isolated'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


checks = json.loads((OUT / 'runtime.json').read_text(encoding='utf-8'))['checks']
assert all(record['pass'] for record in checks)
sources = []
for folder in ['commons/artifacts/facade_room_cast', 'commons/facade_parts']:
    for path in sorted((ROOT / folder).rglob('*')):
        if path.suffix not in ('.gd', '.gdshader', '.tscn', '.json'):
            continue
        relative = path.relative_to(ROOT)
        assert path.read_bytes() == (TESTED / relative).read_bytes(), relative
        sources.append({'file': relative.as_posix(), 'sha256': digest(path), 'matches_tested_copy': True})
for path in sorted(MAP.iterdir()) + [ROOT / 'commons/artifacts/registry/facade_room_cast.json', ROOT / 'commons/maps/Boolean_Colour_Spaces_II/map_data.json']:
    if path.is_file():
        sources.append({'file': path.relative_to(ROOT).as_posix(), 'sha256': digest(path)})
images = []
for path in sorted(OUT.glob('*.png')):
    with Image.open(path) as im:
        im.load()
        assert im.size == (1440, 900)
    images.append({'file': path.name, 'width': 1440, 'height': 900, 'sha256': digest(path)})
assert len(images) == 10
(OUT / 'manifest.json').write_text(json.dumps({
    'scope': 'Native isolated desktop study. Supplied camera and capsule routes. Full museum loader, tracked headset and Quest performance remain unverified.',
    'passed_records': len(checks), 'source': sources, 'images': images,
}, indent=2), encoding='utf-8')

relative = Path('commons/maps/Boolean_Colour_Spaces_II/map_data.json')
before = (OUT / 'before' / relative).read_text(encoding='utf-8')
after = (ROOT / relative).read_text(encoding='utf-8')
(OUT / 'study-portal.diff').write_text(''.join(difflib.unified_diff(
    before.splitlines(True), after.splitlines(True), fromfile='before/' + relative.as_posix(), tofile=relative.as_posix()
)), encoding='utf-8')

previous = (OUT.parent / '2026-09-24-boolean-more-spaces/index.html').read_text(encoding='utf-8')
style = re.search(r'<style>(.*?)</style>', previous, re.S).group(1)
style = style.replace('--pink:#efbddc', '--pink:#ddc49a').replace('--bg:#10121c', '--bg:#171817').replace('background:#1b1b2b', 'background:#242522')
style += '\nsection{scroll-margin-top:24px}.roomhead p{max-width:730px}.reading .footnote{font:15px/1.6 system-ui,sans-serif}.reading .footnote p{overflow-wrap:anywhere}.reading em{font-size:inherit}.reading p:has(img)+p em{font-size:16px}a:focus-visible,summary:focus-visible{outline:2px solid var(--pink);outline-offset:6px}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}'
reading = markdown.markdown((MAP / 'final.md').read_text(encoding='utf-8'), extensions=['footnotes'])
reading = re.sub(r'<h1>.*?</h1>', '<h2>The room and its volume</h2>', reading, count=1)


def figure(name, caption, alt):
    return f'<figure><a href="{name}.png"><img width="1440" height="900" loading="lazy" src="{name}.png" alt="{alt}"></a><figcaption>{caption}</figcaption></figure>'


page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The room and its volume | Ada Research</title><style>__STYLE__</style></head>
<body><header><p class="eyebrow">Ada Research / Boolean + Facade study / 24 September 2026</p>
<h1>The room<br>and its volume.</h1>
<p class="lead">Enter the room. Then walk around the space it held.</p>
<nav aria-label="Page sections"><a href="#encounter">The encounter</a><a href="#details">What remains</a><a href="#reading">Read the hall</a><a href="#play">Walk inside</a><a href="#evidence">Build notes</a></nav>
<a href="pair.png"><img width="1440" height="900" src="pair.png" alt="A terracotta facade with an open door beside the pale positive volume of its interior"></a>
<p class="caption">Two constructions from one interior. Native Godot render of the playable study.</p></header>
<main><div class="intro"><p>The existing facade works give us a door, a window and a cornice. Behind them, a straight wall meets a curved alcove. Beside the building, the removed volume stands on the same ground.</p><p>The openings become projections. A wall rail becomes a groove. You can recognise the room while finding that it no longer lets you in.</p><p><a href="../2026-09-24-boolean-more-spaces/index.html">Return to the coloured Boolean spaces</a></p></div>
<section class="room" id="encounter"><div class="roomhead"><span class="number">01</span><div><p class="eyebrow">A familiar face / an undisclosed interior</p><h2>Behind the facade.</h2><p>Step through the left opening. The wall has depth; the room curves away beyond it. Come back through the same doorway and approach the corresponding solid.</p></div></div>
<div class="pair">__INTERIOR____POSITIVE__</div>
<details><summary>The facade and both forms from above</summary><div class="pair">__FACADE____OVERVIEW__</div></details></section>
<section class="room" id="details"><div class="roomhead"><span class="number">02</span><div><p class="eyebrow">Window / wall rail</p><h2>The details change sides.</h2><p>The comparison belongs to these particular surfaces. The window retains its stepped reveal. The rail that projects into the room cuts a groove into its positive.</p></div></div>
<div class="pair">__WINDOW_IN____WINDOW_OUT__</div>
<details open><summary>The same rail, in relief and in recess</summary><div class="pair">__RAIL_IN____RAIL_OUT__</div></details></section>
<section id="reading" class="reading"><p class="eyebrow">Current study chapter / Boolean_Facade_Cast / final.md</p>__READING__</section>
<section class="play" id="play"><p class="eyebrow">Playable Godot study</p><h2>Go behind the face.</h2><p>Open <code>commons/artifacts/facade_room_cast/study.tscn</code> in Godot and press F6. WASD moves; the mouse looks; Escape releases the mouse. Keys 1, 2 and 3 return you to the entrance, the interior and the front of the positive.</p><p>The development map is <code>Boolean_Facade_Cast</code>. A new portal links it from <code>Boolean_Colour_Spaces_II</code>, and a return portal leads back. The paired artifact includes its own level ground.</p><p><a href="/compose/sources?map=Boolean_Facade_Cast&amp;doc=final">Read the chapter in Sources</a></p></section>
<section class="evidence" id="evidence"><h2>Built from the existing work.</h2><p>The window and door surround, cornice, dentils and string course reuse the existing facade-part factories. The NYC tenement preset supplies the wall colour and ground-floor window parameters. This is a new one-storey fragment using that vocabulary; it does not reproduce the whole facade.</p><p>The room is a block minus its interior. The positive is the intersection of that same block and interior. Doorway, window, reveal and wall details come from the same geometry definition. The positive is clipped to the block, so extensions of the cutting shapes outside it are excluded.</p><p>__COUNT__ passing records cover generated meshes, matching landmarks, 120 sampled partition points, a supported capsule route into the room and back, refusal at the solid counterpart, a circuit around it, a clear window sightline and ten native image writes. Sampling is finite. Full museum-loader, headset experience and Quest performance remain to be checked.</p><details><summary>References, source and evidence</summary><p>Whiteread's <a href="https://www.nga.gov/artworks/131285-ghost"><i>Ghost</i></a> and <a href="https://www.artangel.org.uk/project/house/construction/"><i>House</i></a> inform the relation between space, its impressions and former use. This invented digital room has no former household; the chapter begins from the visitor's own recent memory of entering it.</p><p><a href="DECISIONS.md">Decisions</a> · <a href="runtime.json">Runtime checks</a> · <a href="manifest.json">Source and image hashes</a> · <a href="study-portal.diff">New study connection</a></p><p>These are captures of the production artifact in an isolated Godot scene. They also illustrate the new chapter. The existing canonical Boolean sequence, chapter texts, facade presets and factories are unchanged.</p></details></section>
</main><footer>Ada Research · The room and its volume · Native geometry, shared book illustrations · 24 September 2026</footer></body></html>'''

replacements = {
    '__STYLE__': style, '__READING__': reading, '__COUNT__': str(len(checks)),
    '__INTERIOR__': figure('inside', 'Enter: the enclosure opens into a curved alcove.', 'Inside the room, looking into its curved alcove'),
    '__POSITIVE__': figure('positive', 'Return: the doorway and window occupy space as projections.', 'Oblique view of the solid positive with doorway and window projections'),
    '__FACADE__': figure('facade', 'Reused facade parts surround actual openings.', 'Front of the terracotta facade'),
    '__OVERVIEW__': figure('overview', 'Two results, a common ground, room to walk around.', 'Elevated view of both forms'),
    '__WINDOW_IN__': figure('window-inside', 'The window reveal, seen from inside.', 'The stepped window opening from the room'),
    '__WINDOW_OUT__': figure('window-positive', 'Its corresponding profile on the positive.', 'Stepped projection where the window was'),
    '__RAIL_IN__': figure('room-rail', 'A rail standing out from the interior wall.', 'A projecting plaster rail near the ceiling'),
    '__RAIL_OUT__': figure('positive-rail', 'The rail becomes a recessed line on the positive.', 'The rail impression on the positive form'),
}
for key, value in replacements.items():
    page = page.replace(key, value)
assert not re.search(r'__[A-Z_]+__', page)
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'passing_records': len(checks), 'source_files': len(sources), 'native_images': len(images), 'page': str(OUT / 'index.html')}))
