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
files += [p.relative_to(R) for p in (R/'commons/artifacts/continuing_die').iterdir() if p.is_file()]
manifest=[];diff=[]
for f in files:
 before=H/'before'/f;current=R/f
 a=read(before) if before.exists() else '';b=read(current)
 save(H/'after'/f,b)
 manifest.append({'path':f.as_posix(),'before_sha256':sha(before) if before.exists() else None,'after_sha256':sha(current)})
 if f.as_posix()=='commons/data/museum_core_encounters.json':
  a=json.dumps({m:json.loads(a)['rooms'][m] for m in ['Random_Cubes','Random_Game']},ensure_ascii=False,indent=2)+'\n';b=json.dumps({m:json.loads(b)['rooms'][m] for m in ['Random_Cubes','Random_Game']},ensure_ascii=False,indent=2)+'\n'
 diff.extend(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+f.as_posix(),tofile='after/'+f.as_posix()))
save(H/'changes.diff',''.join(diff));save(H/'source-manifest.json',json.dumps(manifest,indent=2)+'\n')
a=load(H/'before/commons/maps/Random_Cubes/map_data.json');b=load(R/'commons/maps/Random_Cubes/map_data.json')
check('all original structure and utilities retained',all(a['layers'][k]==b['layers'][k] for k in ['structure','utilities']))
check('map layers retain 12 by 20 dimensions',all(len(v)==20 and all(len(row)==12 for row in v) for v in b['layers'].values()))
cells=[(x,z,u,v) for z,(ar,br) in enumerate(zip(a['layers']['interactables'],b['layers']['interactables'])) for x,(u,v) in enumerate(zip(ar,br)) if u!=v]
check('one new cell; no displaced artifact',cells==[(2,5,' ','continuing_die:180')])
a=load(H/'before/commons/maps/sequences/randomness.json');b=load(R/'commons/maps/sequences/randomness.json')
check('fourteen-hall sequence order unchanged',a['sequences']['randomness']['maps']==b['sequences']['randomness']['maps'] and len(b['sequences']['randomness']['maps'])==14)
old=read(H/'before/commons/maps/Random_Cubes/final.md');new=read(R/'commons/maps/Random_Cubes/final.md')
check('every previous dice-hall manuscript line retained',re.sub(r'<!-- @continuing_die -->.*?(?=<!-- @coin_toss -->)','',new,flags=re.S)==old)
game_old=read(H/'before/commons/maps/Random_Game/final.md');game_new=read(R/'commons/maps/Random_Game/final.md')
check('every previous Random_Game line retained',game_new.replace(read(H/'game-return.md'),'')==game_old)
core=load(R/'commons/data/museum_core_encounters.json')['rooms']
check('six primaries follow book order',core['Random_Cubes']['primary_tokens']==re.findall(r'<!-- @([a-z_0-9]+) -->',new))
for m in ['Random_Cubes','Random_Game']:check(m+' current text hash',core[m]['text_sha256']==sha(R/f'commons/maps/{m}/final.md'))
check('current cubes map hash',core['Random_Cubes']['map_sha256']==sha(R/'commons/maps/Random_Cubes/map_data.json'))
for path in ['commons/artifacts/paired_dice_column/paired_die.gd','algorithms/randomness/dice_throw/dice_throw.gd']:check('reused source unchanged: '+path,sha(R/path)==sha(H/'before'/path))
reg=load(R/'commons/artifacts/registry/randomness.json')['artifacts']['continuing_die'];check('registry points to existing scene',(R/reg['scene'].removeprefix('res://')).exists())
native=load(H/'native-checks.json');museum=load(H/'museum-runtime.json')
check('32 native checks pass',len(native['checks'])==32 and not native['failures'] and all(c['passed'] for c in native['checks']))
check('all museum checks pass',bool(museum['checks']) and not museum['failures'] and all(c['passed'] for c in museum['checks']))
check('three walking routes and approach floor pass',len(museum['walks'])==3 and all(c['passed']for c in museum['walks']) and all(c['passed']for c in museum['rays']))
check('passing runs have no script errors','SCRIPT ERROR' not in read(H/'native.log') and 'SCRIPT ERROR' not in read(H/'museum-process.log'))
check('live 6+6+3 finishes at fifteen',museum['complete_chain']['chain']==[6,6,3] and museum['complete_chain']['total']==15 and museum['complete_chain']['closed'])
check('five sixes are unfinished, not completed',museum['capped_chain']['chain']==[6]*5 and museum['capped_chain']['total']==30 and museum['capped_chain']['capped'] and not museum['capped_chain']['closed'])
for name in ['room.png','empty.png','six.png','fifteen.png','unfinished.png']:check('museum image exists: '+name,(H/name).stat().st_size>1000)
save(H/'before-final.md',old);save(H/'after-final.md',new);save(H/'game-after.md',game_new)
passage=re.search(r'<!-- @continuing_die -->\s*(.*?)\s*<!-- @ -->',new,re.S).group(1)
save(H/'new-passage.md',passage+'\n')
css='body{font:16px system-ui;background:#f5f1e9;padding:25px;color:#252d2e}table{width:100%;border-collapse:collapse}td{padding:4px;vertical-align:top}.diff_header{background:#deded4}.diff_add{background:#c8ecdb}.diff_sub{background:#f2c9d0}.diff_next{display:none}th{font:24px Georgia;text-align:left;padding:18px}'
table=difflib.HtmlDiff(wrapcolumn=78).make_table(old.splitlines(),new.splitlines(),fromdesc='Before — preserved',todesc='After — an added encounter',context=True,numlines=3)
table+='\n<h2>Return in Random_Game</h2>'+difflib.HtmlDiff(wrapcolumn=78).make_table(game_old.splitlines(),game_new.splitlines(),fromdesc='Before',todesc='After — one return',context=True,numlines=2)
save(H/'text-diff.html','<!doctype html><html lang="en"><meta charset="utf-8"><title>The continuing die — text differences</title><style>'+css+'</style><h1>The six that does not finish</h1><p><a href="index.html">Back to the hall</a></p>'+table+'</html>')
reading=''
for i,part in enumerate(passage.split('```')):
 if i%2: reading+='<pre><code>'+html.escape(part.removeprefix('gdscript').strip())+'</code></pre>'
 else:
  for p in part.strip().split('\n\n'):
   if p:reading+=('<h3>'+html.escape(p[3:])+'</h3>') if p.startswith('## ') else '<p>'+html.escape(p)+'</p>'
