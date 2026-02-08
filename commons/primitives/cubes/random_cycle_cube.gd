extends Node3D

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

var _cube_material: StandardMaterial3D = null
var _indicator_material: StandardMaterial3D = null

func _ready() -> void:
	_rng.randomize()
	_ensure_nodes()
	_setup_materials()
	_base_position = position
	_set_state(CycleState.IDLE)
	call_deferred("_begin_cycle_loop")

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
	_cube_material = StandardMaterial3D.new()
	_cube_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cube_material.metallic = 0.12
	_cube_material.roughness = 0.42
	_cube_material.emission_enabled = true
	_cube_material.emission_energy = 0.7
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
	_cube_material.albedo_color = albedo
	_cube_material.emission = Color(color_value.r, color_value.g, color_value.b, 1.0) * 0.75

func _set_indicator_visual(color_value: Color, is_visible: bool) -> void:
	if _indicator_mesh:
		_indicator_mesh.visible = is_visible
	if _indicator_material:
		_indicator_material.albedo_color = color_value
		_indicator_material.emission = color_value

func _next_random_wait() -> float:
	var min_wait: float = max(0.1, wait_min_seconds)
	var max_wait: float = max(min_wait, wait_span_seconds)
	if is_equal_approx(min_wait, max_wait):
		return min_wait
	return _rng.randf_range(min_wait, max_wait)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

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

	_restart_cycle_loop()

func _to_float(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		return float(value)
	var text: String = str(value).strip_edges()
	if text.is_valid_float():
		return float(text)
	return fallback
