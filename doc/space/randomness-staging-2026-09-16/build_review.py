import html
import json
import pathlib
import shutil
from stage import ROOT, OUT, ROOMS, load

DEST = ROOT/'doc/research/possible-bodies'
MEDIA = DEST/'randomness-staging'
MEDIA.mkdir(exist_ok=True)
manifest = load(OUT/'manifest.json')
verification = load(OUT/'verification.json')
roles = load(ROOT/'commons/data/artifact_roles.json')
for row in manifest:
    row['runtime'] = load(OUT/(row['map']+'-runtime.json'))
    row['primary'] = [k for k,v in roles['roles'][row['map']].items() if v=='primary']
    row['structure'] = load(ROOT/'commons/maps'/row['map']/'map_data.json')['layers']['structure']
    for view in ['overview','hero']:
        filename = row['map']+'-'+view+'.png'
        shutil.copy2(OUT/filename, MEDIA/filename)

page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Randomness · rooms with a centre · Ada Research</title>
<style>
:root{color-scheme:light;--paper:#f3f0e9;--ink:#202d31;--muted:#5f6869;--red:#ad4838;--blue:#49767b;--line:#d4d4cb}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.5 system-ui,sans-serif}a{color:inherit;text-underline-offset:4px}header,main,footer{max-width:1400px;margin:auto;padding:32px 40px}header{padding-bottom:12px}.eyebrow{font-size:12px;letter-spacing:.15em;text-transform:uppercase;color:var(--red)}h1{font:clamp(36px,5.5vw,70px)/1.04 Georgia,serif;max-width:900px;font-weight:400;margin:18px 0}header p{max-width:810px;font-size:18px;color:var(--muted)}nav{display:flex;gap:8px;flex-wrap:wrap;margin:24px 0 8px}button{font:inherit;cursor:pointer;border:1px solid var(--line);background:transparent;color:var(--ink);border-radius:4px;padding:9px 14px}button[aria-pressed=true]{background:var(--ink);color:white;border-color:var(--ink)}button:hover{border-color:var(--red)}button:focus-visible,a:focus-visible{outline:3px solid var(--red);outline-offset:3px}.head{display:flex;align-items:end;justify-content:space-between;gap:24px}.head h2{font:36px/1.2 Georgia,serif;margin:0}.stats{font-size:14px;color:var(--muted);margin-top:10px}.purpose{max-width:920px;margin:18px 0 24px}.layout{display:grid;grid-template-columns:minmax(0,2.3fr) minmax(260px,1fr);gap:24px}.photo{margin:0;background:#e3e3da;border:1px solid var(--line)}.photo img{display:block;width:100%;aspect-ratio:1.6;object-fit:cover}figcaption{padding:12px 16px;font-size:13px;color:var(--muted)}.switch{display:flex;gap:8px;margin-bottom:12px}.drawing{background:#faf8f4;border:1px solid var(--line);padding:12px}.drawing svg{display:block;width:100%;height:350px}.legend{font-size:13px;color:var(--muted)}.inventory{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px;padding:0;list-style:none;margin-top:26px}.inventory li{border-top:1px solid var(--line);padding-top:12px}.inventory strong{display:block;font-size:15px;overflow-wrap:anywhere}.inventory small{color:var(--muted)}.dot{display:inline-block;width:10px;height:10px;border-radius:50%;background:var(--blue);margin-right:8px}.hero{background:var(--red)}details{margin-top:24px;border-top:1px solid var(--line);padding-top:14px}summary{cursor:pointer}table{border-collapse:collapse;width:100%;font-size:14px}td,th{text-align:left;padding:10px 8px;border-bottom:1px solid var(--line)}footer{font-size:14px;color:var(--muted);padding-top:0}.links{display:flex;gap:20px;flex-wrap:wrap;font-size:14px}.note{border-left:3px solid var(--red);padding-left:18px;max-width:900px;margin:28px 0}#archive{columns:2;font-size:14px;overflow-wrap:anywhere}@media(max-width:850px){header,main,footer{padding:24px 18px}.layout{grid-template-columns:1fr}.head{align-items:start;flex-direction:column}.drawing svg{height:300px}#archive{columns:1}}
</style></head><body>
<header><div class="eyebrow">Ada Research / Randomness / 16 September 2026</div>
<h1>Give chance a centre.</h1>
<p>One encounter to begin with. Supporting works that let the question spread. Seven rooms fitted around what they hold, with their instruments facing the approach from −Z.</p>
<nav aria-label="Randomness halls" id="rooms"></nav></header>
<main><div class="head"><div><h2 id="title"></h2><div id="stats" class="stats"></div></div><div class="links"><a id="book">Read the room</a><a id="thread">Primary artifacts</a></div></div>
<p class="purpose" id="purpose"></p><div class="layout"><div><div class="switch" aria-label="Museum view"><button id="overview" aria-pressed="true">Whole room</button><button id="hero" aria-pressed="false">At the instrument</button></div><figure class="photo"><img id="photo" alt=""><figcaption id="caption"></figcaption></figure></div><div class="drawing"><div id="plan"></div><p class="legend"><span class="dot hero"></span>Central hero &nbsp; <span class="dot"></span>Supporting work<br>Numbers correspond to the inventory below. The top is the entrance; the arrow points toward −Z.</p></div></div>
<ol class="inventory" id="inventory"></ol>
<details><summary>What left this room, and what remains available?</summary><p>These placements are archived, with their original coordinates and configurations. Their artifact scenes remain in the project. Copies can return when they add a distinct discovery.</p><ul id="archive"></ul></details>
<div class="note">The sequence still asks: <strong>what can this random choice change, and what has already been decided before it is drawn?</strong> Remove needs only its complete bench. Game keeps two book encounters: the crossing is the spatial hero, followed by the falling-cube field.</div>
<details><summary>See the whole revision</summary><table><thead><tr><th>Room</th><th>Before → now</th><th>Placements</th><th>Central hero</th></tr></thead><tbody id="table"></tbody></table><p>63 placements became 25 distinct artifacts, with no repeated lookup across these seven active halls. The broader stored map library is retained. Room sizes are source-grid metres; connecting museum vestibules are additional.</p></details>
</main><footer><p>Actual Godot museum captures. All 25 curated scenes instantiated; 28 doorway and bypass floor samples passed, with no automatic route repairs. 115 focused data, runtime and live-book checks passed. Headset reach, traversal comfort and performance remain for an embodied visit.</p><a href="/museum-progress?sequence=randomness">Museum progress</a> · <a href="/research/possible-bodies/index.html">Possible bodies</a></footer>
<script>
const rooms = __DATA__;
let selected=0, view='overview';
const el=id=>document.getElementById(id);
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function draw(r){
 const w=r.size.width,d=r.size.depth;let s=`<svg viewBox="-1 -3 ${w+1} ${d+4}" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Floor plan of ${r.map}"><text x="${(w-1)/2}" y="-1.4" text-anchor="middle" font-size=".5" fill="#5f6869">ENTRANCE / −Z ↑</text>`;
 for(let z=0;z<d;z++)for(let x=0;x<w;x++)s+=`<rect x="${x-.5}" y="${z-.5}" width="1" height="1" fill="${r.structure[z][x]==='w'?'#bfc7c4':r.structure[z][x]==='0'?'#323e43':'#f5f2eb'}" stroke="#dcded6" stroke-width=".025"/>`;
 r.placements.forEach((p,i)=>{const hero=p.lookup===r.hero,b=r.runtime.artifacts.find(a=>a.lookup===p.lookup)?.bounds,color=hero?'#ad4838':'#49767b';if(b&&p.lookup!=='random_butterflies')s+=`<rect x="${b.min[0]}" y="${b.min[2]}" width="${Math.max(.15,b.max[0]-b.min[0])}" height="${Math.max(.15,b.max[2]-b.min[2])}" fill="${color}" opacity=".22"/>`;s+=`<circle cx="${p.x}" cy="${p.z}" r=".42" fill="${color}"/><text x="${p.x}" y="${p.z+.15}" text-anchor="middle" font-family="system-ui" font-size=".45" fill="white">${i+1}</text>`;});
 s+='</svg>';return s;
}
function render(){const r=rooms[selected];
 el('title').textContent=r.map.replaceAll('_',' ');el('stats').textContent=`${r.before_size.width} × ${r.before_size.depth} m → ${r.size.width} × ${r.size.depth} m  ·  ${r.count} artifacts`;
 el('purpose').textContent=r.purpose;el('book').href='/book?map='+r.map+'&section=final';el('thread').href='/necklace/thread?map='+r.map+'&role=primary';
 el('photo').src='randomness-staging/'+r.map+'-'+view+'.png';el('photo').alt=(view==='overview'?'Room overview: ':'Central instrument: ')+r.map.replaceAll('_',' ');el('caption').textContent='Inside the endless museum · '+(view==='overview'?'the central encounter and its supporting works':'approaching the central encounter from −Z');
 el('plan').innerHTML=draw(r);el('inventory').innerHTML=r.placements.map((p,i)=>`<li><strong><span class="dot ${p.lookup===r.hero?'hero':''}"></span>${i+1}. ${esc(p.lookup)}</strong><small>${p.lookup===r.hero?'Central hero':r.primary.includes(p.lookup)?'Second book encounter':'Supporting work'} · (${p.x}, ${p.z})</small></li>`).join('');
 el('archive').innerHTML=r.removed_placements.length?r.removed_placements.map(p=>`<li>${esc(p.lookup)} · previous (${p.x}, ${p.z})</li>`).join(''):'<li>No retired placements.</li>';
 document.querySelectorAll('#rooms button').forEach((b,i)=>b.setAttribute('aria-pressed',i===selected));['overview','hero'].forEach(v=>el(v).setAttribute('aria-pressed',v===view));
 history.replaceState(null,'','#'+r.map);
}
rooms.forEach((r,i)=>{const b=document.createElement('button');b.textContent=(i+1)+' '+r.map.replace('Random_','');b.onclick=()=>{selected=i;render()};el('rooms').append(b)});
el('table').innerHTML=rooms.map(r=>`<tr><td>${esc(r.map.replace('Random_',''))}</td><td>${r.before_size.width}×${r.before_size.depth} → ${r.size.width}×${r.size.depth}</td><td>${r.before_count} → ${r.count}</td><td>${esc(r.hero)}</td></tr>`).join('');
['overview','hero'].forEach(v=>el(v).onclick=()=>{view=v;render()});const first=rooms.findIndex(r=>r.map===location.hash.slice(1));if(first>=0)selected=first;render();
</script></body></html>'''
page = page.replace('__DATA__',json.dumps(manifest,ensure_ascii=False).replace('</','<\\/'))
(DEST/'randomness-staging.html').write_text(page,encoding='utf-8')
print('Built review page and 14 museum captures.')
