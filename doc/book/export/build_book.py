"""Build the Ada Research book as a PDF from the spine chapters (one final.md per hall).

markdown -> one HTML with print CSS -> Chrome headless print-to-pdf (two passes, so the
contents page carries real page numbers) -> reportlab page-number overlay + pypdf outline.
"""
import json, os, re, sys, subprocess, hashlib, io, time, shutil
import markdown
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from PIL import Image

REPO = 'C:/Users/palle/Documents/GitHub/AdaResearch_46'
OUT = 'C:/Users/palle/AppData/Local/Temp/claude/C--Users-palle-Documents-GitHub-AdaResearch-46/8987ca3e-a19b-46d1-b00a-85888e1b0458/scratchpad/book'
os.makedirs(f'{OUT}/img', exist_ok=True)
os.chdir(REPO)
DATE = '25 September 2026'
COMMIT = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip()
CHROME = next(p for p in ['C:/Program Files/Google/Chrome/Application/chrome.exe',
                          'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'] if os.path.exists(p))

# ---------------------------------------------------------------- chapters in spine order
spine = sorted(json.load(open('commons/maps/curriculum_spine.json', encoding='utf-8'))['spine']['sequences'], key=lambda s: s['order'])
parts = []
for s in spine:
    sid = s['name']
    d = json.load(open(f'commons/maps/sequences/{sid}.json', encoding='utf-8'))
    d = d['sequences'][sid] if 'sequences' in d else d
    chapters = []
    for m in d['maps']:
        m = m if isinstance(m, str) else m.get('name')
        p = f'commons/maps/{m}/final.md'
        if not os.path.exists(p):
            continue
        txt = open(p, 'rb').read().decode('utf-8', 'replace').replace('\r\n', '\n')
        title_md = txt.split('\n', 1)[0][2:].strip() if txt.startswith('# ') else m.replace('_', ' ')
        body = txt.split('\n', 1)[1] if txt.startswith('# ') else txt
        chapters.append(dict(hall=m, title_md=title_md, body=body))
    parts.append(dict(id=sid, order=s['order'], name=d.get('name', sid), truth=d.get('truth', ''), chapters=chapters))
