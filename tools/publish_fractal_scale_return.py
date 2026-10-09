"""Publish the reflective revision and native museum evidence; never rewrite sources."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import os
import re
import shutil
from urllib.parse import unquote, urlsplit

import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-08-fractals-scale-and-return'
RUN = ROOT/'ada_run/encounter_pilot/Fractal_RecursiveTrees'
HALLS = [
    ('Fractal_Recursion', 'Recursion', 'Finite calls give us somewhere to begin. Walking through a construction and changing its rule open different possibilities.'),
    ('Fractal_RecursiveTrees', 'Recursive Trees', 'Turn one branch; keep a drawing; walk below its descendants; return with a more situated description.'),
    ('Fractal_CantorSet', 'Cantor Set', 'The hand model, current intervals, history and bodily openings already make distinct readings available. Text retained.'),
    ('Fractal_KochSierpinski', 'Koch / Sierpinski', 'Making a longer path, showing omitted pieces and measuring at another resolution remain distinct operations. Text retained.'),
    ('Fractal_MengerSponge', 'Menger Sponge', 'Finding a hole becomes finding a route. Bring the bodily question back to the construction.'),
    ('Fractal_GoldenSpiral', 'Golden Spiral', 'The same numbers support different mappings. A numerical recurrence alone is no claim to fractality. Text retained.'),
    ('Fractal_Synthesis', 'Synthesis', 'Name the research method: describe, draw, inhabit, revise. Ask what warrants carrying a local finding into a room, sequence or book.'),
]
CHANGED = {'Fractal_Recursion', 'Fractal_RecursiveTrees', 'Fractal_MengerSponge', 'Fractal_Synthesis'}

def read(path):
    return path.read_text(encoding='utf-8-sig')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def dump(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')

for name in ['images', 'tests', 'after']:
    (OUT/name).mkdir(parents=True, exist_ok=True)

reports = []
for source, name, log in [
    (ROOT/'ada_run/fractal_scale_return_tests.json', 'projections-and-snapshot', ROOT/'ada_run/fractal-scale-return-engine.log'),
    (RUN/'report.json', 'museum-hall', RUN/'engine.log'),
]:
    report = json.loads(read(source))
    assert report['passed'] and not report['failures'], source
    assert 'SCRIPT ERROR' not in read(log), log
    shutil.copy2(source, OUT/'tests'/f'{name}.json')
    shutil.copy2(log, OUT/'tests'/f'{name}.log')
    reports.append({'name':name, 'checks':len(report['checks'])})
count = sum(r['checks'] for r in reports)

provenance = []
for name in ['two-readings-before', 'two-readings-after', 'readings-and-canopy', 'under-canopy', 'hand-model', 'above']:
    source = RUN/f'{name}.png'
    shutil.copy2(source, OUT/'images'/source.name)
    provenance.append({'file':'images/'+source.name, 'source':source.relative_to(ROOT).as_posix(), 'sha256':sha(source), 'kind':'native Godot capture / production museum / supplied test poses'})

CSS = '''
:root{--paper:#f6f2eb;--ink:#24222a;--rose:#b6577f;--line:#d8cdc9}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1320px;margin:auto;padding:28px 5vw}nav{display:flex;flex-wrap:wrap;gap:22px}a{color:#803652;text-underline-offset:4px}h1{font:clamp(36px,5.3vw,68px)/1.06 Georgia,serif;max-width:950px}h2{font:34px/1.2 Georgia,serif;margin-top:54px}h3{font-size:21px}p{max-width:74ch}.kicker{text-transform:uppercase;letter-spacing:.14em;font-size:12px}.lead{font:24px/1.5 Georgia,serif;max-width:65ch}.route{display:flex;flex-wrap:wrap;align-items:center;gap:14px;margin:32px 0}.route span{border:1px solid var(--line);padding:12px 18px;background:#fffdf8}blockquote{font:26px/1.45 Georgia,serif;margin:30px 0;padding:10px 24px;border-left:4px solid var(--rose)}figure{margin:26px 0}img{width:100%;display:block}figcaption{font-size:14px;color:#645761;margin-top:8px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:25px}.pair article{background:#fffdf8;padding:24px;min-width:0}.pair h1{font-size:30px}.pair p{font-size:16px}.reading{max-width:880px}.reading article{margin:55px 0;padding-top:10px;border-top:1px solid var(--line)}.reading article h1{font-size:40px}table{border-collapse:collapse;width:100%;background:#fffdf8}td,th{padding:15px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}th{font-size:13px;text-transform:uppercase}button{padding:10px 18px;border:1px solid var(--line);font:inherit;background:white;cursor:pointer;margin:5px 8px 5px 0}button[aria-pressed=true]{background:var(--ink);color:white}pre{background:#25232b;color:#f5edf0;padding:18px;overflow:auto;font:13px/1.6 Consolas,monospace}code{font-size:.88em}details{border-top:1px solid var(--line);padding:14px 0}summary{cursor:pointer;font-weight:650}.pill{display:inline-block;border:1px solid var(--line);border-radius:30px;padding:8px 15px;font-size:14px}.notes{background:#eae2dc;padding:24px}.notes p{margin:8px 0}@media(max-width:850px){.pair{grid-template-columns:1fr}header,main,footer{padding:22px}td,th{padding:10px}}@media print{nav,button{display:none}body{background:white}.pair{display:block}article{break-before:page}pre{white-space:pre-wrap}}
'''

def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+CSS+'</style></head><body><header><p class="kicker">Endless Museum · Fractals · 8 October 2026</p><nav><a href="index.html">Museum experiment</a><a href="final.html">Whole reflective sequence</a><a href="changes.html">Before / after texts</a><a href="method.html">Working method</a></nav></header>'+body+'<footer>Production museum captures; no generated images. In-engine input and geometry checks; physical headset comfort and learner understanding remain untested.</footer></body></html>'

def render(text, folder, prefix):
    rendered = markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])
    # Multiple independently rendered manuscripts have independent footnote IDs.
    rendered = re.sub(r'id="([^"]+)"', lambda m:f'id="{prefix}-{m[1]}"', rendered)
    def relocate(m):
        kind, target = m.groups()
        if target.startswith('#'):
            return f'{kind}="#{prefix}-{target[1:]}"'
        if target.startswith(('https:', 'http:', 'mailto:', 'res:')):
            return m[0]
        parts = urlsplit(target)
        if parts.path.startswith('/book-review/'):
            source = ROOT / unquote(parts.path.removeprefix('/book-review/'))
        else:
            source = (folder / unquote(parts.path)).resolve()
        assert source.exists(), (folder, target)
        anchor = '#'+parts.fragment if parts.fragment else ''
        if kind == 'src':
            destination = OUT/'images'/f'{folder.name}-{source.name}'
            shutil.copy2(source, destination)
            record = {'file':'images/'+destination.name, 'source':source.relative_to(ROOT).as_posix(), 'sha256':sha(source), 'kind':'retained manuscript image'}
            if record not in provenance: provenance.append(record)
            return f'src="images/{destination.name}"'
        return f'href="{Path(os.path.relpath(source, OUT)).as_posix()}{anchor}"'
    return re.sub(r'(src|href)="([^"]+)"', relocate, rendered)

readings = []
changes = []
diffs = []
source_files = []
rows = []
for hall, name, decision in HALLS:
    folder = ROOT/'commons/maps'/hall
    current = read(folder/'final.md')
    before = read(OUT/'before'/f'{hall}-final.md')
    shutil.copy2(folder/'final.md', OUT/'after'/f'{hall}-final.md')
    source_files.append(folder/'final.md')
    readings.append(f'<article id="{hall}"><p class="kicker">{html.escape(name)} · final.md</p>'+render(current, folder, hall)+'</article>')
    rows.append(f'<tr><td><a href="final.html#{hall}">{html.escape(name)}</a></td><td>{html.escape(decision)}</td><td>{"Revised reflection" if hall in CHANGED else "Existing text retained"}</td></tr>')
    if hall in CHANGED:
        changes.append(f'<section id="{hall}"><h2>{html.escape(name)}</h2><p>{html.escape(decision)}</p><details><summary>Read the full before and after</summary><div class="pair"><article><p class="kicker">Before this pass</p>'+render(before, folder, hall+'-before')+'</article><article><p class="kicker">Current final.md</p>'+render(current, folder, hall+'-after')+'</article></div></details></section>')
        diffs.extend(difflib.unified_diff(before.splitlines(True), current.splitlines(True), fromfile=f'before/{hall}/final.md', tofile=f'after/{hall}/final.md'))
    else:
        assert before == current, f'Unexpected edit in retained hall: {hall}'

(OUT/'final.html').write_text(page('Fractals — the whole reflective sequence', '<main class="reading"><h1>Fractals: the reflective sequence</h1><p>Seven current final.md texts in museum order. This pass adds the scale-and-return thread in four halls.</p><nav>'+' '.join(f'<a href="#{hall}">{name}</a>' for hall,name,_ in HALLS)+'</nav>'+''.join(readings)+'</main>'), encoding='utf-8')
(OUT/'changes.html').write_text(page('Fractals — before and after', '<main><h1>Four changes through seven halls.</h1><p>These are the full texts before and after this pass. Cantor, Koch / Sierpinski and Golden Spiral retain their existing reflections. Tutorial files are unchanged.</p><p><a href="final-changes.diff">Plain-text diff</a></p>'+''.join(changes)+'</main>'), encoding='utf-8')
(OUT/'final-changes.diff').write_text(''.join(diffs), encoding='utf-8')
method = ROOT/'doc/book/course/fractals-scale-and-return.md'
shutil.copy2(method, OUT/'METHOD.md')
(OUT/'method.html').write_text(page('Fractals — a working method', '<main class="reading">'+render(read(method), method.parent, 'method')+'</main>'), encoding='utf-8')

body = f'''<main><h1>Return with a<br>different question.</h1>
<p class="lead">Fractal thinking gives a finite encounter with a much larger field of possibilities. Moving from a sentence to a drawing to a room changes what we can notice and do. Returning can change the sentence.</p>
<div class="route" aria-label="Research cycle"><span>Describe</span>→<span>Draw</span>→<span>Inhabit</span>→<span>Describe again</span></div>
<p class="pill">4 reflective texts revised · one existing hall extended · {count} native checks passed</p>
<figure><img src="images/readings-and-canopy.png" alt="Inside the real Recursive Trees hall: two drawings beside the small held-point model, with the large canopy above"><figcaption>Current museum, standing view. The new drawing station is beside the existing tree controls and hand model. The same branch records feed the drawings and canopy.</figcaption></figure>
<h2>Keep. Turn. Walk. Return.</h2>
<p>Grow the tree. Press KEEP, then turn one point on its small model. The current tree is black in the drawings; the kept version is rose. Plan and side view show different parts of the same change. Walk under the canopy and come back: which difference mattered to your body, and how would you describe it now?</p>
<button id="before" aria-pressed="true" onclick="compare(false)">Before the turn</button><button id="after" aria-pressed="false" onclick="compare(true)">After the turn</button>
<figure><img id="comparison" src="images/two-readings-before.png" alt="Plan and side drawings before turning one branch"><figcaption id="comparison-caption">KEEP has just recorded this tree. The two versions coincide. Same camera in both captures.</figcaption></figure>
<p>The plan omits height. The side view omits depth. A vertical trunk appears as a small mark in the plan without any branch being removed from the actual tree. All drawings retain the same fixed scale.</p>
<blockquote>Nothing has been cut from the tree. Something has been left out of the account.</blockquote>
<figure><img src="images/under-canopy.png" alt="Looking up from beneath the solid branching canopy inside the museum"><figcaption>The inherited canopy encounter, tested in the same run. This low view is a bodily reading of the geometry; the drawing does not record the visitor's route or response.</figcaption></figure>
<h2>What enters the final sequence</h2>
<table><thead><tr><th>Hall</th><th>What the encounter carries</th><th>This pass</th></tr></thead><tbody>{''.join(rows)}</tbody></table>
<p><a href="final.html">Read all seven reflective texts</a> · <a href="changes.html">Read the four changes beside their previous versions</a></p>
<h2>What travels between scales?</h2>
<p>The tree provides a particular experiment. Synthesis opens the wider research question: when should a local discovery remain a pleasure in one room, and when does it warrant changing the room, sequence or book? We need an account of what changed and why it matters. More versions alone do not decide that.</p>
<blockquote>Walking explores the world we have made. Changing a generating rule explores worlds it could become.</blockquote>
<p>“Fractal thinking” names this project's method. The text keeps that artistic proposition distinct from a claim about mathematical fractals. A hierarchy of rooms and objects is insufficient proof. A changed viewpoint, changed geometry and changed bodily affordance are also different operations.</p>
<h2>What this instrument keeps</h2>
<p>One copied set of branch endpoints plus the current rule settings, for this visit. KEEP replaces it; CLEAR removes it. The live tree stays under its existing controls. The four rule settings alone cannot recreate a local hand edit; the endpoint record carries that difference. There is no automatic ranking, room restoration or recording of the visitor's experience.</p>
<h2>Verification</h2>
<div class="notes"><p><strong>{count} checks passed:</strong> 21 on real rendered projection geometry, snapshot independence, local coordinates, source invariants and XR pickup; 30 in the production museum, including inherited fork/canopy controls, route clearance, standing approach, desktop-ray KEEP/CLEAR and capture cameras.</p><p>Godot 4.6, OpenGL compatibility rendering and supplied controller poses. Physical headset feel, Quest performance and learning effectiveness still need a visitor. Existing UID/Jolt/renderer diagnostics remain in the saved logs; the final runs contain no script errors.</p><p>The first geometry test used the headless dummy renderer, which returned identity transforms on MultiMesh readback. Running those assertions with the real renderer resolved the test mismatch. No assertion was removed.</p></div>
<p><a href="tests/projections-and-snapshot.json">Projection assertions</a> · <a href="tests/museum-hall.json">Museum assertions</a> · <a href="verification.json">Source hashes</a> · <a href="image-sources.json">Image provenance</a> · <a href="method.html">Working method and compact instruction</a> · <a href="source-note.txt">Your supplied note</a></p>
</main><script>function compare(after){{document.getElementById('comparison').src='images/two-readings-'+(after?'after':'before')+'.png';document.getElementById('comparison').alt=after?'Black live branches diverge from the rose kept tree in two projections':'Plan and side drawings before turning one branch';document.getElementById('before').setAttribute('aria-pressed',String(!after));document.getElementById('after').setAttribute('aria-pressed',String(after));document.getElementById('comparison-caption').textContent=after?'After one point turns: 31 segments remain; 15 spans have moved. Rose keeps the previous geometry. Same camera.':'KEEP has just recorded this tree. The two versions coincide. Same camera in both captures.';}}</script>'''
(OUT/'index.html').write_text(page('Fractal thinking — scale and return', body), encoding='utf-8')

source_files += [method, ROOT/'commons/artifacts/recursive_tree_lesson/tree_readings.gd', ROOT/'commons/artifacts/recursive_tree_lesson/recursive_tree_lesson.gd', ROOT/'tools/probes/fractal_scale_return.gd', ROOT/'tools/probes/fractal_scale_return_museum.gd', ROOT/'tools/test_fractal_scale_return.py']
source_files += [ROOT/'commons/artifacts/recursive_tree_lesson'/name for name in ['hand_fork.gd', 'fork_point.gd', 'branch_canopy.gd', 'HAND_FORK.md']]
source_files.append(ROOT/'algorithms/fractals/recursivetree/recursive_tree.gd')
dump(OUT/'image-sources.json', provenance)
dump(OUT/'verification.json', {'reports':reports, 'total_checks':count, 'sources':[{'file':p.relative_to(ROOT).as_posix(), 'sha256':sha(p)} for p in source_files], 'scope':'Reflective text integration and one local comparison instrument; tutorial code unchanged. Synthetic input, not headset or learning verification.'})

# Validate saved report references without retrying the restricted browser preview.
links = 0
for path in OUT.glob('*.html'):
    for target in re.findall(r'(?:src|href)="([^"]+)"', read(path)):
        if target.startswith(('https:', 'http:', 'mailto:', 'res:')): continue
        parts = urlsplit(html.unescape(target))
        destination = (path.parent/unquote(parts.path)).resolve() if parts.path else path
        assert destination.exists(), (path.name, target)
        if parts.fragment and destination.suffix == '.html':
            assert f'id="{unquote(parts.fragment)}"' in read(destination), (path.name, target)
        links += 1
print(f'Published {OUT}\n{count} native checks; {links} report references resolve; {len(provenance)} image records.')
