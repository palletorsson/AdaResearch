"""Publish photographed Swarm inventory without changing museum content."""
from pathlib import Path
from html import escape as h
from PIL import Image, ImageDraw, ImageFont
import json, shutil, hashlib, math, re

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-10-swarm-artifact-gallery'
(O / 'assets').mkdir(exist_ok=True)
(O / 'receipts').mkdir(exist_ok=True)
read = lambda p: json.loads(p.read_text(encoding='utf8'))
seq = read(R / 'commons/maps/sequences/swarmintelligence.json')['sequences']['swarmintelligence']['maps']
hall_names = ['Physarum', 'Flow Fields', 'Boids', 'Agent-Based Modeling', 'Ant Colony', 'Particle Swarm', 'Population Support']
reg = {}
for f in (R / 'commons/artifacts/registry').glob('*.json'):
    try: reg.update(read(f).get('artifacts', {}))
    except (ValueError, AttributeError): pass
library = {a['token']: a for a in read(O / 'library.json')}
names = {
    'science_screen': 'Scatter screen', 'PhysarumColony': 'Physarum live table',
    'ant_agent': 'Individual ant', 'particle_swarm_optimization_legacy': 'Particle swarm / legacy',
    'flow_field_table': 'Flow-field live table', 'AntColonyV2': 'Ant colony V2',
    'ecosystem_simulation': 'Predator–prey ecosystem', 'film_boid_neighbour': 'Neighbour film',
    'boids_aquarium': 'Boids aquarium', 'boids_2d_in_3d': '2D boids panel',
    'boid_manager': 'Open flock', 'flocking_controls': 'Flocking controls',
    'catalyst_prompter_box': 'Catalyst prompter', 'ant_colony_optimization': 'Ant colony comparison',
    'physarum_colony': 'Original Physarum colony', 'catalyst_foe': 'Catalyst creature',
    'catalyst_vent': 'Catalyst vent', 'navigator_noise': 'Navigator / noise',
    'ant_colony_walk': 'Two trails underfoot', 'particle_swarm_walk': 'A place remembered',
    'fitness_landscape_politics': 'Fitness landscape', 'self_organizing_patterns': 'Self-organizing patterns',
    'tick_flock': 'Tick flock', 'population_account_walk': 'Who keeps the count?',
    'accord_swarm': 'Accord swarm', 'ant_colony_art': 'Ant colony / art',
    'particle_swarm_optimization': 'Particle swarm / alternative', 'stigmergy_grid': 'Stigmergy grid',
}
descriptions = {
    'science_screen': 'A scatter view beside the spatial encounter.',
    'PhysarumColony': 'The original simulation runs inside a live table display.',
    'ant_agent': 'The individual agent used by an older ant-colony simulation.',
    'particle_swarm_optimization_legacy': 'An earlier particle-swarm convergence display.',
    'flow_field_table': 'Directions and moving agents from the existing flow-field simulation.',
    'AntColonyV2': 'Ants, pheromone traces and food sources. Its terrain extends beyond the room.',
    'ecosystem_simulation': 'An existing predator–prey model; it returns inside the final population account.',
    'film_boid_neighbour': 'A monitor introduces the neighbourhood used by a boid.',
    'boids_aquarium': 'A small contained flock with nearby controls.',
    'boids_2d_in_3d': 'The saved 2D-in-3D comparison panel.',
    'boid_manager': 'The large purple flock outside the hall; observable from the balcony.',
    'flocking_controls': 'Separation, alignment, cohesion, speed and perception radius.',
    'catalyst_prompter_box': 'A catalyst apparatus beside the agent-state comparisons.',
    'ant_colony_optimization': 'A second ant-colony model retained for comparison.',
    'physarum_colony': 'The original large simulation that also supplies the first hall’s live table.',
    'catalyst_foe': 'An existing catalyst creature in the agent-based hall.',
    'catalyst_vent': 'A source of catalyst creatures in the room.',
    'navigator_noise': 'A paired navigator display: the same aim under different conditions.',
    'ant_colony_walk': 'Full-size carried points move between home and food using two trail channels.',
    'particle_swarm_walk': 'Full-size points compare current positions, personal memories and a shared best.',
    'fitness_landscape_politics': 'A comparison exhibit for what a chosen fitness landscape rewards.',
    'self_organizing_patterns': 'A compact field of changing collective patterns.',
    'tick_flock': 'A wall display of collective motion.',
    'population_account_walk': 'A new full-size display and event account around the existing ecosystem model.',
    'accord_swarm': 'A registered collective-motion sculpture, outside the seven saved hall plans.',
    'ant_colony_art': 'A separate ant-colony scene with terrain, obstacles and food.',
    'particle_swarm_optimization': 'A second registered PSO scene with particles and a fitness landscape.',
    'stigmergy_grid': 'A separate trace-field artifact in the Swarm library.',
}
new = {'ant_colony_walk', 'particle_swarm_walk', 'population_account_walk'}
cards, rooms = [], []

