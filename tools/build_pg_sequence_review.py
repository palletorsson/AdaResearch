"""Publishable first-traverse review, gated by fresh passing Godot evidence."""
from pathlib import Path
import json,hashlib,shutil,re,html
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';E=R/'doc/space/pg-sequence-2026-09-15'
ROWS=[('PG_Branching_Growth','pg-branching-growth','One nearest invitation','Predict one nearest target; distinguish record count from distinct positions.'),('PG_Percolation_Network','pg-percolation','Touching is not enough','Compare face and corner contact, then follow flow through a finite lattice.'),('PG_Caves_Mazes','pg-caves-mazes','A route needs room','Compare the cave’s carving centres with a maze’s backtracking stack.'),('PG_Sculpted_Forms','pg-sculpted-forms','What did the sample keep?','Freeze twelve falling cubes, resample their centres, reveal a Boolean cut.'),('PG_Mirrored_Patterns','pg-mirrored-patterns','A repeated image, another way through','Hold a cellular field; separately compare a tree, cycles and severed connections.')]
def dump(p,j):p.write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
css='''*{box-sizing:border-box}body{margin:0;background:#13212a;color:#eee9df;font:18px/1.7 system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:32px 24px 80px}a{color:#f4b8c7}nav{display:flex;gap:20px;flex-wrap:wrap;font-size:14px}h1{font:clamp(36px,6vw,70px)/1.1 Georgia,serif;max-width:900px}h2{font:32px/1.2 Georgia,serif;margin-top:48px}h3{font:24px/1.3 Georgia,serif}.lead{font:25px/1.5 Georgia,serif;max-width:860px}.date,figcaption{color:#b2c0c5;font-size:14px}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:22px}.card{border:1px solid #51606b;border-radius:6px;padding:24px;background:#1b303a}.card h2{margin:0 0 16px}img{width:100%;height:auto;display:block}figure{margin:30px 0}figcaption{margin-top:10px}pre{background:#081720;padding:20px;overflow:auto}code{font-size:.9em}details{border-top:1px solid #51606b;padding:24px 0}summary{cursor:pointer;font-size:24px}article{max-width:790px;margin:30px auto}p{max-width:880px}.tag{font-size:13px;color:#a9d8c9}.table{overflow:auto}table{border-collapse:collapse;width:100%}td,th{padding:15px;border-bottom:1px solid #51606b;text-align:left;vertical-align:top}small{color:#b2c0c5}'''
def page(title,body):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+' · Ada Research</title><style>'+css+'</style><main><nav><a href="pg-sequence.html">Procedural generation</a><a href="pg-learning-arc.html">Learning arc</a><a href="spine-iteration.html">Iteration method</a><a href="/museum-progress?sequence=proceduralgeneration">Museum progress</a></nav>'+body+'</main></html>'
assets=[];records=[];roles=json.loads((R/'commons/data/artifact_roles.json').read_text())['roles']
for name,slug,title,argument in ROWS:
 run=R/f'ada_run/pg-review-2026-09-15/{name}';receipt=json.loads((run/'run.json').read_text())
 assert receipt['exit']==0 and not receipt['failures'] and receipt['sources_unchanged'] and receipt['original_hand_unchanged'],name
 assert all(sha(R/p)==h for p,h in receipt['source_sha256'].items()),'stale receipt '+name
 dest=E/name;dest.mkdir(exist_ok=True)
 for source,newname in [(run/'run.json','receipt.json'),(run/name/'probe_ca_edge_live.json','runtime-report.json'),(run/name/'engine.log','engine.log')]:shutil.copyfile(source,dest/newname)
 primary=[t for t,role in roles[name].items() if role=='primary']
 records.append({'map':name,'url':slug+'.html','title':title,'primary':primary,'checks':receipt['checks'],'headset_verified':False})
 figures=''
 for p in sorted((run/name).glob('*.png')):
  out=slug+'-'+p.name;shutil.copyfile(p,O/out);assets.append(out)
  figures+='<figure><img loading="lazy" src="'+out+'" alt="Godot museum: '+html.escape(title)+' — '+p.stem+'"><figcaption>Actual Godot capture · '+p.stem+'. Synthetic desktop review; headset review remains pending.</figcaption></figure>'
 book=markdown.markdown((R/f'commons/maps/{name}/final.md').read_text(),extensions=['fenced_code'])
 links=[]
 for kind in ['final','technical','critical']:
  for before in [False,True]:
   source=(E/'before' if before else R)/f'commons/maps/{name}/{kind}.md'
   out=slug+('-previous-' if before else '-')+kind+'.md';shutil.copyfile(source,O/out);assets.append(out)
   links.append('<a href="'+out+'">'+('Previous ' if before else 'Current ')+kind+'</a>')
 out=slug+'-verification.json';shutil.copyfile(run/'run.json',O/out);assets.append(out)
 body='<p class="date">First traverse · 15 September 2026</p><h1>'+title+'</h1><p class="lead">'+argument+'</p><p class="tag">'+str(receipt['checks'])+' passed desktop checks · '+str(len(primary))+' primary artifact'+('s' if len(primary)>1 else '')+'</p><p><a href="/necklace/thread?map='+name+'&role=primary">Open the primary artifacts</a></p>'
 body+='<details><summary>Read this hall’s book passage</summary><article>'+book+'</article></details>'+figures
 body+='<h2>What is verified</h2><p>Actual scene loading, desktop-pointer button presses, algorithm comparisons, floor support and the museum’s onward passage. The original saved hand was unchanged. Human headset reach, comfort and every generated interior remain unverified. Captures used muted audio and recorded the pre-existing audio-bus UID warning.</p><p><a href="'+out+'">Runtime receipt</a></p><p>'+' · '.join(links)+'</p>'
 (O/(slug+'.html')).write_text(page(title,body),encoding='utf-8');assets.append(slug+'.html')
