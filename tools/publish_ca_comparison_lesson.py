"""Publish the two-procedure lesson and its native museum evidence."""
from pathlib import Path
import ast,difflib,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-ca-two-ways-to-make'
M=R/'commons/maps/CA_AgentsCircuits'
code=json.loads((O/'checks.json').read_text());room=json.loads((O/'museum/report.json').read_text())
assert code['passed'] and room['passed']
n=len(code['checks']);q=len(room['checks']);samples=sum(v['samples'] for v in room['observations']['routes'].values())
colour_error=room['observations']['maximum_colour_channel_error']
(M/'images').mkdir(exist_ok=True);(O/'images').mkdir(exist_ok=True)
shutil.copy2(O/'museum/floor-and-pyramid.png',M/'images/two-procedures.png')
shutil.copy2(M/'images/two-procedures.png',O/'images/two-procedures.png')
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/name)
report=f'''# Two ways to make

The same point returns as an inspector. Move it along the row, read what the neighbours will produce, and trigger one update. Its saved history spreads across the floor. Beside it, the pyramid repeats a placement recipe. Similar shapes give us a reason to compare what their procedures actually do.

## What changed

- **Tutorial:** replace the obsolete Wireworld lesson with the room's actual Rule 90 and recursive-copy comparison. Print all three required files. Teach Boolean inequality, separate old and next rows, a history's space/time axes, and the difference between a state update and a supplied placement recipe. Recursion's derivation waits for Fractals.
- **Reflection:** retain the encounter with resemblance, gaps and bodily support. Add the returning point's changed role and a current image. The same object now inspects a position and advances time; it no longer plants a seed as in the previous room.
- **Interaction:** mount the existing carried-point adapter beside the explorer. Move to inspect; trigger to STEP; release to park. Existing rule, seed, replay and clock controls remain.
- **Room:** preserve all three authored artifact placements and the level floor. Clear incidental sculpture from circulation, remove the extra generic gate and put entry and exit at the thresholds. The desk → recorded floor → fixed pyramid arrangement already works.
- **Wall text:** correct this hall's inherited five-copy caption to six placements, align the explorer caption with the seed comparison, and replace the obsolete Wireworld blurb. The book and shipped catalogue now describe the installed works.
- **Plan:** update this hall's paragraph, learning contract, transfer and evidence. Its review decision remains draft. No sequence reorder.

## What repeats, and what does it read?

Rule 90 reads the old left and right cells. The next cell is occupied when those values differ. The centre does not affect this rule's answer. A new row is written before replacing the present, and earlier snapshots stay intact.

The pyramid reads a position, spacing and remaining depth. Its installed configuration makes six recursive calls: four lower corners and two upper positions, including an extra crown. Spacing halves; the final cube size does not. Some instances overlap. Depth three gives the learner 216 leaf entries; the installed depth four gives 1,296. The supplied recipe matches the source, including its overlaps.

Changing the seed alters the cellular record while every pyramid transform stays fixed. This provides an executable distinction between similar-looking constructions. It makes no claim that this finite image proves an ideal fractal's dimension or computational universality.

## A small independent edit

Change `seed_sites` from `[16]` to `[14,16,18]`. Before running, predict the next occupied addresses. Shared neighbours cancel: the first new row contains only **13 and 19**. The cube construction retains the same 216 positions.

R replays the student's edited beginning. C returns to the built-in single/pair comparison. The exact edited file is executed by the test, rather than testing only an equivalent helper call.

There is also a useful boundary: from the single seed on a 32-cell ring, generation 15 has sixteen occupied cells. Generation 16 is empty. The two directions meet through the periodic boundary and XOR cancels the paired contributions. The apparent growing triangle belongs to a finite system.

## Full code in the existing museum

`procedures.gd` contains the row update and supplied copying function. `comparison.gd` creates the history table, fixed miniature, support, materials, labels and input. `point_body.gd` is byte-identical to the previous hall. These files run on the existing Day Zero `PointStudy`, with its supplied player, camera, lighting and XR Tools. There are no missing prepared study children.

The compact reconstruction fixes Rule 90 and holds at 24 recorded rows. Enter or the held trigger steps; R replays; C switches seeds. The museum supplies its wider VR controls and scrolls its last 24 rows across the floor. The small cubes are visual instances on a solid plinth; they do not recreate each large prefab collider. These differences are stated in the tutorial.

## Evidence

**{n} learner checks and {q} museum checks pass in native Godot 4.6.** The tutorial's three code blocks are extracted, byte-compared with the maintained files and executed.

All eight Rule 90 cases and 240 mixed-start updates agree with the installed general evaluator. Recursive positions, in order, agree with the actual pyramid procedure at depths 0 through 4. Tests cover independent snapshots, periodic wrap, the empty generation, instance transforms, table support, seed/replay controls, the 24-row limit and supplied XRTools pickup/action/release in a translated and rotated study. The three-seed transfer passes. Two deliberately wrong procedures—OR instead of XOR, and writing into the row being read—fail the expected results and are detected.

Museum checks exercise the real point and desk controls, exact chronological floor record, all 768 available floor transforms, colour, scrolling and replay. All 1,296 cube transforms remain fixed after the seed and point actions. A supplied CharacterBody walks across the drawn dark cells on the solid floor without modifying the record. Four routes contain **{samples} layer-1 capsule and level-floor samples**. Both portal approaches are supported. Camera assertions are included in the museum total.

The first learner run caught a real typed-array assignment error; the printed code now uses `assign`. The first colour assertion was too strict for native MultiMesh storage. Its final measured maximum RGB channel difference is **{colour_error:.8f}**, below one 8-bit channel step. State and transform checks remain independent of that tolerance. Both first-pass diagnostics are preserved.

The explorer algorithm, floor receiver and pyramid source remain byte-identical to this pass's baseline. Final logs contain no SCRIPT ERROR or Parse Error; existing unrelated engine warnings remain. The learner miniature is mounted temporarily only for its photograph.

## Still to review

These are native engine captures and supplied-pose interaction tests, not a physical headset session. Quest performance, full portal transfers, independent student acceptance and the secondary film's complete interaction are untested.

Existing blank frames remain visible. The image review caught a caption saying “five copies” although this configuration makes six calls. That caption and the explorer's inherited Rule 110 slogan are now replaced with the actual six-placement and changed-seed comparisons. Native checks confirm both captions appear in the hall. Other halls' captions are outside this review.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Full tutorial](tutorial.html) · [Full reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [procedures.gd](printed/procedures.gd) · [comparison.gd](printed/comparison.gd) · [point_body.gd](printed/point_body.gd)
- [Learner checks](checks.json) · [Museum checks and routes](museum/report.json)
- [Learner log](engine.log) · [Museum log](museum/engine.log)
- [First learner diagnostics](diagnostics/first-pass/learner-engine.log) · [First museum diagnostics](diagnostics/first-pass/museum-report.json)
- [Scoped changes](changes.diff) · [Review ZIP](ca-comparison-review.zip)

Next: **CA_EdgeOfChaos**. Keep the procedure fixed and follow one changed starting value through two nearly matching volumes.
'''
(O/'REPORT.md').write_bytes(report.encode('utf-8'))
(O/'SUMMARY.md').write_text(f'CA_AgentsCircuits: actual Rule90 history + recursive pyramid; no installed Wireworld. SamePointBody heldX->address,triggerSTEP,releasepark; no seedpaint. 32 bools; XOR(left,right),old->new; centreignored; periodic; chronological24cap. Gen15=16sites;gen16empty. Suppliedcopyrecipe6offsets inclcrown,halfspacing,fixedleafsize;depth3=216entries vs installed4=1296;overlapallowed. Transferseed[14,16,18]->[13,19];copiesunchanged. Three full files, DayZero host; compactkeyboardseed/replay vs installedVRcontrols+scrollfloor. {n}printed+{q}museumchecks;240updates+depth0..4sourceparity;2faultsdetected;4routes/{samples}samples. Core3scriptsunchanged. Threeauthoredplacements+floorretained;clearincidental;thresholdportals. Hallblurb+2captionscorrected;nativewallcheck. Noheadset/Quest/student/fullportaltransfer. NextCA_EdgeOfChaos=sameprocedure,changedbeginning.\n',encoding='utf-8')
tree=ast.parse((R/'tools/publish_ca_history_lesson.py').read_text(encoding='utf-8'))
style=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='style' for t in node.targets))
nav='<nav><a href="index.html">Hall report</a><a href="index.html#layout">Before / after</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="ca-comparison-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def photo(path,caption):return f'<figure><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"><figcaption>{html.escape(caption)}</figcaption></figure>'
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Cellular Automata / 8 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>One hall, two complete texts. Native museum evidence. Next: CA_EdgeOfChaos.</footer></body></html>',encoding='utf-8')
body='<p class="lead">The row reads neighbours. The pyramid repeats placements. What changes when you give one of them another beginning?</p>'+f'<span class="badge">{n} learner + {q} museum checks passed</span>'
body+=photo('museum/floor-and-pyramid.png','The actual museum: a recorded row history crosses the floor toward a fixed recursive cube construction. Walking on the image does not alter it.')
body+='<section id="layout"><h2>Keep the comparison; clear the approach</h2><p>Entrance at the top. All three authored placements and the level floor are retained.</p><div class="switch"><input type="radio" name="layout" id="before"><label for="before">Before</label><input type="radio" name="layout" id="after" checked><label for="after">After</label><div class="before">'+photo('before/museum/overhead.png','Before: existing desk, history and pyramid, with incidental sculpture and an extra gate in the approach.')+'</div><div class="after">'+photo('museum/overhead.png','After: the three authored works retain their places. Incidental sculpture is reserved out, and passages sit at the thresholds.')+'</div></div>'
body+='<div class="pair">'+photo('before/museum/raised-oblique.png','Before, raised oblique.')+photo('museum/raised-oblique.png','After, same raised camera: the comparison remains the spatial centre of the room.')+'</div></section>'
body+='<div class="pair">'+photo('before/museum/entry.png','Before, entering the hall.')+photo('museum/entry.png','After, from the same entry camera. The desk, floor history and fixed pyramid form the route.')+'</div>'
body+=photo('museum/point-inspector.png','The familiar black point now selects an address. This supplied XRTools pose reads cell 15 and predicts NEXT: 1 before the trigger advances time. This is not a headset capture.')
body+='<h2>The printed construction</h2>'+photo('museum/printed-study.png','Exact three-file learner model, temporarily mounted inside the museum. One history table, one fixed 216-entry cube construction and the same PointBody.')
body+=md(report.split('\n',2)[2]);page('index.html','Two ways to make',body)
t=md((M/'tutorial.md').read_text(encoding='utf-8'));f=md((M/'final.md').read_text(encoding='utf-8'))
page('tutorial.html','Tutorial · Two ways to make',t);page('final.html','Reflection · The same pattern, different work',f)
page('parallel.html','One resemblance, two procedures','<div class="parallel"><article>'+t+'</article><article>'+f+'</article></div>')
diff=[]
for name in ['tutorial.md','final.md','map_data.json','technical.md','encounter-notes.md','blurb.md']:
 diff.extend(difflib.unified_diff((O/'before'/name).read_text(encoding='utf-8').splitlines(True),(M/name).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
path='commons/artifacts/ca_rule_explorer/neighbour_study.gd'
diff.extend(difflib.unified_diff((O/'before/neighbour_study.gd').read_text(encoding='utf-8').splitlines(True),(R/path).read_text(encoding='utf-8').splitlines(True),fromfile='before/neighbour_study.gd',tofile=path))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
for before,path in [('cellularautomata.json','commons/data/book/cellularautomata.json'),('source-trunk.json','commons/data/trunk_branches.json'),('shipped-trunk.json','commons/data/museum/trunk_branches.json')]:
 diff.extend(difflib.unified_diff((O/'before/catalogue'/before).read_text(encoding='utf-8').splitlines(True),(R/path).read_text(encoding='utf-8').splitlines(True),fromfile='before/'+path,tofile=path))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
readme=f'CA_AgentsCircuits only. Open index.html or read tutorial.md/final.md. Day Zero Endless Museum host with Godot XR Tools required. printed/ contains all three learner files. {n} learner + {q} scoped museum checks pass. verification/ scripts run from the AdaResearch repository, not this extracted ZIP. Native captures, not a physical headset or independent student assessment.\n'
files=['index.html','tutorial.html','final.html','parallel.html','tutorial.md','final.md','REPORT.md','SUMMARY.md','changes.diff','checks.json','museum/report.json','printed/procedures.gd','printed/comparison.gd','printed/point_body.gd','printed-hashes.json','engine.log','museum/engine.log','images/two-procedures.png','diagnostics/first-pass/learner-engine.log','diagnostics/first-pass/museum-report.json','after/lesson-plan.json']
with zipfile.ZipFile(O/'ca-comparison-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in files:
  if name.endswith('.html'):z.writestr(name,(O/name).read_text(encoding='utf-8').replace('href="ca-comparison-review.zip"','href="README.md"').replace('>Review ZIP</a>','>Review README</a>'))
  elif name=='REPORT.md':z.writestr(name,(O/name).read_text(encoding='utf-8').replace('[Review ZIP](ca-comparison-review.zip)','[Review README](README.md)'))
  else:z.write(O/name,name)
 for p in (O/'museum').glob('*.png'):z.write(p,p.relative_to(O).as_posix())
 for name in ['overhead.png','raised-oblique.png','entry.png']:z.write(O/'before/museum'/name,'before/museum/'+name)
 for name in ['test_ca_comparison_lesson.py','probes/ca_comparison_lesson.gd','probes/ca_comparison_room.gd','probes/ca_pyramid_positions.gd']:z.write(R/'tools'/name,'verification/'+Path(name).name)
 z.writestr('README.md',readme)
missing=[];links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:','mailto:')):continue
  links+=1;target,_,anchor=ref.partition('#');dest=p.parent/target if target else p
  if not dest.exists():missing.append(p.name+': '+ref)
  elif anchor and dest.suffix=='.html':assert f'id="{anchor}"' in dest.read_text(encoding='utf-8'),ref
assert not missing,missing
unchanged={'ca_rule_explorer.gd':'commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd','comparison_floor.gd':'commons/artifacts/ca_rule_explorer/comparison_floor.gd','SierpinskiPyramid.gd':'algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd'}
for name,path in unchanged.items():assert (O/'before'/name).read_bytes()==(R/path).read_bytes(),name
assert '```' not in (M/'final.md').read_text(encoding='utf-8')
blocks=re.findall(r'```gdscript\n(.*?)\n```',(M/'tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
for name,block in zip(['procedures.gd','comparison.gd','point_body.gd'],blocks):assert (block+'\n').encode('utf-8')==(O/'printed'/name).read_bytes()
with zipfile.ZipFile(O/'ca-comparison-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','final.html','parallel.html']:
  for ref in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   target=ref.partition('#')[0]
   assert not target or target.startswith(('http:','https:')) or target in z.namelist(),(name,ref)
plan=json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf-8'))
assert next(r for r in plan['plans'] if r['map']=='CA_AgentsCircuits')==json.loads((O/'after/plan-row.json').read_text())
before=json.loads((O/'before/map_data.json').read_text());after=json.loads((M/'map_data.json').read_text())
assert before['layers']['interactables']==after['layers']['interactables']
names=[v.split(':')[0] for row in after['layers']['interactables'] for v in row if v.strip()]
assert len(names)==3 and all(name in [x['key'] for x in room['observations']['inventory']] for name in names)
for path in [O/'engine.log',O/'museum/engine.log']:
 log=path.read_text(encoding='utf-8');assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
(O/'publication-checks.json').write_text(json.dumps({'links':links,'missing':missing,'zip_valid':True,'printed_blocks_unchanged':True,'installed_three_core_scripts_unchanged':True,'staged_plan_current':True,'authored_placements_unchanged_and_loaded':True,'tutorial_sha256':hashlib.sha256((M/'tutorial.md').read_bytes()).hexdigest(),'final_sha256':hashlib.sha256((M/'final.md').read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print(json.dumps({'published':str(O/'index.html'),'links':links,'zip_valid':True,'zip_mb':round((O/'ca-comparison-review.zip').stat().st_size/1024**2,1)}))
