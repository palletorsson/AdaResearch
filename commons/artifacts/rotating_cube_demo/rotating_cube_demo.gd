# rotating_cube_demo.gd
# Simple continuous rotation demonstration
# Shows: θ += ω·dt (angle increases by angular velocity × time)
# The simplest form of rotational motion - constant spin

extends Node3D

class_name RotatingCubeDemo


# @identity
# essence: theta(t) = omega * t, displayed with circular trail and angle readout
# desire: Watch a single cube rotate at constant angular velocity with its circular path traced
# critical_parameter: rotation_speed (omega) — the angular velocity in radians per second
# triggers: continuous time integration rotates the cube; trail mesh shows the circular orbit
# emerges: the connection between angular velocity, period, and the circular path
# needs: VR observation [has], speed adjustment [missing], angle readout [has]
# relationships: depends on basic rotation math; contrasts with y_oscillation_cube (rotation vs translation); unlocks angular velocity intuition
# truth: Rotation at constant speed is the simplest periodic motion — the mother of all oscillation.

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var cube_size: float = 0.3
@export var rotation_speed: float = 1.5  # ω in radians/second
@export var cube_color: Color = Color(0.9, 0.6, 0.2)
@export var show_labels: bool = true
@export var show_trail: bool = true

var _cube_instance: Node3D
var _cube_mesh: MeshInstance3D
var _label: Label3D
var _formula_label: Label3D
var _ground_arc: MeshInstance3D
var _direction_indicator: MeshInstance3D

var _current_angle: float = 0.0  # θ in radians


func _ready():
	_create_cube()
	_create_ground_arc()
	_create_direction_indicator()
	_create_labels()


func _create_cube():
	_cube_instance = CUBE_SCENE.instantiate()
	_cube_instance.scale = Vector3.ONE * cube_size
	_cube_instance.position.y = cube_size / 2.0
	add_child(_cube_instance)
	
	# Get mesh for color
	var static_body = _cube_instance.get_node_or_null("CubeBaseStaticBody3D")
	if static_body:
		_cube_mesh = static_body.get_node_or_null("CubeBaseMesh")
		_apply_cube_color()


func _apply_cube_color():
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("wireframeColor", cube_color)
		mat.set_shader_parameter("emissionColor", cube_color * 1.3)
		mat.set_shader_parameter("modelColor", cube_color * 0.2)


func _create_ground_arc():
	# Circle on ground showing rotation path
	_ground_arc = MeshInstance3D.new()
	_ground_arc.position.y = 0.005
	add_child(_ground_arc)
	
	var mesh = ImmediateMesh.new()
	var radius = cube_size * 0.7
	var segments = 32
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * TAU
		var x = sin(angle) * radius
		var z = cos(angle) * radius
		mesh.surface_set_color(Color(0.5, 0.4, 0.3, 0.5))
		mesh.surface_add_vertex(Vector3(x, 0, z))
	
	mesh.surface_end()
	_ground_arc.mesh = mesh


func _create_direction_indicator():
	# Arrow showing current rotation angle
	_direction_indicator = MeshInstance3D.new()
	
	var mesh = ImmediateMesh.new()
	var radius = cube_size * 0.7
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(Color(1.0, 0.8, 0.3))
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(Vector3(0, 0, radius))
	mesh.surface_end()
	
	# Arrow head
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(Color(1.0, 0.8, 0.3))
	var tip = Vector3(0, 0, radius)
	var left = Vector3(-0.02, 0, radius - 0.04)
	var right = Vector3(0.02, 0, radius - 0.04)
	mesh.surface_add_vertex(tip)
	mesh.surface_add_vertex(left)
	mesh.surface_add_vertex(right)
	mesh.surface_end()
	
	_direction_indicator.mesh = mesh
	_direction_indicator.position.y = 0.01
	add_child(_direction_indicator)


func _create_labels():
	if not show_labels:
		return
	
	# Real-time values
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 56
	_label.outline_size = 6
	_label.text = "θ = 0.0°\nω = %.2f rad/s" % rotation_speed
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.position = Vector3(-cube_size * 1.5, cube_size * 1.5, 0)
	_label.modulate = Color(1.0, 0.9, 0.8)
	add_child(_label)
	
	# Formula - the key concept
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 72
	_formula_label.outline_size = 8
	_formula_label.text = "θ += ω · dt"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, -0.08, cube_size)
	_formula_label.rotation.x = -PI / 6
	_formula_label.modulate = Color(1.0, 0.85, 0.5)
	add_child(_formula_label)
	
	# Title
	var title = Label3D.new()
	title.pixel_size = 0.001
	title.font_size = 48
	title.outline_size = 4
	title.text = "CONTINUOUS ROTATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector3(0, cube_size + 0.2, 0)
	title.modulate = Color(0.9, 0.8, 0.6)
	add_child(title)


func _process(delta):
	# The core formula: θ += ω · dt
	_current_angle += rotation_speed * delta
	
	# Keep angle in 0 to TAU range for display
	while _current_angle >= TAU:
		_current_angle -= TAU
	
	# Apply rotation to cube
	_cube_instance.rotation.y = _current_angle
	
	# Update direction indicator
	if _direction_indicator:
		_direction_indicator.rotation.y = _current_angle
	
	# Update label
	if _label:
		var degrees = rad_to_deg(_current_angle)
		_label.text = "θ = %.1f°\nω = %.2f rad/s\ndt = %.3fs" % [degrees, rotation_speed, delta]
	
	# Subtle color pulse
	_update_color_pulse()


func _update_color_pulse():
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if not mat or not mat is ShaderMaterial:
		return
	
	# Pulse based on rotation angle
	var pulse = (sin(_current_angle * 4.0) + 1.0) / 2.0 * 0.3
	mat.set_shader_parameter("emission_strength", 0.4 + pulse)


# Public API

func set_rotation_speed(speed: float) -> void:
	rotation_speed = speed


func get_rotation_speed() -> float:
	return rotation_speed


func get_current_angle_degrees() -> float:
	return rad_to_deg(_current_angle)


func get_current_angle_radians() -> float:
	return _current_angle


func reset() -> void:
	_current_angle = 0.0


func get_cube_instance() -> Node3D:
	return _cube_instance

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
