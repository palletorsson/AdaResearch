# Sculpted Forms — what the centres keep

## Learning elements

- Capture positions in the construction's local frame
- Map centres to occupied voxel addresses
- Emit faces only where occupied cells meet empty space
- Compare a retained sample with its source objects

Caves and Mazes cleared cells around a list of centres. This hall marks cells around centres and builds their outer surface. The point still lets us commit a step. A surface now records a choice about the bodies we showed it.

## Choose a moment in the existing pile

Press DROP at the museum desk. Twelve cubes fall. SAMPLE freezes them and constructs a surface from their centres. ORIGINAL switches between those frozen cubes and their sample. Their rotations remain visible in the originals, but are absent from the sample's inputs.

We will reconstruct that sampling operation with three fixed cubes. They are declared test objects, already posed, so the same comparison can be repeated. They do not fall and are not a replacement for the installed pile. The supplied museum physics remains available beside the lesson.

## From positions to cells

Save these four complete files together in your prepared Endless Museum project. Attach `sculpture.gd` to an empty Node3D at unit scale in a clear bay. Our test placement is hall-local (8.5, 0, 21), yaw 180 degrees. The museum supplies the player, camera, floor and XRTools.

`sample.gd` keeps three records: the captured centres, the grid origin, and the occupied cells. A dictionary entry means that an address is occupied. Two source objects can mark the same address; it remains one occupied cell.

`capture()` converts each body's global position through the construction frame's `to_local()`. The output mesh will live beneath that same frame. Keeping a global position as though it were local would apply the frame's translation, rotation and scale again when rendering it.

The grid begins one body edge below the smallest captured coordinate on each axis. Divide the distance from that origin by cell size, then use `floor()` to obtain an integer address. The minimum centre anchors the grid: moving that minimum can shift addresses for other bodies too. This origin is not a clipping boundary. Like the installed code, the sparse dictionary accepts every marked address.

### Follow one centre to one face

Use one fixed cube at local (0, 1, 0), with spacing 0.5, as a small example of the same pipeline. Read these stages before assembling the full three-cube surface:

| Stage | Value or decision |
|---|---|
| Capture | `to_local()` gives the centre (0, 1, 0) in the construction frame |
| Anchor | Subtract one body edge: the grid origin is (−1, 0, −1) |
| Address | `floor((centre − origin) / 0.5)` gives (2, 2, 2) |
| Occupy | Extent 2 marks addresses 0 through 4 on every axis |
| Expose | At cell (4, 2, 2), neighbour (5, 2, 2) is absent, so its +x face is emitted |
| Assemble | That face lies at local x = 1.25; four corners become two triangles |

The central cell's six neighbours are present, so it contributes no surface face. A single marked neighbourhood contains 125 cells but exposes only its boundary. The three-cube program follows the same stages, with overlapping addresses stored once. These exact local values explain the rule; the later transform discussion explains why captured floating-point values near an address boundary can produce different counts.

<!-- student-code:sample.gd -->
```gdscript
extends RefCounted
const BODY_EDGE := 1.0
const EXTENT_FACTOR := 1.0
const DIRECTIONS := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
	Vector3i.DOWN, Vector3i(0,0,1), Vector3i(0,0,-1)]
var centres: Array[Vector3] = []
var cells: Dictionary = {}
var origin := Vector3.ZERO
var cell_size := 0.5

func capture(frame: Node3D, bodies: Array) -> void:
	var positions: Array[Vector3] = []
	for body in bodies: positions.append(frame.to_local(body.global_position))
	sample(positions, cell_size)

func sample(positions: Array, spacing: float) -> void:
	assert(spacing > 0.0)
	cell_size = spacing
	centres = []
	for p in positions: centres.append(p)
	cells.clear()
	origin = Vector3.ZERO
	if centres.is_empty(): return
	origin = centres[0]
	for p in centres: origin = origin.min(p)
	origin -= Vector3.ONE * BODY_EDGE
	var extent := ceili(BODY_EDGE * EXTENT_FACTOR / cell_size)
	for p in centres:
		var address := Vector3i(((p - origin) / cell_size).floor())
		for x in range(-extent, extent + 1):
			for y in range(-extent, extent + 1):
				for z in range(-extent, extent + 1):
					cells[address + Vector3i(x,y,z)] = true

func faces() -> Array:
	var result: Array = []
	for cell: Vector3i in cells:
		for direction: Vector3i in DIRECTIONS:
			if not cells.has(cell + direction):
				result.append([cell, direction])
	return result
```

