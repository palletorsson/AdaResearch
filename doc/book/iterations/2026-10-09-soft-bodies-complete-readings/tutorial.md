# Soft Bodies — complete tutorial

9 October 2026 · Nine halls in canonical spine order.


---

<!-- hall:SoftBodies_Soft_Body_Deformation -->

# Soft Body Deformation — one point stays

## Learning elements

- Give a subdivided cube to `SoftBody3D`
- Select and pin a vertex from its reference coordinates
- Distinguish stiffness, damping and pressure
- Use the carried point to press a deforming surface
- Restore settings without confusing that with restarting a simulation

**Carry:** PointBody and cube construction.  
**New work:** Pin a reference vertex; compare stiffness, damping and pressure in `yielding_cube.gd` and its host.  
**Supplied:** The prepared museum and Jolt’s soft-body solver.

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


---

<!-- hall:SoftBodies_Cloth_Physics -->

# Cloth Physics — which points must stay?

## Learning elements

- An open sheet as a subdivided mesh
- Select a set of vertices from reference coordinates
- Combine conditions: top row, upper corners, no pins
- Separate the visible support from the simulated attachment
- Distinguish changing pins from rebuilding a body

**Carry:** PointBody and the previous SoftBody3D setup.  
**New work:** Build `hanging_sheet.gd`; select a row, two corners or no pins. The host makes those choices visible.  
**Supplied:** The prepared museum and Jolt’s solver.

The cube in the previous hall gave way around one fixed point. Keep its SoftBody3D setup and the black PointBody. Change the closed BoxMesh into an open sheet, then change the set of points that must stay. The new operation is a selection rule, not another solver.

## Begin with the hanging strips

The museum already contains eight strips. PINS changes each upper row from eight pinned points to two corners. RELEASE lets them all go. SUPPORT changes the surrounding frame without changing the pin indices. REBUILD makes fresh strips. Try those separately before touching STIFFNESS.

We reconstruct one wider, shorter sheet so that the upper edge is easy to inspect. Its mesh has the same subdivision counts as a museum strip; its dimensions are 1.2 by 1.4 metres. This is a small study of the same operation, not a duplicate of the whole curtain.

Save the three files together. Attach `study.gd` to a unit-scale Node3D in an open part of this existing hall. The prepared museum supplies its camera, floor, player, Jolt and XRTools. The review tests a temporary learner bay beside the strips; the scene does not replace the installed curtain.

## From one selected point to a selected edge

`hanging_sheet.gd` keeps the previous lesson's construction order: the mesh exists in `_init()` before the host adds the body to the world. `PlaneMesh.FACE_Z` puts this sheet in its local x–y plane. Its open surface has no enclosed volume, so pressure stays zero. Stiffness, damping and solver precision match the museum strips and remain fixed during the boundary comparison.

Keep `rest_points` before the solver starts. These local coordinates describe which vertices belong to the original top row, even after the sheet sags or the host moves. `set_pins()` applies one Boolean decision to every array entry:

- Mode 0: the point is on the top row.
- Mode 1: it is on that row **and** at either outer x edge.
- Mode 2: neither condition admits a pin.

The second `absf()` lets one test include both left and right edges. The small tolerance avoids requiring exact floating-point equality. Each call also unpins entries that no longer qualify; merely adding the two corners would leave the original row held.

<!-- student-code:hanging_sheet.gd -->
```gdscript
extends SoftBody3D

const WIDTH := 1.2
const HEIGHT := 1.4
const COLUMNS := 6
var rest_points: PackedVector3Array
var pins: Array[int] = []
var mode := 0

func _init() -> void:
	var surface := PlaneMesh.new()
	surface.orientation = PlaneMesh.FACE_Z
	surface.size = Vector2(WIDTH, HEIGHT)
	surface.subdivide_width = COLUMNS
	surface.subdivide_depth = 12
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	simulation_precision = 5
	total_mass = 1.0
	linear_stiffness = 0.34
	damping_coefficient = 0.05
	pressure_coefficient = 0.0
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("e7dbce")
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = finish
	set_pins(0)

func set_pins(next_mode: int) -> void:
	assert(next_mode in [0, 1, 2])
	mode = next_mode
	pins.clear()
	for i in rest_points.size():
		var p := rest_points[i]
		var top := absf(p.y - HEIGHT * 0.5) < 0.001
		var corner := absf(absf(p.x) - WIDTH * 0.5) < 0.001
		var keep := top and (mode == 0 or (mode == 1 and corner))
		set_point_pinned(i, keep)
		if keep:
			pins.append(i)
```

Six width subdivisions produce eight vertex columns. Twelve depth subdivisions produce fourteen rows: 112 entries. The first policy selects eight; the second selects two. `COLUMNS` sets subdivisions; the final vertex count includes the boundary columns.

## Continue with the same point

The host builds a small bar, the sheet, a readout and the unchanged point. Gold dots show the currently pinned positions. The bar is a visual mesh with no collider. Hiding it cannot remove pins. The museum's larger supports can have colliders, so changing their architecture can still change contact or passage while leaving the pin rule alone.

Grab the black point and press slowly into the sheet. Its existing collider is included in the sheet's mask, just as in the previous lesson. Press the held trigger to release the row to its two corners. Press it again to rebuild a straight row. On desktop, **1** does the same; **2** shows or hides the bar, **X** releases all pins and **R** rebuilds the sheet. The installed museum desk provides its own XR-accessible controls; this reduced host's extra comparisons use those keyboard keys.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const Sheet = preload("hanging_sheet.gd")
const Point = preload("point_body.gd")
const HOME := Vector3(0, 1.3, 0)
var sheet: Sheet
var point: XRToolsPickable
var frame: MeshInstance3D
var markers: Node3D
var caption: Label3D

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0, 2.45, 0)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	markers = Node3D.new()
	add_child(markers)
	frame = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(Sheet.WIDTH + 0.2, 0.05, 0.08)
	frame.mesh = bar
	frame.position = HOME + Vector3(0, Sheet.HEIGHT * 0.5 + 0.06, 0)
	add_child(frame)
	point = Point.new()
	point.position = Vector3(0.85, 1.3, 0.3)
	add_child(point)
	point.action_pressed.connect(func(_p): act("PINS"))
	rebuild()

func rebuild() -> void:
	if is_instance_valid(sheet):
		remove_child(sheet)
		sheet.queue_free()
	sheet = Sheet.new()
	sheet.position = HOME
	add_child(sheet)
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0.85, 1.3, 0.3))
	for j in sheet.pins.size():
		markers.get_child(j).global_position = sheet.get_point_transform(sheet.pins[j])

func act(command: String) -> void:
	match command:
		"PINS":
			if sheet.mode == 0: sheet.set_pins(1)
			else: rebuild()
		"SUPPORT": frame.visible = not frame.visible
		"RELEASE": sheet.set_pins(2)
		"REBUILD": rebuild()
	refresh()

func refresh() -> void:
	for marker in markers.get_children():
		markers.remove_child(marker)
		marker.queue_free()
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d7ad67")
	for i in sheet.pins:
		var dot := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.018
		sphere.height = 0.036
		dot.mesh = sphere
		dot.material_override = gold
		markers.add_child(dot)
		dot.global_position = sheet.get_point_transform(i)
	caption.text = "%s | %d pins\n1 / held trigger: pins | 2: show support\nX: release all | R: rebuild" % [["TOP ROW", "TWO CORNERS", "RELEASED"][sheet.mode], sheet.pins.size()]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("PINS")
			KEY_2: act("SUPPORT")
			KEY_X: act("RELEASE")
			KEY_R: act("REBUILD")
