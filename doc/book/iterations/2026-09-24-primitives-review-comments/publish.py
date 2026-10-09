from pathlib import Path
import json,hashlib,re,difflib,html,urllib.request,sys
sys.stdout.reconfigure(encoding='utf-8')
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-primitives-review-comments'
base=json.loads((out/'baseline.json').read_text(encoding='utf-8-sig')); changed=json.loads((out/'changed-files.json').read_text(encoding='utf-8-sig'))
D=json.loads((out/'decisions.json').read_text(encoding='utf-8'))
seq=json.loads((root/'commons/maps/sequences/primitives.json').read_text(encoding='utf-8-sig'))['sequences']['primitives'];maps=seq['maps']
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)});assert ok,label
check([c.split(':',1)[0] for c in seq['content']]==maps,'Sequence content matches ten maps in spine order')
oldseq=json.loads((out/'before/commons/maps/sequences/primitives.json').read_text(encoding='utf-8-sig'))
newseq=json.loads((root/'commons/maps/sequences/primitives.json').read_text(encoding='utf-8-sig'))
oldseq['sequences']['primitives']['content']=seq['content']
check(newseq==oldseq,'Only sequence content ledger changed')
for rel,h in base.items():
 if rel not in changed and rel!='doc/book/iterations/WORKING.md':
  check(hashlib.sha256((root/rel).read_bytes()).hexdigest()==h,'Preserved '+rel)
