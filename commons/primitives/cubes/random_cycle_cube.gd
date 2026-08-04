extends Node3D

const GRID_SHADER: Shader = preload("res://commons/resourses/shaders/SimpleGrid.gdshader")

# --- DNA (stage 2 - variation), promoted 2026-08-03 -------------------------
#
# WHAT THIS IS. A one-metre cube in a floor that sinks out from under you on
# randomised timing and comes back. Every knob it had was a DURATION - waits,
# sink time, rise time, collider lead and lag - and a still photograph cannot
# see a duration. Sweeping any of them would have produced identical frames at
# random moments, which is the failure this codebase already paid for once with
# info_board. So neither axis below is a rate.
#
# AXIS 1 - POSTURE: which moment of the cycle this one is caught at. Borrowed
# from [[spring_hopper]], [[kresling_spire]] and [[armadillo_eggling]] in this
# same corpus - same question (which body is this thing holding), same
# sentinel-first shape where `cycle` means the state machine keeps sole
# ownership. The four states already exist as CycleState and drive height,
# colour, indicator and collider together; nothing outside the loop could ever
# select one, so every r_c in the corpus is photographed at a coin-flip moment.
#
#   cycle     SHIPPED. The random loop runs and owns position, colour and
#             collider exactly as before. A pure no-op branch.
#   seated    IDLE held. Full height, cyan, collider on, indicator dark.
#   leaving   GOING_OUT held partway down. Orange, indicator LIT, collider
#             still on - the frame where the floor has not yet betrayed you.
#   sunken    HIDDEN held. Down a full sink_distance, dimmed to hidden_color
#             at alpha 0.25, collider OFF. The gap you fall through.
#   arriving  COMING_IN held near the top. Green, indicator LIT, collider back
#             on. The same geometry as `leaving` and the opposite promise.
#
# `leaving` and `arriving` are pinned at different fractions of the travel
# (0.45 and 0.20) on purpose: they are both mid-transit snapshots, the exact
# fraction is arbitrary, and two frames that differ only in hue would buy a
# rung that answers less than it costs.
#
# AXIS 2 - WARNING: how much the block tells you before it costs you anything.
# Adopted word for word from [[path_block]] and [[catalyst_vent]], which ask it
# of an obstacle and of a spawn seam. This cube belongs in that conversation:
# it is a floor tile whose entire function is CONSEQUENCE, and it already ships
# with one answer - a lit mote on its crown - that nobody had ever named.
#
#   beacon  SHIPPED. The emissive sphere at y=0.72, lit only while the block is
#           moving. Broadcast as light, and silent at both ends of the cycle.
#   stain   no mote; a discolouration soaked into the floor at its foot, always
#           there. Addressed to your feet: readable only from the cell itself.
#   cage    no mote; four bars standing at the corners of the cell, always
#           there. Someone catalogued the hazard and fenced it. The block sinks
#           through the bars on exactly the same rule.
#   none    nothing at all. Only the cube's own colour, and colour is the one
#           thing you are not looking at when you are looking where to step.
#
# `stain` and `cage` are top_level, so they stay in the floor while the cube
# leaves it - which is the entire difference between a warning and a skirt.
#
# BOTH DEFAULTS ARE NO-OPS. `cycle` takes the identical _ready path as before
# (_set_state(IDLE) then a deferred loop start) and `beacon` leaves the
# indicator's visibility rule as `is_visible and true`. The 6 existing
# placements (Random_Game and its three placement siblings, Random_Game_Placed,
# TemplateMap_Descent13) are byte-identical to before.
#
# CYCLE_SEED is a fixture knob, not an axis. _rng.randomize() is right in a map
# and fatal on a bench. 0 keeps it; any non-zero pins the wait draw.

const POSTURES: PackedStringArray = ["cycle", "seated", "leaving", "sunken", "arriving"]
const WARNINGS: PackedStringArray = ["beacon", "stain", "cage", "none"]

