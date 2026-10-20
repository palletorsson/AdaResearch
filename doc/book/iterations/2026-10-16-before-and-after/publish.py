"""Reader revision: captured images, numerical evidence and a labelled schematic."""
from pathlib import Path
from hashlib import sha256
from html import escape as e
import json, re, shutil
import markdown
from bs4 import BeautifulSoup
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, KeepTogether, PageBreak, Table, TableStyle, HRFlowable
from reportlab.graphics.shapes import Drawing, Circle, Line, String, Rect
from reportlab.graphics import renderSVG
from pypdf import PdfReader

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
SOURCE=HERE/'final-source.md'  # Freeze this edition; later canonical edits must not rewrite it.
text=SOURCE.read_text(encoding='utf8')
before=(HERE/'before/final.md').read_text(encoding='utf8')
choices=json.loads((HERE/'curation.json').read_text(encoding='utf8'))
seed=json.loads((HERE/'seed-values.json').read_text(encoding='utf8'))
values=seed['window_first_ten_values']; groups=seed['book_first_ten_groups']
rgb=[round(v*255) for v in values[:3]]
swatch='#'+''.join(f'{v:02x}' for v in rgb)
INK=colors.HexColor('#1a201c'); PAPER=colors.HexColor('#f3f0e7'); MUTED=colors.HexColor('#62685e'); RULE=colors.HexColor('#c5c7b9')
WIDTH,HEIGHT=180*mm,250*mm; MARGIN=24*mm; TEXT_WIDTH=WIDTH-2*MARGIN

# This is a rule diagram. No path, pose or event is represented as a captured trial.
plate=Drawing(TEXT_WIDTH,162)
for i,(label,bx) in enumerate([('HELD',72),('RELEASED',115),('RETURNED',18)]):
    ox=i*TEXT_WIDTH/3+3
    plate.add(String(ox,147,label,fontName='Helvetica',fontSize=9,fillColor=MUTED))
    plate.add(Line(ox+18,102,ox+115,102,strokeColor=RULE,strokeWidth=.75))
    plate.add(Circle(ox+18,102,9,strokeColor=MUTED,fillColor=None,strokeWidth=.8))
    plate.add(Circle(ox+bx,102,6,strokeColor=INK,fillColor=INK))
    plate.add(Rect(ox+66,49,12,18,strokeColor=INK,fillColor=None,strokeWidth=1))
    if i==0: plate.add(Line(ox+72,67,ox+72,96,strokeColor=INK,strokeWidth=.9))
    if i==1:
        plate.add(Line(ox+91,119,ox+110,119,strokeColor=INK,strokeWidth=.9))
        plate.add(Line(ox+106,122,ox+110,119,strokeColor=INK,strokeWidth=.9))
    if i==2:
        plate.add(Line(ox+91,119,ox+29,119,strokeColor=INK,strokeWidth=.9))
        plate.add(Line(ox+33,122,ox+29,119,strokeColor=INK,strokeWidth=.9))
plate.add(String(3,17,'Filled circle: sphere   /   open rectangle: visitor   /   open ring: centre',fontName='Helvetica',fontSize=8,fillColor=MUTED))
renderSVG.drawToFile(plate,str(HERE/'release-return.svg'))

