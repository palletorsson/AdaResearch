from pathlib import Path
import hashlib, html, json, re, shutil, zipfile
from urllib.parse import urlsplit, unquote
import markdown
from bs4 import BeautifulSoup

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
HALLS=[
 ('Color_Context_Placed','Colour','The same parts','Assign a palette to familiar forms; change the grouping while geometry stays fixed.','2026-10-06-colour-the-same-parts'),
 ('Color_Flashlight','Flashlight','Keep the surface','Change a light and its aim; distinguish illumination from the receiving material.','2026-10-06-flashlight-keep-the-surface'),
 ('Color_Nails','Nails','A position becomes a colour','Carry PointBody; map its local position to bounded RGB and return the result to a material.','2026-10-06-nails-a-position-to-colour'),
 ('Color_Rainbow','Rainbow','Keep the opening','Use a chosen palette to divide a fixed radial thickness; keep the opening and outer edge.',''),
 ('Color_Pillar','Pillar','Colour has a height','Return to PointBody; map reachable height to HSV value while hue and saturation have their own coordinates.',''),
 ('Color_Grid_Pallet','Grid','A colour left at an address','Store the earlier sample at an address; give two Palette instances separate remembered indices.',''),
 ('Color_Paint','Paint','A mark stays on the surface','Extend PointBody into a study brush; gate a ray by held/action state and accumulate its accepted hits in one image.',''),
 ('Color_Walls','Walls','A view through two colours','Reuse Palette and transforms; change alpha and composition while keeping physical boundaries.',''),
]
FIXTURES={'Color_Flashlight':'separate.png','Color_Nails':'start.png','Color_Rainbow':'rainbow.png','Color_Pillar':'pillar-middle.png','Color_Grid_Pallet':'grid-mark.png','Color_Paint':'paint-marks.png','Color_Walls':'walls-filter.png'}
CSS='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f4f0e7;color:#25262b;font:17px/1.65 Georgia,serif}a{color:#275d64;text-underline-offset:.2em}header{background:#f4f0e7f5;border-bottom:1px solid #d7d0c5;padding:12px 4vw;position:sticky;top:0;z-index:5;font:14px/1.6 system-ui}header a{margin-right:16px}main{max-width:1260px;margin:auto;padding:40px 4vw 80px}h1,h2,h3{line-height:1.16}h1{font-size:clamp(34px,4vw,64px);font-weight:400;margin:10px 0 24px}h2{font-size:29px;margin-top:2em}h3{font-size:22px}p{max-width:75ch}small,.eyebrow,figcaption,.meta{font:13px/1.55 system-ui;color:#696761}.eyebrow{text-transform:uppercase;letter-spacing:.15em}.lead{font-size:23px;max-width:60ch}.actions{display:flex;gap:12px;flex-wrap:wrap;margin:25px 0}.actions a{background:#22595d;color:white;padding:9px 15px;text-decoration:none;border-radius:3px;font:14px/1.5 system-ui}.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px;margin-top:35px}.card{border-top:1px solid #bdb7ac;padding:20px 0}.card h2{margin:12px 0;font-size:30px}.card img{width:100%;height:230px;object-fit:cover;background:#d9d6d0}.card p{font-size:16px}img{max-width:100%;height:auto}figure{margin:20px 0}figcaption{margin-top:7px}pre{background:#e8e5de;padding:18px;overflow:auto;line-height:1.55;font:13px/1.55 Consolas,monospace;border-left:3px solid #608080}code{font-family:Consolas,monospace;font-size:.88em}pre code{font-size:inherit}table{border-collapse:collapse;font:14px/1.5 system-ui;width:100%;margin:25px 0}th,td{padding:10px;border-bottom:1px solid #d0c9be;text-align:left;vertical-align:top}blockquote{border-left:2px solid #b9668c;margin:25px 0;padding-left:22px}nav.halls{display:flex;flex-wrap:wrap;gap:5px}nav.halls a{padding:3px 8px;border:1px solid #d4cec4;margin:0}.selected{background:#275d64;color:white}.spread{max-width:none;padding:0;display:grid;grid-template-columns:1.05fr 1fr;gap:0}.page{padding:30px 3vw;min-width:0;height:calc(100vh - 117px);overflow:auto;scroll-behavior:smooth}.page+.page{border-left:1px solid #ccc4b7;background:#faf7f0}.page h1{font-size:37px}.page h2{font-size:26px}.page pre{font-size:12px}.reading{max-width:880px}.chapter{border-top:1px solid #b9b3a8;margin-top:65px;padding-top:24px;scroll-margin-top:90px}.notice{padding:16px 20px;background:#e7ede7;border-left:3px solid #52705b}.sources{word-break:break-word}details{margin:20px 0}summary{cursor:pointer;font:15px/1.5 system-ui}footer{margin-top:60px;font:13px/1.6 system-ui;color:#696761}@media(max-width:900px){.spread{display:block}.page{height:auto}.page+.page{border-left:0;border-top:1px solid #aaa}.cards{grid-template-columns:1fr}}@media print{header,.actions,nav{display:none}.spread{display:block}.page{height:auto;overflow:visible}.page+.page{border:0}.chapter,.page{break-before:page}pre{white-space:pre-wrap;font-size:10px}body{background:white}main{padding:0}h1{font-size:30px}}'''

