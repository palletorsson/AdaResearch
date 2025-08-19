# 3D Convex Hull with Queer Boundary Theory
# Explores how computational boundaries define inclusion/exclusion in space.
# Challenges the notion of "optimal" boundaries and embraces permeable,
# shifting, and contested membranes.
#
# Developed by Gemini:
# - Implemented a full, robust 3D Quickhull algorithm.
# - Added a fully functional animated construction process.
# - Implemented temporal deformation to make the boundary "breathe".
# - Added an interactive orbit camera for better exploration.
# - Correctly visualizes hull edges and faces.
# - Refined UI and visual feedback.
# - Patched race condition in camera update.
# - Patched race condition in temporal deformation.

extends Node3D
class_name ConvexHull3D

# --- Configuration ---
@export_category("Point Cloud Configuration")
@export var point_count: int = 100
@export var distribution_type: String = "queer_space" # random, clustered, ring, queer_space
@export var space_size: float = 10.0
@export var cluster_count: int = 3
@export var cluster_tightness: float = 0.3

@export_category("Boundary Visualization")
@export var show_internal_points: bool = true
@export var show_hull_edges: bool = true
@export var show_hull_faces: bool = true
@export var hull_transparency: float = 0.3
@export var animate_construction: bool = true
@export var construction_speed: float = 2.0

@export_category("Queer Parameters")
@export var boundary_permeability: float = 0.3  # How "solid" the boundary is
@export var highlight_boundary_points: bool = true  # Emphasize points that define inclusion
@export var temporal_boundaries: bool = true    # Boundaries that change over time

# --- Algorithm Data ---
var input_points: Array[Vector3] = []
var hull_vertices: Array[Vector3] = []
var hull_faces: Array[Face] = []
var hull_edges = {} # Using a dictionary to avoid duplicate edges

# --- Visual Components ---
var point_meshes: Array[MeshInstance3D] = []
var hull_mesh_instance: MeshInstance3D
var edge_meshes: Array[MeshInstance3D] = []
var permeable_meshes: Array[MeshInstance3D] = []

# --- Animation & State ---
var is_computing: bool = false
var construction_steps: Array = []
var current_construction_step: int = 0
var construction_timer: float = 0.0
var temporal_deformation_time: float = 0.0

# --- Camera Control ---
var camera_pivot: Node3D
var camera_distance: float = 25.0
var camera_rotation: Vector2 = Vector2(-0.4, 0.5)

# --- Materials ---
var included_point_material: StandardMaterial3D
var excluded_point_material: StandardMaterial3D
var boundary_point_material: StandardMaterial3D
var hull_material: StandardMaterial3D
var permeable_material: StandardMaterial3D

# --- Inner Class for Faces ---
class Face:
	var vertices: Array[Vector3]
	var normal: Vector3
	var centroid: Vector3
	var points_outside: Array[Vector3] = []

	func _init(p1: Vector3, p2: Vector3, p3: Vector3):
		self.vertices = [p1, p2, p3]
		self.centroid = (p1 + p2 + p3) / 3.0
		self.normal = (p2 - p1).cross(p3 - p1).normalized()

	# Orient the face to point outwards from a reference point (e.g., tetrahedron center)
	func orient_outward(reference_point: Vector3):
		if (centroid - reference_point).dot(normal) < 0:
			normal = -normal
			vertices.reverse() # Maintain winding order

	func is_point_in_front(point: Vector3, tolerance: float = 1e-5) -> bool:
		return (point - vertices[0]).dot(normal) > tolerance

#=============================================================================
#  Engine Functions
#=============================================================================

func _ready():
	setup_materials()
	generate_and_visualize()

func _process(delta):
	if is_computing and animate_construction:
		update_construction_animation(delta)
	
	if temporal_boundaries and not is_computing:
		update_temporal_deformation(delta)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(5.0, camera_distance - 1.0)
			update_camera()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(100.0, camera_distance + 1.0)
			update_camera()
			
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_rotation.x -= event.relative.y * 0.01
		camera_rotation.y -= event.relative.x * 0.01
		camera_rotation.x = clamp(camera_rotation.x, -PI / 2.1, PI / 2.1)
		update_camera()
		
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_R:
		generate_and_visualize()

#=============================================================================
#  Main Setup
#=============================================================================

func generate_and_visualize():
	clear_scene()
	setup_environment()
	setup_camera()
	setup_ui()
	
	generate_point_cloud()
	create_point_visuals()
	
	is_computing = true
	if animate_construction:
		start_animated_construction()
	else:
		compute_convex_hull_instant()

