"""Publish the image trial from explicit curation choices, without editing final.md."""
from pathlib import Path
from hashlib import sha256
from html import escape
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CHOICES = ROOT / 'commons/maps/Random_Definition/book_images.json'
choices = json.loads(CHOICES.read_text(encoding='utf8'))
source = ROOT / choices['text']
original = source.read_text(encoding='utf8')
figures = choices['images']
presets = [('outline', 'Fine outline'), ('hatch', 'Hatching'), ('ink', 'Solid ink')]
e = escape

CSS = '''
:root{--paper:#f3f0e7;--ink:#1a201c;--muted:#62685e;--rule:#c8c9ba;--accent:#49634c}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font:18px/1.7 Georgia,serif}a{color:inherit;text-underline-offset:.2em}a:hover{color:var(--accent)}
.shell{max-width:1420px;margin:auto;padding:30px 5vw 80px}.eyebrow,nav,.label,summary,.toolbar,figcaption,.meta{font:13px/1.5 system-ui,sans-serif}.eyebrow{letter-spacing:.14em;text-transform:uppercase;color:var(--muted)}
nav{display:flex;gap:24px;flex-wrap:wrap;padding-bottom:18px;border-bottom:1px solid var(--rule)}h1{font-size:clamp(36px,5vw,66px);font-weight:400;line-height:1.08;letter-spacing:-.04em;max-width:850px;margin:40px 0 24px}h2{font-size:30px;font-weight:400;line-height:1.2;margin:46px 0 20px}h3{font-size:23px;font-weight:400;margin:12px 0}.lede{font-size:23px;max-width:790px;line-height:1.55}.quiet{color:var(--muted)}.action{display:inline-block;border:1px solid var(--ink);padding:10px 20px;text-decoration:none;font:14px/1.5 system-ui,sans-serif;margin:12px 0 24px}
.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:26px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.card{min-width:0}figure{margin:0}img{width:100%;height:auto;display:block}figcaption{color:var(--muted);margin:12px 0 24px;max-width:650px}figcaption strong{color:var(--ink);font-weight:500}.plate{border-top:1px solid var(--rule);padding-top:12px}.rule{border-top:1px solid var(--rule);margin-top:45px;padding-top:24px}.small{font-size:16px}details{border-top:1px solid var(--rule);padding:18px 0}summary{cursor:pointer;font-size:15px}details p{max-width:850px}.method{max-width:840px}.question{border-left:2px solid var(--accent);padding-left:20px}code{font-size:.8em;overflow-wrap:anywhere}
.reader{padding-top:0}.book{max-width:700px;margin:48px auto}.book h1{font-size:56px;margin-top:28px}.book p{margin:0 0 1.25em}.book .figure{width:calc(100% + 120px);margin:36px -60px 42px}.book figcaption{text-align:center;max-width:none}.book figure img{max-height:590px;object-fit:contain}.book .footnote{font-size:14px;border-top:1px solid var(--rule);padding-top:22px;margin-top:40px}.book section+section{margin-top:45px}.book [id^=encounter]{scroll-margin-top:110px}.book [id^=encounter]:not(:first-of-type){margin-top:42px}.book h2{font-size:16px}.endnote{font:14px/1.6 system-ui,sans-serif;border-top:1px solid var(--rule);padding-top:24px;margin-top:48px;color:var(--muted)}
.toolbar{position:sticky;top:0;background:var(--paper);border-bottom:1px solid var(--rule);padding:12px 0;display:flex;gap:8px;align-items:center;flex-wrap:wrap;z-index:2}.toolbar .label{margin-right:8px}.toolbar label{border:1px solid var(--rule);border-radius:30px;padding:6px 12px;cursor:pointer}.toolbar a{margin-left:auto}.switch{position:absolute;left:-10000px}
.variant{display:none}#curated:checked~.book .variant.chosen,#outline:checked~.book .variant.outline,#hatch:checked~.book .variant.hatch,#ink:checked~.book .variant.ink{display:block}#none:checked~.book .figure{display:none}
#curated:checked~.toolbar label[for=curated],#outline:checked~.toolbar label[for=outline],#hatch:checked~.toolbar label[for=hatch],#ink:checked~.toolbar label[for=ink],#none:checked~.toolbar label[for=none]{background:var(--ink);color:var(--paper);border-color:var(--ink)}
#curated:focus-visible~.toolbar label[for=curated],#outline:focus-visible~.toolbar label[for=outline],#hatch:focus-visible~.toolbar label[for=hatch],#ink:focus-visible~.toolbar label[for=ink],#none:focus-visible~.toolbar label[for=none]{outline:3px solid #627e67;outline-offset:3px}
@media(max-width:800px){.grid{grid-template-columns:1fr}.pair{grid-template-columns:1fr}.shell{padding:20px 6vw 50px}.book{font-size:18px}.book h1{font-size:42px}.book .figure{width:100%;margin:28px 0}.toolbar a{margin-left:0}.toolbar{gap:5px}.toolbar label{padding:5px 9px}.lede{font-size:21px}}
@media print{nav,.toolbar,.endnote,.reading-meta{display:none}.book{max-width:none;margin:0;font-size:11pt}.book h1{font-size:28pt}.book .figure{width:100%;margin:18pt 0;break-inside:avoid}.book figure img{max-height:90mm}.shell{padding:0}a{text-decoration:none}}
'''

