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
files += [p.relative_to(R) for p in (R/'commons/artifacts/random_position_rails').iterdir() if p.is_file()]
manifest=[];diff=[]
for f in files:
 before=H/'before'/f;current=R/f
 a=read(before) if before.exists() else '';b=read(current)
 save(H/'after'/f,b)
 manifest.append({'path':f.as_posix(),'before_sha256':sha(before) if before.exists() else None,'after_sha256':sha(current)})
 if f.as_posix()=='commons/data/museum_core_encounters.json':
  a=json.dumps(json.loads(a)['rooms']['Random_Walk'],ensure_ascii=False,indent=2)+'\n';b=json.dumps(json.loads(b)['rooms']['Random_Walk'],ensure_ascii=False,indent=2)+'\n'
 diff.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+f.as_posix(),tofile='after/'+f.as_posix()))
save(H/'changes.diff',''.join(diff));save(H/'source-manifest.json',json.dumps(manifest,indent=2)+'\n')
a=load(H/'before/commons/maps/Random_Walk/map_data.json');b=load(R/'commons/maps/Random_Walk/map_data.json')
check('original floor and utilities retained',all(a['layers'][k]==b['layers'][k] for k in ['structure','utilities']))
check('all three layers remain 19 by 26',all(len(v)==26 and all(len(row)==19 for row in v) for v in b['layers'].values()))
cells=[(x,z,u,v) for z,(ar,br) in enumerate(zip(a['layers']['interactables'],b['layers']['interactables'])) for x,(u,v) in enumerate(zip(ar,br)) if u!=v]
check('one new placement; all existing placements retained',cells==[(13,8,' ','random_position_rails:180')])
a=load(H/'before/commons/maps/sequences/randomness.json');b=load(R/'commons/maps/sequences/randomness.json')
check('fourteen-hall order retained',a['sequences']['randomness']['maps']==b['sequences']['randomness']['maps'] and len(b['sequences']['randomness']['maps'])==14)
old=read(H/'before/commons/maps/Random_Walk/final.md');new=read(R/'commons/maps/Random_Walk/final.md')
check('every original manuscript line retained',re.sub(r'<!-- @random_position_rails -->.*?(?=<!-- @random_draw_dot -->)','',new,flags=re.S)==old)
core=load(R/'commons/data/museum_core_encounters.json')['rooms']['Random_Walk']
check('four primaries follow book encounter order',core['primary_tokens']==re.findall(r'<!-- @([a-z_0-9]+) -->',new))
check('core manuscript and map hashes current',core['text_sha256']==sha(R/'commons/maps/Random_Walk/final.md') and core['map_sha256']==sha(R/'commons/maps/Random_Walk/map_data.json'))
reg=load(R/'commons/artifacts/registry/randomness.json')['artifacts']['random_position_rails']
check('registry scene exists',(R/reg['scene'].removeprefix('res://')).exists())
native=load(H/'native-checks.json');museum=load(H/'museum-runtime.json')
check('native control and motion checks pass',not native['failures'] and bool(native['checks']) and all(c['passed'] for c in native['checks']))
check('museum artifact checks pass',not museum['failures'] and bool(museum['checks']) and all(c['passed'] for c in museum['checks']))
check('all three walking routes pass',len(museum['walks'])==3 and all(c['passed']for c in museum['walks']))
check('approach floor retained',all(c['passed']for c in museum['rays']))
check('no native script errors','SCRIPT ERROR' not in read(H/'native.log') and 'SCRIPT ERROR' not in read(H/'museum-process.log'))
state=museum['rail_state'];check('fifteen paired moves and twelve-row record',state['tick']==15 and len(state['history'])==12)
for f in ['before.png','targets.png','first-move.png','fifteen-moves.png','room.png']:check('native capture exists: '+f,(H/f).stat().st_size>1000)
save(H/'before-final.md',old);save(H/'after-final.md',new)
passage=re.search(r'<!-- @random_position_rails -->\s*(.*?)\s*(?=<!-- @random_draw_dot -->)',new,re.S).group(1)
save(H/'new-passage.md',passage+'\n')
css='body{font:16px system-ui;background:#f5f1e9;padding:25px;color:#252d2e}table{width:100%;border-collapse:collapse}td{padding:4px;vertical-align:top}.diff_header{background:#deded4}.diff_add{background:#c8ecdb}.diff_sub{background:#f2c9d0}.diff_next{display:none}th{font:24px Georgia;text-align:left;padding:18px}'
table=difflib.HtmlDiff(wrapcolumn=78).make_table(old.splitlines(),new.splitlines(),fromdesc='Before — preserved',todesc='After — an added comparison',context=True,numlines=3)
save(H/'text-diff.html','<!doctype html><html lang="en"><meta charset="utf-8"><title>Random Walk — book addition</title><style>'+css+'</style><h1>Somewhere to start</h1><p><a href="index.html">Back to the hall</a></p>'+table+'</html>')
reading=''.join('<h3>'+html.escape(p[3:])+'</h3>' if p.startswith('## ') else '<p>'+html.escape(p)+'</p>'for p in passage.split('\n\n'))
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Somewhere to start — Ada Research</title><style>
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#f5f1e9;color:#252d2e;font:18px/1.65 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:44px 24px 80px}h1{font:clamp(2.5rem,5vw,4.4rem)/1.08 Georgia,serif}h2{font:2rem Georgia,serif;margin-top:2em}.eyebrow{font-size:.8rem;letter-spacing:.12em;text-transform:uppercase;color:#596963}.lead{font-size:1.25rem;max-width:800px}a{color:#166c7d;text-underline-offset:.18em}nav{display:flex;flex-wrap:wrap;gap:1em;font-size:.9rem;margin:1.7em 0}img{display:block;width:100%;height:auto;border-radius:5px}figure{margin:0}figcaption{font-size:.87rem;color:#58635f;margin:.6em 0 1.5em}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}.reading{max-width:740px;font:1.15rem/1.8 Georgia,serif}blockquote{border-left:4px solid #bd5270;padding:.4em 1.2em;margin:2em 0;max-width:870px;font:1.5rem/1.5 Georgia,serif}.note{background:#e5e4db;border-radius:5px;padding:1.2em 1.4em}.small{font-size:.87rem;color:#58635f}details{margin:1.5em 0}summary{cursor:pointer}table{border-collapse:collapse;width:100%}td,th{padding:.6em;border-bottom:1px solid #cfcec3;text-align:left;vertical-align:top}@media(max-width:750px){.pair{grid-template-columns:1fr}table{font-size:.85rem}}
</style><main><div class="eyebrow">Ada Research · Random Walk · 24 September 2026</div><h1>Somewhere to start.</h1><p class="lead">Two carriages receive the same new number. One takes a fresh position. The other adds a small step to where it already is. Put your marker where you think one will land.</p>
<nav><a href="#comparison">Watch the difference</a><a href="#reading">Book addition</a><a href="text-diff.html">Before / after text</a><a href="#evidence">What was checked</a><a href="http://localhost:3003/compose/sources?map=Random_Walk&amp;doc=final">Current chapter</a><a href="http://localhost:3003/necklace/thread?map=Random_Walk&amp;role=primary">Primary encounters</a></nav>
<figure><a href="room.png"><img src="room.png" alt="Paired rail carriages beside the existing terrarium and in front of the glass-framed walk terrain"></a><figcaption>The rails occupy one new place in Random_Walk. The terrarium, hand-drawn trace, terrain and existing companions remain. Actual Godot museum render.</figcaption></figure>
<h2 id="comparison">What does the last position give you?</h2><div class="pair"><figure><a href="before.png"><img src="before.png" alt="Both carriages begin at the centre; no history is invented"></a><figcaption><strong>Before a pull.</strong> Both bodies begin at the centre. The marker awaits a guess.</figcaption></figure><figure><a href="fifteen-moves.png"><img src="fifteen-moves.png" alt="After fifteen paired moves blue's recorded positions span the rail while pink's remain near the centre"></a><figcaption><strong>After fifteen moves.</strong> Twelve landing pairs remain below. Blue reaches across the rail; pink has accumulated short steps.</figcaption></figure></div>
<p>Both targets appear before the motors move. The journeys then take the same time with the same easing. This makes the comparison visible: a smooth journey can join freshly sampled places, while the small addition carries a previous position into the next choice.</p>
<blockquote>Looking continuous is not enough to tell us what a process remembers.</blockquote>
<details><summary>Targets before movement</summary><div class="pair"><figure><a href="targets.png"><img src="targets.png" alt="Outline targets appear while both carriages are still at their previous positions"></a><figcaption>The selected destinations are shown for 0.65 seconds before motion.</figcaption></figure><figure><a href="first-move.png"><img src="first-move.png" alt="The two carriages have completed their first movement from a shared input"></a><figcaption>First landing. The seeded first draw is small; the records acquire their difference across further moves.</figcaption></figure></div></details>
<h2>Four encounters, a thread</h2><p>The terrarium makes a trail whose next heading does not read it. The rails separate a new destination from a new step. Your hand carries the drawing dot's origin. The terrain holds visits as height. Each asks what is retained, and what that retention lets the next movement do.</p><p>The cases in the previous addition changed the set of possible choices. These rails change how a choice acts on a body. The same draw can mean a place or a displacement.</p>
<h2 id="reading">New book passage</h2><div class="reading">PASSAGE</div><p><a href="text-diff.html">Exact text comparison</a> · <a href="after-final.md">Revised chapter</a> · <a href="before-final.md">Previous chapter</a></p>
<h2 id="evidence">What was checked</h2><table><tr><th>Controls and motion</th><td>NATIVE_COUNT native checks pass: supplied pointer input through the real NEXT lever, prediction slider and replay/run controls; shared draw, targets before motion, matched easing, bounded record, reflection and replay during movement.</td></tr><tr><th>Actual museum</th><td>MUSEUM_COUNT checks pass, plus three sampled walking routes and a floor ray. All earlier artifacts remain. The marker moves through the production pointer body.</td></tr><tr><th>Preservation</th><td>Every previous manuscript line, placement, structure and utility is retained. One added exhibit and one added passage. Book primaries, current intent and tutorial notes align. Fourteen-hall sequence unchanged.</td></tr></table>
<p class="note">Headset grip, reach and comfort are still open. The two rules intentionally share a seeded input; this is not a physical randomness source. The moving blocks illustrate the results and are not rideable. The live museum bake/save was not replaced; the source placement appears when the hall is rebuilt.</p>
<details><summary>Decisions and reproducible evidence</summary><p><a href="DECISIONS.md">Decisions</a> · <a href="changes.diff">Source differences</a> · <a href="source-manifest.json">Preserved versions</a> · <a href="publication-checks.json">Preservation checks</a> · <a href="native-checks.json">Native results</a> · <a href="museum-runtime.json">Museum results</a> · <a href="../2026-09-24-randomness-physical-examples/PLAN.md">Original proposal</a></p><p class="small">The passing runs contain no script errors. An unresolved project UID warning and an undiagnosed ObjectDB exit leak warning remain in the native log. Shared core metadata differences are scoped to Random_Walk. No full-book export or commit.</p></details>
<p><a href="../2026-09-24-sampling-hoppers/index.html">Previous: the bag remembers</a></p></main></html>'''
page=page.replace('PASSAGE',reading).replace('NATIVE_COUNT',str(len(native['checks']))).replace('MUSEUM_COUNT',str(len(museum['checks'])))
save(H/'index.html',page)
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
for url in re.findall(r'(?:href|src)="([^"]+)"',page):
 if not url.startswith(('http:','https:','#')):check('review link exists: '+url,(H/url).exists())
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
print('Published review;',len(checks),'preservation/publication checks;',len(native['checks']),'native;',len(museum['checks']),'museum. All pass.')
