extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# @identity
# essence: F_net = gravity + thrust + drag; drag = -DRAG_COEFFICIENT * velocity; a = F_net / mass; velocity integrates acceleration each frame
# desire: to see Newton's second law in real time — gravity pulls, thrust fights back, drag resists motion, and the ball trajectory shows what the sum decides
# critical_parameter: DRAG_COEFFICIENT (0.8) — too high and the ball stops immediately; zero and it goes parabolic; the visible drag arrow shows the invisible resistance
# triggers: catapult_gadget launches ball → each frame: compute gravity/thrust/drag vectors → sum to F_net → update RigidBody3D → render all 6 vectors simultaneously
# emerges: the visible taxonomy of forces — five simultaneous arrows (gravity, thrust, drag, velocity, acceleration) let you watch how each contributes before they combine
# needs: VR catapult launch [has via catapult_gadget], thrust magnitude control [has via dna regime], drag coefficient slider [missing]
# relationships: the applied combination of VectorAddition (force superposition) and VectorDotProduct (drag opposes velocity direction); prerequisite to VectorTorque
# truth: A force is a direction with a claim. When two forces disagree, the net force is the argument they settle at.

const DRAG_COEFFICIENT := 0.8
const CatapultGadgetScript = preload("res://algorithms/vectors/shared/gadgets/catapult_gadget.gd")

# --- STAGE-2 DNA PROMOTION (2026-07-29) -------------------------------------
# This bench had no exports at all: one fixed sideways thrust, one fixed set of
# six arrows. But its own truth statement is "when two forces disagree, the net
# force is the argument they settle at" — which means the interesting variable
# is WHICH FORCES ARE IN THE ROOM, and WHICH OF THEM THE DIAGRAM CHOOSES TO DRAW.
# Two axes, both defaulting to today's exact behaviour:
#
#   regime   who is arguing         crosswind · freefall · stalemate · liftoff
#   diagram  what the chart shows   taxonomy · inputs · resultant · kinematics
#
# `diagram` is purely rhetorical — the physics is identical in all four; only the
# drawn arrows change. That is the point: a force diagram is an argument about
# what matters, not a readout.

## DNA axis 1 — which forces are present to disagree. crosswind = the historical
## sideways thrust fighting gravity; freefall = gravity alone; stalemate = thrust
## exactly cancels weight (net zero, the ball hangs); liftoff = thrust wins.
@export var regime: String = "crosswind"

## DNA axis 2 — which of the six vectors the diagram draws. taxonomy = all six
## (historical); inputs = only the forces being summed; resultant = only the sum;
## kinematics = only what the sum produced (velocity, acceleration).
@export var diagram: String = "taxonomy"

const THRUST_CROSSWIND := Vector3(2.5, 0.0, 0.0)
const GRAVITY_ACCEL := Vector3(0.0, -6.0, 0.0)
const BALL_MASS := 1.2

const DIAGRAM_SETS := {
	"taxonomy": ["Gravity", "Thrust", "Drag", "Net Force", "Velocity", "Acceleration"],
	"inputs": ["Gravity", "Thrust", "Drag"],
	"resultant": ["Net Force"],
	"kinematics": ["Velocity", "Acceleration"],
}

var _dna_built: bool = false

var ball: RigidBody3D
var gravity_vector: Node3D
var thrust_vector: Node3D
var drag_vector: Node3D
var net_vector: Node3D
var velocity_vector: Node3D
var accel_vector: Node3D
var info_label: Label
var accumulator := 0.0
var catapult_gadget: Node3D

# Cached nodes
var _cached_gravity_nodes: Dictionary = {}
var _cached_thrust_nodes: Dictionary = {}
var _cached_drag_nodes: Dictionary = {}
var _cached_net_nodes: Dictionary = {}
var _cached_velocity_nodes: Dictionary = {}
var _cached_accel_nodes: Dictionary = {}

