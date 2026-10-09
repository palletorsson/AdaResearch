from pathlib import Path
import difflib, html, json, re
import markdown
from PIL import Image, ImageDraw, ImageFont
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]

def font(size, bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/'+('segoeuib.ttf' if bold else 'segoeui.ttf'), size)

# Layout only: native Godot pixels are cropped, resized and captioned.
figure=Image.new('RGB',(2100,870),'#eeeae2')
d=ImageDraw.Draw(figure)
d.text((46,25),'AT EACH ADDRESS, A DECISION',fill='#252525',font=font(30,True))
d.text((46,69),'An Ada Research spatial study after Vera Molnár’s (Des)Ordres, 1974',fill='#57534e',font=font(23))
items=[('plate-one-layer-order','01  /  One layer · order'),('plate-one-layer-departures','02  /  Same sites · departures'),('plate-volume','03  /  Four layers · depth')]
for i,(name,label) in enumerate(items):
    im=Image.open(OUT/(name+'.png')).convert('RGB')
    im=im.crop((0,0,im.width,int(im.height*.95)))
    im.thumbnail((658,640),Image.Resampling.LANCZOS)
    x=46+i*689
    figure.paste(im,(x,144))
    d.text((x,144+im.height+22),label,fill='#252525',font=font(24,True))
    counts='16 sites / 64 nested cubes' if i<2 else '64 sites / 256 nested cubes'
    d.text((x,144+im.height+63),counts,fill='#615e57',font=font(22))
d.text((46,808),'Fixed sites. Changing position, orientation and size. The same working object in museum and book.',fill='#57534e',font=font(24))
figure.save(OUT/'array-departures.png')

before=(OUT/'Array.before.md').read_text(encoding='utf-8')
after=(OUT/'Array.after.md').read_text(encoding='utf-8')
assert after==(ROOT/'commons/maps/Array/final.md').read_text(encoding='utf-8')
def render(text,prefix):
    text=re.sub(r'<!--\s*@[^>]*-->','',text)
    return markdown.markdown(text,extensions=['extra','sane_lists']).replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
def photo(name,caption):
    return '<figure><a href="'+name+'.png"><img loading="lazy" src="'+name+'.png" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
pairs=[]
a,b=before.split('\n\n'),after.split('\n\n')
for i,(tag,x,y,u,v) in enumerate(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
    if tag=='equal':continue
    pairs.append('<div class="pair"><div><h3>Before</h3>'+(render('\n\n'.join(a[x:y]),'before'+str(i)) or '<p>New encounter.</p>')+'</div><div><h3>Now</h3>'+render('\n\n'.join(b[u:v]),'after'+str(i))+'</div></div>')
css="""*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f4f0e8;color:#222321;font-family:system-ui,sans-serif;line-height:1.65}main{max-width:1340px;margin:auto;padding:48px 30px}h1{font-family:Georgia,serif;font-weight:400;font-size:clamp(38px,5vw,72px);line-height:1.1;max-width:950px;margin:16px 0 26px}h2{font:normal 32px Georgia,serif;margin:0 0 20px}h3{font-size:14px;text-transform:uppercase;letter-spacing:.08em;color:#6d675b}.eyebrow{font-size:12px;letter-spacing:.15em;text-transform:uppercase}.intro{font:24px/1.5 Georgia,serif;max-width:840px}a{color:#305c65;text-underline-offset:4px}nav{display:flex;gap:12px 24px;flex-wrap:wrap;border-block:1px solid #cac4b8;padding:19px 0;margin:26px 0}section{padding:34px 0;border-bottom:1px solid #d4cdc1}figure{margin:24px 0}figure img{display:block;width:100%;height:auto}figcaption{font-size:14px;color:#645e54;margin-top:10px;max-width:900px}.status{font-size:14px}.pair,.photos{display:grid;grid-template-columns:1fr 1fr;gap:32px}.pair>div{min-width:0;background:#fffcf5;padding:22px}.pair img{max-width:100%}.reading{max-width:820px;margin:0 auto;font:21px/1.85 Georgia,serif}.reading img{width:100%}.reading code{font-size:.77em}pre{overflow:auto;background:#e9e3d9;padding:18px}details{margin:20px 0}summary{cursor:pointer}footer{font-size:14px;color:#645e54;margin-top:35px}.evidence{max-width:880px}.footnote{font-size:16px}@media(max-width:760px){main{padding:28px 18px}.pair,.photos{grid-template-columns:1fr}.reading{font-size:19px}}"""
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>At each address, a decision — Array</title><style>'+css+'</style></head><body><main>'
page+='''<div class="eyebrow">Ada Research · Arrays · 23 September 2026</div><h1>At each address,<br>a decision.</h1><p class="intro">We have repeated the cube, but we do not have to repeat its fate.</p><p class="status">Built and placed in <strong>Array</strong>, after the row and grid. The encounter and shared illustration are now in <strong>Array/final.md</strong>.</p><nav><a href="#encounter">The new object</a><a href="#museum">Inside the museum</a><a href="#comparison">Text changes</a><a href="#reading">Read the chapter</a><a href="#evidence">Evidence</a><a href="/compose/sources?map=Array&amp;doc=final">Read and comment</a></nav>'''
page+='<section id="encounter"><h2>Transformation acquires addresses</h2>'+photo('array-departures','Native Godot views of the same registered artifact. Book views hide the controls and plinth; the original captures remain available below.')+'''<p>Vera Molnár’s <em>(Des)Ordres</em> (1974) supplies the reference: concentric squares disturbed within a repeated arrangement. This is our spatial interpretation, with nested transparent cubes, depth and three transformation controls. <a href="https://dam.org/museum/artists_ui/artists/molnar-vera/des-ordres/">Digital Art Museum reference</a>.</p><p>Start with one layer and reset. Vary translation, rotation and scale separately, then together. Each nested frame keeps its assigned departures; returning to the same settings returns to the same geometry. DEPTH reveals up to four layers. Walk around to see what the frontal view conceals.</p><p>The original flat Molnár artifact remains. This addition carries a different question: how much can the visible form change while its indexed place remains?</p></section>'''
page+='<section id="museum"><h2>A volume to walk around</h2>'+photo('museum-first-view','Actual Array hall, at source grid position (10,16), facing the incoming route. The low display has a continuous floor around it.')+'<div class="photos">'+photo('volume-close','The four-layer study in the museum; transparent outer faces and nested edge frames.')+photo('controls','Three sliders at reachable heights, with DEPTH and RESET. Desktop pointer events were tested through the shared interaction components.')+'</div></section>'
page+='<section id="comparison"><h2>A new encounter, with the earlier chapter retained</h2><p>The row and grid passages, opening question and code excerpt remain. The addition follows the distinction between indexed address and displayed position. The ending now leads from looking through layers to entering the next hall’s full-scale array.</p><details><summary>Compare original and revised passages</summary>'+''.join(pairs)+'</details><p><a href="Array.diff">Exact manuscript diff</a> · <a href="source-changes.diff">Map, sequence and companion changes</a></p></section>'
page+='<section id="reading"><article class="reading"><h2>Array</h2>'+render(after,'reading')+'</article></section>'
page+='''<section id="evidence" class="evidence"><h2>What was checked</h2><p>38 focused checks pass in an isolated copy of the production museum: placement, actual pointer callbacks, repeatable transformations, fixed sites, transparent faces and geometry bounds. Supplied walking input takes the actual museum body around all four sides and back to the controls. The first run found a floor drop beside the display; a 3 cm exhibition floor now gives it a continuous circuit.</p><p>All 64 sites are allocated once. DEPTH changes visible layers, not allocated memory. The selected book poses use the same artifact in a neutral stage, with the display furniture hidden and a small lower margin cropped. These are distinct from the museum views.</p><p>Headset comfort and legibility remain to be checked. This does not certify a full hall traversal or a frame rate on Quest. Existing startup UID and gridagent warnings are retained in the log and recorded as separate follow-ups.</p><p><a href="report.json">Runtime checks</a> · <a href="source_manifest.json">Runtime inputs</a> · <a href="plate-report.json">Native book poses</a> · <a href="verification.json">Integration checks</a> · <a href="SUMMARY.md">Decisions and scope</a></p><details><summary>Original book captures</summary><p><a href="plate-one-layer-order.png">One layer, order</a> · <a href="plate-one-layer-departures.png">One layer, departures</a> · <a href="plate-volume.png">Four layers</a></p></details></section><footer>The next hall remains Tutorial_3D: a full-scale array with permission to fly.</footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
print('Built native figure and review page.')
