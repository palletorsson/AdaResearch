extends Node3D

# Terrain and simulation parameters
@export var terrain_size: Vector2 = Vector2(50.0, 50.0)
@export var terrain_resolution: int = 100
@export var terrain_height_scale: float = 5.0
@export var terrain_noise_scale: float = 3.0
@export var terrain_seed: int = 42

# Ant colony parameters
@export var num_ants: int = 100
@export var ant_speed: float = 2.0
@export var pheromone_decay_rate: float = 0.999
@export var pheromone_diffusion_rate: float = 0.05
@export var ant_scene: PackedScene
@export var food_source_count: int = 3
@export var food_amount_per_source: int = 100

# References to nodes and resources
var terrain_mesh: MeshInstance3D
var pheromone_map: Array = []
var food_sources: Array = []
var colony_position: Vector3
var noise: FastNoiseLite
var ants: Array = []
var colony_node: Node3D

# Shader resources
var pheromone_image: Image
var pheromone_texture: ImageTexture
var terrain_material: ShaderMaterial

# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Initialize noise generator
	noise = FastNoiseLite.new()
	noise.seed = terrain_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	
	# Initialize pheromone map (2D grid matching terrain resolution)
	initialize_pheromone_map()
	
	# Initialize image and texture for shader
	pheromone_image = Image.create(terrain_resolution + 1, terrain_resolution + 1, false, Image.FORMAT_RGB8)
	pheromone_texture = ImageTexture.create_from_image(pheromone_image)
	
	# Create the terrain
	generate_terrain()
	
	# Place colony and food sources
	place_colony_and_food()
	
	# Spawn ants
	spawn_ants()
	
	# Debug visualization
	create_debug_visualization()

# Generate procedural terrain
func generate_terrain() -> void:
	# Create a plane mesh with the specified resolution
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = terrain_size
	plane_mesh.subdivide_width = terrain_resolution
	plane_mesh.subdivide_depth = terrain_resolution
	
	# Convert to ArrayMesh for editing vertices
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_mesh.get_mesh_arrays())
	
	# Get vertex array
	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(array_mesh, 0)
	
	# Apply random height to vertices
	for i in range(mesh_data_tool.get_vertex_count()):
		var vertex = mesh_data_tool.get_vertex(i)
		
		# Calculate height based on position
		var x_norm = (vertex.x + terrain_size.x/2) / terrain_size.x
		var z_norm = (vertex.z + terrain_size.y/2) / terrain_size.y
		
		# Use simplex noise for natural terrain
		var height = generate_terrain_height(x_norm, z_norm)
		
		# Apply height
		vertex.y = height
		mesh_data_tool.set_vertex(i, vertex)
	
	# Update normals for proper lighting
	for i in range(mesh_data_tool.get_vertex_count()):
		var normal = mesh_data_tool.get_vertex_normal(i)
		normal = normal.normalized()
		mesh_data_tool.set_vertex_normal(i, normal)
	
	# Commit changes back to the mesh
	mesh_data_tool.commit_to_surface(array_mesh)
	
	# Create terrain instance
	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = array_mesh
	
	# Create shader material
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = load("res://algorithms/swarmintelligence/antcolonyoptimization/ant_terrain.gdshader")
	terrain_material.set_shader_parameter("pheromone_texture", pheromone_texture)
	
	terrain_mesh.set_surface_override_material(0, terrain_material)
	add_child(terrain_mesh)

# Generate terrain height using noise
func generate_terrain_height(x: float, z: float) -> float:
	var base_height = noise.get_noise_2d(x * terrain_noise_scale, z * terrain_noise_scale)
	
	# Add some smaller detail noise
	var detail = noise.get_noise_2d(x * terrain_noise_scale * 4, z * terrain_noise_scale * 4) * 0.25
	
	# Combine and scale
	return (base_height + detail) * terrain_height_scale

# Initialize the pheromone map
func initialize_pheromone_map() -> void:
	pheromone_map = []
	for x in range(terrain_resolution + 1):
		var row = []
		for z in range(terrain_resolution + 1):
			# Store different types of pheromones
			row.append({
				"food": 0.0,    # Pheromone leading to food
				"home": 0.0     # Pheromone leading to colony
			})
		pheromone_map.append(row)