```

The first `PINS` action releases six attachments on the running sheet. The next constructs a fresh sheet with the top row held again, just as `REBUILD` does. Changing pin flags alone would leave its folds and motion in place. The same black point and visible bar survive; the gold dots follow the new sheet’s actual pinned positions.

<details>
<summary>Carried file: point_body.gd — unchanged from Soft Body Deformation</summary>

Keep your existing file, or use this identical copy. Sphere construction and grab behaviour are already learned work.

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

## Predict a release

Begin with the upper row pinned. Hide the bar. Predict that the eight attachments stay where they are, then check the gold dots. Bring the bar back and switch to two corners. Watch the six released upper points before pressing the sheet.

Return to the row and notice that this creates a fresh sheet. Then release every pin and watch gravity act. Rebuild again before the next comparison. Keep stiffness and damping unchanged throughout.

Now change `COLUMNS` from 6 to 10 and restart. Predict twelve top-row pins, two corner pins and 168 total entries. The same selection rule should work without a new list of vertex numbers. Explain why the middle points may move in corner mode even though every coefficient is unchanged.

Carry the reference coordinates and the selected boundary into the next hall. There the attachment itself will move. We first need to know what is being carried by it.

Sources: `algorithms/softbodies/cloth_straps/cloth_straps.gd`, `_setup_lesson_straps()`; `commons/artifacts/timing_machines/soft_workshop.gd`, `_cloth_pins()`. API: [PlaneMesh](https://docs.godotengine.org/en/4.6/classes/class_planemesh.html) and [SoftBody3D](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html). The engine solver is supplied; the boundary selection and complete learner host are printed above.

<details markdown="1">
<summary>Optional composition — choose three places</summary>

Keep a two-corner sheet as your reference. On a second sheet, choose three attachment positions in the undeformed coordinates. Select the nearest existing vertices, check that the three indices are distinct, and clear every other pin. Keep the mesh and material settings shared. Predict which former corner can now move; do not prescribe the exact fold. Write the selection before opening the [tested three-attachment example](/book-review/doc/book/iterations/2026-10-09-soft-bodies-three-attachments/index.html), which includes the complete host and its checks. Restore the two upper corners for Carusell.

</details>

<details markdown="1">
<summary>Optional museum return — A little give</summary>

The main lesson ends with the sheet and its selected boundary. This separate encounter changes load while preserving four anchors. Its supplied constraint solver is not required for Carusell; return when you want to compare what the same anchors are asked to carry.

<!-- study-spine:tension_membrane -->

## Return: A little give

Change the added load while preserving the four anchors and material compliance. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses soft, constraint, force. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`tension`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-nengudi-a-little-give/index.html). Release the pink handle before RESET or the preset pull. The four supports stay fixed throughout.

<!-- study-edit:tension_membrane -->

### One source change: A little give

In tension_score.gd, change the last entry of LOAD_KG from 3.0 to 2.0. Predict and compare the settled centre height after the same pull and release. Keep the pins and compliance fixed. The constraint solver and mesh renderer are supplied; no new foundational capability is required.

```gdscript
const LOAD_KG := [0.0, 1.0, 2.0]
```

Source: `commons/artifacts/spine_studies/tension_score.gd`. Use the prepared scene to run and compare.

<!-- tension-reference -->

### Pull, wait, release

This return follows the hanging strips: those changed the fixed points. Here the four corner points stay pinned. The pink bead is one additional prescribed point only while you hold it. Desktop: right-click the bead, move your view, then right-click to release. XR uses the ordinary pickup grip. HOLD A PULL supplies the same target each time; RELEASE lets it move again. Release a hand-held bead before using the preset or RESET.

Start unloaded, use HOLD A PULL, then RELEASE. Watch the bead and the centre height. LOAD selects the next downward load: 0, 1, 3, then 0 kg. Compare one load at a time. MORE / LESS GIVE changes the links' compliance independently of that load. RESET restores the unloaded, settled starting configuration and the firmer setting.

The bead and black load marker are representations. The solver distributes the additional downward force over nine central nodes; there is no separate falling rigid weight. The remaining mesh is visual, not a barrier to the player. The four supports and the museum floor are solid. A bounded grip target and floor limit keep the small study in its space.

### The next close reading

Begin with the single array edit above. The supplied solver keeps three arrays: current positions, previous positions and rest positions. Gravity changes the free points. Distance links share the displacement between their ends; four indices are excluded from movement. A held bead temporarily adds another exclusion. Releasing it removes that exclusion without replacing its current position with its rest position.

`compliance` controls the distance links' response; `damping` removes motion over time. They do different jobs. A softer response may settle lower, while greater damping makes the journey quieter. Neither creates wear or a remembered injury. The rest lengths remain unchanged.


### Reference

Whitney identifies nylon hosiery and places the work in the RSVP series. Nengudi discusses bodily and psychological elasticity and the energy associated with previously worn material. Ada makes an original four-anchor membrane encounter, not a reconstruction or a measurement of her sculpture. Its knit-like opaque surface is procedural. It models reversible distance constraints, damping and a distributed downward load, with a floor limit; it does not simulate nylon, damage, self-collision, skin or a human body.

[Senga Nengudi: Internal I (1977, refabricated 2014)](https://whitney.org/collection/works/46609).

</details>


---

<!-- hall:SoftBodies_Carusell -->

# Carusell — the support moves

## Learning elements

- A prescribed rotation: angular rate × elapsed time
- Move selected attachments in world coordinates
- Separate a command from the body's physical response
- Stop a driver without rebuilding the simulation

**Carry:** Unchanged `hanging_sheet.gd` and `point_body.gd`.  
**New work:** In `study.gd`, move the two attachments with a turning bar; let the sheet respond.  
**Supplied:** The prepared museum and Jolt’s solver.

In Cloth Physics you chose which points must stay. Keep that sheet and the same grabbable black point. This time the two upper corners follow a turning bar. Their attachment remains; its position changes.

## Watch the existing ride

The museum already contains a turning ring, jointed links and soft hanging bodies. Use SPEED, REVERSE and STOP while keeping one body in view. STOP stops the hub's rotation command. It does not remove gravity or restore the hanging bodies to their starting shapes.

The nearby cloth strips provide a fixed-support comparison. The pickup cubes, sticks and other soft objects remain available to explore. Reconstructing the whole collection is not this lesson's task.

## Continue the sheet

Save `study.gd` beside your unchanged `hanging_sheet.gd` and `point_body.gd` from Cloth Physics. Attach it to a unit-scale Node3D in an open part of the prepared museum. The museum supplies the player, camera, floor, XRTools and Jolt. The complete inherited files are included below for checking.

This study isolates the ride's driven-attachment operation using your existing sheet. It leaves out the ride's rigid links and joints. Its bar is visual and has no collider. Two gold markers show the attachment targets.

The familiar rotation rule advances `phase` in radians. Multiplying the rate by `delta` gives an angle for this physics step. `wrapf()` keeps the recorded angle between −π and π; it does not make the motion reverse at that boundary.

For each selected corner, `hub.to_global(offset)` converts a position on the bar into a position in the museum. `soft_body_move_point()` gives that target to the pinned vertex. `get_physics_rid()` identifies this sheet in Godot's physics server. Pinning prevents forces from moving these entries, but the program can still move them. The other entries remain the solver's responsibility.

Only the hub angle and the two attachment targets are prescribed. We never assign the sheet's whole rotation to make it follow the bar. The body can lag, fold or keep moving after the bar stops.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const Sheet = preload("hanging_sheet.gd")
const Point = preload("point_body.gd")
const RATE := 0.4
const HOME := Vector3(0, 1.3, 0)
var sheet: Sheet
var point: XRToolsPickable
var hub: Node3D
var caption: Label3D
var phase := 0.0
var rate := RATE

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0, 2.55, 0)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	hub = Node3D.new()
	hub.position = HOME + Vector3.UP * Sheet.HEIGHT * 0.5
	add_child(hub)
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(Sheet.WIDTH + 0.2, 0.05, 0.08)
	bar.mesh = box
	bar.position.y = 0.06
	hub.add_child(bar)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d7ad67")
	for side in [-1, 1]:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.018
		sphere.height = 0.036
		marker.mesh = sphere
		marker.material_override = gold
		marker.position.x = side * Sheet.WIDTH * 0.5
		hub.add_child(marker)
	point = Point.new()
	point.position = Vector3(1.15, 1.3, 0.6)
	add_child(point)
	point.action_pressed.connect(func(_p): act("PLAY / HOLD"))
	rebuild()

func rebuild() -> void:
	if is_instance_valid(sheet):
		remove_child(sheet)
		sheet.queue_free()
	phase = 0.0
	rate = RATE
	hub.rotation.y = phase
	sheet = Sheet.new()
	sheet.set_pins(1)
	sheet.position = HOME
	add_child(sheet)

func _physics_process(delta: float) -> void:
	phase = wrapf(phase + rate * delta, -PI, PI)
	hub.rotation.y = phase
	for i in sheet.pins:
		var offset := Vector3(sheet.rest_points[i].x, 0, 0)
		var target := hub.to_global(offset)
		PhysicsServer3D.soft_body_move_point(sheet.get_physics_rid(), i, target)
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(1.15, 1.3, 0.6))
	caption.text = "%.2f rad/s | %.2f rad\n1: speed | 2: reverse | 3: stop | R: rebuild\nHeld trigger: play / hold" % [rate, phase]

func act(command: String) -> void:
	match command:
		"SPEED": rate = RATE * 2.0 if is_equal_approx(rate, RATE) else RATE
		"REVERSE": rate = -rate
		"STOP": rate = 0.0
		"PLAY / HOLD": rate = RATE if is_zero_approx(rate) else 0.0
		"REBUILD": rebuild()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("SPEED")
			KEY_2: act("REVERSE")
			KEY_3: act("STOP")
			KEY_R: act("REBUILD")
```

`rebuild()` selects the two corners before the fresh sheet enters the world. Its reference mesh and material settings are unchanged. The two attachment targets are updated on every physics step, including while stopped; a stopped support still holds its points.

## Use the same ball

Grip the black point and press it slowly into the sheet. Its collider and pickup behaviour are unchanged. The held trigger now pauses or resumes the turning support. It changes the host's rate; it does not replace the point or the cloth.

Desktop keys: **1** switches between the base rate and twice that rate; **2** reverses the current rate; **3** stops it; **R** rebuilds the sheet and starts again. Reversing zero still gives zero. Use **1**, or the held trigger, to start after stopping. Resuming selects the positive base rate. The installed museum desk keeps its own SPEED, REVERSE and STOP controls; its speed presets differ from this small study.

Stop after a turn. The angle stops changing, but the free vertices can continue moving. Stop again: nothing is rebuilt. Then use REBUILD and notice the different operation—the reference sheet returns and the angle starts again at zero.

## One independent change

Change `RATE` from 0.4 to 0.8 and restart. Predict twice the commanded angle over the same interval: 0.8 instead of 0.4 radians after one second. One full turn takes `TAU / rate` seconds at a constant positive rate. Keep the geometry, pins and response settings unchanged.

Does the free edge travel twice as far? That does not follow from doubling the command. Its movement also depends on its current shape, velocity, gravity and contact. Explain the difference using the two gold attachment markers and one point farther down the surface.

Carry this separation into the next room: a program can drive a changing condition while a simulated body responds. There the changing condition will be pressure, and the surface will enclose the visitor.

<details>
<summary>Inherited sheet — unchanged from Cloth Physics</summary>

<!-- student-code:hanging_sheet.gd -->
```gdscript
extends SoftBody3D

const WIDTH := 1.2
const HEIGHT := 1.4
const COLUMNS := 6
var rest_points: PackedVector3Array
var pins: Array[int] = []
var mode := 0

func _init() -> void:
	var surface := PlaneMesh.new()
	surface.orientation = PlaneMesh.FACE_Z
	surface.size = Vector2(WIDTH, HEIGHT)
	surface.subdivide_width = COLUMNS
	surface.subdivide_depth = 12
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	simulation_precision = 5
	total_mass = 1.0
	linear_stiffness = 0.34
	damping_coefficient = 0.05
	pressure_coefficient = 0.0
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("e7dbce")
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = finish
	set_pins(0)

func set_pins(next_mode: int) -> void:
	assert(next_mode in [0, 1, 2])
	mode = next_mode
	pins.clear()
	for i in rest_points.size():
		var p := rest_points[i]
		var top := absf(p.y - HEIGHT * 0.5) < 0.001
		var corner := absf(absf(p.x) - WIDTH * 0.5) < 0.001
		var keep := top and (mode == 0 or (mode == 1 and corner))
		set_point_pinned(i, keep)
		if keep:
			pins.append(i)
```

</details>

<details>
<summary>Inherited grabbable PointBody — unchanged</summary>

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

The installed ride advances `ride_hub.rotation.y` in `_physics_process()` and attaches its soft bodies to moving rigid links through `set_point_pinned()` attachment paths. The learner study exposes the world-space target directly so the existing sheet can carry the new operation. Both arrangements prescribe the support; this is not a simulation of a motor receiving reaction torque.

