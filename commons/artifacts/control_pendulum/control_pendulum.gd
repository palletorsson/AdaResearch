# control_pendulum.gd
# Grabbable pendulum that controls oscillation parameters
# When grabbed: oscillation stops. When released: resumes from current position.
# Swing harder = faster oscillation. Higher amplitude = bigger movements.
# Uses XR Tools grabbable sphere for VR interaction.

extends Node3D

class_name ControlPendulum


# @identity
# essence: alpha = -(g/L)*sin(theta), omega += alpha*dt, theta += omega*dt, damped by 0.995
# desire: Grab a pendulum bob in VR and feel gravity convert your release into oscillation
# critical_parameter: pendulum_length — determines the natural frequency via sqrt(g/L)
# triggers: grab() freezes physics; release() converts hand position to initial angle and starts oscillation
# emerges: harmonic motion from the simplest possible setup — mass, string, gravity
# needs: VR grab on bob [has], oscillation_updated signal output [has]
# relationships: depends on gravity simulation; drives oscillation_controlled_cube via signal; contrasts with spring_demo (gravity vs spring restoring force)
# truth: A pendulum is gravity's metronome — length alone determines the tempo.

signal oscillation_updated(y_offset: float, angular_velocity: float, amplitude: float)
signal grabbed
signal released

@export var pendulum_length: float = 0.6
@export var bob_radius: float = 0.06
@export var gravity: float = 9.8
@export var damping: float = 0.995

const GRAB_SPHERE_SCENE = preload("res://commons/primitives/point/grab_sphere_point.tscn")

var _pivot: Node3D
var _rod: MeshInstance3D
var _bob_sphere: Node3D  # The grabbable sphere instance
var _label: Label3D

var _angle: float = 0.3  # Starting angle (radians)
var _angular_velocity: float = 0.0
var _is_grabbed: bool = false
var _last_bob_position: Vector3
var _grab_start_time: float = 0.0
var _grab_velocity_samples: Array[Vector3] = []

# Output values for the controlled cube
var current_y_offset: float = 0.0
var current_angular_velocity: float = 0.0
var current_amplitude: float = 0.0

func _ready():
	_create_pivot()
	_create_rod()
	_create_grabbable_bob()
	_create_label()
	_update_bob_position()

func _create_pivot():
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)

	# Pivot point visual
	var pivot_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	pivot_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.5)
	mat.metallic = 0.8
	pivot_mesh.material_override = mat
	_pivot.add_child(pivot_mesh)

func _create_rod():
	_rod = MeshInstance3D.new()
	_rod.name = "Rod"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = pendulum_length
	_rod.mesh = cylinder
	_rod.position.y = -pendulum_length / 2

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.55, 0.5)
	mat.metallic = 0.6
	_rod.material_override = mat
	_pivot.add_child(_rod)

func _create_grabbable_bob():
	# Instance the grabbable sphere
	_bob_sphere = GRAB_SPHERE_SCENE.instantiate()
	_bob_sphere.name = "BobSphere"

	# Configure the sphere for pendulum use
	if _bob_sphere.has_method("set"):
		_bob_sphere.freeze = true  # Start frozen (controlled by pendulum)
		_bob_sphere.alter_freeze = false  # Don't toggle freeze on drop
		_bob_sphere.glow_color = Color(0.9, 0.4, 0.3)

	# Scale to match bob_radius
	var scale_factor = bob_radius / 0.045  # Default grab sphere radius is ~0.045
	_bob_sphere.scale = Vector3.ONE * scale_factor

	# Connect to picked_up and dropped signals
	if _bob_sphere.has_signal("picked_up"):
		_bob_sphere.picked_up.connect(_on_bob_picked_up)
	if _bob_sphere.has_signal("dropped"):
		_bob_sphere.dropped.connect(_on_bob_dropped)

	# Add as child of the main node (not pivot) so it can move freely when grabbed
	add_child(_bob_sphere)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "GRAB & SWING"
	_label.position = Vector3(0, 0.1, 0)
	_label.modulate = Color(0.7, 0.7, 0.8)
	add_child(_label)

