# ===========================================================================
# @identity
# essence: A moving ball carrying three live arrows — position, velocity, and acceleration — plus a fading trail, so the calculus of motion is shown as nested vectors
# desire: To make the chain "acceleration changes velocity changes position" visible at once, instead of as three separate equations a student must mentally integrate
# critical_parameter: acceleration — it is the only thing directly driven; velocity is its running sum and position is velocity's sum, so the top of the chain governs the whole arc
# triggers: A constant acceleration bends the path into a parabola; a centre-pointing one curls it into an orbit; zero acceleration straightens the trail into a line
# emerges: The relationship between the three vectors becomes legible — velocity always tangent to the trail, acceleration always bending it — without any formula on screen
# needs: moving ball [has], position/velocity/acceleration vectors [has], motion trail [has], live readout label [has]
# relationships: Vectors-sequence sibling to VectorBasics and VectorForces; the moving-body reading of the static vector_field flow
# truth: Position, velocity, and acceleration are one quantity seen at three depths of change — each is the rate at which the one below it is rewritten.
# ===========================================================================
extends "res://algorithms/vectors/shared/vector_scene_base.gd"

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
	ball = create_ball(Vector3(0.0, 1.0, 0.0), 0.2, 1.0, Color(0.9, 0.4, 0.7, 1.0))
	ball.linear_damp = 0.02
	ball.angular_damp = 0.05
	
	# Vectors (Logical values, will be positioned by logic)
	acceleration_vector = spawn_vector(Vector3.ZERO, Vector3(1.5, 0.5, 0.0), Color(1.0, 0.6, 0.3, 1.0), "Acceleration")
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
	
	# Apply SCALED force (F = ma)
	# accel_logical * mass * SCENE_SCALE
	ball.apply_central_force(accel_logical * ball.mass * SCENE_SCALE)
	
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
	ball.global_position = Vector3(0.0, 1.0, 0.0) * SCENE_SCALE
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


func apply_grid_config(config: Dictionary) -> void:
	pass
