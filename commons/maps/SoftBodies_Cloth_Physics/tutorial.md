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
