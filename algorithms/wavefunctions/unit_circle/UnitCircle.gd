extends Node3D

# --- Circle / indicators ---

# @identity
# essence: point(t) = (cos(theta), sin(theta)), waves built stroke by stroke as angle sweeps
# desire: Watch a point trace the unit circle while sine and cosine waves build incrementally
# critical_parameter: rotation_speed — controls how fast the circle is traced and waves extend
# triggers: continuous angle increment builds the wave one sample at a time until complete
# emerges: visual proof that sine and cosine are born from circular motion
# needs: VR observation [has], speed control [missing]
# relationships: depends on MultiMesh segment rendering; contrasts with UnitCircleTrig (buildup vs continuous trail); unlocks the circle-wave connection
# truth: The unit circle is the Rosetta Stone of trigonometry — rotation on one side, oscillation on the other.

# --- DNA ---------------------------------------------------------------------
# correspondence: which relation between the angle and the pair of lengths is actually
#   drawn and walked. "both" is the shipped figure — the vertical sine rod, the
#   horizontal cosine rod, and a bridge whose planks unroll sin(theta).
# buildup / start_angle_deg are BENCH knobs, not axes. The bridge lays itself one plank
#   at a time over ~16 seconds, so a still photographed at t=1s shows 6% of the figure
#   and the answer depends on the shutter. "complete" and a non-zero start angle let the
#   camera see the whole claim; both defaults are the shipped behaviour.
@export_enum("both", "cosine", "tangent", "helix") var correspondence: String = "both"
@export_enum("progressive", "complete") var buildup: String = "progressive"
@export var start_angle_deg: float = 0.0

@export var radius: float = 1.0
@export var rotation_speed: float = 0.8
@export var samples_per_cycle: int = 100
@export var line_thickness: float = 0.03
@export var sine_color: Color = Color(0.6, 1.0, 0.6)
@export var cosine_color: Color = Color(0.6, 0.8, 1.0)
@export var point_color: Color = Color(0.8, 0.6, 1.0)
@export var circle_dot_color: Color = Color(0.85, 0.85, 0.9)
@export var use_color_wheel: bool = true
@export_range(0.0, 1.0, 0.01) var wheel_saturation: float = 0.9
@export_range(0.0, 1.0, 0.01) var wheel_value: float = 1.0
@export var color_platforms_from_wheel: bool = true
@export_range(0.0, 1.0, 0.01) var platform_wheel_value: float = 0.85
@export var num_cycles: int = 2  
# --- Bridge ---
@export var start_x: float = 3.0
@export var wave_length: float = 28.0   # ~2× previous length
@export var platform_size: Vector3 = Vector3(1.5, 0.3, 5.0)  # wider planks
@export var enable_collision: bool = true
@export var platform_color: Color = Color(0.80, 0.65, 0.95)

# --- State ---
var angle: float = 0.0
var built_index: int = -1
var finished: bool = false

# --- Nodes ---
var circle_outline: MultiMeshInstance3D
var rotating_point: MeshInstance3D
var radius_line: Node3D
var sine_line: Node3D
var cosine_line: Node3D
var _sine_cap: Node3D
var _cos_cap: Node3D
var _rotating_material: StandardMaterial3D
var _tangent_line: Node3D = null

# --- Shared mesh ---
var _shared_box: BoxMesh

func _ready() -> void:
	angle = deg_to_rad(start_angle_deg)
	_create_unit_circle_outline()
	_create_rotator()
	_create_projection_lines()
	if correspondence == "tangent":
		_create_tangent_line()
	_add_axes()
	_apply_correspondence()
	# Left out of the default path deliberately: shipped placements got their first rod
	# update from the first _process tick and nothing here should change that.
	if buildup == "complete" or start_angle_deg != 0.0:
		_update_rotator_and_indicators()
	if buildup == "complete":
		_build_all_steps()

func _process(delta: float) -> void:
	if finished:
		return

	angle += rotation_speed * delta
	var total_angle := TAU * num_cycles
	if angle > total_angle:
		angle = total_angle

	_update_rotator_and_indicators()

	# build progress (0 → 1 over total_angle)
	var t_norm: float = clamp(angle / total_angle, 0.0, 1.0)
	var target_index: int = int(floor(t_norm * samples_per_cycle * num_cycles))
	target_index = clamp(target_index, 0, samples_per_cycle * num_cycles - 1)

	while built_index < target_index:
		built_index += 1
		var step_angle: float = float(built_index) / float(samples_per_cycle - 1) * TAU
		_create_bridge_step(step_angle, built_index)

	if built_index >= samples_per_cycle * num_cycles - 1:
		finished = true


