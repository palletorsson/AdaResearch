extends Node3D

## Double Helix Demo
## Demonstrates two rotating drivers creating a double helix (DNA structure)
## Agent-VisualizationExpert: Wave function visualization
## Protocol: IACP v2.2

# The Driver (Rotating Pivot)
@onready var pivot: Node3D = $Pivot
@onready var ball1: MeshInstance3D = $Pivot/Ball1
@onready var ball2: MeshInstance3D = $Pivot/Ball2

# The Products (Spiral Trails)
@onready var trail_instance1: MeshInstance3D = $Trail1
@onready var trail_instance2: MeshInstance3D = $Trail2
var trail_mesh1: ImmediateMesh
var trail_mesh2: ImmediateMesh

# Parameters
@export var radius: float = 1.5
@export var rotation_speed: float = 2.0 # Radians per second
@export var time_speed: float = 2.0 # Speed of the "conveyor belt" (Z-axis)
@export var max_trail_length: int = 400

var time: float = 0.0
var trail_points1: Array[Vector3] = []
var trail_points2: Array[Vector3] = []

func _ready():
	_setup_visuals()
	
	# Setup ball positions (180 degrees apart)
	ball1.position.x = radius
	ball2.position.x = -radius # Opposite side

func _setup_visuals():
	# Trail 1
	trail_mesh1 = ImmediateMesh.new()
	trail_instance1.mesh = trail_mesh1
	
	var material1 = StandardMaterial3D.new()
	material1.albedo_color = Color(0.0, 0.8, 1.0) # Cyan
	material1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material1.use_point_size = true
	material1.point_size = 3.0
	trail_instance1.material_override = material1
	
	# Trail 2
	trail_mesh2 = ImmediateMesh.new()
	trail_instance2.mesh = trail_mesh2
	
	var material2 = StandardMaterial3D.new()
	material2.albedo_color = Color(1.0, 0.0, 0.8) # Magenta
	material2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material2.use_point_size = true
	material2.point_size = 3.0
	trail_instance2.material_override = material2

func _process(delta):
	time += delta
	
	# --- THE DRIVER (Rotation) ---
	# Simple Z-axis rotation of the pivot
	pivot.rotate_z(rotation_speed * delta)
	
	# --- THE PRODUCTS (Spirals) ---
	# The balls move because they are children of the pivot
	_update_trail(ball1, trail_points1, trail_mesh1, delta)
	_update_trail(ball2, trail_points2, trail_mesh2, delta)

func _update_trail(ball: Node3D, points: Array[Vector3], mesh: ImmediateMesh, delta: float):
	# Get world position
	var ball_pos = ball.global_position
	
	# Add new point (Z=0 relative to start)
	points.push_front(Vector3(ball_pos.x, ball_pos.y, 0.0))
	
	# Move existing points along Z
	for i in range(points.size()):
		points[i].z -= time_speed * delta
	
	# Limit trail
	if points.size() > max_trail_length:
		points.pop_back()
	
	# Render
	mesh.clear_surfaces()
	if points.is_empty(): return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		mesh.surface_add_vertex(p)
	mesh.surface_end()
