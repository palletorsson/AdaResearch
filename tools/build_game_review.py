"""Publish the Random Game review using captured engine records."""
from pathlib import Path
import json,shutil,markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';REC=R/'doc/space/game-review-2026-09-12';RUN=R/'ada_run/game-review-2026-09-12';H=RUN/'Random_Game'
run=json.loads((RUN/'run.json').read_text());assert run['exit']==0 and not run['failures']
data=json.loads((H/'encounters.json').read_text());manifest=[]
def save(n,t):(O/n).write_text(t,encoding='utf-8');manifest.append(n)
def copy(p,n):shutil.copyfile(p,O/n);manifest.append(n)
imgs=['probe_game_live','probe_game_approach_live','probe_game_tablet_live','probe_game_row_live','probe_game_stele_live','probe_game_bed_live','probe_game_idol_live','probe_game_plan_live','probe_game_desktop_crossing_live','probe_game_desktop_fallen_live','field-controls','falling-field']
for n in imgs:copy(H/(n+'.png'),'random-game-'+n+'.png')
for n in ['encounters.json','probe_game_live.json']:copy(H/n,'random-game-'+n)
copy(RUN/'run.json','random-game-run.json')
for n in ['final','technical','tutorial','critical']:copy(R/f'commons/maps/Random_Game/{n}.md','random-game-'+n+'.md')
text='''# Told, or finding out

[Random Mushrooms](random-mushrooms.html) → **Random Game** → [Noise Types](random-noise-types.html)

[Two primary encounters and their book passages](/necklace/thread?map=Random_Game&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Random_Game)

Three stones draw how long they will stand. Further into the hall, an emitter draws where cubes begin their flights. The room now carries both as primary encounters. Their relationship gives the book its question: **which decision is already made, and what lets you act on it?**

![The actual crossing from its near lip](random-game-probe_game_live.png)

## First, a pause with a chosen end

Watch the stones. Then turn to their tablet. A current wait has already been sampled, although the next one has not. The ring announces the final 1.2 seconds before movement; the beacon reports movement. CUE removes the rings while leaving the tablet available.

The review below steps through recorded transitions from the actual engine. The coloured blocks are a state account, not collision geometry or a new game simulation. A wait shown during LEAVES or RETURNS is the preceding drawn pause.

<!-- trace -->

![The crossing's state tablet](random-game-probe_game_tablet_live.png)

REPLAY now cancels old movement, restores standing positions and support, then repeats the first waits. All three stones retain movement beacons. The longer threshold reaches its landing before the player's capsule meets the first stone. A deliberate fall and the west recovery ramp are checked separately from the approach.

## Then, a source that can stop

![The local controls on their plinth](random-game-field-controls.png)

RUN / STOP changes emission. CLEAR removes existing flights. Stopping first and clearing second leaves an empty field. Clearing a running field allows new arrivals to follow.

The timer attempts a launch every half-second, with at most 24 active bodies. It draws initial centres within the marked 8×8 region and initial downward speed between 1.6 and 2.6 m/s. The rectangle marks starts, not containment. Bodies can drift beyond it.

<!-- field -->

The two sets above come from 24 synchronous calls per set to the actual spawner at seed 31415; they exercise initial construction and the cap. A separate real-timer check verifies arrivals through the local RUN button. The positions and velocities repeat exactly. Each projectile's later jitter generator is randomized independently, so the initial repeat is not a claim about matching full trajectories.

![The falling field and its marked initial-position region](random-game-falling-field.png)

## What this pass establishes

**__CHECKS__ desktop checks passed, with zero assertion failures and engine exit 0.** The review uses the actual museum and a project desktop rig for pointer input, walking and falling. That rig is a test lane; the museum's default walker and a tracked headset are separate interfaces.

The first pass found a blocked threshold, a frame of stale crown light, missed field button rays and early configuration of an unbound Timer. Those failures are retained, along with the later control-position investigation. The final source and run fingerprints are recorded. Existing engine startup diagnostics remain listed in the handover.

Nine artifacts are named in the map; the live museum omits `monte_carlo` because it has no living scene in this lane. Its extra mode implementations are also unfinished. It stays a recorded secondary candidate. The six creatures remain; their ability to interfere with the two experiments still needs a controlled activation/separation pass. No combat balance, headset comfort or Quest performance result is claimed.

<!-- book -->

[Download the chapter](random-game-final.md) · [Technical account](random-game-technical.md) · [Critical account](random-game-critical.md) · [Captured evidence](random-game-encounters.json) · [Run receipt](random-game-run.json)
'''.replace('__CHECKS__',str(run['checks']))
save('random-game.md',text)
body=markdown.markdown(text,extensions=['fenced_code','tables'])
trace='''<section class="lab"><div class="eyebrow">01 / STORED TRANSITIONS</div><label for="event">Recorded event <output id="event-number"></output></label><input id="event" type="range" min="0" value="2"><div id="stones" class="stones"></div><p id="event-detail" aria-live="polite"></p><p class="small">Frame-observed transitions from three independent streams. The slider selects events; it does not run the museum clock.</p></section>'''
field='''<section class="lab"><div class="eyebrow">02 / INITIAL CONDITIONS</div><div class="controls"><label for="take">Captured set <select id="take"><option value="0">First 24 launches</option><option value="1">Repeat seed 31415</option></select></label><label for="launch">Inspect launch <select id="launch"></select></label></div><svg id="scatter" viewBox="0 0 540 420" role="img" aria-label="Captured initial positions in an eight metre square"></svg><p id="launch-detail" aria-live="polite"></p><p class="small">Coordinates are metres relative to the field origin. Height is +8 m. Circles mark centres, not cube footprints or landing positions. Lines connect each centre to one second of its initial lateral velocity, magnified ×4 for inspection; later jitter is omitted.</p></section>'''
book='<details><summary>Read the book passages</summary><div class="book">'+markdown.markdown((R/'commons/maps/Random_Game/final.md').read_text(encoding='utf-8'),extensions=['fenced_code'])+'</div></details>'
body=body.replace('<!-- trace -->',trace).replace('<!-- field -->',field).replace('<!-- book -->',book)
css='''*{box-sizing:border-box}body{margin:0;background:#10191c;color:#e7e9df;font:18px/1.65 Georgia,serif}main{max-width:1080px;margin:auto;padding:64px 30px 100px}h1{font-size:clamp(42px,7vw,80px);line-height:1.06;letter-spacing:-.045em;margin:16px 0 30px;font-weight:normal}h2{font-size:30px;line-height:1.25;margin:62px 0 22px;font-weight:normal}a{color:#8ee0d4;text-underline-offset:4px}p{max-width:850px}img{display:block;width:100%;border:1px solid #344346;border-radius:8px;margin:28px 0}pre{background:#071113;padding:22px;overflow:auto;font-size:14px}code{font-size:.85em}.lab{background:#1a272c;border:1px solid #486063;border-radius:14px;padding:28px;margin:35px 0;font:16px/1.5 system-ui}.eyebrow{color:#e8b970;letter-spacing:.14em;font-size:12px;margin-bottom:22px}.controls{display:flex;gap:25px;flex-wrap:wrap}label{display:block}select{display:block;background:#10191c;border:1px solid #718989;color:#eef4e8;padding:10px;font:inherit;border-radius:6px;margin-top:7px}input[type=range]{width:100%;margin:20px 0;accent-color:#efd07a}.stones{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}.stone{border-top:7px solid var(--c);background:#10191c;padding:20px;border-radius:5px}.stone strong{display:block;color:var(--c);font-size:21px}.small{font:14px/1.6 system-ui;color:#acc0c1}svg{display:block;width:min(100%,700px);margin:15px auto}summary{cursor:pointer;color:#e9c47c;font:23px/1.4 system-ui;padding:24px 0}.book{border-left:2px solid #697b72;padding-left:28px}details{margin-top:60px;border-top:1px solid #486063}output{color:#f0ca7a}@media(max-width:600px){main{padding:28px 18px}body{font-size:17px}.lab{padding:18px}.stones{gap:5px}.stone{padding:10px;font-size:12px}.stone strong{font-size:15px}.book{padding-left:12px}}'''
js='''const D=__DATA__, E=document.querySelector('#event'), T=D.crossing.trace;E.max=T.length-1;
const colours={STANDS:'#75d9d1',LEAVES:'#f6a266',GONE:'#8b94a3',RETURNS:'#b8de83'};
function trace(){const n=Number(E.value), states=[null,null,null];for(let i=0;i<=n;i++)states[T[i].stone-1]=T[i];document.querySelector('#event-number').textContent=`${n+1} / ${T.length}`;document.querySelector('#stones').innerHTML=states.map((s,i)=>`<div class="stone" style="--c:${colours[s?.state]||'#abc'}">Stone ${i+1}<strong>${s?.state||'Awaiting record'}</strong>${s?`Last draw ${s.wait.toFixed(3)} s<br>Collider ${s.supports?'enabled':'disabled'}`:''}</div>`).join('');const r=T[n];document.querySelector('#event-detail').textContent=`${r.t.toFixed(3)} s into capture · stone ${r.stone} entered ${r.state}. Seed ${D.crossing.seed}.`;}E.addEventListener('input',trace);trace();
const take=document.querySelector('#take'), launch=document.querySelector('#launch');launch.innerHTML=Array.from({length:24},(_,i)=>`<option value="${i}">${i+1}</option>`).join('');
function plot(){const offset=Number(take.value)*24,selected=Number(launch.value),rs=D.field.records.slice(offset,offset+24),svg=document.querySelector('#scatter');let s='<rect x="110" y="35" width="320" height="320" fill="#10191c" stroke="#e9bb6d" stroke-width="2"/>';for(let k=-4;k<=4;k++){let q=270+k*40,z=195+k*40;s+=`<path d="M${q} 35V355 M110 ${z}H430" stroke="#35464b"/><text x="${q}" y="379" fill="#b6c8ca" text-anchor="middle" font-size="12">${k}</text>`;}s+='<text x="270" y="405" fill="#caddde" text-anchor="middle" font-size="13">x metres →</text><text x="77" y="35" fill="#caddde" font-size="12">z −4</text><text x="77" y="355" fill="#caddde" font-size="12">+4</text>';rs.forEach((r,i)=>{const x=270+r.x*40,z=195+r.z*40;s+=`<path d="M${x} ${z}l${r.vx*160} ${r.vz*160}" stroke="#b8de83" stroke-width="2"/><circle data-launch="${i+1}" cx="${x}" cy="${z}" r="${i===selected?8:4}" fill="${i===selected?'#ffd279':'#86d5d2'}" stroke="#10191c"/>`;});svg.innerHTML=s;const r=rs[selected];document.querySelector('#launch-detail').textContent=`Launch ${selected+1} · x ${r.x.toFixed(4)}, z ${r.z.toFixed(4)}, y ${r.y.toFixed(1)} m. Initial velocity (${r.vx.toFixed(4)}, ${r.vy.toFixed(4)}, ${r.vz.toFixed(4)}) m/s. Both captured sets have identical initial values; their later jitter states differ.`;}take.addEventListener('change',plot);launch.addEventListener('change',plot);plot();'''.replace('__DATA__',json.dumps(data).replace('</','<\/'))
save('random-game.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Told, or finding out · Ada Research</title><style>'+css+'</style><main><div class="eyebrow">ADA RESEARCH / POSSIBLE BODIES / RANDOM GAME</div>'+body+'</main><script>'+js+'</script></html>')
(REC/'publication-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Built game review with {len(manifest)} assets')