# ============================================================================
# Unit circle (dotted outline)
# ============================================================================
func _create_unit_circle_outline() -> void:
	circle_outline = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	var dot := SphereMesh.new()
	dot.radius = 0.04
	dot.height = dot.radius * 2.0
	mm.mesh = dot
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var res: int = 64
	mm.instance_count = res

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = circle_dot_color
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 0.6
	circle_outline.material_override = mat

	for i in range(res):
		var th: float = float(i) / float(res) * TAU
		var p: Vector3 = Vector3(cos(th) * radius, sin(th) * radius, 0)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		var dot_color = _get_wheel_color(th, wheel_value) if use_color_wheel else circle_dot_color
		mm.set_instance_color(i, dot_color)

	circle_outline.multimesh = mm
	add_child(circle_outline)

# ============================================================================
# Rotating point + radius line
# ============================================================================
func _create_rotator() -> void:
	rotating_point = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.08
	sm.height = sm.radius * 2.0
	rotating_point.mesh = sm
	_rotating_material = StandardMaterial3D.new()
	_rotating_material.albedo_color = point_color
	_rotating_material.emission_enabled = true
	_rotating_material.emission = point_color * 0.6
	rotating_point.material_override = _rotating_material
	add_child(rotating_point)

	radius_line = _make_line_node(Vector3.ZERO, Vector3(radius, 0, 0), point_color, line_thickness)
	add_child(radius_line)

func _update_rotator_and_indicators() -> void:
	var x: float = cos(angle) * radius
	var y: float = sin(angle) * radius
	var p: Vector3 = Vector3(x, y, 0)
	rotating_point.position = p
	if use_color_wheel and _rotating_material:
		var wheel_color = _get_wheel_color(angle, wheel_value)
		_rotating_material.albedo_color = wheel_color
		_rotating_material.emission = wheel_color * 0.6

	# update lines
	_update_line_node(radius_line, Vector3.ZERO, p, line_thickness)
	_update_line_node(sine_line,   Vector3(x, 0, 0), p, line_thickness)  # vertical
	_update_line_node(cosine_line, Vector3(0, y, 0), p, line_thickness)  # horizontal
	_update_line_node(_sine_cap, Vector3(x, 0, 0), p, 0.01)
	_update_line_node(_cos_cap,  Vector3(0, y, 0), p, 0.01)

	# The tangent segment: from the point on the circle to where the tangent line meets
	# the x-axis at sec(theta). Its length IS tan(theta), which is why it has to be held
	# back from the quarter turn where it runs to infinity.
	if _tangent_line != null and _tangent_line.visible:
		var c: float = cos(angle)
		if absf(c) < 0.12:
			c = 0.12 if c >= 0.0 else -0.12
		_update_line_node(_tangent_line, p, Vector3(radius / c, 0, 0), line_thickness)

# ============================================================================
# Which correspondence is drawn
# ============================================================================
# The unit circle's whole content is that one angle names a pair of lengths. Which pair
# you draw is a claim, not a detail: the shipped figure draws both projections and
# unrolls the sine; cosine reads the same circle for its other shadow; tangent draws the
# segment that runs to the x-axis and blows up at a quarter turn; helix stops unrolling
# into a plane at all and lifts the bridge into the one curve both shadows come from.
func _create_tangent_line() -> void:
	if _tangent_line != null:
		return
	_tangent_line = _make_line_node(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.85, 0.45), line_thickness)
	add_child(_tangent_line)

func _apply_correspondence() -> void:
	if sine_line == null:
		return
	var sine_on: bool = correspondence != "cosine" and correspondence != "tangent"
	var cos_on: bool = correspondence != "tangent"
	sine_line.visible = sine_on
	_sine_cap.visible = sine_on
	cosine_line.visible = cos_on
	_cos_cap.visible = cos_on
	if _tangent_line != null:
		_tangent_line.visible = correspondence == "tangent"

# The height each plank of the bridge is set to. The `_` branch is the shipped
# sin(step_angle), so "both" and "helix" lay exactly the wave that shipped.
func _wave_value(step_angle: float) -> float:
	match correspondence:
		"cosine":
			return cos(step_angle)
		"tangent":
			return clampf(tan(step_angle), -2.5, 2.5)
		_:
			return sin(step_angle)

func _build_all_steps() -> void:
	var total: int = samples_per_cycle * num_cycles
	while built_index < total - 1:
		built_index += 1
		var step_angle: float = float(built_index) / float(samples_per_cycle - 1) * TAU
		_create_bridge_step(step_angle, built_index)
	finished = true

func _rebuild_bridge() -> void:
	for child in get_children():
		if String(child.name).begins_with("Platform_"):
			child.queue_free()
	built_index = -1
	finished = false
	if correspondence == "tangent":
		_create_tangent_line()
	_apply_correspondence()
	_update_rotator_and_indicators()
	if buildup == "complete":
		_build_all_steps()

