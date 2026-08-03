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
## needs: VR draggable force arrow [has], info readout [has], a mass to push against [has — the `body` axis].
## relationships: Entry point for forces sequence. Feeds into combined_forces_demo (multiple forces). Contrasts with work_energy_demo (same force, different measure).
## truth: You never feel position or velocity. You feel acceleration. Force is the only thing that reaches your body.

## AXIS — WHICH MEASURE OF THE RESPONSE STANDS BESIDE THE FORCE. The box has always
## drawn three arrows: the red one you drag, and two read-only companions. Which
## companions it draws is the whole argument about what counts as the answer to a push,
## and it was a hard-coded list of three create_force_vector() calls.
##
##   both           the legacy lineage: force, velocity (green), acceleration (blue), and
##                  the nine-line readout. Every measure at once; you choose what to read.
##   acceleration   force and a = F/m alone. The demo's own truth line, staged: force and
##                  acceleration are the same shape, and nothing else is on offer to look at.
##   velocity       force and v alone. The kinematic account — motion is the answer, the
##                  ball's response to the instant is hidden and only its history shows.
##   none           the red arrow in the glass box and nothing else. What you can push,
##                  with no receipt. The measure withheld, so the ball is all the evidence.
@export_enum("both", "acceleration", "velocity", "none") var measure: String = "both"
const MEASURES: PackedStringArray = ["both", "acceleration", "velocity", "none"]

## AXIS — WHAT THE FORCE IS PUSHING. BALL_MASS is a const 1.0 in the base, and this demo
## divides by it to get a. Every placement has therefore been an argument about force
## with the m in F = ma nailed shut at one — the @identity has asked for this since the
## file was written. Radius follows mass^(1/3), the constant-density reading, so bulk is
## visible and not merely stated: heavier ball, bigger ball, shorter blue arrow.
##
##   light        0.25 kg — the same drag throws it at the wall. Force looks omnipotent.
##   standard     1.0 kg — the legacy body, where a and F read as the same number.
##   heavy        4.0 kg — a is a quarter of F. The drag and the response come apart.
##   immovable    16.0 kg — a stub of a blue arrow. You push and the world barely agrees.
@export_enum("light", "standard", "heavy", "immovable") var body: String = "standard"
const BODY_MASS: Dictionary = {"light": 0.25, "standard": 1.0, "heavy": 4.0, "immovable": 16.0}

var applied_force_vector: Node3D
var velocity_vector: Node3D
var acceleration_vector: Node3D

# The mass actually in play. Resolved from `body` before the base builds the ball, and
# used everywhere BALL_MASS used to be. Literal 1.0 rather than the inherited BALL_MASS
# only because a member initialiser is the one place that const is awkward to reach;
# _ready() overwrites it with _body_mass() before anything reads it, and at the default
# that IS BALL_MASS.
var _mass: float = 1.0

# Cached nodes
var _force_cache: Dictionary = {}
var _velocity_cache: Dictionary = {}
var _accel_cache: Dictionary = {}

# Update throttling
var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

func _ready() -> void:
	# Resolve the mass BEFORE super._ready(), which is where the base builds the ball.
	_mass = _body_mass()
	super._ready()
	_setup_demo()
	print("ForceMagnitudeDemo: Ready - Drag the red force vector!")

## The ball the force pushes. Overridden only so `body` can reach it; at the default it
## hands straight back to the base and the legacy ball is built untouched.
func _create_physics_ball() -> void:
	if is_equal_approx(_mass, BALL_MASS):
		super._create_physics_ball()
		return
	var radius: float = BALL_RADIUS * pow(_mass / BALL_MASS, 1.0 / 3.0)
	physics_ball = create_ball(Vector3.ZERO, radius, _mass, Color(0.9, 0.5, 0.8, 1.0))
	physics_ball.name = "PhysicsBall"
	physics_ball.linear_damp = 0.1
	physics_ball.angular_damp = 0.1

