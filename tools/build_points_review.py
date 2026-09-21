"""Build the illustrated Noise Types review from an accepted real-engine run."""
from pathlib import Path
import json,shutil,markdown,re
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/noise-galleries-2026-09-13';RUN=R/'ada_run/points-review-2026-09-13';H=RUN/'Random_Noise_Types'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and not run['failures']
d=json.loads((H/'encounters.json').read_text());manifest=[]
def save(n,t):(O/n).write_bytes(t.encode('utf-8'));manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
for n in ['single-boundary','sampling-bench','load-readout','clustered-bench','probe_points_plan_live','probe_points_desktop_carry_live']:
 copy(H/(n+'.png'),'random-noise-types-'+n+'.png')
for n in ['encounters.json','probe_points_live.json']:copy(H/n,'random-noise-types-'+n)
copy(RUN/'run.json','random-noise-types-run.json')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Random_Noise_Types/{n}.md','random-noise-types-'+n+'.md')
GRUN=R/'ada_run/noise-galleries-2026-09-13'; GH=GRUN/'Random_Noise_Types'
grun=json.loads((GRUN/'run.json').read_text());assert grun['exit']==0 and not grun['failures']
galleries=json.loads((GH/'galleries.json').read_text())
for token in ['WhiteNoiseGallery','NoiseColors3D']:
 for view in ['gallery','console']:copy(GH/(token+'-'+view+'.png'),'noise-galleries-'+token+'-'+view+'.png')
 for sample in galleries[token]['audio']:copy(GH/sample['file'],'noise-galleries-'+sample['file'])
