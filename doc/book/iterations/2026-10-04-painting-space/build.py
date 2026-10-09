from pathlib import Path
from html import escape
from html.parser import HTMLParser
import json
import zipfile
from PIL import Image, ImageChops

OUT = Path(__file__).resolve().parent
STUDY = OUT.parents[1] / 'studies' / 'painting-space'
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
assert not (OUT / 'native-errors.log').read_text(encoding='utf-8').strip()

frames = []
for i in range(36):
    with Image.open(OUT / f'motion-{i:02d}.png') as im:
        frames.append(im.convert('RGB').resize((960, 600), Image.Resampling.LANCZOS))
frames[0].save(OUT / 'memory.webp', save_all=True, append_images=frames[1:], duration=90, loop=0, quality=86)
with Image.open(OUT / 'memory.webp') as im:
    assert im.n_frames == 36
with Image.open(OUT / 'lines.png') as on, Image.open(OUT / 'lines-no-glow.png') as off:
    assert ImageChops.difference(on.convert('RGB'), off.convert('RGB')).getbbox(), 'Glow comparison must change the rendered image'
with Image.open(OUT / 'painted-sphere.png') as painted, Image.open(OUT / 'unpainted-sphere.png') as empty:
    assert ImageChops.difference(painted.convert('RGB'), empty.convert('RGB')).getbbox(), 'Painting must be visible'

