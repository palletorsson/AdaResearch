from pathlib import Path
import html,re,difflib,markdown,json
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
def font(size,bold=False):return ImageFont.truetype('C:/Windows/Fonts/'+('segoeuib.ttf' if bold else 'segoeui.ttf'),size)
fig=Image.new('RGB',(1740,795),'#eeeae2');draw=ImageDraw.Draw(fig)
draw.text((60,25),'THE TILES STAY. THEIR VALUES CHANGE.',font=font(32,True),fill='#252622')
draw.text((60,74),'One step of the checker, seen from the same place.',font=font(24),fill='#676258')
for i,(name,title,caption) in enumerate([('checker-zero','01 / Phase 0','(x + z + 0) % 2'),('checker-one','02 / Phase 1','(x + z + 1) % 2')]):
 im=Image.open(OUT/(name+'.png')).convert('RGB');im.thumbnail((780,520),Image.Resampling.LANCZOS);x=60+i*840;fig.paste(im,(x,130));draw.text((x,673),title,font=font(28,True),fill='#252622');draw.text((x,716),caption,font=font(24),fill='#676258')
fig.save(OUT/'fixed-addresses-changing-values.png')
def render(text,prefix):
 text=re.sub(r'<!--\s*@[^>]*-->','',text)
 return markdown.markdown(text,extensions=['extra','sane_lists']).replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
