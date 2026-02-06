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

@export_category("Escalator Mode")
@export var escalator_mode: bool = false  # Animate steps like escalator
@export var escalator_speed: float = 2.0  # Speed of escalator movement
@export var escalator_direction: int = 1  # 1 = forward (down Z), -1 = backward (up Z)

# Containers
@onready var sine_path: Node3D = $SinePath
@onready var cosine_path: Node3D = $CosinePath

# State
var current_z: float = 0.0
var generated_steps: Array[Node3D] = []
var sine_steps: Array[Node3D] = []
var cosine_steps: Array[Node3D] = []
var step_phase: float = 0.0  # Escalator phase offset

func _ready():
	# If no step scene is provided, we'll create a simple mesh instance programmatically
	_generate_initial_path()

func _generate_initial_path():
	for i in range(path_length):
		_add_step_pair(i)
		current_z -= step_distance

func _add_step_pair(index: int):
	# Initial z position based on index
	var z_pos: float = -index * step_distance
	
	# Calculate wave values based on index (will be animated in escalator mode)
	var t: float = index * step_distance * frequency
	
	var sin_y: float = sin(t) * amplitude
	var cos_y: float = cos(t) * amplitude
	
	# Create Sine Step (Left side)
	var step_sin := _create_step(Color(1.0, 0.3, 0.3))
	step_sin.position = Vector3(-2.0, sin_y, z_pos)
	step_sin.set_meta("index", index)
	sine_path.add_child(step_sin)
	sine_steps.append(step_sin)
	
	# Create Cosine Step (Right side)
	var step_cos := _create_step(Color(0.3, 0.5, 1.0))
	step_cos.position = Vector3(2.0, cos_y, z_pos)
	step_cos.set_meta("index", index)
	cosine_path.add_child(step_cos)
	cosine_steps.append(step_cos)
	
	generated_steps.append(step_sin)
	generated_steps.append(step_cos)

func _create_step(color: Color) -> Node3D:
	# Create a StaticBody with Mesh and Collision
	var body := StaticBody3D.new()
	
	# Mesh
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 0.2, 0.6) # Wide enough to walk on
	mesh_instance.mesh = box
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh_instance.material_override = mat
	
	body.add_child(mesh_instance)
	
	# Collision
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	body.add_child(collision)
	
	return body

func _physics_process(delta: float):
	if escalator_mode:
		_update_escalator(delta)

func _update_escalator(delta: float):
	# Advance the phase
	step_phase += escalator_speed * delta * escalator_direction
	
	var total_length: float = path_length * step_distance
	
	# Update each step position
	for i in range(sine_steps.size()):
		var step_sin: Node3D = sine_steps[i]
		var step_cos: Node3D = cosine_steps[i]
		
		# Calculate position along the escalator
		var base_offset: float = i * step_distance
		var z_pos: float = fposmod(base_offset + step_phase, total_length) - total_length * 0.5
		
		# Calculate wave height based on current position
		var t: float = (z_pos + total_length * 0.5) * frequency
		var sin_y: float = sin(t) * amplitude
		var cos_y: float = cos(t) * amplitude
		
		# Update positions
		step_sin.position = Vector3(-2.0, sin_y, z_pos)
		step_cos.position = Vector3(2.0, cos_y, z_pos)

func _process(delta: float):
	if generation_speed > 0 and not escalator_mode:
		# Implement endless runner style generation here if needed
		pass
