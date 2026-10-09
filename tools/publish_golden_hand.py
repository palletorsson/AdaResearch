"""Publish current manuscript and native evidence; never rewrite canonical sources."""
from pathlib import Path
import html,json,hashlib,re,shutil,zipfile,difflib
from urllib.parse import urlsplit,unquote
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-golden-two-values-two-views'
H=R/'commons/maps/Fractal_GoldenSpiral'
S=R/'doc/book/studies/fractals-through-the-hands/Fractal_GoldenSpiral'
RUN=R/'ada_run/encounter_pilot/Fractal_GoldenSpiral'
def read(p):return p.read_text(encoding='utf-8-sig')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,v):p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
for n in ['images','tests']:(O/n).mkdir(parents=True,exist_ok=True)
reports={}
for source,slug,log in [(R/'ada_run/golden_hand_tests.json','lesson-and-artifact',R/'ada_run/golden-hand-engine.log'),(RUN/'report.json','museum',RUN/'engine.log')]:
    data=json.loads(read(source));assert data['passed'] and not data['failures'] and 'SCRIPT ERROR' not in read(log)
    shutil.copy2(source,O/'tests'/f'{slug}.json');shutil.copy2(log,O/'tests'/f'{slug}.log');reports[slug]=len(data['checks'])
shutil.copy2(R/'ada_run/golden_student/extraction.json',O/'tests/extraction.json')
images=[]
for name in ['before','arrival','two-seeds','one-sum','two-views','large-log','large-linear','unit-sum','added-rules','rectangle','rectangle-no-arc','overview','student']:
    p=RUN/f'{name}.png';shutil.copy2(p,O/'images'/p.name)
    kind='Native Godot in current Endless Museum; supplied input.'
    if name=='before':kind='Native comparison: new hand table hidden; existing hall otherwise unchanged.'
    if name=='student':kind='Exact tutorial scripts temporarily substituted at hand-table location in the museum; installation furniture hidden.'
    images.append({'file':'images/'+p.name,'source':p.relative_to(R).as_posix(),'sha256':sha(p),'kind':kind})
figure=R/'doc/book/figures/fractals/helix-against-golden-spiral.png'
shutil.copy2(figure,O/'images'/figure.name)
for track in ['tutorial','final','technical']:shutil.copy2(H/f'{track}.md',O/f'{track}.md')
style=re.search(r'<style>(.*?)</style>',read(R/'doc/book/iterations/2026-10-08-menger-a-cell-and-a-room/index.html'),re.S)[1]
style+=' .single{max-width:920px}.hero{max-width:1280px;margin:20px auto}table{width:100%;border-collapse:collapse}td,th{padding:12px;border-bottom:1px solid #d8d1ca;text-align:left}img{max-width:100%;height:auto}button{cursor:pointer}a{overflow-wrap:anywhere}.lead{font-size:1.22rem;max-width:850px}.pair article{min-width:0}'
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+style+'</style></head><body><header><p class="eyebrow">Endless Museum · Fractals 06 · 8 October 2026</p><nav><a href="index.html">Inside the museum</a><a href="parallel.html">Tutorial / reflection</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="student-files.zip">Student files</a></nav></header>'+body+'<footer>Native Godot captures. Headset feel, Quest performance and learner understanding remain untested.</footer></body></html>'
def md(text,prefix):
    text=text.replace('/book-review/doc/book/figures/fractals/helix-against-golden-spiral.png','images/helix-against-golden-spiral.png')
    out=markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
    out=re.sub(r'id="([^"]+)"',lambda m:f'id="{prefix}-{m[1]}"',out)
    return re.sub(r'href="#([^"]+)"',lambda m:f'href="#{prefix}-{m[1]}"',out)
for track in ['tutorial','final']:
    (O/f'{track}.html').write_text(page('Golden Spiral — '+track,'<main class="single reading">'+md(read(H/f'{track}.md'),track)+'</main>'),encoding='utf-8')
(O/'parallel.html').write_text(page('Golden Spiral — two texts','<main class="pair reading"><article><p class="eyebrow">Left · tutorial.md · reconstruct the operation</p>'+md(read(H/'tutorial.md'),'tutorial')+'</article><article><p class="eyebrow">Right · final.md · encounter and reflection</p>'+md(read(H/'final.md'),'final')+'</article></main>'),encoding='utf-8')
changes='<main><h1>Before and after</h1><p>One new hand table beside the original numbers desk. All seven specimens, their placement, original generators and existing controls remain. The tutorial now contains a complete tested reconstruction. The reflection follows the point and the simultaneous views.</p>'
for name in ['tutorial.md','final.md','technical.md']:
    old=read(O/'before'/name);new=read(H/name)
    diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
    (O/(name+'.diff')).write_text(diff,encoding='utf-8')
    changes+=f'<h2>{name}</h2><p><a href="{name}.diff">Plain diff</a></p><details><summary>Read both versions</summary><div class="pair reading"><article>'+md(old,name+'-old')+'</article><article>'+md(new,name+'-new')+'</article></div></details>'
