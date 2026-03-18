## Marching Cubes Gallery - Showcase 7 Beautiful Forms
## Displays multiple marching cubes sculptures side-by-side
extends Node3D

@export var sculptures_per_row : int = 4
@export var spacing : float = 4.0 # Reduced spacing for smaller human-scale objects
@export var auto_generate : bool = true
@export var sculpture_scale : float = 0.04  # Scaled down to be roughly human size (1.8m tall)
@export var enable_rotation : bool = false
@export var rotation_speed : float = 0.0
@export var trace_individual_elements : bool = false  # Extract connected components

var sculptures : Array[MeshInstance3D] = []
var sculpture_configs = [
	{ "name": "Human", "shape_type": 0, "color": Color(0.9, 0.7, 0.6) },
	{ "name": "Chair", "shape_type": 1, "color": Color(0.6, 0.4, 0.2) },
	{ "name": "House", "shape_type": 2, "color": Color(0.8, 0.3, 0.3) },
	{ "name": "Bottle", "shape_type": 3, "color": Color(0.2, 0.8, 0.4) },
	{ "name": "Cup", "shape_type": 4, "color": Color(0.9, 0.9, 0.9) },
	{ "name": "Computer", "shape_type": 5, "color": Color(0.3, 0.3, 0.4) }
]

func _ready() -> void:
	spacing = 15.0 # Distinct grid spacing
	# sculpture_scale is used from export
	if auto_generate:
		call_deferred("generate_gallery")

func _process(delta: float) -> void:
	if enable_rotation:
		for sculpture in sculptures:
			if sculpture:
				sculpture.rotation.y += rotation_speed * delta

func generate_gallery() -> void:
	print("🎨 Generating Marching Cubes Gallery with SDF Shapes...")
	
	for i in range(sculpture_configs.size()):
		var config = sculpture_configs[i]
		var row = i / sculptures_per_row
		var col = i % sculptures_per_row
		
		# Grid positioning
		var pos = Vector3(
			col * spacing - (sculptures_per_row - 1) * spacing * 0.5,
			0,
			row * spacing
		) + Vector3(10, 0, 10) # Shift away from 0,0,0 to avoid player stuck

		print("Creating item ", i, " at ", pos)
		await create_sculpture(config, pos, i)
		# Wait a bit more to let physics settling and memory cleanup happen
		await get_tree().create_timer(1.0).timeout
	
	print("✅ Gallery complete with ", sculptures.size(), " sculptures!")

func create_sculpture(config: Dictionary, position: Vector3, index: int) -> void:
	# Load the SHAPES generator, not the base one
	var terrain_script = load("res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Scripts/TerrainGeneratorShapes.gd")
	
	# Create container node
	var container = Node3D.new()
	container.name = "Sculpture_%d_%s" % [index, config["name"]]
	container.position = position
	container.scale = Vector3.ONE * sculpture_scale
	add_child(container)
	
	# Create terrain instance
	var terrain = MeshInstance3D.new()
	terrain.name = "Terrain"
	terrain.set_script(terrain_script)
	
	# Set parameters
	terrain.shape_type = config["shape_type"]
	terrain.noise_scale = 1.0
	terrain.iso_level = 0.0
	# Important: Scale up chunk_scale to fit the SDFs
	terrain.chunk_scale = 120.0 
	
	# Create custom material with unique color
	var material = StandardMaterial3D.new()
	material.albedo_color = config["color"]
	material.metallic = 0.2
	material.roughness = 0.6
	material.emission_enabled = true
	material.emission = config["color"] * 0.1
	material.emission_energy = 0.3
	# Double-sided rendering
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain.material_override = material
	
	container.add_child(terrain)
	sculptures.append(terrain)
	
	# Add label
	var label = Label3D.new()
	label.name = "Label"
	label.text = config["name"]
	label.font_size = 64 # High res font
	label.outline_size = 12
	label.modulate = config["color"]
	label.position = Vector3(0, 45, 0) # Relative to scaled container
	# Compensate scale for label so it's readable
	label.scale = Vector3.ONE * 2.5 
	container.add_child(label)
	
	# Add local light
	var light = OmniLight3D.new()
	light.name = "Light"
	light.light_color = config["color"]
	light.light_energy = 1.5
	light.omni_range = 8.0
	light.position = Vector3(0, 3, 3)
	container.add_child(light)
	
	print("  🔨 Generated: ", config["name"])
	
	# Wait for next frame to avoid lag
	await get_tree().process_frame

func trace_all_elements() -> void:
	"""Extract and highlight individual connected components from each sculpture"""
	print("\n🔍 Tracing individual elements in sculptures...")
	
	for i in range(sculptures.size()):
		var sculpture = sculptures[i]
		if sculpture and sculpture.mesh:
			var islands = extract_mesh_islands(sculpture.mesh)
			print("  Sculpture ", i, ": Found ", islands.size(), " connected elements")
			
			# Optionally create separate meshes for each island
			if islands.size() > 1:
				visualize_islands(sculpture, islands, i)

