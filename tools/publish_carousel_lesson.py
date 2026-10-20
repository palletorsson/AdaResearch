from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-carousel-the-support-moves'
M=R/'commons/maps/SoftBodies_Carusell'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Carusell'
RUN=R/'ada_run/encounter_pilot/SoftBodies_Carusell/driven-boundary'
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text(encoding='utf8'));room=json.loads((RUN/'report.json').read_text(encoding='utf8'))
assert code['passed'] and room['passed']
assert any(c['name']=='All planned museum and learner checks completed' and c['passed'] for c in room['checks'])
code_log=(O/'engine.log').read_text(encoding='utf8',errors='replace')
room_log=(RUN/'engine.log').read_text(encoding='utf8',errors='replace')
assert not any(s in code_log for s in ['SCRIPT ERROR','Parse Error','without a physics space'])
assert not any(s in room_log for s in ['SCRIPT ERROR','Parse Error'])
# Keep the exact pre-existing curtain initialization limitation visible; reject
# any other missing-space error, or one raised during the learner checks.
def space_errors(text):
    return [re.sub(r'#\d+', '#INSTANCE',line) for line in text.splitlines() if 'without a physics space' in line]
baseline_log=(O/'before-museum/engine.log').read_text(encoding='utf8',errors='replace')
known_space_errors=space_errors(room_log)
assert known_space_errors==space_errors(baseline_log)
assert len(known_space_errors)==2 and all("'SoftBodyStrip:<SoftBody3D#INSTANCE>'" in line for line in known_space_errors)
assert not space_errors(room_log.split('[transformation] PASS requested museum hall loaded',1)[-1])
n,q=len(code['checks']),len(room['checks']);obs=room['observations']
baseline=json.loads((O/'before/hashes.json').read_text(encoding='utf8'))
protected=[p for p in baseline if p.startswith(('algorithms/','commons/artifacts/')) or p.endswith('softbodies.json')]
for p in protected:assert sha(R/p)==baseline[p],p
before=json.loads((O/f'before/commons/maps/{M.name}/map_data.json').read_text(encoding='utf8'))
expected=copy.deepcopy(before);expected['layers']['interactables'][5][11]=expected['layers']['interactables'][3][15];expected['layers']['interactables'][3][15]=''
assert json.loads((M/'map_data.json').read_text(encoding='utf8'))==expected
old=json.loads((O/'before/commons/data/museum/em_plan.json').read_text(encoding='utf8'));now=json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf8'))
expected=copy.deepcopy(next(x for x in old['plans'] if x['map']==M.name));a=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console')
a['cell']=[11,5];a['tile_cell']=[11,5];a['ruled']['cell']=[11,5]
current=copy.deepcopy(next(x for x in now['plans'] if x['map']==M.name))
for row in [expected,current]:row['artifacts'].sort(key=lambda x:x['token'])
assert current==expected
for name in ['assets','museum','after','probes']:(O/name).mkdir(exist_ok=True)
images=['above','entry','installed-ride','fixed-curtain','desk','student-turning','student-stopped','student-faster','with-learner-above']
for name in images:shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/'after'/name)
    if name.endswith('.md'):shutil.copyfile(M/name,O/name)
for name in ['printed','variation']:shutil.copyfile(S/'study.tscn',O/name/'study.tscn')

p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
    object='The inherited two-corner sheet follows a driven support; the same grabbable PointBody pauses or resumes its rate.',
    change='Advance a support angle by rate times delta and give its two transformed world-space targets to the pinned vertices. Leave free entries to Jolt.',
    dependsOn=['Trans_Rotation','SoftBodies_Cloth_Physics'],
    reuses='Unchanged hanging_sheet and PointBody classes; two-corner selection, coordinates, arrays, loops, rotation, physics time and XRTools action/release.',
    given='Prepared Endless Museum, player/camera/floor/XRTools/Jolt. Existing ride, chains and pin joints provide the encounter; the learner isolates a driven boundary on their sheet.',
    later='Motor reaction torque, ride reconstruction and joint tuning are outside this lesson. Pressure driving arrives in the next hall.',
    checks=[f'{n} exact printed-code checks: real target/free-vertex motion, transformed parent, timed angle, STOP state retention, full RATE edit, three faulty hosts and supplied XRTools.',f'{q} native museum checks: six pointer controls, installed hub/joints, temporary learner scene, grabbable ball, retained motion after STOP, full edit, clear approaches and sampled route.'],
    transfer='Edit RATE .4 to .8; predict twice the commanded angle over equal time, without assuming free-vertex displacement doubles.',
    carry='A prescribed drive changes a boundary while the simulated response carries existing state. STOP and REBUILD have different effects.',
    next='SoftBodies_Obsticals: reuse drive versus response while changing pressure on enclosing surfaces.',
    notes='Hall 3 draft tested. Learner files in soft-bodies-through-the-hands/SoftBodies_Carusell. Pin joints corrected from hinges in reflection. No production artifact code changed. Desk moved (15,3)->(11,5) to clear arrival. Native capture exposure .18. Physical headset/Quest and independent student remain open.',
    summary='Watch the museum ride turn its linked soft bodies, then continue with the two-corner sheet and black PointBody from Cloth Physics. Write a support angle as rate times elapsed time and convert the two corner offsets into world targets. Let the solver move the remaining vertices. Hold the ball and use its trigger to stop or resume the drive; distinguish the stationary support from the motion that continues in the sheet. Reverse the rate without resetting phase. Double the base rate and predict the commanded angle over equal time, not twice the deformation. Carry the distinction between drive and response into the pressure-driven room.')
