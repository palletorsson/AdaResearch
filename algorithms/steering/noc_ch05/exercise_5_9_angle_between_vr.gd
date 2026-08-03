extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEC_A := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_VEC_B := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var angle_a: float = 0.0
@export var angle_b: float = PI / 3.0

# ── DNA (promoted 2026-08-03, stage 2) ───────────────────────────────────────
# opening — the CASE the exercise is found in, i.e. what b is to a. The word and
# its four values are borrowed verbatim from the sibling agreement_gauge, which
# asks the same question about the same pair of directions; a room can now set
# both benches to the same case and they will mean the same thing by it.
# a is never moved (angle_a stays 0); the axis turns theta alone.
#   agreeing   the shipped PI/3 — 60 degrees, acute, dot product positive.
#   strangers  90 degrees. The dot product is exactly zero; neither direction has
#              any component of the other. The arc is a quarter turn.
#   opposing   120 degrees, obtuse. The dot product is negative — the two arrows
#              disagree, and a steering force built from them would brake.
#   parallel   0 degrees. The two arrows superimpose and the arc collapses to a
#              point: the degenerate case where "the angle between" has no figure
#              to draw and the answer is still an answer.
@export_enum("agreeing", "strangers", "opposing", "parallel") var opening: String = "agreeing"

# figure — what the angle is DRAWN as. The shipped exercise asserted exactly one
# reading: a thin 20-segment arc of radius 0.12 swept the short way from a to b.
# That is the geometer's answer, and it is not the answer steering code gives.
#   arc     the historical build. Rotation: the angle is a swept turn.
#   wedge   the same sweep filled as a sector. The angle as AREA — a quantity
#           with extent, not a hairline you have to hunt for.
#   chord   a straight segment from tip to tip. This is the difference vector,
#           which is what a steering behaviour actually computes; the exercise
#           name says "angle between" but no steering routine ever takes an arc.
#           The readout gains the chord length so the two claims sit together.
#   none    two arrows and a number. The angle exists only as the digit.
@export_enum("arc", "wedge", "chord", "none") var figure: String = "arc"

const OPENING_VALUES := ["agreeing", "strangers", "opposing", "parallel"]
const FIGURE_VALUES := ["arc", "wedge", "chord", "none"]

# The shipped geometry, kept as named constants so the default path is provably
# the literals that were there before.
const ARC_RADIUS: float = 0.12
const FIGURE_COLOR := Color(1.0, 0.8, 0.95, 0.6)

var _sim_root: Node3D
var _vector_a: MeshInstance3D
var _vector_b: MeshInstance3D
var _arc_mesh: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D
# Base-typed: CONTROLLER_SCENE.instantiate() is statically a Node, and narrowing
# it on assignment is a compile error, not a cast.
var _angle_b_controller: Node = null
var _built: bool = false

func _ready() -> void:
	# opening only chooses the OPENING pose of b; "agreeing" hands back PI/3.0,
	# the shipped literal, so the three existing placements are untouched.
	angle_b = _opening_angle()
	_setup_environment()
	_spawn_scene()
	_built = true
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var angle_a_controller := CONTROLLER_SCENE.instantiate()
	angle_a_controller.parameter_name = "Angle A"
	angle_a_controller.min_value = 0.0
	angle_a_controller.max_value = TAU
	angle_a_controller.default_value = angle_a
	angle_a_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(angle_a_controller)
	angle_a_controller.value_changed.connect(func(v: float) -> void:
		angle_a = v
		_update_vectors()
	)
	angle_a_controller.set_value(angle_a)

	var angle_b_controller := CONTROLLER_SCENE.instantiate()
	_angle_b_controller = angle_b_controller
	angle_b_controller.parameter_name = "Angle B"
	angle_b_controller.min_value = 0.0
	angle_b_controller.max_value = TAU
	angle_b_controller.default_value = angle_b
	angle_b_controller.position = Vector3(0, -0.18, 0)
	angle_b_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(angle_b_controller)
	angle_b_controller.value_changed.connect(func(v: float) -> void:
		angle_b = v
		_update_vectors()
	)
	angle_b_controller.set_value(angle_b)

func _spawn_scene() -> void:
	_vector_a = _create_arrow(MAT_VEC_A)
	_sim_root.add_child(_vector_a)

	_vector_b = _create_arrow(MAT_VEC_B)
	_sim_root.add_child(_vector_b)

	_arc_mesh = MeshInstance3D.new()
	_sim_root.add_child(_arc_mesh)

	_update_vectors()

func _create_arrow(mat: Material) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = 0.01
	mesh.height = 0.25
	arrow.mesh = mesh
	arrow.material_override = mat
	return arrow

