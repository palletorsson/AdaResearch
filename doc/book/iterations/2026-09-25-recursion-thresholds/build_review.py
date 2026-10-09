from pathlib import Path
import json,hashlib,shutil,difflib,re,html,urllib.request,os
import markdown
H=Path(__file__).resolve().parent; R=H.parents[3]; B=H/'before'; D=R/'commons/maps/Fractal_Recursion'
def write(p,s):
 p=Path(p);p.parent.mkdir(parents=True,exist_ok=True);t=p.with_suffix(p.suffix+'.tmp');t.write_bytes(s.encode());os.replace(t,p)
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):checks.append({'name':name,'passed':bool(ok)})
report=json.loads((H/'museum-runtime.json').read_text());check('native probe completed without failures',report['passed'] and not report['failures'])
check('native log has no GDScript error','SCRIPT ERROR' not in (H/'museum-process.log').read_text(errors='replace'))
old=(B/'commons/maps/Fractal_Recursion/final.md').read_text(encoding='utf-8');before=(H/'text-immediately-before.md').read_text(encoding='utf-8');ours=(H/'text-after-encounter.md').read_text(encoding='utf-8');new=(D/'final.md').read_text(encoding='utf-8')
addition=(H/'encounter-addition.md').read_text(encoding='utf-8').strip()
check('only recorded encounter added to fresh chapter',ours.replace('\n\n'+addition+'\n','')==before)
check('all three source-code excerpts retained',re.findall(r'```gdscript(.*?)```',before,re.S)==re.findall(r'```gdscript(.*?)```',new,re.S) and len(re.findall(r'```gdscript',new))==3)
check('all artifact anchors retained',re.findall(r'<!-- @.*?-->',before)==re.findall(r'<!-- @.*?-->',new))
check('body limit distinguished from code limit','standing body' in new and 'TERM_MIN_SIZE' in new)
check('physical terms distinguished from collapsed image','doorframes keep the original measurements' in new)
maprel='commons/maps/Fractal_Recursion/map_data.json';check('only square room option changes map',(R/maprel).read_text().replace('#room:thresholds','')==(B/maprel).read_text())
manifest0=json.loads((H/'before-manifest.json').read_text())
for rel in manifest0:
 if rel.startswith('algorithms/') or rel=='commons/maps/sequences/fractals.json':check('unchanged '+rel,sha(R/rel)==manifest0[rel])
for token in ['fractal_recursion_2','example_8_3_recursion_circles_vr','cube_subdivision','recursive_chair','science_screen','dark_sphere','recursive_table','cube_staircase','fibonacci_pagoda','synthesis_stand']:
 check('native authored work retained: '+token,any(a['token']==token for a in report['artifacts']))
shutil.copy2(H/'seven-frames.png',D/'images/recursion-thresholds.png');check('chapter photograph is original native PNG',sha(D/'images/recursion-thresholds.png')==sha(H/'seven-frames.png'))
core=R/'commons/data/museum_core_encounters.json';data=json.loads(core.read_text(encoding='utf-8'));entry=data['rooms']['Fractal_Recursion'];dump(H/'core-before-update.json',entry)
check('existing two primary works retained',entry['primary_tokens']==['fractal_recursion_2','example_8_3_recursion_circles_vr'])
entry.update({'reason':'One self-call and four self-calls remain the teaching core. The original square terms also become floor-standing doorframes; the standing body meets a limit before the function does. All ten authored works and supporting manuscript encounters remain.','status':'desktop_checked_headset_pending','text_sha256':sha(D/'final.md'),'map_sha256':sha(D/'map_data.json'),'learner_verified':False,'local_review':'doc/book/iterations/2026-09-25-recursion-thresholds/index.html','verification_scope':'Native museum: actual mouse-ray controls, term correspondence, size cutoff, standing-body passage and collision, side bypass and unconfigured lesson. No human headset, Quest profiling, continuous gameplay or learner acceptance.'})
dump(core,data);dump(H/'core-after-update.json',entry)
paths=list(manifest0)+['commons/artifacts/recursion_lesson/threshold_walk.gd','commons/maps/Fractal_Recursion/images/recursion-thresholds.png'];manifest={}
for rel in paths:
 p=R/rel;dest=H/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest);manifest[rel]={'before':manifest0.get(rel),'after':sha(p)}
