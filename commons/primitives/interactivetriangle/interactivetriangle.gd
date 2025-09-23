# SplitQuad.gd - Creates a quad split into two triangles with different colors
extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.5  # Half the original size
@export var sphere_y_offset: float = -5.9

## Freeze behavior options
@export var alter_freeze : bool = false  # Keep triangle fixed; points move freely

# Two triangle mesh instances - one pink, one black
var triangle_mesh_pink: MeshInstance3D
var triangle_mesh_black: MeshInstance3D
var grab_spheres: Array[Node3D] = []

# Quad has 4 corner points that define 2 triangles (horizontal/flat)
var vertex_positions: Array[Vector3] = [
	Vector3(-1.0, sphere_y_offset, -1.0),  # Bottom-left (0) - moved down 2 meters
	Vector3(1.0, sphere_y_offset, 1.0),    # Bottom-right (1) - moved down 2 meters
	Vector3(1.0,  sphere_y_offset, -1.0),   # Top-right (2) - moved down 2 meters
	Vector3(-1.0, sphere_y_offset, 1.0)    # Top-left (3) - moved down 2 meters
]

# Define the two triangles from the quad
# Triangle 1: Bottom-left, Bottom-right, Top-right (indices 0,1,2)
# Triangle 2: Bottom-left, Top-right, Top-left (indices 0,2,3)
var triangle1_indices: Array[int] = [0, 1, 2]  # Pink triangle
var triangle2_indices: Array[int] = [0, 2, 3]  # Black triangle

# Grab sphere scene to instantiate
var grab_sphere_scene: PackedScene

# Pickup state tracking for alternating freeze behavior
var _pickup_count : int = 0
var _should_freeze_this_pickup : bool = false

func _ready():
	# Load the grab sphere with text scene
	grab_sphere_scene = preload("res://commons/primitives/point/grab_sphere_point_with_text.tscn")
	
	create_triangle_meshes()
	create_grab_spheres()
	update_triangle_meshes()
	print_help()

func create_triangle_meshes():
	# Create pink triangle mesh
	triangle_mesh_pink = MeshInstance3D.new()
	triangle_mesh_pink.name = "TriangleMesh_Pink"
	apply_triangle_material(triangle_mesh_pink, Color.DEEP_PINK)
	add_child(triangle_mesh_pink)
	
	# Create black triangle mesh
	triangle_mesh_black = MeshInstance3D.new()
	triangle_mesh_black.name = "TriangleMesh_Black"
	apply_triangle_material(triangle_mesh_black, Color.BLACK)
	add_child(triangle_mesh_black)

func create_grab_spheres():
	# Create four grabbable spheres at quad corners
	for i in range(vertex_positions.size()):
		var sphere_instance = grab_sphere_scene.instantiate()
		sphere_instance.name = "GrabSphere_" + str(i)
		
		# Add to scene first, then set position
		add_child(sphere_instance)
		sphere_instance.position = vertex_positions[i]
		
		# Set sphere color and enhance visibility
		var mesh_instance = sphere_instance.get_node("MeshInstance3D")
		if mesh_instance:
			mesh_instance.scale = Vector3.ONE * sphere_size_multiplier
			
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				# Transparent green marble properties
				material.albedo_color = vertex_color
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.emission_enabled = true
				material.emission = Color(0.1, 0.4, 0.2) * 0.3  # Subtle green glow
				material.roughness = 0.1  # Very smooth like marble
				material.metallic = 0.0   # Non-metallic
				material.refraction = 0.05  # Slight refraction for glass-like effect
				
		# Connect signals if available
		if sphere_instance.has_signal("picked_up"):
			sphere_instance.connect("picked_up", _on_sphere_picked_up.bind(i))
		if sphere_instance.has_signal("dropped"):
			sphere_instance.connect("dropped", _on_sphere_dropped.bind(i))
		
		grab_spheres.append(sphere_instance)
		sphere_instance.set_meta("vertex_index", i)

func update_triangle_meshes():
	# Update both triangle meshes
	update_single_triangle_mesh(triangle_mesh_pink, triangle1_indices)
	update_single_triangle_mesh(triangle_mesh_black, triangle2_indices)

