extends Node3D

const HANDLE_SCENE := preload("res://commons/primitives/point/grab_sphere_point.tscn")
const HANDLE_ORDER := [
	"back_bottom_left",
	"back_bottom_right",
	"back_top_right",
	"back_top_left",
	"front_bottom_left",
	"front_bottom_right",
	"front_top_right",
	"front_top_left"
]

var base_color: Color = Color(1.0, 0.7, 0.9)
var cube_size: float = 0.5

var mesh_instance: MeshInstance3D
var handle_nodes: Dictionary = {}
var last_handle_positions: Dictionary = {}

func _ready():
	_create_handles()
	_rebuild_cube()
	set_process(true)

func _process(_delta: float) -> void:
	if _handles_changed():
		_rebuild_cube()

func _create_handles() -> void:
	if not handle_nodes.is_empty():
		return

	var half := cube_size * 0.5
	var defaults := {
		"back_bottom_left": Vector3(-half, -half, -half),
		"back_bottom_right": Vector3(half, -half, -half),
		"back_top_right": Vector3(half, half, -half),
		"back_top_left": Vector3(-half, half, -half),
		"front_bottom_left": Vector3(-half, -half, half),
		"front_bottom_right": Vector3(half, -half, half),
		"front_top_right": Vector3(half, half, half),
		"front_top_left": Vector3(-half, half, half)
	}

	for name in HANDLE_ORDER:
		var handle := HANDLE_SCENE.instantiate()
		handle.name = name
		handle.position = defaults.get(name, Vector3.ZERO)
		handle.alter_freeze = false
		handle.freeze = true
		handle.set_meta("cube_handle", name)
		add_child(handle)
		handle_nodes[name] = handle
		if owner:
			handle.owner = owner

	_sync_handle_positions()

func _rebuild_cube() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices := _get_current_vertices()
	var faces := _create_cube_faces()

	for face in faces:
		_add_triangle_with_normal(st, vertices, face)

	var mesh := st.commit()
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "EditableCube"
		add_child(mesh_instance)
		if owner:
			mesh_instance.owner = owner
		apply_cube_material(mesh_instance, base_color)

	mesh_instance.mesh = mesh
	_sync_handle_positions()

func _get_current_vertices() -> Array:
	if handle_nodes.size() == HANDLE_ORDER.size():
		return [
			handle_nodes["back_bottom_left"].position,
			handle_nodes["back_bottom_right"].position,
			handle_nodes["back_top_right"].position,
			handle_nodes["back_top_left"].position,
			handle_nodes["front_bottom_left"].position,
			handle_nodes["front_bottom_right"].position,
			handle_nodes["front_top_right"].position,
			handle_nodes["front_top_left"].position
		]

	var half := cube_size * 0.5
	return [
		Vector3(-half, -half, -half),
		Vector3(half, -half, -half),
		Vector3(half, half, -half),
		Vector3(-half, half, -half),
		Vector3(-half, -half, half),
		Vector3(half, -half, half),
		Vector3(half, half, half),
		Vector3(-half, half, half)
	]

func _create_cube_faces() -> Array:
	# Returns vertex indices for each triangular face of the cube
	# Each quad face is split into two triangles
	return [
		# Back face (indices 0,1,2,3)
		[0, 2, 1], [0, 3, 2],
		# Front face (indices 4,5,6,7)
		[4, 5, 6], [4, 6, 7],
		# Bottom face (0,1,5,4)
		[0, 1, 5], [0, 5, 4],
		# Top face (3,2,6,7)
		[3, 6, 2], [3, 7, 6],
		# Left face (0,4,7,3)
		[0, 4, 7], [0, 7, 3],
		# Right face (1,2,6,5)
		[1, 6, 5], [1, 2, 6]
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

func apply_cube_material(mesh: MeshInstance3D, color: Color) -> void:
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
		apply_cube_material(mesh_instance, base_color)

func set_cube_size(size: float) -> void:
	cube_size = size
	if handle_nodes.is_empty():
		_create_handles()

	var half := size * 0.5
	if handle_nodes.has("back_bottom_left"):
		handle_nodes["back_bottom_left"].position = Vector3(-half, -half, -half)
	if handle_nodes.has("back_bottom_right"):
		handle_nodes["back_bottom_right"].position = Vector3(half, -half, -half)
	if handle_nodes.has("back_top_right"):
		handle_nodes["back_top_right"].position = Vector3(half, half, -half)
	if handle_nodes.has("back_top_left"):
		handle_nodes["back_top_left"].position = Vector3(-half, half, -half)
	if handle_nodes.has("front_bottom_left"):
		handle_nodes["front_bottom_left"].position = Vector3(-half, -half, half)
	if handle_nodes.has("front_bottom_right"):
		handle_nodes["front_bottom_right"].position = Vector3(half, -half, half)
	if handle_nodes.has("front_top_right"):
		handle_nodes["front_top_right"].position = Vector3(half, half, half)
	if handle_nodes.has("front_top_left"):
		handle_nodes["front_top_left"].position = Vector3(-half, half, half)

	_sync_handle_positions()
	_rebuild_cube()

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
