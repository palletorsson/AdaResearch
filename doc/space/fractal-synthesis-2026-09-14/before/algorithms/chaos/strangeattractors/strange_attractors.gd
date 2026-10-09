extends Node3D

## Strange Attractors — Expressive VR 3D visualization
## 6 attractor types with velocity-colored trails, real-time Lyapunov exponent,
## parameter space exploration, and VR slider controls.

# @identity
# essence: x_{n+1} = f(x_n, params); for Lorenz/Clifford/De Jong/Bedhead/Svensson/Ikeda, iterate a nonlinear map. The trajectory is bounded but never repeats — a structure that exists without converging.
# desire: To make chaos look like a place — velocity-colored trails turn the attractor into a sculpted ribbon you can walk around in VR, while the Lyapunov exponent reads out divergence as you adjust parameters.
# critical_parameter: attractor_type (which map) + max_points (memory budget for the visible trail) + parameter sliders that lerp toward target_params for smooth basin-to-basin morphing.
# triggers: _process tick → iterate the map iterations_per_frame times → append to _trail_points → rebuild ImmediateMesh ribbon → update Lyapunov readout
# emerges: A stable shape from a divergent process — nearby trajectories separate exponentially (positive Lyapunov), yet the cloud they trace settles into the same skeleton every time.
# needs: VR parameter sliders [missing], type-cycle button [missing]
# relationships: Belongs in fractals as the chaos-side of self-similarity (attractors have fractal dimension); pairs with logistic_map and lorenz_demo in the chaos arc.
# truth: An attractor is a memory the system can't escape — every orbit forgets where it started but remembers what shape it lives inside.

enum AttractorType { LORENZ, CLIFFORD, DE_JONG, BEDHEAD, SVENSSON, IKEDA }

@export var attractor_type: AttractorType = AttractorType.LORENZ
@export var max_points: int = 8000
@export var iterations_per_frame: int = 10
@export var bounding_size: float = 0.8

# ── Internal state ──────────────────────────────────────────────────────
var _position_3d: Vector3 = Vector3.ZERO
var _position_2d: Vector2 = Vector2.ZERO
var _trail_points: PackedVector3Array = PackedVector3Array()
var _trail_velocities: PackedFloat32Array = PackedFloat32Array()
var _is_initialized: bool = false
var _max_velocity: float = 0.001
var _lyapunov_sum: float = 0.0
var _lyapunov_count: int = 0
var _lyapunov_exponent: float = 0.0

# Parameter interpolation
var _target_params: Dictionary = {}
var _current_params: Dictionary = {}
var _param_lerp_speed: float = 3.0

# Mesh nodes
var _trail_mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _trail_material: StandardMaterial3D
var _glow_mesh_instance: MeshInstance3D
var _glow_mesh: ImmediateMesh
var _glow_material: StandardMaterial3D
var _point_mesh_instance: MeshInstance3D
var _label: Label3D
var _lyapunov_label: Label3D

# VR controllers
var _param_a_ctrl: ParameterController3D
var _param_b_ctrl: ParameterController3D
var _speed_ctrl: ParameterController3D
var _type_ctrl: ParameterController3D

# ── Default attractor parameters ────────────────────────────────────────
const ATTRACTOR_DEFAULTS: Dictionary = {
	AttractorType.LORENZ: { "a": 10.0, "b": 28.0, "c": 2.667, "dt": 0.005 },
	AttractorType.CLIFFORD: { "a": -1.4, "b": 1.6, "c": 1.0, "d": 0.7 },
	AttractorType.DE_JONG: { "a": -2.0, "b": -2.0, "c": -1.2, "d": 2.0 },
	AttractorType.BEDHEAD: { "a": -0.81, "b": -0.92, "c": 0.0, "d": 0.0 },
	AttractorType.SVENSSON: { "a": 1.5, "b": -1.8, "c": 1.6, "d": 0.9 },
	AttractorType.IKEDA: { "a": 0.918, "b": 0.0, "c": 0.0, "d": 0.0 },
}

const ATTRACTOR_NAMES: PackedStringArray = [
	"Lorenz", "Clifford", "De Jong", "Bedhead", "Svensson", "Ikeda"
]


func _ready() -> void:
	_setup_trail_mesh()
	_setup_glow_mesh()
	_setup_point_mesh()
	_setup_labels()
	_setup_controllers()
	_load_attractor_params(attractor_type)
	_reset_position()
	_is_initialized = true
	_warm_up(200)


# ── Mesh setup ──────────────────────────────────────────────────────────

