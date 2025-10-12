extends Node3D

# Morphogenesis with Dynamic Topology (Dyntopo) - Growing limbs with adaptive detail

class Vertex:
	var position: Vector3
	var normal: Vector3
	var growth_potential: float = 0.0
	var connections: Array[int] = []  # Indices of connected vertices

class Edge:
	var v1: int
	var v2: int
	var length: float = 0.0

	func _init(vert1: int, vert2: int):
		v1 = mini(vert1, vert2)
		v2 = maxi(vert1, vert2)

class Face:
	var vertex_indices: Array = []
	var center: Vector3
	var normal: Vector3
	var is_growth_zone: bool = false
	var detail_level: float = 1.0  # Higher = needs more detail

var vertices: Array[Vertex] = []
var faces: Array[Face] = []
var edges: Dictionary = {}  # Key: "v1_v2", Value: Edge
var mesh_instance: MeshInstance3D

# Growth parameters
@export var sphere_radius: float = 1.0
@export var initial_subdivisions: int = 2
@export var growth_interval: float = 1.0
@export var extrusion_amount: float = 0.15
@export var gravity_influence: float = 0.3
@export var growth_zone_radius: float = 0.4
@export var subdivision_iterations: int = 2

# Dyntopo parameters
@export_group("Dynamic Topology")
@export var dyntopo_enabled: bool = true
@export var max_edge_length: float = 0.15  # Subdivide edges longer than this
@export var min_edge_length: float = 0.03  # Collapse edges shorter than this
@export var detail_size: float = 0.1  # Target edge length in growth zones

var time_since_last_growth: float = 0.0
var growth_timer: float = 0.0
var current_growth_point: Vector3 = Vector3.ZERO
var is_growing: bool = false
var growth_zones: Array[Vector3] = []

func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create initial sphere
	create_icosphere(sphere_radius, initial_subdivisions)
	update_mesh()
	
	print("Press SPACE to start growth, R to reset")
	print("Growth will pick random points and grow limbs from them")

func create_icosphere(radius: float, subdivisions: int):
	vertices.clear()
	faces.clear()
	
	# Create icosahedron base
	var t = (1.0 + sqrt(5.0)) / 2.0
	
	# 12 vertices of icosahedron
	var base_verts = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)
	]
	
	for v in base_verts:
		var vert = Vertex.new()
		vert.position = v.normalized() * radius
		vert.normal = v.normalized()
		vertices.append(vert)
	
	# 20 faces of icosahedron
	var base_faces = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]
	
	for f in base_faces:
		var face = Face.new()
		face.vertex_indices = f
		faces.append(face)
	
	# Subdivide
	for i in range(subdivisions):
		subdivide_all()
	
	update_face_data()

func subdivide_all():
	var new_faces: Array[Face] = []
	var edge_midpoints: Dictionary = {}
	
	for face in faces:
		var v0 = face.vertex_indices[0]
		var v1 = face.vertex_indices[1]
		var v2 = face.vertex_indices[2]
		
		# Get or create midpoint vertices
		var m0 = get_or_create_midpoint(v0, v1, edge_midpoints)
		var m1 = get_or_create_midpoint(v1, v2, edge_midpoints)
		var m2 = get_or_create_midpoint(v2, v0, edge_midpoints)
		
		# Create 4 new faces
		new_faces.append(create_face([v0, m0, m2]))
		new_faces.append(create_face([v1, m1, m0]))
		new_faces.append(create_face([v2, m2, m1]))
		new_faces.append(create_face([m0, m1, m2]))
	
	faces = new_faces

func get_or_create_midpoint(v1_idx: int, v2_idx: int, cache: Dictionary) -> int:
	var key = [mini(v1_idx, v2_idx), maxi(v1_idx, v2_idx)]
	var key_str = str(key)
	
	if cache.has(key_str):
		return cache[key_str]
	
	var v1 = vertices[v1_idx]
	var v2 = vertices[v2_idx]
	
	var new_vert = Vertex.new()
	var mid_pos = (v1.position + v2.position) / 2.0
	new_vert.position = mid_pos.normalized() * mid_pos.length()
	new_vert.normal = mid_pos.normalized()
	
	var new_idx = vertices.size()
	vertices.append(new_vert)
	cache[key_str] = new_idx
	
	return new_idx

func create_face(vert_indices: Array) -> Face:
	var face = Face.new()
	face.vertex_indices = vert_indices
	return face

