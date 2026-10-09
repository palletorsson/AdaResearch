from pathlib import Path
import hashlib
import html
import json
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/Primitives_Ignorance'
report = json.loads((RUN / 'report.json').read_text())
assert report['passed'], report['failures']
for name in ['court', 'capsule', 'hanging-point', 'rings-and-segments', 'held-low-resolution']:
    shutil.copy2(RUN / (name + '.png'), OUT / (name + '.png'))
for name in ['report.json', 'source_manifest.json', 'stdout.log']:
    shutil.copy2(RUN / name, OUT / name)
sources = list((ROOT / 'commons/artifacts/ignorance_gallery').glob('*.gd'))
sources += [ROOT / p for p in [
    'commons/maps/Primitives_Ignorance/map_data.json',
    'commons/maps/Primitives_Ignorance/final.md',
    'commons/maps/Primitives_Ignorance/tutorial.md',
    'commons/artifacts/registry/commons_artifacts.json',
    'tools/probes/ignorance_form_in_hand.gd',
    'commons/rendering/museum_grayscale.gd']]
(OUT / 'changed-source-hashes.json').write_text(json.dumps({str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}, indent=2))
count = len(report['checks'])
notes = f'''# Ignorance — a form in the hand

The reference image becomes an arrangement in the actual Endless Museum: pale ground and overhead surfaces, column bases and capitals, black and white exhibits, and the existing five-sided capsule shown with flat faces beside a pentagonal profile. The five solids, resolution atlas, plain/wire pairs and count controls stay in place. The older studies keep their side alcove.

The new final bay contains a suspended, shiny black point and two white spheres that distinguish rings from radial segments. The point hangs at 1.45 m. Holding it reduces each mesh count once per 0.15 seconds, stopping at one ring and four radial segments. Radius and spherical collision stay unchanged. Trigger sends a copy of the mesh at that instant, at 6 m/s. Each copy has its own resource, a four-second flight lifetime and the existing primitives catalyst hit protocol. At most eight forms remain active. Release pauses the changes; after two seconds the point returns to its suspension and resets.

This is a local first-catalyst encounter. It does not yet grant a persistent inventory slot or unlock a global catalyst mode. Headset comfort, aim and Quest performance still need a VR playtest.

## Lineage

PointBody → held resolution → a form that can act. The production point reuses runtime copies of the tested learner PointBody and ResolutionPoint, then adds museum presentation, return behavior and the existing catalyst projectile class. The tutorial's generator lesson keeps its agreed focus; a short context note identifies this as a preview of Primitives_Godot. No executable tutorial block changed. The reflective text now follows the point from inspection to action.

## Verification

{count} native checks passed in the real museum: actual XRTools pickup movement, legal mesh limits, unchanged collider/radius, independent shot meshes, launch clearance and velocity, real physics collision with a catalyst receiver, cooldown, bounded live shots, expiry, return/reset, desktop hooks, equal paired meshes, and two body-width routes beside the station. Trigger events were supplied by the probe; this is not a headset acceptance result. One pre-existing unknown resource UID warning remains in the engine log.

Map comparison confirms exactly one added artifact at cell (9,35), with all prior placements and structural room connections preserved. Images are native Godot captures from inside the museum. Before/after court and capsule views use matching cameras; the capsule continues to rotate, so its pose varies.

Run again: `python -X utf8 tools/run_encounter_probe.py Primitives_Ignorance --sequence primitives --render --probe tools/probes/ignorance_form_in_hand.gd`
'''
(OUT / 'REPORT.md').write_text(notes, encoding='utf-8')

def figure(src, caption):
    return f'<figure><a href="{src}"><img loading="lazy" src="{src}" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ignorance — a form in the hand</title><style>
