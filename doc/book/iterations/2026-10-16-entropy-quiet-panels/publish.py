"""Keep the earlier room trial; publish the compact-interface revision beside it."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import markdown

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
MAP=ROOT/'commons/maps/Random_Entropies'
RUN=ROOT/'ada_run/encounter_pilot/Random_Entropies/quiet-panels'
for path in RUN.glob('*.png'):shutil.copy2(path,HERE/path.name)
for src,dst in [('report.json','museum-report.json'),('source_manifest.json','museum-source-manifest.json')]:shutil.copy2(RUN/src,HERE/dst)
reports=[json.loads((HERE/n).read_text(encoding='utf8')) for n in ['verification.json','museum-report.json']]
assert all(r['passed'] and not r['failures'] for r in reports)
counts=[len(r['checks']) for r in reports]
style='''body{margin:0;background:#f3f0e7;color:#243c3e;font:18px/1.55 system-ui,sans-serif}main{max-width:1450px;margin:auto;padding:24px}h1{font:clamp(34px,4vw,58px)/1.12 Georgia,serif;margin:12px 0 22px}h2{font:32px/1.2 Georgia,serif}p{max-width:82ch}a{color:#17695f}nav{display:flex;gap:12px 24px;flex-wrap:wrap}section{margin:32px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.reading{max-width:900px}small{letter-spacing:.08em;text-transform:uppercase;color:#567169}figure{margin:0}img{display:block;width:100%;background:#23373c}figcaption{padding:14px 18px;background:#e1e6d9}.panel{padding:24px;background:#e1e6d9}th,td{padding:12px;border-bottom:1px solid #bdcaba;text-align:left;vertical-align:top}table{width:100%;border-collapse:collapse;font-size:16px}pre{overflow:auto;font-size:14px;background:#e1e6d9;padding:16px}code{font-size:.9em}@media(max-width:850px){.grid{grid-template-columns:1fr}main{padding:18px}}'''
def page(title,body,reading=False):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+' · Ada Research</title><style>'+style+'</style><main'+(' class="reading"' if reading else '')+'>'+body+'</main></html>'
for name in ['tutorial','final','plan']:
    source=(MAP/(name+'.md')).read_text(encoding='utf8')
    source=source.replace('](tutorial.md)','](tutorial.html)').replace('](final.md)','](final.html)')
    (HERE/(name+'.html')).write_text(page(name.title(),'<nav><a href="index.html">← Smaller panels</a><a href="tutorial.html">Tutorial</a><a href="final.html">Final</a></nav>'+markdown.markdown(source,extensions=['tables','fenced_code']),True),encoding='utf8')
rows=[
 ('Shannon chairs','Four of each → rearranged → seven to one → one colour','DRAW'),
 ('Boltzmann chairs','Sorted → mixed → same count, new places','None'),
 ('Description wall','Patterns ↔ recipes','NEW SEED'),
 ('Driven door','Closing → expanding → passage open','STEP'),
 ('Cooling cup','0 → 5 → 15 → 30 → 60 seconds','PLAY / PAUSE'),
 ('Frosted chair','Clear → frosted → opaque','CHAIR'),
 ('Ball pit','Ball ID → colour → large ball weighted','DRAW'),
]
table='<table><thead><tr><th>Encounter</th><th>Previous / Next</th><th>One extra action</th></tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+html.escape(v)+'</td>' for v in row)+'</tr>' for row in rows)+'</tbody></table>'
ids=json.loads((MAP/'writing_wall.json').read_text(encoding='utf8'))['order']
cards=''.join(f'<figure><h3>{i+1}. {html.escape(rows[i][0])}</h3><a href="{id}.png"><img loading="lazy" src="{id}.png" alt="{html.escape(rows[i][0])} with a small control and information stand beside it"></a><figcaption><a href="panel-{i+1}.png">Read this panel up close</a></figcaption></figure>' for i,id in enumerate(ids))
body=f'''<header><small>Ada Research · Random_Entropies · 16 October 2026</small><h1>Make room for the objects</h1><p>One small panel beside each installation. A short question, a named state, the current reading, and two or three buttons. The large placards and cabinet consoles have been removed.</p><nav><a href="#compare">Before / after</a><a href="#controls">State controls</a><a href="tutorial.html">Updated tutorial</a><a href="final.html">Final text</a><a href="/long-museum/writing-wall?map=Random_Entropies">Writing wall</a></nav></header>
<section><figure><img src="entropy_chairs_description.png" alt="Four chair arrangements visible without the former large placards, with a small panel at the side"><figcaption>Native Godot capture at standing eye height. The description wall is visible from end to end; four small floor numbers connect its groups to the recipes on the side panel.</figcaption></figure></section>
<section id="compare"><h2>The installation comes first</h2><div class="grid"><figure><img loading="lazy" src="before-frosted-chair.png" alt="Previous version with three wide text boards and a cabinet"><figcaption>Previous capture: three separate information boards and a large control cabinet.</figcaption></figure><figure><img loading="lazy" src="entropy_frosted_chair.png" alt="Current version with one small panel beside the glass"><figcaption>Current capture: one 0.94 × 0.50 m panel, on a slender stand beside the glass. Viewpoints differ; the new view is at 1.65 m eye height.</figcaption></figure></div></section>
<section id="controls"><h2>Compare states, then look again</h2><p>PREVIOUS and NEXT cycle through named comparisons and return to the beginning. Changing a state stops motion and clears the previous sample marker. The panel identifies what is active. No save, store, KEEP or REPLAY buttons are shown.</p>{table}<p>STEP restarts the door after its eighth update. The open state permits passage. The cooling panel steps between marked times or plays continuously; PREVIOUS/NEXT during playback goes to the next marked time in that direction and pauses.</p></section>
<section class="grid"><figure><img loading="lazy" src="panel-1.png" alt="Compact Shannon panel: question, four-of-each state, one-bit reading and three buttons"><figcaption>Question → state → reading → action. The essential sampling rule stays next to the number.</figcaption></figure><div class="panel"><h2>Less explanation in the room</h2><p>The panel asks one question. It names the current comparison and gives the reading with the condition needed to interpret it. Longer definitions, model limits and reconstruction steps stay in the tutorial.</p><p>Prepared states make these small comparisons recoverable without asking visitors to manage files. Research capture/restore remains available to tooling and old receipts. The first 48-value research pilot retains its fuller save/replay loop.</p><p>The map remains directly after <strong>Random Definition</strong>. Restart the running museum to see the updated panels.</p></div></section>
<section><h2>All seven installations</h2><div class="grid">{cards}</div></section>
<section class="panel"><h2>Checks and next observation</h2><p><strong>{counts[0]} apparatus checks and {counts[1]} actual-room checks pass, with native exits 0.</strong> These exercise physical Previous/Next events, reversible state cycles, time playback/pause, contained panel text, model calculations, retained research reconstruction, clear standing areas, centre sightlines and the door passage.</p><p>Rendered views show the smaller panels and exposed objects. Headset legibility, hand reach and comfort still need a person. The next question is simple: can the visitor identify what NEXT changed and return to the baseline without an explanation?</p><nav><a href="verification.json">Apparatus checks</a><a href="museum-report.json">Room checks</a><a href="manifest.json">Source fingerprints</a><a href="plan.html">Research plan</a><a href="../2026-10-16-ordinary-entropies/sources.html">Measurement sources</a></nav></section>'''
(HERE/'index.html').write_text(page('Make room for the objects',body),encoding='utf8')
files=list((ROOT/'commons/artifacts/ordinary_entropies').glob('*.gd'))+list((ROOT/'commons/artifacts/ordinary_entropies').glob('*.gdshader'))+list(MAP.glob('*.md'))+[MAP/'writing_wall.json',MAP/'map_data.json',ROOT/'commons/artifacts/registry/ordinary_entropies.json']
(HERE/'manifest.json').write_text(json.dumps({'checks':counts,'panel_metres':[0.94,0.50],'max_buttons':3,'sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}},indent=2),encoding='utf8')
(HERE/'README.md').write_text(f'''# Make room for the objects

The user found the information boards and cabinets obscured the installations. This revision combines information and controls on a single 0.94 × 0.50 m plate beside each setup. A thin post replaces the cabinet. Two or three canonical full-size rectangular XR push buttons sit on the plate. The description wall's separate plaques become four small floor numbers.

PREVIOUS/NEXT cycles prepared states. Extra actions exist only where needed: DRAW, NEW SEED, STEP, PLAY/PAUSE or CHAIR. Visitor save/replay actions are removed; the research API retains capture/restore and receipt compatibility. Named states make ordinary comparisons repeatable. The first 48-value pilot and seven-stop room/final order are unchanged. The map remains after Random_Definition.

[Before/after and native views](index.html) · [Tutorial](tutorial.html) · [Final](final.html) · [Plan](plan.html).

{counts[0]} apparatus and {counts[1]} actual-hall checks pass, native exits 0. The suite verifies complete state cycles, backward baseline recovery, plate text bounds, native button callbacks, playback/pause and marked-time navigation, finite model correctness and research reconstruction. The room checks verify normal scale, clear standing positions at the side panels, central view rays, two/three controls, physical NEXT/PREVIOUS and held-open passage. Screenshots include close panels and 1.65 m viewing positions. Centre rays are a limited visibility check, not proof that every view is unobstructed. Headset legibility/reach/comfort and independent learner response remain untested.

Reproduce:

```
python -X utf8 doc/book/iterations/2026-10-16-entropy-quiet-panels/run.py
python -X utf8 tools/run_encounter_probe.py Random_Entropies --sequence randomness --render --no-bridges --output-tag quiet-panels --probe doc/book/iterations/2026-10-16-entropy-quiet-panels/museum_probe.gd
python -X utf8 doc/book/iterations/2026-10-16-entropy-quiet-panels/publish.py
```

Current tutorial, registry, writing-wall notes and plan follow the reduced controls. The final changed only the door/time control references needed to match the installed interaction. Earlier screenshots and receipts remain in the first ordinary-entropies trial.
''',encoding='utf8')
print('Published compact panels',counts)
