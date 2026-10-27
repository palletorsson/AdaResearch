"""Publish the recorded first scout and actual protocol evidence, not a live AI demo."""
import json
from pathlib import Path
import shutil
import re
from model_b import Client

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/model-b-brain-2026-10-26'
SESSION=OUT/'first-session'
PAGE=ROOT/'doc/book/iterations/2026-10-26-model-b-brain'
PAGE.mkdir(parents=True,exist_ok=True)
events=[json.loads(line) for line in (SESSION/'events.jsonl').read_text(encoding='utf-8').splitlines()]
actions={e['after']:e for e in events if e['type']=='action'}
frames=[]
for event in events:
    if event['type']!='observation':continue
    obs=json.loads((SESSION/'observations'/(event['id']+'.json')).read_text(encoding='utf-8'))
    image='images/'+event['id']+'.png'
    (PAGE/'images').mkdir(exist_ok=True)
    shutil.copy2(SESSION/obs['image'],PAGE/image)
    frames.append({'id':obs['id'],'image':image,'body':obs['body'],'memory':obs['memory'],'action':actions.get(obs['id'])})
final=frames[-1]
audit=json.loads((SESSION/'audit'/(final['id']+'.json')).read_text(encoding='utf-8'))
native=json.loads((SESSION/'run-result.json').read_text(encoding='utf-8'))
protocols=[p for p in OUT.glob('protocol-*/checks.json') if json.loads(p.read_text(encoding='utf-8'))['passed']]
assert protocols,'Need a passing native protocol receipt'
protocol_path=max(protocols,key=lambda p:p.stat().st_mtime)
protocol=json.loads(protocol_path.read_text(encoding='utf-8'))
recall=Client(protocol_path.parent).recall('stripes')
assert recall['matching_entries']==1 and recall['entries'][0]['kind']=='hypothesis' and not recall['invalid_records']
assert Client(SESSION).recall('slope')['matching_entries']>=2
presets=(ROOT/'export_presets.cfg').read_text(encoding='utf-8')
filters=re.findall(r'^exclude_filter="(.*)"$',presets,re.M)
assert filters and all('tools/**' in f for f in filters)
offline={'passed':True,'checks':[
    {'name':'Recorded hypothesis and evidence recalled after native shutdown','passed':True},
    {'name':'Pilot notebook retains both the slope hypothesis and later attention note','passed':True},
    {'name':'Developer brain and session scripts remain excluded from game export presets','passed':True}]}
(OUT/'offline-checks.json').write_text(json.dumps(offline,indent=2),encoding='utf-8')
pilot={'passed':native['passed'] and final['body']['deaths']==0 and audit['position'][1]+84>2.9,
    'actions':len(actions),'observations':len(frames),'height_metres':round(audit['position'][1]+84,3),
    'charge':round(final['body']['charge'],2),'deaths':final['body']['deaths'],'next_floor_reached':False,
    'scope':'Connected assistant selected bounded actions using player-eye images and body feedback. Operator already knew the floor; not a blind or trained-policy benchmark. Engine audit was requested only after the final exploration action. Reached the top of the ramp, not the next floor.'}
assert pilot['passed']
(SESSION/'pilot-checks.json').write_text(json.dumps(pilot,indent=2),encoding='utf-8')
notebook=json.loads((SESSION/'memory.json').read_text(encoding='utf-8'))['entries']
data={'frames':frames,'notebook':notebook,'pilot':pilot,'audit':audit,
      'protocol_checks':len(protocol['checks']),'offline_checks':len(offline['checks'])}
