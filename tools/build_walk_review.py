"""Build an illustrated, source-grounded reading of the existing Random Walk hall."""
from pathlib import Path
import json, shutil, hashlib
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/research/possible-bodies'
REC=ROOT/'doc/space/walk-review-2026-09-12'
RUN=ROOT/'ada_run/walk-review-2026-09-12'
HALL=RUN/'Random_Walk'
run=json.loads((RUN/'run.json').read_text(encoding='utf-8'))
assert run['exit']==0 and not run['failures'] and run['checks']==129
assert run['sources_unchanged'] and run['original_hand_unchanged']
manifest=[]
def copy(src,name):shutil.copyfile(src,OUT/name);manifest.append(name)
def save(name,text):(OUT/name).write_bytes(text.encode('utf-8'));manifest.append(name)
for src,dst in [('probe_walk_desktop_front_live.png','random-walk-desk.png'),('walk_2d_300.png','random-walk-2d.png'),('walk_3d_300.png','random-walk-3d.png'),('walk_levy_300.png','random-walk-levy.png'),('probe_walk_logbook_live.png','random-walk-logbook.png'),('histories.json','random-walk-histories.json'),('probe_walk_live.json','random-walk-check.json')]:copy(HALL/src,dst)
copy(RUN/'run.json','random-walk-run.json')
for name in ['final','tutorial','technical','critical']:copy(ROOT/f'commons/maps/Random_Walk/{name}.md',f'random-walk-{name}.md')

