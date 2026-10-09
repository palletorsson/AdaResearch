from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
O=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',30);small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23)
c=Image.new('RGB',(1600,665),'#211b25');d=ImageDraw.Draw(c)
for i,(name,label) in enumerate([('field-overview','Thirty-five selected positions'),('within-the-field','The gaps are passages')]):
 x=20+i*790;im=Image.open(O/(name+'.png')).convert('RGB').resize((770,513),Image.Resampling.LANCZOS)
 c.paste(im,(x,75));d.text((x+7,24),label,font=font,fill='#f8e9ec')
d.text((27,616),'The same museum field. Elevated view at left; reached walker position plus eye height at right.',font=small,fill='#d6b7c8')
c.save(O/'field-and-passage.png')
print('Composed the book figure from two native views.')
