extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Torque Demo
## Demonstrates: τ = r × F (cross product)
## Concept: Rotational force depends on position and direction
## Agent-PhysicsArchitect: Shows angular acceleration
## Protocol: IACP v2.2
##
## @identity
## essence: tau = r x F. The cross product. Torque is perpendicular to both the lever arm and the force. The right-hand rule determines spin direction.
## desire: To let the learner drag both the force and its application point — and watch the purple torque vector pop out perpendicular, spinning the ball.
## critical_parameter: force_offset (the lever arm r). Force through the center produces zero torque. The further off-center, the more spin per unit force.
## triggers: Drag cyan position handle → changes lever arm, drag red force handle → changes force direction/magnitude, purple torque arrow → updates via cross product, ball spins
## emerges: Zero torque when force passes through center (r parallel to F → cross product vanishes). Maximum torque when force is perpendicular to the lever arm.
## needs: VR draggable position and force vectors [has], torque readout [has]. Missing: wrench/door metaphor visualization, angular momentum display.
## relationships: Cross product counterpart to dot_product_projector. Feeds into example_3_2 (angular motion from forces). Core operation in rigid body physics.
## truth: Torque is not a force. It is the force's opinion about rotation, measured by how far off-center and how perpendicular it acts.

var force_vector: Node3D
var position_vector: Node3D
var torque_vector: Node3D

# Cached nodes
var _force_cache: Dictionary = {}
var _position_cache: Dictionary = {}
var _torque_cache: Dictionary = {}

var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

# Force application point (offset from center)
var force_offset: Vector3 = Vector3(0.15, 0, 0)

## AXIS — WHICH PERPENDICULAR THE CROSS PRODUCT IS TAKEN TO MEAN. Taken character for
## character, values and order, from [[VectorCrossProduct]] — the bench standing in THIS
## SAME FOLDER (algorithms/vectors/06_vector_cross_product/) and arguing the same product.
## Two halves of one lesson should not carry two vocabularies for the right-hand rule.
##
##   right  tau = r x F. The purple arrow leaves the ball along +Z and the ball spins the
##          way the right hand says. The literal `r.cross(f)` this file was written with.
##   left   tau = F x r. Same magnitude, other side of the r-F plane: the arrow crosses
##          through the ball and comes out the far side, and the applied spin reverses too.
##   both   the two perpendiculars nose to nose through the ball, the counter-arrow dimmer,
##          so the choice of hand is a picture in the room instead of a rule in the caption.
##
## WHY IT IS REACHABLE HERE AND WAS NOT ON torque_crank. The crank refused this exact word
## on 2026-08-05 for its BODY, not the word's meaning: its tau runs straight down a 0.05 m
## axle rising out of a 0.30 m pedestal, so a left-handed arrow of radius 0.034 lies INSIDE
## the axle for 0.90 of its length and the flip photographs as a DELETION. This bench has
## nothing standing under it. The ball hangs at the centre of a 1x1x1 containment, and
## tau = (0.15,0,0) x (0,2,0) = (0,0,0.30) leaves it HORIZONTALLY — as does -tau, through
## the same empty air, 0.0495 m of it either way against a wall plane 0.165 m out. The
## containment's only rendered panels are the two horizontal ones at y = +/-0.5; the four
## upright ones are PlaneMesh instances scaled on an axis a plane has no extent in, so they
## draw as edge-on slivers. Nothing at all lies between a camera and either perpendicular.
@export_enum("right", "left", "both") var handedness: String = "right"
const HANDEDNESS: PackedStringArray = ["right", "left", "both"]

# The counter-perpendicular. Null unless `both` was asked for — at right and left this node
# is never constructed, so the shipped tree is what it always was.
var torque_mirror: Node3D
var _torque_mirror_cache: Dictionary = {}

func _ready() -> void:
	super._ready()
	_setup_demo()
	print("TorqueDemo: Ready - Apply force off-center!")

func _setup_demo() -> void:
	"""Setup torque demonstration"""
	# Position vector (from center to force application point) - Cyan
	position_vector = create_force_vector(
		"Position (r)",
		force_offset,
		Color(0.3, 0.8, 1.0, 1.0),
		true  # Can drag to change application point
	)
	_position_cache = _cached_vector_nodes["Position (r)"]
	
	# Force vector (user can drag) - Red
	force_vector = create_force_vector(
		"Force (F)",
		Vector3(0, 2.0, 0),
		Color(1.0, 0.3, 0.3, 1.0),
		true
	)
	_force_cache = _cached_vector_nodes["Force (F)"]
	
	# Torque vector (read-only, shows τ = r × F) - Purple
	torque_vector = create_force_vector(
		"Torque (τ)",
		Vector3.ZERO,
		Color(0.8, 0.3, 1.0, 1.0),
		false
	)
	_torque_cache = _cached_vector_nodes["Torque (τ)"]

	# BOTH — the counter-perpendicular. Built here and nowhere else, and only when a map
	# has asked for it: at `right` and `left` this call never happens, so no node is added
	# and the containment, the ball and the three shipped arrows are the whole scene.
	if _handedness_value() == "both":
		_build_mirror()

	update_info_text([
		"Torque Demo",
		"Drag CYAN (position)",
		"Drag RED (force)",
		"τ = r × F"
	])

