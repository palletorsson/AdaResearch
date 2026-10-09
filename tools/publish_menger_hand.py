"""Publish verified Menger text and native museum evidence; never rewrite manuscript sources."""
from pathlib import Path
import html,json,hashlib,re,shutil,zipfile,difflib
from urllib.parse import urlsplit,unquote
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-menger-a-cell-and-a-room'
RUN=ROOT/'ada_run/encounter_pilot/Fractal_MengerSponge'
HALL=ROOT/'commons/maps/Fractal_MengerSponge'
STUDY=ROOT/'doc/book/studies/fractals-through-the-hands/Fractal_MengerSponge'
def read(p):return p.read_text(encoding='utf-8-sig')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,v):p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
for name in ['images','tests']:(OUT/name).mkdir(parents=True,exist_ok=True)
reports=[]
for source,slug,log in [(ROOT/'ada_run/menger_hand_tests.json','lesson-and-artifact',ROOT/'ada_run/menger-hand-engine.log'),(RUN/'report.json','museum',RUN/'engine.log')]:
    data=json.loads(read(source));assert data['passed'] and not data['failures']
    assert 'SCRIPT ERROR' not in read(log)
    shutil.copy2(source,OUT/'tests'/f'{slug}.json');shutil.copy2(log,OUT/'tests'/f'{slug}.log')
    reports.append((slug,len(data['checks'])))
shutil.copy2(ROOT/'ada_run/menger_student/extraction.json',OUT/'tests/extraction.json')
images=[]
for name in ['before','arrival','hand-seed','hand-first','hand-second','cell-and-room','second-cut','ghosts','small-opening','inside','above','student']:
    source=RUN/f'{name}.png';shutil.copy2(source,OUT/'images'/source.name)
    kind='native Godot, current museum with supplied input'
    if name=='before':kind='native Godot; hand model hidden and film returned to prior position; current corrected portals retained'
    if name=='student':kind='native Godot; exact printed learner script temporarily placed in current museum, production hand model hidden'
    images.append({'file':'images/'+source.name,'source':source.relative_to(ROOT).as_posix(),'sha256':sha(source),'kind':kind})
for track in ['tutorial','final','technical']:shutil.copy2(HALL/f'{track}.md',OUT/f'{track}.md')
count=sum(n for _,n in reports)
style=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-10-08-koch-the-distance-between/index.html'),re.S)[1]
style+=' .lead{max-width:850px}.single{max-width:900px}.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:22px}button[aria-pressed=true]{background:#28232b;color:#fff}figcaption{max-width:900px}pre{overflow:auto} @media print{nav,button{display:none}details{display:block}}'
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+style+'</style></head><body><header><p class="eyebrow">Endless Museum · Fractals 05 · 8 October 2026</p><nav><a href="index.html">Inside the museum</a><a href="parallel.html">Tutorial / reflection</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="student-files.zip">Student files</a></nav></header>'+body+'<footer>Native Godot evidence. Physical headset feel, Quest performance and learner understanding remain untested.</footer></body></html>'
def md(text,prefix):
    result=markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
    result=re.sub(r'id="([^"]+)"',lambda m:f'id="{prefix}-{m[1]}"',result)
    return re.sub(r'href="#([^"]+)"',lambda m:f'href="#{prefix}-{m[1]}"',result)
for track in ['tutorial','final']:
    (OUT/f'{track}.html').write_text(page('Menger — '+track,'<main class="reading single">'+md(read(HALL/f'{track}.md'),track)+'</main>'),encoding='utf-8')