CSS='''
:root{--paper:#f3f0e7;--ink:#1a201c;--muted:#62685e;--line:#c5c7b9}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.75 Georgia,serif}main{max-width:1400px;margin:auto;padding:28px 5vw 75px}a{color:inherit;text-underline-offset:.2em}nav{display:flex;gap:24px;flex-wrap:wrap;font:13px/1.5 system-ui;border-bottom:1px solid var(--line);padding-bottom:18px}h1{font-size:clamp(36px,5vw,60px);font-weight:400;line-height:1.12;max-width:850px}h2{font-weight:400;line-height:1.3;font-size:28px}.eyebrow,summary,.meta{font:13px/1.6 system-ui;color:var(--muted)}.book{max-width:650px;margin:50px auto}.book p{margin:0 0 1.25em}.book h1{font-size:46px}.figure{margin:32px 0 40px;scroll-margin-top:25px}img{max-width:100%;height:auto;display:block}.figure img{max-height:420px;object-fit:contain;margin:auto}.figure figcaption{text-align:center;font:italic 14px/1.55 Georgia,serif;margin-top:10px}.note,.footnote{font-size:14px;line-height:1.6;color:var(--muted);border-top:1px solid var(--line);padding-top:22px;margin-top:32px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:45px}.pair article{min-width:0}.pair p{font-size:17px}.pair h2{position:sticky;top:0;background:var(--paper);padding:12px 0;border-bottom:1px solid var(--line)}section{border-top:1px solid var(--line);padding-top:25px;margin-top:36px}table{border-collapse:collapse;width:100%;font:14px/1.5 ui-monospace,monospace;margin:20px 0}td,th{padding:9px 12px;text-align:left;border-bottom:1px solid var(--line)}.rgb{display:flex;gap:20px;align-items:center;border:1px solid var(--line);padding:18px;margin:18px 0}.swatch{width:60px;height:60px;flex-shrink:0;border:1px solid var(--ink)}.reference{font-size:16px;line-height:1.6;border-block:1px solid var(--line);margin:40px 0;padding:20px 0}details{margin:20px 0}summary{cursor:pointer}.lede{font-size:23px;max-width:820px}@media(max-width:800px){.pair{grid-template-columns:1fr}.pair h2{position:static}.book{margin-top:30px}main{padding:20px 6vw 60px}}
'''
def doc(title,body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+e(title)+'</title><style>'+CSS+'</style><body><main>'+body+'</main></body></html>'
def html_md(value,namespace=''):
    out=markdown.markdown(value,extensions=['footnotes','tables'])
    out=out.replace('../../../algorithms/randomness/seed_replay/opening_seed.json','opening_seed.json').replace('../../../doc/book/iterations/','/book-review/doc/book/iterations/').replace('href="tutorial.md"','href="/book-review/commons/maps/Random_Definition/tutorial.md"')
    if namespace:
        out=re.sub(r'(id=")(fn[^\"]+)',lambda m:m[1]+namespace+'-'+m[2],out)
        out=re.sub(r'(href="#)(fn[^\"]+)',lambda m:m[1]+namespace+'-'+m[2],out)
    return out
def relative(path):
    import os
    return Path(os.path.relpath(ROOT/path,HERE)).as_posix()
def picture(item):
    path=ROOT/item['image']
    assert sha256(path.read_bytes()).hexdigest()==item['image_sha256']
    return '<figure class="figure" id="illustration-'+item['id']+'"><a href="'+e(relative(item['image']))+'"><img src="'+e(relative(item['image']))+'" alt="'+e(item['alt'])+'"></a><figcaption>'+e(item['caption'])+'</figcaption></figure>'

comparisons={item['id']:item for item in choices['comparisons']}
after_captions={
    'abacus':'After 48 segments on each row: 576 marks remain. Four speeds, the same X record; the fifth row adds Y.',
    'page':'After holding 33442 at printed row 3, third group from the left, and advancing two rows. The held digits become outlined in this monochrome rendering.'
}
def pair_html(item):
    follow=comparisons[item['id']]
    assert sha256((ROOT/follow['after_image']).read_bytes()).hexdigest()==follow['after_sha256']
    return '<div class="comparison" id="comparison-'+item['id']+'"><div class="eyebrow">BEFORE / AFTER · SAME CAMERA AND FILTER</div><div class="capture-pair">'+picture(item)+'<figure class="figure"><a href="'+relative(follow['after_image'])+'"><img src="'+relative(follow['after_image'])+'" alt="'+e(after_captions[item['id']])+'"></a><figcaption>'+e(after_captions[item['id']])+'</figcaption></figure></div><p class="meta">Scripted continuation of the saved baseline, reconstructed exactly. These are native artifact captures, not a visitor trial. <a href="captures/capture.json">Protocol and state record</a>.</p></div>'

CSS+='''.comparison{margin:36px 0}.capture-pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}.capture-pair .figure{margin:16px 0}.capture-pair img{max-height:none}.book:has(.comparison){max-width:850px}.book>p{max-width:650px;margin-left:auto;margin-right:auto}.book>.footnote{max-width:650px;margin-left:auto;margin-right:auto}.capture-pair figure a{display:block}.book h1{max-width:650px;margin-left:auto;margin-right:auto}@media(max-width:700px){.capture-pair{grid-template-columns:1fr}}'''
rgb_html='<div class="rgb"><span class="swatch" style="background:'+swatch+'" aria-label="Numerical RGB swatch"></span><div>Draws 1–3 → RGB<br><code>'+', '.join(f'{v:.6f}' for v in values[:3])+'</code><br>On the page: <code>'+' · '.join(groups[:3])+'</code></div></div>'
table='<table><thead><tr><th>Draw</th><th>Window channel</th><th>Page group</th></tr></thead><tbody>'+''.join(f'<tr><td>{i+1}</td><td>{v:.6f}</td><td>{g}</td></tr>' for i,(v,g) in enumerate(zip(values,groups)))+'</tbody></table>'
reference='<aside class="reference" id="reference"><div class="eyebrow">NUMERICAL REFERENCE / ONE KEPT BEGINNING</div><h2>The first ten from 435</h2><p>One draw supplies one five-digit group on the page. The baseline window takes three draws for one RGB cell: red, green and blue.</p>'+rgb_html+'<details><summary>Inspect all ten values and the conversion</summary>'+table+'<p>The values shown here are rounded to six decimals. Page groups truncate the full values after five fractional digits, keeping leading zeros. The folio consumes no draw. This swatch represents the numerical RGB assignment, not the illuminated appearance of a captured pane.</p><p><a href="seed-values.json">Godot verification: four seeds, actual window channels and page groups.</a></p></details></aside>'
schematic='<figure class="figure" id="release-study"><img src="release-return.svg" alt="Three schematic states: visitor and sphere together, separation after release, sphere back at centre"><figcaption>Rule study: the sphere returns; the released visitor need not.</figcaption></figure>'
colophon_paras=[
    'The three baseline monochrome images are unchanged Godot captures also used on the hall walls. The abacus and counter were captured on arrival. The number page began with ten rows from 435 and was captured only after all 28 rows filled and settled. No group was held for that photograph; no trace was added to the abacus.',
    'Two further captures follow scripted interactions with those artifacts. Reconstructed baselines match the original images pixel for pixel. The abacus keeps 48 segments per row; the page keeps 33442 while two rows pass. Camera and filter stay fixed. These are controlled comparisons, not records of a visitor’s experience.',
    'The numerical table preserves relationships checked against the program. Its values are evidence; its colour swatch is a representation. The release diagram isolates a rule with authored positions. The prose constructs a possible encounter.',
    'Each form keeps something different. A photograph loses duration and colour; the table leaves the apparatus out; the diagram leaves out the room and the possible actions after release. These choices can be changed and compared. The book is another recorder.'
]
colophon='<section class="note"><h2>Another recorder</h2>'+''.join('<p>'+e(p)+'</p>' for p in colophon_paras)+'</section>'
chapter,notes=text.split('<!-- @ -->',1)
parts=re.split(r'<!-- @([^>]*?) -->',chapter)
rendered=html_md(parts[0])
for i in range(1,len(parts),2):
    artifact,section=parts[i].strip(),parts[i+1]
    for item in choices['images']:
        if item['artifact']==artifact:
            assert section.count(item['insert_after'])==1
            section=section.replace(item['insert_after'],item['insert_after']+'\n\n'+(pair_html(item) if item['id'] in comparisons else picture(item)))
    rendered += section
    if artifact=='geiger_counter': rendered+='\n\n'+reference+'\n\n'
    if artifact=='random_return': rendered+='\n\n'+schematic+'\n\n'
rendered=html_md(rendered+'\n\n'+notes)
nav='<nav><a href="index.html">Revision and evidence</a><a href="compare.html">Before / revised</a><a href="illustrated-chapter.pdf">Download PDF</a><a href="/long-museum/writing-wall?map=Random_Definition">Writing wall</a></nav>'
(HERE/'illustrated.html').write_text(doc('What chance is allowed to do · Before and after',nav+'<article class="book">'+rendered+colophon+'</article>'),encoding='utf8')
(HERE/'compare.html').write_text(doc('Recorder edition and comparison trial',nav+'<h1>A baseline, then a consequence.</h1><p>The prose changes only to clarify the Gaussian resemblance. Two recorded comparisons and a larger release diagram change what can be examined alongside it.</p><p><a href="before/illustrated-chapter.pdf">Previous eight-page PDF</a> · <a href="illustrated-chapter.pdf">Revised eight-page PDF</a></p><div class="pair"><article><h2>Recorder edition</h2>'+html_md(before,'before')+'</article><article><h2>Comparison trial</h2>'+html_md(text,'revised')+'</article></div>'),encoding='utf8')

for name,file in [('Book','georgia.ttf'),('BookItalic','georgiai.ttf'),('BookBold','georgiab.ttf')]: pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file))
pdfmetrics.registerFontFamily('Book',normal='Book',bold='BookBold',italic='BookItalic',boldItalic='BookBold')
pdfmetrics.registerFont(TTFont('Mono','C:/Windows/Fonts/consola.ttf'))
styles={
    'body':ParagraphStyle('body',fontName='Book',fontSize=10.8,leading=16.2,textColor=INK,spaceAfter=10,allowWidows=0,allowOrphans=0),
    'title':ParagraphStyle('title',fontName='Book',fontSize=31,leading=34,textColor=INK,spaceAfter=24),
    'sub':ParagraphStyle('sub',fontName='Book',fontSize=23,leading=28,textColor=INK,spaceAfter=18),
    'label':ParagraphStyle('label',fontName='Helvetica',fontSize=8,leading=11,textColor=MUTED,spaceAfter=13),
    'caption':ParagraphStyle('caption',fontName='BookItalic',fontSize=8.5,leading=12,textColor=MUTED,alignment=1,spaceAfter=16),
    'note':ParagraphStyle('note',fontName='Book',fontSize=8.5,leading=12.5,textColor=MUTED,spaceAfter=9),
}
note_ids=re.findall(r'^\[\^(\w+)\]:',notes,re.M)
def para(value,style='body'):
    for n,id in enumerate(note_ids,1): value=value.replace('[^'+id+']',f'<super>{n}</super>')
    soup=BeautifulSoup(markdown.markdown(value),'html.parser')
    for tag in soup.find_all('a'):
        if tag.get('href','').startswith('https://'): tag.name='link';tag['color']='#354e3b'
        else: tag.unwrap()
    for tag in soup.find_all('em'):tag.name='i'
    for tag in soup.find_all('strong'):tag.name='b'
    for tag in soup.find_all('p'):tag.unwrap()
    return Paragraph(str(soup).replace('\u2011','-'),styles[style])
