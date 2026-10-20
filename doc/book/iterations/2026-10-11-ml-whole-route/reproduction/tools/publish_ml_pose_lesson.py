"""Render canonical ML text, lineage plan and native reconstruction evidence."""
from pathlib import Path
import html, json, shutil, hashlib
import markdown
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-perception-teach-a-sphere'
RUN=ROOT/'ada_run/encounter_pilot/ML_Perception/pose_lesson'
CSS='''
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#11151d;color:#eeeff3;font:18px/1.65 system-ui,sans-serif}
main{max-width:1260px;margin:auto;padding:44px 30px 100px}h1{font-size:clamp(40px,6vw,76px);line-height:1.08;letter-spacing:-.04em}h2{line-height:1.25;margin-top:2.4em}a{color:#9fe1e5}
.eyebrow{color:#e2c08b;font-size:13px;text-transform:uppercase;letter-spacing:.14em}.lead{font-size:25px;max-width:920px}nav{display:flex;gap:20px;flex-wrap:wrap;padding:20px 0;border-bottom:1px solid #3b4250}
figure{margin:30px 0}img{width:100%;display:block}figcaption,.note{font-size:15px;color:#b9c2d0}pre{font:14px/1.6 monospace;background:#080c13;padding:22px;overflow:auto;border:1px solid #35404e}
table{border-collapse:collapse;width:100%;font-size:16px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #424a58;padding:15px}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:35px}.pair>article{min-width:0;max-height:84vh;overflow:auto;padding-right:14px}.pair h1{font-size:34px}.wide{max-width:1700px}
.card{background:#1b2330;padding:24px;border-left:3px solid #9fe1e5;margin:24px 0}.route{display:flex;gap:9px;flex-wrap:wrap;margin:30px 0}.route span{border:1px solid #475667;padding:9px 15px}.route .active{background:#20494f;border-color:#9fe1e5}
li{margin:9px 0}summary{cursor:pointer;padding:18px;background:#202b39}@media(max-width:850px){.pair{display:block}.pair>article{max-height:none}main{padding:26px 18px}table{display:block;overflow:auto}}
'''
def md(text):return markdown.markdown(text,extensions=['fenced_code','tables'])
def page(title,body,wide=False):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><main class="{"wide" if wide else ""}"><p class="eyebrow">Endless Museum / machine learning / 11 October 2026</p><nav><a href="index.html">Sequence & evidence</a><a href="parallel.html">Tutorial left / reflection right</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="lineage.html">Editable plan</a></nav>{body}</main></body></html>'

