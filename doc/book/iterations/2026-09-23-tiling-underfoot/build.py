from pathlib import Path
import html,re,difflib,markdown
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
def font(size,bold=False):return ImageFont.truetype('C:/Windows/Fonts/'+('segoeuib.ttf' if bold else 'segoeui.ttf'),size)
fig=Image.new('RGB',(1740,1445),'#eeeae2');d=ImageDraw.Draw(fig)
d.text((60,26),'ONE MOTIF / SIX RELATIONS',font=font(32,True),fill='#252622')
d.text((60,75),'A common source, placed under different rules.',font=font(24),fill='#676258')
im=Image.open(OUT/'rule-0-ordered.png').convert('RGB');source=im.crop((0,0,32,32)).resize((76,76),Image.Resampling.NEAREST);fig.paste(source,(1604,20));d.text((1480,45),'SOURCE',font=font(19,True),fill='#676258')
labels=['Translate','Alternate','Quarter turn','Reflect','Shift rows','One exception']
for i,title in enumerate(labels):
 name='rule-5-exception' if i==5 else 'rule-'+str(i)+'-ordered'
 im=Image.open(OUT/(name+'.png')).convert('RGB').resize((512,512),Image.Resampling.NEAREST)
 x=60+(i%3)*554;y=145+(i//3)*605
 fig.paste(im,(x,y));d.text((x,y+532),str(i+1).zfill(2)+' / '+title,font=font(25,True),fill='#252622')
d.text((60,1377),'Actual floor textures. Shared orientation: 0°. Last field: EXCEPTION on.',font=font(24),fill='#676258')
fig.save(OUT/'one-motif-six-relations.png')
def render(text,prefix):
 text=re.sub(r'<!--\s*@[^>]*-->','',text)
 return markdown.markdown(text,extensions=['extra','sane_lists']).replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
def photo(name,caption):return '<figure><a href="'+name+'.png"><img loading="lazy" src="'+name+'.png" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
before=(OUT/'Tutorial_Tiling_Floor.before.md').read_text(encoding='utf-8');after=(OUT/'Tutorial_Tiling_Floor.after.md').read_text(encoding='utf-8');assert after==(ROOT/'commons/maps/Tutorial_Tiling_Floor/final.md').read_text(encoding='utf-8')
a,b=before.split('\n\n'),after.split('\n\n');pairs=[]
for i,(tag,x,y,u,v) in enumerate(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
 if tag=='equal':continue
 pairs.append('<div class="pair"><div><h3>Before</h3>'+(render('\n\n'.join(a[x:y]),'old'+str(i)) or '<p>New illustration.</p>')+'</div><div><h3>Now</h3>'+render('\n\n'.join(b[u:v]),'new'+str(i))+'</div></div>')
css=re.search(r'<style>(.*?)</style>',(OUT.parent/'2026-09-23-array-molnar-volume/index.html').read_text(encoding='utf-8'),re.S)[1]
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>A rule underfoot — floor tiling</title><style>'+css+'</style></head><body><main>'
page+='''<div class="eyebrow">Ada Research · Arrays and regularity · 23 September 2026</div><h1>A rule underfoot.</h1><p class="intro">Your eye can find a ridge<br>where your foot finds no step.</p><p class="status">Applied to <strong>Tutorial_Tiling_Floor/final.md</strong>. Two small prose refinements and a shared illustration from the artifact’s own images. The working hall is preserved.</p><nav><a href="#encounter">One motif, six relations</a><a href="#museum">The floor in the museum</a><a href="#comparison">Text changes</a><a href="#reading">Read the hall</a><a href="#evidence">Evidence</a><a href="/compose/sources?map=Tutorial_Tiling_Floor&amp;doc=final">Read and comment</a></nav>'''
page+='<section id="encounter"><h2>The image makes a field</h2>'+photo('one-motif-six-relations','Direct exports of the textures applied to the six floor fields, enlarged and labelled. All use the same source orientation; the sixth has its exception on.')+'<p>One turn at the console changes the source orientation in all six. A separate control turns one tile in the sixth field. The unit you recognise—a stripe, a chevron, a larger figure—can emerge across the boundaries of the little square used to make it.</p></section>'
page+='<section id="museum"><h2>What does the floor let you do?</h2>'+photo('floor-eye','At eye height, repeated diagonals occupy the forward view. The five-metre square image lies just above the existing floor; its black triangles are not holes.')+'<div class="photos">'+photo('exception-before','The sixth field before the local turn.')+photo('exception-after','Same camera after EXCEPTION. The changed image has the same position and support.')+'</div><details><summary>All six fields and the existing controls</summary>'+photo('six-fields','The current hall, seen from a raised inspection camera.')+photo('console','TURN MOTIF and EXCEPTION operate the existing artifact.')+'</details></section>'
page+='<section id="comparison"><h2>Preserve the encounter, clarify the return to ground</h2><p>The chapter keeps its six-rule comparison, remainder code, shared-versus-local change and next-hall transition. The opening now follows the flight between cubes; one sentence gives the picture/support distinction a bodily expression. No new artifact, control or map change.</p><details><summary>Original and current passages</summary>'+''.join(pairs)+'</details><p><a href="Tutorial_Tiling_Floor.diff">Exact manuscript diff</a> · <a href="source-changes.diff">Companion notes and core metadata</a></p></section>'
page+='<section id="reading"><article class="reading"><h2>A rule underfoot</h2>'+render(after,'reading')+'</article></section>'
page+='''<section id="evidence" class="evidence"><h2>What was checked</h2><p>42 focused checks pass in the isolated production museum. The existing buttons receive supplied pointer events. A source turn changes all six images; four turns recover their exact original pixels. EXCEPTION changes only the designated tile in the sixth field, and toggling it off restores the original.</p><p>Surface transforms and sampled collision contacts remain unchanged. Supplied key input drives the actual museum controller and body across TRANSLATE, across the hall and across ONE EXCEPTION, including the outer image borders, on level ground. This verifies those crossings; it does not establish what a person perceives or feels in a headset.</p><p>The figure reuses the artifact’s actual generated textures. Museum photographs use selected camera positions. No generated substitute images or altered gameplay were used. Existing startup UID output is retained in the log; no GDScript runtime error occurred.</p><p><a href="report.json">Runtime checks</a> · <a href="source_manifest.json">Capture inputs</a> · <a href="verification.json">Publication checks</a> · <a href="SUMMARY.md">Findings and decisions</a></p></section><footer>Next: Tutorial_Tiling_Walls. The same image stands up, and its support begins to stop the body.</footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8');print('Built native texture figure and review page.')
