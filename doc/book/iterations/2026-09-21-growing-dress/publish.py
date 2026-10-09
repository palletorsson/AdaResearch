from pathlib import Path
import difflib,hashlib,html,json,re
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base=read(H/'baseline.json');source=read(H/'source-hashes.json');report=read(H/'probe-results.json')
assert len(report['checks'])==44 and not report['failures'] and all(c['pass'] for c in report['checks'])
for path,digest in source.items():assert sha(R/path)==digest,path
room='commons/maps/Ribbon_Patterns_03/map_data.json';assert sha(R/room)==base[room]
core=read(R/'commons/data/museum_core_encounters.json');expected=read(H/'before/commons/data/museum_core_encounters.json');text_rel='commons/maps/Ribbon_Patterns_03/final.md';expected['rooms']['Ribbon_Patterns_03']['text_sha256']=sha(R/text_rel);assert core==expected
before=(H/'before'/text_rel).read_text(encoding='utf-8');now=(R/text_rel).read_text(encoding='utf-8')
markers=lambda s:re.findall(r'<!-- @([A-Za-z_0-9]+) -->',s)
assert markers(before)==markers(now)==core['rooms']['Ribbon_Patterns_03']['primary_tokens']
for quote in ['A visible opening has made a promise that the movement system does not keep.','Repetition can make a group legible without making its members look identical.']:
 assert quote in before and quote in now
changes=[]
for path in (H/'before').rglob('*'):
 if not path.is_file():continue
 rel=path.relative_to(H/'before').as_posix();current=R/rel
 if path.read_bytes()==current.read_bytes():continue
 # Record the precise manuscript and code differences from this task's baseline.
 a=path.read_text(encoding='utf-8');b=current.read_text(encoding='utf-8');diff=''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile='current/'+rel));name=rel.replace('/','__')+'.diff';(H/name).write_text(diff,encoding='utf-8');changes.append({'file':rel,'diff':name})
(H/'verification.json').write_text(json.dumps({'runtime_checks':44,'failures':[],'production_source_copies_match':len(source),'map_unchanged':True,'encounter_order_unchanged':True,'core_change':'Only Ribbon_Patterns_03 text hash','headset_tested':False,'changed_files':changes},indent=2)+'\n',encoding='utf-8')
summary='''# The dress carries the walk

21 September 2026. Author request: let the avatar dress grow like the biome. This is the first implemented connection: growth is caused by encountering sequences and retained across the current visit, rather than by time spent waiting. New operations changing the garment's behaviour remain a next development.

## The repaired connection

The walk dress already gained tiers, but the selected super-drag look hid it and kept a fixed skirt. Selected outfits now inherit the same growth. The museum's walking-triggered growth previously used only its desktop wardrobe. It now finds the wardrobe belonging to the current XR camera, including when that wardrobe becomes ready after the camera. The menu's rig receives no growth from the active visitor's walk.

The wardrobe reads the current 24-sequence spine. Arrays and Tiling therefore participate in restoration as well as walking; their small array and mirrored-mark keepsakes join the existing vocabulary. Repeated visits and duplicate completion signals cannot add another stage. No completion credit is awarded for merely entering a hall.

The growing skirt keeps the same mesh object and material. Its waist remains fixed, while its hem lengthens and widens over a bounded range; the pearl hem follows it. A new arrival eases into its target over 1.4 seconds. Waiting never advances that target. Selecting another look retains stage and fabric. Independent preview and runway models keep their earlier proportions unless explicitly given a growth stage.

## What is and is not inherited

Completed sequences still restore from the progression manager. Arrival-based additions survive within the current visit; this pass does not add a separate cross-session visitor-history save. The chosen appearance and fabric retain their existing persistence. Directly entering a later sequence does not pretend that earlier sequences were encountered.

This is authored geometric growth: a longer, fuller surface on which the same recipe repeats. It adds no collision, locomotion penalty, cloth dynamics, ecological adaptation or biological growth model. The biome's useful principle is retained form plus acquired possibilities. A later pass can let arrays form pleats, waves move folds, or cellular rules grow local structures, provided each becomes an observable garment behaviour rather than another badge. Those are proposals, not implemented features.

## Text

Ribbon_Patterns_03 now introduces the worn garment and its connection to the salon, then lets unchanged repeat counts occupy a growing physical surface. It also corrects the 3 m wall's four repeats to 0.75 m spacing, explains that WEAR SAVED selects the preview silhouette as well as the fabric, and removes the headset-status sentence from the book. The meaningful limits on shader displacement, collision and the named Skirt receiver remain. Its map and encounter order are untouched. The only core-record change is the chapter's text hash.

## Evidence

44 isolated Godot checks pass. They use the real wardrobe, costume, outfit, fabric and trophy scripts plus literal copies of the museum's routing, current-XR-camera and eye-position functions. The completion manager and body poses are test fixtures. Checks cover growth, no duplicate grants, retained mesh/material/recipe, bounded hem and radius, all four look changes, unchanged preview proportions, all 24 keepsakes, completed-sequence restoration, current versus menu rig, late-ready wardrobes, costume-off and desktop routing.

The three PNGs are actual Godot renders of the same chosen outfit and fabric at stages 1, 5 and 24 in an isolated studio. They do not show a live museum visit or a headset. This probe loaded no production autoload, visitor save or museum bake. Physical headset visibility, comfort and wearer's movement remain untested.

Run `python doc/book/iterations/2026-09-21-growing-dress/build_probe.py` to refresh the isolated source copies, then run Godot 4.6 against its probe_project using `--headless --script res://probe.gd --quit-after 1800`. For the native captures, omit headless and pass `-- --capture`. Use a hidden process on Windows. The project has its own user directory, no autoloads, and disables appearance saving. The launcher can return before the Windows application; the saved report and log are the completion record.

## Tiling review still to act on

The supplied review is preserved at `doc/book/review-feedback/2026-09-21/tiling/01-supplied-review.txt`. This continuation acts on the author's garment request and the directly related Ribbon_Patterns_03 prose. Registry config delivery, the equal-greys surround, studio WALL visibility, the seventeen-group room and the remaining editorial recommendations still need their focused checks. Their reported failures have not been presented as verified or silently edited away here.
'''
(H/'SUMMARY.md').write_text(summary,encoding='utf-8')
def render(text,prefix):
 text=re.sub(r'<!--\s*@[^>]*-->','',text);out=markdown.markdown(text,extensions=['fenced_code','footnotes','tables']);out=re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',out);return re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',out)
