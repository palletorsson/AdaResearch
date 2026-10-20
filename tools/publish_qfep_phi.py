"""Publish Phi's paired texts and verified printed-code reconstruction evidence."""
from datetime import datetime
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
from build_qfep_phi import ROOT, OUT, HALL, prepare
import publish_qfep_introduction as review

RUN=ROOT/'ada_run/encounter_pilot/QFEP_Phi_Term/qfep_reconstruction'
review.OUT=OUT
def write(name,text): (OUT/name).write_text(text,encoding='utf8')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    prepare()
    headless=json.loads((OUT/'headless.json').read_text(encoding='utf8'))
    native=json.loads((RUN/'report.json').read_text(encoding='utf8'))
    assert headless['passed'] and native['passed']
    assert headless['extraction_sha256']==sha(OUT/'extraction.json'),'stale headless run'
    for group in ['tested_code','runtime_sources']:
        for path,digest in native['observations'][group].items():
            assert sha(ROOT/path.removeprefix('res://'))==digest,path
    preserved=json.loads((OUT/'preserved-sources.json').read_text(encoding='utf8'))
    assert all(sha(ROOT/path)==digest for path,digest in preserved.items()),'unreviewed runtime change'
    log=(RUN/'stdout.log').read_text(encoding='utf8',errors='replace')
    errors=[line for line in log.splitlines() if re.search(r'(SCRIPT ERROR|^ERROR:|Assertion failed)',line)]
    assert not errors,errors
    warnings=sorted(set(line for line in log.splitlines() if line.startswith('WARNING:')))
    for folder in ['images','evidence']:(OUT/folder).mkdir(exist_ok=True)
    for name in ['positive','negative','longer','reversed','hall','existing-positive','existing-negative']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md']:shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=review.linked(HALL/'tutorial.md');final=review.linked(HALL/'final.md')
    n_model=headless['printed_assertions'];n_input=len(headless['checks']);n_native=len(native['checks'])
    total=n_model+n_input+n_native
    summary={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_Phi_Term','passed':True,
        'printed_assertion_statements':n_model,'synthetic_input_checks':n_input,'native_checks_including_captures':n_native,
        'warnings':warnings,'preserved_sources':preserved,
        'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',plan]},
        'scope':'Phi only, fifth reconstructed QFEP hall. Three halls pending. Author-operated synthetic tests; no headset or independent learner evidence.'}
    write('latest-run.json',json.dumps(summary,indent=2))
    write('tutorial.html',review.page('Phi — tutorial',tutorial))
    write('final.html',review.page('Phi — reflection',final))
    write('parallel.html',review.page('Phi — facing pages','<p class="tag">QFEP Laboratory · Hall 5 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',review.page('QFEP — current route',review.linked(plan)))
    body='''<p class="tag">12 October 2026 · QFEP Laboratory · Hall 5 of 8</p><h1>Give a difference<br>a weight.</h1>
<p class="lead">The same sphere changes phi. The earlier reading, later reading and interval remain available for comparison.</p>
<p>Lambda separated a recommendation from a weight. Phi separates a signed difference from its average rate, then shows what a signed weight does to that difference. Two cyan columns hold the supplied readings; a pink bar shows their weighted difference above or below zero.</p>
<p><button type="button" onclick="showState(0)">Positive weight</button> <button type="button" onclick="showState(1)">Negative weight</button> <button type="button" onclick="showState(2)">Longer interval</button> <button type="button" onclick="showState(3)">Reverse readings</button></p>
<figure><a id="full" href="images/positive.png"><img id="compare" src="images/positive.png" alt="Carried sphere and two reading columns beside a signed contribution bar inside the museum"></a><figcaption id="caption">0.20 → 0.70 over two seconds. Phi +1 gives contribution +0.500. KEEP records the comparison.</figcaption></figure>
<script>function showState(n){const names=['positive','negative','longer','reversed'];const captions=['0.20 → 0.70 over two seconds. Phi +1 gives contribution +0.500. KEEP records the comparison.','Same readings and interval, phi −1: the contribution becomes −0.500.','Four seconds between the same supplied readings: average rate halves to +0.125 per second. Difference and contribution stay fixed.','The supplied pair becomes 0.70 → 0.20. Both difference and phi are negative, so their product is positive. KEEP still records the earlier comparison.'];const src='images/'+names[n]+'.png';document.getElementById('compare').src=src;document.getElementById('full').href=src;document.getElementById('caption').textContent=captions[n];}</script>
<div class="grid"><section class="card"><h2>Tutorial</h2><p>Three complete new files: model, bench interaction and assertions. Three unchanged carried files: PointBody, LineSkin and Bench. The sphere edits one signed parameter. REVERSE, INTERVAL, KEEP, ZERO PHI and LABELS each have a declared job.</p><p><a href="tutorial.html">Read tutorial</a> · <a href="parallel.html">Facing pages</a></p></section><section class="card"><h2>Reflection</h2><p>The argument about direction, magnitude and interpretation stays. One paragraph now distinguishes a weight from the change it multiplies. The zero-emission sentence is corrected against the actual rail.</p><p><a href="final.html">Read reflection</a> · <a href="changes.html">Before and after</a></p></section></div>
<h2>A comparison we can account for</h2>
<table><tr><th>Operation</th><th>Changes</th><th>Remains</th></tr><tr><td>Move the sphere</td><td>Phi and weighted contribution</td><td>Readings, interval, difference, rate</td></tr><tr><td>Change the interval</td><td>Interval and average rate</td><td>Readings, difference, phi, contribution</td></tr><tr><td>Reverse the supplied pair</td><td>Reading order and both result signs</td><td>Positive interval and phi</td></tr><tr><td>Zero phi</td><td>Weight and contribution become zero</td><td>Difference may still be nonzero</td></tr><tr><td>Reveal earlier labels</td><td>Words on the board</td><td>Every model value</td></tr></table>
<p>The pair and interval are authored inputs, not measurements of the room. Changing the interval does not slow an actual timer; reversing the pair does not rewind an event. The lesson computes only phi × difference. It leaves Introduction's full expression intact and does not turn the surrounding patterns into an entropy instrument.</p>'''
    body+=f'<div class="note"><strong>{total} checks passed:</strong> {n_model} printed assertions, {n_input} synthetic input checks and {n_native} native checks including captures. <a href="ghost.html">Evidence and limits.</a></div>'
    body+='''<h2>The installed encounter</h2><figure><a href="images/existing-negative.png"><img src="images/existing-negative.png" alt="Original PHI rail and its earlier labels beside the independent museum patterns"></a><figcaption>The installed rail at phi −0.5, with EARLIER LABELS revealed. Its configured particle speed matches +0.5; direction reverses. The adjoining pattern keeps moving independently.</figcaption></figure>
<figure><a href="images/hall.png"><img src="images/hall.png" alt="The learner's working bench among the original plinths in the Phi hall"></a><figcaption>Native Godot capture. The supplied F6 scene adds the working copy in a checked bay. The existing artifacts and permanent map retain their code and placements.</figcaption></figure>
<h2>What travels onward</h2><p>The record keeps earlier and later readings together with their interval. A parameter is not an observation, and a word on a control is not its effect. <strong>Edge of Chaos is next:</strong> compare evolving patterns over equal model time and make the update rule explicit.</p>
<p><a href="../2026-10-12-qfep-move-the-recommendation/index.html">Previous: Lambda Spectrum</a> · <a href="plan.html">Eight-hall plan</a> · <a href="plan.md">Editable plan</a></p>'''
    write('index.html',review.page('Phi — give a difference a weight',body))
    ghost=f'''<p class="tag">Ghost student · Phi Term</p><h1>A difference is not a rate.</h1><p class="lead">{total} checks pass on the freshly extracted printed code and its museum context.</p>
<p>The harness reconstructs six files from their printed sources: three new files and three inherited files. Godot executes model assertions, then synthetic point and button input under a translated and rotated parent. The native probe loads the existing Phi hall and mounts that extracted code there.</p>
<h2>What the test establishes</h2><p>Changing phi leaves the readings and interval intact. Doubling the interval halves the average rate without changing the difference or contribution. Reversing the readings reverses their difference; a negative weight then gives a positive product. ZERO PHI preserves a nonzero difference. KEEP retains its earlier values; LABELS changes text alone. The independent .10/.90 pair with a three-quarter hand position gives phi .5 and product .4.</p>
<p>The installed rail is checked separately through its slider and button signals. Equal magnitudes give equal speed and particle count, opposite directions and zero gravity. Zero disables new emission. The two-second lifetime is checked as a configured value; this is not a pixel-tracked measurement of every particle's death. The wave pattern keeps the same clock, transforms and materials at each rail event, then continues animating afterward.</p>
<h2>What needed correction</h2><p>The old tutorial described hidden receivers, blend shapes and a global attitude towards change. Those were not implemented relationships in this hall. The reflection also said returning toward zero merely slowed release; the installed sign study stops emission at zero. Both texts now follow the actual control.</p>
<p>The first new-code runs passed. A subsequent range review found that the initial bar scale would put the bottom of a full negative contribution through the tabletop. The diagram now spans 1.00 to 1.80 metres at its full ±1 range, above the table's 0.98-metre top. Two added checks cover those extrema. The amended printed code and native captures were rerun.</p>'''
    for title,checks in [('Synthetic input checks',headless['checks']),('Native museum checks',native['checks'])]:
        ghost+=f'<h2>{title}</h2><table><tr><th>Check</th><th>Result</th></tr>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</table>'
    ghost+='<h2>Engine warnings</h2><p>No script or engine errors in the final runs. Existing registry, Jolt solver-bias, renderer and resource-UID warnings remain:</p><pre>'+html.escape('\n'.join(warnings))+'</pre>'
    ghost+='''<h2>Scope and reproduction</h2><p>This is author-operated synthetic reconstruction, not an independent student or headset study. Placement checks cover floor support and the bench approach, not a complete traversal of the room. KEEP is in-memory. The values and intervals are supplied fixtures, not sampled entropy or a model of social openness.</p><pre>python tools/test_qfep_phi.py
python tools/run_encounter_probe.py QFEP_Phi_Term --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_phi_museum.gd
python tools/publish_qfep_phi.py</pre><p><a href="extraction.json">Printed lineage</a> · <a href="headless.json">Headless receipt</a> · <a href="evidence/report.json">Museum receipt</a> · <a href="evidence/stdout.log">Engine log</a> · <a href="latest-run.json">Run summary</a></p>'''
    write('ghost.html',review.page('Phi — ghost student',ghost))
    changes='<h1>Phi: before and after</h1><p>The tutorial reconstructs a signed weighted difference on the carried bench. The reflection corrects zero emission and adds the difference/rate/product distinction. Original artifact code, map data and sequence order are unchanged and source-hash checked.</p>'
    for name in ['tutorial.md','final.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8');new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact diff</summary><pre class="diff">{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+review.linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+review.linked(HALL/name)+'</article></div>'
    write('changes.html',review.page('Phi — changes',changes,True))
    missing=[]
    class Links(HTMLParser):
        def handle_starttag(self, tag, attrs):
            for key,value in attrs:
                if key not in ['href','src'] or not value:continue
                u=urlsplit(value)
                if not u.scheme and u.path and not u.path.startswith('/') and not (OUT/unquote(u.path)).exists():missing.append(value)
    for path in OUT.glob('*.html'):Links().feed(path.read_text(encoding='utf8'))
    assert not missing,missing
    print(json.dumps(summary,indent=2))
    print('Seven review pages checked for local links.')

if __name__=='__main__':main()
