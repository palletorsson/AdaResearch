"""Review the installed cups, glass, door wall and explicit chance tickets."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
MAP = ROOT / 'commons/maps/Random_Entropies'
RUN = ROOT / 'ada_run/encounter_pilot/Random_Entropies/coffee-glass'
for path in RUN.glob('*.png'):
    shutil.copy2(path, HERE / path.name)
for src, dst in [('report.json', 'museum-report.json'), ('source_manifest.json', 'museum-source-manifest.json')]:
    shutil.copy2(RUN / src, HERE / dst)
reports = [json.loads((HERE / name).read_text(encoding='utf8')) for name in ['verification.json', 'museum-report.json']]
assert all(r['passed'] and not r['failures'] for r in reports)
counts = [len(r['checks']) for r in reports]
style = '''*{box-sizing:border-box}body{margin:0;background:#f1ece2;color:#263c3b;font:18px/1.6 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:28px}h1{font:clamp(36px,5vw,66px)/1.1 Georgia,serif;margin:16px 0 22px}h2{font:32px/1.2 Georgia,serif}h3{font-size:21px}p{max-width:85ch}a{color:#17685d}nav{display:flex;gap:12px 24px;flex-wrap:wrap}small{letter-spacing:.08em;text-transform:uppercase;color:#567168}section{margin:38px 0}figure{margin:0}img{display:block;width:100%;height:auto;background:#263c3b}figcaption{padding:14px 18px;background:#e0e3d5;font-size:16px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}.five{grid-template-columns:repeat(5,1fr);gap:12px}.three{grid-template-columns:repeat(3,1fr)}.panel{padding:24px;background:#e0e3d5}.reading{max-width:960px}pre{overflow:auto;padding:16px;background:#e0e3d5;font-size:14px}table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:12px;border-bottom:1px solid #b7c2b3}code{font-size:.9em}@media(max-width:900px){.grid,.three{grid-template-columns:1fr}.five{grid-template-columns:repeat(2,1fr)}}@media(max-width:500px){main{padding:16px}.five{grid-template-columns:1fr}}'''


def page(title, body, reading=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + ' · Ada Research</title><style>' + style + '</style><main' + (' class="reading"' if reading else '') + '>' + body + '</main></html>'


nav = '<nav><a href="index.html">Installed comparisons</a><a href="tutorial.html">Tutorial</a><a href="final.html">Final text</a><a href="plan.html">Plan</a><a href="#tickets">Understand the last example</a></nav>'
for name in ['tutorial', 'final', 'plan', 'technical']:
    source = (MAP / (name + '.md')).read_text(encoding='utf8')
    for other in ['tutorial', 'final', 'plan', 'technical']:
        source = source.replace('](' + other + '.md)', '](' + other + '.html)')
    (HERE / (name + '.html')).write_text(page(name.title(), nav + markdown.markdown(source, extensions=['tables', 'fenced_code']), True), encoding='utf8')

def picture(path, alt, caption):
    return f'<figure><a href="{path}"><img loading="lazy" width="1600" height="1050" src="{path}" alt="{html.escape(alt)}"></a><figcaption>{caption}</figcaption></figure>'


cups = ''.join(picture(f'cup-{i+1}.png', f'Cup {i+1}, milk mixing stage {i+1} of five', label) for i, label in enumerate(['A · distinct milk region', 'B · a drawn-out swirl', 'C · finer ribbons', 'D · fading distinctions', 'E · an even mixture']))
glass = ''.join(picture(f'glass-{i+1}.png', f'Glass version {i+1}', label) for i, label in enumerate(['A · identity<br>1 candidate / 0 bits', 'B · colour + arms<br>2 candidates / 1 bit', 'C · colour<br>4 candidates / 2 bits', 'D · colour<br>4 candidates / 2 bits', 'E · no detail<br>8 candidates / 3 bits']))
tickets = ''.join(picture(f'tickets-{i+1}.png', f'Ticket tray {i+1}, with winning chances marked in gold', label) for i, label in enumerate(['A · any one number wins on 1 of 16 tickets', 'B · teal wins on 15 of 16 tickets', 'C · number 16 wins on 15 of 30 tickets']))
body = f'''<header><small>Ada Research · Random Entropies · 16 October 2026</small><h1>Five cups, five panes,<br>chances we can count</h1><p>The comparisons become easier to inspect: cups share a table, milk spreads through five surfaces, frosting blurs the same chair, and visible tickets make the final example’s probabilities concrete. The doors belong to a solid wall.</p>{nav}</header>
<section>{picture('coffee-table.png','Five open cups on one shared table with a torus donut and a plate','Installed view at standing eye height. Five cups, one table, one donut and one plate. The liquid surfaces are open and visible from above.')}</section>
<section><h2>The same amount of milk, differently distributed</h2><p>Each surface keeps a prescribed 25% milk fraction. A distinct region becomes a swirl, then finer ribbons, then an even mixture. The ribbons move gently while each cup retains its prepared mixing stage.</p><div class="grid five">{cups}</div><p>The labels separately compare the heat model at 0, 5, 15, 30 and 60 seconds. The cup loses entropy while its finite surroundings gain more. The swirl image does not calculate that thermal entropy: this is an illustration of mixing, with a separate heat calculation. Both are named on the <a href="wall-5.png">framed explanation</a>.</p></section>
<section><h2>Five versions of the frosted chair</h2><p>The glass now spreads detail rather than simply placing a pale tint over it. A clear view gives way to increasing frost and then a genuinely opaque face. Each version holds the same chair.</p><div class="grid five">{glass}</div><p>The records are declared explicitly. Among eight equally likely chair identities, colour plus arms leaves two candidates, colour alone leaves four, and no distinguishing detail leaves all eight. <strong>C and D have different blur but the same two-bit record.</strong> The numbers describe what the record keeps, not a measured limit of human vision.</p><p><a href="five-panes.png">See all five panes in the room</a> · <a href="wall-6.png">Read their wall explanation</a></p></section>
<section id="tickets"><h2>The last example: which guess succeeds most often?</h2><p>Each pit still contains fifteen small teal balls and one large pink ball. Now the balls are numbered, and a tray of tickets exposes the chance assigned to each. Imagine drawing one ticket, every ticket equally likely, and returning it afterwards. Gold borders mark the tickets that make one best guess correct.</p><table><thead><tr><th></th><th>The question</th><th>Best guess</th><th>Winning tickets</th></tr></thead><tbody><tr><td>A</td><td>Which ball number?</td><td>Any one number, including 16</td><td>1 out of 16</td></tr><tr><td>B</td><td>Which colour?</td><td>Teal</td><td>15 out of 16</td></tr><tr><td>C</td><td>Which ball number, with extra tickets for 16?</td><td>16</td><td>15 out of 30</td></tr></tbody></table><p>B is easiest to guess. C gives the large ball an advantage because it has more tickets. Its physical size does not create that advantage. A makes every number equally likely.</p><div class="grid three">{tickets}</div><div class="panel"><p><strong>Min-entropy turns the best winning chance into a number: −log₂(p<sub>max</sub>).</strong> It is 4 bits in A, about 0.093 in B, and 1 in C. Lower means the best guess succeeds more often. Start with the tickets; the formula follows their counts.</p><p>The trays show exact probabilities, not the results of a performed random trial. <a href="wall-7.png">The wall text</a> and <a href="tutorial.html">tutorial reconstruction</a> now follow this explanation.</p></div></section>
<section><h2>Doors in a wall</h2>{picture('doors-in-wall.png','Three framed door openings in a solid wall, with the central passage open','The two side pairs repeat contracting and expanding rules. The central door remains open. The complete wall and doors move together as one registered artifact.')}<p>The old grid blocks that would have closed these openings were removed. The centre passage has been checked at all nine steps of the cycle. A door in motion is still a model of its stated rule; motion alone is not evidence of chaotic dynamics.</p></section>
<section class="panel"><h2>Checked in the installed hall</h2><p><strong>{counts[0]} apparatus checks and {counts[1]} actual-room checks pass; both Godot runs exit 0.</strong> Tests cover the finite models, visible ticket counts and winning chances, fixed milk fraction, separate animation and heat clocks, reconstruction, invalid-record rejection, all five glass records, opaque concealment in rendered pixels, wall support and passage clearance. The map pathfinder also passes.</p><p>Headset appearance, performance and understanding still require a person. The next reading check is simple: can the visitor explain why B’s teal guess wins more often than A’s number guess before reading the formula?</p><nav><a href="verification.json">Apparatus checks</a><a href="museum-report.json">Room checks</a><a href="manifest.json">Source fingerprints</a><a href="technical.html">Implementation</a><a href="aerial.png">Room overview</a></nav></section>
<footer><p>Restart the museum to load this revision. Random Entropies remains directly after Random Definition; the seven-stop room and final order is unchanged. The shared research wall remains available for drawing and notes. The first 48-value seed bench remains the first research pilot.</p><nav><a href="../2026-10-16-research-info-wall/index.html">Research wall</a><a href="../2026-10-16-entropy-visible-states/index.html">Previous comparison</a><a href="/long-museum/writing-wall?map=Random_Entropies">Map planning wall</a></nav></footer>'''
(HERE / 'index.html').write_text(page('Five cups, five panes, visible chances', body), encoding='utf8')
files = [p for p in (ROOT / 'commons/artifacts/ordinary_entropies').iterdir() if p.suffix in ['.gd', '.gdshader', '.tscn']] + list(MAP.glob('*.md')) + [MAP / 'map_data.json', MAP / 'writing_wall.json', ROOT / 'commons/artifacts/registry/ordinary_entropies.json']
(HERE / 'manifest.json').write_text(json.dumps({'checks': counts, 'milk_fraction': .25, 'thermal_times_seconds': [0,5,15,30,60], 'conditional_bits': [0,1,2,2,3], 'tickets': [16,16,30], 'winning_tickets': [1,15,15], 'sha256': {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}, indent=2), encoding='utf8')
(HERE / 'README.md').write_text(f'''# Five cups, five panes, visible chances

User-requested revision of Random Entropies: five cups on one table with one donut/plate; the same milk amount in different mixing stages; five better frosted-chair versions; doors in a real wall; a more understandable last example.

The last example keeps its existing min-entropy contracts but displays them as equiprobable tickets. The glass adds a colour-plus-arms record while retaining the earlier channel meanings. Two frost levels deliberately keep the same colour record. Cup swirls are an illustration with a prescribed 25% milk fraction, independent of the five thermal snapshots. No physical mixing entropy or human recognition capacity is measured from pixels.

{counts[0]} native apparatus tests and {counts[1]} actual-hall checks pass, exits 0. Tests include ticket enumeration, all five channel values, saved-state reconstruction, invalid-record rejection, opaque concealment after changing the hidden chair, and the centre door route across all driven steps. Pathfinder passes. Headset appearance, performance and human understanding remain unverified.

Reproduce:

```
python -X utf8 doc/book/iterations/2026-10-16-entropy-coffee-glass/run.py
python -X utf8 tools/run_encounter_probe.py Random_Entropies --sequence randomness --render --no-bridges --output-tag coffee-glass --probe doc/book/iterations/2026-10-16-entropy-coffee-glass/museum_probe.gd
python tools/map_pathfinder.py check Random_Entropies --verbose
python -X utf8 doc/book/iterations/2026-10-16-entropy-coffee-glass/publish.py
```

The single affected museum row is re-derived for the revised wall and the wider five-pane placement at (9,41). Other rows are preserved. The seven-stop order and the first 48-value seed-bench pilot remain unchanged. Earlier map, derived row and text versions are retained here. Current screenshots come from the actual museum, including overhead/close views; camera views are supplied test observations, not visitor evidence.

Sieve: explicit tickets add a countable relation between object, answer and chance. Their fixed preparation forecloses free sampling in this installation; that remains a reconstruction task. The unmeasured difference is how a person's bodily attention and recognition depart from the declared channel, especially C/D's shared record and differently blurred images.
''', encoding='utf8')
print('Published current comparisons:', counts)
