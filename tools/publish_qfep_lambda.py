"""Publish Lambda's paired texts, native images and bounded reconstruction evidence."""
from datetime import datetime
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
from build_qfep_lambda import ROOT, OUT, HALL, prepare
import publish_qfep_introduction as review

RUN=ROOT/'ada_run/encounter_pilot/QFEP_Lambda_Spectrum/qfep_reconstruction'
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
    for name in ['opening','strip-moved','weight-changed','hall','existing','existing-moved']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md']:shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=review.linked(HALL/'tutorial.md');final=review.linked(HALL/'final.md')
    n_model=headless['printed_assertions'];n_input=len(headless['checks']);n_native=len(native['checks'])
    total=n_model+n_input+n_native
    summary={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_Lambda_Spectrum','passed':True,
        'printed_assertion_statements':n_model,'synthetic_input_checks':n_input,'native_checks_including_captures':n_native,
        'warnings':warnings,'preserved_sources':preserved,'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',plan]},
        'scope':'Lambda only, fourth reconstructed QFEP hall. Four halls pending. Author-operated synthetic tests; no headset or independent learner evidence.'}
    write('latest-run.json',json.dumps(summary,indent=2))
    write('tutorial.html',review.page('Lambda — tutorial',tutorial))
    write('final.html',review.page('Lambda — reflection',final))
    write('parallel.html',review.page('Lambda — facing pages','<p class="tag">QFEP Laboratory · Hall 4 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',review.page('QFEP — current route',review.linked(plan)))
    body='''<p class="tag">12 October 2026 · QFEP Laboratory · Hall 4 of 8</p><h1>Move the recommendation.<br>Keep the surroundings.</h1>
<p class="lead">The same sphere edits two different things: a weight in a calculation, or a recommendation in space.</p>
<p>The lesson reuses Introduction's complete calculation and the inherited bench. Twenty-four cubes are built once. The green strip can move beneath them; changing the arithmetic weight can change a score while the strip stays still.</p>
<div class="note"><strong>Three states, one comparison:</strong> the strip moves from 0.35 to 0.80 while the total stays 0.450. Then lambda changes from 0.5 to 1: the total becomes 0.350, and the strip stays at 0.80.</div>
<p><button type="button" onclick="showState(0)">Opening</button> <button type="button" onclick="showState(1)">Move strip</button> <button type="button" onclick="showState(2)">Change weight</button></p>
<figure><a id="full" href="images/opening.png"><img id="compare" src="images/opening.png" alt="Same sphere, fixed cubes and a movable green recommendation inside the museum"></a><figcaption id="caption">Opening: lambda 0.50, strip 0.35, total 0.450. KEEP records these values.</figcaption></figure>
<script>function showState(n){const names=['opening','strip-moved','weight-changed'];const captions=['Opening: lambda 0.50, strip 0.35, total 0.450. KEEP records these values.','Move strip: recommendation 0.80. The 24 cubes and total 0.450 are unchanged. Amber marks the earlier recommendation.','Change weight: lambda 1.00 gives total 0.350. Recommendation remains 0.80; all cubes retain their transforms and colours.'];const src='images/'+names[n]+'.png';document.getElementById('compare').src=src;document.getElementById('full').href=src;document.getElementById('caption').textContent=captions[n];}</script>
<div class="grid"><section class="card"><h2>Tutorial</h2><p>Complete model, scene script and assertions; four unchanged carried files. WEIGHT and STRIP select the sphere's job. KEEP retains both values, RETURN restores only the strip, ZERO L suppresses E's contribution without deleting E.</p><p><a href="tutorial.html">Read tutorial</a> · <a href="parallel.html">Facing pages</a></p></section><section class="card"><h2>Reflection</h2><p>The existing argument about an authored invitation stays. One new paragraph asks what must stay fixed for a comparison to be informative, and what the control cannot reveal about a visitor's reasons.</p><p><a href="final.html">Read reflection</a> · <a href="changes.html">Before and after</a></p></section></div>
<h2>How this follows E Term</h2><p>E Term distinguished the inventory of endings from its entropy assumption. Lambda now distinguishes that inventory from a weight or recommendation. The lesson deliberately names the supplied E input: 0.2 in Introduction's dimensionless console. It does not quietly replace that input with ln(81) or claim to measure entropy from the cube field.</p>
<p>The old tutorial said walking changed lambda, reshaped the world and made creatures disappear outside a preferred band. Those connections are not implemented in this hall. The new lesson teaches the actual independent recommendation control and compares it with the carried arithmetic model.</p>'''
    body+=f'<div class="note"><strong>{total} checks passed:</strong> {n_model} printed assertions, {n_input} synthetic input checks and {n_native} native checks including captures. <a href="ghost.html">Evidence and limits.</a> Physical headset testing remains open.</div>'
    body+='''<h2>Back at body scale</h2><figure><a href="images/existing-moved.png"><img src="images/existing-moved.png" alt="The original walk-in spectrum with its recommendation moved toward one side"></a><figcaption>The existing seven-metre-wide artifact, after moving its LIT STRIP rail. Rows retain their arrangement; its animation continues independently. The learner's 1.8-metre-wide copy uses the same normalized coordinate mapping.</figcaption></figure>
<figure><a href="images/hall.png"><img src="images/hall.png" alt="Learner bench beside the retained full-size cube spectrum"></a><figcaption>The supplied F6 lesson scene mounts the working copy in a checked side bay. The permanent map, sequence and original artifact are unchanged.</figcaption></figure>
<p>The engine reported an existing blocked authored entrance and used its safe fallback. The learner bay passed floor/support checks; the whole walking route and headset reach have not been validated.</p>
<h2>What travels onward</h2><p><strong>Phi Term is next.</strong> Keep a parameter's sign separate from the language used to interpret it. Compare earlier and later readings, and distinguish a signed difference from a rate over an interval.</p><p><a href="../2026-10-12-qfep-count-the-endings/index.html">Previous: E Term</a> · <a href="plan.html">Eight-hall plan</a> · <a href="plan.md">Editable plan</a></p>'''
    write('index.html',review.page('Lambda — move the recommendation',body))
    ghost=f'''<p class="tag">Ghost student · Lambda Spectrum</p><h1>What changed, what stayed?</h1><p class="lead">{total} checks pass on the freshly extracted printed code.</p><p>Three new files and four inherited files were extracted from the book. Godot runs the model assertions, then the same point under a translated and rotated parent. The native probe loads the existing museum, operates its actual LIT STRIP and RETURN signals, and mounts the extracted working copy.</p>
<h2>The invariants</h2><p>Moving a recommendation preserves the arithmetic inputs and score. Changing a weight preserves the strip. Every miniature cube keeps its identity, transform and colour. KEEP retains its copied values. RETURN restores only the recommendation. The independent quarter/three-quarter hand exercise produces .35/ .65 and symmetric offsets without using a preset.</p><p>The installed artifact is checked separately: each rail event preserves its row meshes, instance transforms and colours, material values, drifter poses, animation clock, configured structural lambda and capture camera. A subsequent timed check confirms animation continues. The seven-metre hall and 1.8-metre model agree on normalized position; they do not have identical geometry.</p>
<h2>What failed first</h2><p>The first native RETURN assertion demanded a weight of exactly 1.0 after hand motion through world/local transforms. The actual value was 0.999999930461248. RETURN had correctly preserved it. The test now compares the value immediately before and after RETURN exactly; the separate target-height test uses approximate equality. This corrects the test's contract without rounding or changing the lesson's data.</p><p><a href="first-native-failure.json">First native failure and actual values</a></p>'''
    for title,checks in [('Synthetic input checks',headless['checks']),('Native museum checks',native['checks'])]:
        ghost+=f'<h2>{title}</h2><table><tr><th>Check</th><th>Result</th></tr>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</table>'
    ghost+='<h2>Engine warnings</h2><p>No script or engine errors in the final run. The existing authored entry reports a blocked frame and uses its safe fallback. Other retained warnings:</p><pre>'+html.escape('\n'.join(warnings))+'</pre>'
    ghost+='''<h2>Scope and reproduction</h2><p>This is author-operated synthetic reconstruction, not an independent learner or headset study. The complete walking route is not certified. KEEP is in-memory. The miniature is static; the installed hall retains its independent animation. Both are authored comparisons, not entropy measurements, optimizers or evidence that a preferred middle is universally better.</p><pre>python tools/test_qfep_lambda.py
python tools/run_encounter_probe.py QFEP_Lambda_Spectrum --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_lambda_museum.gd
python tools/publish_qfep_lambda.py</pre><p><a href="extraction.json">Printed lineage</a> · <a href="headless.json">Headless receipt</a> · <a href="evidence/report.json">Museum receipt</a> · <a href="evidence/stdout.log">Engine log</a> · <a href="latest-run.json">Run summary</a></p>'''
    write('ghost.html',review.page('Lambda — ghost student',ghost))
    changes='<h1>Lambda: before and after</h1><p>The tutorial reconstructs the independent recommendation and contrasts it with the carried arithmetic weight. The reflection gains one paragraph. Original artifact code, map data and sequence order are unchanged and source-hash checked.</p>'
    for name in ['tutorial.md','final.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8');new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact diff</summary><pre class="diff">{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+review.linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+review.linked(HALL/name)+'</article></div>'
    write('changes.html',review.page('Lambda — changes',changes,True))
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