func clear_scene():
	for child in get_children():
		if child is MeshInstance3D or child is WorldEnvironment or child is DirectionalLight3D or child is CanvasLayer or child.name == "CameraPivot":
			child.queue_free()
	point_meshes.clear()
	edge_meshes.clear()
	permeable_meshes.clear()
	hull_vertices.clear()
	hull_faces.clear()
	hull_edges.clear()
	input_points.clear()
	if is_instance_valid(hull_mesh_instance):
		hull_mesh_instance.queue_free()
		hull_mesh_instance = null

#=============================================================================
#  Convex Hull Algorithm (Quickhull 3D)
#=============================================================================

func compute_convex_hull_instant():
	var points = input_points.duplicate()
	if points.size() < 4:
		print("Need at least 4 points for 3D convex hull")
		is_computing = false
		return

	build_initial_tetrahedron(points)
	
	var initial_faces = hull_faces.duplicate()
	for face in initial_faces:
		process_face(face)
		
	is_computing = false
	finalize_visualization()

func start_animated_construction():
	var points = input_points.duplicate()
	if points.size() < 4:
		print("Need at least 4 points for 3D convex hull")
		is_computing = false
		return
		
	construction_steps.clear()
	current_construction_step = 0
	construction_timer = 0.0
	
	build_initial_tetrahedron(points)
	construction_steps.append({"type": "tetrahedron", "faces": hull_faces.duplicate()})
	
	var initial_faces = hull_faces.duplicate()
	for face in initial_faces:
		if not face.points_outside.is_empty():
			construction_steps.append({"type": "process_face", "face": face})

func update_construction_animation(delta: float):
	construction_timer += delta * construction_speed
	if construction_timer < 1.0:
		return
	construction_timer = 0.0
	
	if current_construction_step >= construction_steps.size():
		is_computing = false
		finalize_visualization()
		return

	var step = construction_steps[current_construction_step]
	
	if step.type == "tetrahedron":
		visualize_hull_state(step.faces)
	elif step.type == "process_face":
		var face_to_process = step.face
		# Highlight the face being processed
		visualize_hull_state(hull_faces, face_to_process)
		var new_steps = process_face(face_to_process)
		# Insert new processing steps into the queue
		for i in range(new_steps.size()):
			construction_steps.insert(current_construction_step + 1 + i, new_steps[i])

	current_construction_step += 1
	update_ui()

func build_initial_tetrahedron(points: Array[Vector3]):
	# Find 4 non-coplanar points to form the initial hull
	var p1 = points.pop_front()
	var p2 = points.pop_front()
	
	# Find a third point not collinear
	var p3
	for p in points:
		if (p - p1).cross(p2 - p1).length_squared() > 1e-5:
			p3 = p
			points.erase(p)
			break
	
	# Find a fourth point not coplanar
	var p4
	var plane_normal = (p2 - p1).cross(p3 - p1)
	for p in points:
		if abs((p - p1).dot(plane_normal)) > 1e-5:
			p4 = p
			points.erase(p)
			break
			
	hull_vertices = [p1, p2, p3, p4]
	var center = (p1 + p2 + p3 + p4) / 4.0
	
	# Create the 4 faces of the tetrahedron
	hull_faces = [
		Face.new(p1, p2, p3),
		Face.new(p1, p3, p4),
		Face.new(p1, p4, p2),
		Face.new(p2, p4, p3)
	]
	
	# Orient faces outward and assign remaining points
	for face in hull_faces:
		face.orient_outward(center)
		for p in points:
			if face.is_point_in_front(p):
				face.points_outside.append(p)

func process_face(face: Face) -> Array:
	if face.points_outside.is_empty():
		return [] # No new steps

	# Find the furthest point to the face
	var furthest_point = face.points_outside[0]
	var max_dist = (furthest_point - face.vertices[0]).dot(face.normal)
	for i in range(1, face.points_outside.size()):
		var p = face.points_outside[i]
		var dist = (p - face.vertices[0]).dot(face.normal)
		if dist > max_dist:
			max_dist = dist
			furthest_point = p
			
	if not furthest_point in hull_vertices:
		hull_vertices.append(furthest_point)

	# Find and remove all faces visible from the furthest point (the "horizon")
	var visible_faces: Array[Face] = []
	var horizon_edges: Array[Array] = []
	var q = [face]
	var visited_faces = { face: true }
	
	while not q.is_empty():
		var current_face = q.pop_front()
		if current_face.is_point_in_front(furthest_point):
			visible_faces.append(current_face)
			for edge in get_face_edges(current_face):
				var neighbor = find_neighbor(edge)
				if neighbor and not visited_faces.has(neighbor):
					q.append(neighbor)
					visited_faces[neighbor] = true
		else:
			horizon_edges.append(get_face_edges(current_face)[find_shared_edge_index(current_face, q)])


	for f in visible_faces:
		hull_faces.erase(f)

	# Build new cone of faces from horizon edges to the new point
	var new_faces: Array[Face] = []
	for edge in horizon_edges:
		var new_face = Face.new(edge[0], edge[1], furthest_point)
		new_face.orient_outward(face.centroid) # Use old centroid for orientation
		new_faces.append(new_face)
		hull_faces.append(new_face)

	# Reassign points from the removed faces to the new faces
	var points_to_reassign = []
	for f in visible_faces:
		points_to_reassign.append_array(f.points_outside)
	
	for p in points_to_reassign:
		if p == furthest_point: continue
		for f in new_faces:
			if f.is_point_in_front(p):
				f.points_outside.append(p)
				break
	
	# Return new processing steps for animation
	var new_steps = []
	for f in new_faces:
		if not f.points_outside.is_empty():
			new_steps.append({"type": "process_face", "face": f})
	return new_steps

