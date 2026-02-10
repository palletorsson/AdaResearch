# oscillation_controlled_cube.gd
# The "mario cube" that responds to pendulum control
# Pendulum Y â†’ cube Y translation (up/down)
# Pendulum angular velocity â†’ cube rotation speed
# Pendulum amplitude â†’ cube scale pulse

extends Node3D

class_name OscillationControlledCube

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var cube_size: float = 0.3
@export var translation_scale: float = 0.5
@export var rotation_scale: float = 2.0
@export var scale_range: Vector2 = Vector2(0.8, 1.2)
@export var show_guides: bool = true
@export var cube_color: Color = Color(0.2, 0.6, 0.9)

@export var pendulum_path: NodePath

var _cube_instance: Node3D
var _cube_mesh: MeshInstance3D
var _label: Label3D
var _breakdown_label: Label3D
var _pendulum: Node  # ControlPendulum

# Guide visuals
var _vertical_rail: MeshInstance3D
var _rail_top_marker: MeshInstance3D
var _rail_bottom_marker: MeshInstance3D
var _rotation_arc: MeshInstance3D
var _mapping_panel: Node3D

var _base_position: Vector3
var _current_rotation: float = 0.0

func _ready():
	_base_position = position
	_create_cube()
	_create_label()
	_create_guides()
	
	# Try to find and connect to pendulum
	call_deferred("_connect_pendulum")

func _connect_pendulum():
	if pendulum_path:
		_pendulum = get_node_or_null(pendulum_path)
	
	if not _pendulum:
		# Search for ControlPendulum in parent
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child is ControlPendulum:
					_pendulum = child
					break
	
	if _pendulum and _pendulum.has_signal("oscillation_updated"):
		_pendulum.oscillation_updated.connect(_on_oscillation_updated)
		print("OscillationControlledCube connected to pendulum")

func _create_cube():
	_cube_instance = CUBE_SCENE.instantiate()
	_cube_instance.scale = Vector3.ONE * cube_size
	add_child(_cube_instance)
	
	# Get the mesh for color customization
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
		mat.set_shader_parameter("emissionColor", cube_color * 1.2)
		mat.set_shader_parameter("modelColor", cube_color * 0.2)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 48
	_label.outline_size = 6
	_label.text = "Controlled by pendulum"
	_label.position = Vector3(0, cube_size + 0.15, 0)
	_label.modulate = Color(0.6, 0.8, 1.0)
	add_child(_label)


func _create_guides():
	if not show_guides:
		return
	
	# Vertical rail (Y translation range)
	_create_vertical_rail()
	
	# Rotation arc indicator
	_create_rotation_arc()
	
	# Mapping breakdown panel
	_create_mapping_panel()


func _create_vertical_rail():
	var rail_height = translation_scale * 2.0 + cube_size
	
	_vertical_rail = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.006
	cylinder.bottom_radius = 0.006
	cylinder.height = rail_height
	_vertical_rail.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 0.8, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.5, 0.7)
	mat.emission_energy_multiplier = 0.3
	_vertical_rail.material_override = mat
	
	_vertical_rail.position = Vector3(cube_size * 0.8, rail_height / 2.0, 0)
	add_child(_vertical_rail)
	
	# Top marker
	_rail_top_marker = _create_guide_marker(Color(0.3, 0.8, 0.4))
	_rail_top_marker.position = Vector3(cube_size * 0.8, rail_height, 0)
	add_child(_rail_top_marker)
	
	# Bottom marker  
	_rail_bottom_marker = _create_guide_marker(Color(0.8, 0.4, 0.3))
	_rail_bottom_marker.position = Vector3(cube_size * 0.8, 0, 0)
	add_child(_rail_bottom_marker)
	
	# Y label
	var y_label = Label3D.new()
	y_label.pixel_size = 0.001
	y_label.font_size = 32
	y_label.text = "Y"
	y_label.position = Vector3(cube_size * 1.1, rail_height / 2.0, 0)
	y_label.modulate = Color(0.4, 0.7, 0.9)
	add_child(y_label)


