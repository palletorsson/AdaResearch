# ===========================================================================
# Wind Soccer VR - Interactive Game Expansion of Example 2.1: Forces
# This expands on basic wind/gravity forces with VR gameplay
#
# @identity
# essence: A soccer game where wind zones and gravity are continuous forces the players steer the ball through to score
# desire: To make an invisible force playable — push the ball with gusts of wind, fight gravity, aim for the opponent's goal
# critical_parameter: wind impulse strength — the force magnitude each player injects to redirect the ball in mid-flight
# triggers: A timed gust curves the ball toward goal; gravity constantly pulls it down; opposing winds become a tug-of-war
# emerges: Forces as competition — the abstract "apply a force each frame" of example 2.1 becomes a contest of pushes
# needs: wind force zones [has], continuous gravity [has], goal detection [has], VR wind impulse control [has]
# relationships: game expansion of example_2_1 forces; sibling game to force_bowling_vr and friction_racer_vr
# truth: No one touches the ball — they only touch the air, and the air touches the ball.
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const FORCES_UI := preload("res://algorithms/forces/forces_ui.gd")

# Game constants
const GOAL_SCORE_POINTS := 10
const MAX_GAME_TIME := 120.0
const BALL_RESET_Y := -0.5
const WIND_IMPULSE_STRENGTH := 0.8

# Physics
var gravity: Vector3 = Vector3(0, -0.6, 0)
var left_wind: Vector3 = Vector3.ZERO
var right_wind: Vector3 = Vector3.ZERO

# Game objects
var ball: Mover
var left_goal: Area3D
var right_goal: Area3D
var wind_zones: Array[Area3D] = []

# VR interaction
var left_controller_active: bool = false
var right_controller_active: bool = false
var left_controller: XRController3D
var right_controller: XRController3D

# Game state
var score_left: int = 0
var score_right: int = 0
var game_time: float = 0.0
var game_active: bool = true

# UI
var info_label: Label3D
var score_label: Label3D
var timer_label: Label3D
var instructions_label: Label3D
var wind_strength_controller: ParameterController3D

# Settings
var wind_strength: float = 0.5
var show_wind_zones: bool = true

func _ready() -> void:
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	create_field()
	create_goals()
	create_wind_zones()
	create_ball()
	create_ui()
	setup_vr_controllers()

	print("Wind Soccer VR - Use controller triggers to push ball with wind!")

func _process(delta: float) -> void:
	if game_active:
		game_time += delta
		if game_time >= MAX_GAME_TIME:
			end_game()

	update_ui()
	update_vr_input()

func _physics_process(_delta: float):
	if not ball or not game_active:
		return

	# Apply gravity
	ball.apply_force(gravity * ball.mass)

	# Apply wind forces from controllers
	if left_controller_active:
		ball.apply_force(left_wind * wind_strength)

	if right_controller_active:
		ball.apply_force(right_wind * wind_strength)

	# Check if ball fell off
	if ball.position_v.y < BALL_RESET_Y:
		reset_ball()

func setup_vr_controllers() -> void:
	# Try to find XR controllers in the scene
	left_controller = get_node_or_null("/root/Main/XROrigin3D/LeftController")
	right_controller = get_node_or_null("/root/Main/XROrigin3D/RightController")

	if left_controller:
		left_controller.button_pressed.connect(_on_left_button_pressed)
		left_controller.button_released.connect(_on_left_button_released)

	if right_controller:
		right_controller.button_pressed.connect(_on_right_button_pressed)
		right_controller.button_released.connect(_on_right_button_released)

func update_vr_input() -> void:
	# Update wind direction based on controller pointing
	if left_controller_active and left_controller:
		var forward = -left_controller.global_transform.basis.z
		left_wind = forward.normalized() * 1.2

	if right_controller_active and right_controller:
		var forward = -right_controller.global_transform.basis.z
		right_wind = forward.normalized() * 1.2

func _on_left_button_pressed(button: String) -> void:
	if button == "trigger":
		left_controller_active = true
		create_wind_visual_effect(left_controller.global_position if left_controller else Vector3.ZERO, Color.CYAN)

func _on_left_button_released(button: String) -> void:
	if button == "trigger":
		left_controller_active = false

func _on_right_button_pressed(button: String) -> void:
	if button == "trigger":
		right_controller_active = true
		create_wind_visual_effect(right_controller.global_position if right_controller else Vector3.ZERO, Color.ORANGE)

func _on_right_button_released(button: String) -> void:
	if button == "trigger":
		right_controller_active = false

func create_field() -> void:
	# Create floor
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(1.5, 2.0)

	var floor_instance := MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.rotation_degrees = Vector3(-90, 0, 0)
	floor_instance.position = Vector3(0, -0.35, 0)

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.2, 0.8, 0.3, 1.0)
	floor_mat.roughness = 0.8
	floor_instance.material_override = floor_mat
	add_child(floor_instance)

	# Create walls
	create_wall(Vector3(0.75, 0, 0), Vector3(0.02, 0.4, 2.0))  # Right wall
	create_wall(Vector3(-0.75, 0, 0), Vector3(0.02, 0.4, 2.0)) # Left wall

