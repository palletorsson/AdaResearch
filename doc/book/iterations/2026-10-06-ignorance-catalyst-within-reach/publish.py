from pathlib import Path
import hashlib
import html
import json
import shutil
import difflib

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/Primitives_Ignorance'
report = json.loads((RUN / 'report.json').read_text())
assert report['passed'] and not report['failures']
for name in ['catalyst-in-the-court.png', 'catalyst-within-reach.png',
             'held-low-resolution.png', 'report.json', 'source_manifest.json', 'stdout.log']:
    shutil.copy2(RUN / name, OUT / name)
paths = ['commons/artifacts/ignorance_gallery/form_in_hand.gd',
         'commons/artifacts/ignorance_gallery/resolution_catalyst.gd',
         'commons/artifacts/ignorance_gallery/resolution_point.gd',
         'commons/maps/Primitives_Ignorance/map_data.json',
         'tools/probes/ignorance_catalyst_placement.gd']
(OUT / 'source-hashes.json').write_text(json.dumps({
    p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths
}, indent=2), encoding='utf-8')
before = (OUT / 'before/form_in_hand.gd').read_text(encoding='utf-8').splitlines(True)
after = (ROOT / paths[0]).read_text(encoding='utf-8').splitlines(True)
(OUT / 'placement.diff').write_text(''.join(difflib.unified_diff(before, after,
    fromfile='before/form_in_hand.gd', tofile=paths[0])), encoding='utf-8')
count = len(report['checks'])
notes = f'''# The point within reach

The existing resolution catalyst now hangs near the approach to the final court in Primitives Ignorance. It was already installed but sat against a side wall, with instructions on the opposite wall. Its point, guide and live counts now share a slim stand. The sphere is 0.28 m across, with its centre 1.45 m above the floor. The through-routes and the torus shadow field remain open.

Hold the point: rings/segments reduce from 16/32 to the valid minimum 1/4, keeping its physical size. Trigger sends an independent copy of the current form. Release returns it after two seconds and restores the starting counts. These existing behaviours were preserved, not reimplemented. Only the display arrangement changed.

The installation remains form_in_hand at map cell (9,35); no duplicate artifact was added. Map inventory and intent now identify the current installation. Tutorial and final text were not changed.

{count} native Godot checks passed in the real Endless Museum, including clear front access, nearby instructions, actual XR Tools pickup with a synthetic hand, held simplification, projectile collision/dispatch, bounded projectile count, automatic return, desktop hooks, and two body-width passage routes. The inherited moon-torus checks also pass. Images are native museum captures. Headset comfort and controller-button mapping still require a VR playtest; this probe supplies the action event.

Rerun: python -X utf8 tools/run_encounter_probe.py Primitives_Ignorance --sequence primitives --render --probe tools/probes/ignorance_catalyst_placement.gd

The probe uses an isolated copy of the museum runtime and does not change the live em_control.json. Re-enter/reload Primitives Ignorance to load the revised arrangement.
'''
(OUT / 'REPORT.md').write_text(notes, encoding='utf-8')
def figure(src, caption):
    return f'<figure><a href="{src}"><img src="{src}" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The point within reach</title><style>
*{box-sizing:border-box}body{margin:0;background:#eeeae2;color:#252523;font:18px/1.6 Georgia,serif}main{max-width:1300px;margin:auto;padding:46px 5vw}h1{font-size:clamp(38px,6vw,78px);font-weight:400;line-height:1.06}h2{font-size:30px;font-weight:400;margin-top:48px}p{max-width:790px}small,figcaption,nav{font:14px/1.6 system-ui}nav{display:flex;gap:22px;flex-wrap:wrap}figure{margin:22px 0}img{width:100%;display:block}figcaption{padding-top:8px;color:#555}a{color:inherit}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.facts{border-block:1px solid #b1ada2;padding:20px 0}@media(max-width:700px){.pair{grid-template-columns:1fr}main{padding:24px}}
</style><main><small>ENDLESS MUSEUM · PRIMITIVES IGNORANCE · 6 OCTOBER 2026</small><h1>The point within reach.</h1><p>The black sphere hangs near the entrance to the final moon court. Its instructions and live counts now sit beside it.</p><nav><a href="#museum">In the museum</a><a href="#change">Before / after</a><a href="REPORT.md">Notes</a><a href="report.json">Native checks</a></nav><section id="museum">'''
page += figure('catalyst-within-reach.png', 'The actual museum: the familiar black point, at 1.45 m, with its own guide and ring/segment readout.')
page += '<p class="facts"><b>Hold</b> to reduce rings and segments. <b>Trigger</b> to send the current form. <b>Release</b> to return and reset after two seconds.</p>'
page += figure('catalyst-in-the-court.png', 'Near the approach, beside the moon torus and outside the central passage.')
page += '<h2 id="change">The instructions travel with the point.</h2><div class="pair">'
page += figure('before/moon-court.png', 'Before: the point at the far side; its instructions on the opposite wall. Earlier camera position.')
page += figure('catalyst-in-the-court.png', 'After: point and guide together, closer to the approach. Different camera position.')
page += '</div><h2>Fewer divisions; the same size.</h2>'
page += figure('held-low-resolution.png', 'Controlled pickup in the real scene: 1 ring and 4 segments. The collider and radius remain unchanged.')
page += f'<h2>{count} native checks passed.</h2><p>Pickup, simplification, firing, return, approach clearance and the existing torus were exercised in Godot. Headset feel and physical trigger mapping remain for a VR playtest.</p><p>Re-enter Primitives Ignorance to load the updated arrangement.</p></section></main></html>'
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(f'Published {count} checks at {OUT}')
