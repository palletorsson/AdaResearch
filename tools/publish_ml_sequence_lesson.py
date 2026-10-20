"""Publish canonical Sequence Memory texts and exact-print reconstruction evidence."""
from pathlib import Path
import html, json, shutil, hashlib, zipfile
import markdown
from publish_ml_pose_lesson import page
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-memory-both-hands'
RUN=ROOT/'ada_run/encounter_pilot/ML_Sequence_Memory/sequence_lesson'

def md(text):
    text=text.replace('../ML_Perception/tutorial.md','../2026-10-11-perception-teach-a-sphere/tutorial.html')
    return markdown.markdown(text,extensions=['fenced_code','tables'])

def main():
    tests=json.loads((OUT/'tests.json').read_text(encoding='utf-8'))
    museum=json.loads((RUN/'report.json').read_text(encoding='utf-8'))
    assert tests['passed'] and museum['passed'] and not tests['failures'] and not museum['failures']
    log=(RUN/'stdout.log').read_text(encoding='utf-8',errors='replace')
    assert 'SCRIPT ERROR' not in log
    for n in ['empty','hall','replay','test']:shutil.copy2(RUN/f'{n}.png',OUT/f'{n}.png')
    shutil.copy2(RUN/'report.json',OUT/'museum-tests.json')
    (OUT/'museum-diagnostics.json').write_text(json.dumps([x for x in log.splitlines() if x.startswith(('WARNING:','ERROR:'))],indent=2),encoding='utf-8')
    texts={}
    for n in ['tutorial','final']:
        source=ROOT/f'commons/maps/ML_Sequence_Memory/{n}.md'
        texts[n]=source.read_text(encoding='utf-8');shutil.copy2(source,OUT/f'{n}.md')
        (OUT/f'{n}.html').write_text(page('Sequence Memory / '+n,md(texts[n])),encoding='utf-8')
    (OUT/'parallel.html').write_text(page('Both hands, in order','<p>The complete tutorial is on the left; the reflective text is on the right.</p><div class="pair"><article>'+md(texts['tutorial'])+'</article><article>'+md(texts['final'])+'</article></div>',True),encoding='utf-8')
    (OUT/'changes.html').write_text(page('Sequence Memory / before and after','<h1>From unfinished network snippets to a whole phrase</h1><div class="pair"><article><h2>Before</h2>'+md((OUT/'before/tutorial.md').read_text(encoding='utf-8'))+'</article><article><h2>Now</h2>'+md(texts['tutorial'])+'</article></div>',True),encoding='utf-8')
    plan=ROOT/'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'
    shutil.copy2(plan,OUT/'ML-SPHERE-LINEAGE.md')
    (OUT/'lineage.html').write_text(page('The ML route',md(plan.read_text(encoding='utf-8'))),encoding='utf-8')
    shutil.copy2(ROOT/'commons/maps/ML_Perception/tutorial.md',OUT/'carried-perception.md')
    count=len(tests['checks']);spatial=len(museum['checks'])
    body=f'''<h1>Both hands,<br>in order.</h1>
<p class="lead">The point keeps its body. The tutorial adds a history: four seconds of both hands, a learned path, then two possible phrases.</p>
<div class="route"><span>Perception / a pose</span><span class="active">Sequence Memory / a phrase</span><span>Generative / what produced this?</span></div>
<p><a href="parallel.html">Read tutorial and reflection side by side</a> · <a href="changes.html">Before / after</a> · <a href="lineage.html">Place in the eight-hall route</a></p>
<figure><img src="replay.png" alt="The same point sphere between pink and cyan airborne learned hand paths in the museum"><figcaption>Actual Godot Sequence Memory hall. This is the reconstructed tutorial study, fitted with explicitly synthetic examples for the capture. The same sphere follows the midpoint of the two timed paths.</figcaption></figure>
<h2>What the lesson adds</h2>
<table><tr><th>Carried from Perception</th><th>New in Sequence Memory</th></tr>
<tr><td>PointBody, pickup, visible ring and sphere</td><td>The existing point responds to a complete movement.</td></tr>
<tr><td>Head-relative left/right coordinates</td><td>Timestamps preserve order and timing.</td></tr>
<tr><td>Arrays and averaging</td><td>Average separately at 41 common times; check each hand.</td></tr>
<tr><td>Teaching, testing and authored response</td><td>ONE → A/B; unknown and ambiguous results; preview separate from fresh testing.</td></tr></table>
<p>The host extends the printed Perception study. Three previous files are reused unchanged; three new complete files are printed in tutorial.md. The learner is the existing real timed-prototype model, not a newly claimed RNN. Its A/B wrapper changes only the import path to the local printed learner.</p>
<h2>The two texts have different jobs</h2>
<p>The tutorial explains capture, resampling, fitting, distance, timing and the complete executable extension. The reflection asks what an average path retains, what a fixed clock demands, and how a preview changes the next performance. It preserves the hall's hand-set gate cell as a different kind of memory.</p>
<p>A held-pose mean can be identical for forward and reversed movement. The ordered prototypes can distinguish them. That is the chapter's central progression; it does not need an unfinished RNN, LSTM and teacher-forcing course to make the change felt.</p>
<figure><img src="hall.png" alt="High view of Sequence Memory with the learner study in its own side area beside the existing gate cell and transformer diagram"><figcaption>The supplied lesson scene mounts the student code in a side area of the actual hall. The ordinary museum's full multi-mode phrase station remains in Perception. No existing artifact or map geometry was removed.</figcaption></figure>
<h2>Ghost-student reconstruction</h2>
<p><strong>{count} Godot assertions and {spatial} museum checks pass.</strong> The runner extracts six files from the two printed chapters into a fresh learner folder. No production learner fills a missing helper.</p>
<ul><li>Independent interpolation and mean calculations; forward and reversed fixtures have the same whole-pose mean.</li><li>Fresh recognition, reverse order, retiming, swapped hands, a stationary hand and incomplete tracking.</li><li>A/B decisions independent of the selected teaching target; unknown and ambiguous outcomes remain distinct.</li><li>Atomic save validation, unchanged fitting during tests, whole-take interruption, real button signals and supplied XR trackers.</li><li>The same sphere instance through ONE, A/B, preview and response; carried pose data unchanged.</li></ul>
<div class="card">The first native reconstruction found a Godot type-inference error in the new replay visibility variable. The printed code now declares its boolean type explicitly. The passing rerun also tests the inherited point and both airborne paths.</div>
<figure><img src="test.png" alt="Museum test returning phrase A while the teaching selector remains on B"><figcaption>Synthetic fresh test: A is recognised while B remains the selected teaching target. The sphere waits; testing neither refits nor replays.</figcaption></figure>
<p class="note">This ghost student is an author-informed exact-print reconstruction, not an independent blind reader. The tests use synthetic takes and supplied XR tracking. Human recognition, comfort, reach and Quest performance remain untested. Existing audio UID, registry, Jolt and renderer diagnostics are retained in the report; the passing run has no lesson SCRIPT ERROR.</p>
<h2>Try the chapter</h2><ol><li>Run <code>res://doc/book/studies/ml-lineage/SequenceMemory.tscn</code> in the Ada project.</li><li>Choose ONE, CAPTURE three whole performances, then TRAIN.</li><li>REPLAY to inspect; TEST a fresh movement; TRY to let a match act.</li><li>Teach the reverse as B alongside A. Test without telling the recogniser which answer to produce.</li></ol>
<p><a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflective Markdown</a> · <a href="carried-perception.md">Carried Perception chapter</a> · <a href="sequence-memory-review.zip">Review bundle</a></p>
<p><a href="tests.json">Reconstruction receipt</a> · <a href="museum-tests.json">Museum receipt</a> · <a href="reconstruction.json">Predictions and extraction manifest</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Existing diagnostics</a></p>
<details><summary>Reproduce the checks</summary><pre>python tools/test_ml_sequence_lesson.py
python tools/run_encounter_probe.py ML_Sequence_Memory --sequence machinelearning --render --no-bridges --output-tag sequence_lesson --probe tools/probes/ml_sequence_lesson_museum.gd
python tools/publish_ml_sequence_lesson.py</pre><p>The study is in the existing Ada project; its museum, XR Tools and RackTemplates controls are supplied infrastructure.</p></details>'''
    (OUT/'index.html').write_text(page('Sequence Memory / both hands',body),encoding='utf-8')
    sources=[ROOT/'commons/maps/ML_Sequence_Memory/tutorial.md',ROOT/'commons/maps/ML_Sequence_Memory/final.md',ROOT/'commons/maps/ML_Perception/tutorial.md',plan]
    sources+=list((ROOT/'doc/book/studies/ml-lineage').glob('*.gd'))
    sources.append(ROOT/'doc/book/studies/ml-lineage/SequenceMemory.tscn')
    sources+=[ROOT/'tools'/n for n in ['test_ml_sequence_lesson.py','publish_ml_sequence_lesson.py','probes/ml_sequence_lesson_test.gd','probes/ml_sequence_lesson_museum.gd','probes/movement_fixture.gd']]
    (OUT/'source-register.json').write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUT/'sequence-memory-review.zip','w',zipfile.ZIP_DEFLATED) as bundle:
        bundle.writestr('README.txt','''Sequence Memory review / Endless Museum

Read tutorial.md with final.md. carried-perception.md supplies the previous chapter.
learner/ contains six files extracted from those printed chapters, not hidden production helpers.

This bundle is for review within the existing Ada project, not a standalone Godot project.
To run, put the six learner files plus supplied-museum/sequence_museum.gd and
SequenceMemory.tscn in res://doc/book/studies/ml-lineage/ in that project.
Run SequenceMemory.tscn. Museum, XR Tools and RackTemplates remain supplied infrastructure.
The full multi-mode artifact stays in Perception; this supplied lesson scene mounts
the printed study in the actual Sequence Memory hall.

Tests are author-informed reconstruction, not an independent blind reader.
73 Godot checks and 14 museum checks use synthetic traces / supplied XR poses.
Human recognition, headset comfort and Quest performance have not been established.
''')
        for n in ['tutorial.md','final.md','carried-perception.md','ML-SPHERE-LINEAGE.md','tests.json','museum-tests.json','reconstruction.json','source-register.json','museum-diagnostics.json','replay.png','hall.png']:
            bundle.write(OUT/n,n)
        for p in (OUT/'learner/printed').glob('*.gd'):bundle.write(p,'learner/'+p.name)
        for n in ['SequenceMemory.tscn','sequence_museum.gd']:bundle.write(ROOT/'doc/book/studies/ml-lineage'/n,'supplied-museum/'+n)
    print(f'Published {count}+{spatial} checks: {OUT}')

if __name__=='__main__':main()
