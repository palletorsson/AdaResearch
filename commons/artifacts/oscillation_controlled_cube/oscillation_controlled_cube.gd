# oscillation_controlled_cube.gd
# The "mario cube" that responds to pendulum control
# Pendulum Y → cube Y translation (up/down)
# Pendulum angular velocity → cube rotation speed
# Pendulum amplitude → cube scale pulse

extends Node3D

class_name OscillationControlledCube

@export var cube_size: float = 0.3
@export var translation_scale: float = 0.5
@export var rotation_scale: float = 2.0
@export var scale_range: Vector2 = Vector2(0.8, 1.2)

@export var pendulum_path: NodePath

var _cube: MeshInstance3D
var _label: Label3D
var _pendulum: Node  # ControlPendulum

var _base_position: Vector3
var _current_rotation: float = 0.0

func _ready():
	_base_position = position
	_create_cube()
	_create_label()
	
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
	_cube = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3.ONE * cube_size
	_cube.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.3, 0.5)
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.3
	mat.roughness = 0.4
	_cube.material_override = mat
	add_child(_cube)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 10
	_label.text = "Controlled by pendulum"
	_label.position = Vector3(0, cube_size + 0.1, 0)
	_label.modulate = Color(0.6, 0.8, 1.0)
	add_child(_label)

func _on_oscillation_updated(y_offset: float, angular_velocity: float, amplitude: float):
	# Translation: pendulum Y → cube Y
	position.y = _base_position.y + y_offset * translation_scale
	
	# Rotation: angular velocity → rotation speed
	_current_rotation += angular_velocity * rotation_scale * get_process_delta_time()
	_cube.rotation.y = _current_rotation
	
	# Scale: amplitude → scale pulse
	var scale_factor = lerp(scale_range.x, scale_range.y, amplitude)
	_cube.scale = Vector3.ONE * scale_factor
	
	# Update label
	_label.text = "Y: %.2f\nSpin: %.1f°\nScale: %.2f" % [
		position.y - _base_position.y,
		rad_to_deg(_current_rotation),
		scale_factor
	]
	
	# Color feedback based on amplitude
	var mat = _cube.material_override as StandardMaterial3D
	var intensity = amplitude
	mat.emission_energy_multiplier = 0.2 + intensity * 0.6
	mat.albedo_color = Color(0.2 + intensity * 0.3, 0.6, 0.9 - intensity * 0.2)

func _process(delta):
	# Fallback: if no pendulum connected, do default oscillation
	if not _pendulum:
		var t = Time.get_ticks_msec() / 1000.0
		var y_offset = sin(t * 2.0) * 0.3
		var ang_vel = cos(t * 2.0) * 1.5
		var amp = (sin(t * 0.5) + 1.0) * 0.5
		_on_oscillation_updated(y_offset, ang_vel, amp)
