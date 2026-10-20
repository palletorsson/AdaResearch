from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MAP = 'ProceduralGeneration_Reaction_Diffusion_Systems'
STUDY = ROOT / 'doc/book/studies/soft-bodies-through-the-hands' / MAP
CA = ROOT / 'commons/maps/CA_SoftRules/tutorial.md'
TUTORIAL = ROOT / 'commons/maps' / MAP / 'tutorial.md'
OLD = ROOT / 'doc/book/iterations/2026-10-09-reaction-what-keeps-a-pattern'
EDITION = 'RD-20261016-P1'


def read(path):
    return path.read_text(encoding='utf-8')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def blocks(text):
    return dict(re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', text, re.S))


def function(source, name):
    return re.search(r'^func ' + name + r'\(.*?(?=^func |\Z)', source, re.M | re.S).group().rstrip()


current, previous = blocks(read(TUTORIAL)), blocks(read(CA))
assert set(current) == {'field.gd', 'reaction.gd', 'point_body.gd'}
checks = []


def check(name, condition):
    checks.append({'name': name, 'passed': bool(condition)})
    assert condition, name


for name, source in current.items():
    check(f'{name}: printed block matches complete study file', source + '\n' == read(STUDY / name))
check('PointBody is carried unchanged from CA', current['point_body.gd'] == previous['point_body.gd'])
new_rule = function(current['field.gd'], 'next_pair')
old_rule = function(previous['field.gd'], 'next_pair')
incoming = previous['field.gd']
anchor = 'var exchange := true'
check('Variable insertion has one anchor', incoming.count(anchor) == 1)
check('Function replacement has one anchor', incoming.count(old_rule) == 1)
assembled = incoming.replace(anchor, anchor + '\nvar local_terms := true').replace(old_rule, new_rule)
check('Two declared edits exactly reconstruct current field.gd', assembled == current['field.gd'])
host = current['reaction.gd']
check('Comparison host enables exchange in both fields', 'var exchange := true' in current['field.gd'] and '.exchange =' not in host)
check('Comparison host disables local terms in B at start', 'right.local_terms = false' in function(host, '_ready'))
check('Changing comparison resets both histories', 'reset()' in function(host, 'change_local_terms') and 'left.reset()' in function(host, 'reset') and 'right.reset()' in function(host, 'reset'))
check('Witness lies inside the initial patch', 'const W := Vector2i(15, 15)' in host)

for folder in ['files', 'sources']:
    (HERE / folder).mkdir(exist_ok=True)
for name in [*current, 'study.tscn']:
    shutil.copyfile(STUDY / name, HERE / 'files' / name)
shutil.copyfile(TUTORIAL, HERE / 'sources' / 'tutorial.md')
shutil.copyfile(CA, HERE / 'sources' / 'ca-tutorial.md')
shutil.copyfile(ROOT / 'doc/book/course/functional_text/RECONSTRUCTION.md', HERE / 'sources' / 'reconstruction.md')
(HERE / 'files' / 'README.txt').write_text(
    f'{EDITION}: unchanged current lesson files, copied 16 October 2026.\n'
    'Use inside the prepared Endless Museum Godot 4.6 project with XR Tools.\n'
    'Keep these files together. Instance study.tscn at floor level, unit scale,\n'
    'with 3.3 x 2.4 metres clear, facing positive Z. The scene creates its children.\n'
    'Camera, light and player are provided by the museum. This is not a standalone project.\n'
    'Enter: step. Space: +100. C: toggle B local terms and restart both fields.\n'
    'R: replay. V: U/V display. Held point trigger or I: plant in both fields.\n'
    'Keyboard operates the compact clock; the installed museum desk has VR controls.\n'
    'See the report for the focused reading, complete tutorial, and historical evidence.\n', encoding='utf-8')
with zipfile.ZipFile(HERE / 'reaction-study.zip', 'w', zipfile.ZIP_DEFLATED) as bundle:
    for path in sorted((HERE / 'files').iterdir()):
        bundle.write(path, 'reaction-study/' + path.name)

archived_match = all((OLD / 'printed' / n).exists() and read(OLD / 'printed' / n) == s + '\n' for n, s in current.items())
receipt = json.loads(read(OLD / 'checks.json'))
report = {
    'edition': EDITION, 'scope': 'Source and assembly checks only; no new Godot or learner run.',
    'checks': checks, 'passed': all(c['passed'] for c in checks),
    'source_sha256': {str(p.relative_to(ROOT)).replace('\\', '/'): digest(p) for p in [TUTORIAL, CA, *[STUDY / n for n in [*current, 'study.tscn']]]},
    'historical_native_evidence': {
        'path': str((OLD / 'checks.json').relative_to(ROOT)).replace('\\', '/'),
        'sha256': digest(OLD / 'checks.json'), 'recorded_passed': receipt.get('passed'),
        'recorded_checks': len(receipt['checks']), 'current_scripts_match_archived_printed_files': archived_match,
        'limit': 'Script comparison only; engine, harness and all environment dependencies were not revalidated.'
    },
    'human_learning': 'Not tested', 'museum_logic_changed': False,
}
(HERE / 'verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')

def code(text):
    return '<pre><code>' + html.escape(text) + '</code></pre>'

file_readers = ''.join('<details><summary>' + name + ' <span>complete file</span></summary>' + code(source) + f'<p><a href="files/{name}" download>Download {name}</a></p></details>' for name, source in current.items())
page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Carry the work; show the change — Endless Museum</title>
<style>
:root{--paper:#f6f2e8;--ink:#242f31;--muted:#657171;--pink:#eab7c1;--line:#d2d7cf;--green:#245d50}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#e7e9e2;color:var(--ink);font:17px/1.65 system-ui,sans-serif}a{color:var(--green);text-underline-offset:4px}header,main,footer{max-width:1330px;margin:auto;padding:36px}header{padding-top:65px}h1,h2,h3{font-family:Georgia,serif;font-weight:normal;line-height:1.13}h1{font-size:clamp(42px,5.6vw,78px);margin:18px 0 24px;max-width:920px}h2{font-size:37px;margin:20px 0}h3{font-size:25px}.eyebrow{font:12px/1.5 system-ui;letter-spacing:.14em;text-transform:uppercase;color:var(--muted)}.lead{max-width:850px;font-size:21px}nav{display:flex;gap:24px;flex-wrap:wrap;border-top:1px solid var(--line);padding-top:20px;margin-top:28px}figure{margin:0 0 50px}figure img{width:100%;max-height:420px;object-fit:cover;display:block}figcaption{font-size:13px;color:var(--muted);margin-top:8px}.spread{display:grid;grid-template-columns:1.15fr .85fr;gap:2px;box-shadow:0 8px 35px #29332f12}.page{padding:38px;background:var(--paper);min-width:0}.page.web{background:#fffefa}.label{display:inline-block;padding:4px 9px;background:#dce6dc;font:12px/1.5 system-ui;letter-spacing:.05em}.web .label{background:var(--pink)}p{margin:16px 0}code{font-size:.86em}pre{background:#e9ede6;padding:18px;overflow:auto;line-height:1.65;tab-size:2;font-size:13px;border-left:3px solid #74958a}pre code{font-size:inherit}ul,ol{padding-left:21px}li{margin:8px 0}.carry{font-size:14px;border-block:1px solid var(--line);padding:12px 0}.note{font-size:14px;color:var(--muted)}.question{padding:15px 20px;border-left:3px solid var(--pink);background:#f4e8e6}.facts{display:grid;grid-template-columns:1fr 1fr;gap:12px}.facts div{border:1px solid var(--line);padding:14px}.facts b{display:block;font-family:Georgia;font-size:28px;font-weight:normal}.facts span{font-size:12px}.button{display:inline-block;background:var(--green);color:#fff;padding:10px 16px;text-decoration:none;margin:8px 0}.files{padding:0;list-style:none}.files li{border-bottom:1px solid var(--line);padding:10px 0}.files small{display:block;color:var(--muted)}section{scroll-margin-top:20px}.wide{margin-top:55px;background:#faf9f3;padding:34px}.flow{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}.flow div{border-top:3px solid #719289;padding:15px 0}.flow b{display:block}.flow span{font-size:14px;color:var(--muted)}table{border-collapse:collapse;width:100%;font-size:15px}td,th{text-align:left;vertical-align:top;padding:14px 12px;border-bottom:1px solid var(--line)}th{font-size:12px;text-transform:uppercase;letter-spacing:.04em}details{border-bottom:1px solid var(--line);padding:17px 0}summary{cursor:pointer;font-weight:600}summary span{font-size:12px;font-weight:normal;color:var(--muted);margin-left:14px}footer{font-size:14px}button{font:inherit;border:0;background:transparent;text-decoration:underline;cursor:pointer;color:var(--green)}
.page pre{white-space:pre-wrap;overflow-wrap:anywhere}
@media(max-width:850px){header,main,footer{padding:22px}.spread{grid-template-columns:1fr}.page{padding:25px}.flow{grid-template-columns:1fr 1fr}.wide{padding:24px}h2{font-size:30px}}
@media print{body{background:white;font-size:11pt}header,main,footer{max-width:none;padding:0}nav,.no-print{display:none}.spread{display:block;box-shadow:none}.page{padding:0;background:white}.page.web,.wide,figure,footer{display:none}h1{font-size:30pt}h2{font-size:24pt}pre{white-space:pre-wrap;overflow:visible;font-size:8pt;break-inside:avoid}.question{break-inside:avoid}}
</style></head><body>
<header><div class="eyebrow">Endless Museum / Tutorial reading proof / 16 October 2026</div>
<h1>Carry the work.<br>Show the change.</h1>
<p class="lead">A continuing object gives the tutorial its lineage. The book brings the new operation into view; the encyclopedia keeps its complete working context within reach.</p>
<nav><a href="#reading">Try the reading</a><a href="#lineage">What carries onward</a><a href="#files">Complete code</a><a href="#method">Writing agreement</a><span class="note">Print reading proof: Ctrl+P</span></nav></header>
<main><figure><img src="../2026-10-15-rd-gallery-in-museum/inside.png" alt="Saved coloured reaction-diffusion sculptures on plinths inside the actual Endless Museum"><figcaption>Actual museum capture, 15 October. These saved studies widen the encounter. The tutorial below develops one two-field experiment; it does not teach every gallery renderer.</figcaption></figure>
<section class="spread" id="reading"><article class="page"><span class="label">Book / focused reading</span>
<h2>What keeps a pattern changing?</h2><p>Two fields begin with the same small square. In the earlier CA lesson, we changed what neighbouring addresses could exchange. Now leave that exchange running in both. Switch the local reaction off in one. What difference remains?</p>
<p class="carry"><b>Carry:</b> <a href="sources/ca-tutorial.md">CA — What a neighbour offers</a>: the field, its update loop and display. <a href="files/point_body.gd"><code>point_body.gd</code></a> stays unchanged. Complete study: <a href="#files">RD-20261016-P1</a>.</p>
<p>Continue that lesson's <code>field.gd</code>. Add this beside <code>var exchange := true</code>:</p>
__FLAG__
<p>Replace its existing <code>next_pair</code> function with this complete function. Keep indexing, seeding and <code>step</code> unchanged.</p>
__RULE__
<p><code>du</code> and <code>dv</code> begin with neighbour exchange. Inside the condition, conversion takes U and adds the same amount to V. Supply replenishes U; removal takes V away. Setting <code>local_terms</code> to false skips those three local terms, while exchange continues.</p>
<p>Use the updated <a href="files/reaction.gd"><code>reaction.gd</code></a> host in the complete study. It starts B with local terms off. <b>Enter</b> advances both fields once; <b>C</b> toggles B's local terms and restarts both. The host and readout have changed from CA; their complete file is supplied here.</p>
<p>At address (15,15), U starts at 0.5 and V at 0.25. Its neighbours initially match, so exchange contributes zero. After one step, A gives <b>U = 0.48725, V = 0.257</b>. B stays at its initial values there. B still changes at the patch boundary.</p>
<div class="question"><b>Change one decision.</b> Set FEED to 0.050. Predict the first step at this address before running. Why does more feed also remove more V?</div>
<p class="note">One call is one numerical step, with dt = 1. Clamping bounds the output; it does not guarantee an accurate or stable simulation for arbitrary settings. Next we carry the comparison method into a different spatial field; these arrays stay here.</p>
</article><aside class="page web"><span class="label">Encyclopedia / complete working state</span><h2>The whole study is here.</h2>
<p>The same lesson opens at the same operation. Expand a file when you need its construction, or download the complete study for your prepared museum project.</p>
<ul class="files"><li><a href="files/field.gd"><code>field.gd</code></a> — changed<small>Two edits: a local-terms flag and its reaction function. The inherited update loop remains.</small></li>
<li><a href="files/reaction.gd"><code>reaction.gd</code></a> — updated host<small>Comparison switch, witness address and readout are adapted from CA. Includes every display and control helper.</small></li>
<li><a href="files/point_body.gd"><code>point_body.gd</code></a> — unchanged<small>Same carried class as CA; pickup and desktop hand support.</small></li>
<li><a href="files/study.tscn"><code>study.tscn</code></a> — supplied attachment<small>One Node3D with reaction.gd attached. The scripts create its children.</small></li></ul>
<a class="button" href="reaction-study.zip" download>Download complete study</a>
<p class="note">Requires the existing Godot 4.6 museum and XR Tools. Place at floor level, unit scale, with 3.3 × 2.4 metres clear, facing positive Z. The museum supplies camera, light and player. Keyboard operates time and comparison; the held point trigger plants a patch.</p>
<h3>Read before you run</h3><p><a href="sources/tutorial.md">Complete current tutorial</a> · <a href="sources/ca-tutorial.md">Earlier CA lesson</a> · <a href="#files">Expand full scripts</a></p>
<h3>What the checks establish</h3><div class="facts"><div><b>__COUNT__</b><span>source and assembly checks in this proof</span></div><div><b>33</b><span>archived native code checks, 9 October</span></div></div>
<p>The two printed edits reconstruct the current field file exactly. The complete scripts __MATCH__ the archived printed scripts. <a href="verification.json">Source receipt</a>.</p>
<p><a href="../2026-10-09-reaction-what-keeps-a-pattern/REPORT.md">Earlier Godot evidence</a> includes matched starts, the feed variation and deliberate faults. No new Godot or learner test was run for this reading proof. Matching scripts alone does not revalidate its whole environment.</p>
<details><summary>Check your prediction</summary><p>With FEED = 0.050, A's first step at (15,15) gives U = 0.49375 and V = 0.25375. B's first-step values there remain unchanged. Feed appears in both supply and removal.</p><p>Then enable B's local terms and restart. Both fields should agree at equal step counts. Explain a mismatch before interpreting its image.</p></details>
<h3>Keep the comparison exact</h3><p>The installed display uses a different stencil and default rates. Compare A and B within this study. A similar gallery pattern is not proof of the same numerical history.</p>
<p class="note">Local proof __EDITION__. Public edition addresses, a frozen book bundle and page numbers remain publishing work.</p>
</aside></section>
<section class="wide" id="lineage"><div class="eyebrow">Connections through the museum</div><h2>Lineage has more than one kind of thread.</h2>
<div class="flow"><div><b>Point → Lines</b><span>A constructed body becomes a reusable class; two instances form a relation.</span></div><div><b>Trace → Grid</b><span>Saved positions and a drawing travel. A separate copy changes; the source remains.</span></div><div><b>CA → Reaction</b><span>A supplied rule becomes the subject. The field and comparison method return.</span></div><div><b>Geometry → Melencolia</b><span>Known constructions become material for an arrangement and reflection.</span></div></div>
<p>The walking route and the prerequisite links do different jobs. Name the actual earlier lesson, even when another sequence lies between. Let object families branch. A shared class, a saved record and a remembered idea are different continuities.</p></section>
<section class="wide" id="files"><div class="eyebrow">Same source / no parallel implementation</div><h2>Complete files</h2><p>Copied unchanged from the current learner study, and checked against the code printed in tutorial.md. These are the files behind the focused excerpt above.</p>__FILES__</section>
<section class="wide" id="method"><div class="eyebrow">A proposal to use one hall at a time</div><h2>What earns space on the page?</h2>
<table><thead><tr><th>Material</th><th>Book</th><th>Encyclopedia</th></tr></thead><tbody>
<tr><td>New principle</td><td>Encounter, complete new code unit, explanation and a consequence to predict.</td><td>Same reading, with runnable state and evidence.</td></tr>
<tr><td>Unchanged code</td><td>One line: filename, role, earlier lesson and edition reference.</td><td>Exact file, expandable and downloadable.</td></tr>
<tr><td>Changed support</td><td>Name what changed. Print its causal code if that change is the lesson.</td><td>Complete updated file and comparison with predecessor.</td></tr>
<tr><td>Evaluation</td><td>Predict, change, observe, explain; try a new use.</td><td>Assertions, exercise versions, deliberate fault and evidence limits.</td></tr>
<tr><td>Reflection</td><td>final.md keeps its literary and critical work.</td><td>Connected research and other interpretations remain available.</td></tr>
</tbody></table><p>A printed reference must lead to that book's exact version. Offer the current development version separately. Keep readable references beside QR codes and supply an offline bundle. A file name alone is not enough when several revisions exist.</p>
<p>First constructions still show their complete small program. Continuations can show precise changes because the preceding working state is declared and available. The existing Ghost Student checks can test that composition; there is no need for another curriculum database.</p>
<p><a href="README.md">Full proposal and compact writer instruction</a> · <a href="sources/reconstruction.md">Reconstruction agreement snapshot</a></p></section>
</main><footer>Reading proof, not a paginated edition. Canonical tutorials, final.md and museum logic are unchanged. Built locally by build.py in this report folder.</footer></body></html>'''
page = page.replace('__FLAG__', code('var local_terms := true')).replace('__RULE__', code(new_rule)).replace('__FILES__', file_readers)
page = page.replace('__COUNT__', str(len(checks))).replace('__MATCH__', 'match' if archived_match else 'do not match').replace('__EDITION__', EDITION)
(HERE / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'passed': report['passed'], 'source_checks': len(checks), 'archived_scripts_match': archived_match, 'report': str(HERE / 'index.html')}))
