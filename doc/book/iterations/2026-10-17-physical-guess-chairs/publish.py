from pathlib import Path
import json, shutil, html, hashlib, re

here=Path(__file__).parent
root=here.parents[3]
run=root/'ada_run/encounter_pilot/Random_Entropies/physical-guess-chairs'
report=json.loads((run/'report.json').read_text(encoding='utf-8'))
assert report['passed'] and not report['failures']
log=(run/'engine.log').read_text(encoding='utf-8')
assert 'SCRIPT ERROR' not in log and '\nERROR:' not in log
(here/'native').mkdir(exist_ok=True)
for p in list(run.glob('*.png'))+[run/'report.json',run/'source_manifest.json']:
    shutil.copy2(p,here/'native'/p.name)
sources=['commons/artifacts/ordinary_entropies/'+name for name in ['physical_chair.gd','one_guess.gd','guess_table.gd','guess_model.gd','chair_reference.gd']]+['commons/movement/pushable_walk.gd','commons/scenes/endless_museum.gd','commons/artifacts/registry/ordinary_entropies.json']
hashes={}
for relative in sources:
    p=root/relative;dest=here/'sources'/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
    hashes[relative]=hashlib.sha256(p.read_bytes()).hexdigest()
for name in ['Random_Entropies','Random_Entropy']:
    path=root/'commons/maps'/name/'final.md'
    dest=here/'after'/name;dest.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest/'final.md')
    before=(here/'before/commons/maps'/name/'final.md').read_text(encoding='utf-8')
    assert re.findall(r'<!-- @([^>]+) -->',before)==re.findall(r'<!-- @([^>]+) -->',path.read_text(encoding='utf-8'))
before_map=json.loads((here/'before/commons/maps/Random_Entropies/map_data.json').read_text(encoding='utf-8'))
after_map=json.loads((root/'commons/maps/Random_Entropies/map_data.json').read_text(encoding='utf-8'))
def without_layout(o):
    if isinstance(o,dict):return {k:without_layout(v) for k,v in o.items() if k!='layout'}
    if isinstance(o,list):return [without_layout(v) for v in o]
    return o
assert without_layout(before_map)==without_layout(after_map)
assert (here/'before/commons/data/museum/em_plan.json').read_bytes()==(root/'commons/data/museum/em_plan.json').read_bytes()
(here/'verification.json').write_text(json.dumps({'checks':len(report['checks']),'native_passed':True,'no_engine_errors':True,'room_final_order_unchanged':True,'placements_unchanged':True,'headset_test':False,'sources':hashes},indent=2)+'\n',encoding='utf-8')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Min-entropy — chairs in a pyramid</title><style>
*{box-sizing:border-box}body{margin:0;background:#ece8de;color:#28313c;font:17px/1.6 system-ui,sans-serif}main{max-width:1400px;margin:auto;padding:36px}h1{font:clamp(30px,4vw,58px)/1.15 Georgia,serif;max-width:950px}h2{font:30px/1.2 Georgia,serif}a{color:#285f69}header p{max-width:900px}.label{letter-spacing:.16em;font-size:12px;color:#825b73}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}img{width:100%;display:block}figcaption{padding:12px 0;max-width:700px}section{margin:40px 0}.note{background:#ded7e4;padding:20px;max-width:1000px}table{border-collapse:collapse;width:100%;max-width:900px}th,td{text-align:left;padding:12px;border-bottom:1px solid #bebbad}footer{border-top:1px solid #bebbad;padding:22px 0;font-size:14px}@media(max-width:850px){main{padding:20px}.pair{grid-template-columns:1fr}}
</style><main><header><div class="label">ADA RESEARCH · 17 OCTOBER 2026 · ENTROPY TYPES</div><h1>A pyramid can fall.<br>The colour answer can stay.</h1><p>Four pyramids, each made of sixteen full-size chairs. The same 9 + 4 + 2 + 1 arrangement carries four different category distributions. Grip a support, walk into the stack, or build another arrangement.</p></header>
<section class="pair"><figure><a href="native/pink-pyramid.png"><img src="native/pink-pyramid.png" alt="The all-pink chair pyramid standing on the hall floor"></a><figcaption><strong>Before intervention.</strong> Real Godot physics supports the chairs; no body is frozen in place.</figcaption></figure><figure><a href="native/pink-after-walking.png"><img src="native/pink-after-walking.png" alt="Chairs displaced after a supplied walking collision"></a><figcaption><strong>After walking contact.</strong> A native test disturbs the stack. These are actual engine captures, not a prescribed collapse animation.</figcaption></figure></section>
<section><h2>What does the number count?</h2><table><thead><tr><th>Group</th><th>Inventory</th><th>Best guess</th><th>Min-entropy</th></tr></thead><tbody><tr><td>A</td><td>8 pink · 8 black</td><td>50%</td><td>1 bit</td></tr><tr><td>B</td><td>8 pink · 4 black · 4 black with arms</td><td>50%</td><td>1 bit</td></tr><tr><td>C</td><td>12 pink · 4 black</td><td>75%</td><td>0.415 bits</td></tr><tr><td>D</td><td>16 pink</td><td>100%</td><td>0 bits</td></tr></tbody></table><p class="note">The record is chair type, and DRAW selects uniformly among a group’s sixteen labelled IDs. Each chair keeps its group when it moves. A pile does not change that distribution. A and B have the same best guess, while Shannon entropy distinguishes their 1 versus 1.5 bits of average category uncertainty.</p></section>
<section><h2>Try it in the hall</h2><p>In VR, grip a chair and release it. On desktop, right-click to carry or drop; the wheel changes carry distance. Walk into a chair to nudge it. The legs, seats, backs and armrests have their own collision shapes, so objects can support and catch on one another. RESET rebuilds that group after held chairs are released.</p><p>DRAW marks a chair without moving it. CHANGE ONE alters a category while retaining the arrangement. Research receipts preserve poses, motion and generator state; later physics may diverge across engines or machines.</p><figure><a href="native/four-pyramids.png"><img src="native/four-pyramids.png" alt="Four chair pyramids arranged around the central walking route" loading="lazy"></a><figcaption>Same seven-stop room sequence. Four pyramids occupy the last bay, with the central route kept open.</figcaption></figure></section>
<section><h2>The encounter enters the text</h2><p>The final now follows a seat becoming another chair’s support, then asks what a collapse leaves unchanged. The tutorial explains physical interaction and the declared draw rule. The writing wall and plan follow the same encounter.</p><p><a href="before/commons/maps/Random_Entropies/final.md">Previous complete final</a> · <a href="after/Random_Entropies/final.md">Revised complete final</a> · <a href="/book-review/commons/maps/Random_Entropies/tutorial.md">Current tutorial</a> · <a href="/long-museum/writing-wall?map=Random_Entropies">Writing wall</a></p></section>
<footer>120 native checks pass: standing pyramids, physical contacts, desktop carry, supplied XR Tools grab driver, reset guards, category invariants, receipts, seeded replay, controls and central route. <a href="native/report.json">Native report</a> · <a href="verification.json">Source record</a>. These checks do not establish headset comfort, frame rate or whether a visitor discovers the interaction. The 48-value seed bench remains the first research pilot.</footer></main></html>'''
page=page.replace('120 native checks',f"{len(report['checks'])} native checks")
(here/'index.html').write_text(page,encoding='utf-8')
print('Published pyramid review with native captures and unchanged room/final order.')