func create_wall(pos: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	wall.add_child(collider)
	wall.position = pos

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.8, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	wall.add_child(mesh_instance)

	add_child(wall)

func create_goals() -> void:
	# Left goal (blue)
	left_goal = create_goal_area(Vector3(0, 0, -0.9), Color.BLUE)
	left_goal.body_entered.connect(_on_left_goal_scored)

	# Right goal (red)
	right_goal = create_goal_area(Vector3(0, 0, 0.9), Color.RED)
	right_goal.body_entered.connect(_on_right_goal_scored)

func create_goal_area(pos: Vector3, color: Color) -> Area3D:
	var goal := Area3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 0.5, 0.15)
	collider.shape = box
	goal.add_child(collider)
	goal.position = pos

	# Visual representation
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.8, 0.5, 0.02)
	mesh_instance.mesh = box_mesh
	mesh_instance.position = Vector3(0, 0, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.3)
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	goal.add_child(mesh_instance)

	add_child(goal)
	return goal

func create_wind_zones() -> void:
	# Create visible wind zones for visual feedback
	var left_zone_pos := Vector3(-0.4, 0, 0)
	var right_zone_pos := Vector3(0.4, 0, 0)

	create_wind_zone_visual(left_zone_pos, Color.CYAN)
	create_wind_zone_visual(right_zone_pos, Color.ORANGE)

func create_wind_zone_visual(pos: Vector3, color: Color) -> void:
	var zone := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.height = 0.4
	cylinder.top_radius = 0.15
	cylinder.bottom_radius = 0.15
	zone.mesh = cylinder
	zone.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.15)
	mat.emission_enabled = true
	mat.emission = color * 0.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone.material_override = mat

	add_child(zone)

func create_ball() -> void:
	ball = Mover.new()
	ball.mass = 0.8
	ball.position_v = Vector3(0, 0.1, 0)
	ball.velocity = Vector3.ZERO
	ball.bounce_damping = 0.7
	add_child(ball)
	ball.set_size(0.06)
	ball.set_color(Color.WHITE)

func reset_ball() -> void:
	if ball:
		ball.position_v = Vector3(0, 0.1, 0)
		ball.velocity = Vector3.ZERO
		ball.acceleration = Vector3.ZERO

func _on_left_goal_scored(body: Node) -> void:
	if body == ball:
		score_left += GOAL_SCORE_POINTS
		reset_ball()
		create_score_effect(left_goal.position, Color.BLUE)

func _on_right_goal_scored(body: Node) -> void:
	if body == ball:
		score_right += GOAL_SCORE_POINTS
		reset_ball()
		create_score_effect(right_goal.position, Color.RED)

func create_score_effect(pos: Vector3, color: Color) -> void:
	# Create temporary visual effect
	var effect := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	effect.mesh = sphere
	effect.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	effect.material_override = mat

	add_child(effect)

	# Animate and remove
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector3(2, 2, 2), 0.5)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)

func create_wind_visual_effect(pos: Vector3, color: Color) -> void:
	# Particle-like effect for wind
	var particles := CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.position = pos

	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.1
	particles.direction = Vector3(0, 0, 1)
	particles.spread = 15.0
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.0
	particles.scale_amount_min = 0.02
	particles.scale_amount_max = 0.04
	particles.color = color

	add_child(particles)

	# Auto-remove after lifetime
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func create_ui() -> void:
	info_label = Label3D.new()
	FORCES_UI.style_title_label(info_label, Vector3(0, 0.8, 0), 32)
	add_child(info_label)

	score_label = Label3D.new()
	FORCES_UI.style_value_label(score_label, Vector3(0, 0.65, 0), Color.YELLOW, 48)
	score_label.outline_size = 5
	add_child(score_label)

	timer_label = Label3D.new()
	FORCES_UI.style_value_label(timer_label, Vector3(0, 0.5, 0), Color.CYAN, 24)
	add_child(timer_label)

	instructions_label = Label3D.new()
	FORCES_UI.style_instruction_label(instructions_label, Vector3(0, 0.35, 0), 18)
	FORCES_UI.set_label_text(instructions_label, "[TRIGGER] Blow Wind | [R] Reset Game")
	add_child(instructions_label)

	# Wind strength controller
	wind_strength_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	wind_strength_controller.parameter_name = "Wind Power"
	wind_strength_controller.min_value = 0.2
	wind_strength_controller.max_value = 1.5
	wind_strength_controller.default_value = wind_strength
	wind_strength_controller.step_size = 0.05
	wind_strength_controller.position = Vector3(0.5, 0.4, 0.8)
	wind_strength_controller.rotation_degrees = Vector3(0, -20, 0)
	add_child(wind_strength_controller)
	wind_strength_controller.value_changed.connect(_on_wind_strength_changed)
	wind_strength_controller.set_value(wind_strength)

func update_ui() -> void:
	if info_label:
		FORCES_UI.set_label_text(info_label, "WIND SOCCER VR")

	if score_label:
		FORCES_UI.set_label_text(score_label, "Blue %d - %d Red" % [score_left, score_right])

	if timer_label:
		var time_left := MAX_GAME_TIME - game_time
		FORCES_UI.set_label_text(timer_label, "Time: %d:%02d" % [int(time_left) / 60, int(time_left) % 60])

func _on_wind_strength_changed(value: float) -> void:
	wind_strength = value

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_game()
			KEY_SPACE:
				# Keyboard fallback for testing
				if ball:
					ball.apply_force(Vector3(0, 0, 1.0))

func reset_game() -> void:
	score_left = 0
	score_right = 0
	game_time = 0.0
	game_active = true
	reset_ball()

func end_game() -> void:
	game_active = false
	var winner := "Blue" if score_left > score_right else "Red"
	if score_left == score_right:
		winner = "TIE"

	if info_label:
		FORCES_UI.set_label_text(info_label, "GAME OVER! Winner: %s" % winner)

	# Auto-reset after 5 seconds
	await get_tree().create_timer(5.0).timeout
	reset_game()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