func update_single_triangle_mesh(mesh_instance: MeshInstance3D, indices: Array[int]):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Get the three vertices for this triangle
	var triangle_vertices = [
		vertex_positions[indices[0]],
		vertex_positions[indices[1]], 
		vertex_positions[indices[2]]
	]
	
	# Create the triangle face
	add_triangle_with_normal(st, triangle_vertices, [0, 1, 2])
	
	# Commit the mesh
	mesh_instance.mesh = st.commit()

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Add vertices with normal and UV coordinates (front face)
	st.set_normal(normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)
	
	st.set_normal(normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(v2)
	
	# Add the back face for double-sided rendering
	st.set_normal(-normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(v2)
	
	st.set_normal(-normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)

func _on_sphere_picked_up(vertex_index: int, _pickable):
	print("DEBUG PICKUP")
	if _pickable and _pickable.has_method("set_freeze_enabled"):
		_pickable.set_freeze_enabled(false)

func _on_sphere_dropped(vertex_index: int, _pickable):
	# Always freeze on drop so the point stays where you leave it
	if _pickable and _pickable.has_method("set_freeze_enabled"):
		_pickable.set_freeze_enabled(true)
		
	
func _process(delta):
	_sync_vertices_from_spheres()



func _sync_vertices_from_spheres():
	var needs_update = false
	
	for i in range(grab_spheres.size()):
		var sphere = grab_spheres[i]
		if sphere.position != vertex_positions[i]:
			vertex_positions[i] = sphere.position
			needs_update = true
	
	if needs_update:
		update_triangle_meshes()

func apply_triangle_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		
		# Use the input color parameter to determine which triangle gets which color
		var chosen_color: Color
	
		# Fallback to random selection for other colors
		var rand = randi() % 3
		print("interative triangle: random " + str(rand) )		
		if rand == 0:
			chosen_color = Color.BLACK
		elif rand == 1:
			chosen_color = Color.DEEP_PINK
		else:  # rand == 2
			chosen_color = Color.RED
		
		material.set_shader_parameter("wireframe_color", Color.DARK_VIOLET)
		material.set_shader_parameter("fill_color", chosen_color)
		mesh_instance.material_override = material


	else: 
		print("interative triangle: no shader")



func reset_to_square():
	# Reset to perfect square (horizontal) - 2 meters down
	vertex_positions = [
		Vector3(-1.0, -2.0, -1.0),  # Bottom-left
		Vector3(1.0, -2.0, 1.0),    # Bottom-right
		Vector3(1.0, -2.0, -1.0),   # Top-right
		Vector3(-1.0, -2.0, 1.0)    # Top-left
	]
	update_sphere_positions()
	print("Reset to square shape")

func reset_to_quad():
	# Reset to rectangular quad (horizontal) - 2 meters down
	vertex_positions = [
		Vector3(-1.5, -2.0, -0.8),  # Bottom-left
		Vector3(1.5, -2.0, 0.8),    # Bottom-right
		Vector3(1.5, -2.0, -0.8),   # Top-right
		Vector3(-1.5, -2.0, 0.8)    # Top-left
	]
	update_sphere_positions()
	print("Reset to rectangular quad")

func reset_to_diamond():
	# Reset to diamond shape (horizontal) - 2 meters down
	vertex_positions = [
		Vector3(0.0, -2.0, -1.2),   # Bottom
		Vector3(1.2, -2.0, 0.0),    # Right
		Vector3(0.0, -2.0, 1.2),    # Top
		Vector3(-1.2, -2.0, 0.0)    # Left
	]
	update_sphere_positions()
	print("Reset to diamond shape")

func reset_to_trapezoid():
	# Reset to trapezoid shape (horizontal) - 2 meters down
	vertex_positions = [
		Vector3(-1.2, -2.0, -1.0),  # Bottom-left
		Vector3(1.2, -2.0, 1.0),    # Bottom-right
		Vector3(0.8, -2.0, -1.0),   # Top-right
		Vector3(-0.8, -2.0, 1.0)    # Top-left
	]
	update_sphere_positions()
	print("Reset to trapezoid shape")

func arrange_in_boat_formation():
	# Arrange spheres in a boat-like formation with slight offsets (horizontal)
	vertex_positions = [
		Vector3(-1.0, 0.0, -0.1),  # Bottom-left (slightly back)
		Vector3(1.0, 0.0, 0.1),    # Bottom-right (slightly forward)
		Vector3(0.8, 0.0, 0.0),    # Top-right (centered)
		Vector3(-0.8, 0.0, -0.05)  # Top-left (slightly back)
	]
	update_sphere_positions()
	print("Arranged spheres in boat formation")

func update_sphere_positions():
	for i in range(grab_spheres.size()):
		if i < vertex_positions.size():
			grab_spheres[i].position = vertex_positions[i]
	update_triangle_meshes()

func set_vertex_color(color: Color):
	vertex_color = color
	for sphere in grab_spheres:
		var mesh_instance = sphere.get_node("MeshInstance3D")
		if mesh_instance:
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				# Maintain transparent green marble properties
				material.albedo_color = vertex_color
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.emission = Color(0.1, 0.4, 0.2) * 0.3  # Subtle green glow
				material.roughness = 0.1  # Very smooth like marble
				material.metallic = 0.0   # Non-metallic
				material.refraction = 0.05  # Slight refraction for glass-like effect

func print_help():
	print("=== Split Quad Controls ===")
	print("Mouse: Drag the corner spheres to reshape the quad")
	print("R: Reset to square")
	print("Q: Reset to rectangular quad")
	print("D: Reset to diamond")
	print("T: Reset to trapezoid")
	print("B: Arrange spheres in boat formation")
	print("Pink Triangle: Bottom-left → Bottom-right → Top-right")
	print("Black Triangle: Bottom-left → Top-right → Top-left")
	print("============================")

func get_quad_info() -> Dictionary:
	return {
		"vertices": vertex_positions,
		"pink_triangle_area": get_triangle_area(triangle1_indices),
		"black_triangle_area": get_triangle_area(triangle2_indices),
		"total_area": get_triangle_area(triangle1_indices) + get_triangle_area(triangle2_indices)
	}

func get_triangle_area(indices: Array[int]) -> float:
	var v0 = vertex_positions[indices[0]]
	var v1 = vertex_positions[indices[1]]
	var v2 = vertex_positions[indices[2]]
	
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var cross = edge1.cross(edge2)
	return cross.length() * 0.5
