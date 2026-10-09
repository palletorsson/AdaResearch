from pathlib import Path
import json,hashlib,shutil,re,difflib,html,markdown,urllib.request
H=Path(__file__).resolve().parent;R=H.parents[3];D=R/'commons/maps/CA_EdgeOfChaos';B=H/'before'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
checks=[]
def check(n,v):checks.append({'name':n,'passed':bool(v)})
manifest={}
for p in B.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(B);q=R/rel;out=H/'after'/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(q,out);manifest[rel.as_posix()]={'before':sha(p),'after':sha(q)}
for rel in ['algorithms/cellularautomata/ca_showcase/walking_slice.gd','commons/maps/CA_EdgeOfChaos/encounter-notes.md','commons/maps/CA_EdgeOfChaos/images/ca-walking-slice.png']:
 p=R/rel;out=H/'after'/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out);manifest[rel]={'before':None,'after':sha(p)}
dump(H/'source-manifest.json',manifest)
old=(B/'commons/maps/CA_EdgeOfChaos/final.md').read_text(encoding='utf-8');new=(D/'final.md').read_text(encoding='utf-8')
# Separate the bounded immersion edit from concurrent editorial refinements.
a=old.index('Walk between them.');b=old.index('Return to the console.')
start=new.index('Walk between them.');end=new.index('Return to the console.')
ours=old[:a]+new[start:end]+old[b:]
(H/'immersion-only-final.md').write_bytes(ours.encode())
removed=[p for p in old.split('\n\n') if p.strip() and p not in ours]
check('this pass expands only the opening walk paragraph',len(removed)==1 and removed[0].startswith('Walk between them.'))
check('two source code excerpts preserved exactly',re.findall(r'```gdscript(.*?)```',old,re.S)==re.findall(r'```gdscript(.*?)```',new,re.S) and old.count('```gdscript')==2)
check('primary anchors retained',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
check('opening and final transition retained',old.split('Walk between them.')[0]==new.split('Walk between them.')[0] and old.split('<!-- @ -->')[1].split('[^ca-edge]:')[0]==new.split('<!-- @ -->')[1].split('[^ca-edge]:')[0])
check('integer and fractional measured result retained','Now twenty-seven addresses differ, but the largest difference is smaller than before: 0.75 instead of one.' in new)
check('concurrent storage clarification retained','In this comparison the neighbour rule stayed the same; storage decided how much of its answer could remain.' in new)
check('concurrent Langton clarification retained','This hall was conceived under the name *Edge of Chaos*.' in new and 'designated quiescent state' in new)
check('remaining secondary gallery paragraph retained',old.split('The other works remain')[1].split('<!-- @ -->')[0]==new.split('The other works remain')[1].split('<!-- @ -->')[0])
for p in (B/'commons/maps/CA_EdgeOfChaos').glob('*.md'):
 if p.name not in ['final.md','technical.md','intent.md','artifacts.md']:check('unchanged '+p.name,sha(p)==sha(D/p.name))
for rel in ['algorithms/cellularautomata/ca_showcase/difference_model.gd','algorithms/cellularautomata/ca_showcase/self_organization_ca.tscn','commons/maps/sequences/cellularautomata.json']:
 check('unchanged '+rel,sha(B/rel)==sha(R/rel))
a=json.loads((B/'commons/maps/CA_EdgeOfChaos/map_data.json').read_text());b=json.loads((D/'map_data.json').read_text())
for row in b['layers']['interactables']:
 for x,t in enumerate(row):
  if t.startswith('self_organization_ca:'):row[x]=t.removesuffix('#slice:walk')
check('map changes only optional walking receiver flag',a==b)
a=json.loads((H/'before-view/museum-runtime.json').read_text());b=json.loads((H/'museum-runtime.json').read_text());keys=['token','cell','position','rotation','scale']
check('all native artifact roots retain placement',[{k:p[k] for k in keys} for p in a['artifacts']]==[{k:p[k] for k in keys} for p in b['artifacts']])
check('75 native assertions pass',len(b['checks'])==75 and b['passed'] and all(c['passed'] for c in b['checks']))
check('twelve real pointer events pass',len(b['desktop_input'])==12 and all(c['hover_matches'] and c['emissions']==1 and c['clear_to_button'] for c in b['desktop_input']))
check('no GDScript errors','SCRIPT ERROR' not in (H/'museum-process.log').read_text(errors='replace'))
a=json.loads((H/'core-before-update.json').read_text());b=json.loads((H/'core-after-update.json').read_text());a['rooms'].pop('CA_EdgeOfChaos');room=b['rooms'].pop('CA_EdgeOfChaos');check('only this core room updated',a==b)
check('same primary role retained',room['primary_tokens']==['self_organization_ca'])
check('core hashes current',room['text_sha256']==sha(D/'final.md') and room['map_sha256']==sha(D/'map_data.json'))
check('chapter image is original native photograph',sha(D/'images/ca-walking-slice.png')==sha(H/'slice-middle-wide.png'))
dump(H/'verification.json',{'passed':all(c['passed'] for c in checks),'checks':checks})
for name,after,title in [('text-diff.html',ours,'This pass: walk to select a section'),('combined-text-diff.html',new,'Combined with concurrent editorial clarification')]:
 (H/name).write_bytes(difflib.HtmlDiff(wrapcolumn=85).make_file(old.splitlines(),after.splitlines(),'Before this pass',title,context=True,numlines=3).encode())
(H/'concurrent-editorial.diff').write_bytes(''.join(difflib.unified_diff(ours.splitlines(True),new.splitlines(True),fromfile='immersion-only',tofile='current-combined-chapter')).encode())
parts=[]
for rel,item in manifest.items():
 if item['before']!=item['after'] and rel.endswith(('.gd','.md','.json')):
  before=(B/rel).read_text(encoding='utf-8').splitlines(True) if item['before'] else []
  parts.extend(difflib.unified_diff(before,(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
(H/'source-changes.diff').write_bytes(''.join(parts).encode())
for n,source in [('walking-slice.txt',R/'algorithms/cellularautomata/ca_showcase/walking_slice.gd'),('paired-model.txt',R/'algorithms/cellularautomata/ca_showcase/difference_model.gd'),('museum-log.txt',H/'museum-process.log')]:shutil.copy2(source,H/n)
prev=(R/'doc/book/iterations/2026-09-25-ca-pattern-correspondence/index.html').read_text(encoding='utf-8');css=re.search(r'<style>(.*?)</style>',prev,re.S).group(1)
def fig(p,t):return '<figure><a href="'+p+'"><img src="'+p+'" alt="'+html.escape(t)+'"></a><figcaption>'+html.escape(t)+'</figcaption></figure>'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CA — Move past a difference</title><style>'+css+'</style></head><body><main>'
page+='<p class="eyebrow">Ada Research · 25 September 2026 · CA_EdgeOfChaos</p><h1>Move past a difference</h1><p>Walk between the volumes. Your position selects the section; the calculation does not advance with your footsteps. Something can disappear from the image while remaining in the field.</p>'
page+='<p><a href="#chapter">Read the chapter</a> · <a href="text-diff.html">This encounter’s text change</a> · <a href="/compose/sources?map=CA_EdgeOfChaos&amp;doc=final">Read and comment</a> · <a href="DECISIONS.md">Decisions and limits</a></p>'
page+='<h2>The same room, a bodily way to look</h2><div class="pair">'+fig('before-view/arrival.png','Before: two complete volumes, three spatial section cases and a shared difference image on the floor.')+fig('arrival.png','After: gold frames locate the same selected depth in both volumes. Numbered edges let the body select Z along the central passage.')+'</div>'
page+='<blockquote>Walk to six and it disappears from that picture. Come back. It is still there. We have moved past the difference, not removed it.</blockquote>'
page+='<div class="pair">'+fig('slice-5.png','Before the first update: the changed address is visible in section five. Camera at the tested body’s eye height.')+fig('slice-6.png','Walk one depth interval farther: the section no longer contains that address. Both fields and the update count are unchanged.')+'</div>'
page+='<h2>Keep the update; change the section</h2><div class="pair">'+fig('fractional-z3.png','After one fractional update, Z=3 contains no difference. The global count is still 27 addresses.')+fig('fractional-z5.png','The same update at Z=5. The centre differs by .75. Returning to this section finds it again.')+'</div>'
page+='<p>The gold frames locate Z in the volumes. The floor shows the selected X/Y image laid flat; its small depth markers sit at the edges, leaving the image clear. Walking changes the receiver, never the paired values or the scheduled run.</p>'
page+=fig('spread.png','After eleven updates, the difference has spread while its maximum has fallen. Existing display gain makes the weaker trace visible.')
page+='<h2>Keep the work that was already here</h2><p>All five artifacts, their native placements, the paired model, twelve controls, fixed floor and both source-code excerpts remain. This pass adds the early walking encounter. Concurrent editorial changes clarify the storage comparison and Langton reference; they are preserved and recorded separately.</p>'
page+='<h2>Native checks</h2><p>75 assertions and twelve actual mouse-ray events pass: all eleven body-selected depths, exact shared textures, unchanged state and time, loss and return of visibility, storage results, manual controls, run scheduling, boundary hysteresis, player recognition and the unconfigured study. No human headset, Quest performance, continuous gameplay, full secondary-gallery or learner acceptance is claimed.</p>'
page+='<details><summary>Evidence and exact changes</summary><p><a href="museum-runtime.json">Native report</a> · <a href="museum-log.txt">Engine log</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="walking-slice.txt">Walking receiver</a> · <a href="paired-model.txt">Unchanged paired model</a> · <a href="source-changes.diff">All source changes</a> · <a href="combined-text-diff.html">Combined manuscript diff</a> · <a href="concurrent-editorial.diff">Concurrent edits separately</a> · <a href="http-checks.json">HTTP checks</a></p><iframe src="text-diff.html" title="This encounter’s exact text change"></iframe></details>'
page+='<article id="chapter" class="chapter">'+markdown.markdown(new.replace('images/ca-walking-slice.png','slice-middle-wide.png'),extensions=['footnotes','fenced_code'])+'</article><p>Next: <a href="/compose/sources?map=Fractal_Recursion&amp;doc=final">Fractal_Recursion</a>.</p></main></body></html>'
(H/'index.html').write_bytes(page.encode())
print('Preservation',len(checks),all(c['passed'] for c in checks));print([c for c in checks if not c['passed']]);assert all(c['passed'] for c in checks)
base='http://localhost:3003/book-review/'+H.relative_to(R).as_posix()+'/'
assets=['index.html','text-diff.html','combined-text-diff.html','concurrent-editorial.diff','arrival.png','slice-middle-wide.png','slice-5.png','slice-6.png','fractional-z3.png','fractional-z5.png','spread.png','before-view/arrival.png','DECISIONS.md','museum-runtime.json','museum-log.txt','verification.json','source-manifest.json','walking-slice.txt','paired-model.txt','source-changes.diff']
http=[]
for asset in assets:
 try:
  with urllib.request.urlopen(base+asset,timeout=20) as response:raw=response.read();status=response.status
  http.append({'path':asset,'status':status,'passed':status==200 and hashlib.sha256(raw).hexdigest()==sha(H/asset)})
 except Exception as e:http.append({'path':asset,'passed':False,'error':str(e)})
with urllib.request.urlopen('http://localhost:3003/compose/sources?map=CA_EdgeOfChaos&doc=final',timeout=20) as response:http.append({'path':'canonical compose','status':response.status,'passed':response.status==200})
dump(H/'http-checks.json',{'passed':all(c['passed'] for c in http),'checks':http});print('HTTP',len(http),all(c['passed'] for c in http));print([c for c in http if not c['passed']]);assert all(c['passed'] for c in http)
