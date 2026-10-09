from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent
FONTS=Path('C:/Windows/Fonts')
def font(n,bold=False):return ImageFont.truetype(str(FONTS/('segoeuib.ttf' if bold else 'segoeui.ttf')),n)
width=1800;pad=38;gap=24;panel=(width-2*pad-gap)//2
names=['lattice-before.png','lattice-after.png'];ims=[Image.open(OUT/n).convert('RGB') for n in names]
height=round(panel*ims[0].height/ims[0].width)
page=Image.new('RGB',(width,height+235),'#f4f0e7');d=ImageDraw.Draw(page)
d.text((pad,22),'ADA RESEARCH / BODY',font=font(19,True),fill='#566869');d.text((pad,51),'The cut remains',font=font(35,True),fill='#202c31')
labels=['Before the passage','After the body has left']
subtitles=['A low block of separate cells.','The missing cells keep an opening.']
for i,(im,label,sub) in enumerate(zip(ims,labels,subtitles)):
 x=pad+i*(panel+gap);page.paste(im.resize((panel,height),Image.Resampling.LANCZOS),(x,113))
 d.text((x,127+height),label,font=font(26,True),fill='#202c31');d.text((x,169+height),sub,font=font(20),fill='#4a6265')
page.save(OUT/'the-cut-remains.png')
print('Native lattice pair composed.')
