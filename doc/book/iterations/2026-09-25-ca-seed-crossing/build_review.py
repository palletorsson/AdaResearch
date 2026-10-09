from pathlib import Path
import json,hashlib,shutil,re,difflib,html,markdown,urllib.request
H=Path(__file__).resolve().parent;R=H.parents[3];D=R/'commons/maps/CA_SoftRules';B=H/'before'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
checks=[]
def check(n,v):checks.append({'name':n,'passed':bool(v)})
manifest={}
for p in B.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(B);q=R/rel;out=H/'after'/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(q,out);manifest[rel.as_posix()]={'before':sha(p),'after':sha(q)}
for rel in ['commons/artifacts/rd_artifact/walk_seed.gd','commons/maps/CA_SoftRules/encounter-notes.md','commons/maps/CA_SoftRules/images/ca-seed-crossing.png']:
 p=R/rel;out=H/'after'/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out);manifest[rel]={'before':None,'after':sha(p)}
dump(H/'source-manifest.json',manifest)
old=(B/'commons/maps/CA_SoftRules/final.md').read_text(encoding='utf-8');new=(D/'final.md').read_text(encoding='utf-8')
removed=[p for p in old.split('\n\n') if p.strip() and p not in new]
check('only original INJECT paragraph expanded',len(removed)==1 and removed[0].startswith('Try INJECT.'))
check('last three original INJECT sentences retained','We are no longer only watching a prepared beginning; we have entered another event into its history. REPLAY can restore that beginning. It cannot make our first encounter with the difference happen again.' in new)
check('three code excerpts preserved exactly',re.findall(r'```gdscript(.*?)```',old,re.S)==re.findall(r'```gdscript(.*?)```',new,re.S) and old.count('```gdscript')==3)
check('clockmaker and concluding passage preserved',old.split('<!-- @the_clockmaker_of_rules -->')[1]==new.split('<!-- @the_clockmaker_of_rules -->')[1])
check('artifact anchors preserved',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
for p in (B/'commons/maps/CA_SoftRules').glob('*.md'):
 if p.name not in ['final.md','technical.md','intent.md','artifacts.md']:check('unchanged '+p.name,sha(p)==sha(D/p.name))
for rel in ['commons/artifacts/rd_artifact/live_field.gd','commons/artifacts/rd_artifact/rd_artifact.tscn','commons/graph_grammar/operations/rd_displace_op.gd','commons/maps/sequences/cellularautomata.json']:
 check('unchanged '+rel,sha(B/rel)==sha(R/rel))
a=json.loads((B/'commons/maps/CA_SoftRules/map_data.json').read_text());b=json.loads((D/'map_data.json').read_text())
for z,row in enumerate(b['layers']['interactables']):
 for x,token in enumerate(row):
  if token=='rd_artifact:0:0#study:exchange#plinth:0#seed:walk':b['layers']['interactables'][z][x]=token.removesuffix('#seed:walk')
check('map differs only by opt-in seed flag',a==b)
a=json.loads((H/'before-view/museum-runtime.json').read_text());b=json.loads((H/'museum-runtime.json').read_text());keys=['token','cell','position','scale','rotation']
check('all native root placements retained',[{k:p[k] for k in keys} for p in a['artifacts']]==[{k:p[k] for k in keys} for p in b['artifacts']])
check('49 native assertions pass',len(b['checks'])==49 and b['passed'] and all(c['passed'] for c in b['checks']))
check('eight real pointer events pass',len(b['desktop_input'])==8 and all(c['hover_matches'] and c['emissions']==1 and c['clear_to_button'] for c in b['desktop_input']))
check('no GDScript errors','SCRIPT ERROR' not in (H/'museum-process.log').read_text(errors='replace'))
a=json.loads((H/'core-before-update.json').read_text());b=json.loads((H/'core-after-update.json').read_text());a['rooms'].pop('CA_SoftRules');room=b['rooms'].pop('CA_SoftRules');check('only this core room updated',a==b)
check('core manuscript and map hashes current',room['text_sha256']==sha(D/'final.md') and room['map_sha256']==sha(D/'map_data.json'))
check('canonical image is original native photograph',sha(D/'images/ca-seed-crossing.png')==sha(H/'seeded.png'))
dump(H/'verification.json',{'passed':all(c['passed'] for c in checks),'checks':checks})
(H/'text-diff.html').write_bytes(difflib.HtmlDiff(wrapcolumn=85).make_file(old.splitlines(),new.splitlines(),'Before: existing INJECT encounter','After: body crossing and dispersal',context=True,numlines=3).encode())
parts=[]
for rel,item in manifest.items():
 if item['before']!=item['after'] and rel.endswith(('.gd','.md')):
  before=(B/rel).read_text(encoding='utf-8').splitlines(True) if item['before'] else []
  parts.extend(difflib.unified_diff(before,(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
(H/'source-changes.diff').write_bytes(''.join(parts).encode())
shutil.copy2(R/'commons/artifacts/rd_artifact/walk_seed.gd',H/'walk-seed.txt');shutil.copy2(H/'museum-process.log',H/'museum-log.txt')
prev=(R/'doc/book/iterations/2026-09-25-ca-presence/index.html').read_text(encoding='utf-8');css=re.search(r'<style>(.*?)</style>',prev,re.S).group(1)
def fig(src,cap):return '<figure><a href="'+src+'"><img src="'+src+'" alt="'+html.escape(cap)+'"></a><figcaption>'+html.escape(cap)+'</figcaption></figure>'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CA Soft Rules — leave a seed</title><style>'+css+'</style><body><main><p class="eyebrow">ADA RESEARCH · 25 SEPTEMBER 2026 · CELLULAR AUTOMATA</p><h1>Leave a seed</h1>'
page+='<p>A small mark between the curved walls gives the visitor an action in the field. Cross it: both sides receive the same seed. What happens next belongs to their existing relations.</p><p><a href="#chapter">Read the chapter</a> · <a href="text-diff.html">Exact text changes</a> · <a href="DECISIONS.md">Decisions and evidence</a> · <a href="/compose/sources?map=CA_SoftRules&amp;doc=final">Read and comment</a></p>'
page+='<h2>From the desk into the aisle</h2><div class="pair">'+fig('before-view/arrival.png','Before: the two field tables, curved walls and existing side desk.')+fig('arrival.png','After: a floor mark between the displays offers the same INJECT action through a crossing.')+'</div>'
page+='<h2>One arrival, two seeds</h2><div class="pair">'+fig('seeded.png','The body enters after 100 updates. The existing nine-cell patch is placed in both fields, without advancing either clock.')+fig('after-seed-100.png','After 100 further updates. The new patch thins in A; B retains a fainter square. The earlier, larger pattern continues spreading in A.')+'</div>'
page+='<p>Standing in the square does not keep writing the seed. Leaving and returning allows another intervention. You can also pass beside it. The floor remains ordinary museum support.</p>'
page+='<h2>The useful surprise</h2><p>The first test expected exchange to preserve the small seed more strongly. It did not. One update carries concentration beyond its original edge; after a hundred, its centre holds less V with exchange than without it. The rule was retained, and the text followed the result.</p><details><summary>The measured comparison</summary><p>At the unseeded neighbour (6,15), one update gives A V=.02325669, compared with .00332856 in the matched no-entry control; B remains zero there. After 100 subsequent updates the new patch centre (4,15) holds .00515910 in A and .03019554 in B, both below the planted .25. These measurements concern this beginning, location, timing and parameter set.</p></details>'
page+='<div class="pair">'+fig('body-seeded.png','The actual museum body camera sees the new patch from within the display bay.')+fig('first-spread.png','One update after the crossing: the stored field, rather than a separate animation, drives both tables and walls.')+'</div>'
page+='<blockquote>Stay on the mark. It does not keep replenishing the seed. Leave and return to place it again.</blockquote>'
page+='<h2>Preserved and checked</h2><p>All six artifacts, their roles and native root placements; the original solver, constants, buffers, eight controls and shared textures; the preceding chapter, three code excerpts and complete clockmaker passage. The floor receiver is optional and the unconfigured study retains its original behaviour.</p><p>49 native assertions and eight mouse-ray events pass, including body entry, exit, return and bypass. Controlled desktop motion and clock opportunities; no human headset, Quest performance, continuous gameplay or full rear-gallery acceptance. The initial compile failure and rejected persistence expectation are retained in the evidence.</p>'
page+='<details><summary>Native reports, sources and differences</summary><p><a href="museum-runtime.json">Final native report</a> · <a href="museum-log.txt">Engine log</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="walk-seed.txt">Floor receiver source</a> · <a href="source-changes.diff">Complete source/text diff</a> · <a href="seed-diagnostic/museum-runtime.json">Rejected persistence expectation</a> · <a href="first-native/museum-runtime.json">Initial compile diagnostic</a> · <a href="http-checks.json">Publication checks</a></p><iframe src="text-diff.html" title="Exact manuscript revision"></iframe></details>'
page+='<article id="chapter" class="chapter">'+markdown.markdown(new.replace('images/ca-seed-crossing.png','seeded.png'),extensions=['footnotes','fenced_code'])+'</article><p>Next in the active sequence: <a href="/compose/sources?map=CA_AgentsCircuits&amp;doc=final">CA Agents and Circuits</a>.</p></main></body></html>'
(H/'index.html').write_bytes(page.encode())
print('Preservation',len(checks),all(c['passed'] for c in checks));print([c for c in checks if not c['passed']]);assert all(c['passed'] for c in checks)
base='http://localhost:3003/book-review/'+H.relative_to(R).as_posix()+'/'
assets=['index.html','text-diff.html','arrival.png','walls-100.png','body-seeded.png','seeded.png','after-seed-100.png','first-spread.png','before-view/arrival.png','DECISIONS.md','museum-runtime.json','museum-log.txt','verification.json','source-manifest.json','walk-seed.txt','source-changes.diff','seed-diagnostic/museum-runtime.json','first-native/museum-runtime.json']
http=[]
for asset in assets:
 try:
  with urllib.request.urlopen(base+asset,timeout=20) as response:raw=response.read();status=response.status
  http.append({'path':asset,'status':status,'passed':status==200 and hashlib.sha256(raw).hexdigest()==sha(H/asset)})
 except Exception as e:http.append({'path':asset,'passed':False,'error':str(e)})
dump(H/'http-checks.json',{'passed':all(c['passed'] for c in http),'checks':http});print('HTTP',len(http),all(c['passed'] for c in http));print([c for c in http if not c['passed']]);assert all(c['passed'] for c in http)
