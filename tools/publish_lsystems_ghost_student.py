"""Publish the fresh run with readable learner observations and bounded claims."""
from pathlib import Path
import hashlib, html, json, re, shutil
import markdown
R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-09-lsystems-ghost-student'
latest = json.loads((O/'latest-run.json').read_text())
assert latest['complete'] and latest['passed']
run = R/latest['directory']
manifest = json.loads((run/'manifest.json').read_text(encoding='utf-8'))
results = json.loads((run/'results.json').read_text())
exercise = json.loads((run/'transfer-exercise/checks.json').read_text())
museum = R/'ada_run/encounter_pilot/LSystems_Competition/ghost-student-20261009'
room = json.loads((museum/'report.json').read_text())
assert results['passed'] and exercise['passed'] and room['passed']
assert room['observations']['exercise'] == 'res://'+run.relative_to(R).as_posix()+'/transfer-exercise/'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s): p.write_bytes(s.encode('utf-8'))
def dump(p,v): write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')

for folder in ['assets','museum','tools']: (O/folder).mkdir(exist_ok=True)
for p in museum.glob('*.png'): shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','manifest.json','spec.json','engine.log']:
    if (museum/name).exists(): shutil.copyfile(museum/name,O/'museum'/name)
for name in ['test_lsystems_ghost_student.py','test_lsystems_ghost_variation.py','publish_lsystems_ghost_student.py']:
    shutil.copyfile(R/'tools'/name,O/'tools'/name)
shutil.copyfile(R/'tools/probes/lsystems_ghost_museum.gd',O/'museum/run.gd')

notes = [
('Grammar Lab', 'I can write the next sentence without reading new letters during that same pass. I can then keep the sentence and change its angle. The first rewrite gives five segments; an unmapped letter can still take part in rewriting. I must compare model coordinates before display fitting: the two displayed heights do not measure growth. This gives me a description I can retain independently of its body.', 'rewrite / read / display'),
('Growth', 'I can save a complete travelling state, branch, and restore the last saved state. The first reading makes five segments; a closing bracket returns the tip without drawing a return connector. The nested exercise requires direction and stride as well as position. The faulty shared-state and wrong-return-order versions are distinguishable. I carry a copied stack forward, not just a tree silhouette.', 'copied state / stack / replay'),
('Grammars and Curves', 'I can change the direction returned for F while leaving the stored heading alone. Exchanging x and y reflects the path; adding the minus sign for the exercise produces a quarter turn. The off-axis branch distinguishes those operations when a single upright line cannot. The turn-sign and stride changes from Growth are explicitly declared. The optional tube bay can wait.', 'interpretation / vector mapping'),
('Architecture', 'I can move each R after its F and predict two different room addresses without moving the four route segments. The footprint union removes internal walls; a 0.6-metre test body fails at a 0.4-metre opening and passes the wider opening. The full program runs, but the grouping and collider helpers are the heaviest construction step so far. I should first explain records, occupied cells and exposed edges, then inspect those helpers.', 'record / footprint / boundary'),
('Competition', 'I can explain 2.25 followed by 1.98 from the overlapping resource cells. The second tree reads a world the first has changed. Winter consumes before refusing a rewrite; the generation cap refuses before consuming. Reversing the first turn swaps allocation in this fixed-patch experiment. The grammar is carried unchanged from Curves, and the distinction from the larger forest is declared. I can vary the resource relation without rewriting the branch algorithm.', 'shared state / order / conditional execution'),
('Living', 'I can follow a raw design through rounding and clamping: 4.8 selects two generations, 5.0 selects three. Angle changes endpoints without changing the sentence. Held and planted records survive later edits. The new local orientation frame and roll deserve a slow reading; the main lesson remains parameter-to-rule construction. A retained design is a recipe for this builder, not a promise of identical results from another version.', 'requested value / compiled rule / retained recipe'),
('Shape Grammars', 'I can identify the two eligible pink tips before calculating new corners. The A–E list example explains why current indices are processed backwards. Growing is a shared eligibility tag, not a unique face identity. Three inset/extrude rounds give 84 faces for two initial tips; choosing one gives 48. The selection walkthrough makes this transfer from symbols to mesh faces followable without pretending the two representations are the same.', 'selection / replacement / continuation'),
('Assemblage', 'I can distinguish changing samples, changing their threshold decisions and changing the marks those decisions draw. A witness keeps its alphabet as well as its rows. Adding one row retains eleven records while shifting their addresses. The apparent path is not stored connectivity. This is a useful ending because it asks me to transfer the separation between data and interpretation beyond L-systems, then choose an unprescribed change of my own.', 'sample / decision / mark / perceived path')]

