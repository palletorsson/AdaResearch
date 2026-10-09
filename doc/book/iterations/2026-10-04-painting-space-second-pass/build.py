from pathlib import Path
from html.parser import HTMLParser
from PIL import Image, ImageChops
import json, re, zipfile

OUT = Path(__file__).resolve().parent
STUDY = OUT.parents[1] / 'studies/painting-space'
FIRST = OUT.parent / '2026-10-04-painting-space'
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(item['passed'] for item in report['checks'])
assert not (OUT / 'native-errors.log').read_text(encoding='utf-8').strip()
frames = []
for i in range(120):
    with Image.open(OUT / f'motion-{i:02d}.png') as im:
        frames.append(im.convert('RGB').resize((960, 600), Image.Resampling.LANCZOS))
frames[0].save(OUT / 'memory.webp', save_all=True, append_images=frames[1:], duration=95, loop=0, quality=86)
with Image.open(OUT / 'memory.webp') as im:
    assert im.n_frames == 120
for a, b in [('lines.png', 'lines-no-glow.png'), ('painted-sphere.png', 'unpainted-sphere.png'), ('space-brush.png', 'brush-bubbles.png'), ('brush-bubbles.png', 'brush-light.png')]:
    with Image.open(OUT / a) as first, Image.open(OUT / b) as second:
        assert ImageChops.difference(first.convert('RGB'), second.convert('RGB')).getbbox(), (a, b)
