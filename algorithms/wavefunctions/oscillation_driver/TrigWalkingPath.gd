extends Node3D

## Trig Walking Path Demo
## Generates walkable paths from Sine and Cosine waves using individual steps
## Agent-VisualizationExpert: Procedural generation
## Protocol: IACP v2.2

# Parameters
@export var step_scene: PackedScene # Optional: Use a custom scene for steps
@export var frequency: float = 0.5
@export var amplitude: float = 2.0
@export var step_distance: float = 0.6 # Distance between steps along Z
@export var path_length: int = 40 # Number of steps to keep ahead
@export var generation_speed: float = 0.0 # If > 0, generates in real-time. If 0, static generation.
@export var lane_offset: float = 1.6

@export_category("Step Geometry")
@export var step_width: float = 1.8
@export var step_height: float = 0.2
@export var step_depth: float = 0.6
@export var start_height: float = 0.6
@export var end_height: float = -0.6

@export_category("Escalator Mode")
@export var escalator_mode: bool = false  # Animate steps like escalator
@export var escalator_speed: float = 0.6  # Speed of escalator movement
@export var escalator_direction: int = 1  # 1 = forward (down Z), -1 = backward (up Z)

@export_category("End Platforms")
@export var add_end_platforms: bool = true
@export var platform_size: Vector3 = Vector3(6.0, 0.25, 2.0)
@export var platform_color: Color = Color(0.2, 0.2, 0.25)
@export var platform_height_offset: float = -0.2

# Containers
@onready var sine_path: Node3D = $SinePath
@onready var cosine_path: Node3D = $CosinePath
var end_platforms: Node3D

# State
var current_z: float = 0.0
var generated_steps: Array[Node3D] = []
var sine_steps: Array[Node3D] = []
var cosine_steps: Array[Node3D] = []
var step_phase: float = 0.0  # Escalator phase offset

func _ready():
	# If no step scene is provided, we'll create a simple mesh instance programmatically
	_generate_initial_path()
	if add_end_platforms:
		_create_end_platforms()

func _generate_initial_path():
	for i in range(path_length):
		_add_step_pair(i)
		current_z -= step_distance

func _add_step_pair(index: int):
	# Initial z position based on index
	var z_pos: float = -index * step_distance
	
	# Calculate wave values based on index (will be animated in escalator mode)
	var t: float = index * step_distance * frequency
	
	var sin_y: float = _compute_step_y(z_pos, sin(t))
	var cos_y: float = _compute_step_y(z_pos, cos(t))
	
	# Create Sine Step (Left side)
	var step_sin := _create_step(Color(1.0, 0.3, 0.3))
	step_sin.position = Vector3(-lane_offset, sin_y, z_pos)
	step_sin.set_meta("index", index)
	sine_path.add_child(step_sin)
	sine_steps.append(step_sin)
	
	# Create Cosine Step (Right side)
	var step_cos := _create_step(Color(0.3, 0.5, 1.0))
	step_cos.position = Vector3(lane_offset, cos_y, z_pos)
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
	box.size = Vector3(step_width, step_height, step_depth) # Fill the step spacing
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
	step_phase += escalator_speed * delta
	
	var total_length: float = path_length * step_distance
	var half_length: float = total_length * 0.5
	
	# Update each step position
	for i in range(sine_steps.size()):
		var step_sin: Node3D = sine_steps[i]
		var step_cos: Node3D = cosine_steps[i]
		
		# Calculate position along the escalator
		var base_offset: float = i * step_distance
		var z_pos_sin: float = fposmod(base_offset + step_phase * escalator_direction, total_length) - half_length
		var z_pos_cos: float = fposmod(base_offset + step_phase * -escalator_direction, total_length) - half_length
		
		# Calculate wave height based on current position
		var t_sin: float = (z_pos_sin + half_length) * frequency
		var t_cos: float = (z_pos_cos + half_length) * frequency
		var sin_y: float = _compute_step_y(z_pos_sin, sin(t_sin))
		var cos_y: float = _compute_step_y(z_pos_cos, cos(t_cos))
		
		# Update positions
		step_sin.position = Vector3(-lane_offset, sin_y, z_pos_sin)
		step_cos.position = Vector3(lane_offset, cos_y, z_pos_cos)

func _create_end_platforms() -> void:
	if end_platforms and is_instance_valid(end_platforms):
		end_platforms.queue_free()

	end_platforms = Node3D.new()
	end_platforms.name = "EndPlatforms"
	add_child(end_platforms)

	var total_length: float = path_length * step_distance
	var half_length: float = total_length * 0.5

	var z_positions = [
		-half_length,
		half_length
	]
	var y_positions = [
		_platform_y_for_base(start_height),
		_platform_y_for_base(end_height)
	]

	for i in range(z_positions.size()):
		var z = z_positions[i]
		var y = y_positions[i]
		var body := StaticBody3D.new()
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = platform_size
		mesh_instance.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = platform_color
		mat.roughness = 0.8
		mesh_instance.material_override = mat
		body.add_child(mesh_instance)

		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = platform_size
		collision.shape = shape
		body.add_child(collision)

		body.position = Vector3(0.0, y, z)
		end_platforms.add_child(body)

func _compute_step_y(z_pos: float, wave_value: float) -> float:
	var total_length: float = path_length * step_distance
	if total_length <= 0.001:
		return 0.0

	var z_norm = clamp((z_pos + total_length * 0.5) / total_length, 0.0, 1.0)
	var base_y = lerp(start_height, end_height, z_norm)
	# Fade wave to 0 at ends so platforms are reachable
	var edge_fade = sin(PI * z_norm)
	return base_y + wave_value * amplitude * edge_fade

func _platform_y_for_base(base_y: float) -> float:
	return base_y + (step_height - platform_size.y) * 0.5 + platform_height_offset

func _process(_delta: float):
	if generation_speed > 0 and not escalator_mode:
		# Implement endless runner style generation here if needed
		pass
