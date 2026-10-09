from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent
font_dir=Path('C:/Windows/Fonts')
def font(size,bold=False):return ImageFont.truetype(str(font_dir/('segoeuib.ttf' if bold else 'segoeui.ttf')),size)
width=1800;gap=24;pad=38;panel=(width-2*pad-gap)//2
images=[Image.open(OUT/name).convert('RGB') for name in ['door-before.png','door-after.png']]
height=round(panel*images[0].height/images[0].width)
page=Image.new('RGB',(width,height+235),'#f4f0e7');d=ImageDraw.Draw(page)
d.text((pad,22),'ADA RESEARCH / SCALE',font=font(19,True),fill='#566869')
d.text((pad,51),'An opening for whom?',font=font(35,True),fill='#202c31')
labels=['Before / 0.45 × 0.60 metres','After / 1.80 × 2.40 metres']
subs=['The opening is visible. The body cannot pass.','The room changed size; the body did not.']
for i,(im,label,sub) in enumerate(zip(images,labels,subs)):
 x=pad+i*(panel+gap);im=im.resize((panel,height),Image.Resampling.LANCZOS);page.paste(im,(x,113))
 d.text((x,127+height),label,font=font(26,True),fill='#202c31');d.text((x,169+height),sub,font=font(20),fill='#4a6265')
page.save(OUT/'door-and-body.png')
print('Paired figure built from native museum views.')
