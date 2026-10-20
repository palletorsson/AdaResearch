# Foundations Crisis — complete tutorial sequence

Eight halls in the existing Endless Museum. Review snapshot, 12 October 2026.

<!-- Source: commons/maps/Euclid_Parallel/tutorial.md -->

# The same triangle, measured

## Learning elements

- Constructing a parallel through a point.
- Measuring a triangle's interior angles.
- Assumptions, measurements and proof.
- Recognising a degenerate construction.

**Carry:** PointBody, the finite cylinder from Point Lines, three vertices and a triangle face. **New:** calculate the three angles and construct a parallel using the base direction. **Supplied:** the existing Endless Museum, its desktop/XR player, XRTools and the named push-button scene. We are working inside that project.

## Encounter

Find the postulates plaque, the three parallel line modules and the small triangle in Euclid's hall. NEXT changes the sentence; GOLD changes its emphasis. Neither changes the room's geometry. The old flat triangle's three “60°” labels are fixed text even though its corners are unequal. Our study will read the positions instead.

Return to the object you can already build: three points joined by three segments. Move a corner. Its individual angles change. What happens to their sum? Add a guide through C parallel to AB; hide it again. Does removing a drawing remove the relationship?

## Reuse the bodies

Create a folder in your museum working copy. Save the four scripts printed below together. The small `point_body.gd` is unchanged from Graph Theory and Gradient Landscape; `line_skin.gd` is unchanged from Point Lines. They are reprinted at the end for a complete reconstruction, not taught again. We reuse the class and construction; no live sphere or Machine Learning weights are transferred across hall loads.

Create one empty Node3D named `EuclidStudy`, keep its scale at `(1, 1, 1)`, and attach `euclid_study.gd`. Put it on clear floor in your working copy of the Euclid hall; allow 2.8 metres for the table and an approach on its local +Z side. The supplied `res://doc/book/studies/euclid-lineage/museum.tscn` launcher opens the existing hall and mounts this study at a checked position. To run your reconstructed folder, change the `LESSON` preload in `res://doc/book/studies/euclid-lineage/museum.gd` to your `euclid_study.gd`, then run the launcher scene with F6. It is room infrastructure, not a second geometry implementation. No replacement camera, light or player is part of the lesson.

## Keep positions; calculate angles

The array stores A, B and C in table coordinates. A Vector2's second coordinate becomes local Z; every measured point lies on the same plane. At each corner, subtract that position from the other two to obtain two outward vectors. `atan2(abs(cross), dot)` gives their interior angle. Sum those three measured values; do not print 180 as the answer.

`cross` here is the scalar 2D cross product. Its magnitude is twice the area. If the points coincide or nearly align, we withhold the angle reading. `EPS` is a numerical policy for this study, not a new geometric postulate. The relative area check rejects very thin triangles too.

For the parallel, copy the direction B − A and centre the visible segment on C. Equal directions in this flat coordinate model construct parallel supporting lines when C is off AB. The cylinder has finite length; the mathematical line does not end at its cap.

Save `triangle_record.gd`:

<!-- student-code:triangle_record.gd -->
```gdscript
extends RefCounted
## A flat construction in metres. Positions and measurements are separate records.
const EPS := 0.00001
var points: Array[Vector2] = []

func _init() -> void:
    reset()

func reset() -> void:
    points.assign([Vector2(-0.7, 0.4), Vector2(0.7, 0.4), Vector2(0, -0.6)])

func measure() -> Dictionary:
    var ab := points[1] - points[0]
    var ac := points[2] - points[0]
    var bc := points[2] - points[1]
    var longest := maxf(ab.length(), maxf(ac.length(), bc.length()))
    var twice_area := absf(ab.cross(ac))
    # Refuse coincident or nearly collinear corners at this numerical scale.
    if longest <= EPS or twice_area <= EPS * longest * longest:
        return {"valid": false, "angles": [], "sum": 0.0, "area": twice_area * 0.5}
    var angles: Array[float] = []
    var total := 0.0
    for i in range(3):
        var u := points[(i + 1) % 3] - points[i]
        var v := points[(i + 2) % 3] - points[i]
        var angle := rad_to_deg(atan2(absf(u.cross(v)), u.dot(v)))
        angles.append(angle)
        total += angle
    return {"valid": true, "angles": angles, "sum": total, "area": twice_area * 0.5}

func parallel_ends(half_length: float = 1.25) -> Array[Vector2]:
    var direction := points[1] - points[0]
    if direction.length() <= EPS:
        return []
    direction = direction.normalized() * half_length
    return [points[2] - direction, points[2] + direction]
```

## Put the construction in the hand

The host creates every point, segment, label, face and control. There are no hidden scene-node references. GUIDE—or G, or a held point's trigger—only hides/shows the gold construction. RESET—or R—restores the three starting positions and keeps the guide setting. Put all points down before resetting.

The hand may move in three dimensions. We convert its world position into this study's local frame, keep X and Z and limit them to ±1 metre. While held, the sphere stays in your hand; the edges and corner label show its projected, bounded position. On release it rests at that recorded position. The tabletop is a visual guide, not a physical constraint. Moving or rotating the whole unit-scale study does not change this local construction.

Save `euclid_study.gd`:

<!-- student-code:euclid_study.gd -->
```gdscript
extends Node3D
const Triangle = preload("triangle_record.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const HEIGHT := 1.12
var model := Triangle.new()
var points: Array = []
var edges: Array = []
var labels: Array[Label3D] = []
var guide := LineSkin.new()
var face := MeshInstance3D.new()
var readout := Label3D.new()
var guide_on := true

func place(p: Vector2) -> Vector3:
    return Vector3(p.x, HEIGHT, p.y)

func _ready() -> void:
    var top := MeshInstance3D.new()
    var slab := BoxMesh.new()
    slab.size = Vector3(2.8, 0.08, 2.8)
    top.mesh = slab
    top.position.y = HEIGHT - 0.16
    top.material_override = finish(Color("e2ded5"))
    add_child(top)
    for i in range(3):
        var point := PointBody.new()
        point.name = ["A", "B", "C"][i]
        add_child(point)
        points.append(point)
        point.action_pressed.connect(func(_hand): toggle_guide())
        var edge := LineSkin.new()
        add_child(edge)
        edges.append(edge)
        var label := Label3D.new()
        label.font_size = 26
        label.outline_size = 0
        label.pixel_size = 0.002
        label.modulate = Color("25212a")
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        add_child(label)
        labels.append(label)
    add_child(guide)
    guide.material_override = finish(Color("a27622"))
    face.material_override = finish(Color("b2c2ca"))
    add_child(face)
    readout.position = Vector3(0, 1.65, -1.0)
    readout.font_size = 24
    readout.outline_size = 6
    readout.outline_modulate = Color.WHITE
    readout.pixel_size = 0.002
    readout.modulate = Color("25212a")
    readout.no_depth_test = false
    add_child(readout)
    make_button("Guide", Vector3(-0.35, 1.03, 1.15), toggle_guide)
    make_button("Reset", Vector3(0.35, 1.03, 1.15), reset)
    redraw()

func finish(colour: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = 0.6
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func make_button(word: String, where: Vector3, callback: Callable) -> void:
    var button = PushButton.instantiate()
    button.name = word
    button.rotation = Vector3.ZERO
    button.position = where
    add_child(button)
    button.pressed.connect(callback)
    var label := Label3D.new()
    label.text = word.to_upper()
    label.position = where + Vector3(0, 0.13, 0)
    label.font_size = 22
    label.outline_size = 0
    label.pixel_size = 0.002
    label.modulate = Color("25212a")
    add_child(label)

func toggle_guide() -> void:
    guide_on = not guide_on
    redraw()

func reset() -> void:
    for point in points:
        if point.held(): return
    model.reset()
    redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_G: toggle_guide()
        if event.keycode == KEY_R: reset()

func _process(_delta: float) -> void:
    for i in range(3):
        if points[i].held():
            var local := to_local(points[i].global_position)
            model.points[i] = Vector2(clampf(local.x, -1, 1), clampf(local.z, -1, 1))
    redraw()

func _physics_process(_delta: float) -> void:
    # Frozen rigid bodies need their released display position maintained too.
    for i in range(points.size()):
        if not points[i].held(): points[i].global_position = to_global(place(model.points[i]))

func redraw() -> void:
    var result := model.measure()
    for i in range(points.size()):
        var a := place(model.points[i])
        var b := place(model.points[(i + 1) % 3])
        if not points[i].held(): points[i].global_position = to_global(a)
        edges[i].show_segment(a, b - a, a.distance_to(b))
        labels[i].position = a + Vector3(0, 0.18, 0)
        labels[i].text = "%s: %.2f°" % [["A", "B", "C"][i], result.angles[i]] if result.valid else ["A", "B", "C"][i] + ": —"
    var ends := model.parallel_ends()
    guide.hide()
    if guide_on and result.valid and ends.size() == 2:
        var start := place(ends[0])
        var displacement := place(ends[1]) - start
        guide.show_segment(start, displacement, displacement.length())
    face.mesh = null
    if result.valid:
        var builder := SurfaceTool.new()
        builder.begin(Mesh.PRIMITIVE_TRIANGLES)
        for p in model.points: builder.add_vertex(place(p) + Vector3.DOWN * 0.018)
        builder.generate_normals()
        face.mesh = builder.commit()
    readout.text = "MOVE A, B OR C / trigger or G: guide / R: reset\nHand projects onto this flat table; x and z stay within ±1 m.\n"
    readout.text += "Measured sum %.2f° / area %.3f m²\nGuide through C copies the direction B − A." % [result.sum, result.area] if result.valid else "No triangle reading: corners coincide or nearly align.\nSeparate the points to measure again."
```

