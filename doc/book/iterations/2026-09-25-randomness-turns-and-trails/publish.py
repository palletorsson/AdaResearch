from pathlib import Path
import json,hashlib,difflib,re,html,urllib.request,markdown,shutil
r=Path.cwd();o=Path(__file__).parent;base=json.loads((o/'baseline.json').read_text());maps=base['maps'];checks=[]
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def check(ok,label):
 checks.append({'check':label,'passed':bool(ok)})
 assert ok,label
figs=json.loads((o/'figure-provenance.json').read_text())
for f in figs:
 shutil.copy2(r/f['source'],r/f['canonical']);f['sha256']=H(r/f['source'])
(o/'figure-provenance.json').write_text(json.dumps(figs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
prior=json.loads((o/'core-before-update.json').read_text());core=json.loads((r/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for m in maps:
 p=r/'commons/maps'/m/'final.md';s=p.read_text();old=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig')
 check(re.findall(r'```[^\n]*\n(.*?)```',old,re.S)==re.findall(r'```[^\n]*\n(.*?)```',s,re.S),m+': code excerpts retained')
 anchors=re.findall(r'<!--.*?-->',old);newanchors=re.findall(r'<!--.*?-->',s)
 if m=='Random_Walk':
  newanchors.remove('<!-- @pixel_cloud -->');newanchors.remove('<!-- @random_walk_terrarium -->')
 check(anchors==newanchors,m+': original anchors retained; two intentional Walk anchors added')
 check(core['rooms'][m]['text_sha256']==H(p) and core['rooms'][m]['map_sha256']==H(r/'commons/maps'/m/'map_data.json'),m+': current core references')
 a=dict(prior['rooms'][m]);b=dict(core['rooms'][m])
 for k in ['text_sha256','map_sha256','local_review']:a.pop(k,None);b.pop(k,None)
 check(a==b,m+': roles and review maturity retained')
 with urllib.request.urlopen('http://localhost:3003/api/book-text?map='+m,timeout=20) as response:live=json.load(response)
 check(live['sections']['final'].replace('\r\n','\n').strip()==s.strip(),m+': live reader serves canonical text')
changed_maps=['commons/maps/'+m+'/final.md' for m in maps]+['commons/maps/'+m+'/map_data.json' for m in ['Random_Rotate_Random_XYZ','Random_Gaussian']]
for rel,h in base['files'].items():
 if rel.startswith('commons/maps/') and rel not in changed_maps:
  check(H(r/rel)==h,rel+': unchanged')
for rel in ['commons/data/artifact_roles.json','commons/data/book/randomness.json','ada_run/em_plan.json','commons/data/museum/em_plan.json']:
 if rel in base['files']:check(H(r/rel)==base['files'][rel],rel+': unchanged')
for m in ['Random_Rotate_Random_XYZ','Random_Gaussian']:
 a=json.loads((o/'before/commons/maps'/m/'map_data.json').read_text(encoding='utf-8-sig'));b=json.loads((r/'commons/maps'/m/'map_data.json').read_text())
 if m=='Random_Rotate_Random_XYZ':
  a['layers']['interactables'][11][3]=' ';a['layers']['interactables'][11][6]='RotateGridCubes#study:compact'
 else:
  for row in a['layers']['interactables']:
   for i,v in enumerate(row):
    if 'distribution_sampler:' in v:row[i]=v+'#readout:wing'
 check(a==b,m+': only intended artifact cells changed')
check('paired_dice_column' in (r/'commons/maps/Random_Cubes/final.md').read_text() and 'continuing_die' in (r/'commons/maps/Random_Cubes/final.md').read_text(),'Newer dice studies retained')
native=0;limitations={}
for sub,count in [('rotation-after',9),('gaussian-after',11)]:
 d=json.loads((o/sub/'report.json').read_text());exitcode=json.loads((o/sub/'process.json').read_text())['exit_code'];log=(o/sub/'stdout.log').read_text(errors='replace')
 check(d['passed'] and len(d['checks'])==count and not d['failures'],sub+': native assertions passed');native+=count
 check(exitcode==0,sub+': native process exits successfully')
 check('SCRIPT ERROR' not in log,sub+': no GDScript error')
 limitations[sub]={'exit_code':exitcode,'warnings':[l for l in log.splitlines() if 'ERROR:' in l or 'WARNING:' in l]}
(o/'engine-limitations.json').write_text(json.dumps(limitations,indent=2)+'\n')
for f in figs:
 check(H(r/f['canonical'])==H(r/f['source'])==f['sha256'],'Original museum PNG copied unchanged: '+f['canonical'])
 with urllib.request.urlopen('http://localhost:3003/book-review/'+f['canonical'],timeout=20) as response:check(hashlib.sha256(response.read()).hexdigest()==f['sha256'],'HTTP serves original figure')
manifest=json.loads((r/'doc/book/captures/randomness/randomness-book.manifest.json').read_text())
check(all(H(r/m['path'])==m['sha256'] for m in manifest['maps']),'All 14 chapters match current capture')
check(H(r/'doc/book/captures/randomness/randomness-book.md')==manifest['output_sha256'],'Capture hash correct')
(o/'verification.json').write_text(json.dumps({'passed':True,'checks':checks,'native_assertions':native,'scope':'Two actual museum halls, controlled cameras and supplied connected button signals; no headset, tracked-hand throw, comfort, Quest or full route acceptance.'},indent=2)+'\n')
owned=changed_maps+['algorithms/randomness/SlopeGradientCubes.gd','commons/artifacts/distribution_sampler/distribution_sampler.gd','commons/data/museum_core_encounters.json','doc/book/figures/README.md','doc/book/captures/randomness/randomness-book.md','doc/book/captures/randomness/randomness-book.manifest.json']
for rel in owned:
 p=r/rel;dest=o/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes());a=(o/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 if rel=='commons/data/museum_core_encounters.json':a=json.dumps({m:prior['rooms'][m] for m in maps},indent=2)+'\n';b=json.dumps({m:core['rooms'][m] for m in maps},indent=2)+'\n'
 if rel=='doc/book/figures/README.md':a=(o/'figures-before-update.md').read_text()
 dest=o/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(o/'changed-files.json').write_text(json.dumps(owned+[f['canonical'] for f in figs],indent=2)+'\n')
D=json.loads((o/'decisions.json').read_text());q=json.loads((r/'doc/tasks/book_randomness.json').read_text(encoding='utf-8-sig'));tasks={t['id']:t for t in q['tasks']}
rows=''.join('<tr><td>'+html.escape(k+' · '+tasks[k]['title'])+'</td><td><strong>'+v['status']+'</strong> — '+html.escape(v['decision'])+'</td></tr>' for k,v in D.items())
sections=[]
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text()
 reading=markdown.markdown(b,extensions=['fenced_code','footnotes'])
 reading=re.sub(r'id="([^"]+)"',lambda v:'id="'+m+'-'+v[1]+'"',reading);reading=re.sub(r'href="#([^"]+)"',lambda v:'href="#'+m+'-'+v[1]+'"',reading)
 table=difflib.HtmlDiff(wrapcolumn=70).make_table(a.splitlines(),b.splitlines(),fromdesc='Before',todesc='Current final.md',context=True,numlines=2)
 sections.append(f'<section id="{m}"><h2>{m.replace("_"," ")}</h2><p><a href="/compose/sources?map={m}&amp;doc=final">Current chapter and comments</a></p><details><summary>Exact text changes beside the original</summary><div class="diffwrap">{table}</div><a href="diffs/commons/maps/{m}/final.md.diff">Plain text diff</a></details><div class="reading">{reading}</div></section>')
def pair(a,ac,b,bc):
 return '<div class="pair">'+''.join('<figure><a href="'+p+'"><img src="'+p+'" alt="'+html.escape(c,quote=True)+'"></a><figcaption>'+c+'</figcaption></figure>' for p,c in [(a,ac),(b,bc)])+'</div>'
css='body{margin:0;background:#f3eee5;color:#302b31;font:18px/1.65 Georgia,serif}main{max-width:1180px;margin:auto;padding:40px 26px}h1{font-size:48px;line-height:1.13}h2{line-height:1.25}a{color:#72526c}p{max-width:78ch}nav{display:flex;gap:20px;flex-wrap:wrap}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:20px 0}img{width:100%;height:auto}figcaption{font-size:15px}.reading{max-width:760px;margin:40px auto}.reading h1{font-size:35px}section{margin-top:45px;border-top:1px solid #cfc6bb;padding-top:24px}details{padding:18px;border:1px solid #cfc6bb}summary{cursor:pointer}.diffwrap{overflow:auto}.diff{font:12px/1.4 monospace}.diff_header{background:#e2d9cd}.diff_add{background:#d9ead8}.diff_sub{background:#efd9d5}.diff_chg{background:#f0e5b8}table{border-collapse:collapse;width:100%}td,th{vertical-align:top;padding:9px;border-bottom:1px solid #ccc}pre{overflow:auto;background:#e8e1d7;padding:15px;font-size:13px}@media(max-width:750px){.pair{grid-template-columns:1fr}h1{font-size:35px}}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Randomness — turns and trails</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>Turns and trails</h1><p>One throw. An angle that keeps accumulating. A path that remembers earlier positions. A count that gathers their differences into a shape. Four halls ask what a rule keeps, and what a picture lets us see.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the four halls</a><a href="DECISIONS.md">Decisions and limits</a><a href="/book-tasks/review?seq=randomness">Review comments</a></nav><p>Eight comments resolved. Two spatial repairs, small text changes, and the newer dice and walking studies retained. Two headset tasks and die tuning remain open.</p><h2 id="museum">The whole turn fits</h2>'
page+=pair('rotation-before/tilt-field.png','Before: the field begins at the side of the room and continues through the back wall.','rotation-after/tilt-field.png','Now: twenty-five cubes contain the whole level / tilted / level progression. Same interior camera.')
page+='<p>The field is still. Its curve belongs to the rows; your walk gives those rows an order. The two larger stacks continue to accumulate turns. Their difference now has room to be seen.</p><h2>The count becomes visible</h2>'
page+=pair('gaussian-before/sampler-standing.png','Before: the compact console hides the plate the chapter asks you to read.','gaussian-after/sampler-standing.png','Now: the same standing camera shows the raised side record. Turn toward it to read the whole plate.')
page+=pair('gaussian-after/sampler-readout.png','Looking toward the record from the marked standing place: law, count, clipping, bins and the paused state are visible.','gaussian-after/sampler-overview.png','A wider view from that same standing place keeps the compact controls and histogram together.')
page+='<details><summary>What was checked</summary><p>20 assertions passed in native museum runs, both exiting successfully. The field fits inside the walls and clears the floor. BINS regroups 300 retained values; WIDTH changes spread and clears them. The original layouts remain the default in other placements. Original PNGs and process reports are archived here.</p><p>The initial sampler diagnostic emitted the wrong button signal. That probe error is recorded, corrected, and distinguished from the original visual obstruction. Existing engine warnings remain in the logs. These are controlled desktop camera and signal tests; tracked-hand throws, headset comfort and full route checks remain open.</p><p><a href="verification.json">Publication checks</a> · <a href="rotation-after/report.json">Field report</a> · <a href="gaussian-after/report.json">Sampler report</a> · <a href="figure-provenance.json">Image provenance</a></p></details><section><h2>Each review comment</h2><table>'+rows+'</table></section><section id="reading"><h2>The four halls</h2><nav>'+''.join(f'<a href="#{m}">{m.replace("_"," ")}</a>' for m in maps)+'</nav></section>'+''.join(sections)+'</main></html>'
(o/'index.html').write_text(page,encoding='utf-8')
print(f'{len(checks)} publication/preservation checks passed; {native} native assertions. Reading and exact diffs published.')
