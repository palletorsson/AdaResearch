from pathlib import Path
import json,re,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/torus-review-2026-09-13';RUN=R/'ada_run/torus-review-2026-09-13';H=RUN/'Noise_One'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and not run['failures']
d=json.loads((H/'probe_torus_live.json').read_text())['measurements'];manifest=[]
def save(n,s):(O/n).write_bytes(s.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
for n in ['pair','readout','terrain','orb','plan']:copy(H/(n+'.png'),'noise-one-'+n+'.png')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Noise_One/{n}.md','noise-one-'+n+'.md')
copy(H/'probe_torus_live.json','noise-one-evidence.json');copy(RUN/'run.json','noise-one-run.json')
t=f'''# What does a value become?

[Noise Columns](noise-columns.html) → **Noise One** → [Noise Voxel](/necklace/thread?map=Noise_Voxel&role=primary)

[Three primary works and book passages](/necklace/thread?map=Noise_One&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_One)

**The full hall changes the question.** The pair of rings asks how a field becomes relief or colour. The existing landscape extends that into combination. The dark orb brings its own periodic brightness. All three belong in the book.

![Matching rings, field markers and controls in the actual museum](noise-one-pair.png)

## A dark patch has a history

Watch the rings before pausing. FREEZE now holds the current local moment, including both shader stages. SAMPLE moves matching coordinate probes. AMPLITUDE changes how far a value moves a vertex; FREQUENCY changes where the field is sampled.

The initial colour rule sends every negative value to black. **REMAP** gives those differences another address: `(value + 1) / 2`. The relief and field stay the same. A difference that looked absent returns through a change in the receiving operation.

![The cased coordinate readout, showing a negative sample as inward relief and remapped brightness](noise-one-readout.png)

## Try the receiving operation

These are **72 values captured from the Godot instrument**, around its outer equator at t = {d['samples']['time']} s, coordinate frequency {d['samples']['frequency']:.0f} and displacement amplitude {d['samples']['amplitude']:.2f} m. The graph changes the reading of those recorded values; it does not run the VR scene. The photographs show a separate held comparison at frequency 14.

<!-- viewer -->

The field is addressed in local x and z, with no y input. A three-dimensional body is receiving a two-dimensional field. Relief is sampled at vertices, colour across rendered fragments; the displayed scalar is not a measurement of a final lit pixel.

## The landscape that was already here

![The original three-source terrain in a compact basin, with its coordinate frame and contribution controls](noise-one-terrain.png)

The old scene was 200 units wide and placed 20 metres overhead. It now appears at one-fiftieth scale in the room's existing opening. Its complete terrain generator, three noise resources and three coordinate planes remain. SUM, LOW, MIDDLE and HIGH expose the weighted contributions through a panel at the southern edge.

The names deserve inspection: LOW and MIDDLE have nearly equal base frequencies, but different algorithms, seeds and octave counts. The contributions are not three isolated frequency bands. Each view also receives the original three-pass slope-lowering operation. Since that processing comes after addition, the visible SUM need not equal the three processed views added together.

The terrain keeps its violet material. Grass, rock and snow colours are computed in the source but are not enabled as the visible albedo. A calculation can be present without being selected for display. The visible terrain triangles do have a matching collider; the rings' pictured folds do not.

## A pause has an address

![The retained dark orb beside the exit, with its own animation](noise-one-orb.png)

The orb keeps pulsing while the rings are held. It receives a remapped sine through emission, and turns independently. A familiar work can extend the lesson without being converted into another noise demonstration.

![Plan view of the retained room structure and the new terrain staging](noise-one-plan.png)

## What the review established

**{run['checks']} checks passed in the rendered museum.** The desktop pointer reaches all nine controls. FREEZE holds the shader and CPU phase; 256 rendered GPU field samples differ from CPU values by at most {d['gpu_readback']['max_error']:.7f}. The pair now uses a reproducible integer lattice hash; legacy single-ring placements retain the original floating hash.

The terrain restores every one of its 10,201 vertices when SUM returns. Each mode has one collider matching the displayed triangles. The recovered map structure and utilities remain unchanged, all three authored works are retained, and the museum reports a connected route. Headset reach, comfort and Quest performance remain for later.

<!-- book -->

[Download the chapter](noise-one-final.md) · [Technical account](noise-one-technical.md) · [Critical account](noise-one-critical.md) · [Captured evidence](noise-one-evidence.json) · [Run receipt](noise-one-run.json)
'''
save('noise-one.md',t)
body=markdown.markdown(t,extensions=['fenced_code','tables'])
viewer='''<section class="lab" aria-label="Recorded field readings"><div class="eyebrow">ONE CAPTURED FIELD / TWO COLOUR RULES</div><div class="controls"><button id="start">Start</button><button id="next">Next coordinate</button><label><input id="remap" type="checkbox"> Remap signed values</label></div><svg id="field" viewBox="0 0 960 420" role="img" aria-label="Signed field values and their brightness encoding"></svg><p id="reading" aria-live="polite"></p><p class="small">Top: signed field, -1 to +1. Bottom: brightness factor, 0 to 1. Both show the same 72 coordinates; the highlighted coordinate is reported below.</p></section>'''
body=body.replace('<!-- viewer -->',viewer).replace('<!-- book -->','<details><summary>Read the book passages</summary>'+markdown.markdown((R/'commons/maps/Noise_One/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</details>')
css=re.search(r'<style>(.*?)</style>',(O/'random-noise-types.html').read_text(encoding='utf-8'),re.S)[1]
css+='button{background:#203237;color:#ecf0da;border:1px solid #789d9e;border-radius:7px;padding:10px 15px;font:inherit;cursor:pointer}#reading{min-height:4.2em}svg{max-width:100%;display:block}pre{overflow-x:auto}'
js='''const S=__DATA__;let idx=0;const R=document.querySelector('#remap');
function draw(){let out='<text x="62" y="27" fill="#d6e6d8" font-size="18">FIELD / signed value</text><text x="62" y="247" fill="#d6e6d8" font-size="18">COLOUR / '+(R.checked?'REMAP':'CLIP')+'</text>';out+='<path d="M60 42V195H918M60 268V380H918M60 118H918" stroke="#738b88" fill="none"/>';for(let i=0;i<S.length;i++){const s=S[i],x=65+i*11.8,v=s.value,b=R.checked?s.remapped:s.clipped;out+=`<rect x="${x}" y="${v>=0?118-v*70:118}" width="8" height="${Math.abs(v)*70}" fill="${v<0?'#bd9ade':'#87d9c7'}"/><rect x="${x}" y="${380-b*110}" width="8" height="${Math.max(.5,b*110)}" fill="#f0c592"/>`;if(i===idx)out+=`<path d="M${x+4} 40V200M${x+4} 265V390" stroke="#f4f2da" stroke-dasharray="4 3"/>`;}out+='<text x="23" y="52" fill="#c6d9d4">+1</text><text x="30" y="122" fill="#c6d9d4">0</text><text x="23" y="194" fill="#c6d9d4">−1</text><text x="30" y="279" fill="#c6d9d4">1</text><text x="30" y="384" fill="#c6d9d4">0</text>';document.querySelector('#field').innerHTML=out;const s=S[idx];document.querySelector('#reading').textContent=`Coordinate ${idx+1}/72 · field ${s.value.toFixed(3)} · relief ${s.relief.toFixed(3)} m · ${R.checked?'REMAP':'CLIP'} brightness ${(R.checked?s.remapped:s.clipped).toFixed(3)}`;}
document.querySelector('#next').onclick=()=>{idx=(idx+1)%S.length;draw()};document.querySelector('#start').onclick=()=>{idx=0;draw()};R.onchange=draw;draw();'''.replace('__DATA__',json.dumps(d['samples']['samples'],separators=(',',':')))
save('noise-one.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What does a value become? · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE ONE</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Built',len(manifest),'review assets')
