extends Node3D

## Circle Spiral Demo
## Demonstrates a rotating driver creating a spiral (helix) in time
## Circular Motion + Linear Time = Spiral
## Agent-VisualizationExpert: Wave function visualization
## Protocol: IACP v2.2

# The Driver (Rotating Ball)
@onready var pivot: Node3D = $Pivot
@onready var ball: MeshInstance3D = $Pivot/Ball

# The Product (Spiral Trail)
@onready var trail_mesh: ImmediateMesh
@onready var trail_instance: MeshInstance3D = $Trail

# Parameters
@export var radius: float = 1.5
@export var rotation_speed: float = 2.0 # Radians per second
@export var time_speed: float = 2.0 # Speed of the "conveyor belt" (Z-axis)
@export var max_trail_length: int = 400

var time: float = 0.0
var trail_points: Array[Vector3] = []

func _ready():
	_setup_visuals()
	
	# Setup ball position
	ball.position.x = radius

func _setup_visuals():
	trail_mesh = ImmediateMesh.new()
	trail_instance.mesh = trail_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 0.8) # Magenta spiral
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.use_point_size = true
	material.point_size = 3.0
	trail_instance.material_override = material

func _process(delta):
	time += delta
	
	# --- THE DRIVER (Rotation) ---
	# Rotate the pivot
	pivot.rotate_z(rotation_speed * delta)
	
	# --- THE PRODUCT (Spiral) ---
	# The "Value" is the Ball's current world position (X, Y)
	var ball_pos = ball.global_position
	
	# Add new point at the ball's current location (Z=0 relative to start)
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
