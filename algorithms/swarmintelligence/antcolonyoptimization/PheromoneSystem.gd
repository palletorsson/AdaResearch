extends Node3D
class_name PheromoneSystem

# Pheromone system parameters
@export var terrain_reference: NodePath  # Reference to the terrain
@export var resolution: int = 100        # Resolution of the pheromone grid
@export var decay_rate: float = 0.995    # How quickly pheromones decay
@export var diffusion_rate: float = 0.1  # How quickly pheromones spread
@export var visualization_threshold: float = 0.2  # Minimum value to visualize

# Pheromone map
var pheromone_map = []
var terrain = null

# Visualization
var visualization_instance: MultiMeshInstance3D
var last_update_time = 0.0
@export var update_interval: float = 0.1  # Time between visualization updates

func _ready():
	# Get terrain reference
	if terrain_reference:
		terrain = get_node(terrain_reference)
	
	# Initialize pheromone grid
	initialize_pheromone_map()
	
	# Set up visualization
	setup_visualization()

# Initialize the pheromone grid
func initialize_pheromone_map():
	pheromone_map = []
	
	for x in range(resolution + 1):
		var row = []
		for z in range(resolution + 1):
			# Different types of pheromones
			row.append({
				"food": 0.0,    # Pheromone leading to food
				"home": 0.0     # Pheromone leading to nest
			})
		pheromone_map.append(row)

# Setup the visualization system
func setup_visualization():
	# Create a MultiMeshInstance for efficient rendering of particles
	visualization_instance = MultiMeshInstance3D.new()
	visualization_instance.name = "PheromoneVisualization"
	
	var multimesh = MultiMesh.new()
	
	# Create a small mesh for visualization
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	
	multimesh.mesh = sphere
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = 0
	
	visualization_instance.multimesh = multimesh
	add_child(visualization_instance)

# Add pheromone at a specific world position
func add_pheromone(world_pos: Vector3, type: String, amount: float):
	var grid_pos = world_to_grid(world_pos)
	var x = int(grid_pos.x)
	var y = int(grid_pos.y)
	
	if x >= 0 and x <= resolution and y >= 0 and y <= resolution:
		pheromone_map[x][y][type] += amount

# Get the strongest pheromone direction from a position
func get_pheromone_direction(world_pos: Vector3, type: String, perception_radius: int = 3) -> Vector3:
	var grid_pos = world_to_grid(world_pos)
	var center_x = int(grid_pos.x)
	var center_z = int(grid_pos.y)
	
	var strongest_value = 0.0
	var strongest_dir = Vector3.ZERO
	
	# Check in a radius around the position
	for dx in range(-perception_radius, perception_radius + 1):
		for dz in range(-perception_radius, perception_radius + 1):
			var x = center_x + dx
			var z = center_z + dz
			
			# Skip if out of bounds
			if x < 0 or x > resolution or z < 0 or z > resolution:
				continue
				
			# Skip current position
			if dx == 0 and dz == 0:
				continue
			
			var pheromone_value = pheromone_map[x][z][type]
			
			if pheromone_value > strongest_value:
				strongest_value = pheromone_value
				
				# Convert grid position to world position
				var world_x = x * terrain.size.x / resolution - terrain.size.x/2
				var world_z = z * terrain.size.y / resolution - terrain.size.y/2
				var world_y = terrain.get_height_at(world_x, world_z) + 0.1
				
				strongest_dir = Vector3(world_x, world_y, world_z) - world_pos
	
	return strongest_dir.normalized()

# Convert world position to grid indices
func world_to_grid(world_pos: Vector3) -> Vector2:
	if not terrain:
		return Vector2.ZERO
		
	var x_grid = int((world_pos.x + terrain.terrain_size.x/2) * resolution / terrain.terrain_size.x)
	var z_grid = int((world_pos.z + terrain.terrain_size.y/2) * resolution / terrain.terrain_size.y)
	
	# Clamp to valid grid indices
	x_grid = clamp(x_grid, 0, resolution)
	z_grid = clamp(z_grid, 0, resolution)
	
	return Vector2(x_grid, z_grid)