@export_enum("cycle", "seated", "leaving", "sunken", "arriving") var posture: String = "cycle"
@export_enum("beacon", "stain", "cage", "none") var warning: String = "beacon"
@export var cycle_seed: int = 0

@export_group("Timing")
@export var wait_min_seconds: float = 1.0
@export var wait_span_seconds: float = 6.0
@export var sink_duration: float = 0.5
@export var disable_collider_delay: float = 0.2
@export var enable_collider_delay: float = 0.2
@export var rise_duration: float = 0.2
@export var sink_distance: float = 0.5

@export_group("Visual")
@export var idle_color: Color = Color(0.20, 0.92, 1.00, 1.0)
@export var outgoing_color: Color = Color(1.00, 0.44, 0.18, 1.0)
@export var incoming_color: Color = Color(0.28, 1.00, 0.52, 1.0)
@export var hidden_color: Color = Color(0.12, 0.14, 0.18, 0.25)
@export var wireframe_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var wireframe_width: float = 1.8
@export var wireframe_blur: float = 1.0
@export var wireframe_emission_strength: float = 1.45
@export var force_upright: bool = true

enum CycleState {
	IDLE,
	GOING_OUT,
	HIDDEN,
	COMING_IN
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _state: int = CycleState.IDLE
var _loop_ticket: int = 0
var _base_position: Vector3 = Vector3.ZERO

var _cube_mesh: MeshInstance3D = null
var _indicator_mesh: MeshInstance3D = null
var _collider_body: StaticBody3D = null
var _collision_shape: CollisionShape3D = null

var _cube_material: ShaderMaterial = null
var _indicator_material: StandardMaterial3D = null

# WARNING dressing. Built only for stain / cage, so `beacon` and `none` add no
# nodes and the shipped child order is untouched.
var _warn_root: Node3D = null
var _warn_material: StandardMaterial3D = null
var _built: bool = false

func _ready() -> void:
	if cycle_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = cycle_seed
	if force_upright:
		rotation_degrees = Vector3.ZERO
	_ensure_nodes()
	_setup_materials()
	_base_position = position
	_build_warning()
	if posture == "cycle":
		_set_state(CycleState.IDLE)
		call_deferred("_begin_cycle_loop")
	else:
		_apply_posture()
	call_deferred("_anchor_warning")
	_built = true

func _ensure_nodes() -> void:
	_cube_mesh = get_node_or_null("CubeMesh") as MeshInstance3D
	if _cube_mesh == null:
		_cube_mesh = MeshInstance3D.new()
		_cube_mesh.name = "CubeMesh"
		var box_mesh: BoxMesh = BoxMesh.new()
		box_mesh.size = Vector3.ONE
		_cube_mesh.mesh = box_mesh
		add_child(_cube_mesh)

	_indicator_mesh = get_node_or_null("StateIndicator") as MeshInstance3D
	if _indicator_mesh == null:
		_indicator_mesh = MeshInstance3D.new()
		_indicator_mesh.name = "StateIndicator"
		_indicator_mesh.position = Vector3(0.0, 0.72, 0.0)
		_indicator_mesh.visible = false
		add_child(_indicator_mesh)
	if _indicator_mesh.mesh == null:
		var sphere_mesh: SphereMesh = SphereMesh.new()
		sphere_mesh.radius = 0.09
		sphere_mesh.height = 0.18
		_indicator_mesh.mesh = sphere_mesh

	_collider_body = get_node_or_null("ColliderBody") as StaticBody3D
	if _collider_body == null:
		_collider_body = StaticBody3D.new()
		_collider_body.name = "ColliderBody"
		add_child(_collider_body)

