from pathlib import Path
from html.parser import HTMLParser
import copy, hashlib, html, json, re, shutil, zipfile
import markdown

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-soft-a-point-that-stays'
M=R/'commons/maps/SoftBodies_Soft_Body_Deformation'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Soft_Body_Deformation'
RUN=R/'ada_run/encounter_pilot/SoftBodies_Soft_Body_Deformation/yield'
FILES=['yielding_cube.gd','study.gd','point_body.gd']
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text());room=json.loads((RUN/'report.json').read_text())
assert code['passed'] and room['passed']
assert not room['observations']['route']['blocked'] and not room['observations']['route']['gaps']
for log in [O/'engine.log',RUN/'engine.log']:
    text=log.read_text(encoding='utf8',errors='replace')
    assert not any(s in text for s in ['SCRIPT ERROR','Parse Error','without a physics space'])
n,q=len(code['checks']),len(room['checks']);obs=room['observations']
baseline=json.loads((O/'before/hashes.json').read_text())
protected=[p for p in baseline if p.startswith(('commons/artifacts/','algorithms/')) or p.endswith('softbodies.json')]
for p in protected:assert sha(R/p)==baseline[p],p
# Exactly one placement changes. All runtime plan neighbours remain intact.
before_map=json.loads((O/'before/commons/maps/SoftBodies_Soft_Body_Deformation/map_data.json').read_text())
expected=copy.deepcopy(before_map);expected['layers']['interactables'][5][11]=expected['layers']['interactables'][3][15];expected['layers']['interactables'][3][15]=''
assert json.loads((M/'map_data.json').read_text())==expected
old=json.loads((O/'before/commons/data/museum/em_plan.json').read_text())
now=json.loads((R/'commons/data/museum/em_plan.json').read_text())
oldrow=next(x for x in old['plans'] if x['map']==M.name)
expected=copy.deepcopy(oldrow);desk=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console')
desk['cell']=[11,5];desk['tile_cell']=[11,5];desk['ruled']['cell']=[11,5]
current=copy.deepcopy(next(x for x in now['plans'] if x['map']==M.name))
# Runtime plan refreshes can reorder records without changing placements.
current['artifacts'].sort(key=lambda x:x['token']);expected['artifacts'].sort(key=lambda x:x['token'])
assert current==expected
for name in ['assets','museum','after','probes']:(O/name).mkdir(exist_ok=True)
images=['before-above','existing-cube','existing-mill','desk-controls','student-rest','student-press','after-above','student-fewer-vertices','entry-approach']
for name in images:shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/'after'/name)
    if name.endswith('.md'):shutil.copyfile(M/name,O/name)
shutil.copyfile(S/'study.tscn',O/'printed/study.tscn')
shutil.copyfile(S/'study.tscn',O/'variation/study.tscn')

p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
    object='The familiar cube becomes a pinned soft mesh; the unchanged black PointBody presses its surface.',
    change='Create the mesh before the body enters the world, select a crown vertex by its reference position, pin it, then compare stiffness, damping and pressure independently.',
    dependsOn=['Primitives_Polythedra','Vectors_Act4b_Oscillation','PG_Mirrored_Patterns'],
    reuses='BoxMesh, stored positions, loops and selection, whole-object transforms, contact, unchanged Mirrored Patterns PointBody and XRTools action/release.',
    given='Prepared Endless Museum, camera/player/floor/XRTools and Jolt solver. Complete cube and host printed; inherited point file included unchanged.',
    later='No solver implementation, material calibration or mill reconstruction. One vertex selection is sufficient here; boundary sets arrive in Cloth Physics.',
    checks=[f'{n} exact printed-code checks: native Jolt deformation, invariant pin, transformed host, independent controls, reset state, XRTools, subdivision edit, disabled-contact and released-pin controls.',f'{q} native museum checks: six pointer controls, learner contact/action/release, complete edit, clear supported approach and 273-sample route. Nine new captures plus two preserved before images.'],
    transfer='Change DIVISIONS from 4 to 2, restart, predict 216 to 96 mesh entries and a valid top-face attachment. Distinguish surface resolution from softness.',
    carry='A reference mesh, explicit attachment and response settings. Restoring coefficients is distinct from restoring dynamic state.',
    next='SoftBodies_Cloth_Physics: reuse the setup with a sheet and compare a pinned edge with two pinned corners.',
    notes='First Soft Bodies tutorial complete as a draft. Mesh must exist before entering the tree (_init). Exact code and native controls passed. Desk moved aside to restore authored entry. Mill visibly stretches into spikes and remains an open stability review, not the tutorial object. No headset, Quest or independent student claim.',
    summary='Begin with the museum’s hanging green cube and carry the black point forward as a contact probe. Build a subdivided BoxMesh inside SoftBody3D before adding it to the world, keep the reference coordinates and select one top-face vertex to pin. Press the surface and change stiffness, damping or pressure separately while the pin remains fixed. Restore settings without mistaking this for a rewind of the running body. Reduce subdivisions and predict fewer vertices with the same selection rule. Carry the distinction between mesh, attachment and response into Cloth Physics.')
