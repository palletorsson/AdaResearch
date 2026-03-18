extends Node3D

# Config
@export var num_agents: int = 500
@export var grid_resolution: int = 256
@export var terrain_size: Vector2 = Vector2(50, 50)
@export var agent_scene: PackedScene

# Internal
var grid: PhysarumGrid
var p_image: Image
var p_texture: ImageTexture
var emission_centers = []
var markers = []
var dist_timer: float = 0.0
var dist_mode: int = 0
const DURATION = 20.0

# Nodes
@onready var result_mesh: MeshInstance3D = $ResultMesh

func _ready() -> void:
	# 1. Setup Grid
	grid = PhysarumGrid.new(grid_resolution, grid_resolution)
	
	# 2. Setup Texture
	p_image = grid.get_image()
	p_texture = ImageTexture.create_from_image(p_image)
	
	# 3. Apply to Shader
	if result_mesh:
		var mat = result_mesh.get_active_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("slime_texture", p_texture)
			
	# 4. Spawn Agents (Random Circle)
	if agent_scene:
		for i in range(num_agents):
			var agent = agent_scene.instantiate()
			add_child(agent)
			
			# Random pos in circle
			var angle = randf() * TAU
			var rad = randf() * 5.0
			var start_pos = Vector3(cos(angle)*rad, 0, sin(angle)*rad)
			
			agent.initialize(start_pos, grid, terrain_size)
			
	# 5. Start Sequence
	set_distribution(0)

func _physics_process(delta: float) -> void:
	# Sequence Logic
	dist_timer += delta
	if dist_timer >= DURATION:
		dist_timer = 0.0
		dist_mode = (dist_mode + 1) % 4
		set_distribution(dist_mode)

	# Update Grid Logic (Decay + Diffuse)
	grid.process_attractors(emission_centers)
	grid.process_step()
	
	# Update Texture
	p_image = grid.get_image()
	p_texture.update(p_image)

func set_distribution(mode: int) -> void:
	# Clear old
	emission_centers.clear()
	for m in markers: m.queue_free()
	markers.clear()
	
	print("Changing Physarum Distribution to: ", mode)
	
	match mode:
		0: # Triangle (Original)
			add_attractor(Vector3(0,0,0), 8.0)
			add_attractor(Vector3(15,0,15), 6.0)
			add_attractor(Vector3(-15,0,-15), 6.0)
		1: # Circle
			for i in range(8):
				var angle = i * (TAU / 8.0)
				var r = 20.0
				add_attractor(Vector3(cos(angle)*r, 0, sin(angle)*r), 5.0)
		2: # Line (Connector)
			add_attractor(Vector3(-20,0,0), 8.0)
			add_attractor(Vector3(20,0,0), 8.0)
			add_attractor(Vector3(0,0,10), 4.0) # Distraction
		3: # Random
			for i in range(5):
				var pos = Vector3(randf_range(-20,20), 0, randf_range(-20,20))
				add_attractor(pos, 6.0)

func add_attractor(pos_world: Vector3, radius: float) -> void:
	var grid_pos = _world_to_grid(pos_world)
	emission_centers.append({"x": grid_pos.x, "y": grid_pos.y, "radius": radius, "amount": 2.0})
	_spawn_marker(pos_world, radius)

func _spawn_marker(pos: Vector3, radius: float) -> void:
	var m = MeshInstance3D.new()
	m.mesh = SphereMesh.new()
	m.mesh.radius = radius * 0.4 # Scale visual to be slightly smaller than influence
	m.mesh.height = radius * 0.8
	m.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.set_surface_override_material(0, mat)
	add_child(m)
	markers.append(m)

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