previous=read(H.parent/'2026-09-24-random-walk-rails/index.html');style=re.search(r'<style>(.*?)</style>',previous,re.S).group(1)+'pre{background:#242e33;color:#f7eee4;padding:1.2em;border-radius:4px;font-size:.95rem;overflow:auto}'
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The six that does not finish — Ada Research</title><style>STYLE</style><main>
<div class="eyebrow">Ada Research · Random Cubes · 24 September 2026</div><h1>The six that does not finish.</h1><p class="lead">A six can receive a reward. It can also give another throw permission to count. A new physical die encounter turns that difference into a column.</p>
<nav><a href="#comparison">Follow the chain</a><a href="#reading">New book passage</a><a href="text-diff.html">Before / after text</a><a href="#evidence">What was checked</a><a href="http://localhost:3003/compose/sources?map=Random_Cubes&amp;doc=final">Current chapter</a><a href="http://localhost:3003/necklace/thread?map=Random_Cubes&amp;role=primary">Primary encounters</a></nav>
<figure><a href="room.png"><img src="room.png" alt="The new continuing-die column beside the original die and paired-dice comparison in the museum"></a><figcaption>The addition sits beside the existing dice encounters. All earlier artifacts and floor cells remain. Actual Godot museum render.</figcaption></figure>
<h2 id="comparison">Another throw, in the same chain</h2><div class="pair"><figure><a href="six.png"><img src="six.png" alt="One six makes a pink section and keeps the continuation flag raised"></a><figcaption><strong>Six.</strong> One result builds one section and leaves the chain open.</figcaption></figure><figure><a href="fifteen.png"><img src="fifteen.png" alt="Six plus six plus three forms fifteen units; the blue final section closes the live chain"></a><figcaption><strong>Six, six, three.</strong> Fifteen units. The final non-six closes the chain. Seams and labels keep its ingredients visible.</figcaption></figure></div>
<p class="small">These photographed live chains were made with controlled face-up drops into the production physics reader. They demonstrate the rule, not the frequency of long chains during play. The adjacent sculpture is a permanently labelled worked example and never enters the live record.</p>
<blockquote>The number enters twice: once as an amount, once as a condition.</blockquote>
<h2>A different ending</h2><figure><a href="unfinished.png"><img src="unfinished.png" alt="Five sixes build a tall pink column to the amber limit; the readout marks the chain unfinished"></a><figcaption>Five sixes reach thirty. The apparatus stops at its five-throw budget and names the result <strong>UNFINISHED</strong>. It has not confused a display limit with a non-six ending the rule.</figcaption></figure>
<p>The visitor throws the same kind of die as before. There is no automatic reroll and no forced lucky face. RETURN DIE recovers it; NEW CHAIN clears the live column. A completed or capped chain stays in place until that fresh beginning.</p>
<details><summary>Arrival: no invented live history</summary><a href="empty.png"><img src="empty.png" alt="The live plinth is empty on arrival while the separate worked example is labelled"></a><p>The fixed example is available to read while the visitor's own chain is still empty.</p></details>
<h2 id="reading">New book passage</h2><div class="reading">PASSAGE</div><p><a href="text-diff.html">Exact differences in both chapters</a> · <a href="after-final.md">Complete Random_Cubes chapter</a> · <a href="before-final.md">Previous chapter</a></p>
<h2>A later return</h2><div class="reading"><p>GAME_RETURN</p></div><p class="small">One added paragraph in <a href="game-after.md">Random_Game</a>. Every previous line remains.</p>
<h2 id="evidence">What was checked</h2><table><tr><th>Native physics and controls</th><td>32 checks pass: production die faces, one accepted result per release, continuation and closure, held ownership, return, stale-result rejection and the explicit unfinished cap. Event-only edge cases are labelled separately in the probe.</td></tr><tr><th>In the museum</th><td>MUSEUM_COUNT checks pass, plus three sampled walking routes and an approach floor ray. Both the 6+6+3 and five-sixes cases are read from controlled physical landings.</td></tr><tr><th>Preservation</th><td>One new map cell. Every previous placement, structure and utility remains. Original die and paired-tray source unchanged. Both chapters retain all their former lines; primary order and current text hashes align.</td></tr></table>
<p class="note">Headset throwing, reach and comfort remain to be tested. These observations do not establish fair independent faces. The review uses an isolated museum snapshot; the live bake/save is untouched. Rebuild the hall to load the source placement.</p>
<details><summary>Decisions, source and reproducible checks</summary><p><a href="DECISIONS.md">Decisions</a> · <a href="changes.diff">Source differences</a> · <a href="source-manifest.json">Preserved versions</a> · <a href="publication-checks.json">Preservation checks</a> · <a href="native-checks.json">Native results</a> · <a href="museum-runtime.json">Museum results</a> · <a href="../2026-09-24-randomness-physical-examples/PLAN.md">Original proposal</a></p><p class="small">Passing runs contain no script errors. The existing unresolved UID warning remains. Shared core-record differences are scoped to the two edited chapters. No full-book export or commit.</p></details>
<p><a href="../2026-09-24-random-walk-rails/index.html">Previous encounter: somewhere to start</a></p></main></html>'''
page=page.replace('STYLE',style).replace('PASSAGE',reading).replace('GAME_RETURN',html.escape(read(H/'game-return.md').strip())).replace('MUSEUM_COUNT',str(len(museum['checks'])))
save(H/'index.html',page);save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
for url in re.findall(r'(?:href|src)="([^"]+)"',page):
 if not url.startswith(('http:','https:','#')):check('review link exists: '+url,(H/url).exists())
save(H/'publication-checks.json',json.dumps({'checks':checks,'passed':True},indent=2)+'\n')
print('Published;',len(checks),'preservation/publication checks;',len(museum['checks']),'museum checks; all pass.')
