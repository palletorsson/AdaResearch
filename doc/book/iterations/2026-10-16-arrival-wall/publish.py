"""Publish the kept arrival as wall works and chapter figures; preserve the prose."""
from pathlib import Path
from hashlib import sha256
from html import escape as e
import json
import os
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
choices_path = ROOT / 'commons/maps/Random_Definition/book_images.json'
choices = json.loads(choices_path.read_text(encoding='utf8'))
source = ROOT / choices['text']
text = source.read_text(encoding='utf8')

CSS = '''
:root{--paper:#f3f0e7;--ink:#1a201c;--muted:#62685e;--line:#c8c9ba}*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.75 Georgia,serif}a{color:inherit;text-underline-offset:.22em}
main{max-width:1300px;margin:auto;padding:24px 5vw 80px}nav{display:flex;flex-wrap:wrap;gap:20px;justify-content:space-between;font:13px/1.5 system-ui,sans-serif;border-bottom:1px solid var(--line);padding-bottom:18px}
h1{font-weight:400;font-size:clamp(36px,5vw,60px);line-height:1.1;letter-spacing:-.03em;max-width:800px;margin:48px 0 30px}h2{font-weight:400;line-height:1.25;font-size:30px}
p{max-width:770px}.lede{font-size:24px;line-height:1.55}.eyebrow,figcaption,summary,.meta{font:13px/1.55 system-ui,sans-serif;color:var(--muted)}.eyebrow{letter-spacing:.1em;text-transform:uppercase;margin-top:36px}
section{border-top:1px solid var(--line);margin-top:44px;padding-top:20px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}figure{margin:0}img{display:block;width:100%;height:auto}figcaption{margin:10px 0 26px}
.book{max-width:650px;margin:52px auto}.book h1{font-size:clamp(35px,4.6vw,53px);margin-top:16px;margin-bottom:40px}.book p{margin:0 0 1.25em}.book .figure{margin:32px auto 40px;scroll-margin-top:30px;break-inside:avoid}.book .figure img{max-height:420px;object-fit:contain}.book figcaption{text-align:center;font:italic 14px/1.5 Georgia,serif}.book .footnote{font-size:13px;line-height:1.6;border-top:1px solid var(--line);padding-top:20px;margin-top:36px}
.book [id^=encounter]:not(:first-of-type){margin-top:42px}.note{font:14px/1.6 system-ui,sans-serif;color:var(--muted);border-top:1px solid var(--line);margin-top:40px;padding-top:20px}code{font-size:.8em;overflow-wrap:anywhere}details{margin:18px 0}summary{cursor:pointer}
@media(max-width:750px){.pair{grid-template-columns:1fr}main{padding:20px 6vw 50px}.book{font-size:18px;margin-top:30px}}
@media print{nav,.note{display:none}main{padding:0}.book{max-width:none;margin:0;font-size:11pt}.book h1{font-size:28pt}.book .figure img{max-height:75mm}.book .figure{margin:18pt auto}}
'''