func _update_vectors() -> void:
	if not _vector_a or not _vector_b:
		return
		
	var vec_a := Vector3(cos(angle_a), sin(angle_a), 0) * 0.25
	var vec_b := Vector3(cos(angle_b), sin(angle_b), 0) * 0.25
	var center := Vector3(0, 0.5, 0)

	_vector_a.position = center + vec_a * 0.5
	_vector_a.rotation = Vector3(0, 0, angle_a - PI / 2)

	_vector_b.position = center + vec_b * 0.5
	_vector_b.rotation = Vector3(0, 0, angle_b - PI / 2)

	var between = abs(angle_b - angle_a)
	if between > PI:
		between = TAU - between

	# figure=arc is the shipped call, byte for byte. The other readings are only
	# reached when a map asks for them.
	match figure:
		"wedge":
			_update_wedge(center, ARC_RADIUS, angle_a, angle_b)
		"chord":
			_update_chord(center + vec_a, center + vec_b)
		"none":
			_arc_mesh.mesh = null
		_:
			_update_arc(center, ARC_RADIUS, angle_a, angle_b)

	_status_label.text = "Angle Between | %.1f°" % rad_to_deg(between)
	if figure == "chord":
		# The chord IS the difference vector — say its length next to the angle,
		# because that is the number steering code actually uses.
		_status_label.text += "\n|b - a| = %.3f" % (vec_b - vec_a).length()

func _update_arc(center: Vector3, radius: float, start_angle: float, end_angle: float) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var segments := 20
	var angle_range := end_angle - start_angle
	if abs(angle_range) > PI:
		if angle_range > 0:
			angle_range -= TAU
		else:
			angle_range += TAU

	for i in range(segments + 1):
		var t := float(i) / segments
		var angle := start_angle + angle_range * t
		var pos := center + Vector3(cos(angle), sin(angle), 0) * radius
		mesh.surface_set_color(Color(1.0, 0.8, 0.95, 0.6))
		mesh.surface_add_vertex(pos)

	mesh.surface_end()
	_arc_mesh.mesh = mesh

# ── DNA helpers ──────────────────────────────────────────────────────────────

## Where b opens, given the case this exercise is arguing. "agreeing" returns the
## shipped literal so the default build is unchanged. a stays at angle_a = 0, so
## the axis turns theta and nothing else.
func _opening_angle() -> float:
	match opening:
		"strangers":
			return PI / 2.0
		"opposing":
			return 2.0 * PI / 3.0
		"parallel":
			return 0.0
		_:
			return PI / 3.0

## The signed sweep from start to end, folded into (-PI, PI] — the same folding
## _update_arc does inline. Kept separate so _update_arc stays untouched.
func _signed_span(start_angle: float, end_angle: float) -> float:
	var span: float = end_angle - start_angle
	if absf(span) > PI:
		if span > 0.0:
			span -= TAU
		else:
			span += TAU
	return span

## The angle as a filled sector — extent instead of a hairline. Wound both ways
## so it reads from either side without a two-sided material.
func _update_wedge(center: Vector3, radius: float, start_angle: float, end_angle: float) -> void:
	var span: float = _signed_span(start_angle, end_angle)
	if absf(span) < 0.001:
		_arc_mesh.mesh = null
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 20
	for i in range(segments):
		var a0: float = start_angle + span * (float(i) / float(segments))
		var a1: float = start_angle + span * (float(i + 1) / float(segments))
		var p0: Vector3 = center + Vector3(cos(a0), sin(a0), 0) * radius
		var p1: Vector3 = center + Vector3(cos(a1), sin(a1), 0) * radius
		var tri: Array[Vector3] = [center, p0, p1, center, p1, p0]
		for v in tri:
			mesh.surface_set_color(FIGURE_COLOR)
			mesh.surface_add_vertex(v)
	mesh.surface_end()
	_arc_mesh.mesh = mesh

## Tip to tip — the difference vector, drawn where the arc used to be.
func _update_chord(tip_a: Vector3, tip_b: Vector3) -> void:
	if tip_a.distance_to(tip_b) < 0.001:
		_arc_mesh.mesh = null
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var ends: Array[Vector3] = [tip_a, tip_b]
	for v in ends:
		mesh.surface_set_color(FIGURE_COLOR)
		mesh.surface_add_vertex(v)
	mesh.surface_end()
	_arc_mesh.mesh = mesh

func _process(_delta: float) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Guarded: an absent, unknown or unchanged value touches nothing, and nothing is
## redrawn until _ready has actually built the scene once. The angle sliders stay
## live afterwards — opening sets the case the exercise is found in, it does not
## lock it.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return
	var pose_changed: bool = false
	var figure_changed: bool = false
	if config.has("opening"):
		var o: String = str(config["opening"])
		if o in OPENING_VALUES and o != opening:
			opening = o
			pose_changed = true
	if config.has("figure"):
		var f: String = str(config["figure"])
		if f in FIGURE_VALUES and f != figure:
			figure = f
			figure_changed = true
	# Direct angle overrides, applied after opening so an explicit angle wins.
	if config.has("angle_a"):
		angle_a = float(config["angle_a"])
		pose_changed = true
	if config.has("angle_b"):
		angle_b = float(config["angle_b"])
		pose_changed = true
	elif pose_changed and config.has("opening"):
		angle_b = _opening_angle()
	if not _built:
		return
	if pose_changed and is_instance_valid(_angle_b_controller):
		# set_value re-emits value_changed, which is what redraws the vectors.
		_angle_b_controller.call("set_value", angle_b)
	if pose_changed or figure_changed:
		_update_vectors()
