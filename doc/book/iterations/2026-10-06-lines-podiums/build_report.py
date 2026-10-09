"""Keep the actual museum images and their native test evidence together."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
RUN = ROOT / 'ada_run/encounter_pilot/Point_Lines_podiums_after'
BEFORE = ROOT / 'ada_run/encounter_pilot/Point_Lines_podiums_before'
shots = ['hall', 'relations', 'horizontal-vertical', 'materials', 'follow', 'cross-depth']
for name in shots:
    shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
for name in ['hall', 'follow']:
    shutil.copy2(BEFORE / f'{name}.png', OUT / f'before-{name}.png')
shutil.copy2(RUN / 'report.json', OUT / 'report.json')
report = json.loads((OUT / 'report.json').read_text())
manifest = json.loads((RUN / 'source_manifest.json').read_text())
for name in ['line_body.gd', 'line_relations_gallery.gd']:
    path = ROOT / 'commons/artifacts/line_relations_gallery' / name
    manifest['sources'][path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
(OUT / 'source_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')

def picture(name, caption):
    return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

html = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Point Lines · Bodies and relations</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#28242b;font:17px/1.6 system-ui,sans-serif}
main{max-width:1320px;margin:auto;padding:45px 28px 80px}h1{font:clamp(38px,5vw,70px)/1.06 Georgia,serif;margin:.25em 0}h2{font:30px Georgia,serif;margin:2em 0 .6em}
.eyebrow{font-size:12px;letter-spacing:.18em;text-transform:uppercase;color:#75666c}.intro{max-width:850px;font-size:20px}a{color:#844968}nav{display:flex;gap:24px;margin:25px 0}figure{margin:0 0 24px}img{display:block;width:100%;border-radius:3px}figcaption{font-size:14px;margin:8px 0 0;color:#5b5055}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.note{padding:20px 24px;background:#e9e1d7;border-left:4px solid #d584a9;margin:25px 0}.note p{margin:.4em 0}details{margin-top:24px}summary{cursor:pointer;font-weight:600}footer{margin-top:44px;font-size:14px;color:#655b5e}@media(max-width:740px){.grid{grid-template-columns:1fr}main{padding:24px 16px}nav{flex-wrap:wrap}}
</style><main>
<div class="eyebrow">Endless Museum · Point Lines · 6 October 2026</div>
<h1>Bodies and relations.</h1>
<p class="intro">The illustrations now have a physical arrangement in the museum: five relation podiums, a shared plinth of line materials, and a mark that continues from the floor up the wall.</p>
<nav><a href="#podiums">The podiums</a><a href="#materials">Line materials</a><a href="#follow">Follow the line</a><a href="#before">Before / after</a><a href="#checks">Checks</a></nav>
'''
html += picture('hall', 'The actual Point Lines hall, rendered in Godot. Horizontal, vertical, parallel, plus and X have separate off-white podiums.')
html += '<h2 id="podiums">One span. Different relations.</h2><p>Pink segments retain a 1.2 m distance between white endpoint centres. The plus and X cross in the view; their bars occupy planes 18 cm apart. Walk around them, pick up a line, and leave another arrangement.</p><div class="grid">'
html += picture('horizontal-vertical', 'Horizontal and vertical: the same length in different directions.')
html += picture('relations', 'Parallel, plus and X: separate podiums with space to approach from either side.')
html += '</div>' + picture('cross-depth', 'The X from the side. Two separate bars; four endpoints. No extra point has been added at the apparent crossing.')
html += '<h2 id="materials">A body for a line.</h2><p>A wooden plank, a dark rod, a pink luminous strip and a marked ruler share one plinth. Each can be picked up. The broad wooden face and ruler marks face the approaching visitor.</p>'
html += picture('materials', 'Four different physical readings of a line, on a single museum plinth.')
html += '<h2 id="follow">Follow this line.</h2><p>The dark mark runs across the floor, meets the real hall wall and rises to 3.9 m. The floor text now faces the direction of following.</p>'
html += picture('follow', 'Floor and wall carry one continuous mark. The seven leaning planks remain along the same wall.')
html += '<h2 id="before">Before / after.</h2><div class="grid">'
html += picture('before-hall', 'Before: floating dark relation studies shared the open floor.')
html += picture('hall', 'After: each relationship has a named plinth and matching pink-and-white appearance.')
html += picture('before-follow', 'Before: a thin line and a long single-line floor caption.')
html += picture('follow', 'After: a stronger continuous mark, a taller wall segment and a two-line floor caption.')
html += '</div><h2 id="checks">Native museum checks.</h2><div class="note">'
html += f'<p><strong>{len(report["checks"])} checks passed.</strong> Actual museum loading, endpoint/collision agreement, equal spans, depth separation, solid plinths, walking gaps, XRTools pickup/release, held-object-safe reset, tool ray contact and timed rebuilding.</p>'
html += '<p>The existing grid, depth, leaning-plank and ceiling-alignment studies remain. These images are native Godot captures; headset comfort and Quest performance have not been tested.</p></div>'
html += '<details><summary>Evidence and scope</summary><p><a href="report.json">Native checks</a> · <a href="source_manifest.json">Source hashes</a> · <a href="probe.gd">Probe</a> · <a href="run.py">Isolated museum runner</a></p><p>The before and after runs both report an existing blocked authored exit and the museum’s safe portal fallback. This pass checks access between the podiums; it does not certify travel to the next hall. Existing weapon-cabinet material warnings also occur in both runs.</p><p>The line figures use the project’s XRToolsPickable behaviour. Grabbing carries a complete segment and its endpoint spheres; the entrance black-box exhibit remains the separate endpoint-editing study.</p></details>'
html += '<footer>Reference: the supplied illustrations and the Point_Lines prompt in the tutorial comic plates. Implemented in the existing line_relations_gallery artifact; museum map placement and book text are unchanged.</footer></main></html>'
(OUT / 'index.html').write_text(html, encoding='utf-8')
print(f'Wrote {OUT / "index.html"}; {len(report["checks"])} checks, {len(shots)+2} museum captures.')
