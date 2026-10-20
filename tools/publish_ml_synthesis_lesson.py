"""Publish Synthesis's canonical texts and exact-print/native museum evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile
import markdown
from publish_ml_pose_lesson import page

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-synthesis-an-intention-kept'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Synthesis/synthesis_lesson'
STUDY = ROOT / 'doc/book/studies/ml-lineage'
CARRIED = [
    ('ML_Perception', 'carried-perception', '2026-10-11-perception-teach-a-sphere'),
    ('ML_Sequence_Memory', 'carried-memory', '2026-10-11-memory-both-hands'),
    ('ML_Generative', 'carried-generative', '2026-10-11-generative-a-phrase-varied'),
]


def md(text):
    for chapter, filename, _ in CARRIED:
        text = text.replace(f'../{chapter}/tutorial.md', filename + '.html')
    return markdown.markdown(text, extensions=['fenced_code', 'tables'])


def main():
    tests = json.loads((OUT / 'tests.json').read_text(encoding='utf-8'))
    museum = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
    assert tests['passed'] and museum['passed'] and not tests['failures'] and not museum['failures']
    log = (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log
    for name in ['empty', 'hall', 'checks', 'revision']:
        shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
    shutil.copy2(RUN / 'report.json', OUT / 'museum-tests.json')
    (OUT / 'museum-diagnostics.json').write_text(json.dumps(
        [x for x in log.splitlines() if x.startswith(('ERROR:', 'WARNING:'))], indent=2), encoding='utf-8')

    texts = {}
    for name in ['tutorial', 'final']:
        source = ROOT / f'commons/maps/ML_Synthesis/{name}.md'
        texts[name] = source.read_text(encoding='utf-8')
        shutil.copy2(source, OUT / f'{name}.md')
        (OUT / f'{name}.html').write_text(page('Synthesis / ' + name, md(texts[name])), encoding='utf-8')
    (OUT / 'parallel.html').write_text(page('An intention and an answer',
        '<p>Complete tutorial on the left; reflective encounter on the right.</p><div class="pair"><article>'
        + md(texts['tutorial']) + '</article><article>' + md(texts['final']) + '</article></div>', True), encoding='utf-8')
    changes = '<h1>One model.<br>Two accounts.</h1>'
    for name in ['tutorial', 'final']:
        changes += '<h2>' + html.escape(name) + '</h2><div class="pair"><article><h3>Before</h3>'
        changes += md((OUT / f'before/{name}.md').read_text(encoding='utf-8'))
        changes += '</article><article><h3>Now</h3>' + md(texts[name]) + '</article></div>'
    (OUT / 'changes.html').write_text(page('Synthesis / before and after', changes, True), encoding='utf-8')

    plan = ROOT / 'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'
    shutil.copy2(plan, OUT / 'ML-SPHERE-LINEAGE.md')
    (OUT / 'lineage.html').write_text(page('The sphere through four lessons',
        md(plan.read_text(encoding='utf-8')) + '<p class="note">Published snapshot. Edit doc/book/course/storyboards/ML-SPHERE-LINEAGE.md.</p>'), encoding='utf-8')
    for chapter, filename, _ in CARRIED:
        source = ROOT / f'commons/maps/{chapter}/tutorial.md'
        shutil.copy2(source, OUT / f'{filename}.md')
        (OUT / f'{filename}.html').write_text(page(chapter + ' / carried tutorial', md(source.read_text(encoding='utf-8'))), encoding='utf-8')

    count, spatial = len(tests['checks']), len(museum['checks'])
    body = f'''<h1>What I meant.<br>What it answered.</h1>
<p class="lead">Synthesis keeps the same sphere, both hands and the trained A/B phrase model. Before a fresh performance, declare an intention. Keep the model's answer beside it.</p>
<div class="route"><span>Perception / a pose</span><span>Memory / an ordered phrase</span><span>Generative / another possibility</span><span class="active">Synthesis / an intention and an answer</span></div>
<p><a href="parallel.html">Read the facing texts</a> · <a href="changes.html">Before and after</a> · <a href="synthesis-review.zip">Download for review</a></p>
<figure><img src="checks.png" alt="Same dark point sphere, nearby buttons and a table of declared intentions against model answers in the actual Synthesis hall"><figcaption>Actual Godot museum capture. Four explicitly synthetic checks include a mismatch: MEANT B, answered A. The sphere stays still in CHECK. These are demonstration counts, not visitor results.</figcaption></figure>
<h2>What the lesson adds</h2>
<table><tr><th>Carry</th><th>Add</th></tr><tr><td>PointBody, pickup, both hands, four seconds and the beat</td><td>A declaration made before capture</td></tr><tr><td>The trained A/B library from Sequence Memory</td><td>A/B/UNKNOWN/AMBIGUOUS outcomes kept separately</td></tr><tr><td>Deliberate teaching and fitting</td><td>Checks grouped by model snapshot, retained across revisions</td></tr></table>
<p>The tutorial adds two complete files to the eight already printed. It returns to Sequence Memory's classifier; generated output stays outside teaching. The journal calls prediction with movement alone, then joins the answer to the declared intention. Tests never fit the model.</p>
<p>The reflection starts from disagreement without deciding its cause in advance. It then compares the hall's anomaly rule and the creature's reward: different operations ask different questions. The earlier anomaly passage is retained and made exact about its reference population, threshold and hand-written alternative mode.</p>
<figure><img src="revision.png" alt="The same study after fitting revised teaching, showing zero checks for the new model and four retained earlier checks"><figcaption>After revising the teaching: zero checks for this model, four kept under the previous model. Changing the model does not erase its history.</figcaption></figure>
<h2>Ghost-student evidence</h2>
<p><strong>{count} native Godot assertions and {spatial} museum checks pass.</strong> Ten files are extracted directly from the printed chapters into a separate learner folder. This is author-informed reconstruction, not a blind independent student.</p>
<ul><li>Changing the declared intention leaves prediction unchanged for the same take and model.</li><li>Exact teaching takes and duplicate same-model checks cannot inflate the table.</li><li>Unknown, ambiguous, mismatch and agreement occupy separate cells.</li><li>Full takes, model snapshots and numerical results survive export; refitting preserves earlier checks.</li><li>Real control signals and supplied XR tracking exercise capture, interruption, model locking, import, save, load, export and clearing.</li></ul>
<p>The native room pass found that the lowest button overlapped the standing area. The panel now sits back and to the left, leaving the sphere visible. The first room probe also stopped at architecture readiness, before all exhibits loaded; it now drains the real deferred loading queue before checking their presence. No exhibit was removed.</p>
<figure><img src="hall.png" alt="Overhead view of the existing Synthesis hall, its raised layout and retained learning exhibits"><figcaption>The existing hall remains. The printed study is mounted through the supplied lesson launcher. Its sampled floor and standing-capsule checks pass; the wider hall still has large overlapping exhibit footprints and deserves a separate spatial review.</figcaption></figure>
<div class="card">Human headset reach, comfort and recognition quality remain untested. Existing audio UID, Jolt, registry and renderer diagnostics are retained. The deliberately malformed-load test also produces an expected JSON error. The earlier four ML tutorials still need reconstruction before whole-sequence review.</div>
<p><a href="tests.json">Code assertions</a> · <a href="museum-tests.json">Museum checks</a> · <a href="reconstruction.json">Printed-code provenance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Museum diagnostics</a></p>
<h2>Try it</h2>
<p>Run <code>res://doc/book/studies/ml-lineage/Synthesis.tscn</code> in Ada. IMPORT the A/B file saved in Memory, or teach three performances per label here and TRAIN. Choose CHECK, MEANT A / MEANT B / OTHER, then CAPTURE. EXPORT preserves the session; SAVE writes this lesson's model revision separately.</p>
<p>Canonical texts are <code>commons/maps/ML_Synthesis/tutorial.md</code> and <code>final.md</code>. <a href="lineage.html">The editable route</a> now connects all four sphere lessons. Foundations Crisis follows this hall; before moving on, the earlier ML lessons need the same reconstruction standard.</p>'''
    (OUT / 'index.html').write_text(page('Synthesis / an intention kept', body), encoding='utf-8')

    sources = [ROOT / f'commons/maps/{chapter}/tutorial.md' for chapter, _, _ in CARRIED]
    sources += [ROOT / 'commons/maps/ML_Synthesis/tutorial.md', ROOT / 'commons/maps/ML_Synthesis/final.md', plan,
                ROOT / 'commons/maps/sequences/machinelearning.json',
                ROOT / 'tools/probes/ml_synthesis_lesson_test.gd', ROOT / 'tools/probes/ml_synthesis_lesson_museum.gd',
                ROOT / 'tools/test_ml_synthesis_lesson.py', Path(__file__).resolve()]
    for source in (OUT / 'learner/printed').glob('*.gd'):
        # Windows checkout line endings may differ; executable text must match.
        assert source.read_text(encoding='utf-8') == (STUDY / source.name).read_text(encoding='utf-8'), source.name
        sources.append(STUDY / source.name)
    sources += [STUDY / 'Synthesis.tscn', STUDY / 'synthesis_museum.gd']
    sources += [ROOT / 'algorithms/machinelearning/anomaly_detection/AnomalyDetection.gd',
                ROOT / 'algorithms/machinelearning/reinforcementlearning/joint_learn_walk.gd']
    register = [{'path': p.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sources]
    (OUT / 'source-register.json').write_text(json.dumps(register, indent=2), encoding='utf-8')
    (OUT / 'README.md').write_text('''# Synthesis review

Read tutorial.md and final.md together. The three carried tutorials contain the prior code; all ten extracted files are in learner/printed. Two supplied launcher files are included separately. This is a review bundle, not a standalone Godot export: run inside AdaResearch with its declared XR Tools and museum infrastructure.

Run res://doc/book/studies/ml-lineage/Synthesis.tscn. IMPORT reads the A/B save from Memory; SAVE writes a separate Synthesis model. EXPORT overwrites the local checks journal. No visitor saves were touched by the test fixtures.

Reproduce: python tools/test_ml_synthesis_lesson.py

Museum: python tools/run_encounter_probe.py ML_Synthesis --sequence machinelearning --render --no-bridges --output-tag synthesis_lesson --probe tools/probes/ml_synthesis_lesson_museum.gd

Publish: python tools/publish_ml_synthesis_lesson.py

51 native code assertions and 17 museum checks passed. Author-informed exact-print reconstruction using synthetic movement, including supplied XR trackers. Human headset use and recognition quality untested. A malformed JSON negative test is intentional; existing engine diagnostics are retained. Earlier four ML tutorials remain unfinished. Assess continuity, clarity and technical claims with these limits in view.
''', encoding='utf-8')
    names = ['README.md', 'tutorial.md', 'final.md', 'carried-perception.md', 'carried-memory.md', 'carried-generative.md',
             'ML-SPHERE-LINEAGE.md', 'tests.json', 'museum-tests.json', 'museum-diagnostics.json', 'reconstruction.json',
             'source-register.json', 'empty.png', 'checks.png', 'revision.png', 'hall.png']
    with zipfile.ZipFile(OUT / 'synthesis-review.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for name in names:
            z.write(OUT / name, name)
        for p in sorted((OUT / 'learner/printed').glob('*.gd')):
            z.write(p, 'learner/printed/' + p.name)
        for name in ['Synthesis.tscn', 'synthesis_museum.gd']:
            z.write(STUDY / name, 'supplied-museum/' + name)
    print(f'Published {count}+{spatial} checks: {OUT}')


if __name__ == '__main__':
    main()
