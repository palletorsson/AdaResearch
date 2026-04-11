# y_oscillation_cube.gd
# Stage 2: Y-axis oscillation demonstration
# Core concept: y = A * sin(ωt)
# Shows how sine function maps time to vertical position
# Creates cube directly with Grid shader (not cube_scene instantiation)

extends Node3D

class_name YOscillationCube


# @identity
# essence: y(t) = A * sin(2*PI*f*t) — simple harmonic motion along the vertical axis
# desire: Watch a cube bounce on a vertical rail, feeling the simplest possible oscillation
# critical_parameter: frequency — controls how fast the cube oscillates up and down
# triggers: time drives continuous sine evaluation; amplitude and frequency adjustable
# emerges: the most elemental wave visualization — one axis, one sine, one cube
# needs: VR observation [has], amplitude/frequency sliders [missing], ghost trail [has]
# relationships: depends on basic sine function; contrasts with oscillation_controlled_cube (single vs multi-axis oscillation); unlocks y=sin(t) intuition
# truth: y = A*sin(2*pi*f*t) is the simplest sentence in the language of oscillation.

const GRID_SHADER = preload("res://commons/resourses/shaders/Grid.gdshader")

@export var cube_size: float = 0.15  # Size in meters
@export var amplitude: float = 0.2  # A in the formula (movement range)
@export var frequency: float = 1.0  # ω = 2πf
@export var cube_color: Color = Color(0.2, 0.8, 0.5)  # Teal green
@export var show_rail: bool = true
@export var show_trail: bool = true
@export var trail_count: int = 5

var _cube_mesh: MeshInstance3D
var _cube_material: ShaderMaterial
var _label: Label3D
var _formula_label: Label3D
var _rail: MeshInstance3D
var _rail_top_marker: MeshInstance3D
var _rail_bottom_marker: MeshInstance3D
var _trail_ghosts: Array[MeshInstance3D] = []

var _base_y: float = 0.0
var _time: float = 0.0
var _trail_history: Array[float] = []


func _ready():
	print("y_oscillation_cube: cube_size = ", cube_size)  # Debug
	_base_y = cube_size / 2.0  # Rest position (cube sits on ground)
	_create_cube()
	_create_rail()
	_create_labels()
	_create_trail_ghosts()


func _create_cube():
	# Create MeshInstance3D with BoxMesh directly
	_cube_mesh = MeshInstance3D.new()
	
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)  # Set actual size here!
	_cube_mesh.mesh = box
	
	# Create Grid shader material
	_cube_material = ShaderMaterial.new()
	_cube_material.shader = GRID_SHADER
	_cube_material.set_shader_parameter("modelColor", cube_color * 0.2)
	_cube_material.set_shader_parameter("wireframeColor", cube_color)
	_cube_material.set_shader_parameter("emissionColor", cube_color * 1.2)
	_cube_material.set_shader_parameter("width", 3.0)
	_cube_material.set_shader_parameter("blur", 0.5)
	_cube_material.set_shader_parameter("emission_strength", 0.4)
	_cube_material.set_shader_parameter("show_interior", true)
	
	_cube_mesh.material_override = _cube_material
	_cube_mesh.position.y = _base_y
	add_child(_cube_mesh)


func _create_rail():
	if not show_rail:
		return
	
	# Vertical rail showing movement range
	_rail = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = amplitude * 2 + cube_size
	_rail.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.6, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.2
	_rail.material_override = mat
	
	_rail.position = Vector3(cube_size * 0.7, _base_y, 0)
	add_child(_rail)
	
	# Top marker (max amplitude)
	_rail_top_marker = _create_range_marker(Color(0.3, 0.8, 0.4))
	_rail_top_marker.position = Vector3(cube_size * 0.7, _base_y + amplitude, 0)
	add_child(_rail_top_marker)
	
	# Bottom marker (min amplitude)
	_rail_bottom_marker = _create_range_marker(Color(0.8, 0.4, 0.3))
	_rail_bottom_marker.position = Vector3(cube_size * 0.7, _base_y - amplitude, 0)
	add_child(_rail_bottom_marker)


func _create_range_marker(color: Color) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat
	
	return marker


