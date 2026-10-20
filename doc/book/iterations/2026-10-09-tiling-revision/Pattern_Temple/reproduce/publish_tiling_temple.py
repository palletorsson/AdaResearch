"""Publish Temple evidence and add only its missing lesson row to the shared plan."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha,page as base_page
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Pattern_Temple'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Temple'
def page(title,body,wide=False):return base_page(title,body,wide).replace('tiling-disco-review.zip','tiling-temple-review.zip')
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def write(n,s):(O/n).write_text(s,encoding='utf8')
def sync_plan(tests,native):
 p=R/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf8');data=json.loads(raw)
 row={'id':'Pattern_Temple','decision':'draft','mode':'build',
 'object':'Carried PointBody, palette and two five-by-five cube receivers; copies of the familiar asymmetric source and its P1/PM/PG reader.',
 'change':'Select one receiver, edit its recipe, copy that recipe to the other, then prove that later edits remain local. Copying is an action, not an ongoing link.',
 'dependsOn':['Symmetry_Seventeen','Array_Patterns','Pattern_Foundry'],
 'reuses':'Palette indices, wrapped/reflected/glided source addresses, PointBody trigger, receiver-local selection, independent copies from Arrays.',
 'given':'Three unchanged helper files: Palette, GridSurface, PointBody. Museum player/camera/light/XR Tools. Two fixed receiver poses isolate ownership. Installed temple has eight groups with separate materials.',
 'later':'Reduced program copies a dictionary with nested rows using duplicate(true). Installed recipe contains scalar settings, so duplicate() suffices. Curved mappings, seventeen shader groups, studio packages and simulated weathering remain supplied comparisons.',
 'checks':[f"{tests['checks']} Godot assertions across exact printed files and a separately reconstructed four-column source; Pattern_Temple/tests.json.",'Eight executable faults rejected: aliased recipe, shallow copy, shared initial rows, missing repaint, wrong target, missing glide and two incorrect coordinate frames; mutations.json.',f"{len(native['checks'])} native museum checks: real installed pointer controls, material ownership, ALL/local edits, AGE/CLEAN, supported approaches, simulated XR Tools held point/trigger/release; museum/report.json. No physical headset or learner comprehension claim."],
 'transfer':'Use source [[0,1,2,0],[2,0,1,2]]. Predict PG surface[0,4] -> source[1,3]=2; paint table to0, copy, paint wall to1 while table remains0. Copy back in the opposite direction and test independence.',
 'carry':'A selected receiver, its independently owned source/rule record, explicit copying, local repainting, and agreement without a continuing link.',
 'next':'Ribbon_Patterns_01: inspect the source layers and distinguish stored zero, displayed pale body, hiding and deletion.',
 'notes':'9 October: initial complete tutorial/final pair, full four-file reconstruction and native images. Temple desk panel raised 0.2m to expose second-row labels; no control logic, map or route change. Review: Pattern_Temple/index.html in the 9 October Tiling revision.',
 'baseline':{'tutorial':None,'choice':None},
 'summary':'Walk the temple and select one surface group. ALL copies its current recipe, but the next local edit affects only that group. Reconstruct this with the carried point and two addressed cube grids, one horizontal and one upright. Each owns a source and reading rule. Paint one, copy its recipe, then paint the other and verify that they diverge. Repeat with a wider source and copy in the opposite direction. The reflective text follows the authority of an agreeing room and the difference between simulated age and history.'}
 def fmt(x):return '    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
 existing=next((x for x in data['lessons'] if x['id']=='Pattern_Temple'),None)
 if existing is None:
  previous=next(x for x in data['lessons'] if x['id']=='Symmetry_Seventeen');old=fmt(previous)
  assert raw.count(old)==1;new=raw.replace(old,old+',\n'+fmt(row),1)
 else:
  old=fmt(existing);assert raw.count(old)==1;new=raw.replace(old,fmt(row),1)
 parsed=json.loads(new)
 assert [x for x in data['lessons'] if x['id']!='Pattern_Temple']==[x for x in parsed['lessons'] if x['id']!='Pattern_Temple']
 assert p.read_text(encoding='utf8')==raw;p.write_text(new,encoding='utf8')
 write('plan-entry.json',json.dumps(row,ensure_ascii=False,indent=2)+'\n')
def main():
 tests=json.loads((O/'tests.json').read_text());faults=json.loads((O/'mutations.json').read_text())
 run=R/'ada_run/encounter_pilot/Pattern_Temple/receiver-copy';native=json.loads((run/'report.json').read_text())
 assert tests['all_passed'] and faults['all_rejected'] and native['passed']
 assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
 (O/'museum').mkdir(exist_ok=True)
 for p in run.iterdir():
  if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,O/'museum'/p.name)
 prediction=json.loads((O/'prediction.json').read_text());assert sha(M/'tutorial.md')==prediction['source_sha256']
 tracks={};diffs=[]
 for name in ['tutorial','final']:
  text=(M/(name+'.md')).read_text(encoding='utf8');tracks[name]=text;write(name+'.md',text)
  write(name+'.html',page('Pattern Temple / '+name,md(text)))
  delta=''.join(difflib.unified_diff([],text.splitlines(True),fromfile='absent/'+name+'.md',tofile='new/'+name+'.md'))
  write(name+'.diff',delta);diffs.append(f'<h2>{name}.md — new</h2><pre class="diff">{html.escape(delta)}</pre>')
 blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==4
 for n,code in blocks.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==code+'\n' and sha(O/'learner/printed'/n)==prediction['files'][n]
 carried=json.loads((O/'carried-files.json').read_text())
 for n,p in carried.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
 assert (M/'map_data.json').read_bytes()==(O/'before/map_data.json').read_bytes()
 production=R/'commons/artifacts/regularity/pattern_temple.gd'
 old=(O/'before/pattern_temple.gd').read_text(encoding='utf8');new=production.read_text(encoding='utf8')
 assert new.replace('\tp.position.y += 0.2 # Keep the second row and its labels above the support.\n','')==old
 delta=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/pattern_temple.gd',tofile='after/pattern_temple.gd'))
 write('desk.diff',delta);diffs.append('<h2>Desk clearance — one position change</h2><pre>'+html.escape(delta)+'</pre>')
 sync_plan(tests,native)
 sources=[M/n for n in ['tutorial.md','final.md','intent.md','map_data.json']]+[production,R/'commons/maps/sequences/tiling.json',*[R/p for p in carried.values()]]
 write('sources.json',json.dumps([{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
 intro='<p class="meta kicker">Endless Museum / Tiling 06</p><p><a href="../Symmetry_Seventeen/parallel.html">Previous: Symmetry Seventeen</a> · Next: Ribbon Patterns 01</p>'
 write('parallel.html',page('Pattern Temple / tutorial and reflection',intro+'<div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True))
 write('changes.html',page('Pattern Temple / changes','<h1>From a room to a testable lesson</h1><p>This hall had an intent and blurb, but no canonical tutorial or final text. Both tracks are new. The intent now records its actual place in the route. The only artifact edit lifts its desk panel above the support; all controls retain their logic.</p><div class="pair"><figure><img src="before/desk.png"><figcaption>Before: lower labels hidden in the support.</figcaption></figure><figure><img src="museum/desk.png"><figcaption>After: panel raised 20 cm.</figcaption></figure></div>'+''.join(diffs),True))
 report=f'''# The same, for now

Tiling · Pattern Temple · 9 October 2026 · sixth of nine halls

**Select a surface. Copy its recipe. Let it become different again.**

The source audit corrected the tentative plan. The temple does not bind every surface to one live shared source. It has eight independent recipe dictionaries and eight materials. ALL copies the current recipe values; later edits remain local. Meshes within a group, such as the columns, do share their group's material.

## The lesson

The student carries the black point, palette, addressed cube grid and P1/PM/PG reading into a two-receiver comparison. A table and wall each own a source and rule. One paint edit changes several displayed occurrences on the selected receiver. ALL copies the record, then another paint edit demonstrates independence. The program keeps both receiver poses and all fifty cube instances.

The new entry replaces the previous entry rather than running beside it. Three helper files remain unchanged and are printed in full. The new entry consolidates the earlier address operations with an explicit receiver index. It does not reconstruct the whole temple.

Arrays already introduced independent copies. Here that capacity becomes a visible architectural decision. The nested source requires a deep copy; the installed scalar recipe does not. This difference is explained in the text instead of being hidden behind the word “copy”.

## The reflective text

The new reflection follows the floor, wall, columns and dome; agreement across the court; a later local change; and the authority that scale and arrangement lend to a small mark. AGE leads to a distinction between a generated appearance of wear and an actual history. The text does not claim a historical reconstruction from a style label.

## The room

The native capture exposed a practical issue: the support covered the desk's lower labels. The panel now sits 0.2 metres higher, with the same support and callbacks. [Before and after](changes.html) preserves the evidence. No map, route, pattern algorithm or interaction behaviour was changed. The learner construction in these images is a temporary test placement inside the existing court, not a new permanent exhibit.

## Validation

- **{tests['checks']} Godot assertions passed:** 25 on the exact four printed files and 25 on an independent four-column source.
- **{len(faults['results'])} executable faults caught:** aliased recipes, shallow copying, shared initial rows, missing repaint, editing the wrong target, missing glide and incorrect action/receiver frames.
- **{len(native['checks'])} native museum checks passed:** installed controls, material ownership, copy then local edit, AGE/CLEAN, three supported clear approaches, and simulated XR Tools pickup, held action and release.

Two initial test expectations were corrected: MultiMesh colours need a tolerance for channel quantization, and the wider source edit reaches five displayed occurrences, including two in the unreversed block. The tutorial code did not need a behavioural correction. Earlier attempt receipts remain in the working folder; successful receipts and deliberate fault results are included in the reviewer packet.

This is executed code and a museum integration check. It does not establish human understanding, physical-headset comfort or Quest performance. The native engine log retains unrelated UID/registry/renderer warnings and resource cleanup warnings at shutdown; it contains no lesson script errors.

Read the [facing pages](parallel.html), [tutorial](tutorial.html), [reflection](final.html), [changes](changes.html), [code results](tests.json), [fault results](mutations.json), [museum receipt](museum/report.json) or [review ZIP](tiling-temple-review.zip).

The [editable lesson plan](http://localhost:3003/tutorial-plan?map=Pattern_Temple&view=summaries) now includes this hall. The [nine-hall route](../plan.html) records six completed revisions, retained as drafts for review.

**Next: Ribbon Patterns 01 — a source gains layers.**
'''
 write('REPORT.md',report)
 pictures=[('court-before','The existing court before any test edits: separate recipes on architectural receivers.'),('court-all','After ALL: matching recipe values, different surfaces and mappings.'),('court-one-different','A later palette change reaches only the selected east wall.'),('desk','The raised panel exposes the lower control labels.'),('student-table-painted','Student construction in the museum: only the table has been painted mint.'),('student-copied','ALL copies the table recipe to the upright receiver.'),('student-diverged','A later wall edit becomes navy; the table remains mint.')]
 figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in pictures)
 write('index.html',page('Pattern Temple / the same, for now',intro+md(report)+'<h2>Inside the museum</h2>'+figures))
 route_path=O.parent/'PLAN.md';route=route_path.read_text(encoding='utf8')
 old='| Pattern Temple | Carry a retained motif and distinguish selecting a receiver from changing the common source. Verify how the new temple actually binds its surfaces before assigning a student edit. | Next: newly added hall. Inspect its source/receiver bindings before writing the canonical tutorial/final pair and execution-plan row. |'
 new='| [Pattern Temple](Pattern_Temple/parallel.html) | Select one receiver, copy its source/rule recipe to another, then prove that later edits stay local. ALL copies values rather than maintaining a link. | Complete sixth revision; initial tutorial/final pair, exact printed and wider-source tests, native controls/learner evidence. Desk labels exposed. |'
 assert old in route or new in route;route=route.replace(old,new)
 route=route.replace('| Reflective text exists; canonical tutorial absent. |','| Next: inspect the installed source layers and reconstruct one focused extension. Reflective text exists; canonical tutorial absent. |',1)
 start=route.find('Five Tiling lessons are complete')
 if start<0:start=route.find('Six Tiling lessons are complete')
 assert start>=0
 route=route[:start]+'''Six Tiling lessons are complete in this pass: [Disco](Pattern_Disco/index.html), [Foundry](Pattern_Foundry/index.html), [Tutorial Pattern](Tutorial_Pattern/index.html), [Array Patterns](Array_Patterns/index.html), [Symmetry Seventeen](Symmetry_Seventeen/index.html) and [Pattern Temple](Pattern_Temple/index.html). Open the [editable project plan](http://localhost:3003/tutorial-plan?map=Pattern_Temple&view=summaries). All retain draft status; the three ribbon halls remain pending reconstruction or initial writing.
'''
 route_path.write_text(route,encoding='utf8');route_html=page('Tiling / nine-hall route',md(route))
 for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-temple-review.zip']:route_html=route_html.replace('href="'+n+'"','href="Pattern_Temple/'+n+'"')
 (O.parent/'plan.html').write_text(route_html.replace('href="../plan.html"','href="plan.html"'),encoding='utf8')
 write('README.md','''# Pattern Temple review

Open index.html or parallel.html. tutorial.md/final.md are canonical snapshots. learner/printed is extracted from the four tutorial code fences. learner/four_columns is the independent edit. Other learner folders deliberately contain faults. The museum and XR Tools are prerequisites.

Run: python tools/test_tiling_temple.py
Native: python tools/run_encounter_probe.py Pattern_Temple --sequence tiling --render --no-bridges --probe tools/probes/tiling_temple_room.gd --output-tag receiver-copy --spec doc/book/iterations/2026-10-09-tiling-revision/Pattern_Temple/spec-student.json

The native probe temporarily places the learner at temple-local (0,0,1); three approaches were collision-checked. reproduce/ preserves scripts with repository-relative assumptions. Code, pointer and synthetic XR checks do not replace headset or student observation. before/ records absent canonical texts and the original obstructed desk; desk.diff is the sole production artifact change.
''')
 dest=O/'reproduce';dest.mkdir(exist_ok=True)
 for n in ['tools/revise_tiling_temple.py','tools/test_tiling_temple.py','tools/publish_tiling_temple.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_temple_student.gd','tools/probes/tiling_temple_room.gd','tools/probes/transformation_encounters.gd','tools/run_encounter_probe.py']:shutil.copy2(R/n,dest/Path(n).name)
 with zipfile.ZipFile(O/'tiling-temple-review.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in O.rglob('*'):
   if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(O).parts:z.write(p,'Pattern_Temple/'+p.relative_to(O).as_posix())
  for n in ['PLAN.md','plan.html']:z.write(O.parent/n,n)
 print('Published',O/'index.html')
if __name__=='__main__':main()