func _create_guide_marker(color: Color) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.015
	sphere.height = 0.03
	marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat
	
	return marker


func _create_rotation_arc():
	_rotation_arc = MeshInstance3D.new()
	_rotation_arc.position.y = 0.01
	add_child(_rotation_arc)
	_update_rotation_arc()


func _update_rotation_arc():
	var mesh = ImmediateMesh.new()
	var radius = cube_size * 0.6
	var segments = 24
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Full circle to show rotation range
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * TAU
		var x = sin(angle) * radius
		var z = cos(angle) * radius
		
		var color = Color(0.7, 0.5, 0.3, 0.4)
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(x, 0, z))
	
	mesh.surface_end()
	
	# Arrow indicator at current position
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(Color(1.0, 0.8, 0.3))
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(Vector3(0, 0, radius))
	mesh.surface_end()
	
	_rotation_arc.mesh = mesh


func _create_mapping_panel():
	_breakdown_label = Label3D.new()
	_breakdown_label.pixel_size = 0.001
	_breakdown_label.font_size = 40
	_breakdown_label.outline_size = 4
	_breakdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_breakdown_label.text = "MAPPINGS:\ny_offset â†’ Y pos\nang_vel â†’ rotation\namplitude â†’ scale"
	_breakdown_label.position = Vector3(-cube_size * 2.0, cube_size * 0.3, 0)
	_breakdown_label.modulate = Color(0.7, 0.8, 0.9)
	add_child(_breakdown_label)

func _on_oscillation_updated(y_offset: float, angular_velocity: float, amplitude: float):
	# Translation: pendulum Y â†’ cube Y
	position.y = _base_position.y + y_offset * translation_scale
	
	# Rotation: angular velocity â†’ rotation speed
	_current_rotation += angular_velocity * rotation_scale * get_process_delta_time()
	_cube_instance.rotation.y = _current_rotation
	
	# Scale: amplitude â†’ scale pulse
	var scale_factor = lerp(scale_range.x, scale_range.y, amplitude)
	_cube_instance.scale = Vector3.ONE * cube_size * scale_factor
	
	# Update main label
	_label.text = "Y: %.2f\nSpin: %.1fÂ°\nScale: %.2f" % [
		position.y - _base_position.y,
		rad_to_deg(_current_rotation),
		scale_factor
	]
	
	# Update breakdown label with real-time mappings
	if _breakdown_label and show_guides:
		_breakdown_label.text = "MAPPINGS:\ny_offset %.2f â†’ Y %.2f\nang_vel %.2f â†’ Î¸ %.1fÂ°\namplitude %.2f â†’ s %.2f" % [
			y_offset, position.y - _base_position.y,
			angular_velocity, rad_to_deg(fmod(_current_rotation, TAU)),
			amplitude, scale_factor
		]
	
	# Update rotation arc indicator
	if _rotation_arc and show_guides:
		_rotation_arc.rotation.y = _current_rotation
	
	# Color feedback based on amplitude
	_update_color_feedback(amplitude)


func _update_color_feedback(intensity: float):
	if not _cube_mesh:
		return
	
	var mat = _cube_mesh.material_override
	if not mat or not mat is ShaderMaterial:
		return
	
	var current_color = Color(
		cube_color.r + intensity * 0.3,
		cube_color.g,
		cube_color.b - intensity * 0.2
	)
	
	mat.set_shader_parameter("wireframeColor", current_color)
	mat.set_shader_parameter("emissionColor", current_color * (1.0 + intensity * 0.6))
	mat.set_shader_parameter("emission_strength", 0.3 + intensity * 0.5)

func _process(_delta):
	# Fallback: if no pendulum connected, do default oscillation
	if not _pendulum:
		var t = Time.get_ticks_msec() / 1000.0
		var y_offset = sin(t * 2.0) * 0.3
		var ang_vel = cos(t * 2.0) * 1.5
		var amp = (sin(t * 0.5) + 1.0) * 0.5
		_on_oscillation_updated(y_offset, ang_vel, amp)