func update_face_data():
	for face in faces:
		var center = Vector3.ZERO
		for idx in face.vertex_indices:
			center += vertices[idx].position
		face.center = center / face.vertex_indices.size()
		face.normal = face.center.normalized()

func _process(delta):
	if is_growing:
		growth_timer += delta
		
		if growth_timer >= growth_interval:
			growth_timer = 0.0
			start_new_growth_zone()

func start_new_growth_zone():
	# Pick random point on sphere surface
	var random_theta = randf() * TAU
	var random_phi = acos(randf_range(-1.0, 1.0))
	
	current_growth_point = Vector3(
		sin(random_phi) * cos(random_theta),
		sin(random_phi) * sin(random_theta),
		cos(random_phi)
	) * sphere_radius
	
	growth_zones.append(current_growth_point)
	
	# Visualize growth point
	var marker = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	marker.mesh = sphere_mesh
	marker.position = current_growth_point
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	marker.material_override = mat
	add_child(marker)
	
	# Mark faces in growth zone
	for face in faces:
		if face.center.distance_to(current_growth_point) < growth_zone_radius:
			face.is_growth_zone = true
	
	# Perform growth
	for i in range(subdivision_iterations):
		grow_and_extrude()
	
	update_mesh()
	print("New growth zone started at ", current_growth_point)

func grow_and_extrude():
	if dyntopo_enabled:
		# Dynamic topology: subdivide/collapse based on detail needs
		dyntopo_remesh()
	else:
		# Static subdivision approach
		static_subdivide_growth_zone()

	# Extrude vertices in growth zone
	var gravity = Vector3(0, -1, 0)

	for i in range(vertices.size()):
		var vert = vertices[i]
		var distance_to_growth = vert.position.distance_to(current_growth_point)

		if distance_to_growth < growth_zone_radius:
			# Calculate extrusion direction: blend normal and gravity
			var normal_component = vert.normal
			var gravity_component = gravity
			var extrusion_dir = (normal_component + gravity_component * gravity_influence).normalized()

			# Extrusion amount decreases with distance from growth point
			var influence = 1.0 - (distance_to_growth / growth_zone_radius)
			influence = pow(influence, 2.0)  # Smooth falloff

			vert.position += extrusion_dir * extrusion_amount * influence
			vert.normal = vert.position.normalized()

	update_face_data()

func static_subdivide_growth_zone():
	# Original static subdivision approach
	var new_faces: Array[Face] = []
	var edge_midpoints: Dictionary = {}

	for face in faces:
		if face.is_growth_zone:
			var v0 = face.vertex_indices[0]
			var v1 = face.vertex_indices[1]
			var v2 = face.vertex_indices[2]

			var m0 = get_or_create_midpoint(v0, v1, edge_midpoints)
			var m1 = get_or_create_midpoint(v1, v2, edge_midpoints)
			var m2 = get_or_create_midpoint(v2, v0, edge_midpoints)

			# Create 4 new faces, all in growth zone
			var f1 = create_face([v0, m0, m2])
			var f2 = create_face([v1, m1, m0])
			var f3 = create_face([v2, m2, m1])
			var f4 = create_face([m0, m1, m2])

			f1.is_growth_zone = true
			f2.is_growth_zone = true
			f3.is_growth_zone = true
			f4.is_growth_zone = true

			new_faces.append(f1)
			new_faces.append(f2)
			new_faces.append(f3)
			new_faces.append(f4)
		else:
			new_faces.append(face)

	faces = new_faces

func dyntopo_remesh():
	# Dyntopo: adaptive subdivision and collapse based on edge length
	update_edges()

	# Subdivide long edges in growth zones
	var edges_to_subdivide: Array = []
	for edge_key in edges.keys():
		var edge: Edge = edges[edge_key]
		var in_growth_zone = is_vertex_in_growth_zone(edge.v1) or is_vertex_in_growth_zone(edge.v2)

		if in_growth_zone and edge.length > detail_size:
			edges_to_subdivide.append(edge)
		elif edge.length > max_edge_length:
			edges_to_subdivide.append(edge)

	# Subdivide selected edges
	for edge in edges_to_subdivide:
		subdivide_edge(edge)

	# Collapse short edges
	var edges_to_collapse: Array = []
	for edge_key in edges.keys():
		var edge: Edge = edges[edge_key]
		if edge.length < min_edge_length:
			edges_to_collapse.append(edge)

	# Collapse selected edges (limit to prevent over-collapse)
	var collapse_limit = min(edges_to_collapse.size(), 10)
	for i in range(collapse_limit):
		collapse_edge(edges_to_collapse[i])

	# Rebuild edges after modifications
	update_edges()