Sources: `algorithms/softbodies/joyride/revolving_joy_ride.gd`, `commons/artifacts/timing_machines/soft_workshop.gd`. API: [PhysicsServer3D: moving pinned points](https://docs.godotengine.org/en/4.6/classes/class_physicsserver3d.html#class-physicsserver3d-method-soft-body-move-point). The supplied solver handles the free entries; the complete boundary update is printed above.


---

<!-- hall:SoftBodies_Obsticals -->

# Pressure — a drive and a room

## Learning elements

- A closed surface receives internal pressure
- Map a sine wave to a nonnegative pressure coefficient
- Separate amplitude, rate and material response
- Hold a drive without freezing its recipient

**Carry:** PointBody, closed-box construction and coordinate-based pin selection.  
**New work:** Build `pressure_panel.gd`; drive its pressure from a sine wave in `study.gd`.  
**Supplied:** The prepared museum and Jolt’s solver.

Carusell moved the attachments of your sheet. Here the attachments stay and a pressure coefficient changes. Keep the same black PointBody. Return to the closed box from the first Soft Bodies lesson: flatten it into a small panel, then place two copies opposite each other.

## Meet the existing walls

The museum's pink slabs already receive a periodic pressure command. Watch one fixed point and one free part of a surface. Use AMPLITUDE, RATE and HOLD DRIVE on the nearby desk. Holding the drive retains its last pressure; the physics simulation continues. RESET PHASE changes the drive's clock, not the body's history.

The installed walls are not identical samples. Their authored stiffness, shrinking settings and selected pins differ. A shared pressure command does not make their responses a controlled comparison of one parameter. The small learner model below deliberately starts its two panels with matching settings.

## Close the surface

An open cloth sheet does not enclose an interior. A thin BoxMesh does. Its six sides remain a closed surface even when the object looks almost flat. We reuse the coordinate test from Cloth Physics to pin the top, bottom and ends; the broad faces can deform between those boundaries.

Save `pressure_panel.gd` beside the unchanged `point_body.gd`. This is the same construction pattern as the yielding cube, with dimensions and a perimeter pin rule chosen for a wall. Mesh and pins are prepared before the body enters the physics world.

<!-- student-code:pressure_panel.gd -->
```gdscript
extends SoftBody3D

const SIZE := Vector3(0.16, 1.2, 1.8)
var rest_points: PackedVector3Array
var pins: Array[int] = []

func _init() -> void:
	var surface := BoxMesh.new()
	surface.size = SIZE
	surface.subdivide_height = 6
	surface.subdivide_depth = 8
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	total_mass = 1.0
	linear_stiffness = 0.5
	damping_coefficient = 0.1
	pressure_coefficient = 0.0
	simulation_precision = 5
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("c98288")
	material_override = finish
	for i in rest_points.size():
		var p := rest_points[i]
		var edge := absf(absf(p.y) - SIZE.y * 0.5) < 0.001 or absf(absf(p.z) - SIZE.z * 0.5) < 0.001
		if edge:
			set_point_pinned(i, true)
			pins.append(i)
```

## Drive pressure

Save `study.gd` beside those files and attach it to a unit-scale Node3D in an open area of the prepared Endless Museum. Player, camera, floor, XRTools and Jolt are already supplied. This is a small two-panel study you can reach around; it does not replace the installed architecture. The inherited point file is printed below.

`sin(phase)` runs from −1 to 1. Adding one and halving gives 0 to 1. Multiplying by `amplitude` gives 0 to that chosen maximum. At phase zero the pressure is half the maximum. The coefficient is an engine control, not a calibrated value in pascals.

`rate * delta` advances phase in radians. Rate controls the period; amplitude controls the input range. Neither number specifies how far the surface must move. This host updates the command on physics steps; the installed scene uses its frame callback. Both leave vertex motion to the solver.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const PressurePanel = preload("pressure_panel.gd")
const Point = preload("point_body.gd")
const RATE := 1.0
const AMPLITUDE := 0.5
var panels: Array[PressurePanel] = []
var point: XRToolsPickable
var caption: Label3D
var phase := 0.0
var rate := RATE
var amplitude := AMPLITUDE
var held := false
var pressure := 0.0

func _ready() -> void:
	for side in [-1, 1]:
		var panel := PressurePanel.new()
		panel.position = Vector3(side * 0.8, 1.3, 0)
		add_child(panel)
		panels.append(panel)
	point = Point.new()
	point.position = Vector3(0, 1.3, 1.2)
	add_child(point)
	point.action_pressed.connect(func(_p): act("HOLD DRIVE"))
	caption = Label3D.new()
	caption.position = Vector3(0, 2.15, 0.8)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	apply_pressure()

func _physics_process(delta: float) -> void:
	if not held:
		phase = wrapf(phase + rate * delta, 0.0, TAU)
	apply_pressure()
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.3, 1.2))
	caption.text = "PRESSURE %.2f | phase %.2f\n1 amplitude %.2f | 2 rate %.2f | 3 hold %s\n4 stiffness | R reset phase | held trigger: hold drive" % [pressure, phase, amplitude, rate, held]

func apply_pressure() -> void:
	pressure = (sin(phase) + 1.0) * 0.5 * amplitude
	for panel in panels:
		panel.pressure_coefficient = pressure

func act(command: String) -> void:
	match command:
		"AMPLITUDE": amplitude = 0.15 if amplitude > 0.15 else AMPLITUDE
		"RATE": rate = RATE * 0.5 if is_equal_approx(rate, RATE) else RATE
		"HOLD DRIVE": held = not held
		"STIFFNESS":
			for panel in panels:
				panel.linear_stiffness = 0.2 if panel.linear_stiffness > 0.2 else 0.5
		"RESET PHASE": phase = 0.0
	apply_pressure()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("AMPLITUDE")
			KEY_2: act("RATE")
			KEY_3: act("HOLD DRIVE")
			KEY_4: act("STIFFNESS")
			KEY_R: act("RESET PHASE")
```

## Hold the command

Grip the familiar black point. Its held trigger toggles HOLD DRIVE. You can still move the point and press it slowly against a panel. Releasing parks it at the opening. The point is a contact probe and a switch; its position is not mapped to pressure.

Desktop controls: **1** changes amplitude; **2** halves/restores the base rate; **3** holds/resumes the phase; **4** changes stiffness on both panels; **R** sets phase to zero. The installed desk uses its own presets. Read the value before comparing.

Hold near the pressure peak and watch. A constant pressure can still produce motion while the body responds. The program never pins all vertices or disables physics to make HOLD appear successful. Changing amplitude while held immediately changes the pressure at that same phase; holding the clock does not lock every control.

Use RESET PHASE while held. Pressure returns to half the current amplitude. The same panel objects and their current shapes remain. Resetting the signal is different from rebuilding its recipient.

## One independent change

Change `AMPLITUDE` from 0.5 to 0.25 and restart. Predict the pressure at phase zero, π/2 and 3π/2: 0.125, 0.25 and zero. The period remains `TAU / RATE`, about 6.28 seconds with RATE 1.0. Keep geometry, pins, stiffness and damping unchanged.

You halved the commanded pressure. Does the gap between the panels halve? Measure or watch before answering: their response also involves geometry, constraints, material settings and accumulated motion. A pressure value is not a clearance measurement.

The contact gallery and flag dancer remain further encounters in this hall. The tutorial follows one drive into two known bodies. In the next hall, we will control the starting conditions of a contact experiment so that a comparison can be repeated.

<details>
<summary>Inherited grabbable PointBody — unchanged</summary>

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

Source: the installed `breathing_room.tscn` uses `breathing_room_scene.gd`; the sibling `breathing_room.gd` builds a different, unused room. See [Godot's SoftBody3D pressure property](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html#class-softbody3d-property-pressure-coefficient) and [BoxMesh](https://docs.godotengine.org/en/4.6/classes/class_boxmesh.html). Jolt supplies the simulation; the complete construction and pressure command are printed here.


---

<!-- hall:SoftBodies_Obsticals_Part2 -->

# Same fall, another encounter

## Learning elements

- Describe a comparison as two cases
- Change one coefficient while retaining the shared construction
- Rebuild starting conditions instead of resetting only the clock
- Keep a timed observation while the bodies continue

**Carry:** Unchanged `pressure_panel.gd` and `point_body.gd`.  
**New work:** In `study.gd`, compare matched falls and retain a timed height reading.  
**Supplied:** The prepared museum and Jolt’s solver.

The last hall gave matching panels a pressure command. Keep those panel and PointBody classes. Here we remove the panels' pins, turn them flat and let them fall onto two copies of the black point. Both drops begin alike. Only their damping coefficients differ.

## Find a comparison in the museum

<!-- @softbody_gallery_part2 -->

The existing gallery contains twelve named encounters. High Drag gives a sphere more damping; Corner Strike changes where it meets a collider. Other cells change shape, stiffness or pressure together. Looking across the array can suggest a question, but it does not isolate its cause.

The desk's REPLAY reconstructs the group with seed 1337. VARIATION toggles additional changes to stiffness and pressure; GROUP selects another set. A seed repeats the chosen inputs to the random generator. It does not rewind a body or guarantee identical physical trajectories on every machine.

For our smaller comparison, there is no random input to seed. We can state the two cases directly.

## Two cases, one construction

Continue in the prepared Endless Museum: player, floor, camera, XRTools and Jolt already exist. Keep the previous `pressure_panel.gd` and `point_body.gd` beside the new `study.gd`. Attach the host to a unit-scale Node3D in a clear area. The complete inherited files are below.

`CASES` is a list of two dictionaries. Each dictionary names a case and supplies its damping coefficient. Everything else comes from the same panel constructor: mesh, mass, stiffness, pressure, solver setting and material. The two bays are simply separated so their bodies cannot collide with each other.

The old perimeter pins would prevent a fall. The host unpins them on both new panels, then rotates each panel by a quarter turn. Pressure remains zero; there is no sine driver in this experiment. Both black points have the same sphere mesh and collision shape. Their small offset places each point beneath a vertex in the panel's existing grid; it is part of the shared contact setup.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const SamplePanel = preload("pressure_panel.gd")
const Point = preload("point_body.gd")
const SAMPLE_TIME := 1.5
const CONTACT := Vector3(0.6 / 7.0, 1.1, 0.1)
const CASES := [
	{"name": "A", "damping": 0.1},
	{"name": "B", "damping": 0.6},
]
var panels: Array[SamplePanel] = []
var points: Array[XRToolsPickable] = []
var captions: Array[Label3D] = []
var results: Array[float] = []
var elapsed := 0.0
var running := false
var armed := false
var status := ""

func _ready() -> void:
	for i in CASES.size():
		var point := Point.new()
		point.position = bay(i) + CONTACT
		add_child(point)
		points.append(point)
		point.action_pressed.connect(func(_p): request_replay())
		var caption := Label3D.new()
		caption.position = bay(i) + Vector3(0, 2.8, 0.5)
		caption.font_size = 28
		caption.pixel_size = 0.003
		add_child(caption)
		captions.append(caption)
	replay()

func bay(i: int) -> Vector3:
	return Vector3((i - 0.5) * 2.0, 0, 0)

func request_replay() -> void:
	armed = true

func replay() -> void:
	for panel in panels:
		remove_child(panel)
		panel.queue_free()
	panels.clear()
	results.clear()
	for i in CASES.size():
		var panel := SamplePanel.new()
		for index in panel.pins:
			panel.set_point_pinned(index, false)
		panel.pins.clear()
		panel.position = bay(i) + Vector3(0, 2.1, 0)
		panel.rotation.z = PI * 0.5
		panel.damping_coefficient = CASES[i].damping
		add_child(panel)
		panels.append(panel)
	elapsed = 0.0
	running = true
	armed = false
	status = "Fresh drop"

func _physics_process(delta: float) -> void:
	var hand_inside := false
	for i in points.size():
		if points[i].held():
			hand_inside = true
		else:
			points[i].global_transform = global_transform * Transform3D(Basis.IDENTITY, bay(i) + CONTACT)
	if hand_inside:
		running = false
		results.clear()
		status = "Hand changes the experiment"
	elif armed:
		replay()
	elif running:
		elapsed += delta
		if elapsed >= SAMPLE_TIME:
			for panel in panels:
				results.append(height_span(panel))
			running = false
			status = "Sample kept; bodies continue"
	for i in captions.size():
		var reading := "height --"
		if results.size() == CASES.size():
			reading = "height %.3f m" % results[i]
		captions[i].text = "%s | damping %.2f\n%s | t %.2f s\n%s\n1 or grip / trigger / release: replay" % [CASES[i].name, CASES[i].damping, reading, elapsed, status]

func height_span(panel: SoftBody3D) -> float:
	var low := INF
	var high := -INF
	for i in panel.rest_points.size():
		var y := to_local(panel.get_point_transform(i)).y
		low = minf(low, y)
		high = maxf(high, y)
	return high - low

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		request_replay()
```

