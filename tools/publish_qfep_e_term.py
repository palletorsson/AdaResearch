"""Publish E Term's printed reconstruction, native comparisons and test receipts."""
from datetime import datetime
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
from build_qfep_e_term import ROOT, OUT, HALL, prepare
import publish_qfep_introduction as review

RUN=ROOT/'ada_run/encounter_pilot/QFEP_E_Term/qfep_reconstruction'
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
    assert all(sha(ROOT/path)==digest for path,digest in preserved.items()),'unreviewed core runtime change'
    log=(RUN/'stdout.log').read_text(encoding='utf8',errors='replace')
    errors=[line for line in log.splitlines() if re.search(r'(SCRIPT ERROR|^ERROR:|Assertion failed)',line)]
    assert not errors,errors
    warnings=sorted(set(line for line in log.splitlines() if line.startswith('WARNING:')))
    for folder in ['images','evidence']:(OUT/folder).mkdir(exist_ok=True)
    for name in ['opening','open','pruned','two','hall','existing']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md']:shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=review.linked(HALL/'tutorial.md');final=review.linked(HALL/'final.md')
    n_model=headless['printed_assertions'];n_input=len(headless['checks']);n_native=len(native['checks'])
    total=n_model+n_input+n_native
    summary={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_E_Term','passed':True,
        'printed_assertion_statements':n_model,'synthetic_input_checks':n_input,'native_checks_including_captures':n_native,
        'warnings':warnings,'preserved_sources':preserved,'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',plan]},
        'runtime_fix':'microstate_counter: replace unsupported %e string formatting with explicit mantissa/exponent; no model change',
        'scope':'E Term only, following Introduction and F Term. Five halls pending. Author-operated synthetic tests, not headset or independent learner evidence.'}
    write('latest-run.json',json.dumps(summary,indent=2))
    write('tutorial.html',review.page('E Term — tutorial',tutorial))
    write('final.html',review.page('E Term — reflection',final))
    write('parallel.html',review.page('E Term — facing pages','<p class="tag">QFEP Laboratory · Hall 3 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',review.page('QFEP — current route',review.linked(plan)))
    body='''<p class="tag">12 October 2026 · QFEP Laboratory · Hall 3 of 8</p><h1>Count the endings.<br>Keep the paths.</h1>
<p class="lead">A count can change without telling us which possibilities disappeared.</p>
<p>The same sphere now selects one, two or three continuations at each of four stages. Its working copy sits inside the existing E hall. The lesson carries forward the initialized bench, cylinder renderer and practice of retaining evidence.</p>
<div class="note"><strong>Native comparison:</strong> OPEN holds 81 endings. PRUNE closes 18 branches and removes 54 endings, leaving 27. The remaining tips stay in their original slots; KEEP retains the full path list.</div>
<p><button type="button" onclick="showFan(false)">OPEN · 81 endings</button> <button type="button" onclick="showFan(true)">PRUNE · 27 endings</button></p>
<figure><a id="full" href="images/open.png"><img id="compare" src="images/open.png" alt="The sphere and four-stage tree on the student's bench inside Endless Museum"></a><figcaption id="caption">OPEN: 81 equally weighted endings, H = 4.394 nats. Cyan tips are completed paths.</figcaption></figure>
<script>function showFan(pruned){const image='images/'+(pruned?'pruned':'open')+'.png';document.getElementById('compare').src=image;document.getElementById('full').href=image;document.getElementById('caption').textContent=pruned?'PRUNE: 18 amber caps remove 54 endings. 27 survive; H = 3.296 nats. KEEP still records the original 81.':'OPEN: 81 equally weighted endings, H = 4.394 nats. Cyan tips are completed paths.';}</script>
<div class="grid"><section class="card"><h2>Tutorial</h2><p>Three complete printed files: path enumeration, the visible interactive bench and assertions. Recursion has an explicit stopping condition. Closures and leaves have separate records. Entropy states its unit and equal-weight assumption.</p><p><a href="tutorial.html">Read tutorial</a> · <a href="parallel.html">Facing pages</a></p></section><section class="card"><h2>Reflection</h2><p>The existing reflection remains. One added paragraph asks which endings a count refers to: different exclusions can produce the same count and entropy.</p><p><a href="final.html">Read reflection</a> · <a href="changes.html">Before and after</a></p></section></div>
<h2>How the progression holds</h2><p>Introduction retained inputs behind a total. F Term kept evidence fixed while changing a prediction. E Term now keeps the identity of the alternatives being counted. It changes the outcome inventory, whereas F changed the probabilities over the same two bit values.</p>
<p>The old tutorial described an unimplemented random-motion meter and equated motion and spread with entropy. This lesson reconstructs the installed fan. H = ln(N) assumes equal leaf weights; it is not a movement rate or a numerical measure of freedom.</p>'''
    body+=f'<div class="note"><strong>{total} checks passed:</strong> {n_model} printed assertion statements, {n_input} synthetic input checks and {n_native} native checks including captures. Assertions inside loops run for multiple paths. <a href="ghost.html">Evidence and limits.</a> Headset and independent learner testing remain open.</div>'
    body+='''<figure><a href="images/hall.png"><img src="images/hall.png" alt="Student's branching bench with the installed fan and neighbouring works in the museum"></a><figcaption>Actual Godot capture. The supplied F6 scene adds this working copy for the lesson. The permanent map, fan implementation and sequence order are preserved.</figcaption></figure>
<p>A discovered display bug in the neighbouring microstate counter used an unsupported scientific-notation formatter. It now builds the mantissa and exponent explicitly. Its calculation is unchanged; the final native run has no script or engine errors.</p>
<h2>What travels onward</h2><p><strong>Lambda Spectrum is next.</strong> Changing a weight need not change the alternatives themselves. We will distinguish weighting a term from the installed hall's movable recommendation.</p><p><a href="../2026-10-12-qfep-change-the-guess/index.html">Previous: F Term</a> · <a href="plan.html">Eight-hall plan</a> · <a href="plan.md">Editable plan</a></p>'''
    write('index.html',review.page('E Term — count the endings',body))
    ghost=f'''<p class="tag">Ghost student · E Term</p><h1>Which endings remain?</h1><p class="lead">{total} checks pass on the freshly extracted printed code.</p><p>Three new files and three unchanged inherited files were extracted from their tutorial fences. The supplied harness runs actual Godot assertions, then synthetic point and button inputs under a translated and rotated parent. A separate native run loads the real museum and compares the student's tree with the installed fan.</p>
<h2>What the tests establish</h2><p>ONE, OPEN and PRUNE agree with the installed fan on counts, closures, removed endings, entropy and the equal-weight declaration. A second comparison counts actual leaf and closure meshes. The student's retained path list survives rebuilding. Survivors keep their positions. All 120 full-tree cylinders connect their intended endpoints. Hand motion selects sixteen endings without using the TWO button.</p><p>The independent exercise asks a learner to select a closed prefix and name its three missing completions. The assertions verify that such a comparison is possible and correct. They cannot establish that a learner understands it.</p>
<h2>What needed fixing</h2><p>The discovery run exposed an existing counter display error: GDScript's format operator does not support %e. Explicit mantissa/exponent formatting fixes the display without changing the counter model. The printed E example passed its first headless run. The first overview camera sat beyond the room wall: its capture passed the file check but failed visual inspection. Moving the camera inside the room fixed the image. The final native checks were rerun after that change.</p><p><a href="first-counter-error.log">Original counter error log</a> · <a href="first-overview-obstructed.png">Rejected overview</a></p>'''
    for title,checks in [('Synthetic input checks',headless['checks']),('Native museum checks',native['checks'])]:
        ghost+=f'<h2>{title}</h2><table><tr><th>Check</th><th>Result</th></tr>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</table>'
    ghost+='<h2>Engine warnings</h2><p>No script or engine errors in the final run. Retained warnings:</p><pre>'+html.escape('\n'.join(warnings))+'</pre>'
    ghost+='''<h2>Scope and reproduction</h2><p>This is author-operated reconstruction, not an independent student or headset study. KEEP is in-memory. The checked bay has supported floor and a clear approach, not a certification of every walking route. Equal leaf weights are a declared model assumption; the test does not prove that real journeys are equally likely.</p><pre>python tools/test_qfep_e_term.py
python tools/run_encounter_probe.py QFEP_E_Term --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_e_museum.gd
python tools/publish_qfep_e_term.py</pre><p><a href="extraction.json">Printed lineage</a> · <a href="headless.json">Headless receipt</a> · <a href="evidence/report.json">Museum receipt</a> · <a href="evidence/stdout.log">Engine log</a> · <a href="latest-run.json">Run summary</a></p>'''
    write('ghost.html',review.page('E Term — ghost student',ghost))
    changes='<h1>E Term: before and after</h1><p>The tutorial now reconstructs the actual fan; the reflection gains one paragraph about path identity. Map data, fan implementation and sequence order are source-hash checked. A separate display-only repair removes the unsupported %e formatter in microstate_counter.gd.</p>'
    for name in ['tutorial.md','final.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8');new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact diff</summary><pre class="diff">{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+review.linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+review.linked(HALL/name)+'</article></div>'
    write('changes.html',review.page('E Term — changes',changes,True))
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
