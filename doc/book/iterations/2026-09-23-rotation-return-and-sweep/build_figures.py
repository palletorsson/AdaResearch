from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent
font_dir=Path('C:/Windows/Fonts')
def font(size,bold=False):return ImageFont.truetype(str(font_dir/('segoeuib.ttf' if bold else 'segoeui.ttf')),size)
def pair(filename,title,left,right,labels,subtitles):
    width=1800;gap=24;pad=38;panel=(width-pad*2-gap)//2
    images=[Image.open(OUT/(n+'.png')).convert('RGB') for n in (left,right)]
    height=round(panel*images[0].height/images[0].width)
    page=Image.new('RGB',(width,height+235),'#f4f0e7');d=ImageDraw.Draw(page)
    d.text((pad,22),'ADA RESEARCH / ROTATION',font=font(19,True),fill='#566869')
    d.text((pad,51),title,font=font(35,True),fill='#202c31')
    for i,(im,label,sub) in enumerate(zip(images,labels,subtitles)):
        x=pad+i*(panel+gap)
        im=im.resize((panel,height),Image.Resampling.LANCZOS)
        page.paste(im,(x,113))
        d.text((x,127+height),label,font=font(26,True),fill='#202c31')
        d.text((x,169+height),sub,font=font(20),fill='#4a6265')
    page.save(OUT/filename)
pair('marked-return.png','What returned?', 'cube-zero','cube-ninety',['0° / Before the turn','90° / A quarter-turn later'],['The L faces towards the left of the picture.','The outline returns. The marked face has moved.'])
pair('spaces-of-a-turn.png','The room a turn requires','cube-sweep','triangle-sweep',['Cube → cylindrical boundary','Triangular face → conical boundary'],['Amber: one paused position.','Cyan: the outer boundary of a full turn.'])
print('Two figures composed from native museum captures; no painted or generated geometry.')