def document(title, body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+e(title)+'</title><style>'+CSS+'</style><body>'+body+'</body></html>'

def url(path):
    return Path(os.path.relpath(path, HERE)).as_posix()

def picture(item):
    path = ROOT / item['image']
    assert sha256(path.read_bytes()).hexdigest() == item['image_sha256'], item['id']
    return f'<img src="{e(url(path))}" width="1600" height="1200" alt="{e(item["alt"])}" loading="lazy">'

parts = re.split(r'<!-- @([^>]*?) -->', text)
render_input = parts[0]
for n in range(1, len(parts), 2):
    artifact, section = parts[n].strip(), parts[n+1]
    if artifact:
        render_input += '\n\n<div id="encounter-'+artifact.replace('/','-')+'"></div>\n\n'
    for item in choices['images']:
        if item['artifact'] != artifact: continue
        anchor = item['insert_after']
        assert section.count(anchor) == 1, 'Review the changed prose anchor: '+item['id']
        figure = '<figure class="figure" id="illustration-'+item['id']+'">'+picture(item)+'<figcaption>'+e(item['caption'])+'</figcaption></figure>'
        section = section.replace(anchor, anchor+'\n\n'+figure, 1)
    render_input += section
book = markdown.markdown(render_input, extensions=['footnotes', 'tables'])
book = book.replace('../../../algorithms/randomness/seed_replay/opening_seed.json','opening_seed.json')
book = book.replace('../../../doc/book/iterations/','/book-review/doc/book/iterations/')
shutil.copyfile(ROOT/'algorithms/randomness/seed_replay/opening_seed.json', HERE/'opening_seed.json')
shutil.copyfile(source, HERE/'final-source.md')
nav = '<nav><span>ADA RESEARCH / RANDOM DEFINITION</span><a href="index.html">Hall and book ↗</a><a href="illustrated-chapter.pdf">Download PDF ↓</a></nav>'
note = '<p class="note">The abacus and counter are captured on arrival. The page starts with ten rows from seed 435; its camera waits for every row to fill and settle. No touch is supplied for the photograph. The same PNGs hang in the hall from that visit. Later visits produce separate records; the book keeps this selected arrival. Camera crops, monochrome and omitted labels are authored choices.</p>'
(HERE/'illustrated.html').write_text(document('What chance is allowed to do · Arrival edition','<main>'+nav+'<article class="book">'+book+note+'</article></main>'),encoding='utf8')

body = '<main><nav><a href="illustrated.html">Read the illustrated chapter ↗</a><a href="illustrated-chapter.pdf">Download PDF ↓</a><a href="/long-museum/writing-wall?map=Random_Definition">Writing wall ↗</a></nav><div class="eyebrow">Random Definition · Arrival wall pilot</div><h1>One image.<br>Two places to encounter it.</h1><p class="lede">The abacus and counter are photographed as the hall opens. The number page begins with ten seeded rows and is photographed when it is full. That same image becomes a framed work and a page in the book.</p><p>The camera has a chosen position and crop. It isolates the actual Godot geometry, removes selected labels and casing, and prints its contours in black and off-white. The camera adds no touch, trace or random draw; the page fills through its own running sequence. The installation continues after the picture has stopped.</p>'
for item in choices['images']:
    wall = HERE / (item['id']+'-on-wall.png')
    assert wall.exists()
    body += '<section><h2>'+e(item['title'])+'</h2><div class="pair"><figure><img src="'+wall.name+'" width="1600" height="1200" loading="lazy" alt="'+e(item['title'])+' framed on the actual hall wall"><figcaption>In the hall · native desktop capture</figcaption></figure><figure>'+picture(item)+'<figcaption>In the book · '+e(item['caption'])+'</figcaption></figure></div><p>'+e(item['limit'])+'</p><details><summary>Camera, omissions and saved state</summary><p>'+e(item['keep'])+'</p><p>Outside the picture: '+e(item['omit'])+'</p><p><a href="'+url(ROOT/item['capture'])+'">Arrival receipt</a> · <a href="'+url(ROOT/item['image'])+'">Exact wall/book PNG</a></p><p class="meta">SHA-256: <code>'+item['image_sha256']+'</code></p></details></section>'
body += '<section><h2>The dial follows its angle</h2><p>The nine marks now point radially. Marks and needle share a scale in radians, from zero to twelve events per second; the reading averages the last two seconds.</p><img src="geiger-radial-dial.png" width="1600" height="1200" loading="lazy" alt="The actual Geiger dial with radial tick marks" style="max-width:700px"></section><section><h2>A kept arrival can become an edition</h2><p>New visits save new images under Godot’s user data folder. Selecting one for the book copies its PNG files unchanged and checks their hashes. Changing the installation or visiting again does not silently replace this edition.</p><p><a href="README.md">Rebuild and selection instructions</a> · <a href="verification.json">Native capture and seeded-row checks</a> · <a href="museum-report.json">Actual-hall checks</a> · <a href="../2026-10-16-book-image-study/index.html">Earlier staged image study</a></p><p class="meta">Verified on desktop: capture does not consume the source streams, wall textures match saved pixels, frames are backed by walls, and capture cameras are released. Headset performance and reading remain to be tried.</p></section></main>'
(HERE/'index.html').write_text(document('Arrival wall · Random Definition',body),encoding='utf8')
shutil.copyfile(choices_path, HERE/'curation.json')
paths = [source, choices_path, HERE/'publish.py', ROOT/'commons/book/installation_capture.gd',ROOT/'commons/book/arrival_wall.gd',ROOT/'tools/book_image_filter.gdshader']
paths.extend(ROOT/path for path in ['commons/artifacts/random_touch/random_touch.gd','commons/artifacts/geiger_counter/geiger_counter.gd','algorithms/randomness/randomnumbergeneration/scripts/random_number_book_page_1995.gd','commons/scenes/em/em_portal_stream.gd'])
for item in choices['images']: paths.extend([ROOT/item['image'], ROOT/item['capture']])
(HERE/'provenance.json').write_text(json.dumps({'schema':'ada-arrival-edition/1','source_text':choices['text'],'hashes':{p.relative_to(ROOT).as_posix():sha256(p.read_bytes()).hexdigest() for p in set(paths)}},indent=2)+'\n',encoding='utf8')
assert source.read_bytes() == (HERE/'final-source.md').read_bytes()
print('Published arrival wall and chapter; identical PNG hashes, unchanged prose.')