func _ready() -> void:
	super._ready()
	# Half-size for exhibition display
	scale = Vector3(0.5, 0.5, 0.5)

	create_axes(1.5)
	_create_ground()
	ball = create_ball(Vector3(0.0, 1.2, 0.0), 0.22, BALL_MASS, Color(0.9, 0.5, 1.0, 1.0))

	# Force vectors: light blue gravity, warm thrust, cool drag, bright green net
	gravity_vector = spawn_vector(Vector3.ZERO, GRAVITY_ACCEL, Color(0.5, 0.75, 1.0, 1.0), "Gravity")
	thrust_vector = spawn_vector(Vector3.ZERO, THRUST_CROSSWIND, Color(1.0, 0.55, 0.35, 1.0), "Thrust")
	drag_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.65, 0.75, 1.0, 0.6), "Drag", false)
	net_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.45, 1.0, 0.4, 0.9), "Net Force", false)
	velocity_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.55, 0.95, 1.0, 0.8), "Velocity", false)
	accel_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(1.0, 0.9, 0.45, 0.85), "Acceleration", false)

	info_label = create_info_panel("Vector Forces", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "F_net = sum(F_i)", "Net force from thrust, gravity, drag")

	# Catapult gadget
	catapult_gadget = CatapultGadgetScript.new()
	catapult_gadget.position = Vector3(-0.6, 0, 0)
	add_child(catapult_gadget)

	# Cache nodes
	_cache_vector_nodes(gravity_vector, _cached_gravity_nodes)
	_cache_vector_nodes(thrust_vector, _cached_thrust_nodes)
	_cache_vector_nodes(drag_vector, _cached_drag_nodes)
	_cache_vector_nodes(net_vector, _cached_net_nodes)
	_cache_vector_nodes(velocity_vector, _cached_velocity_nodes)
	_cache_vector_nodes(accel_vector, _cached_accel_nodes)

	_dna_built = true
	_apply_dna()

# --- DNA ---------------------------------------------------------------------

## The thrust the chosen regime puts in the room. crosswind returns exactly the
## historical constant, so the default is byte-for-byte the pre-promotion scene.
func _thrust_for_regime() -> Vector3:
	var mass: float = BALL_MASS
	if ball:
		mass = ball.mass
	if regime == "freefall":
		return Vector3.ZERO
	if regime == "stalemate":
		return -GRAVITY_ACCEL * mass
	if regime == "liftoff":
		return -GRAVITY_ACCEL * mass * 1.6
	return THRUST_CROSSWIND

## Push the two axes into the built scene. Nothing here rebuilds: the regime is
## one endpoint move on the thrust arrow, the diagram is six visibility flags.
func _apply_dna() -> void:
	if thrust_vector:
		_update_vector_fast(thrust_vector, _thrust_for_regime(), _cached_thrust_nodes)

	var shown: Array = DIAGRAM_SETS["taxonomy"]
	if DIAGRAM_SETS.has(diagram):
		shown = DIAGRAM_SETS[diagram]

	var arrows: Dictionary = {
		"Gravity": gravity_vector,
		"Thrust": thrust_vector,
		"Drag": drag_vector,
		"Net Force": net_vector,
		"Velocity": velocity_vector,
		"Acceleration": accel_vector,
	}
	for key in arrows.keys():
		var arrow: Node3D = arrows[key]
		if arrow == null:
			continue
		var wanted: bool = shown.has(key)
		arrow.visible = wanted
		if not wanted:
			# Do not leave an invisible arrow grabbable in VR.
			_disable_grab_sphere(arrow.get_node_or_null("lineContainer/GrabSphere"))
			_disable_grab_sphere(arrow.get_node_or_null("lineContainer/GrabSphere2"))