func _setup_trail_mesh() -> void:
	_immediate_mesh = ImmediateMesh.new()
	_trail_mesh_instance = MeshInstance3D.new()
	_trail_mesh_instance.mesh = _immediate_mesh
	_trail_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_trail_material = StandardMaterial3D.new()
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_material.vertex_color_use_as_albedo = true
	_trail_material.emission_enabled = true
	_trail_material.emission = Color(0.4, 0.6, 1.0)
	_trail_material.emission_energy_multiplier = 1.8
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.no_depth_test = false
	_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_trail_mesh_instance.material_override = _trail_material
	add_child(_trail_mesh_instance)


func _setup_glow_mesh() -> void:
	_glow_mesh = ImmediateMesh.new()
	_glow_mesh_instance = MeshInstance3D.new()
	_glow_mesh_instance.mesh = _glow_mesh
	_glow_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_glow_material = StandardMaterial3D.new()
	_glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_material.vertex_color_use_as_albedo = true
	_glow_material.emission_enabled = true
	_glow_material.emission = Color(1.0, 0.4, 0.2)
	_glow_material.emission_energy_multiplier = 3.0
	_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glow_mesh_instance.material_override = _glow_material
	add_child(_glow_mesh_instance)


func _setup_point_mesh() -> void:
	_point_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.012
	sphere.height = 0.024
	sphere.radial_segments = 10
	sphere.rings = 6
	_point_mesh_instance.mesh = sphere
	_point_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.8)
	mat.emission_energy_multiplier = 4.0
	_point_mesh_instance.material_override = mat
	add_child(_point_mesh_instance)


func _setup_labels() -> void:
	_label = Label3D.new()
	_label.font_size = 28
	_label.pixel_size = 0.001
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.modulate = Color(1, 1, 1, 0.9)
	_label.position = Vector3(0, bounding_size * 0.6, 0)
	add_child(_label)

	_lyapunov_label = Label3D.new()
	_lyapunov_label.font_size = 22
	_lyapunov_label.pixel_size = 0.001
	_lyapunov_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lyapunov_label.no_depth_test = true
	_lyapunov_label.modulate = Color(0.7, 0.9, 1.0, 0.85)
	_lyapunov_label.position = Vector3(0, bounding_size * 0.6 - 0.06, 0)
	add_child(_lyapunov_label)


func _setup_controllers() -> void:
	var y_pos := -bounding_size * 0.55

	_param_a_ctrl = ParameterController3D.new()
	_param_a_ctrl.parameter_name = "Param A"
	_param_a_ctrl.min_value = -3.0
	_param_a_ctrl.max_value = 3.0
	_param_a_ctrl.default_value = 0.0
	_param_a_ctrl.step_size = 0.01
	_param_a_ctrl.position = Vector3(-0.3, y_pos, 0)
	_param_a_ctrl.value_changed.connect(_on_param_a_changed)
	add_child(_param_a_ctrl)

	_param_b_ctrl = ParameterController3D.new()
	_param_b_ctrl.parameter_name = "Param B"
	_param_b_ctrl.min_value = -3.0
	_param_b_ctrl.max_value = 3.0
	_param_b_ctrl.default_value = 0.0
	_param_b_ctrl.step_size = 0.01
	_param_b_ctrl.position = Vector3(0.0, y_pos, 0)
	_param_b_ctrl.value_changed.connect(_on_param_b_changed)
	add_child(_param_b_ctrl)

	_speed_ctrl = ParameterController3D.new()
	_speed_ctrl.parameter_name = "Speed"
	_speed_ctrl.min_value = 1.0
	_speed_ctrl.max_value = 30.0
	_speed_ctrl.default_value = 10.0
	_speed_ctrl.step_size = 1.0
	_speed_ctrl.position = Vector3(0.3, y_pos, 0)
	_speed_ctrl.value_changed.connect(_on_speed_changed)
	add_child(_speed_ctrl)

	_type_ctrl = ParameterController3D.new()
	_type_ctrl.parameter_name = "Attractor"
	_type_ctrl.min_value = 0.0
	_type_ctrl.max_value = 5.0
	_type_ctrl.default_value = 0.0
	_type_ctrl.step_size = 1.0
	_type_ctrl.position = Vector3(0.0, y_pos - 0.12, 0)
	_type_ctrl.value_changed.connect(_on_type_changed)
	add_child(_type_ctrl)


# ── Controller callbacks ────────────────────────────────────────────────

func _on_param_a_changed(val: float) -> void:
	_target_params["a"] = val

