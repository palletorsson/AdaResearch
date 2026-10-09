from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
O=Path(__file__).resolve().parent
large=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',40)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',28)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',23)
def pair(output,title,left,right,footer):
 c=Image.new('RGB',(1600,740),'#211b25');d=ImageDraw.Draw(c)
 d.text((27,24),title,font=large,fill='#f8e9ec')
 for i,(name,label) in enumerate([left,right]):
  x=20+i*790;d.text((x+7,95),label,font=font,fill='#f8e9ec')
  im=Image.open(O/(name+'.png')).convert('RGB').resize((770,513),Image.Resampling.LANCZOS);c.paste(im,(x,145))
 d.text((27,693),footer,font=small,fill='#d6b7c8');c.save(O/(output+'.png'))
pair('same-opening','The view changes. The opening stays.',('office-glass','Glass'),('office-opaque','Opaque'),'Same camera, furniture and collision. The body uses the same doorway.')
pair('same-endpoints','The endpoints stay. The middle changes.',('gradient-rgb','RGB'),('gradient-hsv','HSV'),'The same sixteen cubes and red / blue endpoints; another interpolation path.')
pair('from-the-desk','Looking back from inside.',('inside-glass','Through glass'),('inside-opaque','Behind an opaque pane'),'Views from the position reached through the same cubicle entrance.')
print('Built native office, inside and gradient comparisons.')
