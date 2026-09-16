import json
import shutil
from stage import ROOT,OUT,read
dest=ROOT/'doc/research/possible-bodies'
media=dest/'randomness-spatial';media.mkdir(exist_ok=True)
rooms=read(OUT/'manifest.json')
roles=read(ROOT/'commons/data/artifact_roles.json')['roles']
notes={
'Random_Definition':'The seed instrument remains the hero. The 1955 number page is now 3.2 × 4.8 metres, twice its previous width and height.',
'Random_Entropy':'A reachable Shannon ledger leads to a 10 × 10 metre glass enclosure. Inside, a square 16 × 16 plan carries five layers of displaced points. Visible displacement and measured symbol entropy remain distinct experiments.',
'Random_Remove':'The small 8 × 8 bench stays. Behind it, 99 physical floor cells span a fire basin. Entry starts a draw; walking requests more. A red warning precedes removal, and the apron remains. Replay restores both the cells and their colliders.',
'Random_Walk':'The logbook instrument is followed by a full-size ten-metre walk field in a 12 × 12 metre enclosure. Height retains visits. The historical artifact name says 128; its current working lattice is 32 × 32.',
'Random_Gaussian':'The distribution and sampling controls now share one compact console in front of the cabinet. The board, comparator and paint work remain as supporting experiments.',
'Random_Mushrooms':'The six-metre bed sits inside an 8 × 8 metre glass enclosure. Its four-metre entrances leave room beside the specimen table. The buttons face the visitor together on a separate reachable console.',
'Random_Game':'A longer game: sampled waits at the crossing, a floor disappearing as you walk, three randomized doors, then the falling-cube field. One door is a passage; the other two open, warn and release a 2.7 metre fire jet. Replay preserves the assignment; a new seed draws another round.'}
for room in rooms:
 room['note']=notes[room['map']]
 room['primary']=[k for k,v in roles[room['map']].items() if v=='primary']
 room['views']=[]
 for view in ['space','removing','doors','fire','overview','hero']:
  filename=room['map']+'-'+view+'.png'
  if (OUT/filename).exists():
   room['views'].append(view);shutil.copy2(OUT/filename,media/filename)
 room['checks']=read(OUT/(room['map']+'-runtime.json'))['checks']
