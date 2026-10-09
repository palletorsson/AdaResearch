"""Publish the scoped CA feedback response; never rewrite canonical manuscripts."""
from pathlib import Path
from html import escape
import difflib, hashlib, json, re, shutil
import markdown
from bs4 import BeautifulSoup

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-08-ca-a-question-to-follow'
def read(p): return p.read_text(encoding='utf-8-sig')
def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8', newline='\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p, x): write(p, json.dumps(x, ensure_ascii=False, indent=2)+'\n')

checks = json.loads(read(O/'checks.json'))
assert checks['passed'] and len(checks['checks']) == 13
assert not re.search(r'SCRIPT ERROR|Parse Error', read(O/'engine.log'))
snapshots = json.loads(read(O/'before/source-hashes.json'))
changed = []
unchanged = []
for item in snapshots:
    path = item['path']
    before = O/'before'/path
    assert sha(before) == item['sha256'], path
    current = R/path
    if sha(current) == item['sha256']:
        unchanged.append(path)
    else:
        assert path.endswith('/tutorial.md') or path.endswith('/final.md') or path in [
            'doc/book/course/execution-plan/plan.json', 'tools/publish_ca_complete_readings.py'], path
        changed.append(path)
        target = O/'after'/path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(current, target)
        diff = ''.join(difflib.unified_diff(read(before).splitlines(True), read(current).splitlines(True), fromfile='before/'+path, tofile='after/'+path))
        write(O/'diffs'/(path.replace('/', '__')+'.diff'), diff)
required = [p for p in unchanged if p.startswith('doc/book/studies/') and p.endswith('.gd')]
assert len(required) == 19
assert 'commons/maps/sequences/cellularautomata.json' in unchanged
assert all(i['path'] in unchanged for i in snapshots if i['path'].startswith('algorithms/'))

optional_readme = '''# Optional composition: an author-made feasibility response

This helper records the existing `presence.gd` study's inputs and replays them through its unchanged `evolve` function. It is one possible response to the optional task, not the student's required solution. The required tutorial still prints its complete original code.

The record is in memory. Each committed update keeps a simulation-space position and a Boolean saying whether the held point contributes. Repeated positions remain separate: a pause lasts several updates. The beginning, starting tick, SYNC/SCAN and REVERSE settings are retained. This does not serialize a file or measure wall-clock time.

## Use in an experimental copy

The host, PointBody and full `presence.gd` already exist in the museum lesson. Pass that study node explicitly to this helper. Call `begin(study)` after preparing the beginning. Route the experiment's external STEP action to `take_step(study)` instead of directly to `study.step()`. Do not put `take_step` inside `step`: that would recurse. Begin another record after resetting, editing the initial field or changing update settings. Do not advance the study outside the recorder during a recording.

Call `replay(study)` to restore the recorded beginning and apply the stored inputs without sampling the current hand. It returns independent field snapshots, then redraws the final field and its support. Replay is an immediate calculation; a paced animation would be another choice. It does not reproduce a physical body's path or make the tabletop study into a walkable bridge.

## Reproduce the author test

From the AdaResearch repository root, run `python -X utf8 tools/test_ca_composition_replay.py`. The runner currently names the local Godot 4.6 executable explicitly; adjust that path on another machine. This review ZIP is not the museum project. Copies of the probe and runner are in `verification/` for inspection; their working repository locations remain `tools/probes/ca_composition_replay.gd` and `tools/test_ca_composition_replay.py`.

Thirteen fresh native Godot checks passed. A prescribed path generates 80 updates; every one of the 80 cells matches at every replayed update (6,400 values). Counterexamples remove pauses or ignore absence; both change the result. Other checks cover rotated host coordinates, independent snapshots, support redraw, schedule restoration and the existing 300-update cap.

This establishes executable feasibility for one author-made response. It is not an independent ghost-student result, a live improvised walk, a Quest performance test or evidence that the encounter is artistically successful.
'''
write(O/'optional-example/README.md', optional_readme)
for path in ['tools/probes/ca_composition_replay.gd','tools/test_ca_composition_replay.py']:
    dest = O/'verification'/Path(path).name
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(R/path, dest)

