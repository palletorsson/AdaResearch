from pathlib import Path
import difflib,hashlib,html,json,re,shutil
import markdown
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix()
maps=['Fractal_Recursion','Fractal_RecursiveTrees'];checks=[]
def H(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
def check(label,ok):checks.append({'name':label,'passed':bool(ok)});assert ok,label
base=read(o/'baseline.json');owned=read(o/'changed-files.json');concurrent=read(o/'concurrent-immersion.json')
for path,h in concurrent.items():check('concurrent immersion retained '+path,H(r/path)==h)
for path,h in base.items():
 if path not in concurrent and path not in owned+['commons/data/museum_core_encounters.json']:check('preserved '+path,H(r/path)==h)
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 check(m+' code excerpts retained',re.findall(r'```.*?```',a,re.S)==re.findall(r'```.*?```',b,re.S))
 check(m+' encounter anchors retained',re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',b))
 for name in ['final.md','intent.md']:
  p=r/'commons/maps'/m/name;dst=o/'after/commons/maps'/m/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)
  old=(o/'before/commons/maps'/m/name).read_text(encoding='utf-8').splitlines(True)
  write(o/(m+'.'+name+'.diff'),''.join(difflib.unified_diff(old,p.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+m+'/'+name,tofile='after/'+m+'/'+name)))
native=[];warnings=[]
for tag in ['recursion-combined','trees-native']:
 d=read(o/tag/'report.json');log=(o/tag/'stdout.log').read_text(errors='replace')
 check(tag+' checks passed',d['passed'] and not d['failures']);native+=d['checks']
 check(tag+' process exited zero',read(o/tag/'process.json')['exit_code']==0)
 check(tag+' no script/shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
 warnings += [line for line in log.splitlines() if 'WARNING:' in line or 'ERROR:' in line]
write(o/'engine-warnings.json',json.dumps(list(dict.fromkeys(warnings)),indent=2)+'\n')
capture=r/'doc/book/captures/fractals/fractals-book.md';manifest=read(capture.with_suffix('.manifest.json'))
check('seven captured chapters current',len(manifest['maps'])==7 and all(H(r/x['path'])==x['sha256'] for x in manifest['maps']))
check('capture hash current',H(capture)==manifest['output_sha256']);shutil.copy2(capture,o/capture.name)
cp=r/'commons/data/museum_core_encounters.json';core=read(cp);oldcore=json.loads(json.dumps(core));write(o/'core-before-update.json',json.dumps(oldcore,ensure_ascii=False,indent=2)+'\n')
for m in maps:core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/index.html')
write(cp,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
allowed={'text_sha256','map_sha256','local_review'}
for m in maps:check(m+' roles/statuses retained',{k:v for k,v in oldcore['rooms'][m].items() if k not in allowed}=={k:v for k,v in core['rooms'][m].items() if k not in allowed})
check('other core records retained',all(v==oldcore['rooms'][m] for m,v in core['rooms'].items() if m not in maps))
queue=read(r/'doc/tasks/book_fractals.json');check('all 23 earlier task decisions preserved',len(queue['tasks'])==23 and all(t['status']=='done' for t in queue['tasks']) and H(r/'doc/tasks/book_fractals.json')==base['doc/tasks/book_fractals.json'])
decisions='''# Fractals opening: repetition, allocation, recognition

25 September 2026. A restrained follow-up to Claude's already applied Fractals review. All 23 queue items were already marked done; none is re-applied, reopened or re-certified here.

## Decisions

- **Keep the encounters.** Both mature chapters, every artifact anchor, all code excerpts and both critical essays remain. This editorial pass introduces no artifact or control panel. A concurrent immersion pass adds the square study’s threshold receiver and one map opt-in; its encounter and companion changes are preserved and attributed below. The existing supporting collection stays.
- **Recursion is a way in.** The seven squares demonstrate a recursive construction with an actual stopping condition. Smaller copies alone do not establish a fractal. The paragraph now leads into the exact fractal constructions ahead and returns to the last square the room actually draws. The loop/self-call distinction and “We had to look behind the image” remain. Shiffman is credited at the first code excerpt. The explanatory account is attributed to his introductory chapter, rather than presented as a complete definition directly verified in Mandelbrot's 1982 book.
- **Watch how a tree is made.** The growth paragraph separates the generation queue from one possible depth-first self-call. Recursion does not force every implementation to draw in that order. The rear grammar tree keeps its sentence while angle changes its drawing; the three works invite a comparison rather than an exclusive taxonomy. Their lack of environmental response remains the critical question.
- **Repair the scaffolding.** Both older intent files still described unbounded complexity, unseeded variation, obsolete map numbers and missing controls. Updated them to the installed encounters and left the earlier texts intact in before/. They distinguish an image of shelter from an implemented supporting structure. Speculative bodily development remains available. The concurrent intent correction describes the new threshold receiver and distinguishes four manuscript encounters from the two promoted primary works.
- **No uniform pressure.** The rest of these chapters is strong and stays. This is not another full review of Claude's work. Next: Cantor and Koch/Sierpinski, with particular care for pacing and the relation between removal, length and bodily passage.

## What was checked

Two isolated native museum runs, 27 passing checks including capture-camera checks. Supplied signals reach the existing physical buttons. Seven stored squares remain after COLLAPSE; five ring levels request 341 rings while dust loses its fifth level at the cutoff. DRILL and SPREAD both leave 85 cells after twelve splits, at depths twelve and three. Four binary tree generations leave 31 segments; the same depth with three children leaves 121. Changing angle retains the count. The growing branches have no collision support. The red tree retains seed 12345 under STRATA. The grammar work is present, and its angle callback redraws without rewriting the string (source inspection).

The paired PNGs are original native interior renders from the same camera for each comparison. They show different states of existing artifacts, not before/after geometry edits. These two runs test no tracked headset, controller reach, comfort, Quest performance, continuous traversal or learner acceptance. The separate threshold probe does exercise a controlled desktop body through the first opening, against the second and around the side route. Engine UID/environment/material warnings remain in engine-warnings.json. No script or shader errors were reported; both owned processes exited zero.

## Reading source

[Daniel Shiffman, “What Is a Fractal?”](https://natureofcode.com/fractals/#what-is-a-fractal), read 25 September 2026, supports the self-similarity/fine-structure distinction and Mandelbrot naming note. Exact example numbering in the attribution follows the installed source-file headers, which refer to the earlier Processing examples. The museum's GDScript, map tokens and physical lesson fixtures are the evidence for what these rooms currently do.

Canonical final.md files and intent notes are updated. The seven-hall capture is refreshed. Two core review links and digests are refreshed; acceptance statuses and artifact roles remain. The review queue and live museum plan are unchanged. Concurrent threshold work changed one map token, the shared fixture and a new threshold receiver, plus the encounter paragraphs, image and supporting notes. Exact retained hashes are in concurrent-immersion.json. Its separate 43-check museum report passes; the focused comparison was rerun against the combined implementation. No commit.
'''
threshold=read(r/'doc/book/iterations/2026-09-25-recursion-thresholds/museum-runtime.json')
check('concurrent threshold native report passes',threshold['passed'] and not threshold['failures'] and len(threshold['checks'])==43)
write(o/'threshold-native-report.json',json.dumps(threshold,ensure_ascii=False,indent=2)+'\n')
decisions += '\n## Concurrent immersion retained\n\nThe full reading and Recursion diff include the independently developed floor-standing thresholds. The editorial-only snapshot remains in editorial-after/. [Threshold encounter: native report](threshold-native-report.json). Its 43 native assertions include controlled walking and actual mouse-ray operation; headset acceptance remains open.\n'
write(o/'DECISIONS.md',decisions)
write(o/'source-manifest.json',json.dumps({p:{'before':base[p],'after':H(r/p)} for p in base if p!='commons/data/museum_core_encounters.json'},indent=2)+'\n')
def md(s,prefix=''):
 s=re.sub(r'<!--.*?-->','',s,flags=re.S)
 rendered=markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
 if prefix:
  rendered=re.sub(r'id="([^"]+)"',lambda x:'id="'+prefix+x[1]+'"',rendered)
  rendered=re.sub(r'href="#([^"]+)"',lambda x:'href="#'+prefix+x[1]+'"',rendered)
 return rendered
def figure(path,caption):return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'
def pair(a,b):return '<div class="pair">'+figure(*a)+figure(*b)+'</div>'
def diff_rows(a,b):
 aa=a.split('\n\n');bb=b.split('\n\n');rows=[]
 for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb).get_opcodes():
  if tag!='equal':rows.append('<tr><td>'+html.escape('\n\n'.join(aa[i:j]))+'</td><td>'+html.escape('\n\n'.join(bb[k:l]))+'</td></tr>')
 return '<div class="comparison"><table><thead><tr><th>Before this pass</th><th>Current final.md</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table></div>'
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Fractals — again, a fork, a choice</title><style>
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#f1eee5;color:#252a2b;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1240px;margin:auto;padding:34px}header{padding-top:64px}h1{font-size:clamp(32px,4vw,54px);line-height:1.13;max-width:860px}h2{font-size:32px;line-height:1.25}h3{font-size:23px}a{color:#14616a;text-underline-offset:4px}nav{display:flex;gap:18px;flex-wrap:wrap;font:14px/1.5 system-ui}.eyebrow{font:12px system-ui;letter-spacing:.14em;text-transform:uppercase;color:#67706b}.lead{max-width:820px;font-size:23px}.note{background:#e3e9df;padding:20px 25px;border-left:4px solid #546c5b;font:16px/1.65 system-ui}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin:24px 0}figure{margin:0}img{display:block;width:100%;height:auto;background:#14202a;border-radius:3px}figcaption{font:14px/1.55 system-ui;padding:10px 0;color:#525957}section{padding-top:32px;margin-top:30px;border-top:1px solid #c8ccc4}.reading{max-width:780px;margin:40px auto}.reading p{margin:1.15em 0}pre{overflow:auto;background:#e3e4dd;padding:16px;font:14px/1.6 Consolas,monospace}code{font-size:.86em}.comparison{overflow:auto}table{border-collapse:collapse;width:100%;table-layout:fixed;font:15px/1.65 system-ui}td,th{border:1px solid #c7cbc4;padding:18px;text-align:left;vertical-align:top;white-space:pre-wrap;overflow-wrap:anywhere}th{background:#dfe6dc}td:first-child{background:#efe4de}td:last-child{background:#e5ecdf}details{margin:20px 0}summary{cursor:pointer;font:16px/1.5 system-ui;padding:10px 0}.footnote{font-size:15px}footer{font:14px/1.6 system-ui;color:#58635b}@media(max-width:720px){header,main,footer{padding:22px}.pair{grid-template-columns:1fr}.comparison table{min-width:660px}}
</style><header><p class="eyebrow">Endless museum / Fractals / 25 September 2026</p><h1>Again, a fork, a choice</h1><p class="lead">Two opening halls ask where a repeated instruction spends its work, and when the result begins to look like something we know.</p><nav><a href="#Fractal_Recursion">Recursion</a><a href="#Fractal_RecursiveTrees">Trees</a><a href="#decisions">Decisions & evidence</a><a href="fractals-book.md">Full seven-hall capture</a></nav></header><main><p class="note">Claude had already addressed all items in the review queue. This pass keeps the encounters, clarifies two explanations, and repairs their older intent notes. A concurrent threshold study and its new encounter paragraphs are retained in the reading. The image pairs below show the existing artifacts in different states, photographed inside the native museum.</p>
'''
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 page+=f'<section id="{m}"><p class="eyebrow">{m.replace("_"," ")}</p>'
 if m=='Fractal_Recursion':
  page+='<h2>The room has stopped where a rule could go on.</h2><p>The same seven squares can become almost invisible. The same 85 cells can gather their detail in very different places.</p>'
  page+=pair(('recursion-combined/seven-squares.png','Seven nested squares at the desk’s maximum depth.'),('recursion-combined/seven-coincident.png','COLLAPSE: seven stored squares remain; their drawn sizes coincide.'))
  page+=pair(('recursion-combined/drill.png','DRILL — twelve splits, 85 cells, deepest level twelve.'),('recursion-combined/spread.png','SPREAD — twelve splits, 85 cells, deepest level three.'))
 else:
  page+='<h2>Shorter branches do not mean fewer branches.</h2><p>Keep the depth and proportions. A third descendant changes what fills the room. The tree remains a visible construction without climbable branches.</p>'
  page+=pair(('trees-native/two-descendants.png','Two descendants per fork: four generations and 31 segments, including the trunk.'),('trees-native/three-descendants.png','Three descendants per fork: the same four generations leave 121 segments.'))
 page+=f'<details><summary>Exact changed passages · <a href="{m}.final.md.diff">plain-text diff</a></summary>'+diff_rows(a,b)+'</details>'
 page+=f'<details><summary>Intent correction · <a href="{m}.intent.md.diff">plain-text diff</a></summary>'+md((r/'commons/maps'/m/'intent.md').read_text(encoding='utf-8'))+'</details>'
 reading=md(b,m+'-')
 for image in re.findall(r'src="(images/[^"]+)"',reading):
  src=r/'commons/maps'/m/image;dst=o/'chapter-images'/m/image;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
  reading=reading.replace('src="'+image+'"','src="'+dst.relative_to(o).as_posix()+'"')
 page+=f'<article class="reading" id="reading-{m}">'+reading+'</article></section>'
page+='<section id="decisions">'+md(decisions)+'<p><a href="DECISIONS.md">Decision record</a> · <a href="verification.json">Checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="engine-warnings.json">Engine warnings</a></p><p><a href="recursion-combined/report.json">Recursion native report</a> · <a href="trees-native/report.json">Trees native report</a></p></section></main><footer>Current manuscript snapshots and exact prior text are retained beside this page. Museum state comparisons are native images, not generated illustrations. Headset testing remains distinct from these desktop checks.</footer></html>'
write(o/'index.html',page)
write(o/'verification.json',json.dumps({'passed':True,'checks':checks,'native_checks':len(native),'scope':'Two opening halls only; no new headset or learner acceptance'},indent=2)+'\n')
print('Published',len(checks),'preservation/publication checks and',len(native),'native checks')
