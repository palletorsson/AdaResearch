from pathlib import Path
import json,hashlib,shutil,difflib,re,html,urllib.request,os
import markdown
H=Path(__file__).resolve().parent; R=H.parents[3]; B=H/'before'; D=R/'commons/maps/Fractal_RecursiveTrees'
def write(p,s):
 p=Path(p);p.parent.mkdir(parents=True,exist_ok=True);t=p.with_suffix(p.suffix+'.tmp');t.write_bytes(s.encode());os.replace(t,p)
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):checks.append({'name':name,'passed':bool(ok)})
report=json.loads((H/'museum-runtime.json').read_text());check('native probe completed without failures',report['passed'] and not report['failures'])
check('native log has no GDScript error','SCRIPT ERROR' not in (H/'museum-process.log').read_text(errors='replace'))
old=(B/'commons/maps/Fractal_RecursiveTrees/final.md').read_text(encoding='utf-8');before=(H/'text-immediately-before.md').read_text(encoding='utf-8');ours=(H/'text-after-encounter.md').read_text(encoding='utf-8');new=(D/'final.md').read_text(encoding='utf-8')
replaced=(H/'replaced-passage.md').read_text(encoding='utf-8').strip();replacement=(H/'new-passage.md').read_text(encoding='utf-8').strip()
expected=before.replace(replaced,replacement,1).replace('Look back at the two trees near the entrance:','Look back at the two studies near the entrance:',1)
check('only recorded encounter and orientation wording changed',ours==expected)
check('both source-code excerpts retained',re.findall(r'```gdscript(.*?)```',before,re.S)==re.findall(r'```gdscript(.*?)```',new,re.S) and len(re.findall(r'```gdscript',new))==2)
check('all artifact anchors retained',re.findall(r'<!-- @.*?-->',before)==re.findall(r'<!-- @.*?-->',new))
check('source specimen distinguished from solid receiver',"At the desk, the branches are visible meshes" in new and 'enlarged and made solid' in new)
maprel='commons/maps/Fractal_RecursiveTrees/map_data.json';check('only growing-tree room option changes map',(R/maprel).read_text().replace('#room:canopy','')==(B/maprel).read_text())
manifest0=json.loads((H/'before-manifest.json').read_text())
for rel in manifest0:
 if rel.startswith('algorithms/') or rel=='commons/maps/sequences/fractals.json':check('unchanged '+rel,sha(R/rel)==manifest0[rel])
layout=json.loads((D/'map_data.json').read_text())
for z,row in enumerate(layout['layers']['interactables']):
 for x,token in enumerate(row):
  if not token:continue
  base=token.split(':')[0].split('#')[0]
  check('authored work retained at %d,%d: %s'%(x,z,base),any(a['token']==base and a['cell']==[x,z] for a in report['artifacts']))
shutil.copy2(H/'under-canopy.png',D/'images/tree-canopy.png');check('chapter photo is original native PNG',sha(D/'images/tree-canopy.png')==sha(H/'under-canopy.png'))
core=R/'commons/data/museum_core_encounters.json';data=json.loads(core.read_text(encoding='utf-8'));entry=data['rooms']['Fractal_RecursiveTrees']
if not (H/'core-before-update.json').exists():dump(H/'core-before-update.json',entry)
check('prior red-tree primary retained','recursive_tree' in entry['primary_tokens'])
entry.update({'primary_tokens':['recursive_tree_2','recursive_tree'],'reason':'Follow inherited direction and length in a growing specimen and its enlarged solid canopy; compare the seeded block tree. The growing tree joins the red tree as primary because it already leads the manuscript and now carries the bodily encounter. All twelve authored placements remain.','status':'desktop_checked_headset_pending','text_sha256':sha(D/'final.md'),'map_sha256':sha(D/'map_data.json'),'learner_verified':False,'local_review':'doc/book/iterations/2026-09-25-tree-canopy/index.html','verification_scope':'Native geometry and controls: actual mouse rays, exact shared meshes/transforms, eighteen parameter bounds, standing trunk collision and default under-branch passage. No human headset, Quest profiling, all-parameter traversal, climbing, structural-engineering or learner acceptance.'})
dump(core,data);dump(H/'core-after-update.json',entry)
paths=list(manifest0)+['commons/artifacts/recursive_tree_lesson/branch_canopy.gd','commons/maps/Fractal_RecursiveTrees/images/tree-canopy.png'];manifest={}
for rel in paths:
 p=R/rel;dest=H/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest);manifest[rel]={'before':manifest0.get(rel),'after':sha(p)}
