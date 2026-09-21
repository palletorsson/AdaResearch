"""Publish the accepted coordinate study as recorded, inspectable comparisons."""
from pathlib import Path
import json,re,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/inside-review-2026-09-13';RUN=R/'ada_run/inside-review-2026-09-13';H=RUN/'Noise_Inside_Noise'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and not run['failures']
d=json.loads((H/'probe_inside_live.json').read_text())['measurements'];manifest=[]
def save(n,s):(O/n).write_bytes(s.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
prefix='noise-inside-noise-'
for n in ['inside-zero','inside-warp','inside-ceiling','inside-door','skin_0','skin_1','skin_2','skin_3','relief','instrument','readout','orb','plan']+[f'{p}_{i}' for p in ['direct','warped'] for i in range(4)]:copy(H/(n+'.png'),prefix+n+'.png')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Noise_Inside_Noise/{n}.md',prefix+n+'.md')
copy(H/'probe_inside_live.json',prefix+'evidence.json');copy(RUN/'run.json',prefix+'run.json')
t='''# Borrow an address

[Noise 6 Wall](noise-six-wall.html) → **Noise Inside Noise** → [Noise Space 10](/necklace/thread?map=Noise_Space_10&role=primary)

[Two primary works and their book passages](/necklace/thread?map=Noise_Inside_Noise&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_Inside_Noise)

Step into the noise sphere. Colour curves above your head and returns towards the floor behind you. Inside, two smaller spheres and an instrument let you follow what changes in the surrounding field. **Where did the difference enter?**

![Standing inside the noise sphere, with the comparison instrument and two smaller spheres in front of the visitor](noise-inside-noise-inside-warp.png)

In the previous room we added weighted answers. Here we change the address at which an answer is sought. The enclosing sphere, the smaller bodies, the images and the coordinate grid give us different places to follow that operation.

## The sphere is where we stand

The ten-metre sphere encloses the visitor, with a continuous circular floor and two opposing side openings. The controls are inside. WARP changes the enclosing field as well as the small comparison; the enclosing wall, ceiling and floor stay fixed.

![Looking upwards from inside the sphere, with noise covering the ceiling](noise-inside-noise-inside-ceiling.png)

The enclosure uses the same warped samples and projection as the smaller body. Its colour gain is .65 and it is drawn without lighting, so the pattern stays visible from within. Scale and lighting differ; the sampling rule is shared.

![Looking towards a real opening from within the enclosing sphere](noise-inside-noise-inside-door.png)

## Start by returning to zero

Choose zero in the recorded comparison below. The two images agree. Then raise the warp amount while following the yellow point. The pink ring names the address from which the right-hand image borrows its value. Next sample selects another witness without changing the images.

<!-- samples -->

These are the actual 96 × 96 images and numerical readings produced in Godot. Each image samples the same square, from −4 to 4 in both coordinates; positive z is upwards. The markers indicate exact query coordinates, which need not coincide with an image's sample centres. At zero the pink ring surrounds the yellow point. With a warp, a visible displacement opens between them.

```gdscript
func address_at(p: Vector2, amount: float) -> Vector2:
    return p + amount * displacement_at(p)

func value_at(p: Vector2, amount: float) -> float:
    var q: Vector2 = address_at(p, amount)
    return base.get_noise_2d(q.x, q.y)
```

The answer from `q` returns to the original place `p` in the image. Two fixed Perlin fields supply the displacement vector; a fixed Value field supplies the answer. Changing the amount changes neither seed nor colour range. The study stays still between actions, so there is no counter to stop and no earlier moment to recover.

## Give the value another job

Now keep the warp at 0.8 and switch between the two recorded sphere views. SKIN applies colour to round geometry. RELIEF also lets the signed value change each vertex's radius. The flat images keep their values through the switch.

<!-- relief -->

The radius of each small sphere is `0.94 + 0.16 × value` metres in RELIEF. This separates two decisions: where the field is sampled, and what receives the result. Turning the warp to zero makes both relief meshes agree again. The small surfaces have no collision. The enclosing sphere has fixed collision and stays round through RELIEF, giving the visitor a steady floor and openings from which to compare those changes.

## A body still needs a mapping

The spheres use direction x and z, multiplied by three, as their field coordinates. Direction y is omitted. Upper and lower points can ask at the same address. Their apparent continuity depends on this particular projection, the mesh vertices and interpolation between them.

The little instrument keeps the coordinate change visible beside the colour images: an original cyan grid, a displaced pink grid, and the selected link between addresses. A curved line in that drawing does not by itself prove a topological tear. It lets us ask a closer question about this mapping.

![The low instrument housing with its paired images, coordinate witness and numerical readout](noise-inside-noise-instrument.png)

**WARP** selects 0, 0.35, 0.8 or 1.4. **SAMPLE** chooses one of five witnesses. **RELIEF** changes how the values shape the two bodies. **ZERO** returns to direct sampling. All four operate through the actual desktop pointer. The supported, tilted case keeps the numerical record beside the material it describes.

## Keep the other time in the room

![The retained dark orb beside the new study](noise-inside-noise-orb.png)

The dark orb keeps its independent sine-driven pulse. It remains a second primary work in the book. An address can change, a value can gain another use, and a material can keep time. The hall gives those differences separate places to become observable.

## Reconnect the hall

![Overhead view of the enclosing sphere within the museum](noise-inside-noise-plan.png)

Both original artifacts remain. The large legacy sphere scene and its shader remain available in other placements; this hall selects an optional coordinate study with a newly declared sampler. It is not a claim that the old dome shader already performed domain warping.

Every original structure cell and utility remains, including the raised exit landing and adjacent wall. The spherical enclosure adds a circular floor over the earlier study's platform and connects to the museum's side passages. One new ground row from the earlier pass wraps around the exit wall. The book sequence already included this hall, but the active museum skipped it; the reviewed row was restored after Noise 6 Wall.

**52 rendered museum checks passed.** The desktop body enters the enclosure and walks out through the opposite opening. Collision rays find the surrounding wall and ceiling, while both doorways stay clear. The instrument's standing position is inside the sphere. The enclosing colour field agrees with the sampler after its declared gain and 8-bit vertex-colour encoding.

The original comparisons also pass: at zero all 9,216 paired image samples agree; every nonzero preset changes them while preserving the baseline. SKIN keeps matching small-sphere geometry; RELIEF follows the actual samples at all 8,514 output vertices while the enclosure stays fixed. All four pointer controls, the independent legacy instance and the museum route pass.

Headset reach, comfort, legibility and Quest performance await the later headset session. These web controls inspect recorded states, so the comparison can be reviewed remotely.

<!-- book -->

Next to develop: **Noise Space 10**. We can carry the distinction between coordinate, value, surface and collision into the question of where a body can go. Its museum connection remains part of that next pass.

[Chapter](noise-inside-noise-final.md) · [Tutorial](noise-inside-noise-tutorial.md) · [Technical account](noise-inside-noise-technical.md) · [Critical account](noise-inside-noise-critical.md) · [Captured evidence](noise-inside-noise-evidence.json) · [Run receipt](noise-inside-noise-run.json)
'''
save('noise-inside-noise.md',t)
body=markdown.markdown(t,extensions=['fenced_code','tables'])
samples='''<section class="lab" aria-label="Recorded coordinate comparison"><div class="eyebrow">SAME BASE FIELD / DIFFERENT ADDRESSES</div><div class="controls"><label>Warp amount<select id="warp"><option value="0">0 · direct sampling</option><option value="1">0.35</option><option value="2" selected>0.8</option><option value="3">1.4</option></select></label><button id="sample">Next sample</button></div><div class="pair"><figure><figcaption>BASE · N(p)<br><small>Yellow p · pink ring q</small></figcaption><svg viewBox="0 0 320 320" role="img" aria-label="Base field with original and borrowed addresses"><image id="direct" width="320" height="320" href="noise-inside-noise-direct_2.png"/><line id="link" stroke="#ffe68b" stroke-width="2"/><circle id="p0" r="4" fill="#ffe68b" stroke="#151c21"/><circle id="q" r="8" fill="none" stroke="#ff85c1" stroke-width="3"/></svg></figure><figure><figcaption>WARPED · N(q(p))<br><small>Yellow p receives the answer from q</small></figcaption><svg viewBox="0 0 320 320" role="img" aria-label="Warped field with its unchanged display address"><image id="warped" width="320" height="320" href="noise-inside-noise-warped_2.png"/><circle id="p1" r="4" fill="#ffe68b" stroke="#151c21"/></svg></figure></div><div id="sample-state" aria-live="polite"></div><p class="small">Recorded Godot samples and images. Colour interpolates the finite image; the numbers evaluate the exact selected addresses. The pink ring remains visible around p when q = p.</p></section>'''
relief='''<section class="lab" aria-label="Recorded relief comparison"><div class="eyebrow">ONE FIELD / TWO USES</div><div class="controls"><button id="relief" aria-pressed="false">Show relief</button><p id="relief-state" aria-live="polite">SKIN · warp 0.8 · colour on round geometry</p></div><img id="sphere-view" src="noise-inside-noise-skin_2.png" alt="Matched spheres with round geometry and different sampled colours"><p class="small">Same camera and warp amount. This swaps two rendered Godot views independently of the address viewer above.</p></section>'''
body=body.replace('<!-- samples -->',samples).replace('<!-- relief -->',relief).replace('<!-- book -->','<details><summary>Read the book passages</summary><div class="book">'+markdown.markdown((R/'commons/maps/Noise_Inside_Noise/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</div></details>')
css=re.search(r'<style>(.*?)</style>',(O/'random-noise-types.html').read_text(encoding='utf-8'),re.S)[1]
css+='button{background:#203237;color:#ecf0da;border:1px solid #789d9e;border-radius:7px;padding:10px 15px;font:inherit;cursor:pointer;align-self:center}.controls{align-items:center}.controls p{color:#e8c78c}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px;margin:25px 0}.pair figure{margin:0;min-width:0}.pair svg{margin:12px 0;border:1px solid #789d9e;border-radius:5px}.pair small{color:#b5c9c8}#sample-state{font:16px/1.65 ui-monospace,monospace;color:#ffe68b;overflow-wrap:anywhere}#sample-state p{margin:8px 0}#sphere-view{aspect-ratio:16/9;object-fit:cover}@media(max-width:600px){.pair{gap:12px;font-size:13px}.pair small{font-size:11px}.pair{grid-template-columns:1fr 1fr}#sample-state{font-size:13px}}'
js='''const cases=__DATA__;let sample=0;const sel=document.querySelector('#warp'),sbtn=document.querySelector('#sample');const point=v=>[(v[0]+4)*40,(4-v[1])*40];function circle(id,p){const e=document.querySelector(id);e.setAttribute('cx',p[0]);e.setAttribute('cy',p[1]);}const vec=v=>'('+v.map(x=>x.toFixed(3)).join(', ')+')';function draw(){const i=+sel.value,c=cases[i],r=c.probes[sample],p=point(r.p),q=point(r.q);document.querySelector('#direct').setAttribute('href','noise-inside-noise-direct_'+i+'.png');document.querySelector('#warped').setAttribute('href','noise-inside-noise-warped_'+i+'.png');circle('#p0',p);circle('#p1',p);circle('#q',q);const l=document.querySelector('#link');for(const [k,v] of Object.entries({x1:p[0],y1:p[1],x2:q[0],y2:q[1]}))l.setAttribute(k,v);document.querySelector('#sample-state').replaceChildren(...['Sample '+(sample+1)+'/5 · warp '+c.strength.toFixed(2),'p '+vec(r.p)+' → q '+vec(r.q),'N(p) '+r.direct.toFixed(4)+' · N(q) '+r.warped.toFixed(4),c.changed_samples.toLocaleString()+' / '+c.samples.toLocaleString()+' image samples differ from baseline'].map(t=>{const p=document.createElement('p');p.textContent=t;return p;}));}sel.onchange=draw;sbtn.onclick=()=>{sample=(sample+1)%5;draw();};draw();let raised=false;const btn=document.querySelector('#relief'),pic=document.querySelector('#sphere-view');btn.onclick=()=>{raised=!raised;btn.textContent=raised?'Return to skin':'Show relief';btn.setAttribute('aria-pressed',String(raised));pic.src='noise-inside-noise-'+(raised?'relief':'skin_2')+'.png';pic.alt=raised?'The same two spheres with signed radial relief':'Matched spheres with round geometry and different sampled colours';document.querySelector('#relief-state').textContent=(raised?'RELIEF · warp 0.8 · colour and signed radial displacement':'SKIN · warp 0.8 · colour on round geometry');};'''.replace('__DATA__',json.dumps(d['cases'],separators=(',',':')))
save('noise-inside-noise.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Borrow an address · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE INSIDE NOISE</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Built',len(manifest),'review assets')