copy(GH/'galleries.json','noise-galleries-data.json');copy(GRUN/'run.json','noise-galleries-run.json')
a=d['loaded']['admitted']
text=f'''# Which rules keep acting?

[Random Game](random-game.html) → **Noise Types** → [Noise Columns](/necklace/thread?map=Noise_Columns&role=primary)

[Four primary encounters and their book passages](/necklace/thread?map=Random_Noise_Types&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Random_Noise_Types)

The single point keeps returning to its plane. At the sampling bench, a point can enter a neighbourhood its generator would have refused. **The difference becomes visible when somebody moves.** All four existing works now have book passages. The point encounters remain, and the galleries expand the route through height and colour, illustrated spectra and sound.

![The single point's framed local boundary](random-noise-types-single-boundary.png)

## A plane that keeps being made

Carry the point, move it out of the plane, release. Each process frame clips its local x/y into the square and writes zero into z. Dropping does not draw a new position. The frame stands at hand height, clear of the entrance wall, with its own invitation and coordinate label.

## A rule that stops after admission

![The actual sampling bench in the museum](random-noise-types-sampling-bench.png)

Compare the two shallow volumes. REDRAW repeats the construction. NEW SEED changes the arrangement. RULE changes the right-hand generator. LOAD changes the request from 24 to 96 without shrinking the 0.130 m spacing. RESTORE returns the generated positions after you have moved them.

The viewer below uses captured coordinates from the actual Godot artifact at seed 31415. Switch the request or generator, then change your view of the slab. Projected circles can overlap while their centres remain separated in depth; the closest-pair measure uses all three coordinates.

<!-- viewer -->

## A search ending is not a space ending

![The complete candidate count and the bounded ghost display](random-noise-types-load-readout.png)

In the captured 96-point request, the right-hand sampler kept **{a['accepted']}**, refused **{a['refused']}** candidates and left **{a['short']}** requested places unfilled. It tried **{a['attempts']}** candidates. Only the first **{a['ghosts_shown']}** refusals have grey bodies. The totals keep counting when the display stops adding ghosts.

Each requested slot gets at most 100 attempts. Failure within that budget does not establish that no admissible point remains. The earlier wording, “the volume ran out of room,” claimed more than the algorithm knew. The plate now names the actual limit.

RULE's clustered setting makes clamped Gaussian coordinates and applies no pair-distance test. Its close pairs are present from the beginning. The plate says so immediately, including after RESTORE.

![The same bench with the right-hand clustered setting](random-noise-types-clustered-bench.png)

## Move across the rule

The shells turn red when points come closer than the reference spacing minus a one-millimetre tolerance. The observer counts pairs, not coloured points. It does not push them apart. Three coincident centres now correctly count as three close pairs.

That makes a specific continuation of “what bodies are possible?”: **does the condition that produced a body continue to govern what it can become?** The first artifact repeatedly imposes a plane. The second lets us carry an admitted point into a relation its generator would reject.

## Let the other works change the question

The guiding question had left two substantial works outside the book. Their contribution deserves more than a secondary label. This pass keeps all four artifacts, their existing visual fields and the two earlier passages, then adds encounters that take us elsewhere.

![The two existing galleries with human-sized side consoles](noise-galleries-WhiteNoiseGallery-gallery.png)

**WhiteNoiseGallery** ties each of its 10,000 bar heights to a colour through the same draw. Its sound comes from a separate stream. Change what you hear while watching the image stay put. Scanning these heights into sound would be another instrument; it remains an explicit possibility, not an invented feature.

**NoiseColors3D** retains five rows of illustrated spectral shapes, 200 bars in each. Its sound filters accumulate, retain or subtract previous values. The illustrated rows do not measure that audio. The difference gives us something to discover about memory, shared names and what we expect one medium to explain about another.

![The gallery's existing sound choices on their restored console](noise-galleries-NoiseColors3D-console.png)

### Listen to the actual generators

These two-second previews were exported from the existing Godot sample functions. Each starts with the same white-innovation seed, 12345, and reset filter state. They keep the existing gain, so both loudness and temporal structure can differ. The waveform shows the first 512 samples, about 11.6 milliseconds. These are dry source previews, before room attenuation; they are not a recording from a headset.

<!-- sound -->

The first gallery's needles remain needles when the sound changes. The second gallery's five rows remain together. Keeping that visual company allows more than one comparison, or simply time to stay with a texture. The book now makes room for that attention alongside the code.

## What was checked

**{run['checks']} checks passed in the rendered museum, with zero assertion failures and engine exit 0.** Synthetic input used the project's real desktop pointer for the bench controls and both point grabs. Direct coordinate interventions are recorded separately. A headset walk remains to be done; the museum's default walker is also a separate interface from this test rig.

The first pass retained a failed exact live-position replay assertion and an obstructed view of the single-point frame. Returning LOAD repeats the saved generated coordinates exactly. The largest live coordinate difference in this run was {d['returned_max_live_coordinate_drift']:.9f} m after engine transform updates; it is recorded separately from generation. This is a local construction replay, not a replay of the running world.

A separate gallery run passed **{grun['checks']} checks**, including real pointer input for ten sound selections and both STOP controls, unchanged visual fields, source audio export and agreement between the two filter implementations under the same input. The first attempt exposed missed top-row targets; the next exposed a standing position against a recovered platform. The final console positions keep those approaches clear. The original 84-check point run above remains earlier evidence for the unchanged point scripts, rather than a new whole-room acceptance claim.

Headset reach, perceived sound in the room and Quest performance remain unverified. The audio names identify the shipped approximate filters; their plotted model curves are not a claim of exact measured spectral slopes.

<!-- book -->

[Download the chapter](random-noise-types-final.md) · [Technical account](random-noise-types-technical.md) · [Critical account](random-noise-types-critical.md) · [Captured coordinates](random-noise-types-encounters.json) · [Run receipt](random-noise-types-run.json)
'''
save('random-noise-types.md',text)
body=markdown.markdown(text,extensions=['fenced_code','tables'])
viewer='''<section class="lab"><div class="eyebrow">CAPTURED CONSTRUCTIONS / SEED 31415</div><div class="controls"><label for="construction">Construction<select id="construction"><option value="initial">Spaced · request 24</option><option value="loaded">Spaced · request 96</option><option value="clustered">Clustered · request 24</option></select></label><label for="projection">View<select id="projection"><option value="xy">Front · x / y</option><option value="xz">Above · x / z</option></select></label><label class="toggle"><input id="ghosts" type="checkbox" checked> Show refused proposals</label></div><p id="counts" aria-live="polite"></p><svg id="clouds" viewBox="0 0 1000 510" role="img" aria-label="Two captured point clouds with half-distance shells"></svg><p id="measurement"></p><p class="small">Equal metre scales in both views. Circles are projected shells of radius 0.065 m. The cyan line joins the right cloud's closest pair in 3D. Grey marks are the first refusals, capped at 220; they are not all the trials.</p></section>'''
book='<details><summary>Read the book passages</summary><div class="book">'+markdown.markdown((R/'commons/maps/Random_Noise_Types/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</div></details>'
sound='<section class="lab"><div class="eyebrow">DRY GODOT SOURCE / SAME WHITE INNOVATIONS</div><label for="timbre">Sound setting<select id="timbre">'+''.join('<option value="'+str(i)+'">'+a['mode']+'</option>' for i,a in enumerate(galleries['WhiteNoiseGallery']['audio']))+'</select></label><audio id="noise-audio" controls preload="metadata" aria-label="Two-second generated noise preview"></audio><svg id="waveform" viewBox="0 0 1000 260" role="img" aria-label="First 512 source samples"></svg><p id="sound-note" aria-live="polite"></p><p class="small">Fixed vertical scale ±0.95. BROWN retains a bounded accumulation; VIOLET differences consecutive innovations. BLUE uses a high-pass construction; it is not a measured match to the illustrated f curve.</p></section>'
body=body.replace('<!-- viewer -->',viewer).replace('<!-- book -->',book).replace('<!-- sound -->',sound)

css=re.search(r'<style>(.*?)</style>',(O/'random-game.html').read_text(encoding='utf-8'),re.S)[1]
css+='svg{width:100%;max-width:none}.toggle{align-self:center;cursor:pointer}input[type=checkbox]{accent-color:#8fe1d3;width:18px;height:18px;margin-right:8px}#measurement{color:#e8c78c}#counts{min-height:3em}select{max-width:100%}'
js='''const D=__DATA__, S=document.querySelector('#construction'), P=document.querySelector('#projection'), G=document.querySelector('#ghosts');
function draw(){const d=D[S.value], a=d.admitted, ax=P.value==='xy'?1:2, scale=425, oy=270;let svg='';
document.querySelector('#counts').textContent=`Right: ${a.accepted} kept + ${a.short} unfilled = ${d.requested} requested. ${a.attempts} candidates = ${a.accepted} kept + ${a.refused} refused. Showing ${G.checked?a.ghosts_shown:0} refusal marks.`;
for(const [k,ox,c,label] of [['proposed',250,'#edbc77','LEFT · every proposal kept'],['admitted',750,'#84dfd5','RIGHT · '+d.rule]]){
const pts=d.homes[k], h=d.dimensions[ax]*scale,w=d.dimensions[0]*scale, X=v=>ox+v[0]*scale,Y=v=>oy-v[ax]*scale;
svg+=`<text x="${ox}" y="30" text-anchor="middle" fill="${c}" font-size="18">${label}</text><rect x="${ox-w/2}" y="${oy-h/2}" width="${w}" height="${h}" fill="#10191c" stroke="#6f858a"/><text x="${ox}" y="505" text-anchor="middle" fill="#afc5c6" font-size="15">x: −0.45 … +0.45 m · ${ax===1?'y: −0.45 … +0.45':'z: −0.06 … +0.06'} m</text>`;
if(k==='admitted'&&G.checked)for(const v of d.ghost_positions)svg+=`<circle cx="${X(v)}" cy="${Y(v)}" r="2" fill="#c2c4cf" opacity=".65"/>`;
for(const v of pts)svg+=`<circle cx="${X(v)}" cy="${Y(v)}" r="${d.shells*scale}" fill="${c}" fill-opacity=".11" stroke="${c}" stroke-opacity=".32"/><circle cx="${X(v)}" cy="${Y(v)}" r="3" fill="${c}"/>`;
if(k==='admitted'){let best=Infinity,pair;for(let i=0;i<pts.length;i++)for(let j=i+1;j<pts.length;j++){const r=Math.hypot(...pts[i].map((v,n)=>v-pts[j][n]));if(r<best){best=r;pair=[pts[i],pts[j]];}}if(pair)svg+=`<line x1="${X(pair[0])}" y1="${Y(pair[0])}" x2="${X(pair[1])}" y2="${Y(pair[1])}" stroke="#d7faff" stroke-width="3"/>`;document.querySelector('#measurement').textContent=`Right closest pair: ${best.toFixed(6)} m in 3D. ${d.rule==='spaced'?'Admission spacing: '+d.min_dist.toFixed(3)+' m.':'Gaussian applies no spacing test; shells retain the 0.130 m reference.'}`;}}
document.querySelector('#clouds').innerHTML=svg;}
for(const e of [S,P,G])e.addEventListener('change',draw);draw();'''.replace('__DATA__',json.dumps(d,separators=(',',':')).replace('</','<\\/'))
audio_data=galleries['WhiteNoiseGallery']['audio']
js+="""
const A=__AUDIO__, C=document.querySelector('#timbre'), player=document.querySelector('#noise-audio');
function sound(){const a=A[Number(C.value)];player.pause();player.src='noise-galleries-'+a.file;player.load();const poly=a.first.map((v,i)=>`${25+i*950/511},${130-v*110/.95}`).join(' ');document.querySelector('#waveform').innerHTML=`<line x1="25" y1="130" x2="975" y2="130" stroke="#728488"/><polyline points="${poly}" fill="none" stroke="#a9ddd5" stroke-width="1.5"/><text x="25" y="22" fill="#c4d6d4" font-size="17">+0.95</text><text x="25" y="252" fill="#c4d6d4" font-size="17">−0.95 · 0 … 11.6 ms</text>`;document.querySelector('#sound-note').textContent=`${a.mode} · 88,200 samples · 44.1 kHz · RMS ${a.rms.toFixed(4)} · peak ${a.peak.toFixed(4)}. Gain retained; no loudness normalization.`;}C.addEventListener('change',sound);sound();
""".replace('__AUDIO__',json.dumps(audio_data,separators=(',',':')))
css+='audio{display:block;width:100%;margin:24px 0}'
save('random-noise-types.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Which rules keep acting? · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / NOISE TYPES</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode('utf-8'))
print('Built',len(manifest),'review assets')
