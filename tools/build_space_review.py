"""Build the Noise Space 10 review from the accepted Godot recordings."""
from pathlib import Path
import json,re,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/space-review-2026-09-13';RUN=R/'ada_run/space-review-2026-09-13';H=RUN/'Noise_Space_10'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and run['checks']==36 and not run['failures']
d=json.loads((H/'probe_space_live.json').read_text())['measurements'];manifest=[];prefix='noise-space-ten-'
def save(n,s):(O/n).write_bytes(s.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
for n in ['height_0','height_1','height_2','height_3','standing','instrument','orb','plan']:copy(H/(n+'.png'),prefix+n+'.png')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Noise_Space_10/{n}.md',prefix+n+'.md')
copy(H/'probe_space_live.json',prefix+'evidence.json');copy(RUN/'run.json',prefix+'run.json')
t='''# Which way will carry you?

[Inside Noise](noise-inside-noise.html) → **Noise Space 10** → [Noise Perlin Simplex](/necklace/thread?map=Noise_Perlin_Simplex&role=primary)

[Two primary works and their book passages](/necklace/thread?map=Noise_Space_10&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_Space_10)

Two pairs of pale posts face each other across the ground. A gold line joins them. Before entering, follow it with your eyes. **Where would you expect your pace to change?**

![A view from the near margin, with the proposed gold route crossing the noise terrain towards the far posts](noise-space-ten-standing.png)

The previous sphere surrounded us with a field while the floor stayed still. Here a value reaches the ground itself. The same field can carry the body differently when we change how much height it receives.

## Keep the field. Raise its contribution.

Choose a height scale below. The four images were rendered from the same camera in Godot. The seed, generator and routes stay fixed. At zero the ground is level; the field still has values, but its contribution to height is zero.

<!-- comparison -->

The section follows the actual mesh triangles, with 101 points spaced evenly along the route in plan. Its steepest sampled segment helps us investigate a crossing. A line has no width; a moving body meets neighbouring slopes too.

```gdscript
func ground_at(p: Vector2) -> float:
    var value: float = noise.get_noise_2d(p.x * noise_scale, p.y * noise_scale)
    return 1.0 + height_scale * edge_weight(p) * value
```

HEIGHT selects 0, 0.25, 0.65 or 0.90. OpenSimplex2S, seed zero, four fBM octaves, gain 0.5, lacunarity 2, frequency 0.1 and the coordinate multiplier five stay fixed. This gives the change a specific place to enter.

## Let the body answer

In two recorded desktop attempts, the same forward input starts from the near margin:

| Height scale | Route A section | Steepest sampled segment | Recorded attempt |
| --- | --- | --- | --- |
| 0.25 | 8.13 m | 24.18° | Crosses to the far margin |
| 0.90 | 9.45 m | 58.26° | Stops partway across, still supported |

The tested capsule is 1.8 m tall and 0.6 m across, with a 45° floor-angle limit. The stalled attempt belongs to that body, input and setting. Other ways through remain to be tried. Route B is a longer proposal, and its steepest sampled segment is slightly steeper here; a detour has not automatically become an easier way.

## A place from which to change the question

![The supported instrument with its tilted section display and local controls, beside the terrain](noise-space-ten-instrument.png)

The eight-metre patch meets a dark margin at one metre above the museum floor. The last 0.75 m of terrain gradually withholds the noise contribution so the edge stays level. The border is authored. It gives us a steady place to return to while comparing what changed.

**HEIGHT** changes the terrain. **ROUTE** switches the proposed line. **SAMPLE** follows one of five witnesses on the ground and section. **RESET** returns to height 0.25, route A and the first witness. The displayed ground and its collider rebuild together. HEIGHT and RESET wait while a player is on the patch.

The instrument's values come from the triangles actually underfoot. There are 81 × 81 vertices, ten centimetres apart. Querying the noise again between vertices can give a different height from interpolating the constructed surface. That small difference keeps the representation visible inside the result.

## What else could this crease permit?

A place that stops one body might hide another. Shelter would need another encounter: a body, an observer, a line of sight. Walking has opened the question without exhausting it.

Try to find an overhang. This heightfield gives each horizontal position one height. A cave needs room for both a floor and a roof at some of the same positions. The occupied volume of Noise Voxel remains available when this representation reaches its limit.

## Keep another time in the room

![The original dark orb on the raised east platform](noise-space-ten-orb.png)

The dark orb remains a second primary work. Its pulse continues while the terrain resets. Returning a multiplier to its starting value does not recover the time spent finding a way across.

## The restored hall

![Overhead view of the terrain and margin within the preserved museum grid](noise-space-ten-plan.png)

Both original artifacts remain. Every original structure cell remains, including the raised platforms. Two ramps connect the margin to the entrance and teleporter approach. The book already included this hall; the active museum had skipped it. It now follows Noise Inside Noise.

**36 rendered checks passed.** All four height states agree with the displayed vertices and collision faces. Physics rays meet the triangle-interpolated heights. The actual desktop pointer operates all four controls, both player groups prevent an occupied rebuild, and a separate unconfigured terrain keeps its original behaviour. The two ramps and museum route pass their checks.

Headset reach, legibility, comfort and Quest performance await the later headset session. The controls on this page inspect recorded Godot states, so the comparison is available remotely.

<!-- book -->

Next: **Noise Perlin Simplex**. Keep the body and question in view while changing the generator.

[Chapter](noise-space-ten-final.md) · [Tutorial](noise-space-ten-tutorial.md) · [Technical account](noise-space-ten-technical.md) · [Critical account](noise-space-ten-critical.md) · [Captured evidence](noise-space-ten-evidence.json) · [Run receipt](noise-space-ten-run.json)
'''
save('noise-space-ten.md',t);body=markdown.markdown(t,extensions=['fenced_code','tables'])
comparison='''<section class="lab" aria-label="Recorded terrain comparison"><div class="eyebrow">ONE FIELD / DIFFERENT HEIGHTS</div><div class="controls"><label>Height scale<select id="height"><option value="0">0 · level</option><option value="1" selected>0.25 · gentle</option><option value="2">0.65</option><option value="3">0.90 · raised</option></select></label><label>Proposed route<select id="route"><option value="0">A · across</option><option value="1">B · detour</option></select></label><button id="sample">Next sample</button></div><figure class="terrain"><img id="terrain-view" src="noise-space-ten-height_1.png" alt="The noise terrain at height scale 0.25"><figcaption id="photo-state">Godot photograph · height 0.25 · route A</figcaption></figure><div class="charts"><figure><figcaption>THE PROPOSAL IN PLAN</figcaption><svg id="plan-view" viewBox="0 0 260 270" role="img" aria-label="Selected route in plan"><rect x="25" y="15" width="210" height="210" fill="#172f30" stroke="#789d9e"/><path id="plan-path" fill="none" stroke="#e8bd6f" stroke-width="2"/><circle id="plan-witness" r="5" fill="#ffe68b"/><text x="130" y="250" text-anchor="middle">8 m square · x / z</text></svg></figure><figure><figcaption id="profile-caption">GROUND HEIGHT / PLANAR DISTANCE</figcaption><svg id="profile-view" viewBox="0 0 640 280" role="img" aria-label="Actual triangle-interpolated route profile"><path d="M50 20V240H620M50 130H620" fill="none" stroke="#789d9e" stroke-width="1"/><text x="39" y="28" text-anchor="end">2 m</text><text x="39" y="136" text-anchor="end">1 m</text><text x="39" y="240" text-anchor="end">0 m</text><text x="50" y="265">0</text><text id="plan-length" x="620" y="265" text-anchor="end"></text><path id="profile-path" fill="none" stroke="#e8bd6f" stroke-width="2.5"/><circle id="profile-witness" r="6" fill="#ffe68b" stroke="#152427" stroke-width="2"/></svg></figure></div><div id="sample-state" aria-live="polite"></div><p class="small">The photograph always shows route A. The diagrams and readings follow the selected route. Both routes are proposals; their sections do not certify a crossing. Height uses one fixed vertical scale; each route fills the horizontal chart, whose endpoint gives its planar length.</p></section>'''
body=body.replace('<!-- comparison -->',comparison).replace('<!-- book -->','<details><summary>Read the book passages</summary><div class="book">'+markdown.markdown((R/'commons/maps/Noise_Space_10/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</div></details>')
css=re.search(r'<style>(.*?)</style>',(O/'random-noise-types.html').read_text(encoding='utf-8'),re.S)[1]
css+='button{background:#203237;color:#ecf0da;border:1px solid #789d9e;border-radius:7px;padding:10px 15px;font:inherit;cursor:pointer;align-self:center}.controls{align-items:center;flex-wrap:wrap}.terrain{margin:24px 0}.terrain img{aspect-ratio:16/9;object-fit:cover}.terrain figcaption{font:13px/1.5 ui-monospace,monospace;color:#b7cbca}.charts{display:grid;grid-template-columns:1fr 2.4fr;gap:20px;align-items:center}.charts figure{margin:0;min-width:0}.charts figcaption{font:11px/1.5 ui-monospace,monospace;letter-spacing:.06em}.charts svg{width:100%;margin:15px 0}.charts text{fill:#bcd2cf;font:12px ui-monospace,monospace}#sample-state{font:15px/1.65 ui-monospace,monospace;color:#ffe68b;overflow-wrap:anywhere}#sample-state p{margin:6px 0}@media(max-width:650px){.charts{grid-template-columns:1fr}.charts figure:first-child{max-width:240px;margin:auto}.charts text{font-size:15px}#sample-state{font-size:13px}.lab{padding:18px}}'
js='''const cases=__DATA__;let sample=0;const h=document.querySelector('#height'),route=document.querySelector('#route');const el=s=>document.querySelector(s);const circle=(id,x,y)=>{el(id).setAttribute('cx',x);el(id).setAttribute('cy',y);};const xy=p=>[25+(p[0]+4)/8*210,15+(4-p[2])/8*210];const path=points=>points.map((p,i)=>(i?'L':'M')+p.map(n=>n.toFixed(3)).join(',')).join(' ');function draw(){const i=+h.value,c=cases[i],r=c.routes[+route.value],w=r.witnesses[sample];el('#terrain-view').src='noise-space-ten-height_'+i+'.png';el('#terrain-view').alt='The noise terrain at height scale '+c.scale.toFixed(2);el('#photo-state').textContent='Godot photograph · height '+c.scale.toFixed(2)+' · route A';const points=r.profile.map((p,j)=>[50+j/100*570,240-p[1]*110]);el('#profile-path').setAttribute('d',path(points));circle('#profile-witness',...points[sample*25]);el('#plan-path').setAttribute('d',path(r.profile.map(xy)));circle('#plan-witness',...xy(w.position));let planar=0;for(let j=1;j<r.profile.length;j++)planar+=Math.hypot(r.profile[j][0]-r.profile[j-1][0],r.profile[j][2]-r.profile[j-1][2]);el('#plan-length').textContent=planar.toFixed(2)+' m in plan';const vec=v=>'('+v.map(n=>n.toFixed(3)).join(', ')+')';el('#sample-state').replaceChildren(...['Height '+c.scale.toFixed(2)+' · route '+(+route.value?'B':'A')+' · sample '+(sample+1)+'/5','Section '+r.length.toFixed(3)+' m · steepest sampled segment '+r.max_grade.toFixed(2)+'°','x / y / z '+vec(w.position)+' m','Field '+w.raw.toFixed(4)+' · edge weight '+w.edge_weight.toFixed(3),'Triangle height '+w.mesh_height.toFixed(4)+' m · analytical height '+w.analytic_height.toFixed(4)+' m'].map(s=>{const p=document.createElement('p');p.textContent=s;return p;}));}h.onchange=draw;route.onchange=draw;el('#sample').onclick=()=>{sample=(sample+1)%5;draw();};draw();'''.replace('__DATA__',json.dumps(d['cases'],separators=(',',':')))
save('noise-space-ten.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Which way will carry you? · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE SPACE 10</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Built',len(manifest),'review assets')
