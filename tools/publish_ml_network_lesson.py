"""Publish Neural Networks' canonical texts and verified museum reconstruction."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile
import markdown
from publish_ml_pose_lesson import page

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-networks-what-a-weight-keeps'
STUDY = ROOT / 'doc/book/studies/ml-network'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Neural_Networks/network_lesson'
PLAN = ROOT / 'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'
PICTURES = ['opening', 'hall', 'fitted', 'probe', 'flipped']


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
        source = ROOT / f'commons/maps/ML_Neural_Networks/{name}.md'
        texts[name] = source.read_text(encoding='utf-8')
        shutil.copy2(source, OUT / f'{name}.md')
        (OUT / f'{name}.html').write_text(page('Neural Networks / ' + name, md(texts[name])), encoding='utf-8')
    (OUT / 'parallel.html').write_text(page('What a weight keeps',
        '<p>Complete tutorial on the left; reflective encounter on the right.</p><div class="pair"><article>'
        + md(texts['tutorial']) + '</article><article>' + md(texts['final']) + '</article></div>', True), encoding='utf-8')
    changes = '<h1>Move the input.<br>Then change the weights.</h1>'
    for name in ['tutorial', 'final']:
        changes += '<h2>' + name + '</h2><div class="pair"><article><h3>Before</h3>'
        changes += md((OUT / f'before/{name}.md').read_text(encoding='utf-8'))
        changes += '</article><article><h3>Now</h3>' + md(texts[name]) + '</article></div>'
    (OUT / 'changes.html').write_text(page('Neural Networks / before and after', changes, True), encoding='utf-8')
    shutil.copy2(PLAN, OUT / PLAN.name)
    (OUT / 'lineage.html').write_text(page('Machine Learning / editable route', md(PLAN.read_text(encoding='utf-8'))
        + '<p class="note">Published snapshot. Edit doc/book/course/storyboards/ML-SPHERE-LINEAGE.md.</p>'), encoding='utf-8')
    body = f'''<h1>What a weight keeps.</h1>
<p class="lead">The same sphere selects an input. Moving it changes activations; STEP changes the thirteen parameters that shape later answers.</p>
<div class="route"><span>Gradient / objective</span><span>Classification / grouping</span><span class="active">Networks / learned weights</span><span>Perception / both hands</span></div>
<p><a href="parallel.html">Read the facing texts</a> · <a href="changes.html">Before and after</a> · <a href="networks-review.zip">Download for review</a></p>
<figure><img src="fitted.png" alt="The black sphere on a labelled input table beside a small pink and turquoise network inside Endless Museum"><figcaption>Actual Godot capture. The printed 2→3→1 network after 1000 updates. The sphere selects the lower-left input; the output score is low for its supplied label 0.</figcaption></figure>
<h2>Two actions that must stay distinct</h2>
<table><tr><th>Action</th><th>What changes</th><th>What stays</th></tr>
<tr><td>Grab sphere / EXAMPLE</td><td>Input, activations, output</td><td>Weights and training examples</td></tr>
<tr><td>STEP</td><td>One full-batch parameter update</td><td>Input position and supplied labels</td></tr>
<tr><td>TRAIN</td><td>Ten updates per rendered frame, capped at 1000</td><td>The mathematical learning rate</td></tr>
<tr><td>CHECK</td><td>Measurement on four separate positions</td><td>Training data and fitted weights</td></tr>
<tr><td>FLIP</td><td>Target convention reverses; weights restart</td><td>Input coordinates and initial parameter values</td></tr>
<tr><td>RESET</td><td>Initial weights return</td><td>Chosen labels and probe position</td></tr></table>
<h2>What needed fixing</h2>
<p>The former tutorial printed a backward pass without the activation derivatives. It has been replaced by two complete files: a small network and its museum view. The learner includes weighted sums, biases, tanh, sigmoid, stable binary cross-entropy and the chain rule. Every gradient is accumulated before any parameter changes. The tutorial derives the steps and gives independent numerical predictions.</p>
<p>Source inspection found a separate issue in the existing large exhibit: its four inputs already contain its two target answers, reversed, in the last two channels. Real weight updates there do not establish that the network learned the intended two-input exclusive-or problem. The new reconstruction uses only the two coordinates. The exhibit remains, and both texts explain the limitation.</p>
<p>The first reconstructed start fitted the original labels but stalled when they were reversed. We selected another fixed, asymmetric start and checked both conventions. This is an explicit development choice, not evidence that gradient descent always succeeds. The four separate check positions informed development and are not presented as an untouched test set.</p>
<figure><img src="probe.png" alt="The same sphere at a different labelled position while the fitted network gives a high output score"><figcaption>EXAMPLE moves the sphere to another input. The weights remain exactly the same. The new input gives different hidden activations and a high class-1 score.</figcaption></figure>
<h2>The reflective text</h2>
<p>The reflection keeps its question about where learning resides. It now distinguishes a temporary activation from a retained parameter, then asks what information reached the model and who supplied the targets. It also corrects the description of the original exhibit's controls: desktop restart exists, even though there is no nearby spatial restart button.</p>
<p>From Classification we bring the distinction between observations and model state. Here the sphere changes an input rather than a centre. Perception next expands the same weighted calculation to six hand coordinates and three labels. It prints its complete larger model; this lesson does not introduce an unprinted helper.</p>
<figure><img src="flipped.png" alt="The network fitted to reversed labels on the same four positions"><figcaption>FLIP, reset, fit again. The same coordinate data now support the opposite supplied answers. All four fixed check cases match this changed convention.</figcaption></figure>
<h2>Ghost-student evidence</h2>
<p><strong>{count} native code assertions and {spatial} museum checks pass.</strong> The new scripts were extracted from tutorial.md; PointBody is carried unchanged from Classification. This is author-informed exact-print reconstruction, not a blind independent reader.</p>
<ul><li>All thirteen analytical derivatives match central differences across eighteen input/target/parameter cases.</li><li>An independent forward calculation and a numerical full-batch update agree with the printed learner.</li><li>1000 updates yield training loss approximately 0.00504 and separate-check loss approximately 0.00740, with four correct checks on the original convention.</li><li>Reversed labels and a separately changed corner label are fitted; large positive and negative logits remain finite.</li><li>Actual spatial-button signals and the desktop grab adapter retain one sphere. Input decoding survives translation and rotation; delayed physics checks cover release and EXAMPLE.</li><li>The native museum has checked furniture clearance, standing floor and space. Five captures are visually reviewed evidence, not headset testing.</li></ul>
<figure><img src="hall.png" alt="Overhead view of the actual Neural Networks hall and its existing large diagrams"><figcaption>The lesson sits in a checked side bay. The two existing network displays remain. Their large diagrams still extend beyond parts of the hall; this pass does not claim a complete spatial redesign. Fine Tuning appears in the source map but was not present in this isolated render, so it is not counted as verified.</figcaption></figure>
<div class="card">All eight ML halls now have individual reconstruction evidence. Whole-sequence review and human VR reach/comfort testing remain. Existing engine UID and Jolt diagnostics are retained; no script error occurred in the successful runs.</div>
<p><a href="tests.json">Code assertions</a> · <a href="museum-tests.json">Museum checks</a> · <a href="reconstruction.json">Printed-code provenance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Diagnostics</a></p>
<h2>Try it in the museum</h2>
<p>Run <code>res://doc/book/studies/ml-network/Network.tscn</code>. Move the sphere to query; put it down to use STEP, TRAIN, RESET, EXAMPLE, CHECK and FLIP. The supplied launcher opens the actual hall and mounts the learner. State is session-only; this preview requires the Ada project and is not a standalone game export.</p>
<p>Canonical texts: <code>commons/maps/ML_Neural_Networks/tutorial.md</code> and <code>final.md</code>. <a href="lineage.html">The editable route</a> records the handoff. Next: review all eight halls together, including inherited code and transitions.</p>'''
    (OUT / 'index.html').write_text(page('Neural Networks / what a weight keeps', body), encoding='utf-8')
    sources = [ROOT / f'commons/maps/ML_Neural_Networks/{name}.md' for name in ['tutorial', 'final']]
    sources += [PLAN, ROOT / 'commons/maps/sequences/machinelearning.json',
                ROOT / 'tools/test_ml_network_lesson.py', ROOT / 'tools/probes/ml_network_lesson_test.gd',
                ROOT / 'tools/probes/ml_network_lesson_museum.gd', Path(__file__).resolve()]
    for source in sorted((OUT / 'learner/printed').glob('*.gd')):
        assert source.read_text(encoding='utf-8') == (STUDY / source.name).read_text(encoding='utf-8'), source.name
        sources.append(STUDY / source.name)
    carried = ROOT / 'doc/book/studies/ml-classification/point_body.gd'
    assert carried.read_text(encoding='utf-8') == (STUDY / 'point_body.gd').read_text(encoding='utf-8')
    sources += [carried, STUDY / 'Network.tscn', STUDY / 'network_museum.gd',
                ROOT / 'commons/maps/ML_Neural_Networks/map_data.json',
                ROOT / 'algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.gd',
                ROOT / 'algorithms/machinelearning/neural_networks/NeuralNetworks_VR.gd']
    register = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]
    (OUT / 'source-register.json').write_text(json.dumps(register, indent=2), encoding='utf-8')
    (OUT / 'README.md').write_text(f'''# Neural Networks review

Read tutorial.md and final.md together. All new code is printed in two blocks. learner/printed contains those files and the unchanged PointBody carried from Classification. The supplied launcher mounts the study inside the real museum; it does not permanently register a new ordinary-route artifact. This bundle requires AdaResearch, XR Tools and the named RackTemplates button factory. It is not a standalone Godot export.

Run res://doc/book/studies/ml-network/Network.tscn. Move the sphere to query the network; STEP or TRAIN changes weights. Put it down before using controls. EXAMPLE selects an input; CHECK uses separate development cases; FLIP reverses labels and resets; RESET repeats parameters with the current labels. All state is session-only.

Reconstruct: python tools/test_ml_network_lesson.py

Museum: python tools/run_encounter_probe.py ML_Neural_Networks --sequence machinelearning --render --no-bridges --output-tag network_lesson --probe tools/probes/ml_network_lesson_museum.gd

Publish: python tools/publish_ml_network_lesson.py

{count} native assertions and {spatial} museum checks pass. Author-informed exact-print reconstruction, not a blind agent. Synthetic data and supplied desktop hand adapter; human VR comfort untested. Starting parameters were selected after a flipped-label failure, using fixed development cases. Existing engine diagnostics retained. All eight ML halls individually reconstructed; whole-route review remains.
''', encoding='utf-8')
    names = ['README.md', 'tutorial.md', 'final.md', PLAN.name, 'tests.json', 'museum-tests.json',
             'museum-diagnostics.json', 'reconstruction.json', 'source-register.json',
             'index.html', 'parallel.html', 'tutorial.html', 'final.html', 'changes.html', 'lineage.html']
    names += [f'{name}.png' for name in PICTURES]
    names += ['before/tutorial.md', 'before/final.md']
    with zipfile.ZipFile(OUT / 'networks-review.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for name in names: z.write(OUT / name, name)
        for p in sorted((OUT / 'learner/printed').glob('*.gd')): z.write(p, 'learner/printed/' + p.name)
        for name in ['Network.tscn', 'network_museum.gd']: z.write(STUDY / name, 'supplied-museum/' + name)
    print(f'Published {count}+{spatial} checks: {OUT}')


if __name__ == '__main__':
    main()
