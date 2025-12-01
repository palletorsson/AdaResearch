# ===========================================================================
# Hilbert3D Curve - L-System Space-Filling Curve
# Implementation: AI-assisted GDScript, 2025
#
# A 3D Hilbert curve demonstrating space-filling properties using L-Systems
# License: CC BY-NC-SA 3.0
# ===========================================================================

extends Node3D

## 3D Hilbert Curve - Space-Filling Curve Visualization
## Demonstrates how L-Systems can efficiently fill 3D space
## Chapter: L-Systems (Architecture & Space-Filling)

@export var generations: int = 2
@export var step_length: float = 0.2
@export var turn_angle: float = 90.0
@export var show_generation_animation: bool = false
@export var curve_thickness: float = 0.015

var lsystem
var turtle: Turtle3D

# Current generation being displayed
var current_generation: int = 0
var generation_timer: float = 0.0
var generation_speed: float = 2.0  # Seconds per generation

# UI
var info_label: Label3D
var description_label: Label3D
var generation_controller: ParameterController3D

func _ready():
	# Create turtle
	turtle = Turtle3D.new()
	turtle.use_pink_palette = false
	turtle.branch_thickness = curve_thickness
	# Set custom colors for space-filling curve
	turtle.set_colors(Color(0.3, 0.8, 1.0, 1.0), Color(0.6, 0.9, 1.0, 1.0))
	turtle.position = Vector3.ZERO
	add_child(turtle)

	# Create 3D Hilbert L-System
	var LSystemClass = load("res://utils/lsystem.gd")
	lsystem = LSystemClass.create_3d_hilbert()

	# Create UI
	create_info_labels()
	create_controllers()

	# Generate and draw
	if show_generation_animation:
		current_generation = 0
		# Start with at least 1 generation
		lsystem.generate()
		current_generation = 1
		draw_lsystem()
	else:
		lsystem.generate_n(generations)
		draw_lsystem()
		current_generation = generations

	update_info_label()
	print("Hilbert3D: 3D Space-Filling Curve - Generations: %d" % generations)

func _process(delta):
	if show_generation_animation and current_generation < generations:
		generation_timer += delta
		if generation_timer >= generation_speed:
			generation_timer = 0.0
			lsystem.generate()
			current_generation += 1
			draw_lsystem()
			update_info_label()

func create_info_labels():
	"""Create info labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(0.3, 0.9, 1.0)
	info_label.position = Vector3(0, 1.2, 0)
	add_child(info_label)

	description_label = Label3D.new()
	description_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	description_label.font_size = 20
	description_label.modulate = Color(0.7, 0.85, 1.0)
	description_label.position = Vector3(0, 1.0, 0)
	description_label.text = "3D Space-Filling Curve"
	description_label.width = 600.0
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description_label)

func create_controllers():
	"""Create 3D controllers"""
	generation_controller = ParameterController3D.new()
	generation_controller.parameter_name = "Generations"
	generation_controller.min_value = 1.0
	generation_controller.max_value = 4.0
	generation_controller.default_value = float(generations)
	generation_controller.step_size = 1.0
	generation_controller.position = Vector3(0, -1.0, 0)
	generation_controller.value_changed.connect(_on_generation_changed)
	add_child(generation_controller)

func _on_generation_changed(new_gen: float):
	"""Update generation count and redraw"""
	generations = int(new_gen)
	reset()
	lsystem.generate_n(generations)
	current_generation = generations
	draw_lsystem()
	update_info_label()

func update_info_label():
	"""Update info labels"""
	if info_label:
		var instruction_length = lsystem.get_sentence().length()
		var path_segments = count_forward_moves(lsystem.get_sentence())
		info_label.text = "3D Hilbert Curve\nGeneration: %d\nPath Segments: %d" % [current_generation, path_segments]

func count_forward_moves(instructions: String) -> int:
	"""Count forward movement commands in L-System string"""
	var count = 0
	for char in instructions:
		if char == "F" or char == "G":
			count += 1
	return count

func draw_lsystem():
	"""Draw the L-System using turtle graphics"""
	if turtle:
		var instructions = lsystem.get_sentence()
		turtle.interpret_lsystem(instructions, step_length, turn_angle)

func increase_generations():
	"""Increase generation count"""
	if generations < 4:  # Limit to prevent excessive complexity
		generations += 1
		reset()
		lsystem.generate_n(current_generation)
		draw_lsystem()
		if generation_controller:
			generation_controller.set_value(float(generations))
		print("Generations increased to: %d" % generations)

func decrease_generations():
	"""Decrease generation count"""
	if generations > 1:
		generations -= 1
		if current_generation > generations:
			current_generation = generations
		reset()
		lsystem.generate_n(current_generation)
		draw_lsystem()
		if generation_controller:
			generation_controller.set_value(float(generations))
		print("Generations decreased to: %d" % generations)

func reset():
	"""Reset L-System and turtle"""
	current_generation = 0
	generation_timer = 0.0
	lsystem.reset()
	if turtle:
		turtle.reset()
	update_info_label()

func toggle_animation():
	"""Toggle generation animation"""
	show_generation_animation = !show_generation_animation
	if not show_generation_animation:
		# Show final generation immediately
		reset()
		lsystem.generate_n(generations)
		current_generation = generations
		draw_lsystem()
		update_info_label()
