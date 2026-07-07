# ===========================================================================
# Force Bowling VR - Interactive Game Expansion of Example 2.2: Mass Variation
# Demonstrates how different masses respond to forces - bowling pin physics!
#
# @identity
# essence: A bowling game where pins of different mass respond differently to the same impact, making F=ma playable
# desire: To let the player feel mass through collision — heavy pins barely budge while light ones scatter, all from one identical throw
# critical_parameter: per-object mass — the value that distinguishes ball from pins, and pins from each other, in every momentum exchange
# triggers: A heavier ball clears more pins; lighter pins fly farther on contact; lane friction decides how far the ball carries
# emerges: Newton's second law as score — the abstract F=ma becomes a satisfying or frustrating spread of fallen pins
# needs: mass-varied movers [has], collision momentum transfer [has], lane friction [has], VR ball grab and throw [has]
# relationships: game expansion of example_2_2 mass_variation; shares the Mover physics body with all NOC Ch.2 forces artifacts
# truth: Same throw, different mass, different outcome — the law you cannot see, written on the floor in fallen pins.
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const FORCES_UI := preload("res://algorithms/forces/forces_ui.gd")

# Game constants
const PIN_COUNT := 10
const BALL_START_POS := Vector3(0, 0.1, -0.8)
const PIN_AREA_START_Z := 0.5
const POINTS_PER_PIN := 10
const MAX_THROWS := 10

# Physics
var gravity: Vector3 = Vector3(0, -0.9, 0)
var floor_friction: float = 0.15

# Game objects
var bowling_ball: Mover
var pins: Array[Mover] = []
var fallen_pins: int = 0

# VR interaction
var ball_grabbed: bool = false
var release_velocity: Vector3 = Vector3.ZERO
var last_ball_position: Vector3 = Vector3.ZERO

# Game state
var total_score: int = 0
var current_throw: int = 0
var is_throwing: bool = false
var pins_knocked: int = 0

# UI
var info_label: Label3D
var score_label: Label3D
var instructions_label: Label3D
var ball_mass_controller: ParameterController3D
var throw_power_controller: ParameterController3D

# Settings
var ball_mass: float = 2.5
var throw_power_multiplier: float = 1.0

func _ready() -> void:
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	create_bowling_lane()
	create_pins()
	create_bowling_ball()
	create_ui()

	print("Force Bowling VR - Knock down pins with physics!")

func _process(_delta: float):
	update_ui()
	check_throw_complete()

func _physics_process(_delta: float):
	# Apply physics to all objects
	apply_physics_to_ball()
	apply_physics_to_pins()

	# Track ball velocity for throw detection
	if bowling_ball and not ball_grabbed:
		update_throw_state()

func create_bowling_lane() -> void:
	# Create bowling lane floor
	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(0.6, 0.02, 2.0)

	var lane_instance := MeshInstance3D.new()
	lane_instance.mesh = lane_mesh
	lane_instance.position = Vector3(0, -0.36, 0)

	var lane_mat := StandardMaterial3D.new()
	lane_mat.albedo_color = Color(0.9, 0.85, 0.7, 1.0)
	lane_mat.roughness = 0.2
	lane_mat.metallic = 0.1
	lane_instance.material_override = lane_mat
	add_child(lane_instance)

	# Lane markers
	for z in range(-8, 9, 2):
		create_lane_marker(Vector3(0, -0.34, z * 0.1))

	# Gutters
	create_gutter(Vector3(0.35, -0.25, 0))
	create_gutter(Vector3(-0.35, -0.25, 0))

func create_lane_marker(pos: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.height = 0.01
	cylinder.top_radius = 0.015
	cylinder.bottom_radius = 0.015
	marker.mesh = cylinder
	marker.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.4, 1.0)
	marker.material_override = mat
	add_child(marker)

func create_gutter(pos: Vector3) -> void:
	var gutter := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1, 0.2, 2.0)
	collider.shape = box
	gutter.add_child(collider)
	gutter.position = pos

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(0.1, 0.2, 2.0)
	mesh_instance.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.2, 1.0)
	mat.roughness = 0.8
	mesh_instance.material_override = mat
	gutter.add_child(mesh_instance)

	add_child(gutter)

