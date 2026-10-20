"""Publish the tested glide lesson without rewriting other halls or plan entries."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha,page as base_page
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Symmetry_Seventeen'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Symmetry_Seventeen'
def page(title,body,wide=False):return base_page(title,body,wide).replace('tiling-disco-review.zip','tiling-symmetry-review.zip')
def md(s):return markdown.markdown(s.replace('/book-images/figures/tiling/symmetry-p1-pg-museum.png','images/symmetry-p1-pg-museum.png'),extensions=['fenced_code','tables','footnotes'])
def write(name,s):(O/name).write_text(s,encoding='utf8')
def sync_plan(tests,native):
 p=R/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf8');data=json.loads(raw)
 row=next(x for x in data['lessons'] if x['id']=='Symmetry_Seventeen')
 def fmt(x):return '    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
 old=fmt(row);assert raw.count(old)==1
 row.update(
  object='Same two-row, three-column source, twenty-five cubes and black PointBody; previous receiver reused as the parent script.',
  change='Add a PG reading to the P1/PM comparison: in reflected blocks, shift the source row by half the even source height. Cycle rules and paint back into the correctly addressed source entry.',
  dependsOn=['Array_Patterns','Tutorial_Pattern','Pattern_Foundry'],
  given='04_surface_frame.gd, Palette, GridSurface and PointBody unchanged. Existing museum player/camera/XR Tools. Installed four-by-four console supplies held/live images and undo.',
  later='The reduced source has two rows, so its half-height shift is one. An independent four-row source uses two. Odd heights are explicitly excluded by the discrete recipe. Selected renderer names do not establish exact field classification. HOLD/undo remain installed comparisons.',
  checks=[f"{tests['checks']} Godot assertions across exact printed and independent four-row programs. Evidence: Symmetry_Seventeen/tests.json in the 9 October Tiling revision.",'Seven executable faults rejected by assertions, not parse errors. Symmetry_Seventeen/mutations.json.',f"{len(native['checks'])} native museum checks: installed pointer controls/held pixels/undo/reset, three clear supported approaches, simulated XR Tools pickup/trigger/painting/release. Symmetry_Seventeen/museum/report.json. No physical headset or human-learning claim."],
  transfer='Before the new _ready assertion, replace the source with four asymmetric rows. Predict [row0,col3] -> source[2,2]=0 and [row2,col4] -> source[0,1]=1; vertical period4 and horizontal6. Turn/resize the carried receiver and recover the same address.',
  carry='A composed address rule, an explicit even-height domain, diagnostic source marks and the difference between a construction rule, a sampled field and its complete symmetry classification.',
  next='Pattern_Temple: inspect how one retained source binds to several architectural receivers before assigning the student edit.',
  notes='9 October: complete five-file tutorial, one specialized reader and four unchanged carried files; 70 code assertions, seven faults, native museum evidence. Reflection retains its encounters and image, removes the code excerpt and points to Pattern Temple. No production logic, map or route change.',
  summary='Extend the carried receiver with a half-height row shift in reflected source blocks. Use the same point to cycle translation, reflection and glide, and paint through a copy into the correct stored entry. Predict the displayed addresses, then rebuild with four source rows so the glide shifts two rather than one. Compare uniform and distinctive marks. The installed held/live panels broaden the experiment; a named rule is not proof of an exact symmetry group. Carry source, reader and receiver to Pattern Temple.')
 assert p.read_text(encoding='utf8')==raw
 p.write_text(raw.replace(old,fmt(row),1),encoding='utf8')
 write('plan-entry.json',json.dumps(row,ensure_ascii=False,indent=2)+'\n')
 write('plan-entry.diff',''.join(difflib.unified_diff((O/'before/plan-entry.json').read_text(encoding='utf8').splitlines(True),(O/'plan-entry.json').read_text(encoding='utf8').splitlines(True),fromfile='before/plan-entry.json',tofile='after/plan-entry.json')))
def main():
 tests=json.loads((O/'tests.json').read_text());faults=json.loads((O/'mutations.json').read_text())
 run=R/'ada_run/encounter_pilot/Symmetry_Seventeen/glide-reader';native=json.loads((run/'report.json').read_text())
 assert tests['all_passed'] and faults['all_rejected'] and native['passed']
 assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
 (O/'museum').mkdir(exist_ok=True);(O/'images').mkdir(exist_ok=True)
 for p in run.iterdir():
  if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,O/'museum'/p.name)
 shutil.copy2(R.parent/'ada_encyclopedia/public/book-images/figures/tiling/symmetry-p1-pg-museum.png',O/'images/symmetry-p1-pg-museum.png')
 tracks={};diffs=[]
 for name in ['tutorial','final']:
  text=(M/(name+'.md')).read_text(encoding='utf8');tracks[name]=text;write(name+'.md',text)
  write(name+'.html',page('Symmetry Seventeen / '+name,md(text)))
  before=(O/'before'/(name+'.md')).read_text(encoding='utf8')
  delta=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='before/'+name+'.md',tofile='after/'+name+'.md'))
  write(name+'.diff',delta);diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(delta)}</pre>')
 prediction=json.loads((O/'prediction.json').read_text());assert sha(M/'tutorial.md')==prediction['source_sha256']
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==5
 for n,code in blocks.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==code+'\n' and sha(O/'learner/printed'/n)==prediction['files'][n]
 carried=json.loads((O/'carried-files.json').read_text())
 for n,p in carried.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
 assert (M/'map_data.json').read_bytes()==(O/'before/map_data.json').read_bytes()
 before=(O/'before/final.md').read_text(encoding='utf8')
 assert before.split('The three buttons select')[0]==tracks['final'].split('The three buttons select')[0]
 assert before.split('An odd block reverses')[1].split('What could this classification')[0]==tracks['final'].split('An odd block reverses')[1].split('What could this classification')[0]
 assert '```' not in tracks['final'] and re.findall(r'<!--.*?-->',before)==re.findall(r'<!--.*?-->',tracks['final'])
 sync_plan(tests,native)
 sources=[M/n for n in ['tutorial.md','final.md','map_data.json']]+[R/p for p in ['commons/maps/sequences/tiling.json','commons/primitives/arrays/symmetry_compare_lesson.gd','commons/primitives/arrays/wallpaper_groups.gd',*carried.values()]]
 write('sources.json',json.dumps([{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
 intro='<p class="meta kicker">Endless Museum / Tiling 05</p><p><a href="../Array_Patterns/parallel.html">Previous: Array Patterns</a> · Next: Pattern Temple</p>'
 write('parallel.html',page('Symmetry Seventeen / tutorial and reflection',intro+'<div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True))
 write('changes.html',page('Symmetry Seventeen / changes','<h1>A reflection that slips</h1><p>The new reader extends the carried construction. The reflection keeps its encounter and image; the code excerpt becomes prose and the ending now leads into Pattern Temple.</p>'+''.join(diffs)))
 report=f'''# A reflection that slips

Tiling · Symmetry Seventeen · 9 October 2026 · fifth of nine halls

**Keep the point, the source and the receiver. Add a glide to the reading.** The student compares translation, reflection and reflection with a half-height shift, then uses the same point to paint through a copy into its original source entry.

## What changed

The old tutorial described the installed four-by-four console but supplied no full learner program. The new tutorial adds one short script that extends Array Patterns. Four earlier files are unchanged and printed in full. The parent builds the receiver once; the new script adds a RULE label, specializes the lookup and restores painting through the held point. FACE and CELL WIDTH continue to work.

The new concept stays small: compose a reflected column with a shifted row. The source has two rows, so half its height is one row. A separately reconstructed four-row version shifts two rows. An assertion declares that this discrete recipe needs an even height.

The prediction table follows surface row 0, column 3. P1 and PM read different entries with the same navy value; PG reads the pink entry at source row 1, column 2. Painting it mint changes five visible copies. This makes the source address, its value and its displayed occurrences distinguishable.

The finite display still has five columns. The asymmetric PG construction has a six-column horizontal translation period; the text names that mismatch. Tests sample the field beyond the visible display, including negative addresses. A uniform source conceals the rule; restoring a distinctive mark makes the difference visible again.

## What the reflection keeps

The held/live comparison, source painting, undo, cage, makers’ names, finite carpet and question about a garment remain. The code excerpt becomes prose. The ending now leads into Pattern Temple before the later ribbon volumes, matching the current route.

The distinction between construction and classification matters. The [IUCr tables](https://it.iucr.org/Ab/) document seventeen plane-group types and their operations. These three programs do not prove that theorem or establish that every source produces exactly its button’s named group.

## Evidence

- **{tests['checks']} Godot assertions:** {tests['results'][0]['checks']} for files extracted from the printed tutorial, and {tests['results'][1]['checks']} for the independent four-row program.
- **{len(faults['results'])} executable faults caught:** missing glide, shifting every block, missing reflection, source mutation during a rule change, missing repaint, painting without the glided lookup, and world coordinates used for the local action region.
- **{len(native['checks'])} native museum checks:** actual P1/PM/PG/HOLD/paint/UNDO/RESET callbacks, retained pixels versus live texture, three clear supported approaches, simulated XR Tools pickup/held action/release, inherited receiver transforms and the four-row transfer.

The small learner is temporarily placed in front of the existing console for these captures. The production exhibits, hall geometry and route are unchanged. No physical headset, student-learning or Quest-performance claim is made. The native log retains an unresolved UID, empty registry warnings and unsupported Jolt/renderer settings; it has no lesson script errors.

Open the [facing pages](parallel.html), [exact changes](changes.html), [code results](tests.json), [fault results](mutations.json), [museum receipt](museum/report.json), or [review ZIP](tiling-symmetry-review.zip). The [nine-hall route](../plan.html) now records five complete revisions, retained as drafts for review.

**Next: Pattern Temple — one source, several architectural receivers.**
'''
 write('REPORT.md',report)
 figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in [
  ('installed-p1-pg','Current museum comparison: held P1 on the left, live PG on the right.'),
  ('installed-console','Existing source editor and six actions; HOLD owns the saved image pixels.'),
  ('student-p1','Carried two-by-three source and twenty-five cubes, reading by translation.'),
  ('student-pm','Alternate blocks read the source backwards.'),
  ('student-pg','PG also shifts the row: the point finds source row 1, column 2.'),
  ('student-painted-glide','One source edit turns five displayed occurrences mint.'),
  ('student-wall','The glided reading survives the carried receiver’s rotation and resizing.'),
  ('student-four-rows','Independent four-row source: the half-height shift is now two rows.')])
 write('index.html',page('Symmetry Seventeen / a reflection that slips',intro+md(report)+'<h2>Inside the museum</h2>'+figures))
 route_path=O.parent/'PLAN.md';route=route_path.read_text(encoding='utf8')
 old='| Symmetry Seventeen | Compare wrapping, reflection and a glide on a small motif. Predict the return period and inspect the installed selection. A finite display is not a proof of the full classification. | Next: inspect the installed symmetry comparison and reconstruct its operation. |'
 new='| [Symmetry Seventeen](Symmetry_Seventeen/parallel.html) | Extend the carried receiver with a half-height row shift in reflected blocks. Paint back into the source, predict periods and rebuild with four rows. | Complete fifth revision; exact printed and four-row programs tested, with native museum comparison and learner evidence. |'
 assert old in route or new in route;route=route.replace(old,new)
 route=route.replace('Newly added hall. No canonical tutorial/final pair or execution-plan lesson row yet. Preserve its position; integrate after source audit.','Next: newly added hall. Inspect its source/receiver bindings before writing the canonical tutorial/final pair and execution-plan row.')
 start=route.index('Pattern Disco, Pattern Foundry, Tutorial Pattern and Array Patterns are the four') if 'Pattern Disco, Pattern Foundry, Tutorial Pattern and Array Patterns are the four' in route else -1
 if start>=0:route=route[:start]+'''Five Tiling lessons are complete in this pass: [Disco](Pattern_Disco/index.html), [Foundry](Pattern_Foundry/index.html), [Tutorial Pattern](Tutorial_Pattern/index.html), [Array Patterns](Array_Patterns/index.html) and [Symmetry Seventeen](Symmetry_Seventeen/index.html). Open the [editable project plan](http://localhost:3003/tutorial-plan?map=Symmetry_Seventeen&view=summaries). All retain draft status; Pattern Temple and the three ribbon halls remain pending reconstruction or initial writing.
'''
 route_path.write_text(route,encoding='utf8');route_html=page('Tiling / nine-hall route',md(route))
 for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-symmetry-review.zip']:route_html=route_html.replace('href="'+n+'"','href="Symmetry_Seventeen/'+n+'"')
 (O.parent/'plan.html').write_text(route_html.replace('href="../plan.html"','href="plan.html"'),encoding='utf8')
 write('README.md','''# Symmetry Seventeen review

Open index.html or parallel.html. tutorial.md/final.md are canonical snapshots. learner/printed comes from five printed code fences; learner/four_rows is the independent edit. The other learner folders deliberately contain faults. Requires the existing Endless Museum project and XR Tools, not a standalone project.

Run: python tools/test_tiling_symmetry.py
Native: python tools/run_encounter_probe.py Symmetry_Seventeen --sequence tiling --render --no-bridges --probe tools/probes/tiling_symmetry_room.gd --output-tag glide-reader --spec doc/book/iterations/2026-10-09-tiling-revision/Symmetry_Seventeen/spec-student.json

The native probe extends tools/probes/transformation_encounters.gd. The learner is temporarily placed 3.5 metres in front of the console, in its local frame. Reproduction scripts retain repository-relative assumptions. Tests do not prove the seventeen-group classification or a physical headset experience. The existing reflection image is retained; museum/ contains current captures.
''')
 dest=O/'reproduce';dest.mkdir(exist_ok=True)
 for n in ['tools/revise_tiling_symmetry.py','tools/test_tiling_symmetry.py','tools/publish_tiling_symmetry.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_symmetry_student.gd','tools/probes/tiling_symmetry_room.gd','tools/probes/transformation_encounters.gd','tools/run_encounter_probe.py']:shutil.copy2(R/n,dest/Path(n).name)
 with zipfile.ZipFile(O/'tiling-symmetry-review.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in O.rglob('*'):
   if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(O).parts:z.write(p,'Symmetry_Seventeen/'+p.relative_to(O).as_posix())
  for n in ['PLAN.md','plan.html']:z.write(O.parent/n,n)
 print('Published',O/'index.html')
if __name__=='__main__':main()