	_collision_shape = _collider_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape == null:
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "CollisionShape3D"
		var box_shape: BoxShape3D = BoxShape3D.new()
		box_shape.size = Vector3.ONE
		_collision_shape.shape = box_shape
		_collider_body.add_child(_collision_shape)

func _setup_materials() -> void:
	_cube_material = ShaderMaterial.new()
	_cube_material.shader = GRID_SHADER
	_cube_material.set_shader_parameter("wireframeColor", wireframe_color)
	_cube_material.set_shader_parameter("width", wireframe_width)
	_cube_material.set_shader_parameter("blur", wireframe_blur)
	_cube_material.set_shader_parameter("emission_strength", wireframe_emission_strength)
	_cube_material.set_shader_parameter("show_interior", true)
	_cube_material.set_shader_parameter("wireframeOpacity", 1.0)
	_cube_material.set_shader_parameter("globalOpacity", 1.0)
	if _cube_mesh:
		_cube_mesh.material_override = _cube_material

	_indicator_material = StandardMaterial3D.new()
	_indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_indicator_material.emission_enabled = true
	_indicator_material.emission_energy = 1.1
	_indicator_material.metallic = 0.0
	_indicator_material.roughness = 0.25
	if _indicator_mesh:
		_indicator_mesh.material_override = _indicator_material


## AXIS 1. Freeze the cube at one moment of the cycle. Never reached at the
## default `cycle`, which is guarded out in _ready so the loop keeps sole
## ownership of position, colour and collider exactly as it always has.
func _apply_posture() -> void:
	match posture:
		"seated":
			position.y = _base_position.y
			_set_collision_enabled(true)
			_set_state(CycleState.IDLE)
		"leaving":
			position.y = _base_position.y - sink_distance * 0.45
			_set_collision_enabled(true)
			_set_state(CycleState.GOING_OUT)
		"sunken":
			position.y = _base_position.y - sink_distance
			_set_collision_enabled(false)
			_set_state(CycleState.HIDDEN)
		"arriving":
			position.y = _base_position.y - sink_distance * 0.20
			_set_collision_enabled(true)
			_set_state(CycleState.COMING_IN)
		_:
			_set_state(CycleState.IDLE)


## AXIS 2. `beacon` and `none` build nothing — the shipped indicator sphere is
## already there and `_set_indicator_visual` decides whether it may show.
func _build_warning() -> void:
	if _warn_root != null and is_instance_valid(_warn_root):
		if _warn_root.get_parent() == self:
			remove_child(_warn_root)
		_warn_root.queue_free()
	_warn_root = null
	_warn_material = null

