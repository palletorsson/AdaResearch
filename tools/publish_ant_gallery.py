"""Build a read-only image inventory of distinct ant and related trail exhibits."""
from pathlib import Path
import json, hashlib, shutil, html, re
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-ant-simulations'
OLD = ROOT / 'doc/book/iterations/2026-10-10-swarm-artifact-gallery/assets'
OUT.mkdir(parents=True, exist_ok=True)
(OUT/'assets').mkdir(exist_ok=True)

# Aliases loading the same scene are one entry, not extra simulations.
ROWS = [
 ('ant_colony_art', 'Ant Colony Art', 'Colonies', 'Yellow/orange ants, a round nest and a large yellow-green field.', 'library-ant_colony_art', 'Isolated scene · saved 10 October'),
 ('AntColonyV2', 'Ant Colony V2', 'Colonies', 'A colony across a broad sand-coloured terrain, with food areas and trails.', 'ant-v2-isolated', 'Isolated scene · saved 10 October'),
 ('ant_colony_optimization', 'Ant Colony Optimization', 'Colonies', 'Foraging ants, food sources and a coloured pheromone display.', '4-ant_colony_optimization', 'Museum capture · saved 10 October'),
 ('ant_colony_walk', 'Two trails underfoot', 'Colonies', 'The full-size tutorial colony: the carried point returns as spheres with home and food trails.', '5-ant_colony_walk', 'Museum capture · saved 10 October'),
 ('langton_toy', "Langton’s Ant — held toy", 'Cell rules', 'A small held grid: the ant changes a cell and turns according to its state.', None, 'Fresh isolated scene · 11 October'),
 ('langton_bench', "Langton’s Ant — bench", 'Cell rules', 'A standing yellow-and-black grid, already advanced before you arrive.', None, 'Fresh isolated scene · 11 October'),
 ('langton_swarm', 'Turmite Swarm', 'Cell rules', 'Several rule-following walkers paint a shared multicolour cell surface.', None, 'Fresh isolated scene · 11 October'),
 ('grid2d_langtons_ant', "Langton’s Ant — Grid2D", 'Cell rules', 'The Langton cartridge running on the general Grid2D substrate.', None, 'Fresh isolated scene · 11 October'),
 ('stigmergy_toy', 'Stigmergy — held toy', 'Trails and relatives', 'A few walkers deposit a fading signal on a small grid.', None, 'Fresh isolated scene · 11 October'),
 ('stigmergy_bench', 'Stigmergy — bench', 'Trails and relatives', 'The trail-writing process presented as a standing display.', None, 'Fresh isolated scene · 11 October'),
 ('stigmergy_grid', 'Stigmergy Grid', 'Trails and relatives', 'A compact floor tile showing deposited, diffusing and evaporating trails.', 'library-stigmergy_grid', 'Isolated scene · saved 10 October'),
 ('stigmergy_room', 'Stigmergy Room', 'Trails and relatives', 'A floor-scale trail network with several destination pillars; an ant/slime-mould-inspired model.', None, 'Fresh isolated scene · 11 October'),
 ('pheromone_terrain', 'Pheromone Terrain', 'Trails and relatives', 'The Randomness example: walkers alter a pheromone field and accumulate terrain height.', 'PHEROMONE', 'Installed artifact capture · saved 9 October'),
 ('PhysarumColony', 'Physarum Colony', 'Trails and relatives', 'The yellow branching simulation is slime-mould-inspired. Included as a visual relative, not an ant colony.', '1-PhysarumColony', 'Museum capture · saved 10 October'),
 ('ant_agent', 'Ant Agent', 'Components', 'An individual ant component. Its saved Physarum-hall placement was absent in the earlier hall capture, so this is an isolated portrait.', '1-ant_agent', 'Isolated component · saved 10 October'),
 ('simple_ant_v2', 'SimpleAnt — V2 component', 'Components', 'The capsule body inside Ant Colony V2. Shown without running its grid-dependent behaviour.', None, 'Fresh static component · 11 October'),
]

registry = {}
for f in (ROOT/'commons/artifacts/registry').glob('*.json'):
    try: registry.update(json.loads(f.read_text(encoding='utf-8-sig')).get('artifacts', {}))
    except (ValueError, AttributeError): pass
registry['simple_ant_v2'] = {'scene':'res://algorithms/swarmintelligence/ants_v2/SimpleAnt.tscn'}
plans = json.loads((ROOT/'commons/data/museum/em_plan.json').read_text(encoding='utf-8'))['plans']
maps = {}
for f in (ROOT/'commons/maps').glob('*/map_data.json'):
    try: maps[f.parent.name] = json.loads(f.read_text(encoding='utf-8-sig'))
    except ValueError: pass

