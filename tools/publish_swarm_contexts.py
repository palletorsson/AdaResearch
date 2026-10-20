"""Publish proposed Swarm connections beside the unchanged tested lessons."""
from pathlib import Path
import hashlib
import json
import shutil
import markdown

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-swarms-fish-drones-and-hordes'
C=R/'doc/book/iterations/2026-10-10-swarm-complete-readings'
sequence=json.loads((R/'commons/maps/sequences/swarmintelligence.json').read_text(encoding='utf8'))['sequences']['swarmintelligence']['maps']
names=['Physarum','Flow Fields','Boids','Agent-Based Modeling','Ant Colony','Particle Swarm','Population Support']
captions=['A trace left in the ground','Directions supplied to the moving points','The existing flock and its boundaries','The point carries a changing state','Two trails underfoot','A position remembered for its score','What keeps the population present']
hashes={str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for hall in sequence for p in [R/'commons/maps'/hall/'tutorial.md',R/'commons/maps'/hall/'final.md']}
hashes['commons/maps/sequences/swarmintelligence.json']=hashlib.sha256((R/'commons/maps/sequences/swarmintelligence.json').read_bytes()).hexdigest()
(O/'assets').mkdir(exist_ok=True)
cards=[]
for i,(hall,name,caption) in enumerate(zip(sequence,names,captions),1):
    shutil.copy2(C/'assets'/f'{i}.png',O/'assets'/f'{i}.png')
    cards.append(f'<figure><a href="../2026-10-10-swarm-complete-readings/tutorial.html#{hall}"><img loading="lazy" src="assets/{i}.png" alt="{name}: existing museum capture"></a><figcaption><b>{i}. {name}</b><br>{caption}<br><small>Existing capture; not a picture of the proposed extension.</small></figcaption></figure>')
text=(O/'PROPOSAL.md').read_text(encoding='utf8')
body=markdown.markdown(text,extensions=['extra','sane_lists'])
gallery='<section id="halls"><h2>The existing encounters</h2><p>Previously captured museum images. Select a hall to read its current tutorial.</p><div class="cards">'+''.join(cards)+'</div></section>'
body=body.replace('<h2>Different kinds of swarm</h2>',gallery+'<h2>Different kinds of swarm</h2>')
css='''*{box-sizing:border-box}body{margin:0;background:#f3f1e9;color:#18393b;font:18px/1.65 Georgia,serif}nav{background:#173c40;padding:15px 24px;font:14px/1.5 system-ui}nav a{color:#e0f3ec;margin-right:24px}main{max-width:1150px;margin:38px auto;padding:0 24px 80px}h1{font-size:46px;line-height:1.15}h2{margin-top:45px}h3{margin-top:30px}a{color:#136778}table{display:block;overflow:auto;border-collapse:collapse;font:15px/1.55 system-ui}th,td{padding:12px;border-bottom:1px solid #afc5bf;text-align:left;vertical-align:top}.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:22px}figure{margin:0;background:white;padding:14px}img{width:100%;height:auto;display:block}figcaption{font:15px/1.5 system-ui;margin-top:12px}small{color:#566667}code{overflow-wrap:anywhere} @media(max-width:700px){h1{font-size:34px}.cards{grid-template-columns:1fr}}'''
(O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Swarms in nature games and art</title><style>'+css+'</style></head><body><nav><a href="#halls">Existing halls</a><a href="PROPOSAL.md">Editable proposal</a><a href="../2026-10-10-swarm-complete-readings/index.html">Tested sequence</a><a href="https://natureofcode.com/autonomous-agents/">Nature of Code</a></nav><main>'+body+'</main></body></html>',encoding='utf8')
(O/'scope.json').write_text(json.dumps({'status':'Research and proposals only; no changes to lessons, hall order, or museum runtime.','source_texts_sha256':hashes,'image_source':'Existing complete-readings assets, captured before this proposal.','sources_checked':'2026-10-10','new_runtime_tests':False},indent=2)+'\n',encoding='utf8')
print('Published Swarm research proposal, seven existing hall images, cited nature/game/art references. Canonical lessons unchanged.')
