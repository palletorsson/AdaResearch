extends Node3D

# @identity
# essence: N parallel SoftBody3D strips pinned to a frame top bar — each strap is a foil-shader cloth that hangs under gravity and collides with player hands
# desire: to create a curtain you walk through with your body — each strap drapes, parts, and swings back, making soft body physics tactile and intimate
# critical_parameter: strap_count — more straps create a denser curtain with more inter-strap collision, fewer straps let each one swing freely
# triggers: player collision (layer 20) displaces individual straps; throwing a rigid ball (ui_accept) demonstrates mass-vs-compliance interaction
# emerges: overlapping straps tangle and bunch when disturbed simultaneously, creating knot-like configurations never coded into the system
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: follows jelly_cube and softmill as cloth-specific soft body; precedes flagdancer which adds bone-driven wind simulation
# truth: a curtain is not a surface — it is an array of constraints negotiating gravity, and parting it reveals that softness is a collective property

# Cloth and support share their opening dimensions. Generate each soft body at
# rest size; duplicating a live, scaled SoftBody3D loses the intended fit in Jolt.
# Suspension changes the rig; hanging changes the attachment/hem of the strips.

@export var strap_count: int = 8
@export var strap_width: float = 0.3
@export var strap_height: float = 3.5
@export var strap_overlap: float = 0.05

## What holds the cloth up. All rigs use the same attachment height.
@export_enum("none", "gantry", "wall", "hoop", "mast") var suspension: String = "gantry"

## The allow-list a map token is checked against. An unknown word keeps the shipped
## rig rather than stranding a placement with a body nobody declared.
const SUSPENSIONS: PackedStringArray = ["none", "gantry", "wall", "hoop", "mast"]

## Original frame colour, retained outside the coloured walkway.
const RIG_COLOR := Color(0.5, 0.0, 0.1)

@export_enum("row", "corners", "single", "staggered", "arch") var hanging := "row"
@export_enum("foil", "coral", "rose", "violet", "blue", "mint") var palette := "foil"
@export var walkway := false
const HANGINGS := ["row", "corners", "single", "staggered", "arch"]
const PALETTES := {"coral": 0.035, "rose": 0.94, "violet": 0.76, "blue": 0.57, "mint": 0.40}
const HEM_CLEARANCE := 0.08
var _rig: StaticBody3D = null
var _built: bool = false


func _ready() -> void:
	if get_parent() == get_tree().root or self == get_tree().current_scene:
		setup_scene()
	setup_frame()
	setup_straps()
	_built = true

func setup_scene() -> void:
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2, 6)
	cam.basis = Basis.looking_at(Vector3(0, 1.5, 0) - cam.position, Vector3.UP)
	add_child(cam)

	# Light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.basis = Basis.looking_at(Vector3.ZERO - light.position, Vector3.UP)
	light.shadow_enabled = true
	add_child(light)

func curtain_span() -> float:
	return (strap_count - 1) * (strap_width - strap_overlap) + strap_width

func attachment_height() -> float:
	return strap_height + HEM_CLEARANCE

func strip_length(index: int) -> float:
	if hanging == "staggered":
		return strap_height * (1.0 if index % 2 == 0 else 0.62)
	if hanging == "arch":
		var edge := absf((index - (strap_count - 1) * 0.5) / ((strap_count - 1) * 0.5))
		return lerpf(strap_height * 0.30, strap_height, edge)
	return strap_height