(PAGE/'trace.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
for source,name in [(protocol_path,'protocol-checks.json'),(OUT/'offline-checks.json','offline-checks.json'),(SESSION/'pilot-checks.json','pilot-checks.json')]:
    shutil.copy2(source,PAGE/name)
payload=json.dumps(data,ensure_ascii=False).replace('<',chr(92)+'u003c')
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Care Unit / Model B — first brain</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#17171d;color:#e9e6df;font:16px/1.55 system-ui}main{max-width:1300px;margin:auto;padding:34px 24px}h1{font-size:clamp(30px,4vw,54px);line-height:1.08;margin:16px 0}.eyebrow{color:#ed9ec9;letter-spacing:.12em;font-size:12px}p{max-width:940px}.muted{color:#beb7c6;font-size:14px}.status{display:flex;gap:12px;flex-wrap:wrap}.pill{border:1px solid #674857;border-radius:20px;padding:5px 13px;font-size:13px}.diagram{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:24px 0}.diagram span{padding:12px 18px;border:1px solid #5b4b58;border-radius:8px;background:#242128}.viewer{display:grid;grid-template-columns:minmax(0,1.7fr) minmax(270px,1fr);gap:22px;margin-top:24px}.panel{background:#242128;border:1px solid #41373f;border-radius:9px;overflow:hidden}.pad{padding:20px}img{display:block;width:100%}button{font:inherit;border:1px solid #856275;border-radius:6px;background:#352935;color:#f8e9f3;padding:7px 14px;cursor:pointer}button:hover{background:#513447}.controls{display:flex;gap:10px;align-items:center;flex-wrap:wrap;padding:14px}input{flex:1;min-width:100px;accent-color:#ed9ec9}h2{font-size:22px}h3{margin-top:0;font-size:17px}.metrics{display:grid;grid-template-columns:1fr 1fr;gap:10px}.metric{background:#19181e;padding:9px;border-radius:6px}.metric b{display:block;font-size:20px}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:13px;background:#17151c;padding:13px;border-radius:5px}.note{border-left:3px solid #dc8eb9;padding:9px 13px;margin:10px 0;background:#211d25}.note small{color:#e7a6ca}.evidence{font-size:12px;color:#d4c1d0}a{color:#f3abd0}details{padding:16px 0;border-top:1px solid #41373f;margin-top:24px}.finding{border-left:3px solid #d7c0a0;padding:0 18px;margin:26px 0}@media(max-width:850px){.viewer{grid-template-columns:1fr}main{padding:24px 15px}}</style>
<main><div class="eyebrow">ADA RESEARCH · CARE UNIT / MODEL B · 26 OCTOBER 2026</div><h1>A brain that can look, try, and reconsider.</h1>
<p>The first version controls Model B’s existing player body in an isolated developer session. A connected assistant supplies decisions; Godot executes short actions and returns the actual camera view, contact and charge feedback. The notebook keeps hypotheses distinct from measured outcomes.</p>
<div class="status"><span class="pill">Recorded scout · floor 14</span><span class="pill">External assistant reasoning</span><span class="pill">No RT-2 weights installed</span><span class="pill">Ordinary play unchanged</span></div>
<div class="diagram"><span>Player-eye observation</span>→<span>Reason + remember</span>→<span>Bounded physical action</span>→<span>Observe consequences</span></div>
<div class="viewer"><section class="panel"><img id="view" alt="Recorded Model B player-eye observation"><div class="controls"><button id="prev" aria-label="Previous observation">←</button><button id="play">Replay</button><input id="timeline" type="range" min="0" aria-label="Recorded observation"><button id="next" aria-label="Next observation">→</button><span id="frame"></span></div><div class="pad"><h3 id="reason"></h3><p id="outcome" class="muted"></p></div></section>
<aside class="panel pad"><h2>Body feedback</h2><div class="metrics"><div class="metric"><b id="charge"></b>charge</div><div class="metric"><b id="grounded"></b>support</div><div class="metric"><b id="deaths"></b>deaths</div><div class="metric"><b id="checkpoint"></b>checkpoint</div></div><h2>Working memory at this frame</h2><div id="memory"></div></aside></div>
<section class="finding"><h2>First scout</h2><p id="pilot"></p><p>The side approach produced contact. After inspecting the lower end, the assistant distinguished the strip meeting a vertical block from the continuous slope and tested that slope. The next suspended crossing was inspected but not attempted.</p><p class="muted">This was a familiar-floor integration demonstration, not an unfamiliar-map benchmark. Physics pauses between decisions. Neither real-time autonomous navigation nor a complete descent is claimed.</p></section>
<h2>Session notebook</h2><p class="muted">These are the recorded hypotheses, interpretations and matters of attention at the end of the session. Evidence links return to the images that prompted them.</p><div id="notebook"></div>
<details><summary>Engine audit — requested after the scout</summary><p class="muted">Developer-only coordinates and contacts. This channel is separate from Model B’s player-eye observations.</p><pre id="audit"></pre></details>
<details><summary>What is implemented and checked</summary><p id="checks"></p><p>Actual player-eye PNGs; local movement, looking, jumping and waiting; current-observation checks; evidence-linked memory and notebook recall; human stop/resume; idle closure; and separate engine diagnostics. Actions cannot teleport, reset the encounter or edit the world.</p><p>Reasoning is supplied by the connected assistant through the local protocol. This is a desktop developer pilot. It has no embedded learned policy, autonomous model service, manipulation controller or headset-control acceptance.</p><p><a href="protocol-checks.json">Native checks</a> · <a href="offline-checks.json">Notebook/export checks</a> · <a href="pilot-checks.json">Scout receipt</a> · <a href="trace.json">Recorded trace</a> · <a href="/lab-editor?mode=void&floor=14">Open floor 14</a></p></details></main>
<script id="data" type="application/json">__DATA__</script><script>
const D=JSON.parse(document.getElementById('data').textContent),$=id=>document.getElementById(id),slider=$('timeline');let timer=null;slider.max=D.frames.length-1;slider.value=D.frames.length-1;
function note(entry){const box=document.createElement('div');box.className='note';const kind=document.createElement('small');kind.textContent=entry.kind.replaceAll('_',' ');box.append(kind);const p=document.createElement('p');p.textContent=typeof entry.text==='string'?entry.text:JSON.stringify(entry.text);box.append(p);const ev=document.createElement('div');ev.className='evidence';for(const id of entry.evidence??[]){const a=document.createElement('a');a.href='#recording';a.textContent=id+' ';a.onclick=e=>{e.preventDefault();const n=D.frames.findIndex(f=>f.id===id);if(n>=0){slider.value=n;render();$('view').scrollIntoView({block:'center',behavior:'smooth'})}};ev.append(a)}box.append(ev);return box}
function render(){const f=D.frames[Number(slider.value)];$('view').src=f.image;$('frame').textContent=f.id;$('charge').textContent=f.body.charge.toFixed(1)+'%';$('grounded').textContent=f.body.grounded?'Grounded':'Airborne';$('deaths').textContent=f.body.deaths;$('checkpoint').textContent=f.body.checkpoint;$('reason').textContent=f.action?.reason??'Observe before choosing an action.';const o=f.action?.outcome;$('outcome').textContent=o?`Measured movement: ${o.moved_metres.toFixed(2)} m · Contact: ${o.bumped?'yes':'no'} · Charge used: ${o.charge_used.toFixed(2)}`:'Initial player-eye observation. No action outcome yet.';$('memory').replaceChildren();for(const n of f.memory.filter(n=>n.kind!=='observed_outcome').slice(-4))$('memory').append(note(n));if(!$('memory').children.length)$('memory').textContent='No hypothesis recorded yet.'}
slider.oninput=render;$('prev').onclick=()=>{slider.value=Math.max(0,Number(slider.value)-1);render()};$('next').onclick=()=>{slider.value=Math.min(D.frames.length-1,Number(slider.value)+1);render()};$('play').onclick=()=>{if(timer){clearInterval(timer);timer=null;$('play').textContent='Replay';return}slider.value=0;render();$('play').textContent='Pause replay';timer=setInterval(()=>{if(Number(slider.value)>=D.frames.length-1){clearInterval(timer);timer=null;$('play').textContent='Replay';return}slider.value=Number(slider.value)+1;render()},1400)};
for(const n of D.notebook.filter(n=>n.kind!=='observed_outcome'))$('notebook').append(note(n));$('pilot').textContent=`${D.pilot.actions} bounded actions and ${D.pilot.observations} observations. Reached ${D.pilot.height_metres.toFixed(2)} m above the floor, near the top of the ramp, with ${D.pilot.charge.toFixed(1)}% charge and no deaths. The next floor was not reached.`;$('audit').textContent=JSON.stringify(D.audit,null,2);$('checks').textContent=`${D.protocol_checks} native protocol checks and ${D.offline_checks} notebook/export checks passed. The test exercised real body movement, invalid and stale requests, camera observations, persisted evidence, in-flight interruption, human handover and idle closure.`;render();
</script></html>'''
(PAGE/'index.html').write_text(html.replace('__DATA__',payload),encoding='utf-8')
summary={'pilot':pilot,'native_protocol_checks':len(protocol['checks']),'offline_checks':len(offline['checks']),
         'page':str(PAGE/'index.html'),'new_runtime_scope':'Developer-only tools; no default gameplay changes or model downloads.'}
(OUT/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2))