def reference_story():
    rows=[['Draw','Window channel','Page group']]+[[str(i+1),f'{v:.6f}',g] for i,(v,g) in enumerate(zip(values,groups))]
    t=Table(rows,colWidths=[20*mm,55*mm,57*mm],rowHeights=[12*mm]+[8*mm]*10)
    t.setStyle(TableStyle([('FONTNAME',(0,0),(-1,0),'Helvetica'),('FONTNAME',(0,1),(-1,-1),'Mono'),('FONTSIZE',(0,0),(-1,-1),9),('VALIGN',(0,0),(-1,-1),'MIDDLE'),('TEXTCOLOR',(0,0),(-1,-1),INK),('LINEBELOW',(0,0),(-1,-1),.3,RULE)]))
    return [para('NUMERICAL REFERENCE / ONE KEPT BEGINNING','label'),para('The first ten from 435','sub'),t,Spacer(1,19),para('Values are displayed to six decimal places. Page groups truncate the full value after five fractional digits and retain leading zeros. The folio is independent and consumes no draw. The preceding swatch shows the numerical RGB assignment, not a photographed or colour-calibrated pane.','note'),para('Verified in Godot 4.6 against actual window channels and page rows at seeds 0, 435, 436 and 999. Reset repeats the values; changing the folio preserves the stream. The complete receipt is retained with this edition.','note')]

