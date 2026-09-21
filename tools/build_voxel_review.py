from pathlib import Path
import json,re,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/voxel-review-2026-09-13';RUN=R/'ada_run/voxel-review-2026-09-13';H=RUN/'Noise_Voxel'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and not run['failures']
d=json.loads((H/'probe_voxel_live.json').read_text())['measurements'];manifest=[]
def save(n,s):(O/n).write_bytes(s.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
for n in ['bench','readout','volume','screen','screen-data','cut','orb','plan']:copy(H/(n+'.png'),'noise-voxel-'+n+'.png')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Noise_Voxel/{n}.md','noise-voxel-'+n+'.md')
copy(H/'probe_voxel_live.json','noise-voxel-evidence.json');copy(RUN/'run.json','noise-voxel-run.json')
t='''# The line that decides

[Noise One](noise-one.html) → **Noise Voxel** → [Noise 6 Wall](/necklace/thread?map=Noise_6_Wall&role=primary)

[Four primary works and book passages](/necklace/thread?map=Noise_Voxel&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_Voxel)

The green body loses a block. The field value on the plate stays still. **What changed was the line it had to exceed.** This hall follows that difference through a model, a live section and a large volume. The familiar dark orb keeps another operation in the room.

![The retained lattice model on its plinth, with the large matching volume beside it](noise-voxel-bench.png)

## Keep the field; move the line

THRESHOLD changes the decision at every cell. CELL selects another address and horizontal screen layer. SEED changes the field. CUT opens the model's view while preserving its occupied cells. Four controls let superficially similar changes have different causes.

The cased readout names the field, vertical bias, threshold and decision. At the selected cell, a value of about +0.0023 receives help from the negative height bias: the comparison uses about +0.0784. At threshold zero that cell is occupied.

![The actual cased readout after selecting cell 6,8,17](noise-voxel-readout.png)

## Try the recorded comparison

These are **five configurations captured from Godot**, using the same seed, 31415, and all 13,824 cells. The two images below show layer y12 of the 24-layer volume. Change the threshold and compare the coloured scores with the binary decisions. The web viewer reads these recorded samples; it does not run the VR scene.

<!-- viewer -->

There are fewer occupied cells at every higher threshold. Separate pieces have another rhythm: **4 → 15 → 25 → 21 → 32**. A thin connection can break; an entire fragment can also disappear. That counter measures face-connected components of the occupied set. It does not measure routes, cavities or entropy.

## A section with a source

![The existing science screen now compares a real horizontal field section with its stored occupancy mask](noise-voxel-screen.png)

The screen is retained and connected to the actual hall source. Its left image displays field minus height bias; its right image reads the stored occupied/empty answers. CELL changes the layer, and yellow frames identify the same coordinate. The photograph shows layer y8, selected during the review, while the recorded comparison above uses y12.

An empty square still has a value. A missing source is reported as unavailable. We can inspect a loss without filling it with a plausible invented field.

## The same decisions, another size

![The existing voxel body in a bounded full-size frame](noise-voxel-volume.png)

The volume previously exceeded the hall. It now occupies a 4.8-metre cube domain inside a low 5.2-metre frame. Its 24³ cells sample the same positions as the model, at five times the physical spacing: 20 cm instead of 4 cm. The model leaves tiny gaps around its cubes; the volume joins occupied neighbours and builds the exposed boundary, including cavity walls. The same triangles provide collision.

The source had a quieter mismatch too: the receiver accepted Perlin settings, then reset to Simplex when rebuilding. That is repaired. Every sampled value and every occupancy decision now agrees across both works at all five threshold settings.

![CUT conceals part of the small model, while occupancy and the large volume remain unchanged](noise-voxel-cut.png)

The collision boundary gives a body something to meet. It does not establish that an opening admits the player's shoulders or that a ledge can be reached. A connected component and a traversable route remain different questions.

## Another use for a changing value

![The retained dark orb, whose sine-driven material and rotation remain independent](noise-voxel-orb.png)

The orb has its own sine-driven emission and rotation. It stays in the book because a varying value can acquire a body through several operations. The threshold adds a capability to what we already know; the orb keeps an earlier capability available for comparison.

## What remains, and what was checked

![Overhead view after the control tests, showing the complete retained room and staged works](noise-voxel-plan.png)

All four authored artifacts remain. The recovered walls, raised cells, openings and utilities are unchanged. The bench and screen gain clear approaches; the large volume has a bounded stage. Earlier versions of every room text and relevant source are preserved in the dated review archive. The overhead photograph follows the SEED test and shows a different realization from the close-ups.

**61 checks passed in the rendered museum.** All four buttons respond through the project's actual desktop pointer rig using synthetic mouse events. Tests compare every scalar and occupancy decision, the live slice, exposed mesh faces, matching colliders, sampled roof contacts, empty-volume cleanup and cross-hall control isolation. CUT changes only the model view. The museum reports a connected surrounding route.

Headset reach, comfort, traversal through the volume and Quest performance remain for later. Rebuilding still has a synchronous frame cost; the desktop measurements do not certify headset frame rate.

<!-- book -->

[Download the chapter](noise-voxel-final.md) · [Technical account](noise-voxel-technical.md) · [Critical account](noise-voxel-critical.md) · [Captured evidence](noise-voxel-evidence.json) · [Run receipt](noise-voxel-run.json)
'''
save('noise-voxel.md',t)
body=markdown.markdown(t,extensions=['fenced_code','tables'])
viewer='''<section class="lab" aria-label="Recorded threshold comparison"><div class="eyebrow">ONE FIELD / FIVE THRESHOLDS / TWO READINGS</div><div class="controls"><label>Threshold<select id="threshold"><option value="0">−0.20</option><option value="1">−0.10</option><option value="2" selected>0.00</option><option value="3">+0.10</option><option value="4">+0.20</option></select></label><button id="next">Next coordinate</button><button id="reset">Starting coordinate</button></div><p id="counts" aria-live="polite"></p><svg id="slices" viewBox="0 0 960 460" role="img" aria-label="Biased field values beside stored occupied and empty cells"></svg><p id="reading" aria-live="polite"></p><p class="small">Purple to teal: field minus height bias, fixed colour scale −1 to +1. Mint / dark: occupied / empty. Yellow: the same address in both images. Images show one layer; the counters above describe the entire volume.</p></section>'''
body=body.replace('<!-- viewer -->',viewer).replace('<!-- book -->','<details><summary>Read the book passages</summary>'+markdown.markdown((R/'commons/maps/Noise_Voxel/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</details>')
css=re.search(r'<style>(.*?)</style>',(O/'random-noise-types.html').read_text(encoding='utf-8'),re.S)[1]
css+='button{background:#203237;color:#ecf0da;border:1px solid #789d9e;border-radius:7px;padding:10px 15px;font:inherit;cursor:pointer;align-self:end}#reading{min-height:3em}#counts{font-size:19px;color:#e8c78c}.controls{align-items:end}svg{max-width:100%;display:block}pre{overflow-x:auto}'
payload=[{'threshold':x['threshold'],'counts':x['occupancy'],'slice':x['slice']} for x in d['cases']]
js='''const cases=__DATA__;const sel=document.querySelector('#threshold');let cell=12+12*24;
function color(v){const a=[114,79,150],b=[111,226,203],t=Math.max(0,Math.min(1,(v+1)/2));return 'rgb('+a.map((n,i)=>Math.round(n+(b[i]-n)*t)).join(',')+')';}
function draw(){const c=cases[+sel.value],n=c.slice.grid,x=cell%n,z=Math.floor(cell/n),p=c.slice.rows[z][x];let field='',mask='';for(let j=0;j<n;j++)for(let i=0;i<n;i++){const r=c.slice.rows[j][i];field+=`<rect x="${34+i*16}" y="${48+j*16}" width="15" height="15" fill="${color(r.score)}"/>`;mask+=`<rect x="${526+i*16}" y="${48+j*16}" width="15" height="15" fill="${r.occupied?'#9ee1c2':'#071316'}"/>`;}
let out='<text x="34" y="25" fill="#d6e6d8" font-size="20">FIELD − HEIGHT BIAS / y12</text><text x="526" y="25" fill="#d6e6d8" font-size="20">OCCUPIED / EMPTY</text><g id="field-cells">'+field+'</g><g id="mask-cells">'+mask+'</g>';for(const ox of [34,526])out+=`<rect x="${ox+x*16-1}" y="${48+z*16-1}" width="17" height="17" stroke="#ffe082" fill="none" stroke-width="2"/>`;document.querySelector('#slices').innerHTML=out;
document.querySelector('#counts').textContent=`${c.counts.occupied.toLocaleString('en-US')} of 13,824 cells occupied · ${c.counts.pieces} separate pieces · largest ${c.counts.largest_piece.toLocaleString('en-US')}`;
document.querySelector('#reading').textContent=`Cell ${x},12,${z} · field ${p.value.toFixed(4)} · biased score ${p.score.toFixed(4)} > ${c.threshold.toFixed(2)} → ${p.occupied?'OCCUPIED':'EMPTY'}`;}
sel.onchange=draw;document.querySelector('#next').onclick=()=>{cell=(cell+1)%576;draw()};document.querySelector('#reset').onclick=()=>{cell=300;draw()};draw();'''.replace('__DATA__',json.dumps(payload,separators=(',',':')))
save('noise-voxel.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The line that decides · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE VOXEL</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode())
print('Built',len(manifest),'review assets')
