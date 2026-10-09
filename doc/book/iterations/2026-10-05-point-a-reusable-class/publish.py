"""Publish verified class lessons and a new Ghost Student evidence snapshot."""
from pathlib import Path
from html import escape
import hashlib
import json
import re
import shutil
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
GHOST = ROOT.parent / 'ada_encyclopedia/ghost-student'
REL = HERE.relative_to(ROOT).as_posix()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')

def save(path, value):
    write(path, json.dumps(value, ensure_ascii=False, indent=2) + '\n')

def main():
    protected = load(HERE / 'protected-before.json')
    for rel, expected in protected.items():
        assert sha(ROOT / rel) == expected, rel
    reports = {}
    for short in ('lines', 'trace'):
        report = load(HERE / short / 'report-runtime.json')
        assert report['passed']
        for rel, expected in {**report['inputs'], **report['dependencies']}.items():
            assert sha(ROOT / rel) == expected, rel
        reports[short] = report
        shutil.copyfile(HERE / short / 'run_checks.py', HERE / f'{short}-run-checks.py.txt')
    assert (HERE / 'lines/point_body.gd').read_bytes() == (HERE / 'trace/point_body.gd').read_bytes()
    manifest = load(GHOST / 'manifest.json')
    if not (HERE / 'before/ghost-manifest.json').exists():
        shutil.copyfile(GHOST / 'manifest.json', HERE / 'before/ghost-manifest.json')
        shutil.copyfile(GHOST / 'README.md', HERE / 'before/ghost-README.md')
        for folder in ('003-point-lines', '004-point-trace'):
            shutil.copytree(GHOST / 'states' / folder, HERE / 'before' / folder)
    entries = {f['id']: f for f in manifest['files']}
    def register(id, path, label=None):
        suffix = path.suffix
        entries[id] = {'id': id, 'path': path.relative_to(GHOST).as_posix(), 'label': label or path.name,
                       'language': {'.gd':'gdscript','.md':'markdown','.json':'json','.py':'python'}.get(suffix, 'text'), 'sha256':sha(path)}
        return id
    summaries = {}
    for short, hall, folder, filename in (('lines','Point_Lines','003-point-lines','line.gd'), ('trace','Point_Trace','004-point-trace','trace.gd')):
        evidence = HERE / short
        target = GHOST / 'evidence' / HERE.name / short
        for p in evidence.rglob('*'):
            if p.is_file() and '__pycache__' not in p.parts:
                destination = target / p.relative_to(evidence)
                destination.parent.mkdir(parents=True, exist_ok=True)
                if destination.exists():
                    assert destination.read_bytes() == p.read_bytes(), 'Never overwrite published native evidence'
                else:
                    shutil.copyfile(p, destination)
        ids = {}
        for p in sorted(target.rglob('*')):
            if p.is_file() and p.suffix in {'.gd','.json','.md','.py'}:
                key = p.relative_to(target).with_suffix('').as_posix().replace('/','-').replace('_','-')
                ids[key] = register(f'class-{short}-{key}', p, 'evidence/' + p.relative_to(target).as_posix())
        state = next(s for s in manifest['states'] if s['id'] == f'point-{short}')
        state_dir = GHOST / 'states' / folder
        current = []
        for name, tail in ((filename,'code'),('point_body.gd','body'),('line_skin.gd','skin')):
            shutil.copyfile(evidence / name, state_dir / name)
            current.append(register(f'point-{short}-{tail}', state_dir / name))
        shutil.copyfile(evidence / 'tutorial.md', state_dir / 'tutorial.md')
        tutorial = (evidence / 'tutorial.md').read_text(encoding='utf-8')
        subjects = re.findall(r'^- (.+)$', tutorial.split('##',1)[0], re.M)
        if short == 'lines':
            state['title'] = 'One point class, two instances'
            state['provenance'] = 'The complete printed script extracts the tested Coordinates construction into point_body.gd and creates two instances. The class construction is checked against the predecessor. Each point owns its mesh and collider; native XR pickup, resource independence and line relations are verified.'
            state['brief']['build'] = 'Move familiar geometry and pickup settings into PointBody._init; make A and B with .new; keep positions/readout/relation in the lesson. Convert both ends to local coordinates; subtract, measure and draw.'
            state['brief']['check'] = 'Both instances inherit pickup, move and release independently. Editing one mesh/collider resource leaves the other alone. Segment/readout follow; parallel, +, X and depth exercises work.'
            state['carry'] = 'PointBody class, two independent pickable instances, coordinate readout and live segment. Trace reuses the class unchanged.'
            short_brief = 'Extract familiar point into PointBody. _init builds mesh/collider/settings; XRToolsPickable supplies pickup. Two .new instances, own resources. Lesson owns placement/readout/segment. Explain class vs instance; test independent movement/resources, release, local relation and pairs. Carry class unchanged to Trace.'
        else:
            state['provenance'] = 'The complete printed Trace script continues the verified class-based Lines program. PointBody and LineSkin are carried byte for byte. The lesson owns the array, threshold and neighbour loop. This source-code continuation does not transfer a running museum session.'
            state['brief']['bring'] = 'The verified Lines program, learner PointBody class and supplied line renderer.'
            state['brief']['build'] = 'Keep PointBody unchanged. Replace B/live span with a seeded Array[Vector3]; append when distance from last retained >= threshold; loop neighbouring entries to redraw. Keep history outside the point class.'
            state['carry'] = 'Unchanged PointBody class, coordinate readout and a station-local position array separate from its segment drawing. The record lasts with this station; no Grid transfer yet.'
            short_brief = 'Reuse PointBody unchanged; remove B/live span. Seed local Array[Vector3]. If distance from last retained >= threshold: append, loop neighbours, redraw. Teach indices/size/append/if/for; keep record separate from body and drawing. Test pause, cumulative movement, turns, release, threshold/traversal. Grid transfer still pending.'
        state['brief']['given'] = 'Prepared unit-scale museum study, light/camera/XR hands and library; fully printed line_skin.gd renderer. PointBody is learner code.'
        state['subjects'] = subjects
        report = reports[short]
        contract = load(evidence / 'contract.json')
        state['changes'] = contract['operations']
        state['incomingSha256'] = report['incoming_sha256']
        state['outgoingSha256'] = report['learner_source_sha256']
        state['givenFiles'] = {'point_body.gd':current[1], 'line_skin.gd':current[2]}
        state['evidence'] = {'report':ids['report-runtime'], 'contract':ids['contract'], 'expected':ids['expected'], 'nextInput':ids['next-input'], 'tutorial':ids['tutorial'],
                             'negativeControls':[n['name'] for n in report['negative_controls']],
                             'negativeControl':'Deliberate faults fail the same normal checks: ' + ', '.join(n['name'].replace('_',' ') for n in report['negative_controls']) + '.'}
        state['files'] = current + [ids['tutorial'], f'point-{short}-brief'] + [v for k,v in ids.items() if k != 'tutorial']
        brief = {key:state[key] for key in ('map','status','predecessor','provenance','brief','carry','nextStatus')}
        save(state_dir / 'brief.json', brief)
        register(f'point-{short}-brief', state_dir / 'brief.json')
        summaries[hall] = {'subjects':subjects, 'focus':state['brief']['build'], 'carry':state['carry'], 'short':short_brief, 'review':state['provenance']}
    manifest['files'] = list(entries.values())
    manifest['summary'] = 'Build a point, make it pickable, extract a reusable PointBody class in Lines, then record its positions in Trace. Full code and fresh native evidence accompany each state.'
    readme = (GHOST / 'README.md').read_text(encoding='utf-8-sig')
    readme = readme.replace('It keeps `point`, its shape construction and the LOCAL/WORLD readout, duplicates the point for a second endpoint, and adds a live segment and distance.', 'It extracts familiar geometry and pickup settings into `point_body.gd`, creates two independent class instances, keeps the LOCAL/WORLD readout, and adds a live segment and distance.')
    marker = '## Preserved earlier evidence\n'
    entry = '## Current class extraction\n\nLines and Trace now use `evidence/2026-10-05-point-a-reusable-class/lines` and `/trace`. The complete `point_body.gd` is printed in both lessons and carried unchanged. Lines has 170 native checks including independent resources; Trace retains 124 checks. Old carried-point archives and their manifest IDs remain historical snapshots. The class owns construction and inherited pickup behaviour; the lesson owns relationships and history. No museum runtime was changed.\n\n'
    if entry not in readme:
        readme = readme.replace(marker, entry + marker)
    write(GHOST / 'README.md', readme)
    register('repository-readme', GHOST / 'README.md')
    manifest['files'] = list(entries.values())
    save(GHOST / 'manifest.json', manifest)

    p = ROOT / 'doc/book/course/hall-cards/lineage-opening.json'
    data = load(p)
    for row in data['halls']:
        if row['map'] in summaries:
            info = summaries[row['map']]
            row.update(subjects=info['subjects'], focus=info['focus'], carries=info['carry'], review=info['review'], status='aligned', revision_report=REL+'/index.html', tutorial_sha256_after=sha(ROOT / f"commons/maps/{row['map']}/tutorial.md"))
            if row['map'] == 'Point_Lines':
                row['adds'] = 'A class extracted from familiar construction; independent instances; displacement and distance between endpoints.'
        elif row['map'] == 'Primitives_Godot':
            row['review'] = 'This file is a teaching-intent stub. Choose the small edit host and demonstrate independent resources; the fixed library has no universal parameter controls. Reuse the class/instance distinction now introduced through PointBody in Lines.'
        elif row['map'] == 'Color_Grid_Pallet':
            row['adds'] = 'Deepens the authored class introduced in Lines with changing instance state and methods; separate palettes keep independent indices.'
            if not any(item['map'] == 'Point_Lines' for item in row['builds_on']):
                row['builds_on'].insert(0, {'map':'Point_Lines', 'why':'PointBody introduced an authored class and independent instances; Palette adds methods that change each instance’s own state.'})
    save(p, data)
    p = ROOT / 'doc/book/course/storyboards/opening.json'
    data = load(p)
    for seq in data:
        for hall in seq['halls']:
            if hall['id'] in summaries:
                info = summaries[hall['id']]
                hall.update(storyboard=info['focus'], storyboard_short=info['short'], learns=info['subjects'], carries=info['carry'], review_note=info['review'])
                hall['supplied'] = ['Prepared unit-scale museum room, camera/light and configured XR hands/library', 'Complete printed line_skin.gd renderer']
                if hall['id'] == 'Point_Trace':
                    hall['brings'] = ['Tested Lines program with learner PointBody class', 'Displacement and length', 'Supplied line_skin.gd']
    save(p, data)
    p = ROOT / 'doc/book/course/storyboards/CONTEXT.md'
    context = p.read_text(encoding='utf-8-sig')
    entry = '5 October, reusable point class — current Lines/Trace: [lesson and evidence](../../iterations/2026-10-05-point-a-reusable-class/index.html). Author accepts extracting the familiar Coordinates body into PointBody at Lines. The class creates mesh/collider and inherits pickup; each .new owns independent resources. Lessons own placements, relations and history. Trace carries the class unchanged. Full class/main/renderer are printed, mechanically continued and natively checked (Lines 170; Trace 124; five deliberate faults detected). Earlier reports below are preserved historical snapshots. Point One/Coordinates, final.md and museum behaviour stay unchanged. Grid remains unbuilt.\n\n'
    if entry not in context:
        context = context.replace('## Keep in memory\n\n', '## Keep in memory\n\n' + entry)
    write(p, context)

    for short, file in (('lines','line.gd'),('trace','trace.gd')):
        with zipfile.ZipFile(HERE / f'{short}-three-files.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
            for name in (file,'point_body.gd','line_skin.gd'):
                archive.write(HERE / short / name, name)
    body = escape((HERE / 'lines/point_body.gd').read_text(encoding='utf-8'))
    sections = ''
    for short, hall, file in (('lines','Point_Lines','line.gd'),('trace','Point_Trace','trace.gd')):
        before = (HERE / 'before' / (hall+'.md')).read_text(encoding='utf-8')
        old = re.search(r'<!-- student-code:' + re.escape(file) + r' -->\s*```gdscript\n(.*?)^```', before, re.M|re.S).group(1)
        new = (HERE / short / file).read_text(encoding='utf-8')
        sections += f'<section id="{short}"><p class="eyebrow">{hall.replace("_", " ")}</p><h2>{"Make two instances." if short == "lines" else "Keep their history outside the class."}</h2><p>{escape(summaries[hall]["focus"])}</p><p>The main script moves from {len(old.splitlines())} to {len(new.splitlines())} lines. Its familiar construction is now visible in the {len((HERE / short / "point_body.gd").read_text().splitlines())}-line class.</p><nav><a href="../2026-10-05-primitives-facing-pages/{hall}.html?revision=point-class">Read tutorial beside reflection</a><a href="http://localhost:3003/ghost-student?state=point-{short}">Ghost Student</a><a href="{short}-three-files.zip">Download all three scripts</a></nav><details><summary>Complete main script</summary><pre><code>{escape(new)}</code></pre></details><p class="proof">{len(reports[short]["checks"])} native Godot checks pass. All declared failure controls are detected.</p><nav><a href="{short}/report-runtime.json">Native report</a><a href="{short}/contract.json">Continuation contract</a><a href="{short}/verify.gd">Behaviour assertions</a><a href="{short}-run-checks.py.txt">Test runner</a></nav></section>'
    html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One point, a reusable class — Endless Museum</title><style>
*{box-sizing:border-box}body{margin:0;background:#f4f1eb;color:#262825;font:17px/1.65 system-ui}main{max-width:1050px;margin:auto;padding:55px 30px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.1}h1{font-size:clamp(44px,7vw,78px);letter-spacing:-.035em}h2{font-size:34px}.lead{font:24px/1.5 Georgia,serif;max-width:760px}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.14em;color:#626d62}a{color:#873d59;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:14px 24px;font-size:14px;margin:20px 0}section{border-top:1px solid #c9c4ba;margin-top:34px;padding-top:22px}.proof{background:#dfe7d9;padding:16px}pre{overflow:auto;background:#252928;color:#f5ece7;padding:22px;font:13px/1.65 Consolas,monospace}code{font-size:.9em}img{width:100%;display:block}figure{margin:32px 0}figcaption,footer{font-size:12px;color:#636d64}summary{cursor:pointer}table{width:100%;border-collapse:collapse}td,th{padding:12px;text-align:left;border-bottom:1px solid #d7d1c5}@media(max-width:700px){main{padding:30px 18px}td,th{padding:8px;font-size:14px}}</style><main><p class="eyebrow">Endless Museum / Student code / 5 October 2026</p><h1>One point.<br>A class we can carry.</h1><p class="lead">Build it once where its parts can be understood. Give that construction a name when we need it again.</p><nav><a href="#lines">Lines</a><a href="#trace">Trace</a><a href="#point">The point class</a></nav>
<table><tr><th>Point One → Coordinates</th><th>Lines</th><th>Trace</th></tr><tr><td>Build the body; give it pickup.</td><td>Extract PointBody; make two instances.</td><td>Reuse PointBody; record positions.</td></tr></table>
<figure><img src="../2026-10-05-eight-interaction-lessons/figures/trace.png" alt="The existing Trace hall and its drawing artifacts"><figcaption>Existing museum capture. This update changes the student tutorials and examples; this image does not depict the native test fixture.</figcaption></figure>'''
    html += sections + '<section id="point"><h2>The complete point class.</h2><p>The point owns its surface, boundary and pickup settings. Placement, distance and the trace remain with the lesson. Both lessons print the same class in full.</p><pre><code>' + body + '</code></pre><p><a href="lines/point_body.gd">Download point_body.gd</a></p></section>'
    html += '''<section><h2>What the tests establish</h2><p>294 native assertions pass in Godot 4.6 using the real XR Tools library and synthetic controllers. They exercise pickup/release, independent bodies and resources, line geometry, coordinate frames, arrays, threshold sampling and neighbouring segments. Five deliberate faults fail the expected checks.</p><p>The code extracted from each tutorial is the code executed. The class construction is also checked against Coordinates, and Trace carries the exact tested Lines class. Headset input, rendered appearance and learner understanding still need human testing.</p><p>Point One and Coordinates keep their earlier construction lessons. Reflection and museum runtime remain unchanged. Old reports remain immutable; this page holds the new evidence.</p></section><footer>Shared construction does not require shared state. A future change to point behaviour belongs in the point class; a new relation belongs in the lesson that uses it.</footer></main></html>'''
    write(HERE / 'index.html', html)
    save(HERE / 'publication-checks.json', {'passed':True, 'native_checks':{k:len(v['checks']) for k,v in reports.items()}, 'protected_files_unchanged':len(protected), 'class_identical_across_lessons':True})
    print('Published two verified lessons, current Ghost states, source cards and report.')

if __name__ == '__main__':
    main()
