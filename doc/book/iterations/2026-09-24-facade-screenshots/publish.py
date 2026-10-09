from pathlib import Path
import hashlib,json,html
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
STAGE=ROOT/'ada_run/facade-screenshots-isolated'
WORKS=[
 ('classical','Classical','Facade_Classical','Columns, arches and horizontal bands.'),
 ('baroque','Baroque','Facade_Baroque','A larger front with balconies and a broken rhythm.'),
 ('venetian_gothic','Venetian Gothic','Facade_Venetian_Gothic','Pointed openings above a repeated arcade.'),
 ('naples_diamond_rustication','Diamond rustication','Facade_Rustication','The current Naples rustication preset.'),
 ('florence_marble','Florence marble','Facade_Florence_Marble','A variation in surface and architectural framing.'),
 ('nyc_tenement','NYC tenement','Facade_NYC_Tenement','A narrow front built from repeated storeys.'),
 ('superstudio_grid','Superstudio study','Facade_Critique','The existing grid-monument preset.'),
 ('memphis_totem','Memphis study','Facade_Critique','Different opening types in an asymmetric composition.'),
]
records=json.loads((OUT/'captures.json').read_text(encoding='utf-8'))
assert len(records)==8 and all(c['saved'] and c['composed'] for c in records)
assert 'Forward+' in (OUT/'engine.log').read_text(encoding='utf-8')
images=[]
for slug,_,_,_ in WORKS:
 p=OUT/(slug+'.png')
 with Image.open(p) as im:im.load();assert im.size==(1440,900)
 images.append({'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':[1440,900]})
sources=[]
for folder in ['commons/facade_parts','commons/artifacts/facade_builder','commons/composition']:
 for p in sorted((ROOT/folder).rglob('*')):
  if p.suffix in ['.gd','.gdshader','.tscn','.json']:
   rel=p.relative_to(ROOT)
   assert p.read_bytes()==(STAGE/rel).read_bytes(),rel
   sources.append({'file':rel.as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(OUT/'manifest.json').write_text(json.dumps({'renderer':'Forward+','scope':'Existing facade_builder with current map plan presets, armature none. Isolated presentation ground, lighting and fitted cameras. Not full-hall screenshots; no geometry or material edits.','source':sources,'screenshots':images},indent=2),encoding='utf-8')
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',27)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
sheet=Image.new('RGB',(1440,1090),(23,25,29));draw=ImageDraw.Draw(sheet)
draw.text((26,15),'ADA RESEARCH / THE EXISTING FACADES',font=font,fill=(235,225,210))
draw.text((26,52),'Native Godot captures: classical, Venetian Gothic, tenement and Memphis',font=small,fill=(182,185,192))
for i,slug in enumerate(['classical','venetian_gothic','nyc_tenement','memphis_totem']):
 title=next(t for s,t,m,d in WORKS if s==slug)
 x=i%2*720;y=90+i//2*500
 im=Image.open(OUT/(slug+'.png')).convert('RGB').resize((720,450),Image.Resampling.LANCZOS)
 sheet.paste(im,(x,y));draw.text((x+22,y+460),title,font=font,fill=(235,225,210))
sheet.save(OUT/'overview.png')
items=[]
for i,(slug,title,map_name,description) in enumerate(WORKS):
 items.append(f'<article id="{slug}"><a href="{slug}.png"><img width="1440" height="900" loading="lazy" src="{slug}.png" alt="Native Godot view of the {html.escape(title)} facade"></a><div class="caption"><span>{i+1:02d}</span><div><h2>{title}</h2><p>{description}</p><p class="map">{map_name}</p></div></div></article>')
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>The existing facades | Ada Research</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#17191d;color:#eee9df;font:17px/1.6 system-ui,sans-serif}header,main,footer{max-width:1440px;margin:auto;padding:34px}header{padding-top:60px}.eyebrow,.map{font-size:12px;letter-spacing:.12em;text-transform:uppercase;color:#aeb4bd}h1{font:clamp(42px,6vw,78px)/1.05 Georgia,serif;margin:22px 0}header p{max-width:800px}.lead{font:23px/1.5 Georgia,serif}a{color:#dbc598;text-underline-offset:.2em}.grid{display:grid;grid-template-columns:1fr 1fr;gap:48px 26px}img{width:100%;height:auto;display:block;background:#272b32}article{border-bottom:1px solid #373b43}.caption{display:flex;gap:20px;padding:18px 6px 26px}.caption>span{color:#dbc598;font:25px Georgia,serif;padding-top:5px}h2{font:29px/1.2 Georgia,serif;margin:0 0 8px}.caption p{margin:5px 0;color:#bfc2c8}.caption .map{font-size:11px}footer{font-size:14px;color:#aeb4bd;padding-bottom:60px}details{padding:18px 0}summary{cursor:pointer}a:focus-visible,summary:focus-visible{outline:2px solid #dbc598;outline-offset:5px}@media(max-width:760px){.grid{grid-template-columns:1fr}header,main,footer{padding:24px}.lead{font-size:21px}}
</style></head><body><header><p class="eyebrow">Ada Research / Facade Assembly / 24 September 2026</p><h1>The facades already here.</h1><p class="lead">Eight existing compositions, captured directly in Godot. Click any image to see the full screenshot.</p><p>These use the same facade builder and plan files placed in the Facade Assembly maps. Each front is shown separately on neutral ground, with a camera fitted to its dimensions. The ground, framing and lighting are for this comparison.</p><p><a href="../2026-09-24-facade-room-and-cast/index.html">The new room-and-cast encounter</a> · <a href="overview.png">Four-facade overview</a></p></header><main class="grid">__ITEMS__</main><footer><details><summary>Capture provenance</summary><p>Existing geometry, materials and embedded artifact light are unchanged. Forward+ is used for the transparent bounds marker and marble shader features. The first Compatibility captures were replaced because their appearance was not representative. These are isolated artifact views, not screenshots of the complete museum halls.</p><p><a href="manifest.json">Source and image hashes</a> · <a href="captures.json">Preset dimensions and cameras</a></p></details></footer></body></html>'''
(OUT/'index.html').write_text(page.replace('__ITEMS__',''.join(items)),encoding='utf-8')
print(json.dumps({'screenshots':len(images),'source_files':len(sources),'page':str(OUT/'index.html')}))