total = sum(x['checks'] for x in results['halls'])
text = f'''# L-systems — the ghost student runs the sequence

**The revised sequence holds as an executable learning progression. All eight reconstructed programs passed: {total} native checks across 31 printed files.** An unprescribed transfer exercise passed {len(exercise['checks'])} further checks, followed by {len(room['checks'])} checks and three fresh captures in the actual Competition hall.

This is a simulated ghost-student assessment by the same authoring AI, using the current texts. The executable pass reuses the established native assertion suites; it is not a blind independent assessment. It supplies fresh evidence of reconstruction and transfer, not empirical proof of human learning or physical-headset comfort.

## What was applied

The review's relevant clarifications are in the canonical texts: Grammar Lab names the route from description to interpretation; Shape Grammars introduces eligibility before construction and explains reverse index order; Competition states the deterministic, fixed-patch limits of its experiment. The eight-hall order remains. Curves' tube bay stays optional. All 31 primary learner programs remain unchanged from their tested versions.

## How the run worked

The runner took fresh copies of each current tutorial and reflection, extracted the complete marked programs, checked their relative dependencies and carried files, and recorded predictions before execution. Each hall ran in Godot 4.6 inside the prepared Ada project with XRTools installed. The suites exercise complete hosts, guided edits, negative controls and the supplied interaction poses; the complete physical rooms were not all walked afresh. Receipts below retain the scope of each suite.

Each run has a separate dated directory. Earlier hall receipts were not overwritten. No missing printed helper or undeclared scene-child reference was found in this reconstruction. All sources still matched their captured hashes when the run ended.

## One paragraph per hall

These paragraphs describe the capacities demonstrated by the simulated learner. Passing an assertion is evidence for the named behaviour, not a score for teaching quality.

'''
for entry,result,(title,note,labels) in zip(manifest['halls'],results['halls'],notes):
    base = (R/entry['directory']).relative_to(O).as_posix()
    text += f'### {title}\n\n**{labels}.** {note}\n\n{result["checks"]} native checks passed. [Tutorial]({base}/tutorial.md) · [Reflection]({base}/final.md) · [Receipt]({base}/checks.json) · [Probe]({base}/run.gd) · [Engine log]({base}/engine.log)\n\n'

exercise_path = (run/'transfer-exercise').relative_to(O).as_posix()
text += f'''## A change the exercise did not prescribe

I chose Competition and changed only `const FRACTION := 0.15` to `const FRACTION := 0.25` in a separate copy of `soil.gd`. The first two uptakes should be 3.75 and 3.0: twenty shared cells have already fallen to 0.45 before the second request; its five other cells remain at 0.6. The remaining total should be 233.25. The resource still present plus cumulative uptake should remain 240.

All those predictions passed. Reversing the first turn swapped the recipients and retained the same completed-pair field. Winter consumed 6.75 without rewriting. The cap still refused consumption. Earlier snapshots and the original comparison remained independent. A control using the unedited program failed the uptake expectation while passing sentence equality: checking the branches alone would miss the absent edit.

The surprising result is also the lesson: both branching sentences advance one generation even though more resource has been consumed. This program permits rewriting above a threshold; it does not translate every extra unit into a larger branch. The soil, history and readouts carry the difference. That gives the reflection's “unchanged shape” claim something concrete to inspect.

[Prediction and exact code hashes]({exercise_path}/manifest.json) · [21-check receipt]({exercise_path}/checks.json) · [Exact probe]({exercise_path}/run.gd) · [Original soil.gd]({exercise_path}/original/soil.gd) · [Edited soil.gd]({exercise_path}/quarter/soil.gd)

## In the actual museum

Both programs were temporarily placed at the existing Competition study's transform in an isolated museum run. The original study was hidden for comparison; no hall or artifact changes were saved. These are native rendered captures, not concept images. The first two use the same camera.

![Original printed program after two turns: uptake 15 percent](assets/original-15.png)

*Original: A 2.25, B 1.98. The two outlined sampling squares overlap.*

![Edited program after two turns: uptake 25 percent](assets/changed-25.png)

*Edited: A 3.75, B 3.0. The branches agree; the depleted overlap is darker. The numeric receipt resolves a difference that is subtle at this viewing distance.*

[Fresh museum receipt](museum/report.json) · [Close camera capture](assets/changed-close.png)

The close camera capture also exposes a presentation issue: at that position the front status label dominates the view, while the smaller per-tree numbers are distant. This does not invalidate the resource test, but the numbers deserve a more comfortable viewing arrangement before claiming the small reconstruction is as legible as the installed console. No headset legibility claim is made here.

## What still needs care

**Keep this order.** Each hall changes the job of a retained operation: instructions, state, reading, construction, conditions, authored parameters, selection, then perceived relation. The final text contributes questions and encounters that the code does not settle. It does not require every companion artifact to become a lesson.

Architecture and Shape Grammars remain the main increases in construction difficulty. Living adds an orientation frame whose complete mathematics is not this lesson's subject. The tutorials already point to the functions to read first; preserve that distinction between the operation being learned and the complete supporting implementation. Do not add more required examples to solve a density problem.

The point's appearance and pickup behaviour remain consistent, but its trigger means different things in different halls. The text declares each binding. A future human reading should check whether the learner notices the local action label before acting from the previous hall's habit. A supplied-pose test cannot answer that question.

This run supports sending the revised pair of texts for review. It leaves open unfamiliar learner comprehension, the open assignment as an independently chosen human task, sustained VR comfort and Quest performance. The native tests, the simulated learner's explanations and those future observations are different kinds of evidence.

[Run manifest]({run.relative_to(O).as_posix()}/manifest.json) · [Eight-hall results]({run.relative_to(O).as_posix()}/results.json) · [How to repeat](RUN.md)
'''
write(O/'REPORT.md',text)
write(O/'RUN.md',f'''# Repeat the ghost-student checks

Use the prepared AdaResearch project with Godot 4.6 and its existing XRTools installation. This evidence folder is not a standalone Godot project.

The full-sequence runner is `tools/test_lsystems_ghost_student.py` in the repository. It extracts the current canonical tutorials, snapshots both texts, creates a new run directory, and executes the established assertion suites without overwriting prior receipts. It requires the original `tools/test_*` and `tools/probes/*` files named by its manifest. Then run `tools/test_lsystems_ghost_variation.py` for the unprescribed edit. The copied runners in this folder's tools directory are records; restore them to the repository tools directory if needed.

To re-execute one preserved native reconstruction, retain this folder at `doc/book/iterations/2026-10-09-lsystems-ghost-student` within that prepared project. For example:

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://{run.relative_to(R).as_posix()}/LSystems_Growth/run.gd
```

For the transfer exercise, use its `run.gd` and pass its directory as a user argument:

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://{run.relative_to(R).as_posix()}/transfer-exercise/run.gd -- res://{run.relative_to(R).as_posix()}/transfer-exercise/
```

These direct invocations replace the copied receipt in their directory; keep the original archive as evidence. A nonzero exit, SCRIPT ERROR, Parse Error, missing receipt or failed assertion is a failure. The full runner creates a fresh timestamped run instead.

Fresh museum captures used `tools/run_encounter_probe.py LSystems_Competition --sequence lsystems --render --output-tag ghost-student-20261009 --probe tools/probes/lsystems_ghost_museum.gd`. The probe obtains the programs from latest-run.json. Use a new output tag to retain existing evidence. It temporarily hides the installed forest and places both reconstructions at its transform; it does not persist that scene change.

All runs are author-led native tests. The headless suites supply controller poses to the existing XRTools API; they are not physical-headset sessions. The rendered follow-up covers one museum hall, not a fresh traversal of the entire sequence.
''')

