from pathlib import Path
import json,hashlib,difflib,html,re,urllib.request,markdown
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-randomness-opening-review'
base=json.loads((o/'baseline.json').read_text());maps=base['maps'];D=json.loads((o/'decisions.json').read_text());checks=[]
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)});assert ok,label
prior=json.loads((o/'core-before-update.json').read_text());core=json.loads((r/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for m in maps:
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig')
 check(re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',s),m+': encounter anchors retained')
 check(re.findall(r'```[^\n]*\n(.*?)```',a,re.S)==re.findall(r'```[^\n]*\n(.*?)```',s,re.S),m+': code excerpts retained')
 if m!='Random_Entropy':check(H(p)==base['files'][p.relative_to(r).as_posix()],m+': chapter retained byte for byte')
 check(core['rooms'][m]['text_sha256']==H(p) and core['rooms'][m]['map_sha256']==H(r/'commons/maps'/m/'map_data.json'),m+': core hashes current')
 with urllib.request.urlopen('http://localhost:3003/api/book-text?map='+m,timeout=20) as response:live=json.load(response)
 check(live['sections']['final'].replace('\r\n','\n').strip()==s.strip(),m+': reader serves current canonical text')
 old=dict(prior['rooms'][m]);new=dict(core['rooms'][m])
 for key in ['text_sha256','map_sha256','local_review']:old.pop(key,None);new.pop(key,None)
 check(old==new,m+': roles and verification status preserved')
check(all(core['rooms'][m]==prior['rooms'][m] for m in set(prior['rooms'])-set(maps)),'Other current core records preserved')
for rel,sha in base['files'].items():
 if rel.startswith('commons/maps/') and (rel.endswith('.md') or rel.endswith('map_data.json')) and rel not in ['commons/maps/Random_Entropy/final.md','commons/maps/Random_Entropy/map_data.json']:
  check(H(r/rel)==sha,rel+': untouched')
for rel in ['commons/data/artifact_roles.json','commons/maps/sequences/randomness.json','commons/data/book/randomness.json','ada_run/em_plan.json','commons/data/museum/em_plan.json','commons/context/clipboard/tutorial_text/ten_print_axioms.gd','commons/context/clipboard/tutorial_text/ten_print_axioms.md']:
 check(H(r/rel)==base['files'][rel],rel+': unchanged')
a=json.loads((o/'before/commons/maps/Random_Entropy/map_data.json').read_text(encoding='utf-8-sig'));b=json.loads((r/'commons/maps/Random_Entropy/map_data.json').read_text());a['map_info']['museum']['piers']=False
for row in a['layers']['interactables']:
 for i,v in enumerate(row):
  if isinstance(v,str) and v.startswith('entropy_ruin#'):row[i]=v+'#autostart:false'
check(a==b,'Map changes only declare piers:false and the ruin waiting mode')
logs={};native=0
for sub,count,exitcode in [('entropy',16,0),('removal-cleanup',13,-1),('print',13,0)]:
 d=json.loads((o/sub/'report.json').read_text());log=(o/sub/'stdout.log').read_text(encoding='utf-8',errors='replace');process=json.loads((o/sub/'process.json').read_text())
 check(d['passed'] and not d['failures'] and len(d['checks'])==count,sub+': all recorded encounter assertions passed');native+=count
 check(process['exit_code']==exitcode,sub+': process result accurately recorded')
 check('SCRIPT ERROR' not in log,sub+': no GDScript errors')
 logs[sub]={'runner_exit_code':exitcode,'godot_exit_code':3221225477 if sub=='removal-cleanup' else exitcode,'errors':[v for v in log.splitlines() if 'ERROR:' in v or 'leaked' in v],'limit':'Completed assertions, followed by unresolved native shutdown crash' if exitcode else 'UID/resource/renderer warnings retained; no headset claim'}
(o/'engine-limitations.json').write_text(json.dumps(logs,indent=2)+'\n',encoding='utf-8')
figs=json.loads((o/'figure-provenance.json').read_text())
for f in figs:
 check(H(r/f['canonical'])==H(r/f['source'])==f['sha256'],'Book figure is the unchanged native museum PNG')
 with urllib.request.urlopen('http://localhost:3003/book-review/'+f['canonical'],timeout=20) as response:check(hashlib.sha256(response.read()).hexdigest()==f['sha256'],'Figure served without alteration')
manifest=json.loads((r/'doc/book/captures/randomness/randomness-book.manifest.json').read_text())
check(all(H(r/m['path'])==m['sha256'] for m in manifest['maps']),'Current capture includes all fourteen current chapters')
check(H(r/'doc/book/captures/randomness/randomness-book.md')==manifest['output_sha256'],'Current capture hash correct')
(o/'verification.json').write_text(json.dumps({'checks':checks,'passed':True,'native_assertions':native,'native_processes_clean':False,'limits':'Removal floor completes 13 assertions but crashes at shutdown in both runs. No headset, comfort, tracked hand, performance, or full route acceptance.'},indent=2)+'\n',encoding='utf-8')
owned=['commons/maps/Random_Entropy/final.md','commons/maps/Random_Entropy/map_data.json','commons/artifacts/randomness_space/entropy_ruin.gd','commons/data/museum_core_encounters.json','doc/book/figures/README.md','doc/book/captures/randomness/randomness-book.md','doc/book/captures/randomness/randomness-book.manifest.json']
changed=[]
for rel in owned:
 if H(r/rel)==base['files'][rel]:continue
 changed.append(rel);p=r/rel;dst=o/'after'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(p.read_bytes())
 a=(o/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 if rel=='commons/data/museum_core_encounters.json':a=json.dumps({m:prior['rooms'][m] for m in maps},indent=2)+'\n';b=json.dumps({m:core['rooms'][m] for m in maps},indent=2)+'\n'
 dst=o/'diffs'/(rel+'.diff');dst.parent.mkdir(parents=True,exist_ok=True);dst.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
changed += [f['canonical'] for f in figs];(o/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
q=json.loads((o/'before/doc/tasks/book_randomness.json').read_text(encoding='utf-8-sig'));tasks={t['id']:t for t in q['tasks']}
intro='''# Randomness opening — 25 September 2026

Four halls read: Definition, Entropy, Remove and 10 PRINT. Six comments resolved; two headset checks and the remaining placement decision stay open. One chapter changes. The other three are retained, including Claude's recent additions. This is a deliberately bounded opening pass through a 44-item queue, not completion of the whole sequence.

## What carries the reading

The opening can already move from a recoverable draw, to what a count leaves out, to the set allowed to lose a member, and then to marks whose arrangement can admit or exclude a body. These are different questions about a rule. They do not need the same editorial pressure. The current 10 PRINT chapter already keeps the breathing coin and probability/count comparison that its review says are missing. Keep it.

The entropy ruin needed the encounter improved. It formerly started without the visitor and could reach its lowest courses while the visitor was elsewhere. This hall now opts into a paused beginning. The prose can let someone choose a joint, start the dismantling, and notice that the stones remain while the building changes. Its technical distinction between symbol entropy and a staged architectural rule remains. No new equivalence between destruction, entropy and liberation is claimed.

The existing companions remain available as the thinking behind the chapter. The critical text's chosen neighbours, and its distinction between a useful measurement and an enlarged claim of authority, are already carried by the current ledger encounter. No generic theoretical paragraph has been added.

## Museum evidence and limits

The loader rereads map-authored tiles and artifact tokens at every build. A stale saved plan is not proof that its old piers or science screen still stand. The native loaded halls confirm the relevant piers and screen are absent. Added piers:false explicitly to Entropy to preserve that intent in future generated plans. No live plan, save or global bake was rewritten.

Entropy: 16 native assertions, exit 0. The intact beginning remains after ninety supplied seconds; ONE STONE, seeded RESTORE and RUN/PAUSE work through their signals. Legacy placements retain autostart=true. The baseline run is archived separately (14 assertions, exit 0); its unattended image uses 75 seconds of supplied production updates, not a timed visitor journey. The revised pair holds one camera at local eye height 1.7 m. The second photograph follows one single-step selection and eighteen supplied seconds of running, showing 26 displaced stones. Probe-supplied updates make this a reproducible scene comparison, not an interaction/comfort study.

Removal floor: 13 native assertions completed in each of two runs, using the actual desktop body positioned through the production trigger. Entry removes one of 99 cells and its collider; another 0.7 local units requests another; standing still adds none; REPLAY restores support. Both processes subsequently exit with Windows status 0xC0000005, including after explicit probe-scene cleanup. The cause is unresolved. The photographs and report precede the failure; do not describe this as a clean engine run. Source and prior checks cover an XR recognition branch, but this pass does not exercise that branch.

10 PRINT: 13 native assertions, exit 0. Twelve 2.4 m solid slabs load, with the seven-row non-colliding floor linked to the printer. Images are actual museum interiors and supplied camera viewpoints, not proof that a headset body walked the channel. UID, renderer and resource-cleanup warnings remain in the archived logs. The printed-maze and removal-floor headset tasks remain open.

One original museum photograph enters Random_Entropy/final.md. Companion manuscripts, other chapter text, roles, anchors, code excerpts, sequence order and all other placements are preserved. The current fourteen-chapter capture is refreshed; historical captures stay frozen. Next: Random_Cubes and the following halls, respecting new Claude work already in the queue.

## Each comment
'''
rows=[]
for tid,d in D.items():
 title=tasks[tid]['title'];intro+=f'\n### {tid} — {title}\n\n**{d["status"]}** — {d["decision"]}\n'
 rows.append('<tr><td>'+html.escape(tid+' · '+title)+'</td><td><strong>'+d['status']+'</strong> — '+html.escape(d['decision'])+'</td></tr>')
(o/'DECISIONS.md').write_text(intro,encoding='utf-8')
sections=[]
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8');reading=markdown.markdown(b,extensions=['fenced_code','footnotes'])
 reading=re.sub(r'id="([^"]+)"',lambda v:'id="'+m+'-'+v[1]+'"',reading);reading=re.sub(r'href="#([^"]+)"',lambda v:'href="#'+m+'-'+v[1]+'"',reading)
 diff=''
 if a!=b:
  table=difflib.HtmlDiff(wrapcolumn=75).make_table(a.splitlines(),b.splitlines(),fromdesc='Before',todesc='Current final.md',context=True,numlines=2)
  diff='<details><summary>Exact changes beside the original</summary><div class="diffwrap">'+table+'</div><a href="diffs/commons/maps/'+m+'/final.md.diff">Plain-text diff</a></details>'
 else:diff='<p class="quiet">Current chapter retained unchanged.</p>'
 sections.append(f'<section id="{m}"><h2>{html.escape(m.replace("_"," "))}</h2><p><a href="/compose/sources?map={m}&amp;doc=final">Current chapter and comments</a></p>{diff}<div class="reading">{reading}</div></section>')
def pair(a,ac,b,bc):return '<div class="pair"><figure><img src="'+a+'" alt="'+html.escape(ac,quote=True)+'"><figcaption>'+ac+'</figcaption></figure><figure><img src="'+b+'" alt="'+html.escape(bc,quote=True)+'"><figcaption>'+bc+'</figcaption></figure></div>'
css='body{background:#f4f0e9;color:#282630;margin:0;font:18px/1.65 Georgia,serif}main{max-width:1180px;margin:auto;padding:36px 26px}h1{font-size:46px;line-height:1.12}h2{line-height:1.25}p{max-width:78ch}a{color:#69527a}nav{display:flex;gap:18px;flex-wrap:wrap}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:20px 0}img{width:100%;height:auto}figcaption,.quiet{font-size:15px}section{margin-top:48px;border-top:1px solid #ccc;padding-top:25px}.reading{max-width:760px;margin:36px auto}.reading h1{font-size:35px}pre{overflow:auto;background:#e5e0d8;padding:16px;font-size:13px}details{border:1px solid #ccc;padding:16px}summary{cursor:pointer}.diffwrap{overflow:auto}.diff{font:12px/1.4 monospace}.diff_header{background:#e3ddd4}.diff_add{background:#d3e8d5}.diff_sub{background:#f1d3d2}.diff_chg{background:#f3e6ae}td,th{vertical-align:top;padding:10px;border-bottom:1px solid #ccc}table{border-collapse:collapse;width:100%}@media(max-width:750px){.pair{grid-template-columns:1fr}h1{font-size:34px}}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Randomness — before anything falls</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>Before anything falls</h1><p>The ruin can wait for someone to choose where to look. Its inventory stays at 116 stones while a wall loses its shape. In the next hall, a step asks the floor to lose a cell. Further on, two printed marks become walls high enough to keep a body out.</p><nav><a href="#reading">Read the four halls</a><a href="#museum">Inside the museum</a><a href="DECISIONS.md">Decisions and limits</a><a href="/book-tasks/review?seq=randomness">Review queue</a></nav><p>Six comments resolved. One chapter revised; three retained. Two headset checks and one placement decision stay open. The new writing and encounters already added by Claude are preserved.</p><h2 id="museum">A beginning the visitor can reach</h2>'
page+=pair('entropy-before/ruin-unattended.png','Before: the original running default, after 75 supplied seconds. The visitor need not have reached it.','entropy/ruin-waiting.png','Now: this hall waits intact. The same camera; no stones have moved on arrival.')
page+=pair('entropy/ruin-waiting.png','Choose a joint before starting. The intact ruin is now available to look at.','entropy/ruin-after-choices.png','After ONE STONE and eighteen supplied seconds of RUN: 26 displaced, still 116 stones. Same camera.')
page+='<h2>A floor that keeps account of a step</h2>'+pair('removal-cleanup/floor-before-entry.png','Before entry: 99 supported cells, with a permanent apron around them.','removal-cleanup/floor-after-entry.png','The actual desktop body enters, then moves 0.7 local units: two cells and their colliders are gone.')
page+='<p>The trigger, removal and replay checks completed. Both floor processes subsequently crashed during shutdown. These photographs support the recorded encounter observations; they do not establish a clean run or a headset walk.</p><h2>The printed walls are already here</h2>'+pair('print/printed-walls.png','Twelve characters standing as 2.4 m solid slabs in the actual museum.','print/inside-printed-walls.png','An eye-height view from within the field. The headset passage and comfort check remains open.')
page+='<p>The old plan still lists a placeholder screen. The museum refreshes these map-authored placements on load, and the native hall contains the walls instead. Rewriting the whole plan would not improve this encounter.</p><details><summary>What changed, what remains uncertain</summary><p>The ruin has an optional paused start, enabled only here; Entropy also records piers:false. Its arrival paragraph and one museum photograph enter final.md. Definition, Remove and 10 PRINT are retained byte for byte. The current 10 PRINT text already explains breathing bias and probability versus exact count.</p><p>42 encounter assertions completed across the three final native runs. Entropy and 10 PRINT exit 0; the removal floor fails during shutdown (0xC0000005), despite successful checks, in both attempts. No headset, tracked-hand or comfort acceptance. Full reports, logs and process outcomes are archived beside this page.</p><p>Reload Random_Entropy for its waiting ruin. Four secondary placements in 10 PRINT still need a deliberate curation decision; they have not been cut to fit a shorter chapter.</p></details><section><h2>Each review comment</h2><table>'+''.join(rows)+'</table></section><section id="reading"><h2>The opening four halls</h2><nav>'+''.join(f'<a href="#{m}">{html.escape(m.replace("_"," "))}</a>' for m in maps)+'</nav></section>'+''.join(sections)+'</main></html>'
(o/'index.html').write_text(page,encoding='utf-8');print(f'{len(checks)} publication/preservation checks passed. Native shutdown limitation retained explicitly.')
