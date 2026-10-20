# Four positions enclose a body

## From alignment to a physical body — 17 October 2026

The room now begins with `align_tetrahedron`, followed by `align_wedge`. Release the pink vertex within 12 cm of the ring. A distant release leaves the construction editable; a near release creates the completed rigid body and enables gravity. It can then be picked up and released again. Re-enter the hall for a fresh construction trial.

The tetrahedron already has tetrahedral connectivity before completion. The target restores the particular regular form authored here. For the wedge it restores the triangular prism. Acceptance tests a position, not every possible valid solid.

First reconstruct just the tetrahedron's four positions and faces, as below. Keep that surface separate from the interaction that accepts a target and the physics body created afterwards. The production implementation is `commons/artifacts/primitive_encounters/align_solid.gd`; `geometry.gd` supplies outward normals and matching convex geometry.

The later corner and platform change the scale of the question. First, a central bank of five standing prisms blocks a straight walk. Three clear grid columns on either side let the body go around. Farther ahead, `wp` ramps run forward along both sides and rise onto a broad platform. The sequence is obstruction, detour, support and ascent, then sculpture and a small rearrangeable model. The basin and rock side room follow the descent.

For the central collection, place `prism_block:0:0:2#grain:solid#offset:0.5,0,0.5#plinth:0#pin:1` at (5, 24), (7, 24), (9, 24), (11, 24) and (13, 24). The uniform scale makes each original one-metre prism two metres tall, wide and deep. The half-cell offsets centre each solid over its exact 2 × 2-cell footprint. Together they occupy columns 5–14 and rows 24–25. This leaves three full floor columns on either side: 2–4 and 15–17. The existing static collider scales with the visible geometry.

For the ascent, place `wp:0` at row 29, columns 2–4 and 15–17. All six wedges climb in +Z, along the walk. Each side is three metres wide, with a one-metre rise over a two-metre run. Short inner walls at columns 5 and 14, rows 27–29, hold the two approaches beside the hall's outer walls.

Use structure `2` at columns 2–17 and rows 30–32 for the shared 16 × 3 m platform. Keep `map_info.museum.wall_height: 3`: structure `1` is the normal floor and `2` raises the walking surface one metre. Walls remain explicit `w`. Four `wp:180` units at row 33, columns 8–11, give a centred four-metre-wide descent. The `wedge_palace#layout:map` anchor at (9, 31) preserves the encounter's identity without adding duplicate geometry.

Test a straight approach into the central bank. Then go around its left end and follow the side ramp onto the platform; repeat on the right. Check the low edges and the joins, and continue down to the basin. The signs have no collision. The prisms stop the straight route; the ramps support the ascending route. These checks concern ordinary walking, not an exclusion of jumping, teleporting or flying.

## The wedge becomes sculpture, then a small experiment

`wedge_column` at (6.5, 32) stands on the platform. It instantiates six copies of the existing `prism_block.tscn`, scales each uniformly to 0.65, and turns paired copies by ±90 degrees about Z. Their original bases meet; three pairs form a 1.95 m column. The mesh and collision come from the same scene as the standing blockers. The joints are static. This is a configured sculpture, not a simulated balancing result.

`wedge_mouse_model` at (13, 32) places a 2.8 × 1.0 m plinth on the platform. Its top is 0.82 m above the platform. Seven grabbable construction wedges share exactly the same six vertices and convex collision geometry: 0.22 m width, 0.24 m rise, 0.48 m run. These are right-triangular wedges, related to the stock `wp` profile. The symmetric `prism_block` used in the sculpture has a different triangular profile; rotating it alone would not change that profile.

Build just a pair first. Keep one wedge upright; turn the second by 180 degrees about Z after orienting both along X. Raise the second by 0.24 m. Their sloping faces now meet to form a rectangular platform. Put a third identical wedge alongside with its sloping face exposed: it becomes the approach.

Then give a small body a capsule collider, gravity, and steering from a returning joystick. The player directs the brown wedge mouse; there are no automatic targets. `CharacterBody3D.move_and_slide()` resolves contact with the current surfaces. JUMP launches a ballistic arc in the last steered direction, so a desktop user can release the stick and click the jump control. Returning the stick to centre stops walking.

**Experiment loop:**

1. Grip or pointer-drag the stick. Steer straight into a standing wedge, then around it. Find the incline and climb.
2. Stop near the platform edge, face the cheese, and press JUMP. Releasing the joystick stops walking; the jump retains the last direction.
3. Move only the approach wedge. HOME resets the mouse while preserving the arrangement. Try the same steering again.
4. Restore, then move the landing pair. Compare a low landing with an obstruction before ascent. The cheese is a physical body and falls when unsupported.
5. Turn the pieces and reconstruct a supported course. In VR, grab and rotate; on desktop, Q/E roll and R/F tilt while held. Construction pieces stay where released.
6. RESTORE returns the seven wedges, mouse and cheese. The layout is held for the current scene only; there is no disk save or claim of physics replay.

