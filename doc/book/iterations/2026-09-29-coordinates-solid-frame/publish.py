"""Publish native evidence of the hall-specific coordinate frame treatment."""
from pathlib import Path
import difflib, hashlib, json, shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
run = ROOT / 'ada_run/encounter_pilot/Point_Coordinates'
report = json.loads((run / 'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and len(report['checks']) == 30
for name in ['solid-frame.png', 'coordinates-basin.png', 'coordinate-arrival.png', 'report.json', 'source_manifest.json']:
    shutil.copy2(run / name, OUT / name)
sources = [ROOT / 'algorithms/vectors/00_coordinates/CoordinateSystem3M.gd']
sources += [ROOT / 'commons/maps/Point_Coordinates' / n for n in ['map_data.json', 'final.md', 'technical.md']]
manifest = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
(OUT / 'source-versions.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
for p in sources:
    shutil.copy2(p, OUT / p.name)
    before = OUT / 'before' / p.name
    if before.exists():
        diff = ''.join(difflib.unified_diff(before.read_text(encoding='utf-8-sig').splitlines(True), p.read_text(encoding='utf-8-sig').splitlines(True), fromfile='before/'+p.name, tofile='after/'+p.name))
        (OUT / (p.name+'.diff')).write_text(diff, encoding='utf-8')
decisions = '''# A coordinate frame with a body

29 September 2026. Author asks for a larger, solid coordinate system and proposes pink, grey and black.

- Applied only to Point_Coordinates through map parameters: X pink, Y grey, Z near-black; fully opaque, shaded rods and matching moving markers.
- Shafts extend from 4.5 m to 5.1 m. Diameter increases from 15 cm to 24 cm. The frame's display scale stays 1.5, so this larger drawing does not change LOCAL readings.
- Kept the origin at floor level and the original eleven-cell L basin. Kept both cards, the named held point, target and secondary works.
- Restored axis letters. The existing Z arm physically runs towards negative Z; its label now follows that arm and reads −Z. Colours identify components, independently of sign. The shared label-placement correction also applies when other frames show labels; their default RGB palette, translucent rods and arm directions remain unchanged.
- Solid means opaque meshes here. No new collision barrier was added across the basin.
- Updated the colour sentence in final.md and implementation reference. The separate desktop tutorial kit still has its own conventional RGB guides.

Validation: 30 native museum checks passed. Includes production pickup and release, both live readouts, target activation, basin collision and height, opaque shaded materials, axis/marker palette, correct negative-Z label, unchanged default palette and transparency. Rendered images inspected. No headset or learner trial.
'''
(OUT/'DECISIONS.md').write_text(decisions, encoding='utf-8')
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Coordinates · A frame with a body</title><style>
*{box-sizing:border-box}body{margin:0;background:#f2efe9;color:#25252a;font:19px/1.7 Georgia,serif}main{max-width:1280px;margin:auto;padding:50px 32px}h1{font-weight:400;font-size:clamp(38px,5vw,72px);line-height:1.1;letter-spacing:-.03em}h2{font-size:30px;font-weight:400}.intro{font-size:24px;max-width:850px}.small,figcaption,nav,.key{font:14px/1.6 system-ui,sans-serif;color:#56525c}a{color:#67415b;text-underline-offset:4px}nav{display:flex;gap:25px;flex-wrap:wrap}img{width:100%;display:block}figure{margin:30px 0}figcaption{margin-top:10px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.key{display:flex;gap:26px;margin:28px 0;font-size:17px}.swatch{display:inline-block;width:22px;height:22px;vertical-align:middle;margin-right:8px;border-radius:50%}.note{max-width:780px;margin:45px auto}footer{border-top:1px solid #c9c2c7;padding-top:25px}@media(max-width:750px){main{padding:25px 16px}.pair{grid-template-columns:1fr}.intro{font-size:21px}}
</style><main><p class="small">ADA RESEARCH · POINT COORDINATES · 29 SEPTEMBER 2026</p><h1>A coordinate frame<br>with a body.</h1><p class="intro">Pink, grey and black. Longer arms, thicker rods, and light catching a solid surface. The drawing becomes larger; the point keeps the same two addresses.</p><nav><a href="#museum">Inside the museum</a><a href="#comparison">Before / after</a><a href="/compose/sources?map=Point_Coordinates&amp;doc=final">Current text</a><a href="DECISIONS.md">Decisions</a></nav>
<section id="museum"><div class="key"><span><i class="swatch" style="background:#d76c9f"></i>X</span><span><i class="swatch" style="background:#96969d"></i>Y</span><span><i class="swatch" style="background:#202127"></i>Z</span></div><figure><a href="solid-frame.png"><img src="solid-frame.png" alt="Opaque pink, grey and black coordinate axes in the museum's L-shaped basin."></a><figcaption>Actual Godot museum capture. The grey axis rises from the origin; the black arm follows negative Z along the basin.</figcaption></figure></section>
<section id="comparison"><h2>The same basin, a clearer frame.</h2><div class="pair"><figure><img src="before/coordinates-basin.png" alt="Earlier translucent red, green and blue frame."><figcaption>Before: translucent RGB, 4.5 m shafts, 15 cm diameter.</figcaption></figure><figure><img src="coordinates-basin.png" alt="Larger opaque pink, grey and black frame."><figcaption>After: opaque shaded surfaces, 5.1 m shafts, 24 cm diameter.</figcaption></figure></div></section>
<div class="note"><p>The palette is a choice made for this room. Letters name the axes; colour helps us follow them. The black arm is marked −Z because that is the direction it actually points.</p><p>WORLD and LOCAL still follow the same held point. Extending the rods has not changed the coordinate scale. The basin's glass stays level with the museum floor.</p><p class="small">Solid here means opaque rather than transparent. The axes do not add a new physical barrier across the floor.</p></div>
<footer class="small"><p>30 native checks passed; no headset trial. <a href="report.json">Runtime checks</a> · <a href="source-versions.json">Source versions</a> · <a href="final.md.diff">Text change</a> · <a href="../2026-09-29-point-and-coordinates/index.html#museum">Point One and Coordinates</a></p></footer></main></html>'''
(OUT/'index.html').write_text(page, encoding='utf-8')
print('Published coordinate frame review with 30 passing native checks.')