report=read(OUT/'verification.json')
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Randomness at two scales · Ada Research</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#eeeae2;color:#263b40;font:16px/1.55 system-ui,sans-serif}header,main,footer{max-width:1400px;margin:auto;padding:28px 36px}header{padding-bottom:0}small,.muted{color:#667577}.eyebrow{font-size:12px;letter-spacing:.13em;text-transform:uppercase;color:#925543}h1{font:clamp(36px,5vw,68px)/1.1 Georgia,serif;margin:18px 0}header p{max-width:850px;font-size:19px}nav,.views,.links{display:flex;gap:8px;flex-wrap:wrap;margin:18px 0}button{font:inherit;border:1px solid #9caaa9;color:inherit;background:transparent;border-radius:3px;padding:9px 14px;cursor:pointer}button[aria-pressed=true]{background:#263b40;color:#fff}button:focus-visible,a:focus-visible{outline:3px solid #b96748;outline-offset:3px}a{color:inherit;text-underline-offset:3px}.layout{display:grid;grid-template-columns:minmax(0,2.8fr) minmax(250px,1fr);gap:26px}figure{margin:0;background:#faf7f1;border:1px solid #c8ccc6}img{display:block;width:100%;aspect-ratio:1.6;object-fit:contain}figcaption{font-size:13px;padding:12px 18px}h2{font:36px Georgia,serif;margin:6px 0 12px}h3{font:24px Georgia,serif}ul{padding-left:20px}li{margin:12px 0;overflow-wrap:anywhere}.links{gap:22px}.note{border-left:3px solid #b96748;padding-left:18px;margin:24px 0;max-width:1000px}details{border-top:1px solid #bec5c0;padding-top:14px;margin-top:26px}summary{cursor:pointer}#checks{font-size:14px;columns:2}.tag{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:#935440}footer{font-size:14px;color:#617073}@media(max-width:850px){header,main,footer{padding:22px 16px}.layout{grid-template-columns:1fr}#checks{columns:1}}
</style></head><body><header><div class="eyebrow">Ada Research / Randomness / 16 September 2026</div><h1>Randomness at two scales</h1><p>An instrument close enough to touch. A space large enough to enter. The rule travels between them, and its consequences change when it becomes the ground beneath you.</p><nav id="rooms" aria-label="Choose a hall"></nav></header>
<main><h2 id="title"></h2><p id="description"></p><p id="dimensions" class="muted"></p><div class="views" id="views" aria-label="Museum views"></div><div class="layout"><figure><img id="photo" alt=""><figcaption id="caption"></figcaption></figure><aside><h3>In this hall</h3><ul id="inventory"></ul><div class="links"><a id="book">Read the book</a><a id="thread">Primary artifacts</a></div></aside></div>
<p class="note">The glass enclosures have real openings and collidable side walls. The floor experiment owns its cells; it does not delete the museum. Its return in Random Game is an intentional application of a rule first investigated at the table.</p>
<details><summary>What has been checked</summary><p>__CHECKS__ focused checks passed across the seven halls: map and plan agreement, book roles, artifact loading, floor support, control reach and the new interaction paths. The fire jet was tested through museum death and respawn. The standing marks provide a geometric reach check; headset comfort and performance remain to be assessed in VR.</p><ul id="checks"></ul></details></main><footer><p>All images are captures from the actual Godot endless museum. “Twelve removals” shows twelve sequential draws using the normal warning time; “Fire door” shows an active jet alongside the revealed passage.</p><a href="/museum-progress?sequence=randomness">Museum progress</a> · <a href="randomness-staging.html">Previous compact staging pass</a></footer>
<script>
const rooms=__DATA__;
const $=id=>document.getElementById(id);
const names={space:'Enter the space',removing:'Twelve removals',doors:'Choose a door',fire:'Fire door',overview:'Hall overview',hero:'The instrument'};
let selected=Math.max(0,rooms.findIndex(r=>r.map===location.hash.slice(1))),view='';
function render(){const r=rooms[selected];if(!r.views.includes(view))view=r.views[0];$('title').textContent=r.map.replaceAll('_',' ');$('description').textContent=r.note;$('dimensions').textContent=`${r.size.width} × ${r.size.depth} source-grid metres · ${r.count} artifacts`;$('photo').src='randomness-spatial/'+r.map+'-'+view+'.png';$('photo').alt=r.map.replaceAll('_',' ')+': '+names[view];$('caption').textContent='Inside the endless museum · '+names[view];$('book').href='/book?map='+r.map+'&section=final';$('thread').href='/necklace/thread?map='+r.map+'&role=primary';$('inventory').replaceChildren();r.placements.forEach(p=>{const li=document.createElement('li'),strong=document.createElement('strong'),label=document.createElement('div');strong.textContent=p.lookup;label.className='tag';label.textContent=r.primary.includes(p.lookup)?'Book encounter':'Supporting work';li.append(strong,label);$('inventory').append(li)});$('views').replaceChildren();r.views.forEach(v=>{const b=document.createElement('button');b.textContent=names[v];b.setAttribute('aria-pressed',v===view);b.onclick=()=>{view=v;render()};$('views').append(b)});document.querySelectorAll('#rooms button').forEach((b,i)=>b.setAttribute('aria-pressed',i===selected));$('checks').replaceChildren();r.checks.forEach(c=>{const li=document.createElement('li');li.textContent=(c.passed?'✓ ':'✕ ')+c.check;$('checks').append(li)});history.replaceState(null,'','#'+r.map)}
rooms.forEach((r,i)=>{const b=document.createElement('button');b.textContent=(i+1)+' '+r.map.replace('Random_','');b.onclick=()=>{selected=i;view='';render()};$('rooms').append(b)});render();
</script></body></html>'''
assert not report['failed'],report['failed']
page=page.replace('__DATA__',json.dumps(rooms,ensure_ascii=False).replace('</','<\\/')).replace('__CHECKS__',str(report['checks']))
(dest/'randomness-spatial.html').write_bytes(page.encode())
print('Built randomness-spatial.html with',sum(len(r['views']) for r in rooms),'actual museum captures.')
