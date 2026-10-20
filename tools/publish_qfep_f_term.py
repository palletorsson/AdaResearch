"""Publish F Term's full texts, native comparisons and bounded ghost-student evidence."""
from datetime import datetime
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
from build_qfep_f_term import ROOT, STUDY, OUT, HALL, prepare
import publish_qfep_introduction as review

RUN=ROOT/'ada_run/encounter_pilot/QFEP_F_Term/qfep_reconstruction'
# Reuse the facing-page style and source-relative link resolver; no other report is written.
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
    for name in ['opening','expect-zero','expect-one','hall','existing']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md']:shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=review.linked(HALL/'tutorial.md');final=review.linked(HALL/'final.md')
    n_model=headless['printed_assertions'];n_input=len(headless['checks']);n_native=len(native['checks'])
    total=n_model+n_input+n_native
    summary={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_F_Term','passed':True,
        'printed_assertions':n_model,'synthetic_input_checks':n_input,'native_checks_including_captures':n_native,
        'warnings':warnings,'preserved_sources':preserved,'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',plan]},
        'scope':'F Term only, after completed Introduction. Six halls pending. Author-operated synthetic tests, not headset or independent learner evidence.'}
    write('latest-run.json',json.dumps(summary,indent=2))
    write('tutorial.html',review.page('F Term — tutorial',tutorial))
    write('final.html',review.page('F Term — reflection',final))
    write('parallel.html',review.page('F Term — facing pages','<p class="tag">QFEP Laboratory · Hall 2 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',review.page('QFEP — current route',review.linked(plan)))
    body='''<p class="tag">12 October 2026 · QFEP Laboratory · Hall 2 of 8</p><h1>Change the guess.<br>Keep the grid.</h1>
<p class="lead">A better prediction can come from changing an expectation while the observed world stays still.</p>
<p>We continue from Introduction's retained inputs. The same sphere now controls a source probability. The student keeps one seeded sample, selects a constant guess and compares three distinct readings: entropy, expected error and observed mistakes.</p>
<div class="note"><strong>Native comparison:</strong> p stays at 0.9. The bits stay fixed. EXPECT 0 makes 56 mistakes; EXPECT 1 makes 8. Source entropy remains 0.469 bits/symbol.</div>
<p><button type="button" onclick="showGuess(0)">Show EXPECT 0</button> <button type="button" onclick="showGuess(1)">Show EXPECT 1</button></p>
<figure><a id="full" href="images/expect-zero.png"><img id="compare" src="images/expect-zero.png" alt="The same 64-cell grid in the museum, with amber marks showing incorrect guesses"></a><figcaption id="caption">EXPECT 0: expected error 90%; observed mistakes 56/64 (87.5%).</figcaption></figure>
<script>function showGuess(n){const image='images/expect-'+(n?'one':'zero')+'.png';document.getElementById('compare').src=image;document.getElementById('full').href=image;document.getElementById('caption').textContent=n?'EXPECT 1: expected error 10%; observed mistakes 8/64 (12.5%). The bits and H are unchanged.':'EXPECT 0: expected error 90%; observed mistakes 56/64 (87.5%).';}</script>
<div class="grid"><section class="card"><h2>Tutorial</h2><p>Complete printed model, visible grid and assertions. Reuse the existing PointBody and initialized bench. The hand changes p; the guess buttons change only the mistake marks. KEEP retains the reading and bits.</p><p><a href="tutorial.html">Read tutorial</a> · <a href="parallel.html">Facing pages</a></p></section><section class="card"><h2>Reflection</h2><p>The existing reflection stays grounded in the installed workbench. A new paragraph distinguishes choosing a better expectation on this evidence from testing it on what comes next.</p><p><a href="final.html">Read reflection</a> · <a href="changes.html">Before and after</a></p></section></div>
<h2>What changed in the teaching</h2><p>The old tutorial equated absolute error with free energy and described an unimplemented dark-room proof. The new lesson reconstructs the actual hall's prediction experiment. Source H, expected mistakes and observed mistakes keep separate names and units. This predictor is selected by the player; it is not trained.</p>
<p>The working copy uses 64 draws for a legible tabletop. They match the first 64 of the original workbench's 256 draws. Counts are compared on that shared prefix; the different sample sizes stay explicit.</p>'''
    body+=f'<div class="note"><strong>{total} checks passed:</strong> {n_model} printed assertions, {n_input} synthetic input checks, {n_native} native checks including captures. <a href="ghost.html">Read the evidence and limits.</a> Physical headset and independent learner testing remain open.</div>'
    body+='''<figure><a href="images/hall.png"><img src="images/hall.png" alt="The learner's grid and sphere mounted beside the existing F Term exhibits"></a><figcaption>Actual museum capture. The supplied F6 scene adds the working copy for the lesson; normal hall placement and existing artifacts remain unchanged.</figcaption></figure>
<h2>What travels onward</h2><p><strong>E Term is next.</strong> Before calculating uncertainty, we must specify the alternatives being counted. The same sphere and the habit of retaining evidence continue into the branching fan.</p><p><a href="../2026-10-12-qfep-four-inputs/index.html">Previous: Introduction</a> · <a href="plan.html">Eight-hall plan</a> · <a href="plan.md">Editable plan</a></p>'''
    write('index.html',review.page('F Term — change the guess',body))
    ghost=f'''<p class="tag">Ghost student · F Term</p><h1>Keep the evidence fixed</h1><p class="lead">{total} checks pass on the freshly extracted printed code.</p><p>The extraction contains three new files and three unchanged inherited files. The harness exercises the actual PointBody under a translated and rotated parent. In the real museum it also compares the learner's draws with the installed workbench and checks mistake counts on the same prefix.</p><p>The independent exercise uses the sphere to choose another p, predicts which guess should fare better and compares both. The synthetic run uses p=.35 and checks complementary counts. This verifies the operations available to a learner, not the learner's understanding.</p><h2>Checks that matter</h2><p>Changing the guess must preserve p, stored draws, bits, source H and displayed bit colours. Every amber mark must correspond to a counted mismatch. Reversing a binary guess makes the two mistake counts sum to the sample size. Returning to a prior p must reproduce its bits. KEEP must retain the earlier probability, guess, reading and bit record.</p><p>The deterministic four-draw assertion deliberately produces 25% observed error at p=.1 against 10% expected error. It tests the difference without depending on random chance to produce a discrepancy.</p><h2>What was fixed</h2><p>The first native harness did not parse because a boolean inferred from a dynamically loaded artifact had no statically known type. An explicit bool annotation fixed the harness. The printed lesson passed its first headless run. Both final logs are checked for script/engine errors, not just a passing count.</p><p><a href="first-native-load.log">First native harness failure</a></p>'''
    for title,checks in [('Synthetic input checks',headless['checks']),('Native museum checks',native['checks'])]:
        ghost+=f'<h2>{title}</h2><table><tr><th>Check</th><th>Result</th></tr>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</table>'
    ghost+='<h2>Engine warnings</h2><p>No script or engine errors in the final run. The compatibility capture retains these warnings:</p><pre>'+html.escape('\n'.join(warnings))+'</pre>'
    ghost+='''<h2>Scope and reproduction</h2><p>No headset ergonomics or independent learner study was performed. The installed artifact uses 256 draws; the working copy uses 64. KEEP is an in-memory record for this run. The sample was not used to train a model. The checked bay has floor support and an unobstructed approach; that does not certify all walking routes.</p><pre>python tools/test_qfep_f_term.py
python tools/run_encounter_probe.py QFEP_F_Term --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_f_museum.gd
python tools/publish_qfep_f_term.py</pre><p><a href="extraction.json">Printed lineage</a> · <a href="headless.json">Headless receipt</a> · <a href="evidence/report.json">Museum receipt</a> · <a href="evidence/stdout.log">Engine log</a> · <a href="latest-run.json">Run summary</a></p>'''
    write('ghost.html',review.page('F Term — ghost student',ghost))
    changes='<h1>F Term: before and after</h1><p>The tutorial is reconstructed around the existing prediction workbench. The reflection gains one paragraph. Map data, artifact implementation and sequence order are unchanged and source-hash checked.</p>'
    for name in ['tutorial.md','final.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8');new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact diff</summary><pre class="diff">{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+review.linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+review.linked(HALL/name)+'</article></div>'
    write('changes.html',review.page('F Term — changes',changes,True))
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
