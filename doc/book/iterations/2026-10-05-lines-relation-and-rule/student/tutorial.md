# Point Lines — what can two lines do?

**Learning elements**

- Endpoints and a segment
- Displacement and distance
- Reusing an object
- Parallel, cross and X
- Position in depth

Take one end of the line in the black room. The other stays. The span between them turns and changes length. What have you moved: a point, or a line?

Continue with your pickable point from Coordinates. Keep its construction. We will make a second point and draw the segment between them. Later in the hall, two lines become parallel planks, a plus and an X. We will try those relations with the same small construction.

Use the same student station and configured XR hand as the [Coordinates reconstruction](../../../doc/book/iterations/2026-10-05-lesson-state-chain/tutorial.md). Keep the station's scale at one. Save the supplied [line_skin.gd](../../../doc/book/iterations/2026-10-05-lines-relation-and-rule/student/line_skin.gd) beside your script. It draws a thin cylinder; we will give it a start, a displacement and a length. The museum supplies the room and hands. This helper supplies the visible thickness and orientation.

## Keep the point; give it another end

Below `CENTRE`, before `_ready()`, add:

~~~gdscript
const LineSkin = preload("line_skin.gd")
var point_a: XRToolsPickable
var point_b: XRToolsPickable
var line: MeshInstance3D
var distance := 0.0
~~~

These names belong to the script, so both `_ready()` and `_process()` can use them. `preload` loads the supplied drawing script. The types after `:` say what kind of node each reference will hold.

Keep your existing `_ready()` construction. Immediately after `body.reparent(solid)`, add:

~~~gdscript
	point_a = solid
	point_b = solid.duplicate() as XRToolsPickable
	point_b.name = "SecondPoint"
	point_b.position = CENTRE + Vector3(1.0, 0, 0)
	add_child(point_b)
	line = LineSkin.new()
	line.name = "Segment"
	add_child(line)
~~~

These lines remain inside `_ready()`. `point_a` refers to the point you already made. `duplicate()` copies that body and its children, including the surface and collider; `as XRToolsPickable` identifies the result's type. The copy begins one unit along X. It has its own position and can be held independently. The two points share mesh and material resources; this lesson changes their positions.

`line` is the drawing between them. It has no collision boundary or pickup behaviour. Moving an endpoint will determine where it appears.

## Read the relation

Add this function after the existing functions:

~~~gdscript
func _process(_delta: float) -> void:
	var a := to_local(point_a.global_position)
	var b := to_local(point_b.global_position)
	var displacement := b - a
	distance = displacement.length()
	line.show_segment(a, displacement, distance)
~~~

We reuse Point Zero's repeated update and Coordinates' change of frame. Both world positions are converted into this station's local coordinates. Subtracting positions in different frames would give a misleading result.

`b - a` gives the displacement from A to B. Initially it is `(1, 0, 0)`: one unit along X. `.length()` returns one number, `1.0`. The displacement contains direction and length; the distance contains length alone. With the station at unit scale, one unit is one metre.

`show_segment` receives those values. The helper centres the cylinder between the ends and turns it along the displacement. Its source is included; building an orientation basis can wait.

Run your working copy. Move either point. The segment follows because the relation is read again each frame. Release the point: it stays, and the segment stays with it.

Change B's starting offset to `Vector3(0, 1.0, 0)`. Predict the result. The span stands upright but keeps its length. Reverse the subtraction to `a - b`: its length is unchanged, but the drawing now points the other way from A. Restore `b - a`.

## What can two lines do?

Look at the parallel planks, the plus and the X in the hall. A second segment gives us something to arrange in relation to the first. After `add_child(line)` in `_ready()`, add:

~~~gdscript
	point_a.position = Vector3(-0.6, 1.42, 0)
	point_b.position = Vector3(0.6, 1.42, 0)
	var c := Vector3(0, 0.82, 0)
	var d := Vector3(0, 2.02, 0)
	var other_line := LineSkin.new()
	other_line.name = "OtherSegment"
	add_child(other_line)
	other_line.show_segment(c, d - c, (d - c).length())
~~~

This makes a plus. A and B are still the positions of held bodies. C and D are position values: we have given them no spheres or pickup bodies. The second segment is drawn once in `_ready()` and stays while you move the first. A position can define an end without becoming something we can grab.

Change these four assignments to try another arrangement. All values use the same station frame.

| Arrangement | A | B | C | D |
|---|---|---|---|---|
| Parallel | (-0.6, 1.12, 0) | (0.6, 1.12, 0) | (-0.6, 1.62, 0) | (0.6, 1.62, 0) |
| Plus | (-0.6, 1.42, 0) | (0.6, 1.42, 0) | (0, 0.82, 0) | (0, 2.02, 0) |
| X | (-0.6, 0.82, 0) | (0.6, 2.02, 0) | (-0.6, 2.02, 0) | (0.6, 0.82, 0) |

The first segment joins A to B; the second joins C to D. Complete versions are available for [parallel](../../../doc/book/iterations/2026-10-05-lines-relation-and-rule/student/two_lines_parallel.gd), [plus](../../../doc/book/iterations/2026-10-05-lines-relation-and-rule/student/two_lines_plus.gd) and [X](../../../doc/book/iterations/2026-10-05-lines-relation-and-rule/student/two_lines_x.gd).

Make an X. Then set the Z component of both C and D to `0.2`. Viewed straight on, the lines can still look crossed. Step sideways: they occupy different depths. The hall's plus and X use a smaller separation to make this same distinction available to your movement.

No new shared vertex is created where the drawings cross. Our code still holds four endpoints and two relations. Nor does making an X cause damage: the museum's hurt and recovery passage adds that behaviour separately.

Choose another arrangement of your own. Predict which endpoints need to move, then make it. Can you preserve each segment's length while changing what the pair suggests?

## What the line keeps

Give B the same position as A. The displacement and distance become zero. The supplied helper hides spans of `0.0001` units or less; it cannot orient a segment with no direction.

Separate the ends again. Carry B around a detour and return it to its starting place. The line returns to the same span. It has kept no journey.

Carry forward the two positions and the operation that joins them. Trace will keep more positions, in order, so that a detour can remain.
