from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
O=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',29);small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',21)
def pair(output,items,caption):
 c=Image.new('RGB',(1460,715),'#211b25');d=ImageDraw.Draw(c)
 for i,(name,label) in enumerate(items):
  im=Image.open(O/(name+'.png')).convert('RGB');im=ImageOps.fit(im,(700,570),centering=(0.5,0.5));x=20+i*720;c.paste(im,(x,78));d.text((x+8,25),label,font=font,fill='#f8e9ec')
 d.text((27,671),caption,font=small,fill='#d6b7c8');c.save(O/(output+'.png'))
pair('same-choice-two-scales',[('giant-turquoise','Grand / 4.3 metres'),('petite-turquoise','Petit / 0.32 metres')],'The same selected skin and nail values. Different scales in the hall; separate close views here.')
pair('one-channel-two-choices',[('petite-red','Red 0.80 / Green 0.08 / Blue 0.12'),('petite-violet','Red 0.80 / Green 0.08 / Blue 0.80')],'One coordinate changes. The skin and geometry stay the same.')
print('Composed two figures from native museum captures.')
