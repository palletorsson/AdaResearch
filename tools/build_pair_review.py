"""Illustrated review of the accepted, retained Perlin/Simplex comparison."""
from pathlib import Path
import json,re,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/pair-review-2026-09-13';RUN=R/'ada_run/pair-review-2026-09-13';N='Noise_Perlin_Simplex';H=RUN/N
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and run['checks']==39 and not run['failures']
d=json.loads((H/'probe_pair_live.json').read_text())['measurements'];manifest=[];prefix='noise-perlin-simplex-'
def save(n,s):(O/n).write_bytes(s.encode());manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
for n in ['relief','plate','detuned','matched','witness','terrain','orb','portal','plan']:copy(H/(n+'.png'),prefix+n+'.png')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/{N}/{n}.md',prefix+n+'.md')
copy(H/'probe_pair_live.json',prefix+'evidence.json');copy(RUN/'run.json',prefix+'run.json')
t='''# What counts as the same

[Noise Space 10](noise-space-ten.html) → **Noise Perlin Simplex** → [Cellular Automata: the next row](ca-introduction.html)

[Four primary works and their book passages](/necklace/thread?map=Noise_Perlin_Simplex&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_Perlin_Simplex)

A hollow on one side of the aisle faces a ridge on the other. It is easy to call that the difference between Perlin and simplex. **Walk a little further before deciding.**

![The two retained noise fields, pink sample markers and central comparison instrument](noise-perlin-simplex-relief.png)

The previous room changed the height of one field. Here two generators share the other declared conditions. A different picture can become evidence about a different rule—but only after we ask what else changed.

## Give both fields the same question

SAMPLE moves a pink marker to the same local coordinate in both fields. The plate gives their answers and the signed difference. Use the recorded comparison below to follow all five witnesses.

<!-- comparison -->

The shared integer seed makes each configured generator repeatable. It does not make one ridge the counterpart of another. A larger answer is a larger answer at this address; it does not decide which landscape is more useful.

```gdscript
func sample_pair(p: Vector2) -> Vector2:
    return Vector2(pair[0].sample_at(p.x,p.y), pair[1].sample_at(p.x,p.y))
```

## Change the conditions and let the plate admit it

![The supported live generator plate, shared sample readings and three control buttons facing the entrance](noise-perlin-simplex-witness.png)

The original FREQ and OCTAVES sliders remain on both fields, with REGEN and REPLAY buttons. The central plate now reads their actual state as it changes. Adjust FREQ on just one side and it names the differing sample scale. MATCH returns both fields to their declared settings. Either REPLAY returns only its own side.

The matched pair reports OpenSimplex2 and Perlin, seed 20260910, generator frequency .05, four fBM octaves, gain .5, lacunarity 2, coordinate multiplier 10 and zero offset. These basis names follow the engine's actual definitions. [Godot FastNoiseLite](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html#enumerations).

The plate previously described the intended comparison even after a condition changed. Reading the objects that generate the fields lets the sentence change with the experiment.

## What did the height contribute?

Choose the flat state above. VIEW gives the two displays the same operation: retain the values as colour, but stop using them to lift cube centres. The sampled addresses and generator settings remain unchanged.

The visible square array belongs to the display. It is shared by both algorithms, and is not a direct picture of either generator's internal lattice. Returning to relief gives the answers height again. The fields have 64 cubes each; these are visual comparisons, with a walking aisle between them.

## Keep the other work in the room

![The original pink terrain raised above a low plinth](noise-perlin-simplex-terrain.png)

The small sheet has its own experiment. A timer advances its third noise coordinate by .5 every half-second. Its 484 vertices sample another slice of a three-dimensional field. This is not erosion or a remembered deformation of the previous sheet.

Its inherited name is perlin_noise_terrain. Its actual generator is OpenSimplex2S, with seed one and frequency .07. That difference belongs in the chapter. The work remains useful without becoming a third matched member of the pair.

![The retained dark orb beside the route through the room](noise-perlin-simplex-orb.png)

The orb keeps a separate rhythm too. Both it and the small sheet continue through MATCH. A return always has a scope.

## Five works retained, four in the book

![Overhead view of the comparison hall and its central aisle](noise-perlin-simplex-plan.png)

All five current placements remain, along with every original structure cell and utility. The two fields, small terrain and orb each have a primary book passage. The museum's stale arrangement has been replaced with the current authored map. The control faces now address the entrance, and the instrument has a supported case.

The optional Lab Path portal has no working destination through its current loader. It remains at the side, explicitly labelled **Lab Path - not connected** and inactive. Its connection and short coda remain a separate backlog item. The central museum passage continues into [Cellular Automata](ca-introduction.html).

**39 rendered checks passed:** all eleven actual pointer controls; every displayed sample's height and material mapping through four recorded states; five shared witnesses; live settings and replay; local ownership; the independent terrain clock; and the body crossing the aisle and far doorway. The disabled optional portal is checked as inactive, not certified as working.

Headset reach, comfort, legibility and Quest performance remain for the later headset session.

## Carry the pleasure, keep the question open

The book ending now carries Palle's blob-culture argument. Noise can be an easy, useful filter for the first organic gesture, including a queer expression someone desires. That satisfaction can also become a mental algorithmic wall: many different bodies acquire a familiar appearance before we investigate what else they could do. The next chapter introduces stored states and neighbour relations as further capabilities. Noise can remain part of what we build.

<!-- book -->

[Chapter](noise-perlin-simplex-final.md) · [Tutorial](noise-perlin-simplex-tutorial.md) · [Technical account](noise-perlin-simplex-technical.md) · [Critical account](noise-perlin-simplex-critical.md) · [Recorded evidence](noise-perlin-simplex-evidence.json) · [Run receipt](noise-perlin-simplex-run.json)
'''
save('noise-perlin-simplex.md',t);body=markdown.markdown(t,extensions=['fenced_code','tables'])
lab='''<section class="lab" aria-label="Recorded paired fields"><div class="eyebrow">ONE ADDRESS / TWO ANSWERS</div><div class="controls"><label>Recorded state<select id="state"><option value="0">Matched · relief</option><option value="1">Matched · flat colour</option><option value="2">One frequency changed · flat colour</option><option value="3">Matched return · relief</option></select></label><button id="sample">Next sample</button></div><figure class="photograph"><img id="photo" src="noise-perlin-simplex-relief.png" alt="Matched fields in relief"><figcaption>Godot photograph · Perlin on the left, Simplex on the right from this camera. Photograph marks sample 1; diagrams below follow the selected sample.</figcaption></figure><div class="pair"><figure><figcaption>OPENSIMPLEX2 · recorded samples</figcaption><svg viewBox="0 0 320 320" role="img" aria-label="Simplex sample grid"><g id="field-a"></g><circle id="marker-a" r="10" fill="none" stroke="#ff75b5" stroke-width="4"/></svg></figure><figure><figcaption>PERLIN · recorded samples</figcaption><svg viewBox="0 0 320 320" role="img" aria-label="Perlin sample grid"><g id="field-b"></g><circle id="marker-b" r="10" fill="none" stroke="#ff75b5" stroke-width="4"/></svg></figure></div><div id="reading" aria-live="polite"></div><p class="small">The diagrams plot actual recorded samples using the shared material ramp; photography also includes museum lighting. The diagrams always show colour, including when the photograph shows relief. Their axes are local x horizontally and z upwards. The markers select actual cube centres.</p></section>'''
body=body.replace('<!-- comparison -->',lab).replace('<!-- book -->','<details><summary>Read the book passages</summary><div class="book">'+markdown.markdown((R/f'commons/maps/{N}/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</div></details>')
css=re.search(r'<style>(.*?)</style>',(O/'random-noise-types.html').read_text(encoding='utf-8'),re.S)[1]
css+='button{background:#203237;color:#ecf0da;border:1px solid #789d9e;border-radius:7px;padding:10px 15px;font:inherit;cursor:pointer;align-self:center}.controls{align-items:center}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px;margin:24px 0}.pair figure{margin:0;min-width:0}.pair svg{border:1px solid #789d9e;border-radius:5px}.pair figcaption,.photograph figcaption{font:12px/1.5 ui-monospace,monospace;color:#b7cecb}.photograph{margin:24px 0}#reading{font:15px/1.6 ui-monospace,monospace;color:#ffd2df;overflow-wrap:anywhere}#reading p{margin:7px 0}@media(max-width:600px){.pair{gap:12px}.pair figcaption{font-size:10px}#reading{font-size:13px}}'
js='''const cases=__DATA__;let sample=0;const e=s=>document.querySelector(s);const coords=p=>[(p[0]+2)*80+20,(1.5-p[1])*80+20];const ns='http://www.w3.org/2000/svg';function grid(id,values){const g=e(id);g.replaceChildren();for(const v of values){const p=coords(v.p),r=document.createElementNS(ns,'rect');for(const [k,x] of Object.entries({x:p[0]-20,y:p[1]-20,width:40,height:40,fill:'rgb('+v.color.map(c=>Math.round(c*255)).join(',')+')'}))r.setAttribute(k,x);g.appendChild(r);}}function draw(){const c=cases[+e('#state').value],s=c.samples[sample];e('#photo').src='noise-perlin-simplex-'+c.name+'.png';e('#photo').alt=e('#state').selectedOptions[0].textContent;grid('#field-a',c.fields[0].values);grid('#field-b',c.fields[1].values);for(const id of ['#marker-a','#marker-b']){const p=coords(s.p);e(id).setAttribute('cx',p[0]);e(id).setAttribute('cy',p[1]);}const gs=c.generators;const mismatch=gs[0].sample_scale!==gs[1].sample_scale;const lines=['Sample '+(sample+1)+'/5 · x '+s.p[0].toFixed(1)+' · z '+s.p[1].toFixed(1),'OpenSimplex2 '+s.values[0].toFixed(5)+' · Perlin '+s.values[1].toFixed(5),'Perlin − Simplex = '+s.difference.toFixed(5),'Coordinate multipliers: '+gs[0].sample_scale.toFixed(3)+' / '+gs[1].sample_scale.toFixed(3),mismatch?'Another condition differs: sample scale.':'Matched conditions: only the basis differs.'];e('#reading').replaceChildren(...lines.map(t=>{const p=document.createElement('p');p.textContent=t;return p;}));}e('#state').onchange=draw;e('#sample').onclick=()=>{sample=(sample+1)%5;draw();};draw();'''.replace('__DATA__',json.dumps(d['cases'],separators=(',',':')))
save('noise-perlin-simplex.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What counts as the same · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE PERLIN SIMPLEX</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Built',len(manifest),'review files')
