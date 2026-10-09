"""Publish the combined vector room with real museum captures and test evidence."""
from pathlib import Path
import hashlib, html, json, shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-vectors-one-room'
def esc(s):return html.escape(str(s))
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def picture(path,caption):
    assert (OUT/path).is_file(),path
    return f'<figure><a href="{path}"><img src="{path}" loading="lazy" alt="{esc(caption)}"></a><figcaption>{esc(caption)}</figcaption></figure>'
plan=read(ROOT/'commons/artifacts/force_halls/curation.json')
reports={name:read(OUT/name/'report.json') for name in ['interaction','layout','teleport']}
assert all(r['passed'] for r in reports.values())
for name in reports:assert 'SCRIPT ERROR' not in (OUT/name/'engine.log').read_text(errors='replace')
# Freeze the source beside the captures, so the report remains reviewable later.
sources=['commons/artifacts/force_halls/point_lesson.gd','commons/artifacts/force_halls/vector_arrow.gd',
 'commons/artifacts/force_halls/lesson_point.gd','commons/artifacts/force_halls/hall_display.gd',
 'commons/artifacts/force_halls/curation.json','commons/maps/Vectors_Act1_WhatAVectorIs/map_data.json',
 'commons/maps/Vectors_Act1_WhatAVectorIs/FORCES_LESSON.md','commons/maps/sequences/forces.json',
 'commons/data/map_authored.json','tools/compact_force_vectors.py','tools/probes/forces_vectors_compact.gd',
 'tools/probes/forces_layout.gd','tools/probes/forces_teleport_buttons.gd','doc/book/course/forces-primary-objects.json']
manifest={}
for path in sources:
    src=ROOT/path;dst=OUT/'sources'/path;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    manifest[path]=hashlib.sha256(src.read_bytes()).hexdigest()
