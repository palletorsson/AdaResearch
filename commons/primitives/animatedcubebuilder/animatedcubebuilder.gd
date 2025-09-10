# VRAnimatedCubeBuilder.gd - Clean VR cube construction animation
# No UI - just the educational animation for VR environments
extends Node3D

# Animation states
enum BuildState {
	WAITING,
	SHOWING_VERTICES,
	SHOWING_EDGES,  
	SHOWING_TRIANGLES,
	SHOWING_FINAL_MESH,
	COMPLETE
}

var current_state = BuildState.WAITING
var animation_step = 0
var cube_size = 1.0

# Cube vertices (8 corners)
var vertices = [
	Vector3(-0.5, -0.5, -0.5),  # 0: bottom-back-left
	Vector3(0.5, -0.5, -0.5),   # 1: bottom-back-right
	Vector3(0.5, 0.5, -0.5),    # 2: top-back-right
	Vector3(-0.5, 0.5, -0.5),   # 3: top-back-left
	Vector3(-0.5, -0.5, 0.5),   # 4: bottom-front-left
	Vector3(0.5, -0.5, 0.5),    # 5: bottom-front-right
	Vector3(0.5, 0.5, 0.5),     # 6: top-front-right
	Vector3(-0.5, 0.5, 0.5)     # 7: top-front-left
]

# Cube edges (12 edges connecting vertices)
var edges = [
	# Bottom face edges
	[0, 1], [1, 2], [2, 3], [3, 0],
	# Top face edges  
	[4, 5], [5, 6], [6, 7], [7, 4],
	# Vertical edges
	[0, 4], [1, 5], [2, 6], [3, 7]
]

# Triangle faces (2 triangles per face, 12 total)
var triangles = [
	# Bottom face
	[0, 1, 4], [1, 5, 4],
	# Top face
	[2, 3, 6], [3, 7, 6], 
	# Front face
	[4, 5, 7], [5, 6, 7],
	# Back face  
	[1, 0, 2], [0, 3, 2],
	# Left face
	[0, 4, 3], [4, 7, 3],
	# Right face
	[5, 1, 6], [1, 2, 6]
]

# Visual components
var vertex_spheres = []
var edge_lines = []
var triangle_meshes = []
var final_cube_mesh: MeshInstance3D

# Animation timing
var vertex_blink_timer = 0.0
var step_duration = 0.5  # Much faster animation
var current_step_time = 0.0
var initial_delay = 0.5  # Shorter delay before starting animation

# Colors optimized for VR - Marble green balls, transparent triangles, black edges
var vertex_color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
var vertex_color_alt = Color(0.2, 0.8, 0.3, 0.7)  # Same marble green for all
var edge_color = Color(0.1, 0.1, 0.1)    # Black edges
var triangle_color = Color(0.8, 0.2, 0.4, 0.6)  # Transparent dark pink
var triangle_color_alt1 = Color(0.8, 0.1, 0.1, 0.6)  # Transparent red
var triangle_color_alt2 = Color(0.1, 0.1, 0.1, 0.6)  # Transparent black
var final_color = Color(0.2, 1.0, 0.4)   # Bright green

# Audio feedback (optional - can be connected externally)
signal animation_step_completed(step_name: String)
signal animation_completed()

func _ready():
	setup_scene()
	# Start after a brief delay to allow VR user to focus
	await get_tree().create_timer(initial_delay).timeout
	start_animation()

func setup_scene():
	# Pre-create all visual elements (invisible initially)
	create_vertex_spheres()
	create_edge_lines()
	# add a wait here for 3 sec  
	await get_tree().create_timer(3.0).timeout
	create_triangle_meshes()
	#create_final_mesh()

func create_vertex_spheres():
	for i in range(vertices.size()):
		var sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.025  # Slightly larger for VR visibility
		sphere_mesh.height = 0.05
		sphere.mesh = sphere_mesh
		sphere.position = vertices[i] * cube_size
		
		# All vertices are marble green
		var color = vertex_color
		
		# Create transparent green marble material
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color(0.1, 0.4, 0.2) * 0.3  # Subtle green glow
		material.roughness = 0.1  # Very smooth like marble
		material.metallic = 0.0   # Non-metallic
		material.refraction = 0.05  # Slight refraction for glass-like effect
		material.flags_unshaded = true
		material.no_depth_test = false
		sphere.material_override = material
		
		sphere.visible = false
		vertex_spheres.append(sphere)
		add_child(sphere)