body='<p class="date">Seven halls · first traverse · 15 September 2026</p><h1>What can a generator make room for?</h1><p class="lead">Select → guide → branch → connect → inhabit → materialize → compose.</p><p>The remaining five halls now have controlled encounters and book passages tied to their primary artifacts. The original collection is retained. Genetic Evolution and Space Colonization lead into this work with their earlier illustrated reviews.</p><p><a href="genetic-evolution.html">1 · Genetic Evolution</a> · <a href="space-colonization.html">2 · Space Colonization</a></p><div class="cards">'
for i,record in enumerate(records):
 body+='<section class="card"><p class="tag">HALL '+str(i+3)+'</p><h2><a href="'+record['url']+'">'+record['title']+'</a></h2><p>'+ROWS[i][3]+'</p><small>'+str(record['checks'])+' desktop checks · '+str(len(record['primary']))+' primary artifacts</small></section>'
body+='</div><h2>The thread we can now test</h2><p>A criterion selects what continues. A target field guides where construction reaches. A branch policy decides who can respond again. A neighbourhood admits some connections. Carving gives those relations width; sampling and cutting establish material boundaries. Copying and network construction compose the available tools.</p><p>Each capability creates a different place for the question: <em>what bodies are possible here, and what would we have to change?</em> The text stays with the operation before asking what its abstraction leaves behind.</p><h2>Keep these questions for the return</h2><ul><li>Make a full human headset pass: reach, scale, comfort and actual interior passage.</li><li>Extend the six-seed graph into secondary growth without losing a legible comparison.</li><li>Compare centre-based voxelization with a sampler that respects cube rotation.</li><li>Decide when coincident growth records are useful history and when to suppress them.</li><li>Give the retained rear structures clearer viewing approaches; their raised cells are not all certified accessible decks.</li></ul><p>All five source maps retain their earlier structure cells, with explicit support covers over the inherited zeros after artifact relocation. The larger surrounds and the tested crossing routes are staging decisions. No blanket meaning for zero was introduced.</p><p><a href="pg-sequence-verification.json">Combined verification index</a></p>'
(O/'pg-sequence.html').write_text(page('What can a generator make room for?',body),encoding='utf-8');assets.append('pg-sequence.html')
dump(O/'pg-sequence-verification.json',records);assets.append('pg-sequence-verification.json')
arc='''# What can a generator make room for?

First traverse · 15 September 2026. All seven active halls have developed encounters; the remaining five are documented in [the illustrated sequence review](pg-sequence.html). The supplemental Chamber_ProcGen remains outside this seven-hall route.

**Select → guide → branch → connect → inhabit → materialize → compose.**

| Hall | New capability | Main comparison |
|---|---|---|
| [Genetic Evolution](genetic-evolution.html) | Select represented forms | A body and its incomplete score |
| [Space Colonization](space-colonization.html) | Assign demands and sum directions | A strand and persistent sites that can fork |
'''
for i,(name,slug,title,argument) in enumerate(ROWS):arc+='| ['+name.removeprefix('PG_').replace('_',' ')+']('+slug+'.html) | '+title+' | '+argument+' |\n'
arc+='''
The map, tutorial roles, critical question and book now agree on the principal encounters. One primary was a scaffold, never a quota: Caves/Mazes, Sculpted Forms and Mirrored Patterns each have two primary book artifacts. Existing useful secondary works are retained.

The source review corrected a fixed-angle-tree description into nearest-target growth, a 2D percolation story into this six-neighbour 3D lattice, and a generic stacking story into centre-based sampling. Cave/BSP UI attachments and the membrane’s script path were repaired. The mirrored automaton now draws its current 3D mesh directly; the obsolete camera-less viewport wrapper is gone.

The critical question follows an operation the visitor can actually perform. Distinct positions are not the same as record count. Signal reachability is not body clearance. Sampled geometry is not the physical event. Surface symmetry is not network connectivity. A bounded first example gives us a foothold, not a final ontology.

Floor provenance is recorded in doc/space/pg-sequence-2026-09-15/floor-audit.json and the earlier July-grid audit. Museum support covers are explicit. Desktop tests use actual pointer input and a physical body on the onward route. Human headset review and exhaustive generated-interior clearance remain pending.

Continue the whole spine, then return to deepen these comparisons and rewrite with the later capabilities in view. Keep the question: **what bodies are possible under this construction, and what would have to change?**
'''
(O/'pg-learning-arc.md').write_text(arc,encoding='utf-8');assets.append('pg-learning-arc.md')
(O/'pg-learning-arc.html').write_text(page('Procedural generation learning arc',markdown.markdown(arc,extensions=['tables'])),encoding='utf-8');assets.append('pg-learning-arc.html')
assets+=['spine-iteration.md','spine-iteration.html']
manifest=['possible-bodies/'+a for a in assets];dump(E/'publish-targets.json',manifest);dump(E/'publish-hashes.json',{a:sha(R/'doc/research'/a) for a in manifest})
print('Built',len(assets),'review assets;',sum(r['checks'] for r in records),'runtime checks across five halls.')
