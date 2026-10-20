"""A typeset chapter, seed reference and separately labelled illustration proposal."""
from pathlib import Path
from hashlib import sha256
from html import escape
import json
import re
import argparse
import shutil

from bs4 import BeautifulSoup
import markdown
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, KeepTogether, PageBreak, Table, TableStyle, HRFlowable
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--proposal', type=Path)
parser.add_argument('--edition-directory', type=Path, help='Keep a separate arrival edition beside its selected images')
args = parser.parse_args()
EDITION = args.edition_directory.resolve() if args.edition_directory else HERE
EDITION.mkdir(parents=True, exist_ok=True)
OUT = ROOT / 'output/pdf'
OUT.mkdir(parents=True, exist_ok=True)
DEST = OUT / ('what-chance-is-allowed-to-do-arrival.pdf' if args.edition_directory else 'what-chance-is-allowed-to-do-illustrated.pdf')
source = ROOT / 'commons/maps/Random_Definition/final.md'
text = source.read_text(encoding='utf8')
choices = json.loads((ROOT/'commons/maps/Random_Definition/book_images.json').read_text(encoding='utf8'))
seed = json.loads((HERE/'seed-values.json').read_text(encoding='utf8'))

for name, filename in [('Book','georgia.ttf'),('BookItalic','georgiai.ttf'),('BookBold','georgiab.ttf')]:
    pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/'+filename))
pdfmetrics.registerFontFamily('Book',normal='Book',bold='BookBold',italic='BookItalic',boldItalic='BookBold')
pdfmetrics.registerFont(TTFont('Mono','C:/Windows/Fonts/consola.ttf'))
PAPER=colors.HexColor('#f3f0e7'); INK=colors.HexColor('#1a201c'); MUTED=colors.HexColor('#62685e'); RULE=colors.HexColor('#c5c7b9')
WIDTH, HEIGHT = 180*mm, 250*mm
MARGIN = 24*mm
TEXT_WIDTH = WIDTH-2*MARGIN
styles={
 'body':ParagraphStyle('body',fontName='Book',fontSize=10.8,leading=16.2,textColor=INK,spaceAfter=10,allowWidows=0,allowOrphans=0),
 'title':ParagraphStyle('title',fontName='Book',fontSize=31,leading=34,textColor=INK,spaceAfter=24),
 'sub':ParagraphStyle('sub',fontName='Book',fontSize=23,leading=28,textColor=INK,spaceAfter=18),
 'label':ParagraphStyle('label',fontName='Helvetica',fontSize=8,leading=11,textColor=MUTED,spaceAfter=13),
 'caption':ParagraphStyle('caption',fontName='BookItalic',fontSize=8.5,leading=12,textColor=MUTED,alignment=TA_CENTER,spaceBefore=8,spaceAfter=18),
 'note':ParagraphStyle('note',fontName='Book',fontSize=8.5,leading=12.5,textColor=MUTED,spaceAfter=9),
 'table':ParagraphStyle('table',fontName='Helvetica',fontSize=8.5,leading=11,textColor=INK),
 'close':ParagraphStyle('close',fontName='BookItalic',fontSize=10.8,leading=16.2,textColor=INK,spaceBefore=6,spaceAfter=18),
}

def clean_dashes(value):
    return value.replace('\u2011','-').replace('\u2013','-').replace('\u2014',' - ')

def inline(value):
    value=value.replace('[^arrival]','<super>1</super>').replace('[^entropy]','<super>2</super>')
    soup=BeautifulSoup(markdown.markdown(value),'html.parser')
    for tag in soup.find_all('a'):
        if tag.get('href','').startswith('https://'):
            tag.name='link'; tag['color']='#354e3b'
        else:tag.unwrap()
    for tag in soup.find_all('em'):tag.name='i'
    for tag in soup.find_all('strong'):tag.name='b'
    for tag in soup.find_all('p'):tag.unwrap()
    return clean_dashes(str(soup))

def para(value,style='body'):
    return Paragraph(inline(value), styles[style])