assert row['decision']==decision
assert [x for x in plan['lessons'] if x['id']!=M.name]==[x for x in prior['lessons'] if x['id']!=M.name]
assert {k:v for k,v in plan.items() if k!='lessons'}=={k:v for k,v in prior.items() if k!='lessons'}
dump(p,plan);dump(O/'lesson-plan.json',row)

report=f'''# The support moves

Soft Bodies, hall 3 of 9. Cloth Physics selected a boundary. Carusell now moves it. The same sheet and black PointBody carry the lesson, so the new code concerns a changing attachment rather than another geometry construction.

|Part|Before|Now|
|---|---|---|
|Tutorial|Encounter and proposed focus|Complete runnable host; inherited sheet and point included unchanged|
|New operation|Rate and stopping described|Angle = rate × time; two pinned targets transformed into world space|
|Interaction|Installed desk|The same grabbable ball additionally pauses/resumes the learner drive with its held trigger|
|Transfer|Unspecified|RATE .4 → .8; predict double the commanded angle over equal time|
|Reflection|Pin joints called hinges; rate units explained|Correct point-joint description; attention stays with command, response and what stopping leaves behind|
|Arrival|Desk in the entry path|Same desk at (11,5), clear of centre arrival|

**{n} exact printed-code checks and {q} native museum checks passed.** The code extracted from the tutorial runs under Jolt. It preserves geometry, reference coordinates and body identity across STOP. Under a translated, rotated parent, the two pins reach the commanded world positions. After stopping the support, free vertices continue moving. A full edited host verifies the RATE change. Three faulty whole programs are rejected: omitting delta, ignoring target updates, and rebuilding when STOP is requested.

The unchanged PointBody is actually pickable through the supplied XRTools path. Tests hold it, trigger stop/resume and release it back to its parking place. These are supplied controller poses and actions, not a physical headset test. The photographed learner ball belongs to the runnable study; the study was mounted temporarily for the review and is not another permanently installed artifact.

## What continues from Cloth Physics

The full sheet and PointBody files are byte-identical to the preceding lesson. The new host starts with the already learned two-corner selection. A visual bar turns at a prescribed rate, and PhysicsServer3D receives only those two world-space targets. A stopped support continues supplying its same targets. The sheet's free entries retain their ongoing state.

This is a reduction of the installed ride's driving principle. The original ride uses a kinematically frozen rigid hub, eight PinJoint3D connections and four soft bodies attached to lower rigid links. The learner uses their existing sheet to isolate the drive. The tutorial declares this difference and does not pretend to rebuild the chains or simulate a motor receiving reaction torque.

The sheet's independent motion after STOP measured {code['observations']['free_motion_after_stop']:.3f} m in the isolated code check and {obs['learner_motion_after_stop']:.3f} m in the native museum run. These are evidence that the body was not frozen or replaced, not a material calibration or a promise of identical trajectories across runs.

The rate edit changes the command. It does not license a claim that every physical displacement will double. This is the useful step in the lineage: the learner now supplies a changing condition while leaving the response to an ongoing simulation.

## Room and images

The existing ride, fixed-support curtain and wider collection remain. All six workshop controls were exercised through the actual desktop pointer. The hub stopped advancing after STOP, while its rigid links remained dynamic. Installed artifact scripts and the sequence order are hash-checked unchanged.

The entry capsule intersected the desk's buttons and body. Moving that one placement from (15,3) to (11,5) clears the centre arrival. All {obs['route']['samples']} samples along the entry and left-side route have capsule clearance and floor support. The first straight right-side route intersected the existing mushroom field; its failed receipt is retained. A direct left-wall line met the projecting columns, so the checked route runs inside those columns before joining the outer aisle around the older enclosed structure. Failed route receipts are retained. This is a sampled local route, not a complete streamed passage or headset comfort test.

The learner scene was temporarily mounted at hall-local (9.5,0,8.5), yaw 180 degrees, unit scale. Its approach is clear and supported. The report includes the running sheet, its stopped support, the complete faster-rate edit, installed encounters and an overhead view of the hall. The floor's older enclosed structure and the long side circulation remain visible. The larger ride's instability and incidental trajectories are not resolved by checking that its buttons work; this pass validates a bounded learner object.

The final captures use camera exposure .18 to make the unusually bright hall more legible; the preserved before images used .45. Room lighting and physics continued between shots. Before/after images establish placement, not an identical lighting or material comparison.

## Verification limits

The first room probe itself called a soft-body-only method on a rigid link and stopped early. That log is preserved; it is not a passing receipt. The corrected probe now has an explicit completion check, and publication rejects script errors as well as failed checks. The final run completes every planned operation.

Printed code, inherited-file parity, the transfer edit, faulty controls, source hashes, full logs and before/after texts are included. No production ride algorithm was rewritten. The installed curtain emits two startup errors about transforming SoftBodyStrip before a Jolt physics space exists; the same two occur in the unchanged baseline. They remain unresolved here. Publication checks their exact normalized messages and rejects missing-space errors during the lesson. The isolated printed-code run has no script, parse or missing-space errors. The museum run has no script or parse errors; its passing checks are not a claim of an error-free hall. Existing UID/renderer warnings also remain. Browser layout was not automated; local links, displayed code parity and ZIP contents are checked.

Next: **SoftBodies_Obsticals — the room has a body**. The next drive changes pressure while the enclosing surface responds.
'''
write(O/'REPORT.md',report)
css=re.search(r"css='''(.*?)'''",(R/'tools/publish_soft_yield.py').read_text(encoding='utf8'),re.S)[1]
def md(s,prefix=''):
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes']);blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
    return out
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p>ENDLESS MUSEUM · SOFT BODIES 03 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="carousel-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Actual Godot captures · author-led executable checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('The support moves — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md((O/f'before/commons/maps/{M.name}/{k}.md').read_text(encoding='utf8'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>The support<br>moves.</h1><p class="lead">Keep the sheet and its two attachments. Turn the support. Stop it, and watch what continues.</p><p class="note">The same grabbable black point returns. '+str(n)+' exact-code checks + '+str(q)+' native museum checks passed.</p>'
body+='<div class="pair">'+fig('assets/student-turning.png','The carried sheet follows its two gold attachment targets. The unchanged black ball can be gripped.')+fig('assets/student-stopped.png','Held trigger stops the drive. The same sheet retains its motion; STOP does not rebuild it.')+'</div>'
body+='<h2>Change the command</h2>'+fig('assets/student-faster.png','Complete RATE edit, .4 to .8 rad/s. The commanded angle doubles over equal time. Physical displacement need not double.')
body+='<h2>Return to the existing ride</h2><div class="pair">'+fig('assets/installed-ride.png','The museum ride: driven ring, rigid links, pin joints and soft hanging bodies. The learner isolates one operation from this apparatus.')+fig('assets/fixed-curtain.png','The nearby fixed-support strips remain a comparison. They keep their existing implementation.')+'</div>'
body+='<h2>The entrance</h2><div class="pair">'+fig('before-museum/entry.png','Before: the desk occupies centre arrival.')+fig('assets/entry.png','After: the same desk moved four metres sideways and two metres into the hall. Its controls remain reachable.')+'</div>'
body+='<h2>The hall from above</h2><div class="pair">'+fig('before-museum/above.png','Before: the ride and older rear structure occupy distinct parts of the hall.')+fig('assets/with-learner-above.png','After: clear centre arrival and temporary learner sheet beside the front encounters. All other placements are preserved.')+'</div>'
body+='<section class="report">'+md(report)+'<p><a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></section></main>'
write(O/'index.html',page('Carusell — the support moves',body))
for name in ['carousel_lesson.gd','carousel_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_carousel_lesson.py','publish_carousel_lesson.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged_sources':{p:sha(R/p) for p in protected},'inherited':['hanging_sheet.gd','point_body.gd'],'checks':[n,q],'placement_delta':{'token':'soft_workshop_console','from':[15,3],'to':[11,5]},'route':obs['route'],'learner_placement':'temporary, not installed exhibit','headset':False})
write(O/'README.txt','Open index.html for native museum photographs; parallel.html for tutorial left/reflection right. printed/ contains the complete three-file lesson; variation/ changes RATE .4 to .8. The three fault folders deliberately violate behavioural checks. Instantiate study.tscn inside the prepared Endless Museum project; player, camera, floor, XRTools and Jolt are supplied. The same grabbable PointBody and sheet are inherited unchanged from Cloth Physics. Hall 3 of 9. No headset, Quest or independent student test.\n')
archive=O/'carousel-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="carousel-review.zip"',b'href="README.txt"')
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
for name,s in zip(['study.gd','hanging_sheet.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
dump(O/'validation.json',{'passed':True,'local_refs':count,'rendered_code_parity':3,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False})
print(json.dumps({'report':str(O/'index.html'),'checks':[n,q],'local_refs':count,'zip_MB':round(archive.stat().st_size/1e6,2)}))