def rgb_plate():
    c=Drawing(TEXT_WIDTH,80)
    c.add(Rect(0,8,60,60,fillColor=colors.Color(*values[:3]),strokeColor=INK,strokeWidth=.5))
    c.add(String(76,64,'Draws 1–3 become RGB',fontName='Book',fontSize=10,fillColor=INK))
    c.add(String(76,42,', '.join(f'{v:.6f}' for v in values[:3]),fontName='Mono',fontSize=9,fillColor=INK))
    c.add(String(76,20,'On the page: '+' · '.join(groups[:3]),fontName='Mono',fontSize=9,fillColor=INK))
    return c

def capture_image(path,width):
    im=Image(str(ROOT/path),width=width*mm,height=width*.75*mm);im.hAlign='CENTER';return im

def comparison_story(id,stacked=False):
    original=next(x for x in choices['images'] if x['id']==id)
    following=comparisons[id]
    if stacked:
        return [para('A PAGE / TWO MOMENTS','label'),capture_image(original['image'],100),para('Before selection. '+original['caption'],'caption'),capture_image(following['after_image'],100),para(after_captions[id],'caption'),para('Scripted continuation from the saved state. Same camera and filter. Printed row numbers begin at zero.','note')]
    table=Table([[capture_image(original['image'],57),capture_image(following['after_image'],57)],[para('Before touch. Five rods.','caption'),para('After 48 segments per row.','caption')]],colWidths=[TEXT_WIDTH/2]*2)
    table.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),0),('RIGHTPADDING',(0,0),(-1,-1),0)]))
    return [para('ONE BEGINNING / TWO RECORDS','label'),table,para('576 marks per row, through scripted contact. The contour filter preserves edges, not the original darkness.','note')]

