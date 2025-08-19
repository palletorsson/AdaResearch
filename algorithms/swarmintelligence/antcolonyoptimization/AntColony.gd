extends Node3D
class_name AntColony

# Colony properties
@export var colony_size: float = 2.0
@export var colony_color: Color = Color(0.6, 0.3, 0.1)
@export var max_food_capacity: float = 1000.0
@export var initial_ant_count: int = 50
@export var max_ant_count: int = 200
@export var new_ant_food_cost: float = 10.0
@export var ant_scene: PackedScene
@export var terrain_path: NodePath
@export var pheromone_system_path: NodePath

# Food and resources
var stored_food: float = 100.0
var food_sources = []

# Internal state
var ants = []
var terrain = null
var pheromone_system = null
var colony_entrance: Vector3
var spawn_timer: float = 0.0
var display_info: Label3D

func _ready():
	# Get references
	if terrain_path:
		terrain = get_node(terrain_path)
	
	if pheromone_system_path:
		pheromone_system = get_node(pheromone_system_path)
	
	# Create colony mesh
	create_colony_mesh()
	
	# Add information display
	create_info_display()
	
	# Spawn initial ants
	spawn_initial_ants()

func _process(delta):
	# Handle colony growth
	process_colony_growth(delta)
	
	# Update information display
	update_info_display()

# Create the visual representation of the colony
func create_colony_mesh():
	# Main colony mound
	var mound = MeshInstance3D.new()
	var mound_mesh = SphereMesh.new()
	mound_mesh.radius = colony_size
	mound_mesh.height = colony_size * 1.5
	mound.mesh = mound_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = colony_color
	material.roughness = 0.9
	mound.set_surface_override_material(0, material)
	
	add_child(mound)
	
	# Colony entrance
	var entrance = MeshInstance3D.new()
	var entrance_mesh = CylinderMesh.new()
	entrance_mesh.top_radius = colony_size * 0.2
	entrance_mesh.bottom_radius = colony_size * 0.3
	entrance_mesh.height = colony_size * 0.5
	entrance.mesh = entrance_mesh
	entrance.position = Vector3(0, 0, -colony_size * 0.5)
	entrance.rotation_degrees = Vector3(90, 0, 0)
	
	var entrance_material = StandardMaterial3D.new()
	entrance_material.albedo_color = Color(0.1, 0.05, 0)  # Dark entrance
	entrance.set_surface_override_material(0, entrance_material)
	
	add_child(entrance)
	
	# Remember entrance position for ant spawning
	colony_entrance = entrance.global_position
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = colony_size
	collision.shape = sphere_shape
	
	add_child(collision)

# Create information display for the colony
func create_info_display():
	display_info = Label3D.new()
	display_info.position = Vector3(0, colony_size + 1, 0)
	display_info.pixel_size = 0.01
	display_info.font_size = 24
	display_info.modulate = Color(1, 1, 1)
	#display_info.billboard = Label3D.BILLBOARD_ENABLED
	display_info.text = "Colony Information"
	display_info.outline_size = 1
	
	add_child(display_info)

# Update the colony information display
func update_info_display():
	if display_info:
		display_info.text = "Colony Stats:\n"
		display_info.text += "Food: " + str(int(stored_food)) + " / " + str(int(max_food_capacity)) + "\n"
		display_info.text += "Ants: " + str(ants.size()) + " / " + str(max_ant_count) + "\n"
		
		# Count ants by state
		var foragers = 0
		var returners = 0
		var others = 0
		
		for ant in ants:
			if ant.state == ant.AntState.SEARCHING_FOOD:
				foragers += 1
			elif ant.state == ant.AntState.RETURNING_HOME:
				returners += 1
			else:
				others += 1
				
		display_info.text += "Foragers: " + str(foragers) + "\n"
		display_info.text += "Returners: " + str(returners) + "\n"
		display_info.text += "Others: " + str(others)

# Spawn the initial ants
func spawn_initial_ants():
	for i in range(initial_ant_count):
		spawn_ant()

# Process colony growth
func process_colony_growth(delta):
	# Update spawn timer
	spawn_timer -= delta
	
	# Check if we can spawn a new ant
	if spawn_timer <= 0 and stored_food >= new_ant_food_cost and ants.size() < max_ant_count:
		spawn_ant()
		stored_food -= new_ant_food_cost
		spawn_timer = 10.0  # 10 seconds between new ants

# Spawn a new ant
func spawn_ant():
	var ant
	
	if ant_scene:
		# Instantiate from scene
		ant = ant_scene.instantiate()
	else:
		# Create a basic ant
		ant = load("res://algorithms/swarmintelligence/antcolonyoptimization/AntAgent.gd").new()
	
	# Set properties
	ant.colony_color = colony_color
	
	# Add to scene
	add_child(ant)
	
	# Initialize ant
	var spawn_pos = get_spawn_position()
	ant.position = spawn_pos
	
	if ant.has_method("initialize"):
		ant.initialize(self, pheromone_system, terrain, food_sources)
	
	# Track the ant
	ants.append(ant)

# Get a position to spawn a new ant
func get_spawn_position() -> Vector3:
	# Random point around colony entrance
	var angle = randf() * TAU
	var distance = randf() * colony_size * 0.5
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	
	var spawn_pos = colony_entrance + offset
	
	# Adjust height to terrain
	if terrain and terrain.has_method("get_height_at"):
		spawn_pos.y = terrain.get_height_at(spawn_pos.x, spawn_pos.z) + 0.1
	
	return spawn_pos

# Add a food source to the colony's knowledge
func add_food_source(food_source):
	if not food_source in food_sources:
		food_sources.append(food_source)
		
	# Inform all ants about the new food source
	for ant in ants:
		if ant.has_method("update_food_sources"):
			ant.update_food_sources(food_sources)

# Deposit food into the colony storage
func deposit_food(amount: float):
	stored_food = min(stored_food + amount, max_food_capacity)

# Set the colony's terrain reference
func set_terrain(terrain_ref):
	terrain = terrain_ref
	
	# Update position height to match terrain
	if terrain and terrain.has_method("get_height_at"):
		var height = terrain.get_height_at(position.x, position.z)
		position.y = height

# Set the colony's pheromone system reference
func set_pheromone_system(pheromone_sys):
	pheromone_system = pheromone_sys

# Remove an ant from the colony
func remove_ant(ant):
	if ant in ants:
		ants.erase(ant)
		ant.queue_free()
