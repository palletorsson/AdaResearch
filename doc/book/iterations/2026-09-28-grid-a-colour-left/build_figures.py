from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
O=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',29);small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23);large=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',41)
c=Image.new('RGB',(1600,1322),'#211b25');d=ImageDraw.Draw(c)
d.text((27,24),'An address keeps a colour.',font=large,fill='#f8e9ec')
for i,(name,label) in enumerate([('edited','Write pink / (10,10)'),('attention-away','Look elsewhere / (11,10)'),('returned','Return / (10,10)'),('rule-after','Run RULE / (10,10)')]):
 x=20+(i%2)*790;y=106+(i//2)*588
 im=Image.open(O/(name+'.png')).convert('RGB').resize((770,513),Image.Resampling.LANCZOS);c.paste(im,(x,y+44));d.text((x+7,y),label,font=font,fill='#f8e9ec')
d.text((27,1280),'Same camera. The edit stays at (10,10); the outline follows the selected address.',font=small,fill='#d6b7c8')
c.save(O/'an-address-keeps-colour.png')
print('Composed four actual floor states for the book.')
