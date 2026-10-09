from pathlib import Path
import html,re,difflib,json
import markdown
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]

def font(size,bold=False):return ImageFont.truetype('C:/Windows/Fonts/'+('segoeuib.ttf' if bold else 'segoeui.ttf'),size)
fig=Image.new('RGB',(1800,1090),'#eeeae2');d=ImageDraw.Draw(fig)
d.text((40,25),'SUPER TRIANGLE',font=font(36,True),fill='#252622')
d.text((40,80),'Six arrangements on the same floor. Let the edges move.',font=font(25),fill='#676258')
families=['Diagonals','Chevrons','Diamonds','Turning waves','Large diamonds','Super diamonds']
for n,title in enumerate(families):
 im=Image.open(OUT/('triangles-'+str(n*4).zfill(2)+'.png')).convert('RGB');im.thumbnail((550,390),Image.Resampling.LANCZOS)
 x=40+(n%3)*590;y=140+(n//3)*470;fig.paste(im,(x,y))
 d.text((x,y+385),f'{n+1:02d} / {title}',font=font(25,True),fill='#252622')
fig.save(OUT/'triangle-combinations.png')

def render(text):return markdown.markdown(re.sub(r'<!--\s*@[^>]*-->','',text),extensions=['extra','sane_lists'])
def photo(name,caption):return '<figure><a href="'+name+'.png"><img loading="lazy" src="'+name+'.png" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
before=(OUT/'Tutorial_Disco.before.md').read_text(encoding='utf-8');after=(OUT/'Tutorial_Disco.after.md').read_text(encoding='utf-8');assert after==(ROOT/'commons/maps/Tutorial_Disco/final.md').read_text(encoding='utf-8')
a,b=before.split('\n\n'),after.split('\n\n');pairs=[]
for tag,x,y,u,v in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes():
 if tag=='equal':continue
 pairs.append('<div class="pair"><div><h3>Before</h3>'+(render('\n\n'.join(a[x:y])) or '<p>No triangle encounter.</p>')+'</div><div><h3>Added</h3>'+render('\n\n'.join(b[u:v]))+'</div></div>')
css=re.search(r'<style>(.*?)</style>',(OUT.parent/'2026-09-23-array-molnar-volume/index.html').read_text(encoding='utf-8'),re.S)[1]
css+='\n.motion{max-width:980px;margin:auto}.motion img{width:100%;display:block}.motion button{padding:.7em 1em;margin:.3em .4em .3em 0;cursor:pointer}.motion input{width:100%}.motion label{display:block;margin:.8em 0}.motion figcaption{min-height:2em}button:focus-visible,input:focus-visible{outline:3px solid #ac496f;outline-offset:3px}'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Super Triangle — the disco floor</title><style>'+css+'</style></head><body><main>'
page+='''<div class="eyebrow">Ada Research · Arrays and regularity · 23 September 2026</div><h1>Super Triangle.</h1><p class="intro">An edge turns.<br>Another figure appears.</p><p class="status">Built into the existing disco floor. At the floor console, press <strong>PATTERN</strong> until <strong>SUPER TRIANGLE</strong> appears, just after SNAKE. PLAY / HOLD, ONE STEP and SPEED all apply.</p><nav><a href="#motion">Watch it move</a><a href="#combinations">Six combinations</a><a href="#reading">Read the hall</a><a href="#changes">Text changes</a><a href="#evidence">Evidence</a><a href="/compose/sources?map=Tutorial_Disco&amp;doc=final">Read and comment</a></nav>'''
page+='''<section id="motion"><h2>Let the diagonal move.</h2><div class="motion"><figure><img id="motion-frame" src="motion-000.png" alt="The native museum floor at triangle phase zero"><figcaption id="motion-label">DIAGONALS · pose 0.00</figcaption></figure><button id="motion-play" type="button" aria-pressed="false">Play the movement</button><button id="motion-step" type="button">Next pose</button><label for="motion-position">Explore the twelve-second cycle</label><input id="motion-position" type="range" min="0" max="95" step="1" value="0"><p>Native Godot frames sampled from the actual shader, replayed silently at eight frames per second. Pause anywhere or scrub to compare. In the museum the shader moves continuously; ONE STEP selects the next exact pose.</p></div></section>'''
page+='<section id="combinations"><h2>From one triangle to a larger figure</h2>'+photo('triangle-combinations','Six native views at held poses 0, 4, 8, 12, 16 and 20. Diagonals, chevrons and turning waves meet larger diamond groupings. The last two motifs span two and three tile pitches.')+'<p>The new mode makes a return to the earlier half-square floor motif. Rotation and scale change what can be seen across neighbouring addresses. The level floor continues to carry the walking body.</p>'+photo('triangles-underfoot','A view from the body’s reached position after crossing the running triangle floor.')+'<details><summary>The same small floor console</summary>'+photo('triangle-console','PATTERN reaches the new mode. HOLD keeps an intermediate turn; ONE STEP advances to its next pose. SPEED changes the visual timing.')+'</details><p>The four earlier modes remain available. The shared controller also gives the later coloured disco this mode with its selected palette.</p></section>'
page+='<section id="changes"><h2>A small addition to the chapter</h2><p>Two paragraphs and one shared illustration connect the new movement to the fixed array addresses. The earlier score, independent clocks, folded columns and moving body remain in the text.</p><details><summary>Original and added passage</summary>'+''.join(pairs)+'</details><p><a href="Tutorial_Disco.diff">Exact manuscript diff</a> · <a href="source-changes.diff">Implementation and companion changes</a></p></section>'
page+='<section id="reading"><article class="reading"><h2>How can an arrangement that sits still make a rhythm?</h2>'+render(after)+'</article></section>'
page+='''<section id="evidence" class="evidence"><h2>What was checked</h2><p>121 focused checks pass in the isolated production museum. The same controls receive supplied pointer input. Tests retain the existing checker and row comparisons and separate clocks, then cover all 24 triangle poses, the cycle return, holding an intermediate pose, stepping from that pose, musical column pulses and their expiry, selected palette inputs, mode return, unchanged tile transforms and collision.</p><p>Three selected walks use supplied keys through the ordinary museum controller, including a crossing of the running triangle floor. The score is unchanged by walking. The colour palette is checked through the shared controller; the later colour hall was not separately visited. Audio was muted. Headset comfort and listening quality remain untested.</p><p>The first pulse assertion ran before the next process/render cycle. Waiting for that rendered frame confirms both the recorded column and its shader texture. The first report is retained. Existing startup UID, viewport-texture and renderer warnings are recorded in the log; there are no new shader or script errors. Figures use native captures with labels and resizing only.</p><p><a href="report.json">Passing checks</a> · <a href="first-report.json">First run</a> · <a href="source_manifest.json">Capture manifest</a> · <a href="verification.json">Publication checks</a> · <a href="SUMMARY.md">Findings and decisions</a></p></section><footer>Next in the spine: Color_Context_Placed. Familiar primitives, transformations and arrays gather into coloured stacks.</footer></main>'''
js='''const frame=document.getElementById('motion-frame');
const label=document.getElementById('motion-label');
const play=document.getElementById('motion-play');
const slider=document.getElementById('motion-position');
const families=['DIAGONALS','CHEVRONS','DIAMONDS','TURNING WAVES','LARGE DIAMONDS','SUPER DIAMONDS'];
let index=0,timer=null,preloaded=false;
function show(i){index=(i+96)%96;frame.src='motion-'+String(index).padStart(3,'0')+'.png';frame.alt='Native museum floor, triangle pose '+(index/4).toFixed(2);label.textContent=families[Math.floor(index/16)]+' · pose '+(index/4).toFixed(2);slider.value=String(index);}
function stop(){clearInterval(timer);timer=null;play.textContent='Play the movement';play.setAttribute('aria-pressed','false');}
play.addEventListener('click',()=>{if(timer!==null){stop();return;}if(!preloaded){for(let i=0;i<96;i++){const im=new Image();im.src='motion-'+String(i).padStart(3,'0')+'.png';}preloaded=true;}play.textContent='Pause';play.setAttribute('aria-pressed','true');timer=setInterval(()=>show(index+1),125);});
slider.addEventListener('input',()=>{stop();show(Number(slider.value));});
document.getElementById('motion-step').addEventListener('click',()=>{stop();show((Math.floor(index/4)+1)*4);});
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
'''
(OUT/'motion-viewer.js').write_text(js,encoding='utf-8')
page+='<script>'+js+'</script></body></html>'
(OUT/'index.html').write_text(page,encoding='utf-8')
print('Built shared triangle figure, native motion viewer and chapter reading.')
