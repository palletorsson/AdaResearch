extends Node3D

## Particle Body Generator
## Creates dynamic mesh bodies by connecting particles with lines or surfaces
## Agent-VisualizationExpert: Organic shape generation
## Protocol: IACP v2.2

class_name ParticleBody

enum ConnectionMode {
	NONE,           # No connections
	NEAREST,        # Connect to N nearest neighbors
	OUTER_HULL,     # Connect outer particles (convex hull)
	DELAUNAY,       # Delaunay triangulation
	ALL_LINES,      # Connect all particles (warning: expensive!)
	DISTANCE_BASED  # Connect if within distance threshold
}

# Configuration
@export var connection_mode: ConnectionMode = ConnectionMode.NEAREST
@export var max_connections_per_particle: int = 3
@export var connection_distance: float = 0.5
@export var line_thickness: float = 0.01
@export var use_surface: bool = false  # If true, create mesh surface instead of lines
@export var surface_color: Color = Color(0.8, 0.5, 1.0, 0.3)
@export var line_color: Color = Color(1.0, 0.6, 1.0, 1.0)

# Particles
var particles: Array[Node3D] = []
var particle_positions: PackedVector3Array = []

# Visualization
var line_mesh: ImmediateMesh
var line_mesh_instance: MeshInstance3D
var surface_mesh: ArrayMesh
var surface_mesh_instance: MeshInstance3D

# Connection data
var connections: Array[Vector2i] = []  # Pairs of particle indices

func _ready():
	_setup_visualization()
	print("ParticleBody: Ready - Mode: %s" % ConnectionMode.keys()[connection_mode])

func _setup_visualization():
	"""Setup mesh instances for visualization"""
	# Line mesh (ImmediateMesh for dynamic lines)
	line_mesh = ImmediateMesh.new()
	line_mesh_instance = MeshInstance3D.new()
	line_mesh_instance.mesh = line_mesh
	
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = line_color
	line_material.emission_enabled = true
	line_material.emission = line_color * 0.5
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mesh_instance.material_override = line_material
	
	add_child(line_mesh_instance)
	
	# Surface mesh (ArrayMesh for triangulated surface)
	surface_mesh = ArrayMesh.new()
	surface_mesh_instance = MeshInstance3D.new()
	surface_mesh_instance.mesh = surface_mesh
	
	var surface_material = StandardMaterial3D.new()
	surface_material.albedo_color = surface_color
	surface_material.emission_enabled = true
	surface_material.emission = surface_color * 0.3
	surface_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	surface_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # See both sides
	surface_mesh_instance.material_override = surface_material
	surface_mesh_instance.visible = use_surface
	
	add_child(surface_mesh_instance)

func add_particle(particle: Node3D):
	"""Add a particle to the body"""
	particles.append(particle)
	_update_particle_positions()

func set_particles(particle_array: Array):
	"""Set all particles at once"""
	particles.clear()
	for p in particle_array:
		if p is Node3D:
			particles.append(p)
	_update_particle_positions()

func _update_particle_positions():
	"""Update cached particle positions (in local space)"""
	particle_positions.clear()
	for particle in particles:
		# Convert to local space relative to this node
		var local_pos = to_local(particle.global_position)
		particle_positions.append(local_pos)

func update_body():
	"""Update the body mesh based on current particle positions"""
	_update_particle_positions()
	
	if particles.size() < 2:
		return
	
	# Calculate connections based on mode
	_calculate_connections()
	
	# Draw visualization
	if use_surface:
		_draw_surface()
	else:
		_draw_lines()

func _calculate_connections():
	"""Calculate which particles to connect"""
	connections.clear()
	
	match connection_mode:
		ConnectionMode.NONE:
			pass
		
		ConnectionMode.NEAREST:
			_connect_nearest_neighbors()
		
		ConnectionMode.OUTER_HULL:
			_connect_outer_hull()
		
		ConnectionMode.DELAUNAY:
			_connect_delaunay()
		
		ConnectionMode.ALL_LINES:
			_connect_all()
		
		ConnectionMode.DISTANCE_BASED:
			_connect_by_distance()

func _connect_nearest_neighbors():
	"""Connect each particle to its N nearest neighbors"""
	for i in range(particles.size()):
		var distances: Array = []
		
		# Calculate distances to all other particles
		for j in range(particles.size()):
			if i == j:
				continue
			var dist = particle_positions[i].distance_to(particle_positions[j])
			distances.append({"index": j, "distance": dist})
		
		# Sort by distance
		distances.sort_custom(func(a, b): return a.distance < b.distance)
		
		# Connect to N nearest
		for k in range(min(max_connections_per_particle, distances.size())):
			var j = distances[k].index
			# Avoid duplicate connections
			if i < j:
				connections.append(Vector2i(i, j))