## The two inner faces leave 2 cm beside the strip envelope. The top pins meet
## the underside of the crossbar; the full-length hem clears the floor by 8 cm.
func setup_frame() -> void:
	if is_instance_valid(_rig):
		# Detach BEFORE freeing: queue_free() defers to the end of the frame, so a
		# replacement added first would collide with the old node's name and be
		# silently renamed to @Frame@2.
		var old_parent: Node = _rig.get_parent()
		if old_parent != null:
			old_parent.remove_child(_rig)
		_rig.queue_free()
	_rig = null
	if suspension == "none":
		return

	var frame_width: float = curtain_span() + 0.04
	var frame_height: float = attachment_height() + 0.1
	var frame_thickness: float = 0.5

	var frame := StaticBody3D.new()
	# Frame bottom should be at y=0. Frame height is frame_height.
	# Center of frame is at frame_height/2.0.
	frame.position = Vector3(0, frame_height/2.0, 0)
	frame.name = "Frame"

	# Deep Red Material for Frame
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color("29232e") if walkway else RIG_COLOR
	frame_mat.roughness = 0.6

	match suspension:
		"wall":
			_rig_wall(frame, frame_mat, frame_width, frame_height, frame_thickness)
		"hoop":
			_rig_hoop(frame, frame_mat, frame_width, frame_height, frame_thickness)
		"mast":
			_rig_mast(frame, frame_mat, frame_width, frame_height, frame_thickness)
		_:
			# Default: an open-bottom doorway.
			_rig_gantry(frame, frame_mat, frame_width, frame_height, frame_thickness)

	add_child(frame)
	_rig = frame
	if walkway:
		var title := Label3D.new()
		title.text = {"row":"TOP EDGE", "corners":"TWO CORNERS", "single":"ONE CORNER", "staggered":"LONG / SHORT", "arch":"AN OPENING"}[hanging]
		title.position = Vector3(0, frame_height * 0.5, -0.251)
		title.rotation.y = PI
		title.font_size = 32
		title.pixel_size = 0.004
		title.modulate = Color("fff6eb")
		title.outline_size = 0
		title.double_sided = false
		frame.add_child(title)
		var reverse := title.duplicate() as Label3D
		reverse.rotation.y = 0.0
		reverse.position.z = 0.251
		frame.add_child(reverse)
		# Flat colour runners mark the procession without adding a physical step.
		var runner := StandardMaterial3D.new()
		runner.albedo_color = Color.from_hsv(PALETTES.get(palette, 0.94), 0.48, 0.78)
		runner.roughness = 1.0
		_bar(frame, Vector3(0, -frame_height * 0.5 + 0.004, 0), Vector3(frame_width, 0.006, 2.96), runner, false)

