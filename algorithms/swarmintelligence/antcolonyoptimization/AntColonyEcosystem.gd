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
@export var pheromone_decay_rate: float = 0.995
@export var pheromone_diffusion_rate: float = 0.1
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

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize noise generator
	noise = FastNoiseLite.new()
	noise.seed = terrain_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	
	# Create the terrain
	generate_terrain()
	
	# Initialize pheromone map (2D grid matching terrain resolution)
	initialize_pheromone_map()
	
	# Place colony and food sources
	place_colony_and_food()
	
	# Spawn ants
	spawn_ants()
	
	# Debug visualization
	create_debug_visualization()

# Generate procedural terrain
func generate_terrain():
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
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.4, 0.2)
	material.metallic_specular = 0.1
	material.roughness = 0.9
	
	terrain_mesh.set_surface_override_material(0, material)
	add_child(terrain_mesh)

# Generate terrain height using noise
func generate_terrain_height(x: float, z: float) -> float:
	var base_height = noise.get_noise_2d(x * terrain_noise_scale, z * terrain_noise_scale)
	
	# Add some smaller detail noise
	var detail = noise.get_noise_2d(x * terrain_noise_scale * 4, z * terrain_noise_scale * 4) * 0.25
	
	# Combine and scale
	return (base_height + detail) * terrain_height_scale

# Initialize the pheromone map
func initialize_pheromone_map():
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
func place_colony_and_food():
	# Place colony in a suitable flat area near the center
	var center_x = 0
	var center_z = 0
	colony_position = Vector3(center_x, get_height_at(center_x, center_z) + 0.5, center_z)
	
	# Create colony visual representation
	var colony = MeshInstance3D.new()
	var colony_mesh = SphereMesh.new()
	colony_mesh.radius = 2.0
	colony_mesh.height = 4.0
	colony.mesh = colony_mesh
	
	var colony_material = StandardMaterial3D.new()
	colony_material.albedo_color = Color(0.6, 0.3, 0.1)
	colony.set_surface_override_material(0, colony_material)
	
	colony.position = colony_position
	add_child(colony)
	
	# Place food sources away from the colony
	for i in range(food_source_count):
		# Place food in random locations away from colony
		var angle = randf() * TAU
		var distance = 15.0 + randf() * 15.0
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
func spawn_ants():
	if ant_scene == null:
		# Create a simple ant representation if no scene is provided
		for i in range(num_ants):
			var ant = Ant.new()
			ant.initialize(self, colony_position, ant_speed)
			add_child(ant)
			ants.append(ant)
	else:
		# Instantiate provided ant scene
		for i in range(num_ants):
			var ant = ant_scene.instantiate()
			if ant.has_method("initialize"):
				ant.initialize(self, colony_position, ant_speed)
			add_child(ant)
			ants.append(ant)

# Create visualization for pheromones
func create_debug_visualization():
	# Create a MultiMeshInstance for efficient rendering of pheromone particles
	var pheromone_viz = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	
	# Create a small sphere mesh for pheromone visualization
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	
	multimesh.mesh = sphere
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 0  # Will be updated during simulation
	
	pheromone_viz.multimesh = multimesh
	pheromone_viz.name = "PheromoneVisualization"
	add_child(pheromone_viz)

# Update pheromone visualization
func update_pheromone_visualization():
	var pheromone_viz = get_node_or_null("PheromoneVisualization")
	if pheromone_viz == null:
		return
	
	var multimesh = pheromone_viz.multimesh
	
	# Count strong pheromones
	var strong_pheromones = []
	for x in range(terrain_resolution + 1):
		for z in range(terrain_resolution + 1):
			var food_pheromone = pheromone_map[x][z].food
			var home_pheromone = pheromone_map[x][z].home
			
			# Only visualize strong pheromones
			if food_pheromone > 0.2 or home_pheromone > 0.2:
				# Convert grid position to world position
				var world_x = x * terrain_size.x / terrain_resolution - terrain_size.x/2
				var world_z = z * terrain_size.y / terrain_resolution - terrain_size.y/2
				var world_y = get_height_at(world_x, world_z) + 0.1
				
				strong_pheromones.append({
					"position": Vector3(world_x, world_y, world_z),
					"food": food_pheromone,
					"home": home_pheromone
				})
	
	# Update multimesh
	multimesh.instance_count = strong_pheromones.size()
	
	for i in range(strong_pheromones.size()):
		var pheromone = strong_pheromones[i]
		var transform = Transform3D()
		transform.origin = pheromone.position
		
		# Color based on pheromone type
		var color = Color(0, 0, 1)  # Home (blue)
		if pheromone.food > pheromone.home:
			color = Color(1, 0, 0)  # Food (red)
		
		multimesh.set_instance_transform(i, transform)
		multimesh.set_instance_color(i, color)

# Process pheromones (decay and diffusion)
func process_pheromones(delta):
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

# Convert world position to pheromone grid indices
func world_to_grid(world_pos: Vector3) -> Vector2:
	var x_grid = int((world_pos.x + terrain_size.x/2) * terrain_resolution / terrain_size.x)
	var z_grid = int((world_pos.z + terrain_size.y/2) * terrain_resolution / terrain_size.y)
	
	# Clamp to valid grid indices
	x_grid = clamp(x_grid, 0, terrain_resolution)
	z_grid = clamp(z_grid, 0, terrain_resolution)
	
	return Vector2(x_grid, z_grid)

# Place pheromone at world position
func place_pheromone(world_pos: Vector3, type: String, amount: float):
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

