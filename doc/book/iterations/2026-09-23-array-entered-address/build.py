from pathlib import Path
import html,re,difflib,markdown
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
def font(size,bold=False):return ImageFont.truetype('C:/Windows/Fonts/'+('segoeuib.ttf' if bold else 'segoeui.ttf'),size)
fig=Image.new('RGB',(1800,940),'#eeeae2');draw=ImageDraw.Draw(fig)
draw.text((45,25),'AN ADDRESS YOU CAN ENTER',font=font(30,True),fill='#242522')
draw.text((45,68),'Same selected site. Same view. A changed record.',font=font(24),fill='#656156')
for i,state in enumerate(['before','after']):
 x=45+i*870
 im=Image.open(OUT/('address-'+state+'.png')).convert('RGB');w,h=im.size
 im=im.crop((0,0,w,int(h*.95)));im.resize((840,532),Image.Resampling.LANCZOS).save(OUT/('book-address-'+state+'.png'))
 fig.paste(im.resize((840,532),Image.Resampling.LANCZOS),(x,120))
 con=Image.open(OUT/('console-'+state+'.png')).convert('RGB');w,h=con.size
 con=con.crop((int(w*.29),int(h*.49),int(w*.71),int(h*.59)))
 con.thumbnail((840,140),Image.Resampling.LANCZOS);fig.paste(con,(x+(840-con.width)//2,669))
 draw.text((x,827),'01 / Cube present' if i==0 else '02 / Cube collected; visitor hovering',font=font(25,True),fill='#242522')
draw.text((45,893),'The selected address remains. The stored value counts cubes; it does not record the visitor.',font=font(24),fill='#656156')
fig.save(OUT/'an-address-you-can-enter.png')
def render(text,prefix):
 text=re.sub(r'<!--\s*@[^>]*-->','',text)
 return markdown.markdown(text,extensions=['extra','sane_lists']).replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
def photo(name,caption):return '<figure><a href="'+name+'.png"><img loading="lazy" src="'+name+'.png" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
before=(OUT/'Tutorial_3D.before.md').read_text(encoding='utf-8');after=(OUT/'Tutorial_3D.after.md').read_text(encoding='utf-8');assert after==(ROOT/'commons/maps/Tutorial_3D/final.md').read_text(encoding='utf-8')
a,b=before.split('\n\n'),after.split('\n\n');pairs=[]
for i,(tag,x,y,u,v) in enumerate(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
 if tag=='equal':continue
 pairs.append('<div class="pair"><div><h3>Before</h3>'+(render('\n\n'.join(a[x:y]),'old'+str(i)) or '<p>New illustration.</p>')+'</div><div><h3>Now</h3>'+render('\n\n'.join(b[u:v]),'new'+str(i))+'</div></div>')
css=re.search(r'<style>(.*?)</style>',(OUT.parent/'2026-09-23-array-molnar-volume/index.html').read_text(encoding='utf-8'),re.S)[1]
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>An address you can enter — Tutorial 3D</title><style>'+css+'</style></head><body><main>'
page+='''<div class="eyebrow">Ada Research · Arrays · 23 September 2026</div><h1>An address you can enter.</h1><p class="intro">The table says zero.<br>You are hovering there.</p><p class="status">Applied to <strong>Tutorial_3D/final.md</strong>. A short connection to the previous hall, a passage about the gaps and a shared native figure. The existing flight encounter is preserved.</p><nav><a href="#encounter">The shared illustration</a><a href="#museum">Inside the volume</a><a href="#comparison">Text differences</a><a href="#reading">Read the hall</a><a href="#evidence">Evidence</a><a href="/compose/sources?map=Tutorial_3D&amp;doc=final">Read and comment</a></nav>'''
page+='<section id="encounter"><h2>The record and the place</h2>'+photo('an-address-you-can-enter','Address [1,2,0] before and after actual player contact. Matching native camera views above; actual console crops below. The independent marker survives. The visiting body hovers at the recorded absence in the second view.')+'<p>In Array, nested cubes departed from fixed sites. Here the pickup cubes are far enough apart to travel among them. The gaps are usable space without being additional array entries. The closing question already belongs to this encounter: what would the stored record need to notice the visitor?</p></section>'
page+='<section id="museum"><h2>From outside to inside</h2><div class="photos">'+photo('enclosure','The existing 12 m glass enclosure and 64 pickup cubes, viewed from outside.')+photo('inside-volume','A view from the reached player position, 5.26 m above the floor plus the normal 1.65 m eye offset. Supplied key events brought the body here through the production controller.')+'</div></section>'
page+='<section id="comparison"><h2>Keep the question; make the connection</h2><p>The code excerpts, controls, storage-order explanation and closing question remain. No new artifact or interface was needed. The map, registry, cube behavior and flight scripts are unchanged.</p><details><summary>Original and current passages</summary>'+''.join(pairs)+'</details><p><a href="Tutorial_3D.diff">Exact text diff</a> · <a href="source-changes.diff">Companion notes and core metadata</a></p></section>'
page+='<section id="reading"><article class="reading"><h2>Fly into the third index</h2>'+render(after,'reading')+'</article></section>'
page+='''<section id="evidence" class="evidence"><h2>What was checked</h2><p>31 checks pass in the isolated production museum. Pointer events select [1,2,0]. Supplied W, Space and Ctrl events drive the unchanged museum physics controller and actual capsule through the doorway, upwards, to contact, into the interior, down and out. The chosen cube disappears; the remaining cubes keep their positions; the selected marker and zero remain while the body hovers. Flight permission ends outside.</p><p>Cube bobbing and turning are frozen for the paired photographs, while contact remains live. Cameras are staged separately from the player except for the interior viewpoint. Images are cropped and captioned; no object is painted in or removed. The first probe used obsolete button names; fixing the test lookup resolved all five related failures without a production change.</p><p>This is supplied-input evidence, not a headset comfort or learner test. Existing startup UID warnings are retained in the log. No live museum restart, live bake/save replacement or frozen-book/audio rebuild.</p><p><a href="report.json">Runtime checks</a> · <a href="source_manifest.json">Runtime source manifest</a> · <a href="verification.json">Publication checks</a> · <a href="SUMMARY.md">Scope and decisions</a></p></section><footer>Next: Tutorial_Tiling_Floor. Return to the ground; the repeated element begins to organise a surface.</footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8');print('Built figure and review page.')