def main():
    receipts=[]
    for p in [OUT/'tests.json',RUN/'report.json']:
        d=json.loads(p.read_text(encoding='utf-8'));assert d['passed'] and not d['failures'];receipts.append(d)
    log=(RUN/'stdout.log').read_text(encoding='utf-8',errors='replace')
    assert 'SCRIPT ERROR' not in log
    for name in ['lesson','room','response']:shutil.copy2(RUN/f'{name}.png',OUT/f'{name}.png')
    shutil.copy2(RUN/'report.json',OUT/'museum-tests.json')
    (OUT/'museum-diagnostics.json').write_text(json.dumps([x for x in log.splitlines() if x.startswith(('ERROR:','WARNING:'))],indent=2),encoding='utf-8')
    texts={}
    for n in ['tutorial','final']:
        source=ROOT/f'commons/maps/ML_Perception/{n}.md'
        texts[n]=source.read_text(encoding='utf-8')
        shutil.copy2(source,OUT/f'{n}.md')
        (OUT/f'{n}.html').write_text(page(n,md(texts[n])),encoding='utf-8')
    plan=ROOT/'doc/book/course/storyboards/ML-SPHERE-LINEAGE.md'
    shutil.copy2(plan,OUT/'ML-SPHERE-LINEAGE.md')
    (OUT/'lineage.html').write_text(page('Where the sphere fits',md(plan.read_text(encoding='utf-8'))+'<p class="note">Edit the source at doc/book/course/storyboards/ML-SPHERE-LINEAGE.md. This page is a published snapshot.</p>'),encoding='utf-8')
    (OUT/'parallel.html').write_text(page('Perception / facing pages','<p>The executable construction is on the left; its reflective encounter is on the right.</p><div class="pair"><article>'+md(texts['tutorial'])+'</article><article>'+md(texts['final'])+'</article></div>',True),encoding='utf-8')
    before=(OUT/'before/tutorial.md').read_text(encoding='utf-8')
    (OUT/'changes.html').write_text(page('Tutorial / before and after','<h1>From disconnected snippets to one reconstruction</h1><div class="pair"><article><h2>Before</h2>'+md(before)+'</article><article><h2>Now</h2>'+md(texts['tutorial'])+'</article></div>',True),encoding='utf-8')
    counts=[len(d['checks']) for d in receipts]
    body=f'''<h1>The point learns a distinction.</h1><p class="lead">The new work fits inside the existing eight-hall route. Perception now has a complete pose lesson; movement and intention provide the next steps.</p>
<div class="route"><span>Selection</span><span>Loss</span><span>Grouping</span><span>Weights</span><span class="active">Perception</span><span>Memory</span><span>Generation</span><span>Evaluation</span></div>
<figure><img src="lesson.png" alt="The reconstructed point and ten controls in the real Perception hall"><figcaption>Actual Godot museum capture of the printed lesson. Empty teaching data; no prerecorded answers. This preview substitutes the learner's pose study at the existing anchor. The ordinary museum retains the full multi-mode station.</figcaption></figure>
<h2>One object, distinct learning jobs</h2>
<table><tr><th>Where</th><th>What the sphere lets us teach</th></tr>
<tr><td>Gradient Landscape — a proposed return</td><td>Fit a hand measurement to height. Compare objective, parameters and error.</td></tr>
<tr><td>Perception — written and reconstructed now</td><td>Teach three poses. Six coordinates, real learned weights, fresh tests, acceptance rules, visible response.</td></tr>
<tr><td>Sequence Memory — next</td><td>Retain both hands through time. Fit one phrase, then compare A/B. Keep order, timing and rejection visible.</td></tr>
<tr><td>Synthesis — later</td><td>Declare intention before performing. Keep disagreements and compare results under a specific model.</td></tr></table>
<p>All these working modes currently live together in the enlarged <strong>Perception</strong> map. This is a teaching allocation, not a claim that the artifacts have already moved. The hall order remains unchanged.</p>
<div class="card"><strong>Progression judgement:</strong> the order is defensible. The first four halls establish different mechanisms and questions; Perception puts data collection and testing in your hands. Some earlier tutorials still have missing helpers or multiple competing subjects. They need reconstruction before the whole sequence can be called review-ready. Generative especially needs a real, deliberately scoped learner: a diagram or phrase replay does not fill that gap.</div>
<figure><img src="room.png" alt="A high view of the enlarged hall, separate dance and teaching bays and shared forecourt"><figcaption>The current room remains: original exhibits to the left, dance in the middle, learning bay on the right. No artifacts were removed from the ordinary museum.</figcaption></figure>
<h2>What changed in the texts</h2><p>Perception's tutorial now carries PointBody, declares the museum/XR interface support, and prints all three files: the point, the real classifier and its pose-only host. It explains fitting, testing and authored action separately. The reflective text asks what the six-number representation admits or loses, keeping the Sobel exhibit as a useful comparison.</p>
<p>Short bridges now connect Neural Networks to hand features, Perception to time, and Synthesis to Foundations Crisis. The complete editable plan contains one paragraph for each of the eight halls.</p>
<p><a href="parallel.html">Read the two texts together</a> · <a href="changes.html">Tutorial before / after</a> · <a href="lineage.html">Whole sequence plan</a> · <a href="ML-SPHERE-LINEAGE.md">Plan as Markdown</a></p>
<h2>Reconstruct, then test</h2><p><strong>{counts[0]} native Godot checks + {counts[1]} museum checks passed.</strong> The test extracts the code actually printed in tutorial.md. It does not import the production learner to supply missing functions.</p>
<ul><li>All 83 derivatives checked by numerical differences; fitting lowers fixture loss.</li><li>Fifteen fresh synthetic takes, changed labels, file persistence and malformed-load rejection.</li><li>Real button signals, supplied XR trackers, whole-take cancellation, stable pose capture, unchanged weights during testing.</li><li>The same constructed sphere visibly floats, spins or stretches after acceptance and dwell.</li></ul>
<figure><img src="response.png" alt="Synthetic C rehearsal stretching the sphere inside the museum"><figcaption>Explicit synthetic rehearsal after empty-state captures. This tests the chain from examples to response; it is not evidence of human recognition accuracy.</figcaption></figure>
<p class="note">Author-informed reconstruction, not an independent blind ghost student. No human headset or Quest performance test. Existing museum diagnostics include an audio UID, Jolt solver-bias warning, renderer feature warnings and older computer-vision look-at calls. No lesson SCRIPT ERROR in the passing run.</p>
<p><a href="tests.json">39 reconstruction checks</a> · <a href="museum-tests.json">13 museum checks</a> · <a href="reconstruction.json">Extraction and predictions before running</a> · <a href="source-register.json">Source hashes</a> · <a href="museum-diagnostics.json">Museum diagnostics</a></p>
<details><summary>Code, source and reproducible commands</summary><p>Canonical texts: commons/maps/ML_Perception/tutorial.md and final.md. Edit the plan in doc/book/course/storyboards/ML-SPHERE-LINEAGE.md.</p><p>Run res://doc/book/studies/ml-lineage/Perception.tscn inside the Ada project.</p><pre>python tools/test_ml_pose_lesson.py
python tools/run_encounter_probe.py ML_Perception --sequence machinelearning --render --no-bridges --output-tag pose_lesson --probe tools/probes/ml_pose_lesson_museum.gd
python tools/publish_ml_pose_lesson.py</pre>
<p><a href="learner/printed/point_body.gd">Carried point</a> · <a href="learner/printed/pose_learner.gd">Extracted learner</a> · <a href="learner/printed/pose_study.gd">Extracted study</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></details>'''
    (OUT/'index.html').write_text(page('The point learns a distinction',body),encoding='utf-8')
    sources=[ROOT/'commons/maps/ML_Perception/tutorial.md',ROOT/'commons/maps/ML_Perception/final.md',plan]
    sources+=list((ROOT/'doc/book/studies/ml-lineage').glob('*.gd'))
    sources+=[ROOT/'tools/test_ml_pose_lesson.py',ROOT/'tools/probes/ml_pose_lesson_test.gd',ROOT/'tools/probes/ml_pose_lesson_museum.gd',ROOT/'tools/publish_ml_pose_lesson.py',ROOT/'commons/maps/sequences/machinelearning.json']
    (OUT/'source-register.json').write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
    print(f'Published {counts}: {OUT}')

if __name__=='__main__':main()