func create_pins() -> void:
	# Create bowling pins in traditional 10-pin arrangement
	var pin_positions := [
		Vector3(0, 0, PIN_AREA_START_Z),  # Front pin
		Vector3(-0.08, 0, PIN_AREA_START_Z + 0.14),  # Row 2
		Vector3(0.08, 0, PIN_AREA_START_Z + 0.14),
		Vector3(-0.16, 0, PIN_AREA_START_Z + 0.28),  # Row 3
		Vector3(0, 0, PIN_AREA_START_Z + 0.28),
		Vector3(0.16, 0, PIN_AREA_START_Z + 0.28),
		Vector3(-0.24, 0, PIN_AREA_START_Z + 0.42),  # Row 4
		Vector3(-0.08, 0, PIN_AREA_START_Z + 0.42),
		Vector3(0.08, 0, PIN_AREA_START_Z + 0.42),
		Vector3(0.24, 0, PIN_AREA_START_Z + 0.42),
	]

	for i in range(PIN_COUNT):
		var pin := create_pin(pin_positions[i], i)
		pins.append(pin)

func create_pin(pos: Vector3, index: int) -> Mover:
	var pin := Mover.new()
	pin.mass = 0.6 + (index % 3) * 0.2  # Varying masses
	pin.position_v = pos
	pin.velocity = Vector3.ZERO
	pin.bounce_damping = 0.4
	add_child(pin)

	# Pin shape (tall cylinder)
	pin.set_size(0.03)
	var color := Color(1.0, 1.0 - (index % 3) * 0.15, 0.9, 1.0)
	pin.set_color(color)

	# Make pins taller by scaling
	if pin.mesh_instance:
		pin.mesh_instance.scale = Vector3(1, 2.5, 1)

	return pin

func create_bowling_ball() -> void:
	bowling_ball = Mover.new()
	bowling_ball.mass = ball_mass
	bowling_ball.position_v = BALL_START_POS
	bowling_ball.velocity = Vector3.ZERO
	bowling_ball.bounce_damping = 0.6
	add_child(bowling_ball)
	bowling_ball.set_size(0.08)
	bowling_ball.set_color(Color(0.2, 0.2, 0.3, 1.0))

	last_ball_position = BALL_START_POS

func apply_physics_to_ball() -> void:
	if not bowling_ball or ball_grabbed:
		return

	# Gravity
	bowling_ball.apply_force(gravity * bowling_ball.mass)

	# Friction
	if bowling_ball.velocity.length() > 0.02:
		var friction_dir := -bowling_ball.velocity.normalized()
		var normal_force: float = abs(gravity.y) * bowling_ball.mass
		var friction_force: Vector3 = friction_dir * floor_friction * normal_force
		bowling_ball.apply_force(friction_force)

func apply_physics_to_pins() -> void:
	for pin in pins:
		if not is_instance_valid(pin):
			continue

		# Gravity
		pin.apply_force(gravity * pin.mass)

		# Friction
		if pin.velocity.length() > 0.02:
			var friction_dir := -pin.velocity.normalized()
			var normal_force: float = abs(gravity.y) * pin.mass
			var friction_force: Vector3 = friction_dir * floor_friction * normal_force
			pin.apply_force(friction_force)

		# Check if pin is knocked down
		if not pin.get_meta("knocked_down", false):
			# Check tilt or movement threshold
			if pin.velocity.length() > 0.3 or pin.position_v.y < -0.15:
				pin.set_meta("knocked_down", true)
				pins_knocked += 1
				create_pin_knock_effect(pin.position_v)

func update_throw_state() -> void:
	if not is_throwing and bowling_ball:
		# Check if ball is moving (throw initiated)
		if bowling_ball.velocity.length() > 0.5:
			is_throwing = true

func check_throw_complete() -> void:
	if not is_throwing or not bowling_ball:
		return

	# Check if throw is complete (ball stopped or out of bounds)
	var ball_stopped: bool = bowling_ball.velocity.length() < 0.1
	var ball_out_of_bounds: bool = abs(bowling_ball.position_v.x) > 0.5 or bowling_ball.position_v.z > 1.2

	if ball_stopped or ball_out_of_bounds:
		complete_throw()

func complete_throw() -> void:
	is_throwing = false
	current_throw += 1

	# Calculate score
	var points := pins_knocked * POINTS_PER_PIN
	total_score += points

	# Wait a moment then reset
	await get_tree().create_timer(2.0).timeout
	reset_for_next_throw()

