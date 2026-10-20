from pathlib import Path
import json, shutil, hashlib, html
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
RUN=ROOT/'ada_run/encounter_pilot/Random_Entropy/plinth-physical-ruin'
BEFORE=ROOT/'ada_run/encounter_pilot/Random_Entropy/plinth-ruin-before'
for name in ['jars-plinth','jar-detail','ruin-intact','column-corrected','ruin-pulling','ruin-fallen']:
    shutil.copy2(RUN/(name+'.png'),HERE/(name+'.png'))
for name in ['jars-before','column-before']:
    shutil.copy2(BEFORE/(name+'.png'),HERE/(name+'.png'))
shutil.copy2(RUN/'report.json',HERE/'museum-report.json')
model=json.loads((HERE/'verification.json').read_text(encoding='utf8'))
room=json.loads((HERE/'museum-report.json').read_text(encoding='utf8'))
legacy=json.loads((HERE/'legacy-verification.json').read_text(encoding='utf8'))
assert model['passed'] and room['passed'] and not legacy['failures']
style='''*{box-sizing:border-box}body{margin:0;background:#eeeae4;color:#2d3039;font:17px/1.6 system-ui}main{max-width:1460px;margin:auto;padding:24px}h1{font:40px/1.15 Georgia,serif;margin:0 0 12px}h2{font:28px/1.2 Georgia,serif;margin-top:38px}p{max-width:86ch}a{color:#66527b}figure{margin:0}img{width:100%;display:block}figcaption{padding:12px 16px;background:#e0d9e1;font-size:15px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}.hero img{max-height:72vh;object-fit:contain;background:#303748}fieldset{border:0;padding:0}input{accent-color:#806496}label{display:inline-block;padding:6px 16px;margin:8px 20px 15px 4px;border:1px solid #a393aa;cursor:pointer}input:checked+label{background:#66527b;color:white}.frames figure{display:none}#intact:checked~.frames .intact,#pulling:checked~.frames .pulling,#fallen:checked~.frames .fallen{display:block}.frames img{max-height:72vh;object-fit:contain;background:#303748}nav{display:flex;gap:18px;flex-wrap:wrap;margin:25px 0}details{margin-top:18px}summary{cursor:pointer}pre{white-space:pre-wrap;font:16px/1.65 system-ui}.status{padding:12px 18px;border-left:4px solid #857096;background:#e4dce7}@media(max-width:800px){main{padding:15px}.pair{grid-template-columns:1fr}h1{font-size:32px}}'''
body='''<h1>Larger jars. One stone removed.</h1><p>Entropy Workshop now gives the four slow mixtures a shared plinth. At the ruin, a support can leave the stack and let the other stones fall through contact and gravity.</p><figure class="hero"><img src="jars-plinth.png" alt="Four large lavender and coral jars on a shared pale plinth"><figcaption>Four 1.04 m wide, 2.30 m tall glass bodies on a 0.4 m shared plinth. Rounded shoulders, pale lids and metal collars; the slow seeded paths and lavender/coral palette are retained.</figcaption></figure><p>The larger display sits left of the entrance, with clear floor at each viewing position. The beginnings are named on the plinth; PAUSE and RESTART stay on the side panel. Reload <strong>Random_Entropy</strong> to visit.</p><h2>Remove one support</h2><p><strong>ONE STONE</strong> pulls out a supporting drum, then releases it. The other stones have no prescribed landing places. A VR grip or desktop carry can make the intervention directly. <strong>RUN / PAUSE</strong> starts or stops automatic selection; gravity stays on. <strong>RESTORE</strong> rebuilds the starting arrangement after held stones are released.</p><fieldset><legend>Native views from the same camera</legend>'''
for key,title in [('intact','Before'),('pulling','Pulling one support'),('fallen','After release')]:
    body+=f'<input type="radio" name="ruin" id="{key}" {"checked" if key=="intact" else ""}><label for="{key}">{title}</label>'
body+='<div class="frames">'
for key,caption in [('intact','116 stones. The lowest two courses remain anchored; 84 stones are loose.'),('pulling','The selected support is being drawn out. Gravity already acts on its neighbours.'),('fallen','One selected removal can move several unselected stones. The inventory remains 116.')]:
    body+=f'<figure class="{key}"><img src="ruin-{key}.png" alt="{caption}"><figcaption>{caption}</figcaption></figure>'
body+='''</div></fieldset><p>RESTORE repeats the arrangement and selection seed 79. A seed alone does not preserve a physics landing. This is loose masonry, with no mortar, fracture, or thermodynamic entropy calculation.</p><h2>The column faces were reversed</h2><div class="pair"><figure><img src="column-before.png" alt="Before: inward-facing fluted drum surfaces"><figcaption>Before: inward faces exposed the backs of the drums.</figcaption></figure><figure><img src="column-corrected.png" alt="After: outward-facing flutes and end caps"><figcaption>After: outward faces, separate flute normals, solid end caps. The corrected mesh also supplies the collision hull.</figcaption></figure></div><h2>What the checks establish</h2>'''
body+=f'<p class="status">{len(model["checks"])} apparatus checks and {len(room["checks"])} installed-room checks pass. The inherited museum weathering model retains {legacy["checks"]} passing checks.</p>'
body+='''<p>The removed drum falls, an unselected upper drum descends, reset rebuilds the stack, and both supplied XRTools and desktop pickup respect held objects. The larger jars retain their previous slow coordinates and have clear supported approaches. Physical headset comfort and visitor interpretation still need a visit.</p><p>The next question is small: before removing a drum, which other stones seem likely to move? Compare the prediction with the PULLED and MOVED counts. A stack that stays standing is evidence too.</p>'''
for name in ['final.md','tutorial.md','plan.md']:
    text=(ROOT/'commons/maps/Random_Entropy'/name).read_text(encoding='utf8')
    (HERE/name).write_text(text,encoding='utf8')
    body+=f'<details><summary>Updated {name}</summary><pre>{html.escape(text)}</pre></details>'
