# scale_cube.gd - A cube that scales to fill space
# Demonstrates: scale is multiplicative, volume grows cubically
extends Node3D

class_name ScaleCube

const MIN_SHAPE_SCALE: float = 0.001

# Scale settings
@export var min_scale: float = 0.5  # Minimum size
@export var max_scale: float = 3.0  # Maximum size (fills 3m gap)
@export var scale_speed: float = 1.0  # Units per second
@export var pause_at_max: float = 4.0  # Seconds to pause when fully scaled (walkable time)
@export var pause_at_min: float = 1.0  # Seconds to pause when minimum

# Position offset (cube scales from center, so offset to align with gap)
@export var center_offset: Vector3 = Vector3(1.5, 0, 0)
@export var y_offset: float = 0.0  # Vertical offset for alignment

# Visual - green theme for scale/growth
@export var fill_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var wireframe_color: Color = Color(0.4, 1.0, 0.5, 1.0)

# Internal state
var current_scale: float = 0.5
var is_scaling_up: bool = true
var pause_timer: float = 0.0

# Components
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D
var box_shape: BoxShape3D

func _ready() -> void:
	create_cube()
	_sanitize_scale_range()
	current_scale = min_scale
	apply_scale()
	
	# Apply y offset
	position.y += y_offset
	
	var volume_ratio = (max_scale / min_scale) ** 3
	print("ScaleCube: %.1f → %.1f (volume ×%.1f), pause=%.1fs, y_offset=%.1f" % [min_scale, max_scale, volume_ratio, pause_at_max, y_offset])

func create_cube() -> void:
	# Create mesh (1x1x1 base, we'll scale it)
	mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3.ONE
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
	box_shape = BoxShape3D.new()
	box_shape.size = Vector3.ONE
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)

func apply_scale() -> void:
	var safe_scale: float = maxf(absf(current_scale), MIN_SHAPE_SCALE)
	var scale_vec: Vector3 = Vector3(safe_scale, safe_scale, safe_scale)
	mesh_instance.scale = scale_vec
	mesh_instance.position = center_offset
	
	# Update collision
	box_shape.size = scale_vec
	static_body.position = center_offset

func _process(delta: float) -> void:
	if pause_timer > 0:
		pause_timer -= delta
		return
	
	if is_scaling_up:
		current_scale += scale_speed * delta
		if current_scale >= max_scale:
			current_scale = max_scale
			is_scaling_up = false
			pause_timer = pause_at_max
	else:
		current_scale -= scale_speed * delta
		if current_scale <= min_scale:
			current_scale = min_scale
			is_scaling_up = true
			pause_timer = pause_at_min
	
	apply_scale()

# Check if cube is currently walkable (at or near max scale)
func is_walkable() -> bool:
	return current_scale >= max_scale * 0.95

# Configuration
func set_scale_range(min_s: float, max_s: float):
	min_scale = min_s
	max_scale = max_s
	_sanitize_scale_range()
	current_scale = clampf(current_scale, min_scale, max_scale)

func set_offset(offset: Vector3):
	center_offset = offset

static func parse_parameters(param_string: String) -> Dictionary:
	var result = {
		"min_scale": 0.5,
		"max_scale": 3.0,
		"offset_x": 1.5,
		"speed": 1.0,
		"pause_max": 4.0,
		"pause_min": 1.0
	}
	
	if param_string.is_empty():
		return result
	
	var parts = param_string.split(":")
	
	if parts.size() >= 1:
		result.max_scale = parts[0].to_float()
	if parts.size() >= 2:
		result.min_scale = parts[1].to_float()
	if parts.size() >= 3:
		result.offset_x = parts[2].to_float()
	if parts.size() >= 4:
		result.speed = parts[3].to_float()
	
	return result


func _sanitize_scale_range() -> void:
	min_scale = maxf(min_scale, MIN_SHAPE_SCALE)
	max_scale = maxf(max_scale, MIN_SHAPE_SCALE)
	if max_scale < min_scale:
		var tmp: float = min_scale
		min_scale = max_scale
		max_scale = tmp
