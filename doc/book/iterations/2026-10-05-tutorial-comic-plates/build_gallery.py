"""Save generated book illustrations and show their teaching lineage."""
from pathlib import Path
from hashlib import sha256
from html import escape
import json
import os
import re
import shutil
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
spec=json.loads((HERE/'plates.json').read_text(encoding='utf-8'))
records=json.loads((HERE/'generated-files.json').read_text(encoding='utf-8'))['files']
previous_path=HERE/'provenance.json'
previous={p['map']:p for p in json.loads(previous_path.read_text(encoding='utf-8'))['plates']} if previous_path.exists() else {}
summaries={
 'point-one':'Give a position a visible surface and a separate physical boundary. One radius controls both. Seeing and contact can be changed independently.',
 'coordinates':'Keep the same point; add pickup and release. Local and world addresses describe that one object from different frames. A drawn guide is finite; its coordinate system continues.',
 'lines':'Put the familiar point construction into a class and create two instances. Read their displacement and draw a segment. Arrange two segments, then step sideways to investigate their depth.',
 'trace':'Reuse the point class and keep its positions in an ordered array. A movement condition accepts another entry; a loop joins neighbouring positions. Changing the threshold changes what survives.'
}
alt={
 'point-one':'Six-panel museum comic: an empty position becomes a white sphere with a separate physical boundary; a hierarchy connects surface and boundary to the point; changing radius changes both.',
 'coordinates':'Six-panel museum comic: the same sphere becomes pickable, remains after release, has local and world addresses, moves beyond a finite axis drawing, and can have pickup disabled.',
 'lines':'Six-panel museum comic: a point class gives two endpoint instances, a pink segment connects them, length and direction differ, and crossed drawings can occupy different depths.',
 'trace':'Six-panel museum comic: a carried point leaves a polygonal trace, positions are stored in order, a movement threshold accepts new entries, and four positions produce three neighbouring segments.'
}
panels=[]; facts=[]; prompt_text=['# Tutorial comic prompts','', 'Built-in image_gen. The supplied comic and the preceding Trace plate were style/character references. Initial prompts and any targeted refinements are retained below.','']
for i,r in enumerate(records):
 destination=HERE/(r['slug']+'.png')
 original=Path(r['generated_path'])
 if destination.exists():
  if destination.read_bytes()!=original.read_bytes(): raise SystemExit('Existing asset differs; create a versioned sibling: '+str(destination))
 else: shutil.copy2(original,destination)
 with Image.open(destination) as im: dimensions=list(im.size)
 source=ROOT/r['source']
 text=source.read_text(encoding='utf-8-sig')
 # Proposed-focus headings may include an explanatory paragraph before their list.
 match=re.search(r'\*\*Learning elements(?: — proposed focus)?\*\*.*?\n((?:- [^\n]+\n)+)',text,re.S)
 actual=re.findall(r'^- (.+)$',match.group(1),re.M) if match else []
 if actual!=r['concepts']: raise SystemExit('Learning elements changed; review plate '+r['slug'])
 source_hash=sha256(source.read_bytes()).hexdigest()
 reviewed_hash=r.get('source_sha256_at_draft',previous.get(r['map'],{}).get('source_sha256',source_hash))
 if source_hash!=reviewed_hash: raise SystemExit('Source changed since illustration review: '+r['map'])
 facts.append(dict(map=r['map'],source=r['source'],source_sha256=reviewed_hash,
                   image=destination.name,image_sha256=sha256(destination.read_bytes()).hexdigest(),dimensions=dimensions,
                   subject_status=r.get('subject_status','current'),
                   method='Illustration manually reviewed against the current tutorial. Schematic proportions; no runtime capture or learner assessment.'))
 href=os.path.relpath(source,HERE).replace('\\','/')
 subjects=''.join('<li>'+escape(x)+'</li>' for x in r['concepts'])
 prev=records[max(0,i-1)]['map']; next_map=records[min(len(records)-1,i+1)]['map']
 summary=r.get('summary',summaries.get(r['slug'],''))
 alt_text=r.get('alt',alt.get(r['slug'],r['title']))
 subject_heading='Learning elements — proposed focus' if r.get('subject_status')=='proposed' else 'Learning elements'
 status_note='<p class="caption">The source tutorial marks these subjects as a proposed focus; its full lesson still awaits alignment.</p>' if r.get('subject_status')=='proposed' else ''
 panels.append(f'''<section id="{r['map']}" class="plate" {'hidden' if i else ''}>
<a class="image-link" href="{destination.name}"><img src="{destination.name}" alt="{escape(alt_text)}" width="{dimensions[0]}" height="{dimensions[1]}"></a>
<aside><p class="eyebrow">{i+1:02} / {len(records):02} · {escape(r['map'].replace('_',' '))}</p><h2>{escape(r['title'].title())}</h2><p>{escape(summary)}</p><h3>{subject_heading}</h3><ul>{subjects}</ul>{status_note}<p><a href="{href}">Read this tutorial</a> · <a href="{destination.name}" download>Download the illustration</a></p><div class="prev-next"><button data-map="{prev}" {'disabled' if i==0 else ''}>← Previous</button><button data-map="{next_map}" {'disabled' if i==len(records)-1 else ''}>Next →</button></div><p class="caption">An illustrated encounter based on the lesson. Characters and room staging are imagined; the diagram overlays make the teaching relation visible.</p></aside></section>''')
 prompt=next(p['prompt'] for p in spec['plates'] if p['slug']==r['slug'])
 prompt_text+=['## '+r['title'],'',prompt,'','### Targeted refinement','',r['refinement_prompt'],'']
