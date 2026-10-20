# Soft Body Deformation — one point stays

## Learning elements

- Give a subdivided cube to `SoftBody3D`
- Select and pin a vertex from its reference coordinates
- Distinguish stiffness, damping and pressure
- Use the carried point to press a deforming surface
- Restore settings without confusing that with restarting a simulation

In Procedural Generation, we kept descriptions, samples and results separate. Here the cube's surface keeps its connections while its positions change. Translation, rotation and scale moved the whole cube. This lesson lets its parts move relative to one another.

## Begin with the museum's cube

The green jelly cube is already here, held at one upper point. Its desk changes STIFFNESS, DAMPING and PRESSURE. Change one setting and watch before touching another. RESET restores settings; it does not rewind the surface. The mill and other bodies remain comparisons in the room.

We reconstruct that small setup: a subdivided cube, one selected attachment and the three response settings. Godot supplies the solver. The prepared Endless Museum supplies the camera, floor, player and XRTools. We retain the black PointBody from Mirrored Patterns and use its existing collider as a probe.

Save these three files together. Attach `study.gd` to an empty Node3D at unit scale in an open museum bay. The review places it at hall-local (11.5, 0, 8.5), yaw 180 degrees, beside the installed cube. This is a learner reconstruction inside the existing hall; it does not replace the hall's artifact.

## A mesh that can yield

`yielding_cube.gd` extends `SoftBody3D`. Unlike our earlier rigid point, this node uses its mesh for both rendering and collision. A separate box collider would remain rigid and would not describe the changing surface.

The familiar `BoxMesh` supplies a closed surface. Four subdivisions on each axis add positions that can move; this is different from `simulation_precision`, which controls solver work. Keep both fixed for the first comparison. The cube uses the installed artifact's 0.3 metre edge, mass and opening response values. The current project selects **Jolt Physics**.

Read the undeformed vertex array before the simulation changes it. `crown_index()` first restricts the search to the top face, then chooses the point closest to its centre in x and z. It returns an array address, not a position. Ties keep the first candidate. We do not invent an unexplained vertex number or assume that every subdivision has an exact centre vertex.

<!-- student-code:yielding_cube.gd -->
```gdscript
extends SoftBody3D

const EDGE := 0.3
const DIVISIONS := 4
var rest_points: PackedVector3Array
var anchor_index := -1

func _init() -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * EDGE
	box.subdivide_width = DIVISIONS
	box.subdivide_height = DIVISIONS
	box.subdivide_depth = DIVISIONS
	rest_points = box.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	mesh = box
	simulation_precision = 5
	total_mass = 1.0
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	reset_settings()
	anchor_index = crown_index(rest_points)
	set_point_pinned(anchor_index, true)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.2, 0.9, 0.5, 0.8)
	finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	finish.roughness = 0.2
	material_override = finish

func crown_index(points: PackedVector3Array) -> int:
	var selected := -1
	var nearest := INF
	for i in points.size():
		var p := points[i]
		if absf(p.y - EDGE * 0.5) > 0.001:
			continue
		var distance := Vector2(p.x, p.z).length_squared()
		if distance < nearest:
			nearest = distance
			selected = i
	assert(selected >= 0, "The mesh needs a top face.")
	return selected

func reset_settings() -> void:
	linear_stiffness = 0.5
	damping_coefficient = 0.01
	pressure_coefficient = 1.0
```

`_init()` runs when `YieldingCube.new()` constructs the object. It supplies the mesh before the host adds the body to the scene tree. That order matters: the soft body prepares its physics mesh when it enters the world. The host's `_ready()` then places the complete object in the museum.

The pin prevents that selected position from moving. The rest may respond to gravity and contact. The gold dot in the host marks the attachment; drawing the dot does not create the constraint. `set_point_pinned()` does that work.

`linear_stiffness` changes resistance to deformation. `damping_coefficient` reduces motion. `pressure_coefficient` adds inflation to this closed surface. These are different controls, not three names for softness. Begin with the given values; compare one change at a time rather than expecting a universal material from a slider number.

## The point becomes a probe

`study.gd` creates the cube and the same black point. The soft body's collision mask includes the point (mask value 4, meaning layer 3), the room (layer 1), and the museum hands (layers 18 and 19). The shifted bits select those hand layers. This adds contact with our carried point to the installed cube's existing room-and-hand mask. The inherited point itself needs no new geometry or grab implementation.

