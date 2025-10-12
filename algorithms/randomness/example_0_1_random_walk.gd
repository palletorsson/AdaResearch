# ===========================================================================
# NOC Example 0.1: Random Walk
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

var fish_tank: FishTank
var walker: Walker3D

var steps_per_second: float = 12.0
var step_accumulator: float = 0.0

var info_label: Label3D
var instructions_label: Label3D
var step_controller: ParameterController3D
var speed_controller: ParameterController3D

func _ready() -> void:
	ensure_fish_tank()
	create_ui()
	spawn_walker()
	print("Example 0.1: Random walk - traditional")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(walker):
		return

	step_accumulator += delta
	var step_interval: float = 1.0 / max(steps_per_second, 0.1)

	# Limit iterations to prevent hanging if delta becomes very large
	var max_iterations: int = 100
	var iterations: int = 0

	while step_accumulator >= step_interval and iterations < max_iterations:
		walker.step_random()
		step_accumulator -= step_interval
		iterations += 1

	# If we hit the max iterations, reset accumulator to prevent buildup
	if iterations >= max_iterations:
		step_accumulator = 0.0

func _process(_delta: float) -> void:
	update_info_label()
	update_labels()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_walk()
			KEY_T:
				toggle_trail_visibility()

func ensure_fish_tank() -> void:
	fish_tank = get_node("../FishTank") if has_node("../FishTank") else null
	if not fish_tank:
		fish_tank = FishTank.new()
		fish_tank.tank_size = 1.0
		fish_tank.wall_color = Color(1.0, 0.7, 0.9, 0.15)
		get_parent().add_child(fish_tank)

func spawn_walker() -> void:
	if is_instance_valid(walker):
		walker.queue_free()

	walker = Walker3D.new()
	walker.step_size = 0.05
	walker.max_trail_points = 400
	walker.plane_height = -0.45
	walker.trail_width = 0.012
	add_child(walker)

func create_ui() -> void:
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 26
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.68, -0.25)
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 18
	instructions_label.modulate = Color(0.8, 1.0, 0.9)
	instructions_label.position = Vector3(0, 0.58, -0.25)
	instructions_label.text = "[R] Reset walk  |  [T] Toggle trail"
	add_child(instructions_label)

	step_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	step_controller.parameter_name = "Step size"
	step_controller.min_value = 0.01
	step_controller.max_value = 0.18
	step_controller.default_value = 0.05
	step_controller.step_size = 0.005
	step_controller.position = Vector3(-0.45, 0.48, 0.2)
	step_controller.rotation_degrees = Vector3(0, 25, 0)
	add_child(step_controller)
	step_controller.value_changed.connect(_on_step_size_changed)
	step_controller.set_value(0.05)

	speed_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Steps/sec"
	speed_controller.min_value = 1.0
	speed_controller.max_value = 25.0
	speed_controller.default_value = steps_per_second
	speed_controller.step_size = 0.5
	speed_controller.position = Vector3(0.45, 0.48, 0.2)
	speed_controller.rotation_degrees = Vector3(0, -25, 0)
	add_child(speed_controller)
	speed_controller.value_changed.connect(_on_speed_changed)
	speed_controller.set_value(steps_per_second)

func update_info_label() -> void:
	if info_label and is_instance_valid(walker):
		info_label.text = "Example 0.1: Random walk\nStep %.3f  |  %.1f steps/s" % [walker.step_size, steps_per_second]

func reset_walk() -> void:
	if is_instance_valid(walker):
		walker.reset_path(Vector3.ZERO)
	step_accumulator = 0.0

func toggle_trail_visibility() -> void:
	if is_instance_valid(walker):
		walker.set_trail_visible(not walker.is_trail_visible())

func update_labels() -> void:
	if not instructions_label:
		return
	if is_instance_valid(walker) and not walker.is_trail_visible():
		instructions_label.text = "[R] Reset walk  |  [T] Show trail"
	else:
		instructions_label.text = "[R] Reset walk  |  [T] Toggle trail"

func _on_step_size_changed(value: float) -> void:
	if is_instance_valid(walker):
		walker.set_step_size(value)

func _on_speed_changed(value: float) -> void:
	steps_per_second = clamp(value, 1.0, 25.0)
