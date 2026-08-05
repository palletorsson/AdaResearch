extends Node3D
class_name TranslationCubeDemo

# @identity
# essence: constrained_translation — move only on allowed axis; sequential constraints: first UP, then SIDEWAYS
# desire: learner physically discovers that translation is axis-specific — the door will not open any other way
# critical_parameter: the axis sequence constraint — UP must complete before SIDEWAYS unlocks
# triggers: grabbing the knob and moving; axis deviation is corrected by projecting motion onto the allowed axis
# emerges: the idea that translation has direction — not all displacement is allowed, only along defined axes
# needs: [has two grabbable door knobs [has], visual axis indicator showing current allowed direction [has, `guide`]]
# relationships: precursor to axis_translation_cube; demonstrates constrained translation before the animated version
# truth: a translation requires both a direction and a magnitude — constraint is what makes it meaningful

## Translation Demo - Two sliding doors with doorknob handles
## Each door: grab knob, slide along leg 1, then along leg 2 to open

@export var cube_size: float = 1.5  # Container size
@export var door_width: float = 0.5   # Door panel width
@export var door_height: float = 1.0  # Door panel height
@export var door_depth: float = 0.04  # Door thickness
@export var target_y: float = 0.25    # Slide up this far
@export var knob_height: float = 0.5  # Doorknob height on door

## AXIS — COURSE. Which displacements the door concedes, and in what order.
##
## The word is the family's: axis_translation_cube (x_/y_/z_translation_cube) already carries
## `course` for the same question — which way the translation runs — and this demo sits beside
## those three in the same sequence and the same registry file. THE VALUE LIST IS NOT THEIRS,
## and that is a fact about this object rather than a liberty. Their course is ONE axis
## (lateral | lift | depth) because their cube travels once. This door's whole argument, and
## its own declared critical_parameter, is that permission comes in an ORDER: the family's
## three words survive here as the legs, and the value names them in the sequence they unlock.
##
##   lift_lateral  THE DEFAULT and the shipped puzzle: up, then apart. Two freedoms, gated.
##   lateral_lift  the same two freedoms, dealt the other way round. Nothing about the door
##                 or the destination changes — only which permission comes first, which is
##                 the cleanest available demonstration that order is part of the rule.
##   lift_depth    up, then INTO the frame. The second leg runs along the axis a display case
##                 hides best, so the same displacement is read almost entirely as scale —
##                 z_translation_cube's lesson, asked of a door.
##   lateral       one permission and no gate at all. Just a sliding door. The degenerate
##                 case that shows how much of this object is the SEQUENCE and not the slide.
##   free          both freedoms conceded at once: one diagonal permission to the same corner.
##                 The negative case — with nothing forbidden there is nothing to feel.
@export_enum("lift_lateral", "lateral_lift", "lift_depth", "lateral", "free") var course: String = "lift_lateral"

## Allow-list for `course`. A word outside it is a typo in a map token and keeps the value
## already held, which on a fresh instance is the shipped puzzle.
const COURSES: PackedStringArray = ["lift_lateral", "lateral_lift", "lift_depth", "lateral", "free"]

## AXIS — GUIDE. How the permission is put into the room.
##
## The constraint itself is enforced in _physics_process, which a still frame cannot
## photograph, so this axis is what the object LEAVES STANDING to say what it will allow.
## The artifact's own @identity listed "missing visual axis indicator showing current allowed
## direction" under `needs`; the axis was named in the file before it was reachable.
##
##   arrows  THE DEFAULT, byte for byte: two thin emissive path lines per door with cone
##           heads and the "1.Up" / "2.Slide" captions. The rule as INSTRUCTION — the object
##           tells you, in words and order, before you touch it.
##   none    nothing. The rule as pure resistance: you find out what a translation is by
##           pushing and being refused, which is what the desire line actually asks for.
##   slot    the permitted path routed through a backing plate as a bright channel. The rule
##           as HARDWARE — not advice about where to go, a hole that goes nowhere else.
##   rail    a guide rod along each leg with hard end stops. The same permission as
##           machinery rather than as a cut: it says how far as well as which way.
##   ghost   no path at all, only a translucent copy of each door where it ends up. The rule
##           stated by its OUTCOME — the textbook figure's claim that only endpoints matter.
@export_enum("arrows", "none", "slot", "rail", "ghost") var guide: String = "arrows"

## Allow-list for `guide`. Same rule as COURSES.
const GUIDES: PackedStringArray = ["arrows", "none", "slot", "rail", "ghost"]

