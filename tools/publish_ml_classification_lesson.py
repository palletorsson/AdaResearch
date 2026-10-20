"""Publish Classification's canonical texts and verified museum reconstruction."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile
import markdown
from publish_ml_pose_lesson import page

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-classification-a-group-without-a-name'
STUDY = ROOT / 'doc/book/studies/ml-classification'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Classification/classification_lesson'
PLAN = ROOT / 'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'
PICTURES = ['opening', 'hall', 'assigned', 'means', 'rings']


def md(text):
    return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])


def main():
    tests = json.loads((OUT / 'tests.json').read_text(encoding='utf-8'))
    museum = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
    assert tests['passed'] and museum['passed'] and not tests['failures'] and not museum['failures']
    log = (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log
    count, spatial = len(tests['checks']), len(museum['checks'])
    for name in PICTURES:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    (OUT / 'museum-diagnostics.json').write_text(json.dumps(
        [line for line in log.splitlines() if line.startswith(('ERROR:', 'WARNING:'))], indent=2), encoding='utf-8')
    texts = {}
    for name in ['tutorial', 'final']:
        source = ROOT / f'commons/maps/ML_Classification/{name}.md'
        texts[name] = source.read_text(encoding='utf-8')
        shutil.copy2(source, OUT / f'{name}.md')
        (OUT / f'{name}.html').write_text(page('Classification / ' + name, md(texts[name])), encoding='utf-8')
    (OUT / 'parallel.html').write_text(page('A group without a name',
        '<p>Complete tutorial on the left; reflective encounter on the right.</p><div class="pair"><article>'
        + md(texts['tutorial']) + '</article><article>' + md(texts['final']) + '</article></div>', True), encoding='utf-8')
    changes = '<h1>Keep the observations.<br>Move the centres.</h1>'
    for name in ['tutorial', 'final']:
        changes += '<h2>' + name + '</h2><div class="pair"><article><h3>Before</h3>'
        changes += md((OUT / f'before/{name}.md').read_text(encoding='utf-8'))
        changes += '</article><article><h3>Now</h3>' + md(texts[name]) + '</article></div>'
    (OUT / 'changes.html').write_text(page('Classification / before and after', changes, True), encoding='utf-8')
    shutil.copy2(PLAN, OUT / PLAN.name)
    (OUT / 'lineage.html').write_text(page('Machine Learning / editable route', md(PLAN.read_text(encoding='utf-8'))
        + '<p class="note">Published snapshot. Edit doc/book/course/storyboards/ML-SPHERE-LINEAGE.md.</p>'), encoding='utf-8')
    body = f'''<h1>A group.<br>Still without a name.</h1>
<p class="lead">The carried sphere returns as one cluster centre. Move it, assign the unchanged observations, then let the group move its centre in return.</p>
<div class="route"><span>Evolution / conditions</span><span>Gradient / objective</span><span class="active">Classification / grouping</span><span>Networks / learned weights</span></div>
<p><a href="parallel.html">Read the facing texts</a> · <a href="changes.html">Before and after</a> · <a href="classification-review.zip">Download for review</a></p>
<figure><img src="means.png" alt="The carried black sphere and three groups of fixed observations connected to their centres on a dark table inside the museum"><figcaption>Actual Godot capture of the reconstructed study in ML_Classification. Three centres after repeated assignment and mean updates. Small dots remain observations; the black sphere controls the selected centre.</figcaption></figure>
<h2>One operation at a time</h2>
<table><tr><th>Action</th><th>What changes</th><th>What stays</th></tr>
<tr><td>ASSIGN</td><td>Each observation's centre index and colour</td><td>Observation and centre positions</td></tr>
<tr><td>MEAN</td><td>Each occupied centre moves to its group's mean</td><td>Observations and the last assignments</td></tr>
<tr><td>Grab the black sphere</td><td>Selected centre; previous assignments clear</td><td>Observations and other centres</td></tr>
<tr><td>CENTRE</td><td>Which centre the sphere controls</td><td>The same PointBody instance and model</td></tr>
<tr><td>K 2 / K 3 / K 4</td><td>Number and initial positions of centres</td><td>The observation dataset</td></tr>
<tr><td>DATA</td><td>Fixed blobs, rings or grid; centres restart</td><td>The chosen K</td></tr></table>
<figure><img src="assigned.png" alt="The first nearest-centre assignments shown before any mean update"><figcaption>The first ASSIGN, before centres move. The two separate buttons make the alternation available for prediction. The next-step readout prevents an unexplained repeat.</figcaption></figure>
<h2>What the tutorial now carries</h2>
<p>Two complete printed files replace partial K-means, SVM and neural-network snippets. The model groups fixed two-dimensional observations. The host maps those coordinates to a museum table, connects actual buttons and reads the carried PointBody in local coordinates. The museum launcher and XR/button infrastructure are declared separately.</p>
<p>From Gradient we keep observations, parameters, a measure and an update procedure distinct. Here there is no learning rate: nearest-centre assignment and the mean update alternate. The tutorial makes ties, empty groups, starting positions and chosen K explicit. A centre without members stays where it was; an exact tie goes to the lower index. More centres do not guarantee more occupied groups or a more useful description.</p>
<p>The <a href="https://scikit-learn.org/stable/modules/clustering.html#k-means">K-means squared-distance objective</a> is shown as current SSE. Source inspection found that the existing exhibit's Total Distance instead sums ordinary distances before moving its centres. The texts distinguish those readouts; the existing algorithm remains in place.</p>
<figure><img src="rings.png" alt="Two rings split by four centres into coloured groups on the museum table"><figcaption>Four centres on two rings. A geometrically precise assignment need not preserve the curved form a visitor follows with their eye. The next dataset is a regular grid with no planted blobs.</figcaption></figure>
<h2>Reflection and progression</h2>
<p>The reflection preserves the strongest question: why can a stationary point change groups? It now connects to Gradient, distinguishes clustering from learning supplied labels, and corrects an overconfident description of the SVM. The existing K-means, SVM and random forest remain supporting encounters. Colour identifies a centre index; it does not discover a diagnosis, personality or social identity.</p>
<h2>Ghost-student evidence</h2>
<p><strong>{count} native code assertions and {spatial} museum checks pass.</strong> The two new files were extracted from tutorial.md; the sphere class is carried unchanged from Gradient. This is author-informed exact-print reconstruction, not an independent blind reader.</p>
<p>Image inspection exposed a bug beyond the initial immediate checks: the frozen sphere could return to an old physics position after a mean update. The host now synchronizes the unheld sphere on physics ticks. A new delayed assertion verifies that its actual position still matches the selected centre after native frames have elapsed. The code and its explanation are printed in the tutorial.</p>
<ul><li>Independent midpoint fixture: assignments [0, 0, 1], SSE 0.64 before and 0.32 after the mean. Moving the middle observation changes the result as predicted.</li><li>Both phases keep SSE nonincreasing through twenty rounds for every combination of three datasets and K 2, 3 or 4.</li><li>Ties, empty groups, phase guards, repeatable starts and unchanged observations are checked.</li><li>Real button signals and the desktop grab adapter keep one PointBody; hand coordinates work under a translated and rotated host.</li><li>The native hall retains all three original exhibits and supplies clear floor and space for the reconstruction.</li></ul>
<figure><img src="hall.png" alt="Overhead view of Classification with original exhibits and the new lesson table"><figcaption>The supplied lesson launcher places the table beside the entrance exhibit, facing across the bay. An initial placement failed architecture and floor checks and was moved. The ordinary museum route and its artifacts are retained.</figcaption></figure>
<div class="card">Human headset reach and comfort remain untested. These checks use fixed synthetic observations and a desktop hand adapter. Existing engine diagnostics are retained in the report. Seven of eight ML lessons are reconstructed; Neural Networks remains before whole-sequence review.</div>
<p><a href="tests.json">Code assertions</a> · <a href="museum-tests.json">Museum checks</a> · <a href="reconstruction.json">Printed-code provenance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Diagnostics</a></p>
<h2>Try it in the museum</h2>
<p>Run <code>res://doc/book/studies/ml-classification/Classification.tscn</code>. ASSIGN and MEAN alternate. Choose CENTRE to move a different centre with the black sphere. Put it down before pressing controls. RESET repeats the chosen dataset and K; all model state is session-only. This preview mounts the learner's reconstruction in the real hall; it is not a standalone exported game.</p>
<p>Canonical texts: <code>commons/maps/ML_Classification/tutorial.md</code> and <code>final.md</code>. <a href="lineage.html">The editable route</a> records the handoff. Next: Neural Networks, where examples supply labels and fitted weights connect input to output.</p>'''
    (OUT / 'index.html').write_text(page('Classification / a group without a name', body), encoding='utf-8')
    sources = [ROOT / f'commons/maps/ML_Classification/{name}.md' for name in ['tutorial', 'final']]
    sources += [PLAN, ROOT / 'commons/maps/sequences/machinelearning.json',
                ROOT / 'tools/test_ml_classification_lesson.py', ROOT / 'tools/probes/ml_classification_lesson_test.gd',
                ROOT / 'tools/probes/ml_classification_lesson_museum.gd', Path(__file__).resolve()]
    for source in sorted((OUT / 'learner/printed').glob('*.gd')):
        assert source.read_text(encoding='utf-8') == (STUDY / source.name).read_text(encoding='utf-8'), source.name
        sources.append(STUDY / source.name)
    carried = ROOT / 'doc/book/studies/ml-gradient/point_body.gd'
    assert carried.read_text(encoding='utf-8') == (STUDY / 'point_body.gd').read_text(encoding='utf-8')
    sources += [carried, STUDY / 'Classification.tscn', STUDY / 'classification_museum.gd',
                ROOT / 'commons/maps/ML_Classification/map_data.json',
                ROOT / 'algorithms/machinelearning/kmeansclustering/enhanced_kmeans.gd',
                ROOT / 'algorithms/machinelearning/supportvectormachine/svm_visualization.gd',
                ROOT / 'algorithms/machinelearning/randomforest/random_forest_visualization.gd']
    register = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]
    (OUT / 'source-register.json').write_text(json.dumps(register, indent=2), encoding='utf-8')
    (OUT / 'README.md').write_text(f'''# Classification review

Read tutorial.md and final.md together. All new code is printed in two blocks. learner/printed contains those files and the unchanged PointBody carried from Gradient Landscape. The supplied launcher mounts the study inside the real museum; it does not permanently register a new ordinary-route artifact. This bundle requires AdaResearch with XR Tools and the named RackTemplates button factory. It is not a standalone Godot export.

Run res://doc/book/studies/ml-classification/Classification.tscn. ASSIGN and MEAN alternate. CENTRE chooses the centre controlled by the carried sphere. K changes centres; DATA changes fixed observations; RESET repeats the selected start. Hand editing clears assignments. All state is session-only. Existing exhibits remain.

Reconstruct: python tools/test_ml_classification_lesson.py

Museum: python tools/run_encounter_probe.py ML_Classification --sequence machinelearning --render --no-bridges --output-tag classification_lesson --probe tools/probes/ml_classification_lesson_museum.gd

Publish: python tools/publish_ml_classification_lesson.py

{count} native assertions and {spatial} museum checks pass. Author-informed exact-print reconstruction, not a blind agent. Synthetic data and supplied desktop hand adapter; human VR comfort untested. Existing engine diagnostics retained. Seven ML halls reconstructed; Neural Networks remains before whole-sequence review.
''', encoding='utf-8')
    names = ['README.md', 'tutorial.md', 'final.md', PLAN.name, 'tests.json', 'museum-tests.json',
             'museum-diagnostics.json', 'reconstruction.json', 'source-register.json',
             'index.html', 'parallel.html', 'tutorial.html', 'final.html', 'changes.html', 'lineage.html']
    names += [f'{name}.png' for name in PICTURES]
    with zipfile.ZipFile(OUT / 'classification-review.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for name in names: z.write(OUT / name, name)
        for p in sorted((OUT / 'learner/printed').glob('*.gd')): z.write(p, 'learner/printed/' + p.name)
        for name in ['Classification.tscn', 'classification_museum.gd']: z.write(STUDY / name, 'supplied-museum/' + name)
    print(f'Published {count}+{spatial} checks: {OUT}')


if __name__ == '__main__':
    main()
