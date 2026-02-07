extends Node3D

@export var room_size: Vector3 = Vector3(10.0, 3.2, 8.0)
@export var wall_thickness: float = 0.05
@export var glass_alpha: float = 0.22
@export var floor_color: Color = Color(0.08, 0.09, 0.12, 1.0)
@export var ceiling_color: Color = Color(0.06, 0.07, 0.09, 1.0)
@export var wall_tint: Color = Color(0.5, 0.7, 0.9, 0.4)

@export_category("Constellations")
@export var constellations_per_zone: int = 4
@export var points_per_constellation: int = 18
@export var extra_connections: int = 10
@export var point_radius: float = 0.045
@export var zone_inset: float = 0.12
@export var zone_falloff: float = 2.0
@export var fade_speed: float = 3.5

@export_category("Adaptive Color")
@export_range(0.0, 1.0, 0.01) var color_saturation: float = 0.9
@export_range(0.0, 1.0, 0.01) var color_value: float = 1.0

var _player_node: Node3D
var _zones: Array = []

func _ready() -> void:
	_build_room()
	_build_zones()
	_player_node = _find_player()

func _process(delta: float) -> void:
	if _player_node == null:
		_player_node = _find_player()
	if _player_node == null:
		return

	var player_local = to_local(_player_node.global_position)
	_update_zones(player_local, delta)

func _build_room() -> void:
	var room = Node3D.new()
	room.name = "OfficeRoom"
	add_child(room)

	var half_w = room_size.x * 0.5
	var half_h = room_size.y * 0.5
	var half_d = room_size.z * 0.5

	# Floor
	var floor = MeshInstance3D.new()
	floor.mesh = _make_box(Vector3(room_size.x, wall_thickness, room_size.z))
	floor.material_override = _make_solid_material(floor_color)
	floor.position = Vector3(0, -half_h, 0)
	room.add_child(floor)

	# Ceiling
	var ceiling = MeshInstance3D.new()
	ceiling.mesh = _make_box(Vector3(room_size.x, wall_thickness, room_size.z))
	ceiling.material_override = _make_solid_material(ceiling_color)
	ceiling.position = Vector3(0, half_h, 0)
	room.add_child(ceiling)

	# Glass walls
	var wall_mat = _make_glass_material(wall_tint)

	var left_wall = MeshInstance3D.new()
	left_wall.mesh = _make_box(Vector3(wall_thickness, room_size.y, room_size.z))
	left_wall.material_override = wall_mat
	left_wall.position = Vector3(-half_w, 0, 0)
	room.add_child(left_wall)

	var right_wall = MeshInstance3D.new()
	right_wall.mesh = _make_box(Vector3(wall_thickness, room_size.y, room_size.z))
	right_wall.material_override = wall_mat
	right_wall.position = Vector3(half_w, 0, 0)
	room.add_child(right_wall)

	var back_wall = MeshInstance3D.new()
	back_wall.mesh = _make_box(Vector3(room_size.x, room_size.y, wall_thickness))
	back_wall.material_override = wall_mat
	back_wall.position = Vector3(0, 0, -half_d)
	room.add_child(back_wall)

	var front_wall = MeshInstance3D.new()
	front_wall.mesh = _make_box(Vector3(room_size.x, room_size.y, wall_thickness))
	front_wall.material_override = wall_mat
	front_wall.position = Vector3(0, 0, half_d)
	room.add_child(front_wall)

	# Simple desks for office vibe
	var desk_left = MeshInstance3D.new()
	desk_left.mesh = _make_box(Vector3(2.2, 0.08, 0.9))
	desk_left.material_override = _make_solid_material(Color(0.12, 0.12, 0.14, 1.0))
	desk_left.position = Vector3(-2.0, -half_h + 0.6, -1.6)
	room.add_child(desk_left)

	var desk_right = MeshInstance3D.new()
	desk_right.mesh = _make_box(Vector3(2.2, 0.08, 0.9))
	desk_right.material_override = _make_solid_material(Color(0.12, 0.12, 0.14, 1.0))
	desk_right.position = Vector3(2.0, -half_h + 0.6, 1.6)
	room.add_child(desk_right)

	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-45, -20, 0)
	room.add_child(light)

func _build_zones() -> void:
	_zones.clear()

	var half_w = room_size.x * 0.5
	var left_x = -half_w + wall_thickness + zone_inset
	var right_x = half_w - wall_thickness - zone_inset

	_zones.append(_create_zone("AdditiveZone", left_x, true))
	_zones.append(_create_zone("SubtractiveZone", right_x, false))

func _create_zone(name: String, wall_x: float, is_additive: bool) -> Dictionary:
	var zone_root = Node3D.new()
	zone_root.name = name
	zone_root.position = Vector3(wall_x, 0, 0)
	add_child(zone_root)

	var constellations: Array = []
	var zone = {
		"root": zone_root,
		"wall_x": wall_x,
		"is_additive": is_additive,
		"constellations": constellations
	}

	for i in range(constellations_per_zone):
		var c = _create_constellation(zone_root, i + (0 if is_additive else 100))
		constellations.append(c)
	return zone