func _physics_process(delta: float) -> void:
	# Get position and force (logical)
	var r = _get_vector_fast_cached(_position_cache)
	var f = _get_vector_fast_cached(_force_cache)
	
	# Calculate torque: τ = r × F (cross product!)
	# HANDEDNESS decides which perpendicular that phrase names. `right` is r.cross(f) —
	# the literal shipped line — and `left` takes the operands the other way round, which
	# is the same anti-commutativity VectorCrossProduct's `left` reads off the same product.
	var torque: Vector3 = f.cross(r) if _handedness_value() == "left" else r.cross(f)

	# Update torque vector visualization
	_update_vector_fast_cached(_torque_cache, torque * 0.5)  # Scale for visibility
	# The counter-arrow, when `both` built one. Same scale, opposite side of the plane.
	if torque_mirror != null:
		_update_vector_fast_cached(_torque_mirror_cache, torque * -0.5)
	
	# Apply torque to ball (scaled)
	physics_ball.apply_torque(torque * SCENE_SCALE)
	
	# Also apply the force at the offset position
	# This makes the physics more realistic
	var force_world_pos = physics_ball.global_position + (r * SCENE_SCALE)
	physics_ball.apply_force(f * SCENE_SCALE, r * SCENE_SCALE)
	
	# Update vector positions
	var ball_pos_scaled = physics_ball.global_position
	position_vector.position = ball_pos_scaled
	force_vector.position = ball_pos_scaled + (r * SCENE_SCALE)
	torque_vector.position = ball_pos_scaled
	if torque_mirror != null:
		torque_mirror.position = ball_pos_scaled

	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(r, f, torque)
		accumulator = 0.0

func _update_info(r: Vector3, f: Vector3, torque: Vector3) -> void:
	"""Update info display"""
	var angular_vel = physics_ball.angular_velocity / SCENE_SCALE
	
	var lines = [
		"Torque Demo",
		"",
		"Position: %.2f m" % r.length(),
		"r = (%.2f, %.2f, %.2f)" % [r.x, r.y, r.z],
		"",
		"Force: %.2f N" % f.length(),
		"F = (%.2f, %.2f, %.2f)" % [f.x, f.y, f.z],
		"",
		"Torque: %.2f N·m" % torque.length(),
		"τ = r × F",
		"τ = (%.2f, %.2f, %.2f)" % [torque.x, torque.y, torque.z],
		"",
		"Angular Velocity: %.2f rad/s" % angular_vel.length(),
		"ω = (%.2f, %.2f, %.2f)" % [angular_vel.x, angular_vel.y, angular_vel.z]
	]
	update_info_text(lines)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_demo()
		elif event.keycode == KEY_SPACE:
			physics_ball.linear_velocity = Vector3.ZERO
			physics_ball.angular_velocity = Vector3.ZERO

func _reset_demo() -> void:
	"""Reset to initial state"""
	reset_ball(Vector3.ZERO)
	
	# Reset position vector
	var end_r: Node3D = _position_cache.get("end")
	if end_r:
		end_r.position = Vector3(0.15, 0, 0) * SCENE_SCALE
	var line_r: Node3D = _position_cache.get("line_container")
	if line_r and line_r.has_method("refresh_connections"):
		line_r.refresh_connections()
	
	# Reset force vector
	var end_f: Node3D = _force_cache.get("end")
	if end_f:
		end_f.position = Vector3(0, 2.0, 0) * SCENE_SCALE
	var line_f: Node3D = _force_cache.get("line_container")
	if line_f and line_f.has_method("refresh_connections"):
		line_f.refresh_connections()
	
	print("TorqueDemo: Reset")

# --- HANDEDNESS ---------------------------------------------------------------
# One axis, three values, shared word for word with the bench next door. Nothing below
# changes what the machine COMPUTES about magnitude: |tau| = |r||F|sin(theta) is the same
# float at every value, the readout prints the same "Torque: %.2f N·m", and the arrow is
# the same length. Only which way it points, and therefore which way the ball turns.


## An unrecognised word falls back to the shipped reading rather than stranding a live
## placement with no perpendicular at all — the same allow-list discipline the rest of the
## vector subject uses.
func _handedness_value() -> String:
	var h: String = String(handedness).strip_edges().to_lower()
	return h if HANDEDNESS.has(h) else "right"


## The second perpendicular, read-only and dimmer than the first, so the pair reads as one
## arrow and its reflection rather than as two claims. Its endpoint is driven from the same
## torque every physics frame, negated.
func _build_mirror() -> void:
	if torque_mirror != null:
		return
	torque_mirror = create_force_vector(
		"Torque (-τ)",
		Vector3.ZERO,
		Color(0.45, 0.22, 0.62, 1.0),
		false
	)
	_torque_mirror_cache = _cached_vector_nodes["Torque (-τ)"]


## Guarded on all three counts this corpus has been burned by: the key must be NAMED, the
## word must VALIDATE, and the value must actually DIFFER. Nothing is ever torn down — the
## perpendicular is recomputed from `handedness` on the next physics frame, and the only
## structural change any value can make is adding or freeing the single counter-arrow that
## `both` asks for. Called before _ready, torque_vector is still null and the value simply
## waits for _setup_demo() to read it.
##
## super.apply_grid_config() is deliberately NOT called, which preserves today's behaviour
## exactly: this override has always been `pass`, so scale_multiplier has never reached this
## bench. Forwarding it would route into VectorSceneBase.rebuild(), which calls build_scene()
## — a method this artifact does not implement, because it builds from _ready() instead. That
## would free the demo and rebuild an empty containment. Reported, not fixed here.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or not config.has("handedness"):
		return
	var h: String = String(config["handedness"]).strip_edges().to_lower()
	if not HANDEDNESS.has(h) or h == handedness:
		return
	handedness = h
	if torque_vector == null:
		return                                   # _ready has not built yet; it will read it
	if h == "both":
		_build_mirror()
	elif torque_mirror != null:
		force_vectors.erase("Torque (-τ)")
		_cached_vector_nodes.erase("Torque (-τ)")
		_torque_mirror_cache = {}
		torque_mirror.queue_free()
		torque_mirror = null