func create_edge_lines():
	for edge in edges:
		var line = create_line_mesh(vertices[edge[0]] * cube_size, vertices[edge[1]] * cube_size)
		line.visible = false
		edge_lines.append(line)
		add_child(line)

func create_line_mesh(start: Vector3, end: Vector3) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	
	# Create a thicker line for VR visibility
	var cylinder = CylinderMesh.new()
	var line_length = start.distance_to(end)
	cylinder.height = line_length
	cylinder.top_radius = 0.015  # Thicker for VR
	cylinder.bottom_radius = 0.015
	cylinder.radial_segments = 8
	
	mesh_instance.mesh = cylinder
	
	# Position at the center point between start and end
	var center_pos = (start + end) * 0.5
	mesh_instance.position = center_pos
	
	# Calculate the direction vector from start to end
	var direction = (end - start).normalized()
	
	# Create a proper transform that aligns the cylinder's Y-axis (height) with the line direction
	var transform = Transform3D()
	transform.origin = center_pos
	
	# If direction is not straight up or down, use cross product for alignment
	if abs(direction.dot(Vector3.UP)) < 0.99:
		# Standard case: create orthonormal basis
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		up = right.cross(direction).normalized()
		transform.basis = Basis(right, direction, up)
	else:
		# Special case: direction is nearly vertical
		var right = Vector3.RIGHT if direction.y > 0 else Vector3.LEFT
		var forward = direction.cross(right).normalized()
		right = forward.cross(direction).normalized()
		transform.basis = Basis(right, direction, forward)
	
	mesh_instance.transform = transform
	
	# Create black material for edges
	var material = StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission_enabled = false
	material.roughness = 0.3
	material.metallic = 0.0
	mesh_instance.material_override = material
	
	return mesh_instance

func create_triangle_meshes():
	for triangle in triangles:
		var mesh_instance = MeshInstance3D.new()
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		# Get triangle vertices
		var v0 = vertices[triangle[0]] * cube_size
		var v1 = vertices[triangle[1]] * cube_size  
		var v2 = vertices[triangle[2]] * cube_size
		
		# Calculate normal
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		
		# Add triangle (both sides for VR visibility)
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_normal(normal)
		st.add_vertex(v2)
		
		# Add reverse side
		st.set_normal(-normal)
		st.add_vertex(v0)
		st.set_normal(-normal)
		st.add_vertex(v2)
		st.set_normal(-normal)
		st.add_vertex(v1)
		
		mesh_instance.mesh = st.commit()
		
		# Create transparent material with alternating colors
		var material = StandardMaterial3D.new()
		var tri_index = triangle_meshes.size()
		var color = triangle_color
		if tri_index % 3 == 1:
			color = triangle_color_alt1  # Red
		elif tri_index % 3 == 2:
			color = triangle_color_alt2  # Black
		
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = false
		material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides in VR
		mesh_instance.material_override = material
		
		mesh_instance.visible = false
		triangle_meshes.append(mesh_instance)
		add_child(mesh_instance)

func create_final_mesh():
	final_cube_mesh = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Add all triangles to create the complete cube
	for triangle in triangles:
		var v0 = vertices[triangle[0]] * cube_size
		var v1 = vertices[triangle[1]] * cube_size  
		var v2 = vertices[triangle[2]] * cube_size
		
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_normal(normal)
		st.add_vertex(v2)
	
	final_cube_mesh.mesh = st.commit()
	
	# Create final material with shader if available
	var shader = load("res://commons/resourses/shaders/grid_solid.gdshader")
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("base_color", final_color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 2.0)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.2)  # Brighter for VR
		final_cube_mesh.material_override = material
	else:
		var material = StandardMaterial3D.new()
		material.albedo_color = final_color
		material.emission_enabled = true
		material.emission = final_color * 0.5
		final_cube_mesh.material_override = material
	
	#final_cube_mesh.visible = false
	add_child(final_cube_mesh)

func start_animation():
	current_state = BuildState.SHOWING_VERTICES
	animation_step = 0
	current_step_time = 0.0

func _process(delta):
	current_step_time += delta
	vertex_blink_timer += delta
	
	match current_state:
		BuildState.SHOWING_VERTICES:
			animate_vertices(delta)
		BuildState.SHOWING_EDGES:
			animate_edges(delta)
		BuildState.SHOWING_TRIANGLES:
			animate_triangles(delta)
		#BuildState.SHOWING_FINAL_MESH:
			#animate_final_mesh(delta)
		BuildState.COMPLETE:
			# Keep what we built without animation
			pass

