# ===========================================================================
# NOC Example 8.9: L-System Tree
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.9: L-System Tree
## Procedural plant generation using L-Systems and 3D Turtle graphics
## Chapter 08: Fractals

@export var generations: int = 4
@export var step_length: float = 0.08
@export var turn_angle: float = 25.0
@export var show_generation_animation: bool = true

var lsystem: LSystem
var turtle: Turtle3D

# Current generation being displayed
var current_generation: int = 0
var generation_timer: float = 0.0
var generation_speed: float = 1.5  # Seconds per generation

# Available L-System presets
enum PresetType { PLANT, TREE, BUSH, FRACTAL_PLANT, ALGAE }
@export var preset: PresetType = PresetType.PLANT

# UI
var info_label: Label3D
var preset_label: Label3D
var angle_controller: ParameterController3D
var length_controller: ParameterController3D

func _ready():
	# Create turtle
	turtle = Turtle3D.new()
	turtle.use_pink_palette = true
	turtle.position = Vector3(0, -0.4, 0)  # Start at bottom
	add_child(turtle)

	# Create L-System based on preset
	create_lsystem_preset()

	# Create UI
	create_info_labels()
	create_controllers()

	# Generate and draw
	if show_generation_animation:
		current_generation = 0
	else:
		lsystem.generate_n(generations)
		draw_lsystem()
		current_generation = generations

	update_info_label()
	print("Example 8.9: L-System Tree - Preset: %s, Generations: %d" % [get_preset_name(), generations])

func _process(delta):
	if show_generation_animation and current_generation < generations:
		generation_timer += delta
		if generation_timer >= generation_speed:
			generation_timer = 0.0
			lsystem.generate()
			current_generation += 1
			draw_lsystem()
			update_info_label()

func create_lsystem_preset():
	"""Create L-System based on selected preset"""
	match preset:
		PresetType.PLANT:
			lsystem = LSystem.create_plant()
			step_length = 0.05
			turn_angle = 25.0
		PresetType.TREE:
			lsystem = LSystem.create_tree()
			step_length = 0.06
			turn_angle = 22.5
		PresetType.BUSH:
			lsystem = LSystem.create_bush()
			step_length = 0.08
			turn_angle = 25.7
		PresetType.FRACTAL_PLANT:
			lsystem = LSystem.create_fractal_plant()
			step_length = 0.04
			turn_angle = 25.0
		PresetType.ALGAE:
			lsystem = LSystem.create_algae()
			step_length = 0.1
			turn_angle = 90.0

func get_preset_name() -> String:
	match preset:
		PresetType.PLANT: return "Simple Plant"
		PresetType.TREE: return "Binary Tree"
		PresetType.BUSH: return "Bush"
		PresetType.FRACTAL_PLANT: return "Fractal Plant"
		PresetType.ALGAE: return "Algae"
	return "Unknown"

func create_info_labels():
	"""Create info labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.7, 0)
	add_child(info_label)

	preset_label = Label3D.new()
	preset_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	preset_label.font_size = 24
	preset_label.modulate = Color(0.8, 1.0, 0.8)
	preset_label.position = Vector3(0, 0.6, 0)
	preset_label.text = "L-System: %s" % get_preset_name()
	add_child(preset_label)

func create_controllers():
	"""Create 3D controllers"""
	angle_controller = ParameterController3D.new()
	angle_controller.parameter_name = "Angle"
	angle_controller.min_value = 10.0
	angle_controller.max_value = 45.0
	angle_controller.default_value = turn_angle
	angle_controller.step_size = 1.0
	angle_controller.position = Vector3(-0.3, -0.6, 0)
	angle_controller.value_changed.connect(_on_angle_changed)
	add_child(angle_controller)

	length_controller = ParameterController3D.new()
	length_controller.parameter_name = "Length"
	length_controller.min_value = 0.02
	length_controller.max_value = 0.15
	length_controller.default_value = step_length
	length_controller.step_size = 0.01
	length_controller.position = Vector3(0.3, -0.6, 0)
	length_controller.value_changed.connect(_on_length_changed)
	add_child(length_controller)

func _on_angle_changed(new_angle: float):
	"""Update turn angle and redraw"""
	turn_angle = new_angle
	draw_lsystem()

func _on_length_changed(new_length: float):
	"""Update step length and redraw"""
	step_length = new_length
	draw_lsystem()

func update_info_label():
	"""Update info labels"""
	if info_label:
		var instruction_length = lsystem.get_sentence().length()
		info_label.text = "L-System Tree\nGeneration: %d / %d\nInstructions: %d" % [current_generation, generations, instruction_length]

func draw_lsystem():
	"""Draw the L-System using turtle graphics"""
	if turtle:
		var instructions = lsystem.get_sentence()
		turtle.interpret_lsystem(instructions, step_length, turn_angle)

func cycle_preset():
	"""Cycle to next L-System preset"""
	preset = (preset + 1) % 5
	reset()
	create_lsystem_preset()
	preset_label.text = "L-System: %s" % get_preset_name()

	# Update controllers
	if angle_controller:
		angle_controller.set_value(turn_angle)
	if length_controller:
		length_controller.set_value(step_length)

	print("Preset changed to: %s" % get_preset_name())

func increase_generations():
	"""Increase generation count"""
	if generations < 8:  # Limit to prevent explosion
		generations += 1
		reset()
		lsystem.generate_n(current_generation)
		draw_lsystem()
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
		print("Generations decreased to: %d" % generations)

func reset():
	"""Reset L-System and turtle"""
	current_generation = 0
	generation_timer = 0.0
	lsystem.reset()
	if turtle:
		turtle.reset()
	update_info_label()
