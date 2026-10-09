from pathlib import Path
import difflib,hashlib,html,json,re,shutil
import markdown
r=Path.cwd();rel='doc/book/iterations/2026-09-25-ca-opening-review';o=r/rel
maps=['CA_Introduction','CA_ElementaryRules','CA_GameOfLife','CA_BeyondBinary','CA_AgentsCircuits']
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
checks=[]
def check(name,passed):checks.append({'name':name,'passed':bool(passed)});assert passed,name
base=json.loads((o/'baseline.json').read_text());owned=json.loads((o/'changed-files.json').read_text())
later=['commons/data/museum_core_encounters.json','doc/tasks/book_cellularautomata.json','doc/book/captures/cellularautomata/cellularautomata-book.md','doc/book/captures/cellularautomata/cellularautomata-book.manifest.json']
for path,sha in base.items():
 if path not in owned+later:check('retained: '+path,H(r/path)==sha)
for m in maps:
 a=(o/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');b=(r/'commons/maps'/m/'final.md').read_text()
 check(m+': all code excerpts retained',re.findall(r'```.*?```',a,re.S)==re.findall(r'```.*?```',b,re.S))
 check(m+': encounter anchors retained',re.findall(r'<!--.*?-->',a)==re.findall(r'<!--.*?-->',b))
for m in ['CA_ElementaryRules','CA_BeyondBinary']:check(m+': manuscript unchanged',H(r/'commons/maps'/m/'final.md')==base[f'commons/maps/{m}/final.md'])
a=(o/'before/commons/maps/CA_Introduction/final.md').read_text();b=(r/'commons/maps/CA_Introduction/final.md').read_text()
start='Just beyond the desk,';end='<!-- @persian_rug -->'
check('new ring encounter preserved word for word',a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)])
a=(o/'before/commons/maps/CA_GameOfLife/final.md').read_text();b=(r/'commons/maps/CA_GameOfLife/final.md').read_text()
start='Leave the desk and walk';end='The same record is dressed'
check('new walking-history encounter preserved word for word',a[a.index(start):a.index(end)]==b[b.index(start):b.index(end)])
older=r/'doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_Introduction/after.md'
shutil.copy2(older,o/'claude-audited-opening.md')
write(o/'claude-to-current-before-pass.diff',''.join(difflib.unified_diff(older.read_text(encoding='utf-8-sig').splitlines(True),(o/'before/commons/maps/CA_Introduction/final.md').read_text().splitlines(True),fromfile='Claude audited opening',tofile='Current opening before this pass')))
check('audited opening code excerpts retained',re.findall(r'```.*?```',older.read_text(),re.S)==re.findall(r'```.*?```',(r/'commons/maps/CA_Introduction/final.md').read_text(),re.S))

# Geometry and placement changes are limited to the inactive runner and lab signage.
def read(rel,before=False):return json.loads(((o/'before'/rel) if before else (r/rel)).read_text(encoding='utf-8-sig'))
for m in maps:
 p=f'commons/maps/{m}/map_data.json';a=read(p,True);b=read(p)
 check(m+': structure and utilities retained',a['layers']['structure']==b['layers']['structure'] and a['layers']['utilities']==b['layers']['utilities'])
 if m=='CA_Introduction':
  for row in a['layers']['interactables']:
   for i,v in enumerate(row):
    if v=='grid_substrate_runner':row[i]=' '
 elif m=='CA_GameOfLife':
  for row_a,row_b in zip(a['layers']['interactables'],b['layers']['interactables']):
   for i,v in enumerate(row_a):
    if str(v).startswith('lab_room#'):
     old=v.split('#');new=row_b[i].split('#');allowed=['signage_top','signage_sub','signage_wall','signage_height_offset','show_wall_annotations','annotation_top','annotation_bottom']
     check('lab changes signage only',[s for s in old if s.split(':',1)[0] not in allowed]==[s for s in new if s.split(':',1)[0] not in allowed])
     row_a[i]=row_b[i]
 if m in ['CA_ElementaryRules','CA_GameOfLife','CA_BeyondBinary']:a['map_info']['title']=b['map_info']['title']
 check(m+': no other map changes',a==b)
