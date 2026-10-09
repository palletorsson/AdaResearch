# Bernini — a turn through height

## Learning elements

- Sampling an oval profile in rings.
- Giving each ring an angle according to its height.
- Connecting neighbouring rings with triangle faces.
- Separating stored geometry from whole-object rotation.

Walk between the museum's columns. Follow one ridge upward. Then keep your gaze at one height while the shaft turns past it. You are following two changes: one through height, the other through time.

Effect Sound put one sine inside another's phase. Here we return to Unit Circle's coordinates and Primitives' connected faces. A rising sequence of angles becomes a shape. We will build a small shaft beside the existing installation, using an oval profile so its orientation is easy to see.

## Carry the point as a control

Keep `point_body.gd` and `line_skin.gd` unchanged. The same black sphere now selects the amount of twist. Its trigger starts or stops rotation of the finished shaft. The pink line follows the same numbered corner up through the rings.

In your prepared museum working copy, attach `07_twisted_shaft.gd` to an empty, unit-scale `Node3D` at hall-local `(5, 0, 10)`, yaw 180 degrees, in the entrance study bay. Keep the three files together. The museum supplies floor, camera, light, player and XR input routing. The script creates the shaft, its low base, control and label. The shaft and base are visual studies without collision; the carried sphere retains its pickup collider.

Start with the shaft still. Lower the sphere to local height 0.8 metres: the profiles line up. Raise it to 1.2 metres: they make half a turn over the shaft's height. At 1.6 metres they make one turn. Movement beyond those heights is clamped. Press the trigger while holding the sphere. Watch the whole shaft rotate, then press again. The twist remains when rotation stops.

## Complete program

Only the main script is new. The two carried files are printed below it and included in the download.

<!-- student-code:07_twisted_shaft.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export var height := 2.4
@export var sides := 8
@export var spans := 16
@export var radii := Vector2(0.40, 0.20)
@export var angular_speed := 0.4
var turns := 0.5
var running := false
var points: Array[Vector3] = []
var faces: Array[Vector3i] = []
var shaft := Node3D.new()
var surface := MeshInstance3D.new()
var point: PointBody
var label: Label3D
var witness: Array[MeshInstance3D] = []

func ring_position(row: int, corner: int) -> Vector3:
    var u := float(row) / spans
    var angle := TAU * corner / sides
    var profile := Vector3(radii.x * cos(angle), 0, radii.y * sin(angle))
    return profile.rotated(Vector3.UP, TAU * turns * u) + Vector3(0, 0.25 + height * u, 0)

func turns_from_height() -> float:
    return clampf((point.position.y - 0.8) / 0.8, 0.0, 1.0)

func _ready() -> void:
    add_child(shaft)
    shaft.add_child(surface)
    var ivory := StandardMaterial3D.new()
    ivory.albedo_color = Color(0.91, 0.89, 0.84)
    ivory.roughness = 0.55
    surface.material_override = ivory
    var base := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.55
    cylinder.bottom_radius = 0.55
    cylinder.height = 0.25
    base.mesh = cylinder
    base.position.y = 0.125
    base.material_override = ivory
    add_child(base)
    for row in range(spans):
        var line := LineSkin.new()
        shaft.add_child(line)
        witness.append(line)
    point = PointBody.new()
    point.position = Vector3(1.1, 1.2, 0.4)
    var black := StandardMaterial3D.new()
    black.albedo_color = Color(0.025, 0.025, 0.03)
    black.roughness = 0.18
    point.get_child(0).material_override = black
    add_child(point)
    point.action_pressed.connect(toggle_rotation)
    label = Label3D.new()
    label.position = Vector3(0.5, 3.0, 0)
    label.font_size = 28
    label.pixel_size = 0.004
    add_child(label)
    turns = turns_from_height()
    rebuild()
    draw_label()

func rebuild() -> void:
    points.clear()
    faces.clear()
    for row in range(spans + 1):
        for corner in range(sides):
            points.append(ring_position(row, corner))
    for row in range(spans):
        for corner in range(sides):
            var next := (corner + 1) % sides
            var a := row * sides + corner
            var b := row * sides + next
            var c := a + sides
            var d := b + sides
            faces.append(Vector3i(a, b, c))
            faces.append(Vector3i(b, d, c))
    var bottom := points.size()
    points.append(Vector3(0, 0.25, 0))
    var top := points.size()
    points.append(Vector3(0, 0.25 + height, 0))
    for corner in range(sides):
        var next := (corner + 1) % sides
        faces.append(Vector3i(bottom, next, corner))
        faces.append(Vector3i(top, spans * sides + corner, spans * sides + next))
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    builder.set_smooth_group(-1)
    for face in faces:
        for index in [face.x, face.y, face.z]:
            builder.add_vertex(points[index])
    builder.generate_normals()
    surface.mesh = builder.commit()
    for row in range(spans):
        var a := points[row * sides]
        var b := points[(row + 1) * sides]
        witness[row].show_segment(a, b - a, a.distance_to(b))

