from pathlib import Path
import sys,re,hashlib,shutil
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'ada_run'))
from soft_sequence import *
import markdown,html
css=re.search(r'<style>(.*?)</style>',(O/'pg-sequence.html').read_text(),re.S)[1]
def page(title,body):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+' · Ada Research</title><style>'+css+'</style><main><nav><a href="soft-bodies.html">Soft Bodies</a><a href="soft-learning-arc.html">Learning arc</a><a href="pg-sequence.html">Previous sequence</a><a href="/museum-progress?sequence=softbodies">Museum progress</a></nav>'+body+'</main></html>'
assets=['spine-iteration.md','spine-iteration.html'];records=[]
shutil.copyfile(E/'encounter-order-check.json',O/'soft-encounter-order-check.json');assets.append('soft-encounter-order-check.json')
arc='''# A body and the conditions holding it

15 September 2026 · First traverse

**Deform → constrain → drive → encounter → compare → sample → interpret → exchange → map a field.**

The previous sequence constructed shapes. Here their parts can respond to forces while some relations remain prescribed. Softness does not automatically add tearing, changing connectivity or biological growth. The later halls make those distinctions available to inspect.

The museum had six of the nine halls listed in the sequence. This pass restores Cloth Physics, Affect and Entropy Morphogenesis, and places cloth before the carousel: stationary constraints come before driven supports. Existing artifacts and historical structure cells are retained.

| Hall | Question | Principal encounter |
|---|---|---|
'''
for m,k,title,primary,q,controls in ROWS:arc+='| ['+title+'](soft-'+k+'.html) | '+q+' | '+', '.join('`'+p+'`' for p in primary)+' |\n'
arc+='''
Begin with one prediction and one action. Observe the consequence; then expose its code. The critical question concerns a specific choice: a pin, a collision, a stop, a measurement, a boundary rule or a mapping between parameters. Keep earlier useful works as comparisons rather than forcing each hall into a one-artifact quota.

The final two halls separate local reaction–diffusion from a gyroid controlled by a parameter called S. S is an authored input here, not measured entropy. A chemical pattern does not automatically become a load-bearing body; a sampled surface does not automatically provide a traversable opening.

Next iteration: human headset reach and comfort, generated-interior clearance, solver cost, and sharper comparisons between matched starting conditions. Continue the whole spine with these limits recorded.
'''
(O/'soft-learning-arc.md').write_text(arc,encoding='utf-8');assets.append('soft-learning-arc.md');(O/'soft-learning-arc.html').write_text(page('Soft Bodies learning arc',markdown.markdown(arc,extensions=['tables'])),encoding='utf-8');assets.append('soft-learning-arc.html')
for m,k,title,primary,q,controls in ROWS:
 run=R/f'ada_run/soft-review-2026-09-15/{m}';receipt=read(run/'run.json');assert receipt['exit']==0 and not receipt['failures'],m
 assert current_sources(receipt),'stale '+m
 dest=E/m;dest.mkdir(exist_ok=True)
 for src,name in [(run/'run.json','receipt.json'),(run/m/'probe_ca_edge_live.json','runtime-report.json'),(run/m/'engine.log','engine.log')]:shutil.copyfile(src,dest/name)
 slug='soft-'+k;figures=''
 for p in sorted((run/m).glob('*.png')):
  out=slug+'-'+p.name;shutil.copyfile(p,O/out);assets.append(out);figures+='<figure><img loading="lazy" src="'+out+'" alt="'+html.escape(title)+' — '+p.stem+'"><figcaption>Actual Godot museum capture · '+p.stem+'. Desktop review; human headset review remains pending.</figcaption></figure>'
 links=[]
 for kind in ['final','technical','critical']:
  for before in [False,True]:
   source=(E/'before' if before else R)/f'commons/maps/{m}/{kind}.md'
   if not source.exists():continue
   out=slug+('-previous-' if before else '-')+kind+'.md';shutil.copyfile(source,O/out);assets.append(out);links.append('<a href="'+out+'">'+('Previous ' if before else 'Current ')+kind+'</a>')
 out=slug+'-verification.json';shutil.copyfile(run/'run.json',O/out);assets.append(out)
 body='<p class="date">Soft Bodies · First traverse · 15 September 2026</p><h1>'+title+'</h1><p class="lead">'+q+'</p><p class="tag">'+str(receipt['checks'])+' desktop checks passed · '+str(len(primary))+' primary artifact'+('s' if len(primary)>1 else '')+'</p><p><a href="/necklace/thread?map='+m+'&role=primary">Open the primary artifacts</a></p><details><summary>Read this hall’s book passage</summary><article>'+markdown.markdown((R/f'commons/maps/{m}/final.md').read_text(),extensions=['fenced_code'])+'</article></details>'+figures+'<h2>What was checked</h2><p>Actual scene loading, physical desk-button activation through DesktopPlayer, model-specific outcomes, supported circulation and the onward museum crossing. The original saved hand remains unchanged. A later data-only correction aligns Necklace encounter order; <a href="soft-encounter-order-check.json">its separate verification</a> accompanies the unchanged runtime receipts. Human headset comfort, Quest performance and every generated interior remain unverified. Captures were muted; the existing audio-bus UID warning is recorded.</p><p><a href="'+out+'">Runtime receipt</a></p><p>'+' · '.join(links)+'</p>'
 (O/(slug+'.html')).write_text(page(title,body),encoding='utf-8');assets.append(slug+'.html');records.append(dict(map=m,url=slug+'.html',title=title,question=q,primary=primary,checks=receipt['checks']))
body='<p class="date">Nine halls · 15 September 2026</p><h1>A body and the conditions holding it</h1><p class="lead">Deform → constrain → drive → encounter → compare → sample → interpret → exchange → map a field.</p><p>All nine halls now have book passages tied to their primary artifacts and compact controls for concrete comparisons. The existing collection remains. Three halls missing from the museum route have been restored.</p><p><a href="soft-learning-arc.html">Read the pedagogical order and its reasoning</a></p><div class="cards">'
for i,a in enumerate(records):body+='<section class="card"><p class="tag">HALL '+str(i+1)+'</p><h2><a href="'+a['url']+'">'+a['title']+'</a></h2><p>'+a['question']+'</p><small>'+str(a['checks'])+' desktop checks</small></section>'
body+='</div><h2>The question carried forward</h2><p>What bodies are possible under these conditions? The new capability is a form that responds through relations between its parts. Pins, prescribed motion, collision, sampling and measurement each establish a different limit. The later field studies ask how a pattern becomes a surface, and who chose that mapping.</p><p>The first traverse is a basis for returning. Human headset testing, performance and exhaustive interior access remain future work. Source maps keep historical structure cells with explicit support covers; the larger courts and independent onward aisles are staging decisions.</p>'
(O/'soft-bodies.html').write_text(page('Soft Bodies',body),encoding='utf-8');assets.append('soft-bodies.html');dump(O/'soft-verification.json',records);assets.append('soft-verification.json')
manifest=['possible-bodies/'+a for a in assets];dump(E/'publish-targets.json',manifest);dump(E/'publish-hashes.json',{a:hashlib.sha256((R/'doc/research'/a).read_bytes()).hexdigest() for a in manifest})
(R/'ada_run/publish_soft_sequence.ps1').write_text((R/'ada_run/publish_pg_sequence.ps1').read_text().replace('pg-sequence-2026-09-15','soft-sequence-2026-09-15'),encoding='utf-8')
print('Built',len(assets),'assets;',sum(a['checks'] for a in records),'desktop checks.')