Grab it and move it slowly into the green surface. Its held position is prescribed by your hand. It can displace the soft surface, but the surface cannot move your tracked controller. Fast motion may pass through a small surface; begin with a slow press and observe contact.

The held trigger changes stiffness. On desktop, **1** changes stiffness, **2** damping, **3** pressure and **R** restores the settings. These paired values are a smaller comparison than the museum desk's cycles. Release parks the point clear of the cube, as it did in the earlier study.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const YieldingCube = preload("yielding_cube.gd")
const Point = preload("point_body.gd")
var cube: YieldingCube
var point: XRToolsPickable
var caption: Label3D

func _ready() -> void:
	cube = YieldingCube.new()
	cube.position = Vector3(0, 1.3, 0)
	add_child(cube)
	var pin := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.012
	sphere.height = 0.024
	pin.mesh = sphere
	pin.position = cube.position + cube.rest_points[cube.anchor_index]
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d7ad67")
	pin.material_override = gold
	add_child(pin)
	point = Point.new()
	point.position = Vector3(0.45, 1.3, 0.25)
	add_child(point)
	point.action_pressed.connect(func(_p): act("STIFFNESS"))
	caption = Label3D.new()
	caption.position = Vector3(0, 1.85, 0)
	caption.font_size = 32
	caption.pixel_size = 0.001
	add_child(caption)
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0.45, 1.3, 0.25))

func act(command: String) -> void:
	match command:
		"STIFFNESS": cube.linear_stiffness = 0.1 if cube.linear_stiffness > 0.1 else 0.5
		"DAMPING": cube.damping_coefficient = 0.1 if cube.damping_coefficient < 0.1 else 0.01
		"PRESSURE": cube.pressure_coefficient = 0.0 if cube.pressure_coefficient > 0.0 else 1.0
		"RESET": cube.reset_settings()
	refresh()

func refresh() -> void:
	caption.text = "ONE POINT STAYS\n1 stiffness %.2f | 2 damping %.2f\n3 pressure %.1f | R reset settings\nBlack point: press the surface; trigger changes stiffness" % [cube.linear_stiffness, cube.damping_coefficient, cube.pressure_coefficient]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("STIFFNESS")
			KEY_2: act("DAMPING")
			KEY_3: act("PRESSURE")
			KEY_R: act("RESET")
```

The host creates its label before calling `refresh()`. Every referenced object is created here or in the cube class. No pre-existing mesh node or scene-path lookup is required.

<details>
<summary>Carried file: point_body.gd — unchanged from Mirrored Patterns</summary>

Keep your existing file, or copy this identical version. Its sphere, collision boundary and XRTools pickup behaviour are inherited work.

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

</details>

## Predict, then compare

Find the gold attachment before moving the point. Predict which part must remain fixed. Press slowly, move the probe away and watch the surface continue responding. The hand supplied a condition; it did not specify every later position.

Restore settings. Change stiffness alone, then restore and change damping alone. Do the two bodies of motion look different? Keep the mesh and attachment fixed. A smaller movement does not by itself prove a greater stiffness: the interaction and elapsed time also matter.

Press R while the surface is moving. The same simulated body continues with the original coefficients. For a comparison with matching initial positions and velocities, restart the learner instance. Resetting coefficients alone is not that experiment.

Try one code change: set `DIVISIONS` to 2 and restart. Predict that the selection function will still find a top-face point and that the mesh will have fewer vertices. Test both claims. Describe the changed surface without calling fewer vertices a softer material. The next room will change which positions are pinned, using a sheet instead of an enclosed cube.

## Keep, change, compare

Keep the reference mesh and its attachment. Change one response setting. Compare motion while remembering that the running body carries state. Carry forward a complete solver setup and a selection rule for its boundary.

Sources: `commons/artifacts/jelly_cube/jelly_cube.gd`, `_create_soft_body()`, `_configure_anchor()` and `_reset_physics()`; `commons/artifacts/timing_machines/soft_workshop.gd`. API: [Godot 4.6 SoftBody3D](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html) and [the mesh-based setup](https://docs.godotengine.org/en/4.6/tutorials/physics/soft_body.html). The solver is supplied; the tutorial reconstructs its visible setup and conditions.
