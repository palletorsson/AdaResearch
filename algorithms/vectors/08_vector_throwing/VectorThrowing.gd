# VectorThrowing.gd
# Main scene for demonstrating projectile motion with velocity, gravity vectors, and homing drone targets
extends "../shared/vector_scene_base.gd"

@export_group("Scene Configuration")
@export var num_balls: int = 3
@export var ball_spawn_height: float = 1.5
@export var ball_spawn_spacing: float = 0.3

@export_group("Target Configuration")
@export var target_rows: int = 3
@export var target_columns: int = 4
@export var target_spacing: float = 0.6
@export var target_distance: float = 3.0
@export var target_height_offset: float = 1.0

@export_group("Drone Configuration")
@export var enable_drones: bool = true
@export var drone_count: int = 1
@export var drone_spawn_radius: float = 3.5
@export var drone_spawn_height: float = 1.6
@export var drone_respawn_time: float = 6.0
@export var drone_points_value: int = 40
@export var drone_base_color: Color = Color(1.0, 0.45, 0.1, 1.0)

@export_group("Scoring")
@export var enable_scoring: bool = true
@export var show_instructions: bool = true

# Scene references
var throw_balls: Array[Node3D] = []
var target_cubes: Array[Node3D] = []
var score_label: Label3D = null
var instructions_label: Label3D = null
var info_panel: Label3D = null
var drone_container: Node3D = null

# Trajectory Visualization
var _trajectory_mesh: ImmediateMesh = null
var _trajectory_points: PackedVector3Array = []
var _time_since_last_text_update: float = 0.0

# Game state
var total_score: int = 0
var total_hits: int = 0
var throws_count: int = 0
var drones_destroyed: int = 0
var player_hits_taken: int = 0

var drone_spawn_points: Array[Vector3] = []
var drones_by_index: Dictionary = {}

# Preloaded scenes
var throw_ball_scene = preload("res://algorithms/vectors/08_vector_throwing/throw_ball.tscn")
var hit_target_scene = preload("res://algorithms/vectors/08_vector_throwing/hit_target_cube.tscn")
var drone_scene = preload("res://algorithms/vectors/08_vector_throwing/vector_drone.tscn")

func _ready() -> void:
	super._ready()
	
	_setup_trajectory_vis()
	_setup_environment()
	_spawn_throw_balls()
	_spawn_target_grid()
	_spawn_drones()
	_create_score_display()
	_create_instructions()
	_create_physics_info_panel()
	_update_score_display()

func _setup_trajectory_vis() -> void:
	_trajectory_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _trajectory_mesh
	mesh_instance.name = "TrajectoryLine"
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.4)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 1.0)
	material.emission_energy_multiplier = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	
	environment_root.add_child(mesh_instance)

func _setup_environment() -> void:
	create_axes(2.0)
	create_floor(10.0, Color(0.2, 0.3, 0.4, 0.5))
	_create_origin_marker()

func _spawn_throw_balls() -> void:
	var balls_container = Node3D.new()
	balls_container.name = "ThrowBalls"
	add_child(balls_container)

	for i in range(num_balls):
		var ball = throw_ball_scene.instantiate()
		ball.name = "ThrowBall_%d" % i
		var x_offset = (i - (num_balls - 1) / 2.0) * ball_spawn_spacing
		# Apply global SCENE_SCALE to position and size
		ball.position = Vector3(x_offset, ball_spawn_height, 0.5) * SCENE_SCALE
		ball.scale = Vector3.ONE * SCENE_SCALE
		
		var hue = float(i) / float(num_balls)
		var color = Color.from_hsv(hue, 0.8, 1.0)
		if ball.has_method("set_ball_color"):
			ball.set_ball_color(color)
		else:
			ball.ball_color = color
		ball.dropped.connect(_on_ball_thrown.bind(ball))
		balls_container.add_child(ball)
		throw_balls.append(ball)

func _spawn_target_grid() -> void:
	var targets_container = Node3D.new()
	targets_container.name = "TargetCubes"
	add_child(targets_container)

	for row in range(target_rows):
		for col in range(target_columns):
			var target = hit_target_scene.instantiate()
			target.name = "Target_%d_%d" % [row, col]
			var x = (col - (target_columns - 1) / 2.0) * target_spacing
			var y = target_height_offset + (row * target_spacing)
			var z = target_distance
			# Apply global SCENE_SCALE
			target.position = Vector3(x, y, z) * SCENE_SCALE
			target.scale = Vector3.ONE * SCENE_SCALE
			
			var distance_factor = float(row + 1) / float(max(target_rows, 1))
			target.points_value = 10 * (row + 1)
			var value_hue = distance_factor * 0.33
			target.target_color = Color.from_hsv(value_hue, 0.8, 1.0)
			target.target_hit.connect(_on_target_hit)
			targets_container.add_child(target)
			target_cubes.append(target)

