# rotation_cube.gd - A cube that rotates to create walkable surfaces
# Demonstrates: rotation creates alignment, 90° is the unit of cubic geometry
extends Node3D

class_name RotationCube

# Rotation mode
enum RotationMode { STEP_PAUSE, CONTINUOUS }

@export var mode: RotationMode = RotationMode.STEP_PAUSE
@export var cube_size: float = 2.2  # Size so diagonal (2.2 * √2 ≈ 3.1) fills 3m gap

# Step-pause mode settings (rotate, stop, rotate back)
@export var rotation_angle: float = 45.0  # Degrees to rotate
@export var rotation_axis: Vector3 = Vector3.UP  # Y axis default
@export var rotation_speed: float = 45.0  # Degrees per second
@export var pause_duration: float = 4.0  # Seconds to pause at each end (longer for walkability)

# Continuous mode settings
@export var continuous_axis: Vector3 = Vector3.RIGHT  # X axis for rolling
@export var continuous_speed: float = 30.0  # Degrees per second

# Position
@export var y_offset: float = 0.0  # Vertical offset for alignment

# Visual - orange theme for rotation
@export var fill_color: Color = Color(1.0, 0.5, 0.1, 1.0)
@export var wireframe_color: Color = Color(1.0, 0.8, 0.0, 1.0)

# Internal state
var current_angle: float = 0.0
var target_angle: float = 0.0
var is_rotating: bool = false
var is_forward: bool = true
var pause_timer: float = 0.0

# Components
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D

func _ready() -> void:
	create_cube()
	
	if mode == RotationMode.STEP_PAUSE:
		pause_timer = pause_duration
	
	# Apply y offset
	position.y += y_offset
	
	print("RotationCube: %.2fm cube, mode=%s, pause=%.1fs, y_offset=%.1f" % [cube_size, "step-pause" if mode == RotationMode.STEP_PAUSE else "continuous", pause_duration, y_offset])

func create_cube() -> void:
	# Create mesh
	mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(cube_size, cube_size, cube_size)
	mesh_instance.mesh = box_mesh
	
	# Load and apply Grid shader (matching transport_cube parameters)
	var shader = load("res://commons/resourses/shaders/Grid.gdshader")
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("modelColor", fill_color)
		material.set_shader_parameter("wireframeColor", wireframe_color)
		material.set_shader_parameter("emissionColor", wireframe_color)
		material.set_shader_parameter("width", 3.713)
		material.set_shader_parameter("blur", 0.581)
		material.set_shader_parameter("emission_strength", 0.458)
		material.set_shader_parameter("show_interior", true)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var material = StandardMaterial3D.new()
		material.albedo_color = fill_color
		material.emission_enabled = true
		material.emission = wireframe_color
		material.emission_energy_multiplier = 1.5
		mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	# Create static body for collision (walkable)
	static_body = StaticBody3D.new()
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(cube_size, cube_size, cube_size)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)

func _process(delta: float) -> void:
	match mode:
		RotationMode.STEP_PAUSE:
			process_step_pause(delta)
		RotationMode.CONTINUOUS:
			process_continuous(delta)
	
	# Sync collision with mesh
	static_body.transform = mesh_instance.transform

func process_step_pause(delta: float) -> void:
	if pause_timer > 0:
		pause_timer -= delta
		if pause_timer <= 0:
			is_rotating = true
			target_angle = rotation_angle if is_forward else 0.0
		return
	
	if is_rotating:
		var direction = 1.0 if target_angle > current_angle else -1.0
		current_angle += direction * rotation_speed * delta
		
		if (direction > 0 and current_angle >= target_angle) or \
		   (direction < 0 and current_angle <= target_angle):
			current_angle = target_angle
			is_rotating = false
			is_forward = not is_forward
			pause_timer = pause_duration
		
		mesh_instance.rotation_degrees = rotation_axis * current_angle

func process_continuous(delta: float) -> void:
	current_angle += continuous_speed * delta
	if current_angle >= 360.0:
		current_angle -= 360.0
	mesh_instance.rotation_degrees = continuous_axis * current_angle

# Configuration helpers
func set_step_pause_mode(angle: float = 45.0, axis: Vector3 = Vector3.UP, pause: float = 4.0):
	mode = RotationMode.STEP_PAUSE
	rotation_angle = angle
	rotation_axis = axis.normalized()
	pause_duration = pause

func set_continuous_mode(axis: Vector3 = Vector3.RIGHT, speed: float = 30.0):
	mode = RotationMode.CONTINUOUS
	continuous_axis = axis.normalized()
	continuous_speed = speed

static func parse_parameters(param_string: String) -> Dictionary:
	var result = {
		"mode": RotationMode.STEP_PAUSE,
		"angle": 45.0,
		"axis": Vector3.UP,
		"pause": 4.0,
		"speed": 30.0,
		"size": 2.2
	}
	
	if param_string.is_empty():
		return result
	
	var parts = param_string.split(":")
	
	if parts[0].to_lower() == "continuous":
		result.mode = RotationMode.CONTINUOUS
		if parts.size() > 1:
			result.axis = _parse_axis(parts[1])
		if parts.size() > 2:
			result.speed = parts[2].to_float()
	else:
		result.mode = RotationMode.STEP_PAUSE
		result.angle = parts[0].to_float()
		if parts.size() > 1:
			result.axis = _parse_axis(parts[1])
		if parts.size() > 2:
			result.pause = parts[2].to_float()
	
	return result

static func _parse_axis(s: String) -> Vector3:
	match s.to_lower():
		"x": return Vector3.RIGHT
		"y": return Vector3.UP
		"z": return Vector3.BACK
		"-x": return Vector3.LEFT
		"-y": return Vector3.DOWN
		"-z": return Vector3.FORWARD
		_: return Vector3.UP
