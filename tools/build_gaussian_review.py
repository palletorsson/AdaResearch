"""An illustrated comparison made from captured values, not a replacement sampler."""
from pathlib import Path
import json,hashlib,shutil
import markdown
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/research/possible-bodies';REC=ROOT/'doc/space/gaussian-review-2026-09-12'
RUN=ROOT/'ada_run/gaussian-review-2026-09-12';HALL=RUN/'Random_Gaussian'
run=json.loads((RUN/'run.json').read_text(encoding='utf-8'))
assert run['exit']==0 and not run['failures'] and run['sources_unchanged'] and run['original_hand_unchanged']
histories=json.loads((HALL/'histories.json').read_text(encoding='utf-8'))
edge=histories['expon_edge'];count=run['checks'];manifest=[]
def copy(src,name):shutil.copyfile(src,OUT/name);manifest.append(name)
def save(name,text):(OUT/name).write_bytes(text.encode('utf-8'));manifest.append(name)
for src,dst in [('probe_gaussian_desktop_front_live.png','random-gaussian-desk.png'),('sample_1_12.png','random-gaussian-twelve.png'),('sample_1_300.png','random-gaussian-three-hundred.png'),('sample_0_300.png','random-gaussian-uniform.png'),('probe_gaussian_readout_live.png','random-gaussian-readout.png'),('histories.json','random-gaussian-histories.json'),('probe_gaussian_live.json','random-gaussian-check.json')]:copy(HALL/src,dst)
copy(RUN/'run.json','random-gaussian-run.json')
for name in ['final','tutorial','technical','critical']:copy(ROOT/f'commons/maps/Random_Gaussian/{name}.md',f'random-gaussian-{name}.md')
text='''# The shape we counted

[Random Walk](random-walk.html) → **Random Gaussian** → [Random Mushrooms](random-mushrooms.html)

[The primary and its book passage](/necklace/thread?map=Random_Gaussian&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Gaussian)

A curve is waiting before the beads arrive. What can this particular arrangement tell us before we let the model finish it?

![The existing distribution cabinet from the desktop visitor's operating position](random-gaussian-desk.png)

The `distribution_sampler` remains the room's single primary. Its cabinet, two outboard panels, headline and six-line account are retained. This continuation repairs the sampling and marker bookkeeping, keeps the model curve inside its display, and writes the book around a distinction the controls can actually expose: **the values stay while the account of them moves.**

## Enough to look full

![Twelve actual GAUSS values at seed 31415, with blue sample bars, pale model counts and the orange model shape](random-gaussian-twelve.png)

This is a controlled twelve-value capture. It is not a claim that the cabinet has a twelve-draw button. Its tallest blue bar already occupies almost the full display height. That height alone cannot tell us how many observations support the shape.

The orange model shape now stays inside the frame. Its sign says that it has a separate scale. Pale model-count bars share the blue bars' count scale, providing the quantitative comparison at the present N. Empty blue bins still have the cabinet's one-centimetre baseline.

## Same count, another law

<!-- comparison-images -->

These two captures use the same seed and N=300, with thirty bins and a shared camera. The sampler constructs GAUSS using a guarded Box–Muller transform. UNIFORM uses each draw directly. More UNIFORM draws will not turn their law into a Gaussian law.

```gdscript
var u1 := maxf(_rand(), 0.0001)
var u2 := _rand()
var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
return _fit(gaussian_mean + z * gaussian_std)
```

The logarithm guard matters at both ends. The earlier added offset could push an input above one and make the square root invalid. The repaired lower guard keeps values finite; it also limits the computed tail. The ideal model remains a reference against which to examine a finite numerical implementation.

## Change the grouping

Choose a small sample, then increase N. Change the bins while leaving N fixed. Compare the mean computed from the retained values with the estimate from bin centres. The latter can move even though every value remains.

This reading view uses exported Godot values and model probabilities. It makes no fresh random draws. The plots use visible count axes, with one shared height scale across the pair; their zero-count bars have zero height. “Retained mean” is an extra calculation for this review. The VR plate shows the binned estimate.

<!-- histogram-view -->

The optional tick strip exposes individual retained values without changing them. In the cabinet, BINS cycles 30 → 60 → 10 → 30. Returning to the earlier partition restores its counts and estimates.

## What the edge absorbs

The previous room reflected an overshoot. Here the display clamps an out-of-range value to zero or one:

```gdscript
func _fit(raw: float) -> float:
    if raw < 0.0 or raw > 1.0:
        _clipped += 1
    return clampf(raw, 0.0, 1.0)
```

The retained value loses its original distance past the edge. The clipped counter remembers that the crossing occurred. Edge-bin counts also contain ordinary interior values, so they cannot substitute for that counter.

At common seed 31415 none of the thousand EXPON draws is clipped, despite the ideal model's nonzero right tail. The second exponential sample above is deliberately selected: **seed __EDGE_SEED__, __EDGE_CLIPS__ clipped draws**. The recorded selection rule was the first seed in 1–20 with at least one clipped value among a thousand. It shows how the edge behaves; it is not presented as a typical sample or a larger clipping probability.

## A pause with something still happening

![The cabinet's account identifies issued and landed evidence, clipping, bins, seed and running state](random-gaussian-readout.png)

PAUSE stops new automatic draws. Already airborne beads keep falling. CLEAR now removes their meshes as well as their records, preserves paused/running state and restarts the named seed. BATCH lands up to one hundred immediately and reserves room for beads already in flight.

The check exercises a cap of ten with four beads airborne: BATCH can land only six. Further manual samples and batches add nothing until CLEAR starts another run. After PAUSE, the existing four can finish and bring the landed total to ten. Beads now land at the height of the bar actually drawn.

This is a local pause; the museum keeps running. The controls give a group a repeatable sample to discuss without pretending to suspend every process around it.

## What is ready

**__CHECKS__ independent desktop checks passed, zero assertion failures, engine exit 0.** These cover the existing nine control paths, actual desktop pointer input, law comparisons, seed replay, retained-value rebinning, logarithm endpoints, airborne capacity, marker cleanup, bar landing height, model-curve bounds, access and unload/rebuild.

The review contains four common-seed samples of one thousand values each and the separately labelled edge example. Intermediate count snapshots are frozen copies and checked against their own N. An earlier export held mutable count arrays and is retained only as rejected evidence. Two subsequent review-harness compile errors were corrected before the accepted run.

The room's 14×22 layers, recovered floor/platforms, teleporter floor override and secondary artifacts remain. Headset approach, small lettering and Quest performance still need the later visit. The accepted run's startup diagnostics are recorded separately from the passing checks; no headset verification is claimed.

[Desktop report](random-gaussian-check.json) · [Run receipt](random-gaussian-run.json) · [Captured values](random-gaussian-histories.json) · [Tutorial](random-gaussian-tutorial.md) · [Technical notes](random-gaussian-technical.md) · [Critical text](random-gaussian-critical.md)

**Next: [Random Mushrooms](random-mushrooms.html).** Which properties of a body are the sampled values allowed to change?
'''.replace('__EDGE_SEED__',str(edge['seed'])).replace('__EDGE_CLIPS__',str(sum(edge['clipped']))).replace('__CHECKS__',str(count))
images='<div class="comparison-images"><figure><img src="random-gaussian-three-hundred.png" alt="GAUSS at N 300 and seed 31415"><figcaption>GAUSS · N 300 · seed 31415</figcaption></figure><figure><img src="random-gaussian-uniform.png" alt="UNIFORM at N 300 and seed 31415"><figcaption>UNIFORM · N 300 · seed 31415</figcaption></figure></div>'
view='''<section class="histogram-view" aria-label="Captured distribution comparisons"><div class="controls">
<label>Compare <select id="comparison"><option value="laws">GAUSS / UNIFORM · seed 31415</option><option value="discrete">POISSON / GAUSS · seed 31415</option><option value="edges">EXPON / selected edge sample</option></select></label>
<label>Landed values <select id="sample-count"><option value="1">1</option><option value="12" selected>12</option><option value="100">100</option><option value="300">300</option><option value="1000">1000</option></select></label>
<label>Bins <select id="bins"><option value="30" selected>30</option><option value="60">60</option><option value="10">10</option></select></label></div>
<p id="comparison-status" role="status" aria-live="polite"></p><div class="plots"><figure><figcaption id="left-title"></figcaption><svg id="left-plot" viewBox="0 0 480 335" role="img"></svg><p id="left-account"></p></figure><figure><figcaption id="right-title"></figcaption><svg id="right-plot" viewBox="0 0 480 335" role="img"></svg><p id="right-account"></p></figure></div>
<label class="option"><input type="checkbox" id="show-values"> Show individual retained values · review only</label><p class="legend">Blue: observed counts. Pale gold: ideal-model expected counts at the same N. Tick marks, when shown: retained values; clipped values are red. Both plots use the same count axis.</p><p id="selection-note"></p><noscript>Download the captured values below to inspect the samples.</noscript></section>'''
script='''<script>
const data=__DATA__,ns='http://www.w3.org/2000/svg',$=id=>document.getElementById(id);
const pairs={laws:[['gauss','GAUSS'],['uniform','UNIFORM']],discrete:[['poisson','POISSON'],['gauss','GAUSS']],edges:[['expon','EXPON'],['expon_edge','EXPON · selected edge example']]};
function counts(values,bins){const c=Array(bins).fill(0);for(const v of values)c[Math.max(0,Math.min(bins-1,Math.floor(v*bins)))]++;return c;}
function render(){const n=Number($('sample-count').value),b=Number($('bins').value),pair=pairs[$('comparison').value];
 const records=pair.map(([key,title])=>{const h=data[key],values=h.values.slice(0,n),c=counts(values,b),model=data[key==='expon_edge'?'expon':key].rebinned[String(b)].expected.map(e=>e*n/1000);return{h,values,c,model,title};});
 const max=Math.max(1,...records.flatMap(r=>r.c.concat(r.model))),top=Math.ceil(max*1.1);
 records.forEach((r,index)=>{const side=index?'right':'left',svg=$(side+'-plot');svg.replaceChildren();
 function add(tag,attrs,text){const e=document.createElementNS(ns,tag);for(const[k,v]of Object.entries(attrs))e.setAttribute(k,v);if(text!==undefined)e.textContent=text;svg.append(e);return e;}
 const x=v=>48+v*410,y=c=>275-c/top*235,w=410/b;
 add('title',{},`${r.title}, N ${n}, ${b} bins, seed ${r.h.seed}`);add('rect',{x:0,y:0,width:480,height:335,fill:'#fcfaf5'});
 for(const value of [0,top/2,top]){add('line',{x1:48,y1:y(value),x2:458,y2:y(value),stroke:'#d8dbd2','stroke-dasharray':'3 5'});add('text',{x:40,y:y(value)+4,'text-anchor':'end','font-size':12,fill:'#48554e'},Number.isInteger(value)?value:value.toFixed(1));}
 add('text',{x:48,y:24,'font-size':13,fill:'#48554e'},'count');
 for(let i=0;i<b;i++){add('rect',{x:48+i*w+1,y:y(r.model[i]),width:Math.max(1,w-2),height:275-y(r.model[i]),fill:'#ebd8a3',stroke:'#bba875','stroke-width':.6});const bar=add('rect',{x:48+i*w+w*.18,y:y(r.c[i]),width:Math.max(.7,w*.64),height:275-y(r.c[i]),fill:'#367d9b','data-bin':i,'data-count':r.c[i]});const title=document.createElementNS(ns,'title');title.textContent=`${(i/b).toFixed(3)}–${((i+1)/b).toFixed(3)}: ${r.c[i]} observed; ${r.model[i].toFixed(2)} expected`;bar.append(title);}
 for(const v of [0,.5,1])add('text',{x:x(v),y:297,'text-anchor':'middle','font-size':13,fill:'#48554e'},v);
 if($('show-values').checked)r.values.forEach((v,i)=>add('line',{x1:x(v),x2:x(v),y1:310+(i%3)*5,y2:314+(i%3)*5,stroke:r.h.clipped[i]?'#b43b58':'#537467','stroke-width':1,opacity:r.h.clipped[i]?1:.55,'data-value':v}));
 const exact=r.values.reduce((s,v)=>s+v,0)/n,binned=r.c.reduce((s,c,i)=>s+c*(i+.5)/b,0)/n,clipped=r.h.clipped.slice(0,n).filter(Boolean).length;
 $(side+'-title').textContent=`${r.title} · seed ${r.h.seed}`;
 $(side+'-account').textContent=`Retained mean ${exact.toFixed(6)} · binned mean ${binned.toFixed(3)}. Clipped ${clipped}; edge bins ${r.c[0]} | ${r.c[b-1]}.`;
 svg.setAttribute('aria-label',`${r.title}: ${n} values in ${b} bins; retained mean ${exact.toFixed(6)}, binned mean ${binned.toFixed(3)}, ${clipped} clipped.`);
 });
 $('comparison-status').textContent=`${n} retained values per plot · ${b} bins · changing bins makes no new draws.`;
 $('selection-note').textContent=$('comparison').value==='edges'?`Right sample deliberately selected: ${data.expon_edge.selection}. Its full thousand contains ${data.expon_edge.clipped.filter(Boolean).length} clipped values; a shorter prefix may contain none.`:'Both samples use seed 31415. Different laws consume and transform its draws differently.';
}
for(const id of ['comparison','sample-count','bins','show-values'])$(id).addEventListener('change',render);render();
</script>'''.replace('__DATA__',json.dumps(histories,separators=(',',':')))
style=(OUT/'synthesis-lab.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+='''.comparison-images,.plots{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.comparison-images figure,.plots figure{margin:10px 0;min-width:0}.comparison-images img{width:100%;margin:0}.comparison-images figcaption,.plots figcaption{font-size:14px;line-height:1.4}.histogram-view{background:#fbf8f0;border:1px solid #c2bbaa;padding:24px;border-radius:8px}.controls{display:flex;gap:12px;flex-wrap:wrap;align-items:center}.controls label,.option{font-size:14px}select{font:inherit;font-size:14px;padding:9px;border:1px solid #716658;border-radius:4px;background:white;color:#242a2c}select:focus-visible,input:focus-visible{outline:3px solid #743653;outline-offset:3px}.plots svg{width:100%;display:block;margin:10px 0}.plots p,.legend,#comparison-status,#selection-note{font-size:14px;line-height:1.5}.option{display:block;margin:12px 0}.option input{accent-color:#b23756}h1{font-size:clamp(32px,5vw,46px)}@media(max-width:600px){body{padding:0 14px}.histogram-view{padding:12px}.plots,.comparison-images{grid-template-columns:1fr}.controls label{max-width:100%}.controls select{max-width:100%;font-size:12px}}'''
final=(ROOT/'commons/maps/Random_Gaussian/final.md').read_text(encoding='utf-8')
save('random-gaussian.md',text.replace('<!-- comparison-images -->','![GAUSS, N 300](random-gaussian-three-hundred.png)\n\n![UNIFORM, N 300](random-gaussian-uniform.png)').replace('<!-- histogram-view -->','[Compare the captured values](random-gaussian.html).')+'\n## Book passage\n\n'+final)
body=markdown.markdown(text,extensions=['fenced_code','tables']).replace('<!-- comparison-images -->',images).replace('<!-- histogram-view -->',view)
body+='<details><summary>Read the book passage</summary>'+markdown.markdown(final,extensions=['fenced_code'])+'</details>'
save('random-gaussian.html','<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The shape we counted · Ada Research</title><style>'+style+'</style></head><body><main>'+body+'</main>'+script+'</body></html>\n')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode('utf-8'))
(REC/'publication-hashes.json').write_bytes((json.dumps({n:hashlib.sha256((OUT/n).read_bytes()).hexdigest() for n in manifest},indent=2)+'\n').encode('utf-8'))
print(json.dumps({'checks':count,'files':len(manifest),'edge_seed':edge['seed'],'edge_clips':sum(edge['clipped'])}))
