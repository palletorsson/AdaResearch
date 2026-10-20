"""Publish the canonical Generative lesson, facing text and native reconstruction evidence."""
from pathlib import Path
import hashlib, html, json, shutil, zipfile
import markdown
from publish_ml_pose_lesson import page

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-generative-a-phrase-varied'
RUN = ROOT / 'ada_run/encounter_pilot/ML_Generative/generative_lesson'
STUDY = ROOT / 'doc/book/studies/ml-lineage'

def md(text):
    for chapter, report in [('ML_Perception', '2026-10-11-perception-teach-a-sphere'), ('ML_Sequence_Memory', '2026-10-11-memory-both-hands')]:
        text = text.replace(f'../{chapter}/tutorial.md', f'../{report}/tutorial.html')
    return markdown.markdown(text, extensions=['fenced_code', 'tables'])

def main():
    tests = json.loads((OUT/'tests.json').read_text(encoding='utf-8'))
    museum = json.loads((RUN/'report.json').read_text(encoding='utf-8'))
    assert tests['passed'] and museum['passed'] and not tests['failures'] and not museum['failures']
    log = (RUN/'stdout.log').read_text(encoding='utf-8', errors='replace')
    assert 'SCRIPT ERROR' not in log
    for name in ['empty', 'hall', 'mean', 'generated']:
        shutil.copy2(RUN/f'{name}.png', OUT/f'{name}.png')
    shutil.copy2(RUN/'report.json', OUT/'museum-tests.json')
    (OUT/'museum-diagnostics.json').write_text(json.dumps([x for x in log.splitlines() if x.startswith(('ERROR:', 'WARNING:'))], indent=2), encoding='utf-8')
    texts = {}
    for name in ['tutorial', 'final']:
        source = ROOT/f'commons/maps/ML_Generative/{name}.md'
        texts[name] = source.read_text(encoding='utf-8')
        shutil.copy2(source, OUT/f'{name}.md')
        (OUT/f'{name}.html').write_text(page('Generative / '+name, md(texts[name])), encoding='utf-8')
    (OUT/'parallel.html').write_text(page('Another phrase from the same hands', '<p>The runnable tutorial is on the left; the reflective encounter is on the right.</p><div class="pair"><article>'+md(texts['tutorial'])+'</article><article>'+md(texts['final'])+'</article></div>', True), encoding='utf-8')
    changes = '<h1>From unfinished networks to one fitted generator</h1>'
    for name in ['tutorial', 'final']:
        changes += '<h2>'+html.escape(name)+'</h2><div class="pair"><article><h3>Before</h3>'+md((OUT/f'before/{name}.md').read_text(encoding='utf-8'))+'</article><article><h3>Now</h3>'+md(texts[name])+'</article></div>'
    (OUT/'changes.html').write_text(page('Generative / before and after', changes, True), encoding='utf-8')
    plan = ROOT/'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'
    shutil.copy2(plan, OUT/'ML-SPHERE-LINEAGE.md')
    (OUT/'lineage.html').write_text(page('Where the sphere goes next', md(plan.read_text(encoding='utf-8'))+'<p class="note">Published snapshot. Edit doc/book/course/storyboards/ML-SPHERE-LINEAGE.md.</p>'), encoding='utf-8')
    for chapter, name in [('ML_Perception', 'carried-perception.md'), ('ML_Sequence_Memory', 'carried-memory.md')]:
        shutil.copy2(ROOT/f'commons/maps/{chapter}/tutorial.md', OUT/name)
    count = len(tests['checks']); spatial = len(museum['checks'])
    e = tests['evidence']
    body = f'''<h1>Another phrase.<br>The same hands.</h1>
<p class="lead">The sphere carries its body and its timed paths into a real, small generative process. Your performances teach the mean and the ways the two hands varied together.</p>
<div class="route"><span>Perception / a pose</span><span>Memory / an ordered phrase</span><span class="active">Generative / a fitted possibility</span><span>Synthesis / an intention meets an answer</span></div>
<p><a href="parallel.html">Read the complete facing texts</a> · <a href="changes.html">Both texts before and after</a> · <a href="generative-review.zip">Download the review bundle</a></p>
<figure><img src="generated.png" alt="Point sphere between pink and cyan generated hand paths with nearby controls in the actual museum"><figcaption>Actual Godot Generative hall. The printed study was fitted with explicitly synthetic paired performances for this capture. It is a lesson preview in the museum; the ordinary hall still contains the existing GAN diagram.</figcaption></figure>
<h2>One new operation</h2>
<table><tr><th>Keep</th><th>Add</th></tr><tr><td>PointBody, pickup, both hands, four seconds, beat and airborne paths</td><td>A distribution fitted from whole performances</td></tr><tr><td>The mean from Sequence Memory</td><td>Each take's difference from that mean, kept across hands and times</td></tr><tr><td>Seeded normal randomness</td><td>One coefficient per whole difference; compare source, mean and sample</td></tr></table>
<p>Two complete new files extend the six printed files already carried. The model estimates a Gaussian distribution directly; no unfinished neural-network helper is needed. It is not a trained GAN. Its generated result also is not a dance-quality judgement.</p>
<h2>What the two texts do</h2>
<p>The tutorial reconstructs fitting, sampling and the inherited interaction. The reflection asks how a recording, an average and a generated path acquire different histories while wearing the same familiar sphere. The strongest earlier passage remains: a learned critic would change the question again, but the room's adversarial diagram does not train one.</p>
<figure><img src="hall.png" alt="Overhead view showing the small student study beside the existing adversarial diagram"><figcaption>The study has its own side space. Native floor and standing-capsule checks pass. No ordinary hall geometry or existing artifact was removed.</figcaption></figure>
<h2>Ghost-student reconstruction</h2>
<p><strong>{count} native Godot assertions and {spatial} museum checks pass.</strong> Eight files are extracted from the printed Perception, Memory and Generative chapters into a separate learner folder. This is author-informed reconstruction, not an independent blind reader.</p>
<ul><li>Independent mean and whole-path calculations; shared changes persist across hands and times.</li><li>Same seed repeats; changed source changes the result; identical takes cannot invent variation.</li><li>Sampling leaves all original takes and fitted data unchanged. Invalid input and out-of-policy output are handled explicitly.</li><li>Real button signals, inherited capture/interruption, source/mean/sample controls, same sphere and native museum placement.</li></ul>
<table><tr><th>2,048 synthetic draws, before preview filtering</th><th>Expected</th><th>Observed</th></tr><tr><td>Selected left-hand coordinate variance</td><td>{e['expected_variance']:.6f}</td><td>{e['observed_variance']:.6f}</td></tr><tr><td>Paired coordinate covariance</td><td>{e['expected_cross_hand_covariance']:.6f}</td><td>{e['observed_cross_hand_covariance']:.6f}</td></tr></table>
<p>These checks establish a particular statistical construction, not meaningful choreography. The first reconstruction found a member-name collision with the inherited pose host. Renaming the generated-result field fixed the printed code; the passing run has no script errors.</p>
<div class="card">Human VR comfort, physical reach and the quality of a performed response remain untested. Existing audio UID, registry, Jolt and renderer diagnostics are retained separately. The earlier four ML tutorials still need reconstruction before whole-sequence review.</div>
<p><a href="tests.json">Model and host assertions</a> · <a href="museum-tests.json">Museum checks</a> · <a href="reconstruction.json">Exact-print provenance</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Existing engine diagnostics</a></p>
<h2>Run or revise</h2><p>In the Ada Godot project, run <code>res://doc/book/studies/ml-lineage/Generative.tscn</code>. IMPORT reads the ONE phrase saved in Memory, or CAPTURE three takes here, then FIT. SOURCE, MEAN and DRAW make the distinction visible. NEXT changes the seed; LESS and MORE change the amount.</p>
<p>Canonical texts: <code>commons/maps/ML_Generative/tutorial.md</code> and <code>final.md</code>. Reconstruct with <code>python tools/test_ml_generative_lesson.py</code>; the museum runner and publisher are retained with the project. <a href="lineage.html">Synthesis is next</a>: declare an intention before a fresh trial, and preserve the result rather than quietly train it away.</p>'''
    (OUT/'index.html').write_text(page('Generative / a phrase varied', body), encoding='utf-8')
    sources = [ROOT/f'commons/maps/{chapter}/tutorial.md' for chapter in ['ML_Perception','ML_Sequence_Memory','ML_Generative']]
    sources += [ROOT/'commons/maps/ML_Generative/final.md', plan]
    for p in (OUT/'learner/printed').glob('*.gd'):
        assert p.read_text(encoding='utf-8') == (STUDY/p.name).read_text(encoding='utf-8'), p.name
        sources.append(STUDY/p.name)
    sources += [STUDY/'Generative.tscn', STUDY/'generative_museum.gd']
    (OUT/'source-register.json').write_text(json.dumps({str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
    readme = f'''GENERATIVE: ANOTHER PHRASE FROM THE SAME HANDS

Read tutorial.md and final.md; the two carried chapters contain the six prior files.
learner/ has all eight exact printed files. New: phrase_generator.gd and generative_study.gd.
This review bundle requires the existing Ada project (Godot 4.6, museum, XR Tools, RackTemplates).
Place the learner files plus supplied-museum files in res://doc/book/studies/ml-lineage/.
Run Generative.tscn. Its supplied launcher mounts the study in the real Generative hall.
It does not replace or train the existing animated GAN diagram.

SAVE in Memory with ONE selected, then IMPORT here. Or record three takes, then FIT.
SOURCE is a resampled recording; MEAN is the fit; DRAW samples learned joint variation.
NEXT changes seed. LESS/MORE change amount. These session controls are not persisted.
SAVE keeps source takes separately from the previous hall. Generated output never trains.

{count} Godot assertions and {spatial} native museum checks passed.
Author-informed exact-print reconstruction, not an independent blind student.
Synthetic fixtures and real button signals; no human/headset usability or dance-quality claim.
'''
    (OUT/'README.txt').write_text(readme,encoding='utf-8')
    with zipfile.ZipFile(OUT/'generative-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for n in ['README.txt','tutorial.md','final.md','carried-perception.md','carried-memory.md','ML-SPHERE-LINEAGE.md','tests.json','museum-tests.json','reconstruction.json','source-register.json','museum-diagnostics.json','generated.png','hall.png']:
            z.write(OUT/n,n)
        for p in (OUT/'learner/printed').glob('*.gd'): z.write(p,'learner/'+p.name)
        for n in ['Generative.tscn','generative_museum.gd']: z.write(STUDY/n,'supplied-museum/'+n)
    print(f'Published {count}+{spatial} checks: {OUT}')

if __name__ == '__main__': main()
