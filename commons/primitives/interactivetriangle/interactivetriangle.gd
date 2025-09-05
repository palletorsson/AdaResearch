# InteractiveTriangle.gd - Triangle with grabbable corner spheres
extends Node3D

var base_color: Color = Color(0.8, 0.3, 0.9)  # Purple triangle
var vertex_color: Color = Color(1.0, 0.8, 0.2)  # Golden spheres
var triangle_mesh_instance: MeshInstance3D
var grab_spheres: Array[Node3D] = []

# Triangle vertices (can be modified by moving spheres)
var vertex_positions: Array[Vector3] = [
	Vector3(-1.0, 0.0, 0.0),   # Left vertex
	Vector3(1.0, 0.0, 0.0),    # Right vertex  
	Vector3(0.0, 1.5, 0.0)     # Top vertex
]

# Grab sphere scene to instantiate
var grab_sphere_scene: PackedScene

func _ready():
	# Load the grab sphere scene
	grab_sphere_scene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
	
	create_triangle_mesh()
	create_grab_spheres()
	update_triangle_mesh()

func create_triangle_mesh():
	# Create the triangle mesh instance
	triangle_mesh_instance = MeshInstance3D.new()
	triangle_mesh_instance.name = "TriangleMesh"
	apply_triangle_material(triangle_mesh_instance, base_color)
	add_child(triangle_mesh_instance)

func create_grab_spheres():
	# Create three grabbable spheres at triangle vertices
	for i in range(vertex_positions.size()):
		var sphere_instance = grab_sphere_scene.instantiate()
		sphere_instance.name = "GrabSphere_" + str(i)
		sphere_instance.position = vertex_positions[i]
		
		# Set sphere color
		var mesh_instance = sphere_instance.get_node("MeshInstance3D")
		if mesh_instance:
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				material.albedo_color = vertex_color
				material.emission_enabled = true
				material.emission = vertex_color * 0.3
		
		# Connect to the sphere's position change
		sphere_instance.connect("position_changed", _on_sphere_moved.bind(i))
		
		add_child(sphere_instance)
		grab_spheres.append(sphere_instance)
		
		# Store the vertex index in the sphere for reference
		sphere_instance.set_meta("vertex_index", i)

func update_triangle_mesh():
	# Update the triangle mesh based on current vertex positions
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create the triangle face
	add_triangle_with_normal(st, vertex_positions, [0, 1, 2])
	
	# Commit the mesh
	triangle_mesh_instance.mesh = st.commit()

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Add vertices with normal and UV coordinates
	st.set_normal(normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.set_color(base_color)
	st.add_vertex(v0)
	
	st.set_normal(normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.set_color(base_color)
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.set_color(base_color)
	st.add_vertex(v2)
	
	# Add the back face for double-sided rendering
	st.set_normal(-normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.set_color(base_color)
	st.add_vertex(v0)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.set_color(base_color)
	st.add_vertex(v2)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.set_color(base_color)
	st.add_vertex(v1)

func _on_sphere_moved(vertex_index: int):
	# Called when a grab sphere is moved
	if vertex_index < grab_spheres.size():
		var sphere = grab_spheres[vertex_index]
		vertex_positions[vertex_index] = sphere.global_position
		update_triangle_mesh()
		
		# Print debug info
		print("Vertex ", vertex_index, " moved to: ", vertex_positions[vertex_index])

func _process(delta):
	# Continuously update vertex positions from sphere positions
	# This ensures the triangle updates even if the sphere signal doesn't fire
	var needs_update = false
	
	for i in range(grab_spheres.size()):
		var sphere = grab_spheres[i]
		if sphere.global_position != vertex_positions[i]:
			vertex_positions[i] = sphere.global_position
			needs_update = true
	
	if needs_update:
		update_triangle_mesh()

func apply_triangle_material(mesh_instance: MeshInstance3D, color: Color):
	# Create shader material using the SimpleGrid shader
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		
		# Set shader parameters for triangle
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 2.0)
		material.set_shader_parameter("edge_sharpness", 3.0)
		material.set_shader_parameter("emission_strength", 0.6)
		
		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader not found
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.vertex_color_use_as_albedo = true
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.2
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
		standard_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.material_override = standard_material

func set_triangle_color(color: Color):
	base_color = color
	apply_triangle_material(triangle_mesh_instance, base_color)

func set_vertex_color(color: Color):
	vertex_color = color
	# Update all sphere colors
	for sphere in grab_spheres:
		var mesh_instance = sphere.get_node("MeshInstance3D")
		if mesh_instance:
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				material.albedo_color = vertex_color
				material.emission = vertex_color * 0.3

func reset_triangle():
	# Reset triangle to default shape
	vertex_positions = [
		Vector3(-1.0, 0.0, 0.0),   # Left vertex
		Vector3(1.0, 0.0, 0.0),    # Right vertex  
		Vector3(0.0, 1.5, 0.0)     # Top vertex
	]
	
	# Move spheres back to default positions
	for i in range(grab_spheres.size()):
		grab_spheres[i].global_position = vertex_positions[i]
	
	update_triangle_mesh()

func get_triangle_area() -> float:
	# Calculate triangle area using cross product
	var edge1 = vertex_positions[1] - vertex_positions[0]
	var edge2 = vertex_positions[2] - vertex_positions[0]
	var cross = edge1.cross(edge2)
	return cross.length() * 0.5

func get_triangle_perimeter() -> float:
	# Calculate triangle perimeter
	var side1 = vertex_positions[0].distance_to(vertex_positions[1])
	var side2 = vertex_positions[1].distance_to(vertex_positions[2])
	var side3 = vertex_positions[2].distance_to(vertex_positions[0])
	return side1 + side2 + side3

func get_triangle_centroid() -> Vector3:
	# Calculate triangle centroid (center of mass)
	return (vertex_positions[0] + vertex_positions[1] + vertex_positions[2]) / 3.0

# Alternative implementation if grab sphere doesn't have position_changed signal
func setup_sphere_monitoring():
	# Monitor sphere positions every frame if signals aren't available
	# This is handled in _process() function above
	pass
