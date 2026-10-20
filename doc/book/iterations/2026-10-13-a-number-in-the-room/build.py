"""Publish the canonical reflection with actual museum captures; no prose rewrite."""
from pathlib import Path
import html
import json
import re
import shutil
import hashlib
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'commons/maps/Random_Definition/final.md'
text = SOURCE.read_text(encoding='utf-8')
without_markers = re.sub(r'<!--.*?-->\s*', '', text, flags=re.S)
body = re.split(r'^\[\^.*?\]:', without_markers, maxsplit=1, flags=re.M)[0]
paragraphs = [p.strip() for p in body.split('\n\n') if p.strip() and not p.startswith('#')]
assert len(paragraphs) == 12
plain = [re.sub(r'\[\^[^]]+\]', '', p).replace('*', '') for p in paragraphs]
(HERE / 'draft.md').write_text('# A pattern that returns\n\n' + '\n\n'.join(plain) + '\n', encoding='utf-8')
photos = ROOT / 'ada_run/encounter_pilot/Random_Definition/opening-number-photos-20261013'
run = ROOT / 'ada_run/encounter_pilot/Random_Definition/opening-number-20261013'
for filename in ['opening-435.png', 'one-draw-later.png']:
    shutil.copy2(photos / filename, HERE / filename)
shutil.copy2(run / 'number-display.png', HERE / 'number-display.png')
shutil.copy2(run / 'report.json', HERE / 'runtime-report.json')
shutil.copy2(photos / 'report.json', HERE / 'photograph-report.json')
for report in [run / 'report.json', photos / 'report.json']:
    data = json.loads(report.read_text(encoding='utf-8'))
    assert data['passed'] and not data['failures']

captions = {
    'number-display.png': '435: the saved atmospheric draw, with its source and receipt date.',
    'opening-435.png': 'Before: the same seed and requests give matching colour grids.',
    'one-draw-later.png': 'After +1 DRAW: 435 stays. Only the right grid starts one draw later.',
}
notes = [
    ('atmosphere', 'RANDOM.ORG describes its atmospheric source and bounded integer requests in its HTTP interface documentation. The displayed 435 is a saved response received on 13 October 2026. Godot generates the cube colours locally.', 'https://www.random.org/clients/http/api/'),
    ('rand-1955', 'RAND, A Million Random Digits with 100,000 Normal Deviates (1955), introduction and production account. The museum page recalls the book; its falling digits are an authored behaviour of this installation.', 'https://www.rand.org/pubs/monograph_reports/MR1418.html'),
]

def markup(p):
    p = html.escape(p)
    p = re.sub(r'\*([^*]+)\*', r'<i>\1</i>', p)
    return re.sub(r'\[\^([^]]+)\]', r'<sup><a href="#note-\1">*</a></sup>', p)

def figure(name):
    return f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(captions[name])}"></a><figcaption>{captions[name]}</figcaption></figure>'

article = []
for i, p in enumerate(paragraphs):
    article.append('<p>' + markup(p) + '</p>')
    if i == 0:
        article.append(figure('number-display.png'))
    if i == 3:
        article.append('<div class="comparison">' + figure('opening-435.png') + figure('one-draw-later.png') + '</div>')
