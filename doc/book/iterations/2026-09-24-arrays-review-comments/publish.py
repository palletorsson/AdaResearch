from pathlib import Path
import json,hashlib,shutil,difflib,html,re,urllib.request,sys
sys.stdout.reconfigure(encoding='utf-8')
r=Path.cwd();o=r/'doc/book/iterations/2026-09-24-arrays-review-comments'
base=json.loads((o/'baseline.json').read_text(encoding='utf-8'));changed=json.loads((o/'changed-files.json').read_text(encoding='utf-8'));D=json.loads((o/'decisions.json').read_text(encoding='utf-8'))
maps=['Array','Tutorial_3D','Tutorial_Tiling_Floor','Tutorial_Tiling_Walls','Tutorial_Disco']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Freeze this passing run before another isolated probe can replace it.
run=r/'ada_run/encounter_pilot/Array';runtime=json.loads((run/'report.json').read_text(encoding='utf-8'))
assert runtime['passed'] and not runtime['failures'] and len(runtime['checks'])==25,runtime['failures']
(o/'floor').mkdir(exist_ok=True)
for f in ['report.json','source_manifest.json','stdout.log','spec.json']:shutil.copy2(run/f,o/'floor'/f)
figs=json.loads((o/'figure-provenance.json').read_text(encoding='utf-8'));figs=[f for f in figs if f['map']!='Array']
for f in ['the-written-floor.png','floor-restored.png','restore-at-the-entrance.png']:
 shutil.copy2(run/f,o/f)
 if f!='restore-at-the-entrance.png':
  p=r/'doc/book/figures/Array'/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(run/f,p)
  figs.append({'map':'Array','source':(o/f).relative_to(r).as_posix(),'canonical':p.relative_to(r).as_posix(),'sha256':sha(p),'capture':'Native production Godot; same camera before/after restoration, explicitly supplied mutations held for comparison. Desktop overlay hidden in isolated probe.'})