changes+='<h2>The new neighbour</h2><div class="pair"><figure><img src="images/before.png" alt="Existing Fibonacci desk with the new hand table hidden"><figcaption>New hand table hidden for comparison.</figcaption></figure><figure><img src="images/arrival.png" alt="Hand table beside the original Fibonacci desk"><figcaption>Same camera. The new table sits beside the original console.</figcaption></figure></div></main>'
(O/'changes.html').write_text(page('Golden Spiral — changes',changes),encoding='utf-8')
count=sum(reports.values())
body=f'''<main><h1>Two values.<br>Two ways to give them height.</h1><p class="lead">After Menger's cube becomes a room, the familiar point returns to the hand. Two points carry the last two values. Bring them together and ask the museum for their sum.</p><p class="pill">{count} Godot checks passed · 13 museum captures · complete two-file tutorial</p>
<figure class="hero"><img src="images/two-views.png" alt="Two held-value spheres and adjacent linear and logarithmic rows on an off-white museum table"><figcaption>Same ten values, two height functions. The nearby points now carry34 and55. The view headings stay visible above their rows.</figcaption></figure>
<h2>One meeting, one next term</h2><figure><img src="images/one-sum.png" alt="Two points labelled1 touch while the readout states1 plus1 equals2"><figcaption>Move one point to its resting partner, or hold both. Keeping them together adds only once. Release both before requesting the next sum. The trigger offers the same request.</figcaption></figure>
<p>The points retain their shape and size. Their labels carry the quantities. On the table, a fixed unit makes early values small; the supplied logarithmic function keeps them conspicuous while compressing later values. Neither view edits the record.</p>
<h2>What the student makes</h2><table><tr><th>Carried from earlier halls</th><th>Added here</th></tr><tr><td>PointBody, pickup/release, arrays, loops and a BoxMesh</td><td>Read the last two entries and append their sum</td></tr><tr><td>A threshold and a Boolean state</td><td>One contact per request; release rearms it</td></tr><tr><td>Data separated from displayed scale</td><td>The same list read by two height functions</td></tr></table>
<p>The exact printed scripts run in the prepared museum workspace. The installation uses the same construction with an adapter to the existing desk. The learner's small version owns its record and computes each new term. Change only the seeds to1 and2: predict, then verify the tenth value89.</p>
<p><a href="parallel.html">Read tutorial left / reflection right</a> · <a href="student-files.zip">Download the tested files</a> · <a href="changes.html">Compare the changes</a></p>
<figure><img src="images/student.png" alt="The exact printed two-file study running in the current museum"><figcaption>Exact code extracted from tutorial.md, temporarily substituted at this location. The museum furniture is separate from the minimal example.</figcaption></figure>
<h2>Keep a common unit in sight</h2><figure><img src="images/unit-sum.png" alt="Two equal-height stacks represent21 plus34 and55"><figcaption>The existing SUM witness:21 units plus34 units match55. Each large unit is5cm. The small linear table uses a common0.2 reduction, so its units are1cm.</figcaption></figure>
<div><button onclick="mapping(false)">Large logarithmic view</button> <button onclick="mapping(true)">Large linear view</button></div><figure><img id="large-mapping" src="images/large-log.png" alt="The large towers using logarithmic heights"><figcaption id="large-caption">Logarithmic heights; the stored values remain1,1,2,3,5,8,13,21,34,55. Same camera in both views.</figcaption></figure>
<h2>A rectangle is another operation</h2><div><button onclick="arc(true)">With circular arcs</button> <button onclick="arc(false)">Partition only</button></div><figure><img id="rectangle" src="images/rectangle.png" alt="Five measured squares with joined quarter-circle arcs"><figcaption>Five cuts of the existing golden rectangle. The side lengths shrink. ARC adds a curve; it does not generate the partition. These circular pieces are not an exact logarithmic spiral.</figcaption></figure>
<p>This remains a comparison, alongside the helix, seed arrangement and other constructed forms. The required tutorial stays with one record and its readers. Seven artifacts remain in the hall.</p>
<blockquote>Their bodies give the quantities a place in your hands. What a value does to the next body is still a choice.</blockquote>
<details><summary>See the surrounding collection</summary><figure><img src="images/added-rules.png" alt="Seed points, layered scales and shell-like construction on an existing supported display"><figcaption>The retained objects use further position, angle and scale choices.</figcaption></figure><figure><img src="images/overview.png" alt="Elevated view over the museum's towers, supported specimens and rectangle"><figcaption>Native elevated view through the hall. No map reorder or placement changes in this pass.</figcaption></figure></details>
<h2>Verification</h2><p>{reports['lesson-and-artifact']} checks execute the printed code and independent seed variation, compare the existing source, test actual mesh heights, contact/release behaviour, the unit witness and rectangle area/proportion. {reports['museum']} checks cover the installed room, real desktop-ray controls, XRTools with supplied hand poses, standing clearance, both authored portals and capture cameras.</p><p>All final runs exited successfully with no script errors. These checks do not establish physical headset feel, Quest performance or student comprehension. Existing UID and renderer diagnostics remain in the logs.</p>
<p><a href="tests/lesson-and-artifact.json">Lesson assertions</a> · <a href="tests/museum.json">Museum assertions</a> · <a href="tests/extraction.json">Printed-code hashes</a> · <a href="evidence.json">Source evidence</a> · <a href="SUMMARY.md">Short instruction</a></p><p>Next: Fractal Synthesis. Choose the seed, operation, stopping condition and display; compose with their differences.</p></main>
<script>function mapping(linear){{document.getElementById('large-mapping').src='images/large-'+(linear?'linear':'log')+'.png';document.getElementById('large-mapping').alt=linear?'The same ten values shown with linear heights':'The same ten values shown with logarithmic heights';document.getElementById('large-caption').textContent=(linear?'Linear: five centimetres per unit.':'Logarithmic: compressed heights.')+' Same values and camera.';}}function arc(on){{document.getElementById('rectangle').src='images/rectangle'+(on?'':'-no-arc')+'.png';document.getElementById('rectangle').alt=on?'Five measured squares with circular arcs':'The same five squares without the arc';}}</script>'''
# Keep readable spacing in copy independently of compact research notes.
body=body.replace('carry34 and55','carry 34 and 55').replace('to1 and2','to 1 and 2').replace('value89','value 89').replace(':21',': 21').replace('plus34','plus 34').replace('match55','match 55').replace('is5cm','is 5 cm').replace('common0.2','common 0.2').replace('are1cm','are 1 cm').replace('remain1,','remain 1,')
(O/'index.html').write_text(page('Golden Spiral — two values, two views',body),encoding='utf-8')
with zipfile.ZipFile(O/'student-files.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in S.glob('*.gd'):z.write(p,p.name)
    z.write(H/'tutorial.md','tutorial.md')
    z.writestr('READ-ME.txt','Use the configured Endless Museum workspace and installed XRTools. Save both scripts together; attach sum_points.gd to an empty unit-scale Node3D on the workspace floor. Museum camera, lighting and player are already supplied. Join the last two points, press a held trigger or Enter to add once. Release both points between held requests. Run again to reset. No standalone project or new camera/player included.\n')
paths=['commons/artifacts/golden_mapping_lesson/'+n for n in ['golden_mapping_lesson.gd','hand_sum.gd','sum_points.gd','point_body.gd']]+['commons/maps/Fractal_GoldenSpiral/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+['tools/probes/golden_hand.gd','tools/probes/golden_hand_museum.gd','algorithms/fractals/fibonacci_sequences/FibonacciSequences.gd','algorithms/fractals/golden_rectangle/golden_rectangle.gd']
for path in paths[-2:]:assert sha(R/path)==sha(O/'before'/Path(path).name)
assert sha(H/'map_data.json')==sha(O/'before/map_data.json')
plan=json.loads(read(R/'doc/book/course/execution-plan/plan.json'));lesson=next(r for r in plan['lessons'] if r['id']=='Fractal_GoldenSpiral')
old=json.loads(read(O/'before/lesson-plan.json'));assert lesson['decision']==old['decision'] and lesson['baseline']==old['baseline']
dump(O/'lesson-plan.json',lesson)
(O/'SUMMARY.md').write_text('# Golden Spiral — two values, two views\n\n'+lesson['summary']+'\n\nGolden | carry PointBody + array + cube; last two → sum → append; cap10; contact once/release both; same positive record → linear0.05n / supplied0.5ln(n)+0.5; model×0.2; compare SUM; seeds1,2 test ends89; rectangle cut≠numeric growth; arcs≠exact log spiral; Synthesis next.\n',encoding='utf-8')
dump(O/'image-sources.json',images)
dump(O/'evidence.json',{'checks':count,'reports':reports,'source_sha256':{p:sha(R/p) for p in paths},'student_extraction':json.loads(read(O/'tests/extraction.json')),'headset_verified':False,'map_and_original_generators_unchanged':True,'before_capture':'Only new hand table hidden. Existing hall unchanged.','existing_figure':{'path':figure.relative_to(R).as_posix(),'sha256':sha(figure),'kind':'Previously published comparison diagram; not a new museum screenshot.'}})
links=0
for p in O.glob('*.html'):
    for target in re.findall(r'(?:href|src)="([^"]+)"',read(p)):
        if target.startswith(('http:','https:','mailto:','res:')):continue
        parts=urlsplit(html.unescape(target));dest=(p.parent/unquote(parts.path)).resolve() if parts.path else p
        assert dest.exists(),(p.name,target)
        if parts.fragment and dest.suffix=='.html':assert f'id="{unquote(parts.fragment)}"' in read(dest),(p.name,target)
        links+=1
print('Published',count,'checks;',len(images),'native captures;',links,'references validated.')
