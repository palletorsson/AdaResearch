"""Publish one tested Tiling lesson, preserving the existing museum."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil, zipfile
import markdown
from publish_noise_opening import page as base_page

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Disco'
MAP=ROOT/'commons/maps/Pattern_Disco'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def page(title,body,wide=False):
    return base_page(title,body,wide).replace('Noise route','Tiling route').replace('noise-opening-review.zip','tiling-disco-review.zip')
def md(s):
    return markdown.markdown(s.replace('/book-images/iterations/2026-09-28-disco-colour-in-step/checker-pair.png','images/checker-pair.png'),extensions=['fenced_code','tables','footnotes'])

def main():
    tests=json.loads((OUT/'tests.json').read_text());faults=json.loads((OUT/'mutations.json').read_text())
    run=ROOT/'ada_run/encounter_pilot/Pattern_Disco/tiling-palette-return'
    native=json.loads((run/'report.json').read_text())
    assert tests['all_passed'] and faults['all_rejected'] and native['passed']
    assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for p in run.iterdir():
        if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,museum/p.name)
    images=OUT/'images';images.mkdir(exist_ok=True)
    shutil.copy2(ROOT.parent/'ada_encyclopedia/public/book-images/iterations/2026-09-28-disco-colour-in-step/checker-pair.png',images/'checker-pair.png')
    prediction=json.loads((OUT/'prediction.json').read_text())
    assert sha(MAP/'tutorial.md')==prediction['source_sha256']
    tracks={};diffs=[]
    for name in ['tutorial','final']:
        text=(MAP/(name+'.md')).read_text(encoding='utf8');tracks[name]=text
        (OUT/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page('Pattern Disco / '+name,md(text)),encoding='utf8')
        before=(OUT/'before'/(name+'.md')).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='before/'+name+'.md',tofile='after/'+name+'.md'))
        (OUT/(name+'.diff')).write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(diff)}</pre>')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S))
    assert len(blocks)==4
    for name,code in blocks.items():
        p=OUT/'learner/printed'/name
        assert p.read_text()==code+'\n' and sha(p)==prediction['files'][name]
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    before=(OUT/'before/final.md').read_text(encoding='utf8')
    assert re.findall(r'<!--.*?-->',before)==re.findall(r'<!--.*?-->',tracks['final'])
    carried=json.loads((OUT/'carried-files.json').read_text())
    for name,source in carried.items():assert (OUT/'learner/printed'/name).read_text()==(ROOT/source).read_text()
    sources=[MAP/n for n in ['tutorial.md','final.md','map_data.json']]
    sources.extend(ROOT/p for p in ['commons/maps/sequences/tiling.json','commons/artifacts/regularity/disco_controls.gd',*carried.values()])
    (OUT/'sources.json').write_text(json.dumps([{'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
    (OUT/'parallel.html').write_text(page('Pattern Disco / tutorial and reflection','<p class="meta kicker">Endless Museum / Tiling 01</p><p>Left: reconstruct one distinction. Right: walk, compare and reflect on the wider room.</p><div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf8')
    (OUT/'changes.html').write_text(page('Pattern Disco / changes','<h1>One value, another colour</h1><p>The encounter guide becomes a complete reconstruction. The reflection keeps its encounters, image and ending; its lookup code becomes prose.</p>'+''.join(diffs)),encoding='utf8')
    report=f'''# Keep the pattern, change its colours

Tiling · first hall · 9 October 2026

**Pattern Disco now has a complete, tested tutorial beside its reflective text.** Arrays supplied addresses and repeated bodies; Colour supplied the palette. Here the student separates a pattern value from the colour assigned to it.

The current museum route contains nine Tiling halls, including the newly added Pattern Temple. This is the first lesson, not a completion claim for the sequence.

## Before and after

| Track | Before | This revision |
| --- | --- | --- |
| Tutorial | Instructions for comparing the installed controls, without a complete learner program. | A small 5 × 5 display using the carried cube grid, Palette class and pickable point. Four complete files, explicit museum host and one new pattern rule. |
| Reflection | A strong passage through palette, pattern, walking and independent score, with a short code block. | The same encounters and image remain; the code block and its adjacent explanation become prose. |
| Museum | A 12 × 12 walkable floor, colour controls and independent sequencer. | Existing installation retained. The small learner display is temporarily added for evidence only. |

## What the student learns

At each address, a checker rule returns zero or one. The selected palette supplies the corresponding colour. Changing the palette preserves phase; changing phase can exchange values while retaining the palette. The familiar black point supplies grip and trigger, with local left/middle/right regions selecting palette, step and play/hold.

The independent edit gives both entries the same grey. The checker disappears from view even while a step still exchanges its values. Selecting another pair reveals the retained pattern. A still-looking surface cannot establish that its input has stopped. The student predicts this before running, then chooses their own pair and explains the distinction.

The new work is the pattern-to-palette connection. The full carried helpers remain printed so the program can be reconstructed. They are supplied infrastructure here, not three additional subjects to learn. Their source is the complete Colour review draft and inherited PointBody; this does not silently promote the entire Colour draft to canonical status.

## What passed

- **{tests['checks']} Godot assertions:** {tests['results'][0]['checks']} on the exact printed files and {tests['results'][1]['checks']} on the independently edited equal-grey program.
- **Five executable faults rejected:** ignored phase, palette resetting phase, one colour for every value, lost clock remainder and ignored pause. All failed behaviour assertions, not parsing.
- **{len(native['checks'])} native museum checks:** existing pointer controls and independent clocks, ordinary desktop walking on the floor, unchanged tile geometry, a supported and clear learner approach, and simulated XR Tools grip, held trigger and release.

Checks cover known parity values, unchanged addresses and transforms, colour assignment, held time, remainder across long frames, the local frame under a rotated host, independent palette ownership and the changed program. Native images below come from Godot, including the printed reconstruction in the museum.

The first run caught a missing bracket in the new script. It was corrected in the study and printed text, then extracted and tested again. The museum probe initially allowed an earlier subtest's completion flag to mask the learner load failure; it now requires the student reconstruction to complete. A later clearance check placed its standing capsule too close to the pickable sphere. Moving that test position back by 20 cm gave an unobstructed approach. Failed receipts remain in the repository's attempts directory.

This is an author-informed ghost-student reconstruction. It verifies these behaviours, not human understanding, headset comfort or Quest performance. Audio was muted. The native log still contains existing project UID, viewport-texture, registry and renderer warnings/errors; the lesson has no script errors. The small unshaded display verifies assigned colour, not lighting or a required perceptual response.

## What carries onward

**Pattern Foundry** replaces this calculated motif with a small editable source. The student can then distinguish the stored values, the read rule and the receiving surface. That gives the next hall a new operation while keeping addresses, colours and the cube receiver available.

Read the [facing pages](parallel.html), [exact changes](changes.html), [test receipts](tests.json), [deliberate faults](mutations.json), [museum checks](museum/report.json), [nine-hall plan](../plan.html) or [review ZIP](tiling-disco-review.zip). The [editable lesson plan](http://localhost:3003/tutorial-plan?map=Pattern_Disco&view=summaries) remains a draft.
'''
    (OUT/'REPORT.md').write_text(report,encoding='utf8')
    figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in [
      ('palette-navy-pink','Installed 12 × 12 museum floor. Its existing controls and geometry are retained.'),
      ('student-pink','Exact printed 5 × 5 continuation, temporarily placed in the museum. The inherited black point controls it.'),
      ('student-grey','Independent equal-grey edit after one step. The hidden zero/one values exchange while the visible colours stay equal.'),
      ('triangle-yellow','The wider installed encounter includes a held triangle turn. Its shader is available to explore, outside this checker reconstruction.')])
    (OUT/'index.html').write_text(page('Tiling / keep the pattern','<p class="meta kicker">Endless Museum / Tiling 01</p>'+md(report)+'<h2>Inside the museum</h2>'+figures),encoding='utf8')
    route=page('Tiling / nine-hall plan',md((OUT.parent/'PLAN.md').read_text(encoding='utf8')))
    for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-disco-review.zip']:route=route.replace('href="'+n+'"','href="Pattern_Disco/'+n+'"')
    route=route.replace('href="../plan.html"','href="plan.html"')
    (OUT.parent/'plan.html').write_text(route,encoding='utf8')
    (OUT/'README.md').write_text('''# Pattern Disco review

Open index.html or parallel.html. tutorial.md and final.md are canonical snapshots. learner/printed contains the exact fenced files; learner/equal-grey is the independent edit. Other learner directories intentionally contain faults, not recommended examples.

This is a review packet, not a standalone Godot project. Use the existing Endless Museum with its Day Zero player and XR Tools. Run tools/test_tiling_disco.py with Godot 4.6. Native verification uses tools/run_encounter_probe.py Pattern_Disco --sequence tiling --render --no-bridges --probe tools/probes/tiling_disco_room.gd --output-tag tiling-palette-return --spec doc/book/iterations/2026-10-09-tiling-revision/Pattern_Disco/spec-student.json. Reproduction sources assume their original repository locations.

The learner display was temporarily placed at hall-local (14.5, 0, 7), yaw 0 and unit scale before entering the scene tree. Standing approach at its local (0, 0, 2.5) passed support and clearance checks. It is not permanently installed. Native Compatibility-renderer captures and simulated hand tests do not certify physical headset comfort.
''',encoding='utf8')
    methods=OUT/'reproduce';methods.mkdir(exist_ok=True)
    for n in ['tools/revise_tiling_disco.py','tools/test_tiling_disco.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_disco_student.gd','tools/probes/tiling_disco_room.gd']:shutil.copy2(ROOT/n,methods/Path(n).name)
    with zipfile.ZipFile(OUT/'tiling-disco-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in OUT.rglob('*'):
            if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(OUT).parts:z.write(p,'Pattern_Disco/'+p.relative_to(OUT).as_posix())
        for n in ['PLAN.md','plan.html']:z.write(OUT.parent/n,n)
    print('Published',OUT/'index.html')
if __name__=='__main__':main()
