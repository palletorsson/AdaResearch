# rotation_oscillation_cube.gd
# Stage 3: Rotation oscillation demonstration
# Shows θ = A * sin(ωt) for oscillating mode, or θ += ω*dt for continuous
# Parallel concept to Y-oscillation: same math, different output mapping

extends Node3D

class_name RotationOscillationCube

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")
var RackTpl = load("res://commons/audio/rack_templates/RackTemplates.gd")

## Side length of the cube in meters
@export_range(0.05, 2.0, 0.05) var cube_size: float = 0.3
## Peak rotation angle in degrees (oscillating mode only)
@export_range(1.0, 180.0, 1.0) var amplitude_degrees: float = 45.0
## Oscillation / spin frequency in Hz
@export_range(0.01, 5.0, 0.01) var frequency: float = 0.8
## Base color applied to the cube wireframe shader
@export var cube_color: Color = Color(0.8, 0.5, 0.2)
## If true: constant spin (θ += ω·dt), else: oscillate (θ = A·sin(ωt))
@export var continuous_mode: bool = false
## Show the arc indicator on the ground plane
@export var show_arc: bool = true
## Show the directional arrow on the cube face
@export var show_direction_arrow: bool = true

var _cube_instance: Node3D
var _cube_mesh: MeshInstance3D
var _label: Label3D
var _formula_label: Label3D
var _arc_mesh: MeshInstance3D
var _direction_arrow: MeshInstance3D
var _center_marker: MeshInstance3D
var _speed_slider: Node3D
var _created_nodes: Array[Node] = []

var _time: float = 0.0
var _current_angle: float = 0.0  # In radians


func _ready():
	_create_cube()
	_create_arc_indicator()
	_create_direction_arrow()
	_create_labels()
	_create_center_marker()
	_setup_controls()


## Instantiate the main cube from the shared cube scene and apply color
func _create_cube():
	_cube_instance = CUBE_SCENE.instantiate()
	_cube_instance.scale = Vector3.ONE * cube_size
	_cube_instance.position.y = cube_size / 2.0
	add_child(_cube_instance)
	_created_nodes.append(_cube_instance)
	
	# Get the mesh for color customization
	var static_body = _cube_instance.get_node_or_null("CubeBaseStaticBody3D")
	if static_body:
		_cube_mesh = static_body.get_node_or_null("CubeBaseMesh")
		_apply_cube_color()


## Set wireframe shader colors on the cube mesh material
func _apply_cube_color():
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("wireframeColor", cube_color)
		mat.set_shader_parameter("emissionColor", cube_color * 1.2)
		mat.set_shader_parameter("modelColor", cube_color * 0.2)


## Draw an arc on the ground plane showing the rotation range
func _create_arc_indicator():
	if not show_arc:
		return

	_arc_mesh = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	_arc_mesh.mesh = mesh

	_arc_mesh.position.y = 0.01
	add_child(_arc_mesh)
	_created_nodes.append(_arc_mesh)
	
	_update_arc_mesh()


## Rebuild the arc ImmediateMesh geometry for current amplitude/mode
func _update_arc_mesh():
	if not _arc_mesh:
		return
	
	var mesh = ImmediateMesh.new()
	var radius = cube_size * 0.8
	var segments = 32
	var arc_angle = deg_to_rad(amplitude_degrees) if not continuous_mode else PI
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = -arc_angle + t * arc_angle * 2.0
		var x = sin(angle) * radius
		var z = cos(angle) * radius
		
		# Color gradient: center is dim, edges are bright
		var edge_factor = abs(t - 0.5) * 2.0
		var color = Color(0.4 + edge_factor * 0.4, 0.5, 0.3 + edge_factor * 0.3)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(x, 0, z))
	
	mesh.surface_end()
	
	# Add end markers
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var end_angle_1 = -arc_angle
	var end_angle_2 = arc_angle
	
	# Tick marks at range limits
	for angle in [end_angle_1, end_angle_2]:
		var inner_r = radius * 0.7
		var outer_r = radius * 1.1
		mesh.surface_set_color(Color(0.8, 0.6, 0.3))
		mesh.surface_add_vertex(Vector3(sin(angle) * inner_r, 0, cos(angle) * inner_r))
		mesh.surface_add_vertex(Vector3(sin(angle) * outer_r, 0, cos(angle) * outer_r))
	
	mesh.surface_end()
	
	_arc_mesh.mesh = mesh


## Create a prism arrow on the cube face indicating rotation direction
func _create_direction_arrow():
	if not show_direction_arrow:
		return

	_direction_arrow = MeshInstance3D.new()
	
	# Simple arrow using prism
	var mesh = PrismMesh.new()
	mesh.size = Vector3(cube_size * 0.15, cube_size * 0.4, cube_size * 0.05)
	_direction_arrow.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 0.5
	_direction_arrow.material_override = mat
	
	# Position on front face of cube
	_direction_arrow.position = Vector3(0, cube_size / 2.0, cube_size / 2.0 + 0.01)
	_direction_arrow.rotation.x = -PI / 2  # Point outward
	add_child(_direction_arrow)
	_created_nodes.append(_direction_arrow)