func _on_param_b_changed(val: float) -> void:
	_target_params["b"] = val

func _on_speed_changed(val: float) -> void:
	iterations_per_frame = int(val)

func _on_type_changed(val: float) -> void:
	var new_type := clampi(int(val), 0, 5) as AttractorType
	if new_type != attractor_type:
		change_attractor(new_type)


# ── Parameter management ────────────────────────────────────────────────

func _load_attractor_params(atype: AttractorType) -> void:
	_target_params = ATTRACTOR_DEFAULTS[atype].duplicate()
	_current_params = _target_params.duplicate()
	_sync_controllers()


func _sync_controllers() -> void:
	if _param_a_ctrl:
		var a_val: float = _current_params.get("a", 0.0)
		var a_range := _get_param_range(attractor_type, "a")
		_param_a_ctrl.parameter_name = _get_param_label(attractor_type, "a")
		_param_a_ctrl.min_value = a_range.x
		_param_a_ctrl.max_value = a_range.y
		_param_a_ctrl.set_value(a_val)

	if _param_b_ctrl:
		var b_val: float = _current_params.get("b", 0.0)
		var b_range := _get_param_range(attractor_type, "b")
		_param_b_ctrl.parameter_name = _get_param_label(attractor_type, "b")
		_param_b_ctrl.min_value = b_range.x
		_param_b_ctrl.max_value = b_range.y
		_param_b_ctrl.set_value(b_val)

	if _speed_ctrl:
		_speed_ctrl.set_value(float(iterations_per_frame))

	if _type_ctrl:
		_type_ctrl.set_value(float(attractor_type))


func _get_param_range(atype: AttractorType, param: String) -> Vector2:
	match atype:
		AttractorType.LORENZ:
			if param == "a": return Vector2(1.0, 30.0)  # sigma
			return Vector2(10.0, 50.0)  # rho
		AttractorType.IKEDA:
			if param == "a": return Vector2(0.1, 1.0)  # u
			return Vector2(-1.0, 1.0)
		AttractorType.BEDHEAD:
			return Vector2(-2.0, 2.0)
		_:
			return Vector2(-3.0, 3.0)


func _get_param_label(atype: AttractorType, param: String) -> String:
	match atype:
		AttractorType.LORENZ:
			if param == "a": return "Sigma"
			return "Rho"
		AttractorType.IKEDA:
			if param == "a": return "u"
			return "---"
		AttractorType.BEDHEAD:
			if param == "a": return "a"
			return "b"
		_:
			if param == "a": return "a"
			return "b"


func _interpolate_params(delta: float) -> void:
	for key in _target_params:
		if _current_params.has(key):
			_current_params[key] = lerpf(_current_params[key], _target_params[key],
				clampf(_param_lerp_speed * delta, 0.0, 1.0))


# ── Main loop ───────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _is_initialized:
		return

	_interpolate_params(delta)

	for i in range(iterations_per_frame):
		_iterate()

	_rebuild_trail_mesh()
	_rebuild_glow_mesh()
	_update_point()
	_update_labels()


func _warm_up(count: int) -> void:
	for i in range(count):
		_iterate()


func _iterate() -> void:
	var prev_3d := _position_3d
	var prev_2d := _position_2d
	var world_point: Vector3

	if attractor_type == AttractorType.LORENZ:
		_position_3d = _lorenz_step(_position_3d)
		world_point = Vector3(
			_position_3d.x / 50.0,
			(_position_3d.z - 25.0) / 50.0,
			_position_3d.y / 50.0
		) * bounding_size * 0.5
		# Lyapunov from divergence of nearby trajectory
		var perturbed := _lorenz_step(prev_3d + Vector3(0.0001, 0, 0))
		var d1 := (_position_3d - perturbed).length()
		if d1 > 1e-12:
			_lyapunov_sum += log(d1 / 0.0001)
			_lyapunov_count += 1
	else:
		_position_2d = _iterate_2d(_position_2d)
		# Lift 2D attractors into 3D: y = velocity-based displacement
		var vel_2d := (_position_2d - prev_2d).length()
		world_point = Vector3(
			_position_2d.x * bounding_size * 0.15,
			vel_2d * bounding_size * 0.3,
			_position_2d.y * bounding_size * 0.15
		)
		# Lyapunov for 2D maps
		var perturbed := _iterate_2d(prev_2d + Vector2(0.0001, 0))
		var d1 := (_position_2d - perturbed).length()
		if d1 > 1e-12:
			_lyapunov_sum += log(d1 / 0.0001)
			_lyapunov_count += 1

	if world_point.length() > 100.0:
		return

	# Velocity for coloring
	var velocity := 0.0
	if _trail_points.size() > 0:
		velocity = (world_point - _trail_points[_trail_points.size() - 1]).length()
	_max_velocity = maxf(_max_velocity, velocity)

	_trail_points.append(world_point)
	_trail_velocities.append(velocity)

	if _trail_points.size() > max_points:
		_trail_points.remove_at(0)
		_trail_velocities.remove_at(0)

	# Update Lyapunov running average
	if _lyapunov_count > 0:
		_lyapunov_exponent = _lyapunov_sum / float(_lyapunov_count)


