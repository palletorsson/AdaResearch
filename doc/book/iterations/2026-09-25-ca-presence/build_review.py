from pathlib import Path
import hashlib,json,shutil,re,difflib,html,markdown,urllib.request
H=Path(__file__).resolve().parent;R=H.parents[3];D=R/'commons/maps/CA_ExpandingSpace'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
checks=[]
def check(n,b):checks.append({'name':n,'passed':bool(b)})
before=H/'before';after=H/'after';manifest={}
for p in before.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(before);q=R/rel;t=after/rel;t.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(q,t)
 manifest[rel.as_posix()]={'before':sha(p),'after':sha(q)}
for p in [D/'encounter-notes.md',D/'images/ca-presence-depleted.png']:
 t=after/p.relative_to(R);t.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,t)
dump(H/'source-manifest.json',manifest)
old=(before/'commons/maps/CA_ExpandingSpace/final.md').read_text(encoding='utf-8');new=(D/'final.md').read_text(encoding='utf-8')
check('all previous chapter paragraphs retained',all(p in new for p in old.split('\n\n') if p.strip()))
check('three source excerpts retained exactly',re.findall(r'```gdscript(.*?)```',old,re.S)==re.findall(r'```gdscript(.*?)```',new,re.S) and len(re.findall(r'```gdscript',new))==3)
check('artifact anchors retained',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
allowed={'final.md','technical.md','intent.md','artifacts.md'}
for p in (before/'commons/maps/CA_ExpandingSpace').glob('*.md'):
 if p.name not in allowed:check('unchanged '+p.name,sha(p)==sha(D/p.name))
for rel in ['commons/maps/CA_ExpandingSpace/map_data.json','algorithms/cellularautomata/living_architecture/decaying_bridge.gd','algorithms/cellularautomata/living_architecture/decaying_bridge.tscn']:
 check('unchanged '+rel,sha(before/rel)==sha(R/rel))
seq_path='commons/maps/sequences/cellularautomata.json'
sa=json.loads((before/seq_path).read_text());sb=json.loads((R/seq_path).read_text())
check('active map order unchanged',sa['sequences']['cellularautomata']['maps']==sb['sequences']['cellularautomata']['maps'])
sa['sequences']['cellularautomata'].pop('content');sb['sequences']['cellularautomata'].pop('content')
check('sequence changes restricted to concurrent display titles',sa==sb)
a=json.loads((H/'before-view/museum-runtime.json').read_text());b=json.loads((H/'museum-runtime.json').read_text());keys=['token','cell','position','scale','rotation']
check('all native root placements unchanged',[{k:x[k] for k in keys} for x in a['artifacts']]==[{k:x[k] for k in keys} for x in b['artifacts']])
check('49 native assertions pass',len(b['checks'])==49 and all(c['passed'] for c in b['checks']) and b['passed'])
check('eight actual pointer events pass',len(b['desktop_input'])==8 and all(c['emissions']==1 and c['hover_matches'] and c['clear_to_button'] for c in b['desktop_input']))
check('no GDScript errors','SCRIPT ERROR' not in (H/'museum-process.log').read_text(errors='replace'))
a=json.loads((H/'core-before-update.json').read_text());b=json.loads((H/'core-after-update.json').read_text());a['rooms'].pop('CA_ExpandingSpace');b['rooms'].pop('CA_ExpandingSpace');check('only this core room changed',a==b)
check('canonical photograph is unaltered capture',sha(D/'images/ca-presence-depleted.png')==sha(H/'depleted.png'))
check('three source citations stay in code',new.count('```gdscript')==old.count('```gdscript'))
check('exact body encounter paragraph present','you are still looking at the same address from a little lower down.' in new)
check('frieze still uses original material reference','panel.material_override=work.materials[cell]' in (R/'algorithms/cellularautomata/living_architecture/proximity_study.gd').read_text())
dump(H/'verification.json',{'passed':all(c['passed'] for c in checks),'checks':checks})
(H/'text-diff.html').write_text(difflib.HtmlDiff(wrapcolumn=90).make_file(old.splitlines(),new.splitlines(),'Before: mature chapter','After: focused encounter addition',context=True,numlines=3),encoding='utf-8')
parts=[]
for rel,v in manifest.items():
 if v['before']!=v['after'] and rel.endswith(('.md','.gd')):
  parts.extend(difflib.unified_diff((before/rel).read_text(encoding='utf-8').splitlines(True),(R/rel).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
(H/'source-changes.diff').write_text(''.join(parts),encoding='utf-8')
shutil.copy2(R/'algorithms/cellularautomata/living_architecture/proximity_study.gd',H/'proximity-study.txt');shutil.copy2(H/'museum-process.log',H/'museum-log.txt')
style=re.search(r'<style>(.*?)</style>',(R/'doc/book/iterations/2026-09-25-ca-life-floor/index.html').read_text(encoding='utf-8'),re.S)
css=style.group(1) if style else 'body{max-width:1100px;margin:auto;padding:3rem;background:#f8f5ee;color:#242320;font:18px/1.6 Georgia}img{max-width:100%}'
css+=' .pair{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:18px}figure{margin:0}figure img{width:100%}figcaption{font:15px/1.5 system-ui;margin:8px 0 22px}.chapter{max-width:780px;margin:3em auto}pre{overflow:auto}iframe{width:100%;height:600px;background:white}'
def fig(src,caption):return '<figure><a href="'+src+'"><img src="'+src+'" alt="'+html.escape(caption)+'"></a><figcaption>'+html.escape(caption)+'</figcaption></figure>'
chapter=markdown.markdown(new.replace('images/ca-presence-depleted.png','depleted.png'),extensions=['fenced_code','footnotes'])
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CA Expanding Space — the same cell, from lower down</title><style>'+css+'</style><body><main>'
page+='<p class="eyebrow">ADA RESEARCH · 25 SEPTEMBER 2026 · CELLULAR AUTOMATA</p><h1>The same cell, from lower down</h1><p>The bridge already had a strong argument. This pass makes one relation easier to find: W is both a tile underfoot and a colour on the wall.</p><p><a href="#chapter">Read the chapter</a> · <a href="text-diff.html">Exact text comparison</a> · <a href="DECISIONS.md">Decisions and limits</a> · <a href="/compose/sources?map=CA_ExpandingSpace&amp;doc=final">Read and comment</a></p>'
page+='<h2>A room that can receive the body</h2><div class="pair">'+fig('before-view/full.png','Before: W is marked only on the bridge. The open sides reveal sky beyond the museum floor.')+fig('full.png','After: the same wall address has a gold frame. Four lining faces close the shallow basin below floor height.')+'</div>'
page+='<h2>One value, two consequences</h2><div class="pair">'+fig('full.png','Full bridge: the gold frames identify the same cell on both surfaces.')+fig('depleted.png','After 25 near-probe updates: W is still visible, while its floor collider no longer carries a body.')+'</div>'
page+='<h2>Wait, and the view changes</h2><div class="pair">'+fig('standing.png','Actual museum body at W, looking at its wall panel. The study is held.')+fig('in-basin.png','After 21 visitor-input updates: the same body has landed 0.60 m lower. The wall keeps showing W.')+'</div><p>The tested body then reaches the existing ramp and climbs back to the museum floor. The ordinary margin remains independently walkable outside the lamp post.</p>'
page+='<blockquote>Look up to find W again. A gold frame holds its place on the frieze. Wait above the tile while watching its colour there. The change stays in front of you; the consequence arrives beneath your feet.</blockquote>'
page+='<h2>What was preserved</h2><p>All seven artifacts, every recorded native root placement, the complete earlier chapter, three code excerpts, the original solver and thresholds, eight controls, two recovery ramps, and the sequence order. The shared wall material still carries the cell’s actual value; the gold frame adds no simulation.</p><p>49 native assertions and eight real mouse-ray events pass. Controlled desktop body and explicit simulation steps; headset comfort, Quest performance, continuous play and the rear collection remain unverified. The first diagnostic run is retained, including test routes that met the existing desk foot and lamp post.</p>'
page+='<details><summary>Evidence, source and exact changes</summary><p><a href="museum-runtime.json">Final native report</a> · <a href="museum-log.txt">Engine log</a> · <a href="verification.json">Preservation checks</a> · <a href="source-manifest.json">Source hashes</a> · <a href="source-changes.diff">Source/text diff</a> · <a href="proximity-study.txt">Current study source</a> · <a href="first-native/museum-runtime.json">Initial diagnostic</a> · <a href="http-checks.json">HTTP publication checks</a></p><iframe src="text-diff.html" title="Exact chapter changes"></iframe></details>'
page+='<article id="chapter" class="chapter">'+chapter+'</article><p>Next: <a href="/compose/sources?map=CA_SoftRules&amp;doc=final">CA Soft Rules</a> — what a cell can receive from a neighbourhood.</p></main></body></html>'
(H/'index.html').write_text(page,encoding='utf-8')
print('Preservation checks:',len(checks),'passed:',all(c['passed'] for c in checks));print([c for c in checks if not c['passed']])
assert all(c['passed'] for c in checks)
base='http://localhost:3003/book-review/'+H.relative_to(R).as_posix()+'/'
assets=['index.html','text-diff.html','arrival.png','full.png','depleted.png','recovered.png','standing.png','in-basin.png','before-view/full.png','before-view/depleted.png','DECISIONS.md','museum-runtime.json','museum-log.txt','verification.json','source-manifest.json','source-changes.diff','proximity-study.txt','first-native/museum-runtime.json']
http=[]
for asset in assets:
 try:
  with urllib.request.urlopen(base+asset,timeout=25) as response: raw=response.read();status=response.status
  http.append({'path':asset,'status':status,'passed':status==200 and hashlib.sha256(raw).hexdigest()==sha(H/asset)})
 except Exception as e:http.append({'path':asset,'passed':False,'error':str(e)})
dump(H/'http-checks.json',{'passed':all(c['passed'] for c in http),'checks':http});print('HTTP:',len(http),'passed:',all(c['passed'] for c in http));print([c for c in http if not c['passed']]);assert all(c['passed'] for c in http)
