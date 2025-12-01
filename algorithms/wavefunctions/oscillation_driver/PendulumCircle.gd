extends Node3D

## Pendulum Circle Demo
## Demonstrates compound motion: A rotating circle attached to a swinging pendulum
## "The circle rotation hangs on a pendulum"
## Agent-VisualizationExpert: Complex wave function visualization
## Protocol: IACP v2.2

# The Primary Driver (Pendulum)
@onready var pendulum_pivot: Node3D = $PendulumPivot
@onready var rod: MeshInstance3D = $PendulumPivot/Rod
@onready var bob_center: Node3D = $PendulumPivot/BobCenter

# The Secondary Driver (Circle)
@onready var circle_pivot: Node3D = $PendulumPivot/BobCenter/CirclePivot
@onready var ball: MeshInstance3D = $PendulumPivot/BobCenter/CirclePivot/Ball

# The Product (Complex Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Physics Parameters (Pendulum)
@export var pendulum_length: float = 2.5
@export var gravity: float = 9.8
@export var initial_angle: float = 30.0 # Degrees
@export var pendulum_damping: float = 0.1

# Motion Parameters (Circle)
@export var circle_radius: float = 0.8
@export var rotation_speed: float = 5.0 # Radians per second

# Visualization Parameters
@export var time_speed: float = 2.0 # Speed of the "conveyor belt" (Z-axis)
@export var max_trail_length: int = 500

var time: float = 0.0
var pendulum_angle: float = 0.0
var pendulum_velocity: float = 0.0
var trail_points: Array[Vector3] = []

func _ready():
	_setup_visuals()
	
	# Initialize pendulum
	pendulum_angle = deg_to_rad(initial_angle)
	
	# Setup structure dimensions
	rod.position.y = -pendulum_length / 2.0
	rod.mesh.height = pendulum_length
	bob_center.position.y = -pendulum_length
	ball.position.x = circle_radius

func _setup_visuals():
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 1.0, 0.5) # Spring Green trail
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 2.0
	trail_instance.material_override = material

func _process(delta):
	time += delta
	
	# --- 1. PENDULUM PHYSICS ---
	# Acceleration = -(g/L) * sin(theta)
	var accel = -(gravity / pendulum_length) * sin(pendulum_angle)
	
	pendulum_velocity += accel * delta
	pendulum_velocity *= (1.0 - pendulum_damping * delta)
	pendulum_angle += pendulum_velocity * delta
	
	# Apply to pivot
	pendulum_pivot.rotation.z = pendulum_angle
	
	# --- 2. CIRCLE ROTATION ---
	# Rotate the circle pivot relative to the pendulum
	circle_pivot.rotate_z(rotation_speed * delta)
	
	# --- 3. TRAIL GENERATION ---
	# Get absolute world position of the ball
	var ball_pos = ball.global_position
	
	# Add new point (using X and Y from ball, Z starts at 0)
	trail_points.push_front(Vector3(ball_pos.x, ball_pos.y, 0.0))
	
	# Move all existing points along Z (Time flowing away)
	for i in range(trail_points.size()):
		trail_points[i].z -= time_speed * delta
	
	# Limit trail
	if trail_points.size() > max_trail_length:
		trail_points.pop_back()
	
	# Render
	_draw_trail()

func _draw_trail():
	trail_mesh.clear_surfaces()
	
	if trail_points.is_empty():
		return
		
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail_points:
		trail_mesh.surface_add_vertex(p)
	trail_mesh.surface_end()
