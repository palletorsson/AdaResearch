"""Publish exact manuscripts and native evidence without rewriting authoring sources."""
from pathlib import Path
import html, json, hashlib, re, shutil, zipfile, difflib
from urllib.parse import urlsplit, unquote
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-synthesis-a-rule-kept'
H=R/'commons/maps/Fractal_Synthesis'
S=R/'doc/book/studies/fractals-through-the-hands/Fractal_Synthesis'
RUN=R/'ada_run/encounter_pilot/Fractal_Synthesis'
def read(p):return p.read_text(encoding='utf-8-sig')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,obj):p.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
for name in ['images','tests']:(O/name).mkdir(parents=True,exist_ok=True)
reports={}
for source,slug,log in [(R/'ada_run/synthesis_recipe_tests.json','lesson-and-artifact',R/'ada_run/synthesis-recipe-engine.log'),(RUN/'report.json','museum',RUN/'engine.log')]:
    data=json.loads(read(source));assert data['passed'] and not data['failures'] and 'SCRIPT ERROR' not in read(log)
    shutil.copy2(source,O/'tests'/f'{slug}.json');shutil.copy2(log,O/'tests'/f'{slug}.log');reports[slug]=len(data['checks'])
shutil.copy2(R/'ada_run/synthesis_student/extraction.json',O/'tests/extraction.json')
images=[]
for name in ['before','arrival','thirds','quarters','comparison','restored','five-cuts','cantor','tree','overview','student','exit']:
    p=RUN/f'{name}.png';assert p.exists();shutil.copy2(p,O/'images'/p.name)
    kind='Native Godot in current Endless Museum with supplied input.'
    if name=='before':kind='Comparison capture with new table hidden, not a historical capture; repaired exit remains.'
    if name=='student':kind='Exact printed scripts temporarily substituted for table, installation furniture hidden.'
    images.append({'file':'images/'+p.name,'source':p.relative_to(R).as_posix(),'sha256':sha(p),'kind':kind})
for track in ['tutorial','final','technical']:shutil.copy2(H/f'{track}.md',O/f'{track}.md')
style=re.search(r'<style>(.*?)</style>',read(R/'doc/book/iterations/2026-10-08-golden-two-values-two-views/index.html'),re.S)[1]
style+=' .controls{display:flex;gap:12px;flex-wrap:wrap}button{padding:10px 18px;border:1px solid #aaa;background:#eee6de;border-radius:4px;font:inherit}button[aria-pressed=true]{background:#26232a;color:white}.note{border-left:3px solid #b97991;padding:14px 20px}.compare-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:25px}pre{overflow:auto}footer{max-width:1200px;margin:2rem auto;padding:1rem}figcaption{margin:12px 0;color:#534c4a}'
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+style+'</style></head><body><header><p class="eyebrow">Endless Museum · Fractals 07 · 8 October 2026</p><nav><a href="index.html">Inside the museum</a><a href="parallel.html">Tutorial / reflection</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="student-files.zip">Student files</a></nav></header>'+body+'<footer>Native Godot captures. Headset feel, Quest performance and learner understanding remain untested.</footer></body></html>'
def md(text,prefix):
    out=markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
    out=re.sub(r'id="([^"]+)"',lambda m:f'id="{prefix}-{m[1]}"',out)
    return re.sub(r'href="#([^"]+)"',lambda m:f'href="#{prefix}-{m[1]}"',out)
for track in ['tutorial','final']:
    (O/f'{track}.html').write_text(page('Synthesis — '+track,'<main class="single reading">'+md(read(H/f'{track}.md'),track)+'</main>'),encoding='utf-8')