files = ['project.godot', 'study.tscn', 'study.gd', 'shell.gdshader', 'paint.gdshader', 'mist.gdshader', 'light.gdshader', 'README.md', 'JetBrainsMono-Medium.ttf', 'JetBrainsMono-OFL.txt', '.gitignore']
with zipfile.ZipFile(OUT / 'painting-space.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for name in files:
        z.write(STUDY / name, 'painting-space/' + name)
with zipfile.ZipFile(OUT / 'painting-space.zip') as z:
    assert z.testzip() is None
    for name in files:
        assert z.read('painting-space/' + name) == (STUDY / name).read_bytes()
style = re.search(r'<style>(.*?)</style>', (FIRST / 'index.html').read_text(encoding='utf-8'), re.S).group(1)

def figure(name, title, caption=''):
    return f'<figure><a href="{name}"><img src="{name}" alt="{title}" width="1600" height="1000" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

def compare(identity, options):
    buttons = ''.join(f'<button data-view="{identity}" data-src="{file}" aria-pressed="{str(i == 0).lower()}">{label}</button>' for i, (label, file) in enumerate(options))
    return f'<div class="controls" role="group" aria-label="Image comparison">{buttons}</div><img id="{identity}" src="{options[0][1]}" alt="{options[0][0]} — native Godot capture" width="1600" height="1000"><p class="small" id="{identity}-status" aria-live="polite">{options[0][0]} — native Godot capture.</p>'

specimens = [
    ('solid', 'A solid', 'A lit sphere establishes the reference. Its visible boundary is continuous.'),
    ('points', 'Points hold a shape', '420 luminous points occupy the same spherical boundary. The gaps remain open.'),
    ('lines', 'Lines leave it open', 'Latitude and longitude suggest a body through emissive lines.'),
    ('shells', 'Colour through colour', 'Slightly offset shells carry an angle-dependent sheen. Their overlaps change as you move.'),
    ('space-brush', 'A brush in space', 'B switches the knot between soft colour, bubbles and light points while retaining every mark.'),
    ('painted-sphere', 'A surface found', 'Your strokes reveal the sphere beneath them. Fast movements receive intermediate marks along its surface.'),
    ('slices', 'The missing intervals', 'Thirteen thin sections imply the sphere between them. From the side, its gaps become clear.'),
    ('memory', 'A short memory', 'Moving points leave tails that shrink and darken. Duration contributes to the body we perceive.'),
]
cards = ''.join(f'<article class="card" id="{name}"><a href="{name}.png"><img src="{name}.png" alt="{title}" width="1600" height="1000" loading="lazy"></a><div class="card-copy"><div class="eyebrow">0{i+1}</div><h2>{title}</h2><p>{copy}</p></div></article>' for i, (name, title, copy) in enumerate(specimens))
body = '''<nav><a href="#shared">One drawing, three materials</a><a href="#forms">Eight forms</a><a href="blog.html">Read the blog</a><a href="../2026-10-04-freehand-drawing/index.html">Freehand test</a><a href="#line-forms">Lines make form</a><a href="#before">Before / after</a><a href="#play">Try it</a><a href="../2026-10-04-painting-space/index.html">First pass</a></nav>
<header><div class="eyebrow">Ada / Painting space / second pass / 4 October 2026</div><h1>The drawing stays.<br>The body changes.</h1><p>A soft band of colour becomes a chain of bubbles, then a line of light. The positions stay where we left them. A different material makes us see a different body.</p><div class="controls"><a class="button primary" href="painting-space.zip" download>Download the updated Godot study</a><a class="button" href="#shared">Compare the materials</a></div></header>
<section class="copy" id="shared"><div class="eyebrow">One saved path</div><h2>Three ways to hold the same mark</h2><p>All three views use the same 540 positions and stored colours. Soft stamps accumulate into a mist-like band. Spherical shells make the overlaps visible. Smaller luminous points return the path to a line.</p>BRUSH_COMPARE<p>In the live study, B makes this comparison with your own drawing. X changes ink for the next stroke. Brackets change the brush size.</p></section>
GALLERY
<section class="copy" id="before"><div class="eyebrow">Before / after</div><h2>Make room to see</h2>PASS_COMPARE<p>Neighbouring spheres and the large wall lettering no longer compete with a transparent form. Press 0 to return to the full gallery.</p></section>
<section class="cards" id="forms">CARDS</section>
<section class="copy" id="line-forms"><div class="eyebrow">Another family of possibilities</div><h2>Lines make form</h2><p>A line can outline a body, become its structure, or acquire a body of its own when given thickness. We can leave space between lines and still see a surface. Walking around it makes those gaps return.</p>
<table><tr><th>Approach</th><th>What it can make</th></tr><tr><td>Contours and rings</td><td>Cross-sections, wireframes and open shells. The latitude and longitude study already makes a sphere legible this way.</td></tr><tr><td>Ribs and woven lines</td><td>Lattices, screens, cages and canopies. Spacing and crossing become decisions about how much remains open.</td></tr><tr><td>Straight lines between curves</td><td>A curved envelope built from straight segments: a string-like surface whose form changes when either guiding curve moves.</td></tr><tr><td>A profile along a line</td><td>Tubes, ribbons, rails and knots. The path chooses where the form goes; the profile gives it width and section.</td></tr><tr><td>Traces and branches</td><td>Drawing accumulated into a body, or paths growing into a network. Order and duration contribute to the form.</td></tr></table>
<p>The rings and moving traces are working studies here; the brush also lets us draw a path in space. Woven structures, straight-line surfaces and branching networks are possibilities to test next. The <a href="../2026-10-04-glyph-form-atlas/index.html#possibilities">profile atlas</a> already explores carrying a section along a path.</p><p>A visible line needs a width. Our luminous rings use thin cylinder segments; the brush’s light view uses a chain of points. Neither automatically fills the gaps or creates a collision boundary. A crossing may look joined while the parts remain separate. That difference belongs to the form we are making.</p></section>
<section class="copy"><h2>Where the mark is</h2><p>The cursor now shows brush width. A guide drops to the floor, giving its position another reference. Changing depth and drawing from another viewpoint lets a stroke leave the flat plane of the screen.</p>CONTROLS<p>Moving quickly fills gaps between pointer samples. Holding still deposits more marks in one place. On the sphere, intermediate marks follow a spherical arc; in free space, they connect successive positions.</p></section>
<section class="copy"><h2>What does the glow add?</h2>GLOW_COMPARE<p>The lines remain luminous when screen glow is off. The halo is another contribution to their appearance; it does not itself light the floor.</p></section>
<section class="copy"><h2>A short memory</h2><img id="moving" src="memory.png" alt="Moving points with fading tails" width="1600" height="1000"><div class="controls"><button id="motion-button" aria-pressed="false">Play the native capture</button></div><p class="small">120 native frames, approximately the timing of the live scene. Playback begins only when you press play.</p></section>
<section class="copy" id="play"><div class="eyebrow">Working desktop study</div><h2>Draw into it</h2><p>Open <code>project.godot</code> in Godot 4.6, let the font import and run. Press <strong>5</strong> for the free-space brush or <strong>6</strong> to paint the hidden sphere. C clears the example; R restores it.</p><a class="button primary" href="painting-space.zip" download>Download Painting space</a>
<table><tr><th>Control</th><th>Action</th></tr><tr><td>1–8 / 0</td><td>Focus a study / return to the gallery</td></tr><tr><td>Left-drag</td><td>Orbit, or draw at stations 5 and 6</td></tr><tr><td>Shift + left-drag</td><td>Orbit at a drawing station</td></tr><tr><td>Wheel</td><td>Approach; at station 5, change brush depth</td></tr><tr><td>B</td><td>Soft colour / bubbles / light points</td></tr><tr><td>X / [ / ]</td><td>Change ink / smaller brush / larger brush</td></tr><tr><td>Z / C / R</td><td>Undo / clear / restore example</td></tr><tr><td>F5 / F9</td><td>Save / load both drawings locally</td></tr><tr><td>Right-drag + WASD / QE</td><td>Look and fly</td></tr><tr><td>G / Space</td><td>Glow / pause the moving traces</td></tr></table>
<p>F5 saves both drawings and their settings in Godot's local user-data folder, replacing the previous save. F9 brings them back. This is an explicit save, not autosave. Z can undo a stroke, clearing, restoring an example or loading a save.</p>
<details><summary>Construction and verification</summary><p>CHECK_COUNT native checks passed, including mouse drawing, continuous strokes, material switching with retained positions, undo, disk save/load, invalid-state rejection, the paint seam and pole, bounded brush memory and rendered views. The native renderer reported no errors.</p><p>Soft colour uses camera-facing stamps with radial falloff. Shells use additive colour and a view-dependent sheen. These suggest volume and glass; they do not simulate filled fog or physical refraction. The space brush holds at most 900 stamps, replacing the oldest after that. Undo retains up to 12 states.</p><p>The camera flies freely without walking collision. This remains a standalone desktop study; museum placement and tracked-hand testing on Quest are still ahead.</p><p><a href="verification.json">Native checks</a> · <a href="../../studies/painting-space/README.md">Method and controls</a> · <a href="../../studies/painting-space/study.gd">Scene and interaction code</a> · <a href="../../studies/painting-space/mist.gdshader">Soft colour shader</a> · <a href="first-pass-source.zip">Preserved first-pass source</a></p></details></section>
<footer>Ada / Painting space · Second pass · Native Godot 4.6 captures · JetBrains Mono, OFL included.</footer>'''
body = body.replace('BRUSH_COMPARE', compare('brush-comparison', [('Soft colour', 'space-brush.png'), ('Bubbles', 'brush-bubbles.png'), ('Light points', 'brush-light.png'), ('Another viewpoint', 'brush-side.png')]))
body = body.replace('PASS_COMPARE', compare('pass-comparison', [('Second pass', 'painted-sphere.png'), ('First pass', 'paint-before.png')]))
body = body.replace('GLOW_COMPARE', compare('glow-comparison', [('Glow on', 'lines.png'), ('Glow off', 'lines-no-glow.png')]))
body = body.replace('GALLERY', figure('gallery.png', 'Eight form studies in the updated gallery', 'Seven stations retain the spherical comparison. The free-space brush now describes a knot. Focus a station to see it without neighbouring forms.'))
body = body.replace('CONTROLS', figure('drawing-controls.png', 'Brush outline, floor guide and working controls', 'The actual desktop controls. F5 saves your work before you close the study.'))
body = body.replace('CARDS', cards).replace('CHECK_COUNT', str(len(report['checks'])))
script = '''document.querySelectorAll('button[data-view]').forEach(button=>button.addEventListener('click',()=>{const target=button.dataset.view;document.getElementById(target).src=button.dataset.src;document.getElementById(target).alt=button.textContent+' — native Godot capture';document.querySelectorAll('button[data-view="'+target+'"]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));document.getElementById(target+'-status').textContent=button.textContent+' — native Godot capture.';}));
document.getElementById('motion-button').addEventListener('click',event=>{const button=event.currentTarget;const playing=button.getAttribute('aria-pressed')!=='true';button.setAttribute('aria-pressed',String(playing));button.textContent=playing?'Stop the capture':'Play the native capture';document.getElementById('moving').src=playing?'memory.webp':'memory.png';});'''
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Painting space — second pass</title><style>' + style + '</style></head><body><main>' + body + '</main><script>' + script + '</script></body></html>'
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
checks = {'native_checks': len(report['checks']), 'local_links': links.count, 'source_equal_zip_files': len(files), 'native_motion_frames': 120, 'comparison_images_differ': True}
(OUT / 'package-checks.json').write_text(json.dumps(checks, indent=2) + '\n', encoding='utf-8')
print(json.dumps(checks))
