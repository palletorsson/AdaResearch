"""Illustrated single-hall review with samples from the accepted Godot run."""
from pathlib import Path
import json,re,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/columns-review-2026-09-13';RUN=R/'ada_run/columns-review-2026-09-13';H=RUN/'Noise_Columns'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and not run['failures']
d=json.loads((H/'encounters.json').read_text());manifest=[]
def save(n,s):(O/n).write_bytes(s.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
for n in ['probe_columns_live','probe_columns_matte_live','probe_columns_plan_live','dark_sphere','synthesis_stand']:
 copy(H/(n+'.png'),'noise-columns-'+n+'.png')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Noise_Columns/{n}.md','noise-columns-'+n+'.md')
copy(H/'encounters.json','noise-columns-encounters.json');copy(RUN/'run.json','noise-columns-run.json')
text=f'''# What keeps a body changing?

[Noise Types](random-noise-types.html) → **Noise Columns** → [Noise One](/necklace/thread?map=Noise_One&role=primary)

[Three primary works and their book passages](/necklace/thread?map=Noise_Columns&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_Columns)

**Where does change enter a body?** This hall keeps the existing three-column comparison, the dark orb and its six-orb relative. The route grows through all three: a value enters vertices, appearance, or the choices that construct a body.

![The three existing columns and their improved cased instrument](noise-columns-probe_columns_live.png)

## Take time before naming the movement

Follow one silhouette through more than one return. FREEZE holds the local column clock. SPIN turns a held shape. MARBLE removes the shaft's veining; its folds remain. REVEAL names the held, periodic and field-driven shafts after observation. The base and capital keep their own patterned materials.

The reference is already ribbed, twisted and slightly lowered. A fixed body is itself a construction. The two moving shafts feed the same mesh recipe with different histories. One has a sine's fixed return; the other samples a seeded coherent field along time.

## A shape and its history

The traces below contain 241 samples taken from the **actual Godot driver functions**, at seed 31415, from 0 to 48 seconds in 0.2-second steps. They are two driver histories, not the physical left and right columns. Inspect them before revealing their names. The moving marker reads a recorded sample; it does not run the Godot simulation in the browser.

<!-- viewer -->

The sine's period at speed 0.9 is about 6.98 seconds. Unequal peak intervals in this field trace do not prove that noise can never repeat. The field is deterministic under the same seed, settings and coordinates. Both output scalars feed the same shaft recipe; the mapped drop at the top is 0.70 × phase, in metres.

The field supplies one scalar for the whole shaft. Its ribs, spiral, bulge and height rule decide how to receive that scalar. It is not a 3D noise sample at each vertex. The recipe gives the field a body to act through.

![The shaft veining removed, with the folded geometry retained](noise-columns-probe_columns_matte_live.png)

## A pause has a boundary

The first review found that the CPU shafts stopped while the bases' and capitals' shaders continued to use engine time. FREEZE now reaches those material clock inputs. The held column's shader clocks stay at zero. Other placements of the shared shader keep their existing engine-time behaviour unless they opt into a local clock.

The instrument now reports the last phase used by the displayed shaft, rather than a newer value evaluated between mesh rebuilds. Moving shafts rebuild at most twelve times a second. Continuous-looking movement still has a sampling budget.

![The existing dark orb, with its own independent clock](noise-columns-dark_sphere.png)

Leave the columns paused and watch the orb. Its clock continues to drive a sine into brightness, along with rotation and a spreading ring. Its geometry remains a sphere. The quiet work once called decoration makes the scope of the pause perceptible.

## One family can have more than one body

![The existing hush and swarm variant, now with a clear viewing approach](noise-columns-synthesis_stand.png)

The synthesis stand chooses **hush / swarm** before construction. Six small orbs turn with one parent, their alternating heights and gaps making a distributed body. It uses an array and a circle; it is not a flock of steering agents. The stand's saved score records a selection procedure, not what a visitor must value.

This work was partly concealed by another sculpture. Its new position keeps it visible while retaining the three authored artifacts and the room's recovered structure. A local passage declaration also repairs the earlier break in the museum route.

## What was checked

**{run['checks']} rendered-museum checks passed, with zero failures.** The actual desktop pointer operates all four column controls. All nine material clock inputs hold during the local freeze; the dark orb continues. Identical phases produce identical full shaft-vertex arrays. All three authored works are present, and the museum reports no severance through this hall and its passage.

The accepted run measured about {d['cost']['rebuild_ms']:.1f} ms per rebuilt shaft on this computer. It is not a headset performance result. Display columns have no supporting collision body; retained triangle connectivity is not a proof that the deformed surface is invertible or free from folds. Headset reach, comfort and Quest performance remain for later.

<!-- book -->

[Download the chapter](noise-columns-final.md) · [Technical account](noise-columns-technical.md) · [Critical account](noise-columns-critical.md) · [Captured data](noise-columns-encounters.json) · [Run receipt](noise-columns-run.json)
'''
save('noise-columns.md',text)
body=markdown.markdown(text,extensions=['fenced_code','tables'])
viewer='''<section class="lab" aria-label="Recorded driver histories"><div class="eyebrow">GODOT SAMPLES / SEED 31415</div><label for="time-sample">Recorded time<input id="time-sample" type="range" min="0" max="240" step="1" value="0"></label><div class="controls"><button id="start">Start</button><button id="later">Seven seconds later</button><label><input id="reveal" type="checkbox"> Reveal driver names</label></div><svg id="traces" viewBox="0 0 960 410" role="img" aria-label="Two recorded driver histories"></svg><p id="reading" aria-live="polite"></p><p class="small">Both panels use phase 0–1 and time 0–48 seconds. Displayed drop is derived as 0.70 × the captured phase. No interpolation or normalization between samples.</p></section>'''
book='<details><summary>Read the book passages</summary>'+markdown.markdown((R/'commons/maps/Noise_Columns/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</details>'
body=body.replace('<!-- viewer -->',viewer).replace('<!-- book -->',book)
css=re.search(r'<style>(.*?)</style>',(O/'random-noise-types.html').read_text(encoding='utf-8'),re.S)[1]
css+='input[type=range]{display:block;width:100%;margin:20px 0;accent-color:#a9ddd5}button{background:#203237;color:#ecf0da;border:1px solid #789d9e;border-radius:7px;padding:10px 15px;font:inherit;cursor:pointer}#reading{min-height:4.2em}svg{max-width:100%;display:block}pre{overflow-x:auto}'
js='''const S=__DATA__, T=document.querySelector('#time-sample'), R=document.querySelector('#reveal');
function draw(){let n=Number(T.value), s=S[n], html='';for(const [key,label,c,y] of [['periodic','A','#f2c48b',50],['field','B','#8fe4df',240]]){const X=t=>65+t*850/48,Y=v=>y+120*(1-v);html+=`<text x="65" y="${y-20}" fill="${c}" font-size="18">${R.checked?key.toUpperCase():label}</text><text x="35" y="${y+5}" fill="#bdd1d0">1</text><text x="35" y="${y+125}" fill="#bdd1d0">0</text><path d="M65 ${y} V${y+120} H915" fill="none" stroke="#638385"/><polyline fill="none" stroke="${c}" stroke-width="2.3" points="${S.map(v=>X(v.t)+','+Y(v[key])).join(' ')}"/><line x1="${X(s.t)}" y1="${y}" x2="${X(s.t)}" y2="${y+120}" stroke="#e7ece2" stroke-dasharray="4 4"/><circle cx="${X(s.t)}" cy="${Y(s[key])}" r="5" fill="${c}"/><text x="65" y="${y+144}" fill="#bdd1d0">0 s</text><text x="880" y="${y+144}" fill="#bdd1d0">48 s</text>`;}document.querySelector('#traces').innerHTML=html;document.querySelector('#reading').textContent=`t ${s.t.toFixed(1)} s · ${R.checked?'PERIODIC':'A'}: phase ${s.periodic.toFixed(3)}, top drop ${(0.7*s.periodic).toFixed(3)} m · ${R.checked?'FIELD':'B'}: phase ${s.field.toFixed(3)}, top drop ${(0.7*s.field).toFixed(3)} m`;}
T.addEventListener('input',draw);R.addEventListener('change',draw);document.querySelector('#start').addEventListener('click',()=>{T.value=0;draw()});document.querySelector('#later').addEventListener('click',()=>{T.value=Math.min(240,Number(T.value)+35);draw()});draw();'''.replace('__DATA__',json.dumps(d['whole_hall']['samples'],separators=(',',':')))
save('noise-columns.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What keeps a body changing? · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE COLUMNS</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Built',len(manifest),'review assets')
