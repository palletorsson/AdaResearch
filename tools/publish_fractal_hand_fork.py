"""Publish the tested two-hall Fractals pilot and unchanged native captures."""
from pathlib import Path
import hashlib, html, json, os, re, shutil, zipfile
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-08-fractal-fork-in-the-hand'
RUN = ROOT / 'ada_run/encounter_pilot/Fractal_RecursiveTrees'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'images').mkdir(exist_ok=True)
(OUT / 'tests').mkdir(exist_ok=True)

def read(p): return p.read_text(encoding='utf-8-sig')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p, v): p.write_text(json.dumps(v, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

reports = []
for source, name, log in [
    (ROOT/'ada_run/fractal_hand_fork_tests.json', 'museum-artifact', ROOT/'ada_run/fractal-hand-fork-engine.log'),
    (ROOT/'ada_run/fractal_lesson_student_tests.json', 'printed-lessons', ROOT/'ada_run/fractal-lesson-student-engine.log'),
    (RUN/'report.json', 'museum-hall', RUN/'engine.log'),
]:
    data = json.loads(read(source))
    assert data['passed'] and not data['failures'], source
    assert 'SCRIPT ERROR' not in read(log), log
    shutil.copy2(source, OUT/'tests'/f'{name}.json')
    shutil.copy2(log, OUT/'tests'/f'{name}.log')
    reports.append((name, len(data['checks'])))
count = sum(n for _, n in reports)
provenance = []
for name in ['arrival','hand-model','before-turn','after-turn','under-canopy','above']:
    source = RUN/f'{name}.png'
    shutil.copy2(source, OUT/'images'/source.name)
    provenance.append({'file':'images/'+source.name,'source':source.relative_to(ROOT).as_posix(),'sha256':sha(source),'kind':'native Godot / current production hall'})
source = ROOT/'doc/book/iterations/2026-09-25-tree-canopy/under-canopy.png'
shutil.copy2(source, OUT/'images/before-pilot-september.png')
provenance.append({'file':'images/before-pilot-september.png','source':source.relative_to(ROOT).as_posix(),'sha256':sha(source),'kind':'historical native Godot capture / 25 September / different viewpoint'})
dump(OUT/'image-sources.json', provenance)
shutil.copy2(ROOT/'ada_run/fractal_lesson_student/extraction.json', OUT/'tests/extraction.json')

style = '''
:root{color-scheme:light;--paper:#f5f1e9;--ink:#26232b;--rose:#cb7292}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}header,main,footer{max-width:1280px;margin:auto;padding:28px 5vw}nav{display:flex;gap:22px;flex-wrap:wrap}a{color:#823856;text-underline-offset:4px}h1{font:clamp(38px,5vw,68px)/1.05 Georgia,serif;max-width:900px}h2{font:34px/1.15 Georgia,serif;margin-top:55px}h3{font-size:20px}p{max-width:75ch}.eyebrow{letter-spacing:.15em;text-transform:uppercase;font-size:12px}.lead{font-size:22px;max-width:65ch}.pill{background:#25232b;color:#fff;padding:9px 16px;display:inline-block;border-radius:30px;font-size:14px}img{width:100%;display:block;border-radius:3px}figure{margin:24px 0}figcaption{font-size:14px;color:#59545d;margin-top:8px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair article{min-width:0;background:#fffdf8;padding:24px}table{border-collapse:collapse;width:100%;background:#fffdf8}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #d8d2ca;padding:16px}pre{white-space:pre;overflow:auto;font:13px/1.6 Consolas,monospace;padding:18px;background:#25232b;color:#f7eef1}code{font-family:Consolas,monospace;font-size:.87em}blockquote{margin:25px 0;padding:12px 26px;border-left:4px solid var(--rose);font:25px/1.5 Georgia,serif}.reading p{max-width:70ch}.reading h2{font-size:27px}.reading h1{font-size:38px}.reading pre{max-height:none}.notes{background:#e9e4dc;padding:22px}button{font:inherit;border:1px solid #b8a7ad;background:#fffdf8;padding:8px 15px;margin:10px 8px 10px 0;cursor:pointer}button[aria-pressed=true]{background:#25232b;color:white}@media(max-width:850px){.pair{grid-template-columns:1fr}header,main,footer{padding:22px}th,td{padding:10px}pre{font-size:12px}}@media print{nav,button{display:none}.pair{display:block}body{background:white}pre{white-space:pre-wrap}article{break-before:page}}
'''
def page(title, body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+style+'</style><header><p class="eyebrow">Endless Museum · 8 October 2026 · Fractals / first pass</p><nav><a href="index.html">Museum & changes</a><a href="recursion.html">Recursion: tutorial / reflection</a><a href="trees.html">Trees: tutorial / reflection</a><a href="student-files.zip">Student scripts</a></nav></header>'+body+'<footer>Native Godot captures. Supplied test input; physical headset feel and learner understanding remain untested.</footer></html>'

def render_manuscript(folder, track):
    rendered = markdown.markdown(read(folder/f'{track}.md'), extensions=['fenced_code','tables','footnotes'])
    def relocate(match):
        kind, target = match.groups()
        if target.startswith(('http:', 'https:', '#', 'res:')): return match.group(0)
        path = (folder/target.split('#')[0]).resolve()
        assert path.exists(), (folder, target)
        anchor = '#'+target.split('#',1)[1] if '#' in target else ''
        if kind == 'src':
            destination = OUT/'images'/f'{folder.name}-{path.name}'
            shutil.copy2(path,destination)
            provenance.append({'file':'images/'+destination.name,'source':path.relative_to(ROOT).as_posix(),'sha256':sha(path),'kind':'existing manuscript illustration; retained'})
            return f'src="images/{destination.name}"'
        return f'href="{Path(os.path.relpath(path,OUT)).as_posix()}{anchor}"'
    return re.sub(r'(src|href)="([^"]+)"', relocate, rendered)

for hall, slug in [('Fractal_Recursion','recursion'),('Fractal_RecursiveTrees','trees')]:
    folder=ROOT/'commons/maps'/hall
    for track in ['tutorial','final']:
        shutil.copy2(folder/f'{track}.md', OUT/f'{hall}-{track}.md')
    body='<main class="pair reading"><article><p class="eyebrow">Tutorial · reconstruct the operation</p>'+render_manuscript(folder,'tutorial')+'</article><article><p class="eyebrow">Final · encounter and reflection</p>'+render_manuscript(folder,'final')+'</article></main>'
    (OUT/f'{slug}.html').write_text(page(hall,body),encoding='utf-8')

body=f'''<main><h1>Turn a fork.<br>Its children follow.</h1><p class="lead">The first Fractals pilot is inside the existing museum: a small tree between two point grips, and the same branch records enlarged above you.</p><p class="pill">{count} assertions passed · two complete printed lessons · six current museum captures</p>
<figure><img src="images/hand-model.png" alt="A small branching tree on an off-white plinth with rose and black sphere grips and nearby Grow and Reset buttons"><figcaption>One standing position: take a point, turn its first branch, release, add a generation. The original rule-comparison desk remains alongside it.</figcaption></figure>
<h2>What changed in each hall</h2><table><tr><th>Hall</th><th>Before</th><th>This pass</th><th>Carried onward</th></tr><tr><td>Recursion</td><td>Eight short code fragments, including factorial, memoisation and undefined drawing helpers.</td><td>One complete frame constructor: four known lines, a self-call, a smaller size and two stopping conditions. Supplied renderer printed in full. Room geometry retained.</td><td>A bounded recursive function and a prediction about size.</td></tr><tr><td>Recursive Trees</td><td>A short encounter guide; growth and rule changes through desk buttons.</td><td>Two hand grips edit the first fork locally. Its descendants and pending tips follow; its sibling remains. Miniature and large canopy share source records. Full runnable tutorial reconstructs this relationship using parented nodes.</td><td>Two child calls; inherited transforms; a distinction between changing geometry and adding branches.</td></tr></table>
<p>The large trunk moved one metre aside after the collision check found it in the central walking line. The tested route now clears the exhibit. Other halls, artifacts and the seven-hall order remain as they were.</p>
<h2>One gesture, at two scales</h2><p>These two images use the same camera. Only the selected subtree changes; no generation is added.</p><div><button id="before" aria-pressed="true" onclick="showTurn(false)">Before the turn</button><button id="after" aria-pressed="false" onclick="showTurn(true)">After the turn</button></div><figure><img id="turn" src="images/before-turn.png" alt="Large canopy before the point grip turns one subtree"><figcaption id="turn-caption">Before: four generations, 31 segments.</figcaption></figure>
<figure><img src="images/above.png" alt="Elevated view of the current tree hall, its two tree exhibits, branching canopy and walking spaces"><figcaption>The real hall from above. This is a placement survey, not a generated illustration.</figcaption></figure>
<h2>The reflective addition</h2><blockquote>You have changed one attachment, and the change has travelled further than your hand.</blockquote><p>The new passage in <code>Fractal_RecursiveTrees/final.md</code> follows the gesture, its inherited consequences and the interface's limit. It also names the difference between a local turn and the desk controls that rebuild the whole rule. The rest of the reflection stays.</p>
<h2>Read the lessons</h2><p><a href="recursion.html">Recursion: full tutorial beside final.md</a> · <a href="trees.html">Recursive Trees: full tutorial beside final.md</a></p><p>The teaching tree is deliberately smaller than the museum implementation. It uses recursive calls and nested nodes. The existing museum generator uses a generation queue and explicit branch records. Both are explained; the tutorial does not pretend they are identical code.</p>
<h2>Before this pass</h2><figure><img src="images/before-pilot-september.png" alt="Historical September museum image of the canopy before the hand model was added"><figcaption>25 September: historical native capture from a different viewpoint. The large canopy already existed. This pass adds direct local editing and the tested lessons.</figcaption></figure>
<h2>Evidence and limits</h2><ul>'''+''.join(f'<li><a href="tests/{name}.json">{name}: {n} passing assertions</a> · <a href="tests/{name}.log">engine log</a></li>' for name,n in reports)+'''</ul><p>The student test extracts the actual fenced files from tutorial.md, then runs them in Godot. It checks predicted sizes and counts, stopping limits, rotated coordinate frames, subtree isolation, attachments, and XRTools/desktop pickup and release. The production checks exercise the existing museum source and both receivers. Pose edits reuse meshes and collision shapes.</p><p>These checks establish software behaviour under supplied input. They do not establish headset comfort, Quest performance or whether a student understands the lesson. Existing audio UID, Jolt solver-bias, registry and compatibility-renderer diagnostics are retained in the logs; no script errors occurred in these runs.</p><div class="notes"><strong>Next: Cantor Set.</strong> Keep the repeated call. Let the hand choose the part to remove, and follow what remains into the next generation. The other five halls are still proposals.</div></main>
<script>function showTurn(after){document.getElementById('turn').src='images/'+(after?'after-turn':'before-turn')+'.png';document.getElementById('turn').alt=after?'The selected canopy subtree turned by the held point':'Large canopy before the point grip turns one subtree';document.getElementById('turn-caption').textContent=after?'After: the same 31 segments; one subtree has turned.':'Before: four generations, 31 segments.';document.getElementById('before').setAttribute('aria-pressed',!after);document.getElementById('after').setAttribute('aria-pressed',after);}</script>'''
(OUT/'index.html').write_text(page('Fractals — a fork in the hand',body),encoding='utf-8')
with zipfile.ZipFile(OUT/'student-files.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in (ROOT/'doc/book/studies/fractals-through-the-hands').rglob('*.gd'):
        z.write(p,p.relative_to(ROOT/'doc/book/studies/fractals-through-the-hands'))
    z.writestr('READ-ME.txt','These are lesson scripts for the existing, configured Endless Museum workspace. They are not a standalone project. XR Tools is a Day Zero prerequisite. Attach frames.gd or tree.gd to an empty unit-scale PointStudy Node3D. Keep each lesson\'s helper files beside it. Full explanation is in the corresponding tutorial.md.\n')
    for p in OUT.glob('*-tutorial.md'): z.write(p,p.name)
sources=[ROOT/p for p in ['algorithms/fractals/recursivetree/recursive_tree.gd','commons/artifacts/recursive_tree_lesson/branch_canopy.gd','commons/artifacts/recursive_tree_lesson/recursive_tree_lesson.gd','commons/artifacts/recursive_tree_lesson/hand_fork.gd','commons/artifacts/recursive_tree_lesson/fork_point.gd','commons/maps/Fractal_Recursion/tutorial.md','commons/maps/Fractal_RecursiveTrees/tutorial.md','commons/maps/Fractal_RecursiveTrees/final.md','tools/probes/fractal_hand_fork.gd','tools/probes/fractal_lesson_student.gd','tools/probes/fractal_hand_fork_museum.gd']]
dump(OUT/'evidence.json',{'checks':count,'tests':dict(reports),'source_sha256':{p.relative_to(ROOT).as_posix():sha(p) for p in sources},'headset_verified':False,'other_five_halls':'proposed, not implemented in this pass'})
for f in OUT.glob('*.html'):
    for target in re.findall(r'(?:src|href)="([^"]+)"',read(f)):
        if target.startswith(('http','#')): continue
        # Manuscript footnotes may link back to their canonical source paths.
        if '/' not in target or target.startswith(('images/','tests/')):
            assert (f.parent/target.split('#')[0]).exists(), (f,target)
dump(OUT/'image-sources.json', provenance)
print('Published',OUT,'checks',count)