## Predict, then try

1. Move only C. Predict which angles grow and which shrink; compare their measured sum. The initial sum should be near 180°, within floating-point error, without three equal corners.
2. Hide the guide. A, B, C and their measurements must remain unchanged. Show it again: its direction should still match B − A.
3. Put C on AB, or put A on B. The study should withhold its triangle reading and face. Separate them and recover it.
4. Make your own scalene triangle. Record its three positions before running. Predict that doubling all coordinates doubles lengths and quadruples area while keeping each angle. Try this in a separate model copy: the hand interface deliberately limits its workspace. Explain any failed comparison before changing the prediction.

An assertion should compare calculated values, not a label that contains the desired answer. Test `(0,0), (1,0), (0,1)`: the three measured angles should be 90°, 45°, 45°, and the area 0.5. Test coincident and collinear positions separately. Test the full host too: three visible point bodies, initialized readout, grab/release, and the two buttons must work.

## What the test means

We chose Cartesian coordinates, straight segments and Euclidean angle measurement before running. A thousand successful drags check this implementation in that model. They do not prove the parallel postulate from the others, or establish which geometry every space must have.

Euclid's Proposition I.32 constructs a parallel through a vertex and reasons with equal angles to derive the triangle sum. Our gold segment recalls that construction; it is not a formal proof checker. Euclid's fifth postulate concerns which extended lines meet when a transversal makes particular interior angles. The familiar “one parallel through an external point” formulation is a later equivalent formulation in the usual Euclidean setting. [Postulate 5](https://mathcs.clarku.edu/~djoyce/elements/bookI/post5.html) · [Proposition I.32](https://mathcs.clarku.edu/~djoyce/elements/bookI/propI32.html).

Carry the three points, the measured result and the assumptions into **Non-Euclidean Spaces**. There we must define the surface and its straightest paths before comparing corner angles. Bending these cylinders on the same table would not, by itself, supply that geometry.

## Carried files, complete

Copy these unchanged if they are not already beside your new scripts. Their source versions are the small PointBody used in Gradient Landscape and Point Lines' LineSkin. The button dependency is `res://commons/interactables/push_button.tscn`; XRTools supplies `XRToolsPickable`. Both belong to the prepared museum project. A blank Godot project does not include them.


### point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

### line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


---

<!-- Source: commons/maps/NonEuclidean_Spaces/tutorial.md -->

# What counts as straight

## Learning elements

- A surface and its geodesic edges.
- Tangent directions at a corner.
- Comparing angles under two geometric models.
- Keeping a record while changing its interpretation.

**Carry:** Euclid's three-point record, PointBody, LineSkin and triangle construction. **New:** a spherical interpretation, great-circle edge samples and tangent-based angle measurements. **Supplied:** the existing Endless Museum, player, XRTools and push-button scene. We continue inside that project.

## Encounter

At the installed triangle workbench, HOST selects PLANE, SPHERE or DISK. Each setting has its own triangle and edge rule. It is a comparison, not a continuous curvature control for the whole room. The separate slider changes its own surface sketch.

Our coding task is smaller: continue Euclid's three grabbable points through **PLANE → SPHERE**. The existing disk remains a further comparison to visit. We will not mistake a radial warp for a new distance model.

Create a folder beside your Euclid working copy. Keep `triangle_record.gd`, `point_body.gd` and `line_skin.gd` unchanged; their complete listings are at the end. Add the two new files below. Attach `surface_study.gd` to a unit-scale Node3D named SurfaceStudy. The supplied `res://doc/book/studies/noneuclid-lineage/museum.tscn` launcher opens the real hall and mounts the study on clear floor; run that scene with F6 to visit it. To mount your own reconstructed folder, change the launcher's `LESSON` preload to your host script. No replacement camera, light or player is needed.

## Keep three pairs; change their meaning

The new model extends `triangle_record.gd`. It inherits the same `points` array, starting values and reset. PLANE calls the previous measurement unchanged. SPHERE reads each pair `(x,z)` as the direction `(x,1,z)`, normalized to a point on the unit sphere. This chart covers its upper hemisphere. Our hand interface uses only the bounded central patch, where x and z stay between −1 and 1.

Switching models preserves the pairs and point-body instances. It does **not** preserve world positions, lengths or angles. The pairs were planar positions; now they select directions from the sphere's centre. This is a declared correspondence, not an isometry or a saved live object travelling between scene loads.

Between two sphere points, blend their vectors and normalize the result. Every sample lies on the sphere and in the plane through both endpoints and its centre: the shorter great-circle arc. Our upper-hemisphere restriction avoids antipodal endpoints, where the short route would not be unique. The samples are not equally spaced in arc length. The cylinders joining them are a finite drawing of the curve.

At a spherical corner `a`, the surface normal is `a` itself. Remove the part of `b` along that normal: `b - a * a.dot(b)`. Normalize what remains. That is the outgoing tangent toward `b`. Use the two outgoing tangents to measure the corner, with the same cross/dot angle operation as before. The readout uses these analytical tangents, not the angle between rendered cylinder pieces.

Euclid's degeneracy check still matters. In this chart, collinear coordinate pairs map to one great circle. We keep the existing numerical refusal instead of reporting a triangle with an interior. The inherited tolerance is a computational policy.

Save `surface_triangle.gd`:

<!-- student-code:surface_triangle.gd -->
```gdscript
extends "triangle_record.gd"
## The same coordinate pairs; two different interpretations of position and edge.
var spherical := false

func corner(p: Vector2) -> Vector3:
    if spherical: return Vector3(p.x, 1.0, p.y).normalized()
    return Vector3(p.x, 0.0, p.y)

func tangent(a: Vector3, b: Vector3) -> Vector3:
    if spherical: return (b - a * a.dot(b)).normalized()
    return (b - a).normalized()

func measure() -> Dictionary:
    var flat := super.measure()
    # In this upper-hemisphere chart, collinear pairs also map to one great circle.
    if not spherical or not flat.valid: return flat
    var angles: Array[float] = []
    var total := 0.0
    for i in range(3):
        var a := corner(points[i])
        var u := tangent(a, corner(points[(i + 1) % 3]))
        var v := tangent(a, corner(points[(i + 2) % 3]))
        var angle := rad_to_deg(atan2(u.cross(v).length(), u.dot(v)))
        angles.append(angle)
        total += angle
    return {"valid": true, "angles": angles, "sum": total}

func edge(index: int, pieces: int = 24) -> Array[Vector3]:
    var a := corner(points[index])
    var b := corner(points[(index + 1) % 3])
    var samples: Array[Vector3] = []
    pieces = maxi(1, pieces)
    for i in range(pieces + 1):
        var p := a.lerp(b, float(i) / pieces)
        samples.append(p.normalized() if spherical else p)
    return samples
```

## Put the changed path in your hand

We keep PointBody's shape and grab behaviour. LineSkin returns many times: 24 short cylinders approximate each edge. The plane keeps its triangle face. On the sphere, the sphere's own skin replaces that flat face; joining only the three corners with a flat face would cut through the body.

PLANE/P and SPHERE/S change the interpretation only after every point is released. RESET/R restores the pairs and keeps the current model. A mode switch does not recreate the PointBody instances.

For a held point, convert the hand's world position to this study's local frame. On the plane, keep X and Z as before. On the sphere, subtract its centre and divide X and Z by Y to invert our direction chart. Bound the resulting pair to the same workspace. A hand at or below the chart's equator is refused; the last record remains and the readout says so. The small 0.02-metre guard avoids division near zero. On release the sphere point returns to the recorded surface position.

The display sphere has radius 0.75 metres. Scaling a display this way preserves its corner angles. It does not give the museum floor a spherical metric. Neither displayed surface constrains the player physically.

Save `surface_study.gd`:

<!-- student-code:surface_study.gd -->
```gdscript
extends Node3D
const SurfaceTriangle = preload("surface_triangle.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const HEIGHT := 1.12
const CENTRE := Vector3(0, 0.82, 0)
const RADIUS := 0.75
const PIECES := 24
var model := SurfaceTriangle.new()
var points: Array = []
var edges: Array = []
var labels: Array[Label3D] = []
var plane := MeshInstance3D.new()
var sphere := MeshInstance3D.new()
var face := MeshInstance3D.new()
var readout: Label3D
var hand_refused := false

func display(p: Vector3) -> Vector3:
    return CENTRE + RADIUS * p if model.spherical else p + Vector3.UP * HEIGHT

func finish(colour: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = 0.6
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _ready() -> void:
    var slab := BoxMesh.new()
    slab.size = Vector3(2.4, 0.04, 2.4)
    plane.mesh = slab
    plane.position.y = HEIGHT - 0.1
    plane.material_override = finish(Color("e2ded5"))
    add_child(plane)
    var skin := SphereMesh.new()
    skin.radius = RADIUS
    skin.height = RADIUS * 2
    skin.radial_segments = 64
    skin.rings = 32
    sphere.mesh = skin
    sphere.position = CENTRE
    sphere.material_override = finish(Color("b2c2ca"))
    add_child(sphere)
    face.material_override = finish(Color("b2c2ca"))
    add_child(face)
    for i in range(3):
        var point := PointBody.new()
        point.name = ["A", "B", "C"][i]
        add_child(point)
        points.append(point)
        var label := make_label("", 25)
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        labels.append(label)
    for i in range(3 * PIECES):
        var line := LineSkin.new()
        add_child(line)
        edges.append(line)
    readout = make_label("", 24)
    readout.position = Vector3(0, 1.95, -1)
    var console := MeshInstance3D.new()
    var board := BoxMesh.new()
    board.size = Vector3(2.1, 0.08, 0.44)
    console.mesh = board
    console.position = Vector3(0, 0.96, 1.35)
    console.material_override = finish(Color("e2ded5"))
    add_child(console)
    make_button("Plane", -0.6, func(): select(false))
    make_button("Sphere", 0.0, func(): select(true))
    make_button("Reset", 0.6, reset)
    redraw()

func make_label(word: String, size: int) -> Label3D:
    var label := Label3D.new()
    label.text = word
    label.font_size = size
    label.pixel_size = 0.002
    label.modulate = Color("25212a")
    label.outline_size = 6
    label.outline_modulate = Color.WHITE
    add_child(label)
    return label

func make_button(word: String, x: float, callback: Callable) -> void:
    var button = PushButton.instantiate()
    button.name = word
    button.rotation = Vector3.ZERO
    button.position = Vector3(x, 1.03, 1.35)
    add_child(button)
    button.pressed.connect(callback)
    make_label(word.to_upper(), 22).position = Vector3(x, 1.16, 1.35)

func any_held() -> bool:
    for point in points:
        if point.held(): return true
    return false

func select(spherical: bool) -> void:
    if any_held(): return
    model.spherical = spherical
    hand_refused = false
    redraw()

func reset() -> void:
    if any_held(): return
    model.reset()
    hand_refused = false
    redraw()

func record_hand(index: int, local: Vector3) -> bool:
    var p := Vector2(local.x, local.z)
    if model.spherical:
        var direction := local - CENTRE
        # Below/too near the equator, this chart has no safe inverse.
        if direction.y <= 0.02: return false
        p = Vector2(direction.x, direction.z) / direction.y
    model.points[index] = Vector2(clampf(p.x, -1, 1), clampf(p.y, -1, 1))
    return true

func _process(_delta: float) -> void:
    var changed := hand_refused
    hand_refused = false
    for i in range(points.size()):
        if points[i].held():
            if not record_hand(i, to_local(points[i].global_position)): hand_refused = true
            changed = true
    if changed: redraw()

func _physics_process(_delta: float) -> void:
    for i in range(points.size()):
        if not points[i].held(): points[i].global_position = to_global(display(model.corner(model.points[i])))

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_P: select(false)
        if event.keycode == KEY_S: select(true)
        if event.keycode == KEY_R: reset()

func redraw() -> void:
    var result := model.measure()
    plane.visible = not model.spherical
    sphere.visible = model.spherical
    for i in range(points.size()):
        var p := display(model.corner(model.points[i]))
        if not points[i].held(): points[i].global_position = to_global(p)
        labels[i].position = p + Vector3.UP * 0.18
        labels[i].text = "%s: %.2f°" % [["A", "B", "C"][i], result.angles[i]] if result.valid else ["A", "B", "C"][i] + ": —"
        var samples := model.edge(i, PIECES)
        for j in range(PIECES):
            var a := display(samples[j])
            var b := display(samples[j + 1])
            edges[i * PIECES + j].show_segment(a, b - a, a.distance_to(b))
    face.mesh = null
    if result.valid and not model.spherical:
        var builder := SurfaceTool.new()
        builder.begin(Mesh.PRIMITIVE_TRIANGLES)
        for p in model.points: builder.add_vertex(display(model.corner(p)) + Vector3.DOWN * 0.018)
        builder.generate_normals()
        face.mesh = builder.commit()
    readout.text = "SPHERE / great-circle edges\n" if model.spherical else "PLANE / straight edges\n"
    readout.text += "Sum %.2f° / difference from 180°: %+.2f°\n" % [result.sum, result.sum - 180] if result.valid else "No triangle reading: separate the corners.\n"
    readout.text += "Release points before PLANE / P, SPHERE / S or RESET / R.\n"
    readout.text += "Hand outside upper chart: last record kept." if hand_refused else "Same coordinate pairs; different positions and paths."
```

## Predict, then check

Start in PLANE. Move C; keep the three pairs. Release it and select SPHERE. Predict whether the sum will stay, rise or fall before reading it. Switch back: the saved pairs and plane measurements should return exactly within numerical tolerance.

Use `(0,0), (1,0), (0,1)` in a model copy. PLANE gives 90°, 45°, 45°. SPHERE gives approximately 90°, 54.73561°, 54.73561°: sum 199.47122°. Each result must come from the calculated vectors, not a mode label. As a separate tangent check, the sphere's north pole and two equator points a quarter-turn apart give three right angles. Those equator points lie outside this hand chart; test their directions directly, without pretending the interface can reach them.

Check edge endpoints, unit-length spherical samples and tangents perpendicular to their corner normals. Collinear or coincident pairs must withhold the reading and recover when separated. Test the full host too: initialized meshes and labels, mode buttons, transformed local frame, sustained grab input, refused lower-chart input and release over several physics frames. A single rigid-body teleport is not a continuously tracked hand.

Make one variation of your own. State what it should preserve and change before running it. Compare numerical outputs and visible behaviour. The earlier shear is available, but you need not choose it. Do not overwrite a failed prediction to make the record look successful.

## What this comparison establishes

The spherical measurement uses great-circle directions. A chord through the sphere is a different edge. More rendering segments improve the picture; they do not change the analytical angle calculation.

For a suitable geodesic triangle, curvature relates to the difference from 180°. This lesson displays that difference; it does not independently integrate curvature or prove the theorem. [Mark Powell, Gauss–Bonnet, §7.2](https://www.maths.gla.ac.uk/~mpowell/M435-chapter-6-gauss-bonnet.pdf).

Return to DISK on the existing museum bench. The Poincaré model uses boundary-orthogonal arcs or diameters and preserves angles in its drawing. Its apparent flatness does not make its distance rule Euclidean. That model is a supporting encounter here, not code we reconstructed in this exercise. [Cornell, Geometries of Surfaces](https://pi.math.cornell.edu/~mec/Winter2009/Victor/part4.htm).

Carry the habit of stating the rule and checking what it permits into **Russell Paradox**. Next we will ask whether a membership demand can be satisfied. That is a different problem from choosing a geometry.

## Carried files, complete

Copy these three files unchanged from Euclid. `surface_triangle.gd` inherits the first; the host uses the other two. The external scene is `res://commons/interactables/push_button.tscn`; `XRToolsPickable` is supplied by the prepared project. These are declared infrastructure, not missing student code. A blank Godot project will not contain them.


### triangle_record.gd

<!-- student-code:triangle_record.gd -->
```gdscript
extends RefCounted
## A flat construction in metres. Positions and measurements are separate records.
const EPS := 0.00001
var points: Array[Vector2] = []

func _init() -> void:
    reset()

func reset() -> void:
    points.assign([Vector2(-0.7, 0.4), Vector2(0.7, 0.4), Vector2(0, -0.6)])

func measure() -> Dictionary:
    var ab := points[1] - points[0]
    var ac := points[2] - points[0]
    var bc := points[2] - points[1]
    var longest := maxf(ab.length(), maxf(ac.length(), bc.length()))
    var twice_area := absf(ab.cross(ac))
    # Refuse coincident or nearly collinear corners at this numerical scale.
    if longest <= EPS or twice_area <= EPS * longest * longest:
        return {"valid": false, "angles": [], "sum": 0.0, "area": twice_area * 0.5}
    var angles: Array[float] = []
    var total := 0.0
    for i in range(3):
        var u := points[(i + 1) % 3] - points[i]
        var v := points[(i + 2) % 3] - points[i]
        var angle := rad_to_deg(atan2(absf(u.cross(v)), u.dot(v)))
        angles.append(angle)
        total += angle
    return {"valid": true, "angles": angles, "sum": total, "area": twice_area * 0.5}

func parallel_ends(half_length: float = 1.25) -> Array[Vector2]:
    var direction := points[1] - points[0]
    if direction.length() <= EPS:
        return []
    direction = direction.normalized() * half_length
    return [points[2] - direction, points[2] + direction]
```

### point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

### line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```


---

<!-- Source: commons/maps/Russell_Paradox/tutorial.md -->

# A demand with no Boolean answer

**Learning elements**

- Membership predicates
- Boolean case analysis
- finite domains
- record versus demand

We leave the surface comparison with a useful habit: state the conditions before trusting the reading. At the existing Russell workbench, use IN and OUT in cell 5, then compare cell 6. Its membership controls are already installed. Our working copy uses the earlier PointBody as the candidate answer. Put it left for OUT, right for IN; release to test the choice. The sphere remains one object. It does not become an actual set containing itself.

The unrestricted demand is `p = not p`. Exhaust its two Boolean inputs. This is a two-case argument, not a search waiting for enough time. Then define the finite ordinal U = n = {0,...,n−1}. The set represented by each x contains precisely the smaller ordinals. None contains itself; filtering all x in U therefore returns U. U is not a member of U. In this restricted example the demand becomes `p = (result is in U) and not p`, with that domain test false. OUT now agrees. This is a finite example of separation, not an implementation of arbitrary set theory.

`members` builds a new array; it is a snapshot. `test` returns the assumption, required answer and agreement separately. No status is silently promoted into a mathematical object. SIZE cycles 1–6; the model also handles the empty ordinal 0, exercised below. DOMAIN preserves the chosen answer so that the rule, rather than the answer, changes in the comparison.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there.

Run the supplied `russell.tscn` in that folder with F6. Its `russell_museum.gd` launcher opens **Russell_Paradox** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `membership.gd`

<!-- student-code:membership.gd -->
```gdscript
extends RefCounted
# n represents the finite ordinal {0,...,n-1}. This is not a universal set.
func members(n: int) -> Array[int]:
    var result: Array[int] = []
    for x in range(maxi(0, n)):
        if not range(x).has(x): result.append(x)
    return result

func test(assumed: bool, restricted: bool, n: int = 4) -> Dictionary:
    if n < 0 or n > 6: return {"valid":false}
    var selected := members(n)
    # Every ordinal below n survives. The result equals ordinal n, outside n.
    var in_domain := range(n).has(n) if restricted else true
    var required := in_domain and not assumed
    return {"valid":true, "assumed":assumed, "required":required,
        "agrees":assumed==required, "members":selected,
        "domain_contains_result":in_domain, "restricted":restricted}
```

### `bench.gd`

<!-- student-code:bench.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
var drawing := Node3D.new()
var point
var point_home := Vector3(0, 1.1, 0)
var readout: Label3D
var buttons: Array = []

func start(title: String, words: Array, actions: Array) -> void:
    block(self, Vector3(0, 0.94, 0), Vector3(2.8, 0.08, 1.9), Color("d3ccc1"))
    block(self, Vector3(0, 1.94, -0.85), Vector3(2.9, 0.72, 0.04), Color("182330"))
    label(self, title, Vector3(0, 2.17, -0.8), 27)
    readout = label(self, "", Vector3(0, 1.9, -0.8), 22)
    add_child(drawing)
    point = PointBody.new()
    point.name = "CarriedPoint"
    point.tint = Color("e8c18c")
    add_child(point)
    for i in words.size():
        var button = PushButton.instantiate()
        button.name = "Action%d" % i
        button.position = Vector3((i-(words.size()-1)*0.5)*0.48, 1.02, 0.77)
        add_child(button)
        button.pressed.connect(actions[i])
        buttons.append(button)
        label(self, words[i], button.position+Vector3(0, 0.12, 0), 18)

func _physics_process(_delta: float) -> void:
    if point != null and not point.held(): point.position = point_home

func clear_drawing() -> void:
    for child in drawing.get_children(): child.free()

func block(parent: Node, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    body.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    body.material_override = material
    body.position = at
    parent.add_child(body)
    return body

func label(parent: Node, words: String, at: Vector3, size: int = 22) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0018
    text.outline_size = 5
    text.outline_modulate = Color("182330")
    parent.add_child(text)
    return text

func segment(a: Vector3, b: Vector3) -> void:
    var line := LineSkin.new()
    drawing.add_child(line)
    line.show_segment(a, b-a, a.distance_to(b))
```

### `russell_study.gd`

<!-- student-code:russell_study.gd -->
```gdscript
extends "bench.gd"
const Membership = preload("membership.gd")
var model := Membership.new()
var restricted := false
var size := 4
var assumed := false
var was_held := false
var held_x := 0.0
var result: Dictionary = {}

func _ready() -> void:
    start("RUSSELL / TEST THE DEMAND", ["OUT", "IN", "DOMAIN", "SIZE"],
        [choose.bind(false), choose.bind(true), domain, next_size])
    refresh()

func choose(value: bool) -> void:
    if point.held(): return
    assumed = value
    refresh()

func domain() -> void:
    if point.held(): return
    restricted = not restricted
    refresh()

func next_size() -> void:
    if point.held(): return
    size = size % 6 + 1
    refresh()

func _process(_delta: float) -> void:
    if point.held():
        was_held = true
        held_x = to_local(point.global_position).x
    elif was_held:
        was_held = false
        choose(held_x >= 0)

func refresh() -> void:
    result = model.test(assumed, restricted, size)
    point_home = Vector3(0.65 if assumed else -0.65, 1.23, 0.25)
    clear_drawing()
    for i in 2:
        var x := -0.65 if i==0 else 0.65
        block(drawing, Vector3(x, 1.01, 0.25), Vector3(0.75, 0.04, 0.42), Color("30465b"))
        label(drawing, "OUT" if i==0 else "IN", Vector3(x, 1.08, 0.48))
    if restricted:
        for x in result.members:
            var at := Vector3((x-(size-1)*0.5)*0.3, 1.04, -0.38)
            block(drawing, at, Vector3.ONE*0.12, Color("99bbc7"))
            label(drawing, str(x), at+Vector3.UP*0.18)
    readout.text = "%s\nChoose %s; rule requires %s. %s\n%s" % [
        "WITHIN U = %s"%str(result.members) if restricted else "UNRESTRICTED: p = not p",
        "IN" if assumed else "OUT", "IN" if result.required else "OUT",
        "AGREES" if result.agrees else "DISAGREES",
        "Result = %d; it is outside U."%size if restricted else "Test both Booleans. No fixed answer."]
```

## Predict, build, check

Predict all four cases before running: unrestricted IN and OUT both disagree; restricted IN disagrees and OUT agrees. Set n to 2, then 6: the displayed members change, but the result remains outside its domain. Test n = 0 in code: empty U gives empty result, still not a member of itself. Explain why this is not a repair that makes the original unrestricted condition true.

For the hand test, rotate and translate the study node. Right/left are measured in its local frame using `to_local`. The last held coordinate is retained before release, avoiding a physics tick returning the body to its old slot before the choice is read. While held, buttons refuse edits. The inherited frozen PointBody supplies pickup/release; the new lesson supplies the membership rule.

Carry the distinction between an inconsistent demand and a calculation that has not returned. Gödel's lesson will need it.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.


---

<!-- Source: commons/maps/Godel_Incompleteness/tutorial.md -->

# A derivation you can check

**Learning elements**

- Formal syntax
- axioms and rules
- proof checking
- bounded enumeration
- predictions and saved experiments

The installed sentence machine already says ILLUSTRATION — NOT PROOF SEARCH. Watch its timed arm, then build a working copy that actually checks a derivation. Bring the finite arrays and explicit conditions from Russell. The same sphere now marks the last candidate inspected; its position is an index, not a truth value. Moving it by hand does not change the calculus: release returns it to that index.

Our entire toy language is 0, S0, SS0, and so on. There is one axiom, 0, and one rule: from w append an S at the front to produce Sw. A proof is an ordered array beginning at 0, advancing by exactly that rule, and ending at the requested target. `verify` checks a supplied array without searching. `search` enumerates rule applications up to a declared budget. Budget 0 still examines the axiom. Budget 2 examines 0, S0 and SS0, so it misses SSS0. Budget 3 finds a proof that the checker accepts.

This deliberately simple system is decidable and does not encode arithmetic proofs or construct a Gödel sentence. The lesson teaches a distinction needed to read the room: a bounded miss cannot establish unprovability. The theorem concerns specified effective theories with sufficient arithmetic; the source linked below develops the argument. Nothing in a timer, a label or this toy enumeration substitutes for it.

MORE increases the budget to at most 8; TARGET switches between SSS0 and SSSSSS0. DAMAGE removes the second line of a copied candidate. It never alters the search result's stored array. RESET restores budget 2 and an undamaged candidate, retaining the selected target. The checker must reject a damaged chain even when its last line is the desired sentence.

## From a stored proof to a statement about proof

Our proof is already data: an array of strings. The checker receives that array and tests each step. It speaks about the proof from outside our tiny language, whose strings cannot themselves express “this is a proof.”

The bridge to Gödel is a stronger formal language. Finite strings and sequences can be encoded by natural numbers; an effective syntactic check on a proposed proof can then be represented by arithmetic relations. Sufficiently expressive arithmetic can state that a number encodes a proof of a formula. A fixed-point construction uses this capacity to produce a sentence about its own provability. Merely numbering our strings would not supply that construction or the theorem's hypotheses. Keep the small checker as preparation for this additional argument.

## Keep your own experiment

The second row asks about the next search budget: will its candidate pass the checker? PREDICT YES/NO stores the chosen inputs and your expectation without running that next search. TRY + KEEP runs it and appends the full record to `user://ada_foundations_trials_v1.json`. The expectation never enters `search` or `verify`. Up to eight steps are available here; RESET begins another run without clearing the journal. Changing the exploratory setup cancels a pending prediction. Ordinary MORE is exploration and does not save a run.

`trial_archive.gd` validates the file format, keeps earlier entries and writes a complete temporary file before replacing the journal. The record names `unary-derivation-v1` and the SHA-256 of the executed model source. The supplied museum launcher remains infrastructure; this new save/load code is printed below. The journal is local to this project's Godot user-data directory. Another device needs a copy of the file. It records this finite experiment, not a proof of incompleteness.


## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `godel.tscn` in that folder with F6. Its `godel_museum.gd` launcher opens **Godel_Incompleteness** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `derivation.gd`

<!-- student-code:derivation.gd -->
```gdscript
extends RefCounted
# Toy syntax only: 0, S0, SS0, ... . Axiom 0; rule w -> Sw.
func well_formed(word: String) -> bool:
    if not word.ends_with("0"): return false
    return word.left(word.length()-1).replace("S", "").is_empty()

func verify(proof: Array, target: String) -> bool:
    if not well_formed(target) or proof.is_empty() or proof[0] != "0": return false
    for i in range(1, proof.size()):
        if not proof[i] is String or proof[i] != "S"+str(proof[i-1]): return false
    return proof[-1] == target

func search(target: String, budget: int) -> Dictionary:
    if not well_formed(target) or budget < 0 or budget > 32:
        return {"status":"INVALID INPUT", "proof":[], "examined":0}
    var proof: Array[String] = ["0"]
    for step in range(budget+1):
        if proof[-1] == target:
            return {"status":"CHECKED DERIVATION", "proof":proof, "examined":step+1}
        if step < budget: proof.append("S"+proof[-1])
    return {"status":"NOT FOUND WITHIN BUDGET", "proof":proof, "examined":budget+1}
```

### `trial_archive.gd`

<!-- student-code:trial_archive.gd -->
```gdscript
extends RefCounted
# One local journal. Prediction is recorded but never supplied to the search/checker.
const DEFAULT_PATH = "user://ada_foundations_trials_v1.json"
const MODEL_ID = "unary-derivation-v1"

func capture(model, target: String, budget: int, damage: bool, prediction: bool) -> Dictionary:
    var found: Dictionary = model.search(target, budget)
    var candidate: Array = found.proof.duplicate()
    if damage and candidate.size() > 1: candidate.remove_at(1)
    var accepted: bool = model.verify(candidate, target)
    return {"model_id":MODEL_ID,
        "model_sha256":FileAccess.get_sha256(model.get_script().resource_path),
        "saved_at":Time.get_datetime_string_from_system(true)+"Z",
        "target":target, "budget":budget, "damage":damage,
        "prediction":prediction, "search_result":found.duplicate(true),
        "candidate":candidate, "accepted":accepted,
        "prediction_matched":prediction == accepted}

func whole(value, low: int, high: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value == int(value) and value >= low and value <= high

func words(value) -> bool:
    if not value is Array or value.size() > 33: return false
    for word in value:
        if not word is String or word.length() > 33: return false
    return true

func valid(entry) -> bool:
    if not entry is Dictionary: return false
    for key in ["model_id", "model_sha256", "saved_at", "target", "budget", "damage",
            "prediction", "search_result", "candidate", "accepted", "prediction_matched"]:
        if not entry.has(key): return false
    if entry.model_id != MODEL_ID: return false
    if not entry.model_sha256 is String or entry.model_sha256.length() != 64 or not entry.model_sha256.is_valid_hex_number(false): return false
    if not entry.saved_at is String or not entry.target is String: return false
    if entry.target.length() > 33 or not entry.target.ends_with("0") or not entry.target.left(-1).replace("S", "").is_empty(): return false
    if not whole(entry.budget, 0, 32) or not words(entry.candidate): return false
    for key in ["damage", "prediction", "accepted", "prediction_matched"]:
        if not entry[key] is bool: return false
    var result = entry.search_result
    if not result is Dictionary or not result.has_all(["status", "proof", "examined"]): return false
    if result.status not in ["CHECKED DERIVATION", "NOT FOUND WITHIN BUDGET"]: return false
    if not words(result.proof) or not whole(result.examined, 1, 33): return false
    return entry.prediction_matched == (entry.prediction == entry.accepted)

func read(path: String = DEFAULT_PATH) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok":true, "entries":[], "message":"No saved experiment yet. Visit the Godel study."}
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null: return {"ok":false, "entries":[], "message":"Cannot read the journal."}
    var parser := JSON.new()
    var error := parser.parse(file.get_as_text())
    file.close()
    if error != OK: return {"ok":false, "entries":[], "message":"Journal is not valid JSON; kept unchanged."}
    var data = parser.data
    if not data is Dictionary or not data.has_all(["schema", "entries"]) or data.schema != 1 or not data.entries is Array:
        return {"ok":false, "entries":[], "message":"Unknown journal format; kept unchanged."}
    for entry in data.entries:
        if not valid(entry): return {"ok":false, "entries":[], "message":"Invalid experiment record; kept unchanged."}
        # JSON numbers load as floats. Restore the declared integer fields.
        entry.budget = int(entry.budget)
        entry.search_result.examined = int(entry.search_result.examined)
    return {"ok":true, "entries":data.entries.duplicate(true), "message":"Read %d saved experiments." % data.entries.size()}

func append(entry: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
    if not valid(entry): return {"ok":false, "message":"Experiment record refused."}
    var previous := read(path)
    if not previous.ok: return previous
    var entries: Array = previous.entries
    entries.append(entry.duplicate(true))
    # Replace only after a complete temporary file has been written successfully.
    var temporary := path + ".tmp"
    var file = FileAccess.open(temporary, FileAccess.WRITE)
    if file == null: return {"ok":false, "message":"Cannot open journal for writing."}
    file.store_string(JSON.stringify({"schema":1, "entries":entries}, "  "))
    file.flush()
    var error := file.get_error()
    file.close()
    if error == OK:
        error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
    if error != OK: return {"ok":false, "message":"Save failed; previous journal kept."}
    return {"ok":true, "message":"Kept experiment %d, including its prediction." % entries.size()}
```

### `godel_study.gd`

<!-- student-code:godel_study.gd -->
```gdscript
extends "bench.gd"
const Derivation = preload("derivation.gd")
const TrialArchive = preload("trial_archive.gd")
var model := Derivation.new()
var archive := TrialArchive.new()
var journal_path := TrialArchive.DEFAULT_PATH
var pending: Dictionary = {}
var journal_label: Label3D
var journal_message := "Predict the next budget, then TRY + KEEP."
var target := "SSS0"
var budget := 2
var result: Dictionary = {}
var damaged := false

func _ready() -> void:
    start("GODEL / CHECKING IS NOT SEARCHING", ["MORE", "TARGET", "DAMAGE", "RESET"],
        [more, next_target, damage, reset])
    block(self, Vector3(0, 0.84, 1.15), Vector3(2.5, 0.08, 0.55), Color("d3ccc1"))
    var words := ["PREDICT YES", "PREDICT NO", "TRY + KEEP"]
    var actions := [predict.bind(true), predict.bind(false), run_trial]
    for i in 3:
        var button = PushButton.instantiate()
        button.position = Vector3((i-1)*0.8, 0.92, 1.15)
        add_child(button)
        button.pressed.connect(actions[i])
        buttons.append(button)
        label(self, words[i], button.position+Vector3.UP*0.12, 16)
    journal_label = label(self, "", Vector3(0, 1.69, -0.8), 22)
    refresh()

func cancel_prediction() -> void:
    pending.clear()
    journal_message = "Setup changed. Predict before TRY + KEEP."

func predict(accepted: bool) -> void:
    if point.held(): return
    if budget >= 8:
        journal_message = "RESET first: the next budget would exceed 8."
    else:
        pending = {"target":target, "budget":budget+1, "damage":damaged, "prediction":accepted}
        journal_message = "Next budget %d; checker accepts? %s\nTRY + KEEP will run and retain this prediction." % [budget+1, "YES" if accepted else "NO"]
    refresh()

func run_trial() -> void:
    if point.held(): return
    if pending.is_empty():
        journal_message = "Choose PREDICT YES or NO before running."
    else:
        var entry := archive.capture(model, pending.target, pending.budget, pending.damage, pending.prediction)
        var saved := archive.append(entry, journal_path)
        budget = pending.budget
        journal_message = "%s\nPredicted %s; accepted %s. %s" % [saved.message,
            str(entry.prediction), str(entry.accepted), "MATCH" if entry.prediction_matched else "DID NOT MATCH"]
        pending.clear()
    refresh()

func more() -> void:
    if point.held(): return
    cancel_prediction()
    budget = mini(8, budget+1)
    damaged = false
    refresh()

func next_target() -> void:
    if point.held(): return
    cancel_prediction()
    target = "SSSSSS0" if target=="SSS0" else "SSS0"
    damaged = false
    refresh()

func damage() -> void:
    if point.held(): return
    cancel_prediction()
    damaged = not damaged
    refresh()

func reset() -> void:
    if point.held(): return
    cancel_prediction()
    budget = 2
    damaged = false
    refresh()

func refresh() -> void:
    result = model.search(target, budget)
    var candidate: Array = result.proof.duplicate()
    if damaged and candidate.size()>1: candidate.remove_at(1)
    clear_drawing()
    for i in candidate.size():
        var at := Vector3(-1.12+i*0.28, 1.05+i*0.035, 0)
        block(drawing, at, Vector3(0.23, 0.08, 0.35), Color("94aeba"))
        label(drawing, str(i), at+Vector3(0, 0.12, 0.2), 19)
    point_home = Vector3(-1.12+(candidate.size()-1)*0.28, 1.27+(candidate.size()-1)*0.035, 0)
    readout.text = "Target %s | at most %d rule steps\n%s\nCandidate checks: %s%s" % [
        target, budget, result.status, str(model.verify(candidate, target)),
        " (step removed)" if damaged else ""]
    journal_label.text = journal_message
```

## Predict, build, check

Before running, predict: SSSSSS0 is missed at budget 5 and found at 6. Check the returned array with `verify`. Remove S0 from a valid proof: reaching the target is insufficient when the intermediate inference is invalid. Supply X or 00: syntax validation refuses them, which differs from a bounded miss on a well-formed target.

Write down one claim our test can refute: “not found within two steps means unprovable.” The budget-3 run is its concrete counterexample. Do not replace it with the opposite overclaim that every proof system is this easy. The next hall changes medium: a closed spatial route has a directly checkable height invariant.

Reference: [Olivier Bournez, Incompleteness of arithmetic](https://www.enseignement.polytechnique.fr/informatique/INF412/uploads/Main/chap10english-goodINF412ENGLISH.pdf). Our unary study is an original teaching construction, not that theorem's proof.

For your carried experiment, RESET at target SSS0. Predict whether the checker will accept a candidate at the **next** budget, 3. Press PREDICT YES or PREDICT NO, then TRY + KEEP. The prediction is fixed before that run. Compare it with the accepted result. Keep a mistaken prediction as it was. Repeat with DAMAGE enabled or target SSSSSS0; earlier entries remain.

Leave the study and open Synthesis. Its first personal card must contain your target, budget, damage setting, prediction, candidate and outcome. Returning to RESET never erases the journal. If the journal cannot be read or saved, the display says so; a missing record is not replaced with an invented personal experiment.


The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.


---

<!-- Source: commons/maps/Escher_Impossible/tutorial.md -->

# Where the height returns

**Learning elements**

- Ordered positions
- world-frame measurement
- open and closed paths
- accumulated differences
- invariants

At the existing staircase, STEP follows measured tread centres; FORM offers five arrangements. Our smaller construction isolates one question using four familiar cube treads, the carried LineSkin cylinders and one PointBody marker. No faces of the cube are transformed individually. The player stays on the museum floor; the marker travels the model.

The four centres rise by 0.2 metres three times. Closing the route requires a −0.6-metre move. `step` measures actual centre heights after applying the chosen transform, accumulating positive changes in up and negative magnitudes in down. On return, up minus down is zero within numerical tolerance. `closure` calculates every edge difference independently of the visitor's partial journey. Each height appears once with each sign. This algebraic cancellation explains the general closed-route invariant; the program checks finite instances.

OPEN removes the closing connection and refuses movement past the last centre. It does not wrap through an invisible drop. TILT rotates the entire arrangement by 0.35 radians and starts a new measurement, so no journey mixes coordinate frames. The displayed treads and measured centres use the same transform. Individual signs may change when up changes relative to the model, but a closed route still cancels. RESET keeps the selected arrangement and tilt.

Walk around the installation's separate perspective work. Apparent contact in an image and coincidence in three-dimensional coordinates require different evidence. Our working copy does not fabricate an impossible staircase or prove a result about formal arithmetic.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `escher.tscn` in that folder with F6. Its `escher_museum.gd` launcher opens **Escher_Impossible** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `height_route.gd`

<!-- student-code:height_route.gd -->
```gdscript
extends RefCounted
var points: Array[Vector3] = [Vector3(-0.7,0,-0.5), Vector3(0.7,0.2,-0.5),
    Vector3(0.7,0.4,0.5), Vector3(-0.7,0.6,0.5)]
var closed := true
var index := 0
var up := 0.0
var down := 0.0
var last := 0.0

func reset() -> void:
    index=0
    up=0
    down=0
    last=0

func step(frame: Transform3D = Transform3D.IDENTITY) -> bool:
    if points.is_empty() or (not closed and index==points.size()-1): return false
    var next := (index+1)%points.size()
    last = (frame*points[next]).y - (frame*points[index]).y
    up += maxf(last,0)
    down += maxf(-last,0)
    index=next
    return true

func closure(frame: Transform3D = Transform3D.IDENTITY) -> float:
    var total := 0.0
    for i in points.size():
        total += (frame*points[(i+1)%points.size()]).y - (frame*points[i]).y
    return total
```

### `escher_study.gd`

<!-- student-code:escher_study.gd -->
```gdscript
extends "bench.gd"
const HeightRoute = preload("height_route.gd")
var model := HeightRoute.new()
var tilted := false

func _ready() -> void:
    start("ESCHER / WHERE THE RISE RETURNS", ["STEP", "OPEN", "TILT", "RESET"],
        [advance, open_route, tilt, reset])
    refresh()

func frame() -> Transform3D:
    return global_transform*Transform3D(Basis(Vector3.FORWARD, 0.35 if tilted else 0), Vector3.UP*1.05)

func advance() -> void:
    if point.held(): return
    model.step(frame())
    refresh()

func open_route() -> void:
    if point.held(): return
    model.closed = not model.closed
    reset()

func tilt() -> void:
    if point.held(): return
    tilted = not tilted
    reset()

func reset() -> void:
    if point.held(): return
    model.reset()
    refresh()

func refresh() -> void:
    clear_drawing()
    var t := global_transform.affine_inverse()*frame()
    for i in model.points.size():
        var at: Vector3 = t*model.points[i]
        block(drawing, at, Vector3(0.25,0.07,0.25), Color("9eadb9"))
        label(drawing,str(i),at+Vector3(0,0.12,0),18)
        if i<model.points.size()-1 or model.closed:
            segment(at,t*model.points[(i+1)%model.points.size()])
    point_home = t*model.points[model.index]+Vector3.UP*0.16
    readout.text = "%s | step %d\nLast %+.3f m; up %.3f / down %.3f\n%s" % [
        "CLOSED" if model.closed else "OPEN", model.index, model.last, model.up, model.down,
        "Closing differences sum to %.5f"%model.closure(frame()) if model.closed else "The open end does not wrap."]
```

## Predict, build, check

Predict the fourth change before pressing it: −0.6 metres in the unrotated study. Assert four steps return the marker to index 0 and equal ascent/descent. Open the route: after three moves, the next attempt must fail and retain index 3. Tilt the whole study around another axis in code; calculate each world height and predict the return difference. Keep that frame fixed during a run.

Try changing only one tread's drawn angle while leaving its centre fixed. The centre measure will miss that surface slope; name the limitation rather than calling the reading wrong. The next hall asks what a produced object can witness.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.


---

<!-- Source: commons/maps/Brouwer_Intuitionism/tutorial.md -->

# A witness, then another choice

**Learning elements**

- Chosen finite prefixes
- existential witnesses
- validation
- a finite diagonal construction

The existing choice bench waits for a press; its row does not grow on the clock. Rebuild that behaviour with an eight-term working copy. The arrays and loops are familiar from Trace. A stored 1 at a named index witnesses “this prefix contains a 1.” No 1 in the entire stored prefix settles that finite question negatively. It does not settle whether an indefinitely continued sequence will ever contain a 1. NO WITNESS YET is an evidence status, not a third truth value.

Begin with 0, 0, 0. Wait. Nothing is appended. Press 1 and identify the zero-based index 3. `append_bit` validates both value and capacity before mutating the record. The ninth press is refused. Eight is a storage bound; it is not a completed infinity. The PointBody marks the next available slot, or the last slot when full. Its pickup is inherited; the bit buttons remain the only authors of this record.

Then visit the installed diagonal workbench. In the second exercise, DIAGONAL displays four binary rows and constructs d[i] = 1 − rows[i][i]. Every displayed row disagrees with d at a known index. The model validates a square nonempty array of integer bits before constructing the witness. The gold tiles mark those indices. This implements a finite diagonal stage. An infinite argument quantifies over every row of an arbitrary proposed list; rendering four rows is not rendering that infinity.

DIAGONAL changes the view without clearing the chosen prefix. A new 0 or 1 returns to the prefix. RESET clears the prefix and keeps the chosen view. The earlier arrays therefore survive a change of representation rather than being silently recreated.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `brouwer.tscn` in that folder with F6. Its `brouwer_museum.gd` launcher opens **Brouwer_Intuitionism** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `witness.gd`

<!-- student-code:witness.gd -->
```gdscript
extends RefCounted
const CAPACITY := 8
var terms: Array[int] = []

func append_bit(bit: int) -> bool:
    if bit not in [0,1] or terms.size()>=CAPACITY: return false
    terms.append(bit)
    return true

func first_one() -> int:
    return terms.find(1)

func inspect_prefix() -> Dictionary:
    var index := first_one()
    return {"finite_contains_one":index>=0, "witness_index":index,
        "future_claim":"WITNESSED" if index>=0 else "NO WITNESS YET"}

func diagonal(rows: Array) -> Dictionary:
    if rows.is_empty(): return {"valid":false, "bits":[]}
    for row in rows:
        if not row is Array or row.size()!=rows.size(): return {"valid":false, "bits":[]}
        for bit in row:
            if not bit is int or bit not in [0,1]: return {"valid":false, "bits":[]}
    var bits: Array[int] = []
    for i in rows.size(): bits.append(1-int(rows[i][i]))
    return {"valid":true, "bits":bits}
```

### `brouwer_study.gd`

<!-- student-code:brouwer_study.gd -->
```gdscript
extends "bench.gd"
const Witness = preload("witness.gd")
var model := Witness.new()
var rows: Array = [[0,0,1,1],[1,0,1,0],[0,1,1,0],[1,1,0,1]]
var show_diagonal := false

func _ready() -> void:
    start("BROUWER / PRODUCE THE WITNESS", ["0", "1", "DIAGONAL", "RESET"],
        [choose.bind(0),choose.bind(1),diagonal,reset])
    refresh()

func choose(bit: int) -> void:
    if point.held(): return
    show_diagonal = false
    model.append_bit(bit)
    refresh()

func diagonal() -> void:
    if point.held(): return
    show_diagonal = not show_diagonal
    refresh()

func reset() -> void:
    if point.held(): return
    model.terms.clear()
    refresh()

func bit_at(bit: int, at: Vector3, marked: bool = false) -> void:
    block(drawing,at,Vector3(0.18,0.045,0.13),Color("d29d55") if bit else Color("618da9"))
    label(drawing,str(bit),at+Vector3.UP*0.09,19)
    if marked: block(drawing,at+Vector3(0,-0.015,0),Vector3(0.23,0.01,0.18),Color("ffda88"))

func refresh() -> void:
    clear_drawing()
    if show_diagonal:
        var d: Array = model.diagonal(rows).bits
        for y in rows.size():
            for x in rows[y].size():
                bit_at(rows[y][x],Vector3(-0.75+x*0.3,1.04,-0.48+y*0.21),x==y)
        for i in d.size(): bit_at(d[i],Vector3(-0.75+i*0.3,1.04,0.45))
        point_home=Vector3(0.95,1.18,0.45)
        readout.text="A finite diagonal witness\nNew row: %s\nRow i differs at position i."%str(d)
    else:
        for i in model.terms.size(): bit_at(model.terms[i],Vector3(-1.05+i*0.3,1.05,0))
        point_home=Vector3(-1.05+mini(model.terms.size(),7)*0.3,1.27,0)
        var report := model.inspect_prefix()
        readout.text="%d / %d stored; no automatic next bit\nFinite prefix has 1: %s; index %d\nContinuation: %s"%[
            model.terms.size(),model.CAPACITY,str(report.finite_contains_one),report.witness_index,report.future_claim]
```

## Predict, build, check

Make eight zeros. Predict the finite answer and the continuation status separately. Clear, append three zeros and a 1, and return the witness index. Invalid values and a ninth append must leave the record unchanged.

For the diagonal variation, flip every diagonal entry of the supplied rows. Predict that every output bit flips too; assert disagreement with row i at position i for both versions. Supply a ragged array and refuse it. A displayed “constructed” flag without these checks would not establish the property.

The next hall retains incompatible reports. An absent witness and two opposed reports will be different data states, with different consequences.

Reference: [Joan Rand Moschovakis, Brouwer's Notion of Choice Sequence and Its Descendants](https://www.math.ucla.edu/~joan/Oslonewzoom2022handout.pdf). The finite binary bench is our teaching model.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.


---

<!-- Source: commons/maps/Florensky_Paraconsistent/tutorial.md -->

# Two reports, stated consequences

**Learning elements**

- Independent support
- four information states
- explicit consequence rules
- a countermodel to explosion

At the installed gate, OPEN and CLOSED are independent reports. Both leaves can remain visible; neither supplies evidence for the alarm Q. First reconstruct that store. Then make a small additional step in the student copy: define precisely how negation, conjunction and disjunction combine the reports. This extension is a tiny propositional semantics, not a claim that the installed gate already implements a proof engine or that Florensky proposed this particular logic.

Each Vector2i has two binary components: support for and support against. (0,0) means neither, (1,0) for only, (0,1) against only, and (1,1) both. These are independent flags, not probabilities summing to one. Negation swaps them. For conjunction, positive support requires both positives; negative support needs either negative. Disjunction reverses those AND/OR requirements. A result is designated when its positive component is 1. The code implements the negation/conjunction/disjunction fragment of Dunn–Belnap four-valued semantics; it has no implication connective, quantifiers or proof-search procedure.

Test the consequence claim “P and not P license any Q.” At P=(1,1), both premises are designated. At Q=(0,0), Q is not designated. `explosion_counterexample` enumerates all sixteen assignments of P and Q until it finds that countermodel. This establishes failure of that consequence for these defined tables. It does not establish the truth of both reports about an actual door.

P FOR and P AGAINST toggle the independent components. Q FOR adds a separate report about Q; holding both P reports never performs that action. CLEAR empties both records. The sphere remains the familiar held object; releasing it returns it to the bench rather than resolving a report.

## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `florensky.tscn` in that folder with F6. Its `florensky_museum.gd` launcher opens **Florensky_Paraconsistent** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `reports.gd`

<!-- student-code:reports.gd -->
```gdscript
extends RefCounted
# Pair (support-for, support-against); each component is independently 0 or 1.
var p := Vector2i.ZERO
var q := Vector2i.ZERO

func neg(a: Vector2i) -> Vector2i:
    return Vector2i(a.y,a.x)

func both(a: Vector2i,b: Vector2i) -> Vector2i:
    return Vector2i(mini(a.x,b.x),maxi(a.y,b.y))

func either(a: Vector2i,b: Vector2i) -> Vector2i:
    return Vector2i(maxi(a.x,b.x),mini(a.y,b.y))

func supported(a: Vector2i) -> bool:
    return a.x==1

func describe(a: Vector2i) -> String:
    if a==Vector2i(1,1): return "BOTH REPORTS"
    if a==Vector2i(1,0): return "FOR ONLY"
    if a==Vector2i(0,1): return "AGAINST ONLY"
    return "NO SUPPORT"

func explosion_counterexample() -> Dictionary:
    for positive in [0,1]:
        for negative in [0,1]:
            var premise := Vector2i(positive,negative)
            for q_positive in [0,1]:
                for q_negative in [0,1]:
                    var conclusion := Vector2i(q_positive,q_negative)
                    if supported(premise) and supported(neg(premise)) and not supported(conclusion):
                        return {"found":true,"p":premise,"q":conclusion}
    return {"found":false}
```

### `florensky_study.gd`

<!-- student-code:florensky_study.gd -->
```gdscript
extends "bench.gd"
const Reports = preload("reports.gd")
var model := Reports.new()

func _ready() -> void:
    start("FLORENSKY / KEEP THE REPORTS DISTINCT", ["P FOR", "P AGAINST", "Q FOR", "CLEAR"],
        [toggle.bind(0),toggle.bind(1),toggle.bind(2),reset])
    refresh()

func toggle(which: int) -> void:
    if point.held(): return
    if which==0: model.p.x=1-model.p.x
    elif which==1: model.p.y=1-model.p.y
    elif which==2: model.q.x=1-model.q.x
    refresh()

func reset() -> void:
    if point.held(): return
    model.p=Vector2i.ZERO
    model.q=Vector2i.ZERO
    refresh()

func refresh() -> void:
    clear_drawing()
    for i in 3:
        var at := Vector3(-0.8+i*0.8,1.1,0)
        var present: bool = [model.p.x,model.p.y,model.q.x][i]==1
        block(drawing,at,Vector3(0.45,0.16 if present else 0.025,0.45),Color("bd9fd0") if present else Color("445464"))
        label(drawing,["P","not P","Q"][i],at+Vector3.UP*0.2)
    point_home=Vector3(0,1.2,0.48)
    readout.text="P: %s | Q: %s\nP and not P: %s\nTwo reports do not add support for Q."%[
        model.describe(model.p),model.describe(model.q),model.describe(model.both(model.p,model.neg(model.p)))]
```

## Predict, build, check

Predict all four states of P before pressing the buttons. Hold both reports while Q has no support. Then add Q's own positive report: explain what changed and who supplied it. Negating a pair twice must return the original pair. Check the two De Morgan laws over all sixteen input pairs and conjunction elimination: whenever a conjunction is designated, each conjunct is designated.

Compare this with Brouwer's status “no witness yet.” Our four-valued semantics is an explicit choice for combining reports. It does not turn constructive uncertainty into a third or fourth truth value, and it has no connection to quantum amplitudes. The synthesis will keep these scopes attached to their results.

Reference: [Sutcliffe, Pelletier and Hazen, Making Belnap's Useful Four-Valued Logic Useful](https://cdn.aaai.org/ocs/17599/17599-77711-1-PB.pdf), Table 1. Our pair representation implements the basic tables, not the paper's additional conditional connectives.

The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.


---

<!-- Source: commons/maps/Crisis_Synthesis/tutorial.md -->

# A claim keeps its warrant

**Learning elements**

- Evidence records
- reuse across models
- display scale
- word timing
- claim versus validation

The existing hall brings the formula, independent parameter controls and earlier encounters together. Its sentence-authority work repeats the same words at several scales. Build a small working copy of that operation, carrying the five model files just written. The code keeps six supplied reference cards and also imports your saved experiments from Gödel. The unchanged models are listed below. Their meanings remain distinct.

Each card keeps three fields: sentence, scope and evidence. The first five concern the two Russell cases, a unary search budget, a closed height route, a chosen prefix and a four-valued countermodel. The sixth is an authored AI proposal with no verification procedure attached. That explicit absence does not acquire a certificate from the neighbouring calculations. These examples are finite scoped records, not an automatic truth service.

`current` returns a deep copy, protecting the stored evidence from display edits. NEXT changes the selected card and starts its word rhythm again. SIZE changes font size; HOLD pauses the strip; PACE alternates 0.6 and 1.2 seconds per word and restarts it. Small label, large label and strip read one sentence. None of these controls reruns a model, changes its assumptions or upgrades its result.

The original QFEP formula remains a research proposal. Its λ and φ displays do not measure the entropy of these cards, and the logistic exhibit's r remains independent. Our work here concerns how an assertion is presented and what supports it. The familiar sphere is present as a carried body, not as an oracle that can settle the formula.

## Bring a run you actually made

As in Trace → Grid, your own work travels into another hall. The six reference cards use supplied examples. Your saved Gödel runs are additional cards, read from `user://ada_foundations_trials_v1.json`; the first personal card is selected on entry when available. They retain the target, budget, damage setting, prediction, search output, exact tested candidate, checker result, time in UTC, model identifier and source hash. The journal is read without rerunning the search or rewriting earlier entries. A source change is disclosed alongside the older result. A missing or malformed file produces a notice and no personal cards.

## Keep the difficulties distinct

| Encounter | What must be distinguished |
| --- | --- |
| Plane / sphere | Different geometric models; a changed result can be correct in each. |
| Russell | The unrestricted demand contradicts both Boolean assignments. |
| Gödel | A finite search miss; separately, the theorem's unprovability claim under specified assumptions. |
| Escher | Coincidence in a view versus connection in the measured space. |
| Brouwer | An absent witness now versus a claim about every continuation. |
| Florensky | Opposed reports and the explicitly chosen rules of consequence. |

Each difficulty calls for its own response. They do not accumulate into a verdict that justification has failed. Choose one earlier museum artifact—a trace, a woven pattern or the trained sphere—and state its inputs, rule, observed result and what the result leaves open. This final comparison is a written investigation; the current journal imports Gödel experiments only.


## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new. Also carry `membership.gd`, `derivation.gd`, `height_route.gd`, `witness.gd` and `reports.gd` from the five preceding lessons. These are executable dependencies, not hidden services. Carry `trial_archive.gd` from Gödel too. It reads the saved experiment file; no live node is transferred.

Run the supplied `synthesis.tscn` in that folder with F6. Its `synthesis_museum.gd` launcher opens **Crisis_Synthesis** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `claim_record.gd`

<!-- student-code:claim_record.gd -->
```gdscript
extends RefCounted
const Membership=preload("membership.gd")
const Derivation=preload("derivation.gd")
const HeightRoute=preload("height_route.gd")
const Witness=preload("witness.gd")
const Reports=preload("reports.gd")
const TrialArchive=preload("trial_archive.gd")
var journal_message := "No journal loaded."
var cards: Array[Dictionary] = []
var index := 0
var elapsed := 0.0
var seconds_per_word := 0.6
var paused := false
var large := false

func _init() -> void:
    var membership=Membership.new()
    var proof=Derivation.new().search("SSS0",2)
    var route=HeightRoute.new()
    var prefix=Witness.new()
    prefix.append_bit(0)
    var reports=Reports.new()
    cards=[
        {"sentence":"NEITHER ANSWER MEETS THIS DEMAND", "scope":"Unrestricted Boolean self-membership", "evidence":[membership.test(false,false).agrees,membership.test(true,false).agrees]},
        {"sentence":"NO PROOF WAS FOUND WITHIN TWO STEPS", "scope":"Unary toy syntax; target SSS0", "evidence":proof},
        {"sentence":"THE CLOSED ROUTE RETURNS ITS HEIGHT", "scope":"Four centres in one fixed frame", "evidence":route.closure()},
        {"sentence":"NO WITNESS HAS BEEN RECORDED YET", "scope":"One chosen zero; continuation open", "evidence":prefix.inspect_prefix()},
        {"sentence":"CONFLICT DOES NOT SUPPORT EVERY CLAIM", "scope":"The printed pair semantics", "evidence":reports.explosion_counterexample()},
        {"sentence":"THIS AI PROPOSAL STILL NEEDS CHECKING", "scope":"An authored sentence, not a model verdict", "evidence":"No verification procedure attached"}]

func load_journal(path: String = TrialArchive.DEFAULT_PATH) -> void:
    cards.resize(6)
    index=0
    elapsed=0
    var journal := TrialArchive.new().read(path)
    journal_message=journal.message
    if not journal.ok: return
    var current_hash := FileAccess.get_sha256(Derivation.new().get_script().resource_path)
    for entry in journal.entries:
        cards.append({"sentence":"MY PREDICTION MATCHED THIS RUN" if entry.prediction_matched else "MY PREDICTION FAILED IN THIS RUN",
            "scope":"Saved Godel experiment; finite unary model",
            "evidence":entry.duplicate(true), "student_record":true,
            "same_model_source":entry.model_sha256 == current_hash})
    if cards.size()>6: index=6

func current() -> Dictionary:
    return cards[index].duplicate(true)

func next() -> void:
    index=(index+1)%cards.size()
    elapsed=0

func advance(delta: float) -> void:
    if not paused and is_finite(delta) and delta>=0:
        var count: int=cards[index].sentence.split(" ").size()
        elapsed=fposmod(elapsed+delta,count*seconds_per_word)

func word() -> String:
    var words: PackedStringArray=cards[index].sentence.split(" ")
    return words[int(elapsed/seconds_per_word)%words.size()]

func pace() -> void:
    seconds_per_word=1.2 if seconds_per_word<1 else 0.6
    elapsed=0
```

### `synthesis_study.gd`

<!-- student-code:synthesis_study.gd -->
```gdscript
extends "bench.gd"
const ClaimRecord=preload("claim_record.gd")
var model:=ClaimRecord.new()
var journal_path := ClaimRecord.TrialArchive.DEFAULT_PATH
var journal_label: Label3D
var strip: Label3D
var wall: Label3D
var small: Label3D

func _ready() -> void:
    start("SYNTHESIS / A CLAIM AND ITS WARRANT", ["NEXT", "SIZE", "HOLD", "PACE"],
        [next_card,resize,hold,pace])
    wall=label(drawing,"",Vector3(0,1.42,-0.05),25)
    small=label(drawing,"",Vector3(0,1.04,0.4),12)
    strip=label(drawing,"",Vector3(0,1.2,0.2),25)
    point_home=Vector3(-1.15,1.14,0.4)
    journal_label=label(self,"",Vector3(0,1.69,-0.8),20)
    model.load_journal(journal_path)
    refresh()

func next_card() -> void:
    if point.held(): return
    model.next()
    refresh()

func resize() -> void:
    model.large=not model.large
    refresh()

func hold() -> void:
    model.paused=not model.paused
    refresh()

func pace() -> void:
    model.pace()
    refresh()

func _process(delta: float) -> void:
    model.advance(delta)
    if strip!=null: strip.text=model.word()

func refresh() -> void:
    var card:=model.current()
    small.text=card.sentence
    wall.text=card.sentence
    wall.font_size=25 if model.large else 17
    strip.text=model.word()
    readout.text="%d / %d | %s\nEvidence: %s\n%s | %.1f seconds/word"%[
        model.index+1,model.cards.size(),card.scope,str(card.evidence).left(110),
        "HELD" if model.paused else "RUNNING",model.seconds_per_word]
    journal_label.text=model.journal_message
    if card.get("student_record", false):
        var e: Dictionary=card.evidence
        readout.text="SAVED RUN %d | %s | budget %d | damage %s\nPredicted %s; checker accepted %s\n%s | examined %d" % [
            model.index-5,e.target,int(e.budget),str(e.damage),str(e.prediction),str(e.accepted),
            e.search_result.status,int(e.search_result.examined)]
        journal_label.text="%s | source %s\n%s; saved evidence is not rerun." % [
            e.saved_at,e.model_sha256.left(12),"Same model source" if card.same_model_source else "Different model source"]
```

## Predict, build, check

Freeze a copy of the current card. Change font size, hold for several simulated seconds, change pace, and complete a word cycle. Its scope and evidence must remain exactly the same. At the proof card, identify the target and budget before reading the large sentence. At the AI card, ask for a source or executable test; do not accept size, repetition or fluent wording as that evidence.

Edit a sentence in `cards` and run the three displays. The program will faithfully print even a false or overbroad sentence. This is a deliberate limit of the display, not permission to report the edited claim as validated. Compare it with the evidence kept alongside it and revise the words when they disagree.

Carry this practice into the QFEP laboratory: define the quantities, implement the operation, preserve the record and let someone challenge what the result entitles us to say.

At your own card, identify what you predicted before the run and whether it matched. A failed prediction is part of the evidence. Visit another card and return; restart the hall. The saved inputs and result must survive both. If the model source changes, retain the earlier card and read its source warning; a hash identifies bytes, not the truth or authorship of a record. The reader validates the record's format, not the historical honesty of someone editing its JSON.


The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.
