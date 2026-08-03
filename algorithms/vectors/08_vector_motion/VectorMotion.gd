# ===========================================================================
# @identity
# essence: A moving ball carrying three live arrows — position, velocity, and acceleration — plus a fading trail, so the calculus of motion is shown as nested vectors
# desire: To make the chain "acceleration changes velocity changes position" visible at once, instead of as three separate equations a student must mentally integrate
# critical_parameter: acceleration — it is the only thing directly driven; velocity is its running sum and position is velocity's sum, so the top of the chain governs the whole arc
# triggers: A constant acceleration bends the path into a parabola; a centre-pointing one curls it into an orbit; zero acceleration straightens the trail into a line
# emerges: The relationship between the three vectors becomes legible — velocity always tangent to the trail, acceleration always bending it — without any formula on screen
# needs: moving ball [has], position/velocity/acceleration vectors [has], motion trail [has], live readout label [has], a drive axis so the three paths the identity names — parabola, orbit, straight line — are reachable from a map [has, 2026-08-03], a chain axis picking which depths of change are drawn [has, 2026-08-03]. Missing: an in-world switch so a walker can change drive without a map edit.
# relationships: Vectors-sequence sibling to VectorBasics and VectorForces; the moving-body reading of the static vector_field flow
# truth: Position, velocity, and acceleration are one quantity seen at three depths of change — each is the rate at which the one below it is rewritten.
# ===========================================================================
extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# ── DNA (promoted 2026-08-03, stage 2) ───────────────────────────────────────
# drive — what the acceleration is BOUND to. The shipped bench welded one answer
# into _physics_process: read the grabbable arrow, apply it as a constant central
# force, forever. The @identity's own "triggers" line already named the three
# other paths ("a constant acceleration bends the path into a parabola; a
# centre-pointing one curls it into an orbit; zero acceleration straightens the
# trail into a line") and no map could ask for any of them.
#   constant  the shipped build. The arrow is the acceleration, applied as read.
#             From rest the trail is a parabola — free fall in an arbitrary
#             direction. The player's grab still owns it entirely.
#   central   the arrow's magnitude, re-aimed at the origin every frame, and the
#             ball launched with the tangential speed for a circular orbit. The
#             acceleration is always perpendicular to the motion, so it changes
#             direction without changing speed — the claim that acceleration is
#             not "speeding up".
#   inertial  no force at all. The ball is launched once along the shipped arrow
#             and the arrow is zeroed. The trail is a straight line: with the top
#             of the chain removed, velocity is what persists.
#   resisted  the arrow minus a drag proportional to velocity. The parabola is a
#             lie outside a vacuum; here the ball bends once and then straightens
#             into a slanted line at terminal velocity, where the net acceleration
#             has gone to zero while the driving one has not.
@export_enum("constant", "central", "inertial", "resisted") var drive: String = "constant"

# chain — which depths of change are drawn. All three arrows are the historical
# build, and it is also the only reading a walker has ever been offered.
#   triple       the shipped build: acceleration (orange) and velocity (cyan) at
#                the ball, position (green) from the origin.
#   derivatives  acceleration and velocity only. Motion as cause and effect, with
#                no anchor to any origin — the reading a physicist works in.
#   state        position and velocity only. Where it is and how fast it is
#                going, with the cause off-stage — the reading a save file holds.
#   path         no arrows. Ball and trail alone: the motion itself, before
#                anyone decided to decompose it.
@export_enum("triple", "derivatives", "state", "path") var chain: String = "triple"

const DRIVE_VALUES := ["constant", "central", "inertial", "resisted"]
const CHAIN_VALUES := ["triple", "derivatives", "state", "path"]

# The shipped acceleration literal, named so launches are deterministic (a
# capture must not depend on where the arrow happens to be when it fires).
const ACCEL_START := Vector3(1.5, 0.5, 0.0)
const BALL_START := Vector3(0.0, 1.0, 0.0)
# Logical drag coefficient for drive=resisted. 3.0 puts terminal velocity at
# |a|/k ~ 0.53 logical, slow enough that the straightening is watchable.
const DRAG_K: float = 3.0

var ball: RigidBody3D
var acceleration_vector: Node3D
var velocity_vector: Node3D
var position_vector: Node3D
var info_label: Label
var accumulator := 0.0

# Pedagogical Enhancements: Trail
var trail_mesh_instance: MeshInstance3D
var trail_points: Array[Vector3] = []
const MAX_TRAIL_POINTS := 50
const TRAIL_UPDATE_INTERVAL := 0.05
var trail_timer := 0.0

