extends "res://algorithms/vectors/shared/force_containment_base.gd"

## Combined Forces Demo
## Demonstrates: F_net = F1 + F2 (vector addition)
## Concept: Forces combine using tip-to-tail addition
## Agent-PhysicsArchitect: Shows superposition principle
## Protocol: IACP v2.2
##
## @identity
## essence: F_net = F1 + F2. Superposition. Forces add as vectors. The ball feels only the sum.
## desire: To let the learner drag two force arrows and watch the ball respond to their sum — not to either alone. Superposition as felt experience.
## critical_parameter: The angle between F1 and F2. Parallel forces compound; perpendicular forces create diagonal motion; opposing forces cancel.
## triggers: Drag red F1 or orange F2 → yellow net force updates, ball accelerates along net force, R → reset, Space → freeze
## emerges: Cancellation when forces oppose. Diagonal trajectories from perpendicular forces. The net force arrow always predicting the ball's next move.
## needs: VR draggable force vectors [has], net force visualization [has], velocity readout [has], third force [has, force_count:3].
## relationships: Physical application of vector_addition_demo. Feeds into ForcesComposition map. Prerequisite for weather_vector_field (wind superposition).
## truth: Nature does not apply forces one at a time. Every force acts simultaneously. The body knows only the sum.
##
## STAGE-2 DNA PROMOTION (2026-07-29). This artifact had zero exports: two force
## arrows hard-coded to +X and +Y, forever. Its own @identity already named both
## axes it was missing — "critical_parameter: The angle between F1 and F2" and
## "needs: ... Missing: third force for true 3-body superposition" — so the
## parameter space was written down years before anything could turn it.
##
##   composition   the ANGLE between the forces   orthogonal · compounding · opposing
##   force_count   how many forces the body feels  1 · 2 · 3
##
## composition=orthogonal with force_count=2 reproduces the old scene exactly —
## F1 = (1.5, 0, 0), F2 = (0, 1.5, 0), same colours, same info text — so the five
## existing placements are untouched.
##
## The three compositions are three different claims about addition:
##   orthogonal   90 deg   the resultant points where neither force does
##   compounding  25 deg   the resultant is nearly the sum of the magnitudes
##   opposing    180 deg   the resultant is ZERO and the ball does not move,
##                         which is the one case a learner never predicts
##
## Usage in map_data.json:
##   "combined_forces_demo#composition:opposing"
##   "combined_forces_demo#composition:compounding#force_count:3"

## The angle relationship the two (or three) draggable forces START in.
@export_enum("orthogonal", "compounding", "opposing") var composition: String = "orthogonal"
## How many draggable forces act on the ball. The ball always feels only the sum.
@export_range(1, 3, 1) var force_count: int = 2

## Starting force vectors per composition, in logical units. Slot 0 is identical
## in all three: the promotion changes what F2 (and F3) argue about F1, never F1
## itself. Slot 2 is only read when force_count is 3.
const COMPOSITIONS := {
	"orthogonal": [Vector3(1.5, 0, 0), Vector3(0, 1.5, 0), Vector3(0, 0, 1.5)],
	"compounding": [Vector3(1.5, 0, 0), Vector3(1.36, 0.63, 0), Vector3(1.06, 1.06, 0)],
	"opposing": [Vector3(1.5, 0, 0), Vector3(-1.5, 0, 0), Vector3(0, 1.5, 0)],
}

## Red, orange, violet. The first two are the pre-promotion colours.
const FORCE_COLORS := [
	Color(1.0, 0.3, 0.3, 1.0),
	Color(1.0, 0.6, 0.2, 1.0),
	Color(0.65, 0.4, 1.0, 1.0),
]

var force1_vector: Node3D
var force2_vector: Node3D
var net_force_vector: Node3D
var velocity_vector: Node3D

# Cached nodes
var _force1_cache: Dictionary = {}
var _force2_cache: Dictionary = {}
var _net_cache: Dictionary = {}
var _velocity_cache: Dictionary = {}
# One cache per live force, in slot order. _force1_cache / _force2_cache stay as
# aliases so anything reading them keeps working.
var _force_caches: Array[Dictionary] = []
var _built: bool = false

var accumulator: float = 0.0
const UPDATE_INTERVAL = 0.1

func _ready() -> void:
	super._ready()
	_setup_demo()
	print("CombinedForcesDemo: Ready - Drag the force vectors!")

func _start_force(slot: int) -> Vector3:
	"""Initial vector for a force slot under the current composition."""
	var table: Array = COMPOSITIONS.get(composition, COMPOSITIONS["orthogonal"])
	if slot < 0 or slot >= table.size():
		return Vector3.ZERO
	var v: Vector3 = table[slot]
	return v

