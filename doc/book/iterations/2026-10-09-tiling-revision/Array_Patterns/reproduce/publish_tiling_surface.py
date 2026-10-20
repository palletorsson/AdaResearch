"""Publish the fourth Tiling lesson and update only its execution-plan row."""
from pathlib import Path
import difflib,html,json,re,shutil,zipfile
import markdown
from publish_tiling_disco import sha,page as base_page
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Array_Patterns'
M=R/'commons/maps/Array_Patterns'
def page(title,body,wide=False):return base_page(title,body,wide).replace('tiling-disco-review.zip','tiling-surface-review.zip')
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def write(name,text):(O/name).write_text(text,encoding='utf8')
def sync_plan(tests,native):
    p=R/'doc/book/course/execution-plan/plan.json';raw=p.read_text(encoding='utf8');data=json.loads(raw)
    row=next(x for x in data['lessons'] if x['id']=='Array_Patterns')
    def formatted(x):return '    '+json.dumps(x,ensure_ascii=False,indent=2).replace('\n','\n    ')
    old=formatted(row);assert raw.count(old)==1
    row.update(
      object='Carried two-by-three source, five-by-five cube grid and black PointBody. Installed addressed tunnel provides the larger walkable comparison.',
      change='Keep the source fixed. Turn the existing receiver between a table and right-wall pose, change its cell spacing, and convert the held point’s world position back to the same local address.',
      given='Unchanged Palette, GridSurface and PointBody. Existing museum player, camera, lighting and XR Tools. Unit-scale learner root. Point inspects; two named trigger regions change face and width.',
      later='The tutorial scales a compact receiver; the installed tunnel keeps its dimensions and cuts boundary cells. Shader implementation and general surface construction remain supplied. Root scaling and nonuniform scaling are outside this example.',
      checks=[
        f"{tests['checks']} Godot assertions: exact printed code and independent narrower-width program; transformed host, physical widths, source/colour identity and selection. Array_Patterns/tests.json in the 9 October Tiling revision.",
        'Seven executable faults rejected through assertions, not parse errors. Array_Patterns/mutations.json.',
        f"{len(native['checks'])} native museum checks: installed tunnel pointer controls/undo/UV address, four clear supported approaches, simulated learner XR Tools pickup/action/release. Array_Patterns/museum/report.json. No physical headset or human-learning claim."],
      transfer='Change [0.32,0.48] to [0.24,0.36]. Predict source widths 0.72/1.08 metres, unchanged twenty-five colours, and the same address after turning/resizing. Point-centre selection remains 12–65 cm from the receiver.',
      carry='Source values, read rule, receiver frame and physical extent remain distinct. A surface gives row/column directions; inverse transforms recover addresses. A finite display may cut a repeat.',
      next='Symmetry_Seventeen: compare translation, reflection and glide while keeping a finite receiver and distinguishing a source width from a translation period.',
      notes='9 October: fourth Tiling revision, four printed files and unchanged three carried helpers. Temporary learner display tested inside the existing museum. Map, production artifacts and sequence order unchanged. Existing UID/viewport/renderer/Jolt warnings are documented; no Quest performance claim.',
      summary='Keep the source, cube display and held point. Turn and resize the receiver while its values remain fixed; recover its surface address from the point’s world position. Predict physical cell spacing and source width, then make an independent narrower version. Compare this growing compact display with the installed fixed-size tunnel, whose edges cut cells. Carry source, read rule, frame and extent into the symmetry hall.')
    updated=raw.replace(old,formatted(row),1)
    # Reread before mutation: a concurrent writer must not be overwritten.
    assert p.read_text(encoding='utf8')==raw
    p.write_text(updated,encoding='utf8')
    write('plan-entry.json',json.dumps(row,ensure_ascii=False,indent=2)+'\n')
    write('plan-entry.diff',''.join(difflib.unified_diff((O/'before/plan-entry.json').read_text(encoding='utf8').splitlines(True),(O/'plan-entry.json').read_text(encoding='utf8').splitlines(True),fromfile='before/plan-entry.json',tofile='after/plan-entry.json')))

