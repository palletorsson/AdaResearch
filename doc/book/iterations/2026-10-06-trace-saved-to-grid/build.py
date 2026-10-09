from pathlib import Path
import json,re,shutil,hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OLD=ROOT/'doc/book/iterations/2026-10-05-point-a-reusable-class'
def write(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(s,encoding='utf-8',newline='\n')
def save(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def block(n,t):return '<!-- student-code:'+n+' -->\n```gdscript\n'+t+'```\n'
def main():
    before=HERE/'before'
    if not before.exists():
        before.mkdir()
        for hall in ['Point_Trace','Point_Line_Grid']:
            shutil.copyfile(ROOT/f'commons/maps/{hall}/tutorial.md',before/(hall+'.md'))
        shutil.copyfile(ROOT.parent/'ada_encyclopedia/ghost-student/manifest.json',before/'manifest.json')
    old=(OLD/'trace/trace.gd').read_text()
    operations=[{'id':'archive-support','kind':'insert_after','anchor':'const LineSkin = preload("line_skin.gd")\n','text':'const TraceArchive = preload("trace_archive.gd")\n'},
        {'id':'save-on-release','kind':'insert_after','anchor':'    positions.append(point.position)\n','text':'    point.dropped.connect(_save_trace)\n'},
        {'id':'save-after-drawing-settles','kind':'insert_after','anchor':'    readout.text += "\\nPOINTS " + str(positions.size())\n','text':'\nfunc _save_trace(_point: Node3D) -> void:\n    await get_tree().process_frame\n    if positions.size() < 2:\n        return\n    var error := TraceArchive.save_drawing(trail, positions)\n    if error != OK:\n        push_error("Could not save this trace: " + error_string(error))\n'}]
    code=old
    for op in operations:
        assert code.count(op['anchor'])==1
        code=code.replace(op['anchor'],op['anchor']+op['text'],1)
    for part in ['trace','grid']:
        target=HERE/part
        target.mkdir(exist_ok=True)
        for name in ['point_body.gd','line_skin.gd']:
            shutil.copyfile(OLD/'trace'/name,target/name)
        shutil.copyfile(HERE/'trace_archive.gd',target/'trace_archive.gd')
    write(HERE/'trace/trace.gd',code)
    shutil.copyfile(HERE/'grid.gd',HERE/'grid/grid.gd')
    shutil.copyfile(OLD/'lines/line.gd',HERE/'trace/incoming.gd')
    save(HERE/'trace/operations.json',read(OLD/'trace/contract.json')['operations']+operations)
    write(HERE/'grid/incoming.gd',code)
    save(HERE/'grid/operations.json',[{'id':'receive-the-saved-sculpture','kind':'replace','before':code,'after':(HERE/'grid/grid.gd').read_text()}])
    for part,main in [('trace','trace.gd'),('grid','grid.gd')]:
        for name in ['assembled.gd','expected.gd']:shutil.copyfile(HERE/part/main,HERE/part/name)
    trace=(OLD/'trace/tutorial.md').read_text(encoding='utf-8')
    trace=trace.replace(block('trace.gd',old),block('trace.gd',code))
    assert block('trace.gd',code) in trace
    trace=trace.replace('- Neighbour loops with for','- Neighbour loops with for\n- Saving the drawing for the next hall')
    trace=trace.replace('The prepared room, light and XR hands remain supplied;', 'Work inside the existing Endless Museum Trace hall. Its room, light and XR hands remain supplied;')
    trace=trace[:trace.index('The museum pens add their own sampling and session-transfer behaviour.')]+'''Release the held point when you have a drawing to keep. The supplied `TraceArchive` saves the retained positions **and the segments already made from them**. Grid will place this saved drawing as a sculpture. You will not draw it again or make another sphere there.

`point.dropped.connect(_save_trace)` connects the existing release event to our save function. Waiting one frame lets the current redraw finish before the snapshot is packed. The transport uses local positions in metres; the museum hall's world offset is not baked into the gesture. The archive has no timestamps. A later valid release replaces your saved drawing. Releasing before two positions exist leaves the previous file alone.

## Supplied transport — trace_archive.gd

Keep this file beside the lesson scripts. It packs a snapshot of the existing segment nodes and stores the position array as metadata. The source trace remains live and unchanged. `user://ada_student_trace.scn` belongs to this Godot project's user-data directory, so Trace and Grid must run in the same project. Serialization is supplied here; arrays, sampling and traversal remain this lesson's focus.

'''+block('trace_archive.gd',(HERE/'trace_archive.gd').read_text())+'''
Carry that saved drawing into Grid. Its position data can be read again; its existing visible form can be placed in another hall.

[Download this lesson](../../../doc/book/iterations/2026-10-06-trace-saved-to-grid/trace-files.zip) · [Museum handoff and tests](../../../doc/book/iterations/2026-10-06-trace-saved-to-grid/index.html)
'''
    write(ROOT/'commons/maps/Point_Trace/tutorial.md',trace)
    write(HERE/'trace/tutorial.md',trace)
    grid='''# Point Grid — place the drawing you made

**Learning elements**

- Loading your saved trace
- Reusing a drawing as a sculpture
- One record, different representations
- Source positions and grid addresses
- Integer coordinates and rounding
- Changing a copy while keeping the original

We are in the Endless Museum. In Trace, you moved the held point and released it to save the drawing. Here, place that drawing beside the ruled field. The gesture has become something you can walk around.

The pink sculpture is your saved work: the same retained positions and the same segment geometry. We do not build another point or ask for another gesture. **One record can support different representations.** Here we derive grid addresses from it and change a separate green copy.

Trace stored selected samples of movement, not the whole continuous gesture. Its ordered array, visible segments and rounded addresses each let us do different work. Keeping the source means another interpretation can begin without pretending that rounding recovered everything the hand did.

## Bring your drawing

Continue in the **same working copy of the museum**. Keep `trace.gd` for returning to Trace. Save `grid.gd` beside `trace_archive.gd` and the unchanged `line_skin.gd`, then attach it to your unit-scale `PointStudy` on the clear floor beside Grid's glass field. The museum provides the hall, light and player.

Release the point in Trace before leaving. The supplied archive stores a snapshot under `user://ada_student_trace.scn`; opening Grid loads that snapshot. Without a saved drawing, the readout asks you to return to Trace. It does not invent a replacement. Grid never writes this file.

The first copy stays pink. A second copy receives its own mesh and material resources before any changes. We reuse the segment renderer from Lines to place those copied segments between rounded positions. The original sculpture keeps the hand's recorded form.

## The complete Grid program — grid.gd

'''+block('grid.gd',(HERE/'grid/grid.gd').read_text())+'''
`load_drawing()` returns the saved sculpture, including its recorded positions. `add_child(sculpture)` places it under this study. The positions are local to the study and measured in metres; the hall supplies the study's location. Moving the study moves the sculpture as a whole without rewriting the gesture.

`duplicate()` makes a second node tree. The saved sculpture is static. We attach the familiar `LineSkin` script only to the copy we want to change, then give each copied segment its own saved mesh and material. Otherwise changing a segment's length or colour could change the pink original. This is the same ownership question we met with two PointBody instances. The archive saves shapes and transforms, so loading the pink sculpture does not rerun its construction script.

## An entry is not an address

`positions[2]` means the third sample in the recorded order. A `Vector3i` address instead counts grid intervals from this study's origin. At a spacing of 0.25 metres, X = 0.10 rounds to address 0; X = 0.15 rounds to 1. X = -0.15 rounds to -1. At exact halfway values, `roundi()` rounds away from zero.

Multiplying the address by the spacing returns a position in metres. The loop visits neighbouring addresses and calls the renderer we already used in Trace. Two entries can receive the same address; they stay in the record, while their zero-length connecting segment becomes invisible. All three coordinates are rounded, including height.

The saved original remains untouched. We change only the green copy's existing segments. Their connections can be diagonal; this is not a route restricted to grid edges.

## Change a rule, keep your work

On desktop, press Enter or Space to compare 0.25 and 0.50 metre spacing. In your code, changing the initial `grid_step` gives the same comparison when you return in VR. Input mapping is supplied here, not the new subject. Both versions load the same saved sculpture; you do not repeat the gesture.

Before switching, choose a corner and predict its new address. Find two visits that acquire the same address. Switch back: the finer interpretation returns because the original data was kept, not because coarse rounding can be reversed.

For one experiment, replace `roundi(p.y / grid_step)` with `0`. Run Grid again. Pink keeps the recorded height; green is placed on the study's Y = 0 plane. Restore the expression. The download includes this tested version.

## Carried renderer — line_skin.gd

The saved segments use this same file from Lines and Trace. Its full code is here for completeness; Grid introduces no new recipe for a sphere, cylinder or face.

'''+block('line_skin.gd',(HERE/'grid/line_skin.gd').read_text())+'''
## Supplied archive — trace_archive.gd

This is the same transport used by Trace. Grid calls its loading function; it does not call `save_drawing()`. Keep the file and renderer paths stable in your working project while using the saved scene.

'''+block('trace_archive.gd',(HERE/'trace_archive.gd').read_text())+'''
One drawing can now be a record, a sculpture and material for another calculation. Keep its original positions. Triangle can select three corners from them and ask what closes the boundary and gives it a face.

[Download the complete lesson](../../../doc/book/iterations/2026-10-06-trace-saved-to-grid/grid-files.zip) · [Museum handoff and tests](../../../doc/book/iterations/2026-10-06-trace-saved-to-grid/index.html)
'''
    write(ROOT/'commons/maps/Point_Line_Grid/tutorial.md',grid)
    write(HERE/'grid/tutorial.md',grid)
    shutil.copyfile(OLD/'trace/verify.gd',HERE/'verify_trace.gd')
    write(HERE/'trace/variants/threshold_020.gd',code.replace('const MIN_SEGMENT_DISTANCE := 0.05','const MIN_SEGMENT_DISTANCE := 0.20'))
    # Names in the inherited verifier are authoritative.
    for p in (OLD/'trace/variants').glob('*.gd'):
        oldvariant=p.read_text()
        # Carry only the predecessor's exact exercise edit into the new main.
        if 'threshold' in p.name: variant=code.replace('const MIN_SEGMENT_DISTANCE := 0.05','const MIN_SEGMENT_DISTANCE := 0.20')
        else: variant=code.replace('range(1, positions.size())','range(1, positions.size() - 1)')
        write(HERE/'trace/variants'/p.name,variant)
    write(HERE/'grid/flat_y.gd',(HERE/'grid/grid.gd').read_text().replace('roundi(p.y / grid_step)','0'))
    print('Prepared saved Trace -> sculpture Grid; two complete tutorials.')
if __name__=='__main__':main()