	match warning:
		"stain":
			_warn_material = _make_warn_material(0.30)
			_warn_root = Node3D.new()
			_warn_root.name = "WarnStain"
			_warn_root.top_level = true
			var patch: MeshInstance3D = MeshInstance3D.new()
			patch.name = "Patch"
			var quad: QuadMesh = QuadMesh.new()
			quad.size = Vector2(1.34, 1.34)
			patch.mesh = quad
			patch.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			patch.position = Vector3(0.0, -0.49, 0.0)
			patch.material_override = _warn_material
			_warn_root.add_child(patch)
			add_child(_warn_root)
		"cage":
			_warn_material = _make_warn_material(0.85)
			_warn_root = Node3D.new()
			_warn_root.name = "WarnCage"
			_warn_root.top_level = true
			var bar_mesh: BoxMesh = BoxMesh.new()
			bar_mesh.size = Vector3(0.07, 1.02, 0.07)
			var corners: Array[Vector2] = [
				Vector2(-0.58, -0.58), Vector2(0.58, -0.58),
				Vector2(-0.58, 0.58), Vector2(0.58, 0.58)]
			for c in corners:
				var bar: MeshInstance3D = MeshInstance3D.new()
				bar.mesh = bar_mesh
				bar.position = Vector3(c.x, 0.01, c.y)
				bar.material_override = _warn_material
				_warn_root.add_child(bar)
			add_child(_warn_root)
		_:
			pass


func _make_warn_material(alpha_value: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy = 1.0
	mat.metallic = 0.0
	mat.roughness = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(outgoing_color.r, outgoing_color.g, outgoing_color.b, alpha_value)
	mat.emission = outgoing_color
	mat.set_meta("warn_alpha", alpha_value)
	return mat


## A stain that sinks with the block is a skirt, not a stain. The dressing is
## top_level, so it is pinned to the cell once the map has finished placing us —
## deferred, because global_position is not final inside _ready.
func _anchor_warning() -> void:
	if _warn_root == null or not is_instance_valid(_warn_root):
		return
	_warn_root.global_position = global_position + Vector3(0.0, _base_position.y - position.y, 0.0)
	_warn_root.global_rotation = Vector3.ZERO


func _begin_cycle_loop() -> void:
	_loop_ticket += 1
	var ticket: int = _loop_ticket
	_run_cycle_loop(ticket)

func _restart_cycle_loop() -> void:
	call_deferred("_begin_cycle_loop")

func _run_cycle_loop(ticket: int) -> void:
	while is_inside_tree() and ticket == _loop_ticket:
		var visible_wait: float = _next_random_wait()
		await get_tree().create_timer(visible_wait).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_state(CycleState.GOING_OUT)
		await _animate_vertical(_base_position.y - sink_distance, sink_duration)
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		await get_tree().create_timer(max(0.0, disable_collider_delay)).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_collision_enabled(false)
		_set_state(CycleState.HIDDEN)

		var hidden_wait: float = _next_random_wait()
		await get_tree().create_timer(hidden_wait).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_state(CycleState.COMING_IN)
		await get_tree().create_timer(max(0.0, enable_collider_delay)).timeout
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_collision_enabled(true)
		await _animate_vertical(_base_position.y, rise_duration)
		if not is_inside_tree() or ticket != _loop_ticket:
			return

		_set_state(CycleState.IDLE)

func _animate_vertical(target_y: float, duration_seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", target_y, max(0.01, duration_seconds))
	await tween.finished

func _set_collision_enabled(enabled: bool) -> void:
	if _collision_shape:
		_collision_shape.disabled = not enabled

func _set_state(next_state: int) -> void:
	_state = next_state
	match _state:
		CycleState.IDLE:
			_set_cube_visual(idle_color, 1.0)
			_set_indicator_visual(idle_color, false)
		CycleState.GOING_OUT:
			_set_cube_visual(outgoing_color, 1.0)
			_set_indicator_visual(outgoing_color, true)
		CycleState.HIDDEN:
			_set_cube_visual(hidden_color, hidden_color.a)
			_set_indicator_visual(outgoing_color, false)
		CycleState.COMING_IN:
			_set_cube_visual(incoming_color, 1.0)
			_set_indicator_visual(incoming_color, true)
		_:
			_set_cube_visual(idle_color, 1.0)
			_set_indicator_visual(idle_color, false)

func _set_cube_visual(color_value: Color, alpha_value: float) -> void:
	if _cube_material == null:
		return
	var albedo: Color = Color(color_value.r, color_value.g, color_value.b, clamp(alpha_value, 0.0, 1.0))
	var emission: Color = Color(color_value.r, color_value.g, color_value.b, 1.0)
	var edge_color: Color = color_value.lerp(wireframe_color, 0.55)
	var edge_alpha: float = clamp(max(0.2, albedo.a), 0.0, 1.0)
	_cube_material.set_shader_parameter("modelColor", albedo)
	_cube_material.set_shader_parameter("emissionColor", emission)
	_cube_material.set_shader_parameter("wireframeColor", edge_color)
	_cube_material.set_shader_parameter("modelOpacity", albedo.a)
	_cube_material.set_shader_parameter("wireframeOpacity", edge_alpha)

func _set_indicator_visual(color_value: Color, is_visible: bool) -> void:
	# At the default warning="beacon" this reads `is_visible and true`, which is
	# the shipped rule character for character.
	if _indicator_mesh:
		_indicator_mesh.visible = is_visible and warning == "beacon"
	if _indicator_material:
		_indicator_material.albedo_color = color_value
		_indicator_material.emission = color_value
	if _warn_material != null:
		var wa: float = 0.30
		if _warn_material.has_meta("warn_alpha"):
			wa = float(_warn_material.get_meta("warn_alpha"))
		_warn_material.albedo_color = Color(color_value.r, color_value.g, color_value.b, wa)
		_warn_material.emission = Color(color_value.r, color_value.g, color_value.b, 1.0)

func _next_random_wait() -> float:
	var min_wait: float = max(0.1, wait_min_seconds)
	var max_wait: float = max(min_wait, wait_span_seconds)
	if is_equal_approx(min_wait, max_wait):
		return min_wait
	return _rng.randf_range(min_wait, max_wait)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	# DNA axes, read first so the numeric shorthand below cannot swallow them.
	# Each is guarded: an unknown word, or the value already held, changes
	# nothing at all. `restate` is what licenses touching a built cube.
	var restate: bool = false

	if config_data.has("posture"):
		var p: String = str(config_data["posture"]).strip_edges().to_lower()
		if POSTURES.has(p) and p != posture:
			posture = p
			restate = true

	if config_data.has("warning"):
		var w: String = str(config_data["warning"]).strip_edges().to_lower()
		if WARNINGS.has(w) and w != warning:
			warning = w
			restate = true

	if config_data.has("cycle_seed"):
		var sd: int = int(config_data["cycle_seed"])
		if sd != cycle_seed:
			cycle_seed = sd
			if cycle_seed != 0:
				_rng.seed = cycle_seed
			restate = true

	if config_data.has("span"):
		wait_span_seconds = _to_float(config_data["span"], wait_span_seconds)
	if config_data.has("random_span"):
		wait_span_seconds = _to_float(config_data["random_span"], wait_span_seconds)
	if config_data.has("wait_min"):
		wait_min_seconds = _to_float(config_data["wait_min"], wait_min_seconds)
	if config_data.has("wait_span"):
		wait_span_seconds = _to_float(config_data["wait_span"], wait_span_seconds)
	if config_data.has("down"):
		sink_duration = _to_float(config_data["down"], sink_duration)
	if config_data.has("up"):
		rise_duration = _to_float(config_data["up"], rise_duration)
	if config_data.has("hide"):
		sink_distance = _to_float(config_data["hide"], sink_distance)

	# Support shorthand syntax: r_c:90:0:1#8 (config key "8" => span 8 seconds)
	for key in config_data.keys():
		var key_text: String = str(key).strip_edges()
		if key_text.is_valid_float():
			wait_span_seconds = float(key_text)
			break

	wait_min_seconds = max(0.1, wait_min_seconds)
	wait_span_seconds = max(wait_min_seconds, wait_span_seconds)
	sink_duration = max(0.01, sink_duration)
	rise_duration = max(0.01, rise_duration)
	disable_collider_delay = max(0.0, disable_collider_delay)
	enable_collider_delay = max(0.0, enable_collider_delay)
	sink_distance = max(0.0, sink_distance)

	if force_upright:
		rotation_degrees = Vector3.ZERO

	# Rebuild the dressing only when an axis actually moved and only once
	# _ready has built something to rebuild. A shipped placement that sends
	# nothing but a span never reaches this.
	if restate and _built:
		_build_warning()
		call_deferred("_anchor_warning")

	if posture == "cycle":
		# Shipped path, unconditional and unchanged: the timing knobs above have
		# moved, so the loop is restarted exactly as it always was.
		_restart_cycle_loop()
	elif _built:
		# A pinned posture owns the cube. Burn the ticket so any loop still
		# awaiting a timer exits on its next resume instead of stepping on us.
		# If _ready has not run yet there is nothing to pin — _ready reads the
		# export we just set and pins it itself.
		_loop_ticket += 1
		_apply_posture()

func _to_float(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback
