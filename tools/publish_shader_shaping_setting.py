"""Publish the native first-hall captures and their evidence without changing runtime."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/encounter_pilot/Shader_01_Shaping'
OUT = ROOT / 'doc/book/iterations/2026-10-10-shaping-in-the-museum'
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and all(c['passed'] for c in report['checks'])

views = [
    ('main-wall', 'A mark on a surface', 'Player-height view. One circle mask occupies the large wall and a square receiver on the familiar cube. They share the same material; changing the radius changes both.'),
    ('controls', 'The change is within reach', 'A radius slider, an EDGE button for hard or soft boundaries, and RESET share one bench. The cube stays a cube. The circle changes colour on its front face.'),
    ('graph-wall', 'The graphs remain available', 'The five existing shaping graphs face into the hall from the opposite wall. Full-square display surfaces, raised controls and supported desks give them a clearer place.'),
    ('entrance', 'Entering the room', 'The main mask is visible from the entrance. The centre is open, with room to step back and compare the scale of the same rule.'),
    ('soft-edge', 'A gradual boundary', 'The same installation with a larger radius and soft edge. The drawn boundary changes; the backing and its collision remain.'),
    ('room', 'Across the hall', 'A slightly elevated overview of the working museum. The science screen and dark sphere remain, with the onward passage to Patterns.'),
]
for stem, _, _ in views:
    shutil.copy2(RUN / f'{stem}.png', OUT / f'{stem}.png')
for filename in ['report.json', 'source_manifest.json', 'engine.log']:
    shutil.copy2(RUN / filename, OUT / filename)

sources = [
    'commons/maps/Shader_01_Shaping/map_data.json',
    'algorithms/shaders/book_of_shaders/shader_01_shaping.gd',
    'commons/artifacts/registry/shader_shaping_wall.json',
    'commons/artifacts/shader_shaping_wall/shader_shaping_wall.gd',
    'commons/artifacts/shader_shaping_wall/shader_shaping_wall.tscn',
    'commons/artifacts/shader_shaping_wall/circle_mask.gdshader',
    'tools/probes/shader_shaping_museum.gd',
]
manifest = {'hall': 'Shader_01_Shaping', 'checks_passed': len(report['checks']),
            'scope': report['scope'], 'source_sha256': {}, 'image_sha256': {}}
for rel in sources:
    dest = OUT / 'source' / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / rel, dest)
    manifest['source_sha256'][rel] = hashlib.sha256(dest.read_bytes()).hexdigest()
for stem, _, _ in views:
    manifest['image_sha256'][f'{stem}.png'] = hashlib.sha256((OUT / f'{stem}.png').read_bytes()).hexdigest()
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')

def esc(value):
    return html.escape(str(value), quote=True)

figures = ''.join(f'''<figure id="{stem}"><a href="{stem}.png"><img src="{stem}.png" alt="{esc(title)} — actual Godot museum capture" {'loading="lazy"' if i else ''}></a><figcaption><h2>{esc(title)}</h2><p>{esc(caption)}</p></figcaption></figure>''' for i, (stem, title, caption) in enumerate(views))
checks = ''.join(f'<li>{esc(c["test"])}</li>' for c in report['checks'])
source_links = ''.join(f'<li><a href="source/{p}">{esc(p)}</a></li>' for p in sources)
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Shaping inside Endless Museum</title>
<style>
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#ede9df;color:#24282a;font:18px/1.55 system-ui,sans-serif}a{color:inherit}header,section,footer{max-width:1060px;margin:0 auto;padding:44px 28px}header{padding-top:72px}.eyebrow{font:12px/1.5 system-ui;letter-spacing:.15em;text-transform:uppercase}h1{font:clamp(38px,6vw,72px)/1.03 Georgia,serif;max-width:800px;margin:20px 0}h2{font:29px/1.15 Georgia,serif;margin:0 0 12px}p{max-width:760px}nav{display:flex;gap:18px;flex-wrap:wrap;font-size:14px;margin-top:28px}figure{max-width:1440px;margin:0 auto 56px}figure img{width:100%;height:auto;display:block}figcaption{max-width:1060px;margin:auto;padding:24px 28px}figcaption p{margin:0}.facts{display:grid;grid-template-columns:repeat(3,1fr);gap:30px;border-top:1px solid #bbb4a8}.facts h2{font-size:24px}.facts p{font-size:16px}details{margin-top:26px;font-size:14px}summary{cursor:pointer;font-weight:600}li{margin:7px 0}code{font-size:13px;overflow-wrap:anywhere}.evidence{background:#ded8cc;max-width:none}.inner{max-width:1004px;margin:auto}.badge{display:inline-block;background:#2f4537;color:#fff;padding:7px 12px;font-size:14px}footer{font-size:14px} @media(max-width:650px){.facts{grid-template-columns:1fr;gap:10px}header{padding-top:36px}figure{margin-bottom:20px}}
</style>
<header><div class="eyebrow">Endless Museum · Shaders / hall 1 · 10 October 2026</div><h1>A mark on a surface.</h1><p>The first shader setting is built in <strong>Shader_01_Shaping</strong>. A large graphic wall and a small workbench make one operation visible at two scales. These images come from the actual Godot museum.</p><nav><a href="#main-wall">Main wall</a><a href="#graph-wall">Existing graphs</a><a href="#room">Room view</a><a href="#evidence">Checks and sources</a><a href="../2026-10-10-shaders-in-situ/index.html">Whole sequence proposal</a></nav></header>
'''+figures+'''
<section class="facts"><div><h2>One main encounter</h2><p>Move RADIUS. Compare a hard edge with a soft edge. The wall and cube face share one ShaderMaterial. The boundary is an image, with solid geometry behind it.</p></div><div><h2>A room to compare</h2><p>The map expands from 16 × 10 to 22 × 20 cells. The five graphs stand opposite the large mask, with raised controls and open floor between them. Existing exhibits remain.</p></div><div><h2>The tutorial comes next</h2><p>This is a working museum setting. The proposed reconstruction lesson remains focused on UV coordinates, distance, a uniform and a boundary. The printed tutorial and reflective manuscripts were not changed in this pass.</p></div></section>
<section class="evidence" id="evidence"><div class="inner"><span class="badge">'''+str(len(report['checks']))+''' native checks passed</span><h2 style="margin-top:22px">What was verified</h2><p>Godot 4.6 loaded the hall through the museum and artifact registry. Checks exercised the real slider receiver and button signals, confirmed a shared material, read rendered shader pixels, and sampled floor support and standing clearance along the route.</p><p>Captures use the compatibility renderer with XR disabled. Physical headset interaction and traversal into the next hall remain untested. This is not yet a ghost-student reconstruction test. The engine log contains an ObjectDB cleanup warning at shutdown; no script or shader errors were found.</p><p><a href="report.json">Test results</a> · <a href="engine.log">Engine log</a> · <a href="source_manifest.json">Museum harness manifest</a> · <a href="manifest.json">Source and image hashes</a></p><details><summary>All checks</summary><ol>'''+checks+'''</ol></details><details><summary>Source snapshots</summary><ul>'''+source_links+'''</ul><p>Before: <a href="before/map_data.json">map layout</a> · <a href="before/shader_01_shaping.gd">graph host</a></p></details><details><summary>Reproduce the run</summary><p><code>python -X utf8 tools/run_encounter_probe.py Shader_01_Shaping --sequence shaders --probe tools/probes/shader_shaping_museum.gd --render --no-bridges</code></p></details></div></section><footer>Six native museum views. The elevated view is labelled; the remaining views are at standing eye height. Click an image for its original capture.</footer></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'page': str(OUT / 'index.html'), 'images': len(views), 'checks': len(report['checks'])}))
