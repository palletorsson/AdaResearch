"""Publish Sandbox's complete paired reading and verified reconstruction."""
from datetime import datetime
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
from build_qfep_sandbox import ROOT, OUT, HALL, prepare
import publish_qfep_introduction as review

RUN = ROOT/'ada_run/encounter_pilot/QFEP_Sandbox/qfep_reconstruction'
review.OUT = OUT

def write(name, text): (OUT/name).write_text(text, encoding='utf8')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def figure(name, caption):
    return f'<figure><a href="images/{name}.png"><img src="images/{name}.png" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'

def main():
    prepare()
    headless=json.loads((OUT/'headless.json').read_text(encoding='utf8'))
    native=json.loads((RUN/'report.json').read_text(encoding='utf8'))
    assert headless['passed'] and native['passed']
    assert headless['extraction_sha256']==sha(OUT/'extraction.json'), 'stale headless receipt'
    for group in ['tested_code','runtime_sources']:
        for path,digest in native['observations'][group].items():
            assert sha(ROOT/path.removeprefix('res://'))==digest, path
    preserved=json.loads((OUT/'preserved-sources.json').read_text(encoding='utf8'))
    assert all(sha(ROOT/path)==digest for path,digest in preserved.items()), 'runtime sources changed'
    log=(RUN/'stdout.log').read_text(encoding='utf8',errors='replace')
    errors=[line for line in log.splitlines() if re.search(r'(SCRIPT ERROR|^ERROR:|Assertion failed)',line)]
    assert not errors, errors
    warnings=sorted(set(line for line in log.splitlines() if line.startswith('WARNING:')))
    for name in ['images','evidence']: (OUT/name).mkdir(exist_ok=True)
    for name in ['cut','connected','held','reconnected','hall','existing','existing-cut']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md']:shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=review.linked(HALL/'tutorial.md'); final=review.linked(HALL/'final.md')
    n_model=headless['printed_assertions']; n_input=len(headless['checks']); n_native=len(native['checks'])
    total=n_model+n_input+n_native
    summary={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_Sandbox','passed':True,
        'printed_assertion_statements':n_model,'synthetic_input_checks':n_input,'native_checks_including_captures':n_native,
        'warnings':warnings,'preserved_sources':preserved,
        'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',plan]},
        'scope':'Seventh of eight QFEP halls reconstructed. Author-operated synthetic tests; no headset or independent learner evidence.'}
    write('latest-run.json',json.dumps(summary,indent=2))
    write('tutorial.html',review.page('Sandbox — tutorial',tutorial))
    write('final.html',review.page('Sandbox — reflection',final))
    write('parallel.html',review.page('Sandbox — facing pages','<p class="tag">QFEP Laboratory · Hall 7 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',review.page('QFEP — current route',review.linked(plan)))
    body='''<p class="tag">12 October 2026 · QFEP Laboratory · Hall 7 of 8</p><h1>Where the value<br>arrives.</h1>
<p class="lead">The same sphere offers a value. One named receiver may use it—or keep using an earlier value.</p>
<p>Edge of Chaos made the update explicit. Sandbox makes its connection explicit. A cut route preserves received inputs while motion continues. Reconnecting delivers the present settings immediately; REPEAT restarts the motion with the inputs already held.</p>
<p><button type="button" onclick="showState(0)">Offer while cut</button> <button type="button" onclick="showState(1)">Connect</button> <button type="button" onclick="showState(2)">Cut and change</button> <button type="button" onclick="showState(3)">Reconnect</button></p>
<figure><a id="full" href="images/cut.png"><img id="compare" src="images/cut.png" alt="Carried sphere offers a different pair from the values used by a moving cube in the actual museum"></a><figcaption id="caption">Offer 0.85 / +0.70; used 0.40 / 0.00. At one second the cube has travelled 0.26 m.</figcaption></figure>
<script>function showState(n){const names=['cut','connected','held','reconnected'];const captions=['Offer 0.85 / +0.70; used 0.40 / 0.00. At one second the cube has travelled 0.26 m.','The current pair arrives. After REPEAT and one second the cube has travelled 0.44 m.','CUT, then offer 0.15 / +0.60. The receiver keeps 0.85 / +0.70; after REPEAT it still travels 0.44 m in one second.','Reconnect: the present pair arrives. After REPEAT and one second the cube has travelled 0.16 m. KEEP still holds the first disagreement.'];const src='images/'+names[n]+'.png';document.getElementById('compare').src=src;document.getElementById('full').href=src;document.getElementById('caption').textContent=captions[n];}</script>
<div class="grid"><section class="card"><h2>Tutorial</h2><p>Four complete new files: receiver, input route, working bench and assertions. Carry PointBody, LineSkin and Bench. A familiar BoxMesh travels on a one-metre track; it makes received speed visible.</p><p><a href="tutorial.html">Full runnable tutorial</a> · <a href="parallel.html">Facing pages</a></p></section><section class="card"><h2>Reflection</h2><p>The argument about where a control reaches stays. A new paragraph asks what a record must retain when the hand has moved on but its earlier decision still acts at the receiver.</p><p><a href="final.html">Reflection</a> · <a href="changes.html">Before and after</a></p></section></div>
<h2>One route, different operations</h2>
<table><tr><th>Operation</th><th>Offered pair</th><th>Received pair</th><th>Motion</th></tr><tr><td>Move sphere while CUT</td><td>Changes</td><td>Held</td><td>Continues</td></tr><tr><td>CONNECT</td><td>Retained</td><td>Immediately takes current offer</td><td>Continues from current distance</td></tr><tr><td>Move sphere while CONNECTED</td><td>Changes</td><td>Follows selected input</td><td>Uses received speed</td></tr><tr><td>CUT</td><td>Retained</td><td>Held, not reset</td><td>Continues</td></tr><tr><td>REPEAT</td><td>Retained</td><td>Retained</td><td>Restarts clock and track distance</td></tr><tr><td>KEEP</td><td colspan="3">Copies both pairs, connection state and the current response</td></tr></table>
<p>The miniature copies the installed reactor's colour and speed mappings. It applies the speed to a cube rather than a particle system. The cube's wrap at the end of the track is a display convention; it is not a collision. The code and text state that difference explicitly.</p>'''
    body+=f'<div class="note"><strong>{total} checks passed:</strong> {n_model} printed assertions, {n_input} synthetic interaction checks and {n_native} native checks including captures. <a href="ghost.html">Receipts and limits.</a></div>'
    body+='<h2>Inside the existing hall</h2>'+figure('existing','The original reactor, two rails, CONNECT / CUT console and independent particle field. Native Godot capture; original artifact code and map remain unchanged.')
    body+=figure('hall','The supplied F6 lesson mounts the working bench beside the existing encounter. The approach and separation from the retained artifacts passed placement checks.')
    body+='''<h2>What travels onward</h2><p>A parameter, its offered value, its received value and a body's running state are distinct. <strong>Synthesis is next:</strong> inspect the local controls that reach a deformable body's mechanics. Seven QFEP halls are reconstructed; Synthesis remains.</p><p><a href="plan.html">Current route</a> · <a href="plan.md">Editable plan</a> · <a href="../2026-10-12-qfep-same-time-different-steps/index.html">Previous: Edge of Chaos</a></p>'''
    write('index.html',review.page('Sandbox — where the value arrives',body))
    ghost=f'''<p class="tag">Ghost student · Sandbox</p><h1>Did the value arrive?</h1><p class="lead">{total} passing checks on fresh printed code and the real hall.</p>
<p>Seven files were freshly extracted from the book: four new files, three carried from Euclid and Russell. The harness runs the printed assertions and synthetic point/button input under a translated and rotated parent. The rendered probe mounts that extracted lesson in the real museum. This is author-operated reconstruction, not an independent student or physical headset study.</p>
<h2>What the evidence establishes</h2><p>Offered values can change without delivery. Connecting sends the current pair immediately. Cutting holds the last delivered pair while motion continues. REPEAT changes time and distance without altering connection or inputs. KEEP survives subsequent editing. Redrawing cannot change model state. The same sphere, cube and receiver persist.</p>
<p>The independent task uses the hand to leave OFFER at 0.90 / +0.50 and USED at 0.25 / −0.50. The received speed is 0.20 m/s; reconnecting makes it 0.46 m/s. A separate comparison checks the learner's colour and speed mappings against the installed reactor at seven lambda settings and three phi settings.</p>
<p>The native run uses the actual installed rail and button signals. It checks offered/used readouts, immediate delivery, cut input with continuing animation, deterministic CPU replay at equal update steps, and missing local handles failing closed. Restoring the local pair does not automatically reconnect it. The independent field receives neither input and still advances its own clock.</p>
<h2>What changed in the writing</h2><p>The former tutorial was a correct short encounter brief. It now includes the complete construction, declared inherited files, initialized labels, a smaller visible receiver, exercises and assertions. The reflection gains one paragraph on keeping both sides of an interrupted relation. The installed reactor, wiring, handles, particle field, permanent map and order are source-hash checked as unchanged.</p>
<p>The first headless and native runs passed. Visual inspection confirmed that both offered and received labels, the moving cube, nearby buttons and original artifacts remain visible. No runtime repair was needed in this pass.</p>'''
    for title,checks in [('Synthetic input checks',headless['checks']),('Native museum checks',native['checks'])]:
        ghost+=f'<h2>{title}</h2><table><tr><th>Check</th><th>Result</th></tr>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</table>'
    ghost+='<h2>Limits and warnings</h2><p>Snapshots were taken at controlled animation steps; a separate check confirms that ordinary process frames advance the learner. GPU particle histories are not compared bit for bit. The reduced cube receiver does not recreate the reactor\'s full pulse, jitter or particle population. KEEP is an in-memory snapshot, not a complete event history. No physical headset reach, comfort or independent understanding was tested.</p><p>No script or engine errors remain. The existing authored entry reports a blocked frame and uses a safe fallback. A supported clear bench approach does not certify every walking route. Renderer, registry and resource warnings are preserved below.</p><pre>'+html.escape('\n'.join(warnings))+'</pre>'
    ghost+='''<h2>Reproduce</h2><pre>python tools/test_qfep_sandbox.py
python tools/run_encounter_probe.py QFEP_Sandbox --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_sandbox_museum.gd
python tools/publish_qfep_sandbox.py</pre><p><a href="extraction.json">Printed lineage</a> · <a href="headless.json">Headless receipt</a> · <a href="evidence/report.json">Museum receipt</a> · <a href="evidence/stdout.log">Engine log</a> · <a href="latest-run.json">Run summary</a></p>'''
    write('ghost.html',review.page('Sandbox — ghost student',ghost))
    changes='<h1>Sandbox: before and after</h1><p>Expand the encounter into a complete runnable tutorial. Preserve the reflection and add one paragraph about keeping offered and received values together. Installed logic, permanent map and sequence order are unchanged.</p>'
    for name in ['tutorial.md','final.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8'); new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact diff</summary><pre class="diff">{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+review.linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+review.linked(HALL/name)+'</article></div>'
    write('changes.html',review.page('Sandbox — changes',changes,True))
    missing=[]
    class Links(HTMLParser):
        def handle_starttag(self, tag, attrs):
            for key,value in attrs:
                if key not in ['href','src'] or not value:continue
                u=urlsplit(value)
                if not u.scheme and u.path and not u.path.startswith('/') and not (OUT/unquote(u.path)).exists():missing.append(value)
    for path in OUT.glob('*.html'): Links().feed(path.read_text(encoding='utf8'))
    assert not missing, missing
    print(json.dumps(summary,indent=2))
    print('Seven review pages checked for local links.')

if __name__=='__main__':main()