def put(p,text):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def md(text):return markdown.markdown(text,extensions=['fenced_code','tables','footnotes','sane_lists'])
def page(title,body,rel='',spread=False):
 nav=''.join(f'<a href="{rel}{h}/parallel.html">{n}</a>' for h,n,*_ in HALLS)
 return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} — Endless Museum</title><style>{CSS}</style></head><body><header><div><a href="{rel}index.html">COLOUR · REVIEW DRAFT</a><a href="{rel}all.html">All tutorials</a><a href="{rel}final.html">All reflections</a><a href="{rel}review.html">Reviewer brief & evidence</a><a href="{rel}feedback.html">Feedback revision</a></div><nav class="halls">{nav}</nav></header><main class="{"spread" if spread else ""}">{body}</main></body></html>'

assets={}
def localize_text(text,source_dir,from_dir):
 # Make local images portable; keep historical cross-chapter links as explicit local-server references.
 def replace(m):
  lead,label,url=m.groups()
  if url.startswith(('https://','http://','mailto:','#')):return m.group(0)
  parsed=urlsplit(url)
  raw=unquote(parsed.path)
  if raw.startswith('/book-review/'):
   source=ROOT/raw.removeprefix('/book-review/')
  elif raw.startswith('/'):
   return lead+label+'](http://localhost:3003'+url+')'
  else:
   source=(source_dir/raw).resolve()
  if lead=='![' and source.exists():
   key=sha(source)[:12]+'-'+source.name
   dest=HERE/'assets'/key
   if not dest.exists():dest.parent.mkdir(exist_ok=True);shutil.copyfile(source,dest)
   assets[key]=str(source.relative_to(ROOT)) if source.is_relative_to(ROOT) else str(source)
   import os
   target=os.path.relpath(dest,from_dir).replace('\\','/')
   return '!['+label+']('+target+')'
  if source.exists() and source.is_relative_to(HERE):
   import os
   target=os.path.relpath(source,from_dir).replace('\\','/')
   return lead+label+']('+target+('#'+parsed.fragment if parsed.fragment else '')+')'
  if source.is_relative_to(ROOT):
   return lead+label+'](http://localhost:3003/book-review/'+source.relative_to(ROOT).as_posix()+('#'+parsed.fragment if parsed.fragment else '')+')'
  return m.group(0)
 return re.sub(r'(!?\[)([^\]]*)\]\(([^)]+)\)',replace,text)

