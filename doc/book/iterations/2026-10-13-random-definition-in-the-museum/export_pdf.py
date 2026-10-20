"""Export the current illustrated reading, preserving its prose and six captures."""
from pathlib import Path
import html
import re
import shutil
from reportlab.pdfgen.canvas import Canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUTPUT = ROOT / 'output/pdf/random-definition-illustrated.pdf'
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
P = (HERE / 'draft.md').read_text(encoding='utf-8').strip().split('\n\n')
assert len(P) == 12
for name, file in [('Georgia', 'georgia.ttf'), ('GeorgiaItalic', 'georgiai.ttf'), ('GeorgiaBold', 'georgiab.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(Path('C:/Windows/Fonts') / file)))
pdfmetrics.registerFontFamily('Georgia', normal='Georgia', italic='GeorgiaItalic', bold='GeorgiaBold')

INK = colors.HexColor('#282c29')
MUTED = colors.HexColor('#626b65')
GREEN = colors.HexColor('#276458')
PAPER = colors.HexColor('#faf8f2')
W, H = A4
M = 48
CW = W - M * 2
styles = {
    'body': ParagraphStyle('body', fontName='Georgia', fontSize=11.2, leading=17.1, textColor=INK),
    'caption': ParagraphStyle('caption', fontName='Helvetica', fontSize=8.4, leading=12, textColor=MUTED),
    'note': ParagraphStyle('note', fontName='Helvetica', fontSize=9.3, leading=14, textColor=MUTED),
}
c = Canvas(str(OUTPUT), pagesize=A4, pageCompression=1)
c.setTitle('A pattern that returns - Random Definition')
c.setAuthor('Ada Research / Endless Museum')
c.setSubject('Illustrated reflective review draft, 13 October 2026')
y = 0

def inline(text):
    return re.sub(r'\*([^*]+)\*', r'<i>\1</i>', html.escape(text).replace('—', '-').replace('–', '-'))

def paragraph(text, kind='body', x=M, width=CW, gap=13, raw=False):
    global y
    p = Paragraph(text if raw else inline(text), styles[kind])
    _, height = p.wrap(width, H)
    assert y-height >= 52, f'Page overflow: {text[:70]}'
    p.drawOn(c, x, y-height)
    y -= height+gap

def begin(page, label):
    global y
    c.setFillColor(PAPER)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(GREEN)
    c.setFont('Helvetica', 8)
    c.drawString(M, H-31, 'ENDLESS MUSEUM / RANDOM DEFINITION')
    c.setFillColor(MUTED)
    c.drawRightString(W-M, H-31, label.upper())
    c.setStrokeColor(colors.HexColor('#d9d9cf'))
    c.line(M, 40, W-M, 40)
    c.setFont('Helvetica', 8)
    c.drawString(M, 26, 'Ada Research / Illustrated review draft / 13 October 2026')
    c.drawRightString(W-M, 26, f'{page} / 4')
    y = H-67

def heading(text, size=25):
    global y
    c.setFont('Georgia', size)
    c.setFillColor(INK)
    c.drawString(M, y-size, text)
    y -= size+23

def image(name, caption, width=CW, x=M):
    global y
    ih = width*2/3
    assert y-ih > 85
    c.drawImage(str(HERE/'images'/f'{name}.png'), x, y-ih, width=width, height=ih, preserveAspectRatio=True)
    y -= ih+8
    paragraph(caption, 'caption', x=x, width=width, gap=17)

def pair(items):
    global y
    top = y
    width = (CW-16)/2
    bottoms = []
    for i, (name, caption) in enumerate(items):
        y = top
        image(name, caption, width, M+i*(width+16))
        bottoms.append(y)
    y = min(bottoms)

begin(1, 'Hold the ball')
heading('A pattern that returns', 30)
paragraph('A reflective reading with photographs from Endless Museum.', 'note', gap=24)
for text in P[:2]:
    paragraph(text)
y -= 6
pair([
    ('sphere-centre', 'Centre: the start and end of each excursion. The sphere is paused for this photograph.'),
    ('sphere-out', 'Destination: direction and distance vary. Two paused positions locate the journey; they do not show the experience of being carried.'),
])
paragraph(P[2])
c.showPage()

begin(2, 'An arrangement returns')
heading('An arrangement returns')
for text in P[3:5]:
    paragraph(text)
pair([
    ('seed-before', 'Four by four. Same seed, same requests: both grids recover the same arrangement.'),
    ('seed-after', 'Same seed, one discarded draw. The right grid assigns the stream differently; the left stays.'),
])
for text in P[5:7]:
    paragraph(text)
c.showPage()

begin(3, 'A page that lets go')
heading('A page that lets go')
paragraph(P[7])
image('number-page', 'The museum page and passage to Entropy. A cell can be held while other digits fall. This still shows the installation; its movement unfolds in time.', width=350, x=(W-350)/2)
for text in P[8:]:
    paragraph(text)
c.showPage()

begin(4, 'Later: 10 PRINT')
heading('The same choices, different figures')
paragraph('Appendix: a look ahead. Visit Definition, then Entropy, then Remove, then 10 PRINT. The reflection hands over to Entropy; the textile comparison belongs to the later hall.', 'note', gap=21)
image('textiles-in-ten-print', 'In 10 PRINT: the same seeded draws become large/small blocks, upright/horizontal bars and diagonals.')
y -= 12
paragraph('About this edition', 'note', gap=7)
paragraph('The 622-word reflection also appears in Random Definition/final.md. Its imagined sleeve is an unbuilt extension. Tutorial code and construction instructions remain in the companion tutorial.', 'note')
paragraph('The six images are unaltered Godot screenshots. The sphere was paused for its two photographs. Existing interaction reports are retained; these images do not establish headset experience.', 'note')
paragraph('Historical source: <link href="https://www.rand.org/pubs/monograph_reports/MR1418.html" color="#276458">RAND, A Million Random Digits with 100,000 Normal Deviates</link>, introduction and production account.', 'note', raw=True)
c.save()

reader = PdfReader(str(OUTPUT))
assert len(reader.pages) == 4
text = '\n'.join(page.extract_text() for page in reader.pages)
normal = lambda s: re.sub(r'\s+', ' ', s.replace('*', '').replace('—', '-').replace('–', '-')).strip()
for para in P:
    assert normal(para) in normal(text), f'Missing paragraph: {para[:50]}'
assert sum(len(page.images) for page in reader.pages) == 6
assert 'Next: 10 PRINT'.upper() not in text
shutil.copyfile(OUTPUT, HERE / OUTPUT.name)
print(f'Created {OUTPUT}: 4 pages, all 12 draft paragraphs, 6 images.')
