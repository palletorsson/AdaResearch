extends Node3D
class_name RandomLines

## Random Lines — Random line segment generation in 3D space.
##
## Demonstrates how random geometric objects are constructed by sampling their
## defining parameters. Supports uniform, Gaussian, and clustered distributions
## to show how different probability distributions produce visually distinct
## spatial configurations. Color modes reveal statistical properties like
## segment length.

# --- Configuration ---

@export var num_lines: int = 40
@export var area_size: Vector3 = Vector3(2.0, 2.0, 2.0)

## Distribution: 0=uniform, 1=gaussian, 2=clustered
@export_range(0, 2) var distribution: int = 0
@export var cluster_count: int = 3
@export var cluster_spread: float = 0.4

## Color mode: 0=single_color, 1=random_per_line, 2=length_gradient
@export_range(0, 2) var color_mode: int = 2
@export var base_color: Color = Color(0.3, 0.7, 1.0)
@export var short_color: Color = Color(0.2, 0.9, 0.3)
@export var long_color: Color = Color(1.0, 0.2, 0.2)

@export var animate: bool = false
@export var drift_speed: float = 0.15

@export var show_bounding_box: bool = true

# --- Internal ---

var _mesh_inst: MeshInstance3D
var _im: ImmediateMesh
var _box_mesh_inst: MeshInstance3D
var _box_im: ImmediateMesh
var _endpoints: Array  # Array of [Vector3, Vector3]
var _velocities: Array  # Array of [Vector3, Vector3] for animation
var _rng: RandomNumberGenerator


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	_build_mesh()
	if show_bounding_box:
		_build_bounding_box()
	_generate_lines()
	_draw_lines()


func _build_mesh() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.name = "LinesMesh"
	_im = ImmediateMesh.new()
	_mesh_inst.mesh = _im

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_mesh_inst.material_override = mat

	add_child(_mesh_inst)


func _build_bounding_box() -> void:
	_box_mesh_inst = MeshInstance3D.new()
	_box_mesh_inst.name = "BoundingBox"
	_box_im = ImmediateMesh.new()
	_box_mesh_inst.mesh = _box_im

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box_mesh_inst.material_override = mat

	_draw_bounding_box()
	add_child(_box_mesh_inst)


func _draw_bounding_box() -> void:
	_box_im.clear_surfaces()
	_box_im.surface_begin(Mesh.PRIMITIVE_LINES)

	var h := area_size * 0.5
	var col := Color(1.0, 1.0, 1.0, 0.15)
	var corners: Array[Vector3] = [
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z),
		Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z),
		Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z),
		Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z),
	]
	# 12 edges of the box
	var edges: Array[Vector2i] = [
		Vector2i(0,1), Vector2i(1,2), Vector2i(2,3), Vector2i(3,0),
		Vector2i(4,5), Vector2i(5,6), Vector2i(6,7), Vector2i(7,4),
		Vector2i(0,4), Vector2i(1,5), Vector2i(2,6), Vector2i(3,7),
	]
	for e in edges:
		_box_im.surface_set_color(col)
		_box_im.surface_add_vertex(corners[e.x])
		_box_im.surface_set_color(col)
		_box_im.surface_add_vertex(corners[e.y])

	_box_im.surface_end()


func _generate_lines() -> void:
	_endpoints = []
	_velocities = []

	# Pre-generate cluster centers if needed
	var clusters: Array[Vector3] = []
	if distribution == 2:
		for _c in range(cluster_count):
			clusters.append(_random_point_uniform())

	for _i in range(num_lines):
		var p1: Vector3
		var p2: Vector3

		match distribution:
			0:  # Uniform
				p1 = _random_point_uniform()
				p2 = _random_point_uniform()
			1:  # Gaussian (centered, sigma = area_size / 4)
				p1 = _random_point_gaussian()
				p2 = _random_point_gaussian()
			2:  # Clustered
				var center: Vector3 = clusters[_rng.randi_range(0, clusters.size() - 1)]
				p1 = center + _random_point_gaussian_raw() * cluster_spread
				p2 = center + _random_point_gaussian_raw() * cluster_spread

		_endpoints.append([p1, p2])

		if animate:
			var v1 := Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0)
			).normalized() * drift_speed
			var v2 := Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0)
			).normalized() * drift_speed
			_velocities.append([v1, v2])