func _create_constellation(parent: Node3D, seed: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	var points = []
	var half_d = room_size.z * 0.5
	var y_min = -room_size.y * 0.35
	var y_max = room_size.y * 0.35

	for i in range(points_per_constellation):
		var y = rng.randf_range(y_min, y_max)
		var z = rng.randf_range(-half_d + 0.6, half_d - 0.6)
		points.append(Vector3(0.0, y, z))

	var point_mesh = _make_star_points(points)
	var line_mesh = _make_constellation_lines(points, rng)

	parent.add_child(point_mesh)
	parent.add_child(line_mesh)

	return {
		"points": point_mesh,
		"lines": line_mesh,
		"alpha": 0.0,
		"target_alpha": 0.0
	}

func _make_star_points(points: Array) -> MultiMeshInstance3D:
	var mmi = MultiMeshInstance3D.new()
	mmi.name = "Stars"
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _make_star_mesh()
	mm.instance_count = points.size()
	mmi.multimesh = mm

	for i in range(points.size()):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, points[i]))

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.8
	mmi.material_override = mat
	mmi.visible = false
	return mmi

func _make_star_mesh() -> SphereMesh:
	var mesh = SphereMesh.new()
	mesh.radius = point_radius
	mesh.height = point_radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return mesh

func _make_constellation_lines(points: Array, rng: RandomNumberGenerator) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Lines"
	var array_mesh = ArrayMesh.new()
	mesh_instance.mesh = array_mesh

	var vertices = PackedVector3Array()
	# Connect sequential points for a coherent line
	for i in range(points.size() - 1):
		vertices.append(points[i])
		vertices.append(points[i + 1])
	# Add a few extra random connections
	for i in range(extra_connections):
		var a = rng.randi_range(0, points.size() - 1)
		var b = rng.randi_range(0, points.size() - 1)
		if a != b:
			vertices.append(points[a])
			vertices.append(points[b])

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	if vertices.size() >= 2:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.6
	mesh_instance.material_override = mat
	mesh_instance.visible = false
	return mesh_instance

func _update_zones(player_local: Vector3, delta: float) -> void:
	for zone in _zones:
		var wall_x = zone["wall_x"]
		var dist = abs(player_local.x - wall_x)
		var influence = clamp(1.0 - dist / zone_falloff, 0.0, 1.0)

		var z_norm = clamp((player_local.z + room_size.z * 0.5) / room_size.z, 0.0, 0.999)
		var f = z_norm * float(constellations_per_zone)
		var idx = int(floor(f))
		var t = f - float(idx)

		var is_additive = zone["is_additive"]
		var base_color = _compute_zone_color(player_local, is_additive)
		var constellations = zone["constellations"]

		for i in range(constellations.size()):
			var c = constellations[i]
			var target = 0.0
			if i == idx:
				target = influence * (1.0 - t)
			elif i == (idx + 1) % constellations.size():
				target = influence * t
			c["target_alpha"] = target
			c["alpha"] = _smooth_alpha(c["alpha"], c["target_alpha"], delta)
			_apply_constellation_color(c, base_color, is_additive)

func _compute_zone_color(player_local: Vector3, is_additive: bool) -> Color:
	var nx = clamp((player_local.x + room_size.x * 0.5) / room_size.x, 0.0, 1.0)
	var nz = clamp((player_local.z + room_size.z * 0.5) / room_size.z, 0.0, 1.0)
	var hue = fposmod((atan2(player_local.z, player_local.x) / TAU) + 0.5, 1.0)
	var base = Color.from_hsv(hue, color_saturation, color_value)
	base = Color(max(base.r, nx), max(base.g, nz), max(base.b, 1.0 - 0.5 * (nx + nz)), 1.0)
	if is_additive:
		return base
	return Color(1.0 - base.r, 1.0 - base.g, 1.0 - base.b, 1.0)

func _apply_constellation_color(c: Dictionary, base: Color, is_additive: bool) -> void:
	var alpha = clamp(c["alpha"], 0.0, 1.0)
	var color = base
	color.a = alpha

	var points = c["points"] as MultiMeshInstance3D
	var lines = c["lines"] as MeshInstance3D
	if alpha <= 0.01:
		points.visible = false
		lines.visible = false
		return

	points.visible = true
	lines.visible = true

	var pmat = points.material_override as StandardMaterial3D
	var lmat = lines.material_override as StandardMaterial3D
	if pmat:
		pmat.albedo_color = color
		pmat.emission = base * (0.6 + 0.4 * alpha)
		pmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if is_additive else BaseMaterial3D.BLEND_MODE_MUL
	if lmat:
		lmat.albedo_color = color
		lmat.emission = base * (0.4 + 0.3 * alpha)
		lmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if is_additive else BaseMaterial3D.BLEND_MODE_MUL

func _smooth_alpha(current: float, target: float, delta: float) -> float:
	var k = 1.0 - exp(-fade_speed * delta)
	return lerp(current, target, k)

func _find_player() -> Node3D:
	# Prefer XROrigin3D if present
	var root = get_tree().root
	if root:
		var xr = root.find_child("XROrigin3D", true, false)
		if xr and xr is Node3D:
			return xr
	# Fallback to current camera
	var cam = get_viewport().get_camera_3d()
	if cam:
		return cam
	return null

func _make_box(size: Vector3) -> BoxMesh:
	var box = BoxMesh.new()
	box.size = size
	return box

func _make_solid_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.0
	return mat

func _make_glass_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, glass_alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.1
	mat.roughness = 0.05
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b) * 0.3
	return mat
