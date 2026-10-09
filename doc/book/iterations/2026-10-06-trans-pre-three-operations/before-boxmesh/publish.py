from pathlib import Path
import json, hashlib, shutil, urllib.request, zipfile, difflib, re, html
import markdown
from write_lesson import HERE, ROOT, put

REL = HERE.relative_to(ROOT).as_posix()
BASE = 'http://localhost:3003'
SUBJECTS = ['Translation: position', 'Rotation: orientation and an axis', 'Uniform scale: size and proportion', 'Node origin', 'Animation: a transform changing over time']
SUMMARY = 'Return to CubeBody from Cube and Melencolia. Set its position, Y orientation and uniform scale separately, restoring the initial values between comparisons. Keep the same corner and face data; identify what each transform preserves. Locate the bottom-centre origin so scaling has an explicit anchor. Then let elapsed seconds carry the cube upward in one finite linear journey. Change the duration without changing the destination; combine a fixed turn and size with that translation. Choose another angle and predict which corner moves and which distance stays fixed. The museum supplies the surrounding room and installed pickups. Carry three distinct operations on one construction.'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p, v): put(p, json.dumps(v, ensure_ascii=False, indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def api(route, body=None):
    req = urllib.request.Request(BASE+'/api/'+route, data=None if body is None else json.dumps(body).encode(), headers={'Origin': BASE, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=60) as response: return json.load(response)

def main():
    verified = read(HERE/'verification.json')
    assert verified['passed']
    for p, h in verified['inputs'].items(): assert sha(ROOT/p) == h, p
    assert read(HERE/'museum/report.json')['passed']
    # API writes retain revision checking and existing author decisions.
    current = api('tutorial-cards')
    api('tutorial-cards', {'revision': current['revision'], 'map': 'Trans_Pre', 'subjects': SUBJECTS, 'focus': SUMMARY})
    current = api('tutorial-plan')
    row = next(r for r in current['plan']['lessons'] if r['id'] == 'Trans_Pre')
    row.update(summary=SUMMARY, given='Existing Endless Museum room, player, camera and light. Named TransformStudy root at floor level, zero rotation and unit scale. All three returning CubeBody support files are printed unchanged. The lesson creates its visible cube; installed pickup/collision behaviour remains supplied.',
               next='Author review of this completed lesson, then Trans_Introduction: compare three kinds of crossing.',
               notes='Written and tested 6 October: '+REL+'/index.html . 38 native checks; eight value-edited variants; three deliberate faults rejected. Exact printed program mounted temporarily in Trans_Pre for matched-view captures. Author decision remains editable. No headset or human-learning claim.')
    api('tutorial-plan', {'kind': 'lesson', 'revision': current['revision'], 'record': row})
    cards_path = ROOT/'doc/book/course/hall-cards/lineage-opening.json'
    cards = read(cards_path)
    for card in cards['halls']:
        if card['map'] == 'Trans_Pre':
            card.update(subjects=SUBJECTS, focus=SUMMARY, status='aligned', review='Complete printed example and unchanged returning helpers; 38 native checks and three fault controls. Review human understanding separately.', revision_report=REL+'/index.html', tutorial_sha256_after=sha(ROOT/'commons/maps/Trans_Pre/tutorial.md'))
    save(cards_path, cards)
    stories_path = ROOT/'doc/book/course/storyboards/opening.json'
    stories = read(stories_path)
    for sequence in stories:
        for hall in sequence['halls']:
            if hall['id'] == 'Trans_Pre':
                hall.update(storyboard=SUMMARY, learns=SUBJECTS, storyboard_short='BRING CubeBody. CHANGE position / Y turn / uniform size, separately. KEEP construction. ORIGIN bottom-centre. THEN clock one upward journey; same endpoint, new duration. TEST corners + distances + time. CARRY three transforms. GIVEN museum + installed pickups.')
    save(stories_path, stories)
    course = ROOT/'doc/book/course/execution-plan'
    path = 'commons/maps/Trans_Pre/tutorial.md'
    revisions = read(course/'authorized-revisions.json')
    protected = read(course/'protected-sources.json')
    revisions[path] = {'date': '2026-10-06', 'before': protected[path], 'after': sha(ROOT/path), 'reason': 'Author-approved transformation-first plan; first tutorial rewritten with complete CubeBody study, unchanged inherited helpers, native checks and deliberate faults. Reflection and museum map unchanged.'}
    save(course/'authorized-revisions.json', revisions)
    summaries_path = course/'TRANSFORMATION_SUMMARIES.md'
    original = summaries_path.read_text(encoding='utf-8')
    if not (HERE/'before/TRANSFORMATION_SUMMARIES.md').exists(): put(HERE/'before/TRANSFORMATION_SUMMARIES.md', original)
    text, n = re.subn(r'(## 1\. Trans_Pre[^\n]*\n\n).*?(?=\n## 2\.)', lambda m: m[1]+SUMMARY+'\n', original, flags=re.S)
    assert n == 1
    old = 'The existing tutorial.md files still need complete tested reconstructions.'
    text = text.replace(old, 'Trans_Pre now has a complete tested reconstruction: 38 native checks, eight variants and three deliberate faults. The remaining six tutorial.md files still need this pass.')
    text = text.replace('Begin with Trans_Pre\'s three operations, then add a clock. No tutorial manuscript, reflective text, illustration or museum code changed in this planning revision.', 'Continue with Trans_Introduction after reviewing [the first completed lesson](../../iterations/2026-10-06-trans-pre-three-operations/index.html). Only Trans_Pre tutorial.md has been rewritten so far; the planning review remains an earlier snapshot.')
    put(summaries_path, text)
    request = urllib.request.Request(BASE+'/api/tutorial-plan?download=summaries')
    with urllib.request.urlopen(request, timeout=60) as response: put(course/'lesson-summaries.txt', response.read().decode('utf-8'))
    context = ROOT/'doc/book/course/storyboards/CONTEXT.md'
    text = context.read_text(encoding='utf-8')
    heading = '## Trans_Pre — first tutorial rewritten, 6 October'
    if heading not in text:
        put(context, text+'\n\n'+heading+'\n\nFirst Transformation lesson now prints a 22-line main and the unchanged CubeBody/FaceBody/LineSkin files from Cube. Static position, Y turn and uniform size precede one finite timed translation. CubeBody has a bottom-centre origin; do not describe scaling around the volume centre. 38 native checks, eight variants and three deliberate faults pass/reject as expected. The exact program was temporarily mounted in Trans_Pre for real museum captures. Canonical tutorial, cards, plan, summaries and Ghost Student state are synchronized; final.md and map_data.json are preserved. Review: '+REL+'/index.html. Author acceptance and human understanding remain open. Next: Trans_Introduction, three ways of making a crossing; use the familiar constructions and declare collision/rider support supplied.\n')
    publish_ghost(verified)
    make_pages(verified)
    before_plan = read(HERE/'before/doc/book/course/execution-plan/plan.json')
    after_plan = read(course/'plan.json')
    assert all(next(r for r in after_plan['lessons'] if r['id']==old['id']) == old for old in before_plan['lessons'] if old['id'] != 'Trans_Pre')
    assert all(sha(ROOT/'commons/maps/Trans_Pre'/name) == sha(HERE/'before/commons/maps/Trans_Pre'/name) for name in ['final.md', 'map_data.json'])
    save(HERE/'publication.json', {'passed': True, 'only_plan_lesson_changed': 'Trans_Pre', 'final_and_map_preserved': True, 'tutorial_sha256': sha(ROOT/path)})
    print('Published Trans_Pre; other six lessons remain for subsequent passes.')

def publish_ghost(verified):
    ghost = ROOT.parent/'ada_encyclopedia/ghost-student'
    manifest = read(ghost/'manifest.json')
    backup = HERE/'before/ghost-manifest.json'
    if not backup.exists(): shutil.copyfile(ghost/'manifest.json', backup)
    entries = {r['id']: r for r in manifest['files']}
    sid = 'transformation-pre'
    previous = next(r for r in manifest['states'] if r['id'] == 'primitives-composition')
    incoming = (ghost/entries[previous['code']]['path']).read_text(encoding='utf-8')
    source = (HERE/'lesson.gd').read_text(encoding='utf-8')
    operation = {'id': 'next-museum-study', 'kind': 'replace', 'before': incoming, 'after': source}
    pins = verified['inputs']
    helpers = [HERE/n for n in verified['unchanged_helpers']]
    native = read(HERE/'normal-report.json')
    negatives = [{'name': name, 'expected_failure_detected': True, 'expected_failure_ids': [fault['required_failure']], 'normal_contract_result': read(HERE/(name+'-report.json'))} for name, fault in verified['faults'].items()]
    incoming_sha = hashlib.sha256(incoming.encode()).hexdigest()
    contract = {'incoming': {'sha256': incoming_sha}, 'operations': [operation], 'given_files': [{'path': p.name, 'sha256': sha(p)} for p in helpers], 'sources': [{'path': p, 'sha256': h} for p, h in pins.items()], 'checks': [{'id': c['id'], 'kind': 'native'} for c in native['checks']], 'evidence_inputs': list(pins)}
    save(HERE/'contract.json', contract)
    save(HERE/'next-input.json', {'incoming': {'sha256': sha(HERE/'lesson.gd')}, 'carry': 'CubeBody construction, three transforms, one finite timed translation.'})
    dependencies = {p.relative_to(ROOT).as_posix(): sha(p) for p in helpers}
    save(HERE/'ghost-report.json', {**native, 'inputs': pins, 'dependencies': dependencies, 'learner_source_sha256': sha(HERE/'lesson.gd'), 'incoming_sha256': incoming_sha, 'negative_control': negatives[0], 'negative_controls': negatives, 'scope': verified['scope']})
    dest = ghost/'states/015-transformation-pre'
    dest.mkdir(parents=True, exist_ok=True)
    file_ids = {}
    for p in [HERE/'lesson.gd', *helpers, HERE/'tutorial.md', HERE/'contract.json', HERE/'next-input.json', HERE/'ghost-report.json']:
        target = dest/p.name
        shutil.copyfile(p, target)
        fid = sid+'-'+p.stem.replace('_', '-')
        file_ids[p.name] = fid
        entries[fid] = {'id': fid, 'path': target.relative_to(ghost).as_posix(), 'label': p.name, 'language': {'.gd': 'gdscript', '.json': 'json', '.md': 'markdown'}[p.suffix], 'sha256': sha(target)}
    state = {'id': sid, 'map': 'Trans_Pre', 'title': 'Move, turn, change size', 'status': 'verified', 'predecessor': previous['id'],
             'brief': {'bring': 'Unchanged CubeBody construction used in Cube and Melencolia.', 'make': 'Three static changes, then one timed translation.', 'given': 'Museum host; printed returning geometry files.', 'build': SUMMARY, 'check': '38 native checks, eight variants, three deliberate faults.', 'later': 'Continuous turning, pulsing, crossing collision and rider transport.'},
             'subjects': SUBJECTS, 'carry': 'Position, orientation and scale change while local construction stays fixed.', 'nextStatus': 'Read and review; then three crossings in Trans_Introduction.',
             'provenance': 'Main script explicitly replaces the preceding composition study. CubeBody and its geometry helpers are byte-identical to their printed Cube versions. Class reuse is not a claim that one live node persists across halls. Native Godot execution and temporary museum captures; no human or physical-headset test.',
             'code': file_ids['lesson.gd'], 'incomingSha256': incoming_sha, 'outgoingSha256': sha(HERE/'lesson.gd'), 'changes': [operation], 'givenFiles': {p.name: file_ids[p.name] for p in helpers}, 'files': list(file_ids.values()),
             'evidence': {'report': file_ids['ghost-report.json'], 'contract': file_ids['contract.json'], 'expected': file_ids['lesson.gd'], 'nextInput': file_ids['next-input.json'], 'tutorial': file_ids['tutorial.md'], 'negativeControl': 'Wrong rotation axis, frame-count clock and accumulating position fail the ordinary contract.', 'negativeControls': [n['name'] for n in negatives]}}
    manifest['states'] = [s for s in manifest['states'] if s['id'] != sid] + [state]
    manifest['files'] = list(entries.values())
    manifest['planned'] = [r for r in manifest.get('planned', []) if r.get('map') != 'Trans_Pre']
    manifest['summary'] = 'Fifteen tested learner states: point, pickup, lines, saved trace, Grid, nine Primitives continuations, and the first Transformation study. Returning constructions, explicit main-program replacements, exact printed code and native evidence.'
    save(ghost/'manifest.json', manifest)

CSS = '''*{box-sizing:border-box}body{margin:0;background:#f3f0e9;color:#22221f;font:19px/1.65 Georgia,serif}main{max-width:1160px;margin:auto;padding:55px 38px}.reading{max-width:900px}h1{font-size:clamp(38px,6vw,68px);font-weight:400;line-height:1.05}h2{font-weight:400;font-size:31px;line-height:1.2;margin-top:45px}h3{font:600 17px system-ui}a{color:inherit}nav,.meta,figcaption,button{font:14px/1.6 system-ui}nav{display:flex;gap:20px;flex-wrap:wrap;margin:25px 0}.meta{color:#625e54}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:0}img{width:100%;display:block}figcaption{padding:10px 0}pre{background:#222528;color:#f6f2e9;overflow:auto;padding:25px;font:14px/1.55 Consolas,monospace}code{font-family:Consolas,monospace;font-size:.88em}pre code{font-size:inherit}table{border-collapse:collapse;width:100%;font-size:16px}td,th{border-bottom:1px solid #c8c2b6;text-align:left;vertical-align:top;padding:10px}li{margin:8px 0}summary{cursor:pointer}details{margin:35px 0}.note{border-block:1px solid #c4bcae;padding:20px 0}@media(max-width:700px){main{padding:28px 20px}.gallery{grid-template-columns:1fr}table{font-size:14px}}'''
def shell(title, body, reading=False):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+CSS+'</style><main'+(' class="reading"' if reading else '')+'>'+body+'</main></html>'

def render(text, origin):
    body = markdown.markdown(text, extensions=['fenced_code', 'tables'])
    def link(m):
        value = m[1]
        if ':' in value or value.startswith(('#', '/')): return m[0]
        full = (origin/value.split('#')[0]).resolve()
        if not full.is_relative_to(ROOT): return m[0]
        fragment = '#'+value.split('#', 1)[1] if '#' in value else ''
        return 'href="/book-review/'+full.relative_to(ROOT).as_posix()+fragment+'"'
    return re.sub(r'href="([^"]+)"', link, body)

def make_pages(verified):
    for variant in ['lesson', *verified['variants']]:
        target = HERE/'lesson-files.zip' if variant == 'lesson' else HERE/'variants'/variant/'code.zip'
        folder = HERE if variant == 'lesson' else HERE/'variants'/variant
        with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
            for name in ['lesson.gd', *verified['unchanged_helpers']]: archive.write(folder/name, name)
    tutorial = (ROOT/'commons/maps/Trans_Pre/tutorial.md').read_text(encoding='utf-8')
    before = (HERE/'before/commons/maps/Trans_Pre/tutorial.md').read_text(encoding='utf-8')
    put(HERE/'tutorial.diff', ''.join(difflib.unified_diff(before.splitlines(True), tutorial.splitlines(True), fromfile='before/tutorial.md', tofile='after/tutorial.md')))
    nav = '<nav><a href="index.html">Review</a><a href="lesson-files.zip">Download all four code files</a><a href="final.html">Read the reflection</a><a href="/ghost-student?state=transformation-pre">Tested learner state</a></nav>'
    put(HERE/'tutorial.html', shell('Trans_Pre — Move, turn, change size', nav+render(tutorial, ROOT/'commons/maps/Trans_Pre'), True))
    put(HERE/'before.html', shell('Earlier Trans_Pre tutorial', '<nav><a href="index.html">Review</a><a href="tutorial.html">New tutorial</a></nav>'+render(before, ROOT/'commons/maps/Trans_Pre'), True))
    put(HERE/'final.html', shell('Trans_Pre — Reflection', nav+render((ROOT/'commons/maps/Trans_Pre/final.md').read_text(encoding='utf-8'), ROOT/'commons/maps/Trans_Pre'), True))
    body = '''<p class="meta">ENDLESS MUSEUM · TRANSFORMATION 01 · 6 OCTOBER 2026</p><h1>One cube.<br>Three kinds of change.</h1><p>The first tutorial is rewritten. Keep the cube built in Primitives; change its position, orientation and size separately. Then give one translation a duration.</p><nav><a href="tutorial.html">Read the complete tutorial</a><a href="lesson-files.zip">Download code</a><a href="final.html">Reflection</a><a href="/tutorial-plan?map=Trans_Pre&view=summaries">Editable plan</a></nav><p class="note"><strong>38 native Godot checks pass. Three deliberate faults are rejected.</strong><br><span class="meta">Eight code variants, unchanged returning geometry files, one explicit museum study host.</span></p><h2>Same construction, changed pose</h2><p>The large pale cube is the learner study, placed temporarily in the real Trans_Pre hall. Camera position stays fixed across these captures. Installed exhibits remain around it.</p><div class="gallery">'''
    captions = {'still': 'Starting pose · one-metre edges.', 'translate': 'Translate · one metre along X. Same facing and size.', 'turn': 'Rotate · 45° around Y. Same distances between corners.', 'scale': 'Uniform scale · factor 1.5. Bottom-centre origin stays fixed.', 'rise': 'Timed translation · halfway through the two-second rise.'}
    for variant in ['still', 'translate', 'turn', 'scale']:
        body += '<figure><a href="museum/'+variant+'.png"><img src="museum/'+variant+'.png" alt="'+html.escape(captions[variant])+'"></a><figcaption>'+captions[variant]+'</figcaption></figure>'
    body += '</div><h2>What changed in the writing</h2><p>The earlier tutorial began with stages, a clock and cumulative animation. The revised lesson begins with the three transformations and what each preserves. The 22-line main is complete; CubeBody and its two support files return unchanged and are printed in full. Scaling is explicitly anchored at the bottom centre.</p><p>Time enters after the still comparisons. The first journey goes upward once and stops. Continuous turning and pulsing remain visible in the museum and become subjects in later halls.</p><nav><a href="before.html">Earlier text</a><a href="tutorial.html">Rewritten text</a><a href="tutorial.diff">Exact text changes</a></nav><h2>Try a variation</h2><p>Each download contains the complete four-file version for the same TransformStudy host.</p><nav>'
    for variant in verified['variants']:
        body += '<a href="variants/'+variant+'/code.zip">'+variant+'</a>'
    body += '</nav><details><summary>What the tests establish</summary><p>Code is extracted from tutorial.md unchanged and executed in Godot 4.6. Assertions compare actual transformed corner positions, all corner-pair distances, fixed construction data and the same journey at 30 and 120 updates per second. The engine also calls _process normally. Separate wrong-axis, frame-clock and accumulating-position mutations must fail those same checks.</p><p>The real-hall captures add placement and rendering evidence. Physical headset use and human understanding remain untested. Museum logs contain existing unrelated warnings; this pass does not certify the whole project.</p><nav><a href="verification.json">Source-bound verification</a><a href="normal-report.json">38 assertions</a><a href="museum/report.json">Museum mounting</a><a href="/ghost-student?state=transformation-pre">Ghost Student</a></nav></details><p class="meta">Trans_Pre tutorial updated. Reflection and map layout preserved. The remaining six Transformation lessons follow one at a time.</p>'
    put(HERE/'index.html', shell('Trans_Pre — Three operations', body))

if __name__ == '__main__': main()