dump(H/'source-manifest.json',manifest)
for name,text,title,base in [('text-diff.html',ours,'This encounter: the same branches around a body',before),('combined-text-diff.html',new,'Current combined chapter',old)]:
 write(H/name,difflib.HtmlDiff(wrapcolumn=85).make_file(base.splitlines(),text.splitlines(),'Before',title,context=True,numlines=3))
write(H/'concurrent-editorial.diff',''.join(difflib.unified_diff(old.splitlines(True),before.splitlines(True),fromfile='turn-baseline',tofile='fresh-text-before-encounter'))+''.join(difflib.unified_diff(ours.splitlines(True),new.splitlines(True),fromfile='encounter-added',tofile='current-canonical')))
parts=[]
for rel,item in manifest.items():
 if item['before']!=item['after'] and rel.endswith(('.gd','.md','.json')):
  lines=(B/rel).read_text(encoding='utf-8').splitlines(True) if item['before'] else []
  parts+=list(difflib.unified_diff(lines,(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
write(H/'source-changes.diff',''.join(parts))
for target,source in [('branch-canopy.txt',R/'commons/artifacts/recursive_tree_lesson/branch_canopy.gd'),('lesson.txt',R/'commons/artifacts/recursive_tree_lesson/recursive_tree_lesson.gd'),('museum-log.txt',H/'museum-process.log')]:shutil.copy2(source,H/target)
dump(H/'verification.json',{'passed':all(x['passed'] for x in checks),'checks':checks})
n=len(report['checks']);inputs=len(report['desktop_input'])
write(H/'DECISIONS.md',f'''# Recursive Trees — Stand beneath the rule

The chapter already asked what the image of a tree promised a body. The original visual-only specimen remains. The new room:canopy receiver shares that source's exact branch meshes, materials and transforms, enlarges them uniformly by 1.8, and adds a convex collision hull for each. The root is at hall-relative (8.5, 0, 7.5); the first fork is 2.52 m above the floor. No second branching solver or panel is added.

All six controls remain. GROW, ANGLE, LENGTH, FORKS and RESET reach both receivers; RULE still explains the finite queue. External source resets also clear old solids. The original branches remain without colliders. All twelve authored placements and their addresses remain; the red block study still has its independent FORM/STRATA/REACH/ENDS readings. The growing tree is now formally primary alongside the red tree, aligning the core registry with the existing manuscript and new bodily encounter. Dark sphere remains secondary.

The new passage replaces the deferred shelter question with approaching the trunk, stepping beside it and looking up. Returning to the fourth generation, 65 degrees and .85 inherited length brings some tips towards the floor without changing the binary count. A fork can offer an overhead place or stand across another route; neither meaning is part of the instruction. The earlier tutorial, two source excerpts, anchors, seeded comparison and grammar-tree return remain. The critical companion distinguishes the visual specimen from the solid receiver. Earlier inventory and exact text changes are retained here.

## Evidence and limits

{n} native assertions and {inputs} actual mouse-ray events pass. Counts, exact resource/transform correspondence, reset cleanup, default opt-out, original red-tree controls, standing trunk collision and default passage beneath the branches are checked. Eighteen combinations of two/three forks, 15/35/65 degrees and .50/.70/.85 length ratio remain inside the front room's horizontal bounds, before the rear enclosure. The sweep checks geometry, not every possible traversal or interaction. {len(checks)} source/preservation checks pass.

The controlled museum walker meets the trunk near z=6.989, steps to x=9.4, walks to z=9.7 and rejoins the rear approach at (8.5, 10.4). The photos show real native rendering, including the view from that body. Final native process exits zero with no GDScript errors. Existing UID/environment/material/dressing warnings remain in the log.

No human headset, crouching, comfort, Quest performance, climbing route, every-configuration reach, continuous-play or learner acceptance is claimed. Static collision is not a structural strength, weather or biological model. No live plan/bake/save, frozen book export, sequence ordering or commit changed. Next: Fractal_CantorSet. Concurrent editorial work was fresh-read and preserved.
''')
prev=(R/'doc/book/iterations/2026-09-25-recursion-thresholds/index.html').read_text();css=re.search(r'<style>(.*?)</style>',prev,re.S).group(1)
def fig(p,t):return '<figure><a href="'+p+'"><img src="'+p+'" alt="'+html.escape(t)+'"></a><figcaption>'+html.escape(t)+'</figcaption></figure>'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Recursive Trees — Stand beneath the rule</title><style>'+css+'</style></head><body><main>'
page+='<p class="eyebrow">Ada Research · 25 September 2026 · Fractal_RecursiveTrees</p><h1>Stand beneath the rule</h1><p>The tree leaves the specimen’s scale and occupies the aisle. Its trunk stops us. Its first fork gives us somewhere to stand beneath. The branching instruction has not changed.</p><p><a href="#chapter">Read the chapter</a> · <a href="text-diff.html">Exact encounter revision</a> · <a href="/compose/sources?map=Fractal_RecursiveTrees&amp;doc=final">Read and comment</a> · <a href="DECISIONS.md">Decisions and limits</a></p>'
page+='<div class="pair">'+fig('before-view/grown.png','Before: the grown specimen and red block tree, with an open central aisle.')+fig('grown.png','After: the actual source geometry is enlarged by 1.8 and made solid. Same camera; original specimens retained.')+'</div>'
page+='<blockquote>The same fork can be something to stand beneath or something to get past. Those meanings arrive with us. The instruction contains neither.</blockquote>'
page+=fig('under-canopy.png','From the tested body after walking around the trunk: the first fork is overhead. The original growing specimen remains beside it.')
page+='<h2>Thirty-one branches can occupy another space</h2><div class="pair">'+fig('grown.png','Four generations, two forks, 35 degrees and .70 inherited length: 31 segments.')+fig('wide-low.png','The same 31 segments, now at 65 degrees and .85 inherited length. Some tips descend towards the floor.')+'</div>'
page+='<h2>A third descendant</h2>'+fig('three-forks.png','FORKS changes two children to three. At generation four, 121 segments occupy a fuller volume. This adds connections; angle and length reposition them.')
page+='<p>The six existing controls drive both versions. Each enlarged branch shares the original mesh and pose, with a matching convex collision hull. The canopy does not calculate a second tree. The red tree, grammar specimen, inverted trees, old enclosure and other works remain.</p>'
page+=f'<h2>What was checked</h2><p>{n} native checks and {inputs} actual mouse-ray events pass. All eighteen parameter combinations fit within the front room. Controlled standing-body walking meets the trunk and passes beneath the default branches. Human headset reach, comfort, crouching, Quest performance and learner acceptance remain open.</p>'
page+='<details><summary>Evidence, prior material and exact changes</summary><p><a href="museum-runtime.json">Native report</a> · <a href="museum-log.txt">Engine log</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="branch-canopy.txt">Solid receiver</a> · <a href="lesson.txt">Existing lesson connection</a> · <a href="source-changes.diff">All source changes</a> · <a href="combined-text-diff.html">Combined manuscript diff</a> · <a href="concurrent-editorial.diff">Concurrent changes separately</a> · <a href="prior-artifact-inventory.md">Prior inventory</a> · <a href="http-checks.json">HTTP checks</a></p><iframe src="text-diff.html" title="Exact encounter revision"></iframe></details>'
page+='<article id="chapter" class="chapter">'+markdown.markdown(new.replace('images/tree-canopy.png','under-canopy.png'),extensions=['footnotes','fenced_code'])+'</article><p>Next: <a href="/compose/sources?map=Fractal_CantorSet&amp;doc=final">Fractal_CantorSet</a>.</p></main></body></html>'
write(H/'index.html',page)
print('Preservation',len(checks),all(c['passed'] for c in checks));print([c for c in checks if not c['passed']]);assert all(c['passed'] for c in checks)
base='http://localhost:3003/book-review/'+H.relative_to(R).as_posix()+'/'
assets=['index.html','text-diff.html','combined-text-diff.html','concurrent-editorial.diff','grown.png','under-canopy.png','wide-low.png','three-forks.png','before-view/grown.png','DECISIONS.md','museum-runtime.json','museum-log.txt','verification.json','source-manifest.json','branch-canopy.txt','lesson.txt','source-changes.diff','prior-artifact-inventory.md'];http=[]
for asset in assets:
 try:
  with urllib.request.urlopen(base+asset,timeout=20) as response:raw=response.read();status=response.status
  http.append({'path':asset,'status':status,'passed':status==200 and hashlib.sha256(raw).hexdigest()==sha(H/asset)})
 except Exception as e:http.append({'path':asset,'passed':False,'error':str(e)})
with urllib.request.urlopen('http://localhost:3003/compose/sources?map=Fractal_RecursiveTrees&doc=final',timeout=20) as response:http.append({'path':'canonical compose','status':response.status,'passed':response.status==200})
dump(H/'http-checks.json',{'passed':all(c['passed'] for c in http),'checks':http});print('HTTP',len(http),all(c['passed'] for c in http));assert all(c['passed'] for c in http)