body+='''<details><summary>Previous jar placement</summary><img src="jars-before.png" alt="Earlier narrow columns intersecting the neighbouring enclosure from this viewpoint"><p>The smaller columns were in the crowded centre of the entrance chamber. The new plinth and side panel sit to its left.</p></details><nav><a href="verification.json">Apparatus checks</a><a href="museum-report.json">Installed-room checks</a><a href="README.md">Implementation record</a><a href="/long-museum/writing-wall?map=Random_Entropy">Writing wall</a><a href="../2026-10-16-slow-lavender-columns/index.html">Earlier slow mixing record</a></nav>'''
(HERE/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Larger jars and a physical ruin · Ada Research</title><style>'+style+'</style><main>'+body+'</main></html>',encoding='utf8')
sources=['commons/artifacts/ordinary_entropies/'+n for n in ['jar_column.gd','jar_states.gd','column_mixing.gd']]+['commons/artifacts/randomness_space/'+n for n in ['entropy_ruin.gd','entropy_ruin_physics.gd','ruin_stone.gd','entropy_ruin.tscn']]+['commons/maps/Random_Entropy/'+n for n in ['map_data.json','final.md','tutorial.md','writing_wall.json','plan.md']]+['commons/testing/probe_entropy_ruin.gd','commons/testing/probe_entropy_weathering_base.gd']
(HERE/'manifest.json').write_text(json.dumps({'checks':{'apparatus':len(model['checks']),'room':len(room['checks']),'legacy':legacy['checks']},'sha256':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}},indent=2),encoding='utf8')
(HERE/'README.md').write_text('''# Larger jars and a physical ruin

Requested 16 October: larger, nicer jars on a plinth; remove and drop a ruin stone so the others fall; investigate the strange column faces.

## Result

Four glass bodies now have radius 0.52 m and height 2.30 m, starting at y0.46 over a shared 5.8 m plinth. Their shoulders are rounded, with clear single outward-facing skins, ceramic-coloured lids, metal collars and larger round beads. Labels sit on the plinth. Source coordinates, seeds and 0.48-second step interval are unchanged; the earlier three-minute coordinates match exactly. The view scales the same paths. The bank moved from the current centre placement (8,2) to clear floor at (4,2); the map-derived museum row is synchronized. The hand-sized shakeable jar remains separate.

The fluted drum triangles were inward: native normal/radial dot −0.816. Reversed winding and flat flute/cap normals repair the mesh. The glass shell also passes winding/normal agreement checks.

The installed ruin scene now loads entropy_ruin_physics.gd. It reuses the architectural builder but creates 116 XRTools rigid bodies, including 32 fixed foundation stones and 84 loose stones. Convex drum hulls and box masonry use friction 0.72, zero bounce, gravity and contact. ONE STONE draws a support out over 0.9 s, then releases it; automatic selection waits 4.5 s between completed extractions. Pausing selection does not freeze bodies. VR and desktop pickup share ownership signals and block reset while held. Static reset avoids imparting kinematic teleport velocities. RESTORE repeats the start and selection seed, not a saved physical trajectory. No persistent save/replay is added.

The separate em_weathering_wall.gd still inherits the authored top-course model. Its legacy regression is retained under probe_entropy_weathering_base.gd. That wall does not silently acquire the new contact model.

## Evidence

33 apparatus checks, 28 installed-room checks, and 458 retained staged-model checks pass. In the isolated physical trial, the unselected next drum descends from about 1.38 m to 0.34 m after its support is removed. Installed ONE STONE/RESTORE, supplied XRTools hand, desktop carry, all four jar approaches, and native captures are checked. Map pathfinding passes with the existing end-teleport-height warning. The museum also logs its pre-existing blocked authored entry/fallback warning from the neighbouring point enclosure, present before this revision. The relocated jar approaches are clear. Headset comfort, device performance and human interpretation remain untested.

Run `python doc/book/iterations/2026-10-16-plinth-and-physical-ruin/run.py`, then `python tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag plinth-physical-ruin --probe doc/book/iterations/2026-10-16-plinth-and-physical-ruin/museum_probe.gd`, then publish.py. The standalone physical regression is commons/testing/probe_entropy_ruin.gd. Legacy model check: Godot --headless --script res://commons/testing/probe_entropy_weathering_base.gd -- --no-bridges.

Current final, tutorial, plan, registry and writing-wall notes follow these changes. The 48-value bench remains the first research pilot. No commit or push is part of this request.
''',encoding='utf8')
print('Published larger jars and physical ruin: 33 + 28 checks, 458 legacy checks.')
