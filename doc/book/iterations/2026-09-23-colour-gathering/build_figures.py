from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
O=Path(__file__).resolve().parent
INK='#262820';PAPER='#eeeae2';MUTED='#67665e'
def f(size,bold=False):return ImageFont.truetype('C:/Windows/Fonts/'+('segoeuib.ttf' if bold else 'segoeui.ttf'),size)
fig=Image.new('RGB',(1720,1160),PAPER);d=ImageDraw.Draw(fig)
d.text((50,30),'FIVE FORMS / FOUR COLOUR RULES',font=f(34,True),fill=INK)
d.text((50,88),'What lets these pieces belong together?',font=f(28),fill=MUTED)
items=[('one','01 / ONE COLOUR','One value covers every piece.'),('by_shape','02 / BY SHAPE','A colour for each kind of shape.'),('by_height','03 / BY HEIGHT','Each centre samples a height.'),('by_neighbour','04 / FROM BELOW','Each hue turns halfway around.')]
for i,(name,title,caption) in enumerate(items):
 im=Image.open(O/f'rule-{name}.png').convert('RGB');w,h=im.size
 crop=im.crop((w//2-195,25,w//2+195,h-28));crop.thumbnail((380,884),Image.Resampling.LANCZOS)
 x=50+i*410;fig.paste(crop,(x,152));d.text((x,1049),title,font=f(23,True),fill=INK);d.text((x,1091),caption,font=f(20),fill=MUTED)
fig.save(O/'four-colour-rules.png')
fig=Image.new('RGB',(1740,817),PAPER);d=ImageDraw.Draw(fig)
d.text((50,30),'THE COLUMN STAYS. YOUR VIEW CHANGES.',font=f(32,True),fill=INK)
for i,(n,title) in enumerate([('rainbow-near','One approach'),('rainbow-around','Another side')]):
 im=Image.open(O/(n+'.png')).convert('RGB');im.thumbnail((790,560),Image.Resampling.LANCZOS);x=50+i*850;fig.paste(im,(x,110));d.text((x,680),title,font=f(27,True),fill=INK)
d.text((50,751),'Thirty stripes. Six palette entries. Walking changes which stripes face you.',font=f(25),fill=MUTED)
fig.save(O/'around-the-rainbow.png')
print('Composed two figures from native Godot captures.')