# Place colony and food sources
func place_colony_and_food() -> void:
	# Place colony in a suitable flat area near the center
	var center_x = 0
	var center_z = 0
	colony_position = Vector3(center_x, get_height_at(center_x, center_z) + 0.5, center_z)
	
	# Create colony visual representation
	colony_node = MeshInstance3D.new()
	var colony_mesh = SphereMesh.new()
	colony_mesh.radius = 2.0
	colony_mesh.height = 4.0
	colony_node.mesh = colony_mesh
	
	var colony_material = StandardMaterial3D.new()
	colony_material.albedo_color = Color(0.6, 0.3, 0.1)
	colony_node.set_surface_override_material(0, colony_material)
	
	colony_node.position = colony_position
	add_child(colony_node)
	
	# Place food sources away from the colony
	for i in range(food_source_count):
		# Place food in random locations away from colony
		var angle = randf() * TAU
		var distance = 8.0 + randf() * 8.0
		var food_x = center_x + cos(angle) * distance
		var food_z = center_z + sin(angle) * distance
		
		# Get terrain height at this position
		var food_y = get_height_at(food_x, food_z) + 0.5
		
		# Create food source
		var food_source = {
			"position": Vector3(food_x, food_y, food_z),
			"amount": food_amount_per_source
		}
		
		food_sources.append(food_source)
		
		# Create visual representation
		var food_visual = MeshInstance3D.new()
		var food_mesh = CylinderMesh.new()
		food_mesh.top_radius = 1.5
		food_mesh.bottom_radius = 1.5
		food_mesh.height = 0.5
		food_visual.mesh = food_mesh
		
		var food_material = StandardMaterial3D.new()
		food_material.albedo_color = Color(0.1, 0.8, 0.1)
		food_visual.set_surface_override_material(0, food_material)
		
		food_visual.position = food_source.position
		add_child(food_visual)

# Get terrain height at specific world position
func get_height_at(x: float, z: float) -> float:
	# Convert world position to normalized coordinates
	var x_norm = (x + terrain_size.x/2) / terrain_size.x
	var z_norm = (z + terrain_size.y/2) / terrain_size.y
	
	return generate_terrain_height(x_norm, z_norm)

# Spawn ants around the colony
func spawn_ants() -> void:
	if ant_scene:
		for i in range(num_ants):
			var ant = ant_scene.instantiate()
			add_child(ant)
			# AntAgent.initialize(colony_ref, pheromone_sys_ref, terrain_ref, food_refs)
			# We pass 'self' as the pheromone/terrain system.
			if ant.has_method("initialize"):
				# Ensure we pass the colony NODE, and 'self' for systems
				ant.initialize(colony_node, self, self, food_sources)
			
			# Set random position near colony
			var angle = randf() * TAU
			var dist = randf() * 2.0
			var start_pos = colony_position + Vector3(sin(angle), 0, cos(angle)) * dist
			start_pos.y = get_height_at(start_pos.x, start_pos.z) + 0.5
			ant.position = start_pos

# Alias for compatibility with AntAgent
func add_pheromone(world_pos: Vector3, type: String, amount: float) -> void:
	place_pheromone(world_pos, type, amount)

# Deposit food
var collected_food_total: float = 0.0
func deposit_food(amount: float) -> void:
	collected_food_total += amount

# Place pheromone at world position
func place_pheromone(world_pos: Vector3, type: String, amount: float) -> void:
	var grid_pos = world_to_grid(world_pos)
	var x = int(grid_pos.x)
	var y = int(grid_pos.y)
	
	if x >= 0 and x <= terrain_resolution and y >= 0 and y <= terrain_resolution:
		pheromone_map[x][y][type] += amount

# Get strongest pheromone direction from a position
func get_pheromone_direction(world_pos: Vector3, type: String, perception_radius: int = 3) -> Vector3:
	var grid_pos = world_to_grid(world_pos)
	var center_x = int(grid_pos.x)
	var center_y = int(grid_pos.y)
	
	var strongest_value = 0.0
	var strongest_dir = Vector3.ZERO
	
	# Check in a radius around the ant
	for dx in range(-perception_radius, perception_radius + 1):
		for dy in range(-perception_radius, perception_radius + 1):
			var x = center_x + dx
			var y = center_y + dy
			
			# Skip if out of bounds
			if x < 0 or x > terrain_resolution or y < 0 or y > terrain_resolution:
				continue
			
			var pheromone_value = pheromone_map[x][y][type]
			
			if pheromone_value > strongest_value:
				strongest_value = pheromone_value
				
				# Convert grid position to world position
				var world_x = x * terrain_size.x / terrain_resolution - terrain_size.x/2
				var world_z = y * terrain_size.y / terrain_resolution - terrain_size.y/2
				var world_y = get_height_at(world_x, world_z)
				
				strongest_dir = Vector3(world_x, world_y, world_z) - world_pos
	
	return strongest_dir.normalized()

