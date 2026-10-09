"""Publish the tested Cantor pass without rewriting the canonical manuscript."""
from pathlib import Path
import html, json, hashlib, re, shutil, zipfile, difflib
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-cantor-a-cut-in-the-hand'
RUN=ROOT/'ada_run/encounter_pilot/Fractal_CantorSet'
HALL=ROOT/'commons/maps/Fractal_CantorSet'
STUDY=ROOT/'doc/book/studies/fractals-through-the-hands/Fractal_CantorSet'
for name in ['images','tests']: (OUT/name).mkdir(parents=True,exist_ok=True)
def read(p): return p.read_text(encoding='utf8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,v): p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf8')

reports=[]
for source,slug,log in [(ROOT/'ada_run/cantor_hand_tests.json','lesson-and-artifact',ROOT/'ada_run/cantor-hand-engine.log'),(RUN/'report.json','museum',RUN/'engine.log')]:
    data=json.loads(read(source))
    assert data['passed'] and not data['failures']
    assert 'SCRIPT ERROR' not in read(log)
    shutil.copy2(source,OUT/'tests'/f'{slug}.json'); shutil.copy2(log,OUT/'tests'/f'{slug}.log')
    reports.append((slug,len(data['checks'])))
shutil.copy2(ROOT/'ada_run/cantor_student/extraction.json',OUT/'tests/extraction.json')
images=[]
for name in ['before','arrival','hand-model','pull','latest','history','pagoda','above','student']:
    source=RUN/f'{name}.png'; shutil.copy2(source,OUT/'images'/source.name)
    images.append({'file':'images/'+source.name,'source':source.relative_to(ROOT).as_posix(),'sha256':sha(source),'kind':'native Godot; pre-edit fixture reconstructed from backup' if name=='before' else 'native Godot; printed study temporarily added in real hall' if name=='student' else 'native Godot; current museum hall'})