## The gap between the two door panels. Was a local in three functions that had to agree.
const DOOR_GAP: float = 0.02

var _left_door: Node3D
var _right_door: Node3D
var _container: Node3D
var _guide_root: Node3D
var _indicator_nodes: Array[Node] = []
var _both_reached: bool = false
var _built: bool = false

const ConstrainedDoor = preload("res://commons/primitives/translation/constrained_door.gd")

func _ready() -> void:
	_read_dna()
	_setup_container()
	_create_doors()
	# `arrows` routes straight back into _create_path_indicators() and parents its nodes to
	# self exactly as before, so the legacy tree has no Guide node in it at all.
	_build_guide()
	_built = true


## Read the two axes off the metadata the grid writes on the artifact ROOT before add_child,
## so this runs before anything is built. An unknown word keeps the default rather than
## silently rendering as one.
func _read_dna() -> void:
	if has_meta("config_course"):
		var c: String = str(get_meta("config_course")).strip_edges().to_lower()
		if COURSES.has(c):
			course = c
	if has_meta("config_guide"):
		var g: String = str(get_meta("config_guide")).strip_edges().to_lower()
		if GUIDES.has(g):
			guide = g


## GUARDED, both ways. Returns on an empty dict, assigns only when the incoming word is in
## the allow-list AND differs from the one already held, and rebuilds only when something
## actually moved and only after _ready has built once. None of the 5 existing placements
## passes a config at all, so none of them reaches the teardown.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	var changed: bool = false

	if config_data.has("course"):
		var c: String = str(config_data["course"]).strip_edges().to_lower()
		if COURSES.has(c) and c != course:
			course = c
			changed = true

	if config_data.has("guide"):
		var g: String = str(config_data["guide"]).strip_edges().to_lower()
		if GUIDES.has(g) and g != guide:
			guide = g
			changed = true

	if not changed or not _built:
		return
	_rebuild()


## Tear down only what the two axes own — the doors, the indicators, the guide hardware.
## The wireframe container is untouched: neither axis says anything about it.
func _rebuild() -> void:
	for n in _indicator_nodes:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_indicator_nodes.clear()
	for d in [_left_door, _right_door, _guide_root]:
		if is_instance_valid(d):
			remove_child(d)
			d.queue_free()
	_left_door = null
	_right_door = null
	_guide_root = null
	_both_reached = false
	_create_doors()
	_build_guide()

func _setup_container() -> void:
	_container = Node3D.new()
	_container.name = "Container"
	add_child(_container)

	# Draw wireframe edges
	var edges = [
		[Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5)],
		[Vector3(0.5, 0, -0.5), Vector3(0.5, 0, 0.5)],
		[Vector3(0.5, 0, 0.5), Vector3(-0.5, 0, 0.5)],
		[Vector3(-0.5, 0, 0.5), Vector3(-0.5, 0, -0.5)],
		[Vector3(-0.5, 1, -0.5), Vector3(0.5, 1, -0.5)],
		[Vector3(0.5, 1, -0.5), Vector3(0.5, 1, 0.5)],
		[Vector3(0.5, 1, 0.5), Vector3(-0.5, 1, 0.5)],
		[Vector3(-0.5, 1, 0.5), Vector3(-0.5, 1, -0.5)],
		[Vector3(-0.5, 0, -0.5), Vector3(-0.5, 1, -0.5)],
		[Vector3(0.5, 0, -0.5), Vector3(0.5, 1, -0.5)],
		[Vector3(0.5, 0, 0.5), Vector3(0.5, 1, 0.5)],
		[Vector3(-0.5, 0, 0.5), Vector3(-0.5, 1, 0.5)],
	]

	for edge in edges:
		_create_edge_line(edge[0] * cube_size, edge[1] * cube_size)

