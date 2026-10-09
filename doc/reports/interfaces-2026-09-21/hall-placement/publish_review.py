"""Publish hall evidence with measured positions and the limits of the checks."""
from pathlib import Path
from collections import Counter
import difflib, hashlib, html, json, re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT/'doc/book/iterations/2026-09-21-interface-hall-placement-review'
PREVIOUS = ROOT/'doc/book/iterations/2026-09-21-interface-edge-console-review/index.html'
DEST.mkdir(parents=True, exist_ok=True)
reports = {}
for case in ('grammar', 'fitness', 'edge'):
    report = json.loads((HERE/'after'/case/'report.json').read_text(encoding='utf-8'))
    assert report['passed'] and not report['failures'], (case, report['failures'])
    reports[case] = report
    for path in (HERE/'after'/case).glob('*.png'):
        shutil.copy2(path, DEST/f'{case}-{path.name}')
    shutil.copy2(HERE/'after'/case/'report.json', DEST/f'{case}-checks.json')
shutil.copy2(HERE/'before/grammar/operating.png', DEST/'grammar-before.png')
shutil.copy2(HERE/'before/grammar/report.json', DEST/'grammar-before-checks.json')
shutil.copy2(HERE/'README.md', DEST/'implementation.md')
old_map = json.loads((HERE/'source-before/LSystems_Grammar_Lab.json').read_text(encoding='utf-8'))
new_map = json.loads((ROOT/'commons/maps/LSystems_Grammar_Lab/map_data.json').read_text(encoding='utf-8'))
tokens = lambda d: Counter(str(t) for row in d['layers']['interactables'] for t in row if str(t).strip())
assert tokens(old_map) == tokens(new_map)
assert {k:v for k,v in old_map.items() if k!='layers'} == {k:v for k,v in new_map.items() if k!='layers'}
assert {k:v for k,v in old_map['layers'].items() if k!='interactables'} == {k:v for k,v in new_map['layers'].items() if k!='interactables'}
files = ['commons/artifacts/grammar_provenance/grammar_provenance.gd',
         'commons/maps/LSystems_Grammar_Lab/map_data.json',
         'commons/testing/probe_physical_console_halls.gd',
         'commons/artifacts/fitness_landscape_politics/fitness_landscape_politics.gd',
         'commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd']
