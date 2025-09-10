# VRCubeDeformer.gd - Deformable cube with grab spheres at corners
extends Node3D

@export var base_color: Color = Color(1.0, 0.4, 0.7)  # Pink cube color
@export var hover_color: Color = Color(0.4, 0.8, 1.0)

var is_hovered: bool = false
var mesh_instance: MeshInstance3D
var grab_spheres: Array[Node3D] = []
var original_vertices: Array[Vector3] = []
var current_vertices: Array[Vector3] = []
var is_ready_complete: bool = false

# Cube corner indices for grab spheres
var corner_indices = [0, 1, 2, 3, 4, 5, 6, 7]

func _ready():
	call_deferred("setup_complete_cube")

func setup_complete_cube():
	create_vr_cube()
	await get_tree().process_frame
	create_grab_spheres()
	await get_tree().process_frame
	is_ready_complete = true
	print("Cube setup complete - should see cube and spheres now")

func create_vr_cube():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Regular cube dimensions
	var size = 0.5  # Half size for each dimension
	
	# Store original vertices
	original_vertices = [
		Vector3(-size, -size, size),    # 0 - bottom left front
		Vector3(size, -size, size),     # 1 - bottom right front
		Vector3(size, size, size),      # 2 - top right front
		Vector3(-size, size, size),     # 3 - top left front
		Vector3(-size, -size, -size),   # 4 - bottom left back
		Vector3(size, -size, -size),    # 5 - bottom right back
		Vector3(size, size, -size),     # 6 - top right back
		Vector3(-size, size, -size)     # 7 - top left back
	]
	
	# Copy to current vertices for deformation
	current_vertices = original_vertices.duplicate()
	
	# Cube faces (each face made of 2 triangles)
	var faces = [
		# Front face
		[0, 1, 2], [0, 2, 3],
		# Back face
		[5, 4, 7], [5, 7, 6],
		# Left face
		[4, 0, 3], [4, 3, 7],
		# Right face
		[1, 5, 6], [1, 6, 2],
		# Top face
		[3, 2, 6], [3, 6, 7],
		# Bottom face
		[4, 5, 1], [4, 1, 0]
	]
	
	# Add faces with normals and UVs
	for face in faces:
		add_triangle_with_normal_and_uv(st, current_vertices, face)
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "VRCube"
	apply_cube_material(mesh_instance, base_color)
	add_child(mesh_instance)
	
	# Add hover detection area
	var hover_area = Area3D.new()
	var hover_collision = CollisionShape3D.new()
	var hover_box = BoxShape3D.new()
	hover_box.size = Vector3(size * 2.2, size * 2.2, size * 2.2)  # Slightly larger for easier hovering
	hover_collision.shape = hover_box
	hover_area.add_child(hover_collision)
	hover_area.name = "HoverArea"
	add_child(hover_area)
	
	# Connect hover signals
	hover_area.mouse_entered.connect(_on_hover_start)
	hover_area.mouse_exited.connect(_on_hover_end)
	
	print("Created cube mesh")

func create_grab_spheres():
	print("Creating grab spheres...")
	
	# Load the grab sphere point scene
	var grab_sphere_scene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
	
	for i in range(8):
		var sphere_node = grab_sphere_scene.instantiate()
		sphere_node.name = "GrabSphere_" + str(i)
		
		# Position at corner
		sphere_node.position = current_vertices[i]
		sphere_node.freeze = true		
		# Add to this node (cube) as child
		add_child(sphere_node)
		grab_spheres.append(sphere_node)

		# Connect signals for dragging if they exist
		if sphere_node.has_signal("picked_up"):
			sphere_node.picked_up.connect(_on_sphere_picked_up.bind(i))
		if sphere_node.has_signal("dropped"):
			sphere_node.dropped.connect(_on_sphere_dropped.bind(i))
		
		print("Created sphere ", i, " at position ", current_vertices[i])

func _on_sphere_picked_up(vertex_index: int, _pickable = null):
	print("Sphere ", vertex_index, " picked up")

