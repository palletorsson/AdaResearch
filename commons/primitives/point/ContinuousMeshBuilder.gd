# ContinuousMeshBuilder.gd - Builds mesh continuously from moving points
# Samples point positions at intervals and creates triangulated surfaces
extends Node3D

# === SAMPLING CONFIGURATION ===
@export_group("Sampling Settings")
@export var sample_interval: float = 5.0  # Sample every 5 seconds
@export var max_sample_points: int = 20   # Maximum points to keep in history
@export var auto_triangulate: bool = true
@export var smooth_interpolation: bool = true

# === VISUALIZATION SETTINGS ===
@export_group("Mesh Appearance")
@export var mesh_material: Material
@export var wireframe_overlay: bool = true
@export var show_sample_points: bool = true
@export var mesh_color: Color = Color.CYAN
@export var point_color: Color = Color.YELLOW

# === TRIANGULATION OPTIONS ===
@export_group("Triangulation")
@export var triangulation_method: String = "delaunay"  # "delaunay", "convex_hull", "fan"
@export var create_bottom_surface: bool = false
@export var ground_level: float = 0.0

# === INTERNAL VARIABLES ===
var tracked_points: Array[Node3D] = []  # Points being tracked
var sample_history: Array[Array] = []   # History of sampled positions [time, positions]
var mesh_instance: MeshInstance3D
var wireframe_instance: MeshInstance3D
var point_instances: Array[MeshInstance3D] = []
var sample_timer: Timer

# Mesh building
var surface_tool: SurfaceTool
var current_vertices: Array[Vector3] = []
var current_faces: Array[Array] = []

func _ready():
	setup_mesh_builder()
	setup_sample_timer()
	print("Continuous Mesh Builder initialized - Sampling every ", sample_interval, " seconds")

func setup_mesh_builder():
	"""Initialize the mesh building system"""
	# Create main mesh instance
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "DynamicMesh"
	add_child(mesh_instance)
	
	# Apply material
	if mesh_material:
		mesh_instance.material_override = mesh_material
	else:
		create_default_material()
	
	# Create wireframe overlay if enabled
	if wireframe_overlay:
		create_wireframe_overlay()
	
	# Initialize surface tool
	surface_tool = SurfaceTool.new()

func create_default_material():
	"""Create default material for the mesh"""
	var material = StandardMaterial3D.new()
	material.albedo_color = mesh_color
	material.emission_enabled = true
	material.emission = mesh_color * 0.3
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
	material.flags_transparent = true
	material.albedo_color.a = 0.7
	mesh_instance.material_override = material

func create_wireframe_overlay():
	"""Create wireframe overlay for better visualization"""
	wireframe_instance = MeshInstance3D.new()
	wireframe_instance.name = "WireframeOverlay"
	add_child(wireframe_instance)
	
	var wireframe_material = StandardMaterial3D.new()
	wireframe_material.wireframe = true
	wireframe_material.albedo_color = Color.WHITE
	wireframe_material.emission_enabled = true
	wireframe_material.emission = Color.WHITE * 0.5
	wireframe_material.flags_transparent = true
	wireframe_material.albedo_color.a = 0.8
	wireframe_instance.material_override = wireframe_material

func setup_sample_timer():
	"""Setup timer for regular position sampling"""
	sample_timer = Timer.new()
	sample_timer.name = "SampleTimer"
	sample_timer.wait_time = sample_interval
	sample_timer.timeout.connect(_on_sample_timer_timeout)
	sample_timer.autostart = true
	add_child(sample_timer)

func add_tracked_point(point: Node3D):
	"""Add a point to be tracked and sampled"""
	if point not in tracked_points:
		tracked_points.append(point)
		print("Now tracking point: ", point.name)
		
		# Create visual indicator if enabled
		if show_sample_points:
			create_point_indicator(point)

func remove_tracked_point(point: Node3D):
	"""Remove a point from tracking"""
	var index = tracked_points.find(point)
	if index >= 0:
		tracked_points.remove_at(index)
		
		# Remove visual indicator
		if index < point_instances.size():
			point_instances[index].queue_free()
			point_instances.remove_at(index)
		
		print("Stopped tracking point: ", point.name)

func create_point_indicator(point: Node3D):
	"""Create visual indicator for tracked point"""
	var indicator = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	indicator.mesh = sphere_mesh
	
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = point_color
	point_material.emission_enabled = true
	point_material.emission = point_color * 0.8
	indicator.material_override = point_material
	
	point.add_child(indicator)
	point_instances.append(indicator)

