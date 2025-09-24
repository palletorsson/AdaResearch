extends Node3D

const HANDLE_SCENE := preload("res://commons/primitives/point/grab_sphere_point.tscn")
const HANDLE_ORDER := [
	"base_back_left",
	"base_back_right",
	"base_front_right",
	"base_front_left",
	"apex"
]

var base_color: Color = Color(1.0, 0.8, 0.2)
var pyramid_height: float = 0.8
var base_size: float = 0.6

var mesh_instance: MeshInstance3D
var handle_nodes: Dictionary = {}
var last_handle_positions: Dictionary = {}

func _ready():
	_create_handles()
	_rebuild_pyramid()
	set_process(true)

func _process(_delta: float) -> void:
	if _handles_changed():
		_rebuild_pyramid()

func _create_handles() -> void:
	if not handle_nodes.is_empty():
		return

	var half_base := base_size * 0.5
	var defaults := {
		"base_back_left": Vector3(-half_base, 0.0, -half_base),
		"base_back_right": Vector3(half_base, 0.0, -half_base),
		"base_front_right": Vector3(half_base, 0.0, half_base),
		"base_front_left": Vector3(-half_base, 0.0, half_base),
		"apex": Vector3(0.0, pyramid_height, 0.0)
	}

	for name in HANDLE_ORDER:
		var handle := HANDLE_SCENE.instantiate()
		handle.name = name
		handle.position = defaults.get(name, Vector3.ZERO)
		handle.alter_freeze = false
		handle.freeze = true
		handle.set_meta("pyramid_handle", name)
		add_child(handle)
		handle_nodes[name] = handle
		if owner:
			handle.owner = owner

	_sync_handle_positions()

func _rebuild_pyramid() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices := _get_current_vertices()
	if handle_nodes.size() == HANDLE_ORDER.size():
		var base_points := [
			handle_nodes["base_back_left"].position,
			handle_nodes["base_back_right"].position,
			handle_nodes["base_front_right"].position,
			handle_nodes["base_front_left"].position
		]
		var perimeter := 0.0
		for j in base_points.size():
			var next_index := (j + 1) % base_points.size()
			perimeter += (base_points[next_index] - base_points[j]).length()
		base_size = perimeter / float(base_points.size())
		pyramid_height = handle_nodes["apex"].position.y
	var faces := _create_pyramid_faces()
	for face in faces:
		_add_triangle_with_normal(st, vertices, face)

	var mesh := st.commit()
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Pyramid"
		add_child(mesh_instance)
		if owner:
			mesh_instance.owner = owner
		apply_queer_material(mesh_instance, base_color)

	mesh_instance.mesh = mesh
	_sync_handle_positions()

func _get_current_vertices() -> Array:
	if handle_nodes.size() == HANDLE_ORDER.size():
		return [
			handle_nodes["base_back_left"].position,
			handle_nodes["base_back_right"].position,
			handle_nodes["base_front_right"].position,
			handle_nodes["base_front_left"].position,
			handle_nodes["apex"].position
		]

	var half_base := base_size * 0.5
	return [
		Vector3(-half_base, 0, -half_base),
		Vector3(half_base, 0, -half_base),
		Vector3(half_base, 0, half_base),
		Vector3(-half_base, 0, half_base),
		Vector3(0, pyramid_height, 0)
	]

func _create_pyramid_faces() -> Array:
	return [
		[0, 2, 1],
		[0, 3, 2],
		[0, 1, 4],
		[1, 2, 4],
		[2, 3, 4],
		[3, 0, 4]
	]

func _add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array) -> void:
	var v0: Vector3 = vertices[face[0]]
	var v1: Vector3 = vertices[face[1]]
	var v2: Vector3 = vertices[face[2]]

	var normal := (v1 - v0).cross(v2 - v0).normalized()

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_queer_material(mesh: MeshInstance3D, color: Color) -> void:
	var material := ShaderMaterial.new()
	var shader := load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		mesh.material_override = material
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = color
		fallback.emission_enabled = true
		fallback.emission = color * 0.3
		mesh.material_override = fallback

func set_base_color(color: Color) -> void:
	base_color = color
	if mesh_instance:
		apply_queer_material(mesh_instance, base_color)

func set_pyramid_size(height: float, base: float) -> void:
	pyramid_height = height
	base_size = base
	if handle_nodes.is_empty():
		_create_handles()

	var half := base * 0.5
	if handle_nodes.has("base_back_left"):
		handle_nodes["base_back_left"].position = Vector3(-half, 0.0, -half)
	if handle_nodes.has("base_back_right"):
		handle_nodes["base_back_right"].position = Vector3(half, 0.0, -half)
	if handle_nodes.has("base_front_right"):
		handle_nodes["base_front_right"].position = Vector3(half, 0.0, half)
	if handle_nodes.has("base_front_left"):
		handle_nodes["base_front_left"].position = Vector3(-half, 0.0, half)
	if handle_nodes.has("apex"):
		handle_nodes["apex"].position = Vector3(0.0, height, 0.0)

	_sync_handle_positions()
	_rebuild_pyramid()

func _handles_changed() -> bool:
	if handle_nodes.is_empty():
		return false

	var changed := false
	for name in HANDLE_ORDER:
		if not handle_nodes.has(name):
			continue
		var handle: Node3D = handle_nodes[name]
		var pos := handle.position
		var last_position = last_handle_positions.get(name)
		if last_position == null or not pos.is_equal_approx(last_position):
			changed = true
			last_handle_positions[name] = pos

	return changed

func _sync_handle_positions() -> void:
	for name in handle_nodes.keys():
		last_handle_positions[name] = handle_nodes[name].position
