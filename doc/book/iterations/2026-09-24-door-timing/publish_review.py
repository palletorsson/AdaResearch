from pathlib import Path
import json,hashlib,difflib,re,html
H=Path(__file__).resolve().parent;R=H.parents[3]
def read(p):return p.read_text(encoding='utf-8-sig')
def load(p):return json.loads(read(p))
def save(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 if not ok:raise AssertionError(name)
map_path=R/'commons/maps/Random_Game/map_data.json';chapter_path=R/'commons/maps/Random_Game/final.md'
old=read(H/'before/commons/maps/Random_Game/final.md');new=read(chapter_path)
marker='<!-- @door_timing_trials -->';following='<!-- @cube_projectile_spawner -->'
passage=new.split(marker)[1].split(following)[0].strip()
closing_old='These doors arrange the order differently: the assignment precedes your choice, though its disclosure waits for it.'
closing_new='The fire doors arrange the order differently: the assignment precedes your choice, though its disclosure waits for it. The three passages let us separate those events and walk what follows.'
without=new[:new.index(marker)]+new[new.index(following):]
check('all earlier prose preserved except named closing transition',without.replace(closing_new,closing_old)==old)
a=load(H/'before/commons/maps/Random_Game/map_data.json');b=load(map_path)
check('hall extended by fourteen rows',b['map_info']['dimensions']['depth']==66)
for layer,rows in a['layers'].items():
 restored=b['layers'][layer][:32]+b['layers'][layer][46:]
 check('every former row retained: '+layer,restored==rows)
 for row in range(32,46):
  expected=['w']+['1']*17+['w'] if layer=='structure' else [' ']*19
  if layer=='interactables' and row==38:expected[9]='door_timing_trials'
  check('new bay row %s %d'%(layer,row),b['layers'][layer][row]==expected)
for key in ['utility_definitions','lighting','settings']:check('retained '+key,a[key]==b[key])
check('old fire door source unchanged',sha(H/'before/commons/artifacts/randomness_space/random_doors.gd')==sha(R/'commons/artifacts/randomness_space/random_doors.gd'))
primaries=re.findall(r'<!-- @([^\s>]+) -->',new)
check('book primary order',primaries==['r_c','random_removal_arena','random_doors','door_timing_trials','cube_projectile_spawner'])
seq_path=R/'commons/maps/sequences/randomness.json';seq=load(seq_path);before_seq=load(H/'before/commons/maps/sequences/randomness.json')
check('sequence map order retained',seq['sequences']['randomness']['maps']==before_seq['sequences']['randomness']['maps'])
group=next(g for g in seq['sequences']['randomness']['artifact_groups'] if g['map']=='Random_Game')
check('sequence groups agree with book',group['artifacts']==primaries)
registry=load(R/'commons/artifacts/registry/randomness.json');check('registry scene exists',(R/registry['artifacts']['door_timing_trials']['scene'].removeprefix('res://')).exists())
native=load(H/'native-checks.json');museum=load(H/'museum-runtime.json')
check('native run passed',len(native['checks'])>=64 and not native['failures'] and 'SCRIPT ERROR' not in read(H/'native.log'))
check('actual museum run passed',museum['passed'] and not museum['failures'] and 'SCRIPT ERROR' not in read(H/'museum-process.log'))
for key in ['checks','walks','rays']:check('museum '+key+' pass',bool(museum[key]) and all(c['passed'] for c in museum[key]))
for name in ['before.png','after.png','room.png','plan.png']:check('native image '+name,(H/name).stat().st_size>1000)
# Refresh only this chapter in the shared record, preserving concurrent work.
p=R/'commons/data/museum_core_encounters.json';d=load(p);room=d['rooms']['Random_Game'];room['text_sha256']=sha(chapter_path);room['map_sha256']=sha(map_path);room['primary_tokens']=primaries
room['verification_scope']='Door timing addition: 64 native control/state/collision checks; actual museum player plate entry, direct and detour walks, reset refusal and sampled gallery bypasses. No headset/learner or whole-hall hazard/performance acceptance. Earlier encounter evidence retained in previous reviews.'
room['learner_verified']=False;save(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
check('core record agrees with book',room['primary_tokens']==primaries and room['text_sha256']==sha(chapter_path))
files=[p.relative_to(H/'before') for p in (H/'before').rglob('*') if p.is_file()]
files += [p.relative_to(R) for p in (R/'commons/artifacts/door_timing_trials').iterdir() if p.is_file()]
manifest=[];diff=[]
for f in sorted(set(files)):
 prior=H/'before'/f;current=R/f
 before=read(prior) if prior.exists() else '';after=read(current)
 save(H/'after'/f,after)
 manifest.append({'path':f.as_posix(),'before_sha256':sha(prior) if prior.exists() else None,'after_sha256':sha(current)})
 if f.as_posix()=='commons/data/museum_core_encounters.json':
  before=json.dumps({'Random_Game':json.loads(before)['rooms']['Random_Game']},ensure_ascii=False,indent=2)+'\n';after=json.dumps({'Random_Game':json.loads(after)['rooms']['Random_Game']},ensure_ascii=False,indent=2)+'\n'
 diff.extend(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+f.as_posix(),tofile='after/'+f.as_posix()))
save(H/'changes.diff',''.join(diff));save(H/'source-manifest.json',json.dumps(manifest,indent=2)+'\n')
save(H/'before-final.md',old);save(H/'after-final.md',new);save(H/'new-passage.md',passage+'\n')
css='body{font:16px system-ui;background:#f5f1e9;padding:25px;color:#252d2e}table{width:100%;border-collapse:collapse}td{padding:4px;vertical-align:top}.diff_header{background:#deded4}.diff_add{background:#c8ecdb}.diff_sub{background:#f2c9d0}.diff_next{display:none}th{font:24px Georgia;text-align:left;padding:18px}'
table=difflib.HtmlDiff(wrapcolumn=76).make_table(old.splitlines(),new.splitlines(),fromdesc='Before',todesc='After — one new encounter and a closing transition',context=True,numlines=3)
save(H/'text-diff.html','<!doctype html><html lang="en"><meta charset="utf-8"><title>Door timing — exact text differences</title><style>'+css+'</style><h1>When did the door decide?</h1><p><a href="index.html">Return to the illustrated review</a></p>'+table+'</html>')
reading=''
for i,part in enumerate(passage.split('```')):
 if i%2:reading+='<pre><code>'+html.escape(part.removeprefix('text').strip())+'</code></pre>'
 else:
  for paragraph in part.strip().split('\n\n'):
   if paragraph:reading+='<p>'+html.escape(paragraph)+'</p>'
style=re.search(r'<style>(.*?)</style>',read(H.parent/'2026-09-24-continuing-die/index.html'),re.S).group(1)
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>When did the door decide? — Ada Research</title><style>STYLE</style><main>
<div class="eyebrow">Ada Research · Random Game · 24 September 2026</div><h1>When did the door decide?</h1><p class="lead">The same two routes. Three different orders of drawing, choosing and finding out. A new encounter makes the consequence a distance you walk.</p>
<nav><a href="#comparison">Before / after choosing</a><a href="#reading">New book passage</a><a href="text-diff.html">Exact text differences</a><a href="#evidence">What was checked</a><a href="http://localhost:3003/compose/sources?map=Random_Game&amp;doc=final">Current chapter</a><a href="http://localhost:3003/necklace/thread?map=Random_Game&amp;role=primary">Primary encounters</a></nav>
<figure><a href="room.png"><img src="room.png" alt="Three full-size coloured doorway trials across the Random Game hall"></a><figcaption>SHOWN FIRST, DRAWN AFTER, HIDDEN FIRST. The visitor chooses by stepping onto A or B. The plates and portals use the same geometry in all three trials. Actual Godot museum view after controlled choices.</figcaption></figure>
<h2 id="comparison">A question mark has two possible histories</h2><div class="pair"><figure><a href="before.png"><img src="before.png" alt="Drawn After before a choice: two closed doors and an empty event timeline"></a><figcaption><strong>Before.</strong> In DRAWN AFTER, neither a choice nor a draw has happened. In HIDDEN FIRST, the answer already exists but remains concealed.</figcaption></figure><figure><a href="after.png"><img src="after.png" alt="A selected doorway opens, but its shortcut remains closed; a turn leads around it"></a><figcaption><strong>After.</strong> A controlled detour choice in DRAWN AFTER: CHOOSE → DRAW → REVEAL. The selected entrance opens. The wall asks for a turn.</figcaption></figure></div>
<blockquote>Knowing does not prescribe what you must want.</blockquote>
<p>SHOWN FIRST lets you read DIRECT and AROUND before stepping. DRAWN AFTER assigns the shortcut after your choice. HIDDEN FIRST assigns it at reset, then waits for your choice before disclosure. A repeated footfall never redraws the answer.</p>
<h2>Turn the outcome into architecture</h2><figure><a href="plan.png"><img src="plan.png" alt="Overhead view of the matched central lanes and longer routes around opaque walls"></a><figcaption>The direct lane crosses its opened shortcut. The other lane turns outward, follows the wall, and rejoins behind it. Either route reaches the far side; either entrance allows retreat. Side corridors remain available around the whole exhibit.</figcaption></figure>
<p>The hall extends from 52 to 66 rows for this bay. All previous floor rows, utilities and configured artifacts survive: crossing → removal floor → fire doors → these three passages → falling field → waiting profile. The old fire doors keep their separate, more threatening consequence.</p>
<h2 id="reading">New book passage</h2><div class="reading">PASSAGE</div><p><a href="text-diff.html">Exact before / after</a> · <a href="after-final.md">Full current chapter</a> · <a href="before-final.md">Previous chapter</a></p>
<h2 id="evidence">What was checked</h2><table><tr><th>Native artifact</th><td>NATIVE_COUNT checks pass: production pointer controls, plate entry, one draw per round, event order, both route collisions, replay during opening, and refusal to reset around an occupant. The fixture also uses a translated and rotated host.</td></tr><tr><th>Actual museum</th><td>MUSEUM_COUNT checks pass with the museum player: body-triggered choices in all three trials, direct passages, the detour, and occupied reset. Three further walks check the side bypasses and rear cross passage; two floor rays check the bay.</td></tr><tr><th>Preserved work</th><td>Every former map row survives the insertion. The existing fire-door source is unchanged. One new book encounter and one closing transition; primary order, sequence notes and manuscript hashes agree.</td></tr></table>
<p class="note">These are controlled desktop tests and native renders, not headset or learner acceptance. Seeds reproduce assignments, not visitor memory. No statistical study is claimed. Rebuild the hall to load its new source placement; the active museum bake/save has not been replaced.</p>
<details><summary>Decisions and reproducible evidence</summary><p><a href="DECISIONS.md">Decisions</a> · <a href="changes.diff">Source differences</a> · <a href="source-manifest.json">Frozen versions</a> · <a href="publication-checks.json">Preservation checks</a> · <a href="native-checks.json">Native checks</a> · <a href="museum-runtime.json">Museum checks</a> · <a href="../2026-09-24-randomness-physical-examples/PLAN.md">Original plan</a></p><p class="small">Final passing runs contain no script errors. The unresolved UID warning remains. Early harness failures were a floor parent type, exact float comparison, and missing current-scene host; they required no changes to the retained exhibits. Shared core differences are scoped to this hall. No full-book export or commit.</p></details>
<p><a href="../2026-09-24-continuing-die/index.html">Previous: the six that does not finish</a></p></main></html>'''
page=page.replace('STYLE',style).replace('PASSAGE',reading).replace('NATIVE_COUNT',str(len(native['checks']))).replace('MUSEUM_COUNT',str(len(museum['checks'])))
save(H/'index.html',page)
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
for link in re.findall(r'(?:href|src)="([^"]+)"',page):
 if not link.startswith(('http:','https:','#')):check('review link exists: '+link,(H/link).exists())
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
print('Published',len(checks),'preservation/publication checks;',len(native['checks']),'native;',len(museum['checks']),'museum.')
