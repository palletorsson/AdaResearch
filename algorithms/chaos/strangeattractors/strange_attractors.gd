extends Node3D

## Strange Attractors — VR 3D visualization
## Renders 6 attractor types (Lorenz, Clifford, De Jong, Bedhead, Svensson, Ikeda)
## using ImmediateMesh with PRIMITIVE_LINES and vertex colors for age-based fading.

# Attractor types
enum AttractorType {
	LORENZ,
	CLIFFORD,
	DE_JONG,
	BEDHEAD,
	SVENSSON,
	IKEDA
}

# Current attractor
@export var attractor_type: AttractorType = AttractorType.LORENZ
@export var line_color: Color = Color(0.2, 0.6, 1.0, 0.8)
@export var point_color: Color = Color(1.0, 0.9, 0.2, 1.0)
@export var max_points: int = 5000
@export var iterations_per_frame: int = 5
@export var bounding_size: float = 0.8  # Target bounding box in meters

# Internal state
var current_position: Vector3 = Vector3.ZERO
var current_point_2d: Vector2 = Vector2.ZERO
var trail_points: Array[Vector3] = []
var is_initialized: bool = false

# Mesh nodes
var _trail_mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _trail_material: StandardMaterial3D
var _point_mesh_instance: MeshInstance3D
var _label: Label3D

# Parameters for attractors — identical to original
var lorenz_params: Dictionary = {
	"sigma": 10.0,
	"rho": 28.0,
	"beta": 8.0 / 3.0,
	"dt": 0.01
}

var clifford_params: Dictionary = {
	"a": -1.4,
	"b": 1.6,
	"c": 1.0,
	"d": 0.7
}

var de_jong_params: Dictionary = {
	"a": -2.0,
	"b": -2.0,
	"c": -1.2,
	"d": 2.0
}

var bedhead_params: Dictionary = {
	"a": -0.81,
	"b": -0.92
}

var svensson_params: Dictionary = {
	"a": 1.5,
	"b": -1.8,
	"c": 1.6,
	"d": 0.9
}

var ikeda_params: Dictionary = {
	"u": 0.918
}


func _ready() -> void:
	_setup_trail_mesh()
	_setup_point_mesh()
	_setup_label()
	_reset_position()
	is_initialized = true
	_generate_initial_points()


func _setup_trail_mesh() -> void:
	_immediate_mesh = ImmediateMesh.new()
	_trail_mesh_instance = MeshInstance3D.new()
	_trail_mesh_instance.mesh = _immediate_mesh
	_trail_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_trail_material = StandardMaterial3D.new()
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_material.vertex_color_use_as_albedo = true
	_trail_material.emission_enabled = true
	_trail_material.emission = line_color
	_trail_material.emission_energy_multiplier = 1.5
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.no_depth_test = false
	_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_trail_mesh_instance.material_override = _trail_material
	add_child(_trail_mesh_instance)


func _setup_point_mesh() -> void:
	_point_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	sphere.radial_segments = 8
	sphere.rings = 4
	_point_mesh_instance.mesh = sphere
	_point_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = point_color
	mat.emission_enabled = true
	mat.emission = point_color
	mat.emission_energy_multiplier = 2.0
	_point_mesh_instance.material_override = mat
	add_child(_point_mesh_instance)


func _setup_label() -> void:
	_label = Label3D.new()
	_label.font_size = 32
	_label.pixel_size = 0.001
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.modulate = Color(1, 1, 1, 0.9)
	_label.position = Vector3(0, bounding_size * 0.55, 0)
	add_child(_label)


func _generate_initial_points() -> void:
	for i in range(mini(100, max_points)):
		_calculate_next_iteration()


func _calculate_next_iteration() -> void:
	var world_point: Vector3

	if attractor_type == AttractorType.LORENZ:
		current_position = _lorenz_attractor(current_position)
		# Lorenz lives in 3D natively — scale to ~0.4m
		# Lorenz range: x ≈ [-20,20], y ≈ [-25,25], z ≈ [0,50]
		world_point = Vector3(
			current_position.x / 50.0,
			(current_position.z - 25.0) / 50.0,  # center z around 25
			current_position.y / 50.0
		) * bounding_size * 0.5
	else:
		current_point_2d = _calculate_next_point(current_point_2d)
		# 2D attractors map to XZ plane, Y = 0
		world_point = Vector3(
			current_point_2d.x,
			0.0,
			current_point_2d.y
		)

	# Sanity check — skip divergent points
	if world_point.length() < 100.0:
		trail_points.append(world_point)

	# Keep array at max size
	if trail_points.size() > max_points:
		trail_points.remove_at(0)


func _process(_delta: float) -> void:
	if not is_initialized:
		return

	for i in range(iterations_per_frame):
		_calculate_next_iteration()

	_rebuild_trail_mesh()
	_update_point_position()
	_update_label()