hashes = {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in files}
(DEST/'source-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
for old, current in [('grammar_provenance.gd.txt',files[0]),('LSystems_Grammar_Lab.json',files[1])]:
    difference = ''.join(difflib.unified_diff((HERE/'source-before'/old).read_text(encoding='utf-8').splitlines(True),(ROOT/current).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+current,tofile='after/'+current))
    (HERE/(old+'.diff')).write_text(difference,encoding='utf-8')
total = sum(len(r['checks']) for r in reports.values())
rows = ''
names = {'grammar':'Grammar Lab','fitness':'Particle Swarm Optimization','edge':'Edge of Chaos'}
for case, r in reports.items():
    controls = r['controls']
    low, high = min(c['height'] for c in controls), max(c['height'] for c in controls)
    reach = max(c['horizontal_distance'] for c in controls)
    rows += f'<tr><th>{names[case]}</th><td>{low:.2f}–{high:.2f} m</td><td>{reach:.2f} m</td><td><a href="{case}-checks.json">{len(r["checks"])} passed</a></td></tr>'
previous = PREVIOUS.read_text(encoding='utf-8')
css = re.search(r'<style>(.*?)</style>',previous,re.S).group(1)
css += 'table{width:100%;border-collapse:collapse}th,td{padding:14px 10px;text-align:left;border-bottom:1px solid #ccc}.table-scroll{overflow-x:auto}img{height:auto}'
def image(name, caption):
    return f'<figure><a href="{name}"><img src="{name}" width="1600" height="1200" alt="{html.escape(caption,quote=True)}"></a><figcaption>{caption}</figcaption></figure>'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A place to stand · Ada Research</title><style>{css}</style></head><body>
<header><div class="eyebrow">Ada Research · Physical interfaces · 21 September 2026</div><h1>A place<br>to stand.</h1><p class="lead">The console belongs to a room. Three live museum checks connect the hand, the floor and the work.</p><p><a href="../2026-09-21-interface-edge-console-review/index.html">Previous: who can move the handle?</a></p><div class="metrics"><div class="metric"><strong>3 halls</strong><span>Actual museum geometry</span></div><div class="metric"><strong>3 plaques</strong><span>Recovered from beneath the floor</span></div><div class="metric"><strong>{total} checks</strong><span>Placement, rays, walking and grabs</span></div></div></header>
<main><section><h2>The controls worked. The evidence was buried.</h2><p>Grammar Lab's three provenance plaques were below the floor. Their rules were present in the source, but unavailable to the visitor. The plaques now tilt toward the reader in front of the forms, which stand on shallow bases. The study also moves away from the wall, and the neighbouring tree moves alongside it.</p><div class="comparison">{image('grammar-before.png','Before: only the top edges of the three buried plaques were visible.')}{image('grammar-operating.png','After: each form has its evidence above the floor; the neighbouring tree is to the right.')}</div><p>Every artifact remains in the room. The grammar rules, generated line geometry and manuscript are preserved; the samples are raised 30 cm. These views use the same eye position relative to the console; the study has moved one metre within the hall.</p>{image('grammar-plaques-detail.png','A closer camera view from the same standing position. These are flat text surfaces, now above the floor.')}</section>
<section><h2>Floor, hand, consequence</h2><div class="table-scroll"><table><thead><tr><th>Hall</th><th>Control heights</th><th>Farthest horizontal distance</th><th>Checks</th></tr></thead><tbody>{rows}</tbody></table></div><p>Measurements use a position 50 cm in front of the console centre. The distances are measured from that floor position, not from a shoulder. They describe the layout; they do not certify comfortable arm reach for every body.</p><p>A 1.7 m standing capsule fits at each station. The museum's CharacterBody walks the final metre on supported floor. Every button and both slider endpoints have clear interaction rays, and actual XR Tools grabs move and release the sliders under the halls' authored rotations.</p></section>
<section><h2>The landscape stays in view</h2>{image('fitness-operating.png','Particle Swarm Optimization: controls in front of the floor landscape, with the scoring rule beyond it.')}<p>The existing placement already works at metre scale. No relocation was needed. The tests cover the four choices, inertia rail and reset position.</p><p><a href="/necklace/thread?map=SwarmIntelligence_Particle_Swarm_Optimization&amp;role=primary">Open the swarm hall</a></p></section>
<section><h2>Enter the bay from the side</h2>{image('edge-approach.png','Edge of Chaos: approaching along the level bay beside the terrace.')}{image('edge-controls.png','The console in its actual hall, facing the two fields.')}<p>The central terrace prevents a level approach straight from the west. Both side approaches along the bay are clear. The existing floor position and 270-degree orientation are retained.</p><p><a href="/necklace/thread?map=QFEP_Edge_Of_Chaos&amp;role=primary">Open the edge-of-chaos hall</a></p></section>
<section><h2>Carry the check to the next work</h2><p>The reusable probe discovers physical controls, measures them against the live floor, tests front and side approaches, checks structural obstruction, and drives the real grab mechanism. It can distinguish a problem in the console from a problem in its placement.</p><p>These are desktop Godot captures inside the museum. Operating views use a wide camera; detail views use a narrower view from the same eye position. Small lettering, tracked-hand comfort, shorter and seated visitors, raised or scaled exhibit mounts, and standalone Quest performance still need testing. The check covers the final approach, not an entire visit from entrance to exit.</p><p><a href="implementation.md">Implementation and reproduction</a> · <a href="source-hashes.json">Source hashes</a> · <a href="grammar-before-checks.json">Original buried-plate findings</a></p></section></main><footer>Physical controls · Flat text · A supported place for the body</footer></body></html>'''
(DEST/'index.html').write_text(page,encoding='utf-8')
link='<p><a href="../2026-09-21-interface-hall-placement-review/index.html">Continue: a place to stand — inside the actual halls</a></p>'
if link not in previous: PREVIOUS.write_text(previous.replace('<footer>','<footer>'+link),encoding='utf-8')
print(DEST/'index.html')