# Cached nodes
var _cached_accel_nodes: Dictionary = {}
var _cached_vel_nodes: Dictionary = {}
var _cached_pos_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	super._ready()
	# Match the compact exhibition presentation used by other advanced vector scenes.
	scale = Vector3(0.5, 0.5, 0.5)
	create_axes(1.5)
	
	# Ball at (0, 1, 0) scaled
	ball = create_ball(BALL_START, 0.2, 1.0, Color(0.9, 0.4, 0.7, 1.0))
	ball.linear_damp = 0.02
	ball.angular_damp = 0.05

	# Vectors (Logical values, will be positioned by logic)
	acceleration_vector = spawn_vector(Vector3.ZERO, ACCEL_START, Color(1.0, 0.6, 0.3, 1.0), "Acceleration")
	velocity_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.3, 0.9, 1.0, 1.0), "Velocity", false)
	position_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.6, 1.0, 0.6, 1.0), "Position", false)
	
	info_label = create_info_panel(
		"Motion Vectors",
		Vector3(0.0, 2.5, -0.8),
		Vector2(2.4, 1.0),
		"v += a * dt\np += v * dt",
		"Acceleration drives velocity drives position"
	)
	
	# Trail Setup
	_create_trail_system()

	# Cache nodes
	_cache_vector_nodes(acceleration_vector, _cached_accel_nodes)
	_cache_vector_nodes(velocity_vector, _cached_vel_nodes)
	_cache_vector_nodes(position_vector, _cached_pos_nodes)

	# DNA — with drive=constant the launch is a no-op and with chain=triple this
	# only re-asserts the visibility every arrow already had, so the shipped tree
	# is unchanged.
	_apply_drive_launch()
	_apply_chain()

func _physics_process(delta: float) -> void:
	if not ball:
		return
	
	var ball_pos_scaled = ball.global_position
	# Position vector origin is Origin (0,0,0), pointing to ball
	position_vector.position = Vector3.ZERO
	
	# Accel and Vel vectors originate at the ball
	acceleration_vector.position = ball_pos_scaled
	velocity_vector.position = ball_pos_scaled
	
	# Logic: Read Logical Acceleration from vector input
	var accel_logical = _get_vector_fast(acceleration_vector, _cached_accel_nodes)

	# DNA: what the acceleration is bound to. drive=constant returns the arrow
	# untouched, so this line is the shipped line.
	accel_logical = _drive_acceleration(accel_logical)

	# Apply SCALED force (F = ma)
	# accel_logical * mass * SCENE_SCALE
	ball.apply_central_force(accel_logical * ball.mass * SCENE_SCALE)

	# central re-aims the arrow so the picture tells the truth about the force
	# actually acting. Every other drive leaves the arrow to the player.
	if drive == "central":
		_update_vector_fast(acceleration_vector, accel_logical, _cached_accel_nodes)

	# Read Back Logical Velocity and Position
	var vel_logical = ball.linear_velocity / SCENE_SCALE
	var pos_logical = ball_pos_scaled / SCENE_SCALE

	# Update Visual Vectors with Logical values
	_update_vector_fast(velocity_vector, vel_logical, _cached_vel_nodes)
	_update_vector_fast(position_vector, pos_logical, _cached_pos_nodes) # Points from origin to ball
	
	# Update Trail
	trail_timer += delta
	if trail_timer >= TRAIL_UPDATE_INTERVAL:
		trail_timer = 0.0
		_update_trail(ball_pos_scaled)
	
	# Update Text
	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(accel_logical, vel_logical, pos_logical)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset_ball()
		if event.keycode == KEY_SPACE:
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO

func _reset_ball() -> void:
	ball.global_position = BALL_START * SCENE_SCALE
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO

	# Clear Trail
	trail_points.clear()
	if trail_mesh_instance.mesh:
		trail_mesh_instance.mesh.clear_surfaces()

	var ball_pos_scaled = ball.global_position
	acceleration_vector.position = ball_pos_scaled
	velocity_vector.position = ball_pos_scaled
	# Force update visual positions
	_update_vector_fast(position_vector, ball_pos_scaled / SCENE_SCALE, _cached_pos_nodes)
	# drive=constant leaves the ball at rest exactly as before.
	_apply_drive_launch()

# ── DNA helpers ──────────────────────────────────────────────────────────────

## What the acceleration is bound to. "constant" hands the arrow straight back,
## which is the shipped `ball.apply_central_force(accel * mass * SCENE_SCALE)`.
func _drive_acceleration(from_arrow: Vector3) -> Vector3:
	match drive:
		"central":
			# Same magnitude the arrow carries, always pointing home. Forces are
			# world-space here (the shipped apply_central_force line is), so the
			# direction is taken between world positions.
			var home: Vector3 = global_position - ball.global_position
			var r: float = home.length()
			if r < 0.0001:
				return from_arrow
			return home / r * from_arrow.length()
		"inertial":
			return Vector3.ZERO
		"resisted":
			var vel_logical: Vector3 = ball.linear_velocity / SCENE_SCALE
			return from_arrow - vel_logical * DRAG_K
		_:
			return from_arrow