def illustration(item):
    name=f'{item["id"]}-detail-{item["treatment"]}.png'
    path = ROOT/item['image'] if item.get('image') else HERE/name
    if item.get('image_sha256'):
        assert sha256(path.read_bytes()).hexdigest() == item['image_sha256'], item['id']
    im=Image(str(path),width=110*mm,height=82.5*mm)
    im.hAlign='CENTER'
    return KeepTogether([Spacer(1,5),im,para(item['caption'],'caption')])

def decorate(canvas,doc):
    canvas.saveState()
    canvas.setFillColor(PAPER);canvas.rect(0,0,WIDTH,HEIGHT,fill=1,stroke=0)
    canvas.setFillColor(MUTED);canvas.setFont('Helvetica',7)
    canvas.drawString(MARGIN,HEIGHT-13*mm,'ADA RESEARCH')
    canvas.drawRightString(WIDTH-MARGIN,HEIGHT-13*mm,'RANDOM DEFINITION')
    canvas.setStrokeColor(RULE);canvas.setLineWidth(.35)
    canvas.line(MARGIN,17*mm,WIDTH-MARGIN,17*mm)
    canvas.setFont('BookItalic',7.5)
    canvas.drawString(MARGIN,12*mm,'What chance is allowed to do')
    canvas.setFont('Helvetica',7.5);canvas.drawRightString(WIDTH-MARGIN,12*mm,str(doc.page))
    canvas.restoreState()

story=[Spacer(1,7*mm),para('What chance is<br/>allowed to do','title')]
chapter,notes=text.split('<!-- @ -->',1)
parts=re.split(r'<!-- @([^>]*?) -->',chapter)
inserted=[]
for index in range(1,len(parts),2):
    artifact,section=parts[index].strip(),parts[index+1]
    if index>1:story.append(Spacer(1,5))
    for block in re.split(r'\n\s*\n',section.strip()):
        if not block.strip():continue
        story.append(para(block,'close' if block.strip()=='Here, randomness is domesticated.' else 'body'))
        for item in choices['images']:
            if item['artifact']==artifact and block.endswith(item['insert_after']):
                story.append(illustration(item));inserted.append(item['id'])
assert inserted==['abacus','page','geiger'],inserted
story += [Spacer(1,8),HRFlowable(width='100%',thickness=.35,color=RULE),Spacer(1,14),para('NOTES','label')]
for number,match in enumerate(re.finditer(r'^\[\^(\w+)\]:\s*(.+)$',notes,re.M),1):
    story.append(para(f'<b>{number}.</b> '+match[2],'note'))
if all(item.get('capture') for item in choices['images']):
    story.append(para('The abacus and counter are captured on arrival. The number page starts with ten rows from seed 435; its camera waits for every row to fill and settle. The same images hang in the hall from that visit. No touch is supplied for the photograph. The page generates digits rather than reproducing the historical RAND table; the counter simulates detections. Framing, omitted labels and monochrome are authored choices.','note'))
else:
    story.append(para('The three chapter illustrations are filtered captures of the current Ada artifacts. The abacus compares equal numbers of steps; the page shows generated digits, not a scan of the historical RAND table; the counter shows simulated detections. Framing and monochrome remove surrounding details.','note'))

