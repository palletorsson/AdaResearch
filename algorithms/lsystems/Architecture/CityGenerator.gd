extends Node3D

## 3D Architecture Generator using L-Systems
## Creates complex 3D structures showing L-System spatial patterns

var lsystem
var turtle: Turtle3D

@export var iterations: int = 3
@export var step_length: float = 0.5
@export var structure_thickness: float = 0.06
@export var angle: float = 90.0
@export var show_animation: bool = false

# Materials
var structure_material: StandardMaterial3D

# UI
var info_label: Label3D
var description_label: Label3D
var generation_controller: ParameterController3D

func _ready() -> void:
	# Setup materials for architectural look
	structure_material = StandardMaterial3D.new()
	structure_material.albedo_color = Color(0.7, 0.7, 0.8)  # Concrete gray
	structure_material.metallic = 0.3
	structure_material.roughness = 0.6
	structure_material.emission_enabled = true
	structure_material.emission = Color(0.4, 0.5, 0.6) * 0.3

	# Setup Turtle
	turtle = Turtle3D.new()
	add_child(turtle)
	turtle.branch_thickness = structure_thickness
	turtle.use_pink_palette = false
	turtle.set_colors(Color(0.7, 0.7, 0.8), Color(0.8, 0.8, 0.9))  # Gray structure

	# Setup L-System for 3D Architecture
	var LSystemClass = load("res://utils/lsystem.gd")
	lsystem = LSystemClass.new("X")

	# Create a 3D architectural structure
	# Using orthogonal angles and 3D branching for building-like structures
	lsystem.add_rule("X", "F[+X]F[-X][^X][&X]")
	lsystem.add_rule("F", "FF")

	# Create UI
	create_ui()

	# Generate structure
	generate_structure()

	print("CityGenerator: 3D architectural structure generated")

func generate_structure() -> void:
	"""Generate the 3D structure"""
	lsystem.reset()
	lsystem.generate_n(iterations)

	var sentence = lsystem.get_sentence()
	print("CityGenerator: Generated %d instructions" % sentence.length())

	# Clear previous structure
	if turtle:
		turtle.reset()

	# Interpret with 90 degree angles for orthogonal architecture
	turtle.interpret_lsystem(sentence, step_length, angle)

	# Apply metallic/concrete material to all branches
	for branch in turtle.branches:
		branch.material_override = structure_material

	update_ui()

func create_ui() -> void:
	"""Create info labels and controllers"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(0.7, 0.8, 0.9)
	info_label.position = Vector3(0, 2.0, 0)
	add_child(info_label)

	description_label = Label3D.new()
	description_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	description_label.font_size = 20
	description_label.modulate = Color(0.6, 0.7, 0.8)
	description_label.position = Vector3(0, 1.6, 0)
	description_label.text = "3D Architectural Structure"
	description_label.width = 600.0
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description_label)

	# Add iteration controller
	generation_controller = ParameterController3D.new()
	generation_controller.parameter_name = "Complexity"
	generation_controller.min_value = 1.0
	generation_controller.max_value = 4.0
	generation_controller.default_value = float(iterations)
	generation_controller.step_size = 1.0
	generation_controller.position = Vector3(0, -1.5, 0)
	generation_controller.value_changed.connect(_on_iterations_changed)
	add_child(generation_controller)

func _on_iterations_changed(new_val: float) -> void:
	"""Update iterations and regenerate"""
	iterations = int(new_val)
	generate_structure()

func update_ui() -> void:
	"""Update info display"""
	if info_label:
		var segment_count = turtle.branches.size()
		info_label.text = "L-System Architecture\nComplexity: %d | Segments: %d" % [iterations, segment_count]

	if description_label:
		var instructions = lsystem.get_sentence()
		description_label.text = "3D Architectural Structure\nInstructions: %d" % instructions.length()

func _process(delta: float) -> void:
	# Gentle rotation to view the structure
	rotation.y += delta * 0.15

func set_iterations(val: int) -> void:
	"""Set iteration count (for external control)"""
	iterations = val
	if generation_controller:
		generation_controller.set_value(float(val))
	generate_structure()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