## GANTRY — a top beam and two colliding posts, with no floor threshold.
func _rig_gantry(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	# Top bar
	_bar(frame, Vector3(0, frame_height/2.0, 0),
		Vector3(frame_width + 0.4, 0.2, frame_thickness), mat, true)

	# Side bars
	for x: float in [-frame_width/2.0 - 0.1, frame_width/2.0 + 0.1]:
		_bar(frame, Vector3(x, 0, 0),
			Vector3(0.2, frame_height, frame_thickness), mat, true)

## WALL — held from behind. A ribbed plane the straps hang in FRONT of, with a head
## rail carrying them and a plinth where it meets the floor. The bottom is closed, so
## this is the one value you cannot walk through.
func _rig_wall(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	var w: float = frame_width + 0.9
	var back_z: float = -frame_thickness * 0.5 - 0.12

	# The plane itself, floor to head height.
	_bar(frame, Vector3(0, 0, back_z), Vector3(w, frame_height, 0.24), mat, true)
	# Ribs proud of the face, so the plane reads as built rather than as a backdrop.
	for i in range(5):
		var rx: float = (float(i) / 4.0 - 0.5) * w * 0.9
		_bar(frame, Vector3(rx, 0, back_z + 0.19),
			Vector3(0.16, frame_height - 0.5, 0.14), mat, false)
	# Head rail: what the straps actually hang off, cantilevered clear of the face.
	_bar(frame, Vector3(0, frame_height/2.0 + 0.02, back_z * 0.35),
		Vector3(w, 0.24, frame_thickness * 0.8), mat, true)
	# Plinth.
	_bar(frame, Vector3(0, -frame_height/2.0 + 0.11, back_z * 0.6),
		Vector3(w, 0.22, frame_thickness * 0.9), mat, true)

## HOOP — held from around. A ring overhead on four legs, with a spar across its
## diameter that the rank hangs from. The curtain stops being a boundary and becomes a
## partition standing inside a round room.
func _rig_hoop(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	var rad: float = frame_width * 0.5 + 0.35
	var ry: float = frame_height / 2.0          # local y of the ring == world frame_height

	# The ring, as 24 chords.
	var seg: int = 24
	for i in range(seg):
		var a0: float = TAU * float(i) / float(seg)
		var a1: float = TAU * float(i + 1) / float(seg)
		_rod(frame, Vector3(cos(a0) * rad, ry, sin(a0) * rad),
			Vector3(cos(a1) * rad, ry, sin(a1) * rad), 0.09, mat)

	# The diameter spar the straps hang from — the only part in the cloth's plane.
	_bar(frame, Vector3(0, ry, 0), Vector3(rad * 2.0, 0.2, frame_thickness * 0.4),
		mat, true)

	# Four legs on the diagonals, clear of the rank, with foot pads.
	for i in range(4):
		var a: float = TAU * float(i) / 4.0 + PI * 0.25
		var fx: float = cos(a) * rad
		var fz: float = sin(a) * rad
		_bar(frame, Vector3(fx, 0, fz), Vector3(0.18, frame_height, 0.18), mat, true)
		_bar(frame, Vector3(fx, -frame_height/2.0 + 0.06, fz),
			Vector3(0.55, 0.12, 0.55), mat, false)

## MAST — held from a single point. One column set behind the rank, a head beam
## cantilevered over it, two braces taking the moment. No side posts: the whole load
## path is legible in one look, and the cloth is carried rather than framed.
func _rig_mast(frame: StaticBody3D, mat: StandardMaterial3D, frame_width: float,
		frame_height: float, frame_thickness: float) -> void:
	var mz: float = -frame_thickness * 0.5 - 0.2
	var top_y: float = frame_height / 2.0

	# Column and base plate.
	_bar(frame, Vector3(0, 0.1, mz), Vector3(0.34, frame_height + 0.2, 0.34), mat, true)
	_bar(frame, Vector3(0, -frame_height/2.0 + 0.07, mz),
		Vector3(1.1, 0.14, 1.1), mat, false)
	# Head beam, over the rank.
	_bar(frame, Vector3(0, top_y, 0),
		Vector3(frame_width + 0.4, 0.2, frame_thickness), mat, true)
	# The short link from column head out to the beam, and the two braces.
	_bar(frame, Vector3(0, top_y + 0.16, mz * 0.5),
		Vector3(0.3, 0.16, absf(mz) + 0.34), mat, false)
	for sx: float in [-1.0, 1.0]:
		_rod(frame, Vector3(0, top_y - 0.95, mz),
			Vector3(sx * (frame_width * 0.5 - 0.1), top_y - 0.12, 0.0), 0.06, mat)

## A box with an optional collision twin, in the shipped order: mesh, then shape.
func _bar(frame: StaticBody3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D,
		solid: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	frame.add_child(mi)
	if not solid:
		return
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	col.position = pos
	frame.add_child(col)

## A rod from a to b. CylinderMesh runs along its own Y, so the basis is built with Y
## on the chord. Visual only — an overhead ring nobody can reach needs no collider.
func _rod(frame: StaticBody3D, a: Vector3, b: Vector3, thick: float,
		mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var length: float = d.length()
	if length < 0.0001:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = thick
	cyl.bottom_radius = thick
	cyl.height = length
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	frame.add_child(mi)
	mi.position = (a + b) * 0.5
	var up: Vector3 = d.normalized()
	var ref: Vector3 = Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD
	var xa: Vector3 = ref.cross(up).normalized()
	var za: Vector3 = xa.cross(up).normalized()
	mi.basis = Basis(xa, up, za)

func setup_straps() -> void:
	# A fresh mesh per body. No hidden live template, no non-unit body scale.
	for child in get_children():
		if child is SoftBody3D:
			remove_child(child)
			child.queue_free()
	var foil := ShaderMaterial.new()
	foil.shader = load("res://commons/resourses/shaders/foil_paper.gdshader")
	for i in strap_count:
		var length := strip_length(i)
		var surface := PlaneMesh.new()
		surface.orientation = PlaneMesh.FACE_Z
		surface.size = Vector2(strap_width, length)
		surface.subdivide_width = 4 if walkway else 6
		surface.subdivide_depth = 16 if walkway else 12
		var rest: PackedVector3Array = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
		var body := SoftBody3D.new()
		body.name = "LessonStrip" + str(i)
		body.mesh = surface
		body.position = Vector3((i - (strap_count - 1) * 0.5) * (strap_width - strap_overlap), attachment_height() - length * 0.5, 0)
		body.total_mass = 0.16 if walkway else 1.0
		body.linear_stiffness = 0.7 if walkway else 0.34
		body.damping_coefficient = 0.08 if walkway else 0.05
		body.simulation_precision = 5
		body.collision_layer = 1
		body.collision_mask = 1 | 4 | (1 << 17) | (1 << 18) | (1 << 19)
		if palette == "foil" and not has_meta("config_lesson"):
			body.material_override = foil
		else:
			var finish := StandardMaterial3D.new()
			var hue: float = PALETTES.get(palette, 0.84)
			finish.albedo_color = Color.from_hsv(hue + i * 0.008, 0.65 if i % 2 == 0 else 0.45, 0.92)
			finish.metallic = 0.12
			finish.roughness = 0.48
			finish.cull_mode = BaseMaterial3D.CULL_DISABLED
			body.material_override = finish
		body.set_meta("lesson_rest", rest)
		body.set_meta("curtain_rest_transform", body.transform)
		body.set_meta("curtain_length", length)
		var pins: Array[int] = []
		for index in rest.size():
			var p := rest[index]
			var top := absf(p.y - length * 0.5) < 0.001
			var corner := absf(absf(p.x) - strap_width * 0.5) < 0.001
			var keep := top
			if hanging == "corners": keep = top and corner
			if hanging == "single": keep = top and is_equal_approx(p.x, strap_width * (0.5 if i % 2 == 0 else -0.5))
			if keep:
				body.set_point_pinned(index, true)
				pins.append(index)
		body.set_meta("curtain_pins", pins)
		add_child(body)

func _input(event: InputEvent) -> void:
	if not walkway and event.is_action_pressed("ui_accept"):
		# Throw a ball to test interaction
		var ball = RigidBody3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.3
		mesh.height = 0.6
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		ball.add_child(mi)
		var col = CollisionShape3D.new()
		col.shape = SphereShape3D.new()
		(col.shape as SphereShape3D).radius = 0.3
		ball.add_child(col)

		ball.position = Vector3(0, 1.5, 4)
		ball.mass = 5.0
		add_child(ball)
		ball.apply_central_impulse(Vector3(0, 0, -20))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Map metadata arrives before _ready in the museum. Live changes only rebuild
## what changed; switching the support must preserve the moving cloth's state.
func apply_grid_config(config: Dictionary) -> void:
	var cloth_changed := false
	var frame_changed := false
	if config.has("suspension") and str(config.suspension) in SUSPENSIONS:
		frame_changed = suspension != str(config.suspension)
		suspension = str(config.suspension)
	for key in ["hanging", "palette"]:
		var allowed: Array = HANGINGS if key == "hanging" else ["foil", "coral", "rose", "violet", "blue", "mint"]
		if config.has(key) and str(config[key]) in allowed and get(key) != str(config[key]):
			set(key, str(config[key]))
			cloth_changed = true
	for key in ["strap_count", "strap_width", "strap_height", "strap_overlap"]:
		if not config.has(key): continue
		var value: float = float(config[key])
		match key:
			"strap_count": value = clampi(int(value), 2, 16)
			"strap_width": value = clampf(value, 0.1, 1.0)
			"strap_height": value = clampf(value, 0.4, 5.0)
			"strap_overlap": value = clampf(value, 0.0, strap_width * 0.4)
		if not is_equal_approx(float(get(key)), value):
			set(key, int(value) if key == "strap_count" else value)
			cloth_changed = true
	strap_overlap = minf(strap_overlap, strap_width * 0.4)
	if config.has("walkway"):
		var enabled := str(config.walkway).to_lower() in ["true", "1"]
		frame_changed = frame_changed or walkway != enabled
		walkway = enabled
	if not _built: return
	if cloth_changed or frame_changed: setup_frame()
	if cloth_changed: setup_straps()
