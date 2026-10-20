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
SOURCE=ROOT/'commons/maps/Random_Definition/final.md'
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
plate=Drawing(TEXT_WIDTH,90)
for i,(label,bx) in enumerate([('HELD',72),('RELEASED',115),('RETURNED',18)]):
    ox=i*TEXT_WIDTH/3+3
    plate.add(String(ox,82,label,fontName='Helvetica',fontSize=8,fillColor=MUTED))
    plate.add(Line(ox+18,53,ox+115,53,strokeColor=RULE,strokeWidth=.65))
    plate.add(Circle(ox+18,53,7,strokeColor=MUTED,fillColor=None,strokeWidth=.65))
    plate.add(Circle(ox+bx,53,4,strokeColor=INK,fillColor=INK))
    plate.add(Rect(ox+68,26,8,12,strokeColor=INK,fillColor=None,strokeWidth=.7))
    if i==0: plate.add(Line(ox+72,38,ox+72,49,strokeColor=INK,strokeWidth=.7))
    if i==1:
        plate.add(Line(ox+91,63,ox+110,63,strokeColor=INK,strokeWidth=.7))
        plate.add(Line(ox+106,66,ox+110,63,strokeColor=INK,strokeWidth=.7))
    if i==2:
        plate.add(Line(ox+91,63,ox+29,63,strokeColor=INK,strokeWidth=.7))
        plate.add(Line(ox+33,66,ox+29,63,strokeColor=INK,strokeWidth=.7))
plate.add(String(3,6,'Filled circle: sphere   /   open square: visitor   /   open ring: centre',fontName='Helvetica',fontSize=7,fillColor=MUTED))
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
    return '<figure class="figure" id="illustration-'+item['id']+'"><img src="'+e(relative(item['image']))+'" alt="'+e(item['alt'])+'"><figcaption>'+e(item['caption'])+'</figcaption></figure>'
rgb_html='<div class="rgb"><span class="swatch" style="background:'+swatch+'" aria-label="Numerical RGB swatch"></span><div>Draws 1–3 → RGB<br><code>'+', '.join(f'{v:.6f}' for v in values[:3])+'</code><br>On the page: <code>'+' · '.join(groups[:3])+'</code></div></div>'
table='<table><thead><tr><th>Draw</th><th>Window channel</th><th>Page group</th></tr></thead><tbody>'+''.join(f'<tr><td>{i+1}</td><td>{v:.6f}</td><td>{g}</td></tr>' for i,(v,g) in enumerate(zip(values,groups)))+'</tbody></table>'
reference='<aside class="reference" id="reference"><div class="eyebrow">NUMERICAL REFERENCE / ONE KEPT BEGINNING</div><h2>The first ten from 435</h2><p>One draw supplies one five-digit group on the page. The baseline window takes three draws for one RGB cell: red, green and blue.</p>'+rgb_html+'<details><summary>Inspect all ten values and the conversion</summary>'+table+'<p>The values shown here are rounded to six decimals. Page groups truncate the full values after five fractional digits, keeping leading zeros. The folio consumes no draw. This swatch represents the numerical RGB assignment, not the illuminated appearance of a captured pane.</p><p><a href="seed-values.json">Godot verification: four seeds, actual window channels and page groups.</a></p></details></aside>'
schematic='<figure class="figure" id="release-study"><img src="release-return.svg" alt="Three schematic states: visitor and sphere together, separation after release, sphere back at centre"><figcaption>Rule study: the sphere returns; the released visitor need not.</figcaption></figure>'
colophon='''<section class="note"><h2>What the book keeps</h2><p>The three monochrome images are unchanged Godot captures also used on the hall walls. The abacus and counter were captured on arrival. The number page began with ten rows from 435 and was captured only after all 28 rows filled and settled. No group was held for that photograph; no trace was added to the abacus.</p><p>The numerical table preserves exact relationships checked against the program. Its values are evidence; its colour swatch is a representation. The release diagram isolates a rule with authored positions. It is a schematic, not a recorded route or a wall photograph.</p><p>Each form keeps something different. A photograph loses duration and colour; the table leaves the apparatus out; the diagram leaves out the room and the possible actions after release. These choices can be changed and compared. The book is another recorder.</p></section>'''
chapter,notes=text.split('<!-- @ -->',1)
parts=re.split(r'<!-- @([^>]*?) -->',chapter)
rendered=html_md(parts[0])
for i in range(1,len(parts),2):
    artifact,section=parts[i].strip(),parts[i+1]
    for item in choices['images']:
        if item['artifact']==artifact:
            assert section.count(item['insert_after'])==1
            section=section.replace(item['insert_after'],item['insert_after']+'\n\n'+picture(item))
    rendered += section
    if artifact=='geiger_counter': rendered+='\n\n'+reference+'\n\n'
    if artifact=='random_return': rendered+='\n\n'+schematic+'\n\n'
