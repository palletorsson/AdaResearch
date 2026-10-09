"""Render the bounded continuation test after running its verifier."""
from pathlib import Path
from hashlib import sha256
from html import escape
import json
import sys
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PREFIX = HERE.relative_to(ROOT).as_posix()
sys.path.insert(0, str(ROOT/'doc/book/course/functional_text'))
from reconstruction import validate


def main():
    contract = json.loads((HERE/'contract.json').read_text(encoding='utf-8'))
    checks = validate(contract)
    if checks['structure'] != 'pass' or checks['native']['status'] != 'pass':
        raise SystemExit('Current contract/evidence does not pass: '+str(checks))
    (HERE/'check-report.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
    runtime = json.loads((HERE/'report-runtime.json').read_text(encoding='utf-8'))
    count = len(runtime['checks'])
    omitted = runtime['negative_control']
    if not omitted['expected_failure_detected']:
        raise SystemExit('Deliberate omission did not fail the behaviour contract.')
    incoming = (HERE/'incoming.gd').read_text(encoding='utf-8')
    assembled = (HERE/'assembled.gd').read_text(encoding='utf-8')
    brief = (HERE/'brief.txt').read_text(encoding='utf-8')
    lesson = (HERE/'tutorial.md').read_text(encoding='utf-8')
    report = f'''# The point continues

5 October 2026. One continuation pilot: Point One → Point Coordinates, pickup and release only.

The student continues the same point. Its sphere, material and matching collider are inherited. The new lesson prints three edits: change the physics body class; add its pickup settings; reparent the existing visible surface. Full files remain available outside the lesson's reading flow.

## What the test establishes

1. `incoming.gd` records the assumed student state and pins its source evidence.
2. `contract.json` contains exact edits printed in `tutorial.md`.
3. `prepare_lesson.py` mechanically applies those edits. A missing or ambiguous anchor fails; no solution is filled in behind the lesson.
4. Godot runs `assembled.gd` with a private copy of the actual XR Tools library.
5. The generated output is available as the next lesson's incoming code, with an exact hash in `next-input.json`.

| Check | Result |
|---|---|
| Printed edits assemble the saved outgoing code | Pass |
| Native behaviour | {count}/{count} checks pass |
| Missing reparent line | Rejected by four expected checks |
| Incoming source, lesson, contract, output and verifier freshness | Pass |
| Learner explanation and transfer | Not tested |
| Physical headset and museum integration | Not tested |

The native checks cover radii 0.14 and 0.30, a translated and rotated station, preserved geometry/material/world placement, real near-grab overlap, disabled pickup, movement of both surface and boundary, retained node/resource identity, and stationary release. They bypass hardware input with a synthetic controller. Runtime code and addon files were unchanged.

## The useful failure

Point One makes the visible mesh and static collision body siblings. Merely replacing `StaticBody3D` with `XRToolsPickable` can move the boundary without its visible sphere. Omitting `body.reparent(solid)` compiles but fails the same behaviour contract: the body and collider move while the surface stays. This tests a causal step, not just whether code parses.

## What remains an assumption

The incoming ghost is an explicit reconstruction of what Point One assumes the learner has built. Point One currently provides edits to an existing museum script, so this pilot does not yet prove that its incoming source can be produced from that lesson alone. Source material supplies the names, subdivision settings and material helper; their presence is not evidence that the student has mastered them.

An exact patch assembler cannot judge ambiguous prose. A fresh reader still needs to apply the instructions, and a learner needs to predict, explain and make a variation. The files are reproducible evidence of this bounded transition, not a certificate for the entire Coordinates tutorial or the book.

## Reproduce

From the repository root:

```text
python doc/book/iterations/2026-10-05-lesson-state-chain/prepare_lesson.py
python doc/book/iterations/2026-10-05-lesson-state-chain/run_checks.py
python doc/book/iterations/2026-10-05-lesson-state-chain/build_review.py
python -m unittest discover -s doc/book/course/functional_text -p test_reconstruction.py
```

The runner uses the installed Godot executable, overridable with `GODOT_EXE`; the report renderer requires Python Markdown. Only the private fixture project runs. Lesson/source changes require a fresh test before the report can pass again. The 22 checker tests include omitted printed edits, ambiguous anchors, stale input, manually changed output and incomplete runtime evidence.

The canonical museum tutorials and `final.md` were not revised by this pilot. The durable writing guide now says: **complete lineage, minimal new change**.
'''
    (HERE/'REPORT.md').write_text(report,encoding='utf-8')
    next_input = dict(incoming=dict(path=PREFIX+'/assembled.gd',
        sha256=sha256((HERE/'assembled.gd').read_bytes()).hexdigest(),
        provenance='Mechanically assembled output of the Point One to pickup continuation pilot; verified native fixture, not certified learner mastery or museum integration.'),
        evidence=PREFIX+'/report-runtime.json',
        carry='Existing surface and collider belong to one pickable body. It follows the hand and freezes after release.',
        next_scope='Local/world position can use this same body; no coordinate readout is implemented by this pilot.')
    (HERE/'next-input.json').write_text(json.dumps(next_input,indent=2)+'\n',encoding='utf-8')
    evidence_rows = ''.join('<tr><td>'+escape(c['id'])+'</td><td>'+escape(c['description'])+'</td><td>Pass</td></tr>' for c in runtime['checks'])
    lesson_html = markdown.markdown(lesson,extensions=['fenced_code','tables'])
    report_html = markdown.markdown(report,extensions=['fenced_code','tables'])
    page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The point continues — Ada</title><style>
:root{color-scheme:light;--paper:#f5f3ee;--ink:#252525;--muted:#636260;--line:#d5d1c8;--accent:#915266}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}
header,main,footer{max-width:1120px;margin:auto;padding:2rem}header{padding-top:4rem}h1{font-size:clamp(2.2rem,5vw,3.8rem);letter-spacing:-.055em;line-height:1.07;margin:.6rem 0 1.2rem}h2{font-size:1.6rem;line-height:1.3;letter-spacing:-.025em}h3{font-size:1.05rem}p{max-width:74ch}.eyebrow{font:12px/1.5 system-ui;letter-spacing:.17em;text-transform:uppercase;color:var(--accent)}.lead{font-size:1.2rem;max-width:65ch}
a{color:var(--accent);text-underline-offset:3px}nav{display:flex;gap:1.2rem;flex-wrap:wrap;margin-top:1.5rem}nav a{font-size:.88rem}.chain{display:grid;grid-template-columns:repeat(3,1fr);gap:1rem;margin:0 0 3rem}.card{border-top:3px solid var(--accent);background:#fffdf9;padding:1.4rem}.card p{font-size:.92rem}.number{color:var(--accent);font-size:.8rem}.tree{font-size:.8rem!important;background:transparent!important;padding:0!important}
section{scroll-margin-top:1rem;margin-bottom:3.5rem}.reading{max-width:760px;margin:auto}.reading>h1{font-size:2.2rem}.reading h2{font-size:1.4rem;margin-top:2.4rem}.reading p{line-height:1.85}.reading pre{margin:1.4rem 0}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#e9e7e1;padding:1.2rem;border-radius:3px;font:14px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.92em}details{border-top:1px solid var(--line);padding:1rem 0}summary{cursor:pointer;font-weight:600}table{border-collapse:collapse;width:100%;font-size:.88rem;margin:1.5rem 0}td,th{border-bottom:1px solid var(--line);padding:.65rem;text-align:left;vertical-align:top}.result{border-left:3px solid #49745d;padding:.7rem 1.2rem;background:#edf0e9}.note{color:var(--muted);font-size:.9rem}.separator{border:0;border-top:1px solid var(--line);margin:3rem 0}.technical{max-width:850px;margin:auto}.fail{border-left:3px solid #b3694c;padding:.7rem 1.2rem;background:#f1e9e2}footer{font-size:.85rem;color:var(--muted);border-top:1px solid var(--line)}
@media(max-width:760px){header,main,footer{padding:1.3rem}.chain{grid-template-columns:1fr}.card{padding:1rem}}
@media print{nav,details{display:none}body{background:white}.chain{break-inside:avoid}.reading{max-width:none}a{color:inherit}pre{break-inside:avoid}}
</style></head><body><header><div class="eyebrow">Ada · Tutorial continuation pilot · 5 October 2026</div>
<h1>The point continues.</h1><p class="lead">We already made its surface and boundary. Now we give the same point to the hand. The lesson shows the change; the test keeps the whole lineage.</p>
<nav><a href="#reading">Read the short lesson</a><a href="#tests">See what was tested</a><a href="#brief">Compressed brief</a><a href="REPORT.md">Report</a><a href="../../course/functional_text/RECONSTRUCTION.md">Writing guide</a></nav></header><main>
<div class="chain"><div class="card"><span class="number">01 / BRING</span><h2>The existing point</h2><p>A visible sphere and its matching static boundary. Their size and position are inherited.</p><pre class="tree">Station
├ Visible sphere
└ Static body
  └ Collider</pre><a href="incoming.gd">Incoming file</a></div>
<div class="card"><span class="number">02 / CHANGE</span><h2>Three edits</h2><p>Change the body class. Set pickup and release conditions. Attach the existing surface to that body.</p><p>No second sphere. No repeated material construction.</p><a href="tutorial.md">Printed instructions</a></div>
<div class="card"><span class="number">03 / CARRY</span><h2>One moving point</h2><p>The surface and boundary travel together. Release leaves them in place.</p><pre class="tree">Station
└ Pickable body
  ├ Collider
  └ Visible sphere</pre><a href="assembled.gd">Mechanically assembled output</a></div></div>
<section id="reading" class="reading">'''+lesson_html+'''<details><summary>Full inherited code — reference only</summary><pre>'''+escape(incoming)+'''</pre></details><details><summary>Full result — inherited code plus the printed edits</summary><pre>'''+escape(assembled)+'''</pre></details></section>
<hr class="separator"><section id="tests" class="technical"><div class="eyebrow">Evidence, with its limits</div><h2>Test the continuation.</h2><p class="result"><strong>'''+str(count)+''' native checks passed.</strong> The executed code was generated from the incoming file and the printed edits. No repaired solution was substituted.</p>
<div class="fail"><strong>The deliberate omission was caught.</strong><p>Without <code>body.reparent(solid)</code>, the collider follows the hand while the visible sphere stays behind. This version compiles, but fails four of the same behaviour checks.</p></div>
<p class="note">The incoming file is an explicit assumption assembled from Point One's lesson and source. That lesson currently edits an existing museum script; this test does not yet establish that a learner can produce the complete incoming file from it. Real XR Tools code ran with a synthetic controller. Headset input, museum integration and learner understanding remain untested.</p>
<nav><a href="check-report.json">Lesson check</a><a href="report-runtime.json">Native evidence</a><a href="contract.json">Contract</a><a href="next-input.json">Carry into the next lesson</a></nav>
<details><summary>All native checks</summary><table><thead><tr><th>Case</th><th>Claim tested</th><th>Result</th></tr></thead><tbody>'''+evidence_rows+'''</tbody></table></details>
<details><summary>Method, provenance and reproduction</summary>'''+report_html+'''</details></section>
<section id="brief" class="technical"><h2>The short brief stays short.</h2><pre>'''+escape(brief)+'''</pre><p>The brief selects what to teach. Its attached contract identifies the incoming code, exact edits and test evidence. Compression keeps the teaching choice visible; the files retain the detail needed to check it.</p></section>
</main><footer>Point One → Point Coordinates · Pickup/release only. The canonical tutorials, museum runtime and reflective texts were not revised by this pilot.</footer></body></html>'''
    (HERE/'index.html').write_text(page,encoding='utf-8')
    print('Review written; current structure/native evidence pass. Next input pinned to assembled.gd.')


if __name__ == '__main__':
    main()