## Create real-time value, formula, and mode indicator labels
func _create_labels():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 56
	_label.outline_size = 6
	_label.text = "t = 0.00\nθ = 0.0°"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.position = Vector3(-cube_size * 1.8, cube_size * 1.5, 0)
	_label.modulate = Color(1.0, 0.9, 0.8)
	add_child(_label)
	_created_nodes.append(_label)
	
	# Formula label
	_formula_label = Label3D.new()
	_formula_label.pixel_size = 0.001
	_formula_label.font_size = 72
	_formula_label.outline_size = 8
	
	if continuous_mode:
		_formula_label.text = "θ += ω·dt"
	else:
		_formula_label.text = "θ = A · sin(ωt)"
	
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula_label.position = Vector3(0, -0.08, cube_size)
	_formula_label.rotation.x = -PI / 6
	_formula_label.modulate = Color(1.0, 0.85, 0.6)
	add_child(_formula_label)
	_created_nodes.append(_formula_label)
	
	# Mode indicator
	var mode_label = Label3D.new()
	mode_label.pixel_size = 0.001
	mode_label.font_size = 36
	mode_label.text = "CONTINUOUS" if continuous_mode else "OSCILLATING"
	mode_label.position = Vector3(0, cube_size + 0.2, 0)
	mode_label.modulate = Color(0.8, 0.7, 0.6) if continuous_mode else Color(0.6, 0.8, 0.7)
	add_child(mode_label)
	_created_nodes.append(mode_label)


## Draw a small cylinder at the rotation origin
func _create_center_marker():
	_center_marker = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.015
	cylinder.bottom_radius = 0.015
	cylinder.height = 0.02
	_center_marker.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.5, 0.6)
	mat.emission_energy_multiplier = 0.3
	_center_marker.material_override = mat
	
	_center_marker.position.y = 0.01
	add_child(_center_marker)
	_created_nodes.append(_center_marker)


func _process(delta):
	_time += delta
	
	if continuous_mode:
		# Continuous rotation: θ += ω*dt
		var omega = frequency * TAU
		_current_angle += omega * delta
		# Keep angle bounded for display (but actually continuous)
		while _current_angle > PI:
			_current_angle -= TAU
		while _current_angle < -PI:
			_current_angle += TAU
	else:
		# Oscillating rotation: θ = A * sin(ωt)
		var omega = frequency * TAU
		var amp_rad = deg_to_rad(amplitude_degrees)
		_current_angle = amp_rad * sin(omega * _time)
	
	# Apply rotation to cube
	_cube_instance.rotation.y = _current_angle
	
	# Direction arrow follows cube rotation
	if _direction_arrow:
		_direction_arrow.rotation.y = _current_angle
	
	# Update labels
	_update_labels()
	
	# Update color based on rotation
	_update_color_feedback()


## Refresh the real-time angle / sin / omega readout
func _update_labels():
	if _label:
		var angle_deg = rad_to_deg(_current_angle)
		
		if continuous_mode:
			_label.text = "t = %.2f\nθ = %.1f°\nω = %.2f rad/s" % [
				fmod(_time, 100.0),
				angle_deg,
				frequency * TAU
			]
		else:
			var sin_val = sin(frequency * TAU * _time)
			_label.text = "t = %.2f\nsin(ωt) = %.2f\nθ = %.1f°" % [
				fmod(_time, 100.0),
				sin_val,
				angle_deg
			]


## Shift wireframe color based on current rotation intensity
func _update_color_feedback():
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if not mat or not mat is ShaderMaterial:
		return
	
	# Intensity based on rotation speed/position
	var intensity: float
	if continuous_mode:
		# Pulse with rotation
		intensity = (sin(_current_angle * 4.0) + 1.0) / 2.0
	else:
		# Brighter at rotation extremes
		var amp_rad = deg_to_rad(amplitude_degrees)
		var normalized = abs(_current_angle) / amp_rad if amp_rad > 0 else 0.0
		intensity = normalized
	
	# Subtle color shift
	var shift = intensity * 0.2
	var current_color = Color(
		cube_color.r + shift,
		cube_color.g - shift * 0.5,
		cube_color.b - shift
	)
	
	mat.set_shader_parameter("wireframeColor", current_color)
	mat.set_shader_parameter("emissionColor", current_color * (1.0 + intensity * 0.5))
	mat.set_shader_parameter("emission_strength", 0.3 + intensity * 0.3)


# Public API

func set_mode(continuous: bool) -> void:
	continuous_mode = continuous
	if _formula_label:
		_formula_label.text = "θ += ω·dt" if continuous else "θ = A · sin(ωt)"
	_update_arc_mesh()


func set_amplitude(degrees: float) -> void:
	amplitude_degrees = degrees
	_update_arc_mesh()


func set_frequency(f: float) -> void:
	frequency = f


func get_current_angle_degrees() -> float:
	return rad_to_deg(_current_angle)


func get_current_angle_radians() -> float:
	return _current_angle


func reset() -> void:
	_time = 0.0
	_current_angle = 0.0


func get_cube_instance() -> Node3D:
	return _cube_instance


## Add a VR speed slider for interactive frequency control
func _setup_controls():
	var panel = RackTpl.create_panel("ROTATION", [
		[{"type": "slider_h", "label": "Speed", "default": frequency / 5.0}],
	])
	panel.position = Vector3(0, 0.5, 0.6)
	panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(panel)
	_created_nodes.append(panel)

	_speed_slider = panel.find_child("Param_0", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)


func _on_speed_changed():
	var val = _speed_slider.get_normalized_value()
	set_frequency(val * 5.0)


func _exit_tree():
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()


func apply_grid_config(config_data: Dictionary) -> void:
	pass
