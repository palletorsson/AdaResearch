"""Publish the reusable wall and its native interaction/room evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
MAP = ROOT / 'commons/maps/Random_Entropies'
WALL = ROOT / 'commons/artifacts/research_info_wall'
RUN = ROOT / 'ada_run/encounter_pilot/Random_Entropies/research-wall'
for path in RUN.glob('*.png'):
    shutil.copy2(path, HERE / path.name)
for src, dst in [('report.json', 'museum-report.json'), ('source_manifest.json', 'museum-source-manifest.json')]:
    shutil.copy2(RUN / src, HERE / dst)
reports = [json.loads((HERE / name).read_text(encoding='utf8')) for name in ['verification.json', 'museum-report.json']]
assert all(report['passed'] and not report['failures'] for report in reports)
counts = [len(report['checks']) for report in reports]
style = '''
*{box-sizing:border-box}body{margin:0;background:#f2eee4;color:#263c3b;font:18px/1.6 system-ui,sans-serif}
main{max-width:1440px;margin:auto;padding:30px}h1{font:clamp(38px,5vw,70px)/1.08 Georgia,serif;margin:18px 0 22px}
h2{font:34px/1.2 Georgia,serif}h3{font-size:21px}p{max-width:82ch}a{color:#17685d}nav{display:flex;flex-wrap:wrap;gap:12px 24px}
small{letter-spacing:.1em;text-transform:uppercase;color:#567168}section{margin:40px 0}figure{margin:0}
img{display:block;width:100%;background:#263c3b}figcaption{padding:15px 20px;background:#e1e4d8;font-size:16px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.three{grid-template-columns:repeat(3,1fr)}.panel{padding:26px;background:#e1e4d8}
.reading{max-width:960px}pre{overflow:auto;padding:18px;background:#e1e4d8;font-size:14px}code{font-size:.9em}
table{border-collapse:collapse;width:100%}td,th{padding:12px;text-align:left;border-bottom:1px solid #b9c4b8}
@media(max-width:850px){main{padding:18px}.grid,.three{grid-template-columns:1fr}}
'''


def page(title, body, reading=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + ' · Ada Research</title><style>' + style + '</style><main' + (' class="reading"' if reading else '') + '>' + body + '</main></html>'


nav = '<nav><a href="index.html">The wall</a><a href="tutorial.html">Tutorial</a><a href="final.html">Final text</a><a href="plan.html">Plan</a><a href="illustration.html">Illustration handoff</a></nav>'
for title, source, target in [(name.title(), MAP / (name + '.md'), name + '.html') for name in ['tutorial', 'final', 'plan']] + [('Illustration handoff', WALL / 'ILLUSTRATION_SLOT.md', 'illustration.html'), ('Wall implementation', WALL / 'README.md', 'implementation.html')]:
    content = source.read_text(encoding='utf8')
    for name in ['tutorial', 'final', 'plan']:
        content = content.replace('](' + name + '.md)', '](' + name + '.html)')
    content = content.replace('](ILLUSTRATION_SLOT.md)', '](illustration.html)')
    (HERE / target).write_text(page(title, nav + markdown.markdown(content, extensions=['tables', 'fenced_code']), True), encoding='utf8')

styles = ''.join(f'<figure><h3>{label}</h3><a href="hall-style-{key}.png"><img loading="lazy" src="hall-style-{key}.png" alt="{label} finish on the same physical research wall"></a><figcaption>{description}</figcaption></figure>' for key, label, description in [('gallery', 'Gallery', 'Pale plaster and dark frames. Installed in the hall.'), ('workshop', 'Workshop', 'Warm wood and narrow vertical joints.'), ('night', 'Night', 'Dark blue with light trim and labels.')])
body = f'''<header><small>Ada Research · Random Entropies · 16 October 2026</small><h1>A wall to think with</h1><p>A physical partition gives the explanation a place in the room. A framed reading, an image and visitors’ drawings share its face. Questions can remain beside the objects as handwritten notes.</p>{nav}</header>
<section><figure><a href="work-wall-in-room.png"><img src="work-wall-in-room.png" alt="Full-height research wall in the entropy hall, with framed text, overview image, blank whiteboard, markers and coloured notes"></a><figcaption>Installed just beyond the paired chair studies, facing the description chamber. The 6.2 m wide, 2.35 m high wall rests on the floor and has collision. Routes around both sides remain open. Native Godot capture; the board and notes are blank.</figcaption></figure></section>
<section class="grid"><div><h2>Three kinds of contribution</h2><p><strong>The framed text</strong> introduces what the room compares. <strong>The image</strong> can carry an overview or a close detail. <strong>The drawing surface and movable notes</strong> hold observations made during a visit.</p><p>The current picture is a provisional overhead capture from the previous room revision. It predates this wall. The frame is ready for the illustration being developed separately, with preserved image proportions.</p><p>All seven smaller entropy explanations also now have frames and their own floor-to-top supports. The encounter sequence and simultaneous comparisons remain unchanged.</p></div><figure><img loading="lazy" src="writing-tools.png" alt="Two markers, an eraser, a whiteboard and three coloured writable notes"><figcaption>Dark and red markers, an eraser and three sticky notes. These are usable objects; no button menu is added.</figcaption></figure></section>
<section class="panel"><h2>Write, move, return</h2><ol><li>Lift a marker. Touch the whiteboard or a note with its nib; lift it to end a stroke.</li><li>Use the eraser on the marks to remove them locally.</li><li>Lift a note and release it near the wall to pin it. A release away from the wall returns it to its last pinned place.</li><li>Leave and return. Ink and pinned positions save automatically on this device.</li></ol><p>Dropped or lost tools return to the shelf. This first version supplies three notes; it has no typed entry, unlimited note dispenser or shared online notebook.</p></section>
<section><h2>One structure, different appearances</h2><p>Gallery, workshop and night are author-selectable finishes. Changing finish preserves the writing. Drawing, notes and the image can be enabled separately when placing the wall.</p><div class="grid three">{styles}</div></section>
<section class="grid"><figure><img loading="lazy" src="work-wall-oblique.png" alt="Oblique view showing the thickness, floor support and surrounding passage"><figcaption>The wall is independently registered and placed at map cell (9,13). It can be moved or removed in the map editor without moving a chair study.</figcaption></figure><figure><img loading="lazy" src="wall-1.png" alt="Shannon explanation in a physical frame beside the chair installation"><figcaption>A smaller framed explanation stays beside its installation. Its own backing supports it even when no existing room wall is behind it.</figcaption></figure></section>
<section class="panel"><h2>Verified, and ready for a visitor</h2><p><strong>{counts[0]} native interaction and persistence checks, and {counts[1]} actual-room checks pass.</strong> Tests exercise pickup callbacks, drawing on both surfaces, lifting the nib, erasing, pinning, tool return, autosave and restoration in a fresh wall. Room checks cover physical support, scale, approaches and open passages.</p><p>These are supplied test movements, not a human headset trial. The next check is to write a brief observation, pin a question, walk onward and return. Is it comfortable to reach, and does the note help connect the encounters?</p><p>The first 48-value seed bench remains the first research pilot. This wall supports that research method; it does not count as another entropy measure or replace independent reconstruction.</p><nav><a href="verification.json">Interaction evidence</a><a href="museum-report.json">Room evidence</a><a href="manifest.json">Source fingerprints</a><a href="implementation.html">Implementation</a><a href="aerial.png">Current room overview</a></nav></section>
<footer><p>Restart the museum to load the wall. <strong>Random Entropies</strong> remains directly after <strong>Random Definition</strong>.</p><nav><a href="/long-museum/writing-wall?map=Random_Entropies">Map planning wall</a><a href="../2026-10-16-entropy-visible-states/index.html">Previous visible-states trial</a></nav></footer>'''
(HERE / 'index.html').write_text(page('A wall to think with', body), encoding='utf8')
files = list(WALL.glob('*.gd')) + list(WALL.glob('*.tscn')) + list(MAP.glob('*.md')) + [MAP / 'map_data.json', MAP / 'writing_wall.json', ROOT / 'commons/artifacts/ordinary_entropies/wall_text.gd', ROOT / 'commons/artifacts/ordinary_entropies/comparison.gd', ROOT / 'commons/artifacts/registry/research_walls.json']
(HERE / 'manifest.json').write_text(json.dumps({'checks': counts, 'wall_metres': [6.2, 2.35, .24], 'storage': 'local per device, automatic', 'illustration': 'provisional earlier overhead capture; replacement supplied separately', 'sha256': {path.relative_to(ROOT).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest() for path in files}}, indent=2), encoding='utf8')
(HERE / 'README.md').write_text(f'''# A wall to think with

Random Entropies now has an independently placed physical research wall at (9,13). It combines framed interpretation, a replaceable picture, a working whiteboard, two markers, an eraser and three writable movable notes. Gallery/workshop/night finishes preserve ink. Writing and pin positions autosave locally. The smaller caption frames now own solid floor-to-top supports too.

{counts[0]} native interaction/persistence checks and {counts[1]} actual-room checks pass. The supplied motions exercise actual pickup callbacks and image pixels, but are not a human usability trial. Headset reach, performance and comparative reading remain to be tested. No new APK is claimed. `style-*.png` show synthetic test strokes; `hall-style-*.png` and `work-wall-in-room.png` show the clean installed wall.

The seven-stop route and underlying entropy comparisons remain unchanged. The image frame holds an earlier provisional overhead capture that predates the wall, and is ready for the separately developed illustration. The 48-value seed bench remains the first research pilot.

Reproduce:

```
python -X utf8 doc/book/iterations/2026-10-16-research-info-wall/run.py
python -X utf8 tools/run_encounter_probe.py Random_Entropies --sequence randomness --render --no-bridges --output-tag research-wall --probe doc/book/iterations/2026-10-16-research-info-wall/museum_probe.gd
python -X utf8 doc/book/iterations/2026-10-16-research-info-wall/publish.py
```

See the reusable artifact's README and ILLUSTRATION_SLOT.md for authoring and image handoff. User writing lives under `user://research_info_walls/`, not in this source repository. Native tests use a separate storage key; the museum probe disables persistence while capturing.
''', encoding='utf8')
print('Published research wall:', counts)