def base(token): return re.split(r'[:#]', token)[0]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def esc(s): return html.escape(str(s), quote=True)
records = []
for i, (token, title, category, note, saved, origin) in enumerate(ROWS, 1):
    scene = registry[token]['scene']
    aliases = sorted(k for k,v in registry.items() if v.get('scene') == scene)
    # Substrate scene is shared by many cartridges: keep only this ant cartridge.
    if token == 'grid2d_langtons_ant': aliases = [token]
    spine = [f"{p.get('sequence')} / {p.get('map')}" for p in plans
             if any(base(a.get('token','')) in aliases for a in p.get('artifacts',[]))]
    placements = [name for name,d in maps.items()
                  if any(base(str(t)) in aliases for row in d.get('layers',{}).get('interactables',[]) for t in row)]
    image = OUT/'assets'/f'{token}.png'
    original = None
    if saved:
        original = (ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Pheromone/museum/installed-attract.png') if saved == 'PHEROMONE' else OLD/f'{saved}.png'
        shutil.copy2(original, image)
    assert image.exists(), image
    if token == 'ant_colony_art': location = 'Swarm gallery / Gallery_SwarmIntelligence'
    elif spine: location = ' · '.join(spine)
    elif token in ['ant_agent','simple_ant_v2']: location = 'Colony component library'
    elif token == 'grid2d_langtons_ant': location = 'Test_Substrates / Test_Substrates_Placed'
    elif token.startswith('langton'): location = 'Cellular Automata library / alternate layouts'
    elif token.startswith('stigmergy'): location = 'Trail-simulation library / alternate layouts'
    else: location = 'Library'
    receipt = OUT/'assets'/f'{token}.json'
    records.append(dict(number=i,token=token,title=title,category=category,note=note,scene=scene,
        aliases=aliases,spine=spine,placements=placements,location=location,origin=origin,
        image=f'assets/{token}.png',image_sha256=sha(image),
        original_image=str(original.relative_to(ROOT)).replace('\\','/') if original else None,
        capture_receipt=json.loads(receipt.read_text(encoding='utf-8')) if receipt.exists() else None))

style = '''body{margin:0;background:#f5f2e9;color:#202320;font:17px/1.5 system-ui,sans-serif}main{max-width:1400px;margin:auto;padding:45px 28px}h1{font:clamp(36px,5vw,70px)/1.05 Georgia,serif;margin:12px 0 20px}h2{font:32px Georgia,serif;margin:55px 0 22px}h3{font-size:22px;margin:6px 0}p{max-width:900px}.eyebrow,.tag{font-size:12px;letter-spacing:.1em;text-transform:uppercase}.eyebrow{color:#735332}nav{display:flex;gap:12px;flex-wrap:wrap;margin:28px 0}a{color:inherit;text-underline-offset:4px}nav a,.button{display:inline-block;padding:10px 16px;border:1px solid #bbb4a7;border-radius:25px;text-decoration:none;background:#fffaf3}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:25px}.card{border:1px solid #d2ccbf;background:#fffdf7;border-radius:6px;overflow:hidden}.card img{width:100%;aspect-ratio:3/2;object-fit:contain;background:#151923;display:block}.copy{padding:20px 22px}.num{color:#9c3b67;margin-right:8px}.meta{font-size:13px;color:#5e645b}.location{font-size:14px;overflow-wrap:anywhere}code{font-size:12px;overflow-wrap:anywhere}details{font-size:13px;margin-top:15px}ul{padding-left:20px}.hero{width:100%;max-height:78vh;object-fit:contain;background:#151923}.footer{border-top:1px solid #cfc8bc;margin-top:50px;padding-top:25px;font-size:14px}@media(max-width:750px){main{padding:25px 15px}.grid{grid-template-columns:1fr}}'''
def page(title, body): return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{esc(title)}</title><style>{style}</style><main>{body}</main></html>'
groups = list(dict.fromkeys(r['category'] for r in records))
slug = lambda s: s.lower().replace(' ','-')
body = '<div class="eyebrow">Endless Museum · image inventory · 11 October 2026</div><h1>Ants, trails,<br>and things mistaken for ants.</h1>'
body += '<p>One image for each distinct colony or ant-rule example, followed by related trail systems and the individual ant components. Eight fresh Godot previews sit alongside eight earlier project captures. The captions identify where each image came from.</p>'
body += '<nav>'+''.join(f'<a href="#{slug(g)}">{esc(g)}</a>' for g in groups)+'<a href="assets/all-examples.jpg">All 16 on one sheet</a><a href="INVENTORY.md">Text inventory</a></nav>'
for group in groups:
    body += f'<h2 id="{slug(group)}">{esc(group)}</h2><div class="grid">'
    for r in [x for x in records if x['category']==group]:
        details = '<details><summary>Scene, names and saved placements</summary><p><code>'+esc(r['scene'])+'</code></p><p>Names: '+esc(', '.join(r['aliases']))+'</p><ul>'+''.join('<li>'+esc(x)+'</li>' for x in r['placements'])+'</ul></details>'
        body += f'<article class="card" id="{esc(r["token"])}"><a href="{esc(r["token"])}.html"><img loading="lazy" src="{r["image"]}" alt="{esc(r["title"])}"></a><div class="copy"><div class="tag">{esc(r["category"])}</div><h3><span class="num">{r["number"]:02}</span>{esc(r["title"])}</h3><p>{esc(r["note"])}</p><p class="location"><strong>Location:</strong> {esc(r["location"])}</p><p class="meta">{esc(r["origin"])}</p>{details}</div></article>'
    body += '</div>'
body += '<div class="footer"><p>Scope: distinct registered ant/colony/Langton/turmite scenes, their named pheromone/stigmergy relatives, and two individual ant components. Physarum appears as a labelled visual relative. The two Ant Colony V2 names are collapsed into one entry. Review-package copies and backups are not extra exhibits.</p><p>These are rendered images, not a new behaviour or headset test. Older captures preserve their earlier appearance; no museum code, placement, tutorial or reflective text was changed for this gallery. Grid2D explicitly selects its Langton cartridge; SimpleAnt is a static portrait because it needs a colony grid.</p><a href="manifest.json">Image provenance and placements</a></div>'
(OUT/'index.html').write_text(page('Ant simulations — Endless Museum',body),encoding='utf-8')
for i,r in enumerate(records):
    prev=records[(i-1)%len(records)];nxt=records[(i+1)%len(records)]
    text=f'<nav><a href="index.html#{r["token"]}">All examples</a><a href="{prev["token"]}.html">← Previous</a><a href="{nxt["token"]}.html">Next →</a></nav><div class="eyebrow">{r["number"]:02} / 16 · {esc(r["category"])}</div><h1>{esc(r["title"])}</h1><a href="{r["image"]}"><img class="hero" src="{r["image"]}" alt="{esc(r["title"])}"></a><p>{esc(r["note"])}</p><p><strong>Location:</strong> {esc(r["location"])}</p><p class="meta">{esc(r["origin"])}</p><code>{esc(r["scene"])}</code>'
    (OUT/f'{r["token"]}.html').write_text(page(r['title'],text),encoding='utf-8')

fontpath=Path('C:/Windows/Fonts/segoeui.ttf')
boldpath=Path('C:/Windows/Fonts/segoeuib.ttf')
font=ImageFont.truetype(str(fontpath),21);bold=ImageFont.truetype(str(boldpath),25)
def sheet(rows, name):
    cols=4;w=600;h=470;top=90
    canvas=Image.new('RGB',(cols*w,((len(rows)+cols-1)//cols)*h+top),(245,242,233))
    draw=ImageDraw.Draw(canvas)
    draw.text((24,20),'ENDLESS MUSEUM / ANTS & TRAILS',font=ImageFont.truetype(str(boldpath),36),fill=(32,35,32))
    for j,r in enumerate(rows):
        x=(j%cols)*w;y=top+(j//cols)*h
        photo=ImageOps.contain(Image.open(OUT/r['image']).convert('RGB'),(w-24,360))
        draw.rectangle((x+12,y,x+w-12,y+360),fill=(21,25,35))
        canvas.paste(photo,(x+12+(w-24-photo.width)//2,y+(360-photo.height)//2))
        draw.text((x+15,y+370),f'{r["number"]:02}  {r["title"]}',font=bold,fill=(32,35,32))
        draw.text((x+15,y+407),r['category']+' / '+r['token'],font=font,fill=(90,80,73))
    canvas.save(OUT/'assets'/name,quality=93)
sheet(records,'all-examples.jpg')
sheet(records[:8],'colonies-and-cell-rules.jpg')
sheet(records[8:],'trails-and-components.jpg')
(OUT/'manifest.json').write_text(json.dumps(records,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
md='# Ant simulations and relatives\n\n16 distinct views; 8 fresh Godot previews and 8 earlier project captures. Image inventory only; no runtime or content edits.\n'
for r in records:
    md+=f'\n## {r["number"]:02}. {r["title"]}\n\n{r["note"]}\n\n- Location: {r["location"]}\n- Image: {r["origin"]}\n- Scene: `{r["scene"]}`\n\n![{r["title"]}]({r["image"]})\n'
(OUT/'INVENTORY.md').write_text(md,encoding='utf-8')
print('Published',len(records),'views; fresh receipts',sum(r['capture_receipt'] is not None for r in records))
