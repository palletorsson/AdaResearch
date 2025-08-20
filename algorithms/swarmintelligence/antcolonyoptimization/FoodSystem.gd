extends Node3D
class_name FoodSystem

# Food system parameters
@export var terrain_path: NodePath
@export var colony_path: NodePath
@export var initial_food_sources: int = 5
@export var food_per_source: int = 100
@export var food_respawn_time: float = 120.0  # 2 minutes
@export var min_food_distance: float = 10.0
@export var max_food_distance: float = 30.0

# References
var terrain
var colony
var food_sources = []
var respawn_timer = 0.0

func _ready():
	# Get references
	if terrain_path:
		terrain = get_node(terrain_path)
	
	if colony_path:
		colony = get_node(colony_path)
	
	# Create initial food sources
	for i in range(initial_food_sources):
		create_food_source()

func _process(delta):
	# Handle food respawning
	process_food_respawn(delta)

# Process food respawning
func process_food_respawn(delta):
	respawn_timer -= delta
	
	if respawn_timer <= 0:
		# Check if we need to spawn more food
		var depleted_sources = 0
		for food in food_sources:
			if food.amount <= 0:
				depleted_sources += 1
		
		# Respawn depleted sources or create new ones
		if depleted_sources > 0:
			for i in range(min(depleted_sources, 2)):  # Max 2 sources per timer
				create_food_source()
			
		respawn_timer = food_respawn_time

# Create a new food source
func create_food_source():
	var food_position = get_random_food_position()
	
	# Create food source data
	var food_source = {
		"position": food_position,
		"amount": food_per_source,
		"max_amount": food_per_source,
		"visual": null
	}
	
	# Create visual representation
	var food_visual = create_food_visual(food_source)
	food_source.visual = food_visual
	
	# Add to scene
	add_child(food_visual)
	
	# Add to sources list
	food_sources.append(food_source)
	
	# Inform colony
	if colony and colony.has_method("add_food_source"):
		colony.add_food_source(food_source)

# Create visual representation for food
func create_food_visual(food_source) -> Node3D:
	var food_node = Node3D.new()
	food_node.position = food_source.position
	
	# Main food pile
	var food_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.2
	cylinder.height = 0.3
	food_mesh.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 0.2)  # Green for food
	food_mesh.set_surface_override_material(0, material)
	
	food_node.add_child(food_mesh)
	
	# Food particles (small bits on top)
	var particles = create_food_particles()
	food_node.add_child(particles)
	
	# Add food info display
	var info = Label3D.new()
	info.position = Vector3(0, 1.0, 0)
	info.pixel_size = 0.01
	#info.billboard = Label3D.BILLBOARD_ENABLED
	info.text = "Food: " + str(food_source.amount)
	info.name = "InfoLabel"
	
	food_node.add_child(info)
	
	return food_node

# Create particles for food visual
func create_food_particles() -> Node3D:
	var particles = Node3D.new()
	
	# Create several small spheres randomly placed
	for i in range(10):
		var angle = randf() * TAU
		var distance = randf() * 0.8
		var x = cos(angle) * distance
		var z = sin(angle) * distance
		
		var sphere = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.1 + randf() * 0.1
		mesh.height = mesh.radius * 2
		sphere.mesh = mesh
		
		sphere.position = Vector3(x, 0.2, z)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.7, 0.2).lerp(Color(0.4, 0.9, 0.4), randf())
		sphere.set_surface_override_material(0, material)
		
		particles.add_child(sphere)
	
	return particles

# Get a random position for new food
func get_random_food_position() -> Vector3:
	var position = Vector3.ZERO
	var valid_position = false
	var attempts = 0
	
	while not valid_position and attempts < 20:
		attempts += 1
		
		# Start from colony position if available
		var start_pos = Vector3.ZERO
		if colony:
			start_pos = colony.position
		
		# Random angle and distance
		var angle = randf() * TAU
		var distance = min_food_distance + randf() * (max_food_distance - min_food_distance)
		
		# Calculate position
		var x = start_pos.x + cos(angle) * distance
		var z = start_pos.z + sin(angle) * distance
		
		# Get terrain height
		var y = 0
		if terrain and terrain.has_method("get_height_at"):
			y = terrain.get_height_at(x, z) + 0.2
		
		position = Vector3(x, y, z)
		
		# Check distance to other food sources
		valid_position = true
		for food in food_sources:
			if position.distance_to(food.position) < min_food_distance * 0.5:
				valid_position = false
				break
	
	return position

# Update food source visuals based on amount
func update_food_visuals():
	for food in food_sources:
		if food.visual:
			# Update size based on amount
			var scale_factor = max(0.1, float(food.amount) / food.max_amount)
			food.visual.scale = Vector3(scale_factor, scale_factor, scale_factor)
			
			# Update label
			var label = food.visual.get_node_or_null("InfoLabel")
			if label:
				label.text = "Food: " + str(food.amount)
				
				# Hide label if food is depleted
				label.visible = food.amount > 0

# Take food from a source
func take_food_from_source(source, amount: float = 1.0) -> float:
	if source.amount <= 0:
		return 0.0
	
	var taken = min(source.amount, amount)
	source.amount -= taken
	
	# Update visual
	if source.visual:
		var scale_factor = max(0.1, float(source.amount) / source.max_amount)
		source.visual.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# Update label
		var label = source.visual.get_node_or_null("InfoLabel")
		if label:
			label.text = "Food: " + str(source.amount)
			
			# Hide label if food is depleted
			label.visible = source.amount > 0
	
	return taken
