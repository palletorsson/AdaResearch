"""Publish the native museum evidence after the integration probe passes."""
from pathlib import Path
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/encounter_pilot/ProceduralGeneration_Reaction_Diffusion_Systems'
OUT = ROOT / 'doc/book/iterations/2026-10-15-rd-gallery-in-museum'


def main():
    result = json.loads((RUN / 'rd-gallery-after/report.json').read_text(encoding='utf-8'))
    assert result['passed'], result['failures']
    manifest = json.loads((ROOT / 'commons/artifacts/rd_museum_gallery/manifest.json').read_text(encoding='utf-8'))
    OUT.mkdir(parents=True, exist_ok=True)
    for source, name in [
        ('rd-gallery-before/gallery-in-hall.png', 'before.png'),
        ('rd-gallery-after/gallery-in-hall.png', 'after.png'),
        ('rd-gallery-after/gallery-approach.png', 'approach.png'),
        ('rd-gallery-after/gallery-inside.png', 'inside.png'),
        ('rd-gallery-after/report.json', 'checks.json'),
    ]:
        shutil.copy2(RUN / source, OUT / name)
    rows = ''.join('<li>' + html.escape(item['id'].replace('_', ' ')) + '</li>' for item in manifest['items'])
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Reaction / Diffusion — in the museum</title><style>
body{margin:0;background:#eae7df;color:#272a2d;font:18px/1.55 system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:54px 24px}h1{font:clamp(36px,6vw,72px)/1.05 Georgia,serif;max-width:950px}p{max-width:800px}small{letter-spacing:.08em;text-transform:uppercase}img{width:100%;display:block;border-radius:3px}figure{margin:32px 0}figcaption{font-size:15px;margin-top:10px}a{color:#545889}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}ul{columns:2;font-size:15px;padding-left:20px}@media(max-width:700px){.pair{display:block}ul{columns:1}}code{font-size:15px}
</style><main><small>Endless Museum · Soft Bodies · 15 October 2026</small>
<h1>One chemical model.<br>Eighteen kept fields.</h1>
<p>The web gallery now has a place inside the reaction–diffusion hall: two rows of nine off-white plinths, beside the older inner room. Relief, colour and small pillars give different spatial readings of the concentration field.</p>
<figure><img src="after.png" alt="The reaction-diffusion gallery installed inside the actual museum hall"><figcaption>Native Godot capture from inside the museum. The forms are saved simulations; the existing live experiments remain at the front of the hall.</figcaption></figure>
<div class="pair"><figure><img src="before.png" alt="The same museum view before installation"><figcaption>Before: unused floor beside the inner room.</figcaption></figure><figure><img src="inside.png" alt="Visitor-height view of the first gallery studies"><figcaption>After: compare the surfaces at visitor height. Each label gives F, K, steps, seed and rendering mode.</figcaption></figure></div>
<p>All eighteen studies use the encyclopedia gallery's numerical and rendering settings. Their fields were simulated offline with the existing Godot Gray–Scott implementation and saved as native geometry. Entering the hall loads those forms without starting eighteen solvers.</p>
<p>The gallery begins at map cell <code>(22,29)</code> in <code>ProceduralGeneration_Reaction_Diffusion_Systems</code>. Follow the right-hand side past the existing experiments. Its middle aisle and the outer route to the exit were checked with a player-sized capsule.</p>
<figure><img src="approach.png" alt="Approach to the two rows of reaction-diffusion studies"><figcaption>The comparison aisle.</figcaption></figure>
<p><a href="checks.json">Native museum checks</a> passed: all eighteen studies survive museum packing, the original live desk remains connected, and the gallery route has floor and clearance. Separate native scene assertions check the configurations, geometry, upward relief normals and saved pillar buffers. Physical headset performance has not been tested.</p>
<details><summary>The eighteen studies</summary><ul>ROWS</ul></details>
<p><a href="http://127.0.0.1:3003/rd-gallery">Original web gallery</a></p>
</main></html>'''.replace('ROWS', rows)
    (OUT / 'index.html').write_text(page, encoding='utf-8')
    print(OUT / 'index.html')


if __name__ == '__main__':
    main()