rendered=html_md(rendered+'\n\n'+notes)
nav='<nav><a href="index.html">Revision and evidence</a><a href="compare.html">Before / revised</a><a href="illustrated-chapter.pdf">Download PDF</a><a href="/long-museum/writing-wall?map=Random_Definition">Writing wall</a></nav>'
(HERE/'illustrated.html').write_text(doc('What chance is allowed to do · The book as recorder',nav+'<article class="book">'+rendered+colophon+'</article>'),encoding='utf8')
(HERE/'compare.html').write_text(doc('Before and revised · What chance is allowed to do',nav+'<h1>Let the return happen.</h1><p>The opening, RAND passage and Geiger explanation remain. The movement passage is shorter; details move into a note. The conclusion becomes a release and a return.</p><div class="pair"><article><h2>Before</h2>'+html_md(before,'before')+'</article><article><h2>Revised</h2>'+html_md(text,'revised')+'</article></div>'),encoding='utf8')

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
    t=Table(rows,colWidths=[20*mm,55*mm,57*mm],rowHeights=[12*mm]+[7*mm]*10)
    t.setStyle(TableStyle([('FONTNAME',(0,0),(-1,0),'Helvetica'),('FONTNAME',(0,1),(-1,-1),'Mono'),('FONTSIZE',(0,0),(-1,-1),9),('VALIGN',(0,0),(-1,-1),'MIDDLE'),('TEXTCOLOR',(0,0),(-1,-1),INK),('LINEBELOW',(0,0),(-1,-1),.3,RULE)]))
    c=Drawing(TEXT_WIDTH,54);c.add(Rect(0,5,42,42,fillColor=colors.Color(*values[:3]),strokeColor=INK,strokeWidth=.5));c.add(String(58,35,'Draws 1-3: RGB',fontName='Helvetica',fontSize=9,fillColor=INK));c.add(String(58,18,', '.join(f'{v:.6f}' for v in values[:3]),fontName='Mono',fontSize=9,fillColor=INK))
    return [PageBreak(),para('NUMERICAL REFERENCE / ONE KEPT BEGINNING','label'),para('The first ten from 435','sub'),para('The baseline window takes three draws for one RGB cell: red, green and blue. The page gives each draw its own five-digit group.'),c,Spacer(1,14),t,Spacer(1,15),para('Values are displayed to six decimal places. Page groups truncate the full value after five fractional digits and retain leading zeros. The folio is independent and consumes no draw. The swatch shows the numerical RGB assignment, not a photographed or colour-calibrated pane.','note'),para('Verified in Godot 4.6 against actual window channels and page rows at seeds 0, 435, 436 and 999. Reset repeats the values; changing the folio preserves the stream. The complete receipt is retained with this edition.','note'),PageBreak()]
story=[Spacer(1,7*mm),para('What chance is<br/>allowed to do','title')]
inserted=[]
for i in range(1,len(parts),2):
    artifact,section=parts[i].strip(),parts[i+1]
    for block in re.split(r'\n\s*\n',section.strip()):
        story.append(para(block))
        for item in choices['images']:
            if item['artifact']==artifact and block.endswith(item['insert_after']):
                im=Image(str(ROOT/item['image']),width=110*mm,height=82.5*mm);im.hAlign='CENTER'
                story.append(KeepTogether([Spacer(1,5),im,Spacer(1,8),para(item['caption'],'caption')]))
                inserted.append(item['id'])
    if artifact=='geiger_counter':story.extend(reference_story())
    if artifact=='random_return': story.append(KeepTogether([Spacer(1,3),plate,para('Rule study: the sphere returns; the released visitor need not.','caption')]))
story += [PageBreak(),para('COLOPHON / WHAT THE BOOK KEEPS','label'),para('Another recorder','sub'),para('The three monochrome pictures are unchanged Godot captures also used on the hall walls. The abacus and counter were captured on arrival. The number page began with ten rows from 435 and was photographed only after all 28 rows filled and settled. No group was held for that photograph; no trace was added to the abacus.'),para('The table preserves numerical relationships checked against the program. The release diagram isolates a rule with authored positions. It is a schematic, not a recorded route or a wall photograph.'),para('Each form keeps something different. A photograph loses duration and colour; the table leaves the apparatus out; the diagram leaves out the room and the possible actions after release. These choices can be changed and compared. The book is another recorder.'),Spacer(1,10),HRFlowable(width='100%',thickness=.35,color=RULE),Spacer(1,15),para('RESEARCH NOTES','label')]
for n,match in enumerate(re.finditer(r'^\[\^(\w+)\]:\s*(.+)$',notes,re.M),1): story.append(para(f'<b>{n}.</b> '+match[2],'note'))
def decorate(canvas,document):
    canvas.saveState();canvas.setFillColor(PAPER);canvas.rect(0,0,WIDTH,HEIGHT,fill=1,stroke=0);canvas.setFillColor(MUTED);canvas.setFont('Helvetica',7);canvas.drawString(MARGIN,HEIGHT-13*mm,'ADA RESEARCH');canvas.drawRightString(WIDTH-MARGIN,HEIGHT-13*mm,'RANDOM DEFINITION');canvas.setStrokeColor(RULE);canvas.setLineWidth(.35);canvas.line(MARGIN,17*mm,WIDTH-MARGIN,17*mm);canvas.setFont('BookItalic',7.5);canvas.drawString(MARGIN,12*mm,'What chance is allowed to do');canvas.setFont('Helvetica',7.5);canvas.drawRightString(WIDTH-MARGIN,12*mm,str(document.page));canvas.restoreState()