func _on_sample_timer_timeout():
	"""Sample current positions of all tracked points"""
	if tracked_points.is_empty():
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var current_positions: Array[Vector3] = []
	
	# Sample all tracked point positions
	for point in tracked_points:
		current_positions.append(point.global_position)
	
	# Add to sample history
	sample_history.append([current_time, current_positions.duplicate()])
	
	# Limit history size
	if sample_history.size() > max_sample_points:
		sample_history.pop_front()
	
	print("Sampled ", current_positions.size(), " points at time ", current_time)
	
	# Rebuild mesh if auto-triangulation is enabled
	if auto_triangulate and sample_history.size() >= 3:
		rebuild_mesh()

func rebuild_mesh():
	"""Rebuild the mesh from current sample history"""
	if sample_history.size() < 3:
		print("Need at least 3 sample sets for triangulation")
		return
	
	# Clear previous mesh data
	current_vertices.clear()
	current_faces.clear()
	
	match triangulation_method:
		"delaunay":
			build_delaunay_mesh()
		"convex_hull":
			build_convex_hull_mesh()
		"fan":
			build_fan_mesh()
		_:
			build_delaunay_mesh()
	
	# Create the actual mesh
	create_mesh_from_data()

func build_delaunay_mesh():
	"""Build mesh using Delaunay-style triangulation"""
	# Collect all sampled points
	for sample in sample_history:
		var positions = sample[1] as Array[Vector3]
		current_vertices.append_array(positions)
	
	if current_vertices.size() < 3:
		return
	
	# Simple triangulation - connect consecutive samples
	var points_per_sample = tracked_points.size()
	
	for i in range(sample_history.size() - 1):
		for j in range(points_per_sample):
			var curr_base = i * points_per_sample
			var next_base = (i + 1) * points_per_sample
			
			# Create quad between consecutive samples
			if j < points_per_sample - 1:
				# Triangle 1
				current_faces.append([
					curr_base + j,
					curr_base + j + 1,
					next_base + j
				])
				
				# Triangle 2
				current_faces.append([
					curr_base + j + 1,
					next_base + j + 1,
					next_base + j
				])
	
	# Connect first and last points if we have enough samples
	if sample_history.size() >= 3:
		connect_sample_ends()

func build_convex_hull_mesh():
	"""Build mesh using convex hull approach"""
	# Flatten all points and create convex hull
	current_vertices.clear()
	
	for sample in sample_history:
		var positions = sample[1] as Array[Vector3]
		current_vertices.append_array(positions)
	
	if current_vertices.size() < 4:
		return
	
	# Simple convex hull - connect each point to centroid
	var centroid = Vector3.ZERO
	for vertex in current_vertices:
		centroid += vertex
	centroid /= current_vertices.size()
	
	current_vertices.append(centroid)
	var centroid_index = current_vertices.size() - 1
	
	# Create triangular fan from centroid
	for i in range(current_vertices.size() - 1):
		var next_i = (i + 1) % (current_vertices.size() - 1)
		current_faces.append([centroid_index, i, next_i])

func build_fan_mesh():
	"""Build mesh using fan triangulation"""
	# Use first point as fan center
	if sample_history.is_empty():
		return
	
	var first_sample_positions = sample_history[0][1] as Array[Vector3]
	if first_sample_positions.is_empty():
		return
	
	var fan_center = first_sample_positions[0]
	current_vertices.append(fan_center)
	
	# Add all other points
	for sample in sample_history:
		var positions = sample[1] as Array[Vector3]
		current_vertices.append_array(positions)
	
	# Create fan triangles
	for i in range(1, current_vertices.size() - 1):
		current_faces.append([0, i, i + 1])
	
	# Close the fan
	if current_vertices.size() > 3:
		current_faces.append([0, current_vertices.size() - 1, 1])

func connect_sample_ends():
	"""Connect the ends of the sample chain"""
	var points_per_sample = tracked_points.size()
	
	if points_per_sample > 1:
		var first_sample_start = 0
		var last_sample_start = (sample_history.size() - 1) * points_per_sample
		
		for i in range(points_per_sample - 1):
			current_faces.append([
				first_sample_start + i,
				last_sample_start + i,
				first_sample_start + i + 1
			])
			
			current_faces.append([
				last_sample_start + i,
				last_sample_start + i + 1,
				first_sample_start + i + 1
			])

func create_mesh_from_data():
	"""Create actual mesh from vertices and faces"""
	if current_vertices.is_empty() or current_faces.is_empty():
		return
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Add all triangular faces
	for face in current_faces:
		if face.size() == 3:
			add_triangle_to_surface(face)
	
	# Generate normals and create mesh
	surface_tool.generate_normals()
	var new_mesh = surface_tool.commit()
	
	mesh_instance.mesh = new_mesh
	
	# Update wireframe if enabled
	if wireframe_overlay and wireframe_instance:
		wireframe_instance.mesh = new_mesh
	
	print("Mesh rebuilt with ", current_vertices.size(), " vertices and ", current_faces.size(), " faces")

