"""Publish the current, verified Trace lesson and its teaching choices."""
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
    assert all(c['passed'] for c in report['checks'])
    for path, expected in report['inputs'].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected, path
    protected = json.loads((HERE / 'before/unchanged.json').read_text(encoding='utf-8'))
    for path, expected in protected.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected, path
    (HERE / 'run_checks.py.txt').write_bytes((student / 'run_checks.py').read_bytes())
    variants = sorted((student / 'variants').glob('*.gd'))
    variants_html = ''.join(f'<li><a href="student/variants/{p.name}">{escape(p.stem.replace("_", " ").replace("-", " "))}</a></li>' for p in variants)
    negatives = report.get('negative_controls', [])
    negative_html = ''.join('<li>' + escape(n.get('name', 'Deliberate fault').replace('_', ' ')) + '</li>' for n in negatives)
    count = len(report['checks'])
    html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Let the point leave a trace — Endless Museum</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f4f1eb;color:#292b28;font:16px/1.7 system-ui,sans-serif}main{max-width:1120px;margin:auto;padding:52px 32px 70px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.1}h1{font-size:clamp(42px,6vw,72px);letter-spacing:-.035em}h2{font-size:31px}.eyebrow{font-size:11px;letter-spacing:.13em;text-transform:uppercase;color:#62705c}.lead{font:23px/1.5 Georgia,serif;max-width:800px}a{color:#853f5c;text-underline-offset:4px}a:focus-visible{outline:3px solid #853f5c;outline-offset:4px}nav{display:flex;gap:24px;flex-wrap:wrap;font-size:14px;margin:26px 0}.proof{background:#dfe7d9;border:1px solid #c5cfbd;padding:17px 22px;margin:28px 0}.steps{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}article{background:#fffdf8;border:1px solid #d8d0c7;padding:23px}article h2{margin:15px 0}figure{margin:34px 0}img{width:100%;display:block}figcaption,.small{font-size:12px;color:#626c60;line-height:1.6;margin-top:10px}section{border-top:1px solid #ccc6bc;margin-top:34px;padding-top:16px;max-width:850px}code{font:13px Consolas,monospace}li{margin:7px 0}footer{font-size:12px;color:#63705e;margin-top:44px}@media(max-width:760px){main{padding:30px 20px}.steps{grid-template-columns:1fr}}
</style><main><header><p class="eyebrow">Endless Museum / Point Trace / 5 October 2026</p><h1>Let the point<br>leave a trace.</h1><p class="lead">The same dot can already be held. Now its earlier positions stay behind: an array keeps the order, a condition decides when to add, and a loop joins the neighbours.</p><nav><a href="../2026-10-05-primitives-facing-pages/Point_Trace.html?revision=carried-point">Read tutorial beside reflection ↗</a><a href="#evidence">Code and tests</a><a href="http://localhost:3003/ghost-student?state=point-trace">Ghost Student ↗</a></nav></header>'''
    html += f'<p class="proof"><strong>{count} native Godot checks passed.</strong> The printed Trace script continues the tested Lines construction and uses its unchanged drawing helper.</p>'
    html += '''<div class="steps"><article><p class="eyebrow">01 / Array</p><h2>Keep a position.</h2><p><code>Array[Vector3]</code> stores values in order. Seed the first entry; append new positions. One index selects a three-dimensional position.</p></article><article><p class="eyebrow">02 / If</p><h2>Has it moved enough?</h2><p>Compare the current position with the last one actually kept. Several small movements can cross the threshold. Waiting alone adds nothing.</p></article><article><p class="eyebrow">03 / For</p><h2>Join the neighbours.</h2><p>Visit 1 through size minus one. Draw 0–1, 1–2, 2–3. The same two-point relation now makes a trace.</p></article></div>
<figure><img src="../2026-10-05-eight-interaction-lessons/figures/trace.png" alt="Inside the existing Trace hall, with pens and their plinth readouts"><figcaption>Existing museum capture, 29 September. The hall is the encounter; the new student program follows the previously built dot. This image is not a rendering of the new test fixture.</figcaption></figure>
<section><h2>What changed</h2><p>The earlier tutorial inspected the production pen and its grip offset. This pass returns to the student’s own point. The original point and coordinate readout remain; the second endpoint and single live span give way to retained positions and their connecting segments.</p><p>The tutorial prints the complete <code>trace.gd</code> and <code>line_skin.gd</code>. It explains array lifetime, zero-based indices, append, the distance comparison, indentation and both loops. There is one <code>_ready()</code> definition.</p><p>Two small experiments separate the record from its display: raise the movement threshold, then omit the last neighbouring pair from the drawing loop.</p></section>
<section id="evidence"><h2>Test the record, not just the picture.</h2><p>Native Godot tests the exact printed code with actual XR Tools and a synthetic controller: seed, pickup, small cumulative movements, pauses, turns, returning to an earlier place, release, neighbouring segment geometry and a changed reference frame.</p>'''
    if negative_html:
        html += '<p>These intentionally broken versions are rejected by the ordinary checks:</p><ul>' + negative_html + '</ul>'
    html += '''<nav><a href="student/trace.gd">trace.gd</a><a href="student/line_skin.gd">line_skin.gd</a><a href="student/contract.json">Exact continuation</a><a href="student/report-runtime.json">Native report</a><a href="student/verify.gd">Native checks</a><a href="run_checks.py.txt">Test runner source</a></nav>'''
    if variants_html:
        html += '<h2>Complete experiments</h2><ul>' + variants_html + '</ul>'
    html += '''<p class="small">The tests run headlessly. They verify the code and library behaviour, not hardware input, headset comfort, appearance or a learner’s understanding. The reflective text, museum code and earlier student states are preserved.</p></section>
<section><h2>What travels onward</h2><p>The array contains positions in the station’s local frame. It survives successive frames and pickups while that station exists. It has no timestamps and does not save a file. Grid must reuse this record explicitly; a tested Grid continuation is still to come.</p></section><footer>Reproduce: <code>python doc/book/iterations/2026-10-05-trace-the-carried-point/student/run_checks.py</code></footer></main></html>'''
    (HERE / 'index.html').write_text(html, encoding='utf-8')
    print(json.dumps({'native_checks': count, 'protected_files_unchanged': len(protected), 'variants': len(variants)}))


if __name__ == '__main__':
    main()