def photo(name,caption,ext='png'):return '<figure><a href="'+name+'.'+ext+'"><img loading="lazy" src="'+name+'.'+ext+'" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
before=(OUT/'Tutorial_Disco.before.md').read_text(encoding='utf-8');after=(OUT/'Tutorial_Disco.after.md').read_text(encoding='utf-8');assert after==(ROOT/'commons/maps/Tutorial_Disco/final.md').read_text(encoding='utf-8')
a,b=before.split('\n\n'),after.split('\n\n');pairs=[]
for i,(tag,x,y,u,v) in enumerate(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
 if tag=='equal':continue
 pairs.append('<div class="pair"><div><h3>Before</h3>'+(render('\n\n'.join(a[x:y]),'old'+str(i)) or '<p>New illustration.</p>')+'</div><div><h3>Now</h3>'+render('\n\n'.join(b[u:v]),'new'+str(i))+'</div></div>')
css=re.search(r'<style>(.*?)</style>',(OUT.parent/'2026-09-23-array-molnar-volume/index.html').read_text(encoding='utf-8'),re.S)[1]
report=json.loads((OUT/'report.json').read_text());assert report['passed'];n=len(report['checks'])
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Keep your own time — Tutorial Disco</title><style>'+css+'</style></head><body><main>'
page+='''<div class="eyebrow">Ada Research · Arrays and regularity · 23 September 2026</div><h1>Keep your own time.</h1><p class="intro">The score, the floor,<br>and the body moving across it.</p><p class="status">Applied to <strong>Tutorial_Disco/final.md</strong>. A small change to the opening and a native comparison image. The chapter keeps its investigation of separate clocks and the invitation to keep an unexpected beat.</p><nav><a href="#encounter">Fixed addresses</a><a href="#time">Watch the row</a><a href="#comparison">Text changes</a><a href="#reading">Read the hall</a><a href="#evidence">Evidence</a><a href="/compose/sources?map=Tutorial_Disco&amp;doc=final">Read and comment</a></nav>'''
page+='<section id="encounter"><h2>A changing value at the same address</h2>'+photo('fixed-addresses-changing-values','The actual 12 by 12 floor at successive held checker phases. All 144 tile transforms stay fixed. One step switches their displayed values; another recovers the checker.')+'<p>The earlier halls let us move, copy and arrange objects. Here the tiles can stay exactly where they are while the pattern gives the eye something to follow. Standing still becomes a way to notice the difference.</p></section>'
page+='<section id="time"><h2>What travels?</h2><details id="row-animation"><summary>Open the twelve-state row animation</summary>'+('<figure><img id="row-frame" src="rows-00.png" alt="The native floor at held row phase zero"><figcaption id="row-label">ROWS / phase 0 / row index 0</figcaption></figure><button id="row-play" type="button">Play the twelve states</button><p>Twelve native ROWS states captured through ONE STEP, replayed at 0.75 seconds per image. This is an edited state comparison with no audio.</p>')+'</details>'+photo('underfoot','A selected eye-height view from the position reached by the walking body.')+'<details><summary>The score and the floor control</summary>'+photo('one-note-score','Direct screen export from the placed sequencer. One cell is active in the piano track. Its address remains when its value is turned off.')+photo('floor-console','The existing floor control changes its visual rule and timing; the sequencer retains its own clock.')+'</details><p>A selected note can briefly brighten the floor. Walking across it adds no cells to the score. The chapter asks what happens when these rhythms meet without becoming the same record.</p></section>'
page+='<section id="comparison"><h2>Preserve the investigation</h2><p>The opening now asks the reader to stand still and let the pattern move beneath them. The code, sequencer tutorial, sixteen-to-twelve column fold, bodily question and handoff to coloured stacks are preserved.</p><details><summary>Original and current passages</summary>'+''.join(pairs)+'</details><p>The old technical and critical companions described an unimplemented footstep recorder. Their current versions now distinguish the actual encounter from that possible return. The full originals remain preserved; the recording proposal becomes a future artifact question.</p><p><a href="Tutorial_Disco.diff">Exact manuscript diff</a> · <a href="source-changes.diff">Companion changes and metadata</a> · <a href="before/commons/maps/Tutorial_Disco/critical.md">Earlier movement-as-score proposal</a></p></section>'
page+='<section id="reading"><article class="reading"><h2>How can an arrangement that sits still make a rhythm?</h2>'+render(after,'reading')+'</article></section>'
page+='<section id="evidence" class="evidence"><h2>What was checked</h2><p>'+str(n)+' focused checks pass in the isolated production museum. Supplied pointer events operate the existing floor buttons. Held phase comparisons verify changing values, fixed tile transforms, the checker return, row progression and three speeds. Sequencer UI signals demonstrate the musical clock continuing while the floor holds, and the floor continuing while the score stops.</p><p>Two selected walks use supplied keys through the ordinary museum controller. The visual clock continues; the stored score remains unchanged. The first probe placed the body below the surface by assuming the artifact origin was floor height. The corrected setup starts on the measured standing surface; the production floor and controller were not changed.</p><p>Audio was muted in the isolated capture. These are event and geometry checks, not listening, physical control reach, headset comfort or learner evidence. Native images and the labelled figure are visually inspected; no substitute scene is drawn. Earlier instrument-label and note/address evidence remains <a href="../2026-09-19-arrays-review/disco/AUDIT.md">separately documented</a>.</p><p><a href="report.json">Current checks</a> · <a href="source_manifest.json">Capture inputs</a> · <a href="verification.json">Publication checks</a> · <a href="SUMMARY.md">Findings and decisions</a></p></section><footer>This completes the current Arrays and Regularity pass. Next: Color_Context_Placed, where familiar primitives, transformations and arrays gather into coloured stacks.</footer></main></body></html>'
script = """<script>
const rowView = document.getElementById('row-frame');
const rowLabel = document.getElementById('row-label');
const rowPlay = document.getElementById('row-play');
let rowIndex = 0, rowTimer = null;
function stopRows() { clearInterval(rowTimer); rowTimer = null; rowPlay.textContent = 'Play the twelve states'; }
rowPlay.addEventListener('click', () => {
  if (rowTimer !== null) { stopRows(); return; }
  for (let i = 0; i < 12; i++) { const im = new Image(); im.src = 'rows-' + String(i).padStart(2, '0') + '.png'; }
  rowPlay.textContent = 'Pause';
  rowTimer = setInterval(() => {
    rowIndex = (rowIndex + 1) % 12;
    rowView.src = 'rows-' + String(rowIndex).padStart(2, '0') + '.png';
    rowView.alt = 'Native floor, held ROWS phase ' + rowIndex;
    rowLabel.textContent = 'ROWS / phase ' + rowIndex + ' / row index ' + rowIndex;
  }, 750);
});
document.getElementById('row-animation').addEventListener('toggle', event => { if (!event.target.open) stopRows(); });
document.addEventListener('visibilitychange', () => { if (document.hidden) stopRows(); });
</script>"""
page=page.replace('</body>',script+'</body>')
(OUT/'row-animation.js').write_text(script.removeprefix('<script>').removesuffix('</script>'),encoding='utf-8')
(OUT/'index.html').write_text(page,encoding='utf-8');print('Built native checker figure, pausable twelve-state viewer and review reading.')