(O/'parallel.html').write_text(page('Synthesis — two texts','<main class="pair reading"><article><p class="eyebrow">Left · tutorial.md · reconstruct the operation</p>'+md(read(H/'tutorial.md'),'tutorial')+'</article><article><p class="eyebrow">Right · final.md · encounter and reflection</p>'+md(read(H/'final.md'),'final')+'</article></main>'),encoding='utf-8')
changes='<main><h1>A small table between two procedures</h1><p>The interval and block tree remain. The new table keeps a recipe while another changes. The tutorial prints both runnable files; three new reflective paragraphs follow the comparison. The only map edit moves the exit marker from the side wall to the existing rear opening.</p>'
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    old=read(O/'before'/name);new=read(H/name)
    diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='current/'+name))
    (O/(name+'.diff')).write_text(diff,encoding='utf-8')
    changes+=f'<h2>{name}</h2><p><a href="{name}.diff">Exact diff</a></p>'
    if name.endswith('.md'):changes+='<details><summary>Read both versions</summary><div class="pair reading"><article>'+md(old,name+'-old')+'</article><article>'+md(new,name+'-new')+'</article></div></details>'
changes+='<div class="compare-grid"><figure><img src="images/before.png" alt="Existing interval and tree desks with the new comparison table hidden"><figcaption>New table hidden in the current room. The repaired exit is present; this is not a historical screenshot.</figcaption></figure><figure><img src="images/arrival.png" alt="The new comparison table between the existing desks"><figcaption>Same camera, table visible. The original artifacts remain.</figcaption></figure></div><p><a href="before/portal-diagnostic.json">Original blocked-exit diagnostic</a></p></main>'
(O/'changes.html').write_text(page('Synthesis — changes',changes),encoding='utf-8')
count=sum(reports.values())
body=f'''<main><h1>A rule kept.<br>A difference still available.</h1><p class="lead">The last Fractals hall brings the familiar point back to the interval. Change how much survives at each end. Keep one recipe while trying another.</p><p class="pill">{count} Godot checks passed · 12 museum captures · complete two-file tutorial</p>
<figure class="hero"><img src="images/comparison.png" alt="Black point on an off-white plinth; dark live bars and rose kept bars on a shared display"><figcaption>Eight pieces in each row. The rose recipe keeps quarters; the live one keeps two fifths. Their counts match, their lengths and gaps differ.</figcaption></figure>
<h2>Move, keep, compare</h2><p>Move the point left, centre or right to retain a quarter, third or two fifths at each end. KEEP or the held trigger copies the current recipe. RESTORE brings that recipe back into LIVE. RESET changes only LIVE. NEXT adds a cut, up to five; release before using NEXT, RESTORE or RESET.</p>
<div class="controls" role="group" aria-label="Compare native captures"><button data-shot="thirds" aria-pressed="true" onclick="show(this)">Begin with thirds</button><button data-shot="quarters" aria-pressed="false" onclick="show(this)">Change to quarters</button><button data-shot="comparison" aria-pressed="false" onclick="show(this)">Keep, then change</button><button data-shot="restored" aria-pressed="false" onclick="show(this)">Restore</button><button data-shot="five-cuts" aria-pressed="false" onclick="show(this)">Five cuts</button></div>
<figure><img id="comparison" src="images/thirds.png" alt="Live and kept rows both begin with thirds"><figcaption id="comparison-caption" aria-live="polite">Both rows begin with thirds and three cuts. Each retains about 1.778 model metres.</figcaption></figure>
<p class="note">KEEP holds one independent recipe during this run. It replaces the preceding comparison and is lost on reload. No disk save or cross-hall drawing import is implied.</p>
<h2>One new task, familiar construction</h2><table><tr><th>Bring</th><th>Learn here</th><th>Carry onward</th></tr><tr><td>PointBody, interval pairs, current/next arrays, loops and BoxMesh</td><td>Package the seed, retained fraction and depth as named settings</td><td>A recipe another reader can reconstruct</td></tr><tr><td>Separating data from its displayed form</td><td>Copy settings, rebuild independently and compare at a common scale</td><td>A precise distinction between changing a rule and changing a view</td></tr></table>
<p>The learner reconstructs the interval replacement rather than a whole new museum. Both complete scripts are visible in tutorial.md. Change only the initial depth from three to four: predict sixteen pieces and about 1.185 metres for thirds, then run it. The automated check executes that edited script too.</p>
<p><a href="parallel.html">Read tutorial left / reflection right</a> · <a href="student-files.zip">Download the tested student files</a> · <a href="changes.html">Review before and after</a></p>
<figure><img src="images/student.png" alt="Exact printed point and two interval rows running in the museum without installation furniture"><figcaption>The exact printed code, temporarily substituted at the table location. The existing museum supplies camera, lighting, player and XRTools.</figcaption></figure>
<h2>The collection still has other work to do</h2><div class="compare-grid"><figure><img src="images/cantor.png" alt="Existing Cantor interval and its console"><figcaption>The original interval desk: HISTORY and GHOST change the reading without changing the surviving population.</figcaption></figure><figure><img src="images/tree.png" alt="Red block tree and existing viewing controls"><figcaption>The original block tree: FORM, STRATA, REACH and ENDS read the same generated branches.</figcaption></figure></div>
<p>All ten existing artifacts and the gallery fixture remain. The new required lesson stays with one operation. The reflective text asks what a retained difference makes available for judgment, then returns to the movement between drawing, code, body and revised words.</p><blockquote>The table cannot decide what that difference is worth. More surviving length might answer one wish and frustrate another.</blockquote>
<details><summary>See the room from above</summary><figure><img src="images/overview.png" alt="Elevated native view of the comparison table and both original desks"><figcaption>Standing clearance and supported bypasses on both sides of the table were checked in the live room.</figcaption></figure></details>
<h2>The next reader</h2><p>The next laboratory's Cantor preset rewrites F as FfF and f as fff. Its actual turtle output matches the thirds intervals after normalizing display scale, at depths zero through five. Quarters and two fifths are different recipes. Their results cannot be attributed to that same grammar.</p>
<p>Synthesis's old exit marker was blocked against the side wall. Moving it to the existing rear opening restores the intended passage; a native walker test completes arrival in LSystems_Grammar_Lab.</p>
<p class="note">Next-hall finding: the Grammar Lab's own onward exit also reports an obstruction. It is recorded for that hall's pass; this report verifies arrival there, not an uninterrupted route through the whole L-systems sequence.</p>
<h2>What was checked</h2><p>{reports['lesson-and-artifact']} checks execute the exact printed files and four-cut variation, copy/restore behaviour, all three fractions through five cuts, actual rendered bar dimensions, desktop-held and XRTools supplied poses, and the next lab's real grammar. {reports['museum']} checks cover the installed hall, nearby pointer buttons, hand interaction, floor and standing clearance, native captures and the passage into the next hall.</p><p>Both final runs exited successfully with no script errors. Existing UID, renderer and shutdown diagnostics remain in the archived logs. Headset feel, Quest performance and learning by an independent student remain untested.</p>
<p><a href="tests/lesson-and-artifact.json">Lesson assertions</a> · <a href="tests/museum.json">Museum assertions</a> · <a href="tests/extraction.json">Printed-code hashes</a> · <a href="evidence.json">Source evidence</a> · <a href="SUMMARY.md">Compact instruction</a></p>
<p>Previous: <a href="../2026-10-08-golden-two-values-two-views/index.html">Golden Spiral — two values, two views</a>. Next: L-systems — a sentence read as movement.</p></main>
<script>const captions={{thirds:'Both rows begin with thirds and three cuts. Each retains about 1.778 model metres.',quarters:'LIVE now keeps quarters: eight pieces, 0.750 metres. KEPT still holds the earlier thirds.',comparison:'KEEP copied quarters. LIVE now keeps two fifths: eight pieces, 3.072 metres. Both use the same scale.',restored:'RESTORE copies the kept quarter recipe back into LIVE. Later live edits remain independent.', 'five-cuts':'NEXT changes only LIVE to five cuts: 32 pieces, 0.1875 metres. KEPT remains at three cuts.'}};function show(button){{const name=button.dataset.shot;document.querySelectorAll('[data-shot]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));const img=document.getElementById('comparison');img.src='images/'+name+'.png';img.alt=captions[name];document.getElementById('comparison-caption').textContent=captions[name];}}</script>'''
(O/'index.html').write_text(page('Fractal Synthesis — a rule kept',body),encoding='utf-8')
with zipfile.ZipFile(O/'student-files.zip','w',zipfile.ZIP_DEFLATED) as z:
    for name in ['recipe.gd','point_body.gd']:z.write(S/name,name)
    z.write(H/'tutorial.md','tutorial.md')
    z.writestr('READ-ME.txt','Use the prepared Endless Museum workspace with installed XRTools. Save both scripts together; attach recipe.gd to an empty unit-scale Node3D on the workspace floor, front local +Z. Camera, lighting and player are supplied. Move the point to choose 1/4, 1/3 or 2/5. Held trigger or Enter keeps an independent recipe. Run again to reset. Museum furniture and nearby buttons are separate from the minimal reconstruction. This is not a standalone project.\n')
