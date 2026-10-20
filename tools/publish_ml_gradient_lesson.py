"""Publish Gradient Landscape's printed lesson, reflection and native evidence."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile
import markdown
from publish_ml_pose_lesson import page

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-gradient-a-line-and-a-loss'
STUDY = ROOT / 'doc/book/studies/ml-gradient'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Gradient_Landscape/gradient_lesson'
PLAN = ROOT / 'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'


def md(text):
    return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])


def main():
    tests = json.loads((OUT / 'tests.json').read_text(encoding='utf-8'))
    museum = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
    assert tests['passed'] and museum['passed'] and not tests['failures'] and not museum['failures']
    log = (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log
    count, spatial = len(tests['checks']), len(museum['checks'])
    for name in ['opening', 'hall', 'mse', 'huber']:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    (OUT / 'museum-diagnostics.json').write_text(json.dumps(
        [line for line in log.splitlines() if line.startswith(('ERROR:', 'WARNING:'))], indent=2), encoding='utf-8')
    texts = {}
    for name in ['tutorial', 'final']:
        source = ROOT / f'commons/maps/ML_Gradient_Landscape/{name}.md'
        texts[name] = source.read_text(encoding='utf-8')
        shutil.copy2(source, OUT / f'{name}.md')
        (OUT / f'{name}.html').write_text(page('Gradient / ' + name, md(texts[name])), encoding='utf-8')
    (OUT / 'parallel.html').write_text(page('A line and a loss',
        '<p>Complete tutorial on the left; reflective encounter on the right.</p><div class="pair"><article>'
        + md(texts['tutorial']) + '</article><article>' + md(texts['final']) + '</article></div>', True), encoding='utf-8')
    changes = '<h1>See the prediction.<br>Then change the score.</h1>'
    for name in ['tutorial', 'final']:
        changes += '<h2>' + name + '</h2><div class="pair"><article><h3>Before</h3>'
        changes += md((OUT / f'before/{name}.md').read_text(encoding='utf-8'))
        changes += '</article><article><h3>Now</h3>' + md(texts[name]) + '</article></div>'
    (OUT / 'changes.html').write_text(page('Gradient / before and after', changes, True), encoding='utf-8')
    shutil.copy2(PLAN, OUT / PLAN.name)
    (OUT / 'lineage.html').write_text(page('Machine Learning / editable route', md(PLAN.read_text(encoding='utf-8'))
        + '<p class="note">Published snapshot. Edit doc/book/course/storyboards/ML-SPHERE-LINEAGE.md.</p>'), encoding='utf-8')
    fits = tests['evidence']['outlier_fits']
    body = f'''<h1>A line.<br>A way to judge it.</h1>
<p class="lead">Evolution asked which conditions sustain a population. Gradient Landscape makes a score explicit: the carried sphere selects one line, and a descent step changes its slope and intercept.</p>
<div class="route"><span>Evolution / conditions</span><span class="active">Gradient / prediction and loss</span><span>Classification / grouping</span><span>Networks / learned weights</span></div>
<p><a href="parallel.html">Read the facing texts</a> · <a href="changes.html">Before and after</a> · <a href="gradient-review.zip">Download for review</a></p>
<figure><img src="mse.png" alt="Five orange observations and a turquoise fitted line beside the parameter surface and the carried PointBody in the museum"><figcaption>Actual Godot museum capture: the left diagram shows observations, predictions and residuals. The right surface scores slope/intercept pairs. One fixed endpoint outlier is present.</figcaption></figure>
<h2>The same data, two fits</h2>
<table><tr><th>Quantity</th><th>MSE</th><th>Huber, threshold 1</th></tr>
<tr><td>Slope after descent</td><td>{fits['mse'][0]:.3f}</td><td>{fits['huber'][0]:.3f}</td></tr>
<tr><td>Intercept after descent</td><td>{fits['mse'][1]:.3f}</td><td>{fits['huber'][1]:.3f}</td></tr>
<tr><td>Effect of a large residual</td><td>Squared contribution</td><td>Linear contribution beyond the threshold</td></tr></table>
<p>These are fits to five fixed teaching observations, not results from human participants or evidence of generalisation. The clean data's fit is slope 0.5, intercept 0.2. OUTLIER changes only the last y value, from 0.7 to 4.7. RESET repeats a start without changing the selected data, loss or rate.</p>
<figure><img src="huber.png" alt="The same observations fitted under Huber loss, with a different line and surface"><figcaption>Huber on the same data. The large residual has less influence. Nothing in that change tells us whether this observation is a mistake, a rare case or something we ought to understand.</figcaption></figure>
<h2>What the tutorial adds</h2>
<p>Two complete files replace unfinished surface code and a catalogue of optimizers. The model computes predictions, two losses, central differences and one update. The view links the actual line to its score. PointBody is carried unchanged from Evolution, with a new role: grabbing it pauses descent and chooses parameters in the museum study's local coordinates.</p>
<p>MSE and HUBER retain a candidate while changing its score. The surface uses one linear height scale. The same formula places every mesh sample and the sphere; height is calculated, not produced by gravity. RUN controls viewing pace, while SLOW/LARGE controls the parameter step. A large step can increase loss. A step outside the displayed parameter window is refused and named.</p>
<p>The reflection retains the original three-landscape encounter. It now connects to Evolution, distinguishes observation space from parameter space, and makes the display's separate normalization explicit. The existing comparator's third wavy rule and the optimizer race remain supporting exhibits.</p>
<h2>Ghost-student evidence</h2>
<p><strong>{count} native Godot assertions and {spatial} museum checks pass.</strong> The two new files are reconstructed from the printed code; the third is the declared carried PointBody. This is author-informed reconstruction, not a blind independent reader.</p>
<ul><li>Initial MSE 1.765, gradient (-1.5, 1.6), next slow candidate (-0.85, 0.84), checked independently.</li><li>Clean fits and outlier fits match analytical solutions.</li><li>Large-step loss increases; the following out-of-window proposal is refused without clamping.</li><li>All 3,456 mesh vertices follow the printed height rule.</li><li>Actual button signals retain the point and chosen conditions; hand input still works when the study is translated and rotated.</li></ul>
<figure><img src="hall.png" alt="Overhead view of Gradient Landscape with its retained exhibits and lesson study"><figcaption>The lesson launcher adds the reconstruction on clear floor at the hall's end. The initial placement intersected existing architecture and failed native checks; it was moved. This is not a complete spatial redesign of the older exhibits.</figcaption></figure>
<p>A later whole-route check exposed the frozen point returning to an older physics position after a paused Huber edit. The printed host now synchronizes the unheld sphere on physics ticks. Delayed headless and native-render checks pass.</p>
<div class="card">Human headset reach and comfort remain untested. The hand tests use the supplied desktop grab adapter. Existing engine diagnostics are retained. All eight lessons now have reconstruction evidence; the <a href="../2026-10-11-ml-whole-route/index.html">whole-route review</a> records their connections and limits.</div>
<p><a href="tests.json">Code assertions</a> · <a href="museum-tests.json">Museum checks</a> · <a href="reconstruction.json">Printed-code provenance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Diagnostics</a></p>
<h2>Try it in the museum</h2>
<p>Run <code>res://doc/book/studies/ml-gradient/Gradient.tscn</code>. Grab the point to choose parameters; put it down before pressing controls. STEP attempts one update; RUN toggles automatic descent. Compare MSE and HUBER at the same candidate, then RESET before comparing their descents. OUTLIER toggles a fixed observation. Everything in this small study is session-only.</p>
<p>Canonical texts remain <code>commons/maps/ML_Gradient_Landscape/tutorial.md</code> and <code>final.md</code>. <a href="lineage.html">The editable plan</a> records what travels onward. Next: Classification, where distance is used to group observations.</p>'''
    (OUT / 'index.html').write_text(page('Gradient / a line and a loss', body), encoding='utf-8')
    sources = [ROOT / f'commons/maps/ML_Gradient_Landscape/{name}.md' for name in ['tutorial', 'final']]
    sources += [PLAN, ROOT / 'commons/maps/sequences/machinelearning.json',
                ROOT / 'tools/test_ml_gradient_lesson.py', ROOT / 'tools/probes/ml_gradient_lesson_test.gd',
                ROOT / 'tools/probes/ml_gradient_lesson_museum.gd', Path(__file__).resolve()]
    for source in sorted((OUT / 'learner/printed').glob('*.gd')):
        assert source.read_text(encoding='utf-8') == (STUDY / source.name).read_text(encoding='utf-8'), source.name
        sources.append(STUDY / source.name)
    carried = ROOT / 'doc/book/studies/ml-environment/point_body.gd'
    assert carried.read_text(encoding='utf-8') == (STUDY / 'point_body.gd').read_text(encoding='utf-8')
    sources += [carried, STUDY / 'Gradient.tscn', STUDY / 'gradient_museum.gd',
                ROOT / 'algorithms/machinelearning/loss_function_comparator/loss_function_comparator.gd',
                ROOT / 'algorithms/numericalmethods/gradientdescent/gradient_descent_visualization.gd']
    register = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]
    (OUT / 'source-register.json').write_text(json.dumps(register, indent=2), encoding='utf-8')
    (OUT / 'README.md').write_text(f'''# Gradient Landscape review

Read tutorial.md and final.md together. All new code is printed in two blocks. learner/printed contains those files and the unchanged PointBody carried from Evolution. The supplied launcher mounts the study inside the real museum; it does not permanently register a new ordinary-route artifact. This bundle requires AdaResearch with its XR Tools and named RackTemplates button factory. It is not a standalone Godot export.

Run res://doc/book/studies/ml-gradient/Gradient.tscn. Hand movement chooses slope/intercept; put the point down to score/step. No observations or fit are saved. Existing exhibits are retained.

Reconstruct: python tools/test_ml_gradient_lesson.py

Museum: python tools/run_encounter_probe.py ML_Gradient_Landscape --sequence machinelearning --render --no-bridges --output-tag gradient_lesson --probe tools/probes/ml_gradient_lesson_museum.gd

Publish: python tools/publish_ml_gradient_lesson.py

{count} native assertions and {spatial} museum checks pass. Author-informed exact-print reconstruction, not a blind agent. Synthetic data and supplied desktop hand adapter; human VR comfort untested. Existing engine diagnostics retained. All eight lessons now have reconstruction evidence; see the dated ml-whole-route review for saved-data handoffs and complete readings.
''', encoding='utf-8')
    names = ['README.md', 'tutorial.md', 'final.md', PLAN.name, 'tests.json', 'museum-tests.json',
             'museum-diagnostics.json', 'reconstruction.json', 'source-register.json',
             'opening.png', 'hall.png', 'mse.png', 'huber.png',
             'index.html', 'parallel.html', 'tutorial.html', 'final.html', 'changes.html', 'lineage.html']
    with zipfile.ZipFile(OUT / 'gradient-review.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for name in names: z.write(OUT / name, name)
        for p in sorted((OUT / 'learner/printed').glob('*.gd')): z.write(p, 'learner/printed/' + p.name)
        for name in ['Gradient.tscn', 'gradient_museum.gd']: z.write(STUDY / name, 'supplied-museum/' + name)
    print(f'Published {count}+{spatial} checks: {OUT}')


if __name__ == '__main__':
    main()