assert row['decision']==decision
assert [x for x in plan['lessons'] if x['id']!=M.name]==[x for x in prior['lessons'] if x['id']!=M.name]
assert {k:v for k,v in plan.items() if k!='lessons'}=={k:v for k,v in prior.items() if k!='lessons'}
dump(p,plan);dump(O/'lesson-plan.json',row)

report=f'''# One point stays

Soft Bodies, hall 1 of 9. The cube continues from the earlier chapters; the carried black point becomes a probe. One attachment stays fixed while the surface responds around it. This makes a clear new step after generating forms: the student now supplies conditions under which a form keeps changing.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter prose and three coefficient assignments|A complete cube class, host and unchanged PointBody, with setup, contact and one student edit|
|Selection|An attachment described without a learner implementation|Top-face search returns an index into retained reference positions|
|Reflection|Softness, constraints and the mill, with code and an outdated engine note|A separate reflective reading, no code blocks; current Jolt and hand assumptions stated|
|Entrance|Desk on the authored arrival point|Same desk moved four metres sideways and two metres into the hall, from cell (15,3) to (11,5)|

**{n} exact-code checks and {q} native museum checks pass.** The tested program is extracted from the visible tutorial code. It constructs its own geometry and label; it inherits the prepared museum and XRTools. The pin is checked under a translated, rotated parent. Removing it makes the formerly fixed point fall. Contact with the carried sphere is compared with an otherwise equivalent host whose point-contact mask is disabled.

The first implementation put the soft mesh in `_ready()`. In this setup that was too late: the body entered the world without a mesh and failed to start a Jolt simulation. Moving construction into `_init()` fixed the failure. This order now appears in the explanation. Merely compiling the code would not have caught the missing behaviour.

The student changes one constant, DIVISIONS, from 4 to 2. The full host still runs; mesh entries fall from 216 to 96 and the selected upper point remains pinned. These counts include the mesh’s face entries, not a count of distinct spatial positions. A visibly coarser surface is not automatically a softer material.

The same body survives RESET. Its coefficients return; its positions do not rewind. This is the lesson’s bridge from Procedural Generation’s retained inputs into a simulation with ongoing state.

## The actual room

The original hanging cube remains the primary encounter. The learner reconstruction was placed temporarily beside it at hall-local (11.5,0,8.5), yaw 180 degrees, for the native checks and pictures. **It is not a newly installed main-route artifact.** The study is ready to place there from the printed files. The installed cube and other artifact algorithms are unchanged.

The entrance collision was traced to the workshop desk’s buttons and body. Moving that one placement restores the authored arrival without the blocked-entry fallback. All {obs['route']['samples']} samples along the centre entrance and right-side route have capsule clearance and floor support. This tests the local route; it does not certify a complete streamed portal crossing or headset comfort.

From above, the room has ample separation but a long empty stretch before the retained rear structure. The small encounters could eventually form a more compact court. That wider arrangement is a design finding, not a completed redesign.

The mill’s soft surface visibly stretches into long spikes in the native capture. Its drive control works, but that does not establish stable soft-body behaviour. It remains a comparison with an explicit open issue, rather than a second code task. The learner cube is the bounded, tested object for this hall.

## Evidence and limits

The six installed desk controls were activated with the supplied desktop pointer. The learner point was carried, pressed into the cube, activated and released through supplied XRTools poses. Code tests separately isolate point contact from an equivalent disabled-contact control. Native photos include both mesh resolutions, the existing artifacts and the hall from above.

The captures use the compatibility renderer and camera exposure 0.45. Lighting and running bodies are not frozen for the before/after room photographs, so those images establish placement, not a controlled material comparison. Existing project warnings remain in the logs, including an unrelated missing UID and renderer feature warnings. No script/parse errors or missing-physics-space errors occur in the passing runs.

These are author-led executable checks. Physical headset use, Quest performance and an independent ghost student’s understanding have not been tested. Browser layout was not automated in this pass.

Next: Cloth Physics. The object becomes a sheet, and the new decision is which boundary positions must stay.
'''
write(O/'REPORT.md',report)
css='''*{box-sizing:border-box}body{margin:0;background:#f3f0e9;color:#242723;font:18px/1.65 Georgia,serif}header,footer,main{padding:32px clamp(20px,5vw,84px)}header{border-bottom:1px solid #c5c9bc}header p,.eyebrow,nav,figcaption,footer{font:13px/1.6 system-ui,sans-serif}nav{display:flex;gap:20px;flex-wrap:wrap}a{color:#335745}h1{font-size:clamp(36px,5vw,76px);line-height:1.08;font-weight:normal}h2{font-size:29px;line-height:1.2;margin-top:2em}h3{font-size:23px}article{max-width:850px;margin:auto}main>p{max-width:900px}.lead{font-size:25px;max-width:780px}.pair,.spread{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:36px}.spread article{max-width:none;min-width:0}.spread article+article{border-left:1px solid #ccc;padding-left:32px}figure{margin:24px 0}img{width:100%;height:auto;border:1px solid #d2d5c9}figcaption{padding:10px 0;max-width:900px}pre{font:13px/1.6 Consolas,monospace;background:#172721;color:#e6eee4;padding:22px;overflow:auto;tab-size:4;border-radius:4px}code{font-family:Consolas,monospace}table{border-collapse:collapse;width:100%;font-size:16px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #ccc;padding:12px}summary{cursor:pointer}details{border-top:1px solid #ccc;padding:16px 0}.report{max-width:1050px;margin:64px auto}.note{border-left:3px solid #638068;padding:12px 24px;background:#e8eee2}@media(max-width:1000px){.pair,.spread{display:block}.spread article+article{border:0;padding:0;margin-top:70px}}@media print{nav,footer{display:none}body{font-size:11pt;background:white}pre{white-space:pre-wrap;background:#eee;color:#111}main{padding:0}h1{font-size:32pt}img{max-height:70vh;object-fit:contain}}'''
def md(s,prefix=''):
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
    return out
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p>ENDLESS MUSEUM · SOFT BODIES 01 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="soft-body-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Actual Godot captures · executable author checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('One point stays — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md((O/'before/commons/maps/SoftBodies_Soft_Body_Deformation'/(k+'.md')).read_text(encoding='utf8'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>One point<br>stays.</h1><p class="lead">The cube yields. The carried point presses. One attachment remains.</p><p class="note">First hall of Soft Bodies. Full tutorial left, reflection right. '+str(n)+' exact-code checks + '+str(q)+' native museum checks passed.</p>'
body+='<div class="pair">'+fig('assets/student-rest.png','Temporary learner reconstruction in the actual hall. The unchanged black PointBody sits beside a pinned green soft cube.')+fig('assets/student-press.png','Supplied XRTools hand carries the point into the surface. The gold attachment stays fixed. This is a native engine view, not an illustration.')+'</div>'
body+='<h2>Keep the setup; change the mesh</h2>'+fig('assets/student-fewer-vertices.png','The full student edit: subdivisions reduced from 4 to 2. Ninety-six reference entries replace 216; the attachment rule still works. This image does not establish a softer material.')
body+='<h2>The encounters already here</h2><div class="pair">'+fig('assets/existing-cube.png','Installed jelly cube: the brass support makes the pinned upper point legible. This artifact’s physics code is unchanged.')+fig('assets/existing-mill.png','The existing mill. The long stretched surface is an open stability issue. A working drive button does not certify stable simulation.')+'</div>'
body+='<h2>Clear the arrival</h2><div class="pair">'+fig('before-museum/entry-approach.png','Before: the workshop desk obstructed the authored arrival. Collision queries identified its buttons and body.')+fig('assets/entry-approach.png','After: the same desk sits four metres to the side and two metres forward. The centre entrance and measured right-side route are clear and supported.')+'</div>'
body+='<h2>The hall from above</h2><div class="pair">'+fig('before-museum/before-above.png','Before: the desk is centred at the entrance; the rest of the court is widely spaced.')+fig('assets/after-above.png','After: desk moved aside and learner reconstruction temporarily mounted beside the original cube. The rear structure and other placements remain.')+'</div>'
body+='<section class="report">'+md(report)+'<p><a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></section></main>'
write(O/'index.html',page('Soft Bodies — one point stays',body))
for name in ['soft_yield_lesson.gd','soft_yield_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_soft_yield.py','publish_soft_yield.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged_sources':{p:sha(R/p) for p in protected},'placement_delta':{'token':'soft_workshop_console','from':[15,3],'to':[11,5]},'checks':[n,q],'route':obs['route'],'mill_stability':'open','learner_placement':'temporary reconstruction in actual hall, not installed on main route','headset':False})
write(O/'README.txt','Open index.html for native museum images; parallel.html for tutorial left/reflection right. printed/ contains the exact three-file lesson; variation/ changes only DIVISIONS from 4 to 2. Place study.gd on a Node3D in the prepared Endless Museum; camera, floor, XRTools and Jolt are supplied. This is hall 1 of 9, not the complete Soft Bodies sequence. Desk placement repaired; existing mill stability remains open. No physical headset or independent student claim.\n')
archive=O/'soft-body-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid','.cpp'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="soft-body-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.ids=[]
    def handle_starttag(self,tag,attrs):
        self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
        self.ids.extend(v for k,v in attrs if k=='id')
count=0
for p in O.glob('*.html'):
    parser=Links();parser.feed(p.read_text(encoding='utf8'));assert len(parser.ids)==len(set(parser.ids))
    for link in parser.links:
        if link.startswith(('http:','https:','data:')):continue
        if link.startswith('#'):assert link[1:] in parser.ids;continue
        assert (p.parent/link.split('#')[0]).exists(),(p,link)
        count+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf8'),re.S)]
assert len(rendered)==3
for name,s in zip(FILES,rendered):assert s==(O/'printed'/name).read_text(encoding='utf8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
dump(O/'validation.json',{'passed':True,'local_refs':count,'rendered_code_parity':3,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(json.dumps({'report':str(O/'index.html'),'checks':[n,q],'local_refs':count,'zip_MB':round(archive.stat().st_size/1e6,2)}))