plan=json.loads(read(R/'doc/book/course/execution-plan/plan.json'));lesson=next(r for r in plan['lessons'] if r['id']=='Fractal_Synthesis')
old=json.loads(read(O/'before/lesson-plan.json'));assert lesson['decision']==old['decision'] and lesson['baseline']==old['baseline']
dump(O/'lesson-plan.json',lesson)
summary='# Synthesis — a rule kept\n\n'+lesson['summary']+'\n\nSynthesis | carry PointBody + intervals; seed6m; end-fraction1/4,1/3,2/5; depth3/cap5; live+kept dict copies; rebuild from seed; common scale0.34; trigger KEEP; release before NEXT/RESTORE/RESET; RESET live only; local snapshot/no disk; predict+execute depth4 thirds=16 pieces,32/27m; actual next F/f grammar matches thirds after normalization; other fractions differ; ten artifacts retained; exit moved(1,31)→(9,31), arrival GrammarLab tested; GrammarLab onward exit pending.\n'
(O/'SUMMARY.md').write_text(summary,encoding='utf-8')
paths=['commons/artifacts/fractal_recipe_table/'+n for n in ['recipe.gd','point_body.gd','museum_recipe_table.gd']]+['commons/artifacts/fractal_procedure_gallery/fractal_procedure_gallery.gd']+['commons/maps/Fractal_Synthesis/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]+['tools/probes/synthesis_recipe.gd','tools/probes/synthesis_recipe_museum.gd','commons/artifacts/lsystem_editor/lsystem_editor.gd']
old_map=json.loads(read(O/'before/map_data.json'));new_map=json.loads(read(H/'map_data.json'))
old_map['layers']['utilities'][31][1]='';old_map['layers']['utilities'][31][9]='t';assert old_map==new_map
dump(O/'image-sources.json',images)
dump(O/'evidence.json',{'checks':count,'reports':reports,'source_sha256':{p:sha(R/p) for p in paths},'student_extraction':json.loads(read(O/'tests/extraction.json')),'headset_verified':False,'map_edit':'Only exit marker utility cells (1,31) and (9,31); original artifacts and structure preserved.','before_capture':'New table hidden in current room; repaired exit remains. Not a historical screenshot.','onward_arrival':'LSystems_Grammar_Lab confirmed by native walker input.','next_hall_issue':'Grammar Lab own onward exit reports blocked approach; no edit to that hall.'})
links=0
for p in O.glob('*.html'):
    for target in re.findall(r'(?:href|src)="([^"]+)"',read(p)):
        if target.startswith(('http:','https:','mailto:','res:')):continue
        parts=urlsplit(html.unescape(target));dest=(p.parent/unquote(parts.path)).resolve() if parts.path else p
        assert dest.exists(),(p.name,target)
        if parts.fragment and dest.suffix=='.html':assert f'id="{unquote(parts.fragment)}"' in read(dest),(p.name,target)
        links+=1
dump(O/'publication-checks.json',{'html_references':links,'native_images':len(images),'checks':count,'map_change_verified':True,'tutorial_code_extraction_verified':True})
print('Published',count,'checks;',len(images),'native captures;',links,'HTML references validated.')