func _rebuild_trail_mesh() -> void:
	_immediate_mesh.clear_surfaces()

	if trail_points.size() < 2:
		return

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var count := trail_points.size()
	for i in range(1, count):
		var alpha := float(i) / float(count)
		var color := Color(line_color.r, line_color.g, line_color.b, alpha * line_color.a)

		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(trail_points[i - 1])

		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(trail_points[i])

	_immediate_mesh.surface_end()


func _update_point_position() -> void:
	if trail_points.size() > 0:
		_point_mesh_instance.position = trail_points[trail_points.size() - 1]
		_point_mesh_instance.visible = true
	else:
		_point_mesh_instance.visible = false


func _update_label() -> void:
	_label.text = _get_attractor_name() + " (" + str(trail_points.size()) + " pts)"


func _reset_position() -> void:
	match attractor_type:
		AttractorType.LORENZ:
			current_position = Vector3(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			)
			current_point_2d = Vector2(current_position.x, current_position.y)
		_:
			current_point_2d = Vector2(
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			)

	trail_points.clear()


func _calculate_next_point(point: Vector2) -> Vector2:
	var raw_point := Vector2.ZERO

	match attractor_type:
		AttractorType.CLIFFORD:
			raw_point = _clifford_attractor(point)
		AttractorType.DE_JONG:
			raw_point = _de_jong_attractor(point)
		AttractorType.BEDHEAD:
			raw_point = _bedhead_attractor(point)
		AttractorType.SVENSSON:
			raw_point = _svensson_attractor(point)
		AttractorType.IKEDA:
			raw_point = _ikeda_attractor(point)
		_:
			raw_point = _clifford_attractor(point)

	# Scale 2D attractors to fit within bounding_size
	# Most 2D attractors output in roughly [-3, 3] range
	return raw_point


# ── Attractor math (unchanged) ──────────────────────────────────────────

func _lorenz_attractor(pos: Vector3) -> Vector3:
	var params = lorenz_params
	var dt = params.dt

	var dx = params.sigma * (pos.y - pos.x)
	var dy = pos.x * (params.rho - pos.z) - pos.y
	var dz = pos.x * pos.y - params.beta * pos.z

	return Vector3(
		pos.x + dx * dt,
		pos.y + dy * dt,
		pos.z + dz * dt
	)


func _clifford_attractor(point: Vector2) -> Vector2:
	var params = clifford_params

	var nx = sin(params.a * point.y) + params.c * cos(params.a * point.x)
	var ny = sin(params.b * point.x) + params.d * cos(params.b * point.y)

	return Vector2(nx, ny)


func _de_jong_attractor(point: Vector2) -> Vector2:
	var params = de_jong_params

	var nx = sin(params.a * point.y) - cos(params.b * point.x)
	var ny = sin(params.c * point.x) - cos(params.d * point.y)

	return Vector2(nx, ny)


func _bedhead_attractor(point: Vector2) -> Vector2:
	var params = bedhead_params

	var nx = sin(point.x * point.y / params.b) * point.y + cos(params.a * point.x - point.y)
	var ny = point.x + sin(point.y) / params.b

	return Vector2(nx, ny) * 0.1  # Scale down to avoid explosion


func _svensson_attractor(point: Vector2) -> Vector2:
	var params = svensson_params

	var nx = params.d * sin(params.a * point.x) - sin(params.b * point.y)
	var ny = params.c * cos(params.a * point.x) + cos(params.b * point.y)

	return Vector2(nx, ny)


func _ikeda_attractor(point: Vector2) -> Vector2:
	var params = ikeda_params

	var t = 0.4 - 6.0 / (1.0 + point.x * point.x + point.y * point.y)
	var sin_t = sin(t)
	var cos_t = cos(t)

	var nx = 1.0 + params.u * (point.x * cos_t - point.y * sin_t)
	var ny = params.u * (point.x * sin_t + point.y * cos_t)

	return Vector2(nx, ny) * 0.2  # Scale down to avoid explosion


# ── Utilities ────────────────────────────────────────────────────────────

func _get_attractor_name() -> String:
	match attractor_type:
		AttractorType.LORENZ:
			return "Lorenz Attractor"
		AttractorType.CLIFFORD:
			return "Clifford Attractor"
		AttractorType.DE_JONG:
			return "De Jong Attractor"
		AttractorType.BEDHEAD:
			return "Bedhead Attractor"
		AttractorType.SVENSSON:
			return "Svensson Attractor"
		AttractorType.IKEDA:
			return "Ikeda Attractor"
		_:
			return "Unknown Attractor"


func change_attractor(new_type: AttractorType) -> void:
	attractor_type = new_type
	_reset_position()
	_generate_initial_points()


func _exit_tree() -> void:
	# Clean up procedural resources
	if _immediate_mesh:
		_immediate_mesh.clear_surfaces()


func apply_grid_config(config: Dictionary) -> void:
	pass