## Run and touch

The first pair drops when the study starts. Watch it from the side. Use **1** to repeat. In VR, grip either black point, press its trigger, then release it. The trigger requests a replay; releasing returns both points to their declared places before the new drop begins.

You can still move a point against a panel. Doing so interrupts the measured comparison and clears its readings: your hand has added another changing condition. Trigger and release when you want a fresh trial. A queued replay waits until neither point is held. The program never drags a held point back to its parking place.

`replay()` removes the two old panels from the world and constructs fresh ones. It clears the recorded results and starts the clock again. The PointBody instances remain. Resetting only `elapsed` would leave the existing folds and motion in place, giving the second attempt a different beginning.

## Keep one observation

At the first physics step reaching 1.5 seconds, the host reads each panel's vertex positions. It records the highest minus the lowest height in the study's coordinate frame. This is a vertical extent in metres, not volume, material quality or distance travelled. Keep the host upright and at unit scale.

`get_point_transform()` supplies world positions. `to_local()` brings them into the same reference frame before comparison. The value stays on the caption while the panels continue moving. Sampling does not freeze their physics.

Compare several fresh trials. More damping is expected to reduce motion, but contact, gravity and folding also affect the height at one chosen time. A different height is an observation to investigate; it is not a direct reading of damping. Keep other moving objects and your hands clear during the measured run.

## One independent change

Change B's damping from **0.6 to 0.1** and restart. Before running, predict what now matches: both recipes, contact shapes, initial orientations and release heights. Predict similar readings under the same conditions, rather than promising exact equality across all computers. If a difference persists, check the starting construction, environment and timing before adding another explanation.

You have a repeatable procedure and a small record of its outcome. In the next hall, we will ask what happens when a selected reading or a stopped surface comes to stand for the whole event.

<details>
<summary>Inherited pressure panel — unchanged; this host releases its pins</summary>

<!-- student-code:pressure_panel.gd -->
```gdscript
extends SoftBody3D

const SIZE := Vector3(0.16, 1.2, 1.8)
var rest_points: PackedVector3Array
var pins: Array[int] = []

func _init() -> void:
	var surface := BoxMesh.new()
	surface.size = SIZE
	surface.subdivide_height = 6
	surface.subdivide_depth = 8
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	total_mass = 1.0
	linear_stiffness = 0.5
	damping_coefficient = 0.1
	pressure_coefficient = 0.0
	simulation_precision = 5
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("c98288")
	material_override = finish
	for i in rest_points.size():
		var p := rest_points[i]
		var edge := absf(absf(p.y) - SIZE.y * 0.5) < 0.001 or absf(absf(p.z) - SIZE.z * 0.5) < 0.001
		if edge:
			set_point_pinned(i, true)
			pins.append(i)
```

</details>

<details>
<summary>Inherited grabbable PointBody — unchanged</summary>

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

The installed gallery remains a larger collection of possibilities. This learner study isolates one comparison using the objects you already constructed; it does not rebuild all twelve exhibits.


---

<!-- hall:SoftBodies_Playground_of_Joy -->

# A shape kept

## Learning elements

- Vertex positions and face indices
- Copying a snapshot
- Local coordinates and display placement
- Sampling time versus simulation state

**Carry:** PointBody and the idea of keeping a timed observation.  
**New work:** In `study.gd`, copy positions and face indices while their source continues.  
**Supplied:** The prepared museum; `vessel_surface.gd` and its particle solver replace the earlier Jolt panel.

<!-- @rounded_softbody_test -->

At the rounded body, change MEASURE. The display changes; the body keeps responding. FEEDBACK is a separate action: it changes pressure using the volume of an enclosing box as its reading. That box is a proxy, not the volume inside the skin. Explore this distinction here; the code lesson follows the glass vessel beside it.

<!-- @ -->

<!-- @frozen_glass_vessel -->

Last hall you kept a number while a panel continued to fall. Now keep a surface. The installed vessel already does this: start with a sphere, pin its upper region, simulate, then build a mesh from the resulting positions. DURATION reconstructs it with another number of steps. You are choosing which state becomes the object.

**We carry the act of sampling into a different supplied body.** The previous panel used Jolt. This vessel uses the museum’s custom particle solver, whose `positions` array we can read directly. Its construction and solver are given in full below; we do not transfer the panel’s damping or pressure settings to them. The new work is copying a moving surface. Our black PointBody returns unchanged as the capture control.

## Other shapes in this hall

Four comparison stations extend this encounter. In the first, choose which four moments of one simulation remain. In the second, pull the black point sideways and release: three matching constructions receive opposite lateral pulls. In the third, show the saved surface's triangle edges. Hiding the skin changes its appearance; its contact surface remains.

At **From the soft body gallery**, NEXT selects another group of three examples. POSE, or the held point's trigger, switches between starting and captured geometry: cloth, a lattice, a branch, a cellular-automata net and two mould experiments. Each pair keeps the same display frame. These are saved shapes; the controls do not resume their simulations. Cloth and sphere-grid skins are drawn over their saved connections; other examples show the spring network. A mould constrains particles in this model; it is not a simulation of molten glass.

Use these examples to ask what was retained. The tutorial below still builds one operation: copy the vessel's positions and face indices while its source continues.

## Build beside the encounter

Work in the prepared Endless Museum project. The player, camera, lighting, floor, XRTools and physics setup are already supplied. Create a Node3D named `ShapeKept` in a clear part of this hall, at floor level and unit scale. Attach `study.gd`. Put all four files below in the same folder. The downloadable `study.tscn` provides exactly that root and script attachment; it contains no hidden meshes.

`study.gd` is the new work. `point_body.gd` is the previous hall's class. `vessel_surface.gd` supplies the installed vessel's sphere, spring connections and mesh assembly. `solver.gd` is an unchanged copy of `commons/soft_body/soft_body_sim.gd`. They are printed below for a complete runnable example; writing a solver is not this lesson's task.

Two pink surfaces appear. The left one runs. At step 40, the right one keeps a copy. Hold the black point and press its trigger to replace that copy with a later state. On desktop, press **1** to capture and **2** to start again. Holding or moving the point does not deform these surfaces; here its trigger operates the sampler.

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const VesselSurface = preload("vessel_surface.gd")
const PointBody = preload("point_body.gd")
const SAMPLE_STEP := 40
const STEP := 0.0166667
var surface = VesselSurface.new()
var live := MeshInstance3D.new()
var kept := MeshInstance3D.new()
var point = PointBody.new()
var caption := Label3D.new()
var step_count := 0
var saved_step := -1
var saved_positions := PackedVector3Array()
var saved_indices := PackedInt32Array()

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c98288")
	material.roughness = 0.3
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for body in [live, kept]:
		body.material_override = material
		add_child(body)
	live.position = Vector3(-0.85, 2.0, 0)
	kept.position = Vector3(0.85, 2.0, 0)
	point.position = Vector3(0, 1.1, 1.0)
	add_child(point)
	point.action_pressed.connect(func(_source): capture())
	caption.position = Vector3(0, 3.0, 0)
	caption.font_size = 32
	caption.pixel_size = 0.0025
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)
	restart()

func _physics_process(_delta: float) -> void:
	surface.sim.step(STEP)
	step_count += 1
	live.mesh = surface.mesh_for(surface.sim.positions, surface.indices)
	if step_count == SAMPLE_STEP:
		capture()
	update_caption()

func capture() -> void:
	saved_positions = surface.sim.positions.duplicate()
	saved_indices = surface.indices.duplicate()
	saved_step = step_count
	kept.mesh = surface.mesh_for(saved_positions, saved_indices)
	update_caption()

func restart() -> void:
	surface = VesselSurface.new()
	step_count = 0
	saved_step = -1
	saved_positions.clear()
	saved_indices.clear()
	kept.mesh = null
	live.mesh = surface.mesh_for(surface.sim.positions, surface.indices)
	update_caption()

func update_caption() -> void:
	var reading := "waiting" if saved_step < 0 else "step %d" % saved_step
	caption.text = "LIVE: step %d    |    KEPT: %s\nPoint trigger / 1: capture    2: restart" % [step_count, reading]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			capture()
		elif event.keycode == KEY_2:
			restart()