# ============================================================================
# Sine / Cosine projection lines
# ============================================================================
func _create_projection_lines() -> void:
	sine_line = _make_line_node(Vector3.ZERO, Vector3.ZERO, sine_color, line_thickness)
	cosine_line = _make_line_node(Vector3.ZERO, Vector3.ZERO, cosine_color, line_thickness)
	_sine_cap = _make_line_node(Vector3.ZERO, Vector3.ZERO, sine_color, 0.01)
	_cos_cap  = _make_line_node(Vector3.ZERO, Vector3.ZERO, cosine_color, 0.01)
	for n in [sine_line, cosine_line, _sine_cap, _cos_cap]:
		add_child(n)

# helper for all line rods
func _make_line_node(from: Vector3, to: Vector3, color: Color, thickness: float) -> Node3D:
	var node := Node3D.new()
	var rod := MeshInstance3D.new()
	rod.name = "Rod"
	rod.mesh = _get_shared_box()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	rod.material_override = mat
	node.add_child(rod)
	_update_line_node(node, from, to, thickness)
	return node

func _update_line_node(node: Node3D, from: Vector3, to: Vector3, thickness: float) -> void:
	var rod := node.get_node("Rod") as MeshInstance3D
	var length: float = (to - from).length()
	var mid: Vector3 = (from + to) * 0.5
	node.position = mid
	if length > 0.001:
		var direction = (to - from).normalized()
		# Check if direction is parallel to UP vector (vertical line)
		if abs(direction.dot(Vector3.UP)) > 0.999:
			# For vertical lines, use FORWARD as up to avoid colinear warning
			node.look_at_from_position(mid, to, Vector3.FORWARD)
		else:
			node.look_at_from_position(mid, to, Vector3.UP)
	rod.scale = Vector3(thickness, thickness, max(length, 0.0001))

func _get_shared_box() -> BoxMesh:
	if _shared_box == null:
		_shared_box = BoxMesh.new()
		_shared_box.size = Vector3.ONE
	return _shared_box

# ============================================================================
# Optional: coordinate axes for reference
# ============================================================================
func _add_axes() -> void:
	var grey := Color(0.6, 0.6, 0.7, 0.6)
	var t := 0.015
	add_child(_make_line_node(Vector3(-radius * 1.2, 0, 0), Vector3(radius * 1.2, 0, 0), grey, t)) # X
	add_child(_make_line_node(Vector3(0, -radius * 1.2, 0), Vector3(0, radius * 1.2, 0), grey, t)) # Y

# ============================================================================
# Bridge construction (single pass, 100 steps)
# ============================================================================
func _create_bridge_step(step_angle: float, idx: int) -> void:
	var t: float = float(idx) / float(max(samples_per_cycle - 1, 1))
	var x: float = start_x + t * wave_length
	var y: float = _wave_value(step_angle) * radius
	var z: float = 0.0
	if correspondence == "helix":
		# Same y as the shipped wave, with the cosine added in z: the two shadows are
		# one curve, and the bridge stops pretending the plane was ever necessary.
		z = cos(step_angle) * radius

	var node := Node3D.new()
	node.name = "Platform_%d" % idx
	node.position = Vector3(x, y, z)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = platform_size
	if correspondence == "helix":
		bm.size = Vector3(platform_size.x, platform_size.y, platform_size.x)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	if color_platforms_from_wheel and use_color_wheel:
		var wheel_color = _get_wheel_color(step_angle, platform_wheel_value)
		m.albedo_color = wheel_color
		m.emission_enabled = true
		m.emission = wheel_color * 0.35
	else:
		m.albedo_color = platform_color
		m.emission_enabled = true
		m.emission = platform_color * 0.3
	m.metallic = 0.35
	m.roughness = 0.6
	mi.material_override = m
	node.add_child(mi)

	if enable_collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = bm.size
		shape.shape = box
		body.add_child(shape)
		node.add_child(body)

	add_child(node)

func _get_wheel_color(theta: float, value: float) -> Color:
	var hue = fposmod(theta / TAU, 1.0)
	return Color.from_hsv(hue, wheel_saturation, value)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Guarded twice over: nothing happens unless the key arrived, the value differs, and
	# _ready has already built once. A map that says nothing about correspondence never
	# reaches _rebuild_bridge() at all.
	var changed: bool = false
	if config.has("correspondence"):
		var c: String = str(config["correspondence"])
		if c != "" and c != correspondence:
			correspondence = c
			changed = true
	if config.has("start_angle_deg"):
		var a: float = float(config["start_angle_deg"])
		if a != start_angle_deg:
			start_angle_deg = a
			angle = deg_to_rad(a)
			changed = true
	if config.has("buildup"):
		var b: String = str(config["buildup"])
		if b != "" and b != buildup:
			buildup = b
			changed = true
	if changed and is_node_ready():
		_rebuild_bridge()