func toggle_rotation(_held: Variant) -> void:
    running = not running
    draw_label()

func _process(delta: float) -> void:
    var selected := turns_from_height()
    if absf(selected - turns) > 0.002:
        turns = selected
        rebuild()
    if running:
        shaft.rotate_y(angular_speed * delta)
    draw_label()

func draw_label() -> void:
    label.text = "LIFT: %.2f turns through height\nTRIGGER: whole-object rotation %s" % [turns, "ON" if running else "OFF"]
```


## Read the shape

In `ring_position`, `corner` goes around one profile; `row` moves up the shaft. Dividing the row by `spans` gives `u`, from zero at the bottom to one at the top. The height is `0.25 + height * u`: the first quarter metre belongs to the base.

Cosine supplies X and sine supplies Z, as in Unit Circle, now on a horizontal plane. The unequal radii, 0.40 and 0.20 metres, make an oval. We rotate that profile around Y by `TAU * turns * u`. At half height, the angle is half the total turn. This multiplication has no clock in it. With the default half-turn, corner zero begins at `(0.40, 0.25, 0)`, passes through `(0, 1.45, -0.40)` and ends at `(-0.40, 2.65, 0)`.

A perfectly circular cross-section has no preferred orientation. Merely rotating such a section about its centre cannot give its ideal outline a visible twist. Our oval makes the operation legible. The larger museum columns also move their ring centres and vary their radius. This small study isolates one part of their construction; it does not reproduce every feature or an historical building.

## Connect the rings

Eight corners on each of seventeen rings give 136 positions. Sixteen *spans* are the spaces between those rings. The list still has one dimension: `row * sides + corner` gives an address, just as Grid used a row and column to find an entry.

For each span, `a` and `b` are neighbouring corners on its lower ring; `c` and `d` are the corresponding corners above. The triples `(a, b, c)` and `(b, d, c)` make two triangles. `% sides` wraps the last corner back to zero on the same ring. Without that wrap, the seam would connect the wrong entries. Two centre positions and triangle fans close the bottom and top. We end with 138 positions and 272 faces.

The renderer reads each face's three addresses, adds those positions and generates normals for lighting. The smoothing group of `-1` keeps each triangle flat, so the finite facets and cap edges remain visible. This is the face-list approach used in Polyhedra and Sine Space. The pink line is an added guide through corner zero, not an edge that the surface needs in order to exist.

## Stop the clock without losing the form

Lifting the sphere changes `turns`, so `rebuild` calculates new positions. The face relationships remain the same. Small hand changes below the stated 0.002-turn threshold are ignored to avoid needless rebuilds.

The trigger only changes `running`. While it is true, `rotate_y` changes the parent shaft's orientation by radians per second times `delta`. The stored positions and mesh resource stay unchanged. Stopping preserves the current pose; it does not straighten the shaft. The witness line is a child of the same shaft, so it turns with the surface. The control remains outside that rotating parent.

## Make another shaft

Change `height` from `2.4` to `3.6` and run again. Predict what happens at half height and at the top. The same half-turn is spread over a longer distance; the top's orientation stays the same. Then change `sides` from eight to twelve. The profile has more samples, while height and total turn remain fixed. Explain which edit changed spacing along the shaft and which changed sampling around it.

Keep a form you want to return to. Its list of positions remains when rotation stops. In John Cage, a list will keep sounds and their times instead. We return to the audio functions from Effect Sound and add the decisions about when to play them. The new subject is a score that can be performed again.

## Carried code

`point_body.gd` — the existing point and pickup behaviour.

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```


`line_skin.gd` — the existing finite cylinder between two positions.

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


Implementation reference: [Godot SurfaceTool](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html). The larger museum generator is `algorithms/wavefunctions/berninicolumns/BerniniColumns.gd`. It constructs a mesh on the CPU; this lesson does not require a vertex shader or noise.