css='''*{box-sizing:border-box}body{margin:0;background:#efebe4;color:#23282a;font:19px/1.7 Georgia,serif}header,main,footer{max-width:1060px;margin:auto;padding:26px 5vw}header{border-bottom:1px solid #b6b5af;font:15px system-ui}h1{font-size:clamp(2.5rem,5vw,4rem);line-height:1.12;font-weight:500}h2{margin-top:2em;line-height:1.25}h3{margin-top:1.8em}a{color:#2e5970}img{width:100%;height:auto}pre{padding:18px;background:#222c34;color:#fafafa;overflow:auto;font:14px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.88em}p{max-width:80ch}footer{font:14px/1.6 system-ui}'''
write(O/'index.html','<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>L-systems — ghost-student run</title><style>'+css+'</style></head><body><header>ENDLESS MUSEUM · 9 OCTOBER 2026 · <a href="REPORT.md">Markdown report</a> · <a href="RUN.md">Repeat the checks</a></header><main>'+markdown.markdown(text,extensions=['fenced_code','tables'])+'</main><footer>Fresh executable evidence with an authoring-AI learner simulation. Human learning and headset comfort remain open.</footer></body></html>')

sources = {}
for entry in manifest['halls']:
    for path,digest in entry['sources'].items():
        assert sha(R/path) == digest, (path,'changed after run')
        sources[path] = digest
    for name,digest in entry['printed'].items(): assert sha(R/entry['directory']/'printed'/name)==digest
for link in re.findall(r'(?:href|src)="([^"]+)"',(O/'index.html').read_text(encoding='utf-8')):
    assert (O/link).is_file(), link
checks = {'passed':True,'primary_files':31,'source_pairs':8,'canonical_sources':sources,'native_lesson_checks':total,
          'transfer_checks':len(exercise['checks']),'fresh_museum_checks':len(room['checks']),
          'fresh_museum_halls':['LSystems_Competition'],'native_captures_inspected':True,
          'complete_eight_hall_program_run':True,'complete_eight_hall_museum_walk':False,
          'independent_learner':False,'physical_headset':False,'browser_layout_tested':False,
          'run_directory':run.relative_to(O).as_posix(),'hall_results':results['halls']}
dump(O/'validation.json',checks)
print(json.dumps({k:v for k,v in checks.items() if k not in ['canonical_sources','hall_results']}))
