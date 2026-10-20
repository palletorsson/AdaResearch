"""Publish the first QFEP hall with verified reconstruction receipts and native images."""
from datetime import datetime
from pathlib import Path
from urllib.parse import urlsplit, unquote
from html.parser import HTMLParser
import difflib
import hashlib
import html
import json
import os
import re
import shutil
import markdown
from build_qfep_introduction import ROOT, OUT, HALL, STUDY

RUN = ROOT/'ada_run/encounter_pilot/QFEP_Introduction/qfep_reconstruction'
CSS = '''*{box-sizing:border-box}body{margin:0;background:#eeece6;color:#223238;font:18px/1.65 system-ui}main{max-width:1220px;margin:auto;padding:32px}main.wide{max-width:1800px}a{color:#145f70}nav{display:flex;gap:20px;flex-wrap:wrap;border-bottom:1px solid #bec6c4;padding:15px 0;margin-bottom:35px}h1{font:clamp(36px,5vw,68px)/1.1 Georgia;margin:.45em 0}h2{font:32px/1.25 Georgia;margin-top:1.5em}h3{font-size:23px}p{max-width:900px}.tag{font-size:13px;letter-spacing:.13em;text-transform:uppercase}.lead{font-size:24px}.note{padding:24px;background:#dbe8e3}.grid,.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.card,.pair article{background:#fff;padding:24px;min-width:0}.pair article{max-height:85vh;overflow:auto}.pair h1{font-size:38px}.pair pre{font-size:13px}img{width:100%;height:auto;display:block}figure{margin:28px 0}figcaption{font-size:15px;color:#49606a;margin-top:8px}pre{overflow:auto;padding:20px;background:#152c37;color:#eef4ef;font:14px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;overflow-wrap:anywhere}pre code{font:inherit}table{width:100%;border-collapse:collapse;font-size:16px}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #b6c4c7}details{margin:18px 0}summary{cursor:pointer;font-weight:600}.diff{background:#fff;color:#233;white-space:pre-wrap}ul,ol{padding-left:1.5em}@media(max-width:900px){main{padding:18px}.pair,.grid{grid-template-columns:1fr}.pair article{max-height:none}}@media print{nav{display:none}.pair{display:block}.pair article{max-height:none;overflow:visible}pre{white-space:pre-wrap}}'''

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def write(name,text): (OUT/name).write_text(text,encoding='utf8')
def md(text): return markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])

def linked(source, text=None):
    if text is None: text = source.read_text(encoding='utf8')
    def replace(match):
        target = match.group(2)
        url = urlsplit(target)
        if url.scheme or target.startswith(('#','/')): return match.group(0)
        path = (source.parent/url.path).resolve()
        local = os.path.relpath(path,OUT).replace('\\','/')
        if url.fragment: local += '#'+url.fragment
        return match.group(1)+local+match.group(3)
    return md(re.sub(r'(\]\()([^\s)]+)(\))',replace,text))

def page(title,body,wide=False):
    links=[('index.html','Report'),('parallel.html','Facing pages'),('tutorial.html','Tutorial'),('final.html','Reflection'),('ghost.html','Ghost test'),('plan.html','Eight-hall plan'),('changes.html','Changes')]
    nav=''.join(f'<a href="{u}">{t}</a>' for u,t in links)
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><main class="{"wide" if wide else ""}"><nav>{nav}</nav>{body}</main></body></html>'

