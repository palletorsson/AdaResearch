"""Package generated plates as a static, portable atlas. No image or runtime edits."""
from pathlib import Path
from html import escape as esc
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import shutil
import struct
import zipfile

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
OLD = OUT.parent / '2026-10-06-final-comic-plates'
selected = json.loads((OUT / 'selected-images.json').read_text(encoding='utf-8'))
lessons = json.loads((OUT / 'captions.json').read_text(encoding='utf-8'))
old = json.loads((OLD / 'forces-plates.json').read_text(encoding='utf-8'))['plates']
order = json.loads((ROOT / 'commons/maps/sequences/forces.json').read_text(encoding='utf-8'))['sequences']['forces']['maps']
assert [p['map'] for p in old] == order, 'Current hall order changed; review the atlas.'
assert [p['id'] for p in selected] == [p['id'] for p in lessons]
assert len(selected) == 10 and len(old) == 13

def copy(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    if source.is_file():
        shutil.copy2(source, target)
    assert target.is_file(), str(target)

for p in selected:
    copy(Path(p['source_path']), OUT / p['selected_file'])
for p in old:
    copy(OLD / f"{p['slug']}.png", OUT / 'current-halls' / f"{p['slug']}.png")
(OUT / 'current-halls.json').write_text(json.dumps(old, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

CSS = '''
:root{--paper:#f5f1e8;--ink:#252629;--muted:#64615c;--line:#d6d0c3;--accent:#88334c}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:75px}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}a{color:var(--accent);text-underline-offset:3px}main,header,footer{max-width:1370px;margin:auto;padding:36px}.eyebrow{text-transform:uppercase;letter-spacing:.13em;font-size:11px;font-weight:700;color:var(--accent)}h1,h2,h3{font-family:Georgia,serif;line-height:1.12;letter-spacing:-.025em}h1{font-size:clamp(42px,5.4vw,78px);margin:20px 0 26px}h2{font-size:40px;margin:14px 0 20px}h3{font-size:27px;margin:16px 0 8px}.hero{display:grid;grid-template-columns:1fr .74fr;gap:65px;align-items:center;padding-top:55px;padding-bottom:50px}.hero figure{max-width:420px;margin:0 auto}.lead{font:24px/1.5 Georgia,serif;max-width:710px}.status{border-left:3px solid var(--accent);padding:9px 18px;color:var(--muted);font-size:14px;max-width:690px}.buttons{display:flex;gap:14px;flex-wrap:wrap;margin-top:28px}.button{padding:10px 18px;border:1px solid var(--accent);text-decoration:none;font-size:14px}.button:first-child{background:var(--accent);color:white}nav{position:sticky;top:0;background:rgba(245,241,232,.98);border-block:1px solid var(--line);display:flex;justify-content:center;gap:28px;flex-wrap:wrap;padding:13px 20px;z-index:3;font-size:14px}nav a{text-decoration:none}img{display:block;width:100%;height:auto}.hero img,.card img,.plate{border:1px solid var(--line)}figcaption,.fine{font-size:12px;color:var(--muted);line-height:1.6}figcaption{margin-top:9px}section{margin-bottom:80px}.intro{max-width:800px}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:42px 24px;margin-top:30px}.grid.beyond{grid-template-columns:repeat(2,minmax(0,1fr));max-width:950px}.grid.current{grid-template-columns:repeat(4,minmax(0,1fr))}.card{min-width:0}.card h3{font-size:25px}.card p{font-size:14px;margin:9px 0}.card .eyebrow{font-size:10px}.card .subject{font-size:12px;color:var(--accent)}.card a.image-link{display:block;background:#ddd7cc;transition:transform .18s}.card a.image-link:hover{transform:translateY(-4px)}.card img{aspect-ratio:2/3;object-fit:contain;background:white}.label{display:inline-block;background:#e9e0d5;color:#493c39;font-size:11px;padding:3px 7px}.list{display:grid;grid-template-columns:1fr 1fr;gap:30px;border-top:1px solid var(--line);padding-top:24px}.list p{font-size:14px}.plate-header{max-width:1230px;padding-top:50px}.plate-layout{display:grid;grid-template-columns:minmax(0,850px) minmax(260px,1fr);gap:40px;align-items:start;max-width:1430px}.plate-layout figure{margin:0}.notes{position:sticky;top:85px;font-size:15px}.notes h2{font-size:25px;margin-top:26px}.notes blockquote{font:25px/1.45 Georgia,serif;margin:30px 0;border-left:2px solid var(--accent);padding-left:20px}.notes dl{margin:0}.notes dt{font-size:11px;letter-spacing:.09em;text-transform:uppercase;color:var(--accent);font-weight:bold;margin-top:23px}.notes dd{margin:7px 0}.step-nav{display:flex;justify-content:space-between;gap:20px;border-top:1px solid var(--line);padding-top:25px;margin:35px 0;font-size:14px}footer{font-size:13px;border-top:1px solid var(--line);color:var(--muted);padding-bottom:55px}details{border-top:1px solid var(--line);padding-top:15px;margin-top:22px;font-size:13px}summary{cursor:pointer;font-weight:600}code{overflow-wrap:anywhere}@media(max-width:1000px){.grid,.grid.current{grid-template-columns:repeat(3,minmax(0,1fr))}.hero{gap:32px}.plate-layout{grid-template-columns:1fr}.notes{position:static;max-width:800px}.plate-layout figure{max-width:850px}}@media(max-width:700px){main,header,footer{padding:24px}.hero{grid-template-columns:1fr}.hero figure{max-width:360px}.grid,.grid.current,.grid.beyond{grid-template-columns:repeat(2,minmax(0,1fr));gap:30px 16px}.card h3{font-size:22px}nav{gap:15px;font-size:12px}.list{grid-template-columns:1fr}.lead{font-size:22px}h2{font-size:34px}}@media(max-width:430px){.grid,.grid.current,.grid.beyond{grid-template-columns:1fr}.card{max-width:360px;margin:auto}}@media print{nav,.buttons{display:none}.notes{position:static}.plate-layout{display:block}.plate{max-height:245mm;width:auto;max-width:100%;margin:auto}.grid{grid-template-columns:repeat(3,1fr)}.card{break-inside:avoid}header,main{padding:20px}a{color:inherit}}
'''
(OUT / 'atlas.css').write_text(CSS, encoding='utf-8')

def page(title, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{esc(title)} — Endless Museum</title><style>{CSS}</style></head><body>{body}</body></html>'

def card(p):
    return f'''<article class="card" id="{p['id']}"><a class="image-link" href="{p['id']}.html"><img loading="lazy" src="images/{p['id']}.png" width="1024" height="1536" alt="Comic plate: {esc(p['title'])}"></a><p class="eyebrow">{'Beyond / speculative' if p['id'].startswith(('09','10')) else 'Proposed encounter / ' + p['id'][:2]}</p><h3><a href="{p['id']}.html">{esc(p['title'])}</a></h3><p class="subject">{esc(p['subject'])}</p><p>{esc(p['caption'])}</p></article>'''

current_cards = []
for i,p in enumerate(old,1):
    current_cards.append(f'''<article class="card" id="{p['map']}"><a class="image-link" href="current-halls/{p['slug']}.png"><img loading="lazy" src="current-halls/{p['slug']}.png" alt="Existing hall illustration: {esc(p['title'])}"></a><p class="eyebrow">Current hall / {i:02}</p><h3>{esc(p['title'].capitalize())}</h3><p>{esc(p['summary'])}</p><details><summary>Hall + subject</summary><p><code>{esc(p['map'])}</code></p><p>{esc(p['focus'])}</p></details></article>''')

body = f'''<header class="hero"><div><p class="eyebrow">Endless Museum / Forces / Illustrated atlas</p><h1>The point learns to move the world.</h1><p class="lead">One familiar sphere. A growing set of abilities. From a small push to a room you can fly through.</p><p class="status">10 new concept plates: eight proposed encounters and two pages of possibilities beyond them. All 13 current Forces hall plates are collected below. These are generated illustrations, not screenshots or evidence of installed mechanics.</p><div class="buttons"><a class="button" href="#route">Walk the proposed route</a><a class="button" href="forces-illustrated-atlas.zip">Download the atlas</a></div></div><figure><a href="03-flight.html"><img src="images/03-flight.png" width="1024" height="1536" alt="Two held black spheres produce flight when aimed downward and backward"></a><figcaption>The chosen control: aim down/back and hold the triggers to thrust up/forward.</figcaption></figure></header>
<nav aria-label="Atlas sections"><a href="#route">Eight encounters</a><a href="#beyond">Beyond</a><a href="#current">Current 13 halls</a><a href="#reading">How to read the images</a><a href="README.md">Notes + prompts</a></nav>
<main><section id="route"><div class="intro"><p class="eyebrow">01 / Proposed teaching route</p><h2>The same point, more capacity.</h2><p>Push → launch → fly → brake → enter a vortex → deflect → return → choose a route. Each encounter reuses a known object and adds one relation. This eight-stage arrangement remains a proposal; the current thirteen-hall spine is preserved.</p></div><div class="grid">{''.join(card(p) for p in lessons[:8])}</div></section>
<section id="beyond"><div class="intro"><p class="eyebrow">02 / Speculative extensions</p><h2>What else can a force permit?</h2><p>Two six-panel studies: different ways a body can be carried, and different ways a rule can distribute access. They are possible directions for research, not additional obligations for the first tutorial.</p></div><div class="grid beyond">{''.join(card(p) for p in lessons[8:])}</div></section>
<section id="current"><div class="intro"><p class="eyebrow">03 / Existing illustrated sequence</p><h2>The thirteen halls we have.</h2><p>The existing reflective plates, in the canonical Forces order. The new route can be compared with them without erasing their distinctions. These comics accompany the texts; they do not certify runtime behavior.</p></div><div class="grid current">{''.join(current_cards)}</div></section>
<section id="reading"><p class="eyebrow">Reading key</p><h2>A picture proposes an encounter.</h2><div class="list"><div><p><strong>Continuity.</strong> The student, dark sphere, pale museum, wall identity and recurring material language join the plates. The point changes capacity while remaining recognizable.</p><p><strong>Arrows.</strong> Amber usually marks a force or impulse; cyan marks velocity where labelled. White streams show thrust aim. Curved paths show a journey. In the combined-course plate, cyan lines guide a route.</p></div><div><p><strong>Exactness.</strong> Arrows and architecture are schematic. Numerical ratios, trajectories, collisions and VR comfort require runnable models and tests. Individual plate notes identify the important simplifications.</p><p><strong>Scope.</strong> Complete coverage here means all thirteen canonical Forces halls plus the eight proposed encounters. The beyond pages select further directions; this is not an exhaustive inventory of every force-related script in the repository.</p></div></div><p><a href="http://localhost:3003/book-review/doc/book/iterations/2026-10-06-forces-the-point-gains-power/index.html">Read the editable encounter proposal</a> · <a href="http://localhost:3003/book-review/doc/book/iterations/2026-10-06-forces-current-readings/index.html">Read the current tutorial and reflective texts</a></p></section></main><footer>Generated with OpenAI's built-in image-generation tool. Selected PNGs, generation prompts, captions and this portable gallery are included in the ZIP. <a href="selected-images.json">Image provenance</a> · <a href="captions.json">Editable captions</a> · <a href="manifest.json">Validation manifest</a></footer>'''
(OUT / 'index.html').write_text(page('Forces — the point gains power', body), encoding='utf-8')

for i,p in enumerate(lessons):
    prev = lessons[i-1] if i else None
    next_ = lessons[i+1] if i+1 < len(lessons) else None
    steps = '<div class="step-nav">' + (f'<a href="{prev["id"]}.html">← {esc(prev["title"])}</a>' if prev else '<span></span>') + (f'<a href="{next_["id"]}.html">{esc(next_["title"])} →</a>' if next_ else '<a href="index.html#current">Current hall plates →</a>') + '</div>'
    related = ''.join(f'<li><a href="index.html#{m}">{esc(m)}</a></li>' for m in p['links'])
    body = f'''<nav><a href="index.html#{p['id']}">← Atlas</a><a href="images/{p['id']}.png">Full-size PNG</a><a href="forces-illustrated-atlas.zip">Download all plates</a></nav><header class="plate-header"><p class="eyebrow">{'Beyond / speculative' if i >= 8 else 'Proposed encounter / '+str(i+1).zfill(2)}</p><h1>{esc(p['title'])}</h1><p class="lead">{esc(p['subject'])}</p></header><main class="plate-layout"><figure><a href="images/{p['id']}.png"><img class="plate" src="images/{p['id']}.png" width="1024" height="1536" alt="{esc(p['caption'])}"></a><figcaption>Generated concept illustration. Not a native museum capture.</figcaption>{steps}</figure><aside class="notes"><p>{esc(p['caption'])}</p><blockquote>{esc(p['reflection'])}</blockquote><dl><dt>What travels onward</dt><dd>{esc(p['carry'])}</dd><dt>Build status</dt><dd>{esc(p['build'])}</dd><dt>Reading the drawing</dt><dd>{esc(p['note'])}</dd></dl>{'<h2>Existing relatives</h2><ul>'+related+'</ul>' if related else ''}<details><summary>Prompts and provenance</summary><p>Built-in image generation; selected file: <code>images/{p['id']}.png</code>. Full generation and edit prompts are recorded in <a href="selected-images.json">selected-images.json</a>.</p></details></aside></main><footer>Endless Museum / Forces / Same object, another capacity.</footer>'''
    (OUT / f"{p['id']}.html").write_text(page(p['title'], body), encoding='utf-8')

README = '''# Forces illustrated atlas

Open `index.html`. Each new plate opens a large reading page with previous/next navigation, its teaching purpose, inherited capacity and build status. The gallery also includes the thirteen existing Forces hall plates in canonical order.

- **10 newly generated plates:** eight proposed encounters and two six-panel speculative studies.
- **13 existing plates:** retained as current-hall companions, not counted as new work.
- **No museum runtime, canonical order, tutorial.md or final.md changes.**

## Image method and prompts

The ten new images were made with OpenAI's built-in image-generation tool, then selected after visual review and targeted edits. No programmatic image editing was used. Final PNGs are in `images/`; copied existing plates are in `current-halls/`.

`selected-images.json` records each saved path, original generation prompt, refinement prompts and source output path. `generation-prompts.json` records the original generation set; `prompts.json` is its earlier draft. `images.json` is the earlier selection record. **Use selected-images.json for the final selection.** Captions are editable in `captions.json`.

## Drawing limits

The images propose museum encounters. They are not measurements, screenshots, tested VR layouts or proof of working mechanics. Force, impulse and velocity are distinguished in captions. Arrow lengths are illustrative; the doubled-mass comparison requires half the velocity change for the same impulse. Course guide lines are routes rather than velocity vectors. The spring lesson begins with a one-dimensional guide; the last spring panel explores anchor placement. Two-hand flight is an accepted input design, still requiring implementation.

The beyond pages select twelve visual research directions. Some have existing relatives in the project; they are not an exhaustive source-code inventory or a claim that every pictured idea is new.

## Rebuild and check

In the repository, run `python doc/book/iterations/2026-10-06-forces-illustrated-atlas/build.py`. The script copies available source images without editing pixels, checks the canonical hall order, PNG dimensions, every local HTML link/anchor and ZIP integrity, and writes `manifest.json`. Existing copied images remain usable if generated-image cache paths are unavailable.

The ZIP contains the gallery, all 23 PNGs, captions and prompts. Extract it and open `index.html` without a server. Links to the larger manuscript/proposal use the local encyclopedia server and are separate from the portable atlas.
'''
(OUT / 'README.md').write_text(README, encoding='utf-8')

class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.urls = []; self.ids = set()
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if 'id' in a: self.ids.add(a['id'])
        self.urls += [a[k] for k in ('src','href') if k in a]

parsers = {}
for f in OUT.glob('*.html'):
    p = Links(); p.feed(f.read_text(encoding='utf-8')); parsers[f.resolve()] = p
links = 0
for f,p in parsers.items():
    for url in p.urls:
        u = urlsplit(url)
        if u.scheme: continue
        target = (f.parent / unquote(u.path)).resolve() if u.path else f
        if target.name not in ('forces-illustrated-atlas.zip','manifest.json'):
            assert target.is_file(), (f.name,url)
        if u.fragment:
            assert target in parsers and unquote(u.fragment) in parsers[target].ids, (f.name,url)
        links += 1

files = {}
for f in sorted(list((OUT / 'images').glob('*.png')) + list((OUT / 'current-halls').glob('*.png'))):
    data = f.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', f
    width,height = struct.unpack('>II', data[16:24])
    assert width > 0 and height > 0
    files[f.relative_to(OUT).as_posix()] = {'sha256':hashlib.sha256(data).hexdigest(),'width':width,'height':height,'bytes':len(data)}
assert len(files) == 23
manifest = {'new_plates':10,'existing_hall_plates':13,'total_images':23,'html_pages':len(parsers),'local_links_checked':links,'canonical_hall_order':'pass','image_headers':'pass','kind':'generated illustrations; no runtime certification','images':files}
(OUT / 'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
archive = OUT / 'forces-illustrated-atlas.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for f in sorted(OUT.rglob('*')):
        if f.is_file() and f.suffix != '.zip' and '__pycache__' not in f.parts:
            z.write(f,f.relative_to(OUT))
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len([n for n in z.namelist() if n.endswith('.png')]) == 23
    manifest['zip_crc'] = 'pass'
    manifest['zip_bytes'] = archive.stat().st_size
    manifest['zip_members'] = len(z.namelist())
(OUT / 'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in manifest.items() if k != 'images'},indent=2))
