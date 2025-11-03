# VectorThrowing.gd
# Main scene for demonstrating projectile motion with velocity and gravity vectors
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

@export_group("Scoring")
@export var enable_scoring: bool = true
@export var show_instructions: bool = true

# Scene references
var throw_balls: Array[Node3D] = []
var target_cubes: Array[Node3D] = []
var score_label: Label3D = null
var instructions_label: Label3D = null
var info_panel: Label3D = null

# Game state
var total_score: int = 0
var total_hits: int = 0
var throws_count: int = 0

# Preloaded scenes
var throw_ball_scene = preload("res://algorithms/vectors/08_vector_throwing/throw_ball.tscn")
var hit_target_scene = preload("res://algorithms/vectors/08_vector_throwing/hit_target_cube.tscn")

func _ready() -> void:
	super._ready()
	_setup_environment()
	_spawn_throw_balls()
	_spawn_target_grid()
	_create_score_display()
	_create_instructions()
	_create_physics_info_panel()
	_update_score_display()

func _setup_environment() -> void:
	"""Create the throwing environment"""
	# Create axes for reference
	create_axes(2.0)

	# Create floor
	create_floor(10.0, Color(0.2, 0.3, 0.4, 0.5))

	# Create origin marker
	_create_origin_marker()

func _spawn_throw_balls() -> void:
	"""Spawn throwable balls at starting positions"""
	var balls_container = Node3D.new()
	balls_container.name = "ThrowBalls"
	add_child(balls_container)

	for i in range(num_balls):
		var ball = throw_ball_scene.instantiate()
		ball.name = "ThrowBall_%d" % i

		# Position balls in a row at chest height
		var x_offset = (i - (num_balls - 1) / 2.0) * ball_spawn_spacing
		ball.position = Vector3(x_offset, ball_spawn_height, 0.5)

		# Vary ball colors
		var hue = float(i) / float(num_balls)
		var color = Color.from_hsv(hue, 0.8, 1.0)
		if ball.has_method("set_ball_color"):
			ball.set_ball_color(color)
		else:
			ball.ball_color = color

		# Connect signals
		ball.dropped.connect(_on_ball_thrown.bind(ball))

		balls_container.add_child(ball)
		throw_balls.append(ball)

func _spawn_target_grid() -> void:
	"""Spawn grid of target cubes"""
	var targets_container = Node3D.new()
	targets_container.name = "TargetCubes"
	add_child(targets_container)

	for row in range(target_rows):
		for col in range(target_columns):
			var target = hit_target_scene.instantiate()
			target.name = "Target_%d_%d" % [row, col]

			# Calculate position (grid in front of player)
			var x = (col - (target_columns - 1) / 2.0) * target_spacing
			var y = target_height_offset + (row * target_spacing)
			var z = target_distance

			target.position = Vector3(x, y, z)

			# Vary target properties
			var distance_factor = float(row + 1) / float(target_rows)
			target.points_value = 10 * (row + 1)  # Higher rows = more points

			# Color based on value
			var value_hue = 0.0 + (distance_factor * 0.33)  # Red to yellow range
			target.target_color = Color.from_hsv(value_hue, 0.8, 1.0)

			# Connect signals
			target.target_hit.connect(_on_target_hit)

			targets_container.add_child(target)
			target_cubes.append(target)

func _create_score_display() -> void:
	"""Create floating score display"""
	if not enable_scoring:
		return

	score_label = Label3D.new()
	score_label.name = "ScoreLabel"
	score_label.font_size = 48
	score_label.outline_size = 8
	score_label.outline_modulate = Color.BLACK
	score_label.modulate = Color.YELLOW
	score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	score_label.position = Vector3(0, 2.5, 0)
	add_child(score_label)

func _create_instructions() -> void:
	"""Create instruction panel"""
	if not show_instructions:
		return

	instructions_label = Label3D.new()
	instructions_label.name = "Instructions"
	instructions_label.font_size = 24
	instructions_label.outline_size = 4
	instructions_label.outline_modulate = Color.BLACK
	instructions_label.modulate = Color(0.8, 0.9, 1.0)
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.position = Vector3(0, 2.0, 0)

	instructions_label.text = """VECTOR THROWING DEMO

1. Grab an orange ball with VR controller
2. Move your hand to build velocity
3. Release to throw!

Watch the vectors:
  • CYAN = Velocity (your throw)
  • RED = Gravity (constant down)

Hit targets to score points!"""

	add_child(instructions_label)

func _create_physics_info_panel() -> void:
	"""Create panel showing physics equations"""
	info_panel = create_info_panel("", Vector3(2.0, 1.5, 0))
	if info_panel:
		info_panel.modulate = Color(0.7, 1.0, 0.7)
		_update_physics_info()

func _update_physics_info() -> void:
	"""Update physics information panel"""
	if not info_panel:
		return

	var info_text = """PHYSICS CONCEPTS:

Velocity = Δposition / Δtime
v = (p₁ - p₀) / Δt

Gravity = 9.8 m/s² (downward)
F = ma

Projectile Motion:
• Horizontal: constant velocity
• Vertical: constant acceleration

Total throws: %d
Total hits: %d""" % [throws_count, total_hits]

	info_panel.text = info_text

func _on_ball_thrown(_pickable: Node3D, ball: Node3D) -> void:
	"""Called when a ball is thrown"""
	throws_count += 1
	_update_physics_info()

	# Show throw velocity in console
	if ball.has_method("get_throw_speed"):
		var speed = ball.get_throw_speed()
		print("Ball thrown at %.2f m/s" % speed)

func _on_target_hit(target: Node3D, impact_velocity: Vector3) -> void:
	"""Called when a target is hit"""
	total_hits += 1

	if enable_scoring:
		var points = target.get_points_value() if target.has_method("get_points_value") else 10
		total_score += points
		_update_score_display()

	_update_physics_info()

	# Show hit info
	var speed = impact_velocity.length()
	print("Target hit! Impact: %.2f m/s, Points: %d" % [speed, target.get_points_value() if target.has_method("get_points_value") else 10])

func _update_score_display() -> void:
	"""Update score label"""
	if not score_label:
		return

	score_label.text = "SCORE: %d" % total_score

func _process(_delta: float) -> void:
	"""Update any dynamic information"""
	# Could show real-time ball velocities here
	pass

func reset_game() -> void:
	"""Reset the game state"""
	total_score = 0
	total_hits = 0
	throws_count = 0

	# Reset all targets
	for target in target_cubes:
		if target and target.has_method("reset"):
			target.reset()

	# Reset balls to starting positions
	for i in range(throw_balls.size()):
		var ball = throw_balls[i]
		if ball:
			var x_offset = (i - (num_balls - 1) / 2.0) * ball_spawn_spacing
			ball.global_position = Vector3(x_offset, ball_spawn_height, 0.5)
			if ball is RigidBody3D:
				ball.linear_velocity = Vector3.ZERO
				ball.angular_velocity = Vector3.ZERO

	_update_score_display()
	_update_physics_info()

func get_total_score() -> int:
	"""Return current total score"""
	return total_score

func get_hit_accuracy() -> float:
	"""Calculate hit accuracy percentage"""
	if throws_count == 0:
		return 0.0
	return (float(total_hits) / float(throws_count)) * 100.0