def main():
    headless=json.loads((OUT/'headless.json').read_text(encoding='utf8'))
    native=json.loads((RUN/'report.json').read_text(encoding='utf8'))
    assert headless['passed'] and native['passed']
    assert headless['extraction_sha256']==sha(OUT/'extraction.json'),'stale headless receipt'
    extraction=json.loads((OUT/'extraction.json').read_text(encoding='utf8'))
    for name,entry in extraction['files'].items():
        printed=(OUT/'learner'/name).read_text(encoding='utf8')
        assert hashlib.sha256(printed.encode('utf8')).hexdigest()==entry['sha256'],name
        assert (OUT/'learner'/name).read_text(encoding='utf8')==(STUDY/name).read_text(encoding='utf8'),name
    for key in ['tested_code','runtime_sources']:
        for path,digest in native['observations'][key].items():
            assert sha(ROOT/path.removeprefix('res://'))==digest,path
    log=(RUN/'stdout.log').read_text(encoding='utf8',errors='replace')
    errors=[line for line in log.splitlines() if re.search(r'(SCRIPT ERROR|^ERROR:|Assertion failed)',line)]
    assert not errors,errors
    warnings=sorted(set(line for line in log.splitlines() if line.startswith('WARNING:')))
    (OUT/'images').mkdir(exist_ok=True)
    (OUT/'evidence').mkdir(exist_ok=True)
    for name in ['opening','comparison','hall','existing']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md']:
        shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=linked(HALL/'tutorial.md')
    final=linked(HALL/'final.md')
    count=len(headless['checks'])+headless['printed_assertions']+len(native['checks'])
    run={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_Introduction','passed':True,
         'printed_assertions':headless['printed_assertions'],'synthetic_input_checks':len(headless['checks']),
         'native_checks_including_captures':len(native['checks']),'warnings':warnings,
         'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',plan]},
         'scope':'First QFEP hall only. Printed reconstruction and author-operated synthetic inputs. Remaining seven halls pending; no headset or independent learner claim.'}
    write('latest-run.json',json.dumps(run,indent=2))
    write('tutorial.html',page('Four inputs — tutorial',tutorial))
    write('final.html',page('Four inputs — reflection',final))
    write('parallel.html',page('Four inputs — facing pages','<p class="tag">QFEP Laboratory · Hall 1 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',page('QFEP — eight-hall plan',linked(plan)))
    intro='''<p class="tag">12 October 2026 · QFEP Laboratory · first hall</p>
<h1>Four inputs, one result</h1>
<p class="lead">The same sphere gains a new job: change one contribution while keeping the others available for inspection.</p>
<p>Post-Crisis closes the main spine. QFEP Laboratory sits just before it and still needed its runnable tutorial pass. This starts that work with Introduction; the other seven halls are planned, not yet reconstructed.</p>
<figure><a href="images/comparison.png"><img src="images/comparison.png" alt="The inherited sphere at four coloured bars, pale retained marks and five controls in the actual museum"></a><figcaption>Native Godot capture. PAIR B is visible; pale marks retain PAIR A. Both return 0.450.</figcaption></figure>
<div class="grid"><section class="card"><h2>Tutorial</h2><p>Complete printed model, interaction script and assertions. Carry the sphere and line renderer from Euclid, and the initialized bench from Russell. The original four-rail museum workbench remains beside the student's working copy.</p><p><a href="tutorial.html">Read the tutorial</a> · <a href="parallel.html">Read both pages</a></p></section><section class="card"><h2>Reflection</h2><p>The existing argument stays: a total cannot tell us how its inputs compensated. One new paragraph asks when equality under this calculation warrants substituting one arrangement for another purpose.</p><p><a href="final.html">Read the reflection</a> · <a href="changes.html">See exact changes</a></p></section></div>
<h2>What the student does</h2><p>Select a term, lift the sphere, release, KEEP. Compare two supplied arrangements, then make a third arrangement with the same total using the hand control. Set lambda to zero and show that E still changes even when its contribution vanishes.</p>
<p>The formula uses supplied dimensionless values and a fixed change of 0.3. It does not measure free energy, detect a physical phase or calculate a desirable social order.</p>'''
    intro+=f'<div class="note"><strong>{count} checks passed:</strong> {headless["printed_assertions"]} printed assertions, {len(headless["checks"])} synthetic input checks, and {len(native["checks"])} museum checks including captures. <a href="ghost.html">Read the scope and receipts.</a> This is an author-operated reconstruction, not a headset or independent learner test.</div>'
    intro+='''<figure><a href="images/hall.png"><img src="images/hall.png" alt="Learner bench beside the retained QFEP workbench in the museum hall"></a><figcaption>The supplied lesson launcher mounts this working copy in a checked bay. The normal museum map was not rewritten.</figcaption></figure><h2>What follows</h2><p><strong>F Term:</strong> keep a seeded sample fixed, change its predictor, and distinguish observed mistakes from expected mistakes and entropy. The thread through all eight halls is to keep a parameter, a result and its interpretation distinguishable.</p><p><a href="plan.html">Read the eight-hall plan</a> · <a href="plan.md">Editable plan file</a></p>'''
    write('index.html',page('QFEP — first working lesson',intro))
    ghost=f'''<p class="tag">Ghost student · Introduction only</p><h1>Reconstruct, predict, compare</h1><p class="lead">{count} checks pass on the code printed in the book.</p><p>Six files were freshly extracted: three new files from Introduction and three unchanged carried files from Euclid and Russell. The prepared museum supplies XRTools and the real button scene. The test operates the inherited sphere under a translated and rotated parent, then mounts the same extracted lesson in the actual hall.</p><p>The independent task is a third arrangement with total 0.45. The synthetic hand forms it without the PAIR B button. This tests the available operation; it cannot establish a person's understanding of why it works.</p><h2>What failed first</h2><p>Equal totals could display a signed negative zero. The lesson now normalizes only the displayed difference at its three-decimal precision. Stored values are unchanged. The native harness also tried to compile XRTools-dependent code before its autoloads existed; loading the lesson after startup fixed that harness error. A passing check count alone was insufficient: script errors in the engine log also had to be absent.</p><p><a href="first-headless-failure.json">First display failure</a> · <a href="first-native-load.log">First harness load log</a></p>'''
    for title,checks in [('Synthetic input checks',headless['checks']),('Native museum checks',native['checks'])]:
        ghost+=f'<h2>{title}</h2><table><thead><tr><th>Check</th><th>Result</th></tr></thead><tbody>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</tbody></table>'
    ghost+=f'<h2>Engine warnings</h2><p>No script or engine errors in the final run. Retained warnings are listed below; the rendered probe uses the compatibility renderer.</p><pre>{html.escape(chr(10).join(warnings))}</pre>'
    ghost+='''<h2>Limits and reproduction</h2><p>No physical headset reach, grip, comfort or independent learner study was performed. KEEP retains one arrangement in memory for this run; it does not write a disk record. The museum check verifies supported floor and an unobstructed approach at the supplied bench placement, not every route through the building.</p><pre>python tools/test_qfep_introduction.py
python tools/run_encounter_probe.py QFEP_Introduction --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_introduction_museum.gd
python tools/publish_qfep_introduction.py</pre><p><a href="extraction.json">Extraction and lineage hashes</a> · <a href="headless.json">Assertions/input receipt</a> · <a href="evidence/report.json">Native receipt</a> · <a href="evidence/stdout.log">Final engine log</a> · <a href="latest-run.json">Run summary</a></p>'''
    write('ghost.html',page('QFEP — ghost student',ghost))
    changes='<h1>Changes to the first hall</h1><p>The tutorial replaces imagined term-sphere snippets with a complete reconstruction. The reflection gains one paragraph. Existing museum artifact code, map data and sequence order were not edited.</p>'
    for name in ['tutorial.md','final.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8')
        new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact text diff</summary><pre class="diff">{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+linked(HALL/name)+'</article></div>'
    write('changes.html',page('QFEP — before and after',changes,True))
    missing=[]
    class Links(HTMLParser):
        def handle_starttag(self, tag, attrs):
            for key,value in attrs:
                if key not in ['href','src'] or not value: continue
                target=urlsplit(value)
                if target.scheme or not target.path or target.path.startswith('/'): continue
                if not (OUT/unquote(target.path)).exists(): missing.append(value)
    for path in OUT.glob('*.html'):
        Links().feed(path.read_text(encoding='utf8'))
    assert not missing,missing
    print(f'Checked local links in {len(list(OUT.glob("*.html")))} pages.')
    print(json.dumps(run,indent=2))

if __name__=='__main__': main()