func _physics_process(delta: float) -> void:
	if not ball:
		return
	
	# ball.global_position is already in Scaled World Space.
	# gravity_vector.position expects Scaled World Space (because parent is unscaled).
	# So we can assign directly.
	var ball_pos_scaled = ball.global_position

	gravity_vector.position = ball_pos_scaled
	thrust_vector.position = ball_pos_scaled
	drag_vector.position = ball_pos_scaled
	net_vector.position = ball_pos_scaled
	velocity_vector.position = ball_pos_scaled
	accel_vector.position = ball_pos_scaled

	# get_vector returns LOGICAL force (unscaled).
	var gravity_logical = _get_vector_fast(gravity_vector, _cached_gravity_nodes)
	var gravity_force_logical = gravity_logical * ball.mass
	
	var thrust_force_logical = _get_vector_fast(thrust_vector, _cached_thrust_nodes)
	
	# Calculate LOGICAL velocity from physical scaled velocity
	var velocity_logical = ball.linear_velocity / SCENE_SCALE
	var drag_force_logical = -velocity_logical * DRAG_COEFFICIENT
	
	# Update drag vector visual with LOGICAL force
	_update_vector_fast(drag_vector, drag_force_logical, _cached_drag_nodes)

	# Sum LOGICAL forces
	var net_force_logical = gravity_force_logical + thrust_force_logical + drag_force_logical

	# Update net force vector visual
	_update_vector_fast(net_vector, net_force_logical, _cached_net_nodes)
	# Update velocity / acceleration visuals
	_update_vector_fast(velocity_vector, velocity_logical, _cached_velocity_nodes)
	var accel_logical = net_force_logical / ball.mass
	_update_vector_fast(accel_vector, accel_logical, _cached_accel_nodes)

	# Apply SCALED force to physics body so simulation matches visual scale
	ball.apply_central_force(net_force_logical * SCENE_SCALE)

	# Update catapult gadget â€” follow ball position
	if catapult_gadget:
		catapult_gadget.update_from_vectors(thrust_force_logical, gravity_force_logical)

	accumulator += delta
	if accumulator > 0.1:
		_update_info(gravity_force_logical, thrust_force_logical, drag_force_logical, net_force_logical, velocity_logical)
		accumulator = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_ball()
		if event.keycode == KEY_SPACE:
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO

func _reset_ball() -> void:
	# Reset to scaled position
	ball.global_position = Vector3(0.0, 1.2, 0.0) * SCENE_SCALE
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	
	var ball_pos_scaled = ball.global_position
	gravity_vector.position = ball_pos_scaled
	thrust_vector.position = ball_pos_scaled
	drag_vector.position = ball_pos_scaled
	net_vector.position = ball_pos_scaled
	velocity_vector.position = ball_pos_scaled
	accel_vector.position = ball_pos_scaled

func _update_info(gravity_force: Vector3, thrust_force: Vector3, drag_force: Vector3, net_force: Vector3, velocity: Vector3) -> void:
	var builder := []
	builder.append("Gravity = (%.2f, %.2f, %.2f)" % [gravity_force.x, gravity_force.y, gravity_force.z])
	builder.append("Thrust = (%.2f, %.2f, %.2f)" % [thrust_force.x, thrust_force.y, thrust_force.z])
	builder.append("Drag = (%.2f, %.2f, %.2f)" % [drag_force.x, drag_force.y, drag_force.z])
	builder.append("Net = (%.2f, %.2f, %.2f)" % [net_force.x, net_force.y, net_force.z])
	# Acceleration = F/m (Logical)
	var acc = net_force / ball.mass
	builder.append("Acceleration = (%.2f, %.2f, %.2f)" % [acc.x, acc.y, acc.z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [velocity.x, velocity.y, velocity.z])
	info_label.text = "\n".join(builder)

func _create_ground() -> void:
	var ground = StaticBody3D.new()
	ground.name = "Ground"
	var collider = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(20, 0.1, 20) * SCENE_SCALE # Scale the ground
	collider.shape = box
	ground.add_child(collider)
	add_child(ground)

# --- Caching Helpers (Local Implementation) ---

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary) -> void:
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return (end.global_position - start.global_position) / (SCENE_SCALE * scale.x)
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Guarded: only touches the scene when a value actually CHANGED, and only after
## _ready() has built once. Config can arrive before _ready — then the exports are
## simply seeded and _ready applies them.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var changed: bool = false
	if config.has("regime"):
		var new_regime: String = str(config["regime"])
		if new_regime != regime:
			regime = new_regime
			changed = true
	if config.has("diagram"):
		var new_diagram: String = str(config["diagram"])
		if new_diagram != diagram:
			diagram = new_diagram
			changed = true
	if changed and _dna_built:
		_apply_dna()