report = '''# A question to follow

Cellular Automata · response to the complete-sequence assessment · 8 October 2026

The useful recommendation is to let a student follow an unexpected question after learning how to isolate an operation. The eight-hall progression remains. This revision adds a small opening for composition and reduces explanation at a few moments when the encounter can speak first.

## What changed

| Hall | Revision |
| --- | --- |
| A pattern visits an address | Shorter Life explanation in the reflection. Invite the MEET encounter before giving its observed result in a footnote. The tutorial keeps the rule and full implementation. |
| The surface includes you | Let the visitor attempt a route with the clock running, respond to disappearing support, then inspect the process. Move exact thresholds and update-order detail into notes. Add the route encounter to the tutorial. |
| What a neighbour offers | Reduce the reflection's arithmetic exposition. Keep the distinction between reaction and exchange; the tutorial already opens that calculation. |
| What a difference keeps | Add an optional composition task: return to one earlier operation, preserve a working beginning, and follow a question that emerges. Trace offers one starting point: record an intervention, replay it, then attempt something else. Add a short reflective return to the bridge. |

## What the assessment helps us see

The existing Expanding Space bridge already connects body position, cellular health and physical support. That is a useful place to let a route fail or change before explaining why. No additional feedback artifact is needed for this revision. The new instruction invites a different use of an existing encounter; it does not claim that an independent student has yet discovered it.

An input record also brings an earlier lesson back with a difference. Trace selected positions when the hand moved far enough. Here a stationary hand still acts on successive generations. Keeping only distinct positions would discard duration. This is a reason to revise a familiar tool, rather than introduce an unrelated exercise.

The optional task lets a student choose another connection. Its check establishes what the construction actually does; it cannot determine which unexpected event is worth pursuing. A new attempt may change the question as well as the code.

## What remains a proposal

The suggested comparison of fixed, periodic, propagating and irregular regimes would need a separate experiment and criteria. It is not added here. The final hall compares almost identical fields under the same update procedure. Spreading and attenuating a difference is not evidence of a transition into chaos. Keeping that distinction is part of the chapter's precision.

The review's ratings are editorial judgments. They are useful prompts, not evidence from observing learners. Its linked illustrative images are not captures of our museum. The original assessment is preserved alongside this response.

## Evidence and limits

All nineteen required printed code files, the eight-hall order and the snapshotted production sources remain unchanged. Six canonical manuscripts changed. The two relevant plan records now distinguish the optional encounters from the required learning checks.

An author-made recorder/replayer passed thirteen fresh native Godot checks. It matches 6,400 values across eighty updates and demonstrates why repeated positions and absent input must be retained. This is a feasibility test of one possible composition, not the single expected answer. No new whole-sequence, physical headset or independent ghost-student test is claimed.

The refreshed complete review package contains the full revised tutorial, full reflection, parallel reading, required code, existing museum images and this response. The local before/after copies and diffs retain exactly what changed.
'''
write(O/'REPORT.md', report)