func animate_vertices(delta):
	# Show vertices one by one with blinking effect
	if current_step_time >= step_duration and animation_step < vertices.size():
		vertex_spheres[animation_step].visible = true
		animation_step += 1
		current_step_time = 0.0
		
		if animation_step >= vertices.size():
			# Move to next phase
			current_state = BuildState.SHOWING_EDGES
			animation_step = 0
			current_step_time = 0.0
			animation_step_completed.emit("vertices_complete")
	
	# Blink visible vertices (slower blink for VR comfort)
	var blink_alpha = (sin(vertex_blink_timer * 2.0) + 1.0) * 0.5
	for i in range(min(animation_step + 1, vertices.size())):
		if vertex_spheres[i].visible:
			var material = vertex_spheres[i].material_override as StandardMaterial3D
				# Use marble green for all vertices
			var base_color = vertex_color
			material.emission = Color(0.1, 0.4, 0.2) * (0.3 + blink_alpha * 0.2)

func animate_edges(delta):
	# Show edges progressively
	var edge_step_duration = step_duration * 0.4
	
	if current_step_time >= edge_step_duration and animation_step < edges.size():
		edge_lines[animation_step].visible = true
		animation_step += 1
		current_step_time = 0.0
		
		if animation_step >= edges.size():
			current_state = BuildState.SHOWING_TRIANGLES
			animation_step = 0
			current_step_time = 0.0
			animation_step_completed.emit("edges_complete")

func animate_triangles(delta):
	# Show triangles progressively
	var triangle_step_duration = step_duration * 0.3
	
	if current_step_time >= triangle_step_duration and animation_step < triangles.size():
		triangle_meshes[animation_step].visible = true
		animation_step += 1
		current_step_time = 0.0
		
		if animation_step >= triangles.size():
			current_state = BuildState.COMPLETE
			current_step_time = 0.0
			animation_step_completed.emit("triangles_complete")

func animate_final_mesh(delta):
	# Wait a moment, then transition to final mesh
	if current_step_time >= step_duration:
		# Hide all individual components
		for sphere in vertex_spheres:
			sphere.visible = false
		for line in edge_lines:
			line.visible = false
		for triangle in triangle_meshes:
			triangle.visible = false
		
		# Show final mesh
		final_cube_mesh.visible = true
		current_state = BuildState.COMPLETE
		animation_completed.emit()

func animate_complete_rotation(delta):
	# Slowly rotate the completed cube
	final_cube_mesh.rotation.y += delta * 0.3  # Slower rotation for VR comfort
	final_cube_mesh.rotation.x += delta * 0.1

# Public methods for external control (if needed by your VR system)
func restart_animation():
	# Hide everything and restart
	for sphere in vertex_spheres:
		sphere.visible = false
	for line in edge_lines:
		line.visible = false
	for triangle in triangle_meshes:
		triangle.visible = false
	final_cube_mesh.visible = false
	
	start_animation()

func skip_to_final():
	current_state = BuildState.COMPLETE
	for sphere in vertex_spheres:
		sphere.visible = false
	for line in edge_lines:
		line.visible = false
	for triangle in triangle_meshes:
		triangle.visible = false
	final_cube_mesh.visible = true

func set_animation_speed(speed_multiplier: float):
	step_duration = 0.5 / speed_multiplier

# VR-specific helpers
func get_current_phase() -> String:
	match current_state:
		BuildState.SHOWING_VERTICES:
			return "vertices"
		BuildState.SHOWING_EDGES:
			return "edges"
		BuildState.SHOWING_TRIANGLES:
			return "triangles"
		BuildState.SHOWING_FINAL_MESH:
			return "final_mesh"
		BuildState.COMPLETE:
			return "complete"
		_:
			return "waiting"

func get_progress_percentage() -> float:
	match current_state:
		BuildState.SHOWING_VERTICES:
			return (animation_step / float(vertices.size())) * 0.25
		BuildState.SHOWING_EDGES:
			return 0.25 + (animation_step / float(edges.size())) * 0.25
		BuildState.SHOWING_TRIANGLES:
			return 0.5 + (animation_step / float(triangles.size())) * 0.25
		BuildState.SHOWING_FINAL_MESH:
			return 0.75 + (current_step_time / step_duration) * 0.25
		BuildState.COMPLETE:
			return 1.0
		_:
			return 0.0
