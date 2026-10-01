"""Check every printed page and render a targeted visual proof set."""
from pathlib import Path
import collections
import json
import re
import sys
import unicodedata
import fitz
from bs4 import BeautifulSoup
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding='utf-8')
pdf_path = ROOT / 'output/pdf/AdaResearch_Reading_Proof_2026-09-30.pdf'
manifest_path = ROOT / 'output/pdf/reading-proof-2026-09-30-manifest.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
out = ROOT / 'tmp/pdfs/reading-proof-2026-09-30/qa'
out.mkdir(parents=True, exist_ok=True)
issues = []
pages = []
pdf = fitz.open(pdf_path)
for number, page in enumerate(pdf, 1):
    text = page.get_text()
    spans = [s for b in page.get_text('dict')['blocks'] if 'lines' in b for line in b['lines'] for s in line['spans']]
    visible = [s for s in spans if s['size'] > 2 and s['color'] != 16777215]
    outside = [s for s in visible if s['bbox'][0] < 20 or s['bbox'][2] > page.rect.width - 20 or s['bbox'][1] < 15 or s['bbox'][3] > page.rect.height - 15]
    if outside:
        issues.append(dict(page=number, issue='Text outside safe page area', text=[s['text'] for s in outside]))
    if '\ufffd' in text or '\x00' in text:
        issues.append(dict(page=number, issue='Replacement glyph in extraction'))
    if '~~' in text or re.search(r'\[\^[\w-]+\]', text):
        issues.append(dict(page=number, issue='Unrendered Markdown syntax'))
    useful = [s for s in visible if not (s['bbox'][1] > 790)]
    if not useful and not page.get_images():
        issues.append(dict(page=number, issue='Blank page'))
    pages.append(dict(page=number, words=len(text.split()), images=len(page.get_image_info()),
        bottom=round(max([s['bbox'][3] for s in useful] or [0]),1),
        code_lines=sum('Consolas' in s['font'] for s in useful)))

# Representative proof pages, plus all pages flagged by the automated checks.
selected = {1,2,3,4,8,len(pdf),len(pdf)-1}
for d in manifest['sections']:
    if any(k in d['source'] for k in ['preface.md','day-zero.md','Point_Zero/','Point_One/','Point_Triangle_Context/',
        'Trans_Rotation/','Color_Nails/','Shader_10_ReactionDiffusion/','CA_Introduction/','QFEP_Introduction/','afterword-qfep.md']):
        selected.update([d['page'], min(d['page']+1,len(pdf))])
selected.update(p['page'] for p in sorted(pages,key=lambda p:p['code_lines'],reverse=True)[:5])
selected.update(p['page'] for p in sorted(pages,key=lambda p:p['images'],reverse=True)[:5])
selected.update(i['page'] for i in issues)
for n in sorted(selected):
    pdf[n-1].get_pixmap(matrix=fitz.Matrix(1.25,1.25), alpha=False).save(str(out/f'page-{n:03d}.png'))

# Whole-book contact sheets reveal gross pagination problems without sampling.
for start in range(0,len(pdf),30):
    sheet=Image.new('RGB',(5*200,6*301),'#ccc')
    draw=ImageDraw.Draw(sheet)
    for offset in range(min(30,len(pdf)-start)):
        pix=pdf[start+offset].get_pixmap(matrix=fitz.Matrix(.30,.30),alpha=False)
        im=Image.frombytes('RGB',(pix.width,pix.height),pix.samples)
        x=(offset%5)*200+10;y=(offset//5)*301+22
        sheet.paste(im,(x,y))
        draw.text((x,y-17),str(start+offset+1),fill='black')
    sheet.save(out/f'contact-{start+1:03d}.jpg',quality=85)

source_html = BeautifulSoup((out.parent/'print.html').read_text(encoding='utf-8'),'html.parser')
for link in source_html.select('.footnote-backref'):
    link.decompose()
normal = lambda text: re.sub(r'\s+', '', unicodedata.normalize('NFKC', text).replace('\u00ad','').replace('\u200b',''))
unmatched = []
checked = 0
sections = manifest['sections']
for i, section in enumerate(sections):
    end = sections[i+1]['page']-1 if i+1 < len(sections) else len(pdf)
    actual = normal(''.join(pdf[n].get_text(clip=fitz.Rect(0,0,pdf[n].rect.width,795)) for n in range(section['page']-1,end)))
    for element in source_html.find(id=section['key']).find_all(['p','pre','h1','h2','h3','figcaption','td','th']):
        if element.find_parent('pre') or element.find_parent('figcaption'):
            continue
        expected = normal(element.get_text())
        if len(expected) < 12:
            continue
        checked += 1
        if expected not in actual:
            unmatched.append(dict(section=section['key'], text=element.get_text()[:160]))
if unmatched:
    issues.append(dict(issue='Manuscript text blocks missing from PDF extraction', details=unmatched))
ids = [node['id'] for node in source_html.find_all(id=True)]
refs = [node['href'][1:] for node in source_html.select('a[href^="#"]')]
if len(ids) != len(set(ids)) or set(refs)-set(ids):
    issues.append(dict(issue='Duplicate IDs or broken internal links in assembled book'))
if any('[[CH' in p.get_text() or '[[FR' in p.get_text() for p in pdf):
    issues.append(dict(issue='Internal measurement markers remain in final PDF'))
report=dict(pdf=str(pdf_path),pages=len(pdf),issues=issues,rendered_pages=sorted(selected),page_metrics=pages,
    text_blocks_checked=checked, unmatched_text_blocks=unmatched, bookmarks=len(pdf.get_toc()),
    figures_in_html=len(source_html.find_all('img')), code_blocks=len(source_html.find_all('pre')))
(out/'checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['page_metrics','pdf']},indent=2))
if issues:
    raise SystemExit(1)
