from pathlib import Path
import json,hashlib,re,difflib,html,urllib.request,sys
sys.stdout.reconfigure(encoding='utf-8')
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-transformation-review-comments';base=json.loads((out/'baseline.json').read_text(encoding='utf-8'));changed=json.loads((out/'changed-files.json').read_text(encoding='utf-8'));D=json.loads((out/'decisions.json').read_text(encoding='utf-8'))
seq=json.loads((root/'commons/maps/sequences/transformation.json').read_text(encoding='utf-8-sig'))['sequences']['transformation'];maps=seq['maps'];checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)});assert ok,label
for rel,h in base.items():
 if rel not in changed and rel!='doc/book/iterations/WORKING.md' and not rel.startswith('doc/tasks/book_'):
  check(hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,'Unchanged '+rel)
core=json.loads((root/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8'));oldcore=json.loads((out/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8'))
for m in maps:
 p=root/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');old=(out/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig')
 check(core['rooms'][m]['text_sha256']==hashlib.sha256(p.read_bytes()).hexdigest(),m+' manuscript hash current')
 check(re.findall(r'```[^\n]*\n(.*?)```',old,re.S)==re.findall(r'```[^\n]*\n(.*?)```',s,re.S),m+' all code excerpts preserved')
 check(re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',s),m+' encounter anchors preserved')
 check('\ufffd' not in s,m+' no invalid replacement characters')
 expected=dict(oldcore['rooms'][m]);expected['text_sha256']=core['rooms'][m]['text_sha256'];expected['local_review']=core['rooms'][m]['local_review']
 if m=='Trans_Pit':expected['map_sha256']=hashlib.sha256((root/'commons/maps'/m/'map_data.json').read_bytes()).hexdigest()
 check(core['rooms'][m]==expected,m+' roles and intent preserved; hashes/review link only')
 current=json.load(urllib.request.urlopen('http://localhost:3003/api/book-text?map='+m,timeout=20))
 check(current['sections']['final'].replace('\r\n','\n').strip()==s.strip(),m+' live current chapter matches canonical text')
 for u in re.findall(r'!\[[^\]]*\]\(/book-review/([^\)]+)\)',s):check((root/u).is_file(),m+' figure resolves '+u)
 check(set(re.findall(r'\[\^([^\]]+)\](?!:)',s))==set(re.findall(r'^\[\^([^\]]+)\]:',s,re.M)),m+' footnotes resolve')
old=json.loads((out/'before/commons/maps/Trans_Pit/map_data.json').read_text(encoding='utf-8-sig'));new=json.loads((root/'commons/maps/Trans_Pit/map_data.json').read_text(encoding='utf-8'))
for row in old['layers']['utilities']:
 for x,v in enumerate(row):
  if v=='h:fire':row[x]=' '
old['dev_notes']=new['dev_notes'];check(old==new,'Map changes limited to obsolete fire cells and their explanatory note')
check(not any('h:fire' in str(v) for row in new['layers']['utilities'] for v in row),'No fire utility remains')
figs=json.loads((out/'figure-provenance.json').read_text(encoding='utf-8'))
for f in figs:
 check(hashlib.sha256((root/f['source']).read_bytes()).hexdigest()==hashlib.sha256((root/f['canonical']).read_bytes()).hexdigest()==f['sha256'],'Byte-identical native figure '+f['canonical'])
 with urllib.request.urlopen('http://localhost:3003/book-review/'+f['canonical'],timeout=20) as r:
  check(r.status==200 and hashlib.sha256(r.read()).hexdigest()==f['sha256'],'HTTP serves exact figure '+f['canonical'])
runtime=json.loads((out/'runtime.json').read_text(encoding='utf-8'));process=json.loads((out/'runtime-process.json').read_text(encoding='utf-8'))
check(runtime['passed'] and not runtime['failures'] and len(runtime['checks'])==72 and process['exit_code']==0,'72 runtime checks passed with clean exit')
(out/'verification.json').write_text(json.dumps({'checks':checks,'scope':'Source, live manuscript API, figure publication and controlled native runtime. No headset or learner acceptance.'},indent=2)+'\n',encoding='utf-8')
for rel in changed:
 p=root/rel;dst=out/'after'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil_copy=p.read_bytes();dst.write_bytes(shutil_copy)
 a=(out/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 if rel=='commons/data/museum_core_encounters.json':
  a=json.dumps({m:oldcore['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n';b=json.dumps({m:core['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n'
 diff=''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel));dst=out/'diffs'/(rel+'.diff');dst.parent.mkdir(parents=True,exist_ok=True);dst.write_text(diff,encoding='utf-8')
notes=['# Transformation: review decisions, 24 September 2026','','16 review comments resolved, covering 13 distinct changes; three pairs of duplicate findings are recorded against the same repair. Targeted improvements across seven mature halls. No broad rewrite.','','The existing critical thread remains: what an operation preserves in an object differs from what its changing relation to a body permits. The principal repair strengthens the final encounter rather than cutting its invitation to observe.','','## Evidence and limits','','The current source and manuscripts were inspected, including the final hall’s intent, summary, technical and tutorial notes. Historical field notes and reviews remain unchanged. Old fire utilities were removed from the map; all other cells and artifacts remain. Seventy-two controlled checks in an isolated production Godot museum passed with exit 0. These include 21 floor rays, the three observation walks, ordinary grower timing, and the final door’s opening, crossing, return and closing. No headset or learner test is claimed. The active museum bake was not replaced; reload/rebuild the hall to see source placement changes.','','Four unmodified native photographs now have stable publication paths. The two original bank views share a camera and aligned plank pose; the two new grower views share a camera and hold opposite ends of the size cycle. Earlier review images remain intact.','','## Decisions','']
source=json.loads((out/'before/doc/tasks/book_transformation.json').read_text(encoding='utf-8-sig'));rows=[]
for t in source['tasks']:
 d=D[t['id']];url='http://localhost:3003/book-tasks/review?seq=transformation&map='+t['hall']
 notes.extend([f"### {t['id']} — {t['title']}",'',f"**{d['layer']} · resolved**",'',d['decision'],'',f'[Review queue]({url})',''])
 rows.append('<tr><td>'+html.escape(t['id'].split('.')[-1])+'<br>'+html.escape(t['hall'])+'</td><td><strong>'+html.escape(t['title'])+'</strong><p>'+html.escape(d['decision'])+'</p></td></tr>')
(out/'DECISIONS.md').write_text('\n'.join(notes),encoding='utf-8')
comparisons=[]
for m in maps:
 a=(out/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(root/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 table=difflib.HtmlDiff(wrapcolumn=85).make_table(a.splitlines(),b.splitlines(),fromdesc='Before',todesc='Current final.md',context=True,numlines=2)
 comparisons.append(f'<details id="{m}"><summary>{m.replace("_"," ")}</summary><p><a href="http://localhost:3003/compose/sources?map={m}&amp;doc=final">Read the current chapter</a></p><div class="diffwrap">{table}</div></details>')
css='body{background:#f5f0e8;color:#242329;font:17px/1.6 Georgia,serif;margin:0}main{max-width:1200px;margin:auto;padding:48px 28px}h1{font-size:48px;line-height:1.1}p{max-width:85ch}a{color:#674575}nav{display:flex;gap:24px;flex-wrap:wrap}.pair{display:grid;grid-template-columns:1fr 1fr;gap:14px}figure{margin:0}img{width:100%;height:auto}figcaption{font-size:15px;padding:10px 0 20px}table{border-collapse:collapse;width:100%}td,th{padding:12px;vertical-align:top;border-bottom:1px solid #ccc}details{margin:20px 0;padding:18px;border:1px solid #ccc}summary{cursor:pointer;font:bold 21px Georgia}.diffwrap{overflow:auto}.diff{font:12px/1.45 monospace}.diff td{padding:4px}.diff_add{background:#d3e9d6}.diff_sub{background:#f2d3d1}.diff_chg{background:#f4e6b5}.diff_header{background:#e2ded7}@media(max-width:700px){.pair{grid-template-columns:1fr}h1{font-size:36px}}'
intro='/book-review/doc/book/figures/Trans_Introduction/';pit='/book-review/doc/book/figures/Trans_Pit/'
pairs='<h2>The landing moves; the turn stays</h2><div class="pair"><figure><img src="'+intro+'bank-at-crossing.png" alt="Plank overlapping the near edge of the far bank"><figcaption>BANK +0.00 m · overlap 0.30 m</figcaption></figure><figure><img src="'+intro+'bank-gap.png" alt="Gap beyond the aligned plank"><figcaption>BANK +1.00 m · gap 0.70 m</figcaption></figure></div><p>The same camera and aligned plank in both views. The existing images now sit beside the chapter’s experiment.</p><h2>The observation floor is clear of flames</h2><img src="rotation-observation-floor.png" alt="Two rotating slabs with an open middle floor and moving balls"><p>The slabs and the launched balls remain. Removing the old fire utilities makes the observation route agree with the chapter. A controlled museum-body walk passed along the middle and both side strips.</p><h2>The room keeps time</h2><div class="pair"><figure><img src="'+pit+'growers-small.png" alt="Small cube leaves final door visible"><figcaption>Small · the door remains visible.</figcaption></figure><figure><img src="'+pit+'growers-large.png" alt="Large cube occupies the view"><figcaption>Large · the same cube occupies the view.</figcaption></figure></div><p>Fresh native photographs after the fire removal. Same camera; the size cycle is paused at its two extremes.</p>'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation — review comments</title><style>'+css+'</style><main><p>Ada Research · 24 September 2026</p><h1>Transformation: make the encounter clearer</h1><p>16 comments resolved across seven halls, including three duplicate pairs. Small reading corrections, two restored bank photographs, and one spatial repair: the final hall’s legacy fire utilities no longer occupy the observation floor.</p><nav><a href="http://localhost:3003/book-tasks/review?seq=transformation&map=Trans_Introduction">Review queue</a><a href="#diffs">Text differences</a><a href="DECISIONS.md">Decisions and evidence</a><a href="runtime.json">72 native checks</a></nav><p>The seven canonical final.md texts and current Transformation capture are updated. The controlled Godot run exited cleanly; headset experience remains untested. Reload or rebuild the hall for the map change.</p>'+pairs+'<h2 id="diffs">What changed in the text</h2>'+''.join(comparisons)+'<h2>Comment by comment</h2><table><thead><tr><th>Comment</th><th>Decision</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table></main></html>'
(out/'index.html').write_text(page,encoding='utf-8')
print('Passed',len(checks),'publication and preservation checks; review page and exact differences saved.')
