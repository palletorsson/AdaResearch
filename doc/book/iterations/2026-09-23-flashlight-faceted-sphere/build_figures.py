from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
O=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',27)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
canvas=Image.new('RGB',(1460,850),'#121921');d=ImageDraw.Draw(canvas)
for i,(name,label) in enumerate([('red-from-left','Red lamp to the left'),('red-from-right','Red lamp to the right')]):
 im=Image.open(O/(name+'.png')).convert('RGB').crop((345,125,1075,865))
 im=ImageOps.fit(im,(700,710))
 x=20+i*720;canvas.paste(im,(x,75));d.text((x+8,24),label,font=font,fill='#f4eadc')
d.text((28,806),'One sphere. One pale material. The light changes sides.',font=small,fill='#bdced7')
canvas.save(O/'same-sphere-moving-light.png')
print('Native paired illustration composed.')
