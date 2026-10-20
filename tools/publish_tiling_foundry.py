"""Publish the Foundry continuation and its independently reconstructed evidence."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha, page as prior_page
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Foundry'
MAP=ROOT/'commons/maps/Pattern_Foundry'
def page(title,body,wide=False):return prior_page(title,body,wide).replace('tiling-disco-review.zip','tiling-foundry-review.zip')
def md(s):
    return markdown.markdown(s.replace('/book-images/iterations/2026-09-28-foundry-a-mark-in-the-room/room-pair.png','images/room-pair.png'),extensions=['fenced_code','tables','footnotes'])
def main():
    tests=json.loads((OUT/'tests.json').read_text());faults=json.loads((OUT/'mutations.json').read_text())
    run=ROOT/'ada_run/encounter_pilot/Pattern_Foundry/foundry-source-return'
    native=json.loads((run/'report.json').read_text())
    assert tests['all_passed'] and faults['all_rejected'] and native['passed']
    assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for p in run.iterdir():
        if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,museum/p.name)
    images=OUT/'images';images.mkdir(exist_ok=True)
    shutil.copy2(ROOT.parent/'ada_encyclopedia/public/book-images/iterations/2026-09-28-foundry-a-mark-in-the-room/room-pair.png',images/'room-pair.png')
    prediction=json.loads((OUT/'prediction.json').read_text())
    assert sha(MAP/'tutorial.md')==prediction['source_sha256']
    tracks={};diffs=[]
    for name in ['tutorial','final']:
        text=(MAP/(name+'.md')).read_text(encoding='utf8');tracks[name]=text
        (OUT/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page('Pattern Foundry / '+name,md(text)),encoding='utf8')
        before=(OUT/'before'/(name+'.md')).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='before/'+name+'.md',tofile='after/'+name+'.md'))
        (OUT/(name+'.diff')).write_text(diff,encoding='utf8');diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(diff)}</pre>')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==4
    for name,code in blocks.items():
        p=OUT/'learner/printed'/name
        assert p.read_text()==code+'\n' and sha(p)==prediction['files'][name]
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    before=(OUT/'before/final.md').read_text(encoding='utf8')
    assert re.findall(r'<!--.*?-->',before)==re.findall(r'<!--.*?-->',tracks['final'])
    assert before.split('## On a return visit')[1]==tracks['final'].split('## On a return visit')[1]
    carried=json.loads((OUT/'carried-files.json').read_text())
    for name,source in carried.items():assert (OUT/'learner/printed'/name).read_text()==(ROOT/source).read_text()
    sources=[MAP/n for n in ['tutorial.md','final.md','map_data.json']]
    sources.extend(ROOT/p for p in ['commons/maps/sequences/tiling.json','commons/primitives/arrays/pattern_tile_puzzle.gd','commons/primitives/arrays/pattern_tile_cube.gd','commons/artifacts/pattern_machine_a/recipe_study.gd','commons/primitives/arrays/curved_pattern_room.gd',*carried.values()])
    (OUT/'sources.json').write_text(json.dumps([{'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
    (OUT/'parallel.html').write_text(page('Pattern Foundry / tutorial and reflection','<p class="meta kicker">Endless Museum / Tiling 02</p><p>Disco calculated a value. Foundry keeps an editable source. The room can carry that decision farther than your hand reaches.</p><div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf8')
    (OUT/'changes.html').write_text(page('Pattern Foundry / changes','<h1>From one entry to its returns</h1><p>The tutorial selects source storage and wrapped reading from the wider room. The reflection keeps the architectural skins, tile stations, loom, curved room and return visit; its sampling excerpt becomes prose.</p>'+''.join(diffs)),encoding='utf8')
    report=f'''# One mark, several places

Tiling · Pattern Foundry · 9 October 2026

**The next tutorial now follows the same cube grid and held point from Disco.** The new operation is small: retain a source array, read it through repeating addresses, and change one entry by hand. The reflection keeps the wider museum encounter.

## What changes in the lesson

| Before | Now |
| --- | --- |
| An encounter guide covering tile stations, source recipes, hold states, surfaces and architectural controls. | One complete source-and-reader construction, followed by a concise return to those wider systems. |
| Proposed source arrays and wrapped lookup, with no minimal complete program. | Four printed files: a new entry script and the unchanged cube grid, Palette class and PointBody. |
| General comparison of a source and its many appearances. | A prediction the student can test: one edit changes exactly six displayed copies; adding a row changes the repeat period. |

The display still has twenty-five cube tiles. Its source begins with two rows and three columns; those unequal dimensions make a mistaken row/column assumption visible. The installed small tile is four by four. The loom and fabric studio have their own sources. The reduced learner program does not silently connect to or overwrite them.

The held point becomes the selector. A ring and label show the preview cell and source address beneath it. Trigger changes the shared source entry; carrying the point alone does not paint. The adapter uses the grid's local frame and rejects positions beyond the display or its height range. The program explicitly repaints after editing the data.

## An independent change

The student adds a third row, `[2, 0, 0]`, before running again. Width stays three, but the vertical repeat becomes three rows. Two mint cells appear in preview row two; source row zero returns at row three. The cube count and geometry stay fixed. The same source entry now appears four times in the bounded preview instead of six.

This prepares Tutorial Pattern: keep an asymmetric source and alter the address rule that reads its copies. Array copying, texture holding, recipe saving and time history remain distinct topics. The full technical reference and reflection retain the larger systems; they are not all new programming obligations in this lesson.

## Verification

- **{tests['checks']} Godot assertions:** {tests['results'][0]['checks']} on the exact printed files and {tests['results'][1]['checks']} on the separately edited third-row program.
- **Five executable faults caught:** wrong wrap width, ignored source row, missing repaint, world coordinates used as local coordinates, and a missing height gate.
- **{len(native['checks'])} native museum checks:** installed source/receiver updates, held images, ordinary-controller entry and return through the curved room, standing clearance, and simulated XR Tools pickup, hover, held action and release.

The colour fixtures are independently listed rather than generated with the learner's wrapping function. They check all twenty-five values and their displayed colours. The hand test uses a rotated host. The transfer is a separate program extracted from the tutorial with one source edit, not a changed expectation applied to the original program.

The first test harness needed an explicit Array type before it could run. The first museum pixel assertion compared an eight-bit image with a full-precision palette using an unsuitable tolerance. It now records both colours and checks within one eight-bit channel step. The printed program passed the behavioural runs; the earlier receipts remain in attempts.

These are author-informed reconstructions, not a human learning trial or a physical headset test. Audio was muted. The native log retains an existing UID error and registry/renderer warnings. It also reports a blocked authored entry with a safe fallback and a slow build of the masked-dancer exhibit. The local learner approach and curved-room walk passed; this is not certification of the full route or Quest performance. No lesson script errors are accepted. The learner display is temporarily placed in the museum for evidence. Existing artifact code, hall geometry and sequence order were not changed.

## Reading the two texts

The tutorial makes one operation available to reconstruct. The reflection asks how far a local decision travels, what holds its appearances together, and what kind of exception the instrument permits. Its existing room image, artifact markers, return-visit experiments and ending remain; only the sampling code passage became prose.

Read the [facing pages](parallel.html), [changes](changes.html), [code checks](tests.json), [deliberate faults](mutations.json), [museum receipt](museum/report.json) or [review ZIP](tiling-foundry-review.zip). The [nine-hall route](../plan.html) remains editable; only Disco and Foundry have been reconstructed in this pass.

**Next: Tutorial Pattern — the same source, a different reading rule.**
'''
    (OUT/'REPORT.md').write_text(report,encoding='utf8')
    figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in [
      ('small-source','The installed four-by-four source station and its repeated preview. Native source update checked separately from the learner study.'),
      ('student-source','The printed two-row, three-column source on the carried five-by-five cube display. Temporary learner bay inside the actual museum.'),
      ('student-one-edit','Held point over preview (4, 2): one source entry changes six copies to mint. The ring and readout identify the selected relationship.'),
      ('student-third-row','Separate third-row program. Two mint cells appear in the middle row; the receiver has not grown.'),
      ('room-two-moments','The installed curved room after an edit with its floor held. This texture-holding encounter is distinct from the learner source array.')])
    (OUT/'index.html').write_text(page('Pattern Foundry / one mark, several places','<p class="meta kicker">Endless Museum / Tiling 02</p>'+md(report)+'<h2>Inside the museum</h2>'+figures),encoding='utf8')
    route=page('Tiling / nine-hall route',md((OUT.parent/'PLAN.md').read_text(encoding='utf8')))
    for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-foundry-review.zip']:route=route.replace('href="'+n+'"','href="Pattern_Foundry/'+n+'"')
    route=route.replace('href="../plan.html"','href="plan.html"')
    (OUT.parent/'plan.html').write_text(route,encoding='utf8')
    (OUT/'README.md').write_text('''# Pattern Foundry review

Open index.html or parallel.html. The two markdown readings are canonical snapshots. learner/printed was extracted from the tutorial; learner/third-row is its independent edit. Other learner folders deliberately contain faulty programs.

This packet assumes the existing Endless Museum project, player and XR Tools. It is not a standalone Godot project. Run tools/test_tiling_foundry.py. Native run: tools/run_encounter_probe.py Pattern_Foundry --sequence tiling --render --no-bridges --probe tools/probes/tiling_foundry_room.gd --output-tag foundry-source-return --spec doc/book/iterations/2026-10-09-tiling-revision/Pattern_Foundry/spec-student.json. Reproduce sources retain original repository path assumptions.

Temporary learner host: hall-local (14, 0, 15.5), yaw 90 degrees, unit scale set before creation. Approach local (0,0,2.5) checked for floor support and standing clearance. This is not a permanent museum installation. No saved recipes are written. Small-tile set_cell is exercised directly; loom/studio controls use pointer callbacks; learner point uses simulated XR Tools grip and action. No physical headset, listening quality or human learning claim.
''',encoding='utf8')
    methods=OUT/'reproduce';methods.mkdir(exist_ok=True)
    for n in ['tools/revise_tiling_foundry.py','tools/test_tiling_foundry.py','tools/publish_tiling_foundry.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_foundry_student.gd','tools/probes/tiling_foundry_room.gd']:shutil.copy2(ROOT/n,methods/Path(n).name)
    with zipfile.ZipFile(OUT/'tiling-foundry-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in OUT.rglob('*'):
            if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(OUT).parts:z.write(p,'Pattern_Foundry/'+p.relative_to(OUT).as_posix())
        for n in ['PLAN.md','plan.html']:z.write(OUT.parent/n,n)
    print('Published',OUT/'index.html')
if __name__=='__main__':main()
