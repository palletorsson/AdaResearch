"""Publish the museum's declared-intention check board and scoped evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-sphere-check-your-intention'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Perception/phrase_check'
ART = ROOT / 'commons/artifacts/vogue_timeline'


def receipt(path):
    data = json.loads(path.read_text(encoding='utf-8'))
    assert data.get('passed', True) and not data['failures'], path
    assert data['checks'] and all(c['passed'] for c in data['checks']), path
    return data


def main():
    tests = receipt(OUT / 'tests.json')
    museum = receipt(RUN / 'report.json')
    log = (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR:' not in log
    (OUT / 'museum-diagnostics.json').write_text(json.dumps([s for s in log.splitlines() if s.startswith(('ERROR:', 'WARNING:'))], indent=2), encoding='utf-8')
    previous = 0
    for folder, name in [
        ('2026-10-11-teach-a-sphere', 'pose'),
        ('2026-10-11-teach-a-sphere-height', 'height'),
        ('2026-10-11-teach-a-sphere-phrase', 'one-phrase'),
        ('2026-10-11-teach-a-sphere-two-phrases', 'two-phrases'),
        ('2026-10-11-vogue-a-phrase-of-your-own', 'dance'),
    ]:
        source = ROOT / 'doc/book/iterations' / folder / 'tests.json'
        previous += len(receipt(source)['checks'])
        shutil.copy2(source, OUT / f'{name}-tests.json')
    for name in ['museum', 'empty', 'six-checks', 'retrained', 'new-check']:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    code_names = ['phrase_evaluation.gd', 'phrase_check.gd', 'phrase_library.gd', 'movement_learning.gd', 'movement_learner.gd']
    for name in code_names + ['PHRASE-CHECK.md', 'PHRASE-CHOICES.md', 'PHRASE.md']:
        shutil.copy2(ART / name, OUT / name)
    count, spatial = len(tests['checks']), len(museum['checks'])
    code = html.escape((ART / 'phrase_evaluation.gd').read_text(encoding='utf-8'))
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What did you mean? · Endless Museum</title><style>
:root{{color-scheme:dark}}*{{box-sizing:border-box}}body{{margin:0;background:#10141d;color:#eeedf1;font:18px/1.65 system-ui,sans-serif}}main{{max-width:1200px;margin:auto;padding:48px 28px 90px}}h1{{font-size:clamp(42px,7vw,86px);line-height:1.06;letter-spacing:-.04em}}h2{{margin-top:2em;line-height:1.3}}.lead{{font-size:25px;max-width:880px}}.eyebrow{{color:#92d6e8;font-size:13px;letter-spacing:.12em;text-transform:uppercase}}a{{color:#92d6e8}}figure{{margin:28px 0}}img{{width:100%;display:block;border-radius:8px}}figcaption{{font-size:14px;color:#c1c8d2;margin-top:9px}}.grid{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}.card{{background:#1c2531;padding:25px;border:1px solid #39495b;border-radius:8px}}.card h2{{margin-top:0}}.stamp{{display:inline-block;padding:8px 15px;border:1px solid #6c7b86;border-radius:24px;font-size:14px}}li{{margin:12px 0}}table{{width:100%;border-collapse:collapse;font-size:16px}}th,td{{padding:14px;border-bottom:1px solid #3f4d5f;text-align:left}}pre{{padding:24px;overflow:auto;background:#080d13;font:13px/1.55 monospace}}@media(max-width:760px){{main{{padding:24px 16px}}.grid{{grid-template-columns:1fr}}}}</style></head>
<body><main><p class="eyebrow">Endless Museum · ML_Perception · 11 October 2026</p><h1>What did you mean?</h1>
<p class="lead">The sphere has learned two phrases. Now declare your intention, perform, and compare it with the answer. Keep the disagreements visible when you teach again.</p>
<p class="stamp">{count} new Godot checks · {spatial} museum checks · {previous} earlier checks passed</p>
<figure><img src="museum.png" alt="The new CHECK board beside the same sphere in the actual Perception museum"><figcaption>Actual Godot museum capture. CHECK is part of the existing learning station; the same sphere and two-hand phrase models remain.</figcaption></figure>
<div class="grid"><section class="card"><h2>A small next step</h2><p>Recognition gave us an answer. To evaluate it, we also need to know what the visitor meant to do.</p><p>Choose A, B or neither before recording. The classifier receives only the measured movement; your declared intention is attached to its result afterward.</p></section><section class="card"><h2>The record stays</h2><p>Each completed check keeps its whole take, intention, result and model version. Changing the teaching starts a separate table.</p><p>Earlier results remain available for export. A later successful demonstration does not erase the earlier mistakes.</p></section></div>
<h2>Try it in the museum</h2><ol>
<li>Teach A and B and press TRAIN, as before. Choose <strong>CHECK</strong> on the nearby console.</li>
<li>Select <strong>MEAN A</strong>, <strong>MEAN B</strong> or <strong>NEITHER</strong>. NEITHER declares a movement outside your taught categories; it is not another trained class.</li>
<li>Press <strong>CAPTURE</strong>. Prepare during the count-in, then move both hands over eight beats. Your intention stays locked during the take.</li>
<li>Read the table: <strong>row = what you meant; column = model answer</strong>. Unknown and ambiguous have their own columns. CHECK keeps the sphere still.</li>
<li>Repeat with another declared intention. Then choose BACK, revise your teaching, TRAIN and CHECK again. Changed models get separate counts.</li>
<li>EXPORT keeps the full record locally. CLEAR requires a second press and affects only this journal, leaving teaching and the sphere's learned models intact.</li></ol>
<figure><img src="empty.png" alt="Empty check board and controls to declare an intention before recording"><figcaption>Choose before capturing. The board records personal checks; it does not invent an accuracy percentage or judge the dance.</figcaption></figure>
<h2>Read a disagreement</h2><p>The following museum captures use <strong>synthetic performances with deliberately supplied intentions</strong>. Some intentions disagree with the movement supplied to the classifier. This tests the record keeping; it does not measure a human error rate.</p>
<figure><img src="six-checks.png" alt="Six test performances recorded by intended label and model answer"><figcaption>Six whole performances. Two familiar examples agree, others select a different class or are withheld. Every outcome stays in its own cell.</figcaption></figure>
<table><thead><tr><th>Meant</th><th>Model A</th><th>Model B</th><th>Unknown</th><th>Ambiguous</th></tr></thead><tbody>
<tr><td>A</td><td>1</td><td>1</td><td>0</td><td>0</td></tr><tr><td>B</td><td>0</td><td>1</td><td>1</td><td>0</td></tr><tr><td>Neither</td><td>1</td><td>0</td><td>1</td><td>0</td></tr></tbody></table>
<p>The A row includes a take declared A but returned as B. The neither row includes an accepted A and a withheld unknown. Ambiguity remains distinct from both; its counting is tested with overlapping phrase models.</p>
<h2>Teach again without losing the history</h2><div class="grid"><figure><img src="retrained.png" alt="Changed model with zero current tests and six earlier tests retained"><figcaption>One new teaching demonstration changes the model. Its table starts empty; six checks remain with the earlier version.</figcaption></figure><figure><img src="new-check.png" alt="A fresh performance counted only for the revised model"><figcaption>A new complete performance adds one check to the revised model. It is not mixed into the earlier six.</figcaption></figure></div>
<p>Model contents identify a version. Fitting the same unchanged demonstrations again produces the same version and retains its counts. The table is a tool for investigation, not a promise that every added example improves recognition.</p>
<h2>What the code protects</h2><p>Checks never train. An exact teaching take cannot masquerade as a fresh check; an exact duplicate cannot inflate the same model's counts. Incomplete takes and tracking interruptions add nothing. Every new completed check requires another explicit intention.</p>
<p>The local export includes full timestamped takes, intentions, returned distances and the model snapshots that produced the results. History stays in memory while this session runs; EXPORT preserves it in <code>user://ada_phrase_checks_v1.json</code>. It is not automatically reloaded or converted to training. At 120 records, export and clear to continue; nothing is silently dropped.</p>
<h2>Intention is part of the encounter</h2><p>Your declaration is not an infallible label for a movement. It tells us what you were trying to do. The model answers using a much narrower relation: the positions of two controllers over four seconds. A disagreement gives us something specific to investigate without making either intention or measurement the whole meaning of the gesture.</p>
<p>Repeated personal checks can guide revisions. Once they guide those revisions, they are no longer an untouched final evaluation set. Fresh performances—and eventually a separate final test—are needed for a stronger accuracy claim. Headset use and varied human movement remain to be tried.</p>
<h2>Compact lesson instruction</h2><p class="card">Same sphere + A/B. CHECK: declare A/B/neither; lock intent; capture; predict without label; compare afterward. Whole takes, 3×4 counts. Keep unknown and ambiguous separate. Tests never train. Changed model gets own table; export earlier takes + models. Revise teaching, then collect fresh checks.</p>
<h2>Code and evidence</h2><p><a href="PHRASE-CHECK.md">Play instructions and full notes</a> · <a href="PHRASE-CHOICES.md">Carried A/B lesson</a> · <a href="phrase_evaluation.gd">Evaluation journal</a> · <a href="phrase_check.gd">Museum board and controls</a> · <a href="movement_learning.gd">Capture integration</a> · <a href="phrase_library.gd">Unchanged classifier</a></p>
<p><a href="tests.json">New checks</a> · <a href="museum-tests.json">Museum checks</a> · <a href="two-phrases-tests.json">A/B</a> · <a href="one-phrase-tests.json">ONE</a> · <a href="pose-tests.json">Pose</a> · <a href="height-tests.json">Height</a> · <a href="dance-tests.json">Dance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Existing project diagnostics</a></p>
<p>The receipts cover the production model, native controls, capture completion and actual museum placement. Earlier suites include supplied XR tracker poses. Synthetic tests do not establish human recognition accuracy or a diagnostic-free whole project.</p>
<details><summary>Read the complete evaluation journal</summary><pre><code>{code}</code></pre></details>
<p><a href="../2026-10-11-teach-a-sphere-two-phrases/index.html">Previous: two phrases, room for doubt</a></p></main></body></html>'''
    (OUT / 'index.html').write_text(page, encoding='utf-8')
    sources = [ART / name for name in code_names + ['PHRASE-CHECK.md']]
    sources += [ROOT / 'tools' / name for name in ['test_phrase_check.py', 'publish_phrase_check.py', 'probes/phrase_check_test.gd', 'probes/phrase_check_museum.gd', 'probes/movement_fixture.gd']]
    hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    (OUT / 'source-register.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    print(f'Published {count} + {spatial} + {previous} passing checks: {OUT}')


if __name__ == '__main__':
    main()
