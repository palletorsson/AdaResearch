"""Publish the focused Turrell-reference pass and keep its chapter metadata current."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import subprocess
import sys
import urllib.request

import markdown
from bs4 import BeautifulSoup
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MAP = ROOT / 'commons/maps/Color_Flashlight'
read = lambda p: p.read_text(encoding='utf-8-sig')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
render = lambda s: markdown.markdown(s, extensions=['extra'])

reading = read(HERE / 'READING.md').strip()
chapter = MAP / 'final.md'
old = read(chapter)
prior = HERE / 'before-Color_Flashlight.md'
if not prior.exists(): prior.write_text(old, encoding='utf-8')
start = old.index('<!-- @colour_light_rooms -->')
end = old.index('<!-- @ -->', start)
new = old[:start] + '<!-- @colour_light_rooms -->\n\n' + reading + '\n\n' + old[end:]
footnote = '''[^apertures]: James Turrell's physical light installations are the reference, not the authorship of this scene. Häusler Contemporary describes *Aural* as a walk-in Ganzfeld installation; [its account of the Berlin presentation](https://haeusler-contemporary.com/james-turrell-ganzfeld-aural-en) does not support the supplied collage's VR description. In *Twilight Epiphany* (2012), ceiling illumination meets natural twilight through a roof aperture; see [Rice's Skyspace account](https://moody.rice.edu/james-turrell-twilight-epiphany-skyspace). Here RGB lights meet the museum's rendered sky. Neither natural daylight nor a measured perceptual equivalence is simulated.\n'''
assert '[^apertures]:' in new
new = re.sub(r'^\[\^apertures\]:.*$', lambda _: footnote.rstrip(), new, flags=re.M)
chapter.write_text(new, encoding='utf-8')
(HERE / 'Color_Flashlight.current.md').write_text(new, encoding='utf-8')
(HERE / 'Color_Flashlight.diff').write_text(''.join(difflib.unified_diff(
    read(prior).splitlines(True), new.splitlines(True), fromfile='before/final.md', tofile='current/final.md')), encoding='utf-8')

core_path = ROOT / 'commons/data/museum_core_encounters.json'
core_text = read(core_path)
pattern = r'("Color_Flashlight":\s*\{)(.*?)(\n    \},)'
match = re.search(pattern, core_text, re.S)
assert match
entry = match[2]
entry = re.sub(r'"text_sha256": "[^"]+"', '"text_sha256": "'+sha(chapter)+'"', entry)
entry = re.sub(r'"map_sha256": "[^"]+"', '"map_sha256": "'+sha(MAP/'map_data.json')+'"', entry)
entry = re.sub(r'"local_review": "[^"]+"', '"local_review": "doc/book/iterations/2026-10-02-light-an-opening/index.html"', entry)
core_path.write_text(core_text[:match.start(2)]+entry+core_text[match.end(2):], encoding='utf-8')

# Layout only: paste the two complete, unchanged native screenshots beside one
# another. The original images and their capture provenance remain available.
with Image.open(HERE/'figures/light-well-rose.png') as a, Image.open(HERE/'figures/light-well-violet.png') as b:
    assert a.size == b.size
    pair = Image.new('RGB',(a.width+b.width+24,a.height),(24,24,27))
    pair.paste(a,(0,0)); pair.paste(b,(a.width+24,0))
    pair.save(HERE/'light-well-pair.png')

report = json.loads(read(HERE/'figures/report.json'))
assert not report['failures'] and all(x['passed'] for x in report['checks'])
count = len(report['checks'])
css = '''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#19161b;color:#f0e8eb;font:18px/1.65 system-ui,sans-serif}header,main,footer{max-width:1200px;margin:auto;padding:32px}header{padding-top:70px}.eyebrow{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#f5aac9}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.12}h1{font-size:clamp(44px,7vw,86px);margin:18px 0 24px}h2{font-size:38px;margin-top:0}.lead{font:27px/1.5 Georgia,serif;max-width:870px}a{color:#f5aac9;text-underline-offset:4px}nav{display:flex;gap:24px;flex-wrap:wrap}section{border-top:1px solid #50434b;padding:44px 0;scroll-margin-top:24px}figure{margin:0 0 30px}img{width:100%;display:block}figcaption,.small{font:14px/1.5 system-ui,sans-serif;color:#c9bdc3;margin:10px 0}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}article{max-width:780px;margin:auto;font:24px/1.65 Georgia,serif}article img{margin-top:24px}pre{overflow:auto;background:#100d13;padding:22px;font:15px/1.6 Consolas,monospace}code{font-size:.9em}details{border:1px solid #50434b;padding:20px}summary{cursor:pointer}footer{border-top:1px solid #50434b;font-size:14px;color:#c9bdc3}@media(max-width:700px){.pair{grid-template-columns:1fr}header,main,footer{padding:22px}article{font-size:21px}}'''
footnote_html = '''<p class="small">James Turrell is a reference for our original study. <a href="https://haeusler-contemporary.com/james-turrell-ganzfeld-aural-en">Aural is a physical walk-in installation</a>. Rice describes <a href="https://moody.rice.edu/james-turrell-twilight-epiphany-skyspace">Twilight Epiphany's light and sky aperture</a>. Our sky is rendered, and our room uses RGB lighting.</p>'''
article = render(reading.replace('[^apertures]',''))
tutorial = render(read(MAP/'tutorial.md').split('## Making score:')[1])
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A colour with an opening · Ada</title><style>{css}</style></head><body>
<header><div class="eyebrow">Ada · Colour · 2 October 2026</div><h1>A colour with an opening.</h1><p class="lead">Pink draws us towards a recess. Above the next room, light frames a piece of sky. The body supplies another view.</p><nav><a href="#museum">In the museum</a><a href="#reading">Read</a><a href="#making">Make a comparison</a><a href="#reference">The reference</a></nav></header>
<main><section id="museum"><figure><img src="figures/pink-threshold.png" alt="Pink illuminated recess with visible return walls inside the installed Color Flashlight room"><figcaption>The pink opening has about a metre of depth. Native Godot photograph from inside the museum.</figcaption></figure>
<div class="pair"><figure><img src="figures/light-well-rose.png" alt="Rose light surrounds a real roof opening to the starry museum sky"><figcaption>Same standing viewpoint, rose surrounding light.</figcaption></figure><figure><img src="figures/light-well-violet.png" alt="The same roof opening surrounded by violet illumination"><figcaption>The light changes. The receiving material, well and viewpoint stay fixed.</figcaption></figure></div>
<figure><img src="figures/light-well-landing.png" alt="The stepped light well seen from its raised landing"><figcaption>The ramp gives the well another relation to the eye. This view is inside the assembled hall too.</figcaption></figure></section>
<section id="reading"><article><h2>A colour with an opening</h2>{article}{footnote_html}</article></section>
<section id="making"><h2>Light, then a room that receives it</h2><p>Colour → <strong>Color_Flashlight</strong> → Nails. These rooms follow the handheld lamps and their pale receivers. A light value stays fixed while the hand moves; then the hand rests while a light value changes.</p><p>The study returns to coordinates, transformations and Point Zero's frame loop. The tutorial asks for one light assignment and one controlled comparison. The student's first exercise can be small while the room remains a larger work to inspect.</p><details><summary>Open the making score</summary>{tutorial}</details></section>
<section id="reference"><h2>After Turrell</h2>{footnote_html}<p>The supplied images point towards several possibilities: a light threshold, nested depth, a framed sky and an enclosure for waiting. This pass concentrates on the threshold and sky inside our existing light annex.</p><p>It is an original study. The collages are retained as research leads; individual image attributions have not all been established.</p><details><summary>Evidence and decisions</summary><p>{count} native checks pass. They cover sampled standing clearances, floor support, backing and well walls, the actual roof opening, route footprint and rendered light changes. Full tracked-headset traversal and colour perception remain to be tested.</p><p><a href="figures/report.json">Native report</a> · <a href="figures/provenance.json">Capture sources</a> · <a href="figures/godot.log">Engine log</a> · <a href="DECISIONS.md">Spatial and reference decisions</a> · <a href="Color_Flashlight.current.md">Current chapter</a> · <a href="Color_Flashlight.diff">Text changes</a></p><p>The actual museum was frozen for photography; the room's physics stayed active. UI and player hands are hidden in these stills. No live save or user Godot process was changed.</p></details></section></main><footer>Photographs from Godot 4.6, desktop Compatibility renderer. Read the encounter, then return to its making score.</footer></body></html>'''
soup = BeautifulSoup(page,'html.parser')
ids = [x['id'] for x in soup.find_all(id=True)]
assert len(ids) == len(set(ids))
assert all(x['href'][1:] in ids for x in soup.find_all('a',href=True) if x['href'].startswith('#'))
for image in soup.find_all('img',src=True):
    src = image['src']
    path = ROOT/src.removeprefix('/book-review/') if src.startswith('/book-review/') else HERE/src
    assert path.exists(), path
    with Image.open(path) as img: img.verify()
(HERE/'index.html').write_text(page,encoding='utf-8')
subprocess.run([sys.executable,str(ROOT/'tools/export_book_captures.py'),'--sequence','color'],cwd=ROOT,check=True)
checks = {'native_checks':count,'native_failures':report['failures'],'chapter_sha256':sha(chapter),
          'map_sha256':sha(MAP/'map_data.json'),'page_images_resolve':True,'page_anchors_resolve':True,'served':[]}
for name in ['index.html','figures/pink-threshold.png','figures/light-well-rose.png','figures/light-well-violet.png','light-well-pair.png']:
    url = 'http://localhost:3003/book-review/doc/book/iterations/2026-10-02-light-an-opening/'+name
    body = urllib.request.urlopen(url,timeout=10).read()
    assert body == (HERE/name).read_bytes(),name
    checks['served'].append(name)
(HERE/'VALIDATION.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
print(f'Published light-opening pass: {count} native checks; 5 served files verified.')
