"""Publish the two-lesson test evidence without changing the lesson sources."""
from pathlib import Path
from html import escape
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def main():
    report = json.loads((HERE / 'report-runtime.json').read_text(encoding='utf-8'))
    assert report['passed'] and report['continuation_composes_exactly']
    assert report['source_and_test_inputs_unchanged']
    for path, expected in report['inputs'].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected, path
    protected = json.loads((HERE / 'before/unchanged.json').read_text(encoding='utf-8'))
    for path, expected in protected.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected, path
    # The read-only book server serves .txt, not Python files. This copy is
    # byte-identical to the hashed runner, for reading its implementation.
    (HERE / 'run_checks.py.txt').write_bytes((HERE / 'run_checks.py').read_bytes())

    checks = report['checks']
    assert all(row['passed'] for row in checks)
    negatives = report['negative_controls']
    assert all(row['expected_failure_detected'] for row in negatives)
    lessons = [
        ('001-point-one', 'Point_One', '01', 'Make the point',
         'A position, a visible surface and a physical boundary. The script creates all three from scratch.',
         'Change the centre and radius. Disable collision; hide the surface. Native physics checks distinguish what can be seen from what can be hit.'),
        ('002-point-coordinates', 'Point_Coordinates', '02', 'Carry the same point',
         'Keep its construction. Give the body pickup behaviour, then create a label that reads its local and world position.',
         'The real XR Tools library selects, holds, moves and releases the point. A translated and rotated parent separates the coordinate readings.')
    ]
    cards = []
    for state, hall, number, title, description, tested in lessons:
        entry = report['states'][state]
        code = (HERE / 'states' / state / 'point.gd').read_text(encoding='utf-8')
        assert code.count('func _ready()') == 1
        cards.append(f'''<article>
          <p class="eyebrow">{number} / {entry['check_count']} assertions passed</p>
          <h2>{title}</h2><p class="lead">{description}</p><p>{tested}</p>
          <p><a class="button" href="../2026-10-05-primitives-facing-pages/{hall}.html?revision=built-and-carried">Read the tutorial beside final.md <span aria-hidden="true">↗</span></a></p>
          <p class="files"><a href="states/{state}/point.gd">Download point.gd</a> · <a href="states/{state}/report-runtime.json">Native results</a></p>
          <details><summary>Exact tested program · {len(code.splitlines())} lines</summary><pre><code>{escape(code)}</code></pre></details>
        </article>''')
    negative_rows = ''.join(
        '<li><strong>' + escape(row['name'].replace('_', ' ')) +
        '</strong> — rejected by the ordinary assertions.</li>' for row in negatives)
    variants = list(sorted((HERE / 'states').glob('*/variants/*.gd')))
    variant_links = ''.join(f'<li><a href="{p.relative_to(HERE).as_posix()}">{escape(p.stem.replace("_", " ").replace("-", " "))}</a></li>' for p in variants)
    html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>A point, then a point you can hold — Endless Museum</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f3f0e9;color:#262923;font:16px/1.65 system-ui,sans-serif}main{max-width:1160px;margin:auto;padding:50px 35px 80px}a{color:inherit;text-underline-offset:4px}a:focus-visible,summary:focus-visible{outline:3px solid #946172;outline-offset:5px}.eyebrow{font:11px/1.5 system-ui;letter-spacing:.14em;text-transform:uppercase;color:#536354}h1,h2,h3{font-family:Georgia,serif;font-weight:400;line-height:1.12}h1{font-size:clamp(38px,5.5vw,66px);max-width:780px;letter-spacing:-.025em;margin:20px 0}h2{font-size:35px;margin-top:18px}h3{font-size:27px}.intro{max-width:760px;font:21px/1.65 Georgia,serif}.proof{padding:15px 20px;background:#dde6d9;border:1px solid #c4d0bf;margin:28px 0}.lessons{display:grid;grid-template-columns:1fr 1fr;gap:22px}article{padding:28px;background:#fffdf8;border:1px solid #d4d0c7;min-width:0}.lead{font:21px/1.5 Georgia,serif}.button{display:inline-block;border-bottom:1px solid;padding:6px 0;font-weight:600;font-size:14px}.files{font-size:13px;color:#586154}details{border-top:1px solid #dedbd3;padding-top:14px;margin-top:22px}summary{cursor:pointer;font-size:13px}pre{font:12px/1.6 Consolas,monospace;overflow:auto;padding:15px;background:#efeee9}section{margin-top:32px;padding-top:12px;border-top:1px solid #cdc8be;max-width:830px}.limits{font-size:14px;color:#596052}.links{display:flex;flex-wrap:wrap;gap:18px;font-size:14px}footer{margin-top:40px;font-size:12px;color:#677061}@media(max-width:750px){main{padding:30px 20px}.lessons{grid-template-columns:1fr}article{padding:22px}}
</style><main>
<header><p class="eyebrow">Endless Museum / two executable lessons / 5 October 2026</p>
<h1>A point, then a point<br>you can hold.</h1>
<p class="intro">Build the small program from scratch. Continue with that same construction in the next hall. The code printed in each tutorial is the code Godot tested.</p></header>
'''
    html += f'<p class="proof"><strong>{len(checks)} native assertions passed.</strong> {len(negatives)} deliberate faults were rejected. Coordinates reconstructs exactly from Point One plus its declared edits.</p>'
    html += '<div class="lessons">' + ''.join(cards) + '</div>'
    html += '''<section><h3>What continues</h3><p>The centre, radius, mesh and collider keep their construction. Coordinates changes the body class and adds the pickup settings, a label and its per-frame readings. There is one complete program and one <code>_ready()</code> listing per lesson.</p>
<p>Day Zero supplies the working room, camera, light and configured XR hands/library. It does not secretly supply either lesson’s point or readout.</p></section>'''
    html += '<section><h3>Tests that can fail</h3><ul>' + negative_rows + '</ul>'
    html += '<p>The assertions inspect created objects, query native physics and exercise the actual pickup library. The test runner also hashes the exact tutorial sources and refuses a continuation that differs from the declared edits.</p></section>'
    if variant_links:
        html += '<section><h3>Complete experiment scripts</h3><ul>' + variant_links + '</ul></section>'
    html += '''<section><h3>What the evidence covers</h3><p class="limits">The tests run headlessly in Godot with synthetic controllers. They verify the code and library behaviour; they do not verify hardware grip input, headset comfort, visual appearance or a student’s understanding. Museum runtime and both reflective texts remain unchanged.</p>
<p class="limits">Lines still contains the older Coordinates continuation. Its historical test results remain available, with the changed predecessor marked for revision.</p>
<p class="links"><a href="report-runtime.json">Full result and source hashes</a><a href="run_checks.py.txt">Test runner source</a><a href="verify.gd">Native assertions</a><a href="http://localhost:3003/ghost-student?state=point-coordinates">Ghost Student</a></p></section>
<footer>Reproduce: python doc/book/iterations/2026-10-05-points-built-and-carried/run_checks.py</footer></main></html>'''
    (HERE / 'index.html').write_text(html, encoding='utf-8')
    print(f'Published {len(checks)} passing native assertions; protected sources unchanged.')


if __name__ == '__main__':
    main()