func update_edges():
	edges.clear()

	for face in faces:
		if face.vertex_indices.size() >= 3:
			for i in range(face.vertex_indices.size()):
				var v1 = face.vertex_indices[i]
				var v2 = face.vertex_indices[(i + 1) % face.vertex_indices.size()]
				var edge = Edge.new(v1, v2)
				edge.length = vertices[v1].position.distance_to(vertices[v2].position)

				var key = str(edge.v1) + "_" + str(edge.v2)
				if not edges.has(key):
					edges[key] = edge

func is_vertex_in_growth_zone(v_idx: int) -> bool:
	if v_idx >= vertices.size():
		return false
	return vertices[v_idx].position.distance_to(current_growth_point) < growth_zone_radius

func subdivide_edge(edge: Edge):
	var v1 = vertices[edge.v1]
	var v2 = vertices[edge.v2]

	# Create midpoint vertex
	var new_vert = Vertex.new()
	new_vert.position = (v1.position + v2.position) / 2.0
	new_vert.normal = new_vert.position.normalized()
	var mid_idx = vertices.size()
	vertices.append(new_vert)

	# Find and split faces containing this edge
	var new_faces: Array[Face] = []
	for face in faces:
		if face_contains_edge(face, edge.v1, edge.v2):
			# Split triangle into two
			var v3_idx = -1
			for idx in face.vertex_indices:
				if idx != edge.v1 and idx != edge.v2:
					v3_idx = idx
					break

			if v3_idx >= 0:
				var f1 = create_face([edge.v1, mid_idx, v3_idx])
				var f2 = create_face([mid_idx, edge.v2, v3_idx])
				f1.is_growth_zone = face.is_growth_zone
				f2.is_growth_zone = face.is_growth_zone
				new_faces.append(f1)
				new_faces.append(f2)
		else:
			new_faces.append(face)

	faces = new_faces

func collapse_edge(edge: Edge):
	# Collapse edge by merging v2 into v1
	var target_pos = (vertices[edge.v1].position + vertices[edge.v2].position) / 2.0
	vertices[edge.v1].position = target_pos
	vertices[edge.v1].normal = target_pos.normalized()

	# Redirect all v2 references to v1
	for face in faces:
		for i in range(face.vertex_indices.size()):
			if face.vertex_indices[i] == edge.v2:
				face.vertex_indices[i] = edge.v1

	# Remove degenerate faces (faces with duplicate vertices)
	var valid_faces: Array[Face] = []
	for face in faces:
		if not is_face_degenerate(face):
			valid_faces.append(face)
	faces = valid_faces

func face_contains_edge(face: Face, v1: int, v2: int) -> bool:
	var has_v1 = false
	var has_v2 = false
	for idx in face.vertex_indices:
		if idx == v1:
			has_v1 = true
		if idx == v2:
			has_v2 = true
	return has_v1 and has_v2

func is_face_degenerate(face: Face) -> bool:
	if face.vertex_indices.size() < 3:
		return true
	# Check for duplicate vertices
	for i in range(face.vertex_indices.size()):
		for j in range(i + 1, face.vertex_indices.size()):
			if face.vertex_indices[i] == face.vertex_indices[j]:
				return true
	return false

func update_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faces:
		for idx in face.vertex_indices:
			surface_tool.add_vertex(vertices[idx].position)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.8, 0.6)
	material.metallic = 0.2
	material.roughness = 0.8
	mesh_instance.material_override = material

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			start_growth()
		elif event.keycode == KEY_R:
			reset_growth()

func start_growth():
	is_growing = true
	growth_timer = 0.0
	print("Starting morphogenesis growth from sphere surface...")

func reset_growth():
	is_growing = false
	growth_timer = 0.0
	growth_zones.clear()
	
	# Clear markers
	for child in get_children():
		if child != mesh_instance:
			child.queue_free()
	
	create_icosphere(sphere_radius, initial_subdivisions)
	update_mesh()
	print("Reset complete. Press SPACE to start growing.")