# Convert world position to pheromone grid indices
func world_to_grid(world_pos: Vector3) -> Vector2:
	var x_grid = int((world_pos.x + terrain_size.x/2) * terrain_resolution / terrain_size.x)
	var z_grid = int((world_pos.z + terrain_size.y/2) * terrain_resolution / terrain_size.y)
	
	# Clamp to valid grid indices
	x_grid = clamp(x_grid, 0, terrain_resolution)
	z_grid = clamp(z_grid, 0, terrain_resolution)
	
	return Vector2(x_grid, z_grid)

# Find closest food source
func find_closest_food(world_pos: Vector3) -> Dictionary:
	var closest_food = null
	var closest_distance = INF
	
	for food in food_sources:
		if food.amount <= 0:
			continue
			
		var distance = world_pos.distance_to(food.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_food = food
	
	if closest_food:
		return {
			"food": closest_food,
			"distance": closest_distance
		}
	else:
		return {
			"food": null,
			"distance": INF
		}

# Take food from a source
func take_food_from_source(food_source) -> bool:
	if food_source and food_source.amount > 0:
		food_source.amount -= 1
		return true
	return false

# Update pheromone texture for shader
func update_pheromone_texture() -> void:
	if not pheromone_image: return
	
	for x in range(terrain_resolution + 1):
		for y in range(terrain_resolution + 1):
			var food = clamp(pheromone_map[x][y].food, 0.0, 1.0)
			var home = clamp(pheromone_map[x][y].home, 0.0, 1.0)
			# R corresponds to Food (Red), B corresponds to Home (Blue)
			pheromone_image.set_pixel(x, y, Color(food, 0.0, home))
			
	pheromone_texture.update(pheromone_image)

# Process function called every frame
func _process(delta: float) -> void:
	# Update pheromones
	process_pheromones(delta)
	
	# Update visualization every few frames to improve performance
	if Engine.get_frames_drawn() % 5 == 0:
		update_pheromone_texture()

# Process pheromones (decay and diffusion)
func process_pheromones(_delta) -> void:
	# Decay pheromones
	for x in range(terrain_resolution + 1):
		for z in range(terrain_resolution + 1):
			pheromone_map[x][z].food *= pheromone_decay_rate
			pheromone_map[x][z].home *= pheromone_decay_rate
	
	# Diffuse pheromones (simple diffusion to neighbors)
	var diffused_map = []
	for x in range(terrain_resolution + 1):
		var row = []
		for z in range(terrain_resolution + 1):
			row.append({
				"food": pheromone_map[x][z].food,
				"home": pheromone_map[x][z].home
			})
		diffused_map.append(row)
	
	for x in range(1, terrain_resolution):
		for z in range(1, terrain_resolution):
			# For each neighbor, get a small amount of pheromone
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					if dx == 0 and dz == 0:
						continue
					
					var nx = x + dx
					var nz = z + dz
					
					# Diffuse food pheromone
					var diffuse_amount = pheromone_map[nx][nz].food * pheromone_diffusion_rate
					diffused_map[x][z].food += diffuse_amount / 8.0  # Divide by number of neighbors
					diffused_map[nx][nz].food -= diffuse_amount
					
					# Diffuse home pheromone
					diffuse_amount = pheromone_map[nx][nz].home * pheromone_diffusion_rate
					diffused_map[x][z].home += diffuse_amount / 8.0
					diffused_map[nx][nz].home -= diffuse_amount
	
	pheromone_map = diffused_map

# Create visualization for pheromones (Legacy / Backup)
func create_debug_visualization() -> void:
	# Keep this basic visualizer function if needed, but the Shader does the job now.
	pass

# Update pheromone visualization (Legacy / Backup)
func update_pheromone_visualization() -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

