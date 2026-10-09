"""Publish a blind reader assessment without rewriting the assessed chapter."""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import markdown
import re

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-08-fractals-ghost-student'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(name):
    return json.loads((O / name).read_text(encoding='utf-8'))


def main():
    core, transfer, museum = [read(n) for n in ['core-checks.json', 'transfer-checks.json', 'museum/report.json']]
    submission, packet, canonical = [read(n) for n in ['submission-before-run.json', 'packet-sha256.json', 'canonical-before.json']]
    preserved = all(sha(O / 'attempt' / n) == h and sha(O / 'first-submission' / n) == h for n, h in submission.items())
    packet_ok = all(sha(O / 'packet' / n) == h for n, h in packet.items())
    source_changes = [n for n, h in canonical.items() if sha(R / n) != h]
    chapter_changes = [n for n in source_changes if n.startswith('commons/maps/Fractal_')]
    revised_hashes = read('revision-before-run.json')
    revision_preserved = all(sha(O / 'attempt' / n) == h and sha(O / 'revision-submission' / n) == h for n, h in revised_hashes.items())
    parity = read('reconstruction-parity.json')
    assert core['passed'] and transfer['passed'] and museum['passed'] and preserved and revision_preserved and packet_ok and parity['count'] == 16 and not chapter_changes
    counts = [len(d['checks']) for d in [core, transfer, museum]]
    obs = transfer['observations']
    repaired = O / 'student-predictions-revised-execution.json'
    revised_status = 'The student’s separate runner correction is awaiting execution.'
    if repaired.exists():
        receipt = read(repaired.name)
        assert receipt['exit_code'] == 0 and not receipt['script_errors']
        revised_status = 'The student then supplied a separate runner revision that loads those scripts after project initialization. That revision executes without script errors; the original failing runner remains frozen.'
    report = f'''# A fresh ghost student reads Fractals

**The chapter holds together for this reader, and it supports one independently chosen construction.** A fresh AI student read the complete seven-hall tutorial and reflective sequence, reconstructed all 16 printed files, completed the four-cut exercise, and combined the branching tree with a sine rule. It made predictions before execution. The lesson and composition code required no repair.

The student was not given our conversation, the teacher’s noise-tree solution, production artifact source or test harnesses. It received the current readings, their three figures and seven declared prerequisite readings. Its own review names prior programming and mathematical knowledge. This establishes reconstruction and transfer by one capable AI reader; it does not establish beginner comprehension or headset usability.

## What it carried through the chapter

| Hall | What the reader could carry onward | Where attention is still needed |
| --- | --- | --- |
| Recursion | A self-call has a smaller input and a stopping condition; returning from a call matters. | Separate the learner study’s size limits from the museum’s, and leave one prediction unanswered. |
| Recursive Trees | A function returns a joint and its descendants; turning a parent carries that family. | The supplied quaternion alignment is machinery the student can use without deriving it here. |
| Cantor | A pair stores start and length; current state, next state and history are different records. | A quarter-length numerical variant also needs a redesigned hand model if its physical bars are to agree. |
| Koch / Sierpinski | Ordered positions from Trace now come from replacement; path length differs from endpoint distance. | Keep Sierpinski, box counting and the pyramid as wider encounters, not extra required builds. |
| Menger | A small Boolean rule selects 20 of 27 cells; count, volume, bounds and bodily access differ. | The tutorial label reads a cell; the full museum’s extra highlight and flight are not supplied by this small script. |
| Golden Spiral | Append two preceding values, then distinguish the stored quantity from its visual mapping. | The comparison figure conflates two constructions; the required script deliberately does not draw a spiral. |
| Synthesis | Keep a recipe by copying its data; combine a known construction with a new, named influence. | The four-cut edit alone is too slight to demonstrate independent synthesis. The optional composition does. |

The reader’s strongest account of continuity was the **changing job of the point**: endpoint, branch editor, release request, path reader, cell reader, sum request and recipe selector. Familiar appearance carries the learner onward without pretending that all these interactions perform the same operation.

The tutorial and reflection work together when the former supplies a finite construction and the latter opens the wider museum encounter. Their relationship becomes weaker when a reader has to search several paragraphs to discover that the two describe different limits or controls.

## What the student made and predicted

Its question was: **can endpoints move while branch lengths, fork openings and even the final twigs’ directions remain the same?** It sampled a sine wave by parent depth, using 12 degrees of amplitude, 0.25 cycles per level and phase π/2. Both children receive the same angular offset.

| Claim recorded before execution | Result in native Godot 4.6 |
| --- | --- |
| Four-cut interval exercise produces 16 pieces with total length 32/27 m. | Passed; the saved recipe remains independent. |
| RESET still returns LIVE to three cuts after changing only the initial declaration. | Passed; KEPT stays at four. This is worth stating in the exercise. |
| Three successive parent levels receive +12°, 0°, −12°. | Passed. The frequency is cycles per level, not hertz; this construction is static. |
| The tree keeps 15 segments, their lengths, attached joints and 70° openings. | Passed before manual editing. |
| The final twig directions return to their originals, but their endpoints move. | Passed: maximum endpoint shift {obs['max_terminal_tip_shift_metres']:.4f} m; maximum direction-vector difference {obs['max_terminal_direction_vector_difference']:.2g}. |
| Zero amplitude recovers the original; the same settings repeat the new geometry. | Passed. |
| Existing grips still work after the new angle rule. | Real XRTools pickup and release passed with synthetic controller poses, including a rotated study frame. |

The open task asks for more than changing a supplied number: the student chose the relationship, named its units and receiver, predicted what would remain, and preserved the original for comparison. The terminal-direction argument used the student’s existing knowledge of planar rotations; the chapter alone did not teach that proof.

## Native comparison in the existing museum

![Original and student composition in Fractal Synthesis](museum/front.png)

The student’s composition is on the left, the original on the right. These are native Godot captures of unchanged submitted scripts temporarily mounted in the actual Synthesis hall. Captions and mounting positions were added by the evaluator. The existing recipe table and larger exhibits remain. This is a crowded provisional comparison, not a finished installation or a claim of clear access to every grip.

![Oblique comparison inside the museum](museum/oblique.png)

![Planar trees seen from the side](museum/side.png)

The side view collapses much of both planar structures. This is useful evidence about the limits of a view; it cannot refute the measured change in endpoint positions. The first camera positions were obstructed by the doorway. Those images are [preserved](museum/first-framing/front.png); the temporary pair and cameras were moved inward, without changing the student’s geometry.

## Changes worth making to the writing

1. **Correct the Golden Spiral comparison figure.** Its right panel names quarter-circle radii 1, 1, 2, 3, 5, 8 as the rectangle’s chain. The text describes successive golden-rectangle cuts with side lengths about 3.090, 1.910 and 1.180 m. I checked the real rectangle generator: it recursively removes a square from a golden rectangle. The figure should show that construction or clearly identify the Fibonacci-square approximation as a different comparison. The raw reader review omits the duplicated initial 1 when transcribing the label; the mismatch remains.
2. **Leave an answer for the learner to discover.** Several prompts ask for a prediction and then immediately supply it. Keep a small unworked input or relationship at major steps; place worked answers separately. The student’s optional composition is stronger evidence of transfer than copying or the prescribed four-cut change.
3. **Put the study’s scope where the learner enters.** A brief “you build / the museum also contains” note would make existing differences in geometry, limits, controls and collision easier to locate. It need not turn the room’s other artifacts into required lessons.
4. **Clarify the four-cut RESET.** Changing only the initial recipe leaves RESET at three. State this, or offer changing reset as a separate extension.
5. **Keep a small prediction record.** Input and units → receiving assignment → what remains → what changes → observation → revision. This helps a future reader test a choice without prescribing its appearance.

These are assessment findings. The canonical tutorial and reflective texts were not changed in this test.

## What passed, and what failed

- **{counts[0]} core checks** execute selected geometry, state and variation properties across all seven reconstructed studies.
- **{counts[1]} independent transfer checks** execute the student’s composition, four-cut variation and synthetic XRTools hand interaction.
- **{counts[2]} museum checks** confirm the actual hall, both constructions, supporting floor, retained grips and capture cameras. They do not prove comfort, collision-free placement or human learning.
- **16 printed files match** the frozen reading packet. The full first submission and packet retain their original hashes.

These groups test different scopes; their count is not a learning score or complete behavioral coverage. The original geometry source, rendered views and predicted relationships are the evidence.

Two failed test attempts are preserved. First, my independent core harness assigned an untyped array to a typed property and timed out. I corrected only that harness. Second, the student’s own optional command-line runner preloaded the XRTools dependency chain before the project’s autoload environment was ready. It printed “passed” and exited zero despite compile errors; our wrapper rejected it. {revised_status}

The seven lesson studies and the independently chosen tree required no repairs. Clean accepted executions contain no script errors; existing project UID, rendering and Jolt warnings remain in the raw logs. No physical VR headset, Quest performance, novice reader or independent aesthetic judgement was tested.

## Read the evidence

- [Student’s complete first reading](attempt/review-before.md)
- [Predictions written before execution](attempt/predictions-before.md)
- [Student’s account after results and images](attempt/after-run.md)
- [Frozen packet instructions](packet/README.md), [tutorial](packet/tutorial.md), [reflection](packet/final.md), [reading log](attempt/reading-log.md)
- [Original student composition](attempt/composition/wave_fork/tree_wave.gd) and [four-cut exercise](attempt/variations/Fractal_Synthesis_FourCuts/recipe_four_cuts.gd)
- [Core assertions](core-checks.json), [independent transfer assertions](transfer-checks.json), [museum assertions](museum/report.json)
- [Rejected first student-runner receipt](student-predictions-execution.json) and [full log](logs/student-predictions-engine.log)
- [First evaluator-harness error](logs/core-harness-first-error.log)
- [Frozen first-submission hashes](submission-before-run.json), [source and evidence verification](verification.json)
- [Complete chapter readings](../2026-10-08-fractals-complete-readings/index.html)
'''
    if repaired.exists():
        report += '\n- [Revised student-runner receipt](student-predictions-revised-execution.json)\n'
    if (O / 'revision-checks.json').exists():
        revision = read('revision-checks.json')
        report += f"\nThe observation-led revision has its own [execution record](revision-checks.json): {len(revision['checks'])} checks, passed = {str(revision['passed']).lower()}. It is separate from the first submission.\n"
        revision_section = '''## The student revised the comparison after seeing it

The student kept its generating rule. The images showed that matching twigs across two trees against a busy background was difficult, so it added one small reading aid. Two corresponding terminal segments now appear in a common frame, with a single translation and no rescaling. Cyan is the original; rose is the wave construction; the yellow link measures their tip separation.

![The student's retained twig comparison in the museum](museum-revision/witness.png)

The new card reads approximately 0.166 m of tip separation and 0.00 degrees of direction difference. Seven independent checks confirm the selected records, unchanged tree, equal 0.2401 m twig lengths, connecting length and retention after a live hand edit. The card is labelled “retained at construction”: it is not a live measurement after the branch is moved.

This is the most useful pedagogical result of the assessment. The student made a prediction, found that a correct numerical relationship was hard to see, and changed its means of showing it. The existing chapter supplied enough material for that response, including the distinction between a stored construction and its reader. This is evidence of one reader transferring prior knowledge, not a claim that every beginner will do so.

[Revised complete entry script](attempt/revision/tree_wave_with_witness.gd) · [Revision instructions and predictions](attempt/revision/README.md) · [View in the hall](museum-revision/overview.png) · [Museum execution](museum-revision/report.json)

'''
        report = report.replace('## Changes worth making to the writing', revision_section + '## Changes worth making to the writing')
    (O / 'REPORT.md').write_text(report, encoding='utf-8')
    css = '''*{box-sizing:border-box}body{margin:0;background:#eae7df;color:#242329;font:18px/1.65 Georgia,serif}main{max-width:1140px;margin:auto;padding:40px}h1{font-size:clamp(2.2rem,5vw,3.6rem);line-height:1.06;max-width:860px}h2{line-height:1.2;margin-top:2.3em}a{color:#733c59;text-underline-offset:.2em}p,li{max-width:82ch}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui;background:#fffdf8}td,th{border-bottom:1px solid #d2ccc5;text-align:left;padding:15px;vertical-align:top}th{background:#ded7d2}img{width:100%;height:auto;display:block;margin:18px 0}details{margin:22px 0;background:#fffdf8;padding:22px}summary{cursor:pointer;font:600 17px/1.4 system-ui}pre{overflow:auto;max-height:620px;padding:20px;background:#252831;color:#f7f2ec;font:13px/1.6 Consolas,monospace}.tag{font:13px/1.5 system-ui;letter-spacing:.1em;text-transform:uppercase}code{font-size:.88em}@media(max-width:700px){main{padding:20px}td,th{padding:8px;font-size:12px}}@media print{details{break-inside:avoid}main{max-width:none;padding:0}body{background:white;font-size:11pt}h2{break-after:avoid}img{max-height:80vh;object-fit:contain}}'''
    render = lambda s: markdown.markdown(s, extensions=['tables', 'fenced_code'])
    body = '<p class="tag">Endless Museum · Fractals · 8 October 2026</p>' + render(report)
    for name, title in [('review-before.md', 'Read the ghost student’s full first assessment'), ('predictions-before.md', 'Read its predictions before execution'), ('after-run.md', 'Read its account after results and images')]:
        source = O / 'attempt' / name
        if source.exists():
            student_html = render(source.read_text(encoding='utf-8'))
            student_html = re.sub(r'(href|src)="(?![a-zA-Z]+:|/|#)([^"]+)"', lambda m: m[1] + '="attempt/' + m[2] + '"', student_html)
            body += '<details><summary>' + escape(title) + '</summary>' + student_html + '</details>'
    body += '<details><summary>The student’s original complete composition</summary><pre><code>' + escape((O / 'attempt/composition/wave_fork/tree_wave.gd').read_text(encoding='utf-8')) + '</code></pre></details>'
    (O / 'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Ghost student — Fractals assessment</title><style>' + css + '</style></head><body><main>' + body + '</main></body></html>', encoding='utf-8')
    evidence = {'core_passed': core['passed'], 'transfer_passed': transfer['passed'], 'museum_passed': museum['passed'], 'check_counts':dict(zip(['core', 'transfer', 'museum'],counts)), 'first_submission_unchanged': preserved, 'packet_unchanged': packet_ok, 'printed_files_match': parity['passed'], 'fractal_chapter_unchanged': not chapter_changes, 'other_source_hash_changes':source_changes, 'images': {n:sha(O / 'museum' / (n+'.png')) for n in ['front','oblique','side']}, 'tools': {n:sha(R / n) for n in ['tools/test_fractals_ghost_student.py','tools/probes/fractals_ghost_core.gd','tools/probes/fractals_ghost_transfer.gd','tools/capture_fractals_ghost_museum.py','tools/probes/fractals_ghost_museum.gd']}, 'first_student_runner_accepted': False, 'revised_student_runner_accepted': repaired.exists(), 'limits': 'Fresh capable AI reader; no human beginner, headset, Quest or full interaction certification.'}
    evidence['revision_submission_unchanged'] = revision_preserved
    if (O/'revision-checks.json').exists():
        revision_checks, revision_museum = read('revision-checks.json'), read('museum-revision/report.json')
        assert revision_checks['passed'] and revision_museum['passed']
        evidence['revision_check_counts'] = {'code': len(revision_checks['checks']), 'museum': len(revision_museum['checks'])}
        evidence['revision_images'] = {n:sha(O/'museum-revision'/(n+'.png')) for n in ['witness','overview']}
    (O / 'verification.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')

    class Links(HTMLParser):
        def __init__(self):
            super().__init__()
            self.links=[]
        def handle_starttag(self, tag, attrs):
            self.links.extend(value for key,value in attrs if key in ['href','src'])
    parser=Links(); parser.feed((O/'index.html').read_text(encoding='utf-8'))
    missing=[]
    for link in parser.links:
        uri=urlsplit(link)
        if not uri.scheme and uri.path and not (O/unquote(uri.path)).exists():
            missing.append(link)
    print(json.dumps({'counts':evidence['check_counts'],'preserved':preserved,'canonical_changes':source_changes,'links':len(parser.links),'missing':missing}))
    assert not missing, missing


if __name__ == '__main__':
    main()
