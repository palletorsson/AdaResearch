from pathlib import Path
import json,re,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/wall-review-2026-09-13';RUN=R/'ada_run/wall-review-2026-09-13';H=RUN/'Noise_6_Wall'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and not run['failures']
d=json.loads((H/'probe_wall_live.json').read_text())['measurements'];manifest=[]
def save(n,s):(O/n).write_bytes(s.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
for n in ['panel','readout','entrance','interior-sum','interior-dressed','orb','plan','gpu_1','gpu_2','gpu_4','gpu_6']:copy(H/(n+'.png'),'noise-six-wall-'+n+'.png')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Noise_6_Wall/{n}.md','noise-six-wall-'+n+'.md')
copy(H/'probe_wall_live.json','noise-six-wall-evidence.json');copy(RUN/'run.json','noise-six-wall-run.json')
t='''# The room wears the sum

[Noise Voxel](noise-voxel.html) → **Noise 6 Wall** → [Noise Inside Noise](/necklace/thread?map=Noise_Inside_Noise&role=primary)

[Two primary works and their book passages](/necklace/thread?map=Noise_6_Wall&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_6_Wall)

There is a room inside the hall. Pink gathers in its corners; the little sphere seems to have borrowed something from its walls. **What would have to change for those apparent folds to carry your feet?**

![The staged shader enclosure, with a clear side entrance and the retained pink interior](noise-six-wall-entrance.png)

The enclosure was already here, but its walls extended beyond the museum hall. It now fits around a five-metre floor with two opposing doors. You can enter, look around, and walk out the other side. The original panel, internal sphere and independent dark orb all remain.

## Hold the moment. Change the dress.

These are two actual Godot captures with the same camera, held phase, Perlin basis and six cloud terms. DRESS switches between the cloud accumulation and the complete pink finish. Compare the floor, sphere and opening. The geometry and collision shapes remain the same.

<!-- dress -->

Grey has its own encoding: a gain of two and clipping into the display range. It lets us inspect one part of the construction. The complete finish adds four terms of turbulence, density, colour, corner and edge shading, roughness and a small change to the lighting normal. A surface can be understood and still be desired.

## One instrument, several surfaces

![The supported panel, four comparison patches, cased readout and four reachable desktop controls](noise-six-wall-readout.png)

**LAYERS** sends 1, 2, 4 or 6 cumulative cloud terms into the room and its sphere. **BASIS** changes the shader generator separately. **FREEZE** holds the current local moment without jumping to time zero. **DRESS** changes the finish. The four little windows retain their separate counts and share the selected clock and basis.

The state now reaches the complete local receiver. The sphere also needed its material applied at the combined CSG root that actually draws it; changing a shader below that node had left a misleading result. The repaired wall and sphere shaders produce matching output at matching UV coordinates.

## How much does one more term add?

This small viewer uses the rendered shader captures from the same held moment. Choose a term count and inspect the contribution it adds. The displayed mean is the red channel sampled at 256 positions in each 96 × 96 capture; it is a display measurement, not the raw field value.

<!-- terms -->

Each term adds a weighted absolute value, then halves the amplitude and doubles the frequency for the next term. At a fixed coordinate, additional nonnegative terms cannot reduce the sum. The total weights are **.5 → .75 → .9375 → .984375**. Actual brightness also depends on the sampled magnitudes and the display mapping. The later terms add smaller variations; they are not merely a uniform brightness adjustment.

The live shader branch begins with this accumulation. The code is in the book below, so the reader can move between the room's appearance and the operation that produces it.

## Follow a cloud towards a seam

The material crosses from a square to an enclosure and a sphere. Each wall piece starts its own UV chart, and the sphere wraps another chart around its body. The same calculation can stretch, repeat or meet a seam. This is a shared procedure on several surfaces; it does not claim continuous world-space sampling around the room.

The seam gives us something to discover. Knowing how the dress fits makes another alteration possible. The grey comparison is also a dress: it maps values into something we can see, with a range that can hide differences.

![The retained dark orb on solid floor near the exit](noise-six-wall-orb.png)

The dark orb continues its sine-driven emission while the room is held. FREEZE has a local reach. The book keeps this second primary because the hall contains more than one time, and because a varying value can still find another operation to receive it.

## The complete hall remains

![Overhead view after the pointer tests, showing the staged room and retained surrounding map](noise-six-wall-plan.png)

All three authored placements remain. The map's recovered structure and utilities are unchanged; the new artifact floor bridges the central opening. The orb moves to solid floor near the exit. The overhead view follows the control tests and shows another state: Value, one cloud term, live greyscale. It is not the held Perlin comparison above.

The large legacy scene resource remains available in other placements. This hall explicitly selects the compact room stage. The shared shaders also receive a normal-map encoding correction, which can change shading in their other consumers.

**39 rendered museum checks passed.** They include held/resumed state, complete local control propagation, an excluded outside receiver, sphere/wall shader readback and unchanged collision shapes through DRESS. All four buttons work through the actual desktop pointer with synthetic mouse events. The desktop body crosses both doors and the floor; the surrounding museum route stays connected.

Headset reach, comfort, legibility and Quest performance remain for the later headset session. The web comparisons are recorded states, so you can review the work remotely.

<!-- book -->

Next is **Noise Inside Noise**: from adding answers to changing the coordinates at which another field is read.

[Download the chapter](noise-six-wall-final.md) · [Tutorial](noise-six-wall-tutorial.md) · [Technical account](noise-six-wall-technical.md) · [Critical account](noise-six-wall-critical.md) · [Captured evidence](noise-six-wall-evidence.json) · [Run receipt](noise-six-wall-run.json)
'''
save('noise-six-wall.md',t)
body=markdown.markdown(t,extensions=['fenced_code','tables'])
dress='''<section class="lab" aria-label="Recorded room comparison"><div class="eyebrow">ONE MOMENT / TWO FINISHES</div><div class="controls"><button id="dress" aria-pressed="true">Show cloud sum</button><p id="dress-state" aria-live="polite">PINK FINISH · 6 cloud terms · Perlin · held</p></div><img id="room-image" src="noise-six-wall-interior-dressed.png" alt="The held room and sphere wearing the complete pink cloud finish"><p class="small">Same camera and phase. The button swaps two Godot photographs; the room is not being simulated in the browser.</p></section>'''
terms='''<section class="lab" aria-label="Recorded cloud term comparison"><div class="eyebrow">ONE COORDINATE CHART / FOUR PREFIXES</div><div class="term-grid"><img id="term-image" src="noise-six-wall-gpu_6.png" alt="Six accumulated cloud terms rendered in greyscale"><div><label>Cloud terms<select id="terms"><option value="0">1 term</option><option value="1">2 terms</option><option value="2">4 terms</option><option value="3" selected>6 terms</option></select></label><p id="weights" aria-live="polite"></p><p id="mean" aria-live="polite"></p><p class="small">Perlin · same held phase · gain 2 · 96 × 96 captured pixels. This comparison changes term count only. The room comparison above keeps six terms.</p></div></div></section>'''
body=body.replace('<!-- dress -->',dress).replace('<!-- terms -->',terms).replace('<!-- book -->','<details><summary>Read the book passages</summary>'+markdown.markdown((R/'commons/maps/Noise_6_Wall/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</details>')
css=re.search(r'<style>(.*?)</style>',(O/'random-noise-types.html').read_text(encoding='utf-8'),re.S)[1]
css+='button{background:#203237;color:#ecf0da;border:1px solid #789d9e;border-radius:7px;padding:10px 15px;font:inherit;cursor:pointer;align-self:center}pre{overflow-x:auto}.controls{display:flex;align-items:center;gap:20px;flex-wrap:wrap}.controls p{margin:0;color:#e8c78c}.term-grid{display:grid;grid-template-columns:minmax(180px,300px) 1fr;gap:32px;align-items:center}.term-grid img{width:100%;border:1px solid #49605a}#weights{color:#e8c78c;font-size:22px}#room-image{width:100%;aspect-ratio:16/9;object-fit:cover}@media(max-width:600px){.term-grid{grid-template-columns:1fr}.term-grid img{max-width:300px}}'
payload=[{k:x[k] for k in ['layers','mean_display_red']} for x in d['gpu']['patches']]
js='''const cases=__DATA__,weights=[.5,.75,.9375,.984375];let dressed=true;const room=document.querySelector('#room-image'),btn=document.querySelector('#dress');btn.onclick=()=>{dressed=!dressed;room.src='noise-six-wall-interior-'+(dressed?'dressed':'sum')+'.png';room.alt=dressed?'The held room and sphere wearing the complete pink cloud finish':'The same held room and sphere displaying only the greyscale cloud sum';btn.textContent=dressed?'Show cloud sum':'Restore pink finish';btn.setAttribute('aria-pressed',String(dressed));document.querySelector('#dress-state').textContent=(dressed?'PINK FINISH':'CLOUD SUM')+' · 6 cloud terms · Perlin · held';};const sel=document.querySelector('#terms');function draw(){const i=+sel.value,c=cases[i];document.querySelector('#term-image').src='noise-six-wall-gpu_'+c.layers+'.png';document.querySelector('#term-image').alt=c.layers+' accumulated cloud terms rendered in greyscale';document.querySelector('#weights').textContent='Accumulated weight '+weights[i];document.querySelector('#mean').textContent='Mean captured red channel '+c.mean_display_red.toFixed(4)+' / range 0–1';}sel.onchange=draw;draw();'''.replace('__DATA__',json.dumps(payload,separators=(',',':')))
save('noise-six-wall.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The room wears the sum · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE 6 WALL</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Built',len(manifest),'review assets')
