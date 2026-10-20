"""Publish native room evidence; refuse incomplete or failed runs."""
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-seven-spaces-in-the-museum'
RUN=ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces'
OUT.mkdir(parents=True,exist_ok=True)
runs={}
for tag in ['seven-spaces','seven-spaces-mobile']:
    report=json.loads((RUN/tag/'report.json').read_text(encoding='utf-8'))
    log=(RUN/tag/'stdout.log').read_text(encoding='utf-8')
    assert report['passed'] and any(c['name']=='probe reached every final assertion' and c['passed'] for c in report['checks']),tag
    assert 'SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log,tag
    runs[tag]=report
    dest=OUT/'evidence'/tag
    dest.mkdir(parents=True,exist_ok=True)
    for name in ['report.json','stdout.log','source_manifest.json']:
        shutil.copy2(RUN/tag/name,dest/name)
for path in (RUN/'seven-spaces-mobile').glob('*.png'):
    shutil.copy2(path,OUT/path.name)
sources=list((ROOT/'commons/artifacts/noneuclidean_wing').glob('*'))
sources += [ROOT/'tools/probes/noneuclidean_wing.gd',ROOT/'commons/maps/NonEuclidean_Spaces/map_data.json',ROOT/'commons/artifacts/registry/alternative_geometries.json',ROOT/'doc/book/studies/noneuclid-lineage/point_body.gd']
manifest={'published_utc':datetime.now(timezone.utc).isoformat(),'scope':'Installed museum encounters; author native desktop tests; no headset or fresh ghost reconstruction claim','runs':{k:{'passed':v['passed'],'checks':len(v['checks']),'renderer':v['observations']['renderer']} for k,v in runs.items()},'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources if p.is_file() and p.suffix!='.uid'}}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
notes=(ROOT/'commons/artifacts/noneuclidean_wing/README.md').read_text(encoding='utf-8')
(OUT/'BUILD-NOTES.md').write_text(notes,encoding='utf-8')
items=[
('A room that will not fit','Walk through the narrow door into a larger room, carrying the same black point. Walk back.','Portal connectivity · rigid transfer · object identity','Native stencil view; Euclidean rooms. The preview is unlit and nonrecursive.'),
('The corridor returns your point','Walk across either blue line without turning. You return at the opposite end, still holding the same point.','Topology · periodic coordinates · winding count','The crossing wraps your position. It is a flat corridor, without a recursive view down the ends.'),
('Its arrow does not return','Move the point sideways to carry an arrow around three great-circle arcs. The position returns; its direction changes.','Spherical geodesics · parallel transport · 90° holonomy','A curved two-dimensional surface, displayed as a large sphere inside the room.'),
('The edge you cannot reach','Move a corner with the point in your hand. Compare the Poincare and Klein displays; count equal intrinsic steps near the boundary.','Hyperbolic distance · geodesics · angle deficit · representations','Both displays retain the same metric points. Invalid triangles receive no angle claim.'),
('Hyperbolic galleries / H² × R','Hold the point away from your chest and press its trigger to move through the surrounding architecture. Horizontal distance curves; height stays ordinary.','Product geometry · Lorentz boosts · observer position','A first-person finite metric view around a physical support deck. Not a regular five-squares-around-a-corner tiling.'),
('The room curves upwards too / H³','Use the same point to travel upwards as well as sideways. The galleries now respond to curvature in every plane.','Three-dimensional hyperbolic geometry · eye-relative projection','A finite H³ architecture view. The support deck uses ordinary physics; curved walls do not have Jolt collisions.'),
('Aim straight. Watch the path.','Move the point sideways to aim and press its trigger. The shot follows an exact geodesic; its hit is decided by metric distance.','Geodesic motion · intrinsic speed · metric targeting','The held point aims a rendered shot. Hit substeps use the same geometry as the visible path.'),
]
cards=[]
for i,(title,action,subjects,scope) in enumerate(items,1):
    overhead=f'<details><summary>Look from above</summary><img loading="lazy" src="above-{i:02}.png" alt="Overhead view of chamber {i}"></details>' if (OUT/f'above-{i:02}.png').exists() else ''
    cards.append(f'<section id="space-{i}"><div class="copy"><small>CHAMBER {i:02} / 07</small><h2>{html.escape(title)}</h2><p>{html.escape(action)}</p><p class="subjects">{html.escape(subjects)}</p></div><a href="space-{i:02}.png"><img loading="lazy" src="space-{i:02}.png" alt="Native museum capture: {html.escape(title)}"></a><p class="scope">{html.escape(scope)}</p>{overhead}</section>')
totals=' · '.join(f'{v["observations"]["renderer"]}: {len(v["checks"])} / {len(v["checks"])}' for v in runs.values())
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Seven spaces in the Endless Museum</title><style>
:root{color-scheme:dark;font-family:system-ui,sans-serif;background:#151821;color:#ece7df}*{box-sizing:border-box}body{margin:0}header,main,footer{max-width:1200px;margin:auto;padding:32px}header{padding-top:64px}h1{font-size:clamp(36px,6vw,72px);line-height:1.04;max-width:900px;margin:16px 0 24px}h2{font-size:32px;margin:10px 0}p{line-height:1.65;max-width:870px}small,.subjects{color:#ef91b6}a{color:#91d3df}nav{position:sticky;top:0;background:#151821ed;padding:14px 32px;display:flex;gap:20px;flex-wrap:wrap;z-index:2;border-block:1px solid #343846}nav a{text-decoration:none}section{margin:32px 0 72px;border:1px solid #383c49;border-radius:10px;overflow:hidden;scroll-margin-top:90px}.copy{padding:28px 32px}img{width:100%;height:auto;display:block}.scope{padding:0 32px;color:#b8bdc9}details{padding:20px 32px;border-top:1px solid #383c49}details img{margin-top:20px}summary{cursor:pointer;color:#91d3df}.receipt{padding:20px 24px;border:1px solid #4b5d55;background:#1c2926;border-radius:8px}code{overflow-wrap:anywhere;font-size:0.92em}footer{padding-bottom:70px}
</style><header><small>ENDLESS MUSEUM · BUILT 11 OCTOBER 2026</small><h1>Seven spaces.<br>The same point.</h1><p>The Non-Euclidean hall now opens into seven full-size 3D chambers. These images come from the running Godot museum. Pick up the black point, step through the pink-topped doorway, and follow the controls from changed connections to curved geometry.</p><p><strong>Try it:</strong> reload NonEuclidean_Spaces, or open <code>commons/artifacts/noneuclidean_wing/museum.tscn</code> in Godot and run the current scene. Next, Previous, Museum and Recall point sit on each left-hand console.</p><img src="entry.png" alt="Installed stencil doorway in the existing museum hall"><p class="receipt">COUNTS</p><p><a href="BUILD-NOTES.md">Build notes and controls</a> · <a href="manifest.json">Evidence and source hashes</a> · <a href="../2026-10-11-noneuclid-deeper-spaces/index.html">Research behind the build</a></p></header><nav>NAV</nav><main>CARDS</main><footer><h2>What this build establishes</h2><p>The actual map loads the chambers; the walker crosses the doorway; the carried point remains the same instance; the floor supports arrivals; the trigger and metric operations run. Native pixel checks verify portal visibility and foreground occlusion. Each chamber has a real museum capture.</p><p>The two immersive curved chambers use a metric renderer around an ordinary physical deck. Their surrounding architecture has no hyperbolic collision solver. Physical headset stereo, comfort and Quest performance still need a device run. The original plane/sphere tutorial remains unchanged; this is an installed spatial extension, not a claim that its expanded tutorial has already passed a fresh ghost student.</p><p><a href="evidence/seven-spaces/report.json">Compatibility assertions</a> · <a href="evidence/seven-spaces-mobile/report.json">Mobile assertions</a></p></footer></html>'''
page=page.replace('COUNTS',totals).replace('NAV',''.join(f'<a href="#space-{i}">{i:02}</a>' for i in range(1,8))).replace('CARDS',''.join(cards))
(OUT/'index.html').write_text(page,encoding='utf-8')
print(OUT/'index.html')
print(totals)
