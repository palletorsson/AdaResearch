extends Node3D
class_name SnapTetrahedron

## Tetrahedron mesh that dynamically updates based on 4 snap point positions
## Has 4 triangular faces connecting all 4 points

@export var tetrahedron_color: Color = Color(0.3, 0.7, 0.9, 0.7)  # Blue with transparency
@export var wireframe_color: Color = Color(1.0, 1.0, 1.0, 1.0)

# References to the 4 snap points
var point_a: Node3D = null
var point_b: Node3D = null
var point_c: Node3D = null
var point_d: Node3D = null

# Visual components
var _mesh_instance: MeshInstance3D
var _last_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _update_threshold: float = 0.001

func _ready() -> void:
	_create_mesh_instance()
	if point_a and point_b and point_c and point_d:
		_update_tetrahedron_mesh()

func setup(p_a: Node3D, p_b: Node3D, p_c: Node3D, p_d: Node3D) -> void:
	point_a = p_a
	point_b = p_b
	point_c = p_c
	point_d = p_d
	
	if is_inside_tree():
		_update_tetrahedron_mesh()

func _create_mesh_instance() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TetrahedronMesh"
	add_child(_mesh_instance)
	
	# Create material
	var material = GridMaterialFactory.make(tetrahedron_color, {
		"wireframe_color": wireframe_color,
		"wireframe_width": 2.0,
		"wireframe_brightness": 2.0,
		"double_sided": true
	})
	_mesh_instance.material_override = material

func _process(_delta: float) -> void:
	if not _are_points_valid():
		queue_free()
		return
	
	if _have_points_moved():
		_update_tetrahedron_mesh()

func _are_points_valid() -> bool:
	return point_a and point_b and point_c and point_d and \
	       is_instance_valid(point_a) and \
	       is_instance_valid(point_b) and \
	       is_instance_valid(point_c) and \
	       is_instance_valid(point_d)

func _have_points_moved() -> bool:
	if not _are_points_valid():
		return false
	
	var positions = [
		point_a.global_position,
		point_b.global_position,
		point_c.global_position,
		point_d.global_position
	]
	
	for i in range(4):
		if _last_positions[i].distance_to(positions[i]) > _update_threshold:
			return true
	
	return false

func _update_tetrahedron_mesh() -> void:
	if not _mesh_instance or not _are_points_valid():
		return
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	var pos_c = point_c.global_position
	var pos_d = point_d.global_position
	
	# Store current positions
	_last_positions = [pos_a, pos_b, pos_c, pos_d]
	
	# Build mesh using SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# A tetrahedron has 4 triangular faces:
	# Face 1: ABC
	# Face 2: ABD
	# Face 3: ACD
	# Face 4: BCD
	
	_add_triangle_face(st, pos_a, pos_b, pos_c)
	_add_triangle_face(st, pos_a, pos_b, pos_d)
	_add_triangle_face(st, pos_a, pos_c, pos_d)
	_add_triangle_face(st, pos_b, pos_c, pos_d)
	
	_mesh_instance.mesh = st.commit()

func _add_triangle_face(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3) -> void:
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	if normal.length() < 0.001:
		return  # Skip degenerate faces
	
	# Front face
	st.set_normal(normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(v0)
	
	st.set_normal(normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1))
	st.add_vertex(v2)
	
	# Back face (double-sided)
	st.set_normal(-normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(v0)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(0.5, 1))
	st.add_vertex(v2)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(v1)

func get_volume() -> float:
	if not _are_points_valid():
		return 0.0
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	var pos_c = point_c.global_position
	var pos_d = point_d.global_position
	
	# Volume = |det(B-A, C-A, D-A)| / 6
	var ab = pos_b - pos_a
	var ac = pos_c - pos_a
	var ad = pos_d - pos_a
	
	# Scalar triple product: ab · (ac × ad)
	var determinant = ab.dot(ac.cross(ad))
	
	return abs(determinant) / 6.0

func get_centroid() -> Vector3:
	if not _are_points_valid():
		return Vector3.ZERO
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	var pos_c = point_c.global_position
	var pos_d = point_d.global_position
	
	return (pos_a + pos_b + pos_c + pos_d) / 4.0

func set_tetrahedron_color(color: Color) -> void:
	tetrahedron_color = color
	if _mesh_instance:
		var material = GridMaterialFactory.make(color, {
			"wireframe_color": wireframe_color,
			"wireframe_width": 2.0,
			"wireframe_brightness": 2.0,
			"double_sided": true
		})
		_mesh_instance.material_override = material