```

## Read the operation

`capture()` copies two arrays. Positions say where the vertices are. Indices say which entries form each triangle, just as in the earlier polyhedra lesson. We keep that connectivity while the positions change. The helper recalculates normals for the saved surface and returns a new ArrayMesh.

The copied positions remain in the solver's local frame, measured in the project's metre scale. The two mesh nodes place the same shape to the left and right. Their offsets stage the comparison; they do not change the saved data. Adding a world position to those vertices would apply placement twice.

Each physics callback advances the custom solver by its fixed `0.0166667` step, approximately `1/60` second. We count those steps explicitly. Step 40 means forty integrations; the caption does not promise that forty callbacks took a particular amount of wall-clock time. `SAMPLE_STEP` selects the automatic capture. A trigger can capture at any other step, including after that selection.

Only the live mesh is rebuilt each tick. The saved mesh stays until another capture or a restart. No disk file is written. This snapshot keeps positions, triangle connections and a step number. It omits the solver's previous positions, pins, spring settings and force history. A shape alone is not enough to resume this simulation. The displayed copy also has no collision body; the installed glass artifact does.

## Change when you stop

Change `SAMPLE_STEP` from `40` to `200`. Before running, predict what stays the same: the vertex count, face indices and display placement. Predict what may change: the saved positions. Run the whole example. Check the KEPT caption, then wait. The left side must continue; the right side must keep its step-200 shape. Trigger another capture and verify that the right side changes only then.

Use **2** to restart. The saved mesh and step label clear, the solver is reconstructed, and the same point object remains available. Resetting only the counter would not restart the experiment.

## Supplied files

These files expose the construction the host relies on. Keep their settings fixed for the capture-time experiment. The adapter follows the installed vessel's radius, rings, segments, upper pins, initial expansion and spring order. It uses the same local positions but displays both results in opaque pink so their contours can be compared.

<details>
<summary>vessel_surface.gd — sphere, constraints and mesh assembly</summary>

<!-- student-code:vessel_surface.gd -->
```gdscript
extends RefCounted
## Supplied adapter: the installed glass vessel's construction and solver.
const Solver = preload("solver.gd")
const RINGS := 14
const SEGMENTS := 22
const RADIUS := 0.55
var sim = Solver.new()
var indices := PackedInt32Array()

func _init() -> void:
	sim.stiffness = 0.6
	sim.damping = 0.995
	sim.gravity = Vector3(0, -9.8, 0)
	sim.floor_y = -10.0
	sim.constraint_passes = 5
	for ring in RINGS + 1:
		var phi := PI * float(ring) / RINGS
		var y := cos(phi) * RADIUS
		var ring_radius := sin(phi) * RADIUS
		for segment in SEGMENTS:
			var theta := TAU * float(segment) / SEGMENTS
			var p := Vector3(ring_radius * cos(theta), y, ring_radius * sin(theta))
			var pinned := p.y > RADIUS * (1.0 - 0.12 * 2.0)
			if not pinned:
				p *= 1.2
			sim.add_particle(p, pinned)
	for ring in RINGS:
		for segment in SEGMENTS:
			var next := (segment + 1) % SEGMENTS
			var a := ring * SEGMENTS + segment
			var b := ring * SEGMENTS + next
			var c := (ring + 1) * SEGMENTS + segment
			var d := (ring + 1) * SEGMENTS + next
			sim.add_spring(a, b)
			sim.add_spring(a, c)
			sim.add_spring(a, d)
			indices.append_array([a, c, d, a, d, b])

func mesh_for(points: PackedVector3Array, faces: PackedInt32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(points.size())
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i + 1]
		var c := faces[i + 2]
		var n := (points[b] - points[a]).cross(points[c] - points[a]).normalized()
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 0.0 else Vector3.UP
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = faces
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
```

</details>

<details>
<summary>point_body.gd — the unchanged grabbable point</summary>

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

<details>
<summary>solver.gd — the supplied particle solver</summary>

<!-- student-code:solver.gd -->
```gdscript
# soft_body_sim.gd — Deterministic Verlet-integrator soft body simulator.
# Particles connected by springs. Fixed-timestep headless simulation —
# load a config, step N times, capture the final geometry, render.
#
# This is NOT Godot's SoftBody3D (which is visual cloth only). This is
# a research simulator: same config + same seed = exact same pose every
# time, so the rendered PNG is a reproducible artifact of the DNA.
#
# Algorithm: Verlet integration + iterative distance-constraint relaxation.
# Each step:
#   1. update each non-pinned particle position with Verlet (pos' = 2*pos - prev + accel*dt²)
#   2. apply constraint solver N times (each spring pulls endpoints toward rest_length)
#
# Materials/rendering handled by soft_body_shapes.gd, not here.

extends RefCounted

# Particle indexed fields (parallel arrays — faster than per-particle dicts)
var positions: PackedVector3Array = PackedVector3Array()
var prev_positions: PackedVector3Array = PackedVector3Array()
var pinned: Array = []                 # bool per particle
var masses: PackedFloat32Array = PackedFloat32Array()

# Springs as (a_idx, b_idx, rest_length)
var springs: Array = []
var stiffness: float = 0.8    # 0..1, applied per constraint pass
var constraint_passes: int = 4

# Environment
var gravity: Vector3 = Vector3(0, -9.8, 0)
var damping: float = 0.995    # multiplied into Verlet velocity (1.0 = none)
var floor_y: float = -10.0    # particles stopped at this y

# Topology hints — used by the renderer to know how to draw.
# For cloth: grid_cols × grid_rows, lets the renderer emit triangles.
var topology: String = "generic"    # "cloth_grid" | "jelly_box" | "blob" | "generic"
var grid_cols: int = 0
var grid_rows: int = 0


## Step simulation forward by dt seconds (usually 1/60).
func step(dt: float = 0.0166667) -> void:
	# Verlet position update
	for i in positions.size():
		if pinned[i]:
			continue
		var pos: Vector3 = positions[i]
		var prev: Vector3 = prev_positions[i]
		var vel: Vector3 = (pos - prev) * damping
		var new_pos: Vector3 = pos + vel + gravity * dt * dt
		prev_positions[i] = pos
		positions[i] = new_pos
		# Floor collision
		if positions[i].y < floor_y:
			positions[i].y = floor_y
			prev_positions[i].y = floor_y

	# Constraint relaxation — distance constraints per spring, repeated
	for _p in constraint_passes:
		for s in springs:
			var a: int = s[0]
			var b: int = s[1]
			var rest: float = s[2]
			var pa: Vector3 = positions[a]
			var pb: Vector3 = positions[b]
			var diff: Vector3 = pb - pa
			var cur: float = diff.length()
			if cur < 1e-6:
				continue
			var correction: float = (cur - rest) * 0.5 * stiffness
			var dir: Vector3 = diff / cur
			var cv: Vector3 = dir * correction
			if not pinned[a]:
				positions[a] = pa + cv
			if not pinned[b]:
				positions[b] = pb - cv


## Run N simulation steps.
func simulate(n: int, dt: float = 0.0166667) -> void:
	for _i in n:
		step(dt)


## Add a particle. Returns index.
func add_particle(pos: Vector3, is_pinned: bool = false, mass: float = 1.0) -> int:
	var idx: int = positions.size()
	positions.append(pos)
	prev_positions.append(pos)
	pinned.append(is_pinned)
	masses.append(mass)
	return idx


## Add a spring between two particles. Rest length defaults to current distance.
func add_spring(a: int, b: int, rest_length: float = -1.0) -> void:
	if rest_length < 0.0:
		rest_length = positions[a].distance_to(positions[b])
	springs.append([a, b, rest_length])
```

</details>

## What travels onward

You can turn one state of a process into a separate object, state when you selected it, and name what you left out. Keep the four files. The next lesson reconstructs their step-40 shape as a common starting point; it does not automatically carry your latest trigger capture between halls. We will keep that geometry fixed while changing its appearance: does looking alive tell us how something was made?

<!-- @ -->


---

<!-- hall:SoftBodies_Affect_Theory_Visualization -->

# One shape, one cue

## Learning elements

- A controlled comparison
- Shared geometry, separate materials
- Node motion versus vertex deformation
- Resetting the previous condition
- Appearance and the mechanism it suggests

**Carry:** Unchanged vessel, solver and PointBody files; the step-40 recipe.  
**New work:** In `study.gd`, compare one turn or colour change while keeping geometry fixed.  
**Supplied:** The prepared museum. The inherited solver reconstructs the snapshot once.

<!-- @radiolaria -->

Walk between the radiolaria forms. Stop ROTATION, then turn EFFECTS off. The specimens remain. Their spikes, rings and repeated parts were constructed; the surrounding particles and the turning were additional cues.

This court begins with a fixed construction seed. SEED selects another repeatable draw. COLOUR rebuilds the forms with another palette; keeping the seed helps you compare the same construction. SPIKES can change the geometry and later random choices, so it is a different experiment. A setting called “spikiness” is a generator parameter, not a measured capacity to defend a living body.

Last hall you kept positions and face indices while their source continued. Here we keep that shape fixed and vary its presentation. Two identical copies make the comparison clear: the left stays still and neutral; the right receives one cue. The forms in this room prompted the question. The previous lesson’s snapshot recipe supplies the material for testing it.

## Reconstruct the recorded shape

Work inside the prepared Endless Museum project, where the player, camera, lighting and XRTools already run. Create a Node3D named `OneCue` in a clear place at floor level and unit scale. Attach the following `study.gd`. Keep `vessel_surface.gd`, `solver.gd` and `point_body.gd` beside it: they are unchanged from the previous lesson and printed at the end. The supplied `study.tscn` contains just this root and script attachment.

For a repeatable starting point, this script reconstructs the previous lesson's step-40 snapshot from the same recipe. It does not load a drawing from disk or resume your previous play session. The solver runs those forty steps once. After that, only the display changes.

Hold the black point and press its trigger, or press **1** on desktop. Cycle through three conditions: both copies neutral and still; only the right copy turns; only the right copy changes colour. Press **2** to return to the first condition.

## Complete study.gd

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const VesselSurface = preload("vessel_surface.gd")
const PointBody = preload("point_body.gd")
const SAMPLE_STEP := 40
const TURN_SPEED := 0.7
const NEUTRAL := Color("d6cec0")
const ACCENT := Color("c982a9")
var surface = VesselSurface.new()
var left := MeshInstance3D.new()
var right := MeshInstance3D.new()
var point = PointBody.new()
var caption := Label3D.new()
var saved_positions := PackedVector3Array()
var saved_indices := PackedInt32Array()
var condition := 0

func _ready() -> void:
	# Reconstruct the previous lesson's step-40 snapshot from its same recipe.
	surface.sim.simulate(SAMPLE_STEP, 0.0166667)
	saved_positions = surface.sim.positions.duplicate()
	saved_indices = surface.indices.duplicate()
	var saved_mesh: ArrayMesh = surface.mesh_for(saved_positions, saved_indices)
	for body in [left, right]:
		body.mesh = saved_mesh
		var finish := StandardMaterial3D.new()
		finish.albedo_color = NEUTRAL
		finish.roughness = 0.5
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		body.material_override = finish
		add_child(body)
	left.position = Vector3(-1.25, 2.2, 0)
	right.position = Vector3(1.25, 2.2, 0)
	point.position = Vector3(0, 1.1, 1.0)
	add_child(point)
	point.action_pressed.connect(func(_source): next_condition())
	caption.position = Vector3(0, 3.4, 0)
	caption.font_size = 32
	caption.pixel_size = 0.0025
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)
	set_condition(0)

func _process(delta: float) -> void:
	if condition == 1:
		right.rotate_z(TURN_SPEED * delta)

func set_condition(value: int) -> void:
	condition = value
	right.rotation = Vector3.ZERO
	right.material_override.albedo_color = NEUTRAL
	if condition == 2:
		right.material_override.albedo_color = ACCENT
	caption.text = ["SAME SHAPE / same appearance", "SAME SHAPE / right turns", "SAME SHAPE / right changes colour"][condition]
	caption.text += "\nPoint trigger / 1: next    2: reset"

func next_condition() -> void:
	set_condition((condition + 1) % 3)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			next_condition()
		elif event.keycode == KEY_2:
			set_condition(0)
```