(OUT/'parallel.html').write_text(page('Menger — tutorial and reflection','<main class="pair reading"><article><p class="eyebrow">Left · tutorial.md · reconstruct the operation</p>'+md(read(HALL/'tutorial.md'),'tutorial')+'</article><article><p class="eyebrow">Right · final.md · encounter and reflection</p>'+md(read(HALL/'final.md'),'final')+'</article></main>'),encoding='utf-8')
changes='<main><h1>What changed here</h1><p>The tutorial now builds one complete small example. The existing reflection gains two paragraphs. The hand model reads the original generator; six artifacts remain. The monitor moves aside and the hall markers put the next portal beyond the rear flight door.</p>'
for track in ['tutorial','final','technical','map_data']:
    suffix='.json' if track=='map_data' else '.md'
    old=read(OUT/'before'/(track+suffix));new=read(HALL/(track+suffix))
    (OUT/f'{track}.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+track+suffix,tofile='current/'+track+suffix)),encoding='utf-8')
    changes+=f'<h2>{track}{suffix}</h2><p><a href="{track}.diff">Plain diff</a></p>'
    if suffix=='.md':changes+='<details><summary>Complete before and after</summary><div class="pair reading"><article><p class="eyebrow">Before</p>'+md(old,track+'-before')+'</article><article><p class="eyebrow">After</p>'+md(new,track+'-after')+'</article></div></details>'
changes+='<h2>Placement comparison</h2><div class="pair"><figure><img src="images/before.png" alt="Sponge before adding the hand model, with the film at its old position"><figcaption>Hand model hidden; film at its earlier position. The corrected portal placement is retained, so this is a comparison of the desk addition, not a complete historical replay.</figcaption></figure><figure><img src="images/arrival.png" alt="Sponge with the new hand model and monitor moved aside"><figcaption>Same camera with the hand model and new film placement.</figcaption></figure></div></main>'
(OUT/'changes.html').write_text(page('Menger — before and after',changes),encoding='utf-8')

body=f'''<main><h1>A cell in the hand.<br>A room to enter.</h1><p class="lead">Menger carries the replacement rule into a volume. The same point now reads a cell; the familiar cube becomes twenty cubes, then four hundred. The student can reconstruct the selection before entering its consequences.</p><p class="pill">{count} native checks passed · complete printed code · 12 museum captures</p>
<figure><img src="images/hand-first.png" alt="A black grabbable point beside a transparent Menger model, with a pink frame around a removed first-level cell"><figcaption>The new hand model beside the existing desk. Move the point to read a cell. Its frame is repeated on the nine-metre sponge. The trigger and nearby NEXT both request one cut.</figcaption></figure>
<h2>Keep twenty. Repeat.</h2><p>Three nested loops offer twenty-seven offsets. A short Boolean function rejects cells with two or three middle coordinates: the six face centres and the centre. The other twenty remain. The student carries the current/next array pattern from Cantor and Koch, the cube from Primitives, and PointBody from earlier interaction lessons.</p>
<table><tr><th>Cut</th><th>Retained cubes</th><th>Cube edge</th><th>Represented volume</th></tr><tr><td>0</td><td>1</td><td>9 m</td><td>729 m³</td></tr><tr><td>1</td><td>20</td><td>3 m</td><td>540 m³</td></tr><tr><td>2</td><td>400</td><td>1 m</td><td>400 m³</td></tr></table>
<p>The outer size remains nine metres. More objects represent less retained material. The model scales the geometry by 0.09 for the hand; the numbers still refer to the nine-metre construction.</p>
<div><button id="first" aria-pressed="true" onclick="stage(false)">One cut</button> <button id="second" aria-pressed="false" onclick="stage(true)">Two cuts</button></div><figure><img id="model" src="images/hand-first.png" alt="Transparent twenty-cube model after one cut"><figcaption id="model-caption">One cut: twenty retained cubes. The outlined face-centre cell is removed. Same camera in both views.</figcaption></figure>
<p>The reader always names a first-level cell. At cut two, KEEP can enclose smaller absences. It describes one selection at one scale. The model is transparent and has no cube colliders; the large sponge remains solid.</p>
<h2>The tutorial and the reflection</h2><div class="pair"><article><h3>tutorial.md</h3><p>Complete <code>menger.gd</code> plus unchanged <code>point_body.gd</code>. No hidden scene references. A Boolean predicate, separate next list, fixed budget, count/volume prediction and an executed corner-only variation. The prepared museum supplies the camera, lighting, player and XRTools.</p></article><article><h3>final.md</h3><p>Preserves the existing passage from removal to inhabitation. Two additions follow the same cell through the small model and large structure, then question what KEEP means when a later cut removes something inside it.</p></article></div>
<p><a href="parallel.html">Read the tutorial on the left and reflection on the right</a> · <a href="student-files.zip">Download the exact tested learner files</a> · <a href="changes.html">Review before and after</a></p>
<figure><img src="images/student.png" alt="The exact printed student study shows 400 translucent cubes and the carried black point inside the museum"><figcaption>The exact scripts extracted from tutorial.md, temporarily running at the museum workspace. The student script generates the model; the production installation additionally supplies its furniture, cell frames and full-size receiver.</figcaption></figure>
<h2>Enter what was removed</h2><figure><img src="images/above.png" alt="Elevated view from inside the glass enclosure over the large two-cut Menger sponge"><figcaption>The existing nine-metre sponge after two cuts. The same 400 retained positions can now be read as an arrangement of passages.</figcaption></figure>
<div class="gallery"><figure><img src="images/inside.png" alt="View through the large central opening inside the Menger sponge"><figcaption>The three-metre central passage admits the tested standing capsule.</figcaption></figure><figure><img src="images/small-opening.png" alt="Long sight line through a one-metre axial opening"><figcaption>A ray passes through this smaller opening. A standing capsule collides at its entrance. Visibility is not a guarantee of bodily access.</figcaption></figure></div>
<blockquote>The word belongs to one decision at one scale. It was never a promise that everything inside would remain.</blockquote>
<h2>Two spatial corrections</h2><p>The film monitor at cell (10, 1) obstructed the new hand station. It now stands at (3, 1). The old entry/exit markers also failed the museum's portal-clearance checks, placing the next-hall portal directly before the flight entrance. The entry now uses (7, 1), and one supported exit at (7, 17) leads onward from beyond the rear flight doorway. The shared generator, flight and portal code are unchanged.</p>
<p>The original desk's occupant guard also protects the point's trigger and the new buttons. NEXT, BACK and RESET refuse solid changes while someone is inside. Leaving does not execute a pending request. Readings, GHOST and FRAME can change without rebuilding around a visitor.</p>
<h2>What was tested</h2><div class="notes"><p><strong>{reports[0][1]} lesson / artifact checks:</strong> exact printed files; all 27 selection decisions; retained positions equivalent to the production generator; stages zero to two; bounds and volume; separate input/output arrays; executed eight-corner alternative; rotated coordinate frames; XRTools pickup, action and release; desktop hooks; same occupant guard.</p><p><strong>{reports[1][1]} museum checks:</strong> nearby controls through the actual desktop ray; supported standing approach; ghost/frame collision; occupied-room refusal and fresh retry; central versus small axial passage; shipped walker ascent, hover and restored gravity; authored portal placement and intentional onward journey; native capture cameras.</p><p>Headset feel, Quest performance and learner understanding still need human observation. Existing UID, viewport and Jolt diagnostics remain in the logs; these final runs have no script errors. Test poses keep portal streaming paused during the stationary exhibit checks, then resume it for the deliberate onward walk.</p></div>
<p><a href="tests/lesson-and-artifact.json">Lesson assertions</a> · <a href="tests/museum.json">Museum assertions</a> · <a href="tests/extraction.json">Printed code hashes</a> · <a href="evidence.json">Source evidence</a> · <a href="image-sources.json">Image provenance</a></p>
<p>Next: Golden Spiral. A numerical recurrence supplies quantities; placing them in space requires another decision.</p></main>
<script>function stage(second){{document.getElementById('model').src='images/hand-'+(second?'second':'first')+'.png';document.getElementById('model').alt=second?'Four hundred retained cubes inside the same outer bounds':'Twenty retained cubes inside the same outer bounds';document.getElementById('first').setAttribute('aria-pressed',String(!second));document.getElementById('second').setAttribute('aria-pressed',String(second));document.getElementById('model-caption').textContent=second?'Two cuts: four hundred cubes; the first-level address still refers to its parent region. Same camera.':'One cut: twenty retained cubes. The outlined face-centre cell is removed. Same camera in both views.';}}</script>'''
(OUT/'index.html').write_text(page('Menger — a cell and a room',body),encoding='utf-8')
with zipfile.ZipFile(OUT/'student-files.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in STUDY.glob('*.gd'):z.write(p,p.name)
    z.write(HALL/'tutorial.md','tutorial.md')
    z.writestr('READ-ME.txt','Use the configured Endless Museum workspace with XRTools. Save both .gd files together and attach menger.gd to an empty unit-scale PointStudy Node3D. Camera, light and player come from the museum. Enter or the held point trigger advances; run again to reset. This is not a standalone Godot project.\n')
dump(OUT/'image-sources.json',images)
paths=['commons/artifacts/menger_lesson/menger_lesson.gd','commons/artifacts/menger_lesson/hand_cells.gd','commons/artifacts/recursive_tree_lesson/fork_point.gd','algorithms/fractals/mengersponge/menger_sponge.gd','commons/movement/museum_flight_box.gd','commons/maps/Fractal_MengerSponge/tutorial.md','commons/maps/Fractal_MengerSponge/final.md','commons/maps/Fractal_MengerSponge/technical.md','commons/maps/Fractal_MengerSponge/map_data.json','tools/probes/menger_hand.gd','tools/probes/menger_hand_museum.gd']
assert sha(ROOT/'algorithms/fractals/mengersponge/menger_sponge.gd')==sha(OUT/'before/menger_sponge.gd')
dump(OUT/'evidence.json',{'checks':count,'reports':dict(reports),'source_sha256':{p:sha(ROOT/p) for p in paths},'student_extraction':json.loads(read(OUT/'tests/extraction.json')),'headset_verified':False,'before_capture':'New reader hidden and old film position restored; current corrected portals remain.','generator_unchanged':True})
plan=json.loads(read(ROOT/'doc/book/course/execution-plan/plan.json'));lesson=next(row for row in plan['lessons'] if row['id']=='Fractal_MengerSponge')
baseline=json.loads(read(OUT/'before/lesson-plan.json'));assert lesson['baseline']==baseline['baseline'] and lesson['decision']==baseline['decision']
dump(OUT/'lesson-plan.json',lesson)
(OUT/'SUMMARY.md').write_text('# Menger — short instruction\n\n'+lesson['summary']+'\n\nMenger | cube centres + common edge; offset -1/0/1; keep <2 middles; current→next;20^n; volume729×(20/27)^n; bounds9³; cap2; PointBody reads first cell; trigger requests guarded NEXT; transparent model≠solid room; corners-only test8/64; enter→compare body/ray→return; Golden next.\n',encoding='utf-8')
links=0
for p in OUT.glob('*.html'):
    for target in re.findall(r'(?:href|src)="([^"]+)"',read(p)):
        if target.startswith(('http:','https:','res:','mailto:')):continue
        parts=urlsplit(html.unescape(target));dest=(p.parent/unquote(parts.path)).resolve() if parts.path else p
        assert dest.exists(),(p.name,target)
        if parts.fragment and dest.suffix=='.html':assert f'id="{unquote(parts.fragment)}"' in read(dest),(p.name,target)
        links+=1
print('Published',OUT,'with',count,'checks;',links,'references valid.')
