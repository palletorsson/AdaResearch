from pathlib import Path
import difflib, hashlib, html, json, re
import markdown

H=Path(__file__).resolve().parent
R=H.parents[3]
M='SpeculativeComputation_Rhizome_Network'
relative=H.relative_to(R).as_posix()
old=(H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
new=(R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
patch=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/final.md',tofile='current/final.md'))
(H/'final.diff').write_text(patch,encoding='utf-8')
before_html=markdown.markdown(old,extensions=['fenced_code','footnotes'])
after_html=markdown.markdown(new,extensions=['fenced_code','footnotes'])
images=[('museum-outside.png','The cave in its museum hall; the small grower remains beside the approach.'),('museum-entry.png','At body height, approaching the first division.'),('museum-junction.png','A junction and the violet landmark, reached from the lower passages.'),('museum-upper.png','Inside the upper return, 3.7 metres above the hall floor.')]
figures=''.join(f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" width="1800" height="1200" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name,caption in images)
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rhizome — another way through</title><style>
:root{color-scheme:dark;background:#111c21;color:#dfe6e3;font:17px/1.7 system-ui}body{margin:0}main{max-width:1220px;margin:auto;padding:48px 26px}h1{font:clamp(2.2rem,5vw,4.4rem)/1.12 Georgia,serif;max-width:850px}h2{font:2rem Georgia,serif}.eyebrow{color:#bcd396;text-transform:uppercase;letter-spacing:.12em;font-size:.8rem}.intro{font-size:1.2rem;max-width:780px}a{color:#c6dfad}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}img{display:block;width:100%;height:auto;border-radius:5px}figcaption,.note{color:#a6b7b7;font-size:.86rem}nav{display:flex;gap:20px;flex-wrap:wrap;margin:28px 0}.reading{max-width:750px;margin:64px auto;font:1.18rem/1.85 Georgia,serif}.reading h1{font-size:2.8rem}.reading code,pre{font: .88rem/1.6 ui-monospace,monospace}pre{background:#091015;padding:18px;overflow:auto}.compare{display:grid;grid-template-columns:1fr 1fr;gap:30px}.compare article{min-width:0;background:#17262d;padding:24px}.compare h1{font-size:1.5rem}.compare article p{font-family:Georgia,serif}.compare pre{white-space:pre-wrap}details{margin:32px 0}summary{cursor:pointer;color:#c6dfad}.footnote{font-size:.9rem;border-top:1px solid #39504c;margin-top:40px}.reading a{overflow-wrap:anywhere}@media(max-width:760px){.gallery,.compare{grid-template-columns:1fr}main{padding:26px 18px}}
</style><main><div class="eyebrow">Ada Research · Rhizome · built and written · 21 September 2026</div>
<h1>Another way through</h1><p class="intro">Enter the connections. Find a place again from another direction. Walk an upper crossing that gives no turn into the passage below.</p>
<p>The cave is now the main encounter; the existing grower remains its companion. The chapter begins with the inhabited space, then finds the useful code and the critical question within it.</p>
<nav><a href="#read">Read the chapter</a><a href="#compare">Original beside revision</a><a href="final.diff">Exact text diff</a><a href="SUMMARY.md">Construction and checks</a></nav>
<div class="gallery">'''+figures+'''</div><p class="note">Actual Godot museum captures. The construction is authored, using the existing cave surface extractor. Desktop walking checks passed; headset comfort and learner response remain to be assessed.</p>
<section class="reading" id="read">'''+after_html+'''</section>
<details id="compare"><summary>Read the original and revision side by side</summary><div class="compare"><article><div class="eyebrow">Before this pass</div>'''+before_html+'''</article><article><div class="eyebrow">Current chapter</div>'''+after_html.replace('id="','id="comparison-').replace('href="#','href="#comparison-')+'''</article></div></details></main></html>'''
(H/'index.html').write_text(page,encoding='utf-8')
# Add this pass to the established comparison without removing prior review evidence.
p=R/'doc/book/iterations/2026-09-19-review-comparison/postfoundationscrisis.json'
d=json.loads(p.read_text(encoding='utf-8'))
title='Rhizome: enter the connections'
d['items']=[x for x in d['items'] if x.get('title')!=title]
d['items'].append(dict(title=title,description='The cave is now an inhabited primary encounter, with lower circuits and an upper return. The grower stays as a companion. The chapter begins in the space and recovers a poetic investigation through actual routes.',images=[relative+'/museum-outside.png',relative+'/museum-junction.png'],captions=['The rebuilt museum hall and branching volume.','Inside: different passages meet at a recognisable place.'],image_note='Actual Godot museum views. A continuous controlled museum walk passed all 23 waypoints, including the upper return; headset and learner checks remain open.',text_kind='Book and immersive encounter — 21 September',before='\n\n'.join(old.split('\n\n')[1:4]),after='\n\n'.join(new.split('\n\n')[2:5]),report=relative+'/index.html',report_label='Read the full chapter, comparison and museum views'))
p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
checks=[]
map_data=json.loads((R/'commons/maps'/M/'map_data.json').read_text(encoding='utf-8'))
tokens=[str(t).split(':')[0].split('#')[0] for row in map_data['layers']['interactables'] for t in row if t]
roles=json.loads((R/'commons/data/artifact_roles.json').read_text(encoding='utf-8'))
checks.append(('Both authored artifacts retained',set(tokens)=={'rhizome_grower','rhizome_cave_demo'}))
checks.append(('Book encounters and primary order agree',re.findall(r'<!-- @([a-z_]+) -->',new)==roles['order'][M]['primary']))
checks.append(('Earlier fixed-territory paragraph preserved','The ring does not spread with the shoots. The machine keeps finding new places inside a boundary it chose before the network began. Something is growing, but its territory has already been given.' in new))
checks.append(('Excerpt matches source apart from spacing','air[index]=minf(air[index],passage)' in re.sub(r'\s+','',(R/'algorithms/spacetopology/marchingcubes/rhizome/RhizomePassages.gd').read_text(encoding='utf-8'))))
for filename in ['artifact-runtime.json','museum-runtime.json']:
    data=json.loads((H/filename).read_text(encoding='utf-8')); checks.append((filename+' passes',not data['failures'] and all(v['passed'] for v in data['walks'])))
for name,_ in images:checks.append((name+' exists',(H/name).stat().st_size>10000))
(H/'content-checks.json').write_text(json.dumps([dict(check=k,passed=v) for k,v in checks],indent=2)+'\n')
assert all(v for _,v in checks),checks
p=R/'commons/data/museum_core_encounters.json';d=json.loads(p.read_text(encoding='utf-8'));e=d['rooms'][M];e['status']='runtime_checked_draft'
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:e[k]=hashlib.sha256((R/'commons/maps'/M/n).read_bytes()).hexdigest()
p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Published chapter, image comparison and',len(checks),'content checks.')