func _create_labels():
	# Real-time values label
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 56
	_label.outline_size = 6
	_label.text = "t = 0.00\nsin(t) = 0.00\ny = 0.00"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.position = Vector3(-cube_size * 1.5, _base_y + amplitude + 0.1, 0)
	_label.modulate = Color(0.8, 0.9, 1.0)
	add_child(_label)
	
	# Formula label
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 72
	_formula_label.outline_size = 8
	_formula_label.text = "y = A · sin(ωt)"
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, -0.08, cube_size)
	_formula_label.rotation.x = -PI / 6
	_formula_label.modulate = Color(0.6, 0.85, 1.0)
	add_child(_formula_label)
	
	# Amplitude indicator
	var amp_label = Label3D.new()
	amp_label.pixel_size = 0.001
	amp_label.font_size = 40
	amp_label.text = "A=%.2f" % amplitude
	amp_label.position = Vector3(cube_size * 1.0, _base_y + amplitude * 0.5, 0)
	amp_label.modulate = Color(0.5, 0.8, 0.5)
	add_child(amp_label)


func _create_trail_ghosts():
	if not show_trail:
		return
	
	for i in range(trail_count):
		var ghost = MeshInstance3D.new()
		var box = BoxMesh.new()
		var ghost_size = cube_size * (0.6 + float(i) / trail_count * 0.3)
		box.size = Vector3(ghost_size, ghost_size, ghost_size)
		ghost.mesh = box
		ghost.visible = false
		
		# Create transparent ghost material
		var mat = ShaderMaterial.new()
		mat.shader = GRID_SHADER
		var alpha = 0.1 + (float(i) / trail_count) * 0.2
		mat.set_shader_parameter("modelColor", Color(cube_color.r * 0.2, cube_color.g * 0.2, cube_color.b * 0.2, alpha))
		mat.set_shader_parameter("wireframeColor", Color(cube_color.r, cube_color.g, cube_color.b, alpha))
		mat.set_shader_parameter("emissionColor", Color(cube_color.r, cube_color.g, cube_color.b, alpha * 0.5))
		mat.set_shader_parameter("width", 2.0)
		mat.set_shader_parameter("blur", 0.6)
		mat.set_shader_parameter("emission_strength", 0.2)
		mat.set_shader_parameter("show_interior", false)
		ghost.material_override = mat
		
		add_child(ghost)
		_trail_ghosts.append(ghost)


func _process(delta):
	_time += delta
	
	# Calculate oscillation: y = A * sin(ωt)
	var omega = frequency * TAU  # ω = 2πf
	var sin_value = sin(omega * _time)
	var y_offset = amplitude * sin_value
	
	# Update cube position
	_cube_mesh.position.y = _base_y + y_offset
	
	# Update trail
	_update_trail(y_offset)
	
	# Update labels
	_update_labels(sin_value, y_offset)
	
	# Color feedback based on position
	_update_color_feedback(sin_value)


func _update_trail(current_y_offset: float):
	if not show_trail:
		return
	
	# Add current position to history
	_trail_history.push_front(current_y_offset)
	if _trail_history.size() > trail_count:
		_trail_history.pop_back()
	
	# Update ghost positions
	for i in range(mini(_trail_history.size(), _trail_ghosts.size())):
		var ghost = _trail_ghosts[i]
		ghost.visible = true
		ghost.position.y = _base_y + _trail_history[i]


func _update_labels(sin_value: float, y_offset: float):
	if _label:
		_label.text = "t = %.2f\nsin(ωt) = %.2f\ny = %.3f" % [
			fmod(_time, 100.0),
			sin_value,
			y_offset
		]
		
		# Move label with cube (track it)
		_label.position.y = _base_y + amplitude + 0.15


func _update_color_feedback(sin_value: float):
	if not _cube_material:
		return
	
	# Intensity based on position (brighter at extremes)
	var intensity = abs(sin_value)
	
	# Color shift: green at top, blue at bottom
	var t = (sin_value + 1.0) / 2.0  # 0 to 1
	var current_color = cube_color.lerp(Color(0.3, 0.9, 0.4), t * 0.3)
	
	_cube_material.set_shader_parameter("wireframeColor", current_color)
	_cube_material.set_shader_parameter("emissionColor", current_color * (1.0 + intensity * 0.5))
	_cube_material.set_shader_parameter("emission_strength", 0.3 + intensity * 0.4)


# Public API

func set_amplitude(a: float) -> void:
	amplitude = a
	# Rebuild rail if needed
	if _rail:
		_rail.queue_free()
		_rail_top_marker.queue_free()
		_rail_bottom_marker.queue_free()
		_create_rail()


func set_frequency(f: float) -> void:
	frequency = f


func get_current_y() -> float:
	return _cube_mesh.position.y - _base_y


func get_cube_instance() -> MeshInstance3D:
	return _cube_mesh


func get_sin_value() -> float:
	var omega = frequency * TAU
	return sin(omega * _time)


func reset() -> void:
	_time = 0.0
	_trail_history.clear()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
