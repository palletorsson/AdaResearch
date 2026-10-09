from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
O=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',29)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23)
large=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',41)
c=Image.new('RGB',(1600,1322),'#211b25');d=ImageDraw.Draw(c)
d.text((27,24),'The surface keeps working.',font=large,fill='#f8e9ec')
for i,(name,label) in enumerate([('before-hand','Already painting'),('shared-canvas','A second gesture'),('after-release','Ball returned'),('after-wait','A little later')]):
 x=20+(i%2)*790;y=106+(i//2)*588
 im=Image.open(O/(name+'.png')).convert('RGB').resize((770,513),Image.Resampling.LANCZOS)
 c.paste(im,(x,y+44));d.text((x+7,y),label,font=font,fill='#f8e9ec')
d.text((27,1280),'One camera, one canvas. The automatic brush continues through all four views.',font=small,fill='#d6b7c8')
c.save(O/'the-surface-keeps-working.png')
c=Image.new('RGB',(1600,650),'#211b25');d=ImageDraw.Draw(c)
d.text((27,20),'Separate diagnostic: both inputs quiet.',font=large,fill='#f8e9ec')
for i,(name,label) in enumerate([('feedback-before','Retained image'),('feedback-after','120 rendered frames later')]):
 x=20+i*790;d.text((x+7,90),label,font=font,fill='#f8e9ec')
 im=Image.open(O/(name+'.png')).convert('RGB').resize((770,481),Image.Resampling.LANCZOS);c.paste(im,(x,135))
c.save(O/'feedback-diagnostic.png')
print('Built native four-state book figure and separate feedback diagnostic.')
