from pathlib import Path
import difflib, hashlib, html, json, re, shutil, urllib.request
import markdown
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
def H(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base=read(o/'baseline.json');checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 assert ok,name

# Keep existing indentation in the shared catalogues, reducing unrelated diff noise.
for path in ['commons/data/book/primitives.json','commons/data/map_authored.json']:
 previous=(o/'before'/path).read_text(encoding='utf-8')
 indent=re.search(r'\n([ \t]+)"',previous)[1]
 write(r/path,json.dumps(read(r/path),ensure_ascii=False,indent=indent)+'\n')
# The map editor expects readable grid rows, not one cell per line.
for m in ['Point_Zero','Point_One']:
 p=r/'commons/maps'/m/'map_data.json';d=read(p);s=json.dumps(d,ensure_ascii=False,indent='\t')
 def compact(match):
  try:
   value=json.loads(match[0])
   if isinstance(value,list) and all(not isinstance(v,(list,dict)) for v in value):return json.dumps(value,ensure_ascii=False)
  except ValueError:pass
  return match[0]
 s=re.sub(r'\[[^\[\]{}]*\]',compact,s)
 write(p,s+'\n')

native_count=0
for m,tag in [('Point_Zero','zero-native'),('Point_One','one-native')]:
 src=r/'ada_run/encounter_pilot'/(m+'_zero_one');dst=o/tag;dst.mkdir(exist_ok=True)
 report=read(src/'report.json');check(m+' native checks pass',report['passed'] and not report['failures'])
 native_count+=len(report['checks'])
 log=(src/'stdout.log').read_text(encoding='utf-8',errors='replace')
 check(m+' no script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
 for p in src.iterdir():
  if p.suffix=='.png' or p.name in ['report.json','stdout.log','source_manifest.json']:shutil.copy2(p,dst/p.name)
 write(dst/'warnings.json',json.dumps([x for x in log.splitlines() if 'ERROR:' in x or 'WARNING:' in x],indent=2)+'\n')

seq=read(r/'commons/maps/sequences/primitives.json')['sequences']['primitives']['maps']
check('book order begins Zero, One, Lines',seq[:3]==['Point_Zero','Point_One','Point_Lines'])
check('museum declaration agrees',read(r/'commons/data/map_authored.json')['primitives'][:3]==seq[:3])
book=read(r/'commons/data/book/primitives.json')
check('book pearls agree',[x['map'] for x in book['pearls'][:3]]==seq[:3])
beforebook=read(o/'before/commons/data/book/primitives.json')
check('other book pearls unchanged',[x for x in book['pearls'] if x['map'] not in ['Point_Zero','Point_One']]==[x for x in beforebook['pearls'] if x['map']!='Point_One'])
registry=read(r/'commons/artifacts/registry/commons_artifacts.json')['artifacts']
oldregistry=read(o/'before/commons/artifacts/registry/commons_artifacts.json')['artifacts']
check('all existing registered artifacts retained',all(registry[k]==v for k,v in oldregistry.items()))
for m in ['Point_Zero','Point_One']:
 d=read(r/'commons/maps'/m/'map_data.json');w=d['map_info']['dimensions']['width'];h=d['map_info']['dimensions']['depth']
 check(m+' grid dimensions consistent',all(len(layer)==h and all(len(row)==w for row in layer) for layer in d['layers'].values()))
 final=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 refs=set(re.findall(r'\[\^([^\]]+)\](?!:)',final));defs=set(re.findall(r'^\[\^([^\]]+)\]:',final,re.M))
 check(m+' footnotes complete',refs==defs)
oldtext=(o/'before/commons/maps/Point_One/final.md').read_text(encoding='utf-8')
author=next(p for p in oldtext.split('\n\n') if p.startswith('You can stand in a room you did not build.'))
check('author inherited-work paragraph retained exactly',author in (r/'commons/maps/Point_Zero/final.md').read_text(encoding='utf-8'))
check('old arrival opening occurs once',sum((r/'commons/maps'/m/'final.md').read_text(encoding='utf-8').count('… You arrive late.') for m in seq)==1)
for path in ['commons/maps/Point_One/evolution.json','commons/maps/Point_One/artifact_proposals.json']:
 check('preserved '+path,H(r/path)==base[path])
plan=read(r/'ada_run/em_plan.json');beforeplan=read(o/'before/ada_run/em_plan.json')
def spatial(row):return {k:v for k,v in row.items() if k not in ['pearl_index','pearls_total']}
for p in beforeplan['plans']:
 if p.get('map')=='Point_One':continue
 matches=[x for x in plan['plans'] if x.get('map')==p.get('map') and x.get('sequence')==p.get('sequence')]
 # Other running tasks may add halls, but this pass must preserve these existing rows.
 check('preserved hall '+p.get('map','?'),any(spatial(x)==spatial(p) for x in matches))

# Update source fingerprints after formatting, without changing acceptance claims.
cp=r/'commons/data/museum_core_encounters.json';core=read(cp)
for m in ['Point_Zero','Point_One']:
 core['rooms'][m]['text_sha256']=H(r/'commons/maps'/m/'final.md')
 core['rooms'][m]['map_sha256']=H(r/'commons/maps'/m/'map_data.json')
write(cp,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
changed=[path for path,h in base.items() if H(r/path)!=h]
newfiles=[p for p in (r/'commons/primitives/point').iterdir() if p.stem in ['point_condition','point_absent','point_visible','point_solid','point_held','point_pedestal','arrival_shaft']]
newfiles += [r/'commons/maps/Point_Zero'/name for name in ['final.md','intent.md','artifacts.md']]
newfiles += [r/'doc/book/iterations/2026-09-25-private-writing-notes/halls/Point_Zero.md']
for p in newfiles:
 path=p.relative_to(r).as_posix()
 if path not in changed:changed.append(path)
for path in changed:
 p=r/path;dest=o/'after'/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
 before=(o/'before'/path).read_text(encoding='utf-8') if (o/'before'/path).exists() else ''
 write(o/'diffs'/(path+'.diff'),''.join(difflib.unified_diff(before.splitlines(True),p.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+path,tofile='after/'+path)))
write(o/'changed-files.json',json.dumps(changed,indent=2)+'\n')
write(o/'source-manifest.json',json.dumps({path:{'before':base.get(path),'after':H(r/path)} for path in changed},indent=2)+'\n')
capture=r/'doc/book/captures/primitives/primitives-book.md'
manifest=read(capture.with_suffix('.manifest.json'))
check('eleven current captured chapters',len(manifest['maps'])==11 and all(H(r/x['path'])==x['sha256'] for x in manifest['maps']))
shutil.copy2(capture,o/'primitives-book.md')

decisions='''# Point Zero, then Point One

The author requested two written chapters; this implementation also uses two consecutive museum halls. Point_Zero is first in the Primitives sequence, book pearls and authored museum declaration. The default museum scene begins there. Explicit saved choices to open another hall remain valid.

- Point Zero receives the late-arrival passage, frame counter, folding, borrowed time, Alice and origin. The inherited-work paragraph is unchanged. Real-time rendering, software development and historical inheritance are distinguished. Death drive is raised as the author's critical question, not an empirical diagnosis.
- An open shaft surrounds the existing four-metre arrival drop. The actual museum walker lands before the frame counter. Point zero is attached to the origin through its existing label configuration.
- Point One opens with four equally named stations: absence, a white sphere with no collision, the same white sphere with collision, and a black sphere with pickup. The three spheres are 0.28 m across. The black point uses the existing pickup system and remains black while held.
- WORLD and LOCAL follow that exact point. The carried point activates the existing target and its falling balls. The end sphere is 1.3 m in **diameter**, on a 0.75 m pedestal. Its label is also Point one.
- The invisible-point case, code screen, force variant, Fontana and other side works remain. The old void strip and cross-wall are opened to give the coordinate room and final sculpture a continuous floor. The duplicate Point zero sign on the coordinate frame is removed. The original manuscript, map configurations and technical companion are preserved in this review's before folder. Other museum hall placements are unchanged.

## What was checked

50 native desktop checks pass, including actual gravity landing, capsule passage through the visible-only sphere and obstruction by the solid one, supplied-grabber movement, both coordinate reports, release, target activation and the pedestal dimensions. Images are native renders from inside the museum. The temporary first shaft-ray failure was the probe intersecting the walker itself; excluding that body and testing the actual fall resolved the measurement.

Headset grip, hand contact, comfort during the fall, and an unassisted beginner's reading still need the author's walk. These checks are not marked as learner or headset acceptance. Existing unrelated engine resource/material warnings are recorded alongside each native report.
'''
write(o/'DECISIONS.md',decisions)
def md(s,prefix):
 s=re.sub(r'<!--.*?-->','',s,flags=re.S)
 rendered=markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
 rendered=re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',rendered)
 rendered=re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',rendered)
 return rendered.replace('~~you~~','<del>you</del>')
def figure(src,caption):return f'<figure><a href="{src}"><img src="{src}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
def pair(a,b):return '<div class="pair">'+figure(*a)+figure(*b)+'</div>'
style='''*{box-sizing:border-box}body{margin:0;background:#f1eee6;color:#27282b;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1180px;margin:auto;padding:36px}header{padding-top:65px}h1{font-size:clamp(38px,5vw,65px);line-height:1.1;font-weight:400}h2{font-size:32px;font-weight:400}nav,.eyebrow,figcaption,summary,footer{font:14px/1.6 system-ui,sans-serif}nav{display:flex;gap:22px;flex-wrap:wrap}a{color:#635039;text-underline-offset:4px}.eyebrow{letter-spacing:.14em;text-transform:uppercase}section{margin:55px 0}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0 0 25px}img{width:100%;display:block;border-radius:3px}figcaption{padding:10px 0;color:#56534f}.reading{max-width:740px;margin:60px auto}.reading h1{font-size:44px}.reading p{margin:1.25em 0}.reading h2{margin-top:2em}pre{background:#e5e1d8;padding:20px;overflow:auto;font:14px/1.6 monospace}code{font-size:.84em}.note{border-left:3px solid #8b7c61;padding:16px 24px;background:#e9e4da}details{margin:25px 0}summary{cursor:pointer}.footnote{font-size:15px;border-top:1px solid #cbc5b8;margin-top:40px}.diff{font:14px/1.6 monospace;white-space:pre-wrap}footer{border-top:1px solid #ccc}table{width:100%;border-collapse:collapse}th,td{padding:15px;border:1px solid #cbc5b8;vertical-align:top}td{white-space:pre-wrap;font-size:15px}@media(max-width:750px){header,main,footer{padding:24px}.pair{grid-template-columns:1fr}.reading h1{font-size:36px}}'''
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point Zero, then Point One</title><style>'+style+'</style>'
page+='''<header><p class="eyebrow">The opening / 26 September 2026</p><h1>Point Zero,<br>then Point One.</h1><p>A room already running. A position acquiring a body.</p><nav><a href="#spaces">Inside the museum</a><a href="#reading">Read the two chapters</a><a href="#changes">Text changes</a><a href="primitives-book.md">Full Primitives capture</a><a href="#decisions">Decisions & checks</a></nav></header><main><p class="note">Both chapters are promoted to their canonical final.md files. The book and museum now begin Point Zero → Point One → Lines. These photographs come from the real museum scenes.</p>'''
page+='<section id="spaces"><h2>You arrive late.</h2>'
page+=pair(('zero-native/falling.png','Inside the open shaft, looking towards the running counter.'),('zero-native/arrival-counter.png','At standing height after the fall. The counter was already running.'))
page+=pair(('zero-native/folding.png','Folding Past remains the view through the lobby window.'),('zero-native/origin.png','Point zero now names the origin artifact.'))
page+='<h2>What has to be added?</h2>'+figure('one-native/corridor.png','The corridor repeats Point one: empty place, white surface, white solid, black held sphere.')
page+=pair(('one-native/visible.png','Visible white sphere. No collision body: the walking capsule passes through.'),('one-native/solid.png','Same visible size and material. Its sphere collider obstructs the walking capsule.'))
page+=pair(('one-native/held.png','The black point can be picked up and carried into the coordinate room.'),('one-native/pedestal.png','The final sphere is 1.3 metres across. The same label now asks for another bodily relation.'))
page+=figure('one-native/coordinates.png','The retained coordinate frame and WORLD/LOCAL cards follow the corridor point.')+'</section>'
page+='<section id="reading"><p class="eyebrow">The two current manuscripts</p>'
for m in ['Point_Zero','Point_One']:
 page+=f'<article class="reading" id="reading-{m}"><p><a href="/compose/sources?map={m}&doc=final">Read and comment in Compose</a></p>'+md((r/'commons/maps'/m/'final.md').read_text(encoding='utf-8'),m+'-')+'</article>'
page+='</section><section id="changes"><h2>The original and the split</h2><p>The inherited-work paragraph is kept word for word. Arrival, the counter and folding move to Point Zero. Point One receives the four conditions; its coordinate and target passages remain, with their references adjusted.</p><details><summary>Read the complete original Point One</summary><article class="reading">'+md(oldtext,'before-')+'</article></details>'
page+='<details><summary>Exact Point One changes</summary><pre class="diff">'+html.escape((o/'diffs/commons/maps/Point_One/final.md.diff').read_text(encoding='utf-8'))+'</pre></details><p><a href="diffs/commons/maps/Point_Zero/final.md.diff">New Point Zero text</a> · <a href="changed-files.json">Changed files</a></p></section>'
page+='<section id="decisions">'+md(decisions,'decisions-')+'<p><a href="zero-native/report.json">Arrival checks</a> · <a href="one-native/report.json">Point checks</a> · <a href="verification.json">Publication checks</a> · <a href="source-manifest.json">Source fingerprints</a></p></section></main><footer>Two chapters, consecutive rooms. Existing secondary works remain available. Desktop evidence; headset and learner acceptance remain open.</footer></html>'
write(o/'index.html',page)
write(o/'verification.json',json.dumps({'passed':True,'native_checks':native_count,'checks':checks},indent=2)+'\n')
print('Published',native_count,'native checks and',len(checks),'structural/preservation checks.')