## Read the comparison

Both MeshInstance3D nodes refer to `saved_mesh`. This shared resource is useful because neither copy edits it. Their positions put the same local geometry in two places.

Each loop iteration creates a separate material. Changing the right material therefore leaves the left material alone. If both nodes shared one material, the colour comparison would change both copies.

`_process` turns the right node only in condition 1. `delta` makes `TURN_SPEED` a rate in radians per second. The node's transform changes; its stored vertices do not. This is the transformation you learned earlier, applied to a shape whose deformation has already stopped.

`set_condition` first resets the right node's orientation and colour. Moving from rotation to colour therefore removes the previous cue. Without that reset, the coloured copy could keep a different orientation and you would be comparing more than one change.

No soft-body simulation runs in `_process`. Nothing senses the visitor, grows or decides where to turn. The point's trigger chooses a condition; it does not give the displayed surface a new physical behaviour.

## Make one comparison of your own

Change `TURN_SPEED` from `0.7` to `0.35`. Before running, predict what should differ after one second and what must stay unchanged. The turn angle should halve. The left copy, both vertex arrays and both colours should stay the same. Then return to the still condition before testing a different `ACCENT` colour.

Say what you saw before giving it a biological name. “The right copy turns while the left stays” can be checked against the program. “The right one feels more alive to me” records your response. An assertion can protect the first distinction; it cannot establish the second for every visitor.

The next hall changes the underlying state again: values spread and react across a field. We will be able to ask which visible differences come from those exchanges and which come from how the field is shown.

<!-- @ -->

## Carried files — unchanged

These are the complete files from **A shape kept**. Reuse your copies if they match; no new solver or point class is being introduced here.

<details markdown="1">
<summary>vessel_surface.gd — unchanged</summary>

<!-- student-code:vessel_surface.gd -->
```gdscript
extends RefCounted
## Supplied adapter: the installed glass vessel's construction and solver.
const Solver = preload("solver.gd")
const RINGS := 14
const SEGMENTS := 22
const RADIUS := 0.55
var sim = Solver.new()
var indices := PackedInt32Array()

func _init() -> void:
	sim.stiffness = 0.6
	sim.damping = 0.995
	sim.gravity = Vector3(0, -9.8, 0)
	sim.floor_y = -10.0
	sim.constraint_passes = 5
	for ring in RINGS + 1:
		var phi := PI * float(ring) / RINGS
		var y := cos(phi) * RADIUS
		var ring_radius := sin(phi) * RADIUS
		for segment in SEGMENTS:
			var theta := TAU * float(segment) / SEGMENTS
			var p := Vector3(ring_radius * cos(theta), y, ring_radius * sin(theta))
			var pinned := p.y > RADIUS * (1.0 - 0.12 * 2.0)
			if not pinned:
				p *= 1.2
			sim.add_particle(p, pinned)
	for ring in RINGS:
		for segment in SEGMENTS:
			var next := (segment + 1) % SEGMENTS
			var a := ring * SEGMENTS + segment
			var b := ring * SEGMENTS + next
			var c := (ring + 1) * SEGMENTS + segment
			var d := (ring + 1) * SEGMENTS + next
			sim.add_spring(a, b)
			sim.add_spring(a, c)
			sim.add_spring(a, d)
			indices.append_array([a, c, d, a, d, b])

func mesh_for(points: PackedVector3Array, faces: PackedInt32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(points.size())
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i + 1]
		var c := faces[i + 2]
		var n := (points[b] - points[a]).cross(points[c] - points[a]).normalized()
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 0.0 else Vector3.UP
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = faces
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
```

</details>

<details markdown="1">
<summary>point_body.gd — unchanged</summary>

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

<details markdown="1">
<summary>solver.gd — unchanged</summary>

<!-- student-code:solver.gd -->
```gdscript
# soft_body_sim.gd — Deterministic Verlet-integrator soft body simulator.
# Particles connected by springs. Fixed-timestep headless simulation —
# load a config, step N times, capture the final geometry, render.
#
# This is NOT Godot's SoftBody3D (which is visual cloth only). This is
# a research simulator: same config + same seed = exact same pose every
# time, so the rendered PNG is a reproducible artifact of the DNA.
#
# Algorithm: Verlet integration + iterative distance-constraint relaxation.
# Each step:
#   1. update each non-pinned particle position with Verlet (pos' = 2*pos - prev + accel*dt²)
#   2. apply constraint solver N times (each spring pulls endpoints toward rest_length)
#
# Materials/rendering handled by soft_body_shapes.gd, not here.

extends RefCounted

# Particle indexed fields (parallel arrays — faster than per-particle dicts)
var positions: PackedVector3Array = PackedVector3Array()
var prev_positions: PackedVector3Array = PackedVector3Array()
var pinned: Array = []                 # bool per particle
var masses: PackedFloat32Array = PackedFloat32Array()

# Springs as (a_idx, b_idx, rest_length)
var springs: Array = []
var stiffness: float = 0.8    # 0..1, applied per constraint pass
var constraint_passes: int = 4

# Environment
var gravity: Vector3 = Vector3(0, -9.8, 0)
var damping: float = 0.995    # multiplied into Verlet velocity (1.0 = none)
var floor_y: float = -10.0    # particles stopped at this y

# Topology hints — used by the renderer to know how to draw.
# For cloth: grid_cols × grid_rows, lets the renderer emit triangles.
var topology: String = "generic"    # "cloth_grid" | "jelly_box" | "blob" | "generic"
var grid_cols: int = 0
var grid_rows: int = 0


## Step simulation forward by dt seconds (usually 1/60).
func step(dt: float = 0.0166667) -> void:
	# Verlet position update
	for i in positions.size():
		if pinned[i]:
			continue
		var pos: Vector3 = positions[i]
		var prev: Vector3 = prev_positions[i]
		var vel: Vector3 = (pos - prev) * damping
		var new_pos: Vector3 = pos + vel + gravity * dt * dt
		prev_positions[i] = pos
		positions[i] = new_pos
		# Floor collision
		if positions[i].y < floor_y:
			positions[i].y = floor_y
			prev_positions[i].y = floor_y

	# Constraint relaxation — distance constraints per spring, repeated
	for _p in constraint_passes:
		for s in springs:
			var a: int = s[0]
			var b: int = s[1]
			var rest: float = s[2]
			var pa: Vector3 = positions[a]
			var pb: Vector3 = positions[b]
			var diff: Vector3 = pb - pa
			var cur: float = diff.length()
			if cur < 1e-6:
				continue
			var correction: float = (cur - rest) * 0.5 * stiffness
			var dir: Vector3 = diff / cur
			var cv: Vector3 = dir * correction
			if not pinned[a]:
				positions[a] = pa + cv
			if not pinned[b]:
				positions[b] = pb - cv


## Run N simulation steps.
func simulate(n: int, dt: float = 0.0166667) -> void:
	for _i in n:
		step(dt)


## Add a particle. Returns index.
func add_particle(pos: Vector3, is_pinned: bool = false, mass: float = 1.0) -> int:
	var idx: int = positions.size()
	positions.append(pos)
	prev_positions.append(pos)
	pinned.append(is_pinned)
	masses.append(mass)
	return idx


## Add a spring between two particles. Rest length defaults to current distance.
func add_spring(a: int, b: int, rest_length: float = -1.0) -> void:
	if rest_length < 0.0:
		rest_length = positions[a].distance_to(positions[b])
	springs.append([a, b, rest_length])
```

</details>


---

<!-- hall:ProceduralGeneration_Reaction_Diffusion_Systems -->

# What keeps a pattern changing?

## Learning elements

- Local reaction, supply and removal
- Exchange and reaction as separate contributions
- Old state and next state
- Matched starts and equal step counts
- A concentration field and its colour display

**Carry:** The earlier CA lesson’s four-neighbour field, display pattern and PointBody.  
**New work:** Expose local reaction, supply and removal in `field.gd`; compare both cases with `reaction.gd`.  
**Supplied:** The prepared museum. The vessel solver ends here.

<!-- @turing_pattern_generator -->

At the desk, press STEP, then 100 STEPS. The little patch changes slowly. RESET brings it back. REGIME changes two rates and restarts; SEEDING changes the starting arrangement. Compare one intervention at a time.

In the previous hall a copied surface remained while its source was no longer running. Here we ask what a pattern needs to keep happening. Return to the two fields from **CA — What a neighbour offers**. Both contain U and V at every address. That lesson compared neighbour exchange while a supplied reaction ran in both. Now keep exchange in both and open that reaction function.

## Keep the field; open the local rule

