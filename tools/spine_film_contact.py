"""Contact sheets of actual rendered frames for visual review (no retouching)."""
import argparse
from PIL import Image, ImageDraw, ImageFont
import build_spine_films as build

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--only',nargs='+')
    parser.add_argument('--museum',action='store_true')
    parser.add_argument('--name',default='more-contact')
    args=parser.parse_args()
    films=[e for e in build.read(build.BASE/'catalog.json') if
           (e['id'] in args.only if args.only else e.get('collection')=='more')]
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
    columns=2 if args.museum else 4
    width=640 if args.museum else 384
    height=450 if args.museum else 216
    cells=[]
    for film in films:
        paths=[build.OUT/film['id']/'museum.png'] if args.museum else sorted((build.OUT/film['id']).glob('phase-*.png'))
        for p in paths:
            if p.exists():cells.append((film['id']+' / '+p.stem,p))
    assert cells,'No captures yet'
    # Keep sheets readable at their native resolution.
    per_sheet=8 if args.museum else 12
    for start in range(0,len(cells),per_sheet):
        chunk=cells[start:start+per_sheet]
        sheet=Image.new('RGB',(columns*width,((len(chunk)+columns-1)//columns)*(height+32)),(242,241,238))
        draw=ImageDraw.Draw(sheet)
        for i,(label,path) in enumerate(chunk):
            x=(i%columns)*width;y=(i//columns)*(height+32)
            im=Image.open(path).convert('RGB');im.thumbnail((width,height))
            sheet.paste(im,(x+(width-im.width)//2,y))
            draw.text((x+7,y+height+5),label,font=font,fill=(26,31,39))
        target=build.RUN/(args.name+'-%02d.png'%(start//per_sheet))
        sheet.save(target);print(target)

if __name__=='__main__':main()
