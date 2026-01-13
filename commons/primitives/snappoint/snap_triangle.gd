extends Node3D
class_name SnapTriangle

## Triangle mesh that dynamically updates based on 3 snap point positions
## Maintains references to point handles - never hides or destroys them

@export var triangle_color: Color = Color(0.9, 0.3, 0.7, 0.05)  # Pink with high transparency
@export var wireframe_color: Color = Color(1.0, 1.0, 1.0, 1.0)

# References to the 3 snap points
var point_a: Node3D = null
var point_b: Node3D = null
var point_c: Node3D = null

# Visual components
var _mesh_instance: MeshInstance3D
var _last_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _update_threshold: float = 0.001  # Only update if points moved more than 1mm

func _ready() -> void:
	_create_mesh_instance()
	if point_a and point_b and point_c:
		_update_triangle_mesh()

func setup(p_a: Node3D, p_b: Node3D, p_c: Node3D) -> void:
	point_a = p_a
	point_b = p_b
	point_c = p_c
	
	if is_inside_tree():
		_update_triangle_mesh()

func _create_mesh_instance() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TriangleMesh"
	add_child(_mesh_instance)
	
	# Create transparent material using StandardMaterial3D for better transparency support
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = triangle_color
	material.metallic = 0.2
	material.roughness = 0.8
	material.emission_enabled = true
	material.emission = triangle_color
	material.emission_energy_multiplier = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # For better transparency
	
	_mesh_instance.material_override = material

func _process(_delta: float) -> void:
	# Check if all points are valid
	if not _are_points_valid():
		queue_free()
		return
	
	# Check if any point has moved significantly
	if _have_points_moved():
		_update_triangle_mesh()

func _are_points_valid() -> bool:
	return point_a and point_b and point_c and \
	       is_instance_valid(point_a) and \
	       is_instance_valid(point_b) and \
	       is_instance_valid(point_c)

func _have_points_moved() -> bool:
	if not _are_points_valid():
		return false
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	var pos_c = point_c.global_position
	
	if _last_positions[0].distance_to(pos_a) > _update_threshold:
		return true
	if _last_positions[1].distance_to(pos_b) > _update_threshold:
		return true
	if _last_positions[2].distance_to(pos_c) > _update_threshold:
		return true
	
	return false

func _update_triangle_mesh() -> void:
	if not _mesh_instance or not _are_points_valid():
		return
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	var pos_c = point_c.global_position
	
	# Store current positions
	_last_positions = [pos_a, pos_b, pos_c]
	
	# Build mesh using SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Calculate normal
	var edge1 = pos_b - pos_a
	var edge2 = pos_c - pos_a
	var normal = edge1.cross(edge2).normalized()
	
	if normal.length() < 0.001:
		# Degenerate triangle (points are collinear)
		return
	
	# Add front face
	st.set_normal(normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(pos_a)
	
	st.set_normal(normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(pos_b)
	
	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1))
	st.add_vertex(pos_c)
	
	# Add back face (double-sided)
	st.set_normal(-normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(pos_a)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(0.5, 1))
	st.add_vertex(pos_c)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(pos_b)
	
	_mesh_instance.mesh = st.commit()

func get_area() -> float:
	if not _are_points_valid():
		return 0.0
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	var pos_c = point_c.global_position
	
	var edge1 = pos_b - pos_a
	var edge2 = pos_c - pos_a
	var cross = edge1.cross(edge2)
	
	return cross.length() * 0.5

func get_centroid() -> Vector3:
	if not _are_points_valid():
		return Vector3.ZERO
	
	var pos_a = point_a.global_position
	var pos_b = point_b.global_position
	var pos_c = point_c.global_position
	
	return (pos_a + pos_b + pos_c) / 3.0

func set_triangle_color(color: Color) -> void:
	triangle_color = color
	if _mesh_instance:
		var material = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = color
		material.metallic = 0.2
		material.roughness = 0.8
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.5
		material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # For better transparency
		_mesh_instance.material_override = material

