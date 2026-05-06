class_name PulsingCA
extends BaseCA

# Visualizes CA cells as pulsing spheres.

@export var pulse_speed: float = 2.0
@export var pulse_amount: float = 0.3
@export var base_scale: float = 1.0
@export var demo_mode: bool = true

var sphere_mesh: SphereMesh

func _ready() -> void:
	super._ready()
	# Replace default cube mesh with sphere
	sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = CUBE_SIZE * VISUALIZATION_STEP * 0.4
	sphere_mesh.height = sphere_mesh.radius * 2
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	
	# Re-configure multimesh with sphere
	configure_multimesh(sphere_mesh, GRID_SIZE * GRID_SIZE * GRID_SIZE) # Max possible

func initialize_grid() -> void:
	grid = create_3d_grid()
	if demo_mode:
		# Randomly populate grid for demo purposes
		for i in range(100):
			var x = randi() % GRID_SIZE
			var y = randi() % GRID_SIZE
			var z = randi() % GRID_SIZE
			grid[x][y][z] = 1

func update_visualization() -> void:
	if not multi_mesh_instance: return
	
	var mm = multi_mesh_instance.multimesh
	var instance_idx = 0
	
	var time = Time.get_ticks_msec() / 1000.0
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] > 0:
					var pos = _grid_to_world(Vector3i(x, y, z))
					
					# Pulse effect
					var pulse = 1.0 + sin(time * pulse_speed + x * 0.1 + y * 0.1) * pulse_amount
					var scale = Vector3.ONE * pulse * base_scale
					
					var t = Transform3D(Basis().scaled(scale), pos)
					mm.set_instance_transform(instance_idx, t)
					
					# Color based on state or position
					var col = Color.from_hsv((x + y + z) * 0.01 + time * 0.1, 0.8, 1.0)
					mm.set_instance_color(instance_idx, col)
					
					instance_idx += 1
	
	mm.visible_instance_count = instance_idx

func _grid_to_world(pos: Vector3i) -> Vector3:
	return Vector3(
		(pos.x - GRID_SIZE/2) * CUBE_SIZE * VISUALIZATION_STEP,
		(pos.y - GRID_SIZE/2) * CUBE_SIZE * VISUALIZATION_STEP,
		(pos.z - GRID_SIZE/2) * CUBE_SIZE * VISUALIZATION_STEP
	)

func apply_grid_config(config: Dictionary) -> void:
	pass