css = read(R/'doc/book/iterations/2026-10-08-ca-complete-readings/reading.css')
css += '\n.pair{align-items:start}.excerpt{max-width:76ch}.pair pre{white-space:pre-wrap;overflow-wrap:anywhere;font:16px/1.65 Georgia,serif;background:#fffaf4;color:#292328;padding:20px}details pre{max-height:65vh}.revision-image{width:100%;max-height:540px;object-fit:contain}.pair article{min-width:0}\n'
write(O/'reading.css', css)
def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+escape(title)+'</title><link rel="stylesheet" href="reading.css"></head><body><header><nav><a href="index.html">Response</a><a href="changes.html">Before / after</a><a href="REPORT.md">Report Markdown</a><a href="optional-example/README.md">Optional example</a><a href="evidence.json">Evidence</a></nav></header>'+body+'<footer>8 October 2026 · Editorial revision and optional feasibility study · Existing museum captures.</footer></body></html>'
def render(text): return markdown.markdown(text, extensions=['fenced_code','tables','footnotes'])
photo = next((R/'doc/book/iterations/2026-10-08-ca-complete-readings/assets/CA_ExpandingSpace').glob('*.png'))
(O/'assets').mkdir(exist_ok=True)
shutil.copy2(photo, O/'assets/existing-bridge.png')
body = '<main>'+render(report)+'<figure><img class="revision-image" src="assets/existing-bridge.png" alt="Previously captured Expanding Space museum study"><figcaption>Existing native capture, included for context. This revision changes text and an optional test example.</figcaption></figure><p><a href="changes.html">Read the before-and-after passages →</a></p><p><a href="reviewer-assessment.txt">Original supplied assessment</a> · <a href="checks.json">Thirteen fresh checks</a> · <a href="optional-example/input_record.gd">Recorder/replayer source</a></p></main>'
write(O/'index.html', page('CA — a question to follow', body))

# Show every changed prose line with surrounding context; full source snapshots below.
parts = ['<main class="paired"><h1>Before / after</h1><p>Every prose change is shown in context. Complete source snapshots and a unified diff accompany each manuscript. Required code blocks are unchanged.</p>']
prose_files = [p for p in changed if p.endswith(('/tutorial.md','/final.md'))]
assert len(prose_files) == 6
for path in prose_files:
    old = read(O/'before'/path)
    new = read(R/path)
    assert re.findall(r'```.*?```', old, re.S) == re.findall(r'```.*?```', new, re.S), path
    old_lines, new_lines = old.splitlines(), new.splitlines()
    groups = difflib.SequenceMatcher(None, old_lines, new_lines).get_grouped_opcodes(2)
    parts.append('<section class="chapter"><h2>'+escape('/'.join(Path(path).parts[-2:]))+'</h2>')
    for group in groups:
        a0, a1 = group[0][1], group[-1][2]
        b0, b1 = group[0][3], group[-1][4]
        parts.append('<div class="pair"><article><p class="eyebrow">Before</p><pre>'+escape('\n'.join(old_lines[a0:a1]))+'</pre></article><article><p class="eyebrow">After</p><pre>'+escape('\n'.join(new_lines[b0:b1]))+'</pre></article></div>')
    parts.append('<p><a href="before/'+path+'">Complete before</a> · <a href="after/'+path+'">Complete after</a> · <a href="diffs/'+path.replace('/','__')+'.diff">Unified diff</a></p></section>')
parts.append('</main>')
write(O/'changes.html', page('CA feedback — before and after', ''.join(parts)))
manifest = {
    'date':'2026-10-08','modified_manuscripts':prose_files,
    'changed_snapshotted_files':changed,'unchanged_snapshotted_files':unchanged,
    'required_code_files_unchanged':19,'hall_order_unchanged':True,
    'snapshotted_production_code_unchanged':True,
    'fresh_optional_checks':13,'compared_cell_values':6400,
    'test_scope':checks['observations']['scope'],
    'required_runtime_tests_rerun':False,'independent_student_test':False,
    'browser_render_checked':False,
    'after_hashes':{p:sha(R/p) for p in changed},
}
dump(O/'evidence.json', manifest)
for p in O.glob('*.html'):
    soup = BeautifulSoup(read(p), 'html.parser')
    for tag in soup.find_all(['a','img','link']):
        u = tag.get('href') or tag.get('src')
        if u and not u.startswith(('https:','http:','#')):
            assert (p.parent/u).is_file(), (p,u)
print(json.dumps({'output':str(O),'manuscripts':len(prose_files),'required_files_unchanged':len(required),'optional_checks':13}))
