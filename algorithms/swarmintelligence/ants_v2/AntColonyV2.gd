extends Node3D

# @identity
# essence: ant.move() = gradient_ascent(pheromone_grid) + wander; pheromone_grid *= decay + diffuse — ant and environment co-evolve
# desire: to walk across the terrain floor and watch ant highways emerge beneath you — paths that existed as pure probability before they were paths
# critical_parameter: grid_resolution — at 64×64 trails look blotchy; at 256×256 the chemical landscape develops fine capillaries and branching structure
# triggers: two food clusters at asymmetric distances produce unequal trail widths as the colony allocates traffic proportional to yield and proximity
# emerges: trail Y-junctions that route ants to whichever food source is currently less depleted — an emergent load-balancer no one designed
# needs: [missing] no VR controls at all; no sliders for ant_count, evaporation, deposit_amount; learner cannot intervene with the colony in real time
# relationships: simpler predecessor to AntColonyOptimization (no quality weighting, no tandem running, no modes); AntColonyV2 is world-scale vs. ACO's compact heatmap
# truth: the map is written by the travelers — the territory and the route emerge together

@export var num_ants: int = 100
@export var terrain_size: Vector2 = Vector2(50, 50)
@export var grid_resolution: int = 256 # Higher res for better trails

@export var ant_scene: PackedScene

# Resources
var grid: PheromoneGrid
var p_texture: ImageTexture
var p_image: Image

# Nodes
# Nodes
@onready var terrain_mesh: MeshInstance3D = $ResultMesh

var emission_centers = []

func _ready() -> void:
	# Ensure Home Area detects Ants (Layer 2)
	var home_area = $HomeArea
	if home_area:
		home_area.collision_mask = 2

	# 1. Setup Grid
	grid = PheromoneGrid.new(grid_resolution, grid_resolution)
	
	# Home Emission (Type 0 = Home)
	var home_pos = _world_to_grid(Vector3.ZERO)
	emission_centers.append({
		"x": home_pos.x, "y": home_pos.y,
		"type": 0, "radius": 10.0, "amount": 5.0
	})
	
	# 2. Setup Texture
	p_image = grid.get_image()
	p_texture = ImageTexture.create_from_image(p_image)
	
	# 3. Setup Terrain Shader
	if terrain_mesh:
		var mat = terrain_mesh.get_active_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("pheromone_texture", p_texture)

	# 4. Spawn Ants
	if ant_scene:
		for i in range(num_ants):
			var ant = ant_scene.instantiate()
			add_child(ant)
			ant.initialize(Vector3.ZERO, grid, terrain_size)
	
	# 5. Spawn Food (Simple Mockup)
	_spawn_food_cluster(Vector3(15, 0, 15), 10)
	_spawn_food_cluster(Vector3(-15, 0, -10), 10)

func _spawn_food_cluster(pos: Vector3, radius: float) -> void:
	# Add to emission centers (Type 1 = Food)
	var grid_pos = _world_to_grid(pos)
	emission_centers.append({
		"x": grid_pos.x, "y": grid_pos.y,
		"type": 1, "radius": 10.0, "amount": 5.0
	})

	# Create a visual marker
	var mesh = MeshInstance3D.new()
	mesh.mesh = CylinderMesh.new()
	mesh.mesh.top_radius = 4.5
	mesh.mesh.bottom_radius = 4.5
	mesh.mesh.height = 0.5
	mesh.position = pos
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.0, 1.0, 0.0, 0.3)
	mesh.set_surface_override_material(0, mat)
	add_child(mesh)
	
	# Create Area3D for detection
	var area = Area3D.new()
	area.collision_mask = 2 # Detect Ants (Layer 2)
	var col = CollisionShape3D.new()
	col.shape = CylinderShape3D.new()
	col.shape.radius = 4.5
	area.add_child(col)
	area.position = pos
	area.body_entered.connect(_on_food_entered)
	add_child(area)

func _on_food_entered(body) -> void:
	if body is SimpleAnt:
		# print("Food found!")
		body.set_found_food()

func _physics_process(_delta):
	# 1. Source Emission
	grid.process_source_emission(emission_centers)
	
	# 2. Diffusion (Blur)
	grid.process_diffusion()
	
	# 3. Decay
	grid.process_decay()
	
	# Update Texture (Throttled?)
	# In V2 we want 60fps visuals if possible
	p_image = grid.get_image()
	p_texture.update(p_image)

# Home Area (Implicit at 0,0,0)
func _on_home_area_entered(body) -> void:
	if body is SimpleAnt:
		# print("Home reached!")
		body.set_reached_home()

func _world_to_grid(pos: Vector3) -> Vector2i:
	var gx = int(remap(pos.x, -terrain_size.x/2, terrain_size.x/2, 0, grid.width))
	var gy = int(remap(pos.z, -terrain_size.y/2, terrain_size.y/2, 0, grid.height))
	return Vector2i(gx, gy)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