text='''# The trail is already elsewhere

[Random Remove](random-remove.html) → **Random Walk** → [Random Gaussian](random-gaussian.html)

[The primary and its book passage](/necklace/thread?map=Random_Walk&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Walk)

Follow the red bead until a turn begins to look like hesitation. What would the next step need to know for that reading to become a capability?

![The existing terrarium and logbook wing from the desktop visitor's viewpoint](random-walk-desk.png)

The room keeps Claude's existing `random_walk_terrarium` as its one primary: a glass tank, dark backboard, enlarged red bead, keypad and logbook wing. All twelve placements and the recovered floor remain. This continuation tests the encounter independently and lets its actual rules carry the book.

## A plane, a volume, a longer reach

Start with 2D. Move around the case and notice the level the bead cannot leave. In 3D that coordinate opens. An apparent crossing might separate when you change your viewpoint. LEVY changes the proposed length as well as the direction; its longest permitted step is 0.15 m.

<!-- mode-images -->

These three captures share a camera and seed 31415. Each follows 300 updates of five walkers. They are controlled source captures: simulation time reads 10 seconds while the unadvanced frame clock reads zero. There is no visitor pause control. The modes consume their random draws differently, so these are not identical paths with another coordinate attached.

## The point the line leaves out

Look for a turn near a wall. The next position is proposed, then folded if it lies outside. The displayed segment joins the retained endpoints. It does not include the contact with the glass.

```gdscript
var step = _generate_step()
var new_pos = _walker_positions[i] + step

# Boundary reflection
new_pos = _reflect_boundaries(new_pos)
```

The reading view below uses actual positions and proposals exported from the Godot artifact, with no replacement random generator. Select **LEVY**, then **Next reflected step** to show its proposal. The amber endpoint is what the draw attempted; red is the position the enclosure kept. Change projection to inspect a difference hidden along another axis. In these particular 300-step captures, the followed 2D and 3D beads never require a reflection. The LEVY bead does, eleven times.

<!-- walk-view -->

These browser controls belong to the review. The complete captured history and proposed endpoint are not displays added to the VR cabinet. ONE/ALL exists in both places; in Godot all five walkers continue stepping whichever is bright.

The default line keeps only two hundred previous positions. At step 300 those are positions 100–299; the bead is at 300. Show the complete captured history to recover the beginning in this review. Turn that option off and it leaves again. The source has to retain different data to make that return possible.

## A trail the next step never consults

```gdscript
_walker_trails[i].append(_walker_positions[i])
if _walker_trails[i].size() > trail_length:
    _walker_trails[i] = _walker_trails[i].slice(1)

_walker_positions[i] = new_pos
```

Keep where we were. Shorten the record. Put the bead where we are now. The ordering makes the trail lag by one update even before its earliest points are discarded.

The independent check replayed all three captured walks, cleared the stored trails at step 60, and switched from ONE to ALL. Every later position of all five walkers still agreed exactly. The check also confirmed that the stored trail was actually empty before continuing. This is evidence about the unused trail; the program still has position, generator, mode and timing state.

The familiar parts have accumulated: point, coordinates, sampled line, array, increment, draw. To make a bead avoid its own trail would require another connection between those parts. The desire to read a creature in the tangle can suggest that next experiment without making it an existing capability.

## Two accounts of time

![The housed logbook names the rule, steps, clocks, retained trail, seed and boundary](random-walk-logbook.png)

The simulation count and frame clock can diverge. At thirty updates a second, a two-second frame would ordinarily supply sixty updates. The implementation accepts at most five, while its frame clock gains the supplied two seconds. The excess is discarded, not queued for a later frame. The source test verifies both the five accepted updates and the absence of a backlog.

RESET replays the named procedure at equal step counts. It does not reset every fractional timing accumulator. NEW SEED explicitly rejects the current five-digit number, though an older one may return later. Different modes consume different numbers of draws; the seed alone does not specify the path.

The cabinet's MSD measures the five beads' average squared distance from their release point. It can decrease while the trail grows. Glass bounds the possible value; it does not make the reading a measure of path length, history or entropy.

## What is ready

**129 independent desktop checks passed, zero assertion failures, engine exit 0.** The seven control signals, actual desktop pointer 2D/NEW SEED/RESET, three walk rules, reflection, replay, trail retention, clock cap, physical access and unload/rebuild were exercised. Three complete 300-step histories record five walkers each; every frame was checked against replay.

The neighbouring sampling pavilion's string boolean now uses its existing parser, allowing its east observation-window setting to load. The previous script errors are absent. This is the only production-script change; the terrarium itself is preserved. The pavilion annotation now distinguishes a proposed step from the endpoint the walls fold back.

All twelve placements instantiate. The pavilion and a pixel cloud occupy some local routes; the tested door-to-door and terrarium approaches remain open. The fine trails are pale through the glass in these desktop captures, and the small lettering still needs a person at headset distance. No Quest-performance or tracked-hand claim is made.

The run retains startup diagnostics for the audio UID, certificate store and logger, renderer/registry warnings, and two unset viewport-texture errors from the catalyst crystal. These are separate from the repaired window parser. There are no script errors or shutdown leak warnings in this run.

[Desktop report](random-walk-check.json) · [Run receipt](random-walk-run.json) · [Captured histories](random-walk-histories.json) · [Tutorial](random-walk-tutorial.md) · [Technical notes](random-walk-technical.md) · [Critical text](random-walk-critical.md)

**Next: [Random Gaussian](random-gaussian.html).** We gather draws by frequency and ask what kind of shape that account makes visible.
'''
histories=json.loads((HALL/'histories.json').read_text(encoding='utf-8'))
images='<div class="mode-images">'+''.join(f'<figure><img src="random-walk-{key}.png" alt="{label}: actual five-walker tank after 300 steps at seed 31415"><figcaption>{label} · 300 steps · seed 31415</figcaption></figure>' for key,label in [('2d','2D'),('3d','3D'),('levy','LEVY')])+'</div>'
view='''<section class="walk-view" aria-label="Captured random walks">
<div class="controls"><label>Rule <select id="mode"><option value="2d">2D</option><option value="3d">3D</option><option value="levy">LEVY</option></select></label><label>Projection <select id="projection"><option value="0,2">X / Z · top</option><option value="0,1">X / Y · front</option><option value="2,1">Z / Y · side</option></select></label><label>Follow <select id="follow"><option value="one">ONE</option><option value="all">ALL</option></select></label></div>
<svg id="walk-plot" viewBox="0 0 640 500" role="img" aria-label="Projection of captured walk positions"></svg>
<div class="controls"><button id="previous" type="button">Previous step</button><button id="next" type="button">Next step</button><button id="reflection" type="button">Next reflected step</button><button id="reset" type="button">Return to release</button></div>
<label class="timeline">Step <input id="time" type="range" min="0" max="300" step="1" value="300"><output id="step-output" for="time">300</output></label>
<p id="walk-status" role="status" aria-live="polite"></p>
<label class="option"><input id="full" type="checkbox"> Show the complete captured history · review only</label>
<label class="option"><input id="proposal" type="checkbox"> Show the last proposed step · review only</label>
<p id="step-status"></p><p class="legend">Red: followed bead and recorded trail. Under ONE the other four are grey; ALL shows their colours. Amber dashed: proposed movement when shown. The box is a coordinate projection; dimensions are in metres.</p>
<noscript>Download the captured histories below to read all positions and proposals.</noscript></section>'''
script='''<script>
const histories=__DATA__;
const $=id=>document.getElementById(id),ns='http://www.w3.org/2000/svg';
const names=['x','y','z'],colours=['#b23756','#177b86','#3d51a3','#76519e','#ad6c16'];
const dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0),sub=(a,b)=>a.map((v,i)=>v-b[i]);
function attempted(h,n){return h.frames[n-1][0].map((v,i)=>v+h.proposed_steps_walker_0[n-1][i]);}
function reflected(h,n){return n>0&&Math.hypot(...sub(attempted(h,n),h.frames[n][0]))>1e-6;}
function render(){
 const h=histories[$('mode').value],n=Number($('time').value),axes=$('projection').value.split(',').map(Number),full=$('full').checked,one=$('follow').value==='one';
 const [a,b]=axes,bounds=i=>i===1?[-.05,.45]:[-.30,.30],box=i=>i===1?[0,.4]:[-.25,.25],ar=bounds(a),br=bounds(b);
 const x=v=>54+(v-ar[0])/(ar[1]-ar[0])*544,y=v=>450-(v-br[0])/(br[1]-br[0])*400,point=p=>[x(p[a]),y(p[b])];
 const svg=$('walk-plot');svg.replaceChildren();
 function add(tag,attrs,text){const el=document.createElementNS(ns,tag);for(const [k,v]of Object.entries(attrs))el.setAttribute(k,v);if(text!==undefined)el.textContent=text;svg.append(el);return el;}
 add('title',{},`${h.mode.toUpperCase()}, seed ${h.seed}, step ${n}; ${names[a]} / ${names[b]} projection`);
 add('rect',{x:0,y:0,width:640,height:500,fill:'#fcfaf5'});
 const ba=box(a),bb=box(b);add('rect',{x:x(ba[0]),y:y(bb[1]),width:x(ba[1])-x(ba[0]),height:y(bb[0])-y(bb[1]),fill:'#edf1ec',stroke:'#879990','stroke-width':1.5});
 for(const v of [ba[0],(ba[0]+ba[1])/2,ba[1]]){add('line',{x1:x(v),y1:50,x2:x(v),y2:450,stroke:'#d5dcd5','stroke-dasharray':'3 5'});add('text',{x:x(v),y:474,'text-anchor':'middle',fill:'#4b5654','font-size':13},v.toFixed(2));}
 for(const v of [bb[0],(bb[0]+bb[1])/2,bb[1]]){add('line',{x1:54,y1:y(v),x2:598,y2:y(v),stroke:'#d5dcd5','stroke-dasharray':'3 5'});add('text',{x:47,y:y(v)+4,'text-anchor':'end',fill:'#4b5654','font-size':13},v.toFixed(2));}
 add('text',{x:598,y:492,'text-anchor':'end','font-size':14,fill:'#303c37'},names[a]+' · m');add('text',{x:54,y:28,'font-size':14,fill:'#303c37'},names[b]+' · m');
 const start=full?0:Math.max(0,n-200),end=full?n+1:n;
 // Full capture is explicitly a different record and includes the current point.
 for(const i of [4,3,2,1,0]){
  const c=one&&i!==0?'#84928e':colours[i],op=one&&i!==0?.26:.9;
  const pts=h.frames.slice(start,end).map(f=>point(f[i]));
  if(pts.length>1)add('polyline',{points:pts.map(p=>p.join(',')).join(' '),fill:'none',stroke:c,'stroke-width':i===0?2.2:1.5,opacity:op,'data-trail':i});
  const p=point(h.frames[n][i]);add('circle',{cx:p[0],cy:p[1],r:i===0?6:3.5,fill:c,opacity:one&&i!==0?.5:1,'data-walker':i});
 }
 const last=n?point(h.frames[n-1][0]):null;
 if(last&&!full)add('circle',{cx:last[0],cy:last[1],r:3.8,fill:'#fcfaf5',stroke:'#b23756','stroke-width':1.4});
 if(n&&$('proposal').checked){const to=point(attempted(h,n));add('line',{x1:last[0],y1:last[1],x2:to[0],y2:to[1],stroke:'#9c6709','stroke-width':2,'stroke-dasharray':'5 3'});add('circle',{cx:to[0],cy:to[1],r:4.5,fill:'#fcfaf5',stroke:'#9c6709','stroke-width':2,'data-proposed':'true'});}
 $('step-output').textContent=n;$('previous').disabled=n===0;$('next').disabled=n===300;
 const hasReflection=h.proposed_steps_walker_0.some((_,i)=>reflected(h,i+1));$('reflection').disabled=!hasReflection;$('reflection').textContent=hasReflection?'Next reflected step':'No reflected step in this capture';
 $('walk-status').textContent=`Seed ${h.seed} · step ${n} of 300 · five walkers. `+(n===0?'At release; the stored trail is empty.':full?`Full capture: positions 0–${n}, including the bead's current position.`:`Stored trail: positions ${start}–${n-1} (${n-start} kept). Current bead: position ${n}.`);
 $('step-status').textContent=n?`Last proposal: ${(Math.hypot(...h.proposed_steps_walker_0[n-1])*1000).toFixed(2)} mm. Accepted endpoint displacement: ${(Math.hypot(...sub(h.frames[n][0],h.frames[n-1][0]))*1000).toFixed(2)} mm. ${reflected(h,n)?'A wall folded this endpoint; change projection if the difference is hidden.':'This endpoint needed no reflection.'}`:'The next proposal begins at the release point.';
 svg.setAttribute('aria-label',`${h.mode.toUpperCase()} in ${names[a]}/${names[b]}, step ${n}; ${full?'complete captured history':'up to 200 previous positions'} and five current beads.`);
}
for(const id of ['mode','projection','follow','full','proposal'])$(id).addEventListener('change',render);
$('time').addEventListener('input',render);
$('previous').addEventListener('click',()=>{$('time').value=Number($('time').value)-1;render();});
$('next').addEventListener('click',()=>{$('time').value=Number($('time').value)+1;render();});
$('reset').addEventListener('click',()=>{$('time').value=0;render();});
$('reflection').addEventListener('click',()=>{const h=histories[$('mode').value],n=Number($('time').value);for(let i=1;i<=300;i++){const k=(n+i-1)%300+1;if(reflected(h,k)){$('time').value=k;$('proposal').checked=true;render();return;}}$('step-status').textContent='No reflection in this captured history.';});
render();
</script>'''.replace('__DATA__',json.dumps(histories,separators=(',',':')))
style=(OUT/'synthesis-lab.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+='''.mode-images{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}.mode-images figure{margin:8px 0}.mode-images img{width:100%;margin:0}.mode-images figcaption{font-size:13px;line-height:1.4}.walk-view{background:#fbf8f0;border:1px solid #c2bbaa;padding:24px;border-radius:8px}.controls{display:flex;align-items:center;gap:10px;flex-wrap:wrap}.controls label,.option,.timeline{font-size:15px}button,select{font:inherit;font-size:14px;padding:10px;border:1px solid #716658;border-radius:4px;background:white;color:#242a2c}button{cursor:pointer}button:disabled{opacity:.4;cursor:default}button:focus-visible,input:focus-visible,select:focus-visible{outline:3px solid #743653;outline-offset:3px}#walk-plot{width:100%;max-height:560px;display:block;margin:16px auto}.timeline{display:flex;align-items:center;gap:12px;margin-top:16px}.timeline input{flex:1;min-width:30px;accent-color:#b23756}.timeline output{min-width:3ch;font-family:monospace}.option{display:block;margin:10px 0}.option input{accent-color:#b23756}.legend,#step-status,#walk-status{font-size:14px}h1{font-size:clamp(32px,5vw,46px)}@media(max-width:550px){body{padding:0 14px}.walk-view{padding:12px}.mode-images{grid-template-columns:1fr}.controls{gap:8px}.controls button,.controls select{font-size:12px;padding:8px}}'''
final=(ROOT/'commons/maps/Random_Walk/final.md').read_text(encoding='utf-8')
save('random-walk.md',text.replace('<!-- mode-images -->','\n'.join(f'![{key.upper()}, 300 steps](random-walk-{key}.png)' for key in ['2d','3d','levy'])).replace('<!-- walk-view -->','[Explore captured positions and proposals](random-walk.html).')+'\n## Book passage\n\n'+final)
body=markdown.markdown(text,extensions=['fenced_code','tables']).replace('<!-- mode-images -->',images).replace('<!-- walk-view -->',view)
body+='<details><summary>Read the book passage</summary>'+markdown.markdown(final,extensions=['fenced_code'])+'</details>'
save('random-walk.html','<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The trail is already elsewhere · Ada Research</title><style>'+style+'</style></head><body><main>'+body+'</main>'+script+'</body></html>\n')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode('utf-8'))
(REC/'publication-hashes.json').write_bytes((json.dumps({n:hashlib.sha256((OUT/n).read_bytes()).hexdigest() for n in manifest},indent=2)+'\n').encode('utf-8'))
print(json.dumps({'files':len(manifest),'checks':run['checks'],'histories':len(histories)}))