REVIEW='''# Colour — a complete sequence for review

**Status: eight tutorial drafts, paired with the eight existing final.md reflections.** The final texts are preserved, not newly rewritten. The first three tutorials retain their tested programs; Rainbow through Walls are the newer batch. The full-sequence feedback led to small prose revisions in Colour and Rainbow and a clearer manual-first route through Paint. See FEEDBACK.md. No canonical tutorials, museum runtime, sequence order or acceptance flags were changed by this batch.

## Where we are

We are inside the existing **Endless Museum**. Its rooms, artifacts, player, camera, light and prepared XR Tools already exist. The learner encounters an installed artifact, then reconstructs one selected operation in a small script in their working museum copy. These are not eight replacement environments. The review studies have not been inserted into the live halls. The host and supplied helpers are declared in each lesson.

The tutorial track and the reflective track overlap. An artifact may belong to either, both, or neither. A tutorial need not reconstruct every object or interpretive thread in final.md.

## The learner arriving here

Assume the earlier route: game loop; PointBody and its pickup; local/world coordinates; lines; arrays and loops through Trace and Grid; triangles, meshes and primitives; configuration; whole-object translation, rotation and scale; addressed arrays. The early Array lessons are not all complete review drafts yet. This chapter uses those agreed prior concepts; it does not certify that the entire preceding book has been completed.

The continuous object is a lineage, not an automatic persistence mechanism. PointBody's exact class returns in Nails, Pillar and Paint. Recorded colour values move from Nails to Rainbow, then Pillar to Grid. Palette is introduced in Grid and reused unchanged in Walls. Every study declares whether it copies a value, creates an instance or receives an existing reference.

## Read as the ghost student

Imagine a future in which jobs have disappeared. Read as someone might still play chess after a machine can play better: for the pleasure of making a move, and with some melancholy about what has changed. This is an imagined position, not a prediction the book must prove. The code and its objects are real. Notice where the lesson gives you another capacity and where it merely asks you to trust the teacher. Keep a missing step visible rather than silently supplying it. The teacher is also learning what remains worth handing on.

## Questions for the reviewer

1. Can the learner identify what changes in each hall and which earlier capacity makes that change possible?
2. Does colour remain the subject, with programming serving it? Identify any lesson where infrastructure takes over.
3. Can the printed code and named supplied files reconstruct the selected operation? Flag every undeclared dependency or ambiguous coordinate frame.
4. Does the tutorial stay accountable to the actual museum artifact without pretending to rebuild every effect? Distinguish a declared reduction from a mistaken account.
5. Are there enough independent choices to demonstrate understanding beyond copying? Are their expected observations concrete?
6. Read each final.md beside its tutorial. Do they deepen one another without forcing every reflection into an exercise?

Please return comments by hall: **keep / change / missing**, a precise passage or code location, and the smallest useful revision. If you did not run code, label your assessment as a reading review.

## Decisions particularly worth testing with a reader

- **Rainbow:** its making lesson is optional; encountering celebration does not require completing a coding task.
- **Pillar:** the hand-height adapter is necessary to make a tall field reachable. Does separating it from the HSV function make the two frames legible?
- **Grid:** Palette is a small stateful class, not a new architecture. Does it help the reader distinguish address, instance index and palette index?
- **Paint:** this is the densest lesson. Its point, action, ray and surface are connected completely, and the supplied receiver is printed. Does the separation into one continuation and support files keep the focus readable? Its circular stamps omit the installed can's aerosol, wetness, stretching, runs and fading. The automatic caller is explicitly optional, after a completion check for manual painting; both callers still write one image.
- **Walls:** does the same persistent collider make the difference between a visible opening and a physical passage clear? RGB/HSV models and the interpolation bench remain reflective encounters outside this selected two-pane exercise.

## Evidence and limits

The new batch executes the exact fenced sources under Godot 4.6, including the supplied scripts. It checks all five baselines and 15 additional printed/choice variants. Assertions cover geometry and materials, moved reference frames, retained instance colours, palette ownership, ray hits and occlusion, persistent marks, and collisions through translucent/opaque modes. XR Tools pickup/action/drop is exercised with a synthetic controller.

Ten deliberate behavioural faults must fail specific assertions. Parser failures are not accepted as successful fault detection. Native checks use the real OpenGL renderer because the headless dummy renderer does not retain the MultiMesh colour state being tested. Fixed-camera rendering checks provide separate visual evidence.

Proof files are included and their source hashes are checked at collection time. The revised Colour prose and five-hall manuscripts have fresh checks; the unaffected Flashlight and Nails results are retained from their earlier runs. Tests establish selected implementation behaviour; they do not establish headset comfort, full museum integration, physical controller mapping, educational success, historical interpretation or the reader's emotional response.

The report distinguishes dated **museum captures** from new **isolated study renders**. It does not present the latter as screenshots of installed halls.

## Files

- `ALL_TUTORIALS.md`: all eight complete tutorial texts, in spine order.
- `ALL_FINAL.md`: all eight existing reflective texts, with local image links relocated for this package.
- Each hall folder: exact individual `tutorial.md`, `final.md`, runnable scripts and side-by-side HTML.
- `verification.json`, native/render reports and test runners: new-batch proof.
- `evidence/`: preserved proof and test sources from the first three lessons.
- `manifest.json`: source locations, hashes, collection status and image provenance.

To rerun the new checks from the AdaResearch checkout: `python -X utf8 doc/book/iterations/2026-10-06-colour-complete-drafts/run_checks.py`, then the neighbouring `run_render.py`. The runner uses the repository's XR Tools addon and a Godot 4.6 executable (`GODOT_EXE` may override the recorded local path). A fresh temporary project is created. The ZIP is a review collection, not a replacement for Day Zero or a complete museum distribution.
'''