func _connect_outer_hull():
	"""Connect particles on the outer hull (2D projection for simplicity)"""
	if particles.size() < 3:
		return
	
	# Simple approach: Find convex hull in XZ plane
	var hull_indices = _compute_convex_hull_2d()
	
	# Connect hull points in sequence
	for i in range(hull_indices.size()):
		var next_i = (i + 1) % hull_indices.size()
		connections.append(Vector2i(hull_indices[i], hull_indices[next_i]))

func _compute_convex_hull_2d() -> Array[int]:
	"""Compute 2D convex hull using Graham scan (XZ plane)"""
	if particles.size() < 3:
		return []
	
	# Find lowest point
	var lowest_idx = 0
	for i in range(1, particles.size()):
		if particle_positions[i].z < particle_positions[lowest_idx].z:
			lowest_idx = i
		elif particle_positions[i].z == particle_positions[lowest_idx].z:
			if particle_positions[i].x < particle_positions[lowest_idx].x:
				lowest_idx = i
	
	# Sort by polar angle
	var sorted_indices: Array[int] = []
	for i in range(particles.size()):
		sorted_indices.append(i)
	
	var pivot = particle_positions[lowest_idx]
	sorted_indices.sort_custom(func(a, b):
		if a == lowest_idx: return true
		if b == lowest_idx: return false
		var va = particle_positions[a] - pivot
		var vb = particle_positions[b] - pivot
		var angle_a = atan2(va.z, va.x)
		var angle_b = atan2(vb.z, vb.x)
		return angle_a < angle_b
	)
	
	# Graham scan
	var hull: Array[int] = []
	for idx in sorted_indices:
		while hull.size() >= 2:
			var p1 = particle_positions[hull[hull.size() - 2]]
			var p2 = particle_positions[hull[hull.size() - 1]]
			var p3 = particle_positions[idx]
			
			# Cross product to check turn direction
			var v1 = Vector2(p2.x - p1.x, p2.z - p1.z)
			var v2 = Vector2(p3.x - p2.x, p3.z - p2.z)
			var cross = v1.x * v2.y - v1.y * v2.x
			
			if cross <= 0:
				hull.pop_back()
			else:
				break
		hull.append(idx)
	
	return hull

func _connect_delaunay():
	"""Simple Delaunay-like triangulation (simplified)"""
	# For simplicity, use nearest neighbor approach with triangulation
	_connect_nearest_neighbors()

func _connect_all():
	"""Connect all particles to all other particles (expensive!)"""
	for i in range(particles.size()):
		for j in range(i + 1, particles.size()):
			connections.append(Vector2i(i, j))

func _connect_by_distance():
	"""Connect particles within distance threshold"""
	for i in range(particles.size()):
		for j in range(i + 1, particles.size()):
			var dist = particle_positions[i].distance_to(particle_positions[j])
			if dist <= connection_distance:
				connections.append(Vector2i(i, j))

func _draw_lines():
	"""Draw lines between connected particles"""
	line_mesh.clear_surfaces()
	
	if connections.is_empty():
		return
	
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for conn in connections:
		var p1 = particle_positions[conn.x]
		var p2 = particle_positions[conn.y]
		
		line_mesh.surface_add_vertex(p1)
		line_mesh.surface_add_vertex(p2)
	
	line_mesh.surface_end()

func _draw_surface():
	"""Draw triangulated surface between particles"""
	surface_mesh.clear_surfaces()
	
	if connections.size() < 3:
		return
	
	# Create mesh from connections (triangulate)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Simple triangulation: use connections as edges, create triangles
	# This is a simplified approach - proper Delaunay would be better
	for i in range(0, connections.size() - 2, 3):
		if i + 2 < connections.size():
			var c1 = connections[i]
			var c2 = connections[i + 1]
			var c3 = connections[i + 2]
			
			# Find common vertices to form triangle
			# Simplified: just use first 3 connections
			vertices.append(particle_positions[c1.x])
			vertices.append(particle_positions[c2.x])
			vertices.append(particle_positions[c3.x])
			
			indices.append(i * 3)
			indices.append(i * 3 + 1)
			indices.append(i * 3 + 2)
	
	if vertices.is_empty():
		return
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	surface_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

# Public API

func set_connection_mode(mode: ConnectionMode):
	"""Change connection mode"""
	connection_mode = mode
	update_body()

func set_max_connections(count: int):
	"""Set maximum connections per particle"""
	max_connections_per_particle = count
	update_body()

func set_connection_distance(dist: float):
	"""Set distance threshold for connections"""
	connection_distance = dist
	update_body()

func toggle_surface_mode():
	"""Toggle between lines and surface"""
	use_surface = !use_surface
	surface_mesh_instance.visible = use_surface
	update_body()
