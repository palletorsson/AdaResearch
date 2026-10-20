from pathlib import Path
from html.parser import HTMLParser
import copy, difflib, hashlib, html, json, re, shutil, zipfile
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-09-assemblage-the-choices-remain'
M = R / 'commons/maps/Assemblage_Same_Desire'
RUN = R / 'ada_run/encounter_pilot/Assemblage_Same_Desire'

def write(p, s): p.write_bytes(s.encode('utf-8'))
def dump(p, d): write(p, json.dumps(d, ensure_ascii=False, indent=2) + '\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

code = json.loads((O/'checks.json').read_text())
room = json.loads((RUN/'report.json').read_text())
before = json.loads((O/'before/hashes.json').read_text())
assert code['passed'] and room['passed']
for p in [O/'engine.log', RUN/'engine.log']:
    assert not any(t in p.read_text(encoding='utf-8', errors='replace') for t in ['SCRIPT ERROR', 'Parse Error'])
n, q = len(code['checks']), len(room['checks'])
samples = room['observations']['route_samples']
protected = [p for p in before if p.startswith('commons/artifacts/')]
protected += ['commons/maps/Assemblage_Same_Desire/map_data.json', 'commons/maps/sequences/lsystems.json']
for name in protected: assert sha(R/name) == before[name], name
runtime = 'commons/data/museum/em_plan.json'
old = json.loads((O/'before'/runtime).read_text())
current = json.loads((R/runtime).read_text())
old_row = next(x for x in old['plans'] if x['map'] == 'Assemblage_Same_Desire')
new_row = next(x for x in current['plans'] if x['map'] == 'Assemblage_Same_Desire')
assert old_row == new_row
for folder in ['assets', 'museum', 'after', 'probes']: (O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'): shutil.copyfile(p, O/'assets'/p.name)
for name in ['report.json', 'engine.log', 'source_manifest.json']: shutil.copyfile(RUN/name, O/'museum'/name)
dump(O/'after/runtime-row.json', new_row)

p = R/'doc/book/course/execution-plan/plan.json'
plan = json.loads(p.read_text(encoding='utf-8')); prior = copy.deepcopy(plan)
row = next(x for x in plan['lessons'] if x['id'] == 'Assemblage_Same_Desire')
decision = row['decision']
row.update(
    object='The installed two-mark textile, its held witness and floor drawing; reconstruct the comparison with the carried PointBody.',
    change='Retain random samples and tint draws; change threshold decisions and their glyphs independently. Keep a deep snapshot with its alphabet; advance one bounded row.',
    dependsOn=['Randomness_10_PRINT_Algorithm', 'LSystems_Grammars_And_Curves', 'LSystems_Living', 'LSystems_Shape_Grammars'],
    reuses='RandomNumberGenerator, two-dimensional arrays, strict comparisons, dictionaries, deep copies, BoxMesh, transforms and the unchanged PointBody.',
    given='Prepared Endless Museum camera, floor, player and XRTools. Three complete printed files construct all new sheets, marks and controls. Existing six-button desk remains the full installed interaction.',
    later='No pathfinding, connectivity graph, cell-neighbour rule, RNG-state checkpoint, disk persistence or floor-mark collision. The study is a bounded 12 by 12 reconstruction.',
    checks=[f'{n} exact-printed native checks;30 source comparisons; complete reversed-block-size variation; shallow-snapshot and redraw-on-alphabet faults rejected.', f'{q} native museum checks including ten camera checks, six actual button effects, supplied XRTools poses,51 supported floor samples and {samples} supported right-route samples.'],
    transfer='In glyph(), exchange the large/small block sizes. Predict unchanged samples, choices, count, colour and addresses; execute the whole edited program and inspect the reversed emphasis.',
    carry='Keep samples, decisions, marks and perceived paths distinct. A saved witness includes the interpretation needed to reconstruct its visible state.',
    next='The eight-hall L-systems reading is ready for review; procedural generation follows in the spine.',
    notes='Final L-systems hall reconstructed. Draft decision retained. Production artifacts, authored map and runtime row unchanged. Student installation is temporary in a checked side bay. Right bypass tested; two rejected left-route probes retained. No headset or independent-student acceptance.',
    summary='Return to the two-mark textile. Hold a witness, change its alphabet, then change the threshold against the same samples. Reconstruct the comparison with three complete files and the familiar point. Keep sample draws, decisions and visible marks separate; a deep snapshot keeps its own alphabet and a twelve-row queue retains eleven rows when stepping. Exchange only the large and small block sizes. Predict and verify the same choices, count, colours and positions with another visual emphasis. Carry the distinction between a generated record, its interpretation and a path someone recognises.')
assert row['decision'] == decision
assert all(a == b for a,b in zip(prior['lessons'], plan['lessons']) if a['id'] != 'Assemblage_Same_Desire')
assert all(prior[k] == plan[k] for k in prior if k != 'lessons')
# Use actual existing IDs for the inherited two-mark lesson.
ids = {x['id'] for x in plan['lessons']}
assert all(x in ids for x in row['dependsOn']), row['dependsOn']
dump(p, plan); dump(O/'after/lesson-plan.json', row)

tech = (O/'before/commons/maps/Assemblage_Same_Desire/technical.md').read_text(encoding='utf-8') + f'''

## Reconstructed tutorial — 9 October 2026

Three complete files: sheet.gd, assemblage.gd and byte-unchanged Living point_body.gd. Each cell records two draws in production order: sample then tint. A strict sample < odds produces the Boolean decision; glyph maps that decision to the installed diagonal/orthogonal/block geometry. Reinterpretation consumes no draws. Keep deep-copies rows, alphabet, odds and seed; it is a visible-record snapshot, not an RNG-state checkpoint or persistent file. Twelve rows of twelve cells; index zero is oldest/bottom. Step drops one row and appends one, preserving eleven. The engine's RNG algorithm/call order matter for seed replay; saved-opening.json includes the actual opening samples and tints.

The learner draws editable and held sheets plus a smaller floor, with flat colours rather than the source's glow. Floor row zero is at the far edge; each glyph lies flat, but the complete wall sheet is not rigidly rotated as one object. Neither drawing nor backing adds a collider. The museum floor supplies support. Familiar point trigger cycles ALPHABET; moving alone edits nothing; release parks at local(0,1.15,1.1). Keys A/O/H/Space/N/R cover all six operations. A tested temporary working-copy bay is hall-local(3.2,0,7.5), yaw180, unit scale; approach(3.2,0,5.7). No permanent duplicate artifact was installed.

{n} native exact-printed assertions pass, including30 source comparisons over two seeds, three alphabets and five thresholds. Every cell's sample, tint, choice, glyph size and angle agree. Initial1010/.5 gives83 A cells; .75 gives116 in the installed study. Tests cover strict threshold equality, generator-state retention, row survival and forty further steps, deep snapshot independence, floor mapping, keyboard and supplied XRTools poses under a transformed host. The complete student program swaps large/small block amounts, keeping data, colours and positions. Deliberate shallow-copy and redraw-on-alphabet variants are rejected. This does not establish arbitrary input handling or independent learner comprehension.

{q} native room checks pass, including ten cameras, nine authored artifact tokens present, six actual pointer button effects, held geometry persistence, printed/source sample equality, reachable bay, supplied pickup/action/release,51 supported floor samples across all alphabets and {samples} supported samples on the RIGHT bypass through both partitions to an aligned exit approach. First and second room probes each failed one route assertion: proposed left paths intersected existing fittings/partition trim. Those receipts/probes are retained. No collision geometry was changed and no left-route clearance is claimed. Entry/exit records were checked; full portal traversal was not.

Four baseline and ten final native images inspected. The main comparisons are legible; small distant labels overlap and a long overhead rail crosses the room views. The rear collection is retained as context, not all interactions accepted. Earlier GridSubstrateRunner/GridDataComponent limitations remain. Production textile and lesson scripts, map, canonical sequence and target runtime row are byte/structure unchanged. Existing UID/renderer diagnostics remain; accepted logs contain no SCRIPT ERROR or Parse Error. No headset, Quest-performance or independent ghost-student claim. HTML/code/link/ZIP checks are static, not browser layout verification.

final.md preserved except one sentence: the held witness keeps its alphabet as well as its choices. Review: doc/book/iterations/2026-10-09-assemblage-the-choices-remain/index.html. This completes the eight-hall L-systems tutorial reconstruction pass; review remains open.
'''
write(M/'technical.md', tech)
for name in ['tutorial.md', 'final.md', 'technical.md', 'map_data.json']:
    shutil.copyfile(M/name, O/name); shutil.copyfile(M/name, O/'after'/name)
    a = (O/'before/commons/maps/Assemblage_Same_Desire'/name).read_text(encoding='utf-8')
    b = (M/name).read_text(encoding='utf-8')
    write(O/'after'/(name+'.diff'), ''.join(difflib.unified_diff(a.splitlines(True), b.splitlines(True), fromfile='before/'+name, tofile='after/'+name)))

report = f'''# Assemblage — the choices remain

The final L-systems hall separates **samples → decisions → marks → perceived paths**. It returns to the installed textile and carries the familiar point into a small reconstruction beside it.

Hold the diagonal sheet. Change its alphabet: the same cells choose A and B, but their marks become horizontal/vertical bars or large/small blocks. Change the threshold and different samples choose A. Change the seed and the samples change. These are three different operations.

The full tutorial prints the record, renderer and carried PointBody. It explains deep snapshots, the two draws behind every cell, strict threshold comparison and the twelve-row queue. The student exchanges the block sizes and predicts what stays the same. The executed edit changes the emphasis while preserving all144 samples, decisions, colours and addresses.

|Part|Before|Now|
|---|---|---|
|Tutorial|An encounter outline around the installed desk|Complete three-file reconstruction, explained state and a tested student edit|
|Reflection|Separate choices and recognised paths|Preserved; one sentence makes the witness's alphabet explicit|
|Installed room|Comparison, floor and wider pattern collection|Same arrangement and artifact logic|
|Learner space|No tested placement for this program|A temporary side bay, photographed with the printed program|

**{n} printed-program checks pass**, including30 comparisons with source data/geometry and two rejected faulty implementations. **{q} museum checks pass**, including ten camera checks, all six desk buttons, supplied hand interactions and {samples} supported right-aisle route samples. The full reversed-size student program also ran in the museum.

Two earlier route assertions failed when proposed left-side paths intersected existing fittings or partition trim. The final check establishes a right-hand bypass and aligned exit approach. It does not establish that every possible route is clear. Receipts from both rejected attempts are included.

The floor repeats the decisions at declared addresses. Its marks add no collision: the museum floor still supports you. A path recognised in the pattern is not a pathfinding result. This is where the tutorial's material account meets the reflection without replacing it.

The native views include the installed comparison, its threshold change, the learner version and its complete edit, floor views, the rear collection and before/after overheads. Small distant labels overlap; a high rail crosses some views. Secondary artifact presence is recorded, not blanket acceptance of every interaction.

All eight L-systems halls now have this tutorial pass. The reports contain author-led native checks, not a new independent student review or physical-headset acceptance. The HTML/code/link/archive checks are static. Production artifacts, map and sequence order remain unchanged in this hall.
'''
write(O/'REPORT.md', report)
css = re.search(r'<style>(.*?)</style>', (R/'doc/book/iterations/2026-10-09-competition-the-next-turn/index.html').read_text(encoding='utf-8'), re.S).group(1)

def md(s):
    rendered = markdown.markdown(s, extensions=['fenced_code', 'tables', 'footnotes'])
    blocks = iter(re.findall(r'```gdscript\n(.*?)\n```', s, re.S))
    return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)', lambda m:m[1]+html.escape(next(blocks)+'\n')+m[2], rendered, flags=re.S)

def page(title, body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · L-systems 08 · 9 October 2026</p><nav><a href="index.html">Museum report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="assemblage-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot evidence · author-led checks · physical headset and independent student review remain open.</footer></body></html>'

def fig(path, caption):
    return '<figure><img loading="lazy" src="'+path+'" alt="'+html.escape(caption, quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'

texts = {name:(O/(name+'.md')).read_text(encoding='utf-8') for name in ['tutorial', 'final']}
for name,s in texts.items(): write(O/(name+'.html'), page(name, '<main><article>'+md(s)+'</article></main>'))
write(O/'parallel.html', page('Assemblage — facing pages', '<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(texts['tutorial'])+'</article><article><p class="eyebrow">Right · final.md</p>'+md(texts['final'])+'</article></main>'))
changes = '<main><h1>Before and after.</h1><p>The installed room and its artifact logic are retained.</p>'
for name in ['tutorial', 'final']:
    previous = (O/'before/commons/maps/Assemblage_Same_Desire'/(name+'.md')).read_text(encoding='utf-8')
    changes += '<h2>'+name+'.md</h2><div class="pair"><article>'+md(previous)+'</article><article>'+md(texts[name])+'</article></div>'
write(O/'changes.html', page('Before and after', changes+'</main>'))
body = '<main><h1>The choices<br>remain.</h1><p class="lead">Keep the sample. Change the decision. Change its mark. Notice which path you begin to see.</p>'
body += fig('assets/opening.png', 'The installed comparison and its desk. The held sheet keeps both its choices and its alphabet.')
body += '<div class="pair">'+fig('assets/alphabet.png', 'Same samples,83 of144 A choices. Orthogonal bars replace diagonals on the editable left sheet.')+fig('assets/threshold.png', 'Threshold0.75:116 A choices. The samples stay fixed; the held sheet stays at0.5.')+'</div>'
body += fig('assets/student.png', 'The full printed program in its temporary side bay, beside the installed comparison. The carried point changes the alphabet.')
body += '<div class="pair">'+fig('assets/student-blocks.png', 'Original block reader: A draws the large block, B the small one.')+fig('assets/student-reversed-blocks.png', 'Executed student edit: A draws the small block, B the large one. Data, count, positions and colours agree with the original program.')+'</div>'
body += '<div class="pair">'+fig('assets/floor.png', 'The installed floor drawing. It adds marks, not walls.')+fig('assets/student-floor.png', 'The learner floor uses the same recorded choices and tint values at half the installed spacing.')+'</div>'
body += '<div class="pair">'+fig('before-captures/above.png', 'Before: the existing arrangement, with the comparison first and the wider collection beyond the partition.')+fig('assets/above.png', 'After: same room; the small learner program occupies the side bay. No permanent duplicate was added.')+'</div>'
body += fig('assets/collection.png', 'The retained rear collection offers other encounters. These objects do not all become tutorial obligations.')
body += md(report)+'<p><a href="checks.json">Printed-code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="saved-opening.json">Actual opening record</a> · <a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflection Markdown</a></p></main>'
write(O/'index.html', page('Assemblage — the choices remain', body))
for name in ['assemblage_choices_before.gd', 'assemblage_choices_lesson.gd', 'assemblage_choices_room.gd']: shutil.copyfile(R/'tools/probes'/name, O/'probes'/name)
for name in ['test_assemblage_choices.py', 'write_assemblage_choices.py']: shutil.copyfile(R/'tools'/name, O/'probes'/name)
dump(O/'manifest.json', {'canonical':{name:sha(M/name) for name in ['tutorial.md','final.md','technical.md','map_data.json']}, 'printed':json.loads((O/'printed-hashes.json').read_text()), 'unchanged':{name:sha(R/name) for name in protected}, 'runtime_row_unchanged':True, 'checks':[n,q], 'source_comparisons':30, 'route_samples':samples, 'images':{'before':4, 'after':10}})
write(O/'README.txt', 'Open index.html for native museum views; parallel.html places tutorial left/reflection right. printed/ contains the exact three-file program; variation/ the complete reversed-block-size edit. wrong_alias/ and wrong_redraw/ are deliberate faulty implementations. Requires the prepared Endless Museum with XRTools, camera, floor and player, not an empty project. The learner program was run temporarily in a clear side bay. Production artifacts and map unchanged. Only the right bypass passed the complete route check; two rejected left-route attempts are retained. Author-led tests; no physical headset or independent-student acceptance.\n')
archive = O/'assemblage-review.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in O.rglob('*'):
        if p.is_file() and p.suffix not in ['.zip','.uid'] and p.name != 'validation.json':
            data = p.read_bytes()
            if p.suffix == '.html': data = data.replace(b'href="assemblage-review.zip"', b'href="README.txt"')
            z.writestr(p.relative_to(O).as_posix(), data)

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]
    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k,v in attrs if k in ['href','src'] and v)

refs=0
for p in O.glob('*.html'):
    parser=Links(); parser.feed(p.read_text(encoding='utf-8'))
    for v in parser.links:
        if v.startswith(('http:','https:','#','data:')): continue
        assert (p.parent/v.split('#')[0]).exists(), (p,v)
        refs+=1
rendered=[html.unescape(s) for s in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',(O/'tutorial.html').read_text(encoding='utf-8'),re.S)]
assert len(rendered)==3
for name,s in zip(['sheet.gd','assemblage.gd','point_body.gd'], rendered): assert s==(O/'printed'/name).read_text(encoding='utf-8')
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    members=set(z.namelist())
    for name in members:
        if '/' not in name and name.endswith('.html'):
            parser=Links(); parser.feed(z.read(name).decode('utf-8'))
            for v in parser.links:
                if not v.startswith(('http:','https:','#','data:')): assert v.split('#')[0] in members,(name,v)
dump(O/'validation.json',{'passed':True,'local_references':refs,'rendered_code_matches':3,'zip_crc':True,'zip_internal_refs':True,'zip_MB':round(archive.stat().st_size/1e6,2)})
print(json.dumps({'published':str(O/'index.html'),'checks':[n,q],'refs':refs,'zip_MB':round(archive.stat().st_size/1e6,2)}))