(o/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
# Preserve existing evidence; refresh only current hashes and new floor-check count.
rel='commons/data/museum_core_encounters.json';core=json.loads((r/rel).read_text(encoding='utf-8-sig'));before_core_write=json.loads(json.dumps(core))
for m in maps:
 core['rooms'][m]['text_sha256']=sha(r/'commons/maps'/m/'final.md')
 if m=='Array':
  core['rooms'][m]['map_sha256']=sha(r/'commons/maps'/m/'map_data.json');core['rooms'][m]['floor_runtime_check']['scope']=core['rooms'][m]['floor_runtime_check']['scope'].replace('24 controlled','25 controlled').replace('protected cells','protected cells and existing Molnár pad')
(r/rel).write_text(json.dumps(core,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
new=['commons/artifacts/array_floor_writer/array_floor_writer.gd','commons/artifacts/array_floor_writer/array_floor_writer.tscn','commons/artifacts/registry/array_floor_writer.json']
for p in (r/'commons/artifacts/array_floor_writer').glob('*.uid'):new.append(p.relative_to(r).as_posix())
(o/'new-files.json').write_text(json.dumps(new+[f['canonical'] for f in figs],indent=2)+'\n',encoding='utf-8')
(o/'runtime-source-hashes.json').write_text(json.dumps({p:sha(r/p) for p in new+['commons/maps/Array/map_data.json','commons/hazards/gridagent/grid_agent_base.gd','commons/grid/GridStructureComponent.gd','commons/artifacts/regularity/room_tools.gd','doc/book/iterations/2026-09-24-arrays-review-comments/floor-probe.gd']},indent=2)+'\n',encoding='utf-8')
checks=[]
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)});assert ok,label
oldcore=json.loads((o/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for m in maps:
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig')
 check(core['rooms'][m]['text_sha256']==sha(p),m+' current manuscript hash')
 check(re.findall(r'```[^\n]*\n(.*?)```',a,re.S)==re.findall(r'```[^\n]*\n(.*?)```',s,re.S),m+' original code excerpts preserved')
 oldanchors=re.findall(r'<!--.*?-->',a);anchors=re.findall(r'<!--.*?-->',s)
 if m=='Array':anchors.remove('<!-- @array_floor_writer -->')
 check(oldanchors==anchors,m+' original encounter anchors preserved')
 check('\ufffd' not in s,m+' clean UTF-8')
 check(set(re.findall(r'\[\^([^\]]+)\](?!:)',s))==set(re.findall(r'^\[\^([^\]]+)\]:',s,re.M)),m+' footnotes resolve')
 with urllib.request.urlopen('http://localhost:3003/api/book-text?map='+m,timeout=20) as response:live=json.load(response)
 check(live['sections']['final'].replace('\r\n','\n').strip()==s.strip(),m+' live chapter matches canonical file')
 for link in re.findall(r'!\[[^\]]*\]\(/book-review/([^\)]+)\)',s):check((r/link).is_file(),m+' figure exists '+link)
 if m!='Array':
  expected=dict(oldcore['rooms'][m]);expected['text_sha256']=core['rooms'][m]['text_sha256'];expected['local_review']=core['rooms'][m]['local_review'];check(expected==core['rooms'][m],m+' core record only hash/review update')
outside_changes={m:{'baseline':oldcore['rooms'][m],'current':before_core_write['rooms'][m]} for m in set(oldcore['rooms'])-set(maps) if oldcore['rooms'][m]!=before_core_write['rooms'][m]}
(o/'outside-scope-changes-preserved.json').write_text(json.dumps(outside_changes,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for m in set(before_core_write['rooms'])-set(maps):check(before_core_write['rooms'][m]==core['rooms'][m],'Unrelated core room preserved from current state '+m)
check((o/'before/commons/maps/Tutorial_Tiling_Floor/final.md').read_bytes()==(r/'commons/maps/Tutorial_Tiling_Floor/final.md').read_bytes(),'Mature floor chapter retained without edits')
old=json.loads((o/'before/commons/maps/Array/map_data.json').read_text(encoding='utf-8-sig'));now=json.loads((r/'commons/maps/Array/map_data.json').read_text(encoding='utf-8-sig'))
check(old['layers']['interactables'][17][15]=='gridagent:copy','Original generic agent located at documented cell')
old['layers']['interactables'][17][15]='array_floor_writer:0:0#plinth:0#pin:1';old['dev_notes']=now['dev_notes'];check(old==now,'Only agent token and developer note changed in Array map')
for m in maps[1:]:check((o/'before/commons/maps'/m/'map_data.json').read_bytes()==(r/'commons/maps'/m/'map_data.json').read_bytes(),m+' all map cells preserved')
seq=json.loads((r/'commons/maps/sequences/array_tutorial.json').read_text(encoding='utf-8-sig'));check(seq['sequences']['array_tutorial']['maps']==maps,'Five-hall reading order preserved')
oldseq=json.loads((o/'before/commons/maps/sequences/array_tutorial.json').read_text(encoding='utf-8-sig'))
for groups in [oldseq['artifact_groups'],oldseq['sequences']['array_tutorial']['artifact_groups']]:
 for group in groups:
  if group['map']=='Array':group['artifacts'].insert(2,'array_floor_writer')
check(oldseq==seq,'Sequence change limited to new primary floor encounter')
roles=json.loads((r/'commons/data/artifact_roles.json').read_text(encoding='utf-8-sig'));oldroles=json.loads((o/'before/commons/data/artifact_roles.json').read_text(encoding='utf-8-sig'))
for key in roles:
 if isinstance(roles[key],dict):check({k:v for k,v in roles[key].items() if k!='Array'}=={k:v for k,v in oldroles[key].items() if k!='Array'},'Other artifact '+key+' preserved')
 else:check(roles[key]==oldroles[key],'Role metadata preserved '+key)
check(roles['order']['Array']['primary']==core['rooms']['Array']['primary_tokens'],'Array primary order agrees across curation records')
for f in figs:
 check(sha(r/f['source'])==sha(r/f['canonical'])==f['sha256'],'Byte-identical native figure '+f['canonical'])
 with urllib.request.urlopen('http://localhost:3003/book-review/'+f['canonical'],timeout=20) as response:check(response.status==200 and hashlib.sha256(response.read()).hexdigest()==f['sha256'],'HTTP serves exact figure '+f['canonical'])
for folder,count in [('floor',25),('wall',28),('disco',131)]:
 report=json.loads((o/folder/'report.json').read_text(encoding='utf-8'));check(report['passed'] and not report['failures'] and len(report['checks'])==count,folder+': '+str(count)+' native checks passed')
check('step % disco_floor.grid_width' in (r/'commons/context/discofloor/DiscoSequencerBridge.gd').read_text(encoding='utf-8'),'Remainder expression matches source')
for rel in changed+new:
 p=r/rel;after=o/'after'/rel;after.parent.mkdir(parents=True,exist_ok=True);after.write_bytes(p.read_bytes());before=o/'before'/rel
 a=before.read_text(encoding='utf-8-sig') if before.exists() else '';b=p.read_text(encoding='utf-8-sig')
 if rel=='commons/data/museum_core_encounters.json':
  a=json.dumps({m:oldcore['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n';b=json.dumps({m:core['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n'
 diff=o/'diffs'/(rel+'.diff');diff.parent.mkdir(parents=True,exist_ok=True);diff.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(o/'verification.json').write_text(json.dumps({'checks':checks,'scope':'Scoped source preservation, current manuscript API, native capture publication and isolated runtime. No headset or learner acceptance.'},indent=2)+'\n',encoding='utf-8')
source=json.loads((o/'before/doc/tasks/book_array_tutorial.json').read_text(encoding='utf-8-sig'));rows=[]
notes=['# Arrays: review decisions, 24 September 2026','','12 comments resolved across five halls. Four manuscripts received targeted changes; Tutorial_Tiling_Floor remains unchanged. Comments 003 and 008 concern the same sentence.','','## The author’s decision','','Develop the changing floor. The old agent really edited the hall: an eight-second diagnostic removed 38 floor cells. A new map-specific encounter keeps the shared agent intact elsewhere, limits each state to one write, and gives the visitor physical pause/restore controls. The table and the floor are separate records. The floor is now an encounter in the primary reading order, before the Molnár study.','','## Evidence and limits','','The floor run passes 25 controlled native checks; the wall and disco recaptures pass 28 and 131 respectively. A real museum body descends to the existing surface one metre below an exposed consumed cell. The agent was moved aside for that support test so its own collision did not catch the body. Restoration waits for the body to leave. Threshold/perimeter cells and the Molnár pad remain protected. These tests do not establish headset comfort, a full visitor traverse or recovery from every depression. They do not certify Quest performance.','','Earlier failed tests remain in floor-first/, floor-covered-cell/ and floor-body-contact/. They exposed the lower surface, the separate Molnár pad and contact with the paused sphere respectively. The production fix protects the existing pad; the controlled support test isolates the sphere contact explicitly. No failed run is presented as passing.','','The two floor photographs use the same camera, with supplied mutations paused for comparison. Three wall/disco composites were recaptured from native Godot viewport frames with the desktop-only mushroom count hidden. Historical figures remain unchanged; current final.md files use stable book figure paths. The live museum bake/save was not replaced. Reload/rebuild the Array hall to see its new source placement.','','## Decisions','']
for t in source['tasks']:
 d=D[t['id']];notes += [f"### {t['id']} — {t['title']}",'',f"**{d['layer']} · resolved**",'',d['decision'],'']
 rows.append('<tr><td>'+html.escape(t['id'].split('.')[-1])+'<br>'+html.escape(t['hall'])+'</td><td><strong>'+html.escape(t['title'])+'</strong><p>'+html.escape(d['decision'])+'</p></td></tr>')
(o/'DECISIONS.md').write_text('\n'.join(notes),encoding='utf-8')
comparisons=[]
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
 diff=difflib.HtmlDiff(wrapcolumn=85).make_table(a.splitlines(),b.splitlines(),fromdesc='Before',todesc='Current final.md',context=True,numlines=2) if a!=b else '<p>The existing text holds. No changes.</p>'
 comparisons.append(f'<details id="{m}"><summary>{m.replace("_"," ")}</summary><p><a href="/compose/sources?map={m}&amp;doc=final">Read the current chapter</a></p><div class="diffwrap">{diff}</div></details>')
css='body{background:#f5f0e8;color:#242329;font:17px/1.65 Georgia,serif;margin:0}main{max-width:1200px;margin:auto;padding:48px 28px}h1{font-size:48px;line-height:1.1}p{max-width:85ch}a{color:#674575}nav{display:flex;gap:24px;flex-wrap:wrap}.pair{display:grid;grid-template-columns:1fr 1fr;gap:14px}figure{margin:0}img{width:100%;height:auto}figcaption{font-size:15px;padding:10px 0 20px}table{border-collapse:collapse;width:100%}td,th{padding:12px;vertical-align:top;border-bottom:1px solid #ccc}details{margin:20px 0;padding:18px;border:1px solid #ccc}summary{cursor:pointer;font:bold 21px Georgia}.diffwrap{overflow:auto}.diff{font:12px/1.45 monospace}.diff td{padding:4px}.diff_add{background:#d3e9d6}.diff_sub{background:#f2d3d1}.diff_chg{background:#f4e6b5}.diff_header{background:#e2ded7}blockquote{margin:32px 0;padding:8px 28px;border-left:3px solid #917099;font-size:23px}@media(max-width:700px){.pair{grid-template-columns:1fr}h1{font-size:36px}}'
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Arrays — a floor being written</title><style>'''+css+'''</style><main><p>Ada Research · 24 September 2026</p><h1>A floor being written</h1><p>The Array hall now lets the sphere change the actual floor. Copying raises a cell into the route; consuming an exposed cell reveals the surface below. The visitor can pause the writing and restore the floor.</p><nav><a href="/compose/sources?map=Array&amp;doc=final">Read Array</a><a href="#diffs">Text differences</a><a href="/book-tasks/review?seq=array_tutorial&amp;map=Array">Review queue</a><a href="DECISIONS.md">Decisions and evidence</a></nav><h2>The same place, changed and restored</h2><div class="pair"><figure><img src="the-written-floor.png" alt="Copied blocks and consumed cells in the actual Array hall floor"><figcaption>Copy and consume · supplied operations, paused for comparison.</figcaption></figure><figure><img src="floor-restored.png" alt="The floor after restoration from the same camera"><figcaption>RESTORE FLOOR · the starting occupancy returns.</figcaption></figure></div><blockquote>An empty slot was something we could point to. Underfoot, absence asks something of our balance.</blockquote><p>The floor’s grid and the pickup tables keep separate records. The new passage makes that distinction while letting the same question reach the body: what remains available at an address?</p><h2>Pause, observe, restore</h2><img src="restore-at-the-entrance.png" alt="The floor controls near the hall entrance"><p>Controls remain near the entrance. Restoration waits wherever a body occupies a changed cell. The perimeter, thresholds and the Molnár study’s separate floor pad stay intact. A controlled body test confirms the one-metre drop; headset movement and recovery still need observation.</p><h2>Small repairs across the sequence</h2><p>Twelve comments are resolved, including two findings about one wall sentence. Four canonical chapters have targeted changes; the existing floor-tiling chapter remains intact. Flight instructions now match the controller, the console is read on returning to the doorway, and the row, wall sheet and sequencer are easier to locate.</p><details><summary>Three freshly captured book figures</summary><figure><img src="two-turns.png" alt="The patterned wall closed and open"><figcaption>The same wall, two turns.</figcaption></figure><figure><img src="fixed-addresses-changing-values.png" alt="The disco floor at two checker phases"><figcaption>Fixed addresses, changing values.</figcaption></figure><figure><img src="triangle-combinations.png" alt="Six black and white triangular disco patterns"><figcaption>Triangle combinations. Native Godot viewport frames; desktop-only overlay hidden during capture.</figcaption></figure></details><p><a href="floor/report.json">25 floor checks</a> · <a href="wall/report.json">28 wall checks</a> · <a href="disco/report.json">131 disco checks</a>. Isolated production museum runs; no headset or learner acceptance is claimed. Reload/rebuild the hall to see its new placement.</p><h2 id="diffs">What changed in final.md</h2>'''+''.join(comparisons)+'''<h2>Comment by comment</h2><table><thead><tr><th>Comment</th><th>Decision</th></tr></thead><tbody>'''+''.join(rows)+'''</tbody></table></main></html>'''
(o/'index.html').write_text(page,encoding='utf-8')
print(f'Published paired native views, 12 decisions and exact differences; {len(checks)} publication/preservation checks passed.')