def document(title, body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+e(title)+'</title><style>'+CSS+'</style><body>'+body+'</body></html>'

def picture(item, preset, view='detail'):
    stem = item['id'] + ('-detail' if view == 'detail' else '')
    filename = f'{stem}-{preset}.png'
    assert (HERE / filename).is_file(), filename
    return f'<img src="{filename}" width="1600" height="1200" loading="lazy" alt="{e(item["alt"])}">'

def fragment(item):
    variants = ''.join('<div class="variant '+p+(' chosen' if p == item['treatment'] else '')+'">'+picture(item,p,item['view'])+'</div>' for p,_ in presets)
    return '<figure class="figure" id="illustration-'+e(item['id'])+'" data-artifact="'+e(item['artifact'])+'">'+variants+'<figcaption>'+e(item['caption'])+'</figcaption></figure>'

# Keep a byte-identical text snapshot. Anchor only inside the corresponding artifact.
shutil.copyfile(source, HERE / 'final-source.md')
parts = re.split(r'<!-- @([^>]*?) -->', original)
render_input = parts[0]
for index in range(1, len(parts), 2):
    artifact, section = parts[index].strip(), parts[index+1]
    if artifact:
        render_input += '\n\n<div id="encounter-'+artifact.replace('/','-')+'"></div>\n\n'
    for item in figures:
        if item['artifact'] != artifact:
            continue
        anchor = item['insert_after']
        assert section.count(anchor) == 1, 'Curation anchor changed: '+item['id']
        section = section.replace(anchor, anchor+'\n\n'+fragment(item), 1)
    render_input += section
book = markdown.markdown(render_input, extensions=['footnotes', 'tables'])
# Preserve the prose but resolve its two repository footnote links for this review route.
receipt = ROOT / 'algorithms/randomness/seed_replay/opening_seed.json'
shutil.copyfile(receipt, HERE / 'opening_seed.json')
book = book.replace('../../../algorithms/randomness/seed_replay/opening_seed.json', 'opening_seed.json')
book = book.replace('../../../doc/book/iterations/', '/book-review/doc/book/iterations/')
controls = ''.join(f'<input class="switch" type="radio" name="treatment" id="{id}"'+(' checked' if id=='curated' else '')+'>' for id in ['curated','outline','hatch','ink','none'])
controls += '<div class="toolbar" role="group" aria-label="Image treatment"><span class="label">Images</span>'+''.join(f'<label for="{id}">{label}</label>' for id,label in [('curated','Selected'),('outline','Outline'),('hatch','Hatching'),('ink','Ink'),('none','None')])+'<a href="index.html">Compare the images ↗</a></div>'
reader = '<div class="shell reader">'+controls+'<article class="book"><div class="eyebrow reading-meta">Random Definition · image trial 01</div>'+book+'<div class="endnote">The current final text, with three provisional image placements. Selected uses outline for the abacus and counter, ink for the page. <a href="index.html#curation">See what each image retains and removes</a>.</div></article></div>'
(HERE/'reading.html').write_text(document('What chance is allowed to do · image trial',reader),encoding='utf8')

# The selected illustrations in a quiet chapter layout. Keep the comparison desk separate.
illustrated = re.sub(r'<div class="variant ([^"]+)">(.*?)</div>',
    lambda match: match[2] if 'chosen' in match[1].split() else '', book, flags=re.S)
edition_style = '''<style>
.edition{max-width:1200px;margin:auto;padding:26px 6vw 90px}
.edition-nav{border:0;justify-content:space-between;gap:12px;color:var(--muted);font-size:12px}
.edition .book{max-width:650px;margin:56px auto 0;font-size:19px;line-height:1.75}
.edition .book h1{font-size:clamp(35px,4.6vw,53px);margin:16px 0 40px}
.edition .figure{width:100%;max-width:620px;margin:32px auto 40px;scroll-margin-top:32px;break-inside:avoid}
.edition .figure img{width:100%;max-height:420px;object-fit:contain}
.edition .figure figcaption{font:italic 14px/1.5 Georgia,serif;margin:12px auto 0;color:var(--muted)}
.edition #illustration-page{max-width:520px}
.edition #illustration-geiger{max-width:580px}
.edition .book .footnote{font-size:13px;line-height:1.6}
@media(max-width:700px){.edition{padding:20px 6vw 55px}.edition .book{font-size:18px;margin-top:30px}.edition .figure{margin:26px auto 32px}.edition .book h1{margin-bottom:30px}}
@media print{@page{size:A4;margin:22mm}.edition{padding:0}.edition-nav{display:none}.edition .book{max-width:none;margin:0;font-size:11pt;line-height:1.55}.edition .book h1{font-size:27pt;margin:12pt 0 28pt}.edition .figure img{max-height:75mm}.edition .figure{margin:18pt auto 22pt}.edition .figure figcaption{font-size:9pt}}
</style>'''
edition = edition_style+'<main class="edition"><nav class="edition-nav"><span>ADA RESEARCH / RANDOM DEFINITION</span><a href="#illustration-abacus">First illustration ↓</a><a href="reading.html">Compare with / without images ↗</a></nav><article class="book">'+illustrated+'</article></main>'
if (HERE/'illustrated-chapter.pdf').exists():
    edition = edition.replace('</nav>', '<a href="illustrated-chapter.pdf">Download PDF ↓</a></nav>', 1)
(HERE/'illustrated.html').write_text(document('What chance is allowed to do · Illustrated chapter',edition),encoding='utf8')

cards=''.join('<figure class="card plate"><div class="eyebrow">0'+str(i+1)+' / '+label+'</div>'+picture(figures[0],p)+'<figcaption>'+description+'</figcaption></figure>' for i,((p,label),description) in enumerate(zip(presets,[
    'Contours and traces remain. The bead becomes a boundary; much of its mass disappears.',
    'Hatching gives the bead weight. At a small printed size, the texture may compete with the recorded marks.',
    'Solid regions make a stronger interruption. The page benefits from this contrast; the cabinet becomes heavy.'
])))
curation=''
for n,item in enumerate(figures,1):
    curation += f'<section class="rule"><div class="eyebrow">{n:02d} / {e(item["artifact"])}</div><h3>{e(item["title"])}</h3><div class="pair"><figure>'+picture(item,item['treatment'],'full')+'<figcaption>Whole instrument · '+e(item['treatment'])+'</figcaption></figure><figure>'+picture(item,item['treatment'])+'<figcaption>Proposed fragment · <a href="reading.html#encounter-'+item['artifact'].replace('/','-')+'">Read in place ↗</a></figcaption></figure></div><div class="method small"><p><strong>Retain:</strong> '+e(item['keep'])+'</p><p><strong>Leave outside:</strong> '+e(item['omit'])+'</p><p class="quiet">'+e(item['limit'])+'</p><p class="question">'+e(item['question'])+'</p></div><details><summary>Compare all three treatments of this fragment</summary><div class="grid">'+''.join('<figure>'+picture(item,p)+'<figcaption>'+label+'</figcaption></figure>' for p,label in presets)+'</div></details><details><summary>Show the source capture</summary><div class="pair"><img src="'+item['id']+'-detail-source.png" width="1600" height="1200" loading="lazy" alt="Unfiltered isolated artifact capture"><div class="small"><p>The current Godot artifact, isolated from museum architecture. Labels are suppressed in the abacus and Geiger fragments. The page’s text halos are removed for printing.</p><p>This is an authored camera and staged state, not a record of a visitor’s response.</p></div></div></details></section>'

body = '<main class="shell"><nav><a href="reading.html">Read the illustrated text ↗</a><a href="#curation">Three placements</a><a href="#method">Curation method</a><a href="/long-museum/writing-wall?map=Random_Definition">Writing wall ↗</a></nav><div class="eyebrow" style="margin-top:35px">Ada Research / book image study / 16 October 2026</div><h1>Enough of the object.<br>Room for a world.</h1><p class="lede">A rod, a retained number, a gap between clicks. Can an image hold these relations while leaving the room to the reader’s imagination?</p><p class="method">Three treatments of actual artifact captures, in black and warm off-white. The first reading edition uses three fragments, placed where the text has already brought their procedures into view.</p><a class="action" href="reading.html">Read the full text · switch images on or off →</a><h2>One view, three treatments</h2><div class="grid">'+cards+'</div><p class="method">The outline is the quietest starting point. The number page needs stronger tonal contrast to distinguish the retained group. A single filter does not serve every encounter equally well.</p><section id="curation"><h2>Curating what the picture keeps</h2><p class="method">The crop is a decision about attention. These comparisons use the same artifact and saved state; camera framing and treatment change. MOVE / KEEP and the return journey remain without pictures in this trial.</p>'+curation+'</section><section class="rule method" id="method"><h2>From hall to book, and back</h2><p>Each choice is attached to the artifact’s stable ID and a particular passage in <code>final.md</code>. Its saved state, camera and filter recipe make the image rebuildable when the artifact changes. The current chapter and room are preserved.</p><p>The trial begins with a question: <em>what relation must survive the image?</em> For the abacus, it is the path and its marks. For the page, a selected group among other groups. For the counter, uneven intervals from a kept beginning.</p><ol><li>Keep an artifact state and choose the relation to retain.</li><li>Frame it, remove incidental interface detail, then apply a saved filter.</li><li>Read the unchanged passage with and without the image.</li><li>Record what becomes clearer, what becomes overdetermined and what disappears.</li><li>Revise the crop, passage or apparatus; retain the earlier version for comparison.</li></ol><p>First judgement: does a fragment support attention without prescribing the whole place? The filters are technically reproducible; their effect on imagination still needs a reading.</p><details><summary>Recipes, sources and rebuild instructions</summary><p><a href="curation.json">Curation choices</a> · <a href="filters.json">Filter recipe</a> · <a href="provenance.json">Source hashes</a> · <a href="capture-receipt.json">Camera and state receipt</a> · <a href="README.md">Rebuild instructions</a> · <a href="final-source.md">Unchanged text snapshot</a></p><p>No generated geometry or invented movement is added. Hatching is a print convention applied to existing dark regions. Monochrome deliberately discards colour; the Geiger image therefore cannot communicate its coloured output bits.</p></details></section></main>'
body = body.replace('href="reading.html">Read the illustrated text', 'href="illustrated.html">Read the illustrated text')
body = body.replace('href="reading.html">Read the full text · switch images on or off →', 'href="illustrated.html">Read the illustrated chapter →')
body = body.replace('href="reading.html#encounter-', 'href="illustrated.html#encounter-')
body = body.replace('Proposed fragment ·', 'Selected fragment ·')
body = body.replace('The first reading edition uses three fragments,', 'The selected reading edition uses three fragments,')
if (HERE/'illustrated-chapter.pdf').exists():
    body = body.replace('</nav>', '<a href="illustrated-chapter.pdf">Download PDF ↓</a></nav>', 1)
(HERE/'index.html').write_text(document('Book images · Random Definition',body),encoding='utf8')
shutil.copyfile(CHOICES,HERE/'curation.json')

paths=[source,CHOICES,ROOT/'tools/book_image_filter.gd',ROOT/'tools/book_image_filter.gdshader',HERE/'capture.gd',HERE/'filters.json',HERE/'publish.py',receipt]
for folder in ['commons/artifacts/random_touch','commons/artifacts/geiger_counter']:
    paths.extend(p for p in (ROOT/folder).rglob('*') if p.suffix in {'.gd','.tscn','.gdshader'})
paths.extend([ROOT/'algorithms/randomness/randomnumbergeneration/scripts/random_number_book_page_1995.gd',ROOT/'algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn'])
paths.extend([ROOT/'algorithms/randomness/seed_replay/seed_replay_demo.gd',HERE/'seed-values.gd',HERE/'seed-values.json',HERE/'make_pdf.py'])
paths.extend(HERE.glob('*.png'))
paths.extend(HERE.glob('*-state.json'))
paths.append(HERE/'capture-receipt.json')
hashes={p.relative_to(ROOT).as_posix():sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))}
(HERE/'provenance.json').write_text(json.dumps({'schema':'ada-book-image-provenance/1','source_text':choices['text'],'source_text_sha256':hashes[choices['text']],'artifacts':[i['artifact'] for i in figures],'illustrations':3,'filtered_images':18,'hashes':hashes,'qualification':'Saved hashes establish inputs for this published trial. Recapture and review after source changes; no automatic live update is claimed.'},indent=2)+'\n',encoding='utf8')
assert source.read_bytes()==(HERE/'final-source.md').read_bytes()
print('Published illustrated chapter, comparison and reading trial; 3 selected images, 18 variants; final.md unchanged.')
