from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-pressure-a-drive-and-a-room'
M=R/'commons/maps/SoftBodies_Obsticals'
S=R/'doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals'
RUN=R/'ada_run/encounter_pilot/SoftBodies_Obsticals/pressure-after'
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
code=json.loads((O/'checks.json').read_text(encoding='utf8'))
room=json.loads((RUN/'report.json').read_text(encoding='utf8'))
assert code['passed'] and room['passed']
assert any(c['name']=='All planned checks completed' and c['passed'] for c in room['checks'])
for path in [O/'engine.log',RUN/'engine.log']:
    log=path.read_text(encoding='utf8',errors='replace')
    assert not any(word in log for word in ['SCRIPT ERROR','Parse Error','without a physics space'])
baseline=json.loads((O/'before/hashes.json').read_text(encoding='utf8'))
protected=[p for p in baseline if p.startswith(('algorithms/','commons/artifacts/')) or p.endswith('softbodies.json')]
for p in protected:assert sha(R/p)==baseline[p],p
before=json.loads((O/f'before/commons/maps/{M.name}/map_data.json').read_text(encoding='utf8'))
expected=copy.deepcopy(before);expected['layers']['interactables'][5][11]=expected['layers']['interactables'][3][15];expected['layers']['interactables'][3][15]=''
assert json.loads((M/'map_data.json').read_text(encoding='utf8'))==expected
old=json.loads((O/'before/commons/data/museum/em_plan.json').read_text(encoding='utf8'))
current=json.loads((R/'commons/data/museum/em_plan.json').read_text(encoding='utf8'))
expected=copy.deepcopy(next(x for x in old['plans'] if x['map']==M.name))
a=next(x for x in expected['artifacts'] if x['token']=='soft_workshop_console');a['cell']=[11,5];a['tile_cell']=[11,5];a['ruled']['cell']=[11,5]
assert next(x for x in current['plans'] if x['map']==M.name)==expected
old_final=(O/f'before/commons/maps/{M.name}/final.md').read_text(encoding='utf8')
new_final=(M/'final.md').read_text(encoding='utf8')
assert old_final[old_final.index('<!-- @softbody_gallery_part2 -->'):]==new_final[new_final.index('<!-- @softbody_gallery_part2 -->'):]
for folder in ['assets','museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for name in ['above','entry','installed-walls','desk','student-cycle','student-held','student-half-amplitude','with-learner-above']:
    shutil.copyfile(RUN/(name+'.png'),O/'assets'/(name+'.png'))
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
    shutil.copyfile(M/name,O/'after'/name)
    if name.endswith('.md'):shutil.copyfile(M/name,O/name)
for folder in ['printed','variation']:shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
n,q=len(code['checks']),len(room['checks']);obs=room['observations']
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf8'));prior=copy.deepcopy(plan)
row=next(x for x in plan['lessons'] if x['id']==M.name);decision=row['decision']
row.update(
    object='Two matching closed panels and the inherited grabbable PointBody; a sine command drives their pressure.',
    change='Flatten the earlier closed box into a perimeter-pinned panel. Map phase to a nonnegative pressure coefficient; hold phase while the solver continues.',
    dependsOn=['SoftBodies_Soft_Body_Deformation','SoftBodies_Cloth_Physics','SoftBodies_Carusell','WaveFunctions_Sine_Space'],
    reuses='Closed BoxMesh, coordinate-based pin selection, two instances, rate times delta, sine range mapping, PointBody grip/action/release.',
    given='Existing Endless Museum player, camera, floor, XRTools and Jolt. Installed authored slabs remain the encounter; learner builds a smaller matching pair.',
    later='No motor, fluid, respiratory model or calibrated pressure. No freezing all vertices. Full-body wall collision and Quest comfort remain untested.',
    checks=[f'{n} exact printed-code checks, native Jolt: pinned boundary, signal samples, hold and reset preserving body state, independent amplitude edit, paired pressure comparison, three faulty programs, XRTools pickup.',f'{q} museum checks: actual six pointer controls, source/material audit, learner scene, supplied hand actions, clear approach and outer route.'],
    transfer='Change AMPLITUDE .5 to .25. Predict .125/.25/0 at phase 0/pi-over-two/three-pi-over-two. Period and geometry stay; clearance need not halve.',
    carry='The changing scalar is a command, not a surface position or clearance measurement. Holding or resetting phase leaves a responding body.',
    next='SoftBodies_Obsticals_Part2: rebuild a declared contact experiment, separate initial conditions from accumulated state.',
    notes='Draft tested. Corrected orphan-script account to shipped breathing_room_scene.gd and 19/16 authored pins with unequal stiffness/shrinking. No production artifact edits. Desk (15,3)->(11,5); learner temporarily at (22,0,27), yaw180, unit. No physical headset or independent student test.',
    summary='Meet the museum’s two authored pressure-driven slabs, then return to the earlier closed cube construction and make two small matching panels with pinned perimeters. Keep the black PointBody as contact probe and trigger switch. Map sine phase to a nonnegative pressure coefficient; separate amplitude and rate from the surface response. Hold the phase without freezing or replacing the bodies, then reset only the clock. Halve the amplitude, predict three pressure values and keep the period unchanged. Carry the difference between a command and the state it encounters into a repeatable contact experiment.')
assert row['decision']==decision
assert [x for x in plan['lessons'] if x['id']!=M.name]==[x for x in prior['lessons'] if x['id']!=M.name]
assert {k:v for k,v in plan.items() if k!='lessons'}=={k:v for k,v in prior.items() if k!='lessons'}
dump(p,plan);dump(O/'lesson-plan.json',row)
report=f'''# Pressure — a drive and a room

Soft Bodies, hall 4 of 9. Carusell moved a boundary. Here the boundary stays and a pressure command changes. The black PointBody returns unchanged; the closed box from the first hall becomes two small panels. The open sheet is not silently relabelled as an inflated volume.

|Part|Before|Now|
|---|---|---|
|Tutorial|A pressure-loop fragment with no complete host|Three full files: closed panel, pressure host, inherited point|
|Lineage|General reference to earlier sine spaces|Closed cube → pinned sheet → moving support → pressure-driven closed panels|
|New distinction|Pressure described alongside wall displacement|Command range, cycle rate and physical response remain separate|
|Transfer|No independent executable edit|Halve amplitude; predict three signal values and unchanged period|
|Reflection|Dimensions and perimeter pins from an unused generator; code interruption|The actual unequal authored slabs; bodily recognition and what a container permits|
|Room|Desk obstructs centre arrival|Same desk moved from (15,3) to (11,5)|

## What the source audit changed

The placed scene uses `breathing_room_scene.gd`, not its similarly named sibling `breathing_room.gd`. Its two meshes begin 1 × 4 × 7 metres, with 19 and 16 selected pinned indices. Their stiffness is .5 and .02; shrinking settings are −.2 and .02. The lesson flag adds the sine pressure driver to those existing bodies. The older text instead described the unused generator’s .5 × 4 × 10 walls and perimeter pins.

This matters pedagogically. Two unequal bodies receiving one command do not isolate a single material variable. The installed pair stays as the encounter; the learner creates a declared matching pair for a smaller experiment. Production scene and script hashes, controls and sequence order are unchanged. The contact-gallery portion of final.md is preserved verbatim.

## The learner’s object

Each .16 × 1.2 × 1.8 metre closed panel has {code['observations']['entries']} mesh entries, with {code['observations']['pins']} selected on its perimeter. The broad faces remain free. One phase supplies both pressure coefficients. The inherited ball can be picked up and used as a contact probe; its trigger holds/resumes the phase. It parks at the opening on release.

HOLD leaves the current command in place. RESET PHASE sets the clock to zero and applies half the current amplitude, without replacing the bodies or restoring their shapes. Changing amplitude while held changes pressure at that held phase. Those distinctions are explained alongside the complete code.

The independent edit changes AMPLITUDE .5 to .25. At phase 0, π/2 and 3π/2, the expected coefficients are .125, .25 and zero. The rate remains 1 rad/s. The tutorial asks the learner to distinguish this prediction from the observed space between the surfaces.

## Evidence

**{n} exact printed-code checks and {q} native museum checks passed.** The test extracts the three code blocks from tutorial.md and runs those files under native Godot 4.6 with Jolt. The whole amplitude-edited host also runs. Three faulty hosts—missing delta, ignoring HOLD, and omitting the sine offset—are rejected by behavioural checks.

Checks read actual vertex positions, retained mesh/body identity, world-space pin locations under a translated and rotated parent, pressure values and supplied XRTools pickup/actions/release. Free vertices moved {code['observations']['free_motion_while_held']:.4f} m while the isolated pressure command was held, and {obs['learner_motion_held']:.4f} m in the museum test. A paired run with matching construction, gravity and settings but different pressure produced a maximum relative position difference of {code['observations']['pressure_comparison_difference']:.4f} m. These are runtime observations, not calibrated material measurements or promised identical trajectories.

The real museum desk’s AMPLITUDE, RATE, HOLD DRIVE, STIFFNESS, RESET PHASE and RULE buttons were exercised through the desktop pointer. The authored wall settings were inspected at runtime. Native screenshots include the entry, walls, learner pair, held command, amplitude edit and hall from above.

## Space

The before run found the desk’s collision body and buttons in centre arrival. The relocated desk clears that path and remains reachable. All {obs['route']['samples']} quarter-metre route samples have capsule clearance and floor support along the outer crossing. This tests a route around the deforming specimens, not passage through them at every possible pressure.

The learner study is temporarily placed at hall-local (22,0,27), yaw 180 degrees, unit scale. Its initial test location was too close to the existing contact gallery. The final approach is clear and supported. No permanent extra exhibit was registered. Before and after images use the same .3 camera exposure; the simulations continue between photographs.

## Limits

The code and museum probes complete without script, parse or missing-physics-space errors. Existing project UID/renderer warnings remain in the logs. This is an author-led executable reconstruction, not an independent student assessment. Physical headset input, Quest performance and full-body contact with the large walls remain untested. Local HTML links, displayed-code parity and ZIP contents are checked; browser layout has not been automated.

Next: **SoftBodies_Obsticals_Part2 — same fall, another encounter**. The task becomes rebuilding declared starting conditions and observing what a changed contact makes possible.
'''
write(O/'REPORT.md',report)
css=re.search(r"css='''(.*?)'''",(R/'tools/publish_soft_yield.py').read_text(encoding='utf8'),re.S)[1]
def md(s,prefix=''):
    out=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    blocks=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
    out=re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2],out,flags=re.S)
    if prefix:out=re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m[1]+prefix+m[2],out)
    return out
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p>ENDLESS MUSEUM · SOFT BODIES 04 / 09 · 9 OCTOBER 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="pressure-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Actual Godot captures · author-led executable checks · physical headset and independent student review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
texts={k:(O/(k+'.md')).read_text(encoding='utf8') for k in ['tutorial','final']}
for k,s in texts.items():write(O/(k+'.html'),page(k,'<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html',page('Pressure — facing texts','<main class="spread"><article><p class="eyebrow">LEFT · TUTORIAL.MD</p>'+md(texts['tutorial'],'t-')+'</article><article><p class="eyebrow">RIGHT · FINAL.MD</p>'+md(texts['final'],'f-')+'</article></main>'))
changes='<main><h1>What changed.</h1>'
for k in texts:changes+='<h2>'+k+'.md</h2><div class="pair"><article><p class="eyebrow">BEFORE</p>'+md((O/f'before/commons/maps/{M.name}/{k}.md').read_text(encoding='utf8'),'before-'+k)+'</article><article><p class="eyebrow">AFTER</p>'+md(texts[k],'after-'+k)+'</article></div>'
write(O/'changes.html',page('Before and after',changes+'</main>'))
body='<main><h1>A drive<br>and a room.</h1><p class="lead">Hold the pressure command. Watch the body that still responds.</p><p class="note">Same grabbable black point. Closed panels. '+str(n)+' code checks + '+str(q)+' native museum checks passed.</p>'
body+='<div class="pair">'+fig('assets/student-cycle.png','The small learner pair: two matching closed panels receive one pressure command. The black PointBody returns unchanged.')+fig('assets/student-held.png','The held trigger pauses phase. Pressure remains; the same bodies continue responding.')+'</div>'
body+='<h2>One independent change</h2>'+fig('assets/student-half-amplitude.png','The complete half-amplitude version runs in the museum. Its period and geometry are unchanged.')
body+='<h2>The installed encounter</h2>'+fig('assets/installed-walls.png','The existing authored slabs: unequal stiffness, shrinking settings and pin selections. The tutorial names this difference.')
body+='<h2>Clear the arrival</h2><div class="pair">'+fig('before-museum/entry.png','Before: the workshop desk obstructed centre arrival.')+fig('assets/entry.png','After: the same desk stands to the side, with a clear supported approach.')+'</div>'
body+='<h2>The hall from above</h2><div class="pair">'+fig('before-museum/above.png','Before: pink walls, contact gallery and retained rear structure.')+fig('assets/with-learner-above.png','After: desk moved, learner pair temporarily added beyond the contact gallery. Other exhibits remain in place.')+'</div>'
body+='<section class="report">'+md(report)+'<p><a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="lesson-plan.json">Lesson summary</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></section></main>'
write(O/'index.html',page('Pressure — a drive and a room',body))
for name in ['pressure_lesson.gd','pressure_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_pressure_lesson.py','publish_pressure_lesson.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':json.loads((O/'printed-hashes.json').read_text()),'unchanged_sources':{p:sha(R/p) for p in protected},'inherited':['point_body.gd'],'checks':[n,q],'placement_delta':{'token':'soft_workshop_console','from':[15,3],'to':[11,5]},'route':obs['route'],'learner_placement':'temporary, not installed exhibit','headset':False})
write(O/'README.txt','Open index.html for actual museum images; parallel.html for tutorial left/reflection right. printed/ contains the complete three-file program. variation/ changes AMPLITUDE .5 to .25; fault folders intentionally violate invariants. Instantiate study.tscn inside the prepared Endless Museum project with player, camera, floor, XRTools and Jolt supplied. Hall 4 of 9. No physical headset or independent learner claim.\n')
archive=O/'pressure-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name!='validation.json':
            data=p.read_bytes()
            if p.suffix=='.html':data=data.replace(b'href="pressure-review.zip"',b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.ids=[]
    def handle_starttag(self,tag,attrs):
        self.links.extend(v for k,v in attrs if k in ['href','src'] and v)
        self.ids.extend(v for k,v in attrs if k=='id')
refs=0
for p in O.glob('*.html'):
    parser=Links();parser.feed(p.read_text(encoding='utf8'));assert len(parser.ids)==len(set(parser.ids))
    for link in parser.links:
        if link.startswith(('http:','https:','data:')):continue
        if link.startswith('#'):assert link[1:] in parser.ids;continue
        assert (p.parent/link.split('#')[0]).exists(),(p,link)
        refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf8'),re.S)]
assert len(rendered)==3
for name,s in zip(['pressure_panel.gd','study.gd','point_body.gd'],rendered):assert s==(O/'printed'/name).read_text(encoding='utf8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links();parser.feed(z.read(name).decode('utf8'))
            for link in parser.links:
                if not link.startswith(('http:','https:','#','data:')):assert link.split('#')[0] in members
result={'passed':True,'checks':[n,q],'local_refs':refs,'rendered_code_parity':3,'zip_crc':True,'zip_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2),'browser_layout_checked':False}
dump(O/'validation.json',result);print(json.dumps(result))