func _update_bob_position():
	# Calculate bob position from angle
	if _bob_sphere and not _is_grabbed:
		var bob_x = sin(_angle) * pendulum_length
		var bob_y = -cos(_angle) * pendulum_length
		_bob_sphere.global_position = global_position + Vector3(bob_x, bob_y, 0)
		_last_bob_position = _bob_sphere.global_position

func _physics_process(delta):
	if _is_grabbed:
		# When grabbed, track the bob position and calculate angle
		if _bob_sphere:
			var local_pos = to_local(_bob_sphere.global_position)
			var new_angle = atan2(local_pos.x, -local_pos.y)
			new_angle = clampf(new_angle, -PI * 0.45, PI * 0.45)

			# Track velocity for release impulse
			var current_pos = _bob_sphere.global_position
			if _grab_velocity_samples.size() > 0:
				var velocity = (current_pos - _last_bob_position) / delta
				_grab_velocity_samples.append(velocity)
				if _grab_velocity_samples.size() > 5:
					_grab_velocity_samples.pop_front()
			else:
				_grab_velocity_samples.append(Vector3.ZERO)

			_last_bob_position = current_pos
			_angle = new_angle
			_angular_velocity = 0.0

		_update_label("GRABBED\nRelease to swing")
	else:
		# Simple pendulum physics
		var angular_acceleration = -(gravity / pendulum_length) * sin(_angle)
		_angular_velocity += angular_acceleration * delta
		_angular_velocity *= damping
		_angle += _angular_velocity * delta

		# Clamp angle
		_angle = clampf(_angle, -PI * 0.45, PI * 0.45)

		# Update bob position
		_update_bob_position()

		_update_label("Swing: %.1f deg\nSpeed: %.2f" % [rad_to_deg(_angle), abs(_angular_velocity)])

	# Update visual rotation of pivot (for rod)
	_pivot.rotation.z = _angle

	# Calculate output values
	current_y_offset = sin(_angle) * pendulum_length
	current_angular_velocity = _angular_velocity
	current_amplitude = abs(_angle) / (PI * 0.45)  # Normalized 0-1

	# Emit signal for connected objects
	oscillation_updated.emit(current_y_offset, current_angular_velocity, current_amplitude)

func _update_label(text: String):
	if _label:
		_label.text = text

func _on_bob_picked_up(_pickable):
	_is_grabbed = true
	_grab_start_time = Time.get_ticks_msec() / 1000.0
	_grab_velocity_samples.clear()
	_last_bob_position = _bob_sphere.global_position
	grabbed.emit()

func _on_bob_dropped(_pickable):
	_is_grabbed = false

	# Calculate angular velocity from grab movement
	if _grab_velocity_samples.size() > 0:
		var avg_velocity = Vector3.ZERO
		for v in _grab_velocity_samples:
			avg_velocity += v
		avg_velocity /= _grab_velocity_samples.size()

		# Convert linear velocity to angular velocity
		# Tangential velocity at pendulum length gives angular velocity
		var tangent_direction = Vector3(-cos(_angle), -sin(_angle), 0)
		var tangent_velocity = avg_velocity.dot(tangent_direction)
		_angular_velocity = tangent_velocity / pendulum_length

		# Clamp to reasonable values
		_angular_velocity = clampf(_angular_velocity, -10.0, 10.0)

	_grab_velocity_samples.clear()
	released.emit()

func grab():
	# Manual grab (for non-VR)
	_is_grabbed = true
	grabbed.emit()

func release():
	# Manual release (for non-VR)
	_is_grabbed = false
	released.emit()

func push(impulse: float):
	# Add angular velocity (for VR swing gesture)
	_angular_velocity += impulse

# For manual control (click/drag)
func set_angle_from_position(world_pos: Vector3):
	var local_pos = to_local(world_pos)
	_angle = atan2(local_pos.x, -local_pos.y)
	_angle = clampf(_angle, -PI * 0.45, PI * 0.45)
	_update_bob_position()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
