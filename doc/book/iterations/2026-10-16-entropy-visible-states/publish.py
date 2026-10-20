"""Publish native evidence for simultaneous entropy comparisons."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
MAP=ROOT/'commons/maps/Random_Entropies'
RUN=ROOT/'ada_run/encounter_pilot/Random_Entropies/visible-states'
for path in RUN.glob('*.png'):shutil.copy2(path,HERE/path.name)
for src,dst in [('report.json','museum-report.json'),('source_manifest.json','museum-source-manifest.json')]:shutil.copy2(RUN/src,HERE/dst)
reports=[json.loads((HERE/n).read_text(encoding='utf8')) for n in ['verification.json','museum-report.json']]
assert all(r['passed'] and not r['failures'] for r in reports)
counts=[len(r['checks']) for r in reports]
style='''body{margin:0;background:#f3f0e7;color:#243c3e;font:18px/1.55 system-ui,sans-serif}main{max-width:1450px;margin:auto;padding:24px}h1{font:clamp(34px,4vw,58px)/1.12 Georgia,serif;margin:12px 0 22px}h2{font:32px/1.2 Georgia,serif}p{max-width:82ch}a{color:#17695f}nav{display:flex;gap:12px 24px;flex-wrap:wrap}section{margin:32px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.reading{max-width:900px}small{letter-spacing:.08em;text-transform:uppercase;color:#567169}figure{margin:0}img{display:block;width:100%;background:#23373c}figcaption{padding:14px 18px;background:#e1e6d9}.panel{padding:24px;background:#e1e6d9}th,td{padding:12px;border-bottom:1px solid #bdcaba;text-align:left;vertical-align:top}table{width:100%;border-collapse:collapse;font-size:16px}pre{overflow:auto;font-size:14px;background:#e1e6d9;padding:16px}code{font-size:.9em}@media(max-width:850px){.grid{grid-template-columns:1fr}main{padding:18px}}'''

def page(title,body,reading=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+' · Ada Research</title><style>'+style+'</style><main'+(' class="reading"' if reading else '')+'>'+body+'</main></html>'

for name in ['tutorial','final','plan']:
    source=(MAP/(name+'.md')).read_text(encoding='utf8').replace('](tutorial.md)','](tutorial.html)').replace('](final.md)','](final.html)')
    (HERE/(name+'.html')).write_text(page(name.title(),'<nav><a href="index.html">← Versions together</a><a href="tutorial.html">Tutorial</a><a href="final.html">Final</a></nav>'+markdown.markdown(source,extensions=['tables','fenced_code']),True),encoding='utf8')

rows=[
 ('Shannon chairs','Four inventories: 4/4, rearranged 4/4, 7/1 and 8/0','Colour uncertainty changes with counts; rearranging alone leaves it fixed.'),
 ('Boltzmann chairs','One sorted and two mixed assignments','A distinct arrangement can still satisfy the same coarse description.'),
 ('Description wall','Four arrangements and their candidate recipes','An irregular image can have a short seeded construction.'),
 ('Door dynamics','Two pairs on one clock, plus an open passage','Nearby starts contract or separate under different rules.'),
 ('Cooling cups','Three tables: 0, 15 and 60 seconds','One model at three fixed times; heat transfers while total energy stays fixed.'),
 ('Frosted chairs','One chair identity, three record channels','The record can preserve identity, colour or no distinguishing detail.'),
 ('Ball pits','Three identical inventories with different rules','The best guess depends on the declared outcome and sampling weights.')
]
table='<table><thead><tr><th>Encounter</th><th>What stays visible</th><th>The comparison</th></tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+html.escape(v)+'</td>' for v in row)+'</tr>' for row in rows)+'</tbody></table>'
ids=json.loads((MAP/'writing_wall.json').read_text(encoding='utf8'))['order']
cards=''.join(f'<figure><h3>{i+1}. {html.escape(rows[i][0])}</h3><a href="{id}.png"><img loading="lazy" src="{id}.png" alt="{html.escape(rows[i][0])}: versions remain visible together, without controls"></a><figcaption><a href="wall-{i+1}.png">Read the wall explanation</a></figcaption></figure>' for i,id in enumerate(ids))
body=f'''<header><small>Ada Research · Random_Entropies · 16 October 2026</small><h1>States beside one another</h1><p>The comparison stays in the room. Different versions appear together at everyday scale. Controls and freestanding panels are gone; one compact explanation sits on the wall beside each encounter.</p><nav><a href="#versions">Seven comparisons</a><a href="tutorial.html">Tutorial</a><a href="final.html">Final text</a><a href="/long-museum/writing-wall?map=Random_Entropies">Writing wall</a></nav></header>
<section><figure><img src="entropy_frosted_chair.png" alt="Three copies of the same chair behind clear, frosted and opaque screens, with explanation on the right wall"><figcaption>The same chair, three record channels. These are simultaneously visible versions, not successive screenshots of a changing state. Native Godot capture at 1.65 m eye height.</figcaption></figure></section>
<section id="versions"><h2>Walk between the differences</h2>{table}<p>The two driven door pairs repeat automatically. Cups remain at their labelled model times. The chair-colour and ball-pit displays declare hypothetical sampling rules; they do not perform draws.</p></section>
<section class="grid"><figure><img loading="lazy" src="wall-1.png" alt="Wall-mounted Shannon explanation and four state readings"><figcaption>One 1.60 × 0.98 m wall text: the question's conditions, the comparison and its readings. Floor letters link text with objects.</figcaption></figure><div class="panel"><h2>Explanation alongside the objects</h2><p>The text is expanded from the previous short readout but remains on one small surface. It names what is counted and what the number cannot establish. There are no controls to learn or saved files to manage.</p><p>The room and final retain the same seven-stop order. The tutorial now begins with comparing visible versions and then reconstructing a small calculation independently. The 48-value seed bench remains the first research pilot.</p><p>Restart the museum to load this revision. The map remains directly after <strong>Random Definition</strong>.</p><a href="../2026-10-16-entropy-quiet-panels/index.html">Previous button-controlled version</a></div></section>
<section><h2>The installed comparisons</h2><div class="grid">{cards}</div></section>
<section class="panel"><h2>What has been checked</h2><p><strong>{counts[0]} apparatus checks and {counts[1]} actual-room checks pass, native exits 0.</strong> These verify finite model calculations, actual chair inventories, simultaneous version counts, absent button areas, wall text bounds, individual reconstruction, wall attachment, normal scale, supported clear approaches and the open passage.</p><p>Headset legibility and comparison clarity remain human questions. Does the persistent baseline make the changed condition easier to identify? Can a visitor match each floor letter with its wall reading? The versions remain available together; independent reconstruction tests the capacity to make a new variation.</p><nav><a href="verification.json">Apparatus checks</a><a href="museum-report.json">Room checks</a><a href="manifest.json">Source fingerprints</a><a href="plan.html">Plan</a><a href="aerial.png">Room overview</a></nav></section>'''
(HERE/'index.html').write_text(page('States beside one another',body),encoding='utf8')
files=[p for p in (ROOT/'commons/artifacts/ordinary_entropies').iterdir() if p.suffix in ['.gd','.tscn','.gdshader']]+list(MAP.glob('*.md'))+[MAP/'writing_wall.json',MAP/'map_data.json',ROOT/'commons/artifacts/registry/ordinary_entropies.json']
(HERE/'manifest.json').write_text(json.dumps({'checks':counts,'wall_text_metres':[1.60,0.98],'buttons':0,'sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}},indent=2),encoding='utf8')
(HERE/'README.md').write_text(f'''# States beside one another

The user requested simultaneous versions, no interface, and a compact expanded explanation on the wall. Seven registered scenes now use `comparison.gd`; individual copies share the earlier finite models and receipt schema but disable controls. Wall texts are 1.60 × 0.98 m. Floor letters identify comparisons. The group placements and seven-stop sequence remain unchanged.

{counts[0]} apparatus and {counts[1]} native actual-hall checks pass. These cover finite model correctness, version composition, actual inventories, absent controls, contained text, reconstruction, wall mounting, full scale, standing clearance and passage. Native screenshots show each installation and every wall text. Headset performance/readability and learning value remain unverified.

Reproduce:

```
python -X utf8 doc/book/iterations/2026-10-16-entropy-visible-states/run.py
python -X utf8 tools/run_encounter_probe.py Random_Entropies --sequence randomness --render --no-bridges --output-tag visible-states --probe doc/book/iterations/2026-10-16-entropy-visible-states/museum_probe.gd
python -X utf8 doc/book/iterations/2026-10-16-entropy-visible-states/publish.py
```

The first 48-value bench remains the first pilot. This revision supports comparison by looking and moving; new experimental variants must be reconstructed in code. No automatic sampling or controls are implied by the static chair and pit displays. Doors repeat on an explicit clock; cups are fixed model-time snapshots. Existing research APIs survive on individual copies, not as a visitor interface.
''',encoding='utf8')
print('Published simultaneous comparisons',counts)
