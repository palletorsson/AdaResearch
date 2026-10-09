from pathlib import Path
import json,re,hashlib,difflib,html
H=Path(__file__).resolve().parent;R=H.parents[3]
def read(p):return p.read_text(encoding='utf-8-sig')
def load(p):return json.loads(read(p))
def save(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 if not ok:raise AssertionError(name)
files=sorted(p.relative_to(H/'before') for p in (H/'before').rglob('*') if p.is_file())
files+= [p.relative_to(R) for p in (R/'commons/artifacts/sampling_hoppers').iterdir() if p.is_file()]
files.append(Path('commons/maps/Random_Remove/encounter-notes.md'))
manifest=[];diff=[]
for f in files:
 before=H/'before'/f;current=R/f
 a=read(before) if before.exists() else '';b=read(current)
 save(H/'after'/f,b)
 manifest.append({'path':f.as_posix(),'before_sha256':sha(before) if before.exists() else None,'after_sha256':sha(current)})
 if f.as_posix()=='commons/data/museum_core_encounters.json':
  a=json.dumps(json.loads(a)['rooms']['Random_Remove'],ensure_ascii=False,indent=2)+'\n';b=json.dumps(json.loads(b)['rooms']['Random_Remove'],ensure_ascii=False,indent=2)+'\n'
 diff.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+f.as_posix(),tofile='after/'+f.as_posix()))