func _random_point_uniform() -> Vector3:
	var h := area_size * 0.5
	return Vector3(
		_rng.randf_range(-h.x, h.x),
		_rng.randf_range(-h.y, h.y),
		_rng.randf_range(-h.z, h.z)
	)


func _random_point_gaussian() -> Vector3:
	var raw := _random_point_gaussian_raw()
	return Vector3(
		clampf(raw.x, -1.0, 1.0),
		clampf(raw.y, -1.0, 1.0),
		clampf(raw.z, -1.0, 1.0)
	) * area_size * 0.5


func _random_point_gaussian_raw() -> Vector3:
	return Vector3(
		_rng.randfn(0.0, 0.25),
		_rng.randfn(0.0, 0.25),
		_rng.randfn(0.0, 0.25)
	)


func _color_for_line(p1: Vector3, p2: Vector3, idx: int) -> Color:
	match color_mode:
		0:  # Single color
			return base_color
		1:  # Random per line
			var hue := fmod(float(idx) * 0.618033988, 1.0)  # golden ratio spacing
			return Color.from_hsv(hue, 0.7, 0.9)
		2:  # Length gradient: short=green, long=red
			var length := p1.distance_to(p2)
			var max_possible := area_size.length()
			var t := clampf(length / (max_possible * 0.5), 0.0, 1.0)
			return short_color.lerp(long_color, t)
	return base_color


func _draw_lines() -> void:
	_im.clear_surfaces()
	if _endpoints.is_empty():
		return

	_im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(_endpoints.size()):
		var pair: Array = _endpoints[i]
		var col := _color_for_line(pair[0], pair[1], i)
		_im.surface_set_color(col)
		_im.surface_add_vertex(pair[0])
		_im.surface_set_color(col)
		_im.surface_add_vertex(pair[1])
	_im.surface_end()


func _process(delta: float) -> void:
	if not animate or _endpoints.is_empty():
		return

	var h := area_size * 0.5
	for i in range(_endpoints.size()):
		for j in range(2):
			_endpoints[i][j] += _velocities[i][j] * delta
			# Bounce off bounding box walls
			var p: Vector3 = _endpoints[i][j]
			var v: Vector3 = _velocities[i][j]
			if abs(p.x) > h.x:
				v.x = -v.x
				p.x = clampf(p.x, -h.x, h.x)
			if abs(p.y) > h.y:
				v.y = -v.y
				p.y = clampf(p.y, -h.y, h.y)
			if abs(p.z) > h.z:
				v.z = -v.z
				p.z = clampf(p.z, -h.z, h.z)
			_endpoints[i][j] = p
			_velocities[i][j] = v

	_draw_lines()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("num_lines"):
		num_lines = int(config["num_lines"])
	if config.has("area_size_x"):
		area_size.x = float(config["area_size_x"])
	if config.has("area_size_y"):
		area_size.y = float(config["area_size_y"])
	if config.has("area_size_z"):
		area_size.z = float(config["area_size_z"])
	if config.has("distribution"):
		distribution = int(config["distribution"])
	if config.has("cluster_count"):
		cluster_count = int(config["cluster_count"])
	if config.has("cluster_spread"):
		cluster_spread = float(config["cluster_spread"])
	if config.has("color_mode"):
		color_mode = int(config["color_mode"])
	if config.has("base_color"):
		base_color = Color(config["base_color"])
	if config.has("animate"):
		animate = bool(config["animate"])
	if config.has("drift_speed"):
		drift_speed = float(config["drift_speed"])
	if config.has("show_bounding_box"):
		show_bounding_box = bool(config["show_bounding_box"])

	# Rebuild with new parameters
	for child in get_children():
		child.queue_free()
	call_deferred("_ready")
