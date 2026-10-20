"""Publish Tutorial Pattern and synchronize only its plan entry."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha,page as prior_page
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Tutorial_Pattern'
MAP=ROOT/'commons/maps/Tutorial_Pattern'
def page(title,body,wide=False):return prior_page(title,body,wide).replace('tiling-disco-review.zip','tiling-pattern-review.zip')
def md(s):return markdown.markdown(s.replace('/book-images/iterations/2026-09-28-pattern-a-facing-return/source-pair.png','images/source-pair.png'),extensions=['fenced_code','tables','footnotes'])
def sync_plan():
    p=ROOT/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf8');data=json.loads(raw)
    row=next(x for x in data['lessons'] if x['id']=='Tutorial_Pattern')
    def formatted(x):return '    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
    old=formatted(row);assert raw.count(old)==1
    row.update(
      object='Foundry’s retained two-by-three source, five-by-five cube display and black PointBody selector.',
      change='Alternate whole tile columns between forward and reflected lookup; separately reverse entries within each source row. Paint through a reflected copy back into its true source cell.',
      given='Unchanged Palette, GridSurface and PointBody; existing museum player, camera, lighting and XR Tools. The hand adapter selects a cube or one of two named actions.',
      later='Keep the first address operation in GDScript. Museum shaders, quarter turns, undo and the full wallpaper classification remain supplied. Reversing each row differs from reversing the outer array. A symmetric source can conceal either operation.',
      checks=[
        '69 Godot assertions: 34 exact printed, 35 independent symmetric-source program. Evidence: Tutorial_Pattern/tests.json in the 9 October Tiling revision.',
        'Seven executable faults caught, including whole-tile versus individual-cell reflection. Evidence: Tutorial_Pattern/mutations.json.',
        '62 native museum checks: installed pointer controls, visible fields, bay approach and simulated learner pickup/action/release. Evidence: Tutorial_Pattern/museum/report.json. No physical headset or human-learning claim.'],
      transfer='Replace the second source row with [2,0,2]. Predict unchanged colours under a changed reader and unchanged values after row reversal. Edit reflected display (3,1) to break the symmetry, then expose the difference by switching the reader.',
      carry='Stored source, read address and visible appearance remain distinguishable. A diagnostic mark makes an operation observable; the tile width need not equal the translation period.',
      next='Array_Patterns: keep source and reader while defining the receiver origin, axes and cell width in metres.',
      notes='9 October: exact four-file tutorial reconstructed; 69 assertions, seven faults caught, 62 native museum checks. Draft retained for review. Temporary learner display; no production artifact, hall geometry or route change. Existing exit-fallback, expensive exhibit builds and renderer/UID/viewport warnings remain recorded in the report.',
      summary='Keep Foundry’s source, cube display and held point. Switch the reader so alternate tile columns read backwards without changing stored cells; separately reverse each stored row, then paint through a reflected copy into its original source address. Predict the source, colours and six-cell translation period. Rebuild with a symmetric second row to hide the changed rule, then add a difference to expose it. Carry the distinction between source data, the address that reads it and the appearance on a bounded receiver.')
    p.write_text(raw.replace(old,formatted(row),1),encoding='utf8')
    (OUT/'plan-entry.json').write_text(json.dumps(row,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    old_json=(OUT/'before/plan-entry.json').read_text(encoding='utf8');new_json=(OUT/'plan-entry.json').read_text(encoding='utf8')
    (OUT/'plan-entry.diff').write_text(''.join(difflib.unified_diff(old_json.splitlines(True),new_json.splitlines(True),fromfile='before/plan-entry.json',tofile='after/plan-entry.json')),encoding='utf8')
def main():
    tests=json.loads((OUT/'tests.json').read_text());faults=json.loads((OUT/'mutations.json').read_text())
    run=ROOT/'ada_run/encounter_pilot/Tutorial_Pattern/pattern-reflected-reader';native=json.loads((run/'report.json').read_text())
    assert tests['all_passed'] and faults['all_rejected'] and native['passed']
    assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    for p in run.iterdir():
        if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,museum/p.name)
    images=OUT/'images';images.mkdir(exist_ok=True)
    shutil.copy2(ROOT.parent/'ada_encyclopedia/public/book-images/iterations/2026-09-28-pattern-a-facing-return/source-pair.png',images/'source-pair.png')
    prediction=json.loads((OUT/'prediction.json').read_text());assert sha(MAP/'tutorial.md')==prediction['source_sha256']
    tracks={};diffs=[]
    for name in ['tutorial','final']:
        text=(MAP/(name+'.md')).read_text(encoding='utf8');tracks[name]=text
        (OUT/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page('Tutorial Pattern / '+name,md(text)),encoding='utf8')
        before=(OUT/'before'/(name+'.md')).read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='before/'+name+'.md',tofile='after/'+name+'.md'))
        (OUT/(name+'.diff')).write_text(diff,encoding='utf8');diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(diff)}</pre>')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==4
    for n,code in blocks.items():assert (OUT/'learner/printed'/n).read_text()==code+'\n' and sha(OUT/'learner/printed'/n)==prediction['files'][n]
    assert (MAP/'map_data.json').read_bytes()==(OUT/'before/map_data.json').read_bytes()
    before=(OUT/'before/final.md').read_text(encoding='utf8')
    assert before.split('P1 repeats by translation.')[0]==tracks['final'].split('P1 repeats by translation.')[0]
    assert before.split('Choose a paint colour')[1]==tracks['final'].split('Choose a paint colour')[1]
    assert re.findall(r'<!--.*?-->',before)==re.findall(r'<!--.*?-->',tracks['final']) and '```' not in tracks['final']
    carried=json.loads((OUT/'carried-files.json').read_text())
    for n,p in carried.items():assert (OUT/'learner/printed'/n).read_text()==(ROOT/p).read_text()
    sync_plan()
    sources=[MAP/n for n in ['tutorial.md','final.md','map_data.json']]
    sources.extend(ROOT/p for p in ['commons/maps/sequences/tiling.json','commons/artifacts/pattern_maker_station/pattern_maker_station.gd','commons/artifacts/pattern_maker_station/fixed_motif_lesson.gd','commons/resourses/shaders/wallpaper_tile.gdshader',*carried.values()])
    (OUT/'sources.json').write_text(json.dumps([{'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
    intro='<p class="meta kicker">Endless Museum / Tiling 03</p><p>Foundry kept the source. Here a copy reads it from the other side. <a href="../Pattern_Foundry/parallel.html">Previous: Foundry</a></p>'
    (OUT/'parallel.html').write_text(page('Tutorial Pattern / tutorial and reflection',intro+'<div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True),encoding='utf8')
    (OUT/'changes.html').write_text(page('Tutorial Pattern / changes','<h1>Change the reading</h1><p>The tutorial reconstructs reflected lookup and source reversal using the carried objects. The reflection keeps the original encounter and replaces its three code excerpts with prose.</p>'+''.join(diffs)),encoding='utf8')
    report=f'''# Change the reading

Tiling · Tutorial Pattern · 9 October 2026

**The third lesson keeps Foundry’s source, cube display and held point.** It separates a changed reader from a changed record. The existing museum already makes this comparison with two panels and a source editor; the tutorial now gives the student a complete reduced construction.

## What changed

| Before | Now |
| --- | --- |
| An encounter guide to P1, PM, source flipping, quarter turns and undo. | One runnable comparison: reflect the lookup or reverse the stored row. The wider controls remain in the museum and reflection. |
| No complete learner script. | One new entry script; Palette, GridSurface and PointBody copied unchanged from Foundry and fully printed. |
| A general instruction to use asymmetry. | A predicted symmetric-source variation, executed separately, then an edit that makes the difference visible. |

The point still selects and paints a cube. Two nearby labelled regions give it named actions: READ RULE changes a Boolean; FLIP SOURCE reverses each row in place. Hovering does not act. Painting through a reflected copy finds its original source address. The new code does not rebuild the sphere, change the cube mesh, or require a new player.

The two-row, three-column source remains deliberately smaller than the five-by-five receiver. Under alternating reflection, the asymmetric pattern has a six-cell horizontal translation period. The preview cuts through the second tile; the text names that limit and asks the student to compare an address six cells away. The installed panels show complete paired copies.

## A diagnostic that can fail to show a difference

The independent edit replaces the second row with `[2,0,2]`. Both rows then read the same backwards. The Boolean and addresses can change without a visible colour change. Reversing the rows produces the same stored values. Painting through reflected preview (3,1) changes source column two and breaks that symmetry. Switching the reader becomes visible again.

This is the next capacity after Foundry: inspect data and operation alongside appearance. In Array Patterns the same source and reader will acquire a physical frame—an origin, axes and cell width.

## Evidence

- **{tests['checks']} Godot assertions:** {tests['results'][0]['checks']} on files extracted from the printed tutorial; {tests['results'][1]['checks']} on the separate symmetric-source program.
- **{len(faults['results'])} executable faults rejected:** alternating individual cells instead of tiles, mutating the source while changing the reader, reversing outer row order, missing repaint, painting without reflected lookup, using world coordinates for the control, and truncating negative tile coordinates.
- **{len(native['checks'])} native museum checks:** source data and rendered field comparisons, actual pointer callbacks, ordinary-controller entry and return through the bay, learner standing clearance, simulated XR Tools grip, selection, held action and release.

The first fault run found a weakness in the tests: a three-column source has a fixed middle cell, so a wrong alternate-cell rule can produce the same addresses. The test now also checks a four-column source against the explicit sequence `0,1,2,3 / 3,2,1,0 / 0,1,2,3`. The fault is caught. Earlier receipts remain in `attempts/`; passing results do not erase that correction. The printed program itself passed both runs.

The screenshots below are native museum captures. The small learner display is temporarily placed in the existing comparison bay; it is not a new permanent installation. The installed station retains its own four-by-four source and fixed panels. The reconstruction is author-informed, with simulated input—not a human-learning or physical-headset test. Audio was muted.

### Limits visible in the run

The existing museum log reports a blocked authored exit with a safe fallback, expensive builds of `rocaille` (150 ms) and `sea_forms` (1530 ms), an unresolved UID, viewport/renderer warnings, a panel-bridge look-at call before tree entry, and a resource still in use at exit. The local approach and bay walk passed; this is not a clean bill of health for the full route or Quest performance. There are no lesson script errors. No production artifact logic, map geometry or sequence order was changed by this revision.

## The two readings

The tutorial provides the operation and a way to disprove a mistaken explanation. The reflection asks where an apparent reversal happened, how an interruption becomes regular, and what a boundary around one tile leaves out. Its opening, museum image, artifact markers, later experiments and ending remain intact. Three code excerpts become a short account in prose.

Open the [facing pages](parallel.html), [exact changes](changes.html), [code results](tests.json), [fault results](mutations.json), [museum receipt](museum/report.json), or [review ZIP](tiling-pattern-review.zip). The [nine-hall route](../plan.html) records three completed revisions; this lesson remains a draft for review.

**Next: Array Patterns — give the reading a place and a scale.**
'''
    (OUT/'REPORT.md').write_text(report,encoding='utf8')
    figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in [
      ('two-fixed-fields','Installed comparison: the same source, two fixed reading rules.'),
      ('student-translation','Temporary learner display: the unchanged Foundry motif repeats by translation.'),
      ('student-reflection','READ RULE: alternate copies read backwards; the stored source stays unchanged.'),
      ('student-source-flipped','FLIP SOURCE: each stored row reverses; the reader remains on alternating reflection.'),
      ('student-reflected-edit','Painting through a reflected copy changes its original source cell and all four displayed occurrences.'),
      ('student-symmetric','Independent symmetric-source program: reflection is active, although the colours do not reveal the change.')])
    (OUT/'index.html').write_text(page('Tutorial Pattern / change the reading',intro+md(report)+'<h2>Inside the museum</h2>'+figures),encoding='utf8')
    route=page('Tiling / nine-hall route',md((OUT.parent/'PLAN.md').read_text(encoding='utf8')))
    for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-pattern-review.zip']:route=route.replace('href="'+n+'"','href="Tutorial_Pattern/'+n+'"')
    (OUT.parent/'plan.html').write_text(route.replace('href="../plan.html"','href="plan.html"'),encoding='utf8')
    (OUT/'README.md').write_text('''# Tutorial Pattern review

Open index.html or parallel.html. tutorial.md and final.md are canonical snapshots. learner/printed was extracted from the tutorial; learner/symmetric is its independent source edit. Other learner folders deliberately contain faulty programs. The packet assumes the existing Endless Museum project and XR Tools, not a standalone project.

Run: python tools/test_tiling_pattern.py
Native: python tools/run_encounter_probe.py Tutorial_Pattern --sequence tiling --render --no-bridges --probe tools/probes/tiling_pattern_room.gd --output-tag pattern-reflected-reader --spec doc/book/iterations/2026-10-09-tiling-revision/Tutorial_Pattern/spec-student.json

The native probe extends the September comparison probe and uses its actual pointer controls and ordinary-controller bay walk. The learner is placed 3.2 metres in front of the station in the station frame, before entering the tree. Standing support and clearance are checked. It is a temporary inspection, not a permanent scene addition. See REPORT.md for existing museum warnings and limits. Reproduce files retain repository path assumptions; they are not a bundled engine or project.
''',encoding='utf8')
    methods=OUT/'reproduce';methods.mkdir(exist_ok=True)
    for n in ['tools/revise_tiling_pattern.py','tools/test_tiling_pattern.py','tools/publish_tiling_pattern.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_pattern_student.gd','tools/probes/tiling_pattern_room.gd']:
        shutil.copy2(ROOT/n,methods/Path(n).name)
    (OUT/'reproduce/DEPENDENCIES.md').write_text('Native probe also reads doc/book/iterations/2026-09-28-pattern-a-facing-return/probe.gd, tools/probes/transformation_encounters.gd, tools/probes/array_entered_address.gd and tools/run_encounter_probe.py in the original project. Runtime source hashes are in museum/source_manifest.json.\n')
    with zipfile.ZipFile(OUT/'tiling-pattern-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in OUT.rglob('*'):
            if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(OUT).parts:z.write(p,'Tutorial_Pattern/'+p.relative_to(OUT).as_posix())
        for n in ['PLAN.md','plan.html']:z.write(OUT.parent/n,n)
    print('Published',OUT/'index.html')
if __name__=='__main__':main()
