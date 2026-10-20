"""Publish the actual hall captures and scoped, reproducible learning evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-teach-a-sphere'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Perception/pose_learning'

def main():
    tests = json.loads((OUT / 'tests.json').read_text(encoding='utf-8'))
    museum = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
    dance_path = ROOT / 'doc/book/iterations/2026-10-11-vogue-a-phrase-of-your-own/tests.json'
    dance = json.loads(dance_path.read_text(encoding='utf-8'))
    assert tests['passed'] and museum['passed'] and not dance['failures']
    for name in ['museum', 'teach-empty', 'learned-a', 'learned-b', 'learned-c']:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    shutil.copy2(dance_path, OUT / 'dance-tests.json')
    shutil.copy2(ROOT / 'commons/artifacts/vogue_timeline/LEARNING.md', OUT / 'notes.md')
    for name in ['pose_learner.gd', 'pose_learning_station.gd']:
        shutil.copy2(ROOT / 'commons/artifacts/vogue_timeline' / name, OUT / name)
    diagnostics = [line for line in (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace').splitlines() if line.startswith(('ERROR:', 'SCRIPT ERROR:', 'WARNING:'))]
    (OUT / 'museum-diagnostics.json').write_text(json.dumps(diagnostics, indent=2), encoding='utf-8')
    count = len(tests['checks'])
    spatial = len(museum['checks'])
    regression = len(dance['checks'])
    e = tests['evidence']
    source = html.escape((OUT / 'pose_learner.gd').read_text(encoding='utf-8'))
    text = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Teach a sphere · Endless Museum</title><style>
    :root{{color-scheme:dark}}*{{box-sizing:border-box}}body{{margin:0;background:#10131e;color:#f4f1f6;font:18px/1.65 system-ui,sans-serif}}main{{max-width:1150px;margin:auto;padding:48px 26px 90px}}h1{{font-size:clamp(42px,7vw,82px);line-height:1.05;letter-spacing:-.05em}}h2{{margin-top:2.3em}}a{{color:#7dd6ff}}.lead{{font-size:24px;max-width:850px}}.kicker{{color:#ffc567;text-transform:uppercase;letter-spacing:.1em;font-size:13px}}figure{{margin:30px 0}}img{{display:block;width:100%;border-radius:8px}}figcaption{{font-size:14px;color:#c0bfd0;margin-top:10px}}.grid{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}.card{{padding:24px;background:#1b2031;border:1px solid #373c52;border-radius:10px}}table{{border-collapse:collapse;width:100%;font-size:16px}}td,th{{text-align:left;padding:14px;border-bottom:1px solid #3b4158;vertical-align:top}}pre{{font-size:13px;line-height:1.5;overflow:auto;padding:24px;background:#070a12}}.stamp{{display:inline-block;border:1px solid #65727b;padding:8px 14px;border-radius:30px;font-size:14px}}li{{margin:12px 0}}@media(max-width:720px){{.grid{{grid-template-columns:1fr}}main{{padding:26px 16px}}}}</style></head>
    <body><main><p class="kicker">Endless Museum · ML_Perception · 11 October 2026</p><h1>Teach a sphere.</h1><p class="lead">Your hands provide the examples. A small neural network learns three poses. Its predictions make the sphere float, spin or stretch.</p><p class="stamp">Built in Godot · {count} learning/interaction checks · {spatial} museum checks · {regression} dance regression checks</p>
    <figure><img src="museum.png" alt="Pose teaching station beside the existing dance in the actual Perception hall"><figcaption>Actual museum capture. The new console is on the left of the existing dance. It begins with no examples and no trained pose answers.</figcaption></figure>
    <div class="grid"><section class="card"><h2>Inside the game</h2><p>All fitting runs locally in GDScript. Six measured hand coordinates feed eight hidden units and three outputs. Training changes 83 real parameters; the yellow curve is calculated loss. No cloud model or GPU service is needed.</p><p>The visitor supplies A, B and C. Those categories have no prescribed poses. The output behaviours are authored; which hands produce which category is learned.</p></section><section class="card"><h2>Beside the dance</h2><p>The dance keeps its timed reference paths and recorded-phrase replay. The new station is a separate learning process: examples, fitting, fresh tests, live prediction and a saved model.</p><p>It recognises short held arrangements of two controllers. It does not learn the full dance, infer fingers or evaluate artistic merit.</p></section></div>
    <h2>Try it in VR</h2><ol><li>Stand at <strong>TEACH A SPHERE</strong>, facing the console. In TEACH, press <strong>A</strong>. Use the three-second countdown to arrange your hands, then hold briefly.</li><li>Make at least three separate takes each for <strong>A, B and C</strong>. Choose visibly different poses; move between takes and allow small variations.</li><li>Press <strong>TRAIN</strong>. Watch the measured loss change over 300 updates.</li><li>In <strong>TEST</strong>, press the expected label and perform a fresh take. Read the prediction. These tests never change the model.</li><li>Press <strong>LIVE</strong>. Hold your poses: <strong>A floats, B spins, C stretches</strong>. A low score or a distant input leaves the sphere idle.</li><li><strong>SAVE / LOAD</strong> keeps examples and weights on this device. <strong>ALIGN</strong> establishes your forward direction again. Two RESET presses clear the current session.</li></ol>
    <figure><img src="teach-empty.png" alt="Empty learning station with nearby teach, train, test and save controls"><figcaption>One capture produces one averaged pose example. Tracking loss, a long frame interruption or excessive movement discards the unfinished take. Capturing starts only when you request it.</figcaption></figure>
    <h2>A real fitting run</h2><p>In the automated test, training loss fell from <strong>{e['loss_before']:.3f}</strong> to <strong>{e['loss_after']:.3f}</strong>. The model classified 15 distinct held-out synthetic poses correctly. Permuting the supplied labels changed its answers: the result follows the training examples rather than a built-in pose lookup.</p><p>All 83 analytic derivatives were checked against independent finite differences (maximum error {e['gradient_max_error']:.2g}). Test captures left parameters and training examples unchanged. Save/load preserved parameters to numerical precision.</p><p>These are synthetic test results, not a claim of accuracy on visitors. The following captures explicitly use a synthetic rehearsal; the production artifact starts empty.</p>
    <figure><img src="learned-a.png" alt="A genuinely trained model driving the floating sphere, with the synthetic rehearsal clearly labelled"><figcaption>A / FLOAT. The learning curve comes from an actual fit performed in the museum capture process.</figcaption></figure>
    <div class="grid"><figure><img src="learned-b.png" alt="Trained category B rotates the banded sphere"><figcaption>B / SPIN. The band makes rotation visible.</figcaption></figure><figure><img src="learned-c.png" alt="Trained category C stretches the sphere"><figcaption>C / STRETCH. The same object gains another response.</figcaption></figure></div>
    <h2>What can be real next?</h2><table><thead><tr><th>Encounter</th><th>Bounded in-game process</th></tr></thead><tbody>
    <tr><td>Learned control</td><td>Fit a small regression model from hand positions to a sound or movement parameter.</td></tr><tr><td>Point groups</td><td>Run actual k-means updates on the player's stored point collection.</td></tr><tr><td>Short movement phrases</td><td>Keep ordered hand samples, then train and test on separate complete performances.</td></tr><tr><td>New pose sequences</td><td>Learn transition frequencies and sample another order of known poses.</td></tr><tr><td>Large vision or generative models</td><td>Choose a specific supplied model and runtime first. Separate its prior training from inference in the museum; there is no such integration in this build.</td></tr></tbody></table>
    <h2>The decision is part of the object</h2><p>The three outputs are model scores, not certainty. A separate distance rule withholds some unfamiliar inputs. It cannot guarantee that every unfamiliar pose will be recognised as unfamiliar. You choose the categories, the examples and the meaning of a prediction. Better accuracy does not answer whether the resulting action is desirable.</p><p>Repeatedly testing and revising examples is exploratory evaluation. A later external check should reserve complete performances untouched by those decisions. Headset comfort, tracking variation and device performance still need playing.</p>
    <h2>Code and evidence</h2><p><a href="notes.md">Controls and implementation notes</a> · <a href="pose_learner.gd">Complete learner</a> · <a href="pose_learning_station.gd">Museum interaction code</a> · <a href="tests.json">Learning tests</a> · <a href="museum-tests.json">Museum tests</a> · <a href="dance-tests.json">Dance regression tests</a> · <a href="source-register.json">Source hashes</a></p><p>The surrounding hall retains older audio-UID, computer-vision startup and portal fallback diagnostics. They are preserved in the <a href="museum-diagnostics.json">diagnostic record</a>; passing this artifact's tests does not establish a clean whole-project log.</p><details><summary>Read the complete small learner</summary><pre><code>{source}</code></pre></details>
    <p><a href="../2026-10-11-vogue-a-phrase-of-your-own/index.html?revision=hand-feedback">Return to the dance</a></p></main></body></html>'''
    (OUT / 'index.html').write_text(text, encoding='utf-8')
    paths = ['commons/artifacts/vogue_timeline/pose_learner.gd', 'commons/artifacts/vogue_timeline/pose_learning_station.gd', 'commons/artifacts/vogue_timeline/vogue_timeline.gd', 'commons/artifacts/vogue_timeline/LEARNING.md', 'tools/probes/pose_learning_test.gd', 'tools/probes/pose_learning_museum.gd', 'tools/test_pose_learning.py']
    (OUT / 'source-register.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}, indent=2), encoding='utf-8')
    print(f'Published {count} + {spatial} + {regression} passing checks: {OUT}')

if __name__ == '__main__':
    main()
