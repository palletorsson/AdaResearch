"""Publishable Mushroom hall study with captured populations and an inspectable plan."""
from pathlib import Path
import json,shutil,hashlib
import markdown
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'doc/research/possible-bodies'
REC=ROOT/'doc/space/mushrooms-review-2026-09-12';RUN=ROOT/'ada_run/mushrooms-review-2026-09-12'
HALL=RUN/'Random_Mushrooms';run=json.loads((RUN/'run.json').read_text(encoding='utf-8'))
assert run['exit']==0 and not run['failures'] and run['sources_unchanged']
log=(HALL/'engine.log').read_text(encoding='utf-8')
assert 'SHADER ERROR:' not in log and 'SCRIPT ERROR:' not in log
data=json.loads((HALL/'populations.json').read_text(encoding='utf-8'));manifest=[]
def save(n,s):(OUT/n).write_bytes(s.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,OUT/n);manifest.append(n)
images=['population-size-on','population-size-off','population-other-seed','population-ring','population-rejected','probe_mushrooms_desktop_front_live','probe_mushrooms_readout_live','probe_mushrooms_edibles_live','probe_mushrooms_eaten_live']
for n in images:copy(HALL/(n+'.png'),'random-mushrooms-'+n+'.png')
for n in ['populations.json','probe_mushrooms_live.json']:copy(HALL/n,'random-mushrooms-'+n)
copy(RUN/'run.json','random-mushrooms-run.json')
for n in ['final','tutorial','technical','critical']:copy(ROOT/f'commons/maps/Random_Mushrooms/{n}.md',f'random-mushrooms-{n}.md')
text='''# Which differences were invited?

[Random Gaussian](random-gaussian.html) → **Random Mushrooms** → [Random Game](random-game.html)

[The primary and book passage](/necklace/thread?map=Random_Mushrooms&role=primary) · [Waves, randomness and noise](/research/waves-chance-noise/index.html#Random_Mushrooms)

In the previous room the numbers gathered into bars. Here they have caps and stems. Which differences can this recipe make?

![The six templates and their controls from the actual desktop operating position](random-mushrooms-probe_mushrooms_desktop_front_live.png)

The specimen bed already gives us five useful actions: SHOW, KIND, SIZE, REGROW and NEW SEED. We keep that work, enlarge the housed readout and make `mushrooms` the book hero as well as the primary. The six placed artifacts and the hall's recovered structure remain.

## Remove one use of a draw

Choose **Scale 1, same seed** below. The same 94 instances occupy the same positions, with the same templates and orientations. Their individual scale multipliers change to one. Their templates still have different dimensions.

The capture checks more than a repeated count: it compares every instance, every stored ground height, the template detail positions and the planted edible positions. Returning to size variation restores the earlier record.

```gdscript
func _size(v: float) -> float:
    return v if size_variation else 1.0
```

The scale draw is still consumed before `_size` chooses whether to use it. Removing the draw would pass different random values to the decisions that follow. Holding the seed is only part of holding an experiment still.

<!-- population-view -->

## The circle the bed could not hold

![The ring routine's members marked in the actual seed-31415 bed](random-mushrooms-population-ring.png)

At seed 31415, the ring requests **17 members and places seven**. The other ten candidate positions fall outside the bed. This circle was specified by a centre, a radius and equal angular intervals; it did not emerge from an interaction between mushrooms. Enable the requested ring in the plan to see what the boundary leaves out. That reconstruction is a review feature; the cabinet's plate reports placed membership.

The scattered candidates use a different permission: **71 accepted, nine rejected** from eighty proposals. Rings and clusters do not pass through that noise threshold. Their members may overlap existing bodies. The three routines share a place, not an admission rule.

## The template also has a past

The six slots are construction recipes. A new seed can change details inside one: the puffball's twelve bumps are drawn when its template is built, then copied into the field and onto the table. Seeds 31415 and 27182 give different bump positions; REGROW repeats them within either seed. A reference object is also made by a procedure.

Continuous scale variation never makes a seventh template between two others. A proposed next experiment could vary cap and stem independently, but that would need a new construction rule. The current controls let us identify that missing capability without pretending it already exists.

![The enlarged readout keeps the six lines together on the specimen table](random-mushrooms-probe_mushrooms_readout_live.png)

## Another capability under a similar cap

![A separately pickable mushroom just inside the bed's edge](random-mushrooms-probe_mushrooms_edibles_live.png)

Three edible mushrooms come from another scene. They can be picked up; the ordinary template copies cannot. In the headset, holding one within 0.25 m of the active camera consumes it, adds five health units where the manager supports that call, and triggers a visual effect. Its peak lasts ten seconds, with a fade in and out.

The desktop carry holds it beyond the eating distance. The test uses the real grab ray and carry first, then explicitly calls the eating function as a desktop substitute. It does not claim to reproduce the headset gesture.

![The actual desktop eating path after repairing the effect shader and overlay](random-mushrooms-probe_mushrooms_eaten_live.png)

The first pass found the effect timer running while the desktop shader failed to compile. After repairing the shader branch, a rendered test exposed an overlay with no viewport-sized surface. The overlay now takes its viewport's dimensions and follows size changes. A fixed test image verifies zero-intensity passthrough and a visible change at intensity 0.8; the live eating path verifies the full-screen rectangle too. A state flag alone was insufficient evidence.

This changes the observer's view rather than the mushroom population's arrangement. REGROW restores the planted mushrooms, but does not rewind the player's health or the whole museum.

## What is ready

**__CHECKS__ independent desktop checks passed, zero assertion failures, engine exit 0.** The accepted log has no GDScript or shader compilation errors. The earlier shader failure and subsequent overlay-size failure are retained in the review record. Existing startup diagnostics are recorded separately.

The interactive plan uses captured Godot records. It does not draw a new population. Symbols show identity, placement routine and transform scale; they are not cap footprints or collision geometry. The plan omits height, lighting and overlap in depth. Matched camera captures let those simplifications be compared with the material scene. The full requested ring and point inspection are browser review tools, not new VR controls.

Headset lettering, tracked-hand reach, the felt perception effect and Quest performance remain for the later visit. The visible terrain and its collider use triangles; the population's ground lookup uses an interpolated height grid. Exact contact at every stem is a separate open inspection, not established by these route checks.

[Captured populations](random-mushrooms-populations.json) · [Desktop report](random-mushrooms-probe_mushrooms_live.json) · [Run receipt](random-mushrooms-run.json) · [Tutorial](random-mushrooms-tutorial.md) · [Technical notes](random-mushrooms-technical.md) · [Critical text](random-mushrooms-critical.md)

**Next: [Random Game](random-game.html).** When a draw enters an encounter, which capabilities does the body need to answer it?
'''.replace('__CHECKS__',str(run['checks']))
view='''<section class="population-view" aria-label="Captured mushroom population">
<div class="controls">
<label>Population <select id="population"><option value="seed_31415">Size variation · seed 31415</option><option value="size_off">Scale 1, same seed</option><option value="seed_27182">Another population · seed 27182</option></select></label>
<label>Show <select id="kind"><option value="all">All construction routines</option><option value="scattered">Scattered</option><option value="ring">Ring members</option><option value="cluster">Cluster members</option><option value="rejected">Rejected candidates</option><option value="template">One template</option></select></label>
<label>Template <select id="template"><option value="0">0 · Tan</option><option value="1" selected>1 · Red</option><option value="2">2 · Flat brown</option><option value="3">3 · Tall white</option><option value="4">4 · Puffball</option><option value="5">5 · Glowing</option></select></label>
</div><p id="population-status" role="status"></p>
<div class="study-pair"><figure><svg id="population-plan" viewBox="0 0 680 470" role="group" aria-label="Plan of the captured population"></svg><figcaption>Local x / z in metres. Circle size encodes scale multiplier, not physical cap size. Select a circle to inspect an instance.</figcaption></figure>
<figure><img id="population-image" src="random-mushrooms-population-size-on.png" alt="Captured bed at seed 31415 with size variation"><figcaption id="image-caption">Matched camera · seed 31415 · SIZE on</figcaption></figure></div>
<label class="option"><input id="requested-ring" type="checkbox"> Reveal the requested ring, including positions outside the bed · review only</label>
<p class="legend">Blue: scattered. Green: ring. Violet: cluster. Grey crosses: rejected scatter candidates. Gold diamonds: separately planted edibles.</p>
<label class="option">Inspect instance <select id="inspect-instance" aria-label="Inspect instance"></select></label>
<p id="instance-detail">Select an instance in the plan. Its record will appear here.</p>
<p id="ring-account"></p>
</section>'''
script='''<script>
const populations=__DATA__, $=id=>document.getElementById(id),ns='http://www.w3.org/2000/svg';
const colours={scattered:'#287899',ring:'#32834e',cluster:'#884787'};
function render(){
 const key=$('population').value,d=populations[key],kind=$('kind').value,t=Number($('template').value),svg=$('population-plan');svg.replaceChildren();
 const x=v=>340+v*45,y=v=>220-v*45;
 function add(tag,attrs,text){const e=document.createElementNS(ns,tag);for(const[k,v]of Object.entries(attrs))e.setAttribute(k,v);if(text!==undefined)e.textContent=text;svg.append(e);return e;}
 add('rect',{x:0,y:0,width:680,height:470,fill:'#faf8ef'});add('rect',{x:x(-3),y:y(3),width:270,height:270,fill:'#e7eadb',stroke:'#655b44','stroke-width':3});
 for(const v of [-3,0,3]){add('line',{x1:x(v),y1:y(3),x2:x(v),y2:y(-3),stroke:'#c3cbb5','stroke-dasharray':'3 5'});add('line',{x1:x(-3),y1:y(v),x2:x(3),y2:y(v),stroke:'#c3cbb5','stroke-dasharray':'3 5'});add('text',{x:x(v),y:379,'text-anchor':'middle',fill:'#4a5348','font-size':15},v);add('text',{x:187,y:y(v)+5,'text-anchor':'end',fill:'#4a5348','font-size':15},v);}
 add('text',{x:488,y:380,fill:'#4a5348','font-size':15},'x');add('text',{x:182,y:72,fill:'#4a5348','font-size':15},'z');
 if($('requested-ring').checked){d.rings.forEach((r,group)=>{add('circle',{cx:x(r.centre[0]),cy:y(r.centre[1]),r:r.radius*45,fill:'none',stroke:'#397749','stroke-width':1.5,'stroke-dasharray':'5 5'});for(let i=0;i<r.requested;i++){const a=2*Math.PI*i/r.requested,px=r.centre[0]+Math.cos(a)*r.radius,pz=r.centre[1]+Math.sin(a)*r.radius,out=Math.abs(px)>3||Math.abs(pz)>3;add('circle',{cx:x(px),cy:y(pz),r:5.5,fill:'none',stroke:out?'#a5463c':'#397749','stroke-width':1.5,'data-requested':i,'data-outside':out});}});}
 const inspectSelect=$('inspect-instance');inspectSelect.replaceChildren(new Option('Choose an instance',''));
 d.instances.forEach((m,i)=>inspectSelect.add(new Option(`${i} · template ${m.template} · ${m.kind}`,String(i))));
 function inspect(i){const m=d.instances[i];inspectSelect.value=String(i);$('instance-detail').textContent=`Instance ${i} · template ${m.template} · ${m.kind}${m.group>=0?' group '+m.group:''}. Local position (${m.x.toFixed(3)}, ${m.y.toFixed(3)}, ${m.z.toFixed(3)}) m; yaw ${m.yaw.toFixed(2)}°; scale ${m.scale.toFixed(3)}.`;}
 inspectSelect.onchange=()=>{if(inspectSelect.value!=='')inspect(Number(inspectSelect.value));};
 let highlighted=0;
 d.instances.forEach((m,i)=>{const selected=kind==='all'||kind===m.kind||(kind==='template'&&m.template===t);if(selected)highlighted++;
  const point=add('circle',{cx:x(m.x),cy:y(m.z),r:5*m.scale,fill:colours[m.kind],stroke:kind==='template'&&selected?'#aa236e':'#fcfaf3','stroke-width':kind==='template'&&selected?2:1,opacity:selected?1:.12,tabindex:0,role:'button','aria-label':`Instance ${i}: template ${m.template}, ${m.kind}, scale ${m.scale.toFixed(3)}`,'data-instance':i,'data-scale':m.scale,'data-highlighted':selected});
  point.addEventListener('click',()=>inspect(i));point.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();inspect(i);}});
 });
 d.rejected_positions.forEach((p,i)=>{add('path',{d:`M ${x(p[0])-3} ${y(p[2])-3} l 6 6 m -6 0 l 6 -6`,stroke:'#54565b','stroke-width':kind==='rejected'?2.5:1,opacity:kind==='rejected'||kind==='all'?1:.15,'data-rejected':i});});
 d.edible.planted_at.forEach((p,i)=>add('path',{d:`M ${x(p[0])} ${y(p[2])-5} l 5 5 l -5 5 l -5 -5 Z`,fill:'#aa741e',stroke:'#fff9d4','stroke-width':1,'data-edible':i}));
 const n=d.instances.filter(m=>m.kind==='scattered').length;
 $('population-status').textContent=`Seed ${d.seed} · ${d.instances.length} population instances · ${n} scattered + ${d.rejected} rejected = ${d.candidates} candidates · ${kind==='rejected'?d.rejected:highlighted} highlighted · ${d.edible.planted} separate edibles.`;
 $('ring-account').textContent=d.rings.map((r,i)=>`Ring ${i}: ${r.requested} requested, ${r.placed} placed, ${r.requested-r.placed} outside the bed.`).join(' ');
 let photo={seed_31415:['population-size-on','Captured bed at seed 31415 with size variation','Matched camera · seed 31415 · SIZE on · photo shows template 1'],size_off:['population-size-off','Same seed-31415 bed with all instance scales set to one','Matched camera · seed 31415 · SIZE off · photo shows template 1'],seed_27182:['population-other-seed','Captured bed at seed 27182 with size variation','Matched camera · seed 27182 · SIZE on · photo shows template 1']}[key];
 if(key==='seed_31415'&&kind==='ring')photo=['population-ring','Captured seed-31415 ring members marked in green','Matched camera · seed 31415 · photo shows ring members'];
 if(key==='seed_31415'&&kind==='rejected')photo=['population-rejected','Captured seed-31415 rejected candidates marked in grey','Matched camera · seed 31415 · photo shows rejected candidates'];
 $('population-image').src='random-mushrooms-'+photo[0]+'.png';$('population-image').alt=photo[1];$('image-caption').textContent=photo[2];
 $('instance-detail').textContent='Select an instance in the plan. Its record will appear here.';
}
for(const id of ['population','kind','template','requested-ring'])$(id).addEventListener('change',render);render();
</script>'''.replace('__DATA__',json.dumps(data,separators=(',',':')))
style=(OUT/'synthesis-lab.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+='''.population-view{border:1px solid #c7c2b0;border-radius:8px;background:#faf8ef;padding:22px}.controls{display:flex;flex-wrap:wrap;gap:12px}.controls label,.option,.legend,figcaption,#population-status,#instance-detail,#ring-account{font-size:14px;line-height:1.5}select{font:inherit;padding:8px;border:1px solid #7a7262;border-radius:4px;background:white;color:#242b27;max-width:100%}.study-pair{display:grid;grid-template-columns:1fr 1fr;gap:18px;align-items:center}.study-pair figure{margin:0;min-width:0}.study-pair svg,.study-pair img{width:100%;display:block;margin:0 0 8px}.option{display:block;margin:16px 0}input{accent-color:#8c3666}circle[role=button]{cursor:pointer}circle[role=button]:focus{outline:none;stroke:#161a15;stroke-width:3}select:focus-visible,input:focus-visible{outline:3px solid #a1447e;outline-offset:3px}#instance-detail{min-height:3em;padding:12px;background:#eeeade}h1{font-size:clamp(32px,5vw,46px)}@media(max-width:720px){.study-pair{grid-template-columns:1fr}.population-view{padding:12px}body{padding:0 14px}}'''
final=(ROOT/'commons/maps/Random_Mushrooms/final.md').read_text(encoding='utf-8')
save('random-mushrooms.md',text.replace('<!-- population-view -->','[Inspect the captured population](random-mushrooms.html).')+'\n## Book passage\n\n'+final)
body=markdown.markdown(text,extensions=['fenced_code','tables']).replace('<!-- population-view -->',view)
body+='<details><summary>Read the book passage</summary>'+markdown.markdown(final,extensions=['fenced_code'])+'</details>'
save('random-mushrooms.html','<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Which differences were invited? · Ada Research</title><style>'+style+'</style></head><body><main>'+body+'</main>'+script+'</body></html>\n')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode('utf-8'))
print(json.dumps({'checks':run['checks'],'files':len(manifest),'captured_instances':[len(d['instances']) for d in data.values()]}))
