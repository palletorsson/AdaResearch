extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Force Magnitude Demo
## Demonstrates: Larger force → larger acceleration (F = ma)
## Concept: Vector magnitude affects physical outcome
## Agent-PhysicsArchitect: Educational physics demonstration
## Protocol: IACP v2.2
##
## @identity
## essence: F = ma. Drag the force vector longer → ball accelerates harder. Magnitude is felt, not read.
## desire: To make the learner drag a red arrow and feel the ball respond proportionally — bigger arrow, faster ball.
## critical_parameter: The length of the applied_force_vector. It is the magnitude that drives everything.
## triggers: Force handle drag → acceleration scales linearly, R key → reset ball to origin, Space → freeze motion
## emerges: The intuition that force and acceleration are the same shape. The ball's trajectory traces the force's history.
## needs: VR draggable force arrow [has], info readout [has]. Missing: mass slider to show a = F/m with different m.
## relationships: Entry point for forces sequence. Feeds into combined_forces_demo (multiple forces). Contrasts with work_energy_demo (same force, different measure).
## truth: You never feel position or velocity. You feel acceleration. Force is the only thing that reaches your body.

var applied_force_vector: Node3D
var velocity_vector: Node3D
var acceleration_vector: Node3D

# Cached nodes
var _force_cache: Dictionary = {}
var _velocity_cache: Dictionary = {}
var _accel_cache: Dictionary = {}

# Update throttling
var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

func _ready() -> void:
	super._ready()
	_setup_demo()
	print("ForceMagnitudeDemo: Ready - Drag the red force vector!")

func _setup_demo() -> void:
	"""Setup force magnitude demonstration"""
	# Create force vector (user can drag)
	applied_force_vector = create_force_vector(
		"Applied Force",
		Vector3(2.0, 0, 0),  # Initial force (logical)
		Color(1.0, 0.3, 0.3, 1.0),  # Red
		true  # Allow grab
	)
	_force_cache = _cached_vector_nodes["Applied Force"]
	
	# Create velocity vector (read-only, shows current velocity)
	velocity_vector = create_force_vector(
		"Velocity",
		Vector3.ZERO,
		Color(0.3, 1.0, 0.3, 1.0),  # Green
		false  # No grab
	)
	_velocity_cache = _cached_vector_nodes["Velocity"]
	
	# Create acceleration vector (read-only, shows a = F/m)
	acceleration_vector = create_force_vector(
		"Acceleration",
		Vector3.ZERO,
		Color(0.3, 0.3, 1.0, 1.0),  # Blue
		false  # No grab
	)
	_accel_cache = _cached_vector_nodes["Acceleration"]
	
	# Update info label
	update_info_text([
		"Force Magnitude Demo",
		"Drag the RED force vector",
		"F = ma",
		"Larger force → larger acceleration"
	])

func _physics_process(delta: float) -> void:
	# Update force vector positions to follow ball
	update_force_vector_position()
	
	# Get applied force (logical units)
	var force_logical = _get_vector_fast_cached(_force_cache)
	
	# Calculate acceleration (a = F/m)
	var accel_logical = force_logical / BALL_MASS
	
	# Apply force to ball (scaled for physics)
	physics_ball.apply_central_force(force_logical * SCENE_SCALE)
	
	# Get current velocity (convert from scaled to logical)
	var velocity_logical = physics_ball.linear_velocity / SCENE_SCALE
	
	# Update velocity and acceleration vectors
	_update_vector_fast_cached(_velocity_cache, velocity_logical)
	_update_vector_fast_cached(_accel_cache, accel_logical)
	
	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(force_logical, accel_logical, velocity_logical)
		accumulator = 0.0

func _update_info(force: Vector3, accel: Vector3, velocity: Vector3) -> void:
	"""Update info label with current values"""
	var force_mag = force.length()
	var accel_mag = accel.length()
	var velocity_mag = velocity.length()
	
	var lines = [
		"Force Magnitude Demo",
		"",
		"Force: %.2f N" % force_mag,
		"F = (%.2f, %.2f, %.2f)" % [force.x, force.y, force.z],
		"",
		"Acceleration: %.2f m/s²" % accel_mag,
		"a = F/m = (%.2f, %.2f, %.2f)" % [accel.x, accel.y, accel.z],
		"",
		"Velocity: %.2f m/s" % velocity_mag,
		"v = (%.2f, %.2f, %.2f)" % [velocity.x, velocity.y, velocity.z]
	]
	
	update_info_text(lines)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_demo()
		elif event.keycode == KEY_SPACE:
			# Stop ball motion
			physics_ball.linear_velocity = Vector3.ZERO
			physics_ball.angular_velocity = Vector3.ZERO

func _reset_demo() -> void:
	"""Reset demonstration to initial state"""
	reset_ball(Vector3.ZERO)
	
	# Reset force vector
	var end_node: Node3D = _force_cache.get("end")
	if end_node:
		end_node.position = Vector3(2.0, 0, 0) * SCENE_SCALE
	var line_container: Node3D = _force_cache.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()
	
	print("ForceMagnitudeDemo: Reset")

func apply_grid_config(config: Dictionary) -> void:
	pass