func reset_for_next_throw() -> void:
	pins_knocked = 0

	# Remove and recreate pins
	for pin in pins:
		if is_instance_valid(pin):
			pin.queue_free()
	pins.clear()

	create_pins()

	# Reset ball
	if bowling_ball:
		bowling_ball.position_v = BALL_START_POS
		bowling_ball.velocity = Vector3.ZERO
		bowling_ball.acceleration = Vector3.ZERO

	if current_throw >= MAX_THROWS:
		end_game()

func create_pin_knock_effect(pos: Vector3) -> void:
	var effect := CPUParticles3D.new()
	effect.emitting = true
	effect.one_shot = true
	effect.amount = 15
	effect.lifetime = 0.6
	effect.position = pos
	effect.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	effect.emission_sphere_radius = 0.08
	effect.gravity = gravity
	effect.initial_velocity_min = 0.3
	effect.initial_velocity_max = 0.6
	effect.scale_amount_min = 0.015
	effect.scale_amount_max = 0.03
	effect.color = Color.YELLOW

	add_child(effect)

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(effect):
		effect.queue_free()

func create_ui() -> void:
	info_label = Label3D.new()
	FORCES_UI.style_title_label(info_label, Vector3(0, 0.75, -0.5), 32)
	add_child(info_label)

	score_label = Label3D.new()
	FORCES_UI.style_value_label(score_label, Vector3(0, 0.6, -0.5), Color.YELLOW, 40)
	score_label.outline_size = 5
	add_child(score_label)

	instructions_label = Label3D.new()
	FORCES_UI.style_instruction_label(instructions_label, Vector3(0, 0.45, -0.5), 18)
	FORCES_UI.set_label_text(instructions_label, "[Grab Ball] Throw | [R] Reset")
	add_child(instructions_label)

	# Ball mass controller
	ball_mass_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	ball_mass_controller.parameter_name = "Ball Mass"
	ball_mass_controller.min_value = 1.0
	ball_mass_controller.max_value = 5.0
	ball_mass_controller.default_value = ball_mass
	ball_mass_controller.step_size = 0.2
	ball_mass_controller.position = Vector3(-0.45, 0.35, -0.4)
	ball_mass_controller.rotation_degrees = Vector3(0, 20, 0)
	add_child(ball_mass_controller)
	ball_mass_controller.value_changed.connect(_on_ball_mass_changed)
	ball_mass_controller.set_value(ball_mass)

	# Throw power controller
	throw_power_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	throw_power_controller.parameter_name = "Power"
	throw_power_controller.min_value = 0.5
	throw_power_controller.max_value = 2.0
	throw_power_controller.default_value = throw_power_multiplier
	throw_power_controller.step_size = 0.1
	throw_power_controller.position = Vector3(0.45, 0.35, -0.4)
	throw_power_controller.rotation_degrees = Vector3(0, -20, 0)
	add_child(throw_power_controller)
	throw_power_controller.value_changed.connect(_on_power_changed)
	throw_power_controller.set_value(throw_power_multiplier)

func update_ui() -> void:
	if info_label:
		FORCES_UI.set_label_text(info_label, "FORCE BOWLING VR")

	if score_label:
		FORCES_UI.set_label_text(score_label, "Score: %d | Throw: %d/%d" % [total_score, current_throw, MAX_THROWS])

func _on_ball_mass_changed(value: float) -> void:
	ball_mass = value
	if bowling_ball:
		bowling_ball.mass = ball_mass

func _on_power_changed(value: float) -> void:
	throw_power_multiplier = value

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_game()
			KEY_SPACE:
				# Keyboard throw for testing
				if bowling_ball and not is_throwing:
					bowling_ball.velocity = Vector3(0, 0, 2.5) * throw_power_multiplier
					is_throwing = true

func reset_game() -> void:
	total_score = 0
	current_throw = 0
	pins_knocked = 0
	is_throwing = false
	reset_for_next_throw()

func end_game() -> void:
	if info_label:
		FORCES_UI.set_label_text(info_label, "GAME OVER! Final Score: %d" % total_score)

	await get_tree().create_timer(5.0).timeout
	reset_game()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
