extends Node3D

## Editable tetrahedron with draggable vertex handles
## A tetrahedron has 4 vertices and 4 triangular faces

const HANDLE_SCENE := preload("res://commons/primitives/point/grab_sphere_point.tscn")
const HANDLE_ORDER := [
	"base_back",
	"base_front_left",
	"base_front_right",
	"apex"
]

@export var base_color: Color = Color(0.4, 0.8, 1.0)  # Light blue
@export var tetra_height: float = 0.8
@export var base_size: float = 0.6

var mesh_instance: MeshInstance3D
var handle_nodes: Dictionary = {}
var last_handle_positions: Dictionary = {}

func _ready():
	_create_handles()
	_rebuild_tetrahedron()
	set_process(true)

func _process(_delta: float) -> void:
	if _handles_changed():
		_rebuild_tetrahedron()

func _create_handles() -> void:
	if not handle_nodes.is_empty():
		return

	# Regular tetrahedron base is an equilateral triangle
	var half_base := base_size * 0.5
	var height_offset := base_size * sqrt(3.0) / 6.0  # Distance from center to edge

	var defaults := {
		# Base triangle vertices (equilateral triangle on Y=0 plane)
		"base_back": Vector3(0.0, 0.0, -base_size * sqrt(3.0) / 3.0),
		"base_front_left": Vector3(-half_base, 0.0, height_offset),
		"base_front_right": Vector3(half_base, 0.0, height_offset),
		# Apex above center
		"apex": Vector3(0.0, tetra_height, 0.0)
	}

	for handle_name in HANDLE_ORDER:
		var handle := HANDLE_SCENE.instantiate()
		handle.name = handle_name
		handle.position = defaults.get(handle_name, Vector3.ZERO)
		handle.alter_freeze = false
		handle.freeze = true
		handle.set_meta("tetrahedron_handle", handle_name)
		add_child(handle)
		handle_nodes[handle_name] = handle
		if owner:
			handle.owner = owner

	_sync_handle_positions()

func _rebuild_tetrahedron() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices := _get_current_vertices()
	var faces := _create_tetrahedron_faces()

	for face in faces:
		_add_triangle_with_normal(st, vertices, face)

	var mesh := st.commit()
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Tetrahedron"
		add_child(mesh_instance)
		if owner:
			mesh_instance.owner = owner
		apply_material(mesh_instance, base_color)

	mesh_instance.mesh = mesh
	_sync_handle_positions()

func _get_current_vertices() -> Array:
	if handle_nodes.size() == HANDLE_ORDER.size():
		return [
			handle_nodes["base_back"].position,
			handle_nodes["base_front_left"].position,
			handle_nodes["base_front_right"].position,
			handle_nodes["apex"].position
		]

	# Default regular tetrahedron
	var half_base := base_size * 0.5
	var height_offset := base_size * sqrt(3.0) / 6.0
	return [
		Vector3(0.0, 0.0, -base_size * sqrt(3.0) / 3.0),
		Vector3(-half_base, 0.0, height_offset),
		Vector3(half_base, 0.0, height_offset),
		Vector3(0.0, tetra_height, 0.0)
	]

func _create_tetrahedron_faces() -> Array:
	# 4 triangular faces
	# Vertices: 0=back, 1=front_left, 2=front_right, 3=apex
	return [
		[0, 2, 1],  # Base (bottom face) - wound CCW from below
		[0, 1, 3],  # Back-left face
		[1, 2, 3],  # Front face
		[2, 0, 3]   # Back-right face
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

func apply_material(mesh: MeshInstance3D, color: Color) -> void:
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
		fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = fallback

func set_base_color(color: Color) -> void:
	base_color = color
	if mesh_instance:
		apply_material(mesh_instance, base_color)

func set_tetrahedron_size(height: float, base: float) -> void:
	tetra_height = height
	base_size = base
	if handle_nodes.is_empty():
		_create_handles()

	var half_base := base * 0.5
	var height_offset := base * sqrt(3.0) / 6.0

	if handle_nodes.has("base_back"):
		handle_nodes["base_back"].position = Vector3(0.0, 0.0, -base * sqrt(3.0) / 3.0)
	if handle_nodes.has("base_front_left"):
		handle_nodes["base_front_left"].position = Vector3(-half_base, 0.0, height_offset)
	if handle_nodes.has("base_front_right"):
		handle_nodes["base_front_right"].position = Vector3(half_base, 0.0, height_offset)
	if handle_nodes.has("apex"):
		handle_nodes["apex"].position = Vector3(0.0, height, 0.0)

	_sync_handle_positions()
	_rebuild_tetrahedron()

func _handles_changed() -> bool:
	if handle_nodes.is_empty():
		return false

	var changed := false
	for handle_name in HANDLE_ORDER:
		if not handle_nodes.has(handle_name):
			continue
		var handle: Node3D = handle_nodes[handle_name]
		var pos := handle.position
		var last_position = last_handle_positions.get(handle_name)
		if last_position == null or not pos.is_equal_approx(last_position):
			changed = true
			last_handle_positions[handle_name] = pos

	return changed

func _sync_handle_positions() -> void:
	for handle_name in handle_nodes.keys():
		last_handle_positions[handle_name] = handle_nodes[handle_name].position

func get_vertices() -> Array[Vector3]:
	var verts: Array[Vector3] = []
	for v in _get_current_vertices():
		verts.append(v)
	return verts

func get_volume() -> float:
	var v := _get_current_vertices()
	# Volume of tetrahedron = |det([v1-v0, v2-v0, v3-v0])| / 6
	var a: Vector3 = v[1] - v[0]
	var b: Vector3 = v[2] - v[0]
	var c: Vector3 = v[3] - v[0]
	return abs(a.dot(b.cross(c))) / 6.0
