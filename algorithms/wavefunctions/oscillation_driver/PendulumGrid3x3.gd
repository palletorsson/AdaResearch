extends Node3D

## 3x3 Double Pendulum Grid - Individual Canvas Version
## Each pendulum has its own canvas, avoiding coordinate mapping issues
## Agent-VisualizationExpert: Chaos grid visualization
## Protocol: IACP v2.2

const DoublePendulumScene = preload("res://algorithms/wavefunctions/oscillation_driver/DoublePendulum.tscn")

@export var grid_size: int = 3  # 3x3 grid
@export var cell_spacing: float = 5.0  # Space between each pendulum unit
@export var pendulum_scale: float = 0.5  # Scale factor for each pendulum unit

# Initial angle variations (degrees)
@export var base_theta1: float = 90.0
@export var base_theta2: float = 90.0
@export var angle_variation: float = 8.0  # Variation in degrees

var pendulums: Array[Node3D] = []

func _ready():
	_spawn_pendulum_grid()
	_setup_camera()

func _spawn_pendulum_grid():
	"""Spawn 9 complete DoublePendulum instances in a 3x3 grid"""
	# Calculate offset to center the grid
	var total_size = (grid_size - 1) * cell_spacing
	var offset = -total_size / 2.0
	
	for row in range(grid_size):
		for col in range(grid_size):
			var pendulum = _create_pendulum(row, col)
			
			# Position in grid (each unit is a complete pendulum with its own canvas)
			var x = offset + col * cell_spacing
			var y = offset + row * cell_spacing
			pendulum.position = Vector3(x, y, 0)
			
			# Scale down the entire unit
			pendulum.scale = Vector3.ONE * pendulum_scale
			
			add_child(pendulum)
			pendulums.append(pendulum)
	
	print("PendulumGrid3x3: Spawned %d independent pendulum units" % pendulums.size())

func _create_pendulum(row: int, col: int) -> Node3D:
	"""Create a complete DoublePendulum instance with its own canvas"""
	var pendulum = DoublePendulumScene.instantiate()
	pendulum.name = "Pendulum_%d_%d" % [row, col]
	
	# Vary initial angles for chaotic diversity
	var index = row * grid_size + col
	var theta1_offset = (index - 4) * angle_variation / 4.0  # -8 to +8 degrees
	var theta2_offset = ((index % 3) - 1) * angle_variation / 2.0  # Smaller variation
	
	pendulum.theta1_start = base_theta1 + theta1_offset
	pendulum.theta2_start = base_theta2 + theta2_offset
	
	# Disable individual camera (we use main camera)
	_disable_camera(pendulum)
	
	return pendulum

func _disable_camera(pendulum: Node3D):
	"""Disable camera from individual pendulum"""
	var camera = pendulum.get_node_or_null("Camera3D")
	if camera: 
		camera.queue_free()
	
	# Also disable WorldEnvironment (we use scene one)
	var env = pendulum.get_node_or_null("WorldEnvironment")
	if env: 
		env.queue_free()

func _setup_camera():
	"""Setup the main camera for the grid view"""
	if has_node("Camera3D"):
		return  # Already has camera
	
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	
	# Position camera to see entire grid
	var view_distance = grid_size * cell_spacing * 1.0
	camera.position = Vector3(0, 0, view_distance)
	camera.look_at(Vector3.ZERO)
	
	add_child(camera)

func get_pendulum_at(row: int, col: int) -> Node3D:
	"""Get pendulum at grid position"""
	var index = row * grid_size + col
	if index >= 0 and index < pendulums.size():
		return pendulums[index]
	return null

func reset_all_pendulums():
	"""Reset all pendulums to initial state"""
	for pendulum in pendulums:
		pendulum.theta1 = deg_to_rad(pendulum.theta1_start)
		pendulum.theta2 = deg_to_rad(pendulum.theta2_start)
		pendulum.omega1 = 0.0
		pendulum.omega2 = 0.0
		pendulum.trail_points.clear()