The marking rule deliberately follows the existing artifact. A one-unit body at cell size 0.5 gives an extent of 2 cells **each way**, including the central cell: five cells across. Its sampled box is therefore 2.5 units wide, not one. This operation expands an axis-aligned neighbourhood around a centre. It does not voxelize the exact rotated cube.

The renderer places cell centres at `origin + address * cell_size`. There is no extra half-cell shift. `floor()` chooses the address; it does not promise that the source centre lands at the middle of that cell. These conventions are part of the approximation.

`faces()` asks six questions per occupied cell: is the neighbouring address occupied? If so, the shared face is internal and omitted. If not, emit a face. This is the six-neighbour relation from Percolation doing another job. One isolated voxel has six exposed faces. Two face-adjacent voxels have ten, because their two shared sides disappear from the surface.

## Turn each exposed face into two triangles

Our face and mesh work returns from Primitives. `faces.gd` is the complete assembly helper. For each face, it chooses two axes lying on that face, builds four corners and submits triangles 0–1–2 and 0–2–3. Its vertex positions and winding match the six cases in the installed cube-mound assembler. Here we keep explicit flat face normals. The installed assembler regenerates normals, so its shading can differ. This helper builds only the boundary geometry; it does not add collision.

<!-- student-code:faces.gd -->
```gdscript
extends RefCounted

static func build(faces: Array, origin: Vector3, spacing: float) -> ArrayMesh:
	if faces.is_empty(): return ArrayMesh.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var normal := Vector3(face[1])
		var u: Vector3
		var v: Vector3
		if normal.x != 0:
			u = Vector3(0,0,normal.x)
			v = Vector3.UP
		elif normal.y != 0:
			u = Vector3.RIGHT
			v = Vector3(0,0,normal.y)
		else:
			u = Vector3.UP
			v = Vector3(normal.z,0,0)
		var centre := origin + Vector3(face[0]) * spacing + normal * spacing / 2
		var half := spacing / 2
		var corners := [centre + (-u-v)*half, centre + (u-v)*half,
			centre + (u+v)*half, centre + (-u+v)*half]
		surface.set_normal(normal)
		for i in [0,1,2,0,2,3]: surface.add_vertex(corners[i])
	return surface.commit()
```

## Compare what was captured

`sculpture.gd` constructs the three original cubes, their shared display frame, the sampled mesh, a caption and our point. The display frame scales everything to 0.3. A one-unit cube appears 0.3 metres wide; the initial single-cube sample would appear 0.75 metres wide. Calculations still use the frame's local units.

The program captures an opening sample, then shows the originals. Action on the held point captures again and reveals the surface. Moving the point alone does not change the sample. V switches the view; M moves only the third cube half a local unit along x; R restores the opening arrangement. SPACE is the study's keyboard sampling shortcut. Use the held point in the museum when other artifacts also listen for SPACE.

