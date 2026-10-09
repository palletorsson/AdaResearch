"""Build a small, source-bound review of the current Lines continuation."""
from pathlib import Path
from html import escape
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def main():
    student = HERE / 'student'
    report = json.loads((student / 'report-runtime.json').read_text(encoding='utf-8'))
    assert report['passed']
    for path, expected in report['inputs'].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected, path
    protected = json.loads((HERE / 'before/unchanged.json').read_text(encoding='utf-8'))
    for path, expected in protected.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected, path
    checks = report['checks']
    assert all(c['passed'] for c in checks)
    contract = json.loads((student / 'contract.json').read_text(encoding='utf-8'))
    code = (student / 'line.gd').read_text(encoding='utf-8')
    assert code.count('func _ready()') == 1
    (HERE / 'run_checks.py.txt').write_bytes((student / 'run_checks.py').read_bytes())
    variants = sorted((student / 'variants').glob('*.gd'))
    variants_html = ''.join(f'<li><a href="student/variants/{p.name}">{escape(p.stem.replace("_", " ").replace("-", " "))}</a></li>' for p in variants)
    negative = report.get('negative_controls', [])
    if not negative and report.get('negative_control'):
        negative = [report['negative_control']]
    negatives_html = ''.join('<li>' + escape(n.get('name', n.get('mode', 'Deliberately broken version')).replace('_', ' ')) + '</li>' for n in negative)
    html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Two points, one relation — Endless Museum</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f4f1eb;color:#292a28;font:16px/1.7 system-ui,sans-serif}main{max-width:1140px;margin:auto;padding:52px 32px 70px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.1}h1{font-size:clamp(42px,6vw,72px);letter-spacing:-.035em;max-width:900px}h2{font-size:32px}.eyebrow{font-size:11px;letter-spacing:.13em;text-transform:uppercase;color:#65715d}.lead{font:23px/1.5 Georgia,serif;max-width:790px}a{color:#853e5b;text-underline-offset:4px}a:focus-visible{outline:3px solid #853e5b;outline-offset:4px}nav{display:flex;gap:24px;flex-wrap:wrap;font-size:14px;margin:26px 0}.proof{background:#e0e7d9;border:1px solid #c5cfbd;padding:17px 22px;margin:26px 0}figure{margin:32px 0}img{display:block;width:100%}figcaption{font-size:12px;color:#686c65;margin-top:8px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}article{background:#fffdf8;border:1px solid #d7d0c7;padding:25px}article h2{margin:10px 0 20px}section{padding-top:22px;margin-top:26px;border-top:1px solid #cdc6bd;max-width:850px}code{font:13px Consolas,monospace}li{margin:8px 0}.small{font-size:13px;color:#626b60}footer{margin-top:44px;font-size:12px;color:#697064}@media(max-width:740px){main{padding:30px 20px}.pair{grid-template-columns:1fr}}
</style><main><header><p class="eyebrow">Endless Museum / Point Lines / 5 October 2026</p><h1>Two points,<br>one relation.</h1><p class="lead">The point can already be held. Its copy becomes another end. Between them, a line changes with the distance and direction.</p><nav><a href="../2026-10-05-primitives-facing-pages/Point_Lines.html?revision=carried-point">Read tutorial beside reflection ↗</a><a href="#evidence">Code and tests</a><a href="http://localhost:3003/ghost-student?state=point-lines">Ghost Student ↗</a></nav></header>'''
    html += f'<p class="proof"><strong>{len(checks)} native checks passed.</strong> The complete printed Lines script continues the current, tested Coordinates construction.</p>'
    html += '''<figure><img src="../2026-10-01-lines-triangle-research/lines-final/line-room.png" alt="Inside the existing Point Lines hall, with parallel planks, upright lines and crossed beams"><figcaption>Existing museum capture, 1 October. This is the encounter the lesson draws from. The new tests run the reduced student study; this pass does not change the hall.</figcaption></figure>
<div class="pair"><article><p class="eyebrow">Before</p><h2>The continuation had drifted.</h2><p>Lines still began from an older point construction. It rebuilt extra material settings and omitted the local/world readout. Its earlier passing tests belonged to that older input.</p></article><article><p class="eyebrow">After</p><h2>Keep what was made.</h2><p>The point, collider and readout come directly from the current Coordinates script. A second body and a live segment add the next relation. The readout now also shows distance.</p></article></div>
<section><h2>What the student learns</h2><ul><li>Copy an existing body and keep a reference to the copy.</li><li>Read both endpoints in the same frame.</li><li>Distinguish the displacement <code>b - a</code> from its length.</li><li>Arrange a second line using stored positions, without more pickup bodies.</li><li>Separate an apparent crossing by changing depth.</li></ul><p>The full student script and supplied drawing helper are printed in <code>tutorial.md</code>. Only one <code>_ready()</code> definition is shown. The helper’s orientation calculation is available in full, while this lesson concentrates on endpoints and their relation.</p></section>
<section id="evidence"><h2>The code must carry forward.</h2><p>The verifier executes the printed programs in Godot, with the repository’s real XR Tools. It checks both pickups, moving and released endpoints, the rendered segment, the readout, changed reference frames, and the complete experiment scripts.</p>'''
    if negatives_html:
        html += '<p>Deliberate faults are rejected by the same behavioural checks:</p><ul>' + negatives_html + '</ul>'
    html += '''<nav><a href="student/line.gd">line.gd</a><a href="student/line_skin.gd">line_skin.gd</a><a href="student/report-runtime.json">Native report</a><a href="student/contract.json">Exact continuation</a><a href="student/verify.gd">Native checks</a><a href="run_checks.py.txt">Test runner source</a></nav>'''
    if variants_html:
        html += '<h2>Complete experiments</h2><ul>' + variants_html + '</ul>'
    html += '''<p class="small">Headless tests use synthetic controllers. They verify reconstruction and library behaviour, not headset input, appearance, comfort or a learner’s understanding. The supplied drawing helper, museum code and reflective text are unchanged. Earlier evidence is retained separately.</p></section>
<section><h2>Next: let a detour remain.</h2><p>The line only reads where its ends are now. Trace will retain positions in order. The saved Lines program is ready to become that lesson’s input; a tested Trace continuation has not yet been written.</p></section><footer>Reproduce from the project root: <code>python doc/book/iterations/2026-10-05-lines-from-the-carried-point/student/run_checks.py</code></footer></main></html>'''
    (HERE / 'index.html').write_text(html, encoding='utf-8')
    print(json.dumps({'native_checks': len(checks), 'protected_files_unchanged': len(protected), 'variants': len(variants)}))


if __name__ == '__main__':
    main()