note_html = ''.join(f'<p id="note-{key}">{html.escape(note)} <a href="{url}">Source</a></p>' for key, note, url in notes)
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>A pattern that returns · Random Definition</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f2e9;color:#24221f;font:20px/1.65 Georgia,serif}
header,footer{max-width:1080px;margin:40px auto;padding:0 24px}nav,small,figcaption,.notes{font:14px/1.5 system-ui,sans-serif}
nav{display:flex;gap:22px;flex-wrap:wrap}a{color:#7b3e2a}h1{font-size:clamp(34px,5vw,62px);font-weight:normal;line-height:1.1;margin:24px 0}
article{max-width:1080px;padding:0 24px;margin:auto}article>p{max-width:700px;margin:24px auto}figure{margin:22px auto;max-width:700px}
img{width:100%;display:block}figcaption{padding-top:8px;color:#534d43}.comparison{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin:32px 0}
.comparison figure{margin:0}.notes{max-width:700px;margin:40px auto;border-top:1px solid #c4baab;padding-top:15px}
footer{border-top:1px solid #c4baab;color:#5d554a}sup{font:11px system-ui}@media(max-width:700px){.comparison{grid-template-columns:1fr}body{font-size:18px}}</style>
<header><nav><a href="random-definition-number-first.pdf">Download PDF</a><a href="../../../../commons/maps/Random_Definition/tutorial.md">Tutorial source</a><a href="../../course/text-plans/Random_Definition/final.md">Writing plan</a></nav>
<p><small>ADA RESEARCH / ENDLESS MUSEUM / RANDOMNESS</small></p><h1>A pattern that returns</h1><small>Random Definition · reflection · illustrated with the actual museum</small></header>
<article>''' + '\n'.join(article) + '<aside class="notes">' + note_html + '''</aside></article>
<footer><p><small>Reading edition: 13 October 2026. The prose is the complete current final.md. Captures use the saved response 435; no new request was needed to make this comparison. <a href="runtime-report.json">64 runtime checks passed</a>; <a href="photograph-report.json">7 photograph checks passed</a>. These are desktop Godot checks, not headset or learner validation.</small></p></footer></html>'''
(HERE / 'index.html').write_text(page, encoding='utf-8')

# Three deliberately paced pages: arrival, a changed request, the room of relations.
for name, file in [('Georgia', 'georgia.ttf'), ('Georgia-Italic', 'georgiai.ttf'), ('Georgia-Bold', 'georgiab.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(Path('C:/Windows/Fonts') / file)))
pdfmetrics.registerFontFamily('Georgia', normal='Georgia', bold='Georgia-Bold', italic='Georgia-Italic', boldItalic='Georgia-Bold')
outdir = ROOT / 'output/pdf'
outdir.mkdir(parents=True, exist_ok=True)
pdf = outdir / 'random-definition-number-first.pdf'
c = canvas.Canvas(str(pdf), pagesize=(595.276, 841.89))
c.setTitle('A pattern that returns - Random Definition')
c.setAuthor('Ada Research / Endless Museum')
style = ParagraphStyle('Body', fontName='Georgia', fontSize=10.6, leading=15.6, textColor=colors.HexColor('#24221f'), alignment=TA_LEFT)
caption_style = ParagraphStyle('Caption', fontName='Helvetica', fontSize=8.2, leading=11, textColor=colors.HexColor('#55504b'))
note_style = ParagraphStyle('Note', fontName='Georgia', fontSize=8.5, leading=12, textColor=colors.HexColor('#48423b'))
LEFT, WIDTH = 52, 491.276

def ascii_dash(s):
    return s.replace('—', '-').replace('–', '-').replace('\u2011', '-')

def para(p, y, s=style, x=LEFT, width=WIDTH):
    p = html.escape(ascii_dash(p))
    p = re.sub(r'\*([^*]+)\*', r'<i>\1</i>', p)
    p = re.sub(r'\[\^atmosphere\]', '<super>1</super>', p)
    p = re.sub(r'\[\^rand-1955\]', '<super>2</super>', p)
    obj = Paragraph(p, s)
    _, height = obj.wrap(width, 800)
    assert y - height > 48, f'Paragraph falls off page: {p[:45]}'
    obj.drawOn(c, x, y-height)
    return y-height-12

def picture(name, y, x=LEFT, width=WIDTH, caption=True):
    reader = ImageReader(str(HERE / name))
    w, h = reader.getSize()
    height = width*h/w
    c.drawImage(reader, x, y-height, width=width, height=height)
    y -= height+7
    if caption:
        y = para(captions[name], y, caption_style, x, width)
    return y-5

def page_header(n):
    c.setFillColor(colors.HexColor('#6c6051'))
    c.setFont('Helvetica', 8)
    c.drawString(LEFT, 803, 'ADA RESEARCH  /  RANDOMNESS  /  RANDOM DEFINITION')
    c.drawRightString(543, 29, str(n))
    return 772

y = page_header(1)
c.setFont('Georgia', 26)
c.setFillColor(colors.HexColor('#24221f'))
c.drawString(LEFT, y-24, 'A pattern that returns')
y -= 48
y = para(paragraphs[0], y)
y = picture('number-display.png', y, x=95, width=405)
for p in paragraphs[1:3]:
    y = para(p, y)
c.showPage()
y = page_header(2)
y = para(paragraphs[3], y)
half = (WIDTH-15)/2
y = min(picture('opening-435.png', y, width=half), picture('one-draw-later.png', y, x=LEFT+half+15, width=half))
for p in paragraphs[4:7]:
    y = para(p, y)
c.showPage()
y = page_header(3)
for p in paragraphs[7:]:
    y = para(p, y)
y -= 12
for i, (_, note, url) in enumerate(notes, 1):
    y = para(f'{i}. {note}', y, note_style)
    c.linkURL(url, (LEFT, y+8, LEFT+WIDTH, y+50), relative=0, thickness=0)
y = para('13 October 2026. Complete reflective text; actual museum screenshots. The tutorial supplies the runnable example and a worked number trace.', y-8, caption_style)
c.save()
shutil.copy2(pdf, HERE / pdf.name)

reader = PdfReader(str(pdf))
assert len(reader.pages) == 3
extracted = '\n'.join(p.extract_text() for p in reader.pages)
def normalize(p):
    p = ascii_dash(p).replace('’', "'")
    return re.sub(r'\W+', '', p, flags=re.UNICODE).lower()
for i, p in enumerate(plain):
    # Footnote digits interrupt extraction immediately after the cited sentences.
    expected = normalize(p)
    found = normalize(extracted)
    if i == 0:
        found = found.replace('number1weasked', 'numberweasked')
    if i == 5:
        found = found.replace('publication2', 'publication')
    assert expected in found, f'Missing PDF paragraph {i+1}'
provenance = {
    'canonical': str(SOURCE), 'canonical_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'body_word_count': sum(len(p.split()) for p in plain), 'paragraphs': len(plain),
    'pdf_pages': 3, 'complete_prose_verified': True,
    'images': {name: hashlib.sha256((HERE/name).read_bytes()).hexdigest() for name in captions},
    'capture_run': str(photos), 'runtime_run': str(run),
    'scope': 'Desktop museum. Saved real response 435. Headset network and hand reach unverified.',
}
(HERE / 'provenance.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'pdf': str(pdf), 'html': str(HERE / 'index.html'), 'body_words': provenance['body_word_count'], 'pages': 3, 'paragraphs_verified': 12}))