# Convert grid indices to world position
func grid_to_world(grid_x: int, grid_z: int) -> Vector3:
	if not terrain:
		return Vector3.ZERO
		
	var world_x = grid_x * terrain.terrain_size.x / resolution - terrain.terrain_size.x/2
	var world_z = grid_z * terrain.terrain_size.y / resolution - terrain.terrain_size.y/2
	var world_y = terrain.get_height_at(world_x, world_z) + 0.1
	
	return Vector3(world_x, world_y, world_z)

# Process function called every frame
func _process(delta):
	# Update pheromones
	process_pheromones(delta)
	
	# Update visualization periodically for better performance
	if Time.get_ticks_msec() - last_update_time > update_interval * 1000:
		update_visualization()
		last_update_time = Time.get_ticks_msec()

# Process pheromone decay and diffusion
func process_pheromones(delta):
	# Decay pheromones
	for x in range(resolution + 1):
		for z in range(resolution + 1):
			pheromone_map[x][z].food *= decay_rate
			pheromone_map[x][z].home *= decay_rate
	
	# Diffuse pheromones (simple diffusion to neighbors)
	var diffused_map = []
	for x in range(resolution + 1):
		var row = []
		for z in range(resolution + 1):
			row.append({
				"food": pheromone_map[x][z].food,
				"home": pheromone_map[x][z].home
			})
		diffused_map.append(row)
	
	for x in range(1, resolution):
		for z in range(1, resolution):
			# For each neighbor, get a small amount of pheromone
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					if dx == 0 and dz == 0:
						continue
					
					var nx = x + dx
					var nz = z + dz
					
					# Skip if out of bounds
					if nx < 0 or nx > resolution or nz < 0 or nz > resolution:
						continue
					
					# Diffuse food pheromone
					var diffuse_amount = pheromone_map[nx][nz].food * diffusion_rate
					diffused_map[x][z].food += diffuse_amount / 8.0  # Divide by number of neighbors
					diffused_map[nx][nz].food -= diffuse_amount
					
					# Diffuse home pheromone
					diffuse_amount = pheromone_map[nx][nz].home * diffusion_rate
					diffused_map[x][z].home += diffuse_amount / 8.0
					diffused_map[nx][nz].home -= diffuse_amount
	
	pheromone_map = diffused_map

# Update the visualization of pheromones
func update_visualization():
	if not visualization_instance or not terrain:
		return
	
	var multimesh = visualization_instance.multimesh
	
	# Count strong pheromones for visualization
	var visible_pheromones = []
	
	for x in range(0, resolution + 1, 2):  # Sample every other grid cell for performance
		for z in range(0, resolution + 1, 2):
			var food_pheromone = pheromone_map[x][z].food
			var home_pheromone = pheromone_map[x][z].home
			
			# Only visualize strong pheromones
			var max_pheromone = max(food_pheromone, home_pheromone)
			if max_pheromone > visualization_threshold:
				# Get world position
				var world_pos = grid_to_world(x, z)
				
				# Determine color based on dominant pheromone
				var color
				if food_pheromone > home_pheromone:
					color = Color(1.0, 0.2, 0.2, min(1.0, food_pheromone))  # Red for food
				else:
					color = Color(0.2, 0.2, 1.0, min(1.0, home_pheromone))  # Blue for home
				
				visible_pheromones.append({
					"position": world_pos,
					"color": color,
					"intensity": max_pheromone
				})
	
	# Update multimesh
	multimesh.instance_count = visible_pheromones.size()
	
	for i in range(visible_pheromones.size()):
		var pheromone = visible_pheromones[i]
		var transform = Transform3D()
		transform.origin = pheromone.position
		
		# Scale based on intensity
		var scale = 0.5 + pheromone.intensity * 0.5
		transform = transform.scaled(Vector3(scale, scale, scale))
		
		multimesh.set_instance_transform(i, transform)
		multimesh.set_instance_color(i, pheromone.color)

# Get pheromone value at a specific world position
func get_pheromone_value(world_pos: Vector3, type: String) -> float:
	var grid_pos = world_to_grid(world_pos)
	var x = int(grid_pos.x)
	var y = int(grid_pos.y)
	
	if x >= 0 and x <= resolution and y >= 0 and y <= resolution:
		return pheromone_map[x][y][type]
	
	return 0.0

# Clear all pheromones
func clear_pheromones():
	initialize_pheromone_map()