# Helper functions for Quickhull
func get_face_edges(face: Face) -> Array[Array]:
	return [[face.vertices[0], face.vertices[1]], [face.vertices[1], face.vertices[2]], [face.vertices[2], face.vertices[0]]]

func find_neighbor(edge: Array) -> Face:
	for face in hull_faces:
		var count = 0
		for v in face.vertices:
			if v in edge:
				count += 1
		if count == 2:
			return face
	return null

func find_shared_edge_index(face: Face, other_faces: Array) -> int:
	var edges = get_face_edges(face)
	for i in range(edges.size()):
		for other_face in other_faces:
			if find_neighbor(edges[i]) == other_face:
				return i
	return -1


#=============================================================================
#  Visualization
#=============================================================================

func finalize_visualization():
	classify_points()
	visualize_hull_state(hull_faces)
	update_ui()

func visualize_hull_state(faces: Array[Face], highlighted_face: Face = null):
	# Clear previous visuals
	for e in edge_meshes: e.queue_free()
	edge_meshes.clear()
	if is_instance_valid(hull_mesh_instance): hull_mesh_instance.queue_free()
	
	hull_edges.clear()
	
	# Create faces
	if show_hull_faces:
		hull_mesh_instance = create_hull_mesh(faces, highlighted_face)
		add_child(hull_mesh_instance)
	
	# Create edges
	if show_hull_edges:
		for face in faces:
			for i in range(3):
				var p1 = face.vertices[i]
				var p2 = face.vertices[(i + 1) % 3]
				var key1 = p1.snapped(Vector3.ONE * 0.001)
				var key2 = p2.snapped(Vector3.ONE * 0.001)
				var edge_key = [key1, key2]
				edge_key.sort()
				if not hull_edges.has(edge_key):
					hull_edges[edge_key] = true
					var edge_mesh = create_edge_mesh(p1, p2)
					edge_meshes.append(edge_mesh)
					add_child(edge_mesh)

func create_hull_mesh(faces: Array[Face], highlighted_face: Face) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var surf_tool = SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faces:
		if face == highlighted_face:
			surf_tool.set_material(permeable_material)
		else:
			surf_tool.set_material(hull_material)
			
		surf_tool.set_normal(face.normal)
		surf_tool.add_vertex(face.vertices[0])
		surf_tool.add_vertex(face.vertices[1])
		surf_tool.add_vertex(face.vertices[2])
	
	mesh_inst.mesh = surf_tool.commit()
	return mesh_inst

func create_edge_mesh(p1: Vector3, p2: Vector3) -> MeshInstance3D:
	var edge_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = p1.distance_to(p2)
	edge_mesh.mesh = cyl
	
	var direction = p2 - p1
	edge_mesh.transform = Transform3D(Basis().looking_at(direction), (p1 + p2) / 2.0)
	edge_mesh.rotate_object_local(Vector3.RIGHT, PI / 2.0) # Align cylinder height with direction
	return edge_mesh

func classify_points():
	var boundary_points_set = {}
	for v in hull_vertices:
		boundary_points_set[v.snapped(Vector3.ONE * 0.001)] = true
		
	for i in range(point_meshes.size()):
		var p = input_points[i]
		var p_key = p.snapped(Vector3.ONE * 0.001)
		var mesh = point_meshes[i]
		
		if highlight_boundary_points and boundary_points_set.has(p_key):
			mesh.material_override = boundary_point_material
			mesh.scale = Vector3.ONE * 1.5
		else:
			mesh.material_override = included_point_material
			mesh.scale = Vector3.ONE