out=ROOT/'output/pdf/what-chance-is-allowed-to-do-recorder.pdf'
SimpleDocTemplate(str(out),pagesize=(WIDTH,HEIGHT),rightMargin=MARGIN,leftMargin=MARGIN,topMargin=23*mm,bottomMargin=24*mm,title='What chance is allowed to do',author='Ada Research').build(story,onFirstPage=decorate,onLaterPages=decorate)
shutil.copyfile(out,HERE/'illustrated-chapter.pdf')
reader=PdfReader(out);extracted='\n'.join(p.extract_text() or '' for p in reader.pages)
assert all(g in extracted for g in groups)
assert 'Here, randomness is domesticated.' not in extracted
assert 'It returns to the centre.' in extracted
assert inserted==['abacus','page','geiger']
def count(value):return len(re.findall(r"\b[\w]+(?:['’][\w]+)*\b",re.sub(r'<!--.*?-->|\[[^]]+\]\([^)]+\)', '',value.split('<!-- @ -->')[0],flags=re.S)))
receipt={'source_sha256':sha256(SOURCE.read_bytes()).hexdigest(),'pdf_sha256':sha256(out.read_bytes()).hexdigest(),'pages':len(reader.pages),'prose_words':{'before':count(before),'revised':count(text)},'gem_budget':[600,1500],'illustrations':{x['id']:x['image_sha256'] for x in choices['images']},'release_diagram':'authored rule schematic; not a recorded path','rgb':{'draws':[1,2,3],'channels':values[:3],'page_groups':groups[:3],'html_srgb8':rgb,'scope':'numerical assignment, not screen radiometry'},'review_status':'new reading trial; author response pending'}
(HERE/'publication.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
index=nav+'<div class="eyebrow">RANDOM DEFINITION / 16 OCTOBER 2026</div><h1>The book is another recorder.</h1><p class="lede">A smaller literary revision, one restored encounter, and three forms of evidence allowed to do different work.</p><p><a href="illustrated.html">Read the complete revised chapter</a> · <a href="compare.html">Read before and after side by side</a></p><section><h2>What changed</h2><p>The opening, RAND and Geiger passages remain. The gesture passage keeps the visible change and moves sampling detail into a note. The ending lets release and return happen. The numerical reference now places the first three draws beside one RGB assignment.</p><p>MOVE / KEEP has been restored at its saved position. The 48-value bench remains the first research pilot. The room order has not changed.</p><p>Prose: '+str(receipt['prose_words']['before'])+' → '+str(receipt['prose_words']['revised'])+' words, within the provisional 600–1,500-word range. Length remains earned by encounters, not a target to fill.</p></section><section><h2>Two editions, different evidence</h2><p>The supplied critique reviewed an earlier eight-page staged edition. The current pictures capture arrival, except that the page waits until full. There is no held 84288 or accumulated abacus path to enhance in these images. We keep that absence honest.</p><p>The new release diagram is a labelled schematic. It tests the relation between object and visitor without inventing a captured journey or replacing the shared wall/book images.</p>'+schematic+'</section><section><h2>Where a reading can change the work</h2><p>Does the shorter gesture passage leave enough understanding to make the release matter? Does the diagram reveal the separation, or settle an image that the prose could leave open? A lack of improvement is a valid result.</p><p><a href="supplied-reading.md">Supplied critique</a> · <a href="README.md">Decisions and verification</a> · <a href="museum-report.json">Actual-hall checks</a> · <a href="before/illustrated-chapter.pdf">Previous seven-page edition</a> · <a href="../2026-10-16-book-image-study/index.html">Earlier staged image research</a></p></section>'
index += '<section><h2>MOVE / KEEP, restored</h2><figure><img src="move-keep-restored.png" alt="Restored movement sampler in the actual hall, with six traces and a dark sphere"><figcaption class="meta">Native desktop capture at its saved location. Restart the museum to load the revised map.</figcaption></figure></section>'
(HERE/'index.html').write_text(doc('The book is another recorder · Ada Research',index),encoding='utf8')
print(json.dumps(receipt,indent=2))