# Replace the unusable early camera sample with the inspected pre-edit view.
shutil.copy2(RUN/'before.png',OUT/'before/museum.png')
for track in ['tutorial','final']: shutil.copy2(HALL/f'{track}.md',OUT/f'{track}.md')
count=sum(n for _,n in reports)
style='''*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#25222a;font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1320px;margin:auto;padding:28px 5vw}nav{display:flex;gap:24px;flex-wrap:wrap}a{color:#853856;text-underline-offset:4px}h1{font:clamp(38px,5vw,70px)/1.06 Georgia,serif;max-width:900px}h2{font:32px/1.2 Georgia,serif;margin-top:48px}p{max-width:75ch}.lead{font-size:23px}.eyebrow{font-size:12px;letter-spacing:.12em;text-transform:uppercase}img{width:100%;display:block}figure{margin:28px 0}figcaption{font-size:14px;color:#605964;margin-top:8px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair article{min-width:0;padding:24px;background:#fffcf6}.reading h1{font-size:38px}.reading h2{font-size:27px}pre{overflow:auto;background:#242129;color:#f5eff1;padding:20px;font:13px/1.6 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.88em}table{border-collapse:collapse;width:100%;background:#fffcf6}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #d8d0c7;padding:16px}blockquote{border-left:4px solid #d292a7;margin:25px 0;padding:12px 22px;font:26px/1.5 Georgia,serif}.pill{background:#25222a;color:#fff;padding:8px 18px;display:inline-block;border-radius:22px;font-size:14px}button{font:inherit;background:#fffcf6;border:1px solid #bfa4af;padding:8px 16px;margin-right:8px;cursor:pointer}button[aria-pressed=true]{background:#25222a;color:white}.notes{background:#e8e0d6;padding:22px}del{background:#ffe3e3}ins{background:#e0efdc;text-decoration:none}@media(max-width:850px){.pair{grid-template-columns:1fr}header,main,footer{padding:22px}pre{font-size:12px}}@media print{nav,button{display:none}.pair{display:block}pre{white-space:pre-wrap}body{background:white}article{break-before:page}}'''
def page(title,body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+style+'</style><header><p class="eyebrow">Endless Museum · Fractals 03 · 8 October 2026</p><nav><a href="index.html">Museum & changes</a><a href="parallel.html">Tutorial / reflection</a><a href="changes.html">Text before / after</a><a href="student-files.zip">Student files</a></nav></header>'+body+'<footer>Native Godot captures and supplied test inputs. Physical headset feel and learner understanding remain untested.</footer></html>'
def md(text): return markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
def figure(name,caption): return '<figure><img src="images/'+name+'.png" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+caption+'</figcaption></figure>'
body=f'''<main><h1>Pull out the middle.<br>Keep the two ends.</h1><p class="lead">The next Fractals lesson is in the existing Cantor hall. The point returns as a handle: one gesture applies the same replacement across the current row.</p><p class="pill">{count} passing assertions · complete printed code · real museum captures</p>'''
body+=figure('pull','The rose point carries the middle third. The two outer pieces stay. Release beyond the mark to apply the rule; return before releasing to cancel.')
body+='''<h2>What changed</h2><table><tr><th>Layer</th><th>Before</th><th>Now</th></tr><tr><td>Museum</td><td>Six desk buttons; all generation history visible by default.</td><td>A reachable off-white plinth with a held middle-third control. Latest row first; history and ghost comparisons remain beside it. The pagoda and surrounding collection stay.</td></tr><tr><td>Tutorial</td><td>A short encounter guide without a complete executable example.</td><td>A two-file reconstruction, reusing PointBody: start/length records, outer-third replacement, current/next arrays, retained length and copied history. Actual release drives one generation.</td></tr><tr><td>Reflection</td><td>The cut began with NEXT.</td><td>The hand begins it. One added paragraph asks what the enlarged control stands for as the represented interval shrinks. The existing discussion of history, finite limits and bodily access remains.</td></tr></table>
<h2>Before / after, the same camera</h2><p>The earlier fixture is reconstructed from its pre-edit backup inside the same isolated museum run. This is a native comparison, not an imagined renovation.</p><button onclick="swapRoom(false)" id="old" aria-pressed="true">Before</button><button onclick="swapRoom(true)" id="new" aria-pressed="false">After</button><figure><img id="room" src="images/before.png" alt="Cantor hall before the new hand model"><figcaption id="room-caption">Before: the existing desk and pagoda.</figcaption></figure>'''
body+=figure('hand-model','The small bar always represents one interval enlarged. Keeping the grip usable does not keep the mathematical interval the same length.')
body+='''<h2>One row, or its history</h2><p>These views have the same four cuts and the same current result: 16 pieces, retaining about 1.185 metres. Showing the earlier rows and removed middles changes what can be seen, not what survives in the latest generation.</p><div class="pair">'''
body+=figure('latest','Latest only: 16 surviving intervals.')+figure('history','History and ghosts: the record becomes denser while the latest retained length stays fixed.')+'</div>'
body+='''<h2>Then try to enter the gap</h2><p>The same construction already stands at body scale in the pagoda. The actual desktop collision body climbed the ramp and crossed the 3 m and 1 m openings. The ⅓ m opening stopped it. No new lesson is needed to make the distinction felt: an interval can be open without offering this body a passage.</p>'''
body+=figure('pagoda','Three cuts in the existing pagoda. Height, depth and collision turn an interval drawing into architecture.')
body+=figure('above','The hall from above. The new hand model joins the first desk; the ramps, pagoda, smaller Cantor reference, trees and side route remain.')
body+='''<h2>The student builds inside this museum</h2><p>Place the printed script on the existing empty PointStudy node, beside the carried point_body.gd. The configured museum supplies the player, XR hands, camera and lighting. All lesson objects are created by code. No dollar references or unseen scene objects are required.</p>'''
body+=figure('student','The exact printed two-file study running temporarily beside the existing exhibits. This capture does not add another permanent installation.')
body+='''<p><a href="parallel.html">Read the complete tutorial on the left and final.md on the right.</a> <a href="changes.html">Compare the previous text with this pass.</a></p><blockquote>One movement of your hand is being repeated in places you did not touch.</blockquote>
<h2>Lineage and limits</h2><p>Frames introduced a stopping condition. Trees made two child calls and inherited transforms. Cantor now uses a loop to replace one entire generation per release. The branching pattern returns, but this code does not call itself. The result and the record are separate arrays.</p><p>The independent exercise keeps the outer quarters instead of thirds: predict the new records, then adjust the model to match that changed rule. Five cuts remain a finite study. The interval record lasts for this study; no cross-hall archive or new pagoda probe sphere has been added in this pass.</p><h2>Verification</h2><ul>'''
body+=''.join(f'<li><a href="tests/{slug}.json">{n} checks: {slug}</a> · <a href="tests/{slug}.log">engine log</a></li>' for slug,n in reports)
body+='''</ul><p>Tests execute code extracted from tutorial.md. They verify interval arithmetic, original/history isolation, variants, one-cut release, cancellation, rotated frames, limits and both XRTools and desktop pickup paths. Museum tests add standing clearance, actual button targeting, ramp and opening traversal, and native captures. A wall-side camera obstruction led to moving the hand model farther into the room before the final clearance check.</p><p>No script errors in the final runs. Existing audio UID, Jolt solver-bias, registry, compatibility-renderer and exit cleanup diagnostics remain in the logs. No physical headset or Quest performance test has been done.</p><div class="notes"><strong>Next: Koch / Sierpinski.</strong> Keep the replacement operation. Give a line a detour: its endpoints stay while its length grows.</div></main>
<script>function swapRoom(after){document.getElementById('room').src='images/'+(after?'arrival':'before')+'.png';document.getElementById('room').alt=after?'Cantor hall with the new hand model':'Cantor hall before the new hand model';document.getElementById('room-caption').textContent=after?'After: held middle-third model beside the retained controls.':'Before: the existing desk and pagoda.';document.getElementById('old').setAttribute('aria-pressed',!after);document.getElementById('new').setAttribute('aria-pressed',after);}</script>'''
(OUT/'index.html').write_text(page('Cantor — a cut in the hand',body),encoding='utf8')
parallel='<main class="pair reading"><article><p class="eyebrow">Tutorial · reconstruct the operation</p>'+md(read(HALL/'tutorial.md'))+'</article><article><p class="eyebrow">Final · encounter and reflection</p>'+md(read(HALL/'final.md'))+'</article></main>'
(OUT/'parallel.html').write_text(page('Cantor — tutorial and reflection',parallel),encoding='utf8')
changes='<main><h1>The text changes</h1><p>The previous files are preserved. The tutorial is a replacement; the reflection has a small, local revision.</p>'
for track in ['tutorial','final']:
    old=read(OUT/'before'/f'{track}.md'); new=read(HALL/f'{track}.md')
    (OUT/f'{track}.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+track+'.md',tofile='current/'+track+'.md')),encoding='utf8')
    changes+=f'<h2>{track}.md</h2><p><a href="{track}.diff">Plain diff</a></p><div class="pair reading"><article><p class="eyebrow">Before</p>'+md(old)+'</article><article><p class="eyebrow">After</p>'+md(new)+'</article></div>'
(OUT/'changes.html').write_text(page('Cantor — text before and after',changes+'</main>'),encoding='utf8')
with zipfile.ZipFile(OUT/'student-files.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in STUDY.glob('*.gd'): z.write(p,p.name)
    z.write(HALL/'tutorial.md','tutorial.md')
    z.writestr('READ-ME.txt','Use the existing configured Endless Museum workspace with XR Tools. Save both .gd files together; attach cantor.gd to an empty unit-scale PointStudy Node3D. It creates the lesson objects. The surrounding camera, lighting, player and XR hands belong to Day Zero. This is not a standalone project.\n')
dump(OUT/'image-sources.json',images)
paths=['commons/artifacts/cantor_lesson/cantor_lesson.gd','commons/artifacts/cantor_lesson/hand_cut.gd','commons/artifacts/recursive_tree_lesson/fork_point.gd','algorithms/fractals/cantorset/cantor_set.gd','commons/maps/Fractal_CantorSet/tutorial.md','commons/maps/Fractal_CantorSet/final.md','tools/probes/cantor_hand.gd','tools/probes/cantor_hand_museum.gd']
dump(OUT/'evidence.json',{'checks':count,'reports':dict(reports),'source_sha256':{p:sha(ROOT/p) for p in paths},'student_extraction':json.loads(read(OUT/'tests/extraction.json')),'headset_verified':False,'before_capture':'Reconstructed from preserved pre-edit fixture in the isolated current museum.'})
for p in OUT.glob('*.html'):
    for link in re.findall(r'(?:href|src)="([^"]+)"',read(p)):
        if link.startswith(('http','#')): continue
        assert (p.parent/link.split('#')[0]).exists(),(p,link)
print('Published',OUT,'with',count,'checks; relative links valid.')
