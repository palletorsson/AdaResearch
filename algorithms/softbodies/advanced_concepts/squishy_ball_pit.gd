extends Node3D

@export var spawn_count: int = 30
@export var spawn_interval: float = 0.5
@export var container_size: Vector3 = Vector3(5, 8, 5)

var _spawned_count = 0
var _timer: Timer

func _ready() -> void:
	setup_scene()
	setup_container()
	
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.timeout.connect(_on_spawn_timer)
	add_child(_timer)
	_timer.start()

func setup_scene() -> void:
	var cam = Camera3D.new()
	cam.position = Vector3(0, 5, 12)
	cam.look_at(Vector3(0, 2, 0))
	add_child(cam)
	
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 20, 10)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment = environment
	add_child(env)

func setup_container() -> void:
	var container = Node3D.new()
	container.name = "Container"
	add_child(container)
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.3)
	glass_mat.roughness = 0.1
	glass_mat.refraction_enabled = true
	glass_mat.refraction_scale = 0.05
	
	var thickness = 5.0
	var half_w = container_size.x / 2.0
	var half_d = container_size.z / 2.0
	var h = container_size.y
	
	# Floor (extended to cover under walls)
	create_wall(container, Vector3(container_size.x + thickness * 2, thickness, container_size.z + thickness * 2), Vector3(0, -thickness/2.0, 0), glass_mat)
	
	# Walls (extended to overlap corners)
	# Left/Right walls extend along Z
	create_wall(container, Vector3(thickness, h, container_size.z + thickness * 2), Vector3(-half_w - thickness/2.0, h/2.0, 0), glass_mat) # Left
	create_wall(container, Vector3(thickness, h, container_size.z + thickness * 2), Vector3(half_w + thickness/2.0, h/2.0, 0), glass_mat) # Right
	
	# Front/Back walls extend along X
	create_wall(container, Vector3(container_size.x + thickness * 2, h, thickness), Vector3(0, h/2.0, -half_d - thickness/2.0), glass_mat) # Back
	create_wall(container, Vector3(container_size.x + thickness * 2, h, thickness), Vector3(0, h/2.0, half_d + thickness/2.0), glass_mat) # Front

func create_wall(parent, size, pos, mat) -> void:
	var body = StaticBody3D.new()
	body.position = pos
	
	var mesh = BoxMesh.new()
	mesh.size = size
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	(col.shape as BoxShape3D).size = size
	body.add_child(col)
	
	parent.add_child(body)

func _on_spawn_timer() -> void:
	if _spawned_count >= spawn_count:
		_timer.stop()
		return
		
	spawn_soft_body()
	_spawned_count += 1

func spawn_soft_body() -> void:
	var sb = SoftBody3D.new()
	
	# Random shape: Sphere or Box (Box as SoftBody needs subdivided cube)
	# Let's stick to Spheres for better stability and "ball pit" feel, maybe some cubes if we have a mesh.
	# We'll use SphereMesh.
	
	var mesh = SphereMesh.new()
	mesh.radius = randf_range(0.4, 0.7)
	mesh.height = mesh.radius * 2
	mesh.radial_segments = 16
	mesh.rings = 8
	sb.mesh = mesh
	
	sb.position = Vector3(
		randf_range(-1.0, 1.0),
		container_size.y + 2.0,
		randf_range(-1.0, 1.0)
	)
	
	sb.total_mass = 1.0
	sb.linear_stiffness = 0.4 # Slightly stiffer
	sb.pressure_coefficient = 0.5 # Squishy
	sb.damping_coefficient = 0.05
	sb.simulation_precision = 20 # Higher precision
	
	# Gummy Material
	var mat = StandardMaterial3D.new()
	var hue = randf()
	mat.albedo_color = Color.from_hsv(hue, 0.8, 0.9, 1.0)
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color.from_hsv(hue, 0.8, 0.9) * 0.2
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.5
	
	sb.material_override = mat
	
	# Enable collision with layer 1 (default) and 20 (player)
	sb.collision_layer = 1
	sb.collision_mask = 1 | 524288
	
	add_child(sb)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