(HERE/'PROMPTS.md').write_text('\n'.join(prompt_text)+'\n',encoding='utf-8')
(HERE/'provenance.json').write_text(json.dumps(dict(date='2026-10-05',tool='Built-in image_gen',review='Source hashes captured at final review; these do not certify scale, runtime behaviour or student understanding.',plates=facts),indent=2)+'\n',encoding='utf-8')
buttons=''.join('<button data-map="'+r['map']+'">'+escape(r['map'].replace('_',' '))+'</button>' for r in records)
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Illustrated tutorials · Endless Museum</title><style>
:root{color-scheme:light;--paper:#f6f3ed;--ink:#292826;--accent:#8c5165;--line:#d7d0c5}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.65 system-ui,sans-serif}header,main,footer{max-width:1400px;margin:auto;padding:2rem}header{padding-top:3rem}h1{font:normal clamp(2rem,4vw,3rem)/1.1 Georgia,serif;letter-spacing:-.03em;margin:.6rem 0}header>p{max-width:75ch}.eyebrow{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent)}nav{display:flex;gap:.5rem;flex-wrap:wrap;margin-top:1.4rem}button{font:inherit;font-size:.88rem;cursor:pointer;border:1px solid var(--line);background:#fffdf8;border-radius:3px;padding:.55rem .85rem;color:var(--ink)}button[aria-current="true"]{background:var(--ink);color:var(--paper);border-color:var(--ink)}button:disabled{opacity:.4;cursor:default}a{color:var(--accent);text-underline-offset:3px}.plate{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:2.5rem;align-items:start}.plate[hidden]{display:none}.image-link img{display:block;width:100%;height:auto;box-shadow:0 5px 28px #28242020}aside{position:sticky;top:2rem}aside h2{font:normal 1.8rem/1.2 Georgia,serif}aside h3{font-size:1rem;margin-top:2rem}ul{padding-left:1.2rem}.caption{font-size:.82rem;color:#6e675f;margin-top:2rem}.prev-next{display:flex;gap:.6rem;margin-top:1.5rem}footer{font-size:.8rem;color:#6e675f;border-top:1px solid var(--line);margin-top:2rem}@media(max-width:780px){header,main,footer{padding:1.2rem}.plate{grid-template-columns:1fr;gap:1rem}aside{position:static}}@media print{header,aside,footer{display:none}.plate[hidden],.plate{display:block;break-after:page}.image-link img{max-height:270mm;width:auto;max-width:100%;box-shadow:none}main{padding:0}}
</style></head><body><header><p class="eyebrow">Ada · '''+str(len(records))+''' illustrated tutorials · 5 October 2026</p><h1>Keep the object. Follow what changes.</h1><p>The opening lessons drawn as museum encounters, in the visual language of the ghost-student comic. Each page follows one teaching choice through gesture, code and comparison.</p><nav aria-label="Tutorial pages">'''+buttons+'''</nav></header><main>'''+''.join(panels)+'''</main><footer>Built-in image generation · <a href="PROMPTS.md">Full prompts and refinements</a> · <a href="provenance.json">Lesson sources</a>. Dotted boundaries and frames are explanatory overlays. The exact dimensions and operations are specified in the linked code.</footer><script>
const pages=[...document.querySelectorAll('.plate')];
function show(id){const chosen=pages.find(p=>p.id===id)||pages[0];pages.forEach(p=>p.hidden=p!==chosen);document.querySelectorAll('nav [data-map]').forEach(b=>b.setAttribute('aria-current',String(b.dataset.map===chosen.id)));}
document.querySelectorAll('[data-map]').forEach(b=>b.addEventListener('click',()=>{history.replaceState(null,'','#'+b.dataset.map);show(b.dataset.map);window.scrollTo({top:0,behavior:'smooth'});}));
window.addEventListener('hashchange',()=>show(decodeURIComponent(location.hash.slice(1))));show(decodeURIComponent(location.hash.slice(1)));
</script></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'README.md').write_text('''# Illustrated opening tutorials

Eight teaching comics: Point One, Coordinates, Lines, Trace, Grid, Triangle Context, Polyhedra and Cube. They follow the canonical Primitives sequence and use the same fictional student and teacher as the author-supplied reference comic. Each six-panel page shows an encounter, a code relation and a controlled comparison. The current Lines lesson introduces PointBody as a class; Trace reuses it. Grid illustrates the existing released-pen record retained during the same running museum session.

Triangle Context, Polyhedra and Cube carry proposed learning-element lists in their source tutorials. This gallery retains that status; illustrations do not promote the full lessons or rewrite their text.

View `index.html`; select a hall or use previous/next. The image link opens its full PNG. Source tutorials and learning elements are linked alongside each page. The exact generation and edit prompts are retained in PROMPTS.md. The built-in image_gen tool generated and refined the plates; files were copied into this project.

Review corrected the shared surface/boundary diagram and relative radius comparison, the finite-axis end, the visible endpoint segment and Z-depth inset, and the Trace position values and threshold annotation. These are imagined teaching illustrations, not museum screenshots or evidence that a person has learned. Diagram sizes are schematic; exact construction and dimensions belong to the code. Museum runtime and tutorial text were not edited by this illustration pass.

The continuation review checked retained versus derived positions, Y-up guides, subdivisions versus tick counts, merged snapped neighbours, the four vertices of an open trihedron, incident faces attached to a moved apex, and alternative diagonals between shared cube corners. The supplied records and source hashes retain the basis for review.
''',encoding='utf-8')
print(json.dumps({'plates':[{k:p[k] for k in ('map','image','dimensions')} for p in facts],'gallery':str(HERE/'index.html')},indent=2))
