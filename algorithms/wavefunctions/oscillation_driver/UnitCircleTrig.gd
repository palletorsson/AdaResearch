extends Node3D

## Unit Circle Trig Demo
## Demonstrates how the Unit Circle produces Sine and Cosine waves
## Agent-VisualizationExpert: Math visualization
## Protocol: IACP v2.2

# The Driver (Unit Circle Ball)
@onready var driver_ball: MeshInstance3D = $DriverBall
@onready var connection_lines: MeshInstance3D = $ConnectionLines

# The Products (Wave Indicators)
@onready var sine_ball: MeshInstance3D = $SineBall
@onready var cosine_ball: MeshInstance3D = $CosineBall

# The Trails
@onready var sine_trail: MeshInstance3D = $SineTrail
@onready var cosine_trail: MeshInstance3D = $CosineTrail
var sine_mesh: ImmediateMesh
var cosine_mesh: ImmediateMesh

# Parameters
@export var radius: float = 1.5
@export var rotation_speed: float = 1.5 # Radians per second
@export var time_speed: float = 2.0 # Speed of Z-axis movement
@export var max_trail_length: int = 400
@export var projection_offset: float = 2.5 # Distance to project waves

var time: float = 0.0
var angle: float = 0.0
var sine_points: Array[Vector3] = []
var cosine_points: Array[Vector3] = []

func _ready():
	_setup_visuals()

func _setup_visuals():
	# Sine Trail (Red)
	sine_mesh = ImmediateMesh.new()
	sine_trail.mesh = sine_mesh
	var mat_sin = StandardMaterial3D.new()
	mat_sin.albedo_color = Color(1.0, 0.2, 0.2) # Red for Sine (Y)
	mat_sin.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_sin.use_point_size = true
	mat_sin.point_size = 3.0
	sine_trail.material_override = mat_sin
	
	# Cosine Trail (Blue)
	cosine_mesh = ImmediateMesh.new()
	cosine_trail.mesh = cosine_mesh
	var mat_cos = StandardMaterial3D.new()
	mat_cos.albedo_color = Color(0.2, 0.5, 1.0) # Blue for Cosine (X)
	mat_cos.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_cos.use_point_size = true
	mat_cos.point_size = 3.0
	cosine_trail.material_override = mat_cos
	
	# Connection Lines (Yellow)
	var mat_lines = StandardMaterial3D.new()
	mat_lines.albedo_color = Color(1.0, 1.0, 0.0)
	mat_lines.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	connection_lines.material_override = mat_lines
	connection_lines.mesh = ImmediateMesh.new()

func _process(delta):
	time += delta
	angle += rotation_speed * delta
	
	# --- THE DRIVER ---
	# Calculate position on Unit Circle
	var x = cos(angle) * radius
	var y = sin(angle) * radius
	
	driver_ball.position = Vector3(x, y, 0)
	
	# --- THE PROJECTIONS ---
	# Sine (Y-value) projected to the Right
	sine_ball.position = Vector3(radius + projection_offset, y, 0)
	
	# Cosine (X-value) projected Downwards
	cosine_ball.position = Vector3(x, -radius - projection_offset, 0)
	
	# --- TRAIL GENERATION ---
	# Sine Trail
	# Use local position relative to UnitCircleTrig node
	sine_points.push_front(sine_ball.position)
	_update_trail_points(sine_points, delta)
	_draw_trail(sine_mesh, sine_points)
	
	# Cosine Trail
	# Use local position relative to UnitCircleTrig node
	cosine_points.push_front(cosine_ball.position)
	_update_trail_points(cosine_points, delta)
	_draw_trail(cosine_mesh, cosine_points)
	
	# --- VISUALIZATION LINES ---
	_draw_connections()

func _update_trail_points(points: Array[Vector3], delta: float):
	# Move points along Z (Time)
	for i in range(points.size()):
		points[i].z -= time_speed * delta
	
	if points.size() > max_trail_length:
		points.pop_back()

func _draw_trail(mesh: ImmediateMesh, points: Array[Vector3]):
	mesh.clear_surfaces()
	if points.is_empty(): return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		mesh.surface_add_vertex(p)
	mesh.surface_end()

func _draw_connections():
	var mesh = connection_lines.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var center = driver_ball.position
	
	# Line to Sine (Horizontal)
	mesh.surface_add_vertex(center)
	mesh.surface_add_vertex(sine_ball.position)
	
	# Line to Cosine (Vertical)
	mesh.surface_add_vertex(center)
	mesh.surface_add_vertex(cosine_ball.position)
	
	# Line to Center (Radius)
	mesh.surface_add_vertex(Vector3.ZERO) # Center of UnitCircleTrig
	mesh.surface_add_vertex(center)
	
	mesh.surface_end()
