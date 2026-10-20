"""Assemble the local review from verified native evidence and current map text."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
MAP = ROOT / 'commons/maps/Random_Entropies'
RUN = ROOT / 'ada_run/encounter_pilot/Random_Entropies/ordinary-entropies'
wall = json.loads((MAP / 'writing_wall.json').read_text(encoding='utf8'))
for capture in RUN.glob('*.png'):
    shutil.copy2(capture, HERE / capture.name)
for original, target in [('report.json', 'museum-report.json'), ('source_manifest.json', 'museum-source-manifest.json')]:
    shutil.copy2(RUN / original, HERE / target)
reports = [json.loads((HERE / name).read_text(encoding='utf8')) for name in ['verification.json', 'museum-report.json']]
assert all(report['passed'] and not report['failures'] for report in reports)
counts = [len(report['checks']) for report in reports]
assert counts == [110, 62], counts

style = '''body{margin:0;background:#f3f0e8;color:#243b3c;font:18px/1.6 system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:24px}h1{font:clamp(32px,4.5vw,60px)/1.12 Georgia,serif;margin:12px 0 18px}h2{font:32px/1.2 Georgia,serif}h3{font-size:21px}p{max-width:82ch}a{color:#17665f}nav{display:flex;flex-wrap:wrap;gap:12px 24px}small{letter-spacing:.09em;text-transform:uppercase;color:#536c65}section{margin:36px 0}figure{margin:0}img{display:block;width:100%;background:#15252e}figcaption{padding:14px 18px;background:#e3e7db}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.route{display:grid;grid-template-columns:minmax(250px,360px) 1fr;gap:32px;align-items:start}.route svg{width:100%;max-height:800px}.panel{background:#e3e7db;padding:22px 28px}.reading{max-width:880px}.reading p{max-width:74ch}pre{overflow:auto;padding:18px;background:#e3e7db;font-size:14px}table{width:100%;border-collapse:collapse;font-size:16px}th,td{padding:10px;border-bottom:1px solid #acbeb0;text-align:left;vertical-align:top}code{font-size:.9em}li{margin:8px 0}.proof{font-weight:600}.badge{color:#34594d;background:#d9e7d4;padding:4px 9px;border-radius:6px}@media(max-width:850px){.grid,.route{grid-template-columns:1fr}main{padding:18px}.route svg{max-height:600px}}'''

def page(title, body, reading=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + ' · Ada Research</title><style>' + style + '</style><main' + (' class="reading"' if reading else '') + '>' + body + '</main></html>'

def md_page(name, source, title):
    content = source.read_text(encoding='utf8')
    for target in ['final', 'tutorial', 'plan', 'sources', 'artifacts']:
        content = content.replace('](' + target + '.md)', '](' + target + '.html)')
    content = content.replace('](../../../doc/book/iterations/2026-10-16-ordinary-entropies/index.html)', '](index.html)')
    content = content.replace('](../../../doc/book/iterations/2026-10-16-ordinary-entropies/README.md)', '](index.html)')
    (HERE / name).write_text(page(title, '<nav><a href="index.html">← The seven encounters</a><a href="tutorial.html">Tutorial</a><a href="final.html">Final text</a><a href="sources.html">Sources</a></nav>' + markdown.markdown(content, extensions=['tables', 'fenced_code']), True), encoding='utf8')

for name in ['final', 'tutorial', 'plan', 'artifacts']:
    md_page(name + '.html', MAP / (name + '.md'), name.title())
md_page('sources.html', HERE / 'sources.md', 'Measurement references')

# Diagram is derived from the installed grid. It is a floor plan, not a pathfinding claim.
data = json.loads((MAP / 'map_data.json').read_text(encoding='utf8'))
grid = data['layers']['structure']
svg = ['<svg viewBox="-1 -4 21 65" role="img" aria-label="Floor plan: entrance at top; seven numbered encounters; exit at bottom" xmlns="http://www.w3.org/2000/svg">', '<rect x="0" y="0" width="19" height="57" fill="#e5e6d9"/>']
for z, row in enumerate(grid):
    for x, cell in enumerate(row):
        if str(cell) not in ['0', '1']:
            colour = '#a6ab95' if str(cell).startswith('p:') else '#3d5052'
            svg.append(f'<rect x="{x}" y="{z}" width="1" height="1" fill="{colour}"/>')
svg.append('<g fill="#243b3c" font-family="sans-serif" font-size="1"><text x="9.5" y="-1.3" text-anchor="middle">ENTER ↓</text><text x="9.5" y="59.5" text-anchor="middle">EXIT ↓</text></g>')
positions = [(4,6),(13,6),(9,18),(9,24),(6,30),(6,41),(9,50)]
for i,(x,z) in enumerate(positions,1):
    svg.append(f'<circle cx="{x+.5}" cy="{z+.5}" r="1.2" fill="#b84e78" stroke="#fff" stroke-width=".15"/><text x="{x+.5}" y="{z+.87}" text-anchor="middle" font-family="sans-serif" font-size="1.1" fill="#fff">{i}</text>')
svg.append('</svg>')
floorplan = ''.join(svg)
(HERE / 'floor-plan.svg').write_text(floorplan,encoding='utf8')

captions = [
    ('Shannon: the next colour', 'Eight normal-sized chairs. Rearrangement can change what we see while the uncertainty of the next colour stays fixed. Change the colour shares to change H.'),
    ('Boltzmann: matching arrangements', 'Across the low divider, the same colour totals occupy marked sites. SORTED and MIXED change how many assignments satisfy the left-side count: one versus thirty-six.'),
    ('Algorithmic complexity: along the wall', 'Four groups become visually less regular. SHOW RECIPE reveals a complication: even the scatter has a short seeded construction. Appearance alone does not establish description length.'),
    ('Dynamical entropy: the doorway', 'A solid door and a translucent second leaf begin close together. Compare contraction with the expanding rule. HOLD OPEN allows passage; there is also a side bypass.'),
    ('Thermodynamic entropy: behind the door', 'A hot cup and cooler body share a table. Steam locates the hot object. Advance time to compare the cup’s falling entropy with the combined system’s increase.'),
    ('Conditional entropy: behind another wall', 'A chair waits behind a glass panel. The record can retain identity, only colour, or neither. These channels leave zero, two or three bits unresolved.'),
    ('Min-entropy: the ball pit', 'A large pink ball stands among fifteen small teal ones. Compare equal ID draws, colour outcomes and an explicit weight for the large ball. Being conspicuous does not automatically make an object likely.'),
]
cards = []
for i,(artifact,(title,description)) in enumerate(zip(wall['order'],captions),1):
    cards.append(f'<article><h3>{i}. {html.escape(title)}</h3><figure><a href="{artifact}.png"><img loading="lazy" src="{artifact}.png" alt="Native Godot view of {html.escape(title)}"></a><figcaption>{html.escape(description)}</figcaption></figure></article>')
words = len(re.findall(r"\b[\w’'-]+\b", (MAP / 'final.md').read_text(encoding='utf8')))
body = f'''<aside style="padding:16px;background:#e3e7db"><strong>This is the earlier interface.</strong> <a href="../2026-10-16-entropy-quiet-panels/index.html">See the current compact panels and before/after views →</a></aside><header><small>Ada Research · New map · 16 October 2026</small><h1>Different entropies,<br>ordinary objects</h1><p>Seven encounters at ordinary scale. A chair can be a possible outcome, part of an arrangement, a description, or something only partly recorded. The route changes the question before it changes the measure.</p><nav><a href="/long-museum/writing-wall?map=Random_Entropies">Open the writing wall</a><a href="tutorial.html">Tutorial: build the question</a><a href="final.html">Final: What remains uncertain</a><a href="#room">Walk the room</a><a href="sources.html">Sources and model limits</a></nav></header>
<section><figure><img src="paired-chairs.png" alt="Two full-size chair experiments separated by a low divider, with physical controls"><figcaption>Actual museum capture. Shannon and Boltzmann begin side by side, with eight chairs in each study and a low divider between them.</figcaption></figure></section>
<section id="room" class="route"><figure>{floorplan}<figcaption>Installed floor plan, entrance at the top. Dark cells are walls; the lighter divider is one metre high. Numbers follow the room and final text.</figcaption></figure><div><h2>One route, seven different questions</h2><ol><li><strong>Shannon chairs:</strong> how uncertain is the next recorded colour?</li><li><strong>Boltzmann chairs:</strong> how many arrangements meet the same brief?</li><li><strong>Description wall:</strong> how much must be specified to rebuild this pattern?</li><li><strong>Driven door:</strong> does this rule keep producing new distinctions over time?</li><li><strong>Cooling cup:</strong> where does heat go, and whose entropy changes?</li><li><strong>Frosted chair:</strong> what remains unknown after this particular record?</li><li><strong>Ball pit:</strong> how successful can the best single guess be?</li></ol><p>The new <code>Random_Entropies</code> map follows <code>Random_Definition</code> and precedes <code>Random_Entropy</code> in the randomness sequence. It is 19 × 57 metres, with normal-scale furniture and separate chambers. Each setup is independently registered and placed.</p><p><a href="aerial.png">Native aerial view</a> · <a href="through-the-door.png">Through the held-open door</a> · <a href="artifacts.html">Artifact inventory</a></p><div class="panel"><h3>Keep a difference worth investigating</h3><p>Choose a baseline, change one condition, compare, KEEP, change again, then REPLAY. Each station has one local save slot. Copy its receipt when both baseline and intervention must remain. Reconstruct the small model, then propose the next change from what happened.</p><p>The 48-value seed bench remains the first research pilot. This is the next entropy study.</p></div></div></section>
<section><h2>The installed encounters</h2><div class="grid">{''.join(cards)}</div></section>
<section><figure><img loading="lazy" src="steam-detail.png" alt="A white steam shader rising from a cup on a table beside a cooler teal body"><figcaption>The steam is a visible cue. The calculation follows two finite bodies exchanging heat; it does not simulate evaporation.</figcaption></figure></section>
<section class="panel"><h2>Room, tutorial and final together</h2><p>The <a href="final.html">{words}-word final draft</a> follows the same seven encounters in the established “we” voice. The <a href="tutorial.html">tutorial</a> begins with eight chairs and a small entropy function, then states each experiment’s outcomes, assumptions, controls and reconstruction procedure. Both are working drafts for the first visitor trial.</p><p>Start with one comparison: rearrange the Shannon chairs, then change their colour shares. What changes visibly, and what changes numerically? The neighbouring Boltzmann instrument asks why the same one-bit colour distribution can accompany different arrangement counts.</p></section>
<section><h2>What has been verified</h2><p class="proof">{counts[0]}/{counts[0]} apparatus checks · {counts[1]}/{counts[1]} actual-room checks · both native runs exit successfully.</p><p>Checks cover independent arrangement counting, the finite symbolic door model, thermal energy conservation, the record channels, saved-state reconstruction, physical control callbacks, collision clearance and supported passages. Native screenshots show all seven installed instruments.</p><p>Headset reach, readable labels at standing distance, performance on the target headset and independent student reconstruction still need a human trial. The models distinguish their measurement contracts; none claims that visual disorder alone is a universal entropy value.</p><nav><a href="verification.json">Apparatus checks</a><a href="museum-report.json">Room checks</a><a href="records.json">Saved examples</a><a href="manifest.json">Source fingerprints</a><a href="plan.html">Next research checks</a><a href="source-poster.png">Supplied poster</a></nav></section>'''
(HERE / 'index.html').write_text(page('Different entropies, ordinary objects',body),encoding='utf8')

paths = [p for p in (ROOT / 'commons/artifacts/ordinary_entropies').iterdir() if p.is_file() and p.suffix in ['.gd','.gdshader','.tscn','.md']]
paths += [p for p in MAP.iterdir() if p.is_file() and p.suffix in ['.md','.json']]
paths += [ROOT / p for p in ['commons/artifacts/registry/ordinary_entropies.json','commons/maps/sequences/randomness.json','commons/data/map_authored.json','commons/data/book/randomness.json','commons/data/museum/em_plan.json','tools/install_ordinary_entropies.py']]
(HERE / 'manifest.json').write_text(json.dumps({'map':'Random_Entropies','order':wall['order'],'checks':counts,'record_schema':'ordinary-entropies/1','sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf8')
(HERE / 'README.md').write_text(f'''# Different entropies, ordinary objects

16 October 2026. Seven new, independently registered ordinary-scale encounters in Random_Entropies, immediately after Random_Definition. The user's poster supplies the subjects; the requested sequence supplies the architecture. The last example becomes a ball pit. [Review](index.html), [tutorial](tutorial.html), [final](final.html), [sources and corrections](sources.md), [plan](plan.html).

Shannon and Boltzmann chairs share the entrance chamber across a one-metre divider. A wall introduces four chair descriptions. A driven door connects to the cooling cup; another chamber hides chair detail behind a frosted panel; the last chamber holds the ball pit. The door can be held open and has an independent bypass. Map, writing-wall, final and tutorial follow the same seven-stop order. The first 48-value research pilot remains in place.

{counts[0]}/{counts[0]} apparatus checks and {counts[1]}/{counts[1]} actual-hall checks pass with native process exit 0. These include independently enumerating the chair macrostates, thermal energy conservation/entropy increase, declared channels, native controls, per-station disk KEEP/REPLAY, new-instance reconstruction and safe rejection of invalid receipts. Each station has one replay slot, separate from the hybrid collection. Test pointers are isolated from visitor records.

Render review moved the frosted chair farther from a wall for standing clearance, moved cup controls/signs away from the steam, and made sign backings readable in museum shadows. A test lifecycle fault was fixed by allowing deferred console construction to settle before fixture disposal; teardown is still tested. All source modules and installed text are fingerprinted in manifest.json. The actual-hall source manifest is also retained.

Reproduce:

```
python -X utf8 doc/book/iterations/2026-10-16-ordinary-entropies/run.py
python -X utf8 tools/run_encounter_probe.py Random_Entropies --sequence randomness --render --no-bridges --output-tag ordinary-entropies --probe doc/book/iterations/2026-10-16-ordinary-entropies/museum_probe.gd
python -X utf8 tools/map_pathfinder.py check Random_Entropies --verbose
python -X utf8 doc/book/iterations/2026-10-16-ordinary-entropies/publish.py
```

The narrow installer establishes the new map and integration entries; re-running it would restore its generated placements and writing-wall notes. It is not needed to run the map. Long-museum derivation reports two pre-existing layer-size disagreements in Random_Rotate_Random_XYZ and Noise_Inside_Noise; neither belongs to this new map. Random_Entropies pathfinding reports no issues.

Pending: headset readability/reach/comfort/performance, independent learner reconstruction, and evidence that the sequence produces a meaningful question or reason to revise the apparatus. No automatic cross-station record transfer is implemented. The final is a situated draft grounded in installed behavior, not a report of human learning. Source-poster explanations were made more precise where the pictured object alone could not justify the stated measure.
''',encoding='utf8')
print('Published',HERE / 'index.html',counts)