def main():
    tests=json.loads((O/'tests.json').read_text());faults=json.loads((O/'mutations.json').read_text())
    run=R/'ada_run/encounter_pilot/Array_Patterns/surface-frame';native=json.loads((run/'report.json').read_text())
    assert tests['all_passed'] and faults['all_rejected'] and native['passed']
    assert 'SCRIPT ERROR' not in (run/'engine.log').read_text(encoding='utf8')
    museum=O/'museum';museum.mkdir(exist_ok=True)
    for p in run.iterdir():
        if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(p,museum/p.name)
    prediction=json.loads((O/'prediction.json').read_text())
    assert sha(M/'tutorial.md')==prediction.get('post_test_source_sha256',prediction['source_sha256'])
    tracks={};diffs=[]
    for name in ['tutorial','final']:
        text=(M/(name+'.md')).read_text(encoding='utf8');tracks[name]=text;write(name+'.md',text)
        write(name+'.html',page('Array Patterns / '+name,md(text)))
        before=(O/'before'/(name+'.md')).read_text(encoding='utf8')
        delta=''.join(difflib.unified_diff(before.splitlines(True),text.splitlines(True),fromfile='before/'+name+'.md',tofile='after/'+name+'.md'))
        write(name+'.diff',delta);diffs.append(f'<h2>{name}.md</h2><pre class="diff">{html.escape(delta)}</pre>')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tracks['tutorial'],re.S));assert len(blocks)==4
    for n,code in blocks.items():
        assert (O/'learner/printed'/n).read_text(encoding='utf8')==code+'\n'
        assert sha(O/'learner/printed'/n)==prediction['files'][n]
    assert (M/'map_data.json').read_bytes()==(O/'before/map_data.json').read_bytes()
    before=(O/'before/final.md').read_text(encoding='utf8')
    expected=before.replace('```gdscript\ncolumn % 4\nrow % 4\n```\n\nThese are the wrapping expressions used by the inspector.','The inspector wraps each surface coordinate back into the four-cell source.')
    assert tracks['final']==expected and '```' not in tracks['final']
    carried=json.loads((O/'carried-files.json').read_text())
    for n,p in carried.items():assert (O/'learner/printed'/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
    sync_plan(tests,native)
    sources=[M/n for n in ['tutorial.md','final.md','map_data.json']]
    sources.extend(R/p for p in ['commons/maps/sequences/tiling.json','commons/artifacts/pattern_tunnel/tunnel_address_lesson.gd',*carried.values()])
    write('sources.json',json.dumps([{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in sources],indent=2)+'\n')
    intro='<p class="meta kicker">Endless Museum / Tiling 04</p><p><a href="../Tutorial_Pattern/parallel.html">Previous: Tutorial Pattern</a> · Next: Symmetry Seventeen</p>'
    write('parallel.html',page('Array Patterns / tutorial and reflection',intro+'<div class="pair"><article class="sheet"><p class="meta">LEFT / TUTORIAL</p>'+md(tracks['tutorial'])+'</article><article class="sheet"><p class="meta">RIGHT / REFLECTION</p>'+md(tracks['final'])+'</article></div>',True))
    write('changes.html',page('Array Patterns / changes','<h1>Give the address a surface</h1><p>A complete working reconstruction joins the existing tunnel encounter. The reflective text changes only its small code excerpt into prose.</p>'+''.join(diffs)))
    report=f'''# Give the address a surface

Tiling · Array Patterns · 9 October 2026 · fourth of nine halls

**The pattern stays the same. Its place and size change.** Keep the source, twenty-five cubes and black point from the previous lesson. Turn the display into a right-wall panel; enlarge its cells. The hand still finds the same stored value at the corresponding surface address.

## The teaching choice

| Before | Now |
| --- | --- |
| A short guide to the installed tunnel controls. | That encounter followed by a complete four-file reconstruction. |
| Row, column and cell width named as concepts. | A receiver with an explicit origin, local axes and spacing in metres, selected through the inverse transform. |
| No independent construction check. | A separately rebuilt version with widths 0.24/0.36 metres; predicted source widths 0.72/1.08 metres. |

Transformation returns here as a useful skill. Translation places the first cell, rotation changes which direction a row occupies, and scale changes physical spacing. The point now inspects. The source and its reading rule stay fixed while the receiver changes. Palette, GridSurface and PointBody are unchanged and fully printed; one new entry script holds the lesson.

The compact learner display grows as a whole. The installed tunnel keeps its dimensions while its cell count changes, leaving partial cells at some edges. The text explicitly distinguishes these two behaviours. Neither one is presented as the other’s implementation.

The reflected reader remains available from the preceding lesson. A three-cell source width can belong to a six-cell translation period. The five-column preview cuts that period. Those distinctions travel into Symmetry Seventeen.

## The reflective reading

The existing passage asks when repetition becomes an environment. It follows the tunnel’s corner, separate surface origins, metre measurements, cut cells and the difference between drawn joints and physical support. Those encounters remain. Only the two-line remainder expression becomes prose; the opening, artifact markers and ending are preserved.

## What passed

- **{tests['checks']} Godot assertions:** {tests['results'][0]['checks']} for the exact printed program and {tests['results'][1]['checks']} for the independent narrower version. Both run on a translated, rotated host.
- **{len(faults['results'])} executable faults caught:** wrong world/local frame, unscaled distance gate, wrong wall turn, omitted resizing, source mutation during a face change, wrong action frame, and a missing half-cell boundary offset.
- **{len(native['checks'])} native museum checks:** installed pointer callbacks, wall marker/UV agreement, cell width, undo and drawn joints; four supported and clear learner approaches; simulated XR Tools pickup, held action and release.

The comparisons check explicit expected positions and colours, not just return values from the same calculation. They check that the grid, MultiMesh, local cube transforms and stored source survive changes. A small prose correction after testing clarified the row direction; code hashes and the original prediction remain recorded.

### Scope

These are native Godot images inside the existing Endless Museum. The small learner display was temporarily installed for inspection. No new permanent artifact, production behaviour, hall geometry or sequence order was added in this pass. The recent placement improvements remain in place.

This is an author-informed reconstruction and simulated input test. Physical headset comfort, student understanding and Quest performance remain untested. The museum log still reports an unresolved UID, unassigned viewport textures, empty registry warnings and unsupported renderer/Jolt settings. There are no lesson script errors. Passing this lesson does not certify the whole project.

Open the [facing pages](parallel.html), [exact changes](changes.html), [code results](tests.json), [fault results](mutations.json), [museum receipt](museum/report.json), or [review ZIP](tiling-surface-review.zip). The [route](../plan.html) now records four completed Tiling revisions, all available for review.

**Next: Symmetry Seventeen — which operations let a pattern return?**
'''
    write('REPORT.md',report)
    figures=''.join(f'<figure><img src="museum/{n}.png" alt="{html.escape(c)}"><figcaption>{c}</figcaption></figure>' for n,c in [
      ('installed-tunnel','The existing tunnel gives the address a walkable surface.'),
      ('installed-wall','The right wall: rows descend, columns follow the passage. The yellow indicator names a surface cell.'),
      ('installed-console','The installed console after changing cell width to sixty centimetres.'),
      ('student-table','Temporary reconstruction: the same source, cube grid and black PointBody.'),
      ('student-wall','The carried receiver turns. Surface row 1, column 3 still reads source row 1, column 0.'),
      ('student-wall-wide','Larger cells, unchanged data. The point and ring locate the same addressed value.'),
      ('student-narrower','Independent narrower-width program: source width 1.08 metres.')])
    write('index.html',page('Array Patterns / give the address a surface',intro+md(report)+'<h2>Inside the museum</h2>'+figures))
    route_path=O.parent/'PLAN.md';route=route_path.read_text(encoding='utf8')
    route=route.replace('| Array Patterns | Keep the source fixed and define where the receiver starts, its axes and its cell width in metres. Place the same values on different surfaces. | Next: inspect the receiver and reconstruct its physical frame. |','| [Array Patterns](Array_Patterns/parallel.html) | Keep the source fixed; turn and resize the receiver. Convert the held point’s world position to its surface address. Distinguish source width, repeat period and finite extent. | Complete fourth revision; exact printed and narrower-width programs tested, with native tunnel and learner evidence. |')
    route=route.replace('Existing text and summary; reconstruction pending.','Next: inspect the installed symmetry comparison and reconstruct its operation.',1)
    old='Pattern Disco, Pattern Foundry and Tutorial Pattern are the three Tiling lessons completed in this pass. Read [Disco](Pattern_Disco/index.html), [Foundry](Pattern_Foundry/index.html) and [Tutorial Pattern](Tutorial_Pattern/index.html), or open the [editable project plan](http://localhost:3003/tutorial-plan?map=Tutorial_Pattern&view=summaries). All retain draft status; the other six lessons remain pending reconstruction or initial writing.'
    new='Pattern Disco, Pattern Foundry, Tutorial Pattern and Array Patterns are the four Tiling lessons completed in this pass. Read [Disco](Pattern_Disco/index.html), [Foundry](Pattern_Foundry/index.html), [Tutorial Pattern](Tutorial_Pattern/index.html) and [Array Patterns](Array_Patterns/index.html), or open the [editable project plan](http://localhost:3003/tutorial-plan?map=Array_Patterns&view=summaries). All retain draft status; the other five lessons remain pending reconstruction or initial writing.'
    assert old in route or new in route;route=route.replace(old,new)
    route_path.write_text(route,encoding='utf8')
    route_html=page('Tiling / nine-hall route',md(route))
    for n in ['index.html','parallel.html','tutorial.html','final.html','changes.html','tiling-surface-review.zip']:route_html=route_html.replace('href="'+n+'"','href="Array_Patterns/'+n+'"')
    (O.parent/'plan.html').write_text(route_html.replace('href="../plan.html"','href="plan.html"'),encoding='utf8')
    write('README.md','''# Array Patterns review

Open index.html or parallel.html. tutorial.md/final.md are canonical snapshots. learner/printed is extracted from the tutorial; learner/narrower is the independent width edit. Other learner folders deliberately contain faults. Requires the existing Endless Museum project and XR Tools; this ZIP is a review packet, not a standalone Godot project.

Run: python tools/test_tiling_surface.py
Native: python tools/run_encounter_probe.py Array_Patterns --sequence tiling --render --no-bridges --probe tools/probes/tiling_surface_room.gd --output-tag surface-frame --spec doc/book/iterations/2026-10-09-tiling-revision/Array_Patterns/spec-student.json

Native probe extends tools/probes/transformation_encounters.gd. Temporary learner root is hall-local (11.5,0,15.5). See REPORT.md for test scope and engine warnings. Reproduction scripts retain repository paths and are not portable without that project.
''')
    dest=O/'reproduce';dest.mkdir(exist_ok=True)
    for n in ['tools/revise_tiling_surface.py','tools/test_tiling_surface.py','tools/publish_tiling_surface.py','tools/publish_tiling_disco.py','tools/publish_noise_opening.py','tools/probes/tiling_surface_student.gd','tools/probes/tiling_surface_room.gd','tools/probes/transformation_encounters.gd','tools/run_encounter_probe.py']:shutil.copy2(R/n,dest/Path(n).name)
    with zipfile.ZipFile(O/'tiling-surface-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in O.rglob('*'):
            if p.is_file() and p.suffix not in ['.zip','.uid'] and 'attempts' not in p.relative_to(O).parts:z.write(p,'Array_Patterns/'+p.relative_to(O).as_posix())
        for n in ['PLAN.md','plan.html']:z.write(O.parent/n,n)
    print('Published',O/'index.html')
if __name__=='__main__':main()
