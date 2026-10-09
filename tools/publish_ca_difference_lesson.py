"""Publish the paired-field lesson and its native museum evidence."""
from pathlib import Path
import ast,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-what-a-difference-keeps'
M=R/'commons/maps/CA_EdgeOfChaos'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text())
assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
g20=room['observations']['generation20']
(M/'images').mkdir(exist_ok=True);(O/'images').mkdir(exist_ok=True)
shutil.copy2(O/'museum/paired-volumes.png',M/'images/one-difference.png')
shutil.copy2(M/'images/one-difference.png',O/'images/one-difference.png')
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/name)
report=f'''# What a difference keeps

The same black point returns beside two nearly matching volumes. Move it to select a section; trigger to advance one update. Release it and walking chooses the section again. The final CA lesson asks what survives a procedure—and what the image lets us see of that survival.

## What changed

- **Tutorial:** three complete files reconstruct the paired experiment inside the existing Day Zero museum. Copy one beginning, change one address, advance both under the same rule and forcing, then distinguish count, magnitude and brightness. The carried PointBody class stays unchanged.
- **Reflection:** retain the encounter with storage, visibility and the historical question of an “edge of chaos.” Add the point's role, replace code fragments with prose and show the actual hall. The secondary disease note now describes the source's fixed infection probability when at least one neighbour is infected.
- **Interaction:** place the carried point on a short rail beside the existing console. Hand selection takes priority while held; release restores the walking reader. Trigger uses the existing STEP action. Selecting a section changes neither the arrays nor the scheduled run.
- **Room:** retain all five authored works, their positions and the level floor. Move entry and exit to the thresholds and disable the extra generic gate. The paired volumes already make a strong route into the rear gallery.
- **Plan:** update only this hall's summary, prerequisites, transfer exercise and evidence. Its review decision remains draft. No sequence reorder.

## Three predictions

Set UNIFORM, DRIVE zero, PULL .25 and ONE CELL on. Both fields contain four; B's centre contains five. Before taking a step, predict these outcomes:

| Choice | First result | What the student can explain |
| --- | --- | --- |
| Integer storage | No addresses differ | 4.75 and the neighbours' small gains all truncate to four. |
| Fractional storage | 27 addresses differ; largest difference .75 | The centre keeps three quarters; each neighbour receives .25/26. |
| Zero pull and zero drive | One address keeps a difference of one | Nothing exchanges it or adds a disturbance. |

The model's arrays remain floating-point arrays in both storage modes. INTEGER describes the explicit conversion applied before storing the result. The next two arrays are completed from the old arrays, so scan order does not become part of the intended neighbour rule.

## More places, less difference

After 20 fractional updates, **{g20['different']} addresses** exceed the 0.000001 counting threshold, but the maximum has fallen to **{g20['max_difference']:.8f}**. The difference image's gain has risen to **{g20['gain']:.2f}**. The spreading gold image makes a fading difference visible. A and B retain their fixed 0–9 colour range.

This is why the lesson keeps three questions separate: what is stored, what a measurement counts, and what a display amplifies. At generation zero, selecting Z=6 hides the changed centre without removing it. Integer conversion can actually remove the uniform intervention. Later, a value may remain in the arrays after falling below the counting threshold.

The fractional neighbour average with matched forcing and clipping cannot increase the largest difference for PULL between zero and one. The hall's title therefore stays a question, not a claim that these bright patterns demonstrate chaotic amplification. Nor is the field's total mean promised to be conserved at a finite boundary with unequal neighbour counts.

## The student's independent edit

Change `site` in `paired.gd` from `(5,5,5)` to `(0,0,0)`. Keep the uniform, unforced, fractional comparison. Predict the first update before running it.

Only **eight addresses** now differ. The corner retains .75. A receiving edge cell at (1,0,0) gains .25/11; the interior receiver at (1,1,1) gains .25/26. The changed corner has seven neighbours, but each receiver divides by its own neighbourhood size. There is no wrap to the opposite side. The test executes this actual edited script.

## Complete code, stated support

`paired.gd` owns the fields, neighbour lists, shared forcing and measurements. `difference.gd` makes the two miniature volumes, section images, gold frames, table, labels, materials and input. `point_body.gd` is byte-identical to the previous hall. All three are printed and explained in the tutorial.

The existing Day Zero museum supplies the player, camera, light and XR Tools. No prepared study children are assumed. The miniature starts with the quiet uniform comparison; the installed exhibit initially uses a scattered beginning with DRIVE one. The tutorial states this difference and tells the student which settings to compare.

In the miniature, the held trigger or Enter steps; R replays; I switches storage; C toggles the intervention; P switches pull zero/.25; N switches drive zero/one; B switches the beginning. Parameter changes reset both runs. The museum retains its nearby VR buttons, wider parameter ranges, walking receiver and difference image on the floor. The common forcing recipe is supplied, with no claim that its arithmetic samples are independent randomness.

## Evidence

**{n} exact printed-code checks and {q} museum checks pass in native Godot 4.6.** Every tutorial code block is extracted, byte-compared with the maintained file and executed. Across six parameter settings, all values in **120 paired updates** match the installed solver exactly.

The checks cover independent copies and old arrays, finite neighbourhoods, storage modes, thresholded counts, full instance placement, table support, texture gain, keyboard controls and the 100-update limit. The corner edit passes. Two deliberate defects—giving B a different forcing schedule, and writing B in place during the update—are caught by the tests.

Native supplied XRTools poses exercise pickup, slice selection, trigger and release in a rotated/translated learner study and in the real museum. A CharacterBody actually overlaps the installed walking reader: body selection, dead band, held-point priority and return to the stationary body all pass. Trigger cancels the pending +10 budget just as the original STEP button does; moving the point preserves it. Real console actions, matching frames and shared floor/panel material are checked.

Four routes provide **{samples} capsule-clearance and level-floor samples**, from entry to console, through the body reader and rear gallery, then to the exit. Both portal approaches are supported. Camera assertions are included in the museum total. The installed field model and wrapper remain byte-identical to the baseline; only the hand adapter and reader priority change the primary interaction.

## Limits of this pass

The nine after images are native museum captures. The compact learner model is mounted temporarily for its photograph. These checks use supplied poses, not a physical headset. Quest performance, full portal transfer, independent student acceptance and complete secondary interactions have not been tested.

The rear gallery remains intact. Some of its billboard labels draw through the main view, and existing blank frames remain visible. Those are recorded visual follow-up items. The comparison captures use the same raised camera and settings at updates 1 and 20; they are not two different algorithms or a claim that the growing light measures growing force.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Full tutorial](tutorial.html) · [Full reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [paired.gd](printed/paired.gd) · [difference.gd](printed/difference.gd) · [point_body.gd](printed/point_body.gd)
- [Learner checks](checks.json) · [Museum checks and routes](museum/report.json)
- [Learner log](engine.log) · [Museum log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-difference-review.zip)

This completes the eight CA hall drafts in this pass. The next useful editorial step is to read the tutorial and reflection sequences together. In the museum, **Fractal_Recursion** follows: an explicit instruction to repeat meets the locally accumulated forms we have just explored.
'''
(O/'REPORT.md').write_bytes(report.encode('utf-8'))
(O/'SUMMARY.md').write_text(f'CA_EdgeOfChaos: samePointBody heldZ->slice;triggerSTEP;release->bodyreader. Copy11^3a->b;oneaddress+1;matchedold->new26neighbourmean+sameforcing,clip0..9. Integer=explicittruncateinfloatarray;uniformdrive0pull.25 first0differences;fractional27,max.75;pull0onewhole. Gen20:1331above1e-6,max{g20["max_difference"]:.8f},gain{g20["gain"]:.2f}. State/count/image distinct;nochaosproof. Transfercorner000:8affected,.75corner,.25/11edge,.25/26interior;finite,noWrap. Threefullfiles,DayZero host,pointunchanged;compactkeyboardvsinstalledVR/body/floor declared. {n}printed+{q}museumchecks;120pairedsourceupdatesexact;2faultsdetected;4routes/{samples}samples. Solver/wrapperunchanged. Fiveauthoredworks+levelfloorretained;thresholdportals. Rearbillboards/blankframesremain. Noheadset/Quest/student/fullportaltransfer. EightCAdraftscomplete;readwholepairnext;museum->Fractals.\n',encoding='utf-8')
tree=ast.parse((R/'tools/publish_ca_history_lesson.py').read_text(encoding='utf-8'))
style=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='style' for t in node.targets))
nav='<nav><a href="index.html">Hall report</a><a href="index.html#layout">Before / after</a><a href="index.html#comparison">One update / twenty</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ca-difference-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def photo(path,caption):return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>CA_EdgeOfChaos · Two complete texts and native museum evidence. All eight CA hall drafts are ready for a sequence reading.</footer></body></html>',encoding='utf-8')
body='<p class="lead">More places can carry a difference while less remains at any one place. The image grows brighter as its instrument becomes more sensitive.</p>'+f'<span class="badge">{n} learner + {q} museum checks passed</span>'
body+=photo('museum/paired-volumes.png','The actual museum: matching gold frames select the same spatial section in two volumes. The floor and three cases show that section. Walking does not advance time.')
body+='<section id="layout"><h2>Keep the comparison; place the passages</h2><p>The floor and all five authored artifact placements are retained. Entry is at the top of the plan.</p><div class="switch"><input type="radio" name="layout" id="before"><label for="before">Before</label><input type="radio" name="layout" id="after" checked><label for="after">After</label><div class="before">'+photo('before/museum/overhead.png','Before: paired volumes and rear gallery on a level floor, with passage utilities inset from the thresholds.')+'</div><div class="after">'+photo('museum/overhead.png','After: same five works and floor; entry and exit moved to the thresholds, extra generic gate disabled, carried point added beside the console.')+'</div></div>'
body+='<div class="pair">'+photo('before/museum/raised-oblique.png','Before, raised oblique.')+photo('museum/raised-oblique.png','After, same raised camera. The primary encounter and rear gallery keep their places.')+'</div></section>'
body+='<div class="pair">'+photo('before/museum/entry.png','Before, from the entrance.')+photo('museum/entry.png','After, same entrance camera. The small intervention preserves the established spatial encounter.')+'</div>'
body+=photo('museum/point-reader.png','The carried black point beside the console: move to choose Z, trigger to STEP. While held, it takes priority over the body reader. This uses supplied XRTools poses, not a headset capture.')
body+='<section id="comparison"><h2>A wider image, a weaker difference</h2><p>Same camera, uniform fractional beginning, no drive, pull .25, selected Z=5. A and B use fixed colour ranges; the right-hand difference panel uses the printed gain.</p><div class="pair">'+photo('museum/fractional-first-step.png','Update 1: 27 addresses differ, maximum .75, gain 1.33. The selected section shows the centre and its immediate neighbours.')+photo('museum/difference-at20.png',f'Update 20: {g20["different"]} addresses exceed the threshold, maximum {g20["max_difference"]:.8f}, gain {g20["gain"]:.2f}. The difference spreads while fading.')+'</div></section>'
body+='<h2>The printed reconstruction</h2>'+photo('museum/printed-study.png','All three printed files running inside the existing museum. The two complete miniature fields, section displays, gold frames, support and same PointBody are created by that code. Temporary mount for this photograph.')
body+=photo('museum/rear-gallery.png','The retained rear gallery: secondary works still have their own rules and display limitations. The exit continues to Fractal_Recursion.')
body+=md(report.split('\n',2)[2]);page('index.html','What a difference keeps',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · What a difference keeps',t);page('final.html','Reflection · How far does one difference go?',f)
page('parallel.html','A difference and its image','<div class="parallel"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json','technical.md','encounter-notes.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
for name in ['difference_study.gd','walking_slice.gd','difference_hand.gd']:
 path='algorithms/cellularautomata/ca_showcase/'+name
 source=(O/'before'/name).read_text(encoding='utf-8') if (O/'before'/name).exists() else ''
 diff.extend(difflib.unified_diff(source.splitlines(True),(R/path).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile=path))
diff.extend(difflib.unified_diff((O/'before/lesson-plan.json').read_text(encoding='utf-8').splitlines(True),(O/'after/lesson-plan.json').read_text(encoding='utf-8').splitlines(True),fromfile='before/lesson-plan.json',tofile='after/lesson-plan.json'))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
readme=f'CA_EdgeOfChaos only. Open index.html or read tutorial.md/final.md. Day Zero Endless Museum host with Godot XR Tools required. printed/ contains all three learner files. {n} learner + {q} scoped museum checks pass. verification/ scripts run from the AdaResearch repository, not this extracted ZIP. Native captures and supplied-pose tests, not physical headset or independent student assessment.\n'
files=['index.html','tutorial.html','final.html','parallel.html','tutorial.md','final.md','REPORT.md','SUMMARY.md','changes.diff','checks.json','museum/report.json','printed/paired.gd','printed/difference.gd','printed/point_body.gd','printed-hashes.json','engine.log','museum/engine.log','images/one-difference.png','after/lesson-plan.json']
with zipfile.ZipFile(O/'ca-difference-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in files:
  if name.endswith('.html'):z.writestr(name,(O/name).read_text(encoding='utf-8').replace('href="ca-difference-review.zip"','href="README.md"').replace('>Review ZIP</a>','>Review README</a>'))
  elif name=='REPORT.md':z.writestr(name,(O/name).read_text(encoding='utf-8').replace('[Review ZIP](ca-difference-review.zip)','[Review README](README.md)'))
  else:z.write(O/name,name)
 for p in (O/'museum').glob('*.png'):z.write(p,p.relative_to(O).as_posix())
 for name in ['overhead.png','raised-oblique.png','entry.png']:z.write(O/'before/museum'/name,'before/museum/'+name)
 for name in ['test_ca_difference_lesson.py','probes/ca_difference_lesson.gd','probes/ca_difference_room.gd']:z.write(R/'tools'/name,'verification/'+Path(name).name)
 z.writestr('README.md',readme)
missing=[];links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:','mailto:')):continue
  links+=1;target,_,anchor=ref.partition('#');dest=p.parent/target if target else p
  if not dest.exists():missing.append(p.name+': '+ref)
  elif anchor and dest.suffix=='.html':assert f'id="{anchor}"' in dest.read_text(encoding='utf-8'),ref
assert not missing,missing
for name in ['difference_model.gd','self_organization_ca.gd']:
 assert (O/'before'/name).read_bytes()==(R/'algorithms/cellularautomata/ca_showcase'/name).read_bytes(),name
assert '```' not in (M/'final.md').read_text(encoding='utf-8')
blocks=re.findall(r'```gdscript\n(.*?)\n```',(M/'tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
for name,block in zip(['paired.gd','difference.gd','point_body.gd'],blocks):assert (block+'\n').encode('utf-8')==(O/'printed'/name).read_bytes()
with zipfile.ZipFile(O/'ca-difference-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','final.html','parallel.html']:
  for ref in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   target=ref.partition('#')[0]
   assert not target or target.startswith(('http:','https:')) or target in z.namelist(),(name,ref)
plan=json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf-8'))
assert next(r for r in plan['plans'] if r['map']=='CA_EdgeOfChaos')==json.loads((O/'after/plan-row.json').read_text())
before=json.loads((O/'before/map_data.json').read_text());after=json.loads((M/'map_data.json').read_text())
assert before['layers']['interactables']==after['layers']['interactables']
assert before['layers']['structure']==after['layers']['structure']
names=[v.split(':')[0] for row in after['layers']['interactables'] for v in row if v.strip()]
assert len(names)==5 and all(name in [x['key'] for x in room['observations']['inventory']] for name in names)
for path in [O/'engine.log',O/'museum/engine.log']:
 log=path.read_text(encoding='utf-8');assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
(O/'publication-checks.json').write_text(json.dumps({'links':links,'missing':missing,'zip_valid':True,'printed_blocks_unchanged':True,'installed_solver_and_wrapper_unchanged':True,'staged_plan_current':True,'authored_placements_unchanged_and_loaded':True,'structure_unchanged':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest(),'final_sha256':hashlib.sha256((M/'final.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print(json.dumps({'published':str(O/'index.html'),'links':links,'zip_valid':True,'zip_mb':round((O/'ca-difference-review.zip').stat().st_size/1024**2,1)}))