<!-- student-code:sculpture.gd -->
```gdscript
extends Node3D
const Sample = preload("sample.gd")
const Faces = preload("faces.gd")
const PointBody = preload("point_body.gd")
const START := [Vector3(-1.5,1,0), Vector3(0,1,0), Vector3(1.5,1,0)]
var model := Sample.new()
var frame := Node3D.new()
var bodies: Array = []
var skin := MeshInstance3D.new()
var point := PointBody.new()
var caption := Label3D.new()
var show_sample := false
var moved := false

func _ready() -> void:
	add_child(frame)
	frame.position = Vector3(0,0.8,0)
	frame.scale = Vector3.ONE * 0.3
	for i in START.size():
		var body := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * Sample.BODY_EDGE
		body.mesh = cube
		body.position = START[i]
		body.rotation = Vector3(0.15*i, 0.3*i, 0.2*i)
		frame.add_child(body)
		bodies.append(body)
	frame.add_child(skin)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b58b64")
	skin.material_override = material
	add_child(caption)
	caption.position = Vector3(0,2.45,0)
	caption.font_size = 26
	caption.pixel_size = 0.002
	add_child(point)
	point.action_pressed.connect(func(_p): act("SAMPLE"))
	act("SAMPLE")
	act("VIEW")

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.5))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("SAMPLE")
		KEY_V: act("VIEW")
		KEY_M: act("MOVE")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"SAMPLE":
			model.capture(frame, bodies)
			skin.mesh = Faces.build(model.faces(), model.origin, model.cell_size)
			show_sample = true
		"VIEW": show_sample = not show_sample
		"MOVE":
			moved = not moved
			bodies[2].position = START[2] + Vector3.RIGHT * (0.5 if moved else 0.0)
		"RESET":
			moved = false
			for i in bodies.size(): bodies[i].position = START[i]
			act("SAMPLE")
			show_sample = false
	skin.visible = show_sample
	for body in bodies: body.visible = not show_sample
	caption.text = "WHAT DO THE CENTRES KEEP?\n%d cells | %d exposed faces | spacing %.1f\nSPACE / held action: sample | V: view | M: move one cube | R: reset\n%s" % [model.cells.size(), model.faces().size(), model.cell_size,
		"SAMPLE: last captured centres" if show_sample else "ORIGINALS: current three cubes"]
```

M changes a source object without updating the sample. Switch views before sampling again: one view shows the current objects, the other shows the last captured centres. A retained sample is allowed to disagree with a changed source. The next SAMPLE replaces it deliberately.

The third cube moves from x = 1.5 to x = 2.0. The minimum centre stays at x = -1.5, so the grid origin stays fixed. At spacing 0.5, predict that the third cube's marked neighbourhood shifts one address along x. Some old cells remain because the other cubes also occupy them.

## Keep the familiar point

Copy this file unchanged from Caves and Mazes. It is printed in full so the construction can be reconstructed without an undeclared scene node. The host reuses physics parking on release and connects the point's action to SAMPLE.

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

## Change the approximation

Change only `EXTENT_FACTOR := 1.0` to `EXTENT_FACTOR := 0.5` in `sample.gd`. Restart with the same three cubes.

For one cube, predict an extent of 1 at spacing 0.5: three cells across, or 1.5 local units. The sample is smaller, but still not an exact rotated cube. For the exact local values in START, the original rule marks 275 cells with 270 exposed faces; the edited rule marks 81 cells with 126 exposed faces. The captured centres and grid origin stay identical. Every edited occupied address belongs to the larger baseline sample.

Each exposed face becomes two triangles, with six submitted vertices altogether. For that exact fixture there are 540 triangles in the baseline and 252 in the edit. Shared internal faces contribute none.

A captured coordinate has travelled through floating-point transforms. Near a cell boundary, a tiny round-trip difference can change `floor()` and therefore the count. In the translated and rotated test host, the actual capture gives 250 cells and 250 faces; its edit gives 72 and 114. Those numbers describe those captured inputs, not a different sampling rule. Preserve the actual centres when comparing the two extents. The exact START fixture and the live capture are both tested.

Now rotate one original cube without moving its centre and sample again. Predict no change to the occupied addresses. If you wanted the rotation to matter, which information would the sampling function need to receive? A smaller neighbourhood alone cannot supply that missing information.

## Return to the room

The installed VOXEL control resamples the frozen centres at another cell size. ORIGINAL changes visibility but leaves the generated collider active. The learner miniature has no collision at all. Neither view switch restores the earlier fall. DROP starts a new physical run and removes the old sampled collider.

The dome's CUT control shows a different construction: a blank, the subtractive cores, the cast and a section. The layered membrane is another comparison. These remain part of the museum without becoming two extra implementations in this lesson.

Carry the separate records onward: source objects, captured local centres, occupied addresses and a surface assembled from their boundary. Mirrored Patterns will ask what remains the same when we reuse an input while changing the operation applied to it.

## Keep, change, compare

Keep the captured local centres. Change the marked extent and compare occupied cells and exposed faces. Name the information that neither sample contains, including the cubes' rotations.

Source: `algorithms/proceduralgeneration/hybrid_complex/cubemound/cube_mound.gd`, particularly `generate_mesh_from_cubes`, `create_mesh_from_voxels` and `add_voxel_face`. Museum controls: `commons/artifacts/timing_machines/pg_workshop.gd`.
