"""Publish the tested Koch continuation without rewriting the canonical manuscripts."""
from pathlib import Path
import html, json, hashlib, re, shutil, zipfile, difflib
from urllib.parse import urlsplit, unquote
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-koch-the-distance-between'
RUN=ROOT/'ada_run/encounter_pilot/Fractal_KochSierpinski'
HALL=ROOT/'commons/maps/Fractal_KochSierpinski'
STUDY=ROOT/'doc/book/studies/fractals-through-the-hands/Fractal_KochSierpinski'
for name in ['images','tests']: (OUT/name).mkdir(parents=True,exist_ok=True)
def read(p): return p.read_text(encoding='utf-8-sig')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,v): p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

reports=[]
for source,slug,log in [(ROOT/'ada_run/koch_hand_tests.json','lesson-and-artifact',ROOT/'ada_run/koch-hand-engine.log'),(RUN/'report.json','museum',RUN/'engine.log')]:
    data=json.loads(read(source))
    assert data['passed'] and not data['failures']
    assert 'SCRIPT ERROR' not in read(log)
    shutil.copy2(source,OUT/'tests'/f'{slug}.json'); shutil.copy2(log,OUT/'tests'/f'{slug}.log')
    reports.append((slug,len(data['checks'])))
shutil.copy2(ROOT/'ada_run/koch_student/extraction.json',OUT/'tests/extraction.json')
images=[]
for name in ['before','arrival','hand-start','hand-detour','floor-first','floor-fourth','above','reversed','closed','triangle','student']:
    source=RUN/f'{name}.png'; shutil.copy2(source,OUT/'images'/source.name)
    images.append({'file':'images/'+source.name,'source':source.relative_to(ROOT).as_posix(),'sha256':sha(source),'kind':'native Godot; only new receiver hidden to show prior appearance' if name=='before' else 'native Godot; exact printed study temporarily added in real hall' if name=='student' else 'native Godot; current museum hall, supplied input'})
for track in ['tutorial','final','technical']: shutil.copy2(HALL/f'{track}.md',OUT/f'{track}.md')
count=sum(n for _,n in reports)
style=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-10-08-cantor-a-cut-in-the-hand/index.html'),re.S)[1]
style+='details{border-top:1px solid #d8d0c7;padding:16px 0}summary{cursor:pointer;font-weight:600}.single{max-width:880px}.single h1{font-size:42px}'

def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+style+'</style></head><body><header><p class="eyebrow">Endless Museum · Fractals 04 · 8 October 2026</p><nav><a href="index.html">Museum & changes</a><a href="parallel.html">Tutorial / reflection</a><a href="tutorial.html">Tutorial only</a><a href="changes.html">Before / after</a><a href="student-files.zip">Student files</a></nav></header>'+body+'<footer>Native Godot captures and supplied test inputs. Physical headset feel, Quest performance and learner understanding remain untested.</footer></body></html>'

def md(text,prefix):
    result=markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
    result=re.sub(r'id="([^"]+)"',lambda m:f'id="{prefix}-{m[1]}"',result)
    return re.sub(r'href="#([^"]+)"',lambda m:f'href="#{prefix}-{m[1]}"',result)

for track in ['tutorial','final']:
    (OUT/f'{track}.html').write_text(page('Koch / Sierpinski — '+track,'<main class="reading single">'+md(read(HALL/f'{track}.md'),track)+'</main>'),encoding='utf-8')
(OUT/'parallel.html').write_text(page('Koch / Sierpinski — tutorial beside reflection','<main class="pair reading"><article><p class="eyebrow">Left · tutorial.md · make the operation</p>'+md(read(HALL/'tutorial.md'),'tutorial')+'</article><article><p class="eyebrow">Right · final.md · encounter and reflection</p>'+md(read(HALL/'final.md'),'final')+'</article></main>'),encoding='utf-8')