func extract_mesh_islands(mesh: Mesh) -> Array:
	"""
	Extract connected components (islands) from mesh
	Returns array of vertex index arrays, each representing a connected component
	"""
	if not mesh or mesh.get_surface_count() == 0:
		return []
	
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	
	if not vertices or not indices:
		return []
	
	# Build adjacency graph
	var adjacency = {}  # vertex_index -> [connected_vertex_indices]
	for i in range(0, indices.size(), 3):
		var v0 = indices[i]
		var v1 = indices[i + 1]
		var v2 = indices[i + 2]
		
		# Connect triangle vertices
		_add_edge(adjacency, v0, v1)
		_add_edge(adjacency, v1, v2)
		_add_edge(adjacency, v2, v0)
	
	# Find connected components using flood fill
	var visited = {}
	var islands = []
	
	for vert_idx in adjacency.keys():
		if not visited.has(vert_idx):
			var island = _flood_fill(adjacency, vert_idx, visited)
			if island.size() > 10:  # Ignore tiny components
				islands.append(island)
	
	return islands

func _add_edge(adjacency: Dictionary, v1: int, v2: int) -> void:
	if not adjacency.has(v1):
		adjacency[v1] = []
	if not adjacency.has(v2):
		adjacency[v2] = []
	if not v2 in adjacency[v1]:
		adjacency[v1].append(v2)
	if not v1 in adjacency[v2]:
		adjacency[v2].append(v1)

func _flood_fill(adjacency: Dictionary, start: int, visited: Dictionary) -> Array:
	"""Flood fill to find all connected vertices"""
	var island = []
	var queue = [start]
	visited[start] = true
	
	while not queue.is_empty():
		var current = queue.pop_front()
		island.append(current)
		
		if adjacency.has(current):
			for neighbor in adjacency[current]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
	
	return island

func visualize_islands(sculpture: MeshInstance3D, islands: Array, sculpture_index: int) -> void:
	"""Show only the largest component as a single unified object"""
	if islands.is_empty():
		return
	
	var parent = sculpture.get_parent()
	
	# Find the largest island
	var largest_island = islands[0]
	var largest_size = islands[0].size()
	for island in islands:
		if island.size() > largest_size:
			largest_island = island
			largest_size = island.size()
	
	print("    📦 Found ", islands.size(), " components, keeping largest with ", largest_size, " vertices")
	
	# Create mesh for only the largest island
	var island_mesh = create_island_mesh(sculpture.mesh, largest_island)
	if not island_mesh:
		return
	
	var island_instance = MeshInstance3D.new()
	island_instance.name = "SingleObject"
	island_instance.mesh = island_mesh
	
	# Use the sculpture's configured color
	var config = sculpture_configs[sculpture_index]
	var island_color = config["color"]
	
	var material = StandardMaterial3D.new()
	material.albedo_color = island_color
	material.metallic = 0.2
	material.roughness = 0.6
	material.cull_mode = StandardMaterial3D.CULL_DISABLED
	island_instance.material_override = material
	
	parent.add_child(island_instance)
	
	# Hide original sculpture
	sculpture.visible = false
	print("    ✨ Single unified object created for sculpture ", sculpture_index)

func create_island_mesh(original_mesh: Mesh, island_vertices: Array) -> ArrayMesh:
	"""Create a new mesh containing only the specified vertices"""
	if not original_mesh or original_mesh.get_surface_count() == 0:
		return null
	
	var arrays = original_mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	var indices = arrays[Mesh.ARRAY_INDEX]
	
	# Create set of island vertices for quick lookup
	var island_set = {}
	for v in island_vertices:
		island_set[v] = true
	
	# Filter triangles that belong to this island
	var new_vertices = PackedVector3Array()
	var new_normals = PackedVector3Array()
	var new_indices = PackedInt32Array()
	var vertex_map = {}  # old_index -> new_index
	
	for i in range(0, indices.size(), 3):
		var v0 = indices[i]
		var v1 = indices[i + 1]
		var v2 = indices[i + 2]
		
		# Include triangle if all vertices are in island
		if island_set.has(v0) and island_set.has(v1) and island_set.has(v2):
			# Remap vertices
			for old_idx in [v0, v1, v2]:
				if not vertex_map.has(old_idx):
					vertex_map[old_idx] = new_vertices.size()
					new_vertices.append(vertices[old_idx])
					if normals:
						new_normals.append(normals[old_idx])
			
			new_indices.append(vertex_map[v0])
			new_indices.append(vertex_map[v1])
			new_indices.append(vertex_map[v2])
	
	if new_vertices.size() == 0:
		return null
	
	# Create new mesh
	var new_arrays = []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = new_vertices
	new_arrays[Mesh.ARRAY_NORMAL] = new_normals if new_normals.size() > 0 else null
	new_arrays[Mesh.ARRAY_INDEX] = new_indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
	
	return array_mesh

func toggle_island_tracing() -> void:
	"""Toggle between showing full sculptures and traced islands"""
	trace_individual_elements = not trace_individual_elements
	
	if trace_individual_elements:
		trace_all_elements()
	else:
		# Show original sculptures
		for sculpture in sculptures:
			if sculpture:
				sculpture.visible = true
				# Remove island visualizations
				var parent = sculpture.get_parent()
				for child in parent.get_children():
					if child.name.begins_with("Island_"):
						child.queue_free()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
