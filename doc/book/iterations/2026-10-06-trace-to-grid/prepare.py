"""Author this one continuation; preserve earlier native evidence and museum code."""
from pathlib import Path
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PREVIOUS = ROOT/'doc/book/iterations/2026-10-05-point-a-reusable-class/trace'
CANONICAL = ROOT/'commons/maps/Point_Line_Grid/tutorial.md'
def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8', newline='\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p, d): write(p, json.dumps(d, ensure_ascii=False, indent=2)+'\n')
def block(name, code): return f'<!-- student-code:{name} -->\n```gdscript\n{code}```\n'

ADDITION = '''
func _change_pitch(_held_point: Node3D = null) -> void:
    if grid_step == 0.25:
        grid_step = 0.50
    else:
        grid_step = 0.25
    _redraw_grid()

func _redraw_grid() -> void:
    addresses.clear()
    snapped_positions.clear()
    for segment in grid_trail.get_children():
        segment.queue_free()
    if grid_step <= 0.0:
        return

    for p in positions:
        var address := Vector3i(
            roundi(p.x / grid_step),
            roundi(p.y / grid_step),
            roundi(p.z / grid_step)
        )
        addresses.append(address)
        snapped_positions.append(Vector3(address) * grid_step)

    for i in range(1, snapped_positions.size()):
        var a := snapped_positions[i - 1]
        var displacement := snapped_positions[i] - a
        var segment := LineSkin.new()
        var finish := segment.material_override as StandardMaterial3D
        finish.albedo_color = Color(0.25, 0.85, 0.60)
        grid_trail.add_child(segment)
        segment.show_segment(a, displacement, displacement.length())
'''

OPS = [
 {'id':'room-for-address-readout','kind':'replace','before':'    readout.position = Vector3(0, 1.6, 0)\n    readout.font_size = 36\n    readout.pixel_size = 0.005\n','after':'    readout.position = Vector3(0, 2.0, 0)\n    readout.font_size = 36\n    readout.pixel_size = 0.003\n'},
 {'id':'grid-state','kind':'insert_after','anchor':'var trail: Node3D\n','text':'var grid_step := 0.25\nvar addresses: Array[Vector3i] = []\nvar snapped_positions: Array[Vector3] = []\nvar grid_trail: Node3D\n'},
 {'id':'prepare-comparison','kind':'insert_after','anchor':'    positions.append(point.position)\n','text':'\n    grid_trail = Node3D.new()\n    add_child(grid_trail)\n    point.action_pressed.connect(_change_pitch)\n    _redraw_grid()\n'},
 {'id':'desktop-control','kind':'insert_after','anchor':'func _process(_delta: float) -> void:\n','text':'    if Input.is_action_just_pressed("ui_accept"):\n        _change_pitch()\n\n'},
 {'id':'derive-after-sample','kind':'insert_after','anchor':'            segment.show_segment(a, displacement, displacement.length())\n','text':'\n        _redraw_grid()\n'},
 {'id':'inspect-address','kind':'insert_after','anchor':'    readout.text += "\\nPOINTS " + str(positions.size())\n','text':'    readout.text += "\\nPITCH " + str(grid_step) + " m"\n    if not addresses.is_empty():\n        readout.text += "\\nLAST ADDRESS " + str(addresses[addresses.size() - 1])\n'+ADDITION},
]

def compose(code, operations):
    for op in operations:
        before = op.get('anchor',op.get('before'))
        after = before+op['text'] if op['kind']=='insert_after' else op['after']
        assert code.count(before)==1, op['id']
        code=code.replace(before,after,1)
    return code