func _setup_demo() -> void:
	"""Setup combined forces demonstration"""
	_force_caches.clear()

	var count: int = clampi(force_count, 1, 3)
	for slot in range(count):
		var force_name: String = "Force %d" % (slot + 1)
		var color: Color = FORCE_COLORS[slot]
		var arrow: Node3D = create_force_vector(
			force_name,
			_start_force(slot),
			color,
			true
		)
		_force_caches.append(_cached_vector_nodes[force_name])
		if slot == 0:
			force1_vector = arrow
			_force1_cache = _cached_vector_nodes[force_name]
		elif slot == 1:
			force2_vector = arrow
			_force2_cache = _cached_vector_nodes[force_name]

	# Net force (read-only, shows the sum) - Yellow
	net_force_vector = create_force_vector(
		"Net Force",
		Vector3.ZERO,
		Color(1.0, 1.0, 0.3, 1.0),
		false
	)
	_net_cache = _cached_vector_nodes["Net Force"]

	# Velocity (read-only) - Green
	velocity_vector = create_force_vector(
		"Velocity",
		Vector3.ZERO,
		Color(0.3, 1.0, 0.3, 1.0),
		false
	)
	_velocity_cache = _cached_vector_nodes["Velocity"]

	# The two-force wording is the pre-promotion text, character for character.
	var drag_line: String = "Drag RED and ORANGE vectors"
	var sum_line: String = "F_net = F1 + F2"
	if count == 1:
		drag_line = "Drag the RED vector"
		sum_line = "F_net = F1"
	elif count == 3:
		drag_line = "Drag RED, ORANGE and VIOLET vectors"
		sum_line = "F_net = F1 + F2 + F3"
	update_info_text([
		"Combined Forces Demo",
		drag_line,
		sum_line,
		"Forces add as vectors"
	])
	_built = true

func _physics_process(delta: float) -> void:
	if not _built:
		return
	update_force_vector_position()

	# Get forces (logical units)
	var forces: Array[Vector3] = []
	for cache: Dictionary in _force_caches:
		forces.append(_get_vector_fast_cached(cache))

	# Calculate net force (vector addition!)
	var f_net: Vector3 = Vector3.ZERO
	for f: Vector3 in forces:
		f_net += f

	# Update net force vector visualization
	_update_vector_fast_cached(_net_cache, f_net)

	# Apply net force to ball
	physics_ball.apply_central_force(f_net * SCENE_SCALE)

	# Get velocity
	var velocity: Vector3 = physics_ball.linear_velocity / SCENE_SCALE
	_update_vector_fast_cached(_velocity_cache, velocity)

	# Throttled info update
	accumulator += delta
	if accumulator >= UPDATE_INTERVAL:
		_update_info(forces, f_net, velocity)
		accumulator = 0.0

func _update_info(forces: Array[Vector3], f_net: Vector3, velocity: Vector3) -> void:
	"""Update info display"""
	var lines: Array = ["Combined Forces Demo", ""]
	for i in range(forces.size()):
		var f: Vector3 = forces[i]
		lines.append("Force %d: %.2f N" % [i + 1, f.length()])
		lines.append("F%d = (%.2f, %.2f, %.2f)" % [i + 1, f.x, f.y, f.z])
		lines.append("")
	var sum_terms: String = ""
	for i in range(forces.size()):
		sum_terms += ("F%d" % (i + 1)) if i == 0 else (" + F%d" % (i + 1))
	lines.append("Net Force: %.2f N" % f_net.length())
	lines.append("F_net = " + sum_terms)
	lines.append("F_net = (%.2f, %.2f, %.2f)" % [f_net.x, f_net.y, f_net.z])
	lines.append("")
	lines.append("Velocity: %.2f m/s" % velocity.length())
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

	for i in range(_force_caches.size()):
		var cache: Dictionary = _force_caches[i]
		var end_node: Node3D = cache.get("end")
		if end_node:
			end_node.position = _start_force(i) * SCENE_SCALE
		var line_node: Node3D = cache.get("line_container")
		if line_node and line_node.has_method("refresh_connections"):
			line_node.refresh_connections()

	print("CombinedForcesDemo: Reset")

func _rebuild_forces() -> void:
	"""Tear down the force arrows and build them again from the current DNA.

	Only ever called from apply_grid_config, and only when a value actually
	changed — an unguarded rebuild here would re-spawn every arrow on maps that
	set no DNA at all.
	"""
	_built = false
	for vector in force_vectors.values():
		if is_instance_valid(vector):
			vector.queue_free()
	force_vectors.clear()
	_cached_vector_nodes.clear()
	_force_caches.clear()
	_force1_cache = {}
	_force2_cache = {}
	_setup_demo()

func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("composition"):
		var wanted: String = str(config_data["composition"])
		if COMPOSITIONS.has(wanted) and wanted != composition:
			composition = wanted
			changed = true

	if config_data.has("force_count"):
		var wanted_count: int = clampi(int(config_data["force_count"]), 1, 3)
		if wanted_count != force_count:
			force_count = wanted_count
			changed = true

	# Guarded: no rebuild unless a value moved AND _ready already built once.
	if changed and _built and is_inside_tree():
		_rebuild_forces()
