from pathlib import Path
import hashlib
import html
import json
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
runs = {
    'lines': ('Point_Lines', ['follow-start', 'follow-return', 'follow-hall']),
    'triangle': ('Point_Triangle_Context', ['triangle-side-console', 'triangle-close', 'triangle-front']),
}
reports = {}
sources = ['commons/artifacts/line_relations_gallery/line_relations_gallery.gd',
           'commons/primitives/point/draw_triangle_faces.gd',
           'commons/primitives/line/museum_line_style.gd',
           'commons/ui/triangle_workbench.gd']
for label, (hall, shots) in runs.items():
    run = ROOT / f'ada_run/encounter_pilot/{hall}_column_side_controls'
    report = json.loads((run / 'report.json').read_text())
    log = (run / 'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log and report['passed'] and not report['failures'], label
    assert len(report['checks']) >= (20 if label == 'lines' else 60), label
    reports[label] = report
    shutil.copy2(run / 'report.json', OUT / f'{label}-checks.json')
    for shot in shots:
        shutil.copy2(run / f'{shot}.png', OUT / f'{shot}.png')
    manifest = json.loads((run / 'source_manifest.json').read_text())
    for name in sources:
        manifest['sources'][name] = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
    (OUT / f'{label}-sources.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')

def picture(name, words):
    caption = html.escape(words)
    return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>A line you cannot walk · Room at the triangle</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#28242b;font:17px/1.6 system-ui,sans-serif}main{max-width:1320px;margin:auto;padding:45px 28px 80px}h1{font:clamp(38px,5vw,70px)/1.06 Georgia,serif;margin:.3em 0}h2{font:30px Georgia,serif;margin:2em 0 .6em}.eyebrow{font-size:12px;letter-spacing:.18em;text-transform:uppercase;color:#75666c}.intro{max-width:880px;font-size:20px}a{color:#844968}nav{display:flex;gap:24px;margin:25px 0;flex-wrap:wrap}figure{margin:0 0 24px}img{display:block;width:100%;border-radius:3px}figcaption{font-size:14px;margin:8px 0 0;color:#5b5055}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.note{padding:20px 24px;background:#e9e1d7;border-left:4px solid #d584a9;margin:25px 0}.note p{margin:.5em 0}footer{font-size:14px;margin-top:40px;color:#655b5e}@media(max-width:740px){.grid{grid-template-columns:1fr}main{padding:24px 16px}}
</style><main><div class="eyebrow">Endless Museum · Lines and Triangle · 6 October 2026</div>
<h1>A line you cannot walk.</h1>
<p class="intro">The mark now crosses the middle aisle, climbs a two-metre column, passes over its top and descends to the floor. The mark continues; to follow it, your body has to leave it.</p>
<nav><a href="#line">Follow this line</a><a href="#triangle">Room at the plinth</a><a href="#before">Before / after</a><a href="#checks">Checks</a></nav>
'''
page += picture('follow-return', 'The continuous mark returns down the far side of the solid 2 m column. Both sides remain open for walking around it.')
page += '<h2 id="line">From the floor into a limit.</h2><p>START marks the beginning. FOLLOW THIS LINE sits beside the dark floor stripe. The column has moved into the clear central aisle between the existing studies. The stripe stays thin against the floor, front, top and back surfaces.</p>'
page += picture('follow-start', 'Approaching through the line podiums: the floor mark becomes vertical at the column.')
page += '<h2 id="triangle">Stand close to the drawing.</h2><p>The controls for One drawing, two scales now sit beside the small plinth on their own narrow off-white support. The front edge is clear. You can approach the small triangle directly, hold a corner and watch the large face move.</p>'
page += picture('triangle-front', 'All seven actions remain on the side console, with space directly in front of the small triangle.')
page += picture('triangle-close', 'A close view from the newly cleared front of the plinth.')
page += '<h2 id="before">Before / after.</h2><div class="grid">'
page += picture('before-follow', 'Before: the line ended by rising up the hall wall.')
page += picture('follow-return', 'After: it rises and descends on a freestanding column in the middle aisle.')
page += picture('before-maker', 'Before: the sloped control board occupied the front of the drawing plinth.')
page += picture('triangle-front', 'After: the console stands beside the plinth. The approach is open.')
page += '</div><h2 id="checks">Native museum checks.</h2><div class="note">'
page += f'<p><strong>{len(reports["lines"]["checks"])} Lines checks and {len(reports["triangle"]["checks"])} Triangle checks passed.</strong> The column blocks the marked walking path; both side routes pass. The five painted sections meet. A player-sized capsule can approach the triangle to within 5 cm of the plinth, where the next step contacts the plinth rather than the console.</p>'
page += '<p>The previous snapping, pickup, trigger placement, shared-corner, live-twin, undo and reset checks also pass with the console moved. These are native Godot captures with supplied interaction input. Headset comfort and Quest performance remain untested.</p></div>'
page += '<p><a href="lines-checks.json">Lines checks</a> · <a href="triangle-checks.json">Triangle checks</a> · <a href="lines-sources.json">Lines source hashes</a> · <a href="triangle-sources.json">Triangle source hashes</a></p>'
page += '<footer>Existing museum output paths were isolated for these runs. Unrelated resource-UID, cabinet-material and audio-name warnings remain; the Lines hall also retains its existing exit-portal fallback. This pass verifies the local arrangements, not travel through the entire sequence. Tutorial and reflective writing have not been changed.</footer></main></html>'
(OUT / 'index.html').write_text(page, encoding='utf-8')
print({label: len(report['checks']) for label, report in reports.items()})
print(OUT / 'index.html')