blocks={parts[i].strip():re.split(r'\n\s*\n',parts[i+1].strip()) for i in range(1,len(parts),2)}
a=blocks['random_touch'];b=blocks['random_number_book_page_1955'];g=blocks['geiger_counter'];m=blocks['seed_replay_demo/movement_sampler'];r=blocks['random_return']
# Eight deliberately composed pages. The numerical reference begins on page 5,
# occupying the previously accidental gap; the ending keeps its own larger diagram.
story=[Spacer(1,7*mm),para('What chance is<br/>allowed to do','title')]
story += [para(v) for v in a[:4]]
story += [PageBreak()]+comparison_story('abacus')+[para(v) for v in a[4:]+b[:2]]
story += [PageBreak()]+comparison_story('page',stacked=True)
geiger=next(x for x in choices['images'] if x['id']=='geiger')
story += [PageBreak()]+[para(v) for v in b[2:]+g[:4]]
story += [PageBreak(),capture_image(geiger['image'],75),para(geiger['caption'],'caption')]+[para(v) for v in g[4:]]+[Spacer(1,8),rgb_plate(),para('Three draws assign red, green and blue to one window cell. Each draw also supplies one five-digit group on the page. The full numerical reference follows.','note')]
story += [PageBreak()]+reference_story()+[Spacer(1,12),para(m[0])]
story += [PageBreak()]+[para(v) for v in m[1:]+r]+[Spacer(1,8),plate,para('Rule study: the sphere returns; the released visitor need not.','caption')]
story += [PageBreak(),para('COLOPHON / WHAT THE BOOK KEEPS','label'),para('Another recorder','sub')]+[para(v,'note') for v in colophon_paras]+[Spacer(1,10),HRFlowable(width='100%',thickness=.35,color=RULE),Spacer(1,15),para('RESEARCH NOTES','label')]
for n,match in enumerate(re.finditer(r'^\[\^(\w+)\]:\s*(.+)$',notes,re.M),1): story.append(para(f'<b>{n}.</b> '+match[2],'note'))
def decorate(canvas,document):
    canvas.saveState();canvas.setFillColor(PAPER);canvas.rect(0,0,WIDTH,HEIGHT,fill=1,stroke=0);canvas.setFillColor(MUTED);canvas.setFont('Helvetica',7);canvas.drawString(MARGIN,HEIGHT-13*mm,'ADA RESEARCH');canvas.drawRightString(WIDTH-MARGIN,HEIGHT-13*mm,'RANDOM DEFINITION');canvas.setStrokeColor(RULE);canvas.setLineWidth(.35);canvas.line(MARGIN,17*mm,WIDTH-MARGIN,17*mm);canvas.setFont('BookItalic',7.5);canvas.drawString(MARGIN,12*mm,'What chance is allowed to do');canvas.setFont('Helvetica',7.5);canvas.drawRightString(WIDTH-MARGIN,12*mm,str(document.page));canvas.restoreState()