func _setup_demo() -> void:
	"""Setup force magnitude demonstration"""
	var shown: String = _measure_value()

	# Create force vector (user can drag) — always. It is the thing you hold.
	applied_force_vector = create_force_vector(
		"Applied Force",
		Vector3(2.0, 0, 0),  # Initial force (logical)
		Color(1.0, 0.3, 0.3, 1.0),  # Red
		true  # Allow grab
	)
	_force_cache = _cached_vector_nodes["Applied Force"]

	# Create velocity vector (read-only, shows current velocity)
	if shown == "both" or shown == "velocity":
		velocity_vector = create_force_vector(
			"Velocity",
			Vector3.ZERO,
			Color(0.3, 1.0, 0.3, 1.0),  # Green
			false  # No grab
		)
		_velocity_cache = _cached_vector_nodes["Velocity"]

	# Create acceleration vector (read-only, shows a = F/m)
	if shown == "both" or shown == "acceleration":
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
	
	# Calculate acceleration (a = F/m) — _mass is BALL_MASS unless `body` says otherwise
	var accel_logical = force_logical / _mass
	
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
	
	var shown: String = _measure_value()
	var lines: Array = [
		"Force Magnitude Demo",
		"",
		"Force: %.2f N" % force_mag,
		"F = (%.2f, %.2f, %.2f)" % [force.x, force.y, force.z]
	]

	# Only when the body is not the legacy 1 kg — at the default this line does not exist
	# and the readout is the historical one, line for line.
	if not is_equal_approx(_mass, BALL_MASS):
		lines.append("m = %.2f kg  (%s)" % [_mass, _body_value()])

	if shown == "both" or shown == "acceleration":
		lines.append("")
		lines.append("Acceleration: %.2f m/s²" % accel_mag)
		lines.append("a = F/m = (%.2f, %.2f, %.2f)" % [accel.x, accel.y, accel.z])

	if shown == "both" or shown == "velocity":
		lines.append("")
		lines.append("Velocity: %.2f m/s" % velocity_mag)
		lines.append("v = (%.2f, %.2f, %.2f)" % [velocity.x, velocity.y, velocity.z])

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
	# The grid calls this DEFERRED, so _ready has already built the box. Nothing here may
	# rebuild on its own: a map that names neither axis must get the same scene it got
	# before this artifact was promoted. So each branch fires only when the value is
	# valid, DIFFERENT from what is already in play, and the body exists to change.
	var built: bool = physics_ball != null

	if config.has("body"):
		var b: String = String(config["body"]).strip_edges().to_lower()
		if BODY_MASS.has(b) and b != _body_value():
			body = b
			if built:
				_apply_body()

	if config.has("measure"):
		var m: String = String(config["measure"]).strip_edges().to_lower()
		if MEASURES.has(m) and m != _measure_value():
			measure = m
			if built:
				_apply_measure()


# --- axes -------------------------------------------------------------------

func _measure_value() -> String:
	var v: String = String(measure).strip_edges().to_lower()
	return v if MEASURES.has(v) else "both"


func _body_value() -> String:
	var v: String = String(body).strip_edges().to_lower()
	return v if BODY_MASS.has(v) else "standard"


func _body_mass() -> float:
	return float(BODY_MASS[_body_value()])


## Re-mass the ball that already exists, rather than rebuilding the containment. The
## collider and the mesh both follow the constant-density radius so the bulk is honest.
func _apply_body() -> void:
	_mass = _body_mass()
	if physics_ball == null:
		return
	physics_ball.mass = _mass
	var scaled_radius: float = BALL_RADIUS * pow(_mass / BALL_MASS, 1.0 / 3.0) * SCENE_SCALE
	for child in physics_ball.get_children():
		if child is CollisionShape3D:
			var shape: Shape3D = (child as CollisionShape3D).shape
			if shape is SphereShape3D:
				(shape as SphereShape3D).radius = scaled_radius
		elif child is MeshInstance3D:
			(child as MeshInstance3D).scale = Vector3.ONE * (scaled_radius * 2.0)


## Bring the read-only companion arrows in line with `measure` after the fact. The red
## force arrow is never touched — it is the thing you hold, not a measure.
func _apply_measure() -> void:
	var shown: String = _measure_value()
	_want_measure_vector("Velocity", shown == "both" or shown == "velocity",
		Color(0.3, 1.0, 0.3, 1.0))
	_want_measure_vector("Acceleration", shown == "both" or shown == "acceleration",
		Color(0.3, 0.3, 1.0, 1.0))


func _want_measure_vector(vector_name: String, want: bool, color: Color) -> void:
	var have: bool = force_vectors.has(vector_name)
	if want == have:
		return
	if want:
		var node: Node3D = create_force_vector(vector_name, Vector3.ZERO, color, false)
		if vector_name == "Velocity":
			velocity_vector = node
			_velocity_cache = _cached_vector_nodes.get(vector_name, {})
		else:
			acceleration_vector = node
			_accel_cache = _cached_vector_nodes.get(vector_name, {})
		return
	# Freed, not hidden: the whole arrow goes, so there is no orphaned subtree to keep
	# updating and update_force_vector_position() never sees a dangling entry.
	var old: Node = force_vectors[vector_name]
	force_vectors.erase(vector_name)
	_cached_vector_nodes.erase(vector_name)
	if vector_name == "Velocity":
		velocity_vector = null
		_velocity_cache = {}
	else:
		acceleration_vector = null
		_accel_cache = {}
	if is_instance_valid(old):
		old.queue_free()