*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#20201e;font-family:Georgia,serif;line-height:1.6}header,main,footer{max-width:1300px;margin:auto;padding:38px 5vw}header{padding-bottom:12px}h1{font-size:clamp(38px,6vw,82px);font-weight:400;line-height:1.05;margin:18px 0}h2{font-size:32px;font-weight:400;margin:50px 0 12px}.eyebrow,nav,figcaption,small{font:13px/1.6 system-ui,sans-serif}.eyebrow{letter-spacing:.14em;text-transform:uppercase}p{max-width:760px;font-size:19px}a{color:inherit}nav{display:flex;gap:24px;flex-wrap:wrap;margin:25px 0}figure{margin:16px 0}img{display:block;width:100%;border:1px solid #c9c4b8}figcaption{padding:9px 0;color:#59574f}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.steps{border-top:1px solid #aaa393;border-bottom:1px solid #aaa393;padding:18px 0;font:16px/1.8 system-ui}blockquote{font-size:25px;border-left:2px solid #565347;padding:10px 24px;margin:36px 0;max-width:900px}details{font:14px/1.7 system-ui;margin:30px 0}footer{font:14px/1.7 system-ui;border-top:1px solid #c0b9a9}@media(max-width:700px){.pair{grid-template-columns:1fr}header,main,footer{padding:24px}p{font-size:18px}}
</style><header><div class="eyebrow">Endless Museum · Primitives Ignorance · 6 October 2026</div><h1>A form in the hand.</h1><p>The comic becomes a room: a quieter field for comparing geometry, and a point whose changing form becomes something you can use.</p><nav><a href="#museum">The hanging point</a><a href="#compare">Before / after</a><a href="#reading">The text</a><a href="#checks">What passed</a></nav></header><main id="museum">'''
page += figure('hanging-point.png', 'The new suspended point, between two directions of the same sphere mesh. Real museum capture.')
page += '<div class="steps"><b>Grip:</b> fewer rings and segments. &nbsp; <b>Trigger:</b> send this form. &nbsp; <b>Release:</b> return and reset after two seconds.</div><p>The original point stays in your hand when a copy leaves it. Every shot keeps its own construction, even as the held point continues to change.</p>'
page += figure('held-low-resolution.png', 'The same point at one ring and four segments. Its visible silhouette changes; radius and spherical collider remain fixed.')
page += '<h2 id="compare">Give the comparisons room.</h2><p>Pale surfaces and a simple column order establish a common setting for the five solids. The capsule keeps its five-by-five construction; flat faces make its corners explicit. Its stepped support and the pentagonal diagram show different aspects of the same question.</p><div class="pair">'
page += figure('before/court.png', 'Before · the geometry court.') + figure('court.png', 'After · a pale court and articulated columns.') + '</div><div class="pair">'
page += figure('before/capsule.png', 'Before · the capsule and stepped support.') + figure('capsule.png', 'After · flat faces, the existing eight tiers, and a pentagonal profile.') + '</div>'
page += '<h2 id="reading">From inspection to action.</h2><blockquote>A black point hangs within reach. Take it. As you hold it, the rings and segments decrease; corners emerge where the surface seemed continuous. Its radius stays the same. The hand that examined the form now changes the terms of its construction.</blockquote><p>The reflective text follows this change. The tutorial keeps its generator lesson and marks the hanging point as a preview of the next hall’s resolution study.</p>'
page += f'<h2 id="checks">{count} native checks passed.</h2><p>Pickup, simplification, mesh independence, launch, real collider impact, cooldown, expiry, return and clear routes were tested in Godot. This is a first catalyst within the hall; it does not yet grant a persistent inventory upgrade. Headset comfort and Quest performance remain to be checked.</p><details><summary>Read the checks</summary><ul>'
page += ''.join('<li>'+html.escape(c['name'])+'</li>' for c in report['checks'])
page += '</ul></details><p><a href="REPORT.md">Implementation and lineage notes</a> · <a href="report.json">Native test results</a></p></main><footer>Images rendered from the actual Endless Museum. The comic is the visual reference, not the evidence.</footer></html>'
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(f'Published {OUT}; {count} checks.')