dump(H/'source-manifest.json',manifest)
for name,text,title,base in [('text-diff.html',ours,'This encounter: the same sizes at body scale',before),('combined-text-diff.html',new,'Current combined chapter',old)]:
 write(H/name,difflib.HtmlDiff(wrapcolumn=85).make_file(base.splitlines(),text.splitlines(),'Before',title,context=True,numlines=3))
write(H/'concurrent-editorial.diff',''.join(difflib.unified_diff(old.splitlines(True),before.splitlines(True),fromfile='turn-baseline',tofile='fresh-text-before-encounter'))+''.join(difflib.unified_diff(ours.splitlines(True),new.splitlines(True),fromfile='encounter-added',tofile='current-canonical')))
parts=[]
for rel,item in manifest.items():
 if item['before']!=item['after'] and rel.endswith(('.gd','.md','.json')):
  lines=(B/rel).read_text(encoding='utf-8').splitlines(True) if item['before'] else []
  parts+=list(difflib.unified_diff(lines,(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
write(H/'source-changes.diff',''.join(parts))
for target,source in [('threshold-walk.txt',R/'commons/artifacts/recursion_lesson/threshold_walk.gd'),('lesson.txt',R/'commons/artifacts/recursion_lesson/recursion_lesson.gd'),('museum-log.txt',H/'museum-process.log')]:shutil.copy2(source,H/target)
dump(H/'verification.json',{'passed':all(x['passed'] for x in checks),'checks':checks})
n=len(report['checks']);inputs=len(report['desktop_input'])
write(H/'DECISIONS.md',f'''# Recursion: an opening for whom?

The first desk already generates decreasing square sizes. This pass gives those actual terms a second receiver: floor-standing frames in the central aisle. The original executor, stopping conditions, three code excerpts, four manuscript encounters, ten authored works and two primary roles remain.

The new receiver is opt-in through room:thresholds. It reads the source term list, including its minimum-size cutoff. It does not duplicate the algorithm or treat requested depth as the number actually drawn. MORE/LESS/BEGIN reach both receivers. LAYOUT/COLLAPSE change the desk image; physical term sizes remain. Frame spacing and bar thickness are authored architecture, not recursive results.

The first outer square is 2.2 m; its opening is 2.09 m wide and 2.145 m high. The second is 1.1 m, with a 0.99 by 1.045 m opening. A standing desktop body passes the first, meets the second, steps to x=9.5, passes the last frame and returns to the centre aisle and the retained collection. No shrink, flight, teleporter or new control panel is introduced. This does not establish what every human body, crouch or mobility mode can do.

The chapter adds two encounter paragraphs and a native photograph. Earlier prose and all source excerpts are retained. Technical/intent/inventory companions distinguish the two formal primary works from four manuscript encounters; the stale absent boolean cube listing is corrected without deleting an artifact. The prior inventory remains here. Concurrent editorial work is fresh-read and separately recorded where it differs.

## Verification and its limits

{n} native assertions and {inputs} actual mouse-ray control events pass. Checks include exact seven sizes, both stopping conditions, count changes, unchanged terms under display changes, default opt-out, standing collision and an ordinary bypass. {len(checks)} preservation/source checks pass. Rendered images are original native PNGs. Native process exits zero with no GDScript errors; existing engine UID/environment/material/time-budget and shutdown leak warnings remain in the log.

Two initial diagnostics are preserved. One incorrectly counted museum dressing as authored map works. Both attempted to finish a bypass at the edge of the existing chair's side console; that exact target is obstructed. The final route stays in the actual aisle and returns to its centre. The hall was not altered to satisfy those mistaken targets.

Human headset reach/readability, crouching, comfort, Quest performance, continuous play, all secondary interactions and learner acceptance remain untested. No live museum bake/save, sequence ordering, frozen export or commit changed. Next: Fractal_RecursiveTrees.
''')
prev=(R/'doc/book/iterations/2026-09-25-ca-walking-slice/index.html').read_text();css=re.search(r'<style>(.*?)</style>',prev,re.S).group(1)
def fig(p,t):return '<figure><a href="'+p+'"><img src="'+p+'" alt="'+html.escape(t)+'"></a><figcaption>'+html.escape(t)+'</figcaption></figure>'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Recursion — An opening for whom?</title><style>'+css+'</style></head><body><main>'
page+='<p class="eyebrow">Ada Research · 25 September 2026 · Fractal_Recursion</p><h1>An opening for whom?</h1><p>The same rule reaches a different limit when its squares become doorframes. We keep the four studies and bring the first one onto the floor.</p><p><a href="#chapter">Read the chapter</a> · <a href="text-diff.html">Exact encounter revision</a> · <a href="/compose/sources?map=Fractal_Recursion&amp;doc=final">Read and comment</a> · <a href="DECISIONS.md">Decisions and limits</a></p>'
page+='<div class="pair">'+fig('before-view/arrival.png','Before: the four studies and central aisle.')+fig('arrival.png','After: the first 2.2 m square also stands as a doorway. Same camera and retained collection.')+'</div>'
page+='<blockquote>The instruction keeps making openings after it has stopped making a passage for you.</blockquote>'
page+=fig('seven-frames.png','MORE adds the same terms to the desk and room: 2.2, 1.1, .55, .275, .1375, .06875 and .034375 metres. Each base meets the floor.')
page+='<div class="pair">'+fig('body-limit.png','From the tested standing body: the second lintel stops forward movement. It remains possible to look over it.')+fig('alongside.png','The ordinary floor beside the frames allows a return to the central aisle and the remaining works.')+'</div>'
page+='<h2>A drawn size and a physical opening</h2>'+fig('desk-and-doors.png','LAYOUT spreads the squares at the desk. The floor frames retain their original measured sizes; COLLAPSE likewise changes only the image.')
page+='<p>The first clear opening is 2.09 × 2.145 m; the second is 0.99 × 1.045 m. Frame thickness matters. So does the body we brought to it. The comparison leaves room for another body and another route.</p>'
page+=f'<h2>What was checked</h2><p>{n} native checks and {inputs} actual mouse-ray events pass. The standing museum body passes the first opening, meets the second and reaches the retained collection by the aisle. Human headset, crouching, comfort, Quest performance and learner acceptance are still pending.</p>'
page+='<details><summary>Evidence, prior material and exact changes</summary><p><a href="museum-runtime.json">Native report</a> · <a href="museum-log.txt">Engine log</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="threshold-walk.txt">Doorframe receiver</a> · <a href="lesson.txt">Existing lesson connection</a> · <a href="source-changes.diff">All source changes</a> · <a href="combined-text-diff.html">Combined manuscript diff</a> · <a href="concurrent-editorial.diff">Concurrent changes separately</a> · <a href="prior-artifact-inventory.md">Prior inventory</a> · <a href="http-checks.json">HTTP checks</a></p><iframe src="text-diff.html" title="Exact encounter revision"></iframe></details>'
page+='<article id="chapter" class="chapter">'+markdown.markdown(new.replace('images/recursion-thresholds.png','seven-frames.png'),extensions=['footnotes','fenced_code'])+'</article><p>Next: <a href="/compose/sources?map=Fractal_RecursiveTrees&amp;doc=final">Fractal_RecursiveTrees</a>.</p></main></body></html>'
write(H/'index.html',page)
print('Preservation',len(checks),all(c['passed'] for c in checks));print([c for c in checks if not c['passed']]);assert all(c['passed'] for c in checks)
base='http://localhost:3003/book-review/'+H.relative_to(R).as_posix()+'/'
assets=['index.html','text-diff.html','combined-text-diff.html','concurrent-editorial.diff','arrival.png','seven-frames.png','body-limit.png','alongside.png','desk-and-doors.png','before-view/arrival.png','DECISIONS.md','museum-runtime.json','museum-log.txt','verification.json','source-manifest.json','threshold-walk.txt','lesson.txt','source-changes.diff','prior-artifact-inventory.md'];http=[]
for asset in assets:
 try:
  with urllib.request.urlopen(base+asset,timeout=20) as response:raw=response.read();status=response.status
  http.append({'path':asset,'status':status,'passed':status==200 and hashlib.sha256(raw).hexdigest()==sha(H/asset)})
 except Exception as e:http.append({'path':asset,'passed':False,'error':str(e)})
with urllib.request.urlopen('http://localhost:3003/compose/sources?map=Fractal_Recursion&doc=final',timeout=20) as response:http.append({'path':'canonical compose','status':response.status,'passed':response.status==200})
dump(H/'http-checks.json',{'passed':all(c['passed'] for c in http),'checks':http});print('HTTP',len(http),all(c['passed'] for c in http));assert all(c['passed'] for c in http)