core=json.loads((root/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8'))
oldcore=json.loads((out/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8'))
expected=json.loads(json.dumps(oldcore))
for m in maps:
 p=root/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8')
 check(core['rooms'][m]['text_sha256']==hashlib.sha256(p.read_bytes()).hexdigest(),m+' current text hash')
 for k in ['text_sha256','local_review']:expected['rooms'][m][k]=core['rooms'][m][k]
 used=set(re.findall(r'\[\^([^\]]+)\](?!:)',s));defined=set(re.findall(r'^\[\^([^\]]+)\]:',s,re.M))
 check(used==defined,m+' footnotes resolve')
 old=(out/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8')
 oldblocks=re.findall(r'```[^\n]*\n(.*?)```',old,re.S);newblocks=re.findall(r'```[^\n]*\n(.*?)```',s,re.S)
 if m=='Point_One':oldblocks=[b.replace('var p := Vector3(1.0, 0.5, 0.0)','var point_position := Vector3(1.0, 0.5, 0.0)') for b in oldblocks]
 check(oldblocks==newblocks,m+' code preserved except attributed screen identifier')
 if m!='Point_Triangle_Context':check(re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',s),m+' encounter markers retained')
 urls=re.findall(r'/book-review/(doc/book/figures/[^)]+)',s)
 for u in urls:check((root/u).is_file(),m+' canonical figure exists')
 current=json.load(urllib.request.urlopen('http://localhost:3003/api/book-text?map='+m,timeout=20))
 check(current['sections']['final'].replace('\r\n','\n').strip()==s.strip(),m+' live review text is current')
expected['rooms']['Primitives_Portals']['map_sha256']=core['rooms']['Primitives_Portals']['map_sha256']
concurrent_rooms=[m for m in core['rooms'] if m not in maps and core['rooms'].get(m)!=oldcore['rooms'].get(m)]
check(all(core['rooms'][m]==expected['rooms'][m] for m in maps),'Primitives core changes limited to scoped hashes and review links')
(out/'concurrent-rooms.json').write_text(json.dumps({'observed_other_room_updates':concurrent_rooms,'decision':'Preserved current data; excluded from this pass attribution.'},indent=2)+'\n',encoding='utf-8')
before=json.loads((out/'before/commons/maps/Primitives_Portals/map_data.json').read_text(encoding='utf-8-sig'));after=json.loads((root/'commons/maps/Primitives_Portals/map_data.json').read_text(encoding='utf-8-sig'))
oldlayer=before['layers']['interactables'];oldlayer[8][8]=oldlayer[5][5];oldlayer[5][5]=''
# The map's human-readable note is the only other field changed.
check(json.dumps(before,ensure_ascii=False).replace('`achilles_tortoise` at (5,5)','`achilles_tortoise` at (8,8)')==json.dumps(after,ensure_ascii=False),'Portal map changed only Achilles placement and matching note')
figs=json.loads((out/'figure-provenance.json').read_text(encoding='utf-8-sig'))
for f in figs:
 check(hashlib.sha256((root/f['canonical']).read_bytes()).hexdigest()==hashlib.sha256((root/f['source']).read_bytes()).hexdigest()==f['sha256'],'Unmodified native figure '+f['map'])
 with urllib.request.urlopen('http://localhost:3003/book-review/'+f['canonical'],timeout=20) as r:
  check(r.status==200 and hashlib.sha256(r.read()).hexdigest()==f['sha256'],'Served canonical figure '+f['map'])
runtime=json.loads((out/'runtime.json').read_text(encoding='utf-8-sig'))
check(not runtime['failures'] and len(runtime['checks'])==20,'20 runtime assertions passed; shutdown status recorded separately')
(out/'verification.json').write_text(json.dumps({'checks':checks,'runtime_process_exit':3221225477,'runtime_caveat':'Assertions completed and report written; Godot crashes during teardown. No claim of a clean process exit, full room walk or headset test.'},indent=2)+'\n')
# Preserve before/after documents and exact diffs.
for rel in changed:
 p=root/rel;dest=out/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
 original=(out/'before'/rel).read_text(encoding='utf-8-sig');current=p.read_text(encoding='utf-8-sig')
 if rel=='commons/data/museum_core_encounters.json':
  old_subset={m:oldcore['rooms'][m] for m in maps};new_subset={m:core['rooms'][m] for m in maps}
  original=json.dumps(old_subset,ensure_ascii=False,indent=2)+'\n';current=json.dumps(new_subset,ensure_ascii=False,indent=2)+'\n'
 diff=''.join(difflib.unified_diff(original.splitlines(True),current.splitlines(True),fromfile='before/'+rel,tofile=rel))
 dest=out/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(diff,encoding='utf-8')
source=json.loads((out/'before/doc/tasks/book_primitives.json').read_text(encoding='utf-8-sig'))
notes=['# Primitives — review decisions, 24 September 2026','','41 comments checked. 36 resolved (including repeated comments and author decisions), 3 proposals declined, 2 follow-ups left open. Original review claims and author notes are retained in the live queue.','','## Verification limits','','The production-code probe completed 20 passing assertions: triangle loader regression, quad mesh updates, and portal-panel overlap before/after relocation. Godot then exited abnormally during teardown (3221225477). This is not a clean process-exit result or a full museum/headset walkthrough. `runtime.json`, `runtime.log`, and `verification.json` preserve the evidence. The running museum bake was not replaced.','','## Decisions','']
rows=[]
for t in source['tasks']:
 d=D[t['id']]; n=t['id'].split('.')[-1];m=t['hall']
 url='http://localhost:3003/book-tasks/review?seq=primitives'+('' if m=='sequence' else '&map='+m)+'#'+t['id']
 notes += [f"### {t['id']} — {t['title']}",'',f"**{d['status']} / {d['triage']}**",'']
 if t.get('notes'):notes += ['Author’s original note: '+t['notes'],'']
 notes += [d['decision'],'',f'[Review comment]({url})','']
 rows.append(f'<tr><td><a href="{html.escape(url)}">{n}</a><br>{html.escape(m)}</td><td><strong>{html.escape(t["title"])}</strong><p>{html.escape(d["decision"])}</p>'+('<blockquote>Your note: '+html.escape(t['notes'])+'</blockquote>' if t.get('notes') else '')+f'</td><td>{d["status"]}</td></tr>')
(out/'DECISIONS.md').write_text('\n'.join(notes),encoding='utf-8')
comparisons=[]
for m in maps:
 rel=f'commons/maps/{m}/final.md';a=(out/'before'/rel).read_text(encoding='utf-8');b=(root/rel).read_text(encoding='utf-8')
 table=difflib.HtmlDiff(wrapcolumn=80).make_table(a.splitlines(),b.splitlines(),fromdesc='Before',todesc='Current final.md',context=True,numlines=2)
 comparisons.append(f'<details id="{m}"><summary>{m.replace("_"," ")}</summary><p><a href="http://localhost:3003/compose/sources?map={m}&amp;doc=final">Read and comment on current chapter</a></p><div class="diffwrap">{table}</div></details>')
css='body{background:#f4f0e8;color:#242329;font:17px/1.55 Georgia,serif;margin:0}main{max-width:1180px;margin:auto;padding:48px 28px}h1{font-size:48px;line-height:1.08}a{color:#674575}p{max-width:85ch}table{border-collapse:collapse;width:100%}td,th{padding:12px;vertical-align:top;border-bottom:1px solid #c9c4bb}blockquote{border-left:3px solid #a67c93;padding-left:15px}details{margin:20px 0;padding:18px;border:1px solid #c9c4bb}summary{cursor:pointer;font:bold 20px Georgia}.diffwrap{overflow:auto}.diff{font:12px/1.45 monospace}.diff td{padding:4px}.diff_add{background:#d3e9d6}.diff_sub{background:#f2d3d1}.diff_chg{background:#f4e6b5}.diff_header{background:#e2ded7}nav{display:flex;gap:24px;flex-wrap:wrap}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives — review comments</title><style>'+css+'</style><main><p>Ada Research · 24 September 2026</p><h1>Primitives: what the comments changed</h1><p>36 resolved · 3 proposals declined · 2 follow-ups open. The opening, the secondary Fontana work and the filmed line studies remain. Small prose corrections accompany one grid-loader repair and one track relocation.</p><nav><a href="http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One">Live review queue</a><a href="#diffs">Text differences</a><a href="DECISIONS.md">Full decisions</a><a href="runtime.json">Runtime assertions</a></nav><p>Verification: 20 production-code assertions completed; Godot crashed during teardown. No full-room or headset test is claimed. Source-map placement changes appear when the hall is rebuilt.</p><h2>Comment by comment</h2><table><thead><tr><th>Comment</th><th>Decision</th><th>Status</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table><h2 id="diffs">The text changes</h2>'+''.join(comparisons)+'</main></html>'
(out/'index.html').write_text(page,encoding='utf-8')
print('Passed',len(checks),'scoped checks; saved decisions and exact differences.')