func _on_sphere_dropped(vertex_index: int, _pickable = null):
	if vertex_index < grab_spheres.size():
		var sphere = grab_spheres[vertex_index]
		var drop_position = sphere.position
		
		# Update the vertex position based on the sphere's new position
		current_vertices[vertex_index] = drop_position
		update_cube_mesh()
		print("Sphere ", vertex_index, " dropped at: ", drop_position)

func _process(_delta):
	if not is_ready_complete:
		return
	
	# Continuously track sphere positions for real-time deformation
	var needs_update = false
	for i in range(grab_spheres.size()):
		if i < current_vertices.size():
			var sphere = grab_spheres[i]
			var sphere_pos = sphere.position
			
			# Check if sphere moved significantly
			if current_vertices[i].distance_to(sphere_pos) > 0.001:
				current_vertices[i] = sphere_pos
				needs_update = true
	
	if needs_update:
		update_cube_mesh()

func update_cube_mesh():
	if not mesh_instance:
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Cube faces using updated vertices
	var faces = [
		# Front face
		[0, 1, 2], [0, 2, 3],
		# Back face
		[5, 4, 7], [5, 7, 6],
		# Left face
		[4, 0, 3], [4, 3, 7],
		# Right face
		[1, 5, 6], [1, 6, 2],
		# Top face
		[3, 2, 6], [3, 6, 7],
		# Bottom face
		[4, 5, 1], [4, 1, 0]
	]
	
	# Add faces with updated vertices
	for face in faces:
		add_triangle_with_normal_and_uv(st, current_vertices, face)
	
	mesh_instance.mesh = st.commit()

func add_triangle_with_normal_and_uv(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Simple UV mapping
	var uv0 = Vector2(0, 0)
	var uv1 = Vector2(1, 0)
	var uv2 = Vector2(1, 1)
	
	# Add vertices with normals and UVs
	st.set_normal(normal)
	st.set_uv(uv0)
	st.add_vertex(v0)
	
	st.set_normal(normal)
	st.set_uv(uv1)
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(uv2)
	st.add_vertex(v2)

func apply_cube_material(mesh_instance: MeshInstance3D, color: Color):
	# Use standard material for visibility
	var standard_material = StandardMaterial3D.new()
	standard_material.albedo_color = color
	standard_material.emission_enabled = true
	standard_material.emission = color * 0.3
	mesh_instance.material_override = standard_material

func _on_hover_start():
	is_hovered = true
	animate_hover(true)

func _on_hover_end():
	is_hovered = false
	animate_hover(false)

func animate_hover(hover: bool):
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if hover:
		# Hover effects
		tween.tween_property(self, "scale", Vector3(1.1, 1.1, 1.1), 0.2)
		apply_cube_material(mesh_instance, hover_color)
	else:
		# Return to normal
		tween.tween_property(self, "scale", Vector3.ONE, 0.2)
		apply_cube_material(mesh_instance, base_color)

func reset_cube():
	# Reset cube to original shape
	current_vertices = original_vertices.duplicate()
	
	# Reset grab sphere positions
	for i in range(grab_spheres.size()):
		if i < corner_indices.size():
			grab_spheres[i].position = current_vertices[corner_indices[i]]
	
	update_cube_mesh()

func set_base_color(color: Color):
	base_color = color
	if mesh_instance and not is_hovered:
		apply_cube_material(mesh_instance, base_color)

# VR interaction methods
func activate():
	# Called when VR controller selects this cube
	print("Cube activated")
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.9, 0.9, 0.9), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)
	
	# Emit custom signal
	cube_activated.emit()

signal cube_activated()

# Helper function to position cube in VR space
func set_vr_position(pos: Vector3):
	position = pos

# Test function to manually move a corner and see deformation
func test_deform_corner(corner_index: int, new_pos: Vector3):
	if corner_index < current_vertices.size():
		current_vertices[corner_index] = new_pos
		if corner_index < grab_spheres.size():
			grab_spheres[corner_index].position = new_pos
		update_cube_mesh()
		print("Deformed corner ", corner_index, " to ", new_pos)