# Process function called every frame
func _process(delta):
	# Update pheromones
	process_pheromones(delta)
	
	# Update visualization every few frames to improve performance
	if Engine.get_frames_drawn() % 10 == 0:
		update_pheromone_visualization()

# Ant class definition
class Ant extends Node3D:
	enum AntState { SEARCHING_FOOD, RETURNING_HOME }
	
	var state = AntState.SEARCHING_FOOD
	var speed = 2.0
	var simulation  # Reference to main simulation
	var current_position = Vector3.ZERO
	var direction = Vector3.FORWARD
	var random_timer = 0.0
	var carrying_food = false
	var home_position = Vector3.ZERO
	var last_pheromone_pos = Vector3.ZERO
	var pheromone_distance = 0.5  # Distance between pheromone placements
	
	# Initialize ant
	func initialize(sim, start_pos, ant_spd):
		simulation = sim
		position = start_pos
		speed = ant_spd
		home_position = start_pos
		
		# Add visual representation
		var mesh_instance = MeshInstance3D.new()
		var ant_shape = CapsuleMesh.new()
		ant_shape.radius = 0.1
		ant_shape.height = 0.5
		mesh_instance.mesh = ant_shape
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.1, 0.1, 0.1)  # Black ant
		mesh_instance.set_surface_override_material(0, material)
		
		add_child(mesh_instance)
		
		# Carrying food indicator
		var food_indicator = MeshInstance3D.new()
		var food_shape = SphereMesh.new()
		food_shape.radius = 0.1
		food_indicator.mesh = food_shape
		food_indicator.position = Vector3(0, 0.2, 0)
		food_indicator.visible = false
		food_indicator.name = "FoodIndicator"
		
		var food_material = StandardMaterial3D.new()
		food_material.albedo_color = Color(0.1, 0.8, 0.1)  # Green food
		food_indicator.set_surface_override_material(0, food_material)
		
		add_child(food_indicator)
	
	# Process ant behavior
	func _process(delta):
		# Update random direction timer
		random_timer -= delta
		
		# Get terrain height at current position and adjust ant's height
		var terrain_height = simulation.get_height_at(position.x, position.z)
		position.y = terrain_height + 0.2  # Offset to stay above terrain
		
		match state:
			AntState.SEARCHING_FOOD:
				process_searching_food(delta)
			AntState.RETURNING_HOME:
				process_returning_home(delta)
		
		# Update ant position and orientation
		global_position = position
		
		# Orient ant in direction of travel
		if direction.length() > 0.1:
			look_at(position + direction, Vector3.UP)
		
		# Update food indicator visibility
		var food_indicator = get_node_or_null("FoodIndicator")
		if food_indicator:
			food_indicator.visible = carrying_food
	
	# Process behavior when searching for food
	func process_searching_food(delta):
		# Check if we're at a food source
		var result = simulation.find_closest_food(position)
		var closest_food = result.food
		var distance = result.distance
		
		if closest_food and distance < 1.0:
			# Take food and switch state
			if simulation.take_food_from_source(closest_food):
				carrying_food = true
				state = AntState.RETURNING_HOME
				
				# Reset pheromone tracking
				last_pheromone_pos = position
				return
		
		# Leave home pheromone trail when searching for food
		if position.distance_to(last_pheromone_pos) >= pheromone_distance:
			simulation.place_pheromone(position, "home", 1.0)
			last_pheromone_pos = position
		
		# Determine direction
		var new_direction = Vector3.ZERO
		
		# Follow food pheromone if present
		var pheromone_direction = simulation.get_pheromone_direction(position, "food")
		
		if pheromone_direction != Vector3.ZERO:
			new_direction += pheromone_direction * 2.0  # Give higher weight to pheromone trail
		
		# Add random movement if timer expired
		if random_timer <= 0:
			var random_angle = randf() * TAU
			var random_dir = Vector3(cos(random_angle), 0, sin(random_angle))
			new_direction += random_dir
			random_timer = 1.0 + randf() * 2.0  # 1-3 seconds
		
		# Normalize and update direction
		if new_direction != Vector3.ZERO:
			direction = new_direction.normalized()
		
		# Move ant
		position += direction * speed * delta
	
	# Process behavior when returning to colony
	func process_returning_home(delta):
		# Check if we're back at the colony
		var distance_to_home = position.distance_to(home_position)
		
		if distance_to_home < 1.5:
			# Drop food and switch state
			carrying_food = false
			state = AntState.SEARCHING_FOOD
			
			# Reset pheromone tracking
			last_pheromone_pos = position
			return
		
		# Leave food pheromone trail when returning home
		if position.distance_to(last_pheromone_pos) >= pheromone_distance:
			simulation.place_pheromone(position, "food", 1.0)
			last_pheromone_pos = position
		
		# Determine direction
		var new_direction = Vector3.ZERO
		
		# Vector towards home
		var home_dir = (home_position - position).normalized()
		new_direction += home_dir
		
		# Follow home pheromone if present
		var pheromone_direction = simulation.get_pheromone_direction(position, "home")
		
		if pheromone_direction != Vector3.ZERO:
			new_direction += pheromone_direction
		
		# Add small random movement
		if random_timer <= 0:
			var random_angle = randf() * TAU
			var random_dir = Vector3(cos(random_angle), 0, sin(random_angle))
			new_direction += random_dir * 0.3  # Lower weight for randomness when returning
			random_timer = 1.0 + randf() * 2.0
		
		# Normalize and update direction
		if new_direction != Vector3.ZERO:
			direction = new_direction.normalized()
		
		# Move ant
		position += direction * speed * delta
