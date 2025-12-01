extends Node3D

## Trig Walking Path Demo
## Generates walkable paths from Sine and Cosine waves using individual steps
## Agent-VisualizationExpert: Procedural generation
## Protocol: IACP v2.2

# Parameters
@export var step_scene: PackedScene # Optional: Use a custom scene for steps
@export var frequency: float = 0.5
@export var amplitude: float = 2.0
@export var step_distance: float = 0.8 # Distance between steps along Z
@export var path_length: int = 50 # Number of steps to keep ahead
@export var generation_speed: float = 0.0 # If > 0, generates in real-time. If 0, static generation.

# Containers
@onready var sine_path: Node3D = $SinePath
@onready var cosine_path: Node3D = $CosinePath

# State
var current_z: float = 0.0
var generated_steps: Array[Node3D] = []

func _ready():
	# If no step scene is provided, we'll create a simple mesh instance programmatically
	_generate_initial_path()

func _generate_initial_path():
	for i in range(path_length):
		_add_step_pair(current_z)
		current_z -= step_distance

func _add_step_pair(z_pos: float):
	# Calculate wave values based on Z position (Time)
	# z_pos is negative moving forward, so we invert it for time
	var t = -z_pos * frequency
	
	var sin_y = sin(t) * amplitude
	var cos_y = cos(t) * amplitude
	
	# Create Sine Step (Left side)
	var step_sin = _create_step(Color(1.0, 0.3, 0.3))
	step_sin.position = Vector3(-2.0, sin_y, z_pos)
	sine_path.add_child(step_sin)
	
	# Create Cosine Step (Right side)
	var step_cos = _create_step(Color(0.3, 0.5, 1.0))
	step_cos.position = Vector3(2.0, cos_y, z_pos)
	cosine_path.add_child(step_cos)
	
	generated_steps.append(step_sin)
	generated_steps.append(step_cos)

func _create_step(color: Color) -> Node3D:
	# Create a StaticBody with Mesh and Collision
	var body = StaticBody3D.new()
	
	# Mesh
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 0.2, 0.6) # Wide enough to walk on
	mesh_instance.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh_instance.material_override = mat
	
	body.add_child(mesh_instance)
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	body.add_child(collision)
	
	return body

func _process(delta):
	if generation_speed > 0:
		# Implement endless runner style generation here if needed
		pass