save(H/'changes.diff',''.join(diff));save(H/'source-manifest.json',json.dumps(manifest,indent=2)+'\n')
a=load(H/'before/commons/maps/Random_Remove/map_data.json');b=load(R/'commons/maps/Random_Remove/map_data.json')
check('original floor and utilities retained',all(a['layers'][k]==b['layers'][k] for k in ['structure','utilities']))
check('all three layers are 17 by 26',all(len(v)==26 and all(len(row)==17 for row in v) for v in b['layers'].values()))
cells=[(x,z,u,v) for z,(ar,br) in enumerate(zip(a['layers']['interactables'],b['layers']['interactables'])) for x,(u,v) in enumerate(zip(ar,br)) if u!=v]
check('only one new placement; old artifacts retained',cells==[(3,6,' ','sampling_hoppers:180')])
a=load(H/'before/commons/maps/sequences/randomness.json');b=load(R/'commons/maps/sequences/randomness.json')
check('fourteen-hall order retained',a['sequences']['randomness']['maps']==b['sequences']['randomness']['maps'] and len(b['sequences']['randomness']['maps'])==14)
old=read(H/'before/commons/maps/Random_Remove/final.md');new=read(R/'commons/maps/Random_Remove/final.md')
check('every original manuscript line retained',re.sub(r'<!-- @sampling_hoppers -->.*?(?=<!-- @random_removal_arena -->)','',new,flags=re.S)==old)
core=load(R/'commons/data/museum_core_encounters.json')['rooms']['Random_Remove']
check('three primary tokens match book encounter order',core['primary_tokens']==re.findall(r'<!-- @([a-z_]+) -->',new))
check('core text and map hashes current',core['text_sha256']==sha(R/'commons/maps/Random_Remove/final.md') and core['map_sha256']==sha(R/'commons/maps/Random_Remove/map_data.json'))
reg=load(R/'commons/artifacts/registry/randomness.json')['artifacts']['sampling_hoppers']
check('registry scene resolves',(R/reg['scene'].removeprefix('res://')).exists())
native=load(H/'native-checks.json');museum=load(H/'museum-runtime.json')
check('native pointer and transaction checks pass',len(native['checks'])==43 and not native['failures'] and all(c['passed']for c in native['checks']))
check('museum checks pass',len(museum['checks'])==11 and not museum['failures'] and all(c['passed']for c in museum['checks']))
check('three walking routes and approach floor pass',len(museum['walks'])==3 and all(c['passed']for c in museum['walks']) and all(c['passed']for c in museum['rays']))
state=museum['sampling_state'];check('eight draws leave eight versus zero candidates',state['totals']==[8,8] and len(state['pools'][0])==8 and len(state['pools'][1])==0)
for f in ['full.png','first-draw.png','four-draws.png','eight-draws.png','room.png']:check('native capture exists: '+f,(H/f).stat().st_size>1000)
save(H/'before-final.md',old);save(H/'after-final.md',new)
passage=re.search(r'<!-- @sampling_hoppers -->\s*(.*?)\s*(?=<!-- @random_removal_arena -->)',new,re.S).group(1)
save(H/'new-passage.md',passage+'\n')
css='body{font:16px system-ui;background:#f5f1e9;padding:25px;color:#252d2e}table{width:100%;border-collapse:collapse}td{padding:4px;vertical-align:top}.diff_header{background:#deded4}.diff_add{background:#c8ecdb}.diff_sub{background:#f2c9d0}.diff_next{display:none}th{font:24px Georgia;text-align:left;padding:18px}'
table=difflib.HtmlDiff(wrapcolumn=78).make_table(old.splitlines(),new.splitlines(),fromdesc='Before — preserved',todesc='After — new encounter',context=True,numlines=3)
save(H/'text-diff.html','<!doctype html><html lang="en"><meta charset="utf-8"><title>Random Remove — book addition</title><style>'+css+'</style><h1>Random Remove — an added encounter</h1><p><a href="index.html">Back to the hall</a></p>'+table+'</html>')
reading=''.join('<p>'+html.escape(p)+'</p>'for p in passage.split('\n\n'))
left=', '.join(map(str,state['histories'][0]));right=', '.join(map(str,state['histories'][1]))
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The bag remembers — Ada Research</title><style>
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#f5f1e9;color:#252d2e;font:18px/1.65 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:44px 24px 80px}h1{font:clamp(2.5rem,5vw,4.4rem)/1.08 Georgia,serif}h2{font:2rem Georgia,serif;margin-top:2em}.eyebrow{font-size:.8rem;letter-spacing:.12em;text-transform:uppercase;color:#596963}.lead{font-size:1.25rem;max-width:790px}a{color:#166c7d;text-underline-offset:.18em}nav{display:flex;flex-wrap:wrap;gap:1em;font-size:.9rem;margin:1.7em 0}img{display:block;width:100%;height:auto;border-radius:5px}figure{margin:0}figcaption{font-size:.87rem;color:#58635f;margin:.6em 0 1.5em}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}.reading{max-width:740px;font:1.15rem/1.8 Georgia,serif}blockquote{border-left:4px solid #bd5270;padding:.4em 1.2em;margin:2em 0;max-width:870px;font:1.5rem/1.5 Georgia,serif}.note{background:#e5e4db;border-radius:5px;padding:1.2em 1.4em}.small{font-size:.87rem;color:#58635f}details{margin:1.5em 0}summary{cursor:pointer}code{font-size:.9em}table{border-collapse:collapse;width:100%}td,th{padding:.6em;border-bottom:1px solid #cfcec3;text-align:left;vertical-align:top}@media(max-width:750px){.pair{grid-template-columns:1fr}}
</style><main><div class="eyebrow">Ada Research · Random Remove · 24 September 2026</div><h1>The bag remembers.</h1><p class="lead">Two cases begin with the same eight members. Pull their handles. One returns its choice; the other keeps it out. What must the machine do for the same number to become possible again?</p>
<nav><a href="#comparison">Compare the cases</a><a href="#reading">New book passage</a><a href="text-diff.html">Before / after text</a><a href="#evidence">Evidence</a><a href="http://localhost:3003/compose/sources?map=Random_Remove&amp;doc=final">Current chapter</a><a href="http://localhost:3003/necklace/thread?map=Random_Remove&amp;role=primary">Primary encounters</a></nav>
<figure><a href="room.png"><img src="room.png" alt="The new paired sampling cases beside the existing eligibility board and glass-framed disappearing floor"></a><figcaption>Added beside the existing board in Random_Remove. The board, removal floor, basin and permanent bypass remain in place. Actual Godot museum render.</figcaption></figure>
<div class="pair" id="comparison"><figure><a href="full.png"><img src="full.png" alt="Both transparent cases contain all eight numbered blocks before the first draw"></a><figcaption><strong>Before the first pull.</strong> Matching members, empty records.</figcaption></figure><figure><a href="eight-draws.png"><img src="eight-draws.png" alt="After eight pulls the left case remains full and the right contains only empty numbered slots"></a><figcaption><strong>After eight pulls each.</strong> The left set remains available. The right set is exhausted. The rows below keep the results.</figcaption></figure></div>
<p>The left record: <strong>LEFT_HISTORY</strong>.<br>The right record: <strong>RIGHT_HISTORY</strong>.</p><p class="small">These are the seeded production outcomes from the photographed run. The probe pulled both real lever controls through supplied pointer events; it did not inject the displayed results.</p>
<blockquote>On the right, the number you have just drawn is no longer available. An absence has become part of the next choice.</blockquote>
<h2>Three encounters, three questions</h2><p>The board asks who is eligible. The cases ask whether a chosen member returns. The floor asks what removal does to a body that needed its support. The addition gives the existing chapter another comparison without replacing its central work.</p><p>The draw happens in code. The visible movement carries the selected block forward and then either returns it or keeps it in the record. This lets the visitor inspect the rule's consequence; it is not a simulation of physical mixing.</p>
<details><summary>One draw, then four</summary><div class="pair"><figure><a href="first-draw.png"><img src="first-draw.png" alt="The first draw matches; only the right case loses a member"></a><figcaption>The first result matches because both independent generators begin with the same seed and bounds.</figcaption></figure><figure><a href="four-draws.png"><img src="four-draws.png" alt="Four draws leave the cases with different eligible sets"></a><figcaption>The next possibilities change when a member leaves.</figcaption></figure></div></details>
<h2 id="reading">New book passage</h2><div class="reading">PASSAGE</div><p><a href="text-diff.html">Read the exact text comparison</a> · <a href="after-final.md">Complete revised chapter</a> · <a href="before-final.md">Previous chapter</a></p>
<h2 id="evidence">What was checked</h2><table><tr><th>Native controls</th><td>43 checks pass, including supplied pointer events through the real levers and replay button, one draw per pull, exhaustion, repeated membership, bounded records and replay during motion.</td></tr><tr><th>In the museum</th><td>11 checks pass, plus three sampled walking routes and an approach floor ray. The cases load from the registry and the original two encounters remain.</td></tr><tr><th>Preservation</th><td>One new map placement; all existing structure, utilities and placements remain. Every original manuscript line is retained. The primary order, intent, tutorial notes and registry now include the cases. Fourteen-hall sequence order unchanged.</td></tr></table><p class="note">Headset reach and comfort remain to be tested. These are animated algorithmic selections, not measurements of physical randomness. The native run still reports the project's existing unresolved UID warning; no script errors occurred.</p>
<details><summary>Decisions and reproducible evidence</summary><p><a href="DECISIONS.md">Decisions</a> · <a href="changes.diff">Scoped source diff</a> · <a href="source-manifest.json">Source snapshots</a> · <a href="publication-checks.json">Preservation and link checks</a> · <a href="native-checks.json">Native interaction results</a> · <a href="museum-runtime.json">Museum results</a> · <a href="../2026-09-24-randomness-physical-examples/PLAN.md">Original encounter proposal</a></p><p>Shared core-record differences are scoped to Random_Remove. Other work in the shared repository is preserved. Isolated museum capture; no live bake/save replacement, full-book rebuild or commit.</p></details><p class="small">Next: compare a freshly chosen position with a position that accumulates small steps in Random_Walk.</p></main></html>'''
page=page.replace('LEFT_HISTORY',left).replace('RIGHT_HISTORY',right).replace('PASSAGE',reading)
save(H/'index.html',page)
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
for url in re.findall(r'(?:href|src)="([^"]+)"',page):
 if not url.startswith(('http:','https:','#')):check('review link exists: '+url,(H/url).exists())
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
print('Published review;',len(checks),'checks pass.')