# ── Trail rendering ────────────────────────────────────────────────────

func _velocity_color(vel: float, age_t: float) -> Color:
	# Map velocity to hue: blue (slow) → cyan → green → yellow → red (fast)
	var t := clampf(vel / maxf(_max_velocity, 0.001), 0.0, 1.0)
	var r: float
	var g: float
	var b: float

	if t < 0.25:
		var s := t * 4.0
		r = 0.1
		g = 0.2 + 0.6 * s
		b = 0.9 - 0.2 * s
	elif t < 0.5:
		var s := (t - 0.25) * 4.0
		r = 0.1 + 0.5 * s
		g = 0.8
		b = 0.7 - 0.5 * s
	elif t < 0.75:
		var s := (t - 0.5) * 4.0
		r = 0.6 + 0.4 * s
		g = 0.8 - 0.2 * s
		b = 0.2 - 0.1 * s
	else:
		var s := (t - 0.75) * 4.0
		r = 1.0
		g = 0.6 - 0.5 * s
		b = 0.1

	# Fade old segments
	var alpha := 0.15 + 0.85 * age_t
	return Color(r, g, b, alpha)


func _rebuild_trail_mesh() -> void:
	_immediate_mesh.clear_surfaces()
	var count := _trail_points.size()
	if count < 2:
		return

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(1, count):
		var age_t := float(i) / float(count)
		var vel := _trail_velocities[i]
		var color := _velocity_color(vel, age_t)

		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(_trail_points[i - 1])
		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(_trail_points[i])
	_immediate_mesh.surface_end()


func _rebuild_glow_mesh() -> void:
	# Hot trail: last 5% of points drawn brighter/thicker
	_glow_mesh.clear_surfaces()
	var count := _trail_points.size()
	var glow_start := int(count * 0.95)
	if glow_start >= count - 1:
		return

	_glow_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(glow_start + 1, count):
		var local_t := float(i - glow_start) / float(count - glow_start)
		var vel := _trail_velocities[i]
		var t := clampf(vel / maxf(_max_velocity, 0.001), 0.0, 1.0)
		var color := Color(1.0, 0.6 + 0.4 * (1.0 - t), 0.3 + 0.5 * (1.0 - t), local_t)

		_glow_mesh.surface_set_color(color)
		_glow_mesh.surface_add_vertex(_trail_points[i - 1])
		_glow_mesh.surface_set_color(color)
		_glow_mesh.surface_add_vertex(_trail_points[i])
	_glow_mesh.surface_end()


func _update_point() -> void:
	if _trail_points.size() > 0:
		_point_mesh_instance.position = _trail_points[_trail_points.size() - 1]
		_point_mesh_instance.visible = true
		# Pulse the current point based on velocity
		var vel := _trail_velocities[_trail_velocities.size() - 1]
		var t := clampf(vel / maxf(_max_velocity, 0.001), 0.0, 1.0)
		var mat := _point_mesh_instance.material_override as StandardMaterial3D
		mat.emission = Color(1.0, 0.7 + 0.3 * (1.0 - t), 0.5 + 0.5 * (1.0 - t))
		mat.emission_energy_multiplier = 3.0 + 3.0 * t
	else:
		_point_mesh_instance.visible = false


func _update_labels() -> void:
	_label.text = ATTRACTOR_NAMES[attractor_type] + " (" + str(_trail_points.size()) + " pts)"
	if _lyapunov_count > 100:
		_lyapunov_label.text = "λ ≈ %.3f  %s" % [
			_lyapunov_exponent,
			"(chaotic)" if _lyapunov_exponent > 0 else "(stable)"
		]
	else:
		_lyapunov_label.text = "λ computing..."


# ── Attractor math ──────────────────────────────────────────────────────