changes='<main><h1>One construction, carried onward.</h1><p>The old tutorial surveyed three desks. The new lesson reconstructs Koch using the same point, line renderer and current/next pattern. Two paragraphs join the new encounter to the existing reflection.</p>'
for track in ['tutorial','final']:
    old=read(OUT/'before'/f'{track}.md'); new=read(HALL/f'{track}.md')
    (OUT/f'{track}.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+track+'.md',tofile='current/'+track+'.md')),encoding='utf-8')
    changes+=f'<h2>{track}.md</h2><p><a href="{track}.diff">Plain diff</a></p><details><summary>Read the complete before and after</summary><div class="pair reading"><article><p class="eyebrow">Before</p>'+md(old,track+'-before')+'</article><article><p class="eyebrow">After</p>'+md(new,track+'-after')+'</article></div></details>'
(OUT/'changes.html').write_text(page('Koch — before and after text',changes+'</main>'),encoding='utf-8')

body=f'''<main><h1>The ends stay.<br>The way between changes.</h1><p class="lead">The familiar point reads a line that takes another detour. One gesture requests a replacement; the same rule acts on every current segment.</p><p class="pill">{count} native checks passed · complete printed code · 11 museum captures</p>
<figure><img src="images/hand-detour.png" alt="Black point on a pale hand table follows the first Koch peak, with the same rose route and a second point on the museum floor"><figcaption>Inside the existing Koch / Sierpinski hall. The point sits at 2.667 metres along a 5.333-metre path. The ends remain four metres apart. NEXT, BACK and RESET are beside the hand.</figcaption></figure>
<h2>The hand and the floor</h2><p>Hold the black point and follow the small drawing. Its partner moves over the larger floor drawing. Press the held point's trigger to replace once. Release parks the point on its selected span. The original upright exhibit and its FORM, TURN and RULE controls remain.</p><p>The reader chooses the nearest point on the path. You can skip a fold; the reading then jumps. It measures an address along the curve, not the accumulated distance your hand travelled. The floor version is a non-colliding drawing on the museum's existing support.</p>
<div><button id="first" aria-pressed="true" onclick="stage(false)">First replacement</button><button id="fourth" aria-pressed="false" onclick="stage(true)">Fourth replacement</button></div>
<figure><img id="route" src="images/floor-first.png" alt="Four segments make the first detour between fixed endpoints"><figcaption id="route-caption">First replacement: four segments, 5.333 metres of path. Same camera in both captures.</figcaption></figure>
<h2>What the student learns here</h2><table><tr><th>Carried in</th><th>New construction</th><th>Carried out</th></tr><tr><td>PointBody; the known line renderer; ordered positions from Trace; Cantor's separate current and next arrays.</td><td>One neighbouring pair becomes four equilateral segments. Preserve endpoints; sum all segment lengths; turn the rule with its input.</td><td>A finite geometry-replacement function and distinct measurements of displacement and path length.</td></tr></table>
<p>The complete three-file example runs in the prepared museum workspace. All dependencies are printed: <code>koch.gd</code>, unchanged <code>point_body.gd</code>, and unchanged <code>line_skin.gd</code>. No dollar references or missing scene nodes. The supplied closest-point reader is separated from the main operations in the explanation. On desktop, Enter advances; XR uses the held point's existing action signal.</p>
<figure><img src="images/student.png" alt="The exact printed small Koch study running inside the museum"><figcaption>The exact scripts extracted from tutorial.md, temporarily placed beside the existing artifacts for this capture. Two replacements, sixteen segments. The museum supplies the camera, light and player.</figcaption></figure>
<p><a href="parallel.html">Read tutorial on the left and reflection on the right</a> · <a href="student-files.zip">Download the tested student files</a></p>
<h2>The rest of this hall</h2><p>Sierpinski compares the same replacement pattern on a face: three half-size corners retain three quarters of the area. Its existing kept/ghost/negative views remain. Box counting stays an optional investigation over a fixed sample. The student does not have to rebuild every visible artifact to proceed.</p>
<figure><img src="images/triangle.png" alt="Existing Sierpinski negative view shows removed middles in the museum"><figcaption>The retained comparison: change which computed parts receive meshes. The corner data and rule stay available.</figcaption></figure>
<h2>Before and after the room addition</h2><div class="pair"><figure><img src="images/before.png" alt="Original Koch desk without the added hand table or floor receiver"><figcaption>Prior appearance reconstructed by hiding only the new receiver in this isolated run. The original artifact and lighting remain.</figcaption></figure><figure><img src="images/arrival.png" alt="Koch desk with its new hand table and floor receiver"><figcaption>Same camera, new hand station visible. All ten authored map placements and the seven-hall sequence remain.</figcaption></figure></div>
<figure><img src="images/above.png" alt="Elevated view of the hand table, original upright Koch curve and supported floor drawing"><figcaption>Placement survey from within the museum. The hand table sits beside the original desk; the floor line occupies the open study area.</figcaption></figure>
<blockquote>A route can remain exact after this body loses the means to perform every part of it.</blockquote><p>The added final.md passage follows the point between two scales, then asks what happens when a precise fold becomes too small for a separate step. The rest of the hall's reflection stays. <a href="changes.html">Review text before and after.</a></p>
<h2>Checks and limits</h2><div class="notes"><p><strong>39 lesson / artifact checks:</strong> exact printed files; counts, individual lengths, unchanged endpoints, preserved seed, tilted and mirrored variants, nearest-path reading, actual XRTools pickup/action/release and named desktop input. Production and student geometry agree through all four stages.</p><p><strong>33 museum checks:</strong> installed controls, standing height/clearance, actual ray targeting, support beneath every fourth-generation floor vertex, retained Sierpinski and measuring comparisons, clear central route samples, and capture cameras. The finite display tops out at 256 open segments or 768 closed segments.</p><p>These are in-engine checks with supplied poses. Physical headset feel and learner understanding remain open. Existing UID/Jolt/renderer diagnostics are retained in the logs; the final runs have no script errors.</p></div>
<p><a href="tests/lesson-and-artifact.json">Lesson assertions</a> · <a href="tests/museum.json">Museum assertions</a> · <a href="tests/extraction.json">Printed file hashes</a> · <a href="evidence.json">Source evidence</a> · <a href="image-sources.json">Image provenance</a></p><p>Next: Menger. The replacement operation moves from a line and face into cells of a cube.</p></main>
<script>function stage(fourth){{document.getElementById('route').src='images/floor-'+(fourth?'fourth':'first')+'.png';document.getElementById('route').alt=fourth?'256 finite Koch segments on the supported museum floor':'Four segments make the first detour between fixed endpoints';document.getElementById('first').setAttribute('aria-pressed',String(!fourth));document.getElementById('fourth').setAttribute('aria-pressed',String(fourth));document.getElementById('route-caption').textContent=fourth?'Fourth replacement: 256 segments, 12.642 metres of path; endpoints remain four metres apart. Same camera.':'First replacement: four segments, 5.333 metres of path. Same camera in both captures.';}}</script>'''
(OUT/'index.html').write_text(page('Koch — the distance between',body),encoding='utf-8')

with zipfile.ZipFile(OUT/'student-files.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in STUDY.glob('*.gd'): z.write(p,p.name)
    z.write(HALL/'tutorial.md','tutorial.md')
    z.writestr('READ-ME.txt','Use the existing configured Endless Museum workspace with XRTools. Save all three .gd files together; attach koch.gd to an empty unit-scale PointStudy Node3D. It creates the lesson objects. The camera, lighting, player and XR hands belong to Day Zero. This is not a standalone Godot project. Enter or the held point trigger advances; run again to reset.\n')
dump(OUT/'image-sources.json',images)
paths=['commons/artifacts/koch_sierpinski_lesson/koch_sierpinski_lesson.gd','commons/artifacts/koch_sierpinski_lesson/hand_path.gd','commons/artifacts/recursive_tree_lesson/fork_point.gd','algorithms/fractals/example_8_5_koch_curve_vr.gd','commons/maps/Fractal_KochSierpinski/tutorial.md','commons/maps/Fractal_KochSierpinski/final.md','commons/maps/Fractal_KochSierpinski/technical.md','tools/probes/koch_hand.gd','tools/probes/koch_hand_museum.gd']
dump(OUT/'evidence.json',{'checks':count,'reports':dict(reports),'source_sha256':{p:sha(ROOT/p) for p in paths},'student_extraction':json.loads(read(OUT/'tests/extraction.json')),'headset_verified':False,'before_capture':'Only new receiver hidden in the isolated current museum; original source and lighting preserved.'})
plan=json.loads(read(ROOT/'doc/book/course/execution-plan/plan.json'))
lesson=next(row for row in plan['lessons'] if row['id']=='Fractal_KochSierpinski')
dump(OUT/'lesson-plan.json',lesson)
(OUT/'SUMMARY.md').write_text('# Koch / Sierpinski — short instruction\n\n'+lesson['summary']+'\n\nKoch | ordered positions → separate next; four thirds, fixed endpoints; sum neighbours; XY plane declared; same PointBody; trigger requests one step; nearest span ≠ hand odometer; floor reads same data; cap4; mirror + tilted seed predictions; triangle comparison, box count optional; Menger next.\n',encoding='utf-8')
links=0
for p in OUT.glob('*.html'):
    for target in re.findall(r'(?:href|src)="([^"]+)"',read(p)):
        if target.startswith(('http:','https:','res:','mailto:')): continue
        parts=urlsplit(html.unescape(target)); dest=(p.parent/unquote(parts.path)).resolve() if parts.path else p
        assert dest.exists(),(p.name,target)
        if parts.fragment and dest.suffix=='.html': assert f'id="{unquote(parts.fragment)}"' in read(dest),(p.name,target)
        links+=1
print('Published',OUT,'with',count,'checks;',links,'references valid.')
