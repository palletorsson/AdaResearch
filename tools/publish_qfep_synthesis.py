"""Publish the final QFEP lesson with code-bound tests and native museum images."""
from datetime import datetime
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import hashlib
import html
import json
import re
import shutil
from build_qfep_synthesis import ROOT, OUT, HALL, prepare
import publish_qfep_introduction as review

RUN=ROOT/'ada_run/encounter_pilot/QFEP_Synthesis/qfep_reconstruction'
review.OUT=OUT

def write(name,text): (OUT/name).write_text(text,encoding='utf8')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def figure(name,caption):
    return f'<figure><a href="images/{name}.png"><img src="images/{name}.png" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'

def main():
    prepare()
    h=json.loads((OUT/'headless.json').read_text(encoding='utf8'))
    n=json.loads((RUN/'report.json').read_text(encoding='utf8'))
    assert h['passed'] and n['passed']
    assert h['extraction_sha256']==sha(OUT/'extraction.json'),'stale headless receipt'
    for group in ['tested_code','runtime_sources']:
        for path,digest in n['observations'][group].items():
            assert sha(ROOT/path.removeprefix('res://'))==digest,path
    preserved=json.loads((OUT/'preserved-sources.json').read_text(encoding='utf8'))
    assert all(sha(ROOT/path)==digest for path,digest in preserved.items()),'installed sources changed'
    log=(RUN/'stdout.log').read_text(encoding='utf8',errors='replace')
    errors=[s for s in log.splitlines() if re.search(r'(SCRIPT ERROR|^ERROR:|Assertion failed)',s)]
    assert not errors,errors
    warnings=sorted(set(s for s in log.splitlines() if s.startswith('WARNING:')))
    for name in ['images','evidence']:(OUT/name).mkdir(exist_ok=True)
    for name in ['opening','steady','comparison-a','comparison-b','hall','existing']:
        shutil.copy2(RUN/(name+'.png'),OUT/'images'/(name+'.png'))
    for name in ['report.json','source_manifest.json','stdout.log']:
        shutil.copy2(RUN/name,OUT/'evidence'/name)
    for name in ['tutorial.md','final.md','technical.md']:shutil.copy2(HALL/name,OUT/name)
    plan=ROOT/'doc/book/course/QFEP-READING-PASS.md'
    shutil.copy2(plan,OUT/'plan.md')
    tutorial=review.linked(HALL/'tutorial.md');final=review.linked(HALL/'final.md')
    total=h['printed_assertions']+len(h['checks'])+len(n['checks'])
    summary={'created':datetime.now().astimezone().isoformat(),'hall':'QFEP_Synthesis','passed':True,
        'printed_assertion_statements':h['printed_assertions'],'synthetic_and_physics_checks':len(h['checks']),
        'native_checks_including_captures':len(n['checks']),'warnings':warnings,
        'engine_comparison':h['engine_comparison'],'preserved_sources':preserved,
        'canonical_sources':{p.relative_to(ROOT).as_posix():sha(p) for p in [HALL/'tutorial.md',HALL/'final.md',HALL/'technical.md',plan]},
        'scope':'Eighth QFEP hall reconstructed. This run tests Synthesis; earlier hall receipts are separate. Author-operated synthetic tests; no physical headset or independent learner claim.'}
    write('latest-run.json',json.dumps(summary,indent=2))
    write('tutorial.html',review.page('Synthesis — tutorial',tutorial))
    write('final.html',review.page('Synthesis — reflection',final))
    write('parallel.html',review.page('Synthesis — facing pages','<p class="tag">QFEP Laboratory · Hall 8 of 8</p><div class="pair"><article><p class="tag">Tutorial · build and investigate</p>'+tutorial+'</article><article><p class="tag">Final · reflection</p>'+final+'</article></div>',True))
    write('plan.html',review.page('QFEP — current route',review.linked(plan)))
    body='''<p class="tag">12 October 2026 · QFEP Laboratory · Hall 8 of 8</p><h1>A body<br>keeps moving.</h1>
<p class="lead">Stop the pressure pulse. Nudge the sphere. The body still has somewhere to go.</p>
<p>The same PointBody edits local values. A larger sphere now receives them as a real soft body. The lesson connects the earlier moving object, wave clock and explicit receiver without rebuilding the physics solver.</p>
<p><a href="parallel.html">Tutorial and reflection together</a> · <a href="tutorial.html">Complete runnable tutorial</a> · <a href="final.html">Reflection</a> · <a href="changes.html">Before and after</a></p>'''
    body+=figure('steady','Native Godot capture in Endless Museum. Pulsing is disabled; the soft sphere continues under gravity, contact and the nudge. The outlined box has six solid collision boundaries.')
    body+='''<h2>The test changed the explanation</h2>
<p>The original wording promised four live mechanical controls. Godot 4.6-stable with Jolt does not deliver that: soft-body drag is ignored, and changing the stiffness property does not update an already-built constraint. Pressure and damping do update. The lesson now shows requested stiffness beside its built value, and requested drag beside the engine’s zero.</p>
<p>The ghost run caught the drag mismatch. A second experiment separated runtime stiffness edits from stiffness chosen before construction. The <a href="https://github.com/godotengine/godot/blob/4.6-stable/modules/jolt_physics/objects/jolt_soft_body_3d.cpp">versioned engine source</a> corroborates these limits. The tutorial, reflection and technical note now describe what was tested.</p>
<table><tr><th>Control</th><th>Authored request</th><th>In this running body</th></tr>
<tr><td>Lambda</td><td>Stiffness and pressure baseline</td><td>Pressure updates; built stiffness stays 0.5</td></tr>
<tr><td>Signed phi</td><td>Damping and drag</td><td>Damping updates; drag is unused</td></tr>
<tr><td>PULSE / STEADY</td><td>Enable modulation; restart its phase</td><td>Does not reset the body's positions or motion</td></tr>
<tr><td>NUDGE</td><td>One local-direction impulse</td><td>Acts on the current physical state</td></tr>
<tr><td>KEEP</td><td>Copy settings and clock</td><td>No vertex history or recoverable physics checkpoint</td></tr></table>
<h2>A comparison the student makes</h2><p>Form 0.2 / +0.8, then 0.8 / −0.8 without presets. Both give pressure 1.2; damping changes from 0.0209 to 0.1801. Built stiffness and unused drag stay fixed. Equal pressure does not mean equal starting histories.</p>
<div class="grid">'''
    body+=figure('comparison-a','First pair: low damping, pressure 1.2. KEEP stores these settings.')
    body+=figure('comparison-b','Second pair: higher damping, the same pressure. KEEP still names the first pair.')+'</div>'
    body+=f'<div class="note"><strong>{total} checks passed:</strong> {h["printed_assertions"]} printed assertions, {len(h["checks"])} synthetic input and engine checks, {len(n["checks"])} native checks including captures. <a href="ghost.html">Evidence, failures and limits.</a></div>'
    body+='<h2>Inside the existing museum</h2>'+figure('existing','The original specimen and its own two controls remain. Its plate reports properties; the lesson explains why a readback is not proof of a mechanical effect.')
    body+=figure('hall','The F6 lesson occupies a checked bay in the existing hall. Its first trial overlapped the original specimen; the final placement passes floor, approach and artifact-separation checks.')
    body+='''<h2>The laboratory now has eight runnable lessons</h2><p>The progression moves through inputs, prediction, counted outcomes, weighting, signed change, time steps, connections and finally the body receiving a request. Each hall has its own reconstruction and test receipts. This run completes Synthesis; it is not a new continuous test of all eight halls.</p><p>Post-Crisis follows in the museum. The connection is sharper now: a description can be precise and still leave out the mechanism that determines what it does.</p><p><a href="plan.html">Whole route and receipts</a> · <a href="plan.md">Editable plan</a> · <a href="../2026-10-12-qfep-where-the-value-arrives/index.html">Previous: Sandbox</a></p>'''
    write('index.html',review.page('QFEP Synthesis — a body keeps moving',body))
    comparison=h['engine_comparison']
    ghost=f'''<p class="tag">Ghost student · Synthesis</p><h1>Test the receiving engine.</h1><p class="lead">{total} checks pass on freshly extracted code and the actual museum.</p>
<p>Three new files and three inherited files are extracted from their printed tutorials. Synthetic hands operate a translated and rotated bench; real Jolt simulation moves the vertices. The native run operates the installed artifact's controls as well as the student's working copy. This is author-operated reconstruction, not an independent reader or physical headset study.</p>
<h2>What failed and what changed</h2><p>The first run expected requested drag to reach the body. It read back zero. The test then compared four matching spheres: two built with stiffness 0.5 and edited to 0.1/0.9 while running; two constructed with 0.1/0.9. Their relative vertex differences after matching updates were {comparison['runtime_change_difference']:.8f} m for the runtime edits and {comparison['construction_difference']:.8f} m for different construction settings. This bounded experiment and the versioned engine implementation support the correction; a property setter alone did not.</p>
<p>A harness count also included the supplied buttons' static bodies. It now counts the six direct boundary children. The first native placement overlapped the installed specimen; floor queries and artifact bounds located a separate bay. No engine workaround or hidden body reset was added.</p>
<p><a href="first-headless.json">Initial headless failures</a> · <a href="first-native-failure.json">Initial placement failures</a> · <a href="first-native-overlap.png">Rejected placement</a></p>
<h2>What remains distinct</h2><p>Arithmetic tests verify requested values and pulse extrema. Property checks verify pressure and damping readback, and explicitly expect unused drag to stay zero. Physics checks observe moving vertices after pulsing stops, while the same mesh and body remain. Forty-two parameter/mode combinations match the installed artifact's mappings. No test equates that agreement with identical trajectories, material calibration, life or queerness.</p>'''
    for title,checks in [('Synthetic inputs and physics',h['checks']),('Native museum',n['checks'])]:
        ghost+=f'<h2>{title}</h2><table><tr><th>Check</th><th>Result</th></tr>'
        ghost+=''.join(f'<tr><td>{html.escape(c["name"])}</td><td>{"PASS" if c["passed"] else "FAIL"}</td></tr>' for c in checks)+'</table>'
    ghost+='<h2>Warnings and scope</h2><p>No script or engine errors in the final run. Existing museum warnings remain below. Placement checks cover the bench and its approach; they do not certify the complete route. Headset comfort, real grip/reach and independent learning remain open.</p><pre>'+html.escape('\n'.join(warnings))+'</pre>'
    ghost+='''<h2>Reproduce</h2><pre>python tools/test_qfep_synthesis.py
python tools/run_encounter_probe.py QFEP_Synthesis --sequence qfeplaboratory --render --no-bridges --output-tag qfep_reconstruction --probe tools/probes/qfep_synthesis_museum.gd
python tools/publish_qfep_synthesis.py</pre><p><a href="extraction.json">Printed-source manifest</a> · <a href="headless.json">Assertions and input receipt</a> · <a href="evidence/report.json">Native receipt</a> · <a href="evidence/stdout.log">Engine log</a> · <a href="latest-run.json">Summary</a></p>'''
    write('ghost.html',review.page('QFEP Synthesis — ghost student',ghost))
    changes='<h1>Synthesis: before and after</h1><p>The tutorial is now reconstructable. Reflection and technical notes distinguish requested properties from supported effects. Original artifact code, map data and order remain source-hash checked.</p>'
    for name in ['tutorial.md','final.md','technical.md']:
        old=(OUT/'before'/name).read_text(encoding='utf8');new=(HALL/name).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
        changes+=f'<h2>{name}</h2><details><summary>Exact diff</summary><pre>{html.escape(diff)}</pre></details>'
        changes+='<div class="pair"><article><p class="tag">Before</p>'+review.linked(HALL/name,old)+'</article><article><p class="tag">After</p>'+review.linked(HALL/name)+'</article></div>'
    write('changes.html',review.page('Synthesis — changes',changes,True))
    missing=[]
    class Links(HTMLParser):
        def handle_starttag(self,tag,attrs):
            for key,value in attrs:
                if key not in ['href','src'] or not value:continue
                u=urlsplit(value)
                if not u.scheme and u.path and not u.path.startswith('/') and not (OUT/unquote(u.path)).exists():missing.append(value)
    for path in OUT.glob('*.html'):Links().feed(path.read_text(encoding='utf8'))
    assert not missing,missing
    print(json.dumps(summary,indent=2))
    print('Seven review pages checked for local links.')

if __name__=='__main__':main()
