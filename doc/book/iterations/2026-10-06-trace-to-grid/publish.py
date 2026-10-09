"""Publish only this tested continuation; retain earlier evidence verbatim."""
from pathlib import Path
from html import escape
import json
import re
import shutil
import urllib.request
import zipfile
from prepare import HERE, ROOT, CANONICAL, sha, save, write

GHOST = ROOT.parent/'ada_encyclopedia/ghost-student'
REL = HERE.relative_to(ROOT).as_posix()
BASE = 'http://localhost:3003'

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def api(path, body=None):
    headers = {'Origin':BASE, 'Content-Type':'application/json'}
    request = urllib.request.Request(BASE+path, data=None if body is None else json.dumps(body).encode(), headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)

def main():
    report = read(HERE/'report-runtime.json')
    assert report['passed'] and len(report['checks']) == 71
    for path, expected in {**report['inputs'], **report['dependencies'], **read(HERE/'before/protected.json')}.items():
        assert sha(ROOT/path) == expected, path
    tutorial = CANONICAL.read_text(encoding='utf-8')
    subjects = re.findall(r'^- (.+)$', tutorial.split('##',1)[0], re.M)
    focus = 'Work inside the Endless Museum Grid hall, beside its existing glass field. Continue the tested PointBody recorder in a unit-scale PointStudy. Derive integer XYZ addresses and green snapped positions from its local source array; keep pink source values and order. Compare 0.25 m and 0.50 m pitches on one retained gesture. No display fitting or cross-hall transport.'
    carry = 'The unchanged PointBody class, local source positions, ordered Vector3i addresses and separate snapped Vector3 positions; all live in this station. The pitch may change without erasing the original record.'
    short = 'BRING tested Trace + unchanged PointBody/LineSkin. KEEP local positions/order. DERIVE Vector3i(roundi(p/step)) then Vector3(address)*step; independent arrays. COMPARE .25/.50 m on same record: pink source, green result. EXPLAIN index != address, ties, repeats. TEST source/frame/XR action/pitch/flat-Y. CARRY records; no scene transport.'
    brief = {
        'bring':'The exact verified Trace program and unchanged PointBody/LineSkin files.',
        'make':'A retained gesture with its original pink trace and a green grid interpretation.',
        'given':'Prepared room, view, player and XRTools. Existing pickup action and ui_accept supply the pitch control; their full lessons come later. The two small carried helpers are printed in full.',
        'build':focus,
        'check':'Predict a sample address. Compare two pitches without moving the point; original values/order stay. Check negatives, ties, repeated addresses, local frames and a flat-Y variant. Native code checks pass; learner prediction remains untested.',
        'later':'Triangle can choose three positions and close their boundary. Cross-hall saving, production display fitting and broader input architecture remain separate work.'}
    manifest = read(GHOST/'manifest.json')
    entries = {entry['id']:entry for entry in manifest['files']}
    def register(id, path, label=None):
        entries[id] = {'id':id,'path':path.relative_to(GHOST).as_posix(),'label':label or path.name,'language':{'.gd':'gdscript','.md':'markdown','.json':'json','.py':'python'}.get(path.suffix,'text'),'sha256':sha(path)}
        return id
    evidence = GHOST/'evidence'/HERE.name/'museum-context'
    ids = {}
    names = ['prepare.py','run_checks.py','verify.gd','grid.gd','point_body.gd','line_skin.gd','incoming.gd','assembled.gd','expected.gd','tutorial.md','operations.json','next-input.json','exercise-variants.json','variants/flat_y.gd','contract.json','report-runtime.json']
    for name in names:
        destination = evidence/name
        destination.parent.mkdir(parents=True,exist_ok=True)
        if destination.exists():
            assert destination.read_bytes() == (HERE/name).read_bytes(), 'Published evidence is immutable: '+name
        else:
            shutil.copyfile(HERE/name,destination)
        key = Path(name).with_suffix('').as_posix().replace('/','-').replace('_','-')
        ids[key] = register('grid-museum-'+key,destination,'evidence/'+name)
    state_dir = GHOST/'states/005-point-grid'
    state_dir.mkdir(parents=True,exist_ok=True)
    current = []
    for name,tail in [('grid.gd','code'),('point_body.gd','body'),('line_skin.gd','skin')]:
        shutil.copyfile(HERE/name,state_dir/name)
        current.append(register('point-grid-'+tail,state_dir/name))
    shutil.copyfile(HERE/'tutorial.md',state_dir/'tutorial.md')
    state = {'id':'point-grid','map':'Point_Line_Grid','title':'One trace, two grid spacings','status':'verified','predecessor':'point-trace','brief':brief,'subjects':subjects,
        'provenance':'Exact printed Trace output plus declared edits. PointBody and LineSkin stay byte-identical. Native Godot executes the printed three files and the flat-Y exercise; real XRTools receives synthetic controller input. The learner program continues one station, not the production museum session store.',
        'carry':carry,'nextStatus':'Triangle is next. Its current tutorial has not yet been assembled and verified against this Grid output.',
        'code':current[0],'incomingSha256':report['incoming_sha256'],'outgoingSha256':report['learner_source_sha256'],
        'changes':read(HERE/'operations.json'),'givenFiles':{'point_body.gd':current[1],'line_skin.gd':current[2]},
        'files':current+[ids['tutorial'],'point-grid-brief']+[value for key,value in ids.items() if key!='tutorial'],
        'evidence':{'report':ids['report-runtime'],'contract':ids['contract'],'expected':ids['expected'],'nextInput':ids['next-input'],'tutorial':ids['tutorial'],
            'negativeControl':'The same normal checks reject source mutation, the wrong frame and truncation instead of rounding.',
            'negativeControls':[n['name'] for n in report['negative_controls']]}}
    save(state_dir/'brief.json',{key:state[key] for key in ['map','status','predecessor','provenance','brief','carry','nextStatus']})
    register('point-grid-brief',state_dir/'brief.json')
    manifest['states'] = [s for s in manifest['states'] if s['id']!='point-grid']+[state]
    previous = next(s for s in manifest['states'] if s['id']=='point-trace')
    previous['nextStatus'] = 'Grid now continues this exact source and keeps its local recorder. The next state derives two grid spacings from one live record; it does not transport an earlier running scene.'
    previous['brief']['later'] = 'Grid continues this source with a separately stored interpretation. Its own native report verifies that continuation.'
    # Prior code, brief files and native reports remain historical bytes.
    manifest['planned'] = [p for p in manifest['planned'] if p['map']!='Point_Line_Grid']
    if not any(p['map']=='Primitives_Triangle' for p in manifest['planned']):
        manifest['planned'].append({'map':'Primitives_Triangle','title':'Triangle','note':'Next: select three valid positions, close the boundary, add a face. No verified continuation from Grid yet.'})
    manifest['summary'] = 'Build a point; make it pickable; extract PointBody; record its trace; derive grid addresses without losing the source. Five current states, complete printed code and native behavioural evidence.'
    manifest['files'] = list(entries.values())
    save(GHOST/'manifest.json',manifest)

    card = api('/api/tutorial-cards')
    api('/api/tutorial-cards',{'revision':card['revision'],'map':'Point_Line_Grid','subjects':subjects,'focus':focus})
    p = ROOT/'doc/book/course/hall-cards/lineage-opening.json'
    data = read(p)
    row = next(r for r in data['halls'] if r['map']=='Point_Line_Grid')
    row.update(subjects=subjects,focus=focus,carries=carry,status='aligned',review='6 October: complete learner continuation, 71 native checks and three detected deliberate faults. Real XRTools with synthetic input; no headset or human-learning claim.',adds='An integer spatial address distinct from list order; a reversible change of derivation while preserving source data.',revision_report=REL+'/index.html',tutorial_sha256_after=sha(CANONICAL))
    save(p,data)
    p = ROOT/'doc/book/course/storyboards/opening.json'
    data = read(p)
    for sequence in data:
        for hall in sequence['halls']:
            if hall['id']=='Point_Line_Grid':
                hall.update(storyboard=focus,storyboard_short=short,learns=subjects,carries=carry,review_note=row['review'])
                hall['brings'] = ['Verified local Trace program','PointBody class and LineSkin renderer']
                hall['supplied'] = ['Prepared room, camera/light, player and XRTools','Existing action input for the two-pitch comparison']
    save(p,data)
    plan = api('/api/tutorial-plan')
    lesson = next(l for l in plan['plan']['lessons'] if l['id']=='Point_Line_Grid')
    lesson.update(object='The carried sphere, original trace and addressed copy',change=focus,given=brief['given'],carry=carry,
        checks=['71 native assertions pass on the printed continuation and flat-Y exercise; source order/values, manual rounding oracles and local frame are checked.',
                'Real XRTools pickup, grab-driver movement, action, release and re-grab work under synthetic input. Keyboard action compares two pitches without clearing the source.',
                'The normal contract rejects source mutation, world-frame confusion and truncation. Headset input and student understanding remain untested.'],
        next='Review the Grid lesson; then assemble Triangle from this verified output with a non-collinearity and face-orientation contract.',
        notes='6 October: Grid now has complete printed learner code and native evidence. The production museum TraceData fitting/transfer stays separate. Current Ghost state: point-grid; report: '+REL+'/index.html.',
        later=brief['later'],summary='Continue the same PointBody and its local position record from Trace. Keep the original pink drawing while deriving whole-number XYZ addresses and a green snapped copy. Compare 0.25 m and 0.50 m spacing on one retained gesture, predict an address and distinguish its place in space from its index in a list. Test a flat-Y interpretation without changing the recorded height. Carry the source and both derived arrays in their declared frame; cross-hall transport remains a separate capability.')
    api('/api/tutorial-plan',{'kind':'lesson','revision':plan['revision'],'record':lesson})

    p = ROOT/'doc/book/course/execution-plan/authorized-revisions.json'
    revisions = read(p)
    name = CANONICAL.relative_to(ROOT).as_posix()
    revisions[name] = {'date':'2026-10-06','before':read(p.with_name('protected-sources.json'))[name],'after':sha(CANONICAL),
        'reason':'User requested Trace -> Grid continuation. Replaced production-excerpt tutorial with complete tested learner continuation from the verified local Trace, preserving source data; 71 native checks and three deliberate faults detected.'}
    save(p,revisions)
    p = ROOT/'doc/book/course/storyboards/CONTEXT.md'
    context = p.read_text(encoding='utf-8-sig')
    entry = '6 October, Trace → Grid — [current lesson/evidence](../../iterations/2026-10-06-trace-to-grid/index.html). Continue exact tested Trace code, carry PointBody/LineSkin unchanged, retain local positions and derive independent integer addresses/snapped positions. Compare .25/.50 m in one station with inherited XR action or ui_accept; keep source and pink rendering. Full code printed once; 71 native assertions, three fault controls and flat-Y exercise pass. Five Ghost states / 471 recorded assertions now. No cross-hall data transfer, museum runtime edit or final.md edit. Next: Triangle from this verified output. Earlier Grid-pending entries below are historical.\n\n'
    if entry not in context: context=context.replace('## Keep in memory\n\n','## Keep in memory\n\n'+entry)
    write(p,context)
    p = ROOT/'doc/book/course/functional_text/RECONSTRUCTION.md'
    text = p.read_text(encoding='utf-8-sig')
    start = text.index('## Next handoff: Trace → Grid')
    end = text.index('## What the small checker does',start)
    text = text[:start]+'''## Current handoff: Trace → Grid

Grid now continues the exact tested Trace program in the same `PointStudy`. The unchanged PointBody supplies the moving point; the original local `Array[Vector3]` supplies every derivation. It creates independent `Vector3i` addresses and snapped positions at 0.25 or 0.50 metre pitch. The source remains ordered and intact. No file, timestamp or cross-hall transfer is implied.

[Grid evidence](../../iterations/2026-10-06-trace-to-grid/index.html): 71 native assertions pass, including the printed flat-Y exercise, manual rounding oracles, empty/single records, coincident addresses, frame changes, real XRTools under synthetic input and keyboard pitch changes. The ordinary contract rejects source mutation, a wrong frame and truncation. These are software results; learner prediction and headset experience remain untested.

Next: carry this actual output to Triangle. Select three positions, test whether they can form a face, and distinguish their boundary from the face data. Declare which record supplies the corners and what remains inherited before expanding its text.

'''+text[end:]
    write(p,text)
    p = ROOT/'doc/book/course/execution-plan/README.md'
    text = p.read_text(encoding='utf-8-sig')
    text = text.replace('2. **Complete Trace → Grid.**','2. **Trace → Grid completed, 6 October.** [Full lesson and native evidence](../../iterations/2026-10-06-trace-to-grid/index.html): 71 checks and three fault controls pass; the current chain now has five states / 471 recorded assertions. Next is Triangle. Original contract:')
    text = text.replace('The only current exception is the 6 October Godot Primitives teaching-intent revision.','The current exceptions are the 6 October Godot Primitives teaching-intent revision and the user-requested complete Trace → Grid tutorial.')
    write(p,text)
    p = ROOT/'doc/book/course/execution-plan/REVIEW.md'
    text = p.read_text(encoding='utf-8-sig')
    entry = '6 October executable follow-through: [Trace → Grid](../../iterations/2026-10-06-trace-to-grid/index.html) now passes 71 native assertions and detects three deliberate faults. Five Ghost states carry 471 recorded checks; the four earlier reports remain unchanged. This bounded continuation reuses one local live record, preserving the source through pitch changes. It does not certify museum transport or learner understanding. Historical counts below describe the original plan review.\n\n'
    if entry not in text: text=text.replace('## What this pass examined\n\n',entry+'## What this pass examined\n\n')
    write(p,text)

    with zipfile.ZipFile(HERE/'grid-three-files.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for name in ['grid.gd','point_body.gd','line_skin.gd']: archive.write(HERE/name,name)
        archive.write(HERE/'variants/flat_y.gd','flat_y.gd')
    write(HERE/'run-checks.py.txt',(HERE/'run_checks.py').read_text(encoding='utf-8'))
    html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trace → Grid — Endless Museum</title><style>
*{box-sizing:border-box}body{margin:0;background:#f4f1eb;color:#252928;font:17px/1.65 system-ui}main{max-width:1220px;margin:auto;padding:48px 30px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.12}h1{font-size:clamp(44px,7vw,78px);letter-spacing:-.04em}h2{font-size:34px}.lead{font:24px/1.5 Georgia,serif;max-width:850px}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.15em;color:#647064}a{color:#87405c;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:12px 24px;font-size:14px;margin:24px 0}section{border-top:1px solid #cdc6b9;margin-top:40px;padding-top:24px}.comparison{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:20px 0}img{display:block;width:100%;background:#202426}figcaption,footer{font-size:13px;color:#647064}figcaption{padding-top:8px}pre{overflow:auto;padding:24px;background:#232c2a;color:#f1eee7;font:13px/1.7 Consolas,monospace}.proof{padding:18px;background:#e0e9dd}.pink{color:#a94870}.green{color:#26715d}table{width:100%;border-collapse:collapse}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #d3cbbb;padding:13px}summary{cursor:pointer}@media(max-width:740px){main{padding:28px 18px}.comparison{grid-template-columns:1fr}th,td{font-size:14px;padding:8px}}</style>
<main><p class="eyebrow">Endless Museum · Tutorial continuation · 6 October 2026</p><h1>A trace can have<br>another address.</h1><p class="lead">Keep what the hand recorded. Change the rule that gives those positions a place on the grid.</p>
<nav><a href="../2026-10-05-primitives-facing-pages/Point_Line_Grid.html">Read tutorial beside reflection</a><a href="http://localhost:3003/ghost-student?state=point-grid">Inspect Ghost Student</a><a href="http://localhost:3003/tutorial-plan?map=Point_Line_Grid">Edit lesson plan</a><a href="grid-three-files.zip">Download scripts + exercise</a></nav>
<p>The sphere, pickup behaviour, sampling condition and pink trace return from the tested Trace program. Grid adds integer addresses and a second position array. Both use the same station frame. A small control compares two spacings without clearing the drawing.</p>
<section id="comparison"><h2>One record. Two spacings.</h2><p><strong class="pink">Pink:</strong> retained positions. <strong class="green">Green:</strong> their rounded interpretation. The point and pink trace stay in place while the green corners move.</p><div class="comparison">
<figure><img src="pitch-025.png" alt="Godot learner program: original trace and its green quarter-metre grid interpretation"><figcaption>0.25 metre spacing · nine retained samples</figcaption></figure>
<figure><img src="pitch-050.png" alt="The same program and original trace with the green half-metre interpretation"><figcaption>0.50 metre spacing · the same nine samples</figcaption></figure></div>
<p>Actual renders of the unchanged tested learner script, driven by a fixed example gesture. The camera, lights and floor grid are a capture fixture. They are not a new museum installation. The floor ruling remains 0.25 metres in both views; the second derivation uses every other interval. <a href="capture.gd">Capture source</a>.</p></section>
<section><h2>What this lesson adds</h2><table><tr><th>Trace supplied</th><th>Grid adds</th><th>Student demonstrates</th></tr><tr><td>A held PointBody, an ordered local array, a distance condition and a neighbour loop.</td><td>Vector3i addresses, rounding, a separate placed-position array and a shared derivation function.</td><td>Predict an address, compare pitches on one gesture, then flatten only the derived Y coordinate.</td></tr></table><p>An array index identifies an entry. A grid address identifies a place. Several entries may have the same address; their order remains.</p></section>
<section><h2>From the museum into learner code</h2><figure><img src="../2026-10-05-eight-interaction-lessons/figures/grid.png" alt="Existing Grid hall in the Endless Museum" loading="lazy"><figcaption>Existing museum capture, recorded in the earlier interaction review. The production hall was not rebuilt during this tutorial pass.</figcaption></figure><table><tr><th>Before</th><th>Now</th></tr><tr><td>The tutorial followed the production pen’s session store and display fitting. It did not continue the student’s tested PointBody recorder.</td><td>The tutorial prints a complete continuation of that recorder, plus its unchanged point class and renderer. It keeps all records in one named local frame.</td></tr></table><p>Running Grid starts a new instance of the continued program. Once drawing, you can compare both pitches on its retained record. This does not yet carry a drawing from an earlier running hall or save it between sessions.</p></section>
<section id="evidence"><h2>The printed code runs.</h2><p class="proof">71 native Godot assertions pass. Three deliberate faults are detected by the same normal checks.</p><p>Assertions cover source preservation, manual rounding oracles, negative coordinates and ties, empty/single records, repeated addresses, geometry, frame changes, pitch switching, the flat-Y exercise, pickup, release and resuming the drawing. The actual XRTools library receives synthetic controller input. Headset experience and human learning remain untested.</p><nav><a href="report-runtime.json">Native results</a><a href="contract.json">Contract</a><a href="verify.gd">Behaviour assertions</a><a href="run-checks.py.txt">Runner</a><a href="before/tutorial.md">Previous tutorial</a></nav>'''
    html += '<details><summary>The complete Grid script</summary><pre><code>'+escape((HERE/'grid.gd').read_text())+'</code></pre></details>'
    html += '<details><summary>Short instruction for the next AI</summary><pre>'+escape(short)+'</pre></details></section><section><h2>Next: three corners.</h2><p>The records can supply positions. Triangle must choose three that can form a face, close their boundary, and distinguish that boundary from the surface inside. That is the next increment to write and test.</p></section></main></html>'
    write(HERE/'index.html',html)
    save(HERE/'publication-checks.json',{'passed':True,'native_checks':71,'negative_controls':3,'protected_files_unchanged':len(read(HERE/'before/protected.json')),'helper_files_unchanged':True})
    print('Published Grid, Ghost state 5, selected plan/card, memory and report.')

if __name__=='__main__':main()