Reuse the CA lesson's `field.gd`, two-table display and PointBody. Replace the field with the complete version below; use `reaction.gd` for this comparison. A keeps reaction, supply and removal. B begins with those local terms off, so it only exchanges with its neighbours. Both start from the same 6 × 6 patch and advance the same number of steps.

The new work is in `next_pair`. `conversion = a * b * b` removes an amount from U and adds the same amount to V. With no V present, this conversion is zero. `supply = FEED * (1 - a)` replenishes U toward one. `removal = (KILL + FEED) * b` removes V: in this model, feed also contributes to V's removal. These are the local Gray–Scott terms.[^model]

Neighbour exchange is added separately. The four-neighbour stencil, diffusion coefficients, wrapping boundary and starting square are carried from CA. The installed hall display uses weighted contributions from eight neighbours and different default rates. It demonstrates the same kind of model; it is not an identical numerical run. We keep the learner's known stencil so this lesson changes one part of their program.

One call remains one numerical step with dt = 1, not one second of physical time. Read old U and V, write next U and V, then replace both arrays. The clamp keeps the output in 0–1; it does not make arbitrary coefficients or larger timesteps accurate or stable.

## Predict one address

W is now (15,15), inside the patch. All four neighbours initially match its U = 0.5 and V = 0.25, so both neighbour differences are zero. This position isolates the local terms for the first step.

| Term | Amount |
| --- | --- |
| Conversion from U to V | 0.5 × 0.25 × 0.25 = 0.03125 |
| Supply of U | 0.037 × (1 − 0.5) = 0.0185 |
| Removal of V | (0.060 + 0.037) × 0.25 = 0.02425 |

After one step, A has **U = 0.48725, V = 0.257** at W. B stays **U = 0.5, V = 0.25** there. B still changes around the patch boundary through exchange. Turning off local terms does not freeze the whole field.

## Complete field.gd

<!-- student-code:field.gd -->
```gdscript
extends RefCounted
const N := 32
const FEED := 0.037
const KILL := 0.060
var u := PackedFloat32Array()
var v := PackedFloat32Array()
var exchange := true
var local_terms := true
var ticks := 0

func _init() -> void:
	u.resize(N * N)
	v.resize(N * N)
	reset()

func index(x: int, y: int) -> int:
	return posmod(y, N) * N + posmod(x, N)

func reset() -> void:
	u.fill(1.0)
	v.fill(0.0)
	ticks = 0
	for y in range(13, 19):
		for x in range(13, 19):
			u[index(x, y)] = 0.5
			v[index(x, y)] = 0.25

func seed_at(site: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			u[index(site.x + dx, site.y + dy)] = 0.5
			v[index(site.x + dx, site.y + dy)] = 0.25

func laplacian(values: PackedFloat32Array, x: int, y: int) -> float:
	return values[index(x - 1, y)] + values[index(x + 1, y)] + values[index(x, y - 1)] + values[index(x, y + 1)] - 4.0 * values[index(x, y)]

func next_pair(a: float, b: float, lap_u: float, lap_v: float) -> Vector2:
	# Keep the CA lesson's four-neighbour exchange; one numerical step has dt = 1.
	var coupling := 1.0 if exchange else 0.0
	var du := coupling * 0.16 * lap_u
	var dv := coupling * 0.08 * lap_v
	if local_terms:
		var conversion := a * b * b
		var supply := FEED * (1.0 - a)
		var removal := (KILL + FEED) * b
		du += -conversion + supply
		dv += conversion - removal
	return Vector2(clampf(a + du, 0.0, 1.0), clampf(b + dv, 0.0, 1.0))

func step() -> void:
	var next_u := PackedFloat32Array()
	var next_v := PackedFloat32Array()
	next_u.resize(N * N)
	next_v.resize(N * N)
	for y in N:
		for x in N:
			var i := index(x, y)
			var answer := next_pair(u[i], v[i], laplacian(u, x, y), laplacian(v, x, y))
			next_u[i] = answer.x
			next_v[i] = answer.y
	u = next_u
	v = next_v
	ticks += 1
```

## Run the comparison in the museum

Use your existing museum project with its player, camera, lighting and XRTools. Keep the three files together. Attach `reaction.gd` to a Node3D at floor level and unit scale, facing its positive Z side, with about 3.3 × 2.4 metres clear. The downloadable `study.tscn` contains only that root and script attachment. Every display, material, label and control point used here is created in code.

The staging is carried from CA. W moves inside the patch; the comparison switch now controls local terms instead of exchange. The unchanged black point still selects an address. Hold it just above either table and trigger to replace a 3 × 3 patch at the corresponding address in both fields. Away from the table, or when unheld, it changes nothing. A new patch changes state without changing the rule or the clock. Release parks the point on its shelf.

- **Enter:** one step. **Space:** 100 steps, up to 2,400.
- **C:** enable/disable B's local terms and restart both fields together.
- **R:** replay from the starting square, preserving the comparison setting.
- **V:** display U or V. This changes the view, not the state.
- **Point trigger / I while holding:** plant the same patch in both fields.

The compact learner uses keyboard controls for time and comparison, with XR/desktop pickup for planting. The installed hall supplies its own nearby VR desk. This reconstruction does not claim that its clock is operated by the point trigger.

## Complete reaction.gd

Read `advance`, `change_local_terms` and `plant` first. The display helpers are the carried construction, not a second task to learn here. Each table and its upright panel share a texture. V is mapped through V × 2 before colouring: a saturated colour is not proof that the stored concentration is one.

<!-- student-code:reaction.gd -->
```gdscript
extends Node3D
const Field = preload("field.gd")
const PointBody = preload("point_body.gd")
const LIMIT := 2400
const W := Vector2i(15, 15)
var left := Field.new()
var right := Field.new()
var point: XRToolsPickable
var reading := Label3D.new()
var textures: Array[ImageTexture] = []
var show_u := false
var injections := 0

func _ready() -> void:
	right.local_terms = false
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): plant())
	park()
	reset()

func reset() -> void:
	left.reset()
	right.reset()
	injections = 0
	paint()

func advance(count: int) -> void:
	for i in mini(count, LIMIT - left.ticks):
		left.step()
		right.step()
	paint()

func change_local_terms() -> void:
	right.local_terms = not right.local_terms
	reset()

func target_site() -> Vector2i:
	if not point.held():
		return Vector2i(-1, -1)
	var at := to_local(point.global_position)
	for cx in [0.85, -0.85]:
		if absf(at.x - cx) < 0.64 and absf(at.z - 0.5) < 0.64 and absf(at.y - 1.01) < 0.35:
			return Vector2i(floori((at.x - cx + 0.64) / 0.04), floori((at.z - 0.5 + 0.64) / 0.04))
	return Vector2i(-1, -1)

func plant() -> void:
	var site := target_site()
	if site.x < 0:
		return
	left.seed_at(site)
	right.seed_at(site)
	injections += 1
	paint()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(0, 1.12, -0.35)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: advance(1)
			KEY_SPACE: advance(100)
			KEY_R: reset()
			KEY_C: change_local_terms()
			KEY_V: show_u = not show_u; paint()
			KEY_I: plant()
			_: return
		get_viewport().set_input_as_handled()

func tint(value: float) -> Color:
	if show_u:
		return Color("241e46").lerp(Color("bce8bc"), value)
	return Color("122d3d").lerp(Color("edb1cb"), clampf(value * 2.0, 0.0, 1.0))

func paint() -> void:
	for side in 2:
		var field = left if side == 0 else right
		var data: PackedFloat32Array = field.u if show_u else field.v
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				image.set_pixel(x, y, tint(data[y * 32 + x]))
		textures[side].update(image)
	var i := left.index(W.x, W.y)
	reading.text = "TICK %d / W (15,15)\nA: U %.3f  V %.3f\nB: U %.3f  V %.3f\nB LOCAL TERMS %s / VIEW %s / SEEDS %d\nENTER: STEP   SPACE: +100   R: REPLAY\nC: LOCAL TERMS B   V: VIEW   TRIGGER / I: PLANT" % [left.ticks, left.u[i], left.v[i], right.u[i], right.v[i], "ON" if right.local_terms else "OFF", "U" if show_u else "V x2", injections]

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("263744")
	node.material_override = material
	add_child(node)
	return node

func make_display() -> void:
	for side in 2:
		var cx := -0.85 if side == 0 else 0.85
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var texture := ImageTexture.create_from_image(image)
		textures.append(texture)
		var title := Label3D.new()
		title.text = "A / REACTION + EXCHANGE" if side == 0 else "B / EXCHANGE + OPTIONAL REACTION"
		title.position = Vector3(cx, 2.42, -0.4)
		title.font_size = 22
		title.pixel_size = 0.0015
		add_child(title)
		var finish := StandardMaterial3D.new()
		finish.albedo_texture = texture
		finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		var table := box(Vector3(1.36, 0.08, 1.36), Vector3(cx, 0.96, 0.5))
		box(Vector3(0.5, 0.92, 0.5), Vector3(cx, 0.46, 0.5))
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.36, 0.08, 1.36)
		boundary.shape = shape
		table.add_child(body)
		body.add_child(boundary)
		for wall in [false, true]:
			var display := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(1.28, 1.28)
			display.mesh = plane
			display.material_override = finish
			display.position = Vector3(cx, 1.7, -0.4) if wall else Vector3(cx, 1.01, 0.5)
			if wall:
				display.rotation.x = PI / 2.0
			add_child(display)
		var mark := box(Vector3(0.038, 0.004, 0.038), Vector3(cx + (W.x + 0.5 - 16) * 0.04, 1.014, 0.5 + (W.y + 0.5 - 16) * 0.04))
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color("ffe49a")
		gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gold.albedo_color.a = 0.3
		mark.material_override = gold
	reading.position = Vector3(0, 2.65, 0.5)
	reading.font_size = 30
	reading.pixel_size = 0.0013
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	add_child(reading)
```

## Make a comparison of your own

Set FEED to `0.050`, leaving KILL, the initial patch and exchange unchanged. Predict the first step at W: U should become **0.49375**, V **0.25375** in A, while B's first-step values stay unchanged. Feed appears in two places, so increasing it both supplies more U and removes more V.

Run from reset. Compare the numbers after one step before comparing the patterns after 100 or 1,000. To recover an identical pair, enable B's local terms and restart: every value in A and B should agree at the same step. If they do not, inspect their starting state, parameters and update order before interpreting the picture.

The next hall starts a different field: a three-dimensional sine-and-noise rule. We carry the same PointBody and the method of matched comparison; these concentration arrays stay here. The new lesson separates changes to that spatial rule from changes to the cut that selects its surface.