## World-space speed of a circular orbit at the ball's current radius, given the
## world acceleration the shipped arrow produces (a = |ACCEL_START| * SCENE_SCALE,
## because the force applied is accel_logical * mass * SCENE_SCALE).
func _orbit_speed() -> float:
	var r_world: float = (global_position - ball.global_position).length()
	return sqrt(ACCEL_START.length() * SCENE_SCALE * r_world)

## One-shot initial condition. drive=constant sets NOTHING — no velocity, no
## gravity change — so every existing placement still finds a ball at rest under
## world gravity exactly as it shipped.
##
## The other three switch world gravity off, because each of them is an argument
## about the arrow's acceleration and a 9.8 m/s^2 fall would simply be louder
## than the thing being shown.
func _apply_drive_launch() -> void:
	if not is_instance_valid(ball):
		return
	if drive == "constant":
		return
	ball.gravity_scale = 0.0
	if drive == "resisted":
		# Starts from rest like the shipped bench; the drag does the rest.
		return
	# central and inertial share one initial state — same point, same speed, same
	# direction — so the only difference between the circle and the line is the
	# drive itself.
	var home: Vector3 = global_position - ball.global_position
	if home.length() < 0.0001:
		return
	var tangent: Vector3 = home.cross(Vector3.BACK)
	if tangent.length() < 0.0001:
		tangent = home.cross(Vector3.RIGHT)
	ball.linear_velocity = tangent.normalized() * _orbit_speed()
	if drive == "inertial":
		# Launched, then the arrow is emptied — the whole point is that nothing
		# is driving it any more.
		_update_vector_fast(acceleration_vector, Vector3.ZERO, _cached_accel_nodes)

## Pure visibility on the three arrows that were always built. Nothing is added
## and nothing is freed, so chain=triple is the shipped tree exactly.
func _apply_chain() -> void:
	if is_instance_valid(acceleration_vector):
		acceleration_vector.visible = (chain == "triple" or chain == "derivatives")
	if is_instance_valid(velocity_vector):
		velocity_vector.visible = (chain != "path")
	if is_instance_valid(position_vector):
		position_vector.visible = (chain == "triple" or chain == "state")

func _update_info(accel: Vector3, vel: Vector3, pos: Vector3) -> void:
	var builder := []
	builder.append("Acceleration = (%.2f, %.2f, %.2f)" % [accel.x, accel.y, accel.z])
	builder.append("Velocity = (%.2f, %.2f, %.2f)" % [vel.x, vel.y, vel.z])
	builder.append("Speed = %.2f" % vel.length())
	builder.append("Position = (%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z])
	info_label.text = "\n".join(builder)

# --- Trail System ---

func _create_trail_system() -> void:
	trail_mesh_instance = MeshInstance3D.new()
	trail_mesh_instance.name = "MotionTrail"
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.9, 0.4, 0.7, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.use_point_size = true
	material.point_size = 4.0
	trail_mesh_instance.material_override = material
	
	var mesh = ImmediateMesh.new()
	trail_mesh_instance.mesh = mesh
	environment_root.add_child(trail_mesh_instance)

func _update_trail(current_pos: Vector3) -> void:
	trail_points.push_back(current_pos)
	if trail_points.size() > MAX_TRAIL_POINTS:
		trail_points.pop_front()
	
	var m = trail_mesh_instance.mesh as ImmediateMesh
	m.clear_surfaces()
	m.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in trail_points:
		m.surface_add_vertex(p)
	m.surface_end()

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


## Guarded: an absent, unknown or unchanged value touches nothing, and nothing is
## re-launched until _ready has actually built the ball.
##
## Deliberately does NOT chain to super. This class builds inline in _ready()
## instead of overriding build_scene(), so the base rebuild() (which frees every
## child and then calls an empty build_scene) would leave an empty artifact. The
## pre-promotion override was `pass`, so scale_multiplier was already ignored
## here; keeping it ignored is what preserves the four existing placements.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return
	var drive_changed: bool = false
	var chain_changed: bool = false
	if config.has("drive"):
		var d: String = str(config["drive"])
		if d in DRIVE_VALUES and d != drive:
			drive = d
			drive_changed = true
	if config.has("chain"):
		var c: String = str(config["chain"])
		if c in CHAIN_VALUES and c != chain:
			chain = c
			chain_changed = true
	if not is_instance_valid(ball):
		return
	if drive_changed:
		# Re-run the initial condition and drop the trail the old drive drew.
		_reset_ball()
	if chain_changed:
		_apply_chain()