(OUT/'source-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
before=ROOT/'doc/book/iterations/2026-10-07-forces-curated-progression/after'
for map_name,short in [('Vectors_Act1_WhatAVectorIs','direction'),('VFM_02_Operations','addition'),('Vectors_Act2_VectorArithmetic','projection')]:
    src=before/map_name/'entry.png'
    if src.exists():shutil.copy2(src,OUT/('before-'+short+'.png'))
checks=''.join(f'<li><a href="{name}/report.json">{esc(name)}: {len(r["checks"])} / {len(r["checks"])} passed</a></li>' for name,r in reports.items())
route=' → '.join(esc(r['title']) for r in plan['halls'])
page=['''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Vectors in your hands · Endless Museum</title>
<style>
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#22252a;font:18px/1.6 system-ui,sans-serif}
header,main,footer{max-width:1240px;margin:auto;padding:40px 30px}header{padding-top:70px}h1{font-size:clamp(42px,6vw,76px);line-height:1.02;max-width:850px;margin:18px 0 25px;font-weight:650;letter-spacing:-.045em}
h2{font-size:32px;letter-spacing:-.025em}p{max-width:850px}a{color:#84445f;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:12px;margin-top:32px}nav a{padding:8px 17px;background:#fff9;border-radius:30px;text-decoration:none}
.kicker{font-size:13px;letter-spacing:.12em;text-transform:uppercase}.deck{font-size:23px}.stats{display:flex;gap:12px;flex-wrap:wrap}.stats span{background:#ddd5ca;border-radius:5px;padding:8px 13px}
section{margin-bottom:70px;padding-top:12px;border-top:1px solid #ccc4b6}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}
figure{margin:24px 0}img{display:block;width:100%;border-radius:7px}figcaption{font-size:14px;line-height:1.45;color:#59555a;margin-top:10px}
article{background:#f9f6ee;padding:25px;border-left:3px solid #b77491;margin:22px 0}article p{margin-bottom:0}
code{background:#ddd8d0;padding:2px 5px;font-size:.85em}.route{font-size:15px}.note{font-size:15px;color:#5f575b}
@media(max-width:750px){.grid{grid-template-columns:1fr}header,main,footer{padding:25px 18px}}
</style><header><div class="kicker">Endless Museum · 7 October 2026 · Implemented</div><h1>Vectors in your hands.</h1>
<p class="deck">One room. Three operations. Four familiar black points. Move a ball and read the mathematics where it happens.</p>
<div class="stats"><span>3 halls → 1</span><span>9 exhibits → 3 point stations</span><span>11 Forces halls in the route</span></div>
<nav><a href="#museum">Inside the museum</a><a href="#stations">The three stations</a><a href="#before">Before / after</a><a href="#test">Verification</a></nav></header><main><section id="museum"><h2>The same point, three readings</h2>
<p>Direction and length, addition, then projection now share the first Forces hall. The next passage and NEXT button take you straight to Launch. Reset sits beside each experiment; the hands do the rest.</p>''']
page.append(picture('layout/entry.png','Actual museum, eye-height view. Direction, addition and projection share one open room.'))
page.append('<details><summary>See the arrangement from above</summary>'+picture('layout/above.png','The elevated camera shows the three station footprints and the clear walk to the exit.')+'</details></section><section id="stations"><h2>Move the point. Keep the relation.</h2>')
descriptions=[
('direction','01 / Direction + length','Move the black PointBody relative to O. The label follows it with local X, Y, Z and length in metres. The rose cylinder displays a unit direction at a separate origin; its components are dimensionless. At zero displacement the arrows disappear and the label says that direction is undefined.'),
('addition','02 / Two moves, one arrival','Move either black point. The blue-gray copy of b begins at the tip of a, while the rose cylinder reaches directly to a+b. Both input triples and the sum are live. The direct distance is displayed separately from the length of the two-part route.'),
('projection','03 / What the rail keeps','The X rail has half-metre ticks. The rose component keeps its sign, including behind the origin. The blue-gray cylinder connects the projection to the held point: this is the perpendicular remainder. Their sum recovers the original displacement.')]
for name,title,words in descriptions:
    page.append(f'<article><h2>{esc(title)}</h2><p>{esc(words)}</p></article>'+picture('interaction/'+name+'.png','Actual '+name+' station. The direction shafts are thin CylinderMeshes, not line primitives.'))
page.append('<h2>One point, another position</h2><div class="grid">'+picture('interaction/direction.png','Starting displacement: (+0.90, +0.48, +0.60) m; length about 1.18 m.')+picture('interaction/direction-moved.png','After moving the same ball: (−0.55, +0.75, +0.35) m; length about 0.99 m. The labels and rods update.')+'</div></section>')
page.append('<section id="before"><h2>What was brought together</h2><p>The three former rooms each combined one new point lesson with two older comparison machines. This version retains only the three point lessons. The comparison artifacts and your Keep selections remain in the collection.</p><div class="grid">')
for name in ['direction','addition','projection']:
    if (OUT/('before-'+name+'.png')).exists():page.append(picture('before-'+name+'.png','Before: '+name+' occupied a separate room with comparison machines.'))
page.append(picture('layout/entry.png','After: the point stations together, with live annotations and solid direction cylinders.')+'</div><p>Borrowed visual ideas: head-to-tail construction from the Adder’s Drafting Board; measurement marks from the magnitude studies; signed alignment from the dot-product studies. Their separate mechanisms are not placed in this room.</p><p class="route">'+route+'</p></section>')
page.append('<section id="test"><h2>Checked in Godot</h2><ul>'+checks+'</ul><p>Checks cover numeric results, a zero vector, cancellation, negative projection, moving labels, cylinder orientation, actual desktop and XRTools grab/release, safe reset while held, the museum floor, and teleport travel through all eleven halls.</p><p class="note">These use supplied desktop and XRTools inputs in the real museum. Physical headset readability and hand reach remain for your VR review. The full tutorial and final manuscripts have not been rewritten by this room edit; the lesson contract and route plan now describe the combined room.</p><p><a href="sources/commons/maps/Vectors_Act1_WhatAVectorIs/FORCES_LESSON.md">Lesson contract</a> · <a href="sources/commons/artifacts/force_halls/point_lesson.gd">Point lesson code</a> · <a href="sources/commons/artifacts/force_halls/vector_arrow.gd">Cylinder arrow code</a> · <a href="source-manifest.json">Source hashes</a></p></section></main><footer>ENDLESS MUSEUM<br>always another room</footer></html>')
(OUT/'index.html').write_text(''.join(page),encoding='utf8')
print(OUT/'index.html')
