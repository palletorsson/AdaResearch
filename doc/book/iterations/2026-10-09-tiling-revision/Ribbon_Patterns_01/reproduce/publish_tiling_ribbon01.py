"""Publish the layered reader and its narrowly edited reflection."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha,page as base_page
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Ribbon_Patterns_01'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_01'
def page(title,body,wide=False):return base_page(title,body,wide).replace('tiling-disco-review.zip','tiling-ribbon01-review.zip')
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def write(n,s):(O/n).write_text(s,encoding='utf8')
def sync_plan(tests,native):
 p=R/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf8');data=json.loads(raw)
 row=next(x for x in data['lessons'] if x['id']=='Ribbon_Patterns_01')
 def fmt(x):return '    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
 old=fmt(row);assert raw.count(old)==1
 row.update(object='Same two-row, three-column source, palette and PointBody; five-by-five GridSurface reused as a reference and four stacked receivers.',
 change='Fill values[y][z][x] through a source lookup. Repeat a plane, then add height to the wrapped source column. Inspect a selected slice without deleting data or moving cubes.',
 dependsOn=['Pattern_Temple','Symmetry_Seventeen','Tutorial_3D'],
 reuses='Declared YZX storage versus XYZ space; independently owned rows; wrapped source sampling; the carried grid, palette and held point.',
 given='Three unchanged helper files, the museum player/camera/light/XR Tools. Rendering, layer spacing and point controls support the reading. Installed four-by-four source and four-cubed volume remain a larger comparison.',
 later='Learner:6 source values,25 reference cubes,100 volume values/25 per slice. Installed:16 source/64 volume/16 per slice. Zero selects navy in the carried palette and pale in the installed palette; neither means absence. Translation held fixed while height is introduced. No automatic import of earlier edits.',
 checks=[f"{tests['checks']} Godot assertions:31 exact printed program,29 independent three-layer/reverse-step program; Ribbon_Patterns_01/tests.json in 9 October Tiling revision.",'Eight executable faults rejected by behaviour assertions, including missing height, negative remainder, swapped axes, shared rows and view/action faults; mutations.json.',f"{len(native['checks'])} native checks: installed pointer controls, slice/undo/source markers, preserved nodes and data, three supported clear approaches, simulated XR Tools point selection/actions/release; museum/report.json. No physical headset or learner-understanding claim."],
 transfer='Set layer count3 and shift step-1. Predict75 stored/25 sliced, source[1][2]=1 at volume[1][1][0], values0,1,0 through column0,row1, and index wrap after3 presses. Verify unchanged layer poses.',
 carry='Height-dependent source reading; independently allocated layers/rows; visible, hidden, occluded and absent are different states.',
 next='Ribbon_Patterns_02: retain equal values and compare surrounds and flat/curved receiving surfaces.',
 notes='9 October: initial full four-file tutorial; three helpers unchanged from Temple. Reflection preserves its encounters and anchors; transition names Temple, code excerpt becomes prose. Exact/independent/fault/native evidence complete. No production logic, map or sequence changes.',
 summary='Carry the point and source from Temple into stacked cube grids. Store palette indices as values[y][z][x], first repeating the source and then shifting its column lookup with height. Use the point to inspect a layer and its source address; hide other layers without erasing their data. Predict unequal-index readings, then rebuild with three layers and a negative shift. The installed64-cell comparison and the learner100-cell construction have explicit counts and palette meanings. Carry the distinction between a value and its visibility into the next hall.')
 new=raw.replace(old,fmt(row),1);parsed=json.loads(new)
 assert [x for x in data['lessons'] if x['id']!='Ribbon_Patterns_01']==[x for x in parsed['lessons'] if x['id']!='Ribbon_Patterns_01']
 assert p.read_text(encoding='utf8')==raw;p.write_text(new,encoding='utf8')
 write('plan-entry.json',json.dumps(row,ensure_ascii=False,indent=2)+'\n')
 write('plan-entry.diff',''.join(difflib.unified_diff((O/'before/plan-entry.json').read_text(encoding='utf8').splitlines(True),(O/'plan-entry.json').read_text(encoding='utf8').splitlines(True),fromfile='before/plan-entry.json',tofile='after/plan-entry.json')))
def main():
 tests=json.loads((O/'tests.json').read_text());faults=json.loads((O/'mutations.json').read_text())
 run=R/'ada_run/encounter_pilot/Ribbon_Patterns_01/layered-reader';native=json.loads((run/'report.json').read_text())
 assert tests['all_passed'] and faults['all_rejected'] and native['passed']
 assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
 (O/'museum').mkdir(exist_ok=True)
 for p in run.iterdir():
  if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,O/'museum'/p.name)
 prediction=json.loads((O/'prediction.json').read_text());assert sha(M/'tutorial.md')==prediction['source_sha256']
 tracks={};diffs=[]
 for name in ['tutorial','final']:
  text=(M/(name+'.md')).read_text(encoding='utf8');tracks[name]=text;write(name+'.md',text)
  write(name+'.html',page('Ribbon Patterns 01 / '+name,md(text)))
  before=(O/'before'/(name+'.md')).read_text(encoding='utf8') if name=='final' else ''
  delta=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile=('before/' if before else 'absent/')+name+'.md',tofile='after/'+name+'.md'))
  write(name+'.diff',delta);diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(delta)}</pre>')
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==4
 for n,code in blocks.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==code+'\n' and sha(O/'learner/printed'/n)==prediction['files'][n]
 carried=json.loads((O/'carried-files.json').read_text())
 for n,p in carried.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
 assert (M/'map_data.json').read_bytes()==(O/'before/map_data.json').read_bytes()
 assert (M/'technical.md').read_bytes()==(O/'before/technical.md').read_bytes()
 old=(O/'before/final.md').read_text(encoding='utf8')
 assert re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',tracks['final'])
 assert old.split('<!-- @grid_2d_4x4 -->')[1].split('The changed rule is small.')[0]==tracks['final'].split('<!-- @grid_2d_4x4 -->')[1].split('The changed rule is small:')[0]
 assert old.split('Each result is stored')[1]==tracks['final'].split('Each result is stored')[1]
 assert '```' not in tracks['final']
 sync_plan(tests,native)
 sources=[M/n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+[R/'algorithms/arrays/layer_pattern_lesson.gd',R/'algorithms/arrays/grid_3d_4x4x4.gd',R/'commons/maps/sequences/tiling.json',*[R/p for p in carried.values()]]
 write('sources.json',json.dumps([{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
 intro='<p class="meta kicker">Endless Museum / Tiling 07</p><p><a href="../Pattern_Temple/parallel.html">Previous: Pattern Temple</a> · Next: Ribbon Patterns 02</p>'
 write('parallel.html',page('Ribbon Patterns 01 / tutorial and reflection',intro+'<div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True))
 write('changes.html',page('Ribbon Patterns 01 / changes','<h1>An address gains depth</h1><p>The hall had a reflective text and technical description but no complete tutorial. The new program carries the existing learner grid into layers. The reflection keeps its source/volume encounter, controls, questions and anchors; its opening now follows Temple and its code excerpt becomes prose.</p>'+''.join(diffs)))
 report=f'''# An address gains depth

Tiling · Ribbon Patterns 01 · 9 October 2026 · seventh of nine halls

**Keep the source and the cube grid. Let height enter the reading.**

## The progression

Temple distinguished selecting a receiver from copying its recipe. Here, the familiar receivers form layers of one derived volume. The added index has a purpose: height can change which source column supplies a colour. The student keeps the palette, source and black point; three helper files are unchanged.

The new entry prints the whole construction. It starts with translation, leaving reflection and glide available from earlier work while isolating the effect of height. LAYER selects, SHIFT changes the reading, SLICE changes the view. Hovering follows a value into its source; it does not paint in this lesson.

The counters are explicit. The installed pair has16 source entries and64 volume entries,16 per slice. The carried construction has6 source values,25 reference cubes and100 volume entries,25 per slice. Zero selects pale in the installed palette and navy in ours. Both are visible bodies. Neither display equates zero with missing data.

For the independent edit, the student builds three layers with a negative shift. There are75 stored values; the selected slice still shows25. The predicted column sequence reverses, while source, cube poses and address conventions remain stable.

## The reflection

The existing reflection already makes a strong distinction between a stored value, a visible body and a useful reduction. Most of it remains word for word. Two edits bring it into this pass: the opening follows Pattern Temple, and the inline code becomes a short description of the lookup. All artifact anchors and the ending into Ribbon Patterns02 remain.

The images below show the actual museum, including its existing console. The small learner is temporarily placed beside the installed study for the test. No production artifact, room layout or sequence order was changed. The first temporary placement crossed the unrelated coordinate guide; the final captures move it into clear space. Three standing approaches were checked there.

## Evidence

- **{tests['checks']} Godot assertions passed:**31 on files extracted from the printed tutorial;29 on the independent three-layer, reverse-step version.
- **{len(faults['results'])} executable faults caught:** ignoring height, negative remainder, swapped storage axes, shared rows, incorrect slicing, a fixed layer wrap, wrong action frame and missing view refresh.
- **{len(native['checks'])} native museum checks passed:** installed pointer actions, source/volume frames, repeat/shift, slice/undo, retained nodes and data, supported approaches, simulated XR Tools point pickup/actions/release.

The execution tests passed on their first run. They test the stated behaviours, not a student's understanding. Physical headset reach, comfort and Quest performance remain untested. The native log contains existing UID/registry/renderer warnings; no lesson script errors occurred.

Read the [facing pages](parallel.html), [tutorial](tutorial.html), [reflection](final.html), [changes](changes.html), [code results](tests.json), [fault results](mutations.json), [museum receipt](museum/report.json) or [review ZIP](tiling-ribbon01-review.zip).

The [editable lesson plan](http://localhost:3003/tutorial-plan?map=Ribbon_Patterns_01&view=summaries) and [nine-hall route](../plan.html) now record this seventh revision as a draft for review.

**Next: Ribbon Patterns 02 — what the carrier adds to a value.**
'''
 # Prose uses normal spacing even where the compact audit counters were authored.
 for a,b in [('has16','has 16'),('and64','and 64'),('entries,16','entries, 16'),('has6','has 6'),('values,25','values, 25'),('and100','and 100'),('entries,25','entries, 25'),('are75','are 75'),('shows25','shows 25'),('Patterns02','Patterns 02'),('passed:**31','passed:** 31'),('tutorial;29','tutorial; 29')]:report=report.replace(a,b)
 write('REPORT.md',report)
 pictures=[('installed-repeat','Installed pair: a sixteen-entry source supplies four repeated layers.'),('installed-shift','Height changes the colour lookup; the existing cubes stay in place.'),('installed-slice','One installed slice:16 visible cells,64 stored.'),('installed-console','The console declares both storage orders and the visible/stored counts.'),('student-repeat','Carried learner: one reference grid and four layers built from the same GridSurface.'),('student-shift','The held point reads a fixed volume address through the height-dependent lookup.'),('student-slice','A single learner slice:25 visible,100 stored. Its marker points back to the retained source.')]
 figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in pictures)
 write('index.html',page('Ribbon Patterns 01 / an address gains depth',intro+md(report)+'<h2>Inside the museum</h2>'+figures))
 route_path=O.parent/'PLAN.md';route=route_path.read_text(encoding='utf8')
 line=next(l for l in route.splitlines() if l.startswith('| Ribbon Patterns 01 |') or l.startswith('| [Ribbon Patterns 01]'))
 route=route.replace(line,'| [Ribbon Patterns 01](Ribbon_Patterns_01/parallel.html) | Stack the carried grid; fill YZX values through a height-dependent source lookup. Inspect a slice without erasing data; test three layers and a negative shift. | Complete seventh revision; full printed tutorial, independent edit, fault tests and native museum evidence. Reflection preserved with two targeted edits. |')
 line=next(l for l in route.splitlines() if l.startswith('| Ribbon Patterns 02 |'))
 route=route.replace(line,line.replace('Reflective text exists; canonical tutorial absent.','Next: inspect the contrast and surface comparisons. Reflective text exists; canonical tutorial absent.'))
 start=route.find('Six Tiling lessons are complete')
 if start<0:start=route.find('Seven Tiling lessons are complete')
 assert start>=0
 route=route[:start]+'''Seven Tiling lessons are complete in this pass: [Disco](Pattern_Disco/index.html), [Foundry](Pattern_Foundry/index.html), [Tutorial Pattern](Tutorial_Pattern/index.html), [Array Patterns](Array_Patterns/index.html), [Symmetry Seventeen](Symmetry_Seventeen/index.html), [Pattern Temple](Pattern_Temple/index.html) and [Ribbon Patterns 01](Ribbon_Patterns_01/index.html). Open the [editable project plan](http://localhost:3003/tutorial-plan?map=Ribbon_Patterns_01&view=summaries). All retain draft status; Ribbon Patterns 02 and 03 remain pending reconstruction or initial writing.
'''
 route_path.write_text(route,encoding='utf8');route_html=page('Tiling / nine-hall route',md(route))
 for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-ribbon01-review.zip']:route_html=route_html.replace('href="'+n+'"','href="Ribbon_Patterns_01/'+n+'"')
 (O.parent/'plan.html').write_text(route_html.replace('href="../plan.html"','href="plan.html"'),encoding='utf8')
 write('README.md','''# Ribbon Patterns 01 review

Open index.html or parallel.html. tutorial.md/final.md are canonical snapshots. learner/printed comes from four printed code fences. learner/three_reverse changes layer count and shift direction. Other learner folders deliberately contain faults. The existing museum and XR Tools are required.

Run: python tools/test_tiling_ribbon01.py
Native: python tools/run_encounter_probe.py Ribbon_Patterns_01 --sequence tiling --render --no-bridges --probe tools/probes/tiling_ribbon01_room.gd --output-tag layered-reader --spec doc/book/iterations/2026-10-09-tiling-revision/Ribbon_Patterns_01/spec-student.json

The native probe temporarily places the learner at installed lesson-local (2.5,0,8). Three approaches were collision-checked. reproduce/ retains repository-relative assumptions. Neither native images nor simulated XR tests establish a physical headset experience. The installed lesson uses64 cells; the carried learner uses100 or75. Counts exclude the separate source/reference display.
''')
 dest=O/'reproduce';dest.mkdir(exist_ok=True)
 for n in ['tools/revise_tiling_ribbon01.py','tools/test_tiling_ribbon01.py','tools/publish_tiling_ribbon01.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_ribbon01_student.gd','tools/probes/tiling_ribbon01_room.gd','tools/probes/transformation_encounters.gd','tools/run_encounter_probe.py']:shutil.copy2(R/n,dest/Path(n).name)
 with zipfile.ZipFile(O/'tiling-ribbon01-review.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in O.rglob('*'):
   if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(O).parts:z.write(p,'Ribbon_Patterns_01/'+p.relative_to(O).as_posix())
  for n in ['PLAN.md','plan.html']:z.write(O.parent/n,n)
 print('Published',O/'index.html')
if __name__=='__main__':main()