## Carried point_body.gd — unchanged

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

<!-- @ -->

<!-- @reaction_diffusion -->

## Other encounters in this hall

The second reaction–diffusion display has its own implementation and clock. It is a comparison to explore, not a synchronized copy of this study. The soft-body samples, bulge and Confessing Body remain wider encounters. The tutorial follows one pair of fields; no additional artifact has to become a prerequisite.

<!-- @ -->

[^model]: John E. Pearson, [“Complex Patterns in a Simple System”](https://arxiv.org/abs/patt-sol/9304003), 1993, studies numerical Gray–Scott patterns. This tutorial uses the project's reduced discretization. Its two concentration variables and colour map are not measurements of chemicals in the room.


---

<!-- hall:Topology_Entropy_Morphogenesis -->

# Who connected the controls?

**Learning elements**

- One control, several named parameters
- Holding other parameters fixed
- Field values versus a selected boundary
- Previewing a change before rebuilding geometry

**Carry:** PointBody and the method of matched comparison.  
**New work:** In `recipe.gd`, separate frequency, noise and cut; preview, then commit.  
**Supplied:** The prepared museum and GyroidFieldGenerator’s field sampling, surface extraction and collision.

<!-- @entropy_morphogenesis -->

Look through one opening in the large pale surface. Press S at the museum desk. The form is reconstructed. Follow the opening, then read the new frequency, noise amplitude and threshold. A single action changed three numbers.

Last hall you kept two fields at the same step and isolated their local reaction. Keep that way of comparing. Here we use a different field: a three-dimensional sine rule with a fixed noise contribution. It is not the previous concentration array lifted into space, and it has no simulation clock.

The existing generator samples this field and constructs a boundary. We will keep that machinery supplied and write the recipe that controls it. The same PointBody becomes our hand control. Two small surfaces make the comparison readable: A keeps the opening recipe; B receives your change.

## The operation

Read `recipe()` first. Its three named outputs have different jobs. **Frequency** changes how quickly the sine field varies across space. **Noise amplitude** changes the contribution of a fixed noise field. **Threshold** chooses which field value becomes the boundary. Moving a threshold does not alter the underlying sine-and-noise values.

ALL connects the selected value to all three outputs. FREQUENCY, NOISE and CUT connect it to one output and hold the other two at their opening value, 0.3. Each comparison therefore returns to a common reference; it does not accumulate the previous mode's edits.

At value 0.3, the recipe is frequency **1.11**, noise **0.095**, cut **−0.06**. Predict value 1 before rebuilding:

|Mode|Frequency|Noise amplitude|Cut|
|---|---:|---:|---:|
|ALL|1.60|0.20|0.15|
|FREQUENCY|1.60|0.095|−0.06|
|NOISE|1.11|0.20|−0.06|
|CUT|1.11|0.095|0.15|

`lerpf()` interpolates between two numbers. The cut uses a centred range: `2 * value - 1` runs from −1 to 1; `CUT_SPAN` sets its extent. The dictionary retains the names when `assign()` passes the outputs to their recipients. None of these calculations measures entropy.

## Run beside the existing artifact

In the Endless Museum project, put `recipe.gd` and the unchanged `point_body.gd` in one folder. Attach `recipe.gd` to an empty Node3D at floor level and unit scale in a clear part of this hall. It creates both small specimens, plinths, labels and the point. The museum already supplies the player, camera, lighting and XRTools. The accompanying `study.tscn` is this one-node host.

**Supplied dependency:** the project's `GyroidFieldGenerator`, declared in `algorithms/spacetopology/gyroid_cheese/GyroidFieldGenerator.gd`, supplies field sampling, surface extraction and collision. Its MarchingCubesGenerator, VoxelChunk and CaveCollisionGenerator dependencies remain in the project. We do not recreate their algorithms or claim they have been taught here. This example runs inside the project, not in a blank Godot installation.

Both generators use seed 1337, an eight-unit cube and 24 sampling cells per edge. Their holders display them at quarter scale. Each specimen is two metres wide; the generator's field coordinates stay unchanged. This deliberately cubic fixture avoids the supplied generator's use of one spacing derived from box width for all three axes. The large installed specimen has its own dimensions and is not an identical third copy.

### recipe.gd — complete construction

The lesson's new code is `recipe()` and `assign()`. The rest connects their result to supplied geometry and the familiar point. It is printed in full so the host can run without hidden child nodes.

<!-- student-code:recipe.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const CUT_SPAN := 0.15
const MODES := ["ALL", "FREQUENCY", "NOISE", "CUT"]
var mode := 0
var preview := 0.3
var committed := 0.3
var built_mode := 0
var point: XRToolsPickable
var reading := Label3D.new()
var generators: Array[GyroidFieldGenerator] = []
var holders: Array[Node3D] = []

func recipe(value: float, choice: int) -> Dictionary:
	var s := clampf(value, 0.0, 1.0)
	var f := s if choice == 0 or choice == 1 else 0.3
	var n := s if choice == 0 or choice == 2 else 0.3
	var t := s if choice == 0 or choice == 3 else 0.3
	return {"frequency": lerpf(0.9, 1.6, f),
		"noise_amp": lerpf(0.05, 0.20, n),
		"threshold": CUT_SPAN * (2.0 * t - 1.0)}

func assign(generator: GyroidFieldGenerator, values: Dictionary) -> void:
	generator.frequency = values.frequency
	generator.noise_amp = values.noise_amp
	generator.threshold = values.threshold

func apply_preview() -> void:
	assign(generators[1], recipe(preview, mode))
	generators[1].regenerate(holders[1])
	committed = preview
	built_mode = mode
	refresh()

func reset() -> void:
	mode = 0
	preview = 0.3
	apply_preview()

func _ready() -> void:
	for side in 2:
		var holder := Node3D.new()
		holder.position = Vector3(-1.25 if side == 0 else 1.25, 1.6, 0)
		holder.scale = Vector3.ONE * 0.25
		add_child(holder)
		holders.append(holder)
		var generator := GyroidFieldGenerator.new()
		generator.box_size = Vector3.ONE * 8.0
		generator.voxel_resolution = Vector3i(24, 24, 24)
		generator.noise.seed = 1337
		assign(generator, recipe(0.3, 0))
		generator.generate_gyroid_mesh(holder)
		generator.generate_collision(holder)
		generators.append(generator)
		plinth(holder.position.x)
		caption("A / KEPT AT 0.30" if side == 0 else "B / YOUR RECIPE", Vector3(holder.position.x, 2.8, 0))
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body):
		if point.held(): apply_preview())
	park()
	reading.position = Vector3(0, 3.25, 0.8)
	reading.font_size = 40
	reading.pixel_size = 0.002
	add_child(reading)
	caption("PULL UP: 0.80m -> 1.60m / TRIGGER: BUILD", Vector3(0, 0.65, 1.35))
	refresh()

func _physics_process(_delta: float) -> void:
	if point.held():
		preview = clampf((to_local(point.global_position).y - 0.8) / 0.8, 0.0, 1.0)
		refresh()
	else:
		park()

func park() -> void:
	point.position = Vector3(0, 0.8 + preview * 0.8, 1.35)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: mode = (mode + 1) % MODES.size()
			KEY_UP: preview = minf(1.0, preview + 0.1)
			KEY_DOWN: preview = maxf(0.0, preview - 0.1)
			KEY_SPACE: apply_preview()
			KEY_R: reset()
			_: return
		refresh()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	var values := recipe(preview, mode)
	reading.text = "PREVIEW %.2f / %s\nk %.3f   noise %.3f   cut %.3f\nBUILT %.2f / %s\n1: MODE   UP/DOWN: PREVIEW   SPACE: BUILD   R: RESET" % [preview, MODES[mode], values.frequency, values.noise_amp, values.threshold, committed, MODES[built_mode]]

func caption(words: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = 32
	label.pixel_size = 0.002
	add_child(label)

func plinth(x: float) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.1, 0.6, 2.1)
	surface.mesh = mesh
	surface.position = Vector3(x, 0.3, 0)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("33343d")
	surface.material_override = finish
	add_child(surface)
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	boundary.shape = shape
	surface.add_child(body)
	body.add_child(boundary)
```

## Try the comparison

Press **1** to select ALL, FREQUENCY, NOISE or CUT. Pick up the black point. Raising it from 0.8 to 1.6 metres in the lesson's local frame previews a value from 0 to 1; beyond those heights the value is clamped. Press its trigger to rebuild B. Previewing alone leaves both meshes intact. Releasing keeps the last preview and built geometry. The readout distinguishes them.

On desktop, **Up/Down** adjust the preview, **Space** builds and **R** resets. These clock-free comparisons also work with keyboard controls while you inspect the museum. Mode selection is keyboard-driven in this compact student host; the installed large artifact has its separate VR desk.

Build B at value 1 in each mode. Check the numbers against the table and return to the same beginning when comparing appearances. A stays unchanged throughout. Two surfaces that look different need not have different connectivity. More triangles need not provide more room to pass. These small models have collision surfaces, but are not a test that a player can walk through the large exhibit.

### point_body.gd — carried unchanged

Copy this file from Reaction–diffusion. We reuse its shape, collision and pickup behaviour; the trigger now commits a recipe instead of planting a patch.

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

## Make an independent change

Change only `CUT_SPAN` from **0.15 to 0.30** and restart. Predict ALL at value 1: frequency and noise remain **1.60** and **0.20**; the cut becomes **0.30**. The opening cut also becomes **−0.12**, because the same recipe builds A at 0.3. In CUT mode, B's frequency and noise remain **1.11** and **0.095**. Check these consequences before judging the surface.

For one point in space, changing just the threshold by 0.15 changes the generator's normalized density by −0.025 wherever its clamp does not activate: its conversion is `(field - threshold) / 6 + 0.5`. That is a testable consequence of the supplied mapping. It does not predict every opening or a universal change in topology.

The museum's S control bundles parameters. LEVEL changes its threshold centre; NOISE toggles its noise contribution; RESOLUTION changes sampling; RESET restores the opening settings. These are authored choices. The source name “entropy” does not turn the control into a measured entropy value.

This closes Soft Bodies with a reusable distinction: **the rule that changes a state, the rule that selects a surface, and the control that binds those decisions are separate things you can inspect and alter.** A body can be driven, constrained, sampled or reconstructed. Being able to name the operation lets you decide what to carry forward.

<!-- @ -->

