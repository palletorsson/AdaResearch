"""Publish the two-phrase extension with actual museum captures and test receipts."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-teach-a-sphere-two-phrases'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Perception/phrase_library'
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
    diagnostics = [line for line in log.splitlines() if line.startswith(('ERROR:', 'WARNING:'))]
    (OUT / 'museum-diagnostics.json').write_text(json.dumps(diagnostics, indent=2), encoding='utf-8')
    previous = 0
    for folder, name in [
        ('2026-10-11-teach-a-sphere', 'pose'),
        ('2026-10-11-teach-a-sphere-height', 'height'),
        ('2026-10-11-teach-a-sphere-phrase', 'single-phrase'),
        ('2026-10-11-vogue-a-phrase-of-your-own', 'dance'),
    ]:
        source = ROOT / 'doc/book/iterations' / folder / 'tests.json'
        previous += len(receipt(source)['checks'])
        shutil.copy2(source, OUT / f'{name}-tests.json')
    for name in ['museum', 'empty', 'phrase-a', 'phrase-b', 'unknown', 'ambiguous']:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    for name in ['phrase_library.gd', 'movement_learner.gd', 'movement_learning.gd', 'pose_learning_station.gd', 'PHRASE.md', 'PHRASE-CHOICES.md']:
        shutil.copy2(ART / name, OUT / name)
    count, spatial = len(tests['checks']), len(museum['checks'])
    code = html.escape((ART / 'phrase_library.gd').read_text(encoding='utf-8'))
    content = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Two phrases, room for doubt · Endless Museum</title><style>
:root{{color-scheme:dark}}*{{box-sizing:border-box}}body{{margin:0;background:#10141d;color:#eeedf1;font:18px/1.65 system-ui,sans-serif}}main{{max-width:1200px;margin:auto;padding:48px 28px 90px}}h1{{font-size:clamp(42px,7vw,86px);line-height:1.07;letter-spacing:-.045em;max-width:960px}}h2{{margin-top:2.2em;line-height:1.25}}.lead{{font-size:25px;max-width:900px}}.eyebrow{{color:#91d5e8;letter-spacing:.12em;font-size:13px;text-transform:uppercase}}a{{color:#92d9ef}}figure{{margin:28px 0}}img{{width:100%;display:block;border-radius:7px}}figcaption{{font-size:14px;color:#bec6d2;margin-top:9px}}.grid{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}.card{{padding:24px;background:#1d2430;border:1px solid #364455;border-radius:8px}}.card h2{{margin-top:0}}.stamp{{display:inline-block;padding:8px 15px;border:1px solid #667788;border-radius:24px;font-size:14px}}li{{margin:12px 0}}table{{border-collapse:collapse;width:100%;font-size:16px}}th,td{{padding:14px;border-bottom:1px solid #405062;text-align:left;vertical-align:top}}pre{{padding:24px;background:#080c12;overflow:auto;font:13px/1.55 monospace}}.accent{{color:#ffd282}}@media(max-width:760px){{main{{padding:24px 16px}}.grid{{grid-template-columns:1fr}}}}</style></head>
<body><main><p class="eyebrow">Endless Museum · ML_Perception · 11 October 2026</p>
<h1>Two phrases.<br>Room for doubt.</h1>
<p class="lead">Teach the same sphere two movements of your own. Let it recognise the difference—and notice when that difference is too small to support a choice.</p>
<p class="stamp">{count} new Godot checks · {spatial} museum checks · {previous} earlier checks passed</p>
<figure><img src="museum.png" alt="The existing Teach a sphere station inside the Perception museum hall"><figcaption>Built in the actual museum, beside the existing dance. The same sphere, hand traces and four-second capture carry forward.</figcaption></figure>
<div class="grid"><section class="card"><h2>What changes</h2><p>PHRASE now has <strong>ONE / A / B</strong>. A and B are labels you teach through complete performances. A fresh take is compared against both, without being told which you intend.</p><p>The sphere replays the recognised path. It waits for unfamiliar or ambiguous movement.</p></section><section class="card"><h2>What remains</h2><p>ONE keeps the earlier single-phrase activity and examples. POSE and HEIGHT retain their own work. Switching lessons keeps the same sphere.</p><p>Eight beats at 120 BPM; both hands; three complete takes per label. The new work adds a distinction, not another dance to copy.</p></section></div>
<h2>Try it</h2><ol>
<li>Select <strong>PHRASE → A</strong>. CAPTURE your first phrase three times. Prepare during the count-in, then move both hands for eight beats.</li>
<li>Select <strong>B</strong>. CAPTURE another phrase three times. Try the first movement in reverse order, or invent a distinct second one.</li>
<li>Press <strong>TRAIN</strong>. A and B select the teaching/preview set. REPLAY shows its fitted paths.</li>
<li>Choose <strong>TEST → CAPTURE</strong>. Perform either phrase without selecting its label. Read A, B, UNKNOWN or AMBIGUOUS. Test takes never train the model.</li>
<li>Press <strong>TRY</strong>. A clear match makes the original sphere replay that learned path. A result withheld leaves it waiting.</li>
<li>Try teaching very similar movements under the two labels. What difference can this recording actually retain?</li>
</ol>
<p>SAVE / LOAD keeps both sets locally. UNDO removes the last teaching take of the selected label. RESET asks for a second press and clears only A + B in memory. ONE returns to the earlier lesson. SOUND switches the beat click.</p>
<figure><img src="empty.png" alt="An empty A/B session with controls for capture, teaching, testing and selecting a phrase"><figcaption>The visitor session arrives empty. Buttons are on the existing nearby console; the sphere's response label sits beside the object.</figcaption></figure>
<h2>Four outcomes</h2><p>The following are real Godot captures using <strong>labelled synthetic demonstrations and fresh synthetic test performances</strong>. They show the running behaviour, not a claim about human recognition accuracy.</p>
<div class="grid"><figure><img src="phrase-a.png" alt="A recognised test causes the sphere to replay learned phrase A"><figcaption><strong class="accent">A.</strong> A fresh performance fits the first taught path. The gold sphere responds.</figcaption></figure>
<figure><img src="phrase-b.png" alt="The same sphere replays phrase B, taught as a reversal of A"><figcaption><strong class="accent">B.</strong> The fixture teaches the reverse order as a second class. Recognition selects its learned path.</figcaption></figure>
<figure><img src="unknown.png" alt="Unknown movement leaves the sphere waiting"><figcaption><strong>UNKNOWN.</strong> Neither prototype accepts the new movement. The sphere stays silver and still.</figcaption></figure>
<figure><img src="ambiguous.png" alt="Similar learned phrases produce an ambiguous result without a sphere response"><figcaption><strong>AMBIGUOUS.</strong> In a separate fixture, both classes describe almost the same movement. Both fit; neither is clearly nearer.</figcaption></figure></div>
<h2>How the decision works</h2>
<p>Each label uses the existing timed prototype: 41 points through time, each holding six hand coordinates. Training averages the complete takes and derives a bounded tolerance for each hand. Both hands must pass; one cannot compensate for the other.</p>
<table><thead><tr><th>Comparison</th><th>Result</th></tr></thead><tbody>
<tr><td>Neither prototype passes its two-hand limits</td><td>UNKNOWN</td></tr><tr><td>Only one passes</td><td>That label</td></tr>
<tr><td>Both pass and their normalised distance scores differ by at least 0.20</td><td>The nearer label</td></tr><tr><td>Both pass and the difference is smaller</td><td>AMBIGUOUS</td></tr></tbody></table>
<p>The score uses the worse hand's RMS error relative to its fitted tolerance. It is a distance, <strong>not a probability</strong>. The margin is an authored choice. Incomplete takes are discarded before this comparison. Fixed timing remains part of the lesson; variable-speed alignment is not implemented.</p>
<h2>A distinction you can revise</h2>
<p>A and B do not name natural kinds of movement. They record a distinction the visitor proposes. Changing the demonstrations changes what the sphere can distinguish; swapping their labels swaps the model's answers.</p>
<p>Hesitation can be informative. Two movements may matter differently to you while looking almost identical through head-relative controller positions. Intent, fingers, the rest of the body and cultural context are outside this measurement. The visitor can revise the examples, question the measurement, or leave the distinction unresolved.</p>
<h2>What passed</h2><p>The new assertions test fresh A/B decisions, reversal, label swapping, unknown movement, ambiguity, both-hand requirements, save/load, atomic rejection of damaged data, unchanged models during tests, native controls, completed capture, scoped reset and the same sphere's response. The earlier phrase, pose, height and dance checks also pass, including supplied XR tracker input and interrupted capture.</p>
<p>These are controlled software tests. Human repetition, headset comfort, timing variation and device performance still need playtesting. Existing surrounding museum diagnostics are recorded separately; this is not a whole-project clean bill of health.</p>
<h2>Compact lesson instruction</h2><p class="card">Same sphere. ONE retained. A/B: three whole takes each; fit timed prototypes. TEST fresh takes against both. TRY replays clear match. UNKNOWN neither; AMBIGUOUS overlap. Change examples to change categories. Distances, never confidence. Keep whole takes separate from tests.</p>
<h2>Code and evidence</h2><p><a href="PHRASE-CHOICES.md">Interaction and model notes</a> · <a href="PHRASE.md">Carried capture and timing</a> · <a href="phrase_library.gd">Complete two-label model</a> · <a href="movement_learner.gd">Underlying prototype</a> · <a href="movement_learning.gd">Museum interaction</a></p>
<p><a href="tests.json">New tests</a> · <a href="museum-tests.json">Museum tests</a> · <a href="single-phrase-tests.json">ONE</a> · <a href="pose-tests.json">Pose</a> · <a href="height-tests.json">Height</a> · <a href="dance-tests.json">Dance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Existing diagnostics</a></p>
<details><summary>Read the complete two-label model</summary><pre><code>{code}</code></pre></details>
<p><a href="../2026-10-11-teach-a-sphere-phrase/index.html">Previous: the sphere keeps one phrase</a></p>
</main></body></html>'''
    (OUT / 'index.html').write_text(content, encoding='utf-8')
    names = ['phrase_library.gd', 'movement_learning.gd', 'movement_learner.gd', 'pose_learning_station.gd', 'PHRASE-CHOICES.md', 'PHRASE.md']
    sources = [ART / name for name in names]
    sources += [ROOT / 'tools' / name for name in ['test_phrase_library.py', 'publish_phrase_library.py', 'probes/phrase_library_test.gd', 'probes/phrase_library_museum.gd', 'probes/movement_fixture.gd']]
    hashes = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    (OUT / 'source-register.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    print(f'Published {count} + {spatial} + {previous} passing checks: {OUT}')


if __name__ == '__main__':
    main()
