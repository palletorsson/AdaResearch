"""Publish the saved drawing handoff, retaining prior native evidence verbatim."""
from pathlib import Path
import re, shutil, urllib.request, zipfile
from build import HERE, ROOT, OLD, read, write, save, sha

GHOST = ROOT.parent / 'ada_encyclopedia/ghost-student'
REL = HERE.relative_to(ROOT).as_posix()
BASE = 'http://localhost:3003'

def api(route, body=None):
    import json
    req = urllib.request.Request(BASE + '/api/' + route, data=None if body is None else json.dumps(body).encode(), headers={'Origin': BASE, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.load(response)

LESSONS = {
    'trace': {
        'map': 'Point_Trace', 'state': 'point-trace', 'dir': '004-point-trace', 'title': 'Keep the drawing; bring it onward', 'predecessor': 'point-lines',
        'bring': 'The verified Lines program, unchanged PointBody class and LineSkin renderer.',
        'make': 'Hold the same point, record its movement, and release it to save both the positions and the drawing already made from them.',
        'given': 'The existing Endless Museum hall, player and XRTools; fully printed TraceArchive supplies packing and loading. PointBody and LineSkin return unchanged.',
        'build': 'Inside the Trace hall, retain local positions in metres with an array, minimum-distance condition and neighbour loop. Connect the existing release event to the supplied archive. Save the visible segments as a static sculpture with their position record; carry it to Grid in the same project.',
        'check': 'Predict when a movement adds a sample; vary the threshold. Hold, move and release the point, then load the saved geometry in a separate Grid run. Removing the condition or joining the wrong neighbours must fail.',
        'later': 'Grid receives this actual saved drawing. Serialization internals are supplied; Triangle will later select valid corners.',
        'carry': 'The saved segment sculpture and ordered local positions in user://ada_student_trace.scn. Metres, PointStudy-local frame, no timestamps; a later valid release replaces the save.',
        'summary': 'Move the point already built in Point One and made pickable in Coordinates. Trace keeps selected local positions in an array, uses a distance condition to admit a sample, and loops over neighbours to join them. Predict which motion is retained and try another threshold. Release the point to save its positions and existing drawing through the supplied archive. Bring that work into the next museum hall; Grid will receive the sculpture instead of asking for another gesture.',
        'short': 'BRING same PointBody + LineSkin. RECORD local metre positions; Array, append/index, distance IF, neighbour FOR. RELEASE saves positions + existing segment sculpture via supplied TraceArchive. CHECK pause/threshold/order/geometry + cross-process load. CARRY actual saved work to Grid; no timestamps.',
        'reflection': 'A hand, pen or rolling ball leaves a selected record of movement; bringing the trace into the next hall lets that finished gesture become a sculpture and find another use.',
        'next': 'Grid loads the saved drawing in another hall, preserving its source and interpreting a separate copy.'
    },
    'grid': {
        'map': 'Point_Line_Grid', 'state': 'point-grid', 'dir': '005-point-grid', 'title': 'Meet your trace as a sculpture', 'predecessor': 'point-trace',
        'bring': 'The actual drawing saved on release in Trace, its local position record and the unchanged LineSkin renderer.',
        'make': 'Place the saved drawing as a sculpture, and compare it with a separately owned grid interpretation.',
        'given': 'The existing Endless Museum Grid hall, light and player; the same fully printed TraceArchive supplies loading. Desktop ui_accept changes pitch; the initial grid_step can be edited for VR.',
        'build': 'Load the existing sculpture and positions in Grid without making another point or recording another gesture. Keep the original pink. Duplicate its segments with independent meshes/materials, derive integer XYZ addresses, and use the carried renderer to place only the green copy. Compare 0.25 and 0.50 metre pitches.',
        'check': 'Predict a corner address, switch pitch, and try flattening only the copy. Assert saved positions, original geometry and file remain unchanged; missing saves ask for Trace. Deliberate source mutation and collapsed edges must fail.',
        'later': 'Triangle can select three valid positions from the original record. Production display fitting and broader input architecture remain separate lessons.',
        'carry': 'Original saved sculpture and positions, independently owned derived segments and integer XYZ addresses. The drawing file and original record survive every comparison.',
        'summary': 'Meet the drawing made in Trace as a sculpture in the Grid hall. Load its saved geometry and local position record; make neither a new sphere nor another gesture. Keep the original pink while a separate copy receives rounded XYZ addresses. Predict a corner, compare two pitches and flatten only the copy to test what the rule changes. The original remains available for another use, including choosing three corners in Triangle.',
        'short': 'BRING saved Trace sculpture + positions. LOAD in same museum project; no new point/gesture/geometry recipe. KEEP pink source. COPY with independent resources; round XYZ/pitch to Vector3i; place green via earned LineSkin. TEST source/file/geometry unchanged, absent save, .25/.50, flat-Y. CARRY original to Triangle.',
        'reflection': 'Your drawing arrives from Trace as a sculpture. Grid addresses make repeatable placements possible while keeping the original gesture available for another use.',
        'next': 'Select three valid source positions in Point_Triangle_Context; declare and test the boundary-to-face continuation before expanding its code.'
    }
}

def main():
    reports = {}
    for part, d in LESSONS.items():
        report = read(HERE / part / 'report-runtime.json')
        assert report['passed']
        for p, expected in {**report['inputs'], **report['dependencies']}.items():
            assert sha(ROOT / p) == expected, 'Evidence drift: ' + p
        d['subjects'] = re.findall(r'^- (.+)$', (HERE / part / 'tutorial.md').read_text().split('##', 1)[0], re.M)
        reports[part] = report
    for name in ['point_body.gd', 'line_skin.gd']:
        assert sha(HERE / 'trace' / name) == sha(OLD / 'trace' / name)
    museum = {}
    for part, d in LESSONS.items():
        run = ROOT / 'ada_run/encounter_pilot' / (d['map'] + '_saved_student_20261006')
        result = read(run / 'report.json')
        assert result['passed'] and all(c['passed'] for c in result['checks'])
        museum[part] = result
        for name in ['report.json', 'source_manifest.json', 'stdout.log']:
            shutil.copyfile(run / name, HERE / ('museum-' + part + '-' + name))
    assert museum['trace']['observations']['archive_sha256'] == museum['grid']['observations']['archive_sha256']
    for part, names in [('trace', ['museum-trace-side.png']), ('grid', ['museum-grid-sculpture.png', 'museum-grid-coarse.png'])]:
        run = ROOT / 'ada_run/encounter_pilot' / (LESSONS[part]['map'] + '_saved_student_20261006')
        for name in names:
            shutil.copyfile(run / name, HERE / name)
    museum_pins = [HERE / 'museum_handoff.gd', HERE / 'run_museum.py', ROOT / 'commons/scenes/endless_museum.gd', ROOT / 'tools/probes/transformation_encounters.gd', ROOT / 'tools/run_encounter_probe.py']
    museum_pins += [ROOT / f'commons/maps/{d["map"]}/map_data.json' for d in LESSONS.values()]
    save(HERE / 'museum-report.json', {'passed': True, 'trace': museum['trace'], 'grid': museum['grid'], 'same_saved_file': True,
        'source_pins': {p.relative_to(ROOT).as_posix(): sha(p) for p in museum_pins},
        'learner_inputs': {p: h for r in reports.values() for p, h in r['inputs'].items()},
        'capture_pins': {p.name: sha(p) for p in HERE.glob('museum-*.png')},
        'scope': 'Separate engine runs in actual museum halls, same saved file. Temporary unit-scale learner study at hall-local (8.5,0,8.5); synthetic controller, inspection camera. Prior user save restored afterwards. No permanent map edit or physical headset test.',
        'diagnostics': 'The full museum logs retain unrelated unresolved UID, legacy material and entrance-placement warnings. These bounded checks do not certify whole-project health.'})

    manifest = read(GHOST / 'manifest.json')
    entries = {entry['id']: entry for entry in manifest['files']}
    def register(id, path, label=None):
        entries[id] = {'id': id, 'path': path.relative_to(GHOST).as_posix(), 'label': label or path.name,
            'language': {'.gd': 'gdscript', '.md': 'markdown', '.json': 'json', '.py': 'python'}.get(path.suffix, 'text'), 'sha256': sha(path)}
        return id
    for part, d in LESSONS.items():
        report = reports[part]
        destination = GHOST / 'evidence' / HERE.name / part
        evidence = {}
        paths = [p for p in (HERE / part).rglob('*') if p.is_file() and p.suffix in ['.gd', '.md', '.json']]
        paths += [HERE / name for name in ['build.py', 'run_checks.py', 'verify_trace.gd', 'verify_handoff.gd', 'museum_handoff.gd', 'run_museum.py', 'museum-report.json']]
        for source in paths:
            relative = source.relative_to(HERE / part) if source.is_relative_to(HERE / part) else Path('support') / source.name
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                assert target.read_bytes() == source.read_bytes(), 'Archive is immutable: ' + str(target)
            else:
                shutil.copyfile(source, target)
            key = relative.with_suffix('').as_posix().replace('/', '-').replace('_', '-')
            evidence[key] = register('saved-' + part + '-' + key, target, 'evidence/' + relative.as_posix())
        current = GHOST / 'states' / d['dir']
        current.mkdir(parents=True, exist_ok=True)
        helpers = ['point_body.gd', 'line_skin.gd', 'trace_archive.gd'] if part == 'trace' else ['line_skin.gd', 'trace_archive.gd']
        helper_ids = {}
        for name in [part + '.gd'] + helpers:
            target = current / name
            shutil.copyfile(HERE / part / name, target)
            tail = {'point_body.gd': 'body', 'line_skin.gd': 'skin', 'trace_archive.gd': 'archive'}.get(name, 'code')
            id = register(d['state'] + '-' + tail, target)
            if name in helpers: helper_ids[name] = id
        shutil.copyfile(HERE / part / 'tutorial.md', current / 'tutorial.md')
        brief = {k: d[k] for k in ['bring', 'make', 'given', 'build', 'check', 'later']}
        state = {'id': d['state'], 'map': d['map'], 'title': d['title'], 'status': 'verified', 'predecessor': d['predecessor'],
            'brief': brief, 'subjects': d['subjects'], 'carry': d['carry'], 'nextStatus': d['next'],
            'provenance': 'Exact printed source plus declared predecessor edits, executed in native Godot. Trace saves the actual held-point drawing; Grid loads the same sculpture in a separate process. PointBody and LineSkin remain unchanged. Same working museum project; synthetic controller evidence, not a human submission.',
            'code': d['state'] + '-code', 'incomingSha256': report['incoming_sha256'], 'outgoingSha256': report['learner_source_sha256'],
            'changes': read(HERE / part / 'operations.json'), 'givenFiles': helper_ids,
            'files': [d['state'] + '-code', *helper_ids.values(), d['state'] + '-brief', *evidence.values()],
            'evidence': {'report': evidence['report-runtime'], 'contract': evidence['contract'], 'expected': evidence['expected'], 'nextInput': evidence['next-input'], 'tutorial': evidence['tutorial'],
                'negativeControl': 'The same normal assertions detect both declared faults.', 'negativeControls': [n['name'] for n in report['negative_controls']]}}
        save(current / 'brief.json', {k: state[k] for k in ['map', 'status', 'predecessor', 'provenance', 'brief', 'carry', 'nextStatus']})
        register(d['state'] + '-brief', current / 'brief.json')
        manifest['states'][next(i for i, s in enumerate(manifest['states']) if s['id'] == d['state'])] = state
        with zipfile.ZipFile(HERE / (part + '-files.zip'), 'w', zipfile.ZIP_DEFLATED) as bundle:
            for name in [part + '.gd'] + helpers: bundle.write(HERE / part / name, name)
            if part == 'trace':
                for p in (HERE / part / 'variants').glob('*.gd'): bundle.write(p, p.name)
            else: bundle.write(HERE / part / 'flat_y.gd', 'flat_y.gd')
    manifest['files'] = list(entries.values())
    for planned in manifest['planned']:
        if planned['map'] == 'Primitives_Triangle': planned['map'] = 'Point_Triangle_Context'
    manifest['summary'] = 'Build and carry the point; reuse its class; record and save a gesture in Trace; meet that same drawing as a sculpture in Grid. Five tested states inside the Endless Museum, with full printed code and a verified saved-data handoff.'
    save(GHOST / 'manifest.json', manifest)

    lineage_path = ROOT / 'doc/book/course/hall-cards/lineage-opening.json'
    lineage = read(lineage_path)
    story_path = ROOT / 'doc/book/course/storyboards/opening.json'
    stories = read(story_path)
    summary_path = ROOT / 'doc/book/course/hall-cards/final-summaries-opening.json'
    summaries = read(summary_path)
    for part, d in LESSONS.items():
        card = api('tutorial-cards')
        api('tutorial-cards', {'revision': card['revision'], 'map': d['map'], 'subjects': d['subjects'], 'focus': d['build']})
        row = next(r for r in lineage['halls'] if r['map'] == d['map'])
        row.update(subjects=d['subjects'], focus=d['build'], carries=d['carry'], status='aligned',
            review='6 October author correction: bring the actual saved drawing into the next museum hall. Native source-bound tests and actual-hall checks pass; headset and human learning not tested.',
            revision_report=REL + '/index.html', tutorial_sha256_after=sha(ROOT / f'commons/maps/{d["map"]}/tutorial.md'))
        for sequence in stories:
            for hall in sequence['halls']:
                if hall['id'] == d['map']:
                    hall.update(storyboard=d['summary'], storyboard_short=d['short'], learns=d['subjects'], carries=d['carry'], brings=[d['bring']], supplied=[d['given']], review_note=row['review'])
        summary = next(s for s in summaries['summaries'] if s['map'] == d['map'])
        summary.update(summary=d['reflection'], source_sha256=sha(ROOT / f'commons/maps/{d["map"]}/final.md'))
        plan = api('tutorial-plan')
        lesson = next(l for l in plan['plan']['lessons'] if l['id'] == d['map'])
        lesson.update(object=d['make'], change=d['build'], given=d['given'], reuses=d['bring'], later=d['later'], carry=d['carry'], summary=d['summary'], next=d['next'], transfer=d['check'],
            checks=[str(len(reports[part]['checks'])) + ' native assertions pass on exact printed code; 10 producer assertions also appear in the companion report.',
                'Trace release saves the existing geometry and local positions. Grid loads the same file in another engine process and preserves it while changing an independent copy.',
                'Both deliberate faults fail ordinary assertions. Actual museum hall checks pass with synthetic input; headset experience and student understanding remain untested.'],
            notes='6 October corrected saved-sculpture handoff, selected by author. Final text also carries the gesture between halls. Report: ' + REL + '/index.html')
        api('tutorial-plan', {'kind': 'lesson', 'revision': plan['revision'], 'record': lesson})
    save(lineage_path, lineage); save(story_path, stories); save(summary_path, summaries)

    revisions_path = ROOT / 'doc/book/course/execution-plan/authorized-revisions.json'
    revisions = read(revisions_path); baseline = read(revisions_path.with_name('protected-sources.json'))
    for d in LESSONS.values():
        for name in ['tutorial.md', 'final.md']:
            path = f'commons/maps/{d["map"]}/{name}'
            revisions[path] = {'date': '2026-10-06', 'before': baseline[path], 'after': sha(ROOT / path),
                'reason': 'Author explicitly requested carrying saved hand-movement data and the existing drawing from Trace into Grid as a sculpture, and adding that continuity to final.md. Full printed tutorial code passes cross-process native assertions; museum runtime unchanged.'}
    save(revisions_path, revisions)
    update_memory()
    # README is live repository documentation, not an immutable native report.
    for item in manifest['files']:
        if item['path'] == 'README.md': item['sha256'] = sha(GHOST / 'README.md')
    save(GHOST / 'manifest.json', manifest)
    save(HERE / 'publication.json', {'passed': True, 'trace_checks': 134, 'grid_checks': 53, 'shared_producer_checks': 10, 'distinct_native_checks': 177, 'negative_controls': 4,
        'museum_checks': sum(len(r['checks']) for r in museum.values()), 'same_saved_file': True, 'unchanged_PointBody_and_LineSkin': True,
        'final_sources': {d['map']: sha(ROOT / f'commons/maps/{d["map"]}/final.md') for d in LESSONS.values()}})
    print('Published corrected Trace/Grid code, two reflections, Ghost states, cards, summaries and execution plan.')

def update_memory():
    entry = '6 October CURRENT AUTHOR DIRECTION — WORK INSIDE ENDLESS MUSEUM. Trace saves hand-movement positions AND its existing segment drawing on release. Grid LOADS that sculpture: no new sphere, gesture or geometry lesson. Preserve pink original/data/file; derive only an independent green copy. Same project, PointStudy-local metres, no timestamps. Both final.md chapters now carry this gesture between halls. [Current report](../../iterations/2026-10-06-trace-saved-to-grid/index.html). Native Trace 134 / Grid 53 checks (10 shared; 177 distinct), four detected faults; separate-process actual-museum handoff also passes. Earlier same-station Grid proposal below is superseded. Next: Point_Triangle_Context.\n\n'
    p = ROOT / 'doc/book/course/storyboards/CONTEXT.md'; text = p.read_text(encoding='utf-8-sig')
    if entry not in text: text = text.replace('## Keep in memory\n\n', '## Keep in memory\n\n' + entry)
    write(p, text)
    p = ROOT / 'doc/book/course/functional_text/RECONSTRUCTION.md'; text = p.read_text(encoding='utf-8-sig')
    start = text.index('## Current handoff: Trace → Grid'); end = text.index('## What the small checker does', start)
    text = text[:start] + '''## Current handoff: Trace → Grid

Trace saves both its ordered local positions and the segment drawing already built from them when the point is released. Grid runs in the next museum hall and loads that sculpture. It creates no new point and asks for no repeated gesture. The original stays pink; only a separately owned green copy is placed at rounded grid addresses. The file, source values and original geometry stay intact. The prepared archive is printed support; the new lessons remain recording, traversal and interpreting a retained record.

The transport uses the same Godot project's `user://ada_student_trace.scn`, PointStudy-local metres and no timestamps. A later valid release replaces the file. An empty save leaves the previous record alone; an absent file makes Grid ask for Trace. The archive packs static meshes so loading does not rerun a constructor that could alter their dimensions.

[Current evidence](../../iterations/2026-10-06-trace-saved-to-grid/index.html): Trace 134 and Grid 53 native assertions, with 10 shared producer assertions (177 distinct); four faults detected. Separate engine processes also save and receive the same file inside the actual museum halls. Temporary placement and synthetic hand input are declared. Physical headset use and learner understanding remain untested.

Next: Point_Triangle_Context selects three valid positions from the source. Declare the boundary/face operation before extending the full lesson. The previous same-running-station Grid proposal is superseded.

''' + text[end:]; write(p, text)
    p = ROOT / 'doc/book/course/COURSE_WORLD.md'; text = p.read_text(encoding='utf-8-sig')
    entry = '''## Current saved drawing — 6 October

The author's correction is explicit: save the hand movement in Trace and place its drawing as a sculpture in Grid. The current class-based lessons do this inside the existing museum. They carry the saved geometry as well as the position record. Grid introduces no replacement point or new drawing. [Actual museum images, complete lessons and assertions](../iterations/2026-10-06-trace-saved-to-grid/index.html).

The learner study is temporarily hosted at hall-local (8.5,0,8.5), unit scale, in each actual hall for the integration check. Rooms, artifacts, lighting and player belong to the museum. Native source tests and this separate-process hall check pass; physical headset use remains untested. The tutorial makes this available in the student's working copy; it does not permanently add another artifact to the shipped map. Earlier starter and existing-artifact pilots below are historical course versions.

'''
    if entry not in text: text = text.replace('## Day Zero establishes the environment\n', entry + '## Day Zero establishes the environment\n')
    write(p, text)
    p = ROOT / 'doc/book/course/execution-plan/README.md'; text = p.read_text(encoding='utf-8-sig')
    text = re.sub(r'^2\. \*\*Trace → Grid completed.*$', '2. **Trace → Grid completed and corrected, 6 October.** [Current lesson and evidence](../../iterations/2026-10-06-trace-saved-to-grid/index.html): save the actual hand-movement record and existing drawing in Trace; load it as a sculpture in Grid. Compare an independently owned copy without redrawing or changing the source. Trace 134 / Grid 53 native checks include 10 shared producer assertions; four deliberate faults are detected. Separate actual-museum runs receive the same saved file. Triangle is next.', text, flags=re.M)
    text = text.replace('The current exceptions are the 6 October Godot Primitives teaching-intent revision and the user-requested complete Trace → Grid tutorial.', 'The five current exceptions are the selected Godot Primitives teaching intent, the two complete Trace/Grid tutorials and their two user-requested reflective transitions.')
    write(p, text)
    p = ROOT / 'doc/book/course/execution-plan/REVIEW.md'; text = p.read_text(encoding='utf-8-sig')
    text = re.sub(r'^6 October executable follow-through:.*$', '6 October executable follow-through, corrected by the author: [Trace saves; Grid receives](../../iterations/2026-10-06-trace-saved-to-grid/index.html). The same drawing crosses hall runs as saved geometry and local positions. Trace 134 / Grid 53 checks include 10 shared producer assertions; four faults are detected. Actual museum checks confirm the same file arrives. The first three Ghost states are unchanged. Headset use and learning remain untested; earlier review counts below are historical.', text, flags=re.M)
    write(p, text)
    p = GHOST / 'README.md'; text = p.read_text(encoding='utf-8-sig')
    entry = '## Current continuation — 6 October\n\nTrace now saves its actual hand-movement record and segment sculpture on release. Grid loads that saved work in the next museum hall; it makes no new point. Both complete tutorials, contracts and native results are in `evidence/2026-10-06-trace-saved-to-grid/`. Trace 134 / Grid 53 checks include 10 shared producer checks. Earlier evidence remains immutable. Current manifests and live source checks determine validity; older counts and same-station descriptions below are historical.\n\n'
    if entry not in text: text = text.split('\n', 1)[0] + '\n\n' + entry + text.split('\n', 1)[1].lstrip('\n')
    write(p, text)

if __name__ == '__main__': main()
