"""Compact visual inspection sheets; these are not the user's museum images."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OUT=ROOT/'doc/book/iterations/2026-10-04-museum-tutorial-storyboards'
data=json.loads((OUT/'route.json').read_text(encoding='utf-8'))
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)
for batch in range(0,len(data['halls']),24):
    im=Image.new('RGB',(1600,6*230),'#f6f4ee');draw=ImageDraw.Draw(im)
    for n,h in enumerate(data['halls'][batch:batch+24]):
        x=(n%4)*400;y=(n//4)*230
        if h['images']:
            with Image.open(OUT/h['images'][0]['src']) as pic:
                pic.thumbnail((395,200));im.paste(pic,(x,y))
        draw.text((x+4,y+202),str(h['number'])+' '+h['id'],font=font,fill='#202524')
    im.save(OUT/f'contact-{batch//24+1:02}.jpg',quality=90)
print('9 contact sheets saved for image QA')
