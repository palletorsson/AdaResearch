from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
O=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',30)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',25)
large=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',42)
canvas=Image.new('RGB',(1600,1322),'#211b25');d=ImageDraw.Draw(canvas)
d.text((27,24),'The bands change. The opening remains.',font=large,fill='#f8e9ec')
for i,(name,label) in enumerate([('bands-6','Six bands'),('bands-7','Seven bands'),('bands-48','Forty-eight bands'),('bands-2','Two bands')]):
 x=20+(i%2)*790;y=106+(i//2)*588
 im=Image.open(O/(name+'.png')).convert('RGB').resize((770,513),Image.Resampling.LANCZOS)
 canvas.paste(im,(x,y+44));d.text((x+7,y),label,font=font,fill='#f8e9ec')
d.text((27,1280),'Same camera and geometry. The palette also recolours the steps.',font=small,fill='#d6b7c8')
canvas.save(O/'four-arrangements.png')
print('Composed the shared book figure from four native museum captures.')