def main():
 put(HERE/'style.css',CSS)
 put(HERE/'feedback.html',page('Colour feedback revision',md((HERE/'FEEDBACK.md').read_text(encoding='utf-8'))))
 manifest={'status':'review draft; not promoted','date':'2026-10-06','halls':[],'proof':[]}
 old_proofs=[]
 for hall,name,title,summary,old in HALLS:
  folder=HERE/hall;folder.mkdir(exist_ok=True)
  if old:
   source=HERE.parent/old
   for p in list(source.glob('*.gd'))+[source/'tutorial.md',source/'final.md']:
    shutil.copyfile(p,folder/p.name)
   v=json.loads((source/'verification.json').read_text())
   for path,digest in v['inputs'].items():assert sha(ROOT/path)==digest,(old,path,'stale proof')
   target=HERE/'evidence'/hall;target.mkdir(parents=True,exist_ok=True)
   for pattern in ['*.json','*.gd','*.py','*.godot']:
    for p in source.glob(pattern):shutil.copyfile(p,target/p.name)
   for p in source.glob('*.png'):shutil.copyfile(p,folder/p.name)
   old_proofs.append(v)
   manifest['proof'].append({'hall':hall,'source':source.relative_to(ROOT).as_posix(),'passed':v['passed'],'assertions':v.get('native_assertions',v.get('assertions')),'render_assertions':v.get('render_assertions',0),'faults_rejected':v['faults_rejected'],'source_hashes_current':True})
  assert sha(folder/'final.md')==sha(ROOT/'commons/maps'/hall/'final.md'),hall+' final changed'
  manifest['halls'].append({'map':hall,'summary':summary,'tutorial_sha256':sha(folder/'tutorial.md'),'final_sha256':sha(folder/'final.md'),'canonical_final_matches':True,'source':old or HERE.name})
 v=json.loads((HERE/'verification.json').read_text())
 assert v['passed']
 for path,digest in v['inputs'].items():assert sha(HERE/path)==digest,(path,'stale new proof')
 for path,digest in v['preserved'].items():assert sha(ROOT/path)==digest,(path,'canonical file changed')
 manifest['proof'].append({'halls':[x[0] for x in HALLS[3:]],'assertions':v['native_assertions'],'render_assertions':v['render_assertions'],'faults_rejected':v['faults_rejected'],'variants':v['variants'],'passed':True,'source_hashes_current':True})
 total=sum(p['assertions'] for p in manifest['proof']);render=sum(p['render_assertions'] for p in manifest['proof']);faults=sum(p['faults_rejected'] for p in manifest['proof'])
 totals=f'Across the collected evidence: **{total} native assertions, {render} render checks, {faults} deliberate faults rejected**. The new five-hall batch contributes {v["native_assertions"]}, {v["render_assertions"]} and {v["faults_rejected"]}, respectively.'
 put(HERE/'REVIEW.md',REVIEW+'\n'+totals+'\n')
 put(HERE/'review.html',page('Reviewer brief',md(REVIEW+'\n'+totals)))
 tutorial_sections=[];final_sections=[];cards=[];summaries=['# Colour — one paragraph per hall\n']
 for index,(hall,name,title,summary,old) in enumerate(HALLS):
  folder=HERE/hall
  tutorial=(folder/'tutorial.md').read_text(encoding='utf-8-sig')
  final=(folder/'final.md').read_text(encoding='utf-8-sig')
  # Always resolve the copied tutorials' old links from their original folder.
  source_dir=HERE.parent/old if old else folder
  t=localize_text(tutorial,source_dir,HERE)
  f=localize_text(final,ROOT/'commons/maps'/hall,HERE)
  tutorial_sections.append(f'<section class="chapter" id="{hall}"><p class="eyebrow">{index+1:02} / 08 · {hall}</p>'+md(t)+'</section>')
  final_sections.append(f'<section class="chapter" id="{hall}"><p class="eyebrow">{index+1:02} / 08 · {hall}</p>'+md(f)+'</section>')
  summaries.append(f'## {index+1}. {name} — {title}\n\n{summary} The tutorial reconstructs this operation in a working copy of the existing hall. The reflection keeps the wider encounter available.\n')
  t_hall=localize_text(tutorial,source_dir,folder)
  f_hall=localize_text(final,ROOT/'commons/maps'/hall,folder)
  fixture=''
  if hall in FIXTURES:
   target=(folder/FIXTURES[hall]) if old else (HERE/FIXTURES[hall])
   import os
   fixture=f'<details><summary>See the tested code study</summary><figure><img src="{os.path.relpath(target,folder).replace(chr(92),"/")}" alt="{name} isolated code study"><figcaption>Isolated native Godot study render, 6 October. This is verification of the printed example, not a capture of the installed museum.</figcaption></figure></details>'
  prev=f'<a href="../{HALLS[index-1][0]}/parallel.html">← {HALLS[index-1][1]}</a>' if index else '<a href="../index.html">← Colour</a>'
  nxt=f'<a href="../{HALLS[index+1][0]}/parallel.html">{HALLS[index+1][1]} →</a>' if index<7 else '<a href="../review.html">Reviewer brief →</a>'
  navigation=f'<p class="meta">{prev} · {index+1} / 8 · {nxt}</p>'
  paired=f'<article class="page"><p class="eyebrow">Tutorial · Working in the Endless Museum</p>{navigation}{fixture}{md(t_hall)}</article><article class="page"><p class="eyebrow">Reflection · Existing final.md</p>{navigation}{md(f_hall)}</article>'
  put(folder/'parallel.html',page(name,paired,'../',True))
  put(folder/'tutorial.html',page(name+' tutorial',md(t_hall),'../'))
  put(folder/'final.html',page(name+' reflection',md(f_hall),'../'))
  first=BeautifulSoup(md(f),'html.parser').find('img')
  pic=f'<img src="{first["src"]}" alt="{html.escape(first.get("alt",name),quote=True)}" loading="lazy"><p class="meta">Existing museum capture · source recorded in manifest.json</p>' if first else ''
  cards.append(f'<article class="card"><span class="eyebrow">{index+1:02} / 08 · {name}</span><h2><a href="{hall}/parallel.html">{title}</a></h2>{pic}<p>{summary}</p><a href="{hall}/parallel.html">Read tutorial + reflection →</a></article>')
 put(HERE/'SUMMARIES.md','\n'.join(summaries))
 put(HERE/'all.html',page('All eight tutorials','<div class="reading"><p class="eyebrow">Complete tutorial draft · eight halls</p><h1>Where colour is kept</h1><p>The existing Endless Museum is the host. Each lesson reconstructs one selected operation encountered there. Follow one question across the halls: <strong>where is the colour held, and what receives it?</strong></p>'+''.join(tutorial_sections)+'</div>'))
 put(HERE/'final.html',page('All eight reflections','<div class="reading"><p class="eyebrow">Existing reflective sequence · eight halls</p><h1>Colour — the encounters</h1><p>All eight final.md texts, preserved in spine order.</p>'+''.join(final_sections)+'</div>'))
 all_t=['# Colour — all eight tutorial drafts\n\nReview collection, 6 October 2026. Read REVIEW.md first. The host is the existing Endless Museum. Follow one question across the halls: **where is the colour held, and what receives it?**\n']
 all_f=['# Colour — all eight reflective texts\n\nExisting final.md texts in spine order. Image paths relocated for this review collection; wording preserved.\n']
 for hall,name,*_ in HALLS:
  old=next(x[4] for x in HALLS if x[0]==hall)
  all_t.append('\n---\n\n<!-- hall:'+hall+' -->\n\n'+localize_text((HERE/hall/'tutorial.md').read_text(encoding='utf-8-sig'),HERE.parent/old if old else HERE/hall,HERE))
  all_f.append('\n---\n\n<!-- hall:'+hall+' -->\n\n'+localize_text((HERE/hall/'final.md').read_text(encoding='utf-8-sig'),ROOT/'commons/maps'/hall,HERE))
 put(HERE/'ALL_TUTORIALS.md','\n'.join(all_t));put(HERE/'ALL_FINAL.md','\n'.join(all_f))
 manifest['assets']=assets
 manifest['totals']={'native_assertions':total,'render_assertions':render,'faults_rejected':faults}
 put(HERE/'manifest.json',json.dumps(manifest,indent=2))
 body='<p class="eyebrow">Endless Museum / Colour / Review draft / 6 October 2026</p><h1>A colour, then another use.</h1><p class="lead">Eight halls. Complete tutorial texts beside the reflective sequence. The next room keeps a body, a value or a behaviour—and changes what it can do.</p><p class="notice"><strong>We are inside the existing Endless Museum.</strong> The learner reconstructs selected operations in their working copy. The room, player and XR setup are already there. These drafts are ready for review; the study scripts have not been installed in the live halls.</p><div class="actions"><a href="Color_Context_Placed/parallel.html">Read side by side</a><a href="ALL_TUTORIALS.md" download>Full tutorial · Markdown</a><a href="ALL_FINAL.md" download>Full final · Markdown</a><a href="colour-review.zip" download>Reviewer ZIP</a></div><p><a href="feedback.html">Feedback and revisions</a> · <a href="review.html">Reviewer brief and evidence</a> · <a href="SUMMARIES.md">One paragraph per hall</a></p>'+md(totals)+'<div class="cards">'+''.join(cards)+'</div><footer>Left: reconstruction and code. Right: critical and poetic encounter. Actual museum captures accompany the halls; isolated code renders are labelled separately. Canonical texts and museum code remain unchanged by this batch.</footer>'
 put(HERE/'index.html',page('Colour, complete',body))
 # Static integrity: every local image and intra-collection link resolves.
 broken=[]
 for p in HERE.rglob('*.html'):
  if 'evidence' in p.parts:continue
  soup=BeautifulSoup(p.read_text(encoding='utf-8'),'html.parser')
  for node in soup.select('[src], a[href], link[href]'):
   url=node.get('src',node.get('href',''))
   if url.startswith(('http:','https:','mailto:','#')):continue
   target=(p.parent/unquote(urlsplit(url).path)).resolve()
   if target.name=='colour-review.zip':continue
   if not target.exists():broken.append((str(p.relative_to(HERE)),url))
 assert not broken,broken
 files=[p for p in HERE.rglob('*') if p.is_file() and p.suffix not in ['.zip','.pyc'] and '__pycache__' not in p.parts]
 with zipfile.ZipFile(HERE/'colour-review.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in files:z.write(p,p.relative_to(HERE).as_posix())
 print('Built 8 paired halls; source hashes current;',total,'native,',render,'render,',faults,'faults; links OK;',len(files),'files in ZIP')

if __name__=='__main__':main()