The joystick and JUMP, HOME and RESTORE share one panel on the plinth's starting end, behind the waiting mouse. Looking along the course, stick-up means forward towards the cheese (+X in model coordinates); stick-right means +Z. The joystick supports hand gripping and pointer dragging; the buttons use hand pokes or ray clicks. Holding a construction piece centres steering and prevents jumping while it is held. The platform crossing and both access ramps remain outside the display footprints.

The mouse and upright cheese each use one bare wedge mesh. A flush strip made from four thin boxes marks the initial approach around the stoppers to the ramp. It has no collider or steering force. Moving a wedge can interrupt that route; the strip does not promise that every edited arrangement remains traversable. The cheese is 0.24 m tall with a 0.18 × 0.18 m base.

## Learning elements

- Shared vertices
- A list of face-index triples
- Tetrahedron connectivity
- Surface enclosure versus collision

## In the museum

A tetrahedron is the smallest closed body made entirely of triangular faces. The museum's polyhedra let you encounter a surface from outside and imagine the volume it encloses. Our construction begins with the same three saved entries used for Triangle and adds one point behind their face.

This lesson reloads the original Trace record. Moving a temporary Triangle handle did not change that file. Use the same CORNERS triple you selected there; the number of stored drawing entries determines which indices are available.

## Make this study

Attach lesson.gd to a unit-scale Node3D named PolyhedronStudy in this hall's working copy. Copy FaceBody, LineSkin and TraceArchive alongside it. No replacement camera, player or room is required.

The body uses a two-sided material so that removing a face lets you see the remaining surfaces from inside. Their winding still defines a front, as in Triangle; this display choice does not add volume or collision.

Carried unchanged from [Lines](../Point_Lines/tutorial.md): `line_skin.gd`. Carried unchanged from [Trace](../Point_Trace/tutorial.md): `trace_archive.gd`. Carried unchanged from [Triangle](../Point_Triangle_Context/tutorial.md): `face_body.gd`.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Archive = preload("trace_archive.gd")
const FaceBody = preload("face_body.gd")
const CORNERS := Vector3i(0, 1, 2)
const DEPTH := 0.6
var points: Array[Vector3] = []
var faces: Array[Vector3i] = [
    Vector3i(0, 1, 2), Vector3i(0, 3, 1),
    Vector3i(1, 3, 2), Vector3i(2, 3, 0)]
var body := FaceBody.new()
var message := Label3D.new()

func _ready() -> void:
    body.surface.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
    add_child(body)
    add_child(message)
    message.position = Vector3(0, 2, 0)
    message.pixel_size = 0.003
    var drawing := Archive.load_drawing()
    if drawing == null:
        message.text = "Bring a drawing from Trace."
        return
    var record: PackedVector3Array = drawing.get_meta("positions")
    drawing.free()
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        if index < 0 or index >= record.size():
            message.text = "Choose three saved indices."
            return
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        points.append(record[index])
    var normal := (points[2] - points[0]).cross(points[1] - points[0])
    if normal.length() < 0.00001 or DEPTH <= 0.0:
        message.text = "Use a valid triangle and a positive depth."
        return
    var centre := (points[0] + points[1] + points[2]) / 3.0
    points.append(centre - normal.normalized() * DEPTH)
    body.show_faces(points, faces)
    message.text = "%d positions; %d faces." % [points.size(), faces.size()]
```

## Read the construction

`points` holds four positions. `faces` holds four **triples of indices into points**. In `Vector3i(0, 3, 1)`, the renderer reads entries zero, three and one; it does not create three new independent corners.

The fourth position starts at the base triangle's centre and moves DEPTH metres behind its front. Using the base normal means the apex remains off the base plane whichever way the saved triangle faces. A zero-area base cannot define that normal; the guard stops before normalizing it. DEPTH must be positive.

Each of the tetrahedron's six edges belongs to exactly two faces. Adjacent faces traverse their common edge in opposite directions, keeping their fronts outside. The renderer reads the same position again wherever its index occurs. For flat lighting it submits separate render vertices per face, but the construction still has four shared positions.

Change `points[3]`, then call `body.show_faces(points, faces)` again. Three faces move with that one entry. Editing an index changes a connection instead. A closed mesh is still only a visible surface: this program adds no collision shape.

## Make it your own

Replace the selected base with another valid triple, then halve DEPTH. Check that all four faces remain and that the apex is still off the base plane. Explain why a fifth copied point would not automatically become part of the enclosure.

Carry the separation between positions and connectivity into Cube. A longer face list will reuse the same renderer.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Polythedra/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