files = ['project.godot', 'study.tscn', 'study.gd', 'shell.gdshader', 'paint.gdshader', 'README.md', 'JetBrainsMono-Medium.ttf', 'JetBrainsMono-OFL.txt', '.gitignore']
with zipfile.ZipFile(OUT / 'painting-space.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for name in files:
        z.write(STUDY / name, 'painting-space/' + name)
with zipfile.ZipFile(OUT / 'painting-space.zip') as z:
    assert z.testzip() is None
    for name in files:
        assert z.read('painting-space/' + name) == (STUDY / name).read_bytes()

specimens = [
    ('solid', 'A solid', 'A surface receives light and casts a shadow. This is our reference: a sphere 2.6 metres across.', 'How much can we remove and still recognise it?'),
    ('points', 'Points hold a shape', '420 luminous points occupy the same spherical boundary. The spaces between them remain visible as you approach.', 'The points are separate. The body is something we see between them.'),
    ('lines', 'Lines leave it open', 'Latitude and longitude describe a boundary in cyan. Short cylindrical segments carry emission; screen glow softens their edges.', 'A line gives us enough to imagine the missing surface.'),
    ('shells', 'Colour through colour', 'Three nested transparent shells keep pink, cyan and amber edges visible. Their colours add where the images overlap.', 'These are surfaces with empty interiors. The shader lets us imagine something more substantial.'),
    ('space-brush', 'A brush in space', 'A helix of overlapping translucent spheres is the first mark. Press 5, then C, and draw your own. Scroll to move the brush plane in depth.', 'A slow hand deposits more marks in the same place.'),
    ('painted-sphere', 'A surface found', 'The sphere begins almost invisible. Your marks follow its curvature. Paint stays attached as you move around it. Press 6 and C to begin again.', 'Here the boundary precedes the drawing. We learn where it is by touching it with colour.'),
    ('slices', 'The missing intervals', 'Thirteen thin discs occupy sections through the same sphere. The gaps become more visible from the side.', 'A volume can become legible through its interruptions.'),
    ('memory', 'A short memory', 'Moving points leave tails that shrink and darken. The paths lie on a sphere, but no complete surface is ever supplied. Space pauses their motion.', 'Duration becomes part of the body we perceive.'),
]
cards = []
for i, (name, title, copy, question) in enumerate(specimens):
    cards.append(f'''<article id="{name}" class="card"><a href="{name}.png"><img src="{name}.png" alt="Native Godot view: {escape(title)}" loading="lazy" width="1600" height="1000"></a><div class="card-copy"><span class="eyebrow">0{i+1} / {name.replace('-', ' ')}</span><h2>{title}</h2><p>{copy}</p><p class="question">{question}</p></div></article>''')

page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Painting space — Ada form studies</title>
<style>
:root{color-scheme:dark;--bg:#11151f;--card:#1b2130;--ink:#e9e3df;--muted:#a7b1c6;--pink:#efb8cd;--line:#354054}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--ink);font:20px/1.65 Georgia,serif}main{max-width:1450px;margin:auto;padding:28px 34px 85px}a{color:var(--pink);text-underline-offset:5px}nav{display:flex;gap:24px;flex-wrap:wrap;padding-bottom:18px;border-bottom:1px solid var(--line)}nav,.eyebrow,figcaption,.small,button,.button,summary,footer,table{font:14px/1.6 system-ui,sans-serif}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:var(--muted)}header{max-width:850px;margin:65px auto 45px}h1{font-weight:400;font-size:clamp(64px,9vw,112px);line-height:.98;letter-spacing:-3px;margin:20px 0 30px}h2{font-size:32px;font-weight:400;line-height:1.15}p{margin:16px 0}img{display:block;width:100%;height:auto}figure{margin:32px 0 55px}figcaption{color:var(--muted);padding:12px 0;max-width:950px}.copy{max-width:820px;margin:65px auto}.cards{display:grid;grid-template-columns:1fr 1fr;gap:26px}.card{border:1px solid var(--line);background:var(--card);scroll-margin-top:22px}.card-copy{padding:26px 30px}.question{color:#c0dce6;font-style:italic}.button,button{display:inline-block;padding:12px 19px;border:1px solid #7a859c;background:#222b3c;color:var(--ink);text-decoration:none;cursor:pointer;border-radius:3px}.button.primary{background:var(--pink);color:#191c28;border:none}.controls{display:flex;flex-wrap:wrap;gap:12px;margin:18px 0}button[aria-pressed=true]{background:#d6e6ee;color:#151c28}button:focus-visible,a:focus-visible,summary:focus-visible{outline:2px solid var(--pink);outline-offset:5px}.small{color:var(--muted)}table{border-collapse:collapse;width:100%;font-size:16px}td,th{text-align:left;border-bottom:1px solid var(--line);padding:12px 14px}details{border-top:1px solid var(--line);margin-top:30px;padding-top:20px}summary{cursor:pointer;font-size:17px}code{font:.85em Consolas,monospace}footer{border-top:1px solid var(--line);padding-top:22px;color:var(--muted)}@media(max-width:800px){main{padding:22px 18px}.cards{grid-template-columns:1fr}h1{letter-spacing:-1px}.card-copy{padding:24px}body{font-size:18px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
</style></head><body><main>
<nav><a href="#forms">Eight forms</a><a href="#compare">Glow &amp; paint</a><a href="#motion">A moving trace</a><a href="#play">Try the study</a><a href="../2026-10-04-glyph-form-atlas/index.html">Borrowed outlines</a></nav>
<header><div class="eyebrow">Ada / native Godot study / 4 October 2026</div><h1>Painting<br>space</h1><p>A point shines. A line keeps its path. A nearly invisible sphere receives a mark. How much has to be present before we begin to see a body?</p><div class="controls"><a class="button primary" href="painting-space.zip" download>Download the playable Godot study</a><a class="button" href="#forms">Explore the captures</a></div></header>
<figure><a href="gallery.png"><img src="gallery.png" alt="Eight spherical form studies on plinths in a dark Godot gallery" width="1600" height="1000"></a><figcaption>The native gallery. A common 2.6 m spherical envelope lets us compare eight constructions. All images below come from the working Godot project.</figcaption></figure>
<section class="cards" id="forms">CARDS</section>
<section class="copy" id="compare"><div class="eyebrow">Two changes, held still</div><h2>What does the glow add?</h2><p>The geometry stays in place. Turning off glow removes the halo but leaves the luminous lines. Looking bright and lighting the surrounding room are separate operations here.</p><div class="controls" role="group" aria-label="Glow comparison"><button data-view="glow" data-src="lines.png" aria-pressed="true">Glow on</button><button data-view="glow" data-src="lines-no-glow.png" aria-pressed="false">Glow off</button></div><img id="glow" src="lines.png" alt="Line sphere with screen glow enabled" width="1600" height="1000"><p class="small" id="glow-status" aria-live="polite">Glow on — native Godot capture.</p>
<h2>What does the paint reveal?</h2><p>A faint rim gives us somewhere to begin. The first stroke discovers the curvature. Further strokes remember where the brush has been; turning the camera reveals the same marks from another side.</p><div class="controls" role="group" aria-label="Surface painting comparison"><button data-view="paint" data-src="unpainted-sphere.png" aria-pressed="false">Before paint</button><button data-view="paint" data-src="painted-sphere.png" aria-pressed="true">After paint</button></div><img id="paint" src="painted-sphere.png" alt="Coloured strokes attached to a transparent sphere" width="1600" height="1000"><p class="small" id="paint-status" aria-live="polite">After paint — native Godot capture.</p></section>
<section class="copy" id="motion"><div class="eyebrow">Time leaves a shape</div><h2>A short memory</h2><img id="moving" src="memory.png" alt="Moving points leave short tails on a spherical path" width="1600" height="1000"><div class="controls"><button id="motion-button" aria-pressed="false">Play the native capture</button></div><p class="small">36 native frames in an accelerated loop. The live Godot scene moves more slowly and continuously. Animation starts only when you press play.</p></section>
<section class="copy" id="play"><div class="eyebrow">Working desktop experiment</div><h2>Draw into the comparison</h2><p>Open <code>project.godot</code> in Godot 4.6 and run. Press <strong>5</strong> for the free-space brush or <strong>6</strong> to paint the hidden sphere. Each begins with an example; <strong>C</strong> clears it and <strong>R</strong> restores it.</p><a class="button primary" href="painting-space.zip" download>Download Painting space</a><table><tr><th>Control</th><th>Action</th></tr><tr><td>1–8 / 0</td><td>Approach a study / return to the gallery</td></tr><tr><td>Left-drag</td><td>Orbit, or draw at stations 5 and 6</td></tr><tr><td>Shift + left-drag</td><td>Orbit while at a drawing station</td></tr><tr><td>Wheel</td><td>Approach; at station 5, change brush depth</td></tr><tr><td>Right-drag + WASD / QE</td><td>Look and fly</td></tr><tr><td>G / Space</td><td>Toggle glow / pause the moving traces</td></tr></table><p>A slow stroke deposits more transparent marks in one place. Changing the depth and drawing from another side gives the free-space brush a volume to work in. On the sphere, a camera ray constrains the brush to the surface.</p>
<details><summary>Construction, evidence and limits</summary><p>CHECKS native checks passed, including actual mouse-event drawing, ray hits and misses, painting across the longitude seam and pole, recycling old brush marks, pause and glow. The native renderer reported no errors.</p><p>The shells use additive colour and a view-dependent edge shader; they do not simulate filled fog or physical glass. The free-space brush holds at most 900 stamps and replaces the oldest after that. The surface painting is stored in a texture. Both drawings last for the current run only.</p><p>The live camera flies freely without collision. This is a separate desktop study; it has not yet been placed in a museum hall or tested with tracked hands on Quest.</p><p><a href="verification.json">Native checks</a> · <a href="../../studies/painting-space/README.md">Method and controls</a> · <a href="../../studies/painting-space/study.gd">Scene and interactions</a> · <a href="../../studies/painting-space/shell.gdshader">Transparent shell shader</a> · <a href="../../studies/painting-space/paint.gdshader">Surface paint shader</a></p></details></section>
<footer>Ada / Painting space · Godot 4.6 Forward+ · JetBrains Mono, OFL included · The gallery is a test of representation, material and memory.</footer>
</main><script>
document.querySelectorAll('button[data-view]').forEach(button=>button.addEventListener('click',()=>{const target=button.dataset.view;document.getElementById(target).src=button.dataset.src;document.getElementById(target).alt=button.textContent+' — native Godot capture';document.querySelectorAll('button[data-view="'+target+'"]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));document.getElementById(target+'-status').textContent=button.textContent+' — native Godot capture.';}));
document.getElementById('motion-button').addEventListener('click',event=>{const button=event.currentTarget;const playing=button.getAttribute('aria-pressed')!=='true';button.setAttribute('aria-pressed',String(playing));button.textContent=playing?'Stop the capture':'Play the native capture';document.getElementById('moving').src=playing?'memory.webp':'memory.png';});
</script></body></html>'''.replace('CARDS', '\n'.join(cards)).replace('CHECKS', str(len(report['checks'])))
(OUT / 'index.html').write_text(page, encoding='utf-8')

class Links(HTMLParser):
    count = 0
    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in ('src', 'href', 'data-src') and value and not value.startswith(('http:', 'https:', '#')):
                assert (OUT / value.split('#')[0]).exists(), value
                self.count += 1

links = Links()
links.feed(page)
checks = {'native_checks': len(report['checks']), 'local_links': links.count, 'source_equal_zip_files': len(files), 'native_motion_frames': 36, 'glow_and_paint_images_differ': True}
(OUT / 'package-checks.json').write_text(json.dumps(checks, indent=2) + '\n', encoding='utf-8')
print(json.dumps(checks))