# A separate reference page keeps the number inspection out of the chapter's voice.
story += [PageBreak(),para('REFERENCE / ONE KEPT BEGINNING','label'),para('The first ten from 435','sub')]
story.append(para('435 is the seed: a starting number, not a list of further seeds. The colour window and falling page read the same sequence. One value becomes a colour channel there and a five-digit group here.'))
headers=[Paragraph(t,styles['table']) for t in ['Draw','Colour window<br/>0-1 value','Book page<br/>five-digit group']]
rows=[headers]+[[str(i+1),f'{value:.6f}',group] for i,(value,group) in enumerate(zip(seed['window_first_ten_values'],seed['book_first_ten_groups']))]
table=Table(rows,colWidths=[20*mm,55*mm,57*mm],rowHeights=[14*mm]+[8*mm]*10,hAlign='LEFT')
table.setStyle(TableStyle([
 ('FONTNAME',(0,1),(-1,-1),'Mono'),('FONTSIZE',(0,1),(-1,-1),10),
 ('TEXTCOLOR',(0,0),(-1,-1),INK),('VALIGN',(0,0),(-1,-1),'MIDDLE'),
 ('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),
 ('LINEBELOW',(0,0),(-1,0),.65,INK),('LINEBELOW',(0,1),(-1,-1),.25,RULE),
 ('BOTTOMPADDING',(0,0),(-1,0),6),
]))
story += [table,Spacer(1,18)]
story.append(para('Window values above are rounded to six decimal places. The book truncates each full value after five fractional digits, retaining leading zeros: 0.4981114268... becomes 49811. It consumes one value per group; each RGB cell in the baseline window consumes three. The folio starts at page 1 and is a separate address: changing it consumes no draw.','note'))
story.append(para('Verified in Godot 4.6 against the actual window colours and incoming page rows at seeds 0, 435, 436 and 999. Reset repeats the sequence; changing the folio preserves the stream and held groups. Exact values and checks are saved in seed-values.json alongside this edition.','note'))
story.append(para('435 is a kept beginning; the procedure determines what follows.','close'))

if args.proposal:
    assert args.proposal.is_file()
    story += [PageBreak(),para('ILLUSTRATION PROPOSAL / A DIFFERENT DEGREE OF ABSTRACTION','label'),para('Path. Hold. Interval.','sub')]
    story.append(para('The drawings I would explore next keep the action more strongly than the apparatus. Rods become paths and accumulated traces. A bracket holds one group in a field of numbers. A line receives unequal intervals. The surrounding room stays absent.'))
    im=Image(str(args.proposal)); ratio=im.imageHeight/im.imageWidth
    im.drawWidth=TEXT_WIDTH;im.drawHeight=TEXT_WIDTH*ratio;im.hAlign='CENTER'
    story += [Spacer(1,16),im,para('An interpretive plate: path and trace; one group held; gaps in a sequence.','caption')]
    story.append(para('Generated with the built-in image tool from the three artifact references. This is a visual proposal, not a measured record or a replacement for the accepted chapter images. Numerals and tick positions in this drawing should not be used as experimental data.','note'))
    story.append(para('The test is whether the drawing gives the reader something to think with while leaving enough unpictured to imagine.','close'))

doc=SimpleDocTemplate(str(DEST),pagesize=(WIDTH,HEIGHT),rightMargin=MARGIN,leftMargin=MARGIN,topMargin=23*mm,bottomMargin=24*mm,title='What chance is allowed to do',author='Ada Research',subject='Illustrated Random Definition chapter and first ten values from seed 435',pageCompression=1)
doc.build(story,onFirstPage=decorate,onLaterPages=decorate)
shutil.copyfile(DEST,EDITION/'illustrated-chapter.pdf')
reader=PdfReader(DEST)
extracted='\n'.join(p.extract_text() or '' for p in reader.pages)
assert all(group in extracted for group in seed['book_first_ten_groups'])
assert all(f'{v:.6f}' in extracted for v in seed['window_first_ten_values'])
assert 'Here, randomness is domesticated.' in extracted
assert all(item['caption'] in extracted for item in choices['images'])
(EDITION/'pdf-receipt.json').write_text(json.dumps({'pdf':str(DEST),'pages':len(reader.pages),'source_sha256':sha256(source.read_bytes()).hexdigest(),'pdf_sha256':sha256(DEST.read_bytes()).hexdigest(),'illustrations':inserted,'image_hashes':{i['id']:i.get('image_sha256') for i in choices['images']},'seed_table':'All ten groups and rounded window values found in PDF text','proposal':str(args.proposal) if args.proposal else None,'page_size_mm':[180,250]},indent=2)+'\n',encoding='utf8')
print(json.dumps({'output':str(DEST),'pages':len(reader.pages),'bytes':DEST.stat().st_size,'page_word_counts':[len((p.extract_text() or '').split()) for p in reader.pages]},indent=2))