def main():
    HERE.mkdir(parents=True,exist_ok=True)
    if not (HERE/'before/tutorial.md').exists():
        (HERE/'before').mkdir(exist_ok=True)
        shutil.copyfile(CANONICAL,HERE/'before/tutorial.md')
        shutil.copyfile(ROOT.parent/'ada_encyclopedia/ghost-student/manifest.json',HERE/'before/ghost-manifest.json')
        save(HERE/'before/protected.json',{str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in [ROOT/'commons/maps/Point_Line_Grid/final.md',ROOT/'commons/maps/Point_Line_Grid/map_data.json',ROOT/'commons/maps/Point_Trace/tutorial.md',*PREVIOUS.glob('*.gd'),PREVIOUS/'report-runtime.json']})
    incoming=(PREVIOUS/'trace.gd').read_text(encoding='utf-8')
    code=compose(incoming,OPS)
    body=(PREVIOUS/'point_body.gd').read_text(encoding='utf-8')
    skin=(PREVIOUS/'line_skin.gd').read_text(encoding='utf-8')
    for name,text in {'grid.gd':code,'incoming.gd':incoming,'assembled.gd':code,'expected.gd':code,'point_body.gd':body,'line_skin.gd':skin}.items():write(HERE/name,text)
    save(HERE/'operations.json',OPS)
    lesson='''# Point Grid — give your trace addresses

**Learning elements**

- Reusing the PointBody and its trace
- A list index and a spatial address
- Integer coordinates with Vector3i
- Rounding at a chosen grid spacing
- Source and derived position arrays
- Comparing two rules on the same record

We are in the Endless Museum's Grid hall. Find the ruled field and the sphere that snaps to its addresses. These artifacts are already here. Your work continues the small point and recorder you built in Trace: draw a bend, keep its positions in pink, then give each one a grid address in green. Change the spacing and compare what happens.

In the museum, Grid returns to drawings made in Trace. Our learner program continues the working Trace code in the same `PointStudy`. Its positions remain local to that station; we do not borrow the production pen's world-coordinate session store or enlarge the drawing to fit a display.

## Continue the program

Save `grid.gd` beside the unchanged `point_body.gd` and `line_skin.gd` from [Trace](../Point_Trace/tutorial.md). Keep `trace.gd`, and attach this continuation to your unit-scale `PointStudy` in your working copy of Endless Museum. Work on the clear floor beside the Grid hall's glass field; the [workplace report](../../../doc/book/iterations/2026-10-06-trace-to-grid/index.html#workplace) shows the tested placement. This script creates your point and its two drawings. The existing museum supplies the room, light, player and XRTools; its other artifacts remain available to inspect.

Start this version and draw a short shape. It uses Trace's existing recorder: the same sphere, the same five-centimetre acceptance condition, the same array and pink neighbour lines. The new program derives its green copy from that array. Restarting begins a new drawing; this lesson does not import a drawing from a previous run or transport it to another hall.

Hold the sphere still and press its existing XR action, or press **Enter / Space** on desktop. The pitch switches between 0.25 and 0.50 metres. This small input connection is supplied here to compare the same record without restarting; named actions and signals receive a fuller lesson in Transformation. On desktop, retain your prepared player/input setup from Coordinates.

## The complete continuation — grid.gd

'''+block('grid.gd',code)+'''
The original `positions` array still belongs to the recorder. `_redraw_grid()` reads it; it never assigns a rounded value back into it. We call that function after accepting a position and after changing the pitch. A function lets both occasions use the same instructions.

## Which entry, which place?

`positions[2]` selects the third retained sample. Its index describes its place in the list, not its place in the room.

`Vector3i` holds three integers. Here they count grid intervals from the station's origin. Divide each component of `p` by `grid_step`, then `roundi()` chooses the nearest integer. At a pitch of 0.25 metres, X = 0.10 gets address 0 and X = 0.15 gets address 1. Negative X = -0.15 gets address -1.

Exactly halfway, `roundi()` rounds away from zero: +0.125 gets address +1 and -0.125 gets -1 at this pitch. This tie rule matters at a boundary; it is part of our chosen calculation.

An address is a count of intervals. `Vector3(address) * grid_step` turns those counts back into a position in metres. Address `(1, 4, -2)` at pitch 0.25 becomes `(0.25, 1.0, -0.5)`. X, Y and Z are all rounded. The museum floor may show a flat ruling, but this operation also assigns height an address.

`addresses[i]` and `snapped_positions[i]` both come from `positions[i]`. The three lists keep the same length and order. Several entries can acquire the same address. We keep those visits, including returns to an earlier address; our unchanged drawing helper hides a zero-length segment when two neighbours coincide. It does not erase either entry.

## Change the rule, keep the drawing

Pause your hand before switching pitch. `_change_pitch()` changes one number and calls the same derivation again. `clear()` empties the two derived arrays and the old green segment nodes are queued for removal. The source list and pink drawing remain. Reducing the pitch again recovers the finer **derivation** because its original samples are still available; it cannot recover movement Trace never recorded.

The coordinate readout still follows the live point. LAST ADDRESS describes the last retained sample. Small hand movements can change the readout without adding a sample or changing that address. Green connects neighbouring results directly; those segments can be diagonal. Where both drawings coincide, their surfaces can overlap.

Both drawings use the same station frame and unit scale. Moving or turning the whole station carries them together. There is no centring, fitting or extra display offset in this example. Those would be separate transformations to declare later.

## Make one prediction

Draw a corner, then return towards an earlier location. Hold still. Before switching to the coarser pitch, choose a retained sample and predict its address in X, Y and Z. Which two entries might meet? Switch and inspect the result. Switch back without moving the sphere: the finer result is calculated again from the same source.

For one code experiment, replace `roundi(p.y / grid_step)` with `0` in the address construction. Run it and draw upward. Pink still records height; green lies on the station's Y = 0 plane. You changed the interpretation, not the recorded gesture. Restore the original expression. The download includes the complete tested variant.

## The carried point — point_body.gd

Keep this file unchanged from Lines and Trace. The record and its new interpretation remain outside the point class.

'''+block('point_body.gd',body)+'''
## The drawing helper — line_skin.gd

This is the same complete renderer from Lines and Trace. The green drawing changes the colour of its own material; its cylinder placement and zero-length guard remain supplied. Neither drawing adds collision.

'''+block('line_skin.gd',skin)+'''
You now have one retained drawing and more than one way to place its samples. Carry the source, its grid addresses and the derived positions forward. Triangle will select three positions and ask what it takes to close a boundary and give it a face.

[Download the three scripts](../../../doc/book/iterations/2026-10-06-trace-to-grid/grid-three-files.zip) · [Code, comparison and test evidence](../../../doc/book/iterations/2026-10-06-trace-to-grid/index.html) · [Ghost Student](http://localhost:3003/ghost-student?state=point-grid)
'''
    write(CANONICAL,lesson)
    write(HERE/'tutorial.md',lesson)

if __name__=='__main__':main()