n_ch = sum(len(p['chapters']) for p in parts)
print(f'{len(parts)} parts, {n_ch} chapters')
WORDS = ['zero','one','two','three','four','five','six','seven','eight','nine','ten','eleven','twelve','thirteen','fourteen','fifteen','sixteen','seventeen','eighteen','nineteen','twenty','twenty-one','twenty-two','twenty-three','twenty-four','twenty-five','twenty-six','twenty-seven','twenty-eight','twenty-nine','thirty']
def words(n):
    if n < len(WORDS): return WORDS[n]
    if n < 100: return WORDS[20 + 0] if False else (WORDS[n // 10 * 10 // 10 * 10 // 10 + 18] if False else ['twenty','thirty','forty','fifty','sixty','seventy','eighty','ninety'][n // 10 - 2] + ('' if n % 10 == 0 else '-' + WORDS[n % 10]))
    return ('one hundred' if n < 200 else 'two hundred') + ('' if n % 100 == 0 else ' and ' + words(n % 100))
N_PARTS_W = words(len(parts)); N_CH_W = words(n_ch)

# ---------------------------------------------------------------- images: convert, bound, relink
missing = []
img_cache = {}


def image_url(src, hall):
    if src.startswith('/book-review/'):
        rel = src[len('/book-review/'):]
    elif src.startswith('/'):
        rel = src.lstrip('/')
    else:
        rel = f'commons/maps/{hall}/{src}'
    ap = os.path.join(REPO, rel)
    if not os.path.exists(ap):
        missing.append(rel)
        return None
    if ap in img_cache:
        return img_cache[ap]
    h = hashlib.md5(rel.encode()).hexdigest()[:10]
    try:
        im = Image.open(ap)
        im.load()
        if 'A' in im.getbands():
            bg = Image.new('RGB', im.size, (255, 255, 255))
            bg.paste(im.convert('RGBA'), mask=im.convert('RGBA').split()[-1])
            im = bg
        im = im.convert('RGB')
        if im.width > 1400:
            im = im.resize((1400, int(im.height * 1400 / im.width)), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, format='PNG', optimize=True)
        if buf.tell() < 350 * 1024:
            outp = f'{OUT}/img/{h}.png'
            open(outp, 'wb').write(buf.getvalue())
        else:
            outp = f'{OUT}/img/{h}.jpg'
            im.save(outp, format='JPEG', quality=85, optimize=True, subsampling=0)
    except Exception as e:
        print('  image failed', rel, e)
        missing.append(rel)
        return None
    url = 'file:///' + outp.replace('\\', '/')
    img_cache[ap] = url
    return url


MOJIBAKE = [('â†’', '→'), ('â€™', '’'), ('â€œ', '“'), ('â€\u009d', '”'),
            ('â€”', '—'), ('â€“', '–'), ('Ã©', 'é'), ('Ã¶', 'ö'), ('Ã¥', 'å'), ('Ã¤', 'ä')]
repaired = {}


def repair(md_text, hall):
    for bad, good in MOJIBAKE:
        if bad in md_text:
            repaired[hall] = repaired.get(hall, 0) + md_text.count(bad)
            md_text = md_text.replace(bad, good)
    return md_text


def relink(md_text, hall):
    md_text = repair(md_text, hall)

    def sub(m):
        url = image_url(m.group(2), hall)
        if url is None:
            return f'*[figure not in the tree: {m.group(2)}]*'
        return f'![{m.group(1)}]({url})'
    md_text = re.sub(r'!\[([^\]]*)\]\(([^)\s]+)\)', sub, md_text)

    def link(m):
        text, target = m.group(1), m.group(2)
        if target.startswith(('http://', 'https://', '#', 'mailto:')):
            return m.group(0)
        if '/doc/' in target or target.startswith('doc/'):
            path = re.sub(r'^(\.\./)+', '', target).split('#')[0]
            return f'{text} <span class="path">({path})</span>'
        return text          # encyclopedia deep links: the text alone
    return re.sub(r'(?<!!)\[([^\]]+)\]\(([^)\s]+)\)', link, md_text)


# ---------------------------------------------------------------- markdown
MD = markdown.Markdown(extensions=['footnotes', 'fenced_code', 'tables', 'attr_list', 'sane_lists'],
                       extension_configs={'footnotes': {'UNIQUE_IDS': True, 'BACKLINK_TEXT': '\u21a9'}})


def md_inline(s):
    MD.reset()
    h = MD.convert(s).strip()
    return re.sub(r'^<p>|</p>$', '', h)


def plain(s):
    return re.sub(r'<[^>]+>', '', md_inline(s))


CSS = '''
@page { size: A4; margin: 22mm 30mm 24mm 30mm; }
html { -webkit-print-color-adjust: exact; }
body { font-family: Cambria, Georgia, "Times New Roman", serif; font-size: 11pt; line-height: 1.5; color: #111; margin: 0; }
.path { font-size: 8.5pt; color: #666; }
.title-page { text-align: center; padding-top: 38%; page-break-after: always; }
.title-page .t { font-size: 34pt; letter-spacing: 1px; }
.title-page .s { font-size: 13pt; margin-top: 14pt; color: #333; }
.title-page .m { font-size: 9.5pt; margin-top: 60pt; color: #666; }
.toc { page-break-after: always; }
.toc h2 { font-size: 16pt; margin: 0 0 12pt 0; }
.toc .part { margin-top: 9pt; font-weight: bold; font-size: 10pt; display: flex; }
.toc .ch { display: flex; font-size: 9.4pt; margin-left: 14pt; }
.toc .t { flex: 1; }
.toc .p { margin-left: 10pt; min-width: 22pt; text-align: right; color: #333; }
.part-page { page-break-before: always; text-align: center; padding-top: 36%; }
.part-page .n { font-size: 10pt; color: #777; letter-spacing: 2px; text-transform: uppercase; }
.part-page h1 { font-size: 24pt; margin: 10pt 0 14pt 0; }
.part-page .truth { font-style: italic; color: #444; max-width: 80%; margin: 0 auto; font-size: 11pt; }
.chapter { page-break-before: always; }
.chapter h1 { font-size: 17.5pt; line-height: 1.2; margin: 0 0 4pt 0; }
.chapter .hall { font-size: 8.5pt; color: #888; margin: 0 0 16pt 0; letter-spacing: 0.5px; }
h2 { font-size: 12.5pt; margin: 16pt 0 6pt 0; page-break-after: avoid; }
p { margin: 0 0 7pt 0; orphans: 3; widows: 3; }
pre { font-family: Consolas, "Courier New", monospace; font-size: 9.4pt; line-height: 1.35; background: #f4f3f1; border: 0.5pt solid #d0cdc8; padding: 6pt 8pt; white-space: pre-wrap; word-wrap: break-word; page-break-inside: avoid; margin: 6pt 0 10pt 0; }
code { font-family: Consolas, "Courier New", monospace; font-size: 0.92em; }
p code { background: #f4f3f1; padding: 0 2pt; }
img { max-width: 100%; max-height: 120mm; height: auto; display: block; margin: 9pt auto 4pt auto; page-break-inside: avoid; }
p > em:only-child { color: #444; }
blockquote { margin: 6pt 18pt 8pt 18pt; color: #444; }
.footnote { font-size: 8.4pt; line-height: 1.35; margin-top: 16pt; color: #222; }
.footnote hr { border: 0; border-top: 0.5pt solid #999; width: 28%; margin: 0 0 6pt 0; }
.footnote ol { padding-left: 16pt; margin: 0; }
.footnote li { margin-bottom: 3pt; }
.footnote-backref { text-decoration: none; }
sup { line-height: 0; }
a { color: inherit; text-decoration: none; }
table { border-collapse: collapse; font-size: 9.3pt; margin: 6pt 0 9pt 0; }
td, th { border: 0.5pt solid #aaa; padding: 2pt 5pt; vertical-align: top; }
.mark { font-size: 6pt; color: #fff; }
.chapter h1, .part-page h1 { page-break-after: avoid; }
'''


def build_html(page_of=None):
    """page_of: dict marker -> page number for the contents (second pass)."""
    out = ['<!DOCTYPE html><html><head><meta charset="utf-8"><title>Ada Research, the book</title>',
           f'<style>{CSS}</style></head><body>']
    out.append('<div class="title-page"><div class="t">Ada Research</div>'
               f'<div class="s">The book of the museum: {N_PARTS_W} sequences, {N_CH_W} halls</div>'
               f'<div class="m">Compiled from the working tree on {DATE}, at commit {COMMIT}.<br>'
               'Every chapter is a hall walked in the headset; the names arrive after the hall has performed the thing.</div></div>')
    # contents
    out.append('<div class="toc"><h2>Contents</h2>')
    ci = 0
    for pi, part in enumerate(parts):
        pn = page_of.get(f'PT{pi:02d}', '') if page_of else ''
        out.append(f'<div class="part"><span class="t">{part["order"]}. {part["name"]}</span><span class="p">{pn}</span></div>')
        for ch in part['chapters']:
            pn = page_of.get(f'CH{ci:03d}', '') if page_of else ''
            out.append(f'<div class="ch"><span class="t">{md_inline(ch["title_md"])}</span><span class="p">{pn}</span></div>')
            ci += 1
    out.append('</div>')
    # parts and chapters
    ci = 0
    for pi, part in enumerate(parts):
        out.append(f'<div class="part-page"><div class="n">Sequence {part["order"]} of 24 <span class="mark">[[PT{pi:02d}]]</span></div>'
                   f'<h1>{part["name"]}</h1></div>')
        for ch in part['chapters']:
            MD.reset()
            body_html = MD.convert(relink(ch['body'], ch['hall']))
            out.append(f'<div class="chapter"><h1>{md_inline(ch["title_md"])}</h1>'
                       f'<div class="hall">{ch["hall"].replace("_", " ")} <span class="mark">[[CH{ci:03d}]]</span></div>{body_html}</div>')
            ci += 1
    out.append('</body></html>')
    return '\n'.join(out)


def render(html_path, pdf_path):
    if os.path.exists(pdf_path):
        os.remove(pdf_path)
    prof = f'{OUT}/chrome-profile'
    cmd = [CHROME, '--headless=new', '--disable-gpu', '--disable-extensions', f'--user-data-dir={prof}',
           '--no-pdf-header-footer', '--run-all-compositor-stages-before-draw', '--virtual-time-budget=60000',
           f'--print-to-pdf={pdf_path}', 'file:///' + html_path.replace('\\', '/')]
    t0 = time.time()
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
    ok = os.path.exists(pdf_path) and os.path.getsize(pdf_path) > 10000
    print(f'  render {os.path.basename(pdf_path)}: {"ok" if ok else "FAILED"} in {time.time() - t0:.0f} s, rc {r.returncode}, {os.path.getsize(pdf_path) // 1024 if ok else 0} KB')
    if not ok:
        print(r.stderr[-1500:])
        sys.exit(1)


def locate(pdf_path):
    reader = PdfReader(pdf_path)
    found = {}
    pat = re.compile(r'\[\[(PT\d\d|CH\d\d\d)\]\]')
    for i, page in enumerate(reader.pages):
        try:
            t = page.extract_text() or ''
        except Exception:
            t = ''
        for m in pat.finditer(re.sub(r'\s+', '', t)):
            found.setdefault(m.group(1), i + 1)   # 1-based
    return found, len(reader.pages)


# ---------------------------------------------------------------- pass 1
html1 = f'{OUT}/book_pass1.html'
open(html1, 'w', encoding='utf-8').write(build_html())
pdf1 = f'{OUT}/book_pass1.pdf'
render(html1, pdf1)
found1, n1 = locate(pdf1)
print(f'  pass 1: {n1} pages, {len(found1)} markers found of {len(parts) + n_ch}')

# ---------------------------------------------------------------- pass 2 with numbered contents
html2 = f'{OUT}/book_pass2.html'
open(html2, 'w', encoding='utf-8').write(build_html(found1))
pdf2 = f'{OUT}/book_pass2.pdf'
render(html2, pdf2)
found2, n2 = locate(pdf2)
drift = sum(1 for k in found1 if found2.get(k) != found1[k])
print(f'  pass 2: {n2} pages, markers that moved between passes: {drift}')

# ---------------------------------------------------------------- page numbers, outline, metadata
reader = PdfReader(pdf2)
n = len(reader.pages)
buf = io.BytesIO()
c = canvas.Canvas(buf, pagesize=A4)
for i in range(n):
    if i > 0:
        c.setFont('Helvetica', 8.5)
        c.setFillGray(0.35)
        c.drawCentredString(A4[0] / 2, 30, str(i + 1))
    c.showPage()
c.save()
buf.seek(0)
overlay = PdfReader(buf)
writer = PdfWriter()
for i, page in enumerate(reader.pages):
    page.merge_page(overlay.pages[i])
    wp = writer.add_page(page)
    wp.compress_content_streams()
toc_item = writer.add_outline_item('Contents', 1)
ci = 0
for pi, part in enumerate(parts):
    pp = found2.get(f'PT{pi:02d}')
    pitem = writer.add_outline_item(f'{part["order"]}. {part["name"]}', (pp or 1) - 1)
    for ch in part['chapters']:
        cp = found2.get(f'CH{ci:03d}')
        if cp:
            writer.add_outline_item(plain(ch['title_md']), cp - 1, parent=pitem)
        ci += 1
writer.add_metadata({'/Title': 'Ada Research: the book of the museum', '/Author': 'Ada Research, Palle Torsson',
                     '/Subject': f'{N_PARTS_W.capitalize()} sequences, {n_ch} halls; compiled {DATE} at commit {COMMIT}',
                     '/Creator': 'build_book.py (markdown, Chrome, reportlab, pypdf)'})
final = f'{OUT}/AdaResearch_Book_2026-09-25.pdf'
with open(final, 'wb') as f:
    writer.write(f)
print(f'FINAL {final}: {n} pages, {os.path.getsize(final) // (1024 * 1024)} MB')
print('double-encoded characters repaired in the export (fix the sources):', repaired)
print('missing figures:', len(set(missing)))
for m in sorted(set(missing)):
    print('   ', m)