out=ROOT/'output/pdf/what-chance-is-allowed-to-do-before-and-after.pdf'
SimpleDocTemplate(str(out),pagesize=(WIDTH,HEIGHT),rightMargin=MARGIN,leftMargin=MARGIN,topMargin=23*mm,bottomMargin=24*mm,title='What chance is allowed to do',author='Ada Research').build(story,onFirstPage=decorate,onLaterPages=decorate)
shutil.copyfile(out,HERE/'illustrated-chapter.pdf')
reader=PdfReader(out);extracted='\n'.join(p.extract_text() or '' for p in reader.pages)
assert all(g in extracted for g in groups)
assert 'Here, randomness is domesticated.' not in extracted
assert 'It returns to the centre.' in extracted
assert '33442' in extracted
assert len(reader.pages)==8, f'Unexpected overflow: {len(reader.pages)} pages'
def count(value):return len(re.findall(r"\b[\w]+(?:['’][\w]+)*\b",re.sub(r'<!--.*?-->|\[[^]]+\]\([^)]+\)', '',value.split('<!-- @ -->')[0],flags=re.S)))
receipt={'source_sha256':sha256(SOURCE.read_bytes()).hexdigest(),'pdf_sha256':sha256(out.read_bytes()).hexdigest(),'pages':len(reader.pages),'prose_words':{'before':count(before),'revised':count(text)},'gem_budget':[600,1500],'illustrations':{x['id']:x['image_sha256'] for x in choices['images']},'comparison_images':{x['id']:x['after_sha256'] for x in choices['comparisons']},'release_diagram':'authored rule schematic, enlarged to 162pt high; not a recorded path','rgb':{'draws':[1,2,3],'channels':values[:3],'page_groups':groups[:3],'html_srgb8':rgb,'scope':'numerical assignment, not screen radiometry'},'review_status':'new reading trial; author response pending'}
(HERE/'publication.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
index=nav+'<div class="eyebrow">RANDOM DEFINITION / 16 OCTOBER 2026</div><h1>Before, and what remains.</h1><p class="lede">The original arrival pictures now meet recorded consequences: marks after movement, and five digits kept while the page moves on.</p><p><a href="illustrated.html">Read the complete illustrated chapter</a> · <a href="illustrated-chapter.pdf">Eight-page PDF</a> · <a href="before/illustrated-chapter.pdf">Previous recorder edition</a></p><section><h2>Two comparisons</h2><p>The saved starting states were reconstructed in the actual Godot scenes. Their rendered images match the original captures pixel for pixel. Scripted contact then produced the second images. The camera, lighting and filter did not change.</p>'+''.join(pair_html(x) for x in choices['images'] if x['id'] in comparisons)+'</section><section><h2>What the book changes</h2><p>“Five paths” becomes “Five rods.” The abacus paragraph distinguishes a Gaussian-looking concentration from the uniform target selection actually used. Page 5 now carries the RGB transformation into the numerical reference. The final rule diagram has more space. The release ending remains verbatim.</p><p>The original three wall pictures remain unchanged. MOVE / KEEP is restored at its saved position and the prior actual-hall verification remains available. The 48-value bench remains the first research pilot. Room and final keep the same order.</p>'+schematic+'</section><section><h2>The next reading</h2><p>Can the paired page make it evident which digits were kept and which moved, before its caption is read? Can the two abacus pictures reveal a consequence without letting the still picture pretend to convey speed?</p><p><a href="supplied-reading.md">Supplied critique</a> · <a href="README.md">Decisions and limits</a> · <a href="captures/capture.json">32 native capture checks and protocols</a> · <a href="museum-report.json">Prior actual-hall checks</a> · <a href="compare.html">Prose before / after</a></p></section>'
index += '<section><h2>MOVE / KEEP, restored</h2><figure><img src="move-keep-restored.png" alt="Restored movement sampler in the actual hall, with six traces and a dark sphere"><figcaption class="meta">Native desktop capture at its saved location. Restart the museum to load the revised map.</figcaption></figure></section>'
(HERE/'index.html').write_text(doc('The book is another recorder · Ada Research',index),encoding='utf8')
print(json.dumps(receipt,indent=2))