func _lorenz_step(pos: Vector3) -> Vector3:
	var sigma: float = _current_params.get("a", 10.0)
	var rho: float = _current_params.get("b", 28.0)
	var beta: float = _current_params.get("c", 2.667)
	var dt: float = _current_params.get("dt", 0.005)

	var dx := sigma * (pos.y - pos.x)
	var dy := pos.x * (rho - pos.z) - pos.y
	var dz := pos.x * pos.y - beta * pos.z
	return Vector3(pos.x + dx * dt, pos.y + dy * dt, pos.z + dz * dt)


func _iterate_2d(point: Vector2) -> Vector2:
	match attractor_type:
		AttractorType.CLIFFORD:
			return _clifford(point)
		AttractorType.DE_JONG:
			return _de_jong(point)
		AttractorType.BEDHEAD:
			return _bedhead(point)
		AttractorType.SVENSSON:
			return _svensson(point)
		AttractorType.IKEDA:
			return _ikeda(point)
		_:
			return _clifford(point)


func _clifford(p: Vector2) -> Vector2:
	var a: float = _current_params.get("a", -1.4)
	var b: float = _current_params.get("b", 1.6)
	var c: float = _current_params.get("c", 1.0)
	var d: float = _current_params.get("d", 0.7)
	return Vector2(sin(a * p.y) + c * cos(a * p.x), sin(b * p.x) + d * cos(b * p.y))


func _de_jong(p: Vector2) -> Vector2:
	var a: float = _current_params.get("a", -2.0)
	var b: float = _current_params.get("b", -2.0)
	var c: float = _current_params.get("c", -1.2)
	var d: float = _current_params.get("d", 2.0)
	return Vector2(sin(a * p.y) - cos(b * p.x), sin(c * p.x) - cos(d * p.y))


func _bedhead(p: Vector2) -> Vector2:
	var a: float = _current_params.get("a", -0.81)
	var b: float = _current_params.get("b", -0.92)
	return Vector2(
		sin(p.x * p.y / b) * p.y + cos(a * p.x - p.y),
		p.x + sin(p.y) / b
	) * 0.1


func _svensson(p: Vector2) -> Vector2:
	var a: float = _current_params.get("a", 1.5)
	var b: float = _current_params.get("b", -1.8)
	var c: float = _current_params.get("c", 1.6)
	var d: float = _current_params.get("d", 0.9)
	return Vector2(d * sin(a * p.x) - sin(b * p.y), c * cos(a * p.x) + cos(b * p.y))


func _ikeda(p: Vector2) -> Vector2:
	var u: float = _current_params.get("a", 0.918)
	var t := 0.4 - 6.0 / (1.0 + p.x * p.x + p.y * p.y)
	return Vector2(
		1.0 + u * (p.x * cos(t) - p.y * sin(t)),
		u * (p.x * sin(t) + p.y * cos(t))
	) * 0.2


# ── Public API ──────────────────────────────────────────────────────────

func change_attractor(new_type: AttractorType) -> void:
	attractor_type = new_type
	_load_attractor_params(new_type)
	_reset_position()
	_warm_up(200)


func _reset_position() -> void:
	match attractor_type:
		AttractorType.LORENZ:
			_position_3d = Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			)
			_position_2d = Vector2(_position_3d.x, _position_3d.y)
		_:
			_position_2d = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))

	_trail_points.clear()
	_trail_velocities.clear()
	_max_velocity = 0.001
	_lyapunov_sum = 0.0
	_lyapunov_count = 0
	_lyapunov_exponent = 0.0


func apply_grid_config(config: Dictionary) -> void:
	if config.has("attractor"):
		var name_str := str(config.attractor).to_lower()
		for i in range(ATTRACTOR_NAMES.size()):
			if ATTRACTOR_NAMES[i].to_lower() == name_str:
				attractor_type = i as AttractorType
				break

	if config.has("max_points"):
		max_points = clampi(int(config.max_points), 1000, 20000)
	if config.has("speed"):
		iterations_per_frame = clampi(int(config.speed), 1, 50)
	if config.has("param_a"):
		_target_params["a"] = float(config.param_a)
	if config.has("param_b"):
		_target_params["b"] = float(config.param_b)

	_load_attractor_params(attractor_type)
	if config.has("param_a"):
		_target_params["a"] = float(config.param_a)
		_current_params["a"] = float(config.param_a)
	if config.has("param_b"):
		_target_params["b"] = float(config.param_b)
		_current_params["b"] = float(config.param_b)

	_reset_position()
	_warm_up(200)
	_sync_controllers()


func _exit_tree() -> void:
	if _immediate_mesh:
		_immediate_mesh.clear_surfaces()
	if _glow_mesh:
		_glow_mesh.clear_surfaces()