style=(R/'doc/book/iterations/2026-09-21-point-one-return/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+='section{margin-top:42px;padding-top:24px;border-top:1px solid var(--line)}.studies{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}.studies figure{margin:0}.studies img{width:100%}.compare{align-items:start}@media(max-width:800px){.studies{grid-template-columns:1fr}}'
figures=''.join('<figure><a href="'+name+'.png"><img src="'+name+'.png" alt="Actual Godot render of the same patterned gown at '+str(n)+' growth stages"></a><figcaption>'+label+'</figcaption></figure>' for name,n,label in [('dress-one',1,'One encountered sequence: a short hem.'),('dress-five',5,'Five: the surface begins to extend.'),('dress-twenty-four',24,'Twenty-four: the same source spans a fuller gown.')])
links=''.join('<li><a href="'+entry['diff']+'">'+html.escape(entry['file'])+'</a></li>' for entry in changes)
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The dress carries the walk — Ada Research</title><style>'''+style+'''</style></head><body><main><div class="eyebrow">Ada Research · Growing garment · 21 September 2026</div><h1>The dress carries<br>the walk.</h1><p class="intro">The same saved mark. More cloth to occupy. The garment can keep a history without becoming a row of medals.</p><p>The first connection is built: the worn dress lengthens and fills out as new sequences are encountered. Choosing a super-drag look now retains that growth. The active VR visitor and the desktop walker both receive it.</p><nav><a href="#studies">Actual rendered studies</a><a href="#text">Original and current text</a><a href="SUMMARY.md">Implementation and limits</a><a href="probe-results.json">44 runtime checks</a><a href="/compose/sources?map=Ribbon_Patterns_03&amp;doc=final">Read and comment</a></nav><section id="studies"><h2>One dress, three stages.</h2><div class="studies">'''+figures+'''</div><p class="note">Actual Godot renders in an isolated studio, using the production costume and fabric scripts. These compare selected growth counts with the same recipe; they are not photographs of a headset visit. The preview and runway models retain their existing proportions.</p><p>The skirt keeps its waist, mesh and chosen material. Its hem descends and spreads, and the pearl edging follows. A new stage arrives gradually; waiting or revisiting the same sequence cannot create another one. Changing your look carries the current stage forward.</p></section><section><h2>Like the biome: a continuing form.</h2><p>The useful connection is what a form can carry from one encounter into another. This first pass repairs visible growth. Later, a new principle can change what the garment does: a fold can move, a surface can branch, a local rule can grow another structure. Those behaviours still need to be built and felt.</p><p>For now the growth is geometric. It changes neither movement collision nor physical cloth behaviour. Completed sequences restore from the existing progression record; newly visited sequences accumulate during the current visit. Entering a late hall does not grant a fictional history of the earlier ones.</p></section><section id="text"><h2>What can you take with you?</h2><blockquote>The chosen look keeps the growth your walk has already given it. As new sequences arrive, the hem can descend and spread without adding another copy of the painted mark. The same number of repeats has more cloth to occupy. The source stays small; its reach changes with the body. Which part of this dress would you call the same?</blockquote><details><summary>Read the revised Ribbon Patterns 03 chapter</summary><div class="reading">'''+render(now,'read-')+'''</div></details><details><summary>Compare the original and current chapter</summary><div class="compare"><article><h3>Original</h3>'''+render(before,'before-')+'''</article><article><h3>Current</h3>'''+render(now,'current-')+'''</article></div></details></section><section><h2>What was checked.</h2><p>44 isolated Godot checks pass: retained fabric and geometry identity, bounded growth, all four looks, all 24 sequence keepsakes, restoration, revisits, unchanged previews, desktop routing, the current XR rig and a wardrobe arriving late. Source copies match production. No visitor save or live museum was loaded.</p><p>Headset visibility, reach and comfort still need the wearer. The supplied Tiling review's other room and configuration problems remain recorded for the next focused pass.</p><nav><a href="verification.json">Preservation checks</a><a href="/book-review/doc/book/review-feedback/2026-09-21/tiling/01-supplied-review.txt">Supplied Tiling review</a><a href="../2026-09-21-colour-return/index.html">Previous Colour pass</a></nav><details><summary>Exact changes from this pass</summary><ul>'''+links+'''</ul></details></section></main></body></html>'''
(H/'index.html').write_text(page,encoding='utf-8')
print('Published growing-dress review: 44 runtime checks, 12 matching source copies, unchanged map and encounter order.')