def photo(source, stem):
    source = Path(source)
    dest = O / 'assets' / (stem + '.png')
    shutil.copyfile(source, dest)
    with Image.open(source) as im:
        im = im.convert('RGB'); im.thumbnail((960, 640))
        im.save(O / 'assets' / (stem + '.jpg'), quality=88)
    return {'image': 'assets/' + stem + '.png', 'thumb': 'assets/' + stem + '.jpg',
            'source': source.relative_to(R).as_posix(), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()}

def earlier(report, image):
    return R / 'doc/book/iterations' / report / 'assets' / (image + '.png')

for n, m in enumerate(seq, 1):
    D = R / 'ada_run/encounter_pilot' / m / 'all-artifacts'
    receipt = read(D / 'report.json')
    assert receipt['passed'] and receipt['completed']
    shutil.copyfile(D / 'report.json', O / 'receipts' / (m + '.json'))
    rooms.append({'map': m, 'name': hall_names[n - 1], **photo(D / 'hall-overview.png', f'hall-{n}')})
    for a in receipt['artifacts']:
        t = a['token']; note = ''; alternatives = []
        kind = 'new' if t in new else 'existing'
        if a['loaded']:
            source = D / a['image']; capture = 'Museum capture · 10 Oct 2026'
        else:
            source = O / library[t]['image']; capture = 'Isolated scene preview · 10 Oct 2026'
            note = 'Saved in this hall’s plan, but no live instance appeared in this capture. This image shows the scene alone.'
        if t == 'science_screen' and n == 1:
            note = 'Live screen; partly obstructed by the room architecture in this capture.'
        if t == 'boids_2d_in_3d':
            note = 'The node loaded, but its panel produced no readable image here or in the isolated preview. The photograph shows its placement area.'
        if t == 'AntColonyV2':
            alternatives.append({'label': 'See the scene alone', **photo(O / 'library/AntColonyV2.png', 'ant-v2-isolated')})
        if t == 'boid_manager':
            alternatives.append({'label': 'From the balcony', **photo(earlier('2026-10-10-boids-observation-balcony', 'balcony-eye'), 'balcony-eye')})
        if t == 'flocking_controls':
            alternatives.append({'label': 'Earlier view with the whole control panel', **photo(earlier('2026-10-10-boids-who-is-near', 'flocking-controls'), 'flocking-controls-earlier')})
        cards.append({'id': f'{n}-{t}', 'token': t, 'title': names[t], 'description': descriptions[t],
                      'hall': m, 'hall_name': hall_names[n - 1], 'kind': kind, 'loaded': a['loaded'],
                      'capture': capture, 'note': note, 'scene': reg.get(t, {}).get('scene', ''),
                      'alternatives': alternatives, **photo(source, f'{n}-{t}')})

# These earlier native captures depict temporary lesson hosts, not saved placements.
studies = [
    ('Trace outside the point', 'A small point reads, deposits and returns to a shared trace.', '2026-10-10-swarm-a-trace-outside', 'student-trace'),
    ('Direction and response', 'Compare the direction stored at an address with the point’s actual velocity.', '2026-10-10-flow-directions-already-here', 'student-turn'),
    ('Who is near?', 'The carried points reveal separation, alignment and cohesion.', '2026-10-10-boids-who-is-near', 'three-requests'),
    ('What the point carries', 'Searching and carrying become explicit states in the same point.', '2026-10-10-abm-what-the-point-carries', 'carrying'),
]
for n, (title, desc, report, image) in enumerate(studies, 1):
    cards.append({'id': f'{n}-study', 'token': 'tutorial study', 'title': title, 'description': desc,
                  'hall': seq[n - 1], 'hall_name': hall_names[n - 1], 'kind': 'study', 'loaded': None,
                  'capture': 'Earlier native museum capture · 10 Oct 2026',
                  'note': 'Temporary teaching reconstruction. Not a permanent artifact in the saved hall plan.',
                  'scene': f'doc/book/studies/swarm-through-the-hands/{seq[n - 1]}/study.gd',
                  'alternatives': [], **photo(earlier(report, image), f'{n}-study')})