bookpath='commons/data/book/cellularautomata.json';a=read(bookpath,True);b=read(bookpath)
for pa,pb in zip(a['pearls'],b['pearls']):
 if pa['map'] in ['CA_ElementaryRules','CA_GameOfLife','CA_BeyondBinary']:
  title=(r/'commons/maps'/pa['map']/'final.md').read_text().splitlines()[0].removeprefix('# ')
  check(pa['map']+': pearl and hall use the chapter title',pb['pearl']==title and read('commons/maps/'+pa['map']+'/map_data.json')['map_info']['title']==title);pa['pearl']=pb['pearl']
check('book roles, IDs, order and all other pearls retained',a==b)
seqpath='commons/maps/sequences/cellularautomata.json';a=read(seqpath,True);b=read(seqpath)
a['sequences']['cellularautomata']['content']=b['sequences']['cellularautomata']['content']
check('sequence route, prerequisites, artifact lists retained',a==b)

reports=[];warnings=[]
for tag in ['intro-after','history-final-height']:
 report=read(rel+'/'+tag+'/report.json');process=read(rel+'/'+tag+'/process.json');log=(o/tag/'stdout.log').read_text(errors='replace')
 check(tag+': native assertions pass',report['passed'] and not report['failures'])
 check(tag+': process exits zero',process['exit_code']==0)
 check(tag+': no script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
 reports.append(report);warnings.extend(s for s in log.splitlines() if 'WARNING:' in s or 'ERROR:' in s)
write(o/'engine-warnings.json',json.dumps(list(dict.fromkeys(warnings)),indent=2)+'\n')
pre=read(rel+'/intro-before/report.json')['observations']['runner']
check('runner removal grounded in native absence of target and geometry',pre['target_present'] is False and pre['meshes']==0)
check('stand still contributes visible geometry',reports[0]['observations']['stand_meshes']>0)

capture=r/'doc/book/captures/cellularautomata/cellularautomata-book.md';manifest=read('doc/book/captures/cellularautomata/cellularautomata-book.manifest.json')
check('all eight captured halls current',len(manifest['maps'])==8 and all(H(r/m['path'])==m['sha256'] for m in manifest['maps']))
check('capture hash matches manifest',H(capture)==manifest['output_sha256'])
shutil.copy2(capture,o/'cellularautomata-book.md')

corepath='commons/data/museum_core_encounters.json';core=read(corepath);prior=json.loads(json.dumps(core))
write(o/'core-before-update.json',json.dumps(prior,ensure_ascii=False,indent=2)+'\n')
for m in maps:core['rooms'][m].update(text_sha256=H(r/'commons/maps'/m/'final.md'),map_sha256=H(r/'commons/maps'/m/'map_data.json'),local_review=rel+'/DECISIONS.md')
write(r/corepath,json.dumps(core,ensure_ascii=False,indent=2)+'\n')
for m in maps:
 permitted={'text_sha256','map_sha256','local_review'}
 check(m+': roles and verification status retained',{k:v for k,v in prior['rooms'][m].items() if k not in permitted}=={k:v for k,v in core['rooms'][m].items() if k not in permitted})
check('other core references retained',all(v==prior['rooms'][m] for m,v in core['rooms'].items() if m not in maps))

decisions={
 'book_cellularautomata.001':{'status':'done','triage':'fix','decision':'The retained lab now asks WHAT COUNTS AS COMPUTATION? and names its tape/head/states model. The unsupported universality assertion and side annotations are removed from this placement. Native photographs exposed occlusion by the apparatus and exit light; the sign uses the existing rear-wall option plus a new optional -0.55 m height offset. Other labs default to offset zero. All five artifacts stay.'},
 'book_cellularautomata.004':{'status':'done','triage':'fix','decision':'The opening now locates the smaller CA RULES panel between the study buttons and board and names its actual 90 and 30 buttons. Agents/Circuits makes the same one-sentence correction, naming 90 then RST. Native signals verify preset selection, reset and held STEP in the opening; headset reach/readability remain unverified.'},
 'book_cellularautomata.007':{'status':'done','triage':'fix','decision':'Shortened the Noise recap to Keep the pleasure of the blob. Bring an unfinished question with it. The board and its invitation to predict arrive sooner; the earlier Noise ending already carries the fuller critique.'},
 'book_cellularautomata.010':{'status':'done','triage':'fix','decision':'The chapter now notices the rear columns, orb, lab and mirrored automaton. It distinguishes the apparatus model from a proof, without inventing a new primary lesson or removing the supporting collection.'},
 'book_cellularautomata.013':{'status':'done','triage':'fix','decision':'Kept the bridge index excerpt and solver explanation; replaced the repeated bit-weight lesson with a return to the board in the first hall. The new walking-history paragraphs stay word for word.'},
 'book_cellularautomata.014':{'status':'done','triage':'fix','decision':'Made the two contrasting outcomes explicit: 100 yields an occupied cell, 010 an empty one. The existing Wolfram footnote now gives all eight ordered inputs and answers, keeping the main encounter moving. Native evaluation confirms 111 through 000 maps to 0,1,0,1,1,0,1,0. No new claim that all eight answers appear together in VR.'},
 'book_cellularautomata.015':{'status':'done','triage':'comment','decision':'Compared the audited opening with the newer chapter. Keep the current version: it corrects NEXT to STEP, names the saved arrival history, includes the supported surrounding ring and retains the historical references. All audited code excerpts and the existing size:2.0 network placement remain. This review makes only targeted opening/orientation/precision edits.'},
 'book_cellularautomata.017':{'status':'done','triage':'fix','decision':'Fresh native inspection finds no GridMultiMesh target and no rendered geometry for grid_substrate_runner. Removed that one hall placement; its implementation and registry remain. The synthesis stand builds visible geometry around its dark_sphere subject, so it stays secondary and is briefly acknowledged in the chapter. No whole-floor CA claim is made.'},
 'book_cellularautomata.033':{'status':'done','triage':'fix','decision':'Aligned the three visitor-facing pearl/hall titles with their current chapters: A cell with a past; A history you can inhabit; A pattern visits an address. The corresponding sequence content labels agree. Historical map IDs, order, placements, artifact roles and routes remain; this is a naming repair, not a redeal.'}}
write(o/'decisions.json',json.dumps(decisions,ensure_ascii=False,indent=2)+'\n')
tasks={t['id']:t for t in read('doc/tasks/book_cellularautomata.json')['tasks']}
notes='''# Cellular Automata — opening review

25 September 2026. Focus: opening orientation, the three misleading historical hall names, and the retained gallery behind the Rule 30 history. The more recent ring, enlarged neighbourhood, walking history and Life floor are substantial improvements; this pass preserves them. It does not impose another full rewrite on the opening.

## Decisions

'''+ '\n\n'.join('### '+k+' — '+tasks[k]['title']+'\n\n'+v['decision'] for k,v in decisions.items())+'''

## Two additional precision edits

Langton’s ants are called moving agents rather than moving cells. The close no longer promises that every later hall changes one or two rule choices: the history hall explicitly changes the representation while retaining the rule, and the pyramid is not an automaton. The four useful questions remain, followed by the more concrete distinction between changing the rule and giving a record another body. The checklist-like phrase “the second choice and the first” is removed from the next-hall invitation.

## What was checked

Final focused runs pass 27 assertions: 13 in CA_Introduction and 14 in the history hall. Both exit zero with no script/shader errors. Supplied actual console signals select 90 and 30, reset and advance a held row. All eight Rule 90 cases match the chapter note. The ring and stand remain. The lab retains its apparatus, builds the revised title and subtitle, omits the crowded annotations and uses the lowered rear sign. The new sign-height export defaults to zero; it changes no other lab unless configured.

These are focused signal, state and camera checks. They do not replace the earlier mouse-ray/body tests, certify a headset route, profile the rug on Quest or review the whole rear gallery's interaction. Existing UID, environment, registry, renderer and material warnings are recorded. The runner's missing-target warning disappears with its placement; no global runner implementation was deleted.

The before and after lab overview views share a camera. The readable question photograph faces the opposite wall because the sign moved; it is not presented as a same-camera comparison. Intermediate photographs show why changing only the wording was insufficient: the apparatus occluded the first position, and the exit light crossed the second. The final view clears both. One attempted file write failed before opening the target; content was checked and the scoped edit retried. Its duplicate intermediate run remains as history-final; the accepted run is history-final-height.

The Rule 90 answer list belongs to a footnote. The museum still shows one local neighbourhood at a time. The small rule controls remain behind the larger study panel; their standing/leaning readability and actual hand reach remain a headset check, not something proved by a button signal.

## Publication and continuity

Three final.md files change: Introduction, history and one sentence in Agents/Circuits. Elementary Rules and Beyond Binary retain their entire manuscripts. All code excerpts, artifact anchors, recent encounter passages and critical companion essays stay. Current inventory/encounter notes record the removed runner and changed lab; dated earlier nine-placement records remain as historical observations. Three pearl/hall titles change without changing their IDs. No route is rebuilt.

The current eight-hall capture is refreshed. Earlier captures/reviews stay frozen. Nine comments are resolved; the other thirteen remain, including headset/performance tasks. The rest of Agents/Circuits is not reviewed in this pass. Later halls and the sequence's older descriptive metadata remain for the next passes. Next: CA_ExpandingSpace and CA_SoftRules, checking their new/current encounters before revising the prose. No commit.
'''
write(o/'DECISIONS.md',notes)
for path in later:
 if path!='doc/tasks/book_cellularautomata.json':owned.append(path)
for path in owned:
 p=r/path;dest=o/'after'/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
 a=(o/'before'/path).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 if path==corepath:
  a=json.dumps({m:prior['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n';b=json.dumps({m:core['rooms'][m] for m in maps},ensure_ascii=False,indent=2)+'\n'
 write(o/'diffs'/(path+'.diff'),''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+path,tofile=path)))
write(o/'changed-files.json',json.dumps(owned,indent=2)+'\n')
write(o/'source-manifest.json',json.dumps([{'path':p,'before_sha256':base.get(p),'after_sha256':H(r/p)} for p in owned],indent=2)+'\n')

def diff(m):
 a=(o/'before/commons/maps'/m/'final.md').read_text();b=(r/'commons/maps'/m/'final.md').read_text()
 return difflib.HtmlDiff(wrapcolumn=70).make_table(a.splitlines(),b.splitlines(),fromdesc='Before this pass',todesc='Current final.md',context=True,numlines=2)
sections=[]
for m in ['CA_Introduction','CA_GameOfLife']:
 text=(r/'commons/maps'/m/'final.md').read_text();reading=markdown.markdown(text,extensions=['fenced_code','footnotes'])
 for src in re.findall(r'<img[^>]*src="([^"]+)"',reading):
  if not src.startswith(('http','/')):
   dest='chapter-images/'+m+'/'+src;target=o/dest;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(r/'commons/maps'/m/src,target);reading=reading.replace('src="'+src+'"','src="'+dest+'"')
 reading=re.sub(r'id="([^"]+)"',lambda v:'id="'+m+'-'+v[1]+'"',reading);reading=re.sub(r'href="#([^"]+)"',lambda v:'href="#'+m+'-'+v[1]+'"',reading)
 sections.append(f'<section id="{m}"><h2>{m.replace("_"," ")}</h2><p><a href="/compose/sources?map={m}&amp;doc=final">Current chapter and comments</a></p><details><summary>Exact text comparison</summary><div class="diffwrap">{diff(m)}</div></details><div class="reading">{reading}</div></section>')
css=re.search(r'<style>(.*?)</style>',(r/'doc/book/iterations/2026-09-25-noise-opening-review/index.html').read_text(),re.S)[1]
def fig(p,c):return '<figure><a href="'+p+'"><img loading="lazy" src="'+p+'" alt="'+html.escape(c,quote=True)+'"></a><figcaption>'+c+'</figcaption></figure>'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cellular Automata — opening review</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>Arrive in time to ask</h1><p>The board waits while the rug continues. You can answer before the next row arrives, then stand inside the past that the calculation has kept. The opening already has a strong encounter; these changes clear the way to it.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the changes</a><a href="DECISIONS.md">Decisions and limits</a><a href="/book-tasks/review?seq=cellularautomata">Review comments</a><a href="cellularautomata-book.md">Current sequence capture</a></nav><p>Nine comments resolved. Shorter recap, clearer orientation and returns, honest lab signage, and names that describe the encounters. The recent immersive work stays.</p><h2 id="museum">The row surrounds us</h2>'+fig('intro-after/inside-history-ring.png','Fresh native museum view from inside the retained history ring. Height marks past updates; standing here does not make the visitor one of the rule’s inputs.')+fig('intro-after/board-and-rule-panels.png','Fresh native view of the two panels. The smaller rule panel is nearer the board; STEP, RUN, SEED and CELL belong to the study in front. Headset hand reach remains unverified.')+'<h2>The lab asks a question</h2><div class="pair">'+fig('history-before/lab-sign.png','Before: the front title and universality claim sit partly behind the apparatus screen.')+fig('history-final-height/lab-sign.png','After, from the same camera: the lab and apparatus remain; the question has moved to the rear wall and the side annotations are gone.')+'</div>'+fig('history-final-height/lab-question.png','Turn around: the revised question sits below the exit light. This is a different view of the same retained room.')+'<h2>Names that meet the work</h2><table><thead><tr><th>Historical map ID</th><th>Reader-facing title</th></tr></thead><tbody>'+''.join('<tr><td>'+m+'</td><td>'+html.escape((r/'commons/maps'/m/'final.md').read_text().splitlines()[0].removeprefix('# '))+'</td></tr>' for m in ['CA_ElementaryRules','CA_GameOfLife','CA_BeyondBinary'])+'</tbody></table><p>Identifiers, route and order stay fixed. The two manuscripts outside this text pass retain their wording.</p><h2 id="reading">Read the two chapters</h2>'+''.join(sections)+'<section><h2>One matching correction later</h2><p>Agents/Circuits now names the same 90 and RST buttons. Its remaining text awaits its own review.</p><details><summary>That sentence beside the original</summary><div class="diffwrap">'+diff('CA_AgentsCircuits')+'</div></details><p><a href="claude-to-current-before-pass.diff">Earlier audited opening compared with the newer chapter</a> · <a href="verification.json">Preservation checks</a> · <a href="intro-after/report.json">Opening native checks</a> · <a href="history-final-height/report.json">Lab native checks</a> · <a href="engine-warnings.json">Engine warnings</a></p><p>27 focused native assertions pass. Headset and performance tasks remain open. Next: the body-sensitive and soft-rule encounters.</p></section></main></html>'
write(o/'index.html',page)
write(o/'verification.json',json.dumps({'passed':True,'checks':checks,'native_assertions':sum(len(x['checks']) for x in reports),'scope':'Focused opening prose, descriptive names, inactive runner placement and lab signage. Not a full-sequence or headset acceptance.'},indent=2)+'\n')
print('Published',len(checks),'preservation checks;',sum(len(x['checks']) for x in reports),'native assertions.')
