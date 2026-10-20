"""Publish Edge's paired texts and source-bound reconstruction evidence."""
from datetime import datetime
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
from build_qfep_edge import ROOT, OUT, HALL, prepare
import publish_qfep_introduction as review

RUN = ROOT/'ada_run/encounter_pilot/QFEP_Edge_Of_Chaos/qfep_reconstruction'
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
    for name in ['initial','coarse','refined','changed','hall','existing']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md']:shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=review.linked(HALL/'tutorial.md'); final=review.linked(HALL/'final.md')
    n_model=headless['printed_assertions']; n_input=len(headless['checks']); n_native=len(native['checks'])
    total=n_model+n_input+n_native
    metrics=headless['metrics']
    first=metrics['rms_dt_03_015']; refined=metrics['rms_dt_015_0075']
    summary={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_Edge_Of_Chaos','passed':True,
        'printed_assertion_statements':n_model,'synthetic_input_checks':n_input,'native_checks_including_captures':n_native,
        'metrics':metrics,'warnings':warnings,'preserved_sources':preserved,
        'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',plan]},
        'scope':'Sixth of eight QFEP halls reconstructed. Author-operated synthetic tests; no headset or independent learner evidence.'}
    write('latest-run.json',json.dumps(summary,indent=2))
    write('tutorial.html',review.page('Edge — tutorial',tutorial))
    write('final.html',review.page('Edge — reflection',final))
    write('parallel.html',review.page('Edge — facing pages','<p class="tag">QFEP Laboratory · Hall 6 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',review.page('QFEP — current route',review.linked(plan)))
    body='''<p class="tag">12 October 2026 · QFEP Laboratory · Hall 6 of 8</p><h1>Same start.<br>Different steps.</h1>
<p class="lead">Carry the sphere, bring back the field, and ask what survives a change in how we calculate its evolution.</p>
<p>Phi separated a difference from its rate. Here dt enters the update itself. The left field takes one step while the right takes two half steps. Both arrive at the same model time; their values need not agree exactly.</p>
<p><button type="button" onclick="showState(0)">Same beginning</button> <button type="button" onclick="showState(1)">Time 60</button> <button type="button" onclick="showState(2)">Halve both steps</button> <button type="button" onclick="showState(3)">Change lambda</button></p>
<figure><a id="full" href="images/coarse.png"><img id="compare" src="images/coarse.png" alt="Two complete fields and carried point sphere on the learner bench in the real museum"></a><figcaption id="caption">Lambda 0.4, time 60. Left: 200 steps of 0.3. Right: 400 steps of 0.15.</figcaption></figure>
<script>function showState(n){const names=['initial','coarse','refined','changed'];const captions=['Same seeded beginning, both clocks zero.','Lambda 0.4, time 60. Left: 200 steps of 0.3. Right: 400 steps of 0.15.','Same seed and duration, finer pair: 400 and 800 steps. KEEP still holds the earlier comparison.','Lambda 0.7 after a restart and another sixty model-time units. Four coefficients changed together.'];const src='images/'+names[n]+'.png';document.getElementById('compare').src=src;document.getElementById('full').href=src;document.getElementById('caption').textContent=captions[n];}</script>
<div class="grid"><section class="card"><h2>Tutorial</h2><p>Four complete new files: timed field, comparison, interaction and assertions. Three carried files: PointBody, LineSkin and Bench. The old-to-new update returns from Cellular Automata; the retained field returns from Shaders.</p><p><a href="tutorial.html">Full runnable tutorial</a> · <a href="parallel.html">Facing pages</a></p></section><section class="card"><h2>Reflection</h2><p>The existing argument stays: a pattern also depends on how we drive and calculate it. A new paragraph asks what a kept comparison must retain beyond a final number or image.</p><p><a href="final.html">Reflection</a> · <a href="changes.html">Before and after</a></p></section></div>'''
    body+=f'''<h2>A measured result, with its conditions</h2><p>At 32 × 32, seed {metrics['seed']}, lambda 0.4 and time 60, the RMS difference in B changes from <strong>{first:.8f}</strong> to <strong>{refined:.8f}</strong> when both timesteps halve. That is evidence for this refinement at this setting, not proof of convergence everywhere. Similar-looking images can still contain different values.</p>
<table><tr><th>Action</th><th>What it changes</th></tr><tr><td>Lift the sphere</td><td>Lambda and four coefficients for future updates</td></tr><tr><td>+6 TIME</td><td>Both fields advance six model-time units</td></tr><tr><td>RESTART</td><td>Same seed, current parameters, zero clocks</td></tr><tr><td>NEW SEED</td><td>Another matching pair of beginnings</td></tr><tr><td>DT / 2</td><td>Switch timestep pair and restart the same seed</td></tr><tr><td>KEEP</td><td>Copy fields, parameters, seed, counts, times and RMS</td></tr></table>
<div class="note"><strong>{total} checks passed:</strong> {n_model} printed assertions, {n_input} synthetic interaction checks and {n_native} native checks including captures. <a href="ghost.html">Receipts and limits.</a></div>'''
    body+='<h2>Inside the existing hall</h2>'+figure('existing','The installed 64 × 64 comparison at model time 60. Its SIM SPEED control changes scheduling; DT changes numerical resolution. Automatic frames were paused for this reproducible capture.')
    body+=figure('hall','Native Godot capture of the learner bench in a checked bay. The ordinary museum retains its artifacts and map.')
    body+='''<h2>What travels onward</h2><p>Seed, model definition, settings, timestep and duration belong with the result. <strong>Sandbox is next:</strong> make the connection between a named sender and its receiver explicit. Six QFEP halls are reconstructed; Sandbox and Synthesis remain.</p><p><a href="plan.html">Current route</a> · <a href="plan.md">Editable plan</a> · <a href="../2026-10-12-qfep-change-has-a-sign/index.html">Previous: Phi Term</a></p>'''
    write('index.html',review.page('Edge — same start, different steps',body))
    ghost=f'''<p class="tag">Ghost student · Edge of Chaos</p><h1>Compare the calculation.</h1><p class="lead">{total} passing checks on fresh printed code and the actual museum.</p>
<p>The harness extracts seven files from the book: four new files here, three carried from Euclid and Russell. It runs numerical assertions and synthetic hand/button inputs under a translated and rotated parent. A native run mounts the same extracted code in the existing hall. This is author-operated reconstruction, not an independent reader or physical headset test.</p>
<h2>What the evidence establishes</h2><p>The tests check seeded replay, a cell's explicit arithmetic, periodic boundaries, synchronous updates, invalid-input faults, equal clocks at different step counts, immutable KEEP records, local hand mapping and palette-only clipping. The independent time-18 task reaches 120/240 steps at the finer pair. The learner's A/B arrays and RMS exactly match a 32 × 32 instance of the installed solver at matching seed, settings and model time.</p>
<p>The installed exhibit is checked through its connected console signals. RESTART, NEW SEED, DT, HOLD/RUN, lambda and SIM SPEED have separate jobs. Its automatic frames are disabled during the deterministic probe; HOLD/RUN is tested by calling the actual scheduling method. The normal exhibit remains automatic. The lesson bench instead uses explicit +6 TIME batches.</p>
<h2>What needed correction</h2><p>The previous tutorial described ants and a preferred regime without a runnable reconstruction of this exhibit. The replacement makes the actual update and comparison explicit. Existing reflective prose was retained.</p>
<p>The first numerical and native state checks passed, but visual inspection showed only part of each field: the thin BoxMesh used its default texture atlas. The screens now use QuadMesh surfaces, each covering the whole texture. An added UV-coverage check and regenerated native captures verify the repair. <a href="first-display-coarse.png">First cropped display</a> · <a href="first-display-report.json">First state-check receipt</a>.</p>
<p>An exploratory camera also hit the hall's central terrace wall. Moving it closer to the installed display produced an unobstructed view. The learner bay was checked separately for floor support, approach clearance and non-overlap with the installed work.</p>'''
    for title,checks in [('Synthetic input checks',headless['checks']),('Native museum checks',native['checks'])]:
        ghost+=f'<h2>{title}</h2><table><tr><th>Check</th><th>Result</th></tr>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</table>'
    ghost+='<h2>Limits and engine warnings</h2><p>The learner grid is 32 × 32; the installed screen is 64 × 64. Their screenshots are not a matched-grid experiment. RMS describes B alone, not artistic value or entropy. KEEP lasts for the current run and preserves B comparisons, not a resumable A/B checkpoint or the history of intervening lambda edits. These tests do not establish universal criticality, physical chemistry, headset comfort or Quest performance.</p><p>No script or engine errors remain. The museum reports unavailable/blocked authored portal placements and uses a fallback. Bench placement checks do not validate the entire walking route. Other existing renderer, registry and resource warnings are retained below.</p><pre>'+html.escape('\n'.join(warnings))+'</pre>'
    ghost+='''<h2>Reproduce</h2><pre>python tools/test_qfep_edge.py
python tools/run_encounter_probe.py QFEP_Edge_Of_Chaos --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_edge_museum.gd
python tools/publish_qfep_edge.py</pre><p><a href="extraction.json">Printed lineage</a> · <a href="headless.json">Headless receipt</a> · <a href="evidence/report.json">Museum receipt</a> · <a href="evidence/stdout.log">Engine log</a> · <a href="latest-run.json">Run summary</a></p>'''
    write('ghost.html',review.page('Edge — ghost student',ghost))
    changes='<h1>Edge: before and after</h1><p>Complete reconstruction and one reflective addition. Installed artifact code, map data and sequence order are unchanged and source-hash checked.</p>'
    for name in ['tutorial.md','final.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8'); new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact diff</summary><pre class="diff">{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+review.linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+review.linked(HALL/name)+'</article></div>'
    write('changes.html',review.page('Edge — changes',changes,True))
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
