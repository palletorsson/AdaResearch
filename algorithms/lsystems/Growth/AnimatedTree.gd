extends Node3D

## Animated L-System Tree
## Grows a tree step-by-step showing the L-System generation process

var lsystem
var turtle: Turtle3D

@export var max_iterations: int = 5
@export var step_length: float = 0.3
@export var base_angle: float = 25.0
@export var growth_delay: float = 1.5  # Seconds between generations
@export var initial_thickness: float = 0.08

var current_iteration: int = 0
var growth_timer: float = 0.0
var is_growing: bool = true

# UI
var info_label: Label3D
var generation_label: Label3D

func _ready() -> void:
	# Setup Turtle with better visual parameters
	turtle = Turtle3D.new()
	add_child(turtle)
	turtle.branch_thickness = initial_thickness
	turtle.set_colors(Color(0.6, 0.4, 0.3), Color(0.3, 0.8, 0.4))  # Brown branches, green leaves
	turtle.use_pink_palette = false

	# Setup L-System (Fractal Plant)
	var LSystemClass = load("res://utils/lsystem.gd")
	lsystem = LSystemClass.create_fractal_plant()

	# Create UI
	create_ui()

	# Start with first generation
	grow_one_generation()

	print("AnimatedTree: L-System tree growth animation started")

func _process(delta: float) -> void:
	if not is_growing:
		return

	growth_timer += delta

	if growth_timer >= growth_delay:
		growth_timer = 0.0
		grow_one_generation()

func grow_one_generation() -> void:
	"""Grow one more generation of the L-System"""
	if current_iteration >= max_iterations:
		is_growing = false
		if info_label:
			info_label.text = "L-System Tree\nGrowth Complete!"
		print("AnimatedTree: Growth complete at %d generations" % current_iteration)
		return

	# Generate one more iteration
	lsystem.generate()
	current_iteration += 1

	# Draw the tree
	var instructions = lsystem.get_sentence()
	turtle.interpret_lsystem(instructions, step_length, base_angle)

	# Update UI
	update_ui()

	print("AnimatedTree: Generation %d - %d instructions" % [current_iteration, instructions.length()])

func create_ui() -> void:
	"""Create info labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(0.4, 0.8, 0.3)
	info_label.position = Vector3(0, 2.0, 0)
	add_child(info_label)

	generation_label = Label3D.new()
	generation_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	generation_label.font_size = 20
	generation_label.modulate = Color(0.6, 0.85, 0.5)
	generation_label.position = Vector3(0, 1.6, 0)
	generation_label.width = 600.0
	generation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(generation_label)

func update_ui() -> void:
	"""Update info display"""
	if info_label:
		var branch_count = turtle.branches.size()
		var leaf_count = turtle.leaves.size()
		info_label.text = "L-System Tree\nGeneration: %d/%d" % [current_iteration, max_iterations]

	if generation_label:
		var instructions = lsystem.get_sentence()
		var status = "Growing..." if is_growing else "Complete"
		generation_label.text = "Status: %s\nBranches: %d | Leaves: %d\nInstructions: %d" % [
			status,
			turtle.branches.size(),
			turtle.leaves.size(),
			instructions.length()
		]

func restart() -> void:
	"""Restart the growth animation"""
	# Reset state
	current_iteration = 0
	growth_timer = 0.0
	is_growing = true

	# Reset L-System
	lsystem.reset()

	# Reset turtle
	if turtle:
		turtle.reset()

	# Start first generation
	grow_one_generation()

	print("AnimatedTree: Restarted growth animation")

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