func _spawn_drones() -> void:
	if not enable_drones or drone_scene == null:
		return
	if not drone_container:
		drone_container = Node3D.new()
		drone_container.name = "VectorDrones"
		add_child(drone_container)
	else:
		for child in drone_container.get_children():
			child.queue_free()

	drones_by_index.clear()
	drone_spawn_points.clear()
	var camera = get_node_or_null("Camera3D")
	var count = max(drone_count, 1)
	for i in range(count):
		var angle = TAU * float(i) / float(count)
		var spawn_pos = Vector3(sin(angle), 0.0, cos(angle)) * drone_spawn_radius
		spawn_pos.y = drone_spawn_height
		drone_spawn_points.append(spawn_pos * SCENE_SCALE) # Apply scale
	for i in range(drone_spawn_points.size()):
		_spawn_drone_at_index(i, camera)

func _spawn_drone_at_index(index: int, camera: Node3D = null) -> void:
	if not enable_drones or drone_scene == null:
		return
	if index < 0 or index >= drone_spawn_points.size():
		return
	if drones_by_index.has(index):
		return
	if not drone_container:
		return

	var drone = drone_scene.instantiate()
	drone.name = "VectorDrone_%d" % index
	drone.position = drone_spawn_points[index]
	drone.scale = Vector3.ONE * SCENE_SCALE # Apply scale
	
	if camera == null:
		camera = get_node_or_null("Camera3D")
	if camera:
		drone.player_path = camera.get_path()
	drone.base_color = drone_base_color
	drone.points_value = drone_points_value
	drone.set_meta("spawn_index", index)
	drone.player_hit.connect(_on_drone_player_hit)
	drone.drone_destroyed.connect(_on_drone_destroyed)
	drone_container.add_child(drone)
	drones_by_index[index] = drone

func _create_score_display() -> void:
	if not enable_scoring:
		return

	score_label = Label3D.new()
	score_label.name = "ScoreLabel"
	score_label.font_size = 48 * SCENE_SCALE
	score_label.outline_size = 8
	score_label.outline_modulate = Color.BLACK
	score_label.modulate = Color.YELLOW
	score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	score_label.position = Vector3(0, 2.5, 0) * SCENE_SCALE
	add_child(score_label)

func _create_instructions() -> void:
	if not show_instructions:
		return

	instructions_label = Label3D.new()
	instructions_label.name = "Instructions"
	instructions_label.font_size = 24 * SCENE_SCALE
	instructions_label.outline_size = 4
	instructions_label.outline_modulate = Color.BLACK
	instructions_label.modulate = Color(0.8, 0.9, 1.0)
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.position = Vector3(0, 2.0, -0.5) * SCENE_SCALE
	instructions_label.text = """VECTOR THROWING DEMO

1. Grab an orange ball with VR controller
2. Move your hand to build velocity
3. Release to throw!

Watch the vectors:
  - CYAN = Velocity (your throw)
  - RED = Gravity (constant down)

New threat:
  - A tetrahedron drone hunts you

Blast the drone and hit targets to score!"""
	add_child(instructions_label)

func _create_physics_info_panel() -> void:
	info_panel = create_info_panel("", Vector3(2.0, 1.5, 0)) # Base class handles pos scale
	if info_panel:
		info_panel.modulate = Color(0.7, 1.0, 0.7)
		_update_physics_info()

func _update_physics_info() -> void:
	if not info_panel:
		return

	var info_text = """PHYSICS CONCEPTS:

Velocity = delta_position / delta_time
v = (p2 - p1) / delta_t

Gravity = 9.8 m/s^2 (downward)
F = m * a

Projectile Motion:
- Horizontal: constant velocity
- Vertical: constant acceleration

Total throws: %d
Target hits: %d
Drones destroyed: %d
Drone hits taken: %d""" % [throws_count, total_hits, drones_destroyed, player_hits_taken]

	info_panel.text = info_text

func _on_ball_thrown(_pickable: Node3D, ball: Node3D) -> void:
	throws_count += 1
	_update_physics_info()
	if ball.has_method("get_throw_speed"):
		var speed = ball.get_throw_speed()
		print("Ball thrown at %.2f m/s" % speed)

