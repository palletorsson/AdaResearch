from pathlib import Path
import hashlib, json, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = ROOT / 'doc/book/iterations/2026-09-21-interface-spine-primitives-review'
OUT.mkdir(parents=True, exist_ok=True)
for variant in ['before', 'after']:
    for room in ['trace', 'grid']:
        for shot in ['reading', 'encounter']:
            shutil.copy2(HERE/variant/room/(shot+'.png'), OUT/f'{variant}-{room}-{shot}.png')
        shutil.copy2(HERE/variant/room/'report.json', OUT/f'{variant}-{room}-checks.json')
for name, source in [('trace', 'trace_data_panel'), ('grid', 'grid_lines_discovery')]:
    shutil.copy2(ROOT/'ada_run'/source/'checks.json', OUT/(name+'-checks.json'))
paths = [
    'commons/ui/data_instrument_surface.gd',
    'commons/primitives/point/draw_dot.gd',
    'commons/primitives/point/draw_dot_time_domain.gd',
    'commons/primitives/line/grid_lines.gd',
    'commons/maps/Point_Trace/map_data.json',
    'commons/maps/Point_Line_Grid/map_data.json',
    'commons/maps/Point_Line_Grid/final.md',
    'commons/testing/probe_trace_data_panel.gd',
    'commons/testing/probe_grid_lines_discovery.gd',
    'commons/testing/probe_spine_data_instruments.gd',
    'commons/scenes/endless_museum.gd',
    'ada_run/em_plan.json', 'ada_run/em_overrides.json', 'ada_run/necklace_hand.json',
]
(OUT/'sources.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf-8')

def figure(file, caption):
    return f'<figure><a href="{file}"><img src="{file}" alt="{caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

style = (ROOT/'doc/book/iterations/2026-09-21-interface-scalar-review/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
html = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Hold the page · Ada Research</title><style>'''+style+'''</style></head><body><main>
<div class="eyebrow">Ada Research · Interfaces along the spine · 21 September 2026</div>
<h1>Hold the page.<br>Look back at the line.</h1>
<p class="lead">The interface pass returns to the actual halls: Point_Trace and Point_Line_Grid. The hand writes a line; the next instrument lets you examine what was kept.</p>
<span class="badge">53 recorder and paging checks</span><span class="badge">24 actual-hall checks</span><span class="badge pending">Headset test remains</span>
<h2>Grid: decide when the page moves</h2>
<p>The table previously advanced every two seconds. It now starts on a held page. Three physical buttons sit together on a backplate: PREVIOUS, AUTO and NEXT. Auto remains available, with a selected cap and a heading that states its mode; either arrow returns to manual reading.</p>
'''+figure('after-grid-encounter.png','Actual Grid hall. The inclined instrument stands at the front-right corner, outside the five-metre lattice.')+'''
<div class="pair">'''+figure('before-grid-reading.png','Before: an automatically paging table beside the lattice.')+figure('after-grid-reading.png','After: fixed screen, aligned numeric columns and a compact physical paging row.')+'''</div>
<p>The screen centre is 1.20 m above the deck. Button targets are about 0.83 m high and 0.41–0.45 m horizontally from the tested operating pose. Collision rays reach all three controls; a standing capsule and the final metre of approach clear the hall geometry. These are measured layout checks, not evidence of headset comfort.</p>
<h2>Trace: the count belongs to the drawing</h2>
<p>The dot remains the drawing tool. Its instrument shows the retained count, the sampling gate, resolution and the last ten world positions. The flat 2D text now sits within a fixed case. Long signed coordinates change the typesetting instead of enlarging the object.</p>
<div class="pair">'''+figure('before-trace-reading.png','Before: the live Trace instrument after a supplied 24-point stroke.')+figure('after-trace-reading.png','After: the same supplied stroke, with a fixed flat display and monospaced coordinate rows.')+'''</div>
<p>Clearing the live stroke, releasing it to Grid, capacity eviction and the anchored reading plane retain their behavior. The inherited time-domain recorder still describes its own clock gate and fits its additional row.</p>
<h2>A reusable instrument, a specific encounter</h2>
<table><thead><tr><th>Shared</th><th>Kept specific</th></tr></thead><tbody>
<tr><td>Flat 2D text, physical casing, bounded screen, redraw on changed content.</td><td>Trace is a direct hand gesture. Its screen follows the first sample once, then stays anchored.</td></tr>
<tr><td>Existing native push buttons and pointer support.</td><td>Grid is a stationary archive. Its controls stand before and beside the replay.</td></tr>
<tr><td>Numeric type fits the screen.</td><td>The source coordinates, rescaling and green display-space quantization stay distinct.</td></tr>
</tbody></table>
<p>One sentence in Grid’s book text now explains held pages and Auto. Artifact roles, the sequence order and the sampling algorithms are preserved.</p>
<h2>Evidence and next pass</h2>
<p>These are Godot renders of the production museum builder, with a reproducible supplied stroke. The reading camera follows each station’s position; Grid has moved forward and inward slightly. The tests dispatch real pointer events to the physical button areas and check the actual replay vertices and source data.</p>
<p><a href="trace-checks.json">23 Trace checks</a> · <a href="grid-checks.json">30 Grid checks</a> · <a href="after-trace-checks.json">6 Trace hall checks</a> · <a href="after-grid-checks.json">18 Grid hall checks</a> · <a href="sources.json">Source snapshot hashes</a></p>
<div class="note">This pass covers these two instruments. It does not certify every interface in either room or the whole spine. Headset reading distance, seated reach, touch behavior with a real hand and Quest performance remain untested. Existing unrelated engine warnings remain in the logs.</div>
<p>Next: Point_Triangle_Context—check the triangle puzzle and face-drawing controls against the surface they create. The smaller snap-sphere readout in Grid remains a separate review item.</p>
<footer><a href="../2026-09-21-interface-scalar-review/index.html">Previous: shared scalar controls</a> · <a href="/necklace/thread?map=Point_Trace&amp;role=primary">Trace artifacts</a> · <a href="/necklace/thread?map=Point_Line_Grid&amp;role=primary">Grid artifacts</a></footer>
</main></body></html>'''
(OUT/'index.html').write_text(html,encoding='utf-8')
print(OUT)
