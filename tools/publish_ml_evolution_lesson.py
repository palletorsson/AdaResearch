"""Publish Evolution's canonical pair, exact-print evidence and native captures."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile
import markdown
from publish_ml_pose_lesson import page

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-evolution-what-keeps-a-body'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Evolution/evolution_lesson'
STUDY = ROOT / 'doc/book/studies/ml-environment'
PLAN = ROOT / 'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'
ARCHIVE = ROOT / 'doc/book/iterations/claude-machinelearning-noc-reading-2026-09-25/probe_novelty_finite.json'


def md(text):
    text = text.replace('/book-images/figures/machinelearning/fresh-ground-runs-out.png', 'fresh-ground-runs-out.png')
    return markdown.markdown(text, extensions=['fenced_code', 'tables', 'footnotes'])


def main():
    tests = json.loads((OUT / 'tests.json').read_text(encoding='utf-8'))
    museum = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
    assert tests['passed'] and museum['passed'] and not tests['failures'] and not museum['failures']
    log = (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log
    for name in ['opening', 'hall', 'finite', 'return']:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    (OUT / 'museum-diagnostics.json').write_text(json.dumps(
        [line for line in log.splitlines() if line.startswith(('ERROR:', 'WARNING:'))], indent=2), encoding='utf-8')
    shutil.copy2(ROOT / 'doc/book/figures/machinelearning/fresh-ground-runs-out.png', OUT / 'fresh-ground-runs-out.png')
    shutil.copy2(ARCHIVE, OUT / 'archived-novelty-test.json')
    texts = {}
    for name in ['tutorial', 'final']:
        source = ROOT / f'commons/maps/ML_Evolution/{name}.md'
        texts[name] = source.read_text(encoding='utf-8')
        shutil.copy2(source, OUT / f'{name}.md')
        (OUT / f'{name}.html').write_text(page('Evolution / ' + name, md(texts[name])), encoding='utf-8')
    (OUT / 'parallel.html').write_text(page('What keeps a body here?',
        '<p>Complete tutorial on the left; reflective encounter on the right.</p><div class="pair"><article>'
        + md(texts['tutorial']) + '</article><article>' + md(texts['final']) + '</article></div>', True), encoding='utf-8')
    changes = '<h1>A condition.<br>A consequence.</h1>'
    for name in ['tutorial', 'final']:
        changes += '<h2>' + html.escape(name) + '</h2><div class="pair"><article><h3>Before</h3>'
        changes += md((OUT / f'before/{name}.md').read_text(encoding='utf-8'))
        changes += '</article><article><h3>Now</h3>' + md(texts[name]) + '</article></div>'
    (OUT / 'changes.html').write_text(page('Evolution / before and after', changes, True), encoding='utf-8')
    shutil.copy2(PLAN, OUT / PLAN.name)
    (OUT / 'lineage.html').write_text(page('Machine Learning / editable route',
        md(PLAN.read_text(encoding='utf-8')) + '<p class="note">Published snapshot. Edit doc/book/course/storyboards/ML-SPHERE-LINEAGE.md.</p>'), encoding='utf-8')
    count, spatial = len(tests['checks']), len(museum['checks'])
    comparison = museum['observations']['thirty_seconds']
    last = tests['evidence']['seed_17_comparison'][-1]
    body = f'''<h1>What keeps<br>a body here?</h1>
<p class="lead">Evolution returns to the sphere as a control. The new object is a small population table: bodies move, eat, split their energy with offspring and disappear when energy runs out.</p>
<div class="route"><span class="active">Evolution / conditions select</span><span>Gradient / an objective</span><span>Classification / a grouping</span><span>Networks / learned weights</span></div>
<p><a href="parallel.html">Read the facing texts</a> · <a href="changes.html">Before and after</a> · <a href="evolution-review.zip">Review ZIP</a></p>
<figure><img src="return.png" alt="Coloured population spheres on a resource grid, with the carried dark PointBody and six controls in the Evolution museum hall"><figcaption>Actual Godot capture. The tutorial study is mounted in the existing Evolution hall by its supplied lesson launcher. Colour records family; it does not score fitness.</figcaption></figure>
<h2>One opening. Two conditions.</h2>
<table><tr><th>Same seed 17</th><th>FINITE</th><th>RETURN</th></tr>
<tr><td>Opening</td><td>12 bodies, 64 meals</td><td>The same bodies and meals</td></tr>
<tr><td>After eating</td><td>Cell stays empty</td><td>Food regrows after 4 simulated seconds</td></tr>
<tr><td>Alive at 30 simulated seconds</td><td>{comparison['finite_alive']}</td><td>{comparison['return_alive']}</td></tr>
<tr><td>Alive at 120 simulated seconds</td><td>{last['finite_alive']}</td><td>{last['return_alive']}</td></tr></table>
<p>These are two seeded simulations, not a general law about every environment. The birth histories diverge, so later random draws need not stay paired. No body is ranked. The food rule still selects who can continue. Birth divides existing energy; inherited speed changes without knowing whether the change will help.</p>
<figure><img src="finite.png" alt="One surviving population body after thirty simulated seconds with finite food"><figcaption>FINITE at the same thirty-second mark. The original handheld sphere remains at the control position; it is separate from the population being counted.</figcaption></figure>
<h2>What changed in the writing</h2>
<p>The earlier tutorial sketched a ranked genetic algorithm with missing implementation. The replacement reconstructs the environmental selection described by the reflection, in two complete files. PointBody is carried unchanged from Graph Theory; the museum, XR rig and button factory are declared infrastructure. The fixed simulation step and four-second regrowth are explicit tutorial choices.</p>
<p>The reflection keeps survival and inheritance at its centre. It now distinguishes a live process from the exhibit's authored, frozen arrangements; corrects the scored creature's current twenty-second generation; and dates the earlier extinction graph. The graph records a September run of the old artifact, whose regrowth depends on rendered frames. It is not the result of this new table.</p>
<p>The historical passage names the visitor sensors in <a href="https://www.karlsims.com/galapagos/">Karl Sims's Galápagos</a>. It asks how a visitor's choice and an authored scoring rule preserve different things.</p>
<h2>Ghost-student evidence</h2>
<p><strong>{count} native Godot assertions and {spatial} museum checks pass.</strong> The two new files were extracted from the printed tutorial, together with the declared carried PointBody. This is author-informed reconstruction, not a blind independent student.</p>
<ul><li>A meal has one recipient; reversing competing records changes that recipient.</li><li>Birth conserves the parent's remaining energy, preserves family and records ancestry separately from total births.</li><li>A cell cannot regrow early. A body already there can eat when it does.</li><li>Same seed and condition repeat; population accounting and movement bounds survive a long run.</li><li>Real control signals operate step, reset, conditions and seed while keeping the same handheld point.</li></ul>
<p>The museum check retains the existing drift, scored creatures and flowers. Image inspection caught a hidden row of controls and a table intersecting a doorway. The panel and placement were revised, and the native check now includes the table footprint as well as the standing area.</p>
<figure><img src="hall.png" alt="Overhead capture of the existing Evolution hall and its retained exhibits"><figcaption>Existing museum context. This is a tested lesson placement, not a complete room redesign: large legacy exhibit footprints still extend beyond their intended spaces.</figcaption></figure>
<div class="card">Human headset reach and comfort remain untested. Existing audio UID, Jolt, registry, renderer and exit diagnostics are retained. No museum exhibit was removed. Gradient Landscape, Classification and Neural Networks still need complete reconstruction before whole-sequence review.</div>
<p><a href="tests.json">Code assertions</a> · <a href="museum-tests.json">Museum checks</a> · <a href="reconstruction.json">Printed-code provenance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Diagnostics</a> · <a href="archived-novelty-test.json">September evidence</a></p>
<h2>Try it in the museum</h2>
<p>Run <code>res://doc/book/studies/ml-environment/Evolution.tscn</code> in Ada. Choose FINITE, RUN, then repeat with RETURN and the same seed. The familiar sphere's trigger toggles run/pause. STEP advances one thirtieth of a second. NEXT SEED changes the opening. The population is session-only; this lesson writes no population save.</p>
<p><a href="lineage.html">The editable route</a> now connects five reconstructed ML lessons. Next: Gradient Landscape, where an explicit objective replaces environmental persistence as the question.</p>'''
    (OUT / 'index.html').write_text(page('Evolution / what keeps a body', body), encoding='utf-8')
    sources = [ROOT / f'commons/maps/ML_Evolution/{name}.md' for name in ['tutorial', 'final']]
    sources += [PLAN, ROOT / 'commons/maps/sequences/machinelearning.json',
                ROOT / 'tools/probes/ml_evolution_lesson_test.gd', ROOT / 'tools/probes/ml_evolution_lesson_museum.gd',
                ROOT / 'tools/test_ml_evolution_lesson.py', Path(__file__).resolve(), ARCHIVE]
    for source in sorted((OUT / 'learner/printed').glob('*.gd')):
        assert source.read_text(encoding='utf-8') == (STUDY / source.name).read_text(encoding='utf-8'), source.name
        sources.append(STUDY / source.name)
    carried = ROOT / 'doc/book/studies/graphs-through-the-hands/GT_Matching/point_body.gd'
    assert carried.read_text(encoding='utf-8') == (STUDY / 'point_body.gd').read_text(encoding='utf-8')
    sources += [carried, STUDY / 'Evolution.tscn', STUDY / 'evolution_museum.gd',
                ROOT / 'algorithms/machinelearning/non_teleological_evolution/non_teleological_evolution.gd',
                ROOT / 'algorithms/machinelearning/carlsims/evolvedcreatures.gd',
                ROOT / 'algorithms/machinelearning/evolvingflowers/evolvingflowers.gd']
    register = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]
    (OUT / 'source-register.json').write_text(json.dumps(register, indent=2), encoding='utf-8')
    (OUT / 'README.md').write_text(f'''# Evolution review

Read tutorial.md and final.md together. The three files in learner/printed are the two complete new code blocks and PointBody carried unchanged from Graph Theory. Supplied launcher files mount the study inside the actual museum. This is a review bundle, not a standalone Godot export: it requires AdaResearch, its XR Tools and named button factory.

Run res://doc/book/studies/ml-environment/Evolution.tscn. The population starts paused. RUN or the held sphere trigger starts it; STEP advances one tick. Compare FINITE and RETURN with the same opening seed. The old exhibits remain. This does not permanently register another artifact in the ordinary museum route.

Reconstruct: python tools/test_ml_evolution_lesson.py

Museum: python tools/run_encounter_probe.py ML_Evolution --sequence machinelearning --render --no-bridges --output-tag evolution_lesson --probe tools/probes/ml_evolution_lesson_museum.gd

Publish: python tools/publish_ml_evolution_lesson.py

{count} native code assertions and {spatial} museum checks pass. Author-informed exact-print reconstruction, synthetic population runs and supplied controls. Human VR comfort untested. Existing engine diagnostics retained. The September chart and archived-novelty-test.json are earlier evidence of a different configuration, not this table. Rendered HTML uses a local chart; canonical final.md retains the project's /book-images route.

Five ML halls now reconstructed. Gradient Landscape, Classification and Neural Networks remain before whole-sequence review. Assess continuity, explanations and actual code with those limits in view.
''', encoding='utf-8')
    names = ['README.md', 'tutorial.md', 'final.md', PLAN.name, 'tests.json', 'museum-tests.json',
             'museum-diagnostics.json', 'reconstruction.json', 'source-register.json',
             'opening.png', 'finite.png', 'return.png', 'hall.png', 'fresh-ground-runs-out.png', 'archived-novelty-test.json']
    names += ['index.html', 'parallel.html', 'tutorial.html', 'final.html', 'changes.html', 'lineage.html']
    with zipfile.ZipFile(OUT / 'evolution-review.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for name in names:
            z.write(OUT / name, name)
        for p in sorted((OUT / 'learner/printed').glob('*.gd')):
            z.write(p, 'learner/printed/' + p.name)
        for name in ['Evolution.tscn', 'evolution_museum.gd']:
            z.write(STUDY / name, 'supplied-museum/' + name)
    print(f'Published {count}+{spatial} checks: {OUT}')


if __name__ == '__main__':
    main()