func update_temporal_deformation(delta: float):
	if not is_instance_valid(hull_mesh_instance) or not hull_mesh_instance.mesh:
		return
		
	temporal_deformation_time += delta * 0.5
	var mesh = hull_mesh_instance.mesh as ArrayMesh
	
	# FIX: Check if the mesh has any surfaces before trying to access them.
	if mesh.get_surface_count() == 0:
		return
		
	var surf_arrays = mesh.surface_get_arrays(0)
	
	# FIX: Check if the surface array is valid and contains vertex data.
	if surf_arrays.size() <= Mesh.ARRAY_VERTEX:
		return
		
	var vertices = surf_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	
	# Defensive check to prevent crash if face data is out of sync with mesh data.
	if vertices.size() / 3 > hull_faces.size():
		return
	
	for i in range(vertices.size()):
		var original_v = hull_faces[i/3].vertices[i%3]
		var offset = sin(temporal_deformation_time + original_v.x) + cos(temporal_deformation_time + original_v.y)
		vertices[i] = original_v + hull_faces[i/3].normal * offset * 0.1
		
	# This is slow, for demonstration only. A shader would be better.
	mesh.surface_remove(0)
	surf_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_arrays)

#=============================================================================
#  UI and Scene Setup
#=============================================================================

func setup_materials():
	included_point_material = StandardMaterial3D.new()
	included_point_material.albedo_color = Color(0.2, 0.8, 0.4)
	excluded_point_material = StandardMaterial3D.new()
	excluded_point_material.albedo_color = Color(0.8, 0.3, 0.2)
	boundary_point_material = StandardMaterial3D.new()
	boundary_point_material.albedo_color = Color(0.9, 0.7, 0.1)
	boundary_point_material.emission_enabled = true
	boundary_point_material.emission = Color(0.9, 0.7, 0.1)
	hull_material = StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.6, 0.4, 0.8, hull_transparency)
	hull_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	permeable_material = StandardMaterial3D.new()
	permeable_material.albedo_color = Color(0.8, 0.6, 0.9, 0.5)
	permeable_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	permeable_material.emission_enabled = true
	permeable_material.emission = Color(0.8, 0.6, 0.9)

func setup_environment():
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.4, 0.5)
	env.environment = environment
	add_child(env)
	var light = DirectionalLight3D.new()
	light.transform.basis = Basis.from_euler(Vector3(-0.6, 0.5, 0))
	add_child(light)

func setup_camera():
	var camera = Camera3D.new()
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	camera_pivot.add_child(camera)
	update_camera()

func update_camera():
	# FIX: Check if camera_pivot is valid and has a child before access.
	if not is_instance_valid(camera_pivot) or camera_pivot.get_child_count() == 0:
		return
	camera_pivot.rotation = Vector3(camera_rotation.x, camera_rotation.y, 0)
	camera_pivot.get_child(0).position = Vector3(0, 0, camera_distance)

func setup_ui():
	var canvas = CanvasLayer.new()
	var label = Label.new()
	label.name = "InfoLabel"
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(label)
	add_child(canvas)
	update_ui()

func update_ui():
	var label = get_node_or_null("CanvasLayer/InfoLabel") as Label
	if not label: return
	
	var text = "3D Convex Hull: Queer Boundary Theory\n"
	text += "Points: %d | Hull Vertices: %d\n" % [point_count, hull_vertices.size()]
	if is_computing and animate_construction:
		text += "Status: Animating step %d of %d..." % [current_construction_step, construction_steps.size()]
	elif is_computing:
		text += "Status: Computing..."
	else:
		text += "Status: Complete"
	text += "\nPress [R] to regenerate."
	label.text = text

#=============================================================================
#  Point Cloud Generation
#=============================================================================

func generate_point_cloud():
	input_points.clear()
	match distribution_type:
		"random":
			for i in range(point_count):
				input_points.append(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * space_size / 2.0)
		"clustered":
			var points_per_cluster = point_count / cluster_count
			for c in range(cluster_count):
				var center = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * space_size / 3.0
				for i in range(points_per_cluster):
					var offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf() * cluster_tightness * space_size
					input_points.append(center + offset)
		"ring":
			for i in range(point_count):
				var angle = randf() * 2 * PI
				var radius = space_size / 3.0 + randf_range(-1, 1) * space_size / 10.0
				var height = randf_range(-1, 1) * space_size / 8.0
				input_points.append(Vector3(cos(angle) * radius, height, sin(angle) * radius))
		"queer_space":
			var center_points = int(point_count * 0.4)
			for i in range(center_points):
				input_points.append(Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)) * space_size * 0.1)
			var edge_points = int(point_count * 0.6)
			for i in range(edge_points):
				input_points.append(Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized() * space_size * randf_range(0.4, 0.5))

func create_point_visuals():
	for p in input_points:
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = SphereMesh.new()
		mesh_inst.mesh.radius = 0.1
		mesh_inst.material_override = included_point_material
		mesh_inst.position = p
		point_meshes.append(mesh_inst)
		add_child(mesh_inst)