for t, a in library.items():
    if a['missing_in_hall']: continue
    cards.append({'id': 'library-' + t, 'token': t, 'title': names[t], 'description': descriptions[t],
                  'hall': 'library', 'hall_name': 'Additional library', 'kind': 'library', 'loaded': None,
                  'capture': 'Isolated scene preview · 10 Oct 2026',
                  'note': 'Registered scene; not placed in the seven current Swarm halls.',
                  'scene': a['scene'], 'alternatives': [], **photo(O / a['image'], 'library-' + t)})
order = {m: n for n, m in enumerate(seq + ['library'])}
cards.sort(key=lambda c: order[c['hall']])
assert len(cards) == 33
assert sum(c['loaded'] is True for c in cards) == 22
assert sum(c['loaded'] is False for c in cards) == 3
assert len({(c['hall'], c['token']) for c in cards if c['kind'] in ('existing', 'new')}) == 25
manifest = {'date': '2026-10-10', 'scope': 'All 25 saved placements in seven Swarm halls, four temporary tutorial studies, four additional registered Swarm scenes. Alias ant_colony_v2 shares the AntColonyV2 scene and is not duplicated.', 'cards': cards, 'rooms': rooms}
manifest['receipts'] = [f'receipts/{m}.json' for m in seq]
(O / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf8')

labels = {'existing': 'Existing exhibit', 'new': 'New full-size installation', 'study': 'Temporary tutorial study', 'library': 'Additional library scene'}
card_html = []
for i, c in enumerate(cards):
    alts = ''.join(f'<a href="{a["image"]}" target="_blank">{h(a["label"])}</a> ' for a in c['alternatives'])
    card_html.append(f'''<article id="{c['id']}" class="card" data-hall="{c['hall']}" data-kind="{c['kind']}" data-search="{h((c['title']+' '+c['token']+' '+c['description']).lower())}">
<a class="zoom" href="view-{c['id']}.html" aria-label="Enlarge {h(c['title'])}"><img src="{c['thumb']}" loading="lazy" width="960" height="640" alt="{h(c['title']+' — '+c['capture'])}"></a>
<div class="body"><div class="eyebrow">{h(c['hall_name'])} <span class="tag {c['kind']}">{labels[c['kind']]}</span></div>
<h2>{h(c['title'])}</h2><p>{h(c['description'])}</p><p class="caption">{h(c['capture'])}</p>
{('<p class="notice">'+h(c['note'])+'</p>') if c['note'] else ''}
<div class="alternatives">{alts}</div><details><summary>Artifact identity</summary><code>{h(c['token'])}</code><p class="path">{h(c['scene'])}</p></details></div></article>''')
room_html = ''.join(f'<figure><a href="{r["image"]}" target="_blank"><img loading="lazy" src="{r["thumb"]}" alt="{h(r["name"])} hall from above"></a><figcaption>{i+1}. {h(r["name"])}</figcaption></figure>' for i, r in enumerate(rooms))
options = ''.join(f'<option value="{m}">{i+1}. {h(hall_names[i])}</option>' for i, m in enumerate(seq))
html = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Swarm · all artifacts</title><style>
*{box-sizing:border-box}body{margin:0;background:#f1f0e9;color:#1c3037;font:16px/1.55 system-ui,sans-serif}a{color:#125965}a:hover{text-decoration:none}nav{padding:16px 4vw;background:#16333b;color:white;display:flex;gap:25px;flex-wrap:wrap}nav a{color:#d6f1e5}main{max-width:1660px;margin:auto;padding:38px 4vw 80px}h1{font:clamp(40px,5vw,72px)/1.05 Georgia,serif;margin:16px 0 22px}header>p{max-width:850px}.eyebrow{font-size:12px;letter-spacing:.035em;text-transform:uppercase;color:#4c646a}.intro{font-size:19px}.stats{display:flex;gap:28px;flex-wrap:wrap;padding:20px 0 26px}.stats b{font-size:30px;display:block}.stats span{font-size:13px}.filters{display:flex;gap:14px;flex-wrap:wrap;align-items:end;background:#f1f0e9ee;border-top:1px solid #b9c9c6;border-bottom:1px solid #b9c9c6;padding:16px 0;margin:15px 0 26px;position:sticky;top:0;z-index:2;backdrop-filter:blur(12px)}label{display:grid;gap:4px;font-size:12px}select,input,button{font:inherit;padding:9px 12px;border:1px solid #a1b8b8;background:white;border-radius:4px;color:#18313b}input{min-width:240px}button{cursor:pointer}button:hover{background:#deece8}:focus-visible{outline:3px solid #b96347;outline-offset:3px}#count{font-size:13px;margin-left:auto;align-self:center}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}.card{background:white;border:1px solid #d5dfda;border-radius:6px;overflow:hidden}.card[hidden]{display:none}.card img{display:block;width:100%;height:auto;aspect-ratio:3/2;object-fit:contain;background:#202631;transition:filter .2s}.zoom:hover img{filter:brightness(1.12)}.body{padding:18px 20px 20px}h2{font:26px/1.12 Georgia,serif;margin:14px 0 12px}.body p{margin:10px 0}.tag{display:table;font:11px/1.7 system-ui;margin-top:7px;border-radius:3px;padding:2px 7px;background:#e7eded;color:#415b60;letter-spacing:0;text-transform:none}.tag.new{background:#d8ebe1;color:#185e40}.tag.study{background:#e9e1f0;color:#68428b}.tag.library{background:#f2e6ca;color:#77571f}.caption{font-size:12px;color:#5a7074}.notice{font-size:13px;padding:10px 12px;border-left:3px solid #b87a45;background:#fbf3e6}.alternatives a{display:block;font-size:13px;margin:7px 0}details{margin-top:14px;font-size:13px}summary{cursor:pointer}code,.path{font-size:11px;overflow-wrap:anywhere}.rooms{margin:26px 0}.rooms summary{font-size:18px}.room-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-top:18px}figure{margin:0}figure img{width:100%}figcaption{font-size:13px}footer{border-top:1px solid #b9c9c6;margin-top:48px;padding-top:18px;max-width:900px;font-size:13px;color:#4c646a}dialog{border:0;background:#15242b;color:white;max-width:96vw;width:1300px;padding:18px;border-radius:8px}dialog::backdrop{background:#081417e8}dialog img{width:100%;max-height:76vh;object-fit:contain;display:block}dialog .bar{display:flex;align-items:center;gap:12px;margin:10px 0}dialog h2{margin:0;flex:1;font-size:23px}dialog a{color:#c7eadc}#modal-note{font-size:13px}#empty{padding:40px;background:white}@media(max-width:1100px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}.room-grid{grid-template-columns:repeat(2,1fr)}}@media(max-width:650px){.grid{grid-template-columns:1fr}.filters{position:static}main{padding:26px 16px}#count{margin:0}.room-grid{grid-template-columns:1fr}dialog .bar{flex-wrap:wrap}}@media print{.filters,dialog{display:none}nav{background:white}body{background:white}.card{break-inside:avoid}.grid{grid-template-columns:1fr 1fr}}
</style></head><body><nav><a href="../2026-10-10-swarm-complete-readings/index.html">Seven-hall readings</a><a href="contact-sheet.jpg">All images on one sheet</a><a href="manifest.json">Image inventory</a></nav><main>
<header><div class="eyebrow">Endless Museum / Swarm Intelligence / 10 October 2026</div><h1>Every artifact in the swarm.</h1><p class="intro">The exhibits, the comparison models, the catalysts and the tutorial objects. Actual Godot captures, arranged by hall. Select any image to enlarge it and move through the collection.</p>
<div class="stats"><div><b>7</b><span>museum halls</span></div><div><b>25</b><span>saved placements</span></div><div><b>4</b><span>temporary tutorial studies</span></div><div><b>4</b><span>additional library scenes</span></div></div>
<p>22 saved placements loaded in the museum capture. Three are shown as isolated scene previews and marked below. The existing 2D boids panel loaded but produced no readable image. “New” describes the recent Swarm work; this gallery changes no exhibits.</p></header>
<details class="rooms"><summary>See all seven rooms from above</summary><div class="room-grid">ROOMS</div></details>
<div class="filters"><label>Hall<select id="hall"><option value="all">All halls + library</option>OPTIONS<option value="library">Additional library</option></select></label><label>Objects<select id="kind"><option value="all">All kinds</option><option value="existing">Existing exhibits</option><option value="new">New full-size installations</option><option value="study">Temporary tutorial studies</option><option value="library">Additional library scenes</option></select></label><label>Find an artifact<input id="search" type="search" placeholder="Try boids, colony, catalyst…"></label><button id="reset">Show all</button><span id="count" aria-live="polite">33 cards</span></div>
<div class="grid">CARDS</div><p id="empty" hidden>No artifacts match these filters.</p><footer>Scope: every authored placement in the seven current Swarm hall plans, the four temporary teaching studies, and the additional scenes in the Swarm and Accord Swarm registries. The two AntColonyV2 registry names share a scene and appear once. This is a visual inventory, not a new behavior or headset test. Cameras were moved for inspection; source geometry and museum layouts were not changed. Native capture receipts are linked in the image inventory.</footer>
</main><dialog id="viewer" aria-label="Artifact image"><div class="bar"><h2 id="modal-title"></h2><button id="close">Close</button></div><img id="large" alt=""><div class="bar"><button id="previous">← Previous</button><button id="next">Next →</button><a id="original" target="_blank">Open full image</a></div><p id="modal-note"></p></dialog>
<script id="data" type="application/json">DATA</script><script>
const data=JSON.parse(document.getElementById('data').textContent);const cards=[...document.querySelectorAll('.card')];const hall=document.getElementById('hall'),kind=document.getElementById('kind'),search=document.getElementById('search'),viewer=document.getElementById('viewer');let current=0;
function filter(){const q=search.value.trim().toLowerCase();let n=0;cards.forEach(c=>{c.hidden=!((hall.value==='all'||c.dataset.hall===hall.value)&&(kind.value==='all'||c.dataset.kind===kind.value)&&c.dataset.search.includes(q));if(!c.hidden)n++});document.getElementById('count').textContent=n+' / '+cards.length+' cards';document.getElementById('empty').hidden=n>0;const p=new URLSearchParams();if(hall.value!=='all')p.set('hall',hall.value);if(kind.value!=='all')p.set('kind',kind.value);if(q)p.set('q',q);history.replaceState(null,'',location.pathname+(p.size?'?'+p:'')+location.hash)}
hall.addEventListener('change',filter);kind.addEventListener('change',filter);search.addEventListener('input',filter);document.getElementById('reset').onclick=()=>{hall.value=kind.value='all';search.value='';filter()};
function show(i){current=i;const c=data[i];document.getElementById('modal-title').textContent=c.hall_name+' / '+c.title;document.getElementById('large').src=c.image;document.getElementById('large').alt=c.title;document.getElementById('original').href=c.image;document.getElementById('modal-note').textContent=c.capture+(c.note?' · '+c.note:'');if(!viewer.open)viewer.showModal()}
function move(step){const visible=cards.map((c,i)=>c.hidden?-1:i).filter(i=>i>=0);const p=visible.indexOf(current);if(visible.length)show(visible[(p+step+visible.length)%visible.length])}
document.querySelectorAll('.zoom').forEach(a=>a.addEventListener('click',e=>{if(e.ctrlKey||e.metaKey||e.shiftKey)return;e.preventDefault();show(Number(a.dataset.index))}));document.getElementById('close').onclick=()=>viewer.close();document.getElementById('previous').onclick=()=>move(-1);document.getElementById('next').onclick=()=>move(1);viewer.addEventListener('keydown',e=>{if(e.key==='ArrowRight')move(1);if(e.key==='ArrowLeft')move(-1)});viewer.addEventListener('click',e=>{if(e.target===viewer)viewer.close()});const params=new URLSearchParams(location.search);if([...hall.options].some(o=>o.value===params.get('hall')))hall.value=params.get('hall');if([...kind.options].some(o=>o.value===params.get('kind')))kind.value=params.get('kind');search.value=params.get('q')||'';filter();
</script></body></html>'''
# The book-review server intentionally disallows scripts. Publish ordinary linked
# pages so hall selection and next/previous work there and from local files.
html = re.sub(r'<dialog id="viewer".*', '</body></html>', html, flags=re.S)
html = html.replace('ROOMS', room_html)
hall_links = [('index.html', 'All'), *[(f'hall-{i+1}.html', f'{i+1}. {name}') for i, name in enumerate(hall_names)], ('hall-library.html', 'Library')]
kind_links = [(f'kind-{k}.html', v) for k, v in labels.items()]
def navlinks(items, active):
    return ''.join(f'<a href="{url}" style="padding:7px 11px;background:{"#d0e5dc" if url==active else "white"};border:1px solid #abc2bb;border-radius:4px" {"aria-current=page" if url==active else ""}>{h(label)}</a>' for url, label in items)
pages = [('index.html', list(range(len(cards))))]
pages += [(f'hall-{i+1}.html', [j for j, c in enumerate(cards) if c['hall']==m]) for i, m in enumerate(seq)]
pages += [('hall-library.html', [j for j,c in enumerate(cards) if c['hall']=='library'])]
pages += [(f'kind-{k}.html', [j for j,c in enumerate(cards) if c['kind']==k]) for k in labels]
for filename, chosen in pages:
    filters = '<div class="filters"><div style="display:flex;gap:8px;flex-wrap:wrap;width:100%">'+navlinks(hall_links,filename)+'</div><div style="display:flex;gap:8px;flex-wrap:wrap">'+navlinks(kind_links,filename)+f'</div><span id="count">{len(chosen)} / {len(cards)} cards</span></div>'
    page = re.sub(r'<div class="filters">.*?<div class="grid">', filters+'<div class="grid">', html, flags=re.S)
    page = page.replace('CARDS', '\n'.join(card_html[j] for j in chosen))
    (O / filename).write_text(page, encoding='utf8')
css = re.search(r'<style>(.*?)</style>', html, re.S).group(1)
for i,c in enumerate(cards):
    prev,next_ = cards[(i-1)%len(cards)],cards[(i+1)%len(cards)]
    notes = f'<p class="notice">{h(c["note"])}</p>' if c['note'] else ''
    detail = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{h(c['title'])} · Swarm</title><style>{css}</style></head><body><nav><a href="index.html#{c['id']}">All artifacts</a><a href="view-{prev['id']}.html">← Previous</a><span>{i+1} / {len(cards)}</span><a href="view-{next_['id']}.html">Next →</a><a href="{c['image']}">Original image</a></nav><main><div class="eyebrow">{h(c['hall_name'])} / {labels[c['kind']]}</div><h1 style="font-size:42px">{h(c['title'])}</h1><img src="{c['image']}" alt="{h(c['title'])}" style="width:100%;max-height:78vh;object-fit:contain;background:#202631"><p>{h(c['description'])}</p><p class="caption">{h(c['capture'])}</p>{notes}<p><code>{h(c['token'])}</code></p></main></body></html>'''
    (O / f'view-{c["id"]}.html').write_text(detail, encoding='utf8')

# A labelled contact sheet uses unaltered native frames, resized only for layout.
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 19)
small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 15)
title_font = ImageFont.truetype('C:/Windows/Fonts/georgia.ttf', 42)
cols, cw, ch, top = 4, 450, 363, 130
sheet = Image.new('RGB', (cols*cw, top + math.ceil(len(cards)/cols)*ch + 30), '#f1f0e9')
draw = ImageDraw.Draw(sheet)
draw.text((24, 20), 'SWARM / ALL ARTIFACTS', font=title_font, fill='#18313b')
draw.text((26, 80), '25 saved placements + 4 temporary studies + 4 library scenes · Actual Godot captures · 10 Oct 2026', font=font, fill='#4c646a')
for i, c in enumerate(cards):
    x=(i%cols)*cw+10; y=top+(i//cols)*ch
    with Image.open(O / c['thumb']) as im:
        im=im.convert('RGB');im.thumbnail((430,286));sheet.paste(im,(x,y))
    draw.text((x,y+291),c['title'],font=font,fill='#18313b')
    badge = 'scene only / missing in hall' if c['loaded'] is False else labels[c['kind']]
    if c['token'] == 'boids_2d_in_3d': badge = 'panel not visible in capture'
    draw.text((x,y+319),c['hall_name']+' · '+badge,font=small,fill='#4c646a')
sheet.save(O/'contact-sheet.jpg',quality=92)
print(f'Published {len(cards)} cards, {len(rooms)} overheads; all 25 saved placements covered.')