func add_triangle_to_surface(face: Array):
	"""Add a triangle to the surface tool"""
	if face.size() != 3:
		return
	
	for i in range(3):
		var vertex_index = face[i]
		if vertex_index >= 0 and vertex_index < current_vertices.size():
			var vertex = current_vertices[vertex_index]
			
			# Calculate UV coordinates
			var uv = Vector2(
				(vertex.x + 10.0) / 20.0,  # Map to 0-1 range
				(vertex.z + 10.0) / 20.0
			)
			
			surface_tool.set_uv(uv)
			surface_tool.set_color(mesh_color)
			surface_tool.add_vertex(vertex)

# === PUBLIC API FUNCTIONS ===

func force_sample():
	"""Force an immediate sample of all tracked points"""
	_on_sample_timer_timeout()

func clear_sample_history():
	"""Clear all sample history and rebuild empty mesh"""
	sample_history.clear()
	current_vertices.clear()
	current_faces.clear()
	
	if mesh_instance:
		mesh_instance.mesh = null
	if wireframe_instance:
		wireframe_instance.mesh = null
	
	print("Sample history cleared")

func set_sample_interval(new_interval: float):
	"""Change the sampling interval"""
	sample_interval = max(0.1, new_interval)
	if sample_timer:
		sample_timer.wait_time = sample_interval
	print("Sample interval set to: ", sample_interval, " seconds")

func set_triangulation_method(method: String):
	"""Change triangulation method and rebuild mesh"""
	triangulation_method = method
	if sample_history.size() >= 3:
		rebuild_mesh()
	print("Triangulation method set to: ", method)

func export_mesh_data() -> Dictionary:
	"""Export current mesh data for saving/analysis"""
	return {
		"vertices": current_vertices,
		"faces": current_faces,
		"sample_history": sample_history,
		"tracked_points_count": tracked_points.size(),
		"triangulation_method": triangulation_method
	}

func import_mesh_data(data: Dictionary):
	"""Import mesh data from external source"""
	if data.has("vertices"):
		current_vertices = data["vertices"]
	if data.has("faces"):
		current_faces = data["faces"]
	if data.has("sample_history"):
		sample_history = data["sample_history"]
	
	create_mesh_from_data()
	print("Mesh data imported")

func get_mesh_statistics() -> Dictionary:
	"""Get statistics about the current mesh"""
	return {
		"vertex_count": current_vertices.size(),
		"face_count": current_faces.size(),
		"sample_count": sample_history.size(),
		"tracked_points": tracked_points.size(),
		"triangulation_method": triangulation_method,
		"sample_interval": sample_interval,
		"time_span": get_time_span()
	}

func get_time_span() -> float:
	"""Get time span covered by samples"""
	if sample_history.size() < 2:
		return 0.0
	
	var first_time = sample_history[0][0]
	var last_time = sample_history[-1][0]
	return last_time - first_time

# === INTEGRATION WITH SPLIT QUAD SYSTEM ===

func connect_to_split_quad(split_quad: Node3D):
	"""Connect to a SplitQuad system to track its corner points"""
	if not split_quad:
		return
	
	# Find grab spheres in the split quad
	var grab_spheres = split_quad.find_children("GrabSphere*", "", true, false)
	
	for sphere in grab_spheres:
		add_tracked_point(sphere)
	
	print("Connected to SplitQuad with ", grab_spheres.size(), " tracked points")

# === DEBUG AND VISUALIZATION ===

func _input(event):
	"""Handle debug input"""
	if not OS.is_debug_build():
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				force_sample()
				print("Forced sample")
			KEY_F6:
				clear_sample_history()
			KEY_F7:
				cycle_triangulation_method()
			KEY_F8:
				toggle_wireframe()
			KEY_F9:
				print(get_mesh_statistics())

func cycle_triangulation_method():
	"""Cycle through triangulation methods"""
	var methods = ["delaunay", "convex_hull", "fan"]
	var current_index = methods.find(triangulation_method)
	var next_index = (current_index + 1) % methods.size()
	set_triangulation_method(methods[next_index])

func toggle_wireframe():
	"""Toggle wireframe overlay visibility"""
	if wireframe_instance:
		wireframe_instance.visible = not wireframe_instance.visible
		print("Wireframe overlay: ", "ON" if wireframe_instance.visible else "OFF")

func _on_tree_exiting():
	"""Cleanup when exiting"""
	if sample_timer:
		sample_timer.stop()
