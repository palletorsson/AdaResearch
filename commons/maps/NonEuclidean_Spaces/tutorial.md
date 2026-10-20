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
