extends Node3D

## Pendulum Wave Demo
## Demonstrates a physical pendulum driving a wave generation
## The pendulum swings in X-Y, and the wave is drawn in Time (Z-axis)
## Agent-VisualizationExpert: Physics visualization
## Protocol: IACP v2.2

# The Driver (Pendulum)
@onready var pivot: Node3D = $Pivot
@onready var rod: MeshInstance3D = $Pivot/Rod
@onready var bob: MeshInstance3D = $Pivot/Bob

# The Product (Wave Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Physics Parameters
@export var length: float = 2.0
@export var gravity: float = 9.8
@export var initial_angle: float = 45.0 # Degrees
@export var damping: float = 0.0 # Air resistance

# Visualization Parameters
@export var time_speed: float = 2.0 # Speed of the "conveyor belt" (Z-axis)
@export var max_trail_length: int = 300

var time: float = 0.0
var angle: float = 0.0
var angular_velocity: float = 0.0
var angular_acceleration: float = 0.0
var trail_points: Array[Vector3] = []

func _ready() -> void:
	_setup_visuals()
	
	# Initialize pendulum
	angle = deg_to_rad(initial_angle)
	_update_pendulum_visuals()

func _setup_visuals() -> void:
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.8, 1.0) # Cyan wave
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 3.0
	trail_instance.material_override = material
	
	# Setup rod length visual
	rod.position.y = -length / 2.0
	rod.mesh.height = length
	bob.position.y = -length

func _process(delta: float) -> void:
	# --- PHYSICS SIMULATION (The Driver) ---
	# Simple Pendulum Equation: alpha = -(g/L) * sin(theta)
	angular_acceleration = -(gravity / length) * sin(angle)
	
	# Integrate
	angular_velocity += angular_acceleration * delta
	angular_velocity *= (1.0 - damping * delta) # Apply damping
	angle += angular_velocity * delta
	time += delta
	
	# Update Pendulum Transform
	_update_pendulum_visuals()
	
	# --- WAVE GENERATION (The Product) ---
	# The "Value" is the Bob's current position relative to the PendulumWave node
	var bob_local_pos = to_local(bob.global_position)
	
	# Add new point at the bob's current location (Z=0 relative to start)
	# We only care about X and Y from the bob, Z is the timeline
	trail_points.push_front(Vector3(bob_local_pos.x, bob_local_pos.y, 0.0))
	
	# Move all existing points along Z (Time flowing away)
	for i in range(trail_points.size()):
		trail_points[i].z -= time_speed * delta
	
	# Limit trail
	if trail_points.size() > max_trail_length:
		trail_points.pop_back()
	
	# Render
	_draw_trail()

func _update_pendulum_visuals() -> void:
	# Rotate pivot to match angle
	pivot.rotation.z = angle

func _draw_trail() -> void:
	trail_mesh.clear_surfaces()
	
	if trail_points.is_empty():
		return
		
	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail_points:
		trail_mesh.surface_add_vertex(p)
	trail_mesh.surface_end()