func _on_target_hit(target: Node3D, impact_velocity: Vector3) -> void:
	total_hits += 1
	if enable_scoring:
		var points = target.get_points_value() if target.has_method("get_points_value") else 10
		total_score += points
		_update_score_display()
	_update_physics_info()
	var speed = impact_velocity.length()
	print("Target hit! Impact: %.2f m/s, Points: %d" % [speed, target.get_points_value() if target.has_method("get_points_value") else 10])

func _on_drone_player_hit(_drone: Node3D) -> void:
	player_hits_taken += 1
	print("Drone hit the player! Total hits taken: %d. Health: %.1f" % [player_hits_taken, GameManager.get_health()])
	_update_physics_info()


func _on_drone_destroyed(drone: Node3D, points_awarded: int) -> void:
	drones_destroyed += 1
	if enable_scoring:
		total_score += points_awarded
		_update_score_display()
	var spawn_index := -1
	if drone.has_meta("spawn_index"):
		spawn_index = int(drone.get_meta("spawn_index"))
	if spawn_index != -1:
		drones_by_index.erase(spawn_index)
		_schedule_drone_respawn(spawn_index)
	print("Drone destroyed! Points: %d (total drones down: %d)" % [points_awarded, drones_destroyed])
	_update_physics_info()

func _schedule_drone_respawn(spawn_index: int) -> void:
	if drone_respawn_time <= 0.0:
		return
	await get_tree().create_timer(drone_respawn_time).timeout
	if not enable_drones:
		return
	if drones_by_index.has(spawn_index):
		return
	_spawn_drone_at_index(spawn_index)
	_update_physics_info()

func _update_score_display() -> void:
	if not score_label:
		return
	score_label.text = "SCORE: %d" % total_score

func _process(_delta: float) -> void:
	_update_trajectory()
	
	# We don't need constant text updates as they are event-driven in this scene
	pass

func _update_trajectory() -> void:
	if not _trajectory_mesh:
		return
		
	_trajectory_mesh.clear_surfaces()
	
	# Find held ball
	var held_ball: Node3D = null
	for ball in throw_balls:
		if is_instance_valid(ball) and ball.get("is_being_held") == true:
			held_ball = ball
			break
			
	if not held_ball:
		return

	# Calculate path: p(t) = p0 + v0*t + 0.5*g*t^2
	var p0 = held_ball.global_position
	var v0 = Vector3.ZERO
	
	if held_ball.has_method("get_current_velocity"):
		var raw_vel = held_ball.get_current_velocity()
		var mult = held_ball.velocity_multiplier if "velocity_multiplier" in held_ball else 1.2
		v0 = raw_vel * mult
	
	# If velocity is too low, don't draw to avoid clutter
	if v0.length_squared() < 0.1:
		return

	var g = Vector3(0, -9.8, 0)
	if "enable_gravity_on_throw" in held_ball and not held_ball.enable_gravity_on_throw:
		g = Vector3.ZERO
	
	_trajectory_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var steps = 40
	var time_step = 0.05 # 2.0 seconds prediction
	
	for i in range(steps):
		var t = i * time_step
		var pos = p0 + v0 * t + 0.5 * g * t * t
		
		# Stop if we hit floor (approximate at y=0)
		if pos.y < 0.0:
			_trajectory_mesh.surface_add_vertex(pos)
			break
			
		_trajectory_mesh.surface_add_vertex(pos)
		
	_trajectory_mesh.surface_end()

func reset_game() -> void:
	total_score = 0
	total_hits = 0
	throws_count = 0
	drones_destroyed = 0
	player_hits_taken = 0

	for target in target_cubes:
		if target and target.has_method("reset"):
			target.reset()

	for i in range(throw_balls.size()):
		var ball = throw_balls[i]
		if ball:
			var x_offset = (i - (num_balls - 1) / 2.0) * ball_spawn_spacing
			ball.global_position = Vector3(x_offset, ball_spawn_height, 0.5)
			if ball is RigidBody3D:
				ball.linear_velocity = Vector3.ZERO
				ball.angular_velocity = Vector3.ZERO

	if drone_container:
		for child in drone_container.get_children():
			child.queue_free()
	drones_by_index.clear()
	_spawn_drones()

	_update_score_display()
	_update_physics_info()

func get_total_score() -> int:
	return total_score

func get_hit_accuracy() -> float:
	if throws_count == 0:
		return 0.0
	return (float(total_hits) / float(throws_count)) * 100.0