func _create_edge_line(from: Vector3, to: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	mesh_instance.mesh = immediate_mesh

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	_container.add_child(mesh_instance)


# ── the course, as a plan ─────────────────────────────────────────────
# ONE description of the permitted path, read by the door constraint, by the arrows, by the
# slot, by the rail and by the ghost. The alternative — five copies of the same ordering —
# is how an artifact ends up drawing one rule and enforcing another.

## The ordered legs for the door on side `side_x` (-1 left, +1 right). `span_side` is how far
## the sideways/depth leg runs; the door and the arrows disagree about that by the door gap,
## and always did, so it is a parameter rather than a constant.
func _leg_plan(side_x: float, span_side: float) -> Array:
	var lift: Vector3 = Vector3(0.0, 1.0, 0.0)
	var side: Vector3 = Vector3(side_x, 0.0, 0.0)
	var into: Vector3 = Vector3(0.0, 0.0, 1.0)
	match course:
		"lateral_lift":
			return [{"dir": side, "span": span_side, "word": "1.Slide"},
					{"dir": lift, "span": target_y, "word": "2.Up"}]
		"lift_depth":
			return [{"dir": lift, "span": target_y, "word": "1.Up"},
					{"dir": into, "span": span_side, "word": "2.Push"}]
		"lateral":
			return [{"dir": side, "span": span_side, "word": "Slide"}]
		"free":
			var diagonal: Vector3 = lift * target_y + side * span_side
			return [{"dir": diagonal.normalized(), "span": diagonal.length(), "word": "Any"}]
		_:
			# "lift_lateral" — the shipped plan. Leg 1 is +Y for target_y, leg 2 is outward
			# for span_side, which is what _create_doors and _create_path_indicators each
			# wrote by hand before.
			return [{"dir": lift, "span": target_y, "word": "1.Up"},
					{"dir": side, "span": span_side, "word": "2.Slide"}]


## Corner points of the path, starting at `origin` and walking the plan.
func _path_points(side_x: float, origin: Vector3, span_side: float) -> Array:
	var pts: Array = [origin]
	var p: Vector3 = origin
	for leg in _leg_plan(side_x, span_side):
		var d: Vector3 = leg["dir"]
		var s: float = leg["span"]
		p = p + d * s
		pts.append(p)
	return pts


func _door_offset() -> float:
	return door_width / 2.0 + DOOR_GAP


func _create_doors() -> void:
	var door_offset: float = _door_offset()

	# Left door: opens outward to the left
	_left_door = _create_constrained_door(
		"LeftDoor",
		Vector3(-door_offset, 0.0, 0.0),
		Color(0.8, 0.3, 0.3),  # Red
		-1.0,
		false  # knob on right side
	)
	add_child(_left_door)

	# Right door: opens outward to the right
	_right_door = _create_constrained_door(
		"RightDoor",
		Vector3(door_offset, 0.0, 0.0),
		Color(0.3, 0.3, 0.8),  # Blue
		1.0,
		true  # knob on left side (mirrored)
	)
	add_child(_right_door)

func _create_constrained_door(
	door_name: String,
	start_pos: Vector3,
	color: Color,
	side_x: float,
	knob_mirrored: bool = false
) -> Node3D:
	var door = Node3D.new()
	door.set_script(ConstrainedDoor)
	door.name = door_name
	door.position = start_pos

	# Set door properties
	door.door_width = door_width
	door.door_height = door_height
	door.door_depth = door_depth
	door.door_color = color
	door.knob_height = knob_height
	door.mirror_knob = knob_mirrored

	# The plan drives the constraint. The sign of the sideways run lives in the DIRECTION
	# here, where the shipped code put it in the signed span; the projection is the same
	# either way, so the default door clamps to the identical band it always clamped to.
	var plan: Array = _leg_plan(side_x, door_width + DOOR_GAP)
	var leg0: Dictionary = plan[0]
	door.phase1_dir = leg0["dir"]
	door.target_y = leg0["span"]
	if plan.size() > 1:
		var leg1: Dictionary = plan[1]
		door.phase2_dir = leg1["dir"]
		door.target_x = leg1["span"]
		door.phase_count = 2
	else:
		door.phase2_dir = Vector3(side_x, 0.0, 0.0)
		door.target_x = 0.0
		door.phase_count = 1

	if course == "free":
		# The plan draws `free` as one diagonal, because that is the honest picture of it.
		# The CONSTRAINT is not a diagonal rail — it is the absence of one, so the door gets
		# the two real freedoms back and no gate between them.
		door.phase1_dir = Vector3(0.0, 1.0, 0.0)
		door.target_y = target_y
		door.phase2_dir = Vector3(side_x, 0.0, 0.0)
		door.target_x = door_width + DOOR_GAP
		door.phase_count = 2
		door.unconstrained = true

	# Connect signal
	door.goal_reached.connect(_on_door_goal_reached.bind(door_name))

	return door

func _on_door_goal_reached(door_name: String) -> void:
	print("Translation Demo: %s opened!" % door_name)
	_check_both_complete()

func _check_both_complete() -> void:
	if _both_reached:
		return

	var left_done = _left_door.has_method("is_goal_reached") and _left_door.is_goal_reached()
	var right_done = _right_door.has_method("is_goal_reached") and _right_door.is_goal_reached()

	if left_done and right_done:
		_both_reached = true
		print("Translation Demo: Both doors open! Puzzle complete!")


# ── the guide ─────────────────────────────────────────────────────────

func _build_guide() -> void:
	if guide == "arrows":
		_create_path_indicators()
		return
	if guide == "none":
		return
	_guide_root = Node3D.new()
	_guide_root.name = "Guide"
	add_child(_guide_root)
	match guide:
		"slot":
			_guide_slot()
		"rail":
			_guide_rail()
		"ghost":
			_guide_ghost()
		_:
			pass


## The two door sides, as (sign, tint). Plain Array; every element is copied into an
## explicitly typed local before use.
func _sides() -> Array:
	return [[-1.0, Color(0.8, 0.3, 0.3)], [1.0, Color(0.3, 0.3, 0.8)]]

func _create_path_indicators() -> void:
	var door_offset: float = _door_offset()
	var arrow_z: float = door_depth + 0.08

	for pair in _sides():
		var side_x: float = pair[0]
		var tint: Color = pair[1]
		var pts: Array = _path_points(side_x, Vector3(side_x * door_offset, knob_height, arrow_z), door_width)
		var plan: Array = _leg_plan(side_x, door_width)

		for i in range(plan.size()):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			_create_path_arrow(a, b, Color(tint.r, tint.g, tint.b, 0.7))

		for i in range(plan.size()):
			var a2: Vector3 = pts[i]
			var b2: Vector3 = pts[i + 1]
			var d: Vector3 = b2 - a2
			# Captions sit beside a vertical leg and above a horizontal one — which is
			# where the four hand-written literals put them.
			var nudge: Vector3 = Vector3(0.0, 0.1, 0.0)
			if absf(d.y) > absf(d.x) and absf(d.y) > absf(d.z):
				nudge = Vector3(-side_x * 0.15, 0.0, 0.0)
			var leg: Dictionary = plan[i]
			_create_label(str(leg["word"]), (a2 + b2) * 0.5 + nudge, tint)

func _create_path_arrow(from: Vector3, to: Vector3, color: Color) -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	mesh_instance.mesh = immediate_mesh

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	mesh_instance.material_override = material
	add_child(mesh_instance)
	_indicator_nodes.append(mesh_instance)

	var arrow_dir = (to - from).normalized()
	_create_arrowhead(to, arrow_dir, color)

func _create_arrowhead(pos: Vector3, direction: Vector3, color: Color) -> void:
	var cone = MeshInstance3D.new()
	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.015
	cone_mesh.height = 0.04
	cone.mesh = cone_mesh

	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right = direction.cross(up).normalized()
	up = right.cross(direction).normalized()
	cone.transform = Transform3D(Basis(right, up, -direction), pos)

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	cone.material_override = material
	add_child(cone)
	_indicator_nodes.append(cone)

func _create_label(text: String, pos: Vector3, color: Color) -> void:
	var label = Label3D.new()
	label.text = text
	label.font_size = 20
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	label.modulate = color
	add_child(label)
	_indicator_nodes.append(label)


# ── guide hardware ────────────────────────────────────────────────────
# Appearance only. Nothing below reads or writes a collision layer, a mask, a shape, the
# grab path or the knob — the puzzle is played exactly the same under every value.

func _guide_mat(tint: Color, glow: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = 0.4
	mat.roughness = 0.5
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = tint
		mat.emission_energy_multiplier = glow
	return mat


func _guide_box(size: Vector3, at: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = box
	mi.position = at
	mi.material_override = mat
	_guide_root.add_child(mi)
	return mi


## A basis whose +Y runs along `dir` — cylinders and capsules stand on Y.
func _aligned_basis(dir: Vector3) -> Basis:
	var up: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(up.dot(ref)) > 0.99:
		ref = Vector3.FORWARD
	var right: Vector3 = ref.cross(up).normalized()
	var fwd: Vector3 = up.cross(right).normalized()
	return Basis(right, up, fwd)


## SLOT — the permitted path routed out of a plate. A dark backing panel behind each door's
## legs with a bright channel following them, so the rule is a hole rather than a caption.
func _guide_slot() -> void:
	var door_offset: float = _door_offset()
	var plate_z: float = door_depth + 0.055
	var chan_w: float = 0.05

	for pair in _sides():
		var side_x: float = pair[0]
		var tint: Color = pair[1]
		var origin: Vector3 = Vector3(side_x * door_offset, knob_height, door_depth + 0.075)
		var pts: Array = _path_points(side_x, origin, door_width)

		var lo: Vector3 = pts[0]
		var hi: Vector3 = pts[0]
		for p in pts:
			var q: Vector3 = p
			lo = Vector3(minf(lo.x, q.x), minf(lo.y, q.y), minf(lo.z, q.z))
			hi = Vector3(maxf(hi.x, q.x), maxf(hi.y, q.y), maxf(hi.z, q.z))
		var pad: float = chan_w * 0.9
		var plate_size: Vector3 = Vector3(
			maxf(hi.x - lo.x, 0.0) + pad * 2.0,
			maxf(hi.y - lo.y, 0.0) + pad * 2.0,
			0.014)
		var plate_at: Vector3 = Vector3((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, plate_z)
		_guide_box(plate_size, plate_at, _guide_mat(Color(0.10, 0.11, 0.13), 0.0))

		var channel: StandardMaterial3D = _guide_mat(Color(tint.r, tint.g, tint.b), 1.6)
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			_guide_leg_box(a, b, chan_w, channel)


## One box lying along a leg, at the leg's own thickness. Legs are axis-aligned in every
## course but `free`, whose single leg lies in the XY plane, so a rotation about Z covers
## all of them and the depth leg is handled on its own.
func _guide_leg_box(a: Vector3, b: Vector3, w: float, mat: StandardMaterial3D) -> void:
	var d: Vector3 = b - a
	var mid: Vector3 = (a + b) * 0.5
	if absf(d.z) > absf(d.x) and absf(d.z) > absf(d.y):
		_guide_box(Vector3(w, w, d.length() + w), mid, mat)
		return
	var seg: MeshInstance3D = _guide_box(Vector3(d.length() + w, w, w), mid, mat)
	seg.rotation_degrees = Vector3(0.0, 0.0, rad_to_deg(atan2(d.y, d.x)))


## RAIL — the same permission as machinery. A rod down each leg with a hard stop at either
## end: it says how FAR as well as which way, which a painted arrow never does.
func _guide_rail() -> void:
	var door_offset: float = _door_offset()
	var steel: StandardMaterial3D = _guide_mat(Color(0.62, 0.64, 0.68), 0.0)

	for pair in _sides():
		var side_x: float = pair[0]
		var tint: Color = pair[1]
		var stop_mat: StandardMaterial3D = _guide_mat(Color(tint.r, tint.g, tint.b), 1.2)
		var origin: Vector3 = Vector3(side_x * door_offset, knob_height, door_depth + 0.08)
		var pts: Array = _path_points(side_x, origin, door_width)

		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var d: Vector3 = b - a
			var rod: CylinderMesh = CylinderMesh.new()
			rod.top_radius = 0.009
			rod.bottom_radius = 0.009
			rod.height = d.length()
			rod.radial_segments = 12
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = rod
			mi.material_override = steel
			mi.transform = Transform3D(_aligned_basis(d), (a + b) * 0.5)
			_guide_root.add_child(mi)

			_guide_stop(a, d, stop_mat)
			_guide_stop(b, d, stop_mat)


func _guide_stop(at: Vector3, dir: Vector3, mat: StandardMaterial3D) -> void:
	var stop: CylinderMesh = CylinderMesh.new()
	stop.top_radius = 0.026
	stop.bottom_radius = 0.026
	stop.height = 0.012
	stop.radial_segments = 12
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = stop
	mi.material_override = mat
	mi.transform = Transform3D(_aligned_basis(dir), at)
	_guide_root.add_child(mi)


## GHOST — the rule by its outcome. No path, no captions: each door is drawn a second time,
## translucent, where the permitted run would leave it. The claim that only endpoints matter.
func _guide_ghost() -> void:
	var door_offset: float = _door_offset()

	for pair in _sides():
		var side_x: float = pair[0]
		var tint: Color = pair[1]
		var origin: Vector3 = Vector3(side_x * door_offset, door_height / 2.0, 0.0)
		# The DOOR's spans, not the arrows' — the panel travels one door gap further.
		var pts: Array = _path_points(side_x, origin, door_width + DOOR_GAP)
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.28)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = tint
		mat.emission_energy_multiplier = 0.5
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_guide_box(Vector3(door_width, door_height, door_depth), pts[pts.size() - 1], mat)


func print_help() -> void:
	print("=== Translation Demo ===")
	print("Grab the doorknob (small cube)")
	print("Phase 1: Slide UP")
	print("Phase 2: Slide SIDEWAYS to open")
