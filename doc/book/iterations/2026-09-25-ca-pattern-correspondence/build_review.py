from pathlib import Path
import json,hashlib,shutil,re,difflib,html,markdown,urllib.request
H=Path(__file__).resolve().parent;R=H.parents[3];D=R/'commons/maps/CA_AgentsCircuits';B=H/'before'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
checks=[]
def check(n,v):checks.append({'name':n,'passed':bool(v)})
manifest={}
for p in B.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(B);q=R/rel;out=H/'after'/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(q,out);manifest[rel.as_posix()]={'before':sha(p),'after':sha(q)}
new_files=['commons/artifacts/ca_rule_explorer/comparison_floor.gd','commons/maps/CA_AgentsCircuits/encounter-notes.md','commons/maps/CA_AgentsCircuits/wireworld-proposal.md','commons/maps/CA_AgentsCircuits/images/ca-pattern-correspondence.png']
for rel in new_files:
 p=R/rel;out=H/'after'/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out);manifest[rel]={'before':None,'after':sha(p)}
dump(H/'source-manifest.json',manifest)
old=(B/'commons/maps/CA_AgentsCircuits/final.md').read_text(encoding='utf-8');new=(D/'final.md').read_text(encoding='utf-8')
removed=[p for p in old.split('\n\n') if p.strip() and p not in new]
check('only remembered-gap paragraph expanded',len(removed)==1 and removed[0].startswith('Choose one triangular gap'))
check('original opening and technical account retained',old.split('Choose one triangular gap')[0]==new.split('Choose one triangular gap')[0])
check('pyramid, seed comparison, classes, closing and references retained',old.split('<!-- @sierpinski_pyramid -->')[1]==new.split('<!-- @sierpinski_pyramid -->')[1])
check('all primary artifact anchors retained',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
for p in (B/'commons/maps/CA_AgentsCircuits').glob('*.md'):
 if p.name not in ['final.md','technical.md','intent.md','artifacts.md']:check('unchanged '+p.name,sha(p)==sha(D/p.name))
archive=(D/'wireworld-proposal.md').read_text(encoding='utf-8')
for name in ['technical.md','intent.md','artifacts.md']:
 check('earlier '+name+' retained whole in development proposal',(B/'commons/maps/CA_AgentsCircuits'/name).read_text(encoding='utf-8') in archive)
for rel in ['commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd','commons/artifacts/ca_rule_explorer/ca_rule_explorer.tscn','algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd','algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.tscn','commons/maps/sequences/cellularautomata.json']:
 check('unchanged '+rel,sha(B/rel)==sha(R/rel))
a=json.loads((B/'commons/maps/CA_AgentsCircuits/map_data.json').read_text());b=json.loads((D/'map_data.json').read_text())
for row in b['layers']['interactables']:
 for x,t in enumerate(row):
  if t.startswith('ca_rule_explorer:'):row[x]=t.removesuffix('#room:comparison')
check('authored map changes only optional receiver flag',a==b)
a=json.loads((H/'before-view/museum-runtime.json').read_text());b=json.loads((H/'museum-runtime.json').read_text());keys=['token','cell','position','rotation','scale']
f=lambda rows:[{k:p[k] for k in keys} for p in rows if p['token'] in ['ca_rule_explorer','sierpinski_pyramid']]
check('both authored roots and existing plinth stay in place',f(a['artifacts'])==f(b['artifacts']))
check('33 native assertions pass',len(b['checks'])==33 and b['passed'] and all(c['passed'] for c in b['checks']))
check('nine real pointer events pass',len(b['desktop_input'])==9 and all(c['hover_matches'] and c['emissions']==1 and c['clear_to_button'] for c in b['desktop_input']))
check('no GDScript errors','SCRIPT ERROR' not in (H/'museum-process.log').read_text(errors='replace'))
a=json.loads((H/'core-before-update.json').read_text());b=json.loads((H/'core-after-update.json').read_text());a['rooms'].pop('CA_AgentsCircuits');room=b['rooms'].pop('CA_AgentsCircuits');check('only this core room updated',a==b)
check('core primary tokens remain both existing works',room['primary_tokens']==['ca_rule_explorer','sierpinski_pyramid'])
check('core manuscript/map hashes match',room['text_sha256']==sha(D/'final.md') and room['map_sha256']==sha(D/'map_data.json'))
check('chapter image is original native photograph',sha(D/'images/ca-pattern-correspondence.png')==sha(H/'floor-history.png'))
dump(H/'verification.json',{'passed':all(c['passed'] for c in checks),'checks':checks})
(H/'text-diff.html').write_bytes(difflib.HtmlDiff(wrapcolumn=85).make_file(old.splitlines(),new.splitlines(),'Before: remembered comparison','After: walk into the resemblance',context=True,numlines=3).encode())
parts=[]
for rel,item in manifest.items():
 if item['before']!=item['after'] and rel.endswith(('.gd','.md','.json')):
  before=(B/rel).read_text(encoding='utf-8').splitlines(True) if item['before'] else []
  parts.extend(difflib.unified_diff(before,(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
(H/'source-changes.diff').write_bytes(''.join(parts).encode())
shutil.copy2(R/'commons/artifacts/ca_rule_explorer/comparison_floor.gd',H/'floor-receiver.txt');shutil.copy2(H/'museum-process.log',H/'museum-log.txt')
shutil.copy2(D/'wireworld-proposal.md',H/'wireworld-proposal.txt')
prev=(R/'doc/book/iterations/2026-09-25-ca-seed-crossing/index.html').read_text(encoding='utf-8');css=re.search(r'<style>(.*?)</style>',prev,re.S).group(1)
def fig(p,t):return '<figure><a href="'+p+'"><img src="'+p+'" alt="'+html.escape(t)+'"></a><figcaption>'+html.escape(t)+'</figcaption></figure>'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CA — Walk into the resemblance</title><style>'+css+'</style></head><body><main>'
page+='<p class="eyebrow">Ada Research · 25 September 2026 · CA_AgentsCircuits</p><h1>Walk into the resemblance</h1><p>The same history leaves the desk and spreads beneath your feet. A dark triangle still holds your weight. Ahead, the cube construction asks whether a similar opening means a similar space.</p>'
page+='<p><a href="#chapter">Read the chapter</a> · <a href="text-diff.html">Exact text comparison</a> · <a href="/compose/sources?map=CA_AgentsCircuits&amp;doc=final">Read and comment</a> · <a href="DECISIONS.md">Decisions and limits</a></p>'
page+='<h2>The encounter, before and after</h2><div class="pair">'+fig('before-view/room.png','Before: the held desk history and recursive construction, separated by ordinary gallery floor.')+fig('room.png','After: the same stored rows occupy a floor display between the existing works.')+'</div>'
page+='<p>The 5.76 × 4.32 m receiver has no new controls or simulation. Rule, seed and time remain at the desk. The two authored works and pyramid plinth stay in place; the museum automatically shifts its decorative sculpture to clear the new floor display.</p>'
page+='<h2>Change the beginning; keep the pyramid</h2><div class="pair">'+fig('floor-history.png','Single seed, Rule 90, generations 0–15. The floor orders the actual stored rows from the desk toward the pyramid.')+fig('pair-history.png','Two adjacent seeds, the same rule and number of steps. The fixed pyramid has not changed.')+'</div>'
page+='<blockquote>Walk into a dark triangle. The cells are empty; the floor still holds you. Here, absence is something drawn beneath your feet.</blockquote>'
page+='<div class="pair">'+fig('standing-gap.png','Eye height at the tested body’s position inside a drawn gap, looking toward the recursive object.')+fig('beside-pyramid.png','After walking beside the object. A flat history and an arrangement of overlapping cubes offer different kinds of comparison.')+'</div>'
page+='<h2>The text keeps its inquiry</h2><p>Only the remembered-gap encounter is expanded, with one native photograph. The opening, copying recipe, changing seed, classifications discussion, closing and references remain. The old Wireworld companion notes are saved whole as a development proposal; current companion notes now describe what is installed.</p>'
page+='<h2>Checked in the native museum</h2><p>33 assertions and nine actual mouse-ray events pass: controls, independent Rule 90 parity, exact shared history and colours, reset, scrolling, held and running clock, original explorer defaults, unchanged pyramid transforms, and controlled walking. Headset comfort, Quest performance, continuous gameplay and learner understanding remain untested.</p>'
page+='<details><summary>Evidence, sources and exact changes</summary><p><a href="museum-runtime.json">Native report</a> · <a href="museum-log.txt">Engine log</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="floor-receiver.txt">Floor receiver</a> · <a href="source-changes.diff">Source and companion changes</a> · <a href="wireworld-proposal.txt">Retained Wireworld proposal</a> · <a href="pointer-diagnostic/museum-runtime.json">Initial harness failure</a> · <a href="http-checks.json">HTTP checks</a></p><iframe src="text-diff.html" title="Exact chapter changes"></iframe></details>'
page+='<article id="chapter" class="chapter">'+markdown.markdown(new.replace('images/ca-pattern-correspondence.png','floor-history.png'),extensions=['footnotes','fenced_code'])+'</article><p>Next: <a href="/compose/sources?map=CA_EdgeOfChaos&amp;doc=final">CA_EdgeOfChaos</a>, following a small change in the beginning through the same procedure.</p></main></body></html>'
(H/'index.html').write_bytes(page.encode())
print('Preservation',len(checks),all(c['passed'] for c in checks));print([c for c in checks if not c['passed']]);assert all(c['passed'] for c in checks)
base='http://localhost:3003/book-review/'+H.relative_to(R).as_posix()+'/'
assets=['index.html','text-diff.html','room.png','floor-history.png','pair-history.png','standing-gap.png','beside-pyramid.png','before-view/room.png','DECISIONS.md','museum-runtime.json','museum-log.txt','verification.json','source-manifest.json','floor-receiver.txt','source-changes.diff','wireworld-proposal.txt','pointer-diagnostic/museum-runtime.json']
http=[]
for asset in assets:
 try:
  with urllib.request.urlopen(base+asset,timeout=20) as response:raw=response.read();status=response.status
  http.append({'path':asset,'status':status,'passed':status==200 and hashlib.sha256(raw).hexdigest()==sha(H/asset)})
 except Exception as e:http.append({'path':asset,'passed':False,'error':str(e)})
with urllib.request.urlopen('http://localhost:3003/compose/sources?map=CA_AgentsCircuits&doc=final',timeout=20) as response:http.append({'path':'canonical compose','status':response.status,'passed':response.status==200})
dump(H/'http-checks.json',{'passed':all(c['passed'] for c in http),'checks':http});print('HTTP',len(http),all(c['passed'] for c in http));print([c for c in http if not c['passed']]);assert all(c['passed'] for c in http)
